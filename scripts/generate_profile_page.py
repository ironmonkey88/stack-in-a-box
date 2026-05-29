#!/usr/bin/env python3
"""Generate the static /profile page from the column-profile snapshot.

Reads (read-only) the most recent snapshot in main_admin.fct_column_profile_raw
and emits a per-column table: row count, null %, distinct count, and type.
Output: `portal/profile.html`. run.sh deploys it to the docroot.

Degrades gracefully if the table is absent (renders an empty-state page).
"""
from __future__ import annotations

import sys
from html import escape
from pathlib import Path

import duckdb

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _nav import nav_html, NAV_CSS  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent.parent
DUCKDB_PATH = str(REPO_ROOT / "data" / "stack.duckdb")
OUT_PATH = REPO_ROOT / "portal" / "profile.html"


def load_profile(conn) -> list[tuple]:
    try:
        return conn.execute("""
            WITH latest AS (
                SELECT MAX(profiled_at) AS ts FROM main_admin.fct_column_profile_raw
            )
            SELECT schema_name, table_name, column_name, column_type,
                   row_count, null_pct, distinct_count
            FROM main_admin.fct_column_profile_raw, latest
            WHERE profiled_at = latest.ts
            ORDER BY schema_name, table_name, column_name
        """).fetchall()
    except Exception:
        return []


def _num(v) -> str:
    return f"{v:,}" if v is not None else "—"


def _pct(v) -> str:
    return f"{v:.1f}%" if v is not None else "—"


def _row(r: tuple) -> str:
    return (
        "<tr>"
        f"<td class='muted'>{escape(str(r[0]))}</td>"
        f"<td>{escape(str(r[1]))}</td>"
        f"<td>{escape(str(r[2]))}</td>"
        f"<td class='muted'>{escape(str(r[3]))}</td>"
        f"<td>{_num(r[4])}</td>"
        f"<td>{_pct(r[5])}</td>"
        f"<td>{_num(r[6])}</td>"
        "</tr>"
    )


def render(rows: list[tuple]) -> str:
    if rows:
        trows = "".join(_row(r) for r in rows)
        body = (
            f"<p class='muted'>{len(rows)} columns profiled.</p>"
            "<table><thead><tr><th>Schema</th><th>Table</th><th>Column</th>"
            "<th>Type</th><th>Rows</th><th>Null %</th><th>Distinct</th>"
            "</tr></thead><tbody>" + trows + "</tbody></table>"
        )
    else:
        body = "<p class='muted'>No column profiles recorded yet.</p>"

    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Profile</title>
<style>{NAV_CSS}</style></head>
<body>
{nav_html(active="profile")}
<header class="hero">
  <span class="hero-label">Column profile</span>
  <h1>What's actually in the data.</h1>
  <p>The most recent observational profile of every analyst-facing column —
  row count, null share, and distinct values. Observational only; profiling
  never fails a run.</p>
  <p class="smoke">🚧 Smoke test — reflects the bundled NYC 311 dataset.</p>
</header>
<main>{body}</main>
</body></html>
"""


def main() -> int:
    rows = []
    try:
        with duckdb.connect(DUCKDB_PATH, read_only=True) as conn:
            rows = load_profile(conn)
    except Exception as e:
        print(f"  warning: could not read warehouse: {e}", file=sys.stderr)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(render(rows), encoding="utf-8")
    print(f"  wrote {OUT_PATH} ({len(rows)} columns)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
