# Plan 3 — First Install on Metal (stack-in-a-box)

**Repo:** `ironmonkey88/stack-in-a-box`
**Branch:** `claude/plan-03-first-install-on-metal`
**Mode:** Code-autonomous (Code has cloud creds for stack-in-a-box)
**Scope:** A — land the first successful end-to-end install, capture findings, stop. ~90 minutes. Plan 4 picks up the version pin; edge cases and F1–F5 failure-mode runs are deferred to a later plan.

---

## Phase 0 — Write this prompt to the repo (first commit)

Before any other work, write this prompt verbatim to `docs/prompts/plan-03-first-install-on-metal.md` on a new branch `claude/plan-03-first-install-on-metal`. This file write is the first commit on the branch. All subsequent phases proceed against that branch.

(The MCP-direct-commit path is paused; Code owns prompt-file creation until further notice.)

---

## Outcome (success criterion — the F6 contract, end-to-end)

Plan 3 is **done** when a fresh-EC2 user can:

1. Clone the repo,
2. Run `bootstrap.sh`,
3. Complete all 10 steps,
4. Ask the chat **"how many 311 service requests are in the warehouse?"**, and
5. Get a **numeric answer with citation and limitations**.

That is the full F6 trust-contract path exercised on real hardware. Nothing less counts as done; nothing more is in scope for this plan.

---

## Context: what's known but unproven

stack-in-a-box has never run on real hardware. Plans 1 and 2 assembled and statically checked all 16 application artifacts plus infrastructure, but four assumption classes remain unexercised:

1. **NYC 311 column names and types** — written from documented SODA schema (`erm2-nwe9`), not observed.
2. **`config.yml` and `answer_agent.agent.yml` grammar** — written from Oxygen docs, never parsed by `oxy validate`.
3. **dbt-duckdb materialization behavior** under `run.sh`'s captured-exit pattern.
4. **`oxy start --local` readiness timing** on a real `t4g.medium`.

One known batch-1↔batch-2 seam: script 07 sets docroot `www-data:755`; `run.sh` runs as `ubuntu`, so portal-page deploys fall back to `sudo`. This assumes default-EC2 passwordless sudo. Confirm it works, or surface the fix (likely group-based — add `ubuntu` to `www-data` — rather than escalating to sudo on every deploy).

---

## Critical framing: failure modes are a dependency chain, not a flat list

The unproven assumptions fail in sequence, each blocking the next:

> Wrong 311 columns → dbt won't compile → `run.sh` fails at stage 2 → admin tables never populate → agent's row-count answers fail.

**Therefore: fix inline (or stub past) the first failure and keep running.** Do not stop at the first stumble. The goal is to walk the entire chain in one pass so the findings doc captures *every* break, not just the first. One 90-minute install should yield one install **plus** a comprehensive findings doc — much higher signal per hour than stopping early and round-tripping.

When stubbing past a failure rather than fixing it, mark the stub clearly and log it as a finding so Plan 4 / backlog triage can pick it up.

---

## Phases

### Phase 1 — Provision and bootstrap
- Provision a fresh `t4g.medium` EC2 instance (Tailscale required per OPEN_DECISIONS).
- Clone `ironmonkey88/stack-in-a-box`, check out the Plan 3 branch.
- Run `bootstrap.sh`. Capture full output. Note the first divergence from the happy path, fix-inline-or-stub, continue.

### Phase 2 — Walk the 10-stage install to first break and beyond
- Drive the install through all 10 steps. For each failure in the dependency chain:
  - Record the symptom, the stage, the root cause.
  - Fix inline if cheap and safe; otherwise stub past with a clear marker.
  - Continue to the next stage. Do **not** halt.
- Specific watch-points, in dependency order:
  1. NYC 311 column names/types vs. observed SODA response.
  2. `oxy validate` on `config.yml` and `answer_agent.agent.yml`.
  3. dbt-duckdb materialization under `run.sh` captured-exit.
  4. `oxy start --local` readiness timing.
  5. The script-07 / `run.sh` docroot-ownership seam.

### Phase 3 — Exercise the F6 contract end-to-end
- Once the warehouse is populated, ask the chat: **"how many 311 service requests are in the warehouse?"**
- Confirm the response carries: a numeric answer, a citation, and a limitations note.
- If any element of the contract is missing, trace it back through the dependency chain and record where it broke.

### Phase 4 — Capture findings and housekeeping
- Write `docs/design/FIRST_INSTALL_FINDINGS.md`: every break, every fix, every stub, with stage + root cause + resolution. Note the working Oxygen version observed (Plan 4 will retroactively pin it).
- If the install fully succeeded: remove CLAUDE.md §1's "Current install state" caveat entirely (not just update it).
- If it succeeded with stubs: update the caveat to reflect exactly what's proven vs. stubbed; do not remove.
- Update LOG.md and TASKS.md.
- Open a PR.

---

## Out of scope (do not do in Plan 3)
- F1–F5 failure-mode scenarios against real hardware (later plan).
- Retroactive Oxygen version pin (Plan 4 — just *record* the working version here).
- Lock-aware `run.sh`, `make rip-out-smoke-test`, `oxy validate` gate, doc batch (backlog).
- The F5-b `--force` partial-install rerun fix (Plan 4 or later).
- Anything in `oxygen-mvp` (Plan 45 branch, Plans 41/42 reserved).

---

## Done means
The F6 contract runs end-to-end on metal, **or** every break in the dependency chain is documented in `FIRST_INSTALL_FINDINGS.md` with a fix or a marked stub. Either way, the findings doc is the durable deliverable.

---

**Code's restatement (PROMPTS.md §5 Step 4):** A real person on a fresh, empty EC2 box should be able to clone this repo, run one script, and end up with a working analytics platform whose chat agent answers a real question about NYC 311 data with a trustworthy answer — a number, where it came from, and what caveats apply. My job this session is to be the first person to ever actually do that on real hardware. The platform has only ever been checked on paper; nothing has run. I expect things to break — and the framing I'm holding is that the breaks form a *chain* (bad data shape blocks dbt, which blocks the warehouse, which blocks the agent's answer), so I walk the whole chain in one pass, fixing-or-stubbing each break and writing every one down, rather than stopping at the first failure. The durable deliverable is the findings doc; a fully-green install is the bonus. Success is the agent answering "how many 311 service requests are in the warehouse?" with a number, a citation, and a limitations note — proof the trust contract works on metal.
