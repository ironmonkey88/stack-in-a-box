# Stack-in-a-Box — Handoff: Plan 2 (second batch, contract-critical slice)

**Date:** 2026-05-28
**Origin:** Code session (continued from the Plan 1 thread)
**Status:** Application layer **built and statically verified**, merged to `main` (PR [#6](https://github.com/ironmonkey88/stack-in-a-box/pull/6), `de56048`). **Never executed on EC2** — the first real run is Plan 3.

This handoff supersedes the "awaiting the second batch" status of [`2026-05-26-stack-in-a-box-v4-handoff.md`](2026-05-26-stack-in-a-box-v4-handoff.md). The empty slots that handoff named (one dlt pipeline, dbt models, semantic YAML, agent prompt, dataset copy) are now filled.

---

## 1. What landed

The 16 core artifacts from design-plan §9, in five commit groups:

| Group | Contents | Commit |
|---|---|---|
| G1 | `requirements.txt` (pinned dlt/dbt/duckdb/ulid) + `dbt/dbt_project.yml` + `dbt/profiles.example.yml` + `config.example.yml` | `355691b` |
| G2 | `dlt/smoke_test_pipeline.py` (NYC 311) + `dlt/load_dbt_results.py` + bronze/gold/admin dbt models | `c69027b` |
| G3 | 3 Airlayer views + topic + `answer_agent.agent.yml` + `docs/schema.sql` + limitations registry + index generator | `7cc46d7` |
| G4 | `pipeline_run_start`/`_end`, `profile_tables`, `check_profile_staleness`, `source_health_check`, `_nav` + 4 page generators | `0f8489b` |
| G5 | `run.sh` (10-stage) + `nginx/stack-in-a-box.conf` + 7 systemd units + first-boot `portal/index.html` | `2e68391` |
| G6 | Docs housekeeping (CLAUDE §1, backlog §A, LOG, TASKS, session, report) | `eacb23c`+`3302e82` |

**Smoke dataset:** NYC 311 (SODA `erm2-nwe9`), SMOKE_MODE small/medium/large/custom, merge on `unique_key`. Gold is a small star: `fct_smoke_test` (grain = request) + `dim_complaint_type` + `dim_borough`. Every smoke file carries 🚧 delete-me markers (decision #3).

## 2. The F6 contract is satisfied

The v4 setup scripts hard-code names/paths in their verify gates. All five constraints (backlog §A, C1–C5) are honored — verified by reading scripts 07/09/10 against the artifacts:

- `main_gold.fct_smoke_test` + `main_admin.fct_pipeline_run_raw` produced (09/10 assert non-empty).
- DuckDB resolves to `$PROJECT_ROOT/data/stack.duckdb` everywhere (every script derives it from repo root — portable across install dirs).
- config/profiles use only `{{DUCKDB_PATH}}`/`{{PROJECT_NAME}}`; systemd units use only `{{PROJECT_ROOT}}`. dbt profile name + Oxygen db name are hardcoded (`stack_in_a_box` / `warehouse`) so a hyphenated PROJECT_NAME can't break them.
- nginx docroot hardcoded `/var/www/stack-in-a-box`; `/docs` served from a docroot subdir (run.sh deploys dbt docs there) so the verbatim-copied conf stays install-dir-independent.
- `run.sh manual` populates both tables and deploys all 5 routes (/metrics, /trust, /profile, /erd, /docs/) to the docroot.

## 3. Verification — static only

dbt/oxy/dlt are not installed locally and there's no EC2, so the gates were:

- `py_compile` on every `.py` in `scripts/` + `dlt/`
- YAML parse on 11 config/semantic/dbt files + the generated limitations index
- `bash -n` + shellcheck 0.11 on `run.sh` (clean)
- `generate_metrics_page.py` run locally → valid HTML with a `<table>` (4 measures × 3 views)
- token audit; `index.html` matches script 07's gate regex
- full read-cross-check of every gate in 07/09/10

The **live-functional gates** (`dbt run`, `oxy validate`, `./run.sh manual` end-to-end, the agent answering with its trust contract) are **Plan 3** by design.

## 4. Risks carried into Plan 3

1. **Docroot write-permission seam (highest).** Script 07 (frozen batch-1) creates the docroot `www-data:755`; `run.sh` runs as `ubuntu`. `deploy_html` and the dbt-docs copy fall back to `sudo` when the dir isn't writable — which assumes the default-EC2 `ubuntu` passwordless sudo. If a hardened AMI strips that, every portal deploy (run.sh stages 6–9e) fails and the run records `failed`. **Confirm on the first real install.**
2. **External-schema guesses.** NYC 311 column names, the exact `config.yml`/agent grammar, the Airlayer view grammar, dbt-duckdb schema materialization (`main_gold` etc.), and `oxy start --local` readiness timing are all written from documented shape, unexercised.
3. **No `oxy validate` gate yet** (backlog B1). A malformed agent/view/topic YAML currently passes every automated gate and only surfaces at script 10's manual browser step.

## 5. Deferred (tracked in IMPROVEMENTS_BACKLOG.md)

- **B (hardening):** `oxy validate` gate, DuckDB-lock-aware run.sh + orphaned-run cleanup, timer ordering, tailscale-SSH re-enable warning, `make rip-out-smoke-test`.
- **C (docs):** HARDENING / SWAP_IN_YOUR_DATA / ARCHITECTURE / SETUP / TEARDOWN.
- **D (small fixes):** preflight proxy hint, `--force` note for partial-install reruns.

These can fold into Plan 3's hardening pass or run as a standalone Plan 2 follow-on.

## 6. Next move

**Plan 3 — first real `bootstrap.sh` on a fresh t4g.medium.** Budget ~90 min (60 install + 30 buffer). It validates risks #1 and #2, captures the working Oxygen version (feeds Plan 4's retroactive pin), and fully removes the CLAUDE.md §1 caveat — which today reads "assembled and checked, not yet proven on metal." The dry-run campaign explicitly converged here: the next high-value validation is metal, not more simulation.
