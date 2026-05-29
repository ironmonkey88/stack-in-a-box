#!/usr/bin/env bash
# run.sh — single entry point for the stack-in-a-box pipeline.
#
# 🚧 SMOKE TEST — ingests the bundled NYC 311 dataset, builds the medallion
# warehouse, runs tests, and regenerates the portal. When you connect your own
# data, replace the dlt ingest (stage 1) and the dbt models; the orchestration
# shape below is what you keep.
#
# Run types (first positional arg, default 'manual'):
#   daily    — invoked by systemd pipeline-refresh.service
#   manual   — invoked by a human
#   backfill — special historical reload
#
# Order:
#   0.  record run start  — main_admin.fct_pipeline_run_raw, returns run_id
#   1.  dlt ingest        — NYC 311 SODA → raw_nyc_311_raw (merge on unique_key)
#   2.  dbt run bronze gold
#   3.  dbt test bronze gold (capture exit; do NOT halt)
#   4.  dlt load_dbt_results — append run_results.json → raw_dbt_results_raw
#   5.  dbt run admin     — dim_data_quality_test, fct_test_run
#   5b. dbt test admin    (capture exit; do NOT halt)
#   6.  dbt docs generate — keep /docs current
#   7.  /metrics page     — regenerate from semantics/views/*.view.yml
#   8.  /trust page       — regenerate from main_admin.fct_test_run
#   8b. sync portal/index.html
#   9.  limitations index — regenerate docs/limitations/_index.yaml
#   9b. profile staleness check  → 9c regen if stale
#   9d. /profile page
#   9e. /erd page
#   10. record run end    — UPDATE fct_pipeline_run_raw with status + outcomes
#
# Exit code: max(bronze/gold-test exit, admin-test exit). Tests can fail
# without losing admin tables or the trust page.

set -euo pipefail

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$REPO_ROOT"

# Portal docroot. Hardcoded by contract — nginx/stack-in-a-box.conf serves
# from here. scripts/setup/07 creates it ubuntu-owned.
DOCROOT="/var/www/stack-in-a-box"

# Activate venv (dbt, dlt, duckdb live here)
# shellcheck disable=SC1091
source "$REPO_ROOT/.venv/bin/activate"

# Portal deploy helper: refuse to deploy a file the generator didn't produce
# (no silent stale page) and write atomically (cp to .tmp then mv) so nginx
# never serves a half-written file. scripts/setup/07 creates the docroot
# www-data:755 (not ubuntu-writable), so when the docroot isn't writable by us
# we go through sudo — the default EC2 `ubuntu` user has passwordless sudo.
deploy_html() {
    local src="$1"
    local dst="$2"
    local dstdir
    dstdir="$(dirname "$dst")"
    if [ ! -f "$src" ]; then
        echo "ERROR: source file $src was not generated; refusing to deploy" >&2
        return 1
    fi
    if [ -w "$dstdir" ]; then
        cp "$src" "${dst}.tmp"
        mv "${dst}.tmp" "$dst"
    else
        sudo cp "$src" "${dst}.tmp"
        sudo mv "${dst}.tmp" "$dst"
    fi
}

RUN_TYPE="${1:-manual}"

# Step 0: record run start, capture run_id
RUN_ID=$(python scripts/pipeline_run_start.py --run-type="$RUN_TYPE")
echo "==> 0/10 pipeline run started: $RUN_ID ($RUN_TYPE)"

# Stage state — written into the run record on exit
BRONZE_STATUS="not_run"
GOLD_STATUS="not_run"
ADMIN_STATUS="not_run"
DBT_TEST_EXIT=0
DBT_ADMIN_TEST_EXIT=0
ERROR_STAGE="setup"

# shellcheck disable=SC2329  # invoked indirectly via the ERR trap below
on_error() {
    local code=$?
    set +e
    python scripts/pipeline_run_end.py \
        --run-id="$RUN_ID" \
        --status=failed \
        --error-stage="$ERROR_STAGE" \
        --error-message="run.sh halted at stage $ERROR_STAGE with exit $code" \
        --bronze-status="$BRONZE_STATUS" \
        --gold-status="$GOLD_STATUS" \
        --admin-status="$ADMIN_STATUS"
    exit "$code"
}
trap on_error ERR

# Step 1: dlt ingest NYC 311 (full pull + merge on unique_key)
ERROR_STAGE="dlt_ingest_nyc_311"
echo "==> 1/10 dlt ingest nyc 311 (SMOKE_MODE=${SMOKE_MODE:-medium})"
python dlt/smoke_test_pipeline.py "$RUN_ID"

# Step 2: dbt run bronze + gold
ERROR_STAGE="dbt_run_bronze_gold"
echo "==> 2/10 dbt run --select bronze gold"
( cd dbt && dbt run --select bronze gold )
BRONZE_STATUS="success"
GOLD_STATUS="success"

# Step 3: dbt test bronze + gold (captured-exit; do not halt)
# `cmd || rc=$?` is exempt from errexit; avoids tripping the ERR trap.
ERROR_STAGE="dbt_test_bronze_gold"
echo "==> 3/10 dbt test --select bronze gold (captured)"
DBT_TEST_EXIT=0
( cd dbt && dbt test --select bronze gold ) || DBT_TEST_EXIT=$?
echo "    dbt test exit code: $DBT_TEST_EXIT"

# Step 4: load dbt run_results into raw_dbt_results_raw
ERROR_STAGE="load_dbt_results"
echo "==> 4/10 load dbt results"
python dlt/load_dbt_results.py

