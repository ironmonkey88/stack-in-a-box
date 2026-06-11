# Prompt B — Add the empathy/honesty/optimism creed to stack-in-a-box/PHILOSOPHY.md

**Kind:** coding (documentation)
**Repo:** `stack-in-a-box`
**Scope:** `PHILOSOPHY.md` only, plus LOG.md / TASKS.md per convention.
**Effort:** ~half a session. No code, no live gates.
**Depends on:** APPROACH.md (already landed, Plan 5).

---

## Phase 0 — write this prompt to the repo first

Before any other work, write this prompt **verbatim** to
`docs/prompts/plan-NN-philosophy-creed.md` on a new branch
`claude/plan-NN-philosophy-creed`. This file write is the first commit on the
branch. All subsequent phases proceed against that branch.

**Plan number:** claim the next available stack-in-a-box slot from LOG.md's Plans
Registry at fire time (the repo is at Plan 5). **Audit open/recent PRs**
(`gh pr list --state all`) before claiming, to confirm the slot is free. Resolve
`NN` before branching.

MCP-direct-commit path is paused; Code owns prompt-file creation.

---

## Outcome (required)

`stack-in-a-box/PHILOSOPHY.md` gains the **empathy / honesty / optimism creed**
as a framing principle, consistent with the reference standard (`APPROACH.md`)
that now sits above it. This is a light addition, not a restructuring: the doc's
existing seven principles (§1–§7) already carry honesty (§4), the trust contract
(§6), and boundary constraints (§7); what's missing is the named three-word creed
that ties them to the cross-repo standard. After this, a reader of the generic
template doc sees the same central conviction — stated in the same terms — as
APPROACH.md.

## Context (conditional)

- **This is the generic, dataset-agnostic doc.** Unlike oxygen-mvp's PHILOSOPHY,
  it has no "three inspirations," no Somerville framing, no system humanism — it
  opens by saying its principles are "properties of any honest data platform, not
  specific to a particular dataset or domain." So this is purely additive: there
  is **no system-humanism split to perform here** (nothing to split) and no
  Somerville-specific language to generalize.
- **The creed in APPROACH.md** (the "What we believe" section): empathy = the
  answer must fit the person and situation, so context is part of correctness;
  honesty = the rule the other two answer to, every answer carries its evidence;
  optimism = earned, a conclusion the evidence supports, correcting the negativity
  bias a complaint/incident feed inherits by construction.
- **Where it fits.** The creed is the *why* beneath several existing principles,
  so it reads best as an early framing principle (a new §0 or §1-prime, or folded
  into the doc's short intro) that the later numbered principles then implement:
  honesty → §4 honest reporting + §6 trust contract; empathy → the "answers carry
  the question's context" point already in §1; optimism → (the one genuinely new
  idea for this doc) the deliberate surfacing of progress against a
  problem-skewed source. Use judgment on exact placement; match the doc's terse,
  principle-first voice.
- **Wiring is already done.** APPROACH.md is referenced from CLAUDE.md and
  session-starter as the reference standard this doc specializes. Don't re-add
  pointers.

## Work (required)

1. **Add the creed** as a framing principle near the top of PHILOSOPHY.md
   (before or as part of §1), naming empathy / honesty / optimism and one line
   each on what each means, in the doc's existing generic register (no Somerville,
   no dataset specifics).
2. **Lightly cross-reference** the existing principles the creed frames — e.g. a
   clause noting honesty is carried by §4/§6, empathy by §1's facts-vs-answers
   point. Keep it light; don't renumber or restructure §1–§7.
3. **The optimism term is the one new idea** for this doc — state it as a general
   property (a platform built on incident/complaint feeds inherits a negativity
   bias by construction, and correcting it by surfacing genuine progress is part
   of honest reporting, not editorializing). Keep it dataset-agnostic.
4. **LOG.md + TASKS.md** per convention.

## Verification (required)

Static-artifact gates:

- PHILOSOPHY.md names empathy, honesty, and optimism as the creed near the top.
- §1–§7 are not renumbered or restructured (verify by diff — additions, not
  rewrites).
- No Somerville-specific or dataset-specific language introduced (this doc stays
  generic).
- LOG.md / TASKS.md updated.

No live-functional gates.

## Halt conditions (conditional)

- If the creed addition would require restructuring §1–§7 to read coherently,
  halt and surface — the intent is a light addition; a restructure is a different,
  larger decision.
- If the plan-number slot is ambiguous after the PR audit, surface and ask.

## Out of scope (conditional)

- No system humanism (it isn't in this doc; do not import it — that lives in
  METHODOLOGY.md per Prompt C).
- No Sensemake / hypothesis-result content (that's METHODOLOGY, Prompt C).
- No renumbering or rewriting of existing principles.
- No edits to STANDARDS.md, CLAUDE.md, or any other doc.

## Commit shape (required)

- Phase 0 prompt-file write is commit 1.
- Then PHILOSOPHY.md edit, then LOG/TASKS (docs commit without a gate).
- One PR; autonomous merge on green per repo policy.
- Step-9 report to sibling `docs/prompts/plan-NN-philosophy-creed.report.md`
  before merge.

---

## Resolution (added by Code at execution, 2026-06-10)

- **Plan number → 6.** Boot audit run first (`gh pr list --state all`): Plans
  1/2/3/5 done, Plan 4 is the in-flight reserved `claude/plan-04-pin-gates-lockaware`
  branch, no PR or branch claims 6 or 7. Prompt C (METHODOLOGY R5–R8) takes the
  adjacent slot **7**; the two were coordinated to avoid collision and are run
  sequentially (B merges before C branches). Slot unambiguous; halt did not fire.
