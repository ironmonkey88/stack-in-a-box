# Report — Plan 7: Add R5–R8 to METHODOLOGY.md (Sensemake, system-humanism build-discipline, declarative/reconciliation)

**Status:** complete
**Date:** 2026-06-10
**Repo:** `stack-in-a-box`
**Prompt:** [`plan-07-methodology-reasoning-rules.md`](plan-07-methodology-reasoning-rules.md)
**PR:** https://github.com/ironmonkey88/stack-in-a-box/pull/11

---

## Outcome

`METHODOLOGY.md` now carries the reasoning-and-build disciplines from the design
session as testable rules in the existing Rule / Origin / Sync form. The rules
layer now enforces the disciplines `APPROACH.md` only names — the trust
contract's reasoning gate (R5), the constrained-agent build pattern (R6), and the
desired-state posture (R7/R8). They're recorded as pending propagation to a
future oxygen-mvp METHODOLOGY.md.

## What shipped

- `METHODOLOGY.md` — four new rules after R4:
  - **R5** — hypothesis/result two-tier gate (Sensemake; labels never strip).
  - **R6** — manufacture operator expertise behind a constrained agent surface
    (system-humanism build half; conviction half stays in PHILOSOPHY.md).
  - **R7** — declarative/desired-state first; reconcile actual to desired.
  - **R8** — keep desired-state specs idempotent (split from R7).
  - Each: Origin = design session 2026-06-10, ratified by Gordon, not yet
    exercised in a plan; Sync = `stack-only`.
  - Framing line above R1 distinguishing R1–R4 (field experience) from R5–R8
    (design-ratified).
  - Four matching rows in the Pending propagation table.
- `LOG.md` — Plans Registry Plan 7 row + Last Updated.
- `TASKS.md` — Plan 7 done entry + registry row.
- `docs/prompts/plan-07-methodology-reasoning-rules.{md,report.md}` — prompt +
  this report.

## Decisions

- **Plan number → 7.** Boot audit first (`gh pr list --state all`): Plans
  1/2/3/5/6 done (Plan 6 = the Prompt B creed, merged just before), Plan 4 the
  in-flight reserved branch; nothing claims 7. Run sequentially after Plan 6 (off
  the post-Plan-6 `main`) so LOG/TASKS didn't conflict. Unambiguous; halt did not
  fire.
- **R7 split into R7 + R8.** Per Work-item-1's option: idempotency is a distinct,
  separately-testable property and stands alone better than bundled. R7 =
  declarative/desired-state + reconciliation (+ the don't-over-rotate and
  capability-to-scope caveats); R8 = idempotency. Four new rules, R5–R8.
- **Rule bodies are denser than R1, in the spirit of R2.** R5–R7 carry their
  failure-mode and "why" inline (as the prompt's halt note permits, citing R2);
  this keeps them genuinely hand-off-able rather than lossy one-liners.

## Verification (all static-artifact gates)

- R5–R8 present, each with Rule / Origin / Sync matching the R1–R4 format — ✓.
- Each new rule's Sync is `stack-only` and has a matching Pending-propagation row
  — ✓ (four rows added).
- **R1–R4 unchanged** — ✓. `git diff` shows only: the framing line above R1, the
  R5–R8 block after R4, and the four propagation rows. No R1–R4 text touched.
- Rules are imperative and context-free (the "hand to someone with no context"
  test) — ✓.
- LOG.md / TASKS.md updated — ✓.

No live-functional gates.

## Out of scope (honored)

- No PHILOSOPHY.md edits (creed work was Plans 6/49); no system-humanism split in
  oxygen-mvp (deferred — R6 is its future destination); no oxygen-mvp
  METHODOLOGY.md instantiation; no changes to the sync *procedure* section (only
  the Rules section + propagation table).

## Next action

None required. When oxygen-mvp gets a METHODOLOGY.md (a separately-scoped future
plan), R5–R8 carry over per the propagation rows — and R6 is where oxygen-mvp's
deferred system-humanism build-discipline split will land.
