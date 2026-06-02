#!/usr/bin/env bash
# 03_install_oxygen.sh — install Oxygen CLI via the official installer.
#
# Idempotent: detects existing oxy and skips reinstall (unless FORCE=1).
#
# Pinned to a known-good Oxygen version (Plan 4). get.oxy.tech's installer
# honors the OXY_VERSION env var (default `latest`); we pass the pin so installs
# are reproducible. Override with OXY_VERSION=<tag> (or OXY_VERSION=latest) in
# the environment to install something else.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

readonly OXY_INSTALLER_URL="https://get.oxy.tech"
readonly OXY_BIN_PATH="$HOME/.local/bin/oxy"
# Plan 3 proved 0.5.54 on metal (docs/design/FIRST_INSTALL_FINDINGS.md); pin it.
# Tag is unprefixed on github.com/oxy-hq/oxygen/releases.
readonly OXY_VERSION_PIN="${OXY_VERSION:-0.5.54}"

main() {
    log_step "03 — install Oxygen"
    require_not_root

    local oxy_ver=""
    if [[ -x "$OXY_BIN_PATH" ]] && [[ "${FORCE:-0}" != "1" ]]; then
        if oxy_ver="$("$OXY_BIN_PATH" --version 2>&1)"; then
            log_info "oxy already installed: $(echo "$oxy_ver" | head -1)"
            log_info "set FORCE=1 to reinstall"
        else
            log_warn "$OXY_BIN_PATH exists but --version failed; reinstalling"
            FORCE=1
        fi
    fi

    if [[ ! -x "$OXY_BIN_PATH" ]] || [[ "${FORCE:-0}" == "1" ]]; then
        log_info "running Oxygen installer..."
        # The installer writes to ~/.local/bin and (if missing) appends
        # PATH lines to ~/.bashrc. We override the shell-rc behaviour by
        # managing PATH ourselves via /etc/environment in script 05.
        #
        # TRUST ASSUMPTION: we trust get.oxy.tech over TLS 1.2+ has not
        # been compromised. The --proto '=https' --tlsv1.2 flags enforce
        # HTTPS-only and a minimum TLS version. For higher assurance,
        # download a specific release tarball with a known SHA256 from
        # github.com/oxy-hq/oxygen/releases.
        # --connect-timeout / --max-time so a slow-but-reachable endpoint
        # fails loud instead of hanging the install indefinitely (dry-run F11).
        log_info "requesting Oxygen version: $OXY_VERSION_PIN"
        if ! OXY_VERSION="$OXY_VERSION_PIN" bash <(curl --proto '=https' --tlsv1.2 --connect-timeout 10 --max-time 120 -LsSf "$OXY_INSTALLER_URL"); then
            die "Oxygen installer failed (or timed out — check get.oxy.tech reachability)"
        fi

        # Verify the install actually produced a working binary — don't
        # mask failures with `|| echo unknown`.
        if ! oxy_ver="$("$OXY_BIN_PATH" --version 2>&1)"; then
            die "Oxygen installer claimed success but $OXY_BIN_PATH --version failed: $oxy_ver"
        fi
        log_ok "oxy installed: $(echo "$oxy_ver" | head -1)"
    fi

    # ---------- mkdir ~/.local/bin if installer didn't ----------
    mkdir -p "$HOME/.local/bin"

    # ---------- verify the binary is at the expected path ----------
    if [[ ! -x "$OXY_BIN_PATH" ]]; then
        die "Oxygen installer succeeded but $OXY_BIN_PATH not found or not executable"
    fi

    # ---------- restart a running oxy.service onto the new binary ----------
    # If this is a version upgrade on a live box, oxy.service is already running
    # the OLD binary. Replacing the binary file does NOT swap the running
    # process — it keeps the now-deleted inode open and holds an abnormal
    # read-write lock on the DuckDB warehouse, blocking readers and a second
    # `oxy run` (Plan 4 finding). Restart it so the new binary takes over and
    # the stale lock is released. On a fresh install the unit doesn't exist yet
    # (created in step 08), so this is a no-op.
    if systemctl is-active --quiet oxy.service 2>/dev/null; then
        log_info "oxy.service is running; restarting onto the new binary..."
        sudo systemctl restart oxy.service || log_warn "oxy.service restart failed; restart manually"
    fi

    verify_gate
}

verify_gate() {
    log_step "03 — verify gate"
    local failures=0

    if [[ -x "$OXY_BIN_PATH" ]]; then
        log_ok "oxy binary present: $OXY_BIN_PATH"
    else
        log_error "oxy binary missing or not executable: $OXY_BIN_PATH"
        failures=$((failures + 1))
    fi

    if "$OXY_BIN_PATH" --version >/dev/null 2>&1; then
        log_ok "oxy --version: $($OXY_BIN_PATH --version 2>/dev/null | head -1)"
    else
        log_error "oxy --version failed"
        failures=$((failures + 1))
    fi

    # Pin assertion — the installed version must match the requested pin so a
    # drifted/over-latest install fails loud instead of silently changing the
    # proven version (Plan 4). Skipped when OXY_VERSION=latest was requested.
    if [[ "$OXY_VERSION_PIN" != "latest" ]]; then
        if "$OXY_BIN_PATH" --version 2>/dev/null | grep -q "$OXY_VERSION_PIN"; then
            log_ok "oxy version matches pin: $OXY_VERSION_PIN"
        else
            log_error "oxy version does not match pin $OXY_VERSION_PIN (got: $($OXY_BIN_PATH --version 2>/dev/null | head -1))"
            failures=$((failures + 1))
        fi
    fi

    # Note: we do NOT verify `oxy` is on PATH for new SSH sessions here.
    # That requires /etc/environment work in script 05. Script 05's verify
    # gate handles the cross-script check.

    if [[ $failures -eq 0 ]]; then
        log_ok "03 — passed"
        return 0
    else
        log_error "03 — $failures verify gate failure(s)"
        return 1
    fi
}

main "$@"
