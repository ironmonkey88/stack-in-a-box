"""Shared portal navigation for the generated pages.

Single source of truth for the nav bar + base CSS tokens used by every
generate_*_page.py. Keeps the generated pages visually consistent without a
build framework. Lean by design — extend the styling for your real platform.
"""
from __future__ import annotations

from html import escape

# (href, label, key) — `key` matches the `active` argument to nav_html().
NAV_ITEMS = [
    ("/", "Home", "home"),
    ("/metrics", "Metrics", "metrics"),
    ("/trust", "Trust", "trust"),
    ("/profile", "Profile", "profile"),
    ("/erd", "ERD", "erd"),
    ("/docs/", "dbt Docs", "docs"),
]

NAV_CSS = """
:root {
  --bg: #0f1115;
  --panel: #171a21;
  --text: #e6e8ec;
  --muted: #9aa3b2;
  --accent: #5b9dff;
  --border: #262b35;
  --ok: #3ec78c;
  --warn: #f3c969;
  --fail: #ff6b6b;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text); line-height: 1.5; }
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
nav.topnav {
  display: flex; gap: 4px; flex-wrap: wrap;
  padding: 12px 20px; background: var(--panel);
  border-bottom: 1px solid var(--border);
}
nav.topnav a {
  padding: 6px 12px; border-radius: 6px; color: var(--muted); font-size: 14px;
}
nav.topnav a.active { background: var(--accent); color: #fff; }
main { max-width: 1100px; margin: 0 auto; padding: 24px 20px 64px; }
header.hero { max-width: 1100px; margin: 0 auto; padding: 28px 20px 8px; }
header.hero h1 { margin: 6px 0; font-size: 28px; }
header.hero .hero-label {
  text-transform: uppercase; letter-spacing: .08em; font-size: 12px;
  color: var(--accent);
}
header.hero p { color: var(--muted); max-width: 760px; }
table { border-collapse: collapse; width: 100%; margin: 12px 0 28px; font-size: 14px; }
th, td { text-align: left; padding: 8px 12px; border-bottom: 1px solid var(--border); }
th { color: var(--muted); font-weight: 600; }
tr:hover td { background: rgba(255,255,255,0.02); }
.pill { padding: 2px 8px; border-radius: 999px; font-size: 12px; font-weight: 600; }
.pill.ok { background: rgba(62,199,140,.15); color: var(--ok); }
.pill.warn { background: rgba(243,201,105,.15); color: var(--warn); }
.pill.fail { background: rgba(255,107,107,.15); color: var(--fail); }
.muted { color: var(--muted); }
.smoke { color: var(--warn); font-size: 13px; }
"""


def nav_html(active: str = "") -> str:
    links = []
    for href, label, key in NAV_ITEMS:
        cls = ' class="active"' if key == active else ""
        links.append(f'<a href="{escape(href)}"{cls}>{escape(label)}</a>')
    return '<nav class="topnav">' + "".join(links) + "</nav>"
