# Prompt — Land the APPROACH-session design-reasoning ("breadcrumbs") doc

**Kind:** coding
**Date:** 2026-06-17
**Scope:** `stack-in-a-box` — new `docs/design/APPROACH_DESIGN_REASONING.md`; pointer wiring in `APPROACH.md` (a single "provenance" footer line) and `session-starter.md`; LOG.md / TASKS.md updates per repo convention.
**Effort:** ~1 session (documentation + wiring; no code, no live gates).
**Depends on:** APPROACH.md (Plan 5, already merged) — this doc references it.

---

## Phase 0 — write this prompt to the repo first (do this before any other work)

Before any other work, write this prompt **verbatim** to
`docs/prompts/plan-NN-approach-design-reasoning.md` on a new branch
`claude/plan-NN-approach-design-reasoning`. This file write is the first commit
on the branch. All subsequent phases proceed against that branch.

**Plan number:** claim the next available plan slot per `stack-in-a-box`'s
LOG.md Plans Registry at fire time — resolve `NN` before branching; do not
assume a number. Boot-audit the registry first; respect reserved-but-unused
slots. If the next contiguous slot is ambiguous, halt and surface before
branching.

The MCP-direct-commit path is paused; Code owns prompt-file creation.

---

## Outcome (required)

The reasoning *behind* APPROACH.md gets preserved in the repo. `APPROACH.md`
itself is deliberately implementation-free and short; it states *what* we
believe and *how* we work but not *why each choice was made the way it was* or
*what alternatives were considered and rejected*. That design reasoning was
worked out in Chat during the APPROACH.md authoring session and currently lives
only in a chat thread — which an account migration would strand. This doc is the
"breadcrumbs": the design-reasoning companion to APPROACH.md, so that a future
reader (or a future Chat reconsidering a principle) can see the road that led to
the standard, not just the standard.

This lives in `stack-in-a-box` only (not both repos): it is reasoning about the
cross-repo standard, and one home for it is correct — duplicating evolving
reasoning across repos invites drift. APPROACH.md gets a one-line provenance
pointer to it.

## Context (conditional)

- **This doc must be reconstructed, not transcribed.** Unlike APPROACH.md and
  the migration summary, the full breadcrumbs text was not preserved as a clean
  canonical body. Reconstruct it from the durable sources listed below, and
  **mark it clearly as reconstructed** (a `**Status:** reconstructed` note at the
  top, exactly as the Plan 43 backfilled prompts in oxygen-mvp did). Do not
  fabricate reasoning that isn't supported by a source; where a rationale is
  uncertain, say so.
