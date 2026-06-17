# APPROACH.md — Design Reasoning ("breadcrumbs")

**Status:** reconstructed.

This document is a reconstruction, not a transcript. The design reasoning behind
`APPROACH.md` was worked out in a Chat authoring/design session whose full text
was not preserved as a clean canonical body. The entries below were rebuilt from
the durable artifacts those decisions left in the repos. Where a rationale is
well-supported it is stated plainly; where the source only partly supports a
claim, that is said out loud rather than smoothed over. Treat this as a faithful
reconstruction, not a verbatim record.

**Reconstructed from:**

- `APPROACH.md` (this repo and `oxygen-mvp`, byte-identical) — the standard
  itself; each section's existence implies a choice worth documenting.
- `docs/prompts/plan-05-approach-reference-standard.md` and its `.report.md` —
  the prompt and the four in-session resolutions (plan numbers, the
  canonical-body merge, the new `session-starter.md`, the contradiction
  halt-check).
- `METHODOLOGY.md` rules R5–R8 and their Origin/Sync rows — the 2026-06-10 design
  session that ratified hypothesis/result (R5), the system-humanism build half
  (R6), declarative/reconciliation (R7), and idempotency (R8).
- `PHILOSOPHY.md` (this repo) and `oxygen-mvp/PHILOSOPHY.md` creed sections — the
  empathy/honesty/optimism framing and its cross-references.
