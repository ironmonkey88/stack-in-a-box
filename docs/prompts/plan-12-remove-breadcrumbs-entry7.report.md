# Report — Plan 12: remove breadcrumbs entry 7 (+ cancel §11 appendix)

**Status:** complete
**Date:** 2026-06-19
**Repo:** `stack-in-a-box` only.
**PR:** [#16](https://github.com/ironmonkey88/stack-in-a-box/pull/16)

This plan covers the two-part disposition instruction from Gordon: **(1)** cancel the migration-summary §11 appendix prompt, and **(2)** remove Plan 9's entry 7 from the breadcrumbs doc.

## Part 1 — CANCEL the §11 appendix prompt (nothing to do)

The migration-summary §11 "Operator migration actions" appendix prompt **was never written**. Verified across both repos:
- No `docs/prompts/*appendix*` file in `stack-in-a-box` or `oxygen-mvp`.
- No `*appendix*` branch (local or `git ls-remote` on origin) in either repo.
- No PR with "appendix" in the title (`gh pr list --state all`) in either repo.
- `docs/MIGRATION_SUMMARY.md` is unmodified in both repos.

So the cancellation required no action — nothing to delete, close, or revert. (Had it already merged, the instruction's path was to surface before reverting; that path was not reached.)

## Part 2 — REMOVE breadcrumbs entry 7

Slot: boot-audit of the stack-in-a-box Plans Registry — highest used = **11** (the instruction's "now at Plan 10 → 11" predated Plan 11 merging), Plan 4 reserved/in-flight → **12** next contiguous free. No ambiguity; halt did not fire.

### What changed
- Removed former **entry 7** ("Why the capability-to-scope law unifies several framings") from `docs/design/APPROACH_DESIGN_REASONING.md` — including its "Sourcing note" paragraph, which was the soft-sourced control-theory-altitude / hardware-abstraction claim Plan 9's report flagged.
- Renumbered former **entry 8** (R7/R8 split) → **entry 7** so the numbered headings stay contiguous **1–7**. This is a mechanical heading-number change only; no entry's reasoning content was altered.

### Verification (all static)
- The entry-7 / broader-unification block is gone — `grep` for `capability-to-scope` returns **0** matches in the doc. ✅
- Numbered headings are now contiguous **1–7** (no gap, no duplicate). ✅
- No dangling references: the capability-to-scope law was not cross-referenced by any other entry (entry 2's "#3" points at optimism, unaffected). ✅
- The doc intro states **no** entry count (it says "the entries below"), so there was no in-doc count to update. ✅
- `Status: reconstructed` note and the "Reconstructed from:" source list are intact (still accurate). ✅
- Rest of the doc unchanged (only the §7 block removed and §8→§7 heading bumped). ✅
- LOG.md + TASKS.md updated. ✅

### Decisions / notes
- **Renumber vs. leave a gap:** chose to renumber 8→7 for a coherent doc; a "1–6, 8" gap would read as an error. Mechanical only — no content rewrite — so the "rest of the doc unchanged" gate holds in substance.
- **Plan 9's historical record left intact:** Plan 9's LOG/TASKS registry rows still say it landed "8 decision entries" — that accurately records what Plan 9 did at the time. Plan 12 is the entry that records the removal; rewriting Plan 9's row would falsify history.

### Halt conditions
Neither fired. Plan number unambiguous; removing entry 7 left no other entry incoherent (entries 6 and the R7/R8 entry are independent of the capability-to-scope law).

### Out of scope (honored)
No change to `APPROACH.md`, `PHILOSOPHY.md`, or `METHODOLOGY.md` — the capability-to-scope law stays where it is validly attested (APPROACH.md "How much to specify depends on the builder"; METHODOLOGY R7). stack-in-a-box only.
