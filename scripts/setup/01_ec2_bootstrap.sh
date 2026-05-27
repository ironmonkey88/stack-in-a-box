#!/usr/bin/env bash
# 01_ec2_bootstrap.sh — get a fresh Ubuntu 24.04 LTS instance into a state
# where every later script's prerequisites are installed.
#
# Idempotent: re-running re-installs the same packages (apt no-op) and
# re-applies the directory/perm scaffolding (no-op if already correct).
#
# Steps:
#   1. apt update + upgrade
#   2. install base packages (build tools, python3.12, htpasswd, ufw, etc.)
#   3. /home/ubuntu chmod 755 (load-bearing — nginx www-data must traverse)
#   4. mkdir project scaffolding
#   5. UFW base posture: allow 22 + 80, deny everything else

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

readonly BASE_PACKAGES=(
    git
    curl
    wget
    unzip
    tar
    gcc
    g++
    make
    software-properties-common
    ufw
    apache2-utils      # htpasswd for /chat Basic Auth (hardening step)
    python3.12
    python3.12-venv
    python3.12-dev
    python3-pip
    jq                 # used by setup scripts + run.sh diagnostics
    netcat-openbsd     # for verify gates (port checks)
)

main() {
    log_step "01 — EC2 bootstrap"
    require_root_or_sudo

    # ---------- apt update + upgrade ----------
    log_info "updating apt index..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq

    log_info "upgrading installed packages (this may take 2-3 min)..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold"

    # ---------- detect reboot requirement ----------
    if [[ -f /var/run/reboot-required ]]; then
        log_warn "kernel update requires a reboot"
        log_warn "rebooting now; rerun this script after SSH comes back"
        log_warn "(systemd will start the reboot in 5 seconds)"
        sleep 5
        sudo systemctl reboot
        exit 100  # special exit code for bootstrap.sh to recognise
    fi

    # ---------- base packages ----------
    log_info "installing base packages..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${BASE_PACKAGES[@]}"

    # ---------- /home/ubuntu permissions ----------
    # nginx www-data must traverse this directory to serve dbt/target/.
    # Default Ubuntu mode is 750 — fails the traversal silently.
    local home_mode
    home_mode="$(stat -c '%a' /home/ubuntu)"
    if [[ "$home_mode" != "755" ]]; then
        log_info "/home/ubuntu mode is $home_mode; setting 755 (needed for nginx)"
        sudo chmod 755 /home/ubuntu
    else
        log_ok "/home/ubuntu already 755"
    fi

    # ---------- project scaffolding ----------
    log_info "creating project scaffolding..."
    mkdir -p "$PROJECT_ROOT"/{data,scratch,logs}
    log_ok "scaffolding ready at $PROJECT_ROOT"

    # ---------- UFW posture ----------
    log_info "configuring UFW..."
    # UFW is defence-in-depth alongside the AWS security group.
    # Only 22 (until Tailscale lockdown in script 06) and 80 (portal) open.
    sudo ufw --force reset >/dev/null
    sudo ufw default deny incoming >/dev/null
    sudo ufw default allow outgoing >/dev/null
    sudo ufw allow 22/tcp >/dev/null
    sudo ufw allow 80/tcp >/dev/null
    sudo ufw --force enable >/dev/null
    log_ok "UFW: 22 + 80 open, all else denied"

    verify_gate
}

verify_gate() {
    log_step "01 — verify gate"
    local failures=0

    # python3.12 resolves
    if python3.12 --version >/dev/null 2>&1; then
        log_ok "python3.12: $(python3.12 --version)"
    else
        log_error "python3.12 not on PATH"
        failures=$((failures + 1))
    fi

    # htpasswd resolves
    if command -v htpasswd >/dev/null 2>&1; then
        log_ok "htpasswd installed"
    else
        log_error "htpasswd not installed (apache2-utils failed?)"
        failures=$((failures + 1))
    fi

    # /home/ubuntu mode
    if [[ "$(stat -c '%a' /home/ubuntu)" == "755" ]]; then
        log_ok "/home/ubuntu mode 755"
    else
        log_error "/home/ubuntu mode is $(stat -c '%a' /home/ubuntu), expected 755"
        failures=$((failures + 1))
    fi

    # Project root exists
    if [[ -d "$PROJECT_ROOT" ]]; then
        log_ok "project root exists: $PROJECT_ROOT"
    else
        log_error "project root missing: $PROJECT_ROOT"
        failures=$((failures + 1))
    fi

    # UFW status
    if sudo ufw status | grep -q "Status: active"; then
        log_ok "UFW active"
    else
        log_error "UFW not active"
        failures=$((failures + 1))
    fi

    if [[ $failures -eq 0 ]]; then
        log_ok "01 — passed"
        return 0
    else
        log_error "01 — $failures verify gate failure(s)"
        return 1
    fi
}

main "$@"
