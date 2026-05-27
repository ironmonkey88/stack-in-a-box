#!/usr/bin/env bash
# 02_install_docker.sh — install Docker, add ubuntu to docker group, enable systemd unit.
#
# Idempotent: re-running detects existing Docker and skips reinstall.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

main() {
    log_step "02 — install Docker"
    require_root_or_sudo

    if command -v docker >/dev/null 2>&1; then
        log_info "docker already installed: $(docker --version)"
    else
        log_info "running official Docker installer..."
        # Official script. We pipe it through bash because that's what
        # docker.com tells everyone to do; the alternative is auditing
        # apt sources manually, which is more surface than less.
        #
        # TRUST ASSUMPTION: we trust that get.docker.com over HTTPS has
        # not been compromised between us and Docker, Inc. For higher
        # assurance, see https://docs.docker.com/engine/install/ubuntu/
        # which describes apt-based install with GPG-signed repos.
        if ! curl -fsSL https://get.docker.com -o /tmp/get-docker.sh; then
            die "failed to download Docker install script"
        fi
        sudo sh /tmp/get-docker.sh
        rm -f /tmp/get-docker.sh
        log_ok "docker installed: $(docker --version)"
    fi

    # ---------- group membership ----------
    if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        log_ok "$USER already in docker group"
    else
        log_info "adding $USER to docker group..."
        sudo usermod -aG docker "$USER"
        log_warn "group membership won't apply to this shell until logout/login"
        log_warn "verify gate will use 'sudo docker ps' to validate; rerun in a new shell to use unprivileged docker"
    fi

    # ---------- enable + start ----------
    if systemctl is-enabled docker >/dev/null 2>&1; then
        log_ok "docker.service already enabled"
    else
        log_info "enabling docker.service..."
        sudo systemctl enable --now docker
    fi

    if ! systemctl is-active docker >/dev/null 2>&1; then
        log_info "starting docker.service..."
        sudo systemctl start docker
    fi

    verify_gate
}

verify_gate() {
    log_step "02 — verify gate"
    local failures=0

    # docker --version resolves
    if docker --version >/dev/null 2>&1; then
        log_ok "docker version: $(docker --version)"
    else
        log_error "docker binary not on PATH"
        failures=$((failures + 1))
    fi

    # docker.service is active and enabled
    if systemctl is-active docker >/dev/null 2>&1; then
        log_ok "docker.service: active"
    else
        log_error "docker.service not active"
        failures=$((failures + 1))
    fi

    if systemctl is-enabled docker >/dev/null 2>&1; then
        log_ok "docker.service: enabled (will survive reboot)"
    else
        log_error "docker.service not enabled"
        failures=$((failures + 1))
    fi

    # docker ps works — try unprivileged first, fall back to sudo
    # (in-script the group change hasn't propagated yet; sudo is the
    # honest way to test docker is functional)
    if sudo docker ps >/dev/null 2>&1; then
        log_ok "docker ps succeeds (via sudo; unprivileged will work after new shell)"
    else
        log_error "docker ps fails even with sudo — daemon not responding"
        failures=$((failures + 1))
    fi

    if [[ $failures -eq 0 ]]; then
        log_ok "02 — passed"
        return 0
    else
        log_error "02 — $failures verify gate failure(s)"
        return 1
    fi
}

main "$@"
