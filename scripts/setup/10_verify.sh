#!/usr/bin/env bash
# 10_verify.sh — final end-to-end functional check.
#
# Each check is one line, pass/fail with hint. Exits 0 if all pass, 1
# with a count of failures otherwise.
#
# The last "check" is browser-only — we print instructions for the user
# to manually verify the Answer Agent works end-to-end with the trust
# contract intact. Curl can't see the SPA chat surface.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

readonly DUCKDB_PATH="$PROJECT_ROOT/data/stack.duckdb"

main() {
    log_step "10 — final verification"
    local failures=0

    # ---------- systemd services ----------
    check_active docker            || failures=$((failures + 1))
    check_active nginx             || failures=$((failures + 1))
    check_active tailscaled        || failures=$((failures + 1))
    check_active oxy.service       || failures=$((failures + 1))

    # ---------- timers ----------
    # We check enabled (boot-persistent), NOT active: step 08 deliberately
    # enables the timers without `--now`, because pipeline-refresh.timer has
    # Persistent=true and activating it mid-install fires an immediate catch-up
    # run.sh that contends with the smoke run / oxy on the DuckDB single-writer
    # lock. The timers activate on next boot.
    local timer
    for timer in pipeline-refresh.timer source-health-check.timer profile-tables.timer; do
        check_enabled "$timer" || failures=$((failures + 1))
    done

    # ---------- portal routes ----------
    check_http 200 http://localhost/        "portal /"                    || failures=$((failures + 1))
    check_http 200 http://localhost/docs/   "dbt docs /docs"              || failures=$((failures + 1))
    check_http 200 http://localhost/metrics "metrics catalog /metrics"    || failures=$((failures + 1))
    check_http 200 http://localhost/trust   "trust page /trust"           || failures=$((failures + 1))
    check_http 200 http://localhost/profile "column profile /profile"     || failures=$((failures + 1))
    check_http 200 http://localhost/erd     "ERD /erd"                    || failures=$((failures + 1))

    # ---------- Oxygen SPA on loopback ----------
    check_http 200 http://localhost:3000    "Oxygen SPA (loopback only)" || failures=$((failures + 1))

    # ---------- warehouse contents ----------
    check_duckdb_rows "main_gold.fct_smoke_test" || failures=$((failures + 1))
    check_duckdb_rows "main_admin.fct_pipeline_run_raw" || failures=$((failures + 1))

    # ---------- AWS SG closed publicly (load-bearing, no longer optional) ----------
    # Iter 9 finding: the optional PUBLIC_IP check could be silently skipped
    # and the install could complete with :3000 internet-exposed. Now we
    # try multiple sources to obtain the public IP and fail loud if we
    # can't verify the SG is closed.
    local public_ip="${PUBLIC_IP:-}"
    if [[ -z "$public_ip" ]]; then
        # Try EC2 instance metadata (IMDSv2 — need to fetch a token first)
        local imds_token
        imds_token="$(curl -sS -X PUT --max-time 3 \
            -H 'X-aws-ec2-metadata-token-ttl-seconds: 30' \
            http://169.254.169.254/latest/api/token 2>/dev/null || true)"
        if [[ -n "$imds_token" ]]; then
            public_ip="$(curl -sS --max-time 3 \
                -H "X-aws-ec2-metadata-token: $imds_token" \
                http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || true)"
        fi
    fi

    if [[ -n "$public_ip" ]]; then
        # NOTE (best-effort): this tests the instance's OWN public IP from
        # inside the instance. AWS may hairpin this connection, so the result
        # is not a fully authoritative substitute for an external probe — a
        # port could read "closed" here yet be open to the internet (or vice
        # versa) depending on routing. The truly authoritative check is from
        # the user's laptop (the browser step below exercises it). We keep
        # this as a loud heuristic; the manual-verify fallback covers the gap.
        log_info "checking public-port lockdown on $public_ip (best-effort, from inside the instance)..."
        local public_sg_failures=0
        if timeout 5 bash -c "</dev/tcp/$public_ip/22" 2>/dev/null; then
            log_error "PUBLIC port 22 (SSH) is OPEN on $public_ip — close it at AWS SG NOW"
            public_sg_failures=$((public_sg_failures + 1))
        else
            log_ok "public port 22 closed on $public_ip"
        fi
        if timeout 5 bash -c "</dev/tcp/$public_ip/3000" 2>/dev/null; then
            log_error "PUBLIC port 3000 (Oxygen SPA) is OPEN on $public_ip — close it at AWS SG NOW"
            log_error "anyone on the internet can reach your chat agent and run queries"
            public_sg_failures=$((public_sg_failures + 1))
        else
            log_ok "public port 3000 closed on $public_ip"
        fi
        if [[ $public_sg_failures -gt 0 ]]; then
            failures=$((failures + public_sg_failures))
        fi
    else
        log_warn "could not determine public IP via env (PUBLIC_IP) or IMDS"
        log_warn "MANUALLY verify your AWS Security Group has 22 and 3000 closed to 0.0.0.0/0"
        log_warn "(this is a load-bearing security step; do not skip it)"
        # Not a hard failure — IMDS could be disabled on the AMI — but loud.
    fi

    # ---------- summary ----------
    echo "" >&2
    if [[ $failures -eq 0 ]]; then
        log_ok "10 — all curl-able checks passed"
        print_browser_instructions
        return 0
    else
        log_error "10 — $failures check(s) failed; review above"
        return 1
    fi
}

