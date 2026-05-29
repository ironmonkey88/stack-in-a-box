#!/usr/bin/env python3
"""Generate the static /trust page from the admin observability tables.

Reads (read-only) main_admin.fct_pipeline_run_raw (latest run),
main_admin.fct_test_run + dim_data_quality_test (latest test outcomes), and
the limitations registry (docs/limitations/_index.yaml). Emits an HTML page
with the run status, a per-test pass/warn/fail table, and the known
limitations. Output: `portal/trust.html`. run.sh deploys it to the docroot.

Every section degrades gracefully: a missing table renders an empty section
rather than crashing, so the page generates even on a partial first boot.
"""
from __future__ import annotations

import sys
from html import escape
from pathlib import Path

import duckdb
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _nav import nav_html, NAV_CSS  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent.parent
DUCKDB_PATH = str(REPO_ROOT / "data" / "stack.duckdb")
LIMITATIONS_INDEX = REPO_ROOT / "docs" / "limitations" / "_index.yaml"
OUT_PATH = REPO_ROOT / "portal" / "trust.html"


def _pill(status: str) -> str:
    s = (status or "").lower()
    cls = "ok" if s in ("pass", "success", "ok") else "warn" if s == "warn" else "fail"
    return f'<span class="pill {cls}">{escape(status or "?")}</span>'


def latest_run(conn) -> dict | None:
    try:
        row = conn.execute("""
            SELECT run_id, run_type, run_status, run_started_at,
                   run_completed_at, run_duration_seconds
            FROM main_admin.fct_pipeline_run_raw
            ORDER BY run_started_at DESC LIMIT 1
        """).fetchone()
    except Exception:
        return None
    if not row:
        return None
    return {
        "run_id": row[0], "run_type": row[1], "run_status": row[2],
        "started_at": row[3], "completed_at": row[4], "duration": row[5],
    }


def latest_tests(conn) -> list[tuple]:
    try:
        return conn.execute("""
            WITH latest AS (
                SELECT run_id FROM main_admin.fct_test_run
                ORDER BY run_at DESC LIMIT 1
            )
            SELECT t.test_id, t.status, t.actual_value, t.failure_message
            FROM main_admin.fct_test_run t
            INNER JOIN latest l ON t.run_id = l.run_id
            ORDER BY (t.status = 'fail') DESC, (t.status = 'warn') DESC, t.test_id
        """).fetchall()
    except Exception:
        return []


def load_limitations() -> list[dict]:
    if not LIMITATIONS_INDEX.exists():
        return []
    try:
        with open(LIMITATIONS_INDEX) as fh:
            data = yaml.safe_load(fh)
        return data or []
    except Exception:
        return []


def render(run: dict | None, tests: list[tuple], lims: list[dict]) -> str:
    if run:
        run_html = (
            f"<p>Latest run <code>{escape(str(run['run_id']))}</code> "
            f"({escape(str(run['run_type']))}) — {_pill(run['run_status'])} "
            f"<span class='muted'>started {escape(str(run['started_at']))}, "
            f"{escape(str(run['duration']))}s</span></p>"
        )
    else:
        run_html = "<p class='muted'>No pipeline runs recorded yet.</p>"

    if tests:
        trows = "".join(
            "<tr>"
            f"<td>{escape(str(t[0]))}</td>"
            f"<td>{_pill(str(t[1]))}</td>"
            f"<td class='muted'>{escape(str(t[2]) if t[2] is not None else '')}</td>"
            f"<td class='muted'>{escape(str(t[3]) if t[3] is not None else '')}</td>"
            "</tr>"
            for t in tests
        )
        passed = sum(1 for t in tests if str(t[1]).lower() == "pass")
        tests_html = (
            f"<p class='muted'>{passed}/{len(tests)} tests passing.</p>"
            "<table><thead><tr><th>Test</th><th>Status</th>"
            "<th>Actual</th><th>Message</th></tr></thead><tbody>"
            + trows + "</tbody></table>"
        )
    else:
        tests_html = "<p class='muted'>No test results recorded yet.</p>"

    if lims:
        lrows = "".join(
            "<tr>"
            f"<td>{escape(str(l.get('id', '')))}</td>"
            f"<td>{_pill(str(l.get('severity', '')))}</td>"
            f"<td>{escape(str(l.get('title', '')))}</td>"
            f"<td class='muted'>{escape(str(l.get('path', '')))}</td>"
            "</tr>"
            for l in lims
        )
        lims_html = (
            "<table><thead><tr><th>ID</th><th>Severity</th>"
            "<th>Title</th><th>Detail</th></tr></thead><tbody>"
            + lrows + "</tbody></table>"
        )
    else:
        lims_html = "<p class='muted'>No active limitations recorded.</p>"

    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Trust</title>
<style>{NAV_CSS}</style></head>
<body>
{nav_html(active="trust")}
<header class="hero">
  <span class="hero-label">Trust</span>
  <h1>Can you trust this data?</h1>
  <p>The latest pipeline run, every data-quality test and its result, and the
  known limitations of the data. Auto-generated each run from the admin
  observability tables.</p>
  <p class="smoke">🚧 Smoke test — reflects the bundled NYC 311 dataset.</p>
</header>
<main>
  <h2>Latest run</h2>
  {run_html}
  <h2>Data-quality tests</h2>
  {tests_html}
  <h2>Known limitations</h2>
  {lims_html}
</main>
</body></html>
"""


def main() -> int:
    run, tests = None, []
    try:
        with duckdb.connect(DUCKDB_PATH, read_only=True) as conn:
            run = latest_run(conn)
            tests = latest_tests(conn)
    except Exception as e:
        print(f"  warning: could not read warehouse: {e}", file=sys.stderr)
    lims = load_limitations()

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(render(run, tests, lims), encoding="utf-8")
    print(f"  wrote {OUT_PATH} ({len(tests)} tests, {len(lims)} limitations)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
