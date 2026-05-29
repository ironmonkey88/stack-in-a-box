#!/usr/bin/env python3
"""Generate the static /metrics page from the Airlayer view YAML.

Walks `semantics/views/*.view.yml`, expands every `measures:` entry, and emits
an HTML table listing each measure with its view, type, filters, and the SQL it
expands to. Output: `portal/metrics.html`. run.sh deploys it to the docroot.

Pure-Python build tool — the YAML is authoritative for measure semantics, so we
do not call airlayer or DuckDB at runtime.
"""
from __future__ import annotations

import sys
from html import escape
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _nav import nav_html, NAV_CSS  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parent.parent
VIEWS_DIR = REPO_ROOT / "semantics" / "views"
OUT_PATH = REPO_ROOT / "portal" / "metrics.html"


def expand_measure_sql(view: dict, measure: dict) -> str:
    table = view.get("table", "<unknown_table>")
    mtype = measure.get("type", "count")
    expr = measure.get("expr")
    filters = measure.get("filters", []) or []
    where = " AND ".join(f["expr"] for f in filters if f.get("expr"))
    if mtype == "count":
        agg = "COUNT(*)"
    elif expr:
        agg = f"{mtype.upper()}({expr})"
    else:
        agg = f"{mtype.upper()}(*)"
    sql = f"SELECT {agg} AS {measure.get('name', 'value')} FROM {table}"
    if where:
        sql += f" WHERE {where}"
    return sql


def load_views() -> list[dict]:
    views = []
    for path in sorted(VIEWS_DIR.glob("*.view.yml")):
        with open(path) as fh:
            data = yaml.safe_load(fh)
        if data:
            views.append(data)
    return views


def render(views: list[dict]) -> str:
    rows = []
    measure_count = 0
    for v in views:
        vname = v.get("name", "?")
        for m in (v.get("measures") or []):
            measure_count += 1
            filters = m.get("filters", []) or []
            fdesc = "; ".join(f["expr"] for f in filters if f.get("expr")) or "—"
            rows.append(
                "<tr>"
                f"<td>{escape(m.get('name', ''))}</td>"
                f"<td class='muted'>{escape(vname)}</td>"
                f"<td>{escape(m.get('type', ''))}</td>"
                f"<td class='muted'>{escape(m.get('description', ''))}</td>"
                f"<td class='muted'>{escape(fdesc)}</td>"
                f"<td><code>{escape(expand_measure_sql(v, m))}</code></td>"
                "</tr>"
            )
    body = (
        "<table><thead><tr>"
        "<th>Measure</th><th>View</th><th>Type</th><th>Description</th>"
        "<th>Filters</th><th>Expands to</th>"
        "</tr></thead><tbody>" + "".join(rows) + "</tbody></table>"
    )
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Metrics catalog</title>
<style>{NAV_CSS}</style></head>
<body>
{nav_html(active="metrics")}
<header class="hero">
  <span class="hero-label">Metrics catalog</span>
  <h1>Every measure, expanded.</h1>
  <p>Auto-generated from the Airlayer view YAML. One row per measure, with its
  description, type, filters, and the SQL it expands to. Single source of truth
  for what each metric means.</p>
  <p class="smoke">🚧 Smoke test — these measures describe the bundled NYC 311
  dataset.</p>
  <div class="muted">{measure_count} measure(s) across {len(views)} view(s).</div>
</header>
<main>{body}</main>
</body></html>
"""


def main() -> int:
    views = load_views()
    html = render(views)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(html, encoding="utf-8")
    measure_count = sum(len(v.get("measures") or []) for v in views)
    print(f"  wrote {OUT_PATH} ({measure_count} measures across {len(views)} views)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
