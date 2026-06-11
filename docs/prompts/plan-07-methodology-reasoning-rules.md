# Prompt C — Add R5–R8 to stack-in-a-box/METHODOLOGY.md (Sensemake, system-humanism build-discipline, declarative/reconciliation)

**Kind:** coding (documentation)
**Repo:** `stack-in-a-box`
**Scope:** `METHODOLOGY.md` (new rules + propagation table), plus LOG.md / TASKS.md.
**Effort:** ~1 session. No code, no live gates. Heaviest of the three cleanup prompts (most new content, must match existing rule form exactly).
**Depends on:** APPROACH.md (landed). Independent of Prompts A and B; can run in any order relative to them.

---

## Phase 0 — write this prompt to the repo first

Before any other work, write this prompt **verbatim** to
`docs/prompts/plan-NN-methodology-reasoning-rules.md` on a new branch
`claude/plan-NN-methodology-reasoning-rules`. This file write is the first commit
on the branch. All subsequent phases proceed against that branch.

**Plan number:** claim the next available stack-in-a-box slot from LOG.md's Plans
Registry at fire time (repo is at Plan 5). **Audit open/recent PRs**
(`gh pr list --state all`) before claiming. If Prompt B is running concurrently,
the two will claim adjacent slots — coordinate so they don't collide. Resolve
`NN` before branching.

MCP-direct-commit path is paused; Code owns prompt-file creation.

---

## Outcome (required)

`stack-in-a-box/METHODOLOGY.md` gains the reasoning-and-build disciplines worked
out in the design session, expressed as testable rules in the file's existing
**imperative Rule / Origin / Sync** form (matching R1–R4): a Sensemake
hypothesis→result rule, a system-humanism build-discipline rule, and a
declarative/desired-state/reconciliation rule (with idempotency). After this, the
methodology layer enforces the disciplines that APPROACH.md only *names* — the
trust contract's reasoning gate, the constrained-agent build pattern, and the
desired-state posture — so the rules layer and the reference standard agree. The
pending-propagation table is updated so a future oxygen-mvp METHODOLOGY.md
instantiation knows to carry these.

## Context (conditional)

- **Match the existing form exactly.** Each rule is: a bold imperative
  one-line-ish **Rule**, an **Origin** (repo + where it came from), and a **Sync**
  state (`stack-only` / `oxygen-only` / `synced` / `n/a`). Terse. Handoff-ready —
  "a rule you could hand to someone with no context." See R1–R4 for the voice.
  These new rules originate in design discussion (Chat), not from a plan's field
  experience, so their Origin should say so honestly (e.g. "design session
  2026-06-10, ratified by Gordon; not yet exercised in a plan").
- **These are stack-only at birth, pending propagation to oxygen-mvp.** oxygen-mvp
  has no METHODOLOGY.md yet; when it gets one, these carry over. Set Sync
  accordingly and add propagation rows.
- **The source material** is the design-session detailed notes. Summary of each
  rule's substance below — Code should express these as rules, not copy the prose.

### R5 — Sensemake: hypothesis and result are separate tiers; the gate is at the lab door

Turning data into understanding follows the scientific method in two
clearly-labeled tiers. A **hypothesis** is a working idea — allowed to be quick,
rough, and to reason ahead of full anchoring — but it always wears the label
"hypothesis." A **result** pays the full trust contract (SQL, row counts,
citations, limitations). A hypothesis becomes a result only by passing the
evidence gate; if it can't, it is surfaced as a stated open question, never
quietly promoted to a finding. The looseness is in the *evidentiary cost* of the
hypothesis tier; it is **never** in the labeling. The failure mode being
prevented: abductive frame-based reasoning (confidence scores, parallel
hypotheses) laundering speculation past the verification gate by shedding its
label before it reaches the reader. Why two tiers and not one strict gate: both
humans and LLMs, given data and no frame, either freeze or confabulate; a cheap
labeled hypothesis tier is where exploration lives, exactly as in science a
conjecture isn't held to publication standard. (Basis: Klein's Data-Frame Theory.
Connects to: the trust contract = peer review; the limitations registry = threats
to validity.)

### R6 — System humanism: manufacture operator expertise into the product behind a constrained agent surface

A product that works only because a human expert is in the loop has not yet been
built — it has been *operated*. To make it stand without the operator, decompose
the operator's expertise and manufacture it into the product as three things: a
**domain-neutral authored spine** (the standardized terms, joins, and structure
the expert would otherwise supply by hand), **structural verification** (tests
and gates that hold what must stay true), and a **constrained agent surface** (the
agent may act only within the rail the spine defines; it cannot exceed it). The
binding that makes this safe: the constrained agent must not be able to produce
output the structural verification can't check. (This is the build-discipline half
of system humanism; the *conviction* half — human dignity/agency as the measure,
dignity/privacy/honesty bounding the trade-off space — stays in PHILOSOPHY.md.
Load-bearing for the desktop/local-app MVP-0 concept, whose whole thesis is this
rule applied.)