# check_active SERVICE — verify a systemd unit is active.
check_active() {
    local svc="$1"
    if systemctl is-active "$svc" >/dev/null 2>&1; then
        log_ok "systemd: $svc active"
        return 0
    else
        log_error "systemd: $svc NOT active — try 'sudo systemctl status $svc'"
        return 1
    fi
}

# check_enabled UNIT — verify a systemd unit is enabled (boot-persistent),
# regardless of whether it is currently active.
check_enabled() {
    local unit="$1"
    if systemctl is-enabled "$unit" >/dev/null 2>&1; then
        log_ok "systemd: $unit enabled (activates on boot)"
        return 0
    else
        log_error "systemd: $unit NOT enabled — try 'sudo systemctl status $unit'"
        return 1
    fi
}

# check_http EXPECTED_CODE URL LABEL — GET URL, compare status code.
check_http() {
    local expected="$1"
    local url="$2"
    local label="$3"
    local code
    code="$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 5 "$url" 2>/dev/null || echo 000)"
    if [[ "$code" == "$expected" ]]; then
        log_ok "$label: $url → $code"
        return 0
    else
        log_error "$label: $url → $code (expected $expected)"
        return 1
    fi
}

# check_duckdb_rows TABLE — verify a DuckDB table has >0 rows.
check_duckdb_rows() {
    local table="$1"
    local count
    count="$(
        "$PROJECT_ROOT/.venv/bin/python" -c "
import duckdb
try:
    c = duckdb.connect('$DUCKDB_PATH', read_only=True)
    r = c.execute(\"SELECT COUNT(*) FROM $table\").fetchone()
    print(r[0] if r else 0)
except Exception as e:
    import sys; print(0); print(e, file=sys.stderr)
" 2>/dev/null || echo 0
    )"
    if [[ "$count" -gt 0 ]]; then
        log_ok "warehouse: $table → $count rows"
        return 0
    else
        log_error "warehouse: $table → empty or missing"
        return 1
    fi
}

print_browser_instructions() {
    local tailnet_hostname=""
    if [[ -f "$PROJECT_ROOT/scratch/tailnet_identity.env" ]]; then
        # shellcheck source=/dev/null
        source "$PROJECT_ROOT/scratch/tailnet_identity.env"
        tailnet_hostname="${TAILNET_HOSTNAME:-}"
    fi

    cat >&2 <<EOF

${CLR_GREEN}========================================================================${CLR_RESET}
${CLR_GREEN}FINAL CHECK — browser-required (cannot be curl'd)${CLR_RESET}
${CLR_GREEN}========================================================================${CLR_RESET}

From a Tailnet-connected device (your laptop), open:
    http://${tailnet_hostname:-<your-tailnet-hostname>}:3000/

In the chat, ask:
    how many records are in the warehouse?

The Answer Agent should reply with:
    - the SQL it ran (something like:
      SELECT COUNT(*) FROM main_gold.fct_smoke_test)
    - the row count (matching what 'check_duckdb_rows' just reported above)
    - a citation to main_gold.fct_smoke_test or a semantic-layer view

If you see all three, the box is fully wired and the trust contract is intact.
This is the sign-off moment: a real query, a real number, with full receipts.

If the chat returns an error or no SQL artifact, check:
    sudo journalctl -u oxy.service -n 100 --no-pager
    curl -sI http://localhost:3000

${CLR_GREEN}========================================================================${CLR_RESET}

EOF
}

main "$@"
