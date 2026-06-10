# LOG.md — Captain's Log Summary

> Single-screen view of project state. Full session narratives live in [`docs/sessions/`](docs/sessions/).

---

## Plans Registry

> Each plan is named `Plan <number> — <label>`. Reference plans by full name in commits and LOG entries.

| # | Name | Status | Closed in |
|---|------|--------|-----------|
| 1 | Decisions resolved + dry-run polish + shellcheck | done | Session 1 (2026-05-27) |
| 2 | Second batch — contract-critical slice | done (slice; B/C/D deferred) | Session 2 (2026-05-28) |
| 3 | First install on metal | done (F6 proven; 6 fixes) | Session 3 (2026-05-29) |
| 5 | APPROACH.md — cross-repo reference standard | done | 2026-06-10 (doc-only; off `main`, parallel to in-flight Plan 4) |

**Session counter:** contiguous 1–N, tracked by Code; all session files at [`docs/sessions/`](docs/sessions/). Chat-side sessions have their own threading and may diverge — Code's counter is authoritative.

---

## Current Status

**Phase:** **Proven on metal.** Plan 3 ran `bootstrap.sh` end-to-end on a fresh `t4g.medium` (Ubuntu 24.04 arm64, Oxygen 0.5.54) — all 10 steps green and the F6 trust contract fired live (agent answered `10000` with SQL + citations + a surfaced limitation on a borough breakdown). Six install bugs found and fixed (see [`docs/design/FIRST_INSTALL_FINDINGS.md`](docs/design/FIRST_INSTALL_FINDINGS.md)). The §1 caveat now reads "validated on EC2." Caveat: validation was fix-and-resume on one box, not a clean from-scratch pass — a fresh-box run of the corrected branch is the recommended final confirmation.

**Active decisions:** All 5 resolved 2026-05-27 — see [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md). Oxygen version observed on metal: **0.5.54** (Plan 4 pins it).

**Active blockers:** None.

**Last Updated:** 2026-06-10 (**Plan 5 — APPROACH.md cross-repo reference standard.** New `APPROACH.md` at repo root (plain-language "how we build": empathy/honesty/optimism, trust contract, hypothesis-then-result, decide-then-build, declarative/reconciliation), tool/dataset-agnostic and **byte-identical to oxygen-mvp's** (oxygen-mvp Plan 47 / this repo Plan 5). Sits above PHILOSOPHY.md (this repo's specialization); CLAUDE.md reading hierarchy gains a "Reference standard (cross-repo, above the convictions)" tier with the reconciliation rule (principle → APPROACH wins; how-it's-done → operational doc wins), and a **new `session-starter.md`** (this repo had none) carries the Chat-side pointers. Canonical body delivered Chat-side + an aligned Google Doc; Gordon approved a merge (pasted body's reconciliation closer + the Doc's newcomer intro). PHILOSOPHY.md + METHODOLOGY.md read in full → compatible (no contradiction). Documentation-only; landed off `main` in parallel with the in-flight Plan 4 (Oxygen version pin). Prompt+report at `docs/prompts/plan-05-approach-reference-standard.{md,report.md}`. **Next (unchanged): Plan 4 — Oxygen 0.5.54 pin + backlog B/C/D + clean from-scratch install confirmation.**)

**Previously:** 2026-05-29 (Plan 3 first install on metal — branch `claude/plan-03-first-install-on-metal`, 7 commits. Found+fixed 6 bugs walking the 10-step install: config-comment `{{` gate false-positive (`09f5d4e`), nginx graceful-reload gate race (`d389251`), `oxy.service` `%h`→`/root` 203/EXEC (`dbb20f7`), `Persistent`-timer catch-up colliding with the smoke run on the DuckDB lock + `setsid` not waiting (`b5c30cc`), step-10 timer is-active→is-enabled (`9e58ec2`), and the F6 blocker — oxy duckdb DB key `dataset`→`path` (`3674088`). F6 proven via `oxy run answer_agent`: total count 10,000 + per-borough breakdown with `borough-unspecified-bucket` limitation surfaced. Observed versions captured for the Plan-4 pin. **Next: Plan 4 — retroactive Oxygen 0.5.54 pin + backlog B/C/D + the recommended clean from-scratch install confirmation.**).

---

## Next-Plan-Candidates

Corrected dependency chain (the original ordering had first-install before the second batch; Plan 1's dry-run showed first-install is impossible until the second batch ships):

1. ~~**Plan 2 — The second batch.**~~ **Contract-critical slice SHIPPED** (Session 2) — the 16 core artifacts + the F6 contract (backlog §A). **B/C/D remain open** (deferred from the slice): B = oxy-validate gate, lock-aware run.sh, timer ordering, ssh-re-enable warn, `make rip-out-smoke-test`; C = HARDENING / SWAP_IN_YOUR_DATA / ARCHITECTURE / SETUP / TEARDOWN docs; D = small fixes (E1 proxy hint, E2 `--force` note). A Plan 2 follow-on or Plan 3's hardening pass picks these up.
2. **Plan 3 — First real install** on a fresh t4g.medium EC2. ~90 minutes. The validation no dry run can substitute for. Captures the working Oxygen version; full removal of the §1 caveat lands here. **Next-Code handoff:** [`docs/prompts/plan-3-first-real-install.md`](docs/prompts/plan-3-first-real-install.md) (preconditions + carried risks + gotchas).
3. **Plan 4 — Retroactive Oxygen version pin** per decision #4 + Plan 3 findings.

---

## Recent Sessions

### Session 3 — 2026-05-29 — plan-03-first-install-on-metal
[full narrative](docs/sessions/session-3-2026-05-29-plan-03-first-install-on-metal.md)

- **Goal:** First real install on a fresh t4g.medium — run `bootstrap.sh` end-to-end, walk every break, prove the F6 trust contract on metal.
- **Shipped:** All 10 steps green; F6 proven (agent answered 10,000 + per-borough breakdown with limitation surfaced). 6 install bugs fixed across 7 commits; `FIRST_INSTALL_FINDINGS.md`; §1 caveat replaced with "validated on EC2"; Oxygen 0.5.54 captured for Plan-4 pin.
- **Decisions:** 4 — see Decisions Log.
- **Status:** complete
- **Next:** Plan 4 — pin Oxygen 0.5.54, clear backlog B/C/D, run a clean from-scratch install confirmation.

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
| 2026-05-29 | oxy duckdb database uses **`path:`**, not `dataset:` — `dataset` makes oxy treat the path as a directory of CSV/parquet files (the F6 query blocker); `path` opens the `.duckdb` file. Confirmed against the proven oxygen-mvp config. | active |
| 2026-05-29 | systemd timers **enabled but not `--now`** during install — `pipeline-refresh.timer` has `Persistent=true`, so activating it mid-install fires a catch-up `run.sh` that collides with the smoke run on the DuckDB lock. Timers activate on next boot; steps 08 + 10 verify `is-enabled`, not `is-active`. | active |
| 2026-05-29 | `oxy.service` ExecStart uses a substituted **`{{HOME_DIR}}`** token, not `%h` — `%h` resolves to `/root` for system units (not `User=`'s home), causing 203/EXEC. | active |
| 2026-05-29 | F6 validation done via **`oxy run` CLI** (autonomous, re-runnable) rather than the browser SPA — same agent + config; proves the trust contract identically. The install's browser-step instructions remain for the human sign-off. | active |
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
