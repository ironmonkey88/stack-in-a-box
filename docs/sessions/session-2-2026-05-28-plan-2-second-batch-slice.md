---
session: 2
date: 2026-05-28
start_time: 21:00 EDT
end_time: 22:45 EDT
type: code
plan: plan-2
layers: [ingestion, bronze, gold, admin, semantic, agent, portal, infra, docs]
work: [feature, infra, docs]
status: complete
---

## Goal

Build Plan 2's contract-critical slice — the minimum application layer to get a real install past step 05 and through the smoke test, honoring the F6 hard contract from the v4 setup scripts. Static-verify only; the first real EC2 run is Plan 3.

## What shipped

- **G1 config templates** (`355691b`): `requirements.txt` (pinned dlt/dbt/duckdb/ulid), `dbt/dbt_project.yml` + `dbt/profiles.example.yml` (profile name hardcoded `stack_in_a_box`, only `{{DUCKDB_PATH}}` token), `config.example.yml` (Oxygen db hardcoded `warehouse`), `docs/prompts/plan-2-second-batch-slice.md`.
- **G2 data path** (`c69027b`): `dlt/smoke_test_pipeline.py` (NYC 311 SODA `erm2-nwe9`, SMOKE_MODE small/medium/large/custom, retry/backoff, merge on `unique_key`), `dlt/load_dbt_results.py`, bronze `raw_nyc_311.sql` + source def, gold `fct_smoke_test`/`dim_complaint_type`/`dim_borough`, admin `dim_data_quality_test`/`fct_test_run` (+ 3 `schema.yml`).
- **G3 trust-contract path** (`7cc46d7`): 3 Airlayer views (`smoke_test`/`complaint_types`/`boroughs`) + `smoke_test.topic.yml`, `agents/answer_agent.agent.yml` (`database: warehouse`, full trust contract), `docs/schema.sql`, 2 seed limitations + README + `scripts/build_limitations_index.py` (regenerated `_index.yaml`).
- **G4 observability + portal generators** (`0f8489b`): `pipeline_run_start.py`/`pipeline_run_end.py` (own `main_admin.fct_pipeline_run_raw`), `profile_tables.py` + `check_profile_staleness.py`, `source_health_check.py` (NYC 311), `_nav.py` + 4 generators (`generate_{metrics,trust,profile,erd}_page.py`).
- **G5 orchestration + serving** (`2e68391`): `run.sh` (10-stage, sudo-aware `deploy_html`), `nginx/stack-in-a-box.conf` (lean, docroot hardcoded), 7 systemd units (`oxy.service` + 3 timer/service pairs), first-boot `portal/index.html`.
- **G6 docs**: CLAUDE.md §1 caveat updated to "assembled, not yet proven on metal"; backlog §A marked SATISFIED + B/C/D noted open; LOG.md + TASKS.md + this session file + report.
- All DUCKDB_PATH derivations repo-root-relative (`Path(__file__).resolve().parents[1]/data/stack.duckdb`) — portable across install dirs.

## Decisions

- dbt profile name + Oxygen db name hardcoded (`stack_in_a_box` / `warehouse`) instead of tokenized — a hyphenated `{{PROJECT_NAME}}` can't be a dbt profile name; a fixed Oxygen db name keeps the agent's `database: warehouse` stable. Stays inside the C3 token whitelist.
- `/docs` served from a docroot subdirectory (run.sh deploys dbt/target there) rather than an nginx `alias` — script 07 copies the conf verbatim, so an alias would couple it to the install dir.
- `deploy_html` made sudo-aware — script 07 creates the docroot `www-data:755` (not ubuntu-writable) but run.sh runs as ubuntu; deploys route through sudo when the docroot isn't writable.

## Issues encountered

- **Batch-1 ↔ batch-2 docroot-ownership seam.** Script 07 (frozen) chowns the docroot `www-data:755`; `run.sh` (new) writes to it as `ubuntu` → plain `cp` would fail on first deploy. Fixed by making `deploy_html` (and the stage-6 dbt-docs copy) fall back to `sudo` when the target dir isn't writable. Default EC2 `ubuntu` has passwordless sudo, so this resolves at runtime — but it's a genuine integration assumption flagged for Plan 3 to confirm.
- **profile table name drift.** Initial `docs/schema.sql` called the profile table `fct_data_profile`; the real `profile_tables.py` (ported from the reference impl) uses `fct_column_profile_raw`. Reconciled schema.sql to the script's name.
- **Inline-ternary string-concat hazard** in `generate_profile_page.py` (f-strings with `if/else` inside an implicit-concatenation join would misparse). Rewrote with explicit `_num`/`_pct`/`_row` helpers.

## Next action

Plan 3 — run `bootstrap.sh` end-to-end on a fresh t4g.medium EC2. The slice is statically verified but never executed; Plan 3 is the first real run (live SODA API, dbt-duckdb materialization, `oxy start --local` readiness, docroot write perms) and the point at which the §1 caveat is fully removed.
