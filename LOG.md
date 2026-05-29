# LOG.md — Captain's Log Summary

> Single-screen view of project state. Full session narratives live in [`docs/sessions/`](docs/sessions/).

---

## Plans Registry

> Each plan is named `Plan <number> — <label>`. Reference plans by full name in commits and LOG entries.

| # | Name | Status | Closed in |
|---|------|--------|-----------|
| 1 | Decisions resolved + dry-run polish + shellcheck | done | Session 1 (2026-05-27) |
| 2 | Second batch — contract-critical slice | done (slice; B/C/D deferred) | Session 2 (2026-05-28) |

**Session counter:** contiguous 1–N, tracked by Code; all session files at [`docs/sessions/`](docs/sessions/). Chat-side sessions have their own threading and may diverge — Code's counter is authoritative.

---

## Current Status

**Phase:** Application layer assembled. Plan 2's contract-critical slice built the 16 core artifacts (dlt NYC 311 pipeline, dbt bronze/gold/admin models, config + dbt-profile templates, semantic layer + Answer Agent, run-observability + profiling + portal-generator scripts, `run.sh`, nginx site, systemd units, first-boot portal) and honored the full F6 contract (backlog §A, C1-C5). **Static-verify only — never executed on EC2.** A real install should now proceed past step 05 and through the smoke test, but the first real EC2 run is Plan 3. The CLAUDE.md §1 caveat now reads "assembled and checked, not yet proven on metal."

**Active decisions:** All 5 resolved 2026-05-27 — see [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md). Inputs honored by Plan 2: NYC 311 smoke source, Tailscale required, smoke in main path with delete-me markers, repo name `stack-in-a-box`, Oxygen version still latest-from-get.oxy.tech (pin in Plan 4).

**Active blockers:** None.

**Last Updated:** 2026-05-28 (Plan 2 contract-critical slice shipped — branch `claude/plan-2-second-batch-slice`, 5 commits G1-G5 + G6 docs. Built the data path (dlt `smoke_test_pipeline.py` → bronze `raw_nyc_311` → gold `fct_smoke_test` + dims → admin `fct_test_run`/`dim_data_quality_test`), the trust-contract path (3 Airlayer views + topic + `answer_agent.agent.yml` + `docs/schema.sql` + 2 seed limitations + index generator), the observability + portal layer (`pipeline_run_start`/`_end`, `profile_tables`, `check_profile_staleness`, `source_health_check`, `_nav` + 4 generators), and the orchestration + serving layer (`run.sh` 10-stage, `nginx/stack-in-a-box.conf`, 7 systemd units, first-boot `portal/index.html`). All DUCKDB_PATH derivations repo-root-relative; dbt profile name + Oxygen db name hardcoded (`stack_in_a_box`/`warehouse`) so only `{{DUCKDB_PATH}}`/`{{PROJECT_NAME}}` tokens remain. Static verification: py_compile (all .py), YAML parse (11 files + limitations index), `bash -n` + shellcheck (run.sh clean), generate_metrics_page run locally → valid HTML, token audit (only `{{PROJECT_ROOT}}` in units), index.html matches 07 gate regex, full read-cross-check against 07/09/10. Backlog §A marked SATISFIED; B/C/D deferred. **Next: Plan 3 — first real EC2 install.**).

---

## Next-Plan-Candidates