- **Sources to reconstruct from (all already in the repos):**
  - `APPROACH.md` (both repos, byte-identical) — the standard itself; each
    section's existence implies a choice worth documenting.
  - `stack-in-a-box/docs/prompts/plan-05-approach-reference-standard.md` and its
    `.report.md` — the prompt, the four in-session resolutions (plan numbers,
    canonical-body merge decision, session-starter creation, contradiction
    halt-check), and the merge rationale (pasted body + Google Doc intro line).
  - `stack-in-a-box/METHODOLOGY.md` rules R5–R8 and their Origin/Sync rows — the
    design session that ratified hypothesis/result (R5), system-humanism build
    half (R6), declarative/reconciliation (R7), idempotency (R8). The Origin
    rows name the 2026-06-10 design session.
  - `stack-in-a-box/PHILOSOPHY.md` and `oxygen-mvp/PHILOSOPHY.md` creed sections
    — the empathy/honesty/optimism framing and its cross-references.
  - `oxygen-mvp` Plan 48 + Plan 49 LOG.md registry rows — the renumbering
    history (47 → 48 collision with PR #76) and the §3/§6.6 reconciliation.
- **The reasoning the doc should capture** (each as a short "decision → why →
  alternatives considered" entry, drawn from the sources above):
  1. Why APPROACH.md sits **above** PHILOSOPHY.md and is implementation-free
     (reference standard others reconcile against; tool/dataset-agnostic so it
     survives stack evolution).
  2. Why the three-term creed is **empathy / honesty / optimism** specifically,
     and why honesty is "the constraint the other two answer to."
  3. Why **optimism** is framed as correcting a *structural* negativity bias in
     complaint/incident feeds — "honest reporting, not editorializing."
  4. Why **hypothesis/result** terminology was chosen over more technical
     framings (reader self-explanatoriness).
  5. Why **system humanism** was split — build-discipline half to METHODOLOGY,
     conviction half to PHILOSOPHY.
  6. Why **declarative-first** is framed as an *accessibility strategy* (engineered
     outcome, not a property of the tool), and the airplane/elevator/oncology
     ladder as its canonical illustration.
  7. Why the **capability-to-scope law** unifies Situational Leadership,
     hardware-abstraction tradeoffs, and control-theory altitude.
  8. The **R7 → R7/R8 split** rationale (declarative/reconciliation and
     idempotency as separately-testable properties).
- If a worked illustration helps (it does for #6), reuse the
  airplane/elevator/oncology ladder already named in APPROACH.md rather than
  inventing a new one.

## Work (required)

1. **Create `docs/design/APPROACH_DESIGN_REASONING.md`** in `stack-in-a-box`,
   reconstructed from the sources above, with a `**Status:** reconstructed` note
   and a one-line list of the sources it was built from. Structure it as a short
   intro + one entry per decision (8 entries above), each in "decision → why →
   alternatives considered / rejected" shape. Plain language; same register as
   APPROACH.md.
2. **Add a provenance footer to `APPROACH.md`** (stack-in-a-box copy only for
   now — see Halt conditions re: the byte-identical constraint): a single line
   at the end pointing to the design-reasoning doc, e.g. "For the reasoning
   behind these choices, see `docs/design/APPROACH_DESIGN_REASONING.md`."
3. **Wire `session-starter.md`**: a one-line pointer under "Key Files to Know"
   (or nearest equivalent).
4. **LOG.md + TASKS.md** updates per repo convention.

## Verification (required)

Static-artifact gates (documentation change; all gates are static):

- `docs/design/APPROACH_DESIGN_REASONING.md` exists, carries the
  `**Status:** reconstructed` note, lists its sources, and contains the 8
  decision entries.
- Every rationale in the doc is traceable to one of the named sources; no
  unsupported claims (spot-check by re-reading the cited source for 2–3
  entries).
- `session-starter.md` references the new doc.
- LOG.md and TASKS.md updated.

No live-functional gates — nothing executes.

## Halt conditions (conditional)

- **The byte-identical APPROACH.md constraint.** APPROACH.md is currently
  byte-identical across both repos. Adding the provenance footer to the
  stack-in-a-box copy breaks that. **Halt and surface before doing Work item 2**:
  present two options to Gordon — (a) add the footer to *both* repos' APPROACH.md
  to preserve byte-identity (the doc itself stays stack-in-a-box-only; only the
  pointer is duplicated), or (b) accept a one-line divergence between the two
  APPROACH.md copies. Do not pick unilaterally; this is a cross-repo-standard
  judgment call that is Gordon's.
- If the next plan number is ambiguous in the registry, surface and ask rather
  than guessing.
- If reconstruction cannot support one of the 8 decision entries from the named
  sources, **do not invent the rationale** — land the entry with an explicit
  "rationale not recoverable from repo sources; flagged for Gordon to fill"
  note, and surface it in the report.

## Out of scope (conditional)

- No edits to PHILOSOPHY.md, METHODOLOGY.md, or the creed/principles themselves —
  this doc *documents* the reasoning, it does not change any standard.
- No `.docx` / Google Doc export.
- Not landed in oxygen-mvp (single home by design), except for the APPROACH.md
  footer if Gordon picks option (a) above.

## Commit shape (required)

- Phase 0 prompt-file write is commit 1 on the branch.
- Then: the design-reasoning doc, then the APPROACH.md footer (per the resolved
  halt-condition decision), then session-starter wiring, then LOG/TASKS —
  committed per Work item.
- Commit messages name the plan number.
- One PR. Open it when the first commit lands; merge when Verification passes.
- Write the report to the sibling
  `docs/prompts/plan-NN-approach-design-reasoning.report.md` before merge,
  recording which halt-condition option Gordon chose and any entries flagged as
  not-recoverable.
