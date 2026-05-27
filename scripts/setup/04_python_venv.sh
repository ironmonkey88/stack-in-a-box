#!/usr/bin/env bash
# 04_python_venv.sh — create the project venv and install the pinned stack.
#
# Idempotent: re-running upgrades the venv to whatever requirements.txt
# currently specifies, but never destroys the existing venv unless
# FORCE=1 is set.
#
# The exact versions are pinned in requirements.txt at the project root.
# This script does not pin inline so the source of truth stays in one
# place (and so `pip install -r requirements.txt` works both inside and
# outside the install flow).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

readonly VENV_DIR="$PROJECT_ROOT/.venv"
readonly REQUIREMENTS_FILE="$PROJECT_ROOT/requirements.txt"

main() {
    log_step "04 — Python venv + pinned stack"
    require_not_root

    if [[ ! -d "$PROJECT_ROOT" ]]; then
        die "$PROJECT_ROOT does not exist — run 01_ec2_bootstrap.sh first"
    fi
    if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
        die "requirements.txt missing at $REQUIREMENTS_FILE — run 05_clone_and_config.sh first (or check the repo was cloned)"
        # Note: this script can run before OR after 05 depending on order.
        # If 05 runs first (the typical bootstrap.sh order), requirements.txt
        # is already present. If 04 runs first, the user needs to clone manually.
        # bootstrap.sh handles the ordering.
    fi

    require_cmd python3.12

    # ---------- venv create / refresh ----------
    if [[ -d "$VENV_DIR" ]] && [[ "${FORCE:-0}" == "1" ]]; then
        log_warn "FORCE=1; removing existing venv at $VENV_DIR"
        rm -rf "$VENV_DIR"
    fi

    if [[ ! -d "$VENV_DIR" ]]; then
        log_info "creating venv at $VENV_DIR..."
        python3.12 -m venv "$VENV_DIR"
        log_ok "venv created"
    else
        log_ok "venv already exists at $VENV_DIR"
    fi

    # ---------- activate + upgrade pip ----------
    # shellcheck source=/dev/null
    source "$VENV_DIR/bin/activate"

    log_info "upgrading pip..."
    # Use 'python -m pip' rather than bare 'pip' for the self-upgrade —
    # bare pip can't reliably overwrite itself mid-execution on some
    # platforms; the python module wrapper sidesteps the lifecycle issue.
    "$VENV_DIR/bin/python" -m pip install --quiet --upgrade pip

    # ---------- install requirements ----------
    log_info "installing pinned packages from requirements.txt (this is the slow part — 2-4 min)..."
    "$VENV_DIR/bin/python" -m pip install --quiet -r "$REQUIREMENTS_FILE"
    log_ok "packages installed"

    verify_gate
}

verify_gate() {
    log_step "04 — verify gate"
    local failures=0

    # venv python is 3.12.x
    local pyver
    pyver="$("$VENV_DIR/bin/python" --version 2>&1 || echo none)"
    if [[ "$pyver" =~ Python\ 3\.12\. ]]; then
        log_ok "venv python: $pyver"
    else
        log_error "venv python is '$pyver', expected Python 3.12.x"
        failures=$((failures + 1))
    fi

    # dlt resolves
    if "$VENV_DIR/bin/dlt" --version >/dev/null 2>&1; then
        log_ok "dlt: $("$VENV_DIR/bin/dlt" --version 2>&1 | head -1)"
    else
        log_error "dlt CLI missing from venv"
        failures=$((failures + 1))
    fi

    # dbt resolves + duckdb adapter
    if "$VENV_DIR/bin/dbt" --version >/dev/null 2>&1; then
        local dbt_ver
        dbt_ver="$("$VENV_DIR/bin/dbt" --version 2>&1)"
        log_ok "dbt: $(echo "$dbt_ver" | grep -E '^Core' | head -1)"
        if echo "$dbt_ver" | grep -q duckdb; then
            log_ok "dbt-duckdb adapter installed"
        else
            log_error "dbt-duckdb adapter NOT found"
            failures=$((failures + 1))
        fi
    else
        log_error "dbt CLI missing from venv"
        failures=$((failures + 1))
    fi

    # duckdb importable
    if "$VENV_DIR/bin/python" -c "import duckdb; print('duckdb', duckdb.__version__)" >/dev/null 2>&1; then
        log_ok "duckdb: $("$VENV_DIR/bin/python" -c 'import duckdb; print(duckdb.__version__)')"
    else
        log_error "duckdb not importable in venv"
        failures=$((failures + 1))
    fi

    # python-ulid importable (we hit this in Somerville Session 29 with the
    # 1.x → 3.x API change; verifying import works guards against the next one)
    if "$VENV_DIR/bin/python" -c "from ulid import ULID; ULID()" >/dev/null 2>&1; then
        log_ok "python-ulid: import + ULID() construct OK"
    else
        log_error "python-ulid import or construct failed (check API version)"
        failures=$((failures + 1))
    fi

    if [[ $failures -eq 0 ]]; then
        log_ok "04 — passed"
        return 0
    else
        log_error "04 — $failures verify gate failure(s)"
        return 1
    fi
}

main "$@"
