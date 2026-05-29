# Limitations Registry

Known data and model limitations for this platform. Each limitation is one
Markdown file with YAML frontmatter for structured fields (consumed by the
Answer Agent and the `/trust` page) followed by free-form prose.

🚧 The entries shipped here describe the bundled NYC 311 **smoke test**. Delete
them when you connect your own data; keep the format and write your own.

## File format

```
docs/limitations/<slug>.md
```

Filename slug must match the `id` frontmatter field.

## Frontmatter schema

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | slug (kebab-case) | yes | Unique. Matches filename minus `.md`. |
| `title` | string | yes | Human-readable name. |
| `severity` | enum | yes | One of `info`, `warning`, `critical`. |
| `affects` | list of strings | yes | View / measure / dimension / table names (e.g. `smoke_test`, `smoke_test.borough`, `main_gold.fct_smoke_test`) or the literal `["all"]`. |
| `since` | YYYY-MM-DD | yes | Date the limitation became known. |
| `status` | enum | yes | `active` or `resolved`. Resolved entries stay in the registry as history. |

## Body

Free-form Markdown. Recommended structure:

- **What the limitation is** — concrete description
- **Impact** — what it breaks or biases for downstream consumers
- **Workaround** — query patterns or guardrails to apply
- **Resolution path** — if planned; otherwise state none

## Severity guide

- `info` — quirky but harmless if known; consumers should be aware
- `warning` — biases or distorts results in a specific direction; document workaround
- `critical` — answers from the agent are likely to be wrong without explicit handling

## Index

`scripts/build_limitations_index.py` regenerates `_index.yaml` from every
`*.md` frontmatter in this directory. `run.sh` runs it each pipeline pass. The
Answer Agent loads `_index.yaml` (not the individual files) as context.
