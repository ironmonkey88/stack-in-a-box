#!/usr/bin/env bash
# 09_first_run.sh — run the smoke-test pipeline end-to-end.
#
# This is THE proof-the-box-works moment. It exercises every layer:
# dlt → DuckDB → dbt bronze/gold/admin → trust + metrics + profile + erd
# portal pages → DuckDB query through Oxygen Answer Agent.
#
# Smoke-test modes (set via SMOKE_MODE env var; default: medium):
#   small   — 10k records,  ~2-3 min   (dev iteration)
#   medium  — ~250k records, ~8-12 min (default — honest stress without 25min wait)
#   large   — ~1M records,   ~20-30 min (full stress test from chat)
#   custom  — uses SMOKE_QUERY env var verbatim
#
# Idempotent: re-running re-pulls data with dlt's merge semantics, so
# the warehouse converges to current source state without duplicates.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

readonly RUN_SH="$PROJECT_ROOT/run.sh"
readonly DUCKDB_PATH="$PROJECT_ROOT/data/stack.duckdb"
readonly TIMING_LOG="$PROJECT_ROOT/scratch/first_run_timing.txt"

main() {
    log_step "09 — first run (smoke test)"

    # ---------- preconditions ----------
    if [[ ! -x "$RUN_SH" ]]; then
        die "$RUN_SH missing or not executable"
    fi
    if [[ ! -d "$PROJECT_ROOT/.venv" ]]; then
        die "$PROJECT_ROOT/.venv missing — run 04_python_venv.sh first"
    fi

    # Verify Oxygen is up before we burn 8-25 min on a smoke test.
    # If oxy.service died between step 08 and now, the smoke test would
    # populate the warehouse fine, but the final "ask chat a question"
    # gate would fail and the user has no way to retry without rerunning
    # the slow data pull.
    if ! systemctl is-active oxy.service >/dev/null 2>&1; then
        log_error "oxy.service is not active — fix before running smoke test"
        log_error "diagnostic: sudo systemctl status oxy.service && sudo journalctl -u oxy.service -n 30"
        die "oxy.service down"
    fi
    local oxy_code
    oxy_code="$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 5 http://localhost:3000 2>/dev/null || echo 000)"
    if [[ ! "$oxy_code" =~ ^[23] ]]; then
        log_error "oxy.service is active but :3000 returns $oxy_code; fix before running smoke test"
        die "oxy not ready"
    fi
    log_ok "oxy.service ready on :3000"

    # Verify Anthropic key is loaded (we're inside the script's shell;
    # env vars from /etc/environment may not yet be present unless this
    # shell is a fresh SSH session — bootstrap.sh handles that, but if
    # this script is run standalone we need to source /etc/environment).
    # shellcheck disable=SC1091
    [[ -f /etc/environment ]] && set -a && source /etc/environment && set +a
    if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        die "ANTHROPIC_API_KEY not in environment — re-run 05_clone_and_config.sh or reconnect SSH"
    fi
    log_ok "ANTHROPIC_API_KEY present (starts with $(echo "$ANTHROPIC_API_KEY" | head -c 14)...)"

    # ---------- smoke mode ----------
    local mode="${SMOKE_MODE:-medium}"
    case "$mode" in
        small|medium|large|custom)
            log_info "smoke mode: $mode"
            ;;
        *)
            die "invalid SMOKE_MODE: $mode (expected: small|medium|large|custom)"
            ;;
    esac

    # Export so run.sh + the dlt pipeline can read it
    export SMOKE_MODE="$mode"
    export SMOKE_QUERY="${SMOKE_QUERY:-}"

    # ---------- run with timing ----------
    # Use `setsid` to detach the pipeline from the controlling terminal,
    # so an SSH disconnect mid-run doesn't kill the dlt pipeline 15 min
    # in. The pipeline still writes to logs/run.sh.log; user can
    # reconnect and `tail -f` from a fresh SSH session.
    log_info "running ./run.sh manual under setsid (survives SSH disconnect)..."
    log_info "tail logs in another shell: tail -f $PROJECT_ROOT/logs/run.sh.log"
    log_info "if SSH drops, reconnect and run: ./bootstrap.sh --only 10  (the verify will check warehouse state)"
    mkdir -p "$PROJECT_ROOT/logs"

    local start_ts end_ts elapsed
    start_ts="$(date +%s)"

    # setsid -w: detach from the controlling terminal (so an SSH SIGHUP
    # doesn't kill the pipeline mid-run) AND wait for completion so we
    # capture the real exit code. Plain `setsid` (no -w) returns the
    # instant it forks the child into the new session, which made the
    # verify gate below race the still-running pipeline (it saw an empty
    # warehouse ~1s in). The -w is load-bearing.
    local run_exit=0
    setsid -w bash -c "'$RUN_SH' manual 2>&1 | tee '$PROJECT_ROOT/logs/run.sh.log'" \
        || run_exit=$?

    # Protect the log file — it may contain debug output we'd rather not
    # leave world-readable (it shouldn't contain the API key, but
    # defense-in-depth).
    chmod 600 "$PROJECT_ROOT/logs/run.sh.log" 2>/dev/null || true

    end_ts="$(date +%s)"
    elapsed=$((end_ts - start_ts))

    # ---------- write timing log ----------
    {
        echo "smoke_mode=$mode"
        echo "elapsed_seconds=$elapsed"
        echo "run_exit=$run_exit"
        echo "ran_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    } > "$TIMING_LOG"
    log_ok "first run elapsed: ${elapsed}s (~$((elapsed / 60)) min)"
    log_ok "timing log: $TIMING_LOG"

    if [[ $run_exit -ne 0 ]]; then
        log_warn "run.sh exited $run_exit — this MAY be a captured dbt test failure"
        log_warn "(the captured-exit contract means non-zero != install failure)"
        log_warn "verify gate will check warehouse contents to decide"
    fi

    verify_gate
}

