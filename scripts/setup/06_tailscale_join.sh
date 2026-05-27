#!/usr/bin/env bash
# 06_tailscale_join.sh — install Tailscale, join the user's Tailnet,
# print AWS SG lockdown instructions.
#
# This script does NOT close the AWS Security Group itself — the user
# does that on their laptop after verifying Tailnet SSH works. Closing
# the SG before Tailnet SSH is verified == locking yourself out.
#
# Idempotent: detects existing Tailscale install + join, skips if already up.
#
# Critical: --ssh=false. Tailscale SSH bypasses OpenSSH's PAM stack,
# which silently breaks /etc/environment env-var loading. Never re-enable
# Tailscale SSH without also fixing the env-var path.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

readonly TAILSCALE_HOSTNAME_DEFAULT="stack-in-a-box"

main() {
    log_step "06 — Tailscale join"
    require_root_or_sudo

    local hostname="${TAILSCALE_HOSTNAME:-$TAILSCALE_HOSTNAME_DEFAULT}"

    # ---------- install Tailscale if missing ----------
    if command -v tailscale >/dev/null 2>&1; then
        log_ok "tailscale already installed: $(tailscale --version | head -1)"
    else
        log_info "installing Tailscale..."
        # TRUST ASSUMPTION: we trust tailscale.com/install.sh over TLS.
        # For higher assurance, see https://tailscale.com/kb/1031/install-linux
        # which describes apt-based install with GPG-signed Tailscale repo.
        if ! curl -fsSL https://tailscale.com/install.sh | sudo sh; then
            die "Tailscale install failed"
        fi
        log_ok "tailscale installed: $(tailscale --version | head -1)"
    fi

    # ---------- check if already joined ----------
    local status_json
    status_json="$(sudo tailscale status --json 2>/dev/null || echo '{}')"
    local backend_state
    backend_state="$(echo "$status_json" | jq -r '.BackendState // "Unknown"')"

    if [[ "$backend_state" == "Running" ]]; then
        local current_hostname
        current_hostname="$(echo "$status_json" | jq -r '.Self.HostName // "unknown"')"
        log_ok "Tailscale already running; hostname: $current_hostname"
        if [[ "$current_hostname" != "$hostname" ]]; then
            log_warn "Tailnet hostname is '$current_hostname'; expected '$hostname'"
            log_warn "(if intentional, set TAILSCALE_HOSTNAME to silence this warning)"
        fi
    else
        log_info "Tailscale backend state: $backend_state — joining..."

        local authkey
        read_secret "Paste Tailscale auth key (tskey-auth-...): " authkey "tskey-auth-" "TAILSCALE_AUTHKEY" \
            || die "auth key entry failed"

        # CRITICAL: --ssh=false. Tailscale SSH preempts port 22 for
        # Tailnet peers via tailscaled be-child, bypassing OpenSSH PAM
        # and silently breaking /etc/environment env-var loading.
        log_info "running: tailscale up --hostname=$hostname --ssh=false"
        if ! sudo tailscale up \
                --authkey="$authkey" \
                --hostname="$hostname" \
                --ssh=false \
                --accept-routes; then
            die "tailscale up failed — check auth key validity and Tailnet config"
        fi
        log_ok "Tailscale joined"
    fi

    # ---------- capture and display Tailnet identity ----------
    local tailnet_ip tailnet_hostname
    tailnet_ip="$(sudo tailscale ip -4 2>/dev/null | head -1 || echo unknown)"
    tailnet_hostname="$(sudo tailscale status --json 2>/dev/null | jq -r '.Self.DNSName // "unknown"' | sed 's/\.$//')"

    if [[ "$tailnet_ip" == "unknown" ]]; then
        die "tailscale ip -4 returned nothing; join may have failed"
    fi

    log_ok "Tailnet IPv4: $tailnet_ip"
    log_ok "Tailnet hostname (MagicDNS): $tailnet_hostname"

    # ---------- write Tailnet identity to scratch for later scripts to use ----------
    mkdir -p "$PROJECT_ROOT/scratch"
    cat > "$PROJECT_ROOT/scratch/tailnet_identity.env" <<EOF
TAILNET_IPV4=$tailnet_ip
TAILNET_HOSTNAME=$tailnet_hostname
EOF
    log_ok "Tailnet identity written to scratch/tailnet_identity.env"

    # ---------- print AWS SG lockdown instructions ----------
    print_lockdown_instructions "$tailnet_ip" "$tailnet_hostname"

    verify_gate "$tailnet_ip"
}