### R7 — Declarative/desired-state first; reconcile actual to desired; keep specs idempotent

State the desired end-state (the outcome plus the tests that prove it), not the
imperative steps; let the build reconcile actual state to desired. Treat the
spec as a **standing description continuously enforced** (check → diff →
execute), not a one-time instruction — this is reconciliation, and the tests +
documentation are its mechanism (they declare what must stay true and drive the
system back when it drifts). Keep specs **idempotent**: applying the same spec
repeatedly equals applying it once, so re-runs and crash-recovery are safe.
Where actual diverges from desired, **report the diff and let a human decide** for
anything judgment-bearing (this is the Code-proposes/human-approves posture). Do
**not** over-rotate on declarative purity: it leaks at complexity and is always
imperative underneath, so stay declarative in the data layer (specs, SQL, tests)
and accept imperative control where the abstraction genuinely can't express the
need. How declarative the agent surface can safely be tracks the
**capability-to-scope ratio** of the executor — a well-constrained, well-tested
surface (the authored spine of R6) raises that ratio, which is what lets the user
state outcomes and trust the answer. (Basis: desired-state infra — Kubernetes/
Terraform reconciliation, idempotency; Situational Leadership for the
coaching-vs-directing/capability framing. Connects to R6: the spine is what makes
the surface safe to operate declaratively.)

## Work (required)

1. **Add R5, R6, R7** to the Rules section of METHODOLOGY.md, in the existing
   Rule / Origin / Sync form, after R4. Express each as a terse imperative rule
   (use the substance above; do not paste the prose). Origin = design session
   2026-06-10, ratified by Gordon, not yet exercised in a plan. Sync =
   `stack-only` (oxygen-mvp has no METHODOLOGY.md yet).
   - If R7 reads better as two rules (one declarative/reconciliation, one
     idempotency), split it — use judgment; match the granularity of R1–R4.
2. **Update the "Pending propagation" table** with rows for each new rule:
   direction `stack → oxygen`, action "carry over when oxygen-mvp METHODOLOGY.md
   is instantiated," status `open`.
3. **Optionally add a short framing line** at the top of the Rules section noting
   that R5–R7 are *reasoning/build disciplines* (vs. R1–R4's
   install/infra-operational character) — only if it reads cleanly; don't force a
   taxonomy the file doesn't currently have.
4. **LOG.md + TASKS.md** per convention.

## Verification (required)

Static-artifact gates:

- R5, R6, R7 (or R5–R8 if R7 split) present in METHODOLOGY.md, each with Rule /
  Origin / Sync fields matching the R1–R4 format.
- Each new rule's Sync is `stack-only` and has a matching row in the Pending
  propagation table.
- R1–R4 unchanged (verify by diff).
- The rules are genuinely imperative and context-free (the "hand to someone with
  no context" test) — not narrative.
- LOG.md / TASKS.md updated.

No live-functional gates.

## Halt conditions (conditional)

- If expressing any rule in the terse imperative form loses something essential
  that only the prose carries, surface it — better to flag than to ship a rule
  that's lossy or misleading. (R6 and R7 are conceptually dense; if they resist
  one-line-ish form, a slightly longer Rule body is acceptable, as R2 already
  demonstrates.)
- If the plan-number slot is ambiguous after the PR audit, or collides with a
  concurrently-running Prompt B, surface and coordinate.

## Out of scope (conditional)

- **No PHILOSOPHY.md edits** in either repo (creed work is Prompts A and B).
- **No system-humanism split in oxygen-mvp** — that's deferred (see Prompt A's
  out-of-scope). R6 here is the *destination* the future split will point at, but
  the split itself isn't done now.
- **No oxygen-mvp METHODOLOGY.md instantiation** — that's a separately-scoped
  future plan. This prompt only authors the rules in stack-in-a-box and records
  that they're pending propagation.
- No changes to the sync *procedure* section — only the Rules section and the
  propagation table.

## Commit shape (required)

- Phase 0 prompt-file write is commit 1.
- Then METHODOLOGY.md edit, then LOG/TASKS (docs commit without a gate).
- One PR; autonomous merge on green per repo policy.
- Step-9 report to sibling
  `docs/prompts/plan-NN-methodology-reasoning-rules.report.md` before merge.

---

## Resolution (added by Code at execution, 2026-06-10)

- **Plan number → 7.** Boot audit run first (`gh pr list --state all`): Plans
  1/2/3/5/6 done (Plan 6 = the Prompt B creed, merged just before this), Plan 4 the
  in-flight reserved branch; nothing claims 7. Run sequentially after Plan 6 (off
  the post-Plan-6 `main`) so LOG/TASKS don't conflict. Unambiguous; halt did not
  fire.
- **R7 split into R7 + R8.** Per the Work-item-1 option, the idempotency property
  is a distinct, testable rule and stands alone better than bundled — so R7 =
  declarative/desired-state + reconciliation (+ the don't-over-rotate and
  capability-to-scope caveats), R8 = idempotency. Four new rules total: R5–R8.