# Step 5: dbt run admin
ERROR_STAGE="dbt_run_admin"
echo "==> 5/10 dbt run --select admin"
( cd dbt && dbt run --select admin )
ADMIN_STATUS="success"

# Step 5b: dbt test admin (captured-exit)
ERROR_STAGE="dbt_test_admin"
echo "==> 5b/10 dbt test --select admin (captured)"
DBT_ADMIN_TEST_EXIT=0
( cd dbt && dbt test --select admin ) || DBT_ADMIN_TEST_EXIT=$?
echo "    dbt admin-test exit code: $DBT_ADMIN_TEST_EXIT"

# Step 6: dbt docs generate (serves /docs). Deploy the generated site into a
# subdirectory of the docroot so nginx serves it from /docs/ without an
# install-dir-dependent alias.
ERROR_STAGE="dbt_docs"
echo "==> 6/10 dbt docs generate"
( cd dbt && dbt docs generate )
if [ -d "$DOCROOT" ] && [ -f dbt/target/index.html ]; then
    if [ -w "$DOCROOT" ]; then
        mkdir -p "$DOCROOT/docs"
        cp dbt/target/index.html dbt/target/manifest.json dbt/target/catalog.json "$DOCROOT/docs/" 2>/dev/null || true
    else
        sudo mkdir -p "$DOCROOT/docs"
        sudo cp dbt/target/index.html dbt/target/manifest.json dbt/target/catalog.json "$DOCROOT/docs/" 2>/dev/null || true
    fi
    echo "    deployed dbt docs to $DOCROOT/docs/"
fi

# Step 7: /metrics page
ERROR_STAGE="metrics_page"
echo "==> 7/10 generate /metrics page"
python scripts/generate_metrics_page.py
if [ -d "$DOCROOT" ]; then
    deploy_html portal/metrics.html "$DOCROOT/metrics.html"
    echo "    deployed to $DOCROOT/metrics.html"
fi

# Step 8: /trust page
ERROR_STAGE="trust_page"
echo "==> 8/10 generate /trust page"
python scripts/generate_trust_page.py
if [ -d "$DOCROOT" ] && [ -f portal/trust.html ]; then
    deploy_html portal/trust.html "$DOCROOT/trust.html"
    echo "    deployed to $DOCROOT/trust.html"
fi

# Step 8b: sync the static portal index (nav changes land without a manual scp)
ERROR_STAGE="index_sync"
if [ -d "$DOCROOT" ] && [ -f portal/index.html ]; then
    deploy_html portal/index.html "$DOCROOT/index.html"
    echo "==> 8b/10 synced portal/index.html -> $DOCROOT/index.html"
fi

# Step 9: build limitations index
ERROR_STAGE="limitations_index"
echo "==> 9/10 build limitations index"
python3 scripts/build_limitations_index.py

# Step 9b: profile staleness check → 9c regen if stale
ERROR_STAGE="profile_staleness"
echo "==> 9b/10 profile staleness check"
PROFILE_STALE=0
python scripts/check_profile_staleness.py || PROFILE_STALE=1

if [ "$PROFILE_STALE" -eq 1 ]; then
    ERROR_STAGE="profile_regen"
    echo "==> 9c/10 profile stale — regenerating"
    python scripts/profile_tables.py --run-id="$RUN_ID"
fi

# Step 9d: /profile page
ERROR_STAGE="profile_page"
echo "==> 9d/10 regenerate /profile page"
python scripts/generate_profile_page.py
if [ -d "$DOCROOT" ] && [ -f portal/profile.html ]; then
    deploy_html portal/profile.html "$DOCROOT/profile.html"
fi

# Step 9e: /erd page
ERROR_STAGE="erd_page"
echo "==> 9e/10 regenerate /erd page"
python scripts/generate_erd_page.py
if [ -d "$DOCROOT" ] && [ -f portal/erd.html ]; then
    deploy_html portal/erd.html "$DOCROOT/erd.html"
fi

# Step 10: record run end (success or partial depending on test exits)
ERROR_STAGE="run_end"
if [ "$DBT_TEST_EXIT" -ne 0 ] || [ "$DBT_ADMIN_TEST_EXIT" -ne 0 ]; then
    FINAL_STATUS="partial"
else
    FINAL_STATUS="success"
fi
echo "==> 10/10 record run end ($FINAL_STATUS)"
python scripts/pipeline_run_end.py \
    --run-id="$RUN_ID" \
    --status="$FINAL_STATUS" \
    --bronze-status="$BRONZE_STATUS" \
    --gold-status="$GOLD_STATUS" \
    --admin-status="$ADMIN_STATUS"

# Final exit code = larger of the two captured test exits
FINAL_EXIT=$DBT_TEST_EXIT
if [ "$DBT_ADMIN_TEST_EXIT" -gt "$FINAL_EXIT" ]; then FINAL_EXIT=$DBT_ADMIN_TEST_EXIT; fi

echo
echo "===== run complete ====="
echo "    run_id:                           $RUN_ID"
echo "    run_type:                         $RUN_TYPE"
echo "    dbt test exit code (bronze/gold): $DBT_TEST_EXIT"
echo "    dbt test exit code (admin):       $DBT_ADMIN_TEST_EXIT"
echo "    run_status:                       $FINAL_STATUS"
echo "    final exit code:                  $FINAL_EXIT"
exit $FINAL_EXIT
