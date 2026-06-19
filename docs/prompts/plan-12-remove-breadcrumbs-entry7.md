# Instruction — Remove Plan 9 entry 7 from the breadcrumbs doc

*This prompt file captures the relevant (Part 2) section of a two-part disposition
instruction from Gordon. Part 1 of that instruction — cancelling the
migration-summary §11 appendix prompt — required no repo artifact (the appendix
prompt was never written; nothing to revert) and so has no Phase-0 file of its
own; its disposition is recorded in this plan's report.*

---

## 2. REMOVE — Plan 9 entry 7 from the breadcrumbs doc

In `stack-in-a-box/docs/design/APPROACH_DESIGN_REASONING.md`, **remove the
entry covering the capability-to-scope law's broader unification** (the
decision→why→alternatives entry that Plan 9's report flagged as only lightly
attested in the core docs — the control-theory-altitude / hardware-abstraction
unification, "entry 7").

**Reason:** Gordon's call. The broader unification was the one soft-sourced claim
in the reconstruction; rather than carry it with a sourcing caveat, drop it. The
capability-to-scope *law itself* remains valid where it's actually attested
(agent design, system architecture, human delegation) — only the under-sourced
*broader-unification* entry in the reasoning doc is removed.

**Action (normal plan discipline):**

### Phase 0
Write this instruction's relevant section verbatim to
`docs/prompts/plan-NN-remove-breadcrumbs-entry7.md` on a new branch
`claude/plan-NN-remove-breadcrumbs-entry7`, as commit 1. Claim `NN` from the
stack-in-a-box LOG.md Plans Registry (now at Plan 10 → next is 11; boot-audit to
confirm, don't assume). Halt and surface if ambiguous.

### Work
1. Remove the entry-7 block from `docs/design/APPROACH_DESIGN_REASONING.md`.
2. If the doc's intro states a decision-entry count (e.g. "8 decision entries"),
   update it to match the new count.
3. If any other entry cross-references entry 7, fix or remove the dangling
   reference.
4. Leave the `Status: reconstructed` note and source list intact (still accurate).
5. LOG.md / TASKS.md per repo convention.

### Verification
- The entry-7 / broader-unification block is gone.
- No dangling references to it remain; any stated entry count matches reality.
- The rest of the doc is unchanged.
- LOG.md / TASKS.md updated.

### Halt conditions
- If removing entry 7 would leave another entry incoherent (e.g. it builds on
  entry 7), surface before deleting rather than cascading edits silently.
- If the plan number is ambiguous, surface and ask.

### Out of scope
- No change to APPROACH.md itself, to PHILOSOPHY.md, or to METHODOLOGY.md — the
  capability-to-scope law stays where it's validly attested. Only the breadcrumbs
  doc's under-sourced entry is removed.
- stack-in-a-box only (the breadcrumbs doc is single-home there).

### Commit shape
- Phase 0 prompt-file write is commit 1.
- Then the doc edit, then LOG/TASKS.
- One PR. Report at `docs/prompts/plan-NN-remove-breadcrumbs-entry7.report.md`
  before merge.
