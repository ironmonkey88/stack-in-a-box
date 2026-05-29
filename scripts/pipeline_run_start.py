"""Record pipeline run start in main_admin.fct_pipeline_run_raw.

Prints the new run_id to stdout so the caller (run.sh) can capture it and
pass it to the dlt pipeline and the end-of-run recorder.

This script OWNS its target table — it creates main_admin.fct_pipeline_run_raw
on first invocation. The admin schema and table are managed by Python here,
not by dbt, so a `dbt run --select admin` cannot clobber run history. This is
the F6 contract table the install's verify gates assert is populated.

DUCKDB_PATH is derived from the repo root (parents[1]/data/stack.duckdb) so the
script is portable across install directories — no hardcoded absolute path.

Usage:
    RUN_ID=$(python scripts/pipeline_run_start.py --run-type=daily)
"""
import argparse
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import duckdb
from ulid import ULID

REPO_ROOT = Path(__file__).resolve().parents[1]
DUCKDB_PATH = str(REPO_ROOT / "data" / "stack.duckdb")

DDL = """
CREATE SCHEMA IF NOT EXISTS main_admin;
CREATE TABLE IF NOT EXISTS main_admin.fct_pipeline_run_raw (
    run_id                     TEXT PRIMARY KEY,
    run_started_at             TIMESTAMP NOT NULL,
    run_completed_at           TIMESTAMP,
    run_duration_seconds       INTEGER,
    run_type                   TEXT NOT NULL,
    run_status                 TEXT NOT NULL,

    source_rows_updated_at     TIMESTAMP,
    source_row_count           BIGINT,
    source_freshness_lag_sec   INTEGER,

    records_fetched            BIGINT,
    records_new                BIGINT,
    records_updated            BIGINT,

    bronze_status              TEXT,
    bronze_test_count          INTEGER,
    bronze_test_failures       INTEGER,
    gold_status                TEXT,
    gold_test_count            INTEGER,
    gold_test_failures         INTEGER,
    admin_status               TEXT,
    admin_test_count           INTEGER,
    admin_test_failures        INTEGER,

    error_stage                TEXT,
    error_message              TEXT,

    pipeline_version           TEXT,
    host                       TEXT
);
"""


def _git_short() -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(REPO_ROOT), "rev-parse", "--short", "HEAD"],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
    except Exception:
        return "unknown"


def _hostname() -> str:
    try:
        return subprocess.check_output(["hostname"]).decode().strip()
    except Exception:
        return "unknown"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--run-type", default="manual",
        choices=["daily", "manual", "backfill"],
    )
    args = parser.parse_args()

    run_id = str(ULID())
    started_at = datetime.now(timezone.utc).replace(tzinfo=None)

    with duckdb.connect(DUCKDB_PATH) as conn:
        conn.execute(DDL)
        conn.execute(
            """
            INSERT INTO main_admin.fct_pipeline_run_raw (
                run_id, run_started_at, run_type, run_status,
                pipeline_version, host
            ) VALUES (?, ?, ?, 'in_progress', ?, ?)
            """,
            (run_id, started_at, args.run_type, _git_short(), _hostname()),
        )

    sys.stdout.write(run_id + "\n")
    sys.stderr.write(
        f"started run {run_id} ({args.run_type}) at {started_at.isoformat()}Z\n"
    )


if __name__ == "__main__":
    main()
