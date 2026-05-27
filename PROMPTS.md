# PROMPTS.md — Chat-to-Code prompt standard

The shape every prompt Chat hands to Code takes, and the workflow Code runs when it receives one.

---

## 1. Why this exists

Chat (the architect) and Code (the executor) communicate through Markdown prompts. The artifact is the contract. If the artifact is well-shaped, the work is durable: Chat's intent survives a session crash, Code's response is consistent across executions, and a third reader (a future Chat session, a future Code session, the user reviewing later) can pick the work back up without reconstructing context from memory.

Two failure modes this standard prevents:

- **Underspecified intent.** A coding prompt that names a change without naming the business outcome forces Code to guess at scope.
- **Inconsistent receipt.** Code's behavior on receiving a prompt varies — sometimes deep pre-flight, sometimes immediate execution. A defined workflow closes that gap.

---

## 2. Two kinds of prompts

Every prompt is one of two kinds. The kind is declared in the prompt's header.

### 2.1 Coding request

A prompt that asks Code to change the system — write code, edit config, run migrations, modify the warehouse, deploy. Anything that produces a commit.

A coding request is wrapped in a business purpose. Code never receives a bare technical instruction; it receives an outcome statement that names what the change is for, then the technical scope that delivers that outcome.

### 2.2 Information request

A prompt that asks Code to investigate the system — read files, query the warehouse, check live state, verify a claim. The output is a written finding, not a commit.

An information request is wrapped in a question. Code never receives a bare "tell me about X"; it receives the question that needs answering and the decision the answer will inform.

---

## 3. The coding-request shape

Every coding prompt has these sections, in order:

```
# Prompt — <short imperative title>

**Kind:** coding
**Date:** YYYY-MM-DD
**Scope:** <files / directories / tables Code will touch>
**Effort:** <rough estimate — minutes, hours, sessions>
**Depends on:** <prerequisite PRs or prompts, or "none">

## Outcome (required)
One paragraph: who benefits, what changes for them. The business purpose
in plain language — no SQL, no file paths, no jargon. If Code couldn't
restate this to a non-technical reader, the outcome isn't yet clear.

## Context (conditional)
State Code needs to know that isn't in the repo.

## Work (required)
The technical scope, broken into discrete items.

## Verification (required)
The conditions under which the work is complete. Distinguish static-artifact
gates (file exists, config committed) from live-functional gates (page
renders, test passes, agent answers correctly).

## Halt conditions (conditional)
When Code should stop and surface rather than barrel ahead.

## Out of scope (conditional)
What Code does NOT do, even if natural-looking.

## Commit shape (required)
How the work lands in git. Single commit vs commit-per-phase. Single PR
vs PR-per-phase. Whether the commit message names a plan number.
```

---

## 4. The information-request shape

Smaller and tighter than coding requests:

```
# Prompt — <short interrogative title>

**Kind:** information
**Date:** YYYY-MM-DD
**Output:** <where the answer goes — chat reply, a docs/ note, a session note>

## Question (required)
One sentence. Yes/no questions stated as yes/no; concrete shape questions
stated concretely.

## Decision this informs (required)
What Chat or the user will do with the answer.

## Where to look (conditional)
If the answer lives in specific files/tables/routes, name them.

## Format (conditional)
If the answer needs a particular shape (count, table, yes/no with rationale).
```

---

## 5. The workflow Code runs on receipt

Code does these steps, in order, for every prompt:

### Step 1 — Read the header

Confirm Kind, Depends-on PRs merged, scope bounded. If any are missing or unclear, ask before proceeding.

### Step 2 — Verify state

`git status` clean (or expected dirty state understood). Local and remote main in sync. LOG.md's newest entry matches today or staleness is acknowledged. If state is stale, halt and surface — the prompt was likely written against state the architect believed was current.

### Step 3 — Branch on kind

**Coding request:** continue to Steps 4-9. **Information request:** skip to Step 7 (Execute). Investigation is the execution; the output is a written finding.

### Step 4 — Restate the Outcome

In Code's first message back, restate the Outcome in its own words. The purpose must be confirmed in Code's understanding, not just present in the prompt. If Code's restatement materially differs from the prompt's Outcome, that's a finding — halt and surface.

