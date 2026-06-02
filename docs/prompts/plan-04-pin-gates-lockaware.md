# Plan 4 — Pin, contract-level gates, lock-aware refresh, clean-box confirm (stack-in-a-box)

**Repo:** `ironmonkey88/stack-in-a-box`
**Branch:** `claude/plan-04-pin-gates-lockaware`
**Mode:** Code-autonomous (proven path from Plan 3)
**Context:** Follows Plan 3 (PR #7, `main` @ `7ebec07`; Oxygen 0.5.54 proven on metal). Resolves the design questions settled in Chat from the `2026-05-30-plan-3-install-and-portal-design.md` handoff.

---

## Phase 0 — Write this prompt to the repo (first commit)
Before any other work, write this prompt verbatim to `docs/prompts/plan-04-pin-gates-lockaware.md` on a new branch `claude/plan-04-pin-gates-lockaware`. This file write is the first commit on the branch. All later phases proceed against it. (MCP-direct-commit path is paused; Code owns prompt-file creation.)

---

## Outcome
A fresh `t4g.medium` runs `bootstrap.sh` **clean from scratch** (not fix-and-resume) on the pinned Oxygen version, the install gate now **fails if the agent can't answer a live query**, and the daily refresh no longer contends with serving on the DuckDB write lock — with contention **measured**, not just mitigated.

---

## Phase 1 — Verify assumptions against source (do this before building)
The prompt's task assumptions below were grounded against `main`, but confirm before editing:
- `dlt/smoke_test_pipeline.py` **already has** `_get_with_retry` (4 attempts, exponential backoff on 429/5xx/timeout) and a `small`=10k path via `_max_rows()`. Q5 is therefore mostly *configuration + test*, not new retry code — confirm this still holds.
- Run-tracking is in `scripts/pipeline_run_start.py` / `pipeline_run_end.py` (they own the admin run-raw table), **not** a dbt model. The lock metric lands there.
- `run.sh` is the writer; `oxy` (systemd `oxy.service`) is the reader. Confirm where the refresh actually opens its DuckDB write.

If any assumption is wrong, adjust the task and note it in findings — don't build on a stale assumption.

---

## Phase 2 — Pin Oxygen 0.5.54 (small, do first)
Retroactively pin the version Plan 3 proved. Update the installer step (script 03) and/or config to request `0.5.54` explicitly rather than latest from `get.oxy.tech`. Record the pin in `FIRST_INSTALL_FINDINGS.md`. This is the Plan 3 follow-through.

## Phase 3 — Contract-level install gates (the headline; methodology rule R1)
The Plan 3 lesson: the install passed all 10 steps while every agent query was broken, because nothing queried *through* oxy. Fix the gate, not just the bug.
- **Add a live-query gate** to step 10 (or a new step): ask the agent a canned question (e.g. "how many 311 service requests are in the warehouse?") *through oxy*, assert a numeric answer returns with the trust-contract sections. Component checks (`:3000 → 200`, table non-empty) stay; this is *added*, not a replacement.
- **Add an `oxy validate` gate** (backlog B1) earlier in the run, so malformed agent/view/topic YAML fails fast instead of surfacing only at a browser step.
- Both gates must be exercised in the Phase 6 clean-box run.

## Phase 4 — Lock-aware refresh + contention measurement (Q1; methodology rule R2)
Decision (Chat-confirmed): **flock + read-side retry now; snapshot/atomic-swap deferred** to a data-driven trigger.
- Wrap the `run.sh` refresh write in an exclusive `flock` on a lockfile beside `stack.duckdb`.
- Give `oxy`-side reads (or the query path) a bounded **retry-with-backoff** when the DB is write-locked, so a refresh slows queries rather than erroring them.
- **Measure it** (this is the explicit ask — measure before it gets bad):
  - Writer: record refresh **lock-hold duration** (acquire→release wall-clock) into the admin run-tracking row via `pipeline_run_end.py`. Add a `lock_held_seconds` field.
  - Reader: count retries + total **wait** before a successful read; emit to a small admin contention record (timestamped).
  - Route both through the existing admin/observability schema so the box can self-report contention.
- **Name the upgrade trigger** in `IMPROVEMENTS_BACKLOG.md`: when lock-hold exceeds a stated threshold (or reader p95 wait exceeds one), that's the documented signal to implement the snapshot/atomic-swap read path. Pick provisional threshold values; they can be tuned.
- This is what lets the timers run for real instead of being boot-deferred. **Only re-enable `--now` timer activation if the flock+retry path is proven** in Phase 6; otherwise keep the boot-deferred workaround and note why.

## Phase 5 — Smoke resilience posture (Q5; methodology rule R4)
Retry already exists — this is config + a resume test, not new retry code.
- **Flip the smoke default to `small`** (10k, clean on metal in Plan 3). Keep `medium`/`large`/`custom` as opt-in `SMOKE_MODE` values. Rationale: the attended install must give a clean one-sitting pass/fail; `medium` hit live SODA read-timeouts.
- **Verify defer-and-resume for the *unattended* refresh:** force a mid-run failure and confirm the merge-on-`unique_key` path resumes cleanly on the next run (idempotent, no dupes, no corruption). Attended install = definitive; unattended refresh = self-heals. Document the result.

## Phase 6 — Clean-box from-scratch confirmation (the Plan 3 caveat)
Plan 3 was fix-and-resume on one instance. Now prove the corrected `main` (this branch) installs clean on a **fresh** `t4g.medium` with no intervention:
- Fresh box, clone branch, `bootstrap.sh` end to end, all gates green **including** the new live-query + validate gates.
- Confirm step 08's `enable` (no `--now`) line actually executes (Plan 3 hit the "already enabled" branch and never exercised the new line).
- If clean: in `CLAUDE.md` §1, **remove** the install-state caveat entirely (Plan 3 softened it to "validated on EC2"; a clean pass earns full removal). Fix the README Status section to "proven from scratch on metal."
- If clean with stubs: state precisely what's proven vs stubbed; don't remove the caveat.

## Phase 7 — Portal items (from handoff §5; Chat decision: minimal)
Build all three as specced; keep the default portal minimal (it's a customization starting point, not a finished product):
1. Keep the basic portal as the simple default.
2. dbt-docs `/docs/` "← Back to portal" link via a `{% docs __overview__ %}` block with plain-Markdown link (dbt-docs sanitizes raw HTML — CLAUDE.md §10).
3. Static `portal/about.html` + "About" nav item in `scripts/_nav.py`, synced by `run.sh` like `index.html` (no generator, no warehouse dependency). The About page documents *the template and how to customize it* — not the internals.

## Phase 8 — Findings + housekeeping + PR
- Update `FIRST_INSTALL_FINDINGS.md` (pin, clean-box result, contention measurements, resume test).
- **Commit `METHODOLOGY.md`** to the repo root (provided by Chat) — this is the seed of the two-repo methodology whiteboard. It contains the rules *and* the sync procedure.
- **Add a one-line pointer in `CLAUDE.md`:** "Methodology rules + cross-repo sync process: see `METHODOLOGY.md`." Do not duplicate the procedure into CLAUDE.md — the procedure lives only in METHODOLOGY.md so the two repos can't drift on how they sync.
- **Report back the Phase 4 threshold placeholders** you chose (lock-hold seconds / reader p95 wait), and write them into `IMPROVEMENTS_BACKLOG.md` next to the snapshot-upgrade item (and note in `FIRST_INSTALL_FINDINGS.md`). These concrete numbers are stack's local instantiation of methodology rule R2 — they live in stack's operational docs, **not** in `METHODOLOGY.md` (which keeps R2 general). Surface the chosen values in the PR description so Gordon sees them.
- Update `LOG.md`, `TASKS.md`, session handoff.
- Triage remaining `IMPROVEMENTS_BACKLOG.md` B/C/D items; note which Plan 4 closed.
- Open a PR.

---

## Out of scope
- Snapshot/atomic-swap DuckDB read path (deferred to the threshold trigger from Phase 4).
- TLS/domain posture (Q4: stay raw-IP HTTP; document TLS options in `HARDENING.md` as a customization step — that doc is backlog C, not this plan's build).
- Backlog C doc batch beyond what Phase 8 triage touches.
- Anything in `oxygen-mvp` — but see the note below.

## Methodology propagation note (do not action in oxygen from this plan)
Rules R1, R2, R3 (and the R4 principle) from Plan 3/4 are foundational and likely apply to oxygen-mvp. They live on the `METHODOLOGY.md` whiteboard committed in Phase 8, which carries both the rules and the **sync process** (eventually-consistent, bidirectional, Code-proposes/human-approves). **Do not edit oxygen-mvp from this plan.** oxygen-side reconciliation — instantiating `METHODOLOGY.md` there and running the first sync pass — is a separate, human-ratified step, per the procedure documented in the file itself.

## Done means
Fresh-box clean install on pinned 0.5.54, live-query + validate gates green, flock+retry refresh with contention measured and a named upgrade threshold, smoke default `small` with verified unattended resume, three portal items built, caveat removed (or precisely qualified), PR open.

---

**Code's restatement (PROMPTS.md §5 Step 4):** Plan 3 proved the box works on metal but left four things open that this plan closes. (1) The version that worked (Oxygen 0.5.54) was never pinned — pin it so installs are reproducible. (2) The install could go fully green while the agent was broken, because no gate ever asked the agent a real question — add a gate that does, plus an `oxy validate` gate so bad YAML fails fast. (3) The daily refresh and the live agent both touch one DuckDB file and will eventually fight over the write lock — put a flock around the refresh and a retry on the read side so the refresh *slows* queries instead of *breaking* them, and crucially *measure* the contention (lock-hold seconds + reader wait) into the admin schema so we get a data-driven signal before it's a problem, with a named threshold that triggers the bigger snapshot fix later. (4) Plan 3's "it works" was fix-and-resume on one box, not a clean from-scratch run — prove the corrected scripts install clean on a brand-new box, and only then fully remove the install caveat. Plus: default the smoke to `small` (so the attended install always passes in one sitting) while verifying the unattended refresh self-heals after a mid-run failure; and build the three minimal portal items (keep-it-simple default, dbt-docs back-link, an About page about *customizing the template*). Note: `METHODOLOGY.md` + its CLAUDE.md pointer were already committed to main last turn (`33751e8`), so Phase 8's methodology-commit is pre-satisfied — this branch already carries it.
