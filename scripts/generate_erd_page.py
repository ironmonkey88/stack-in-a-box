#!/usr/bin/env python3
"""Generate the static /erd page from live warehouse metadata.

Reads (read-only) information_schema.columns for the medallion schemas
(main_bronze, main_gold, main_admin) and emits one section per table listing
its columns and types. A lean text ERD — enough to orient a new analyst on the
shape of the warehouse without a diagramming dependency.

Output: `portal/erd.html`. run.sh deploys it to the docroot. Degrades to an
empty-state page if the warehouse has no tables yet.
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
OUT_PATH = REPO_ROOT / "portal" / "erd.html"
SCHEMAS = ["main_bronze", "main_gold", "main_admin"]


def load_tables(conn) -> dict[str, list[tuple]]:
    placeholders = ",".join("?" * len(SCHEMAS))
    try:
        rows = conn.execute(f"""
            SELECT table_schema, table_name, column_name, data_type
            FROM information_schema.columns
            WHERE table_schema IN ({placeholders})
              AND table_name NOT LIKE '\\_%' ESCAPE '\\'
            ORDER BY table_schema, table_name, ordinal_position
        """, SCHEMAS).fetchall()
    except Exception:
        return {}
    grouped: dict[str, list[tuple]] = {}
    for schema, table, col, dtype in rows:
        grouped.setdefault(f"{schema}.{table}", []).append((col, dtype))
    return grouped


def render(tables: dict[str, list[tuple]]) -> str:
    if tables:
        sections = []
        for qname, cols in tables.items():
            crows = "".join(
                f"<tr><td>{escape(c)}</td><td class='muted'>{escape(d)}</td></tr>"
                for c, d in cols
            )
            sections.append(
                f"<h2>{escape(qname)}</h2>"
                "<table><thead><tr><th>Column</th><th>Type</th></tr></thead>"
                f"<tbody>{crows}</tbody></table>"
            )
        body = (
            f"<p class='muted'>{len(tables)} tables across "
            f"{len(SCHEMAS)} schemas.</p>" + "".join(sections)
        )
    else:
        body = "<p class='muted'>No tables in the warehouse yet.</p>"

    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ERD</title>
<style>{NAV_CSS}</style></head>
<body>
{nav_html(active="erd")}
<header class="hero">
  <span class="hero-label">Warehouse ERD</span>
  <h1>The shape of the warehouse.</h1>
  <p>Every table in the medallion layers (bronze / gold / admin) with its
  columns and types. Read live from DuckDB metadata each run.</p>
  <p class="smoke">🚧 Smoke test — reflects the bundled NYC 311 dataset.</p>
</header>
<main>{body}</main>
</body></html>
"""


def main() -> int:
    tables = {}
    try:
        with duckdb.connect(DUCKDB_PATH, read_only=True) as conn:
            tables = load_tables(conn)
    except Exception as e:
        print(f"  warning: could not read warehouse: {e}", file=sys.stderr)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(render(tables), encoding="utf-8")
    print(f"  wrote {OUT_PATH} ({len(tables)} tables)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