**If the prompt arrived as a file in `docs/prompts/`** (per §5.5 below), Code's restatement is additionally appended to the prompt file as a `**Code's restatement:**` paragraph before execution begins.

### Step 5 — Pre-flight

Confirm the technical assumptions the prompt is built on. Probe live state. The pre-flight is the cheapest place to catch a bad assumption. If pre-flight surfaces a hard finding — the dataset isn't what we thought, the table doesn't exist, the file's been moved — halt and surface.

### Step 6 — Plan the commit shape

Confirm the commit shape against the prompt's instruction. Don't silently rewrite the commit structure.

### Step 7 — Execute

Do the work. Update TASKS.md as items complete. Honor the prompt's halt conditions and the standing honest-reporting discipline. A surfaced finding is a successful outcome, not a failure.

Three shapes things can take when they go wrong:

- **Hard halt.** Assumption wrong, dependency missing, outcome no longer servable. Stop. Do not commit. Move to Step 9 with `blocked` status.
- **Partial.** Some items landed cleanly; others surfaced findings needing the architect to make a call. Commit the items that landed; leave the rest. Status `partial`.
- **Recoverable miss.** A test failed, an assumption was wrong, but the fix is in scope. Fix it. Don't silently rewrite scope.

### Step 8 — Verify and commit

Verification and commits are interleaved, not sequential. Verify each item against its gate before committing it; commit each verified item as it lands.

Static-artifact gates: file exists, config committed, schema.yml has the entry. Re-runnable by `git show`.

Live-functional gates: page renders, test passes, agent answers. Re-runnable by running the same command.

Commit timing:

- One commit per Work item by default.
- Multi-phase work commits per phase.
- Code/config changes commit only after their gate passes.
- Documentation-only changes commit without a gate.
- TASKS.md / LOG.md updates happen as work completes, not batched.

Merge timing:

- The default unit of merge is the prompt.
- PR opens when the first commit lands.
- PR merges when Verification is fully passed OR partial findings are documented and the architect has been asked.

### Step 9 — Report back

After all execution, verification, commits, and merges (or after a halt), Code emits one report back to Chat. **This is the last thing Code emits in the session.** No afterthoughts, no follow-up messages. If something surfaces after the report, it goes into the next session's report.

Report shape:

```
## Gate table
| Scope | Status | PR |

## Shipped
<bulleted list of what changed, with file paths>

## Worth flagging
<findings, deferrals, decisions made under uncertainty, gates that
couldn't be verified. Non-negotiable — write "Nothing." if there's
genuinely nothing.>

## Ready for more work — natural next moves
<Optional. Code's read on what's next. Chat decides; this is input.>
```

Status vocabulary: `complete`, `partial`, `blocked`, `deferred`.

**If the prompt arrived as a file in `docs/prompts/`**, Code additionally writes the report to the sibling `.report.md` file (in addition to emitting it in terminal). Typically as the last commit on the PR branch before merge.

---

## 5.5 The `docs/prompts/` file convention

Prompts and reports may live as durable files in `docs/prompts/` rather than only in chat scrollback. The convention is additive — the paste-and-execute loop survives untouched.

Filename pattern:

- `plan-NN-<slug>.md` — the prompt file (full PROMPTS.md-shaped prompt).
- `plan-NN-<slug>.report.md` — Code's report-back from Step 9.

Lifecycle:

1. Prompt commits to `plan-NN-<slug>.md` (Chat commits it, or Code copies from paste as first execution step).
2. Code executes per §5.
3. Code commits the report to `plan-NN-<slug>.report.md` (typically last commit on PR branch before merge).
4. PR merges. Cycle complete.

A prompt file is "consumed" when its sibling report file exists.

Full convention (filename pattern, what goes in each file, lifecycle, lineage chain, backfill policy, coexistence with `docs/handoffs/`) — when `docs/prompts/README.md` is added in a future plan, it canonicalizes this section.

---

## 6. What this standard does NOT cover

- **The Chat side of the conversation.** This standard governs what Chat hands to Code and how Code receives it; not how the user and Chat decide what to build.
- **Multi-prompt batches.** A batch is a batch of prompts each following this standard.
- **The handoff doc.** Session handoffs in `docs/handoffs/` are Code's existing convention.
- **Plan-numbered work.** When a prompt corresponds to a plan number, the commit-shape section names it.

---

## 7. Migration

This standard takes effect on the date it merges. Prompts written before it are not retroactively reshaped.

If a prompt arrives that doesn't conform, Code asks for it to be reshaped — the cost of a 60-second reshape upstream is much smaller than the cost of misaligned work downstream.
