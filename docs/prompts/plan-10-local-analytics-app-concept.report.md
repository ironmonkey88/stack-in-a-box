# Report — Plan 10: local-analytics-app MVP-0 concept doc

**Status:** complete
**Date:** 2026-06-17
**Repo:** `stack-in-a-box` only.
**PR:** [#14](https://github.com/ironmonkey88/stack-in-a-box/pull/14)

## Plan slot

Boot-audit of the Plans Registry — highest used = 9 (Plan 9 just merged), Plan 4 reserved/in-flight → **10** is the next contiguous free slot. No ambiguity; plan-number halt did not fire.

## What shipped

1. **Phase 0** — this prompt verbatim at `docs/prompts/plan-10-local-analytics-app-concept.md`.
2. **`docs/concepts/` + `README.md`** — new directory established as the home for future-product / downstream-leaf concepts that are not-a-plan, with a one-line index.
3. **`docs/concepts/local-analytics-app-mvp0.md`** — the concept: one-line concept + target user + kill-test, MVP-0 framing, all 10 settled decisions, the operator-in-the-loop insight as load-bearing rationale, the downstream-leaf three-repo relationship, and a "Status: not-a-plan" banner naming the Plan-3 gate.
4. **`session-starter.md`** — pointer to `docs/concepts/` under "Key Files to Know", framed as not-active-plans.
5. **LOG.md + TASKS.md** — Plans Registry rows + Last Updated bump + Next Focus block, all wording the doc-landing plan as numbered while keeping the concept off the plan sequence and active task list.

## Verification (all static — nothing executes)

- `docs/concepts/README.md` and `docs/concepts/local-analytics-app-mvp0.md` both exist. ✅
- Concept doc carries the explicit "Status: not-a-plan" banner with the Plan-3 gate named. ✅
- All 10 settled decisions present (DuckDB store; pluggable connector seam with file-drop + API-pull; dlt reserved for stateful incremental API connectors; reconciling semantic layer with human-confirmed mappings; trust contract + freshness/as-of field; correlation deferred with n-aware guardrails; pasted API key behind a swappable seam; Python + local web UI with in-app on-demand worker; domain-neutral authored spine; operator-in-the-loop insight). ✅
- `session-starter.md` references `docs/concepts/`. ✅
- LOG.md / TASKS.md updated **without** adding the concept to the plan sequence or active tasks — the numbered item is "land the concept doc"; the concept is marked not-a-plan in every entry. ✅

## Halt conditions

Neither fired:
- Plan number unambiguous (10).
- The not-a-plan bookkeeping halt did **not** fire: LOG.md/TASKS.md were landed cleanly by numbering only the doc-landing plan and explicitly marking the documented concept as not-a-plan (not added to the registry or active tasks). No compromise to the load-bearing status was required.

## Out of scope (honored)

No build artifacts (no code/scaffold/`apps/` entry/scripts). No promotion of the concept to a plan. No `.docx`. Nothing landed in oxygen-mvp.
