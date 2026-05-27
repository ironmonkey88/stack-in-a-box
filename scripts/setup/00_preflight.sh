#!/usr/bin/env bash
# 00_preflight.sh — verify the environment before any state-changing scripts run.
#
# Exits 0 if the host looks installable, 1 with diagnostic output otherwise.
# Designed to be safe to re-run at any time; makes no changes.
#
# Checks:
#   - OS: Ubuntu 24.04 (warns on 22.04, fails on others)
#   - Arch: arm64 or amd64
#   - Disk: ≥10 GB free on /
#   - RAM: ≥3.5 GB total (t4g.medium has 4 GB)
#   - Network: can reach apt mirror, get.docker.com, get.oxy.tech,
#              api.anthropic.com, login.tailscale.com,
#              data.cityofnewyork.us (smoke source)
#   - Not running as root (scripts use sudo where needed; running as root
#     breaks /home/ubuntu paths the rest of the install assumes)
#   - /home/ubuntu exists (we assume the ubuntu user is the install user)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

readonly REQUIRED_FREE_GB=10
readonly REQUIRED_RAM_MB=3500
readonly NETWORK_TARGETS=(
    "https://archive.ubuntu.com"
    "https://get.docker.com"
    "https://get.oxy.tech"
    "https://api.anthropic.com"
    "https://login.tailscale.com"
    "https://data.cityofnewyork.us"
)

main() {
    log_step "00 — preflight checks"
    local failures=0

    # ---------- OS check ----------
    log_info "checking OS..."
    if [[ ! -f /etc/os-release ]]; then
        log_error "cannot detect OS — /etc/os-release missing"
        failures=$((failures + 1))
    else
        # shellcheck source=/dev/null
        source /etc/os-release
        if [[ "${ID:-}" != "ubuntu" ]]; then
            log_error "this template targets Ubuntu; detected: ${ID:-unknown}"
            failures=$((failures + 1))
        elif [[ "${VERSION_ID:-}" == "24.04" ]]; then
            log_ok "Ubuntu 24.04 LTS"
        elif [[ "${VERSION_ID:-}" == "22.04" ]]; then
            log_warn "Ubuntu 22.04 — supported but 24.04 is preferred"
        else
            log_error "Ubuntu ${VERSION_ID:-unknown} — untested; expected 24.04"
            failures=$((failures + 1))
        fi
    fi

    # ---------- Arch check ----------
    log_info "checking architecture..."
    local arch
    arch="$(uname -m)"
    case "$arch" in
        aarch64|x86_64) log_ok "architecture: $arch" ;;
        *) log_error "unsupported architecture: $arch"; failures=$((failures + 1)) ;;
    esac

    # ---------- User check ----------
    log_info "checking user..."
    if [[ $EUID -eq 0 ]]; then
        log_error "do not run as root; run as the 'ubuntu' user (sudo is used internally)"
        failures=$((failures + 1))
    elif [[ "${USER:-$(whoami)}" != "ubuntu" ]]; then
        log_warn "user is '${USER:-$(whoami)}'; scripts assume 'ubuntu'. proceed with care."
    else
        log_ok "user: ubuntu"
    fi

    # ---------- Home dir ----------
    if [[ ! -d /home/ubuntu ]]; then
        log_error "/home/ubuntu does not exist; the install assumes this path"
        failures=$((failures + 1))
    else
        log_ok "/home/ubuntu exists"
    fi

    # ---------- Disk ----------
    log_info "checking disk..."
    local free_gb
    free_gb="$(df -BG --output=avail / | tail -1 | tr -d 'G ')"
    if [[ "$free_gb" -lt $REQUIRED_FREE_GB ]]; then
        log_error "free disk on /: ${free_gb}GB (need ≥${REQUIRED_FREE_GB}GB)"
        failures=$((failures + 1))
    else
        log_ok "free disk on /: ${free_gb}GB"
    fi

    # ---------- RAM ----------
    log_info "checking RAM..."
    local total_mb
    total_mb="$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)"
    if [[ "$total_mb" -lt $REQUIRED_RAM_MB ]]; then
        log_error "total RAM: ${total_mb}MB (need ≥${REQUIRED_RAM_MB}MB)"
        failures=$((failures + 1))
    else
        log_ok "total RAM: ${total_mb}MB"
    fi

    # ---------- Network ----------
    log_info "checking network reachability..."
    require_cmd curl
    local target
    for target in "${NETWORK_TARGETS[@]}"; do
        # We deliberately do NOT use `curl -f` here. Most of these
        # endpoints return 4xx without auth (api.anthropic.com → 404,
        # login.tailscale.com → 403, get.docker.com → 403) — that's
        # still proof the network reaches them. We only care that we
        # got SOME HTTP response within the timeout, not the status code.
        local code
        code="$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 5 --max-time 10 "$target" 2>/dev/null || echo "000")"
        if [[ "$code" == "000" ]]; then
            log_error "unreachable: $target (no HTTP response)"
            failures=$((failures + 1))
        else
            log_ok "reachable: $target (HTTP $code)"
        fi
    done

    # ---------- cloud-init still running? ----------
    # A fresh EC2 instance runs cloud-init for ~60-90s after boot. During
    # that window, apt-get is locked by cloud-init's own package updates.
    # If a user SSHes in fast and starts the install, script 01's apt-get
    # update hits "Could not get lock /var/lib/dpkg/lock-frontend".
    if command -v cloud-init >/dev/null 2>&1; then
        local ci_status
        ci_status="$(cloud-init status 2>/dev/null | awk -F': ' '/status:/ {print $2}' || echo unknown)"
        case "$ci_status" in
            done|disabled)
                log_ok "cloud-init: $ci_status"
                ;;
            running|not\ run)
                log_warn "cloud-init is still running; waiting up to 180s for it to finish..."
                log_warn "(this is normal on a freshly-launched EC2; do NOT Ctrl-C — cloud-init"
                log_warn " runs in the background and Ctrl-C just kills our wait, not cloud-init itself)"
                if cloud-init status --wait --long >/dev/null 2>&1; then
                    log_ok "cloud-init completed"
                else
                    log_error "cloud-init did not finish within 180s"
                    log_error "diagnose: cloud-init status --long; sudo journalctl -u cloud-init"
                    failures=$((failures + 1))
                fi
                ;;
            *)
                log_warn "cloud-init status: $ci_status (proceeding anyway)"
                ;;
        esac
    fi

    # ---------- snap-installed Docker warning ----------
    if command -v snap >/dev/null 2>&1; then
        if snap list 2>/dev/null | grep -q '^docker '; then
            log_warn "snap-installed docker detected"
            log_warn "the install assumes deb-installed docker; snap docker has different"
            log_warn "socket paths and group config. recommend: 'sudo snap remove docker' before continuing"
            failures=$((failures + 1))
        fi
    fi

    # ---------- Summary ----------
    echo "" >&2
    if [[ $failures -eq 0 ]]; then
        log_ok "preflight passed — safe to run 01_ec2_bootstrap.sh"
        return 0
    else
        log_error "preflight failed with $failures issue(s) — fix before proceeding"
        return 1
    fi
}

main "$@"
