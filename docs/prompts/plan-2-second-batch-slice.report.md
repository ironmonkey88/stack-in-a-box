# Report — Plan 2: the second batch (contract-critical slice)

**Companion to:** [`plan-2-second-batch-slice.md`](plan-2-second-batch-slice.md)
**Session:** [2](../sessions/session-2-2026-05-28-plan-2-second-batch-slice.md)
**PR:** [#6](https://github.com/ironmonkey88/stack-in-a-box/pull/6)
**Date:** 2026-05-28
**Status:** complete (slice as scoped; B/C/D deferred per the prompt)

---

## Gate table

| Scope | Status | Where |
|---|---|---|
| G1 — requirements + dbt project/profiles + config | complete (static) | `355691b` |
| G2 — dlt NYC 311 pipeline + load_dbt_results + bronze/gold/admin models | complete (static) | `c69027b` |
| G3 — semantic views + topic + agent + schema.sql + limitations | complete (static) | `7cc46d7` |
| G4 — run helpers + profiling + health + portal generators | complete (static) | `0f8489b` |
| G5 — run.sh + nginx + systemd + first-boot portal | complete (static) | `2e68391` |
| G6 — housekeeping (CLAUDE §1, backlog §A, LOG, TASKS, session, report) | complete | this commit |
| F6 hard contract (backlog §A, C1-C5) | SATISFIED | read-cross-check vs 07/09/10 |
| LIVE-functional gates (dbt run, oxy validate, ./run.sh, agent smoke) | **deferred → Plan 3** | no EC2 this session |

## Shipped

**Data path (G2):** `dlt/smoke_test_pipeline.py` (NYC 311 SODA `erm2-nwe9`, SMOKE_MODE small/medium/large/custom, `$where`+`$limit`/`$offset` paging, retry/backoff, merge on `unique_key`, audit columns + post-merge `_first_seen_at`); `dlt/load_dbt_results.py`; bronze `raw_nyc_311.sql` + `bronze_raw` source; gold `fct_smoke_test` (request_sk=md5(unique_key), FK ids=md5(label)) + `dim_complaint_type` + `dim_borough`; admin `dim_data_quality_test` + `fct_test_run` (lean, dbt-tests-only). 3 `schema.yml` with data_tests.

**Trust-contract path (G3):** Airlayer `smoke_test`/`complaint_types`/`boroughs` views + `smoke_test` topic; `answer_agent.agent.yml` (`model: claude-opus-4-7`, `database: warehouse`, full 4-section trust contract); `docs/schema.sql` (bronze+gold+admin DDL context); 2 seed limitations (`bronze-varchar-source-cols`, `borough-unspecified-bucket`) + README + `build_limitations_index.py` (regenerated `_index.yaml`, 2 active).

**Observability + portal (G4):** `pipeline_run_start.py`/`pipeline_run_end.py` own `main_admin.fct_pipeline_run_raw`; `profile_tables.py` + `check_profile_staleness.py` own `fct_column_profile_raw`; `source_health_check.py` (NYC 311) → `fct_source_health_raw`; `_nav.py` + lean functional `generate_{metrics,trust,profile,erd}_page.py`.

**Orchestration + serving (G5):** `run.sh` (10-stage: dlt → dbt bronze/gold → captured tests → load results → dbt admin → captured admin tests → docs → 4 generated pages + index sync → limitations → profile staleness/regen, with ERR-trap run-end recording and max-of-test-exits); `nginx/stack-in-a-box.conf` (lean, docroot hardcoded); `oxy.service` + `pipeline-refresh`/`source-health-check`/`profile-tables` service+timer pairs; first-boot `portal/index.html`.

**Static verification:** `py_compile` (all `.py` in `scripts/` + `dlt/`); YAML parse (11 config/semantic/dbt files + the generated limitations index); `bash -n` + shellcheck 0.11 on `run.sh` (clean after quoting `$code` + annotating the trap fn); `generate_metrics_page.py` run locally → valid HTML with a `<table>` (4 measures × 3 views); token audit (only `{{PROJECT_ROOT}}` in units); `index.html` matches 07's gate regex.

## Worth flagging

- **(a) The one real batch-1↔batch-2 seam:** script 07 (frozen) creates the docroot `www-data:755`; `run.sh` runs as `ubuntu` and would fail a plain `cp` on first deploy. Resolved by making `deploy_html` (and the dbt-docs copy) fall back to `sudo` when the target dir isn't writable. This *assumes* default-EC2 passwordless sudo for `ubuntu` — true on the stock Ubuntu AMI, but it's a runtime assumption Plan 3 must confirm. If a hardened AMI strips that, the portal deploys (stages 6-9e) fail and run.sh records `failed`.
- **(b) External-schema best-effort, unvalidated:** the NYC 311 column list, the exact `config.yml`/agent schema, and the Airlayer view grammar are written from documented shape, not live inspection. dbt-duckdb materialization, `oxy validate`/`oxy start --local` readiness, and the live SODA response shape are all unexercised. The slice is *assembled and checked*, not *proven on metal* — this is the headline caveat, now reflected in CLAUDE.md §1.
- **(c) Deferred per scope (backlog B/C/D):** no `oxy validate` gate in run.sh yet (B1 — the one automated-coverage blind spot for config validity), no DuckDB-lock-aware run.sh / orphaned-run cleanup (B2), no `make rip-out-smoke-test` (B5), and none of the C-docs (HARDENING / SWAP_IN_YOUR_DATA / ARCHITECTURE / SETUP / TEARDOWN). These are real and tracked in `IMPROVEMENTS_BACKLOG.md`; a Plan 2 follow-on or Plan 3's hardening pass should pick them up.
- **(d) Lean generators:** the 4 portal generators are functional (valid HTML, a real `<table>`, graceful degradation when a table is absent) but visually minimal vs. the reference platform's. That was a deliberate slice choice — full-fidelity generators are polish, not contract.
- **(e) §1 caveat updated, not removed:** removing it would over-claim against a never-run install. It now reads "assembled and checked, not yet proven on metal" and is self-marked for replacement with a "validated on EC2" note when Plan 3 lands.

## Ready for more work — natural next moves

1. **Plan 3 — First real install** on a fresh t4g.medium. Run `bootstrap.sh` end-to-end; capture the first real failure, fix, iterate. Confirms (a) the sudo-deploy assumption, (b) every external-schema guess, and removes the §1 caveat. Captures the working Oxygen version (feeds Plan 4).
2. **Plan 2 follow-on (B/C/D)** — fold the oxy-validate gate + lock-aware run.sh + the doc batch into Plan 3's pass, or run as a standalone hardening plan.
3. **Plan 4 — Retroactive Oxygen version pin** per decision #4 + Plan 3 findings.
