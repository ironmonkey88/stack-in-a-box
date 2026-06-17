# Local Analytics App — MVP-0 Concept

> **Status: not-a-plan.** This is a concept document, not an active plan. It is
> **not** numbered in either repo's Plans Registry and is **not** on the active
> task list. It is **not to be started until stack-in-a-box Plan 3 (first real
> EC2 install) is fully resolved.** When the time comes, it must be deliberately
> *promoted* to a plan; until then it lives here as preserved thinking only.

A single-user, local analytics application worked out in full in a Chat
product-design session. This document captures the MVP-0 framing and the settled
design decisions so the idea survives; it does not start the work.

## The concept in one line

A **local, single-user analytics application** for a smart, IT-literate but
**non-developer** analyst — persistent multi-source data with descriptive Q&A
plus correlation, where the product works *without the operator in the loop*
because the operator's expertise has been decomposed and manufactured into the
product.

**Who it's for:** people like sales analysts, non-profit budgeting volunteers,
and social-media trackers — capable with a computer, but not engineers, and
without a data team behind them.

## The kill-test

The concept has to answer one question to justify existing: *why is this more
than Claude + a spreadsheet?* Three properties are the answer:

- **Persistence** — data accumulates over time in a real store, not re-pasted
  each session.
- **Multi-source reconciliation** — separate sources are joined on
  human-confirmed mappings, not eyeballed.
- **Repeatability** — the same question, the same pipeline, gives the same answer
  again next week.

If a feature doesn't serve persistence, reconciliation, or repeatability, it
isn't what makes this more than a chat window over a spreadsheet.

## MVP-0 framing — the thing to prove first

Before building anything complex, prove the smallest load-bearing claim: a
**constrained agent + an authored spine** clears the trust bar on *simple* tasks
— drag in a spreadsheet, pull from an open API, produce a report — **without the
operator present**. MVP-0 is that proof, nothing more. Everything richer waits
behind it.

## Settled design decisions

1. **DuckDB as the single-file persistent store.** One local file is the
   warehouse; it's what makes persistence cheap and portable.
2. **A pluggable connector seam, two connector kinds.** Sources enter through a
   defined seam with two shapes: **file-drop** (drag in a spreadsheet/CSV) and
   **API-pull**.
3. **dlt reserved specifically for stateful incremental API connectors.** dlt is
   used where incremental state matters (the API-pull path), **not** for the
   simple file-drop path, which needs no incremental machinery.
4. **A semantic layer that does cross-source reconciliation, with
   human-confirmed mappings.** This is both the product differentiator and the
   operator-replacement rail: the layer proposes how sources line up; the human
   confirms the mappings once; the reconciliation then runs repeatably.
5. **The trust contract extended with a freshness / as-of field.** For
   pipeline-sourced metrics, the answer carries *when* the data is current as
   of, alongside the existing query/rows/citations/limitations evidence.
6. **Correlation deferred — with n-aware guardrails planned.** Correlation is not
   in the first cut; when it lands it ships with guardrails that account for
   sample size (n-aware), so the product doesn't assert relationships the data
   can't support.
7. **Pasted API key behind a swappable seam.** The first credential path is a
   pasted key, but isolated behind a seam so it can be replaced later (OAuth,
   secret store, etc.) without reworking the connectors.
8. **Python + a local web UI, with an in-app on-demand worker.** The runtime lean
   is Python plus a local web UI; work runs in an in-app, on-demand worker rather
   than a standing service.
9. **A domain-neutral authored guidance spine for the first cut.** The authored
   spine is deliberately *domain-neutral* (not tailored to sales, budgeting, etc.)
   for v1 — generality first, domain specialization later if warranted.
10. **The operator-in-the-loop insight (load-bearing).** Today the product only
    works because the operator is present, supplying judgment. MVP-0 exists to
    prove that this expertise can be **manufactured into the product** as three
    things: (a) a domain-neutral authored spine, (b) structural verification, and
    (c) a constrained agent surface. This is the same rule as `METHODOLOGY.md`
    R6 — *manufacture operator expertise into the product behind a constrained
    agent surface* — applied as a whole product thesis.

## Why the operator-in-the-loop insight is the point

Decisions 1–9 are the *how*; decision 10 is the *why it's hard and why it
matters*. A capable analyst sitting at the keyboard can already get good answers
out of a chat tool — the hard part is making the product trustworthy when that
analyst is **not** there. The three replacements (authored spine, structural
verification, constrained agent surface) are how the operator's judgment is
decomposed and rebuilt inside the product. MVP-0 is the smallest test of whether
that decomposition holds.

## Relationship to the repos

This is a **downstream-leaf product concept**. Under the settled three-repo
architecture, a future Personal Data Warehouse / local app **consumes freely**
from `stack-in-a-box` but **contributes back only via occasional, deliberate
architecture-level harvesting** — not continuous sync. So this concept can draw
on stack-in-a-box's proven patterns (DuckDB store, connector discipline,
reconciling semantic layer, the trust contract) without creating an ongoing
coupling that would drag on either side. It lives as a concept here precisely
because it is *about* a leaf that doesn't exist yet, not a plan for this repo.

---

*If and when stack-in-a-box Plan 3 is fully resolved and this concept is taken
up, promote it deliberately: give it a plan number in the owning repo's Plans
Registry, move it onto the active task list, and supersede this not-a-plan banner
with a pointer to the plan.*
