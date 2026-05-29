"""Smoke-test ingestion pipeline — NYC 311 service requests (SODA `erm2-nwe9`).

🚧 SMOKE TEST — delete this file when you connect your own data. See
`make rip-out-smoke-test` (lands with the second-batch doc work) and
docs/design/OPEN_DECISIONS.md #2/#3. This pulls a real public dataset so
the install can prove the dlt → DuckDB → dbt → agent chain end-to-end.

Full-pull + merge on the source primary key `unique_key`. SMOKE_MODE
(env var, default `medium`) shapes the pull:
  small   — 10k rows                         (~2-3 min)
  medium  — last 90 days                      (~250k rows, default)
  large   — last 365 days                     (~1M rows)
  custom  — SMOKE_QUERY env var as a raw SODA $where clause

Tables produced in `main_bronze`:
  - raw_nyc_311_raw (dlt-owned, merge target)
  - dlt metadata tables

Audit columns injected per row: _extracted_at, _extracted_run_id,
_source_endpoint. `_first_seen_at` is maintained by a post-merge UPDATE.

Usage:
    python dlt/smoke_test_pipeline.py [RUN_ID]
RUN_ID is supplied by scripts/pipeline_run_start.py via run.sh; a fresh
ULID is generated for ad-hoc invocation.
"""
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Iterator

import dlt
import duckdb
import requests
from ulid import ULID

SODA_BASE = "https://data.cityofnewyork.us/resource/erm2-nwe9.json"
PAGE_SIZE = 50_000
REPO_ROOT = Path(__file__).resolve().parent.parent
DUCKDB_PATH = str(REPO_ROOT / "data" / "stack.duckdb")
SOURCE_ENDPOINT = SODA_BASE

# A documented core subset of the NYC 311 schema. Best-effort column list —
# the first real run (Plan 3) validates these against the live API; dlt
# tolerates absent columns gracefully.
COLUMNS = ",".join([
    "unique_key", "created_date", "closed_date",
    "agency", "agency_name", "complaint_type", "descriptor",
    "status", "borough", "incident_zip", "community_board",
    "latitude", "longitude",
])


def _where_clause() -> str | None:
    """Build the SODA $where for the selected SMOKE_MODE."""
    mode = os.environ.get("SMOKE_MODE", "medium")
    if mode == "custom":
        return os.environ.get("SMOKE_QUERY") or None
    if mode == "small":
        return None  # bounded by $limit in fetch_all instead
    days = 365 if mode == "large" else 90  # medium default
    since = (datetime.now(timezone.utc) - timedelta(days=days)).strftime("%Y-%m-%dT00:00:00")
    return f"created_date > '{since}'"


def _max_rows() -> int | None:
    return 10_000 if os.environ.get("SMOKE_MODE", "medium") == "small" else None


def fetch_all() -> Iterator[dict]:
    """Paginate through NYC 311 via SODA $limit + $offset, with retry/backoff."""
    where = _where_clause()
    cap = _max_rows()
    offset = 0
    fetched = 0
    while True:
        params = {
            "$select": COLUMNS,
            "$limit": PAGE_SIZE,
            "$offset": offset,
            "$order": "unique_key ASC",
        }
        if where:
            params["$where"] = where

        batch = _get_with_retry(params)
        if not batch:
            break
        print(f"  offset={offset}: fetched {len(batch)} rows", flush=True)
        for row in batch:
            yield row
            fetched += 1
            if cap and fetched >= cap:
                return
        if len(batch) < PAGE_SIZE:
            break
        offset += PAGE_SIZE


def _get_with_retry(params: dict, attempts: int = 4) -> list:
    """GET one SODA page; retry with backoff on 429/5xx/transient errors."""
    delay = 2
    for attempt in range(1, attempts + 1):
        try:
            resp = requests.get(SODA_BASE, params=params, timeout=90)
            if resp.status_code in (429, 500, 502, 503, 504):
                raise requests.HTTPError(f"HTTP {resp.status_code}")
            resp.raise_for_status()
            return resp.json()
        except (requests.RequestException, ValueError) as e:
            if attempt == attempts:
                raise
            print(f"  retry {attempt}/{attempts} after error: {e} (sleep {delay}s)", flush=True)
            import time
            time.sleep(delay)
            delay *= 2
    return []


def add_audit_columns(rows: Iterator[dict], run_id: str, extracted_at: datetime) -> Iterator[dict]:
    for row in rows:
        row["_extracted_at"] = extracted_at
        row["_extracted_run_id"] = run_id
        row["_source_endpoint"] = SOURCE_ENDPOINT
        yield row


def post_merge_first_seen(extracted_at: datetime) -> None:
    """Maintain _first_seen_at outside the dlt payload (set on INSERT, preserved on UPDATE)."""
    with duckdb.connect(DUCKDB_PATH) as conn:
        conn.execute(
            "ALTER TABLE main_bronze.raw_nyc_311_raw ADD COLUMN IF NOT EXISTS _first_seen_at TIMESTAMP"
        )
        conn.execute(
            "UPDATE main_bronze.raw_nyc_311_raw SET _first_seen_at = _extracted_at WHERE _first_seen_at IS NULL"
        )


def main() -> None:
    run_id = sys.argv[1] if len(sys.argv) > 1 else str(ULID())
    extracted_at = datetime.now(timezone.utc).replace(tzinfo=None)
    mode = os.environ.get("SMOKE_MODE", "medium")
    print(f"\n=== nyc_311 smoke pipeline run {run_id} (mode={mode}) ===")
    print(f"  destination: duckdb @ {DUCKDB_PATH}")

    @dlt.resource(name="raw_nyc_311_raw", primary_key="unique_key", write_disposition="merge")
    def _resource():
        yield from add_audit_columns(fetch_all(), run_id, extracted_at)

    pipeline = dlt.pipeline(
        pipeline_name="nyc_311_smoke",
        destination=dlt.destinations.duckdb(DUCKDB_PATH),
        dataset_name="main_bronze",
    )
    info = pipeline.run(_resource())
    print(f"\nload info: {info}")

    post_merge_first_seen(extracted_at)
    print("post-merge _first_seen_at: done")


if __name__ == "__main__":
    main()
