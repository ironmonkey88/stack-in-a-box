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
| 6 | PHILOSOPHY.md creed (empathy/honesty/optimism) | done | 2026-06-10 (doc-only; additive framing section, §1–§7 unchanged) |
| 7 | METHODOLOGY.md R5–R8 (reasoning/build disciplines) | done | 2026-06-10 (doc-only; R1–R4 unchanged, 4 new rules `stack-only` + propagation rows) |
| 8 | Project migration summary (both repos) | done | 2026-06-17 (doc-only; off `main`, parallel to in-flight Plan 4). New `docs/MIGRATION_SUMMARY.md` — cold-start handoff for resuming the project in a fresh Claude Chat / new account; captures working agreements, in-flight state, deferred decisions + reasoning, repo locations + stack, first-session checklist. **Byte-identical body in both repos** (`shasum` `e44f3c1fc895a3aec8f61f5bac57d92e375461ec`) at the same altitude as APPROACH.md — this repo **Plan 8** / sibling **oxygen-mvp Plan 50**. Body transcribed verbatim from the prompt (point-in-time snapshot 2026-06-17; forward-looking "verify against LOG.md" lines for the next Chat left as-is). `session-starter.md` "Key Files to Know" pointer added (adapted to this repo's table). Slot resolved by boot-audit: highest used = 7, Plan 4 reserved/in-flight → 8 next contiguous free; halt did not fire. Prompt+report at `docs/prompts/plan-08-migration-summary.{md,report.md}`. |
| 9 | APPROACH design-reasoning ("breadcrumbs") doc | done | 2026-06-17 (doc-only; off `main`, parallel to in-flight Plan 4). New `docs/design/APPROACH_DESIGN_REASONING.md` — the reasoning *behind* APPROACH.md (why each choice was made + what was rejected), **reconstructed** (not transcribed) from durable repo sources: APPROACH.md, the `plan-05` prompt+report, METHODOLOGY R5–R8 + Origin/Sync rows, the PHILOSOPHY creed sections, and oxygen-mvp Plan 48/49 rows. Carries a `Status: reconstructed` note + source list; 8 decision entries in decision→why→alternatives shape. **Halt condition resolved (Gordon's call):** the byte-identical-APPROACH.md constraint — chose **option (a)**, add the one-line provenance footer to **both** repos' APPROACH.md to preserve byte-identity (the doc stays single-home here; only the pointer duplicates). Footer `shasum` match confirmed `c6e27ce1aa8ee8e6e8559cb156ddbd5b7ef230cc`; oxygen-mvp side landed as a small mirror PR (not a numbered oxygen-mvp plan). One entry (capability-to-scope law) carries a sourcing note flagging the control-theory/hardware-abstraction breadth as design-session reasoning not fully recoverable from the core docs — surfaced, not invented. `session-starter.md` pointer added. Slot resolved by boot-audit: highest used = 8, Plan 4 reserved → 9 next contiguous free; halt did not fire. Prompt+report at `docs/prompts/plan-09-approach-design-reasoning.{md,report.md}`. |
| 10 | Land the local-analytics-app MVP-0 **concept** doc | done | 2026-06-17 (doc-only; off `main`, parallel to in-flight Plan 4). Established new `docs/concepts/` (+ `README.md`) as the home for future-product / downstream-leaf concepts, and landed its first inhabitant `docs/concepts/local-analytics-app-mvp0.md` — a local single-user analytics app (DuckDB + connector seam + reconciling semantic layer + constrained agent) whose thesis is that it works without the operator in the loop. Captures the one-line concept + target user + kill-test (persistence / multi-source reconciliation / repeatability), the MVP-0 framing, all 10 settled design decisions, the operator-in-the-loop insight (= METHODOLOGY R6 as a whole-product thesis), and the downstream-leaf three-repo relationship. **The documented concept is explicitly not-a-plan** — it carries a "Status: not-a-plan" banner, is gated on stack-in-a-box Plan 3 being fully resolved, and is **not** added to this registry or the active task list. Only *this* plan (the act of landing the doc) is numbered. `session-starter.md` pointer added. Boot-audit: highest used = 9, Plan 4 reserved → 10 next contiguous free; halt did not fire (the not-a-plan status was preserved without bookkeeping compromise). Prompt+report at `docs/prompts/plan-10-local-analytics-app-concept.{md,report.md}`. |
| 11 | session-starter.md new-account cold-start block (both repos) | done | 2026-06-17 (doc-only; off `main`, parallel to in-flight Plan 4). Added one conditional section near the top of `session-starter.md` (right after the "Which repo is this?" callout) orienting a fresh Claude arriving in a **new account / new machine** — names the migration trio in read-order (**`docs/MIGRATION_SUMMARY.md` → `MIGRATION_CHECKLIST.md` → `PROJECT_MIGRATION_2026-06-07.md`**), then hands off to the normal "How to Start Each Session" flow; a continuing session skips it. **Consolidation, not a new doc.** Block **worded identically** to the sibling oxygen-mvp copy (extracted-block `diff` clean, 11 lines); the rest of each `session-starter.md` is repo-specific and untouched (the two files are intentionally **not** byte-identical overall). All three migration docs verified present + git-tracked at their named paths in both repos before wiring (halt condition clear). This repo **Plan 11** / sibling **oxygen-mvp Plan 51**. Supersedes the earlier infra-install "zero-to-live setup runbook" prompt per Gordon's consolidation decision. Boot-audit: highest used = 10, Plan 4 reserved → 11 next contiguous free. Prompt+report at `docs/prompts/plan-11-session-starter-coldstart.{md,report.md}`. |

**Session counter:** contiguous 1–N, tracked by Code; all session files at [`docs/sessions/`](docs/sessions/). Chat-side sessions have their own threading and may diverge — Code's counter is authoritative.

---

## Current Status

**Phase:** **Proven on metal.** Plan 3 ran `bootstrap.sh` end-to-end on a fresh `t4g.medium` (Ubuntu 24.04 arm64, Oxygen 0.5.54) — all 10 steps green and the F6 trust contract fired live (agent answered `10000` with SQL + citations + a surfaced limitation on a borough breakdown). Six install bugs found and fixed (see [`docs/design/FIRST_INSTALL_FINDINGS.md`](docs/design/FIRST_INSTALL_FINDINGS.md)). The §1 caveat now reads "validated on EC2." Caveat: validation was fix-and-resume on one box, not a clean from-scratch pass — a fresh-box run of the corrected branch is the recommended final confirmation.

**Active decisions:** All 5 resolved 2026-05-27 — see [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md). Oxygen version observed on metal: **0.5.54** (Plan 4 pins it).

**Active blockers:** None.

**Last Updated:** 2026-06-17 (**Plan 11 — session-starter cold-start block.** Added a new-account cold-start block near the top of `session-starter.md` (both repos) — a conditional section pointing a fresh Claude to the migration trio in read-order (`docs/MIGRATION_SUMMARY.md` → `MIGRATION_CHECKLIST.md` → `PROJECT_MIGRATION_2026-06-07.md`), then to the normal start-each-session flow; a continuing session skips it. Consolidation only (no new standalone doc); block worded identically across both repos (extracted-block `diff` clean), rest of each file untouched. All three docs verified present + tracked before wiring. This repo Plan 11 / sibling oxygen-mvp Plan 51. Supersedes the earlier infra-install runbook prompt per Gordon's consolidation decision. Boot-audit: highest = 10, Plan 4 reserved → 11 next free. Prompt+report at `docs/prompts/plan-11-session-starter-coldstart.{md,report.md}`.)

**Previously:** 2026-06-17 (**Plan 10 — local-analytics-app MVP-0 concept doc.** Established `docs/concepts/` (+ README) and landed `docs/concepts/local-analytics-app-mvp0.md` — a local single-user analytics app concept (DuckDB + connector seam + reconciling semantic layer + constrained agent) that works without the operator in the loop; captures the kill-test, MVP-0 framing, 10 settled decisions, the operator-in-the-loop insight (= METHODOLOGY R6 as a product thesis), and the downstream-leaf three-repo relationship. **The concept is explicitly not-a-plan** — "Status: not-a-plan" banner, gated on Plan 3 resolution, NOT added to the Plans Registry or active tasks; only the doc-landing plan is numbered. `session-starter.md` pointer added. Boot-audit: highest = 9, Plan 4 reserved → 10 next free; halt did not fire. Prompt+report at `docs/prompts/plan-10-local-analytics-app-concept.{md,report.md}`.)

**Previously:** 2026-06-17 (**Plan 9 — APPROACH design-reasoning doc.** New `docs/design/APPROACH_DESIGN_REASONING.md` — the reasoning *behind* APPROACH.md (why each choice was made + what was rejected), **reconstructed** from durable repo sources and marked `Status: reconstructed`; 8 decision entries in decision→why→alternatives shape. Halt resolved by Gordon: provenance footer added to **both** repos' APPROACH.md to preserve byte-identity (`shasum` `c6e27ce…`), with the design-reasoning doc itself single-home here; oxygen-mvp got a small mirror PR. One entry (capability-to-scope law) flags its control-theory/hardware-abstraction breadth as design-session reasoning not fully recoverable from the core docs. `session-starter.md` pointer added. Boot-audit: highest = 8, Plan 4 reserved → 9 next free. Prompt+report at `docs/prompts/plan-09-approach-design-reasoning.{md,report.md}`.)

**Previously:** 2026-06-17 (**Plan 8 — Project migration summary.** New `docs/MIGRATION_SUMMARY.md` — a cold-start handoff so a fresh Claude Chat in a different account can resume the project with nothing lost (working agreements, in-flight state, deferred decisions + reasoning, repo locations + stack, first-session checklist). Same altitude as APPROACH.md: **byte-identical body in both repos** (`shasum` `e44f3c1…`) — this repo Plan 8 / sibling oxygen-mvp Plan 50. Body transcribed verbatim (point-in-time snapshot 2026-06-17; forward-looking next-Chat lines left as-is). `session-starter.md` pointer added. Doc-only, off `main` parallel to in-flight Plan 4. Boot-audit resolved the slot (highest = 7, Plan 4 reserved → 8 next free). Prompt+report at `docs/prompts/plan-08-migration-summary.{md,report.md}`.)

**Previously:** 2026-06-10 (**Plan 7 — METHODOLOGY.md R5–R8.** Added the reasoning/build disciplines from the design session, in the existing Rule/Origin/Sync form: **R5** hypothesis/result two-tier gate (Sensemake — labels never strip), **R6** manufacture operator expertise behind a constrained agent surface (system-humanism build half; conviction half stays in PHILOSOPHY.md), **R7** declarative/desired-state + reconciliation, **R8** idempotent specs (split from R7). Origin = design session 2026-06-10 ratified by Gordon, not yet exercised in a plan; Sync = `stack-only`, each with a Pending-propagation row (carry to oxygen-mvp when its METHODOLOGY.md is instantiated — R6 is the destination of oxygen-mvp's deferred system-humanism split). R1–R4 unchanged; a framing line distinguishes field-experience rules from design-ratified disciplines. Boot-audited slot 7 free. Prompt+report at `docs/prompts/plan-07-methodology-reasoning-rules.{md,report.md}`.)

**Previously:** 2026-06-10 (**Plan 6 — PHILOSOPHY.md creed.** Added the empathy/honesty/optimism creed as an unnumbered framing section near the top of `PHILOSOPHY.md`, consistent with APPROACH.md (Plan 5). Light cross-references to the principles each frames (empathy → §1's facts-vs-answers point, honesty → §4/§6, optimism → the one new idea: a complaint/incident feed inherits a negativity bias by construction, and correcting it is honest reporting not editorializing). Generic/dataset-agnostic; §1–§7 unchanged (additive, single-hunk diff). Boot-audited slot 6 free first. Prompt+report at `docs/prompts/plan-06-philosophy-creed.{md,report.md}`.)

**Previously:** 2026-06-10 (**Plan 5 — APPROACH.md cross-repo reference standard.** New `APPROACH.md` at repo root (plain-language "how we build": empathy/honesty/optimism, trust contract, hypothesis-then-result, decide-then-build, declarative/reconciliation), tool/dataset-agnostic and **byte-identical to oxygen-mvp's** (oxygen-mvp Plan 48 — landed as 47 then renumbered after a collision with its older open PR #76 / this repo Plan 5). Sits above PHILOSOPHY.md (this repo's specialization); CLAUDE.md reading hierarchy gains a "Reference standard (cross-repo, above the convictions)" tier with the reconciliation rule (principle → APPROACH wins; how-it's-done → operational doc wins), and a **new `session-starter.md`** (this repo had none) carries the Chat-side pointers. Canonical body delivered Chat-side + an aligned Google Doc; Gordon approved a merge (pasted body's reconciliation closer + the Doc's newcomer intro). PHILOSOPHY.md + METHODOLOGY.md read in full → compatible (no contradiction). Documentation-only; landed off `main` in parallel with the in-flight Plan 4 (Oxygen version pin). Prompt+report at `docs/prompts/plan-05-approach-reference-standard.{md,report.md}`. **Next (unchanged): Plan 4 — Oxygen 0.5.54 pin + backlog B/C/D + clean from-scratch install confirmation.**)

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
