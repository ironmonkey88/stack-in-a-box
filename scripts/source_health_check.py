"""Source-health check for the bundled smoke-test dataset (NYC 311 SODA).

🚧 SMOKE TEST. Checks freshness + reachability of the NYC 311 Socrata feed and
writes one row per invocation to main_admin.fct_source_health_raw. The hourly
systemd timer (source-health-check.timer) calls this. The /trust + /metrics
pages read the table.

Parameterized on a dataset config dict so adding your own sources later is a
matter of adding entries — the Socrata metadata API (`/api/views/{id}.json`
returning `rowsUpdatedAt`) is uniform across Socrata domains.

DUCKDB_PATH is derived from the repo root so the script is portable.

Usage:
    python scripts/source_health_check.py <dataset-slug>

Where <dataset-slug> defaults to and currently only supports: nyc-311
"""
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import duckdb
import requests
from ulid import ULID

REPO_ROOT = Path(__file__).resolve().parents[1]
DUCKDB_PATH = str(REPO_ROOT / "data" / "stack.duckdb")

# Per-dataset config: Socrata domain + 4x4 ID + staleness threshold (hours).
# NYC 311 refreshes continuously; allow 36h before flagging stale.
DATASETS = {
    "nyc-311": {
        "domain": "data.cityofnewyork.us",
        "id": "erm2-nwe9",
        "staleness_hours": 36,
    },
}

DDL = """
CREATE SCHEMA IF NOT EXISTS main_admin;
CREATE TABLE IF NOT EXISTS main_admin.fct_source_health_raw (
    check_id                   TEXT PRIMARY KEY,
    checked_at                 TIMESTAMP NOT NULL,
    source_endpoint            TEXT NOT NULL,
    source_rows_updated_at     TIMESTAMP,
    source_row_count           BIGINT,
    hours_since_source_update  INTEGER,
    check_status               TEXT NOT NULL,
    http_response_code         INTEGER,
    fetch_duration_ms          INTEGER,
    error_message              TEXT
);
"""


def check_dataset(slug: str) -> None:
    cfg = DATASETS.get(slug)
    if cfg is None:
        raise SystemExit(f"unknown dataset slug: {slug!r} (choose: {', '.join(DATASETS)})")
    domain = cfg["domain"]
    dataset_id = cfg["id"]
    staleness_hours = cfg["staleness_hours"]
    soda_data = f"https://{domain}/resource/{dataset_id}.json"
    soda_metadata = f"https://{domain}/api/views/{dataset_id}.json"

    check_id = str(ULID())
    checked_at = datetime.now(timezone.utc).replace(tzinfo=None)

    source_rows_updated_at = None
    source_row_count = None
    hours_since = None
    http_code = None
    fetch_ms = None
    check_status = "unreachable"
    error_message = None

    started = time.time()
    try:
        meta_resp = requests.get(soda_metadata, timeout=15)
        http_code = meta_resp.status_code
        fetch_ms = int((time.time() - started) * 1000)
        if meta_resp.status_code != 200:
            error_message = f"metadata HTTP {meta_resp.status_code}"
        else:
            m = meta_resp.json()
            rows_updated_at_epoch = m.get("rowsUpdatedAt")
            if rows_updated_at_epoch is not None:
                source_rows_updated_at = datetime.fromtimestamp(
                    rows_updated_at_epoch, tz=timezone.utc
                ).replace(tzinfo=None)
                hours_since = int(
                    (checked_at - source_rows_updated_at).total_seconds() / 3600
                )

            count_resp = requests.get(
                soda_data,
                params={"$select": "count(*) AS n"},
                timeout=15,
            )
            if count_resp.status_code == 200:
                data = count_resp.json()
                if data and "n" in data[0]:
                    source_row_count = int(data[0]["n"])

            if hours_since is not None and hours_since > staleness_hours:
                check_status = "stale"
            else:
                check_status = "ok"
    except requests.RequestException as e:
        fetch_ms = int((time.time() - started) * 1000)
        check_status = "unreachable"
        error_message = str(e)[:500]
    except Exception as e:
        fetch_ms = int((time.time() - started) * 1000)
        check_status = "unreachable"
        error_message = f"{type(e).__name__}: {str(e)[:500]}"

    with duckdb.connect(DUCKDB_PATH) as conn:
        conn.execute(DDL)
        conn.execute(
            """
            INSERT INTO main_admin.fct_source_health_raw VALUES (
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
            )
            """,
            (
                check_id, checked_at, soda_data,
                source_rows_updated_at, source_row_count,
                hours_since, check_status,
                http_code, fetch_ms, error_message,
            ),
        )

    sys.stderr.write(
        f"check {check_id} [{slug}] -> {check_status} "
        f"(http={http_code}, row_count={source_row_count}, "
        f"hours_since={hours_since})\n"
    )


def main() -> None:
    slug = sys.argv[1] if len(sys.argv) > 1 else "nyc-311"
    check_dataset(slug)


if __name__ == "__main__":
    main()