print_lockdown_instructions() {
    local tailnet_ip="$1"
    local tailnet_hostname="$2"

    cat >&2 <<EOF

${CLR_YELLOW}========================================================================${CLR_RESET}
${CLR_YELLOW}MANUAL STEP REQUIRED — close public SSH and :3000 on AWS${CLR_RESET}
${CLR_YELLOW}========================================================================${CLR_RESET}

This EC2 instance is now reachable on your Tailnet at:
    SSH:    ssh ubuntu@$tailnet_hostname
            (or: ssh ubuntu@$tailnet_ip)
    Oxygen: http://$tailnet_hostname:3000

Before continuing, do TWO things on your laptop:

1. VERIFY Tailnet SSH works:
       ssh ubuntu@$tailnet_hostname 'echo ok-from-tailnet'

   If that fails — STOP. Do not close the AWS SG until it works.
   Check: are you signed in to the same Tailnet on your laptop?
          tailscale status   should show this EC2 node.

2. CLOSE public SSH and :3000 on the AWS Security Group:

   AWS Console → EC2 → Security Groups → (your SG)
   Inbound rules → delete:
       - SSH (22) from 0.0.0.0/0
       - Custom TCP 3000 from 0.0.0.0/0    (if present)
   Inbound rules → keep:
       - HTTP (80) from 0.0.0.0/0          (portal stays public)

Once both are done, continue with: 07_nginx_site.sh

${CLR_YELLOW}========================================================================${CLR_RESET}

EOF
}

verify_gate() {
    local tailnet_ip="$1"
    log_step "06 — verify gate"
    local failures=0

    if sudo systemctl is-active tailscaled >/dev/null 2>&1; then
        log_ok "tailscaled: active"
    else
        log_error "tailscaled not active"
        failures=$((failures + 1))
    fi

    local backend_state
    backend_state="$(sudo tailscale status --json 2>/dev/null | jq -r '.BackendState // "Unknown"')"
    if [[ "$backend_state" == "Running" ]]; then
        log_ok "tailscale backend: Running"
    else
        log_error "tailscale backend: $backend_state"
        failures=$((failures + 1))
    fi

    if [[ "$tailnet_ip" =~ ^100\. ]]; then
        log_ok "Tailnet IPv4 is valid: $tailnet_ip"
    else
        log_error "Tailnet IPv4 invalid: $tailnet_ip"
        failures=$((failures + 1))
    fi

    # Note: we deliberately do NOT try to detect whether Tailscale SSH
    # is enabled from `tailscale status --json`. The `.Self.Capabilities`
    # field reflects tailnet ACL grants, not local up-flag state, and
    # `.Self.SSHHostKeys` only populates after first SSH use.
    # We control the up-flags ourselves (always --ssh=false on join) and
    # this script does not enable Tailscale SSH after the fact, so trust
    # the invocation. If a future operator runs `tailscale set --ssh=true`
    # by hand, that's an operator-error not a script-detection problem.
    log_ok "tailscale SSH should be OFF (we always pass --ssh=false on join)"

    if [[ $failures -eq 0 ]]; then
        log_ok "06 — passed"
        log_warn "complete the manual AWS SG step above before running 07."
        return 0
    else
        log_error "06 — $failures verify gate failure(s)"
        return 1
    fi
}

main "$@"
