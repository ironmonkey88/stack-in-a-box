# LOG.md — Captain's Log Summary

> Single-screen view of project state. Full session narratives live in [`docs/sessions/`](docs/sessions/).

---

## Plans Registry

> Each plan is named `Plan <number> — <label>`. Reference plans by full name in commits and LOG entries.

| # | Name | Status | Closed in |
|---|------|--------|-----------|
| 1 | Decisions resolved + dry-run polish + shellcheck | done | Session 1 (2026-05-27) |

**Session counter:** contiguous 1–N, tracked by Code; all session files at [`docs/sessions/`](docs/sessions/). Chat-side sessions have their own threading and may diverge — Code's counter is authoritative.

---

## Current Status

**Phase:** Pre-installation, decisions settled. Discipline docs + v4 setup scripts are in place and shellcheck-clean. The 5 design decisions are resolved. The application layer (the "second batch") hasn't been built yet — a real install completes steps 00-03 and dies at step 05, which the CLAUDE.md §1 orientation now states honestly.

**Active decisions:** All 5 resolved 2026-05-27 — see [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md). Settled inputs for Plan 2: NYC 311 smoke source, Tailscale required, smoke in main path with delete-me markers, repo name `stack-in-a-box`, Oxygen version pinned later (after first real install).

**Active blockers:** None.

**Last Updated:** 2026-05-28 (post-Plan-1 follow-up — 3 more flow dry-runs F6-F8 in [`docs/design/FLOW_DRY_RUN_FINDINGS.md`](docs/design/FLOW_DRY_RUN_FINDINGS.md): F6 forward contract check (highest-value — pins the second-batch interface: exact table names, DuckDB path, token whitelist, docroot, run.sh outputs), F7 AWS SG lockout sequence (sound; self-check labeled best-effort), F8 secrets lifecycle (posture solid). 2 in-plan fixes — design plan §4 token convention corrected, 10_verify SG self-check comment. The F6 contract is now an inherited requirement on Plan 2.).

---

## Next-Plan-Candidates

Corrected dependency chain (the original ordering had first-install before the second batch; Plan 1's dry-run showed first-install is impossible until the second batch ships):

1. **Plan 2 — The second batch.** Build the 16 missing artifacts per [`docs/design/STACK_IN_A_BOX_PLAN.md`](docs/design/STACK_IN_A_BOX_PLAN.md) §9, against the settled decisions. Estimated 10-14 hours. Removes the CLAUDE.md §1 "Current install state" caveat as part of its housekeeping.
2. **Plan 3 — First real install** on a fresh t4g.medium EC2. ~90 minutes. Captures the working Oxygen version.
3. **Plan 4 — Retroactive Oxygen version pin** per decision #4 + Plan 3 findings.

---

## Recent Sessions

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
| 2026-05-27 | Tailscale **required** (not optional) — cleaner security posture, free-tier covers the audience. | active |
| 2026-05-27 | Smoke source = **NYC 311** (SODA `erm2-nwe9`) — highest pipeline reuse, well-documented API. | active |
| 2026-05-27 | Smoke test lives in **main path** with delete-me markers + `make rip-out-smoke-test` (lands in Plan 2). | active |
| 2026-05-27 | Oxygen install stays **latest from get.oxy.tech** with a TODO; retroactive pin in Plan 4 after first install. | active |
| 2026-05-27 | Repo name **`stack-in-a-box`** stays; rename is a contained future plan if needed. | active |

---

## Active Blockers

_None._
