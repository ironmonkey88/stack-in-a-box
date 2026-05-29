#!/usr/bin/env bash
# 08_systemd_units.sh — install systemd units, enable oxy + timers, verify oxy up.
#
# Idempotent: re-running re-templates and re-deploys unit files; safe.
#
# Units installed:
#   - oxy.service                       (Oxygen SPA at :3000)
#   - pipeline-refresh.{timer,service}  (daily run.sh at 6 AM ET)
#   - source-health-check.{timer,service} (hourly source liveness)
#   - profile-tables.{timer,service}    (Sunday 2 AM weekly profile)
#
# Critical: oxy.service has After=docker.service + Requires=docker.service.
# Without these, oxy.service races docker on reboot and crashes trying to
# bring up the postgres container.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

readonly SYSTEMD_SRC_DIR="$PROJECT_ROOT/systemd"
readonly SYSTEMD_DST_DIR="/etc/systemd/system"

readonly UNITS_TO_INSTALL=(
    "oxy.service"
    "pipeline-refresh.service"
    "pipeline-refresh.timer"
    "source-health-check.service"
    "source-health-check.timer"
    "profile-tables.service"
    "profile-tables.timer"
)

readonly TIMERS_TO_ENABLE=(
    "pipeline-refresh.timer"
    "source-health-check.timer"
    "profile-tables.timer"
)

main() {
    log_step "08 — systemd units"
    require_root_or_sudo

    if [[ ! -d "$SYSTEMD_SRC_DIR" ]]; then
        die "$SYSTEMD_SRC_DIR missing — was the repo cloned correctly?"
    fi

    # ---------- template + install each unit ----------
    local unit src tmp
    for unit in "${UNITS_TO_INSTALL[@]}"; do
        src="$SYSTEMD_SRC_DIR/$unit"
        if [[ ! -f "$src" ]]; then
            log_warn "$unit not in repo — skipping (this is OK if the unit is optional)"
            continue
        fi

        tmp="$(mktemp)"
        # Substitute {{PROJECT_ROOT}} → actual path, {{HOME_DIR}} → install
        # user's home (for oxy.service's ExecStart — see oxy.service comment
        # on why %h can't be used for a system unit).
        sed -e "s|{{PROJECT_ROOT}}|$PROJECT_ROOT|g" \
            -e "s|{{HOME_DIR}}|$HOME|g" \
            "$src" > "$tmp"

        # Verify substitution worked — no lingering tokens
        if grep -q '{{' "$tmp"; then
            log_error "$unit has unsubstituted {{tokens}} after sed:"
            grep '{{' "$tmp" >&2
            rm -f "$tmp"
            die "fix the unit file or substitution"
        fi

        sudo install -m 0644 "$tmp" "$SYSTEMD_DST_DIR/$unit"
        rm -f "$tmp"
        log_ok "installed: $unit"
    done

    # ---------- daemon-reload ----------
    log_info "running daemon-reload..."
    sudo systemctl daemon-reload

    # ---------- enable + start oxy.service ----------
    if systemctl is-enabled oxy.service >/dev/null 2>&1; then
        log_ok "oxy.service already enabled"
    else
        log_info "enabling oxy.service..."
        sudo systemctl enable oxy.service
    fi

    log_info "starting oxy.service..."
    sudo systemctl restart oxy.service

    # ---------- wait for oxy to come up ----------
    # systemctl is-active reports "active" the moment systemd has
    # forked the process — NOT when oxy is listening on :3000. For
    # Type=simple services like this one, "active" and "ready" can be
    # 10-30 seconds apart while the postgres container comes up and
    # oxy runs migrations. Poll the actual endpoint, not just systemd.
    log_info "waiting for oxy.service to be ready on :3000 (up to 90s)..."
    local waited=0
    local readiness="unknown"
    while [[ $waited -lt 90 ]]; do
        # Both conditions must hold for "ready":
        #   (a) systemd thinks the unit is active
        #   (b) :3000 returns a 2xx/3xx HTTP code
        if systemctl is-active oxy.service >/dev/null 2>&1; then
            local code
            code="$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 2 http://localhost:3000 2>/dev/null || echo 000)"
            if [[ "$code" =~ ^[23] ]]; then
                readiness="ready"
                log_ok "oxy.service: ready on :3000 after ${waited}s (HTTP $code)"
                break
            fi
        fi
        sleep 3
        waited=$((waited + 3))
    done

    if [[ "$readiness" != "ready" ]]; then
        log_error "oxy.service did not become ready on :3000 within 90s"
        log_error "diagnostic: sudo journalctl -u oxy.service --no-pager -n 50"
        sudo journalctl -u oxy.service --no-pager -n 30 >&2 || true
        die "oxy.service not ready; review logs above"
    fi

    # ---------- enable timers ----------
    local timer
    for timer in "${TIMERS_TO_ENABLE[@]}"; do
        if [[ ! -f "$SYSTEMD_DST_DIR/$timer" ]]; then
            log_warn "$timer not installed; skipping enable"
            continue
        fi
        if systemctl is-enabled "$timer" >/dev/null 2>&1; then
            log_ok "$timer already enabled"
        else
            sudo systemctl enable --now "$timer"
            log_ok "enabled: $timer"
        fi
    done

    verify_gate
}

verify_gate() {
    log_step "08 — verify gate"
    local failures=0

    # oxy.service
    if systemctl is-active oxy.service >/dev/null 2>&1; then
        log_ok "oxy.service: active"
    else
        log_error "oxy.service: not active"
        failures=$((failures + 1))
    fi

    if systemctl is-enabled oxy.service >/dev/null 2>&1; then
        log_ok "oxy.service: enabled (survives reboot)"
    else
        log_error "oxy.service: not enabled at boot"
        failures=$((failures + 1))
    fi

    # Verify the dependency ordering is in the unit
    if grep -q "Requires=docker.service" "$SYSTEMD_DST_DIR/oxy.service" 2>/dev/null \
        && grep -q "After=.*docker.service" "$SYSTEMD_DST_DIR/oxy.service" 2>/dev/null; then
        log_ok "oxy.service has correct docker.service dependency"
    else
        log_error "oxy.service missing Requires/After=docker.service — will race on reboot"
        failures=$((failures + 1))
    fi

    # :3000 reachable on loopback
    local oxy_code
    oxy_code="$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 5 http://localhost:3000 || echo 000)"
    if [[ "$oxy_code" == "200" ]]; then
        log_ok "GET :3000 → 200 (Oxygen SPA reachable on loopback)"
    else
        log_error "GET :3000 → $oxy_code (expected 200)"
        failures=$((failures + 1))
    fi

    # Timers active
    local timer
    for timer in "${TIMERS_TO_ENABLE[@]}"; do
        if [[ ! -f "$SYSTEMD_DST_DIR/$timer" ]]; then
            continue
        fi
        if systemctl is-active "$timer" >/dev/null 2>&1; then
            log_ok "$timer: active"
        else
            log_error "$timer: not active"
            failures=$((failures + 1))
        fi
    done

    if [[ $failures -eq 0 ]]; then
        log_ok "08 — passed"
        return 0
    else
        log_error "08 — $failures verify gate failure(s)"
        return 1
    fi
}

main "$@"