- `oxygen-mvp` Plan 48 + Plan 49 LOG.md registry rows — the renumbering history
  (47 → 48, collision with PR #76) and the §3/§6.6 creed reconciliation.

**What this is for.** `APPROACH.md` is deliberately short and
implementation-free: it states *what* we believe and *how* we work, not *why
each choice was made the way it was* or *what was considered and rejected*. This
companion holds that missing layer, so a future reader — or a future Chat
reconsidering a principle — can see the road that led to the standard, not just
the standard. It documents reasoning; it does not change any standard.

---

## 1. Why APPROACH.md sits above PHILOSOPHY.md and is implementation-free

**Decision.** Make `APPROACH.md` a single cross-repo **reference standard** that
sits *above* `PHILOSOPHY.md`, byte-identical in both repos, and keep it free of
tools and implementation detail.

**Why.** The principles of how we work are more durable than any tool or dataset
we use to express them. Pinning them to a layer that deliberately omits tools
means the standard survives stack evolution: DuckDB, dlt, dbt, Oxygen can all be
replaced without touching it. Putting it *above* `PHILOSOPHY.md` gives the
project one fixed point that the more detailed docs are reconciled *against*,
rather than a flat pile of docs that can quietly drift apart. The reconciliation
rule it carries makes the hierarchy operational: on a **principle** disagreement
APPROACH.md wins and the detailed doc is corrected; on **how something is
currently done**, the operational doc wins. (Sources: `APPROACH.md` "How to use
this document" + closing reconciliation paragraph; `plan-05` report "Outcome"
and the CLAUDE.md tier decision.)

**Alternatives considered / rejected.** Fold the principles into `PHILOSOPHY.md`
or `CLAUDE.md` instead of a new top doc — rejected because `PHILOSOPHY.md` is the
*Somerville-specific instance* (it specializes the standard for one build), so
housing the cross-repo standard there would couple it to one dataset and one
repo, exactly the drift a single shared standard is meant to prevent.

## 2. Why the creed is empathy / honesty / optimism — and why honesty is the constraint

**Decision.** Name the conviction beneath the principles in three words —
**empathy, honesty, optimism** — and single out honesty as "the rule the other
two answer to."

**Why.** Each word names a distinct way the work can go wrong if it's missing.
Empathy: a fact handed over without the asker's context is *incorrect for that
person*, so context is part of being right, not a courtesy. Honesty: every answer
carries its evidence and states plainly what it can't show. Optimism: the data
skews gloomy by default (see #3), so surfacing real progress is part of telling
the truth. Honesty is load-bearing over the other two because empathy without
honesty degrades into telling people what they want to hear, and optimism without
honesty degrades into spin — so honesty is the boundary both operate inside. The
three were chosen to **distill** convictions already present rather than to add
new ones: the `oxygen-mvp` Plan 49 reconciliation maps honesty → PHILOSOPHY
move 1, optimism → move 2, empathy → move 3, so the creed names what the doc
already did. (Sources: `APPROACH.md` "What we believe"; `PHILOSOPHY.md` "The
creed" §; `oxygen-mvp` Plan 49 registry row.)

**Alternatives considered / rejected.** A longer value list or a single overriding
value — rejected because three terms map cleanly onto the three existing moves in
`PHILOSOPHY.md` (§1 facts-vs-answers, §4 honest reporting, §6 trust contract), so
the creed stays a distillation, not a fourth thing to maintain.

## 3. Why optimism is framed as correcting a structural negativity bias

**Decision.** Frame optimism as the correction of a *structural* negativity bias
baked into complaint/incident data — explicitly "honest reporting, not
editorializing."

**Why.** A platform built on 311-style feeds inherits a negativity bias **by
construction**: its source data is mostly a record of problems, so a faithful
summary of it reads as relentlessly negative even when the underlying community
is improving. Deliberately surfacing genuine progress therefore corrects a
*measurement artifact* — it makes the picture more accurate, which is honesty's
job, not a thumb on the scale. The framing also fences off the failure mode:
optimism here is *earned* (a conclusion the evidence supports), never a mood
applied on top. (Sources: `APPROACH.md` "Optimism" bullet; `PHILOSOPHY.md` "The
creed" Optimism bullet — "negativity bias by construction.")

**Alternatives considered / rejected.** Treat optimism as tone or editorial
choice — rejected because that would violate honesty. Omit optimism entirely —
rejected because leaving the structural bias uncorrected is itself a form of
dishonesty (it reports a distorted picture as if it were the whole one).

## 4. Why "hypothesis / result" rather than more technical terminology

**Decision.** Lock the two-tier sensemaking vocabulary as **hypothesis** and
**result**.

**Why.** The discipline is Klein's Data-Frame Theory of sensemaking applied as a
two-stage gate: a quick, labeled working idea versus an answer that has paid the
full trust contract. The words were chosen for **reader self-explanatoriness** —
"hypothesis" already signals *provisional* and "result" already signals *earned*
to a non-specialist, so the label does its work without a glossary. The label
travels with the claim, which is what stops cheap exploration from quietly being
dressed up as a finding. (Sources: `APPROACH.md` "How we think: hypothesis, then
result"; `METHODOLOGY.md` R5 and its Origin row naming the 2026-06-10 design
session and the Klein basis.)

**Alternatives considered / rejected.** Klein's native "frame / data" vocabulary
— rejected as jargon that a community member wouldn't parse. "Draft / final" —
rejected because it carries no sense of the *evidence gate* that separates the two
tiers.

## 5. Why system humanism was split — build half to METHODOLOGY, conviction half to PHILOSOPHY

**Decision.** Stop treating "system humanism" as one philosophical strand. Move
its build-discipline half into `METHODOLOGY.md` (as rule R6) and leave its
conviction half in `PHILOSOPHY.md`.

**Why.** The idea had two separable parts living under one name. One part is a
**testable build rule**: manufacture the operator's expertise into the product
behind a constrained agent surface (R6). The other part is a **conviction**:
good systems widen what a person can see and do. A rule and a belief want
different homes — a rule belongs where it can be applied and checked
(METHODOLOGY), a belief belongs where convictions are stated (PHILOSOPHY).
Keeping them fused blurred something testable with something held, and made
neither cleanly reconcilable. In `oxygen-mvp` the conviction half stays in
PHILOSOPHY and the corresponding R6 propagation is deliberately *deferred* until
that repo has its own METHODOLOGY.md. (Sources: `METHODOLOGY.md` R6 + its Origin
row; `oxygen-mvp` Plan 49 row noting the system-humanism split is deferred until
oxygen-mvp's METHODOLOGY.md exists.)

**Alternatives considered / rejected.** Keep system humanism as a single
philosophical strand — rejected because a half-rule/half-belief strand can't be
tested as a rule *or* reconciled cleanly as a principle; splitting it lets each
half be governed by the right doc.

## 6. Why declarative-first is an accessibility strategy (not a tool property)

**Decision.** Frame designing for declarative use as a deliberate
**accessibility strategy** — an engineered outcome — and illustrate it with the
airplane → elevator → "take me to oncology" ladder.

**Why.** Declarativeness here is not something a tool hands you for free; it is
something you *build* by spending engineering effort on the inside — reliable
data handling, standardized terms, structured transformations, and tests that
enforce what must stay true — so the user can simply state what they want and
trust the answer. The payoff is reach: a simpler surface lowers the skill needed
to use the system, which widens who can use it from trained analysts to any
community member with a question. The ladder makes the gradient concrete: a plane
is *imperative* (full skill, every step yours); an elevator is *declarative*
(press a button, the system handles the rest); "take me to oncology" goes further
still (the system holds the floor number you'd otherwise need to know). The more
capable the system, the more it absorbs on the user's behalf, and the simpler the
request can be. The ease has to be **earned** — a simple surface is only honest
when the reliability underneath is real, which is the trust contract's whole job.
(Sources: `APPROACH.md` "Why we design for declarative use — and why it matters";
`METHODOLOGY.md` R7.)

**Alternatives considered / rejected.** Treat declarative use as UX convenience /
polish — rejected because it undersells the actual mechanism by which the audience
broadens. Treat it as inherent to SQL or modern tooling — rejected because an
unconstrained system (or an unconstrained AI) can offer a simple surface that
*lies*; the simplicity is only legitimate when the constraints and tests beneath
it make the answer trustworthy.

## 7. Why the capability-to-scope law unifies several framings

**Decision.** Recognize a single law behind several familiar ideas: the
**altitude at which you can issue a command rises with the executor's
capability-to-scope ratio.**

**Why.** The same shape recurs in places usually treated as separate. Managing
people: you *coach* a capable person ("here's the goal, you handle it") and
*direct* an inexperienced one ("do this, then this") — Situational Leadership.
Designing an agent surface: a well-constrained, well-tested spine (R6's authored
guidance) raises the ratio, which is exactly what lets a user state outcomes and
trust the answer rather than spell out steps. Seeing these as one law is what
tells you the methodology's job: *raise the builder's capability so we can
describe outcomes more often and dictate steps less often.* (Sources:
`APPROACH.md` "How much to specify depends on the builder"; `METHODOLOGY.md` R7,
which names the "capability-to-scope ratio" and ties it to Situational
Leadership and R6's authored spine.)

**Sourcing note (per the reconstruction discipline).** The *Situational
Leadership* and *agent-surface* halves of this unification are directly supported
by `APPROACH.md` and R7. The broader claim from the design session — that the
**same** law also unifies hardware-abstraction layers and control-theory altitude
— is recorded in the project's migration summary (`docs/MIGRATION_SUMMARY.md`
§5/§8) but is only lightly attested in the named `APPROACH.md`/`METHODOLOGY.md`
sources. It is preserved here as design-session reasoning, flagged as not fully
recoverable from the core standard docs, for Gordon to confirm or refine.

**Alternatives considered / rejected.** Keep coaching-vs-directing, abstraction
layers, and control altitude as separate analogies — rejected because the value
is in noticing the single isomorphism: once you see it as one ratio, "how much to
specify" becomes a measurable design question rather than a case-by-case feel.

## 8. Why R7 was split into R7 (reconciliation) and R8 (idempotency)

**Decision.** Split the original declarative/desired-state rule into two:
**R7** (declarative-first; reconcile actual → desired) and **R8** (keep
desired-state specs idempotent).

**Why.** They are different properties with different tests. R7 is about
*direction*: state the desired end-state plus the tests that prove it, then let
the build continuously check actual against desired and close the gap
(reconciliation). R8 is about *safety of repetition*: applying a spec repeatedly
must equal applying it once. Idempotency is precisely what makes R7's
reconciliation safe to re-run on a schedule or resume after a mid-run failure —
but a spec can be declarative and still *not* idempotent, and each property needs
its own check. Because idempotency is distinct and separately testable, it earns
its own named rule rather than hiding inside R7. (Sources: `METHODOLOGY.md` R7
and R8, including R8's Origin row: "Split from R7 because idempotency is a
distinct, separately-testable property.")

**Alternatives considered / rejected.** Keep one combined rule — rejected because
bundling a separately-testable property hides it; the real-world failure (a
non-idempotent spec that can't be safely reconciled on a timer or resumed after a
crash) deserves a rule that names it directly.

---

*This is a living reconstruction. If the original design-session record surfaces,
reconcile this doc against it and upgrade the status note accordingly. For the
standard these breadcrumbs explain, see [`APPROACH.md`](../../APPROACH.md).*