verify_gate() {
    log_step "09 — verify gate"
    local failures=0
    local warnings=0

    # ---------- DuckDB file exists ----------
    if [[ -f "$DUCKDB_PATH" ]]; then
        local size_mb
        size_mb="$(du -m "$DUCKDB_PATH" | cut -f1)"
        log_ok "DuckDB file: $DUCKDB_PATH (${size_mb}MB)"
    else
        log_error "DuckDB file missing: $DUCKDB_PATH"
        failures=$((failures + 1))
        return 1  # bail early — every subsequent check needs DuckDB
    fi

    # ---------- pipeline run recorded ----------
    local run_count
    run_count="$(
        "$PROJECT_ROOT/.venv/bin/python" -c "
import duckdb
c = duckdb.connect('$DUCKDB_PATH', read_only=True)
r = c.execute(\"SELECT COUNT(*) FROM main_admin.fct_pipeline_run_raw\").fetchone()
print(r[0] if r else 0)
" 2>/dev/null || echo 0
    )"
    if [[ "$run_count" -ge 1 ]]; then
        log_ok "pipeline runs recorded: $run_count (admin layer is live)"
    else
        log_error "no pipeline runs in main_admin.fct_pipeline_run_raw"
        failures=$((failures + 1))
    fi

    # ---------- gold fact has rows ----------
    local gold_count
    gold_count="$(
        "$PROJECT_ROOT/.venv/bin/python" -c "
import duckdb
c = duckdb.connect('$DUCKDB_PATH', read_only=True)
try:
    r = c.execute(\"SELECT COUNT(*) FROM main_gold.fct_smoke_test\").fetchone()
    print(r[0] if r else 0)
except Exception:
    print(0)
" 2>/dev/null || echo 0
    )"
    if [[ "$gold_count" -gt 0 ]]; then
        log_ok "main_gold.fct_smoke_test: $gold_count rows"
    else
        log_error "main_gold.fct_smoke_test is empty or missing"
        failures=$((failures + 1))
    fi

    # ---------- portal pages render ----------
    local route
    for route in /metrics /trust /profile /erd; do
        local code
        code="$(curl -sI -o /dev/null -w '%{http_code}' "http://localhost$route" || echo 000)"
        if [[ "$code" == "200" ]]; then
            log_ok "GET $route → 200"
        else
            log_warn "GET $route → $code (expected 200; portal page may not have regenerated)"
            warnings=$((warnings + 1))
        fi
    done

    # ---------- dbt docs deployed ----------
    if curl -sf -o /dev/null http://localhost/docs/; then
        log_ok "GET /docs/ → 200 (dbt docs deployed)"
    else
        log_warn "GET /docs/ — failed (dbt docs may not have been generated by run.sh)"
        warnings=$((warnings + 1))
    fi

    # ---------- final ----------
    if [[ $failures -eq 0 ]]; then
        if [[ $warnings -gt 0 ]]; then
            log_warn "09 — passed with $warnings warning(s); install is usable"
        else
            log_ok "09 — passed"
        fi
        return 0
    else
        log_error "09 — $failures verify gate failure(s)"
        return 1
    fi
}

main "$@"