Corrected dependency chain (the original ordering had first-install before the second batch; Plan 1's dry-run showed first-install is impossible until the second batch ships):

1. ~~**Plan 2 — The second batch.**~~ **Contract-critical slice SHIPPED** (Session 2) — the 16 core artifacts + the F6 contract (backlog §A). **B/C/D remain open** (deferred from the slice): B = oxy-validate gate, lock-aware run.sh, timer ordering, ssh-re-enable warn, `make rip-out-smoke-test`; C = HARDENING / SWAP_IN_YOUR_DATA / ARCHITECTURE / SETUP / TEARDOWN docs; D = small fixes (E1 proxy hint, E2 `--force` note). A Plan 2 follow-on or Plan 3's hardening pass picks these up.
2. **Plan 3 — First real install** on a fresh t4g.medium EC2. ~90 minutes. The validation no dry run can substitute for. Captures the working Oxygen version; full removal of the §1 caveat lands here.
3. **Plan 4 — Retroactive Oxygen version pin** per decision #4 + Plan 3 findings.

---

## Recent Sessions

### Session 2 — 2026-05-28 22:29 EDT — plan-2-second-batch-slice
[full narrative](docs/sessions/session-2-2026-05-28-plan-2-second-batch-slice.md)

- **Goal:** Build Plan 2's contract-critical slice — the minimum application layer to get a real install past step 05 and through the smoke test, honoring the F6 contract; static-verify only.
- **Shipped:** 16 core artifacts in 5 commit groups (data path, trust-contract path, observability + portal generators, orchestration + serving) + G6 docs. F6 contract (§A C1-C5) satisfied; all static gates green.
- **Decisions:** 3 — see Decisions Log.
- **Status:** complete
- **Next:** Plan 3 — first real EC2 install.

### Session 1 — 2026-05-27 — plan-1-decisions-and-dry-run-polish

- **Goal:** Open the repo's own plan ledger. Resolve all 5 design decisions, fix the honesty disconnects surfaced by Code's 2026-05-27 dry-run, run shellcheck, and do flow-level dry-runs.
- **Shipped:** All 5 decisions RESOLVED in OPEN_DECISIONS.md with rationale + Plan-2 implications. TASKS.md + LOG.md reordered to the corrected dependency chain. CLAUDE.md §1 "Current install state" caveat. Design plan §8 reframed ("out of scope" → "required follow-up work"). Script 05 real repo URL + clone-block comment. `apps/.gitkeep`. Shellcheck clean (3 minor findings in script 05, all fixed). Flow-level dry-runs across 5 scenarios in FLOW_DRY_RUN_FINDINGS.md. PROMPTS.md notes Plan 1 as first use of the prompt-file convention here.
- **Decisions:** 5 (all inherited from Chat's upstream resolution — recorded, not relitigated).
- **Status:** complete
- **Next:** Plan 2 — the second batch.

---

## Earlier Sessions

_None._

---

## Decisions Log

| Date | Decision | Status |
|---|---|---|
| 2026-05-28 | dbt profile name + Oxygen db name **hardcoded** (`stack_in_a_box` / `warehouse`), not tokenized — a hyphenated `{{PROJECT_NAME}}` can't be a dbt profile name, and a fixed Oxygen db name keeps the agent's `database: warehouse` reference stable across a PROJECT_NAME override. Only `{{DUCKDB_PATH}}`/`{{PROJECT_NAME}}` tokens remain (C3-safe). | active |
| 2026-05-28 | `/docs` served from a **docroot subdirectory** (`run.sh` copies dbt/target into `$DOCROOT/docs/`), not an nginx `alias` to `dbt/target` — script 07 copies the nginx conf verbatim, so an alias would couple it to the install dir; a docroot subdir keeps it path-independent. | active |
| 2026-05-28 | `run.sh` `deploy_html` made **sudo-aware** — script 07 (frozen batch-1) creates the docroot `www-data:755` (not ubuntu-writable), but `run.sh` runs as ubuntu; deploys route through `sudo` when the docroot isn't writable (default EC2 ubuntu has passwordless sudo). Only real batch-1↔batch-2 integration seam found. | active |
| 2026-05-27 | Tailscale **required** (not optional) — cleaner security posture, free-tier covers the audience. | active |
| 2026-05-27 | Smoke source = **NYC 311** (SODA `erm2-nwe9`) — highest pipeline reuse, well-documented API. | active |
| 2026-05-27 | Smoke test lives in **main path** with delete-me markers + `make rip-out-smoke-test` (lands in Plan 2). | active |
| 2026-05-27 | Oxygen install stays **latest from get.oxy.tech** with a TODO; retroactive pin in Plan 4 after first install. | active |
| 2026-05-27 | Repo name **`stack-in-a-box`** stays; rename is a contained future plan if needed. | active |

---

## Active Blockers

_None._
