# Prompt — Land the desktop/local-analytics-app MVP-0 concept writeup

**Kind:** coding
**Date:** 2026-06-17
**Scope:** `stack-in-a-box` — new `docs/concepts/` directory + `docs/concepts/README.md` (directory purpose) + `docs/concepts/local-analytics-app-mvp0.md` (the concept); pointer wiring in `session-starter.md`; LOG.md / TASKS.md updates per repo convention.
**Effort:** ~1 session (documentation + wiring; no code, no live gates).
**Depends on:** none. (The concept itself depends on stack-in-a-box Plan 3 being resolved before it becomes a plan — but *documenting* it does not.)

---

## Phase 0 — write this prompt to the repo first (do this before any other work)

Before any other work, write this prompt **verbatim** to
`docs/prompts/plan-NN-local-analytics-app-concept.md` on a new branch
`claude/plan-NN-local-analytics-app-concept`. This file write is the first
commit on the branch. All subsequent phases proceed against that branch.

**Plan number:** claim the next available plan slot per `stack-in-a-box`'s
LOG.md Plans Registry at fire time — resolve `NN` before branching; do not
assume a number. Boot-audit the registry first; respect reserved-but-unused
slots. If the next contiguous slot is ambiguous, halt and surface before
branching.

The MCP-direct-commit path is paused; Code owns prompt-file creation.

---

## Outcome (required)

The desktop/local single-user analytics application concept — worked out in full
in a Chat product-design session and currently living only in that thread — gets
preserved in the repo as a **concept document**, not a plan. It is explicitly
**not-a-plan**: it must not be numbered in either repo's plan sequence and must
not be started until stack-in-a-box Plan 3 (first real EC2 install) is fully
resolved. The document captures the MVP-0 framing and every design decision the
session reached, so the idea survives the account migration and can be picked up
deliberately when the time comes.

A new `docs/concepts/` directory is established (it does not yet exist in this
repo) as the home for downstream-leaf and future-product concepts that aren't
yet plans — this concept is its first inhabitant.

## Context (conditional)

- **This is a transcription/reconstruction of a completed design session.** The
  decisions below are settled; render them faithfully. Where the writeup needs
  connective prose, keep it minimal and plain — the value is the decisions, not
  new framing.
- **The concept, in one line:** a local, single-user analytics application for a
  smart, IT-literate but non-developer analyst (sales analysts, non-profit
  budgeting volunteers, social-media trackers) — persistent multi-source data
  with descriptive Q&A plus correlation, where the product works *without the
  operator in the loop* because the operator's expertise has been decomposed and
  manufactured into the product.
- **The kill-test it must answer** ("why is this more than Claude + a
  spreadsheet?"): persistence, multi-source reconciliation, and repeatability.
- **MVP-0 framing (the thing to prove first):** a constrained agent + an authored
  spine clears the trust bar on *simple* tasks (drag in a spreadsheet, pull from
  an open API, produce a report) *without the operator present* — before
  building anything more complex.
- **The settled design decisions to capture (each as a short entry):**
  1. **DuckDB** as the single-file persistent store.
  2. A **pluggable connector seam** with two connector kinds: file-drop and
     API-pull.
  3. **dlt reserved specifically for stateful incremental API connectors** (not
     used for the simple file-drop path).
  4. A **semantic layer doing cross-source reconciliation** with human-confirmed
     mappings — this is both the product differentiator and the
     operator-replacement rail.
  5. The **trust contract extended with a freshness / as-of field** for
     pipeline-sourced metrics.
  6. **Correlation deferred**, with n-aware guardrails planned for when it lands.
  7. **Pasted API key behind a swappable seam** (so the credential path can be
     replaced later without reworking connectors).
  8. **Python + local web UI** with an in-app, on-demand worker as the runtime
     lean.
  9. A **domain-neutral (not domain-specific) authored guidance spine** for the
     first cut.
  10. The **operator-in-the-loop insight**: the product only works today because
      the operator is present; MVP-0 exists to prove that expertise can be
      manufactured into the product as (a) a domain-neutral authored spine, (b)
      structural verification, and (c) a constrained agent surface.
- **Relationship to the repos:** this is a downstream-leaf product concept. Per
  the settled three-repo architecture, a future Personal Data Warehouse / local
  app consumes freely from stack-in-a-box but contributes back only via
  occasional deliberate architecture-level harvesting, not continuous sync. State
  this relationship in the doc.

## Work (required)

1. **Create `docs/concepts/` with a `README.md`** stating the directory's
   purpose: a home for future-product and downstream-leaf concepts that are
   **not-a-plan** — documented so they survive, explicitly excluded from the
   plan sequence until promoted. One short paragraph plus a one-line index of
   the concepts within.
2. **Create `docs/concepts/local-analytics-app-mvp0.md`** capturing the concept:
   a short intro (the one-line concept + target user + kill-test), the MVP-0
   framing, the 10 settled decisions as terse entries, the operator-in-the-loop
   insight as the load-bearing rationale, and an explicit **"Status:
   not-a-plan"** banner naming the gate (not started until stack-in-a-box Plan 3
   resolved; not numbered in either plan sequence).
3. **Wire `session-starter.md`**: a one-line pointer to `docs/concepts/` under
   "Key Files to Know" (or nearest equivalent), framed so Chat knows concepts
   live there but are not active plans.
4. **LOG.md + TASKS.md** updates per repo convention — recording this as a
   documentation plan that *lands a concept*, and being careful that the LOG/
   TASKS entries do **not** add the concept itself to the plan sequence or the
   active task list. (The plan that lands the doc is numbered; the concept it
   documents is not.)

## Verification (required)

Static-artifact gates (documentation change; all gates are static):

- `docs/concepts/README.md` and `docs/concepts/local-analytics-app-mvp0.md` both
  exist.
- The concept doc carries the explicit "not-a-plan" status banner with the Plan-3
  gate named.
- All 10 settled decisions are present.
- `session-starter.md` references `docs/concepts/`.
- LOG.md / TASKS.md updated **without** adding the concept to the plan sequence
  or active tasks.

No live-functional gates — nothing executes.

## Halt conditions (conditional)

- If the next plan number is ambiguous in the registry, surface and ask rather
  than guessing.
- If landing this in LOG.md/TASKS.md cannot be done without implying the concept
  is an active plan under that repo's conventions, **halt and surface** — the
  not-a-plan status is load-bearing and must not be compromised by the
  bookkeeping.

## Out of scope (conditional)

- **No build artifacts.** No code, no scaffold, no `apps/` entry, no scripts.
  This is a concept document only.
- No promotion of the concept to a plan in either repo.
- No `.docx` export.
- Not landed in oxygen-mvp.

## Commit shape (required)

- Phase 0 prompt-file write is commit 1 on the branch.
- Then: `docs/concepts/README.md`, then the concept doc, then session-starter
  wiring, then LOG/TASKS — committed per Work item.
- Commit messages name the plan number.
- One PR. Open it when the first commit lands; merge when Verification passes.
- Write the report to the sibling
  `docs/prompts/plan-NN-local-analytics-app-concept.report.md` before merge.
