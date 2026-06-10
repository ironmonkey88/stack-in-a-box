# Report — Plan 5: APPROACH.md as the cross-repo reference standard

**Status:** complete
**Date:** 2026-06-10
**Repo:** `stack-in-a-box` (Plan 5) · sibling `oxygen-mvp` (Plan 47)
**Prompt:** [`plan-05-approach-reference-standard.md`](plan-05-approach-reference-standard.md)
**PR (this repo):** https://github.com/ironmonkey88/stack-in-a-box/pull/8
**PR (sibling):** https://github.com/ironmonkey88/oxygen-mvp/pull/78

---

## Outcome

`APPROACH.md` now exists at the root of both repos, byte-identical, as the
plain-language **reference standard** for how the project works. In this repo it
is framed as a cross-repo shared artifact (same posture as `METHODOLOGY.md`),
sitting above `PHILOSOPHY.md` — which is this repo's specialization of the
standard.

## What shipped (this repo)

- `APPROACH.md` (new, root) — canonical merged body, identical to oxygen-mvp's.
- `CLAUDE.md` — new "Reference standard (cross-repo, above the convictions)"
  tier above the Convictions block; states the reconciliation rule and that
  PHILOSOPHY.md specializes the standard.
- `session-starter.md` (**new** — this repo had none) — Chat-side orientation
  mirroring oxygen-mvp's, adapted to this repo (NYC 311 smoke, the
  install-orient/closing-ritual discipline, the independent plan ledger),
  carrying APPROACH/PHILOSOPHY/METHODOLOGY pointers.
- `LOG.md` — Plans Registry Plan 5 row + Last Updated.
- `TASKS.md` — Plan 5 done entry + Plans Registry row.
- `docs/prompts/plan-05-approach-reference-standard.{md,report.md}` — prompt
  (Phase 0) + this report.

## Decisions

- **Plan numbers** — this repo **5** (Plans 1–3 done; **Plan 4 already
  reserved/in-flight** as `claude/plan-04-pin-gates-lockaware`, the Oxygen
  version pin — so 4 was not free); sibling oxygen-mvp **47**. Not ambiguous;
  plan-number halt did not fire.
- **Branch base** — created off `origin/main`, independent of and parallel to
  the unmerged Plan 4 branch. Plan 5 is documentation-only and does not depend
  on Plan 4; the registry row notes the parallel state.
- **Canonical body delivery** — the prompt's "Canonical content" section was a
  placeholder; the body arrived separately in Chat alongside an aligned Google
  Doc ("How-We-Build-Summary").
- **Merge (Gordon-approved)** — pasted body as base (keeps the closing
  reconciliation paragraph) + the Google Doc's newcomer "start here" intro line;
  title kept per Phase 0. Single human-approved deviation from pure-verbatim.
- **session-starter.md creation (Gordon-approved)** — the prompt's Work item 4
  anticipated "or nearest equivalent"; Gordon directed creating a real
  `session-starter.md` here rather than wiring the pointer into CLAUDE.md alone.

## Verification (all static-artifact gates)

- `APPROACH.md` at both repo roots, identical body — `diff` returned empty.
- `CLAUDE.md` references APPROACH.md at the correct tier (above PHILOSOPHY.md).
- `session-starter.md` created and references APPROACH.md.
- No existing doc edited beyond the named wiring sites.
- LOG.md + TASKS.md updated.
- **Contradiction halt check:** `PHILOSOPHY.md` and `METHODOLOGY.md` read in full
  and found compatible — no principle stated in conflict. Halt did not fire.

No live-functional gates — nothing executes.

## Out of scope (separate already-scoped prompts)

PHILOSOPHY.md / METHODOLOGY.md edits; the empathy/honesty/optimism creed; the
Sensemake/system-humanism methodology work. No `.docx`/export tooling.

## Next action

Both repos' PRs merge in parallel. This repo's **next plan is unchanged: Plan 4**
(Oxygen 0.5.54 pin + backlog B/C/D + clean from-scratch install confirmation).
