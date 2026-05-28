# Prompt — Decisions resolved + dry-run polish + shellcheck

**Kind:** coding
**Date:** 2026-05-27
**Plan:** 1 (Stack-in-a-Box's own LOG.md Plans Registry — first contiguous slot, opens the new repo's ledger)
**Scope:** `stack-in-a-box` only. No `oxygen-mvp` touch. Resolve all 5 open decisions in `docs/design/OPEN_DECISIONS.md`; reorder `TASKS.md` + `LOG.md` Next-Plan-Candidates to reflect the dry-run-discovered dependency chain; fix the small honesty disconnects surfaced by Code's session-2026-05-27 dry-run (placeholder repo URL, missing orientation caveat, out-of-scope framing); run shellcheck on the 13 v4 scripts and land fixes; do additional dry-run passes against the polished bundle.
**Effort:** one session, 3-5 hours. Real complexity is in the dry-run pass — the original 11 iterations validated the scripts; this plan validates the whole flow including the orient-before-executing path that didn't exist when the scripts were dry-run-validated.
**Depends on:** Stack-in-a-Box repo as it exists after Plan 46 (oxygen-mvp) + the scrub commit. Code's session-2026-05-27 dry-run report ("Note to Chat — dry-run findings on stack-in-a-box, asking for guidance") is the input to this plan.

## Phase 0 — Prompt-file commit (per the Plan 43 convention inherited from oxygen-mvp)

Before any other work, write this prompt verbatim to `docs/prompts/plan-1-decisions-and-dry-run-polish.md` on a new branch `claude/plan-1-decisions-and-dry-run-polish`. This file write is the first commit on the branch. All subsequent phases proceed against that branch.

This is the first plan to use this convention in `stack-in-a-box`. After this plan ships, the convention is in active use here and PROMPTS.md should reference it (Phase G of this plan).

## Outcome

A user clones the `stack-in-a-box` repo. Claude Code reads CLAUDE.md and orients them. The orientation is honest about what works and what doesn't yet — specifically, the user is told that today's install completes steps 00 through 03 cleanly (Ubuntu base, Docker, Oxygen CLI) and then dies at step 05 because the application layer (run.sh, dbt models, dlt smoke pipeline, nginx site config, systemd units, portal HTML) hasn't been built yet. The user makes an informed choice — proceed for the partial install (useful for testing the infrastructure layer) or wait for Plan 2 (the second batch) to ship before installing.

The repo's 5 design decisions are resolved and recorded. The next plan's content (the second batch) can be scoped against settled inputs: NYC 311 as the smoke source, Tailscale required, smoke in main path with delete-me markers, repo named `stack-in-a-box`, Oxygen version pinned later (after first real install reveals what works).

The 13 v4 setup scripts pass shellcheck cleanly. Real issues surfaced by shellcheck are fixed; stylistic-only complaints are either fixed or explicitly suppressed with comments naming why. Several additional dry-run passes — not the same 11 iterations from the v4 handoff, which focused on script-level bugs, but new passes focused on the whole flow (orient → user-says-go → install → die-at-step-05 honestly → next-step guidance) — surface any remaining issues.

When this plan ships, the next plan (Plan 2: the second batch) can begin from a known-clean foundation. That's the success criterion. Not "shellcheck passes." Not "decisions resolved." It's "the next person (or next Claude) picking up this work can trust what's in the repo as a clean baseline."

## Context

This plan was scoped after Code's session-2026-05-27 dry-run of bootstrap.sh against the current stack-in-a-box repo. Code surfaced seven specific issues (P1-P7 in Code's note) and asked Chat for guidance on each. Chat resolved all seven in the response that produced this prompt. The plan is the durable record of those resolutions plus the work that follows from them.

A few things to know:

- The 5 open decisions are all resolved now. Chat resolved them in the response to Code's dry-run findings. The resolutions:
  - #1 Tailscale required vs. optional → Required. Don't expand surface area; Basic Auth is a weaker security story.
  - #2 Smoke source → NYC 311 (SODA erm2-nwe9). Cheapest path; 90% pipeline reuse from oxygen-mvp.
  - #3 Smoke in main path vs. examples/ → Main path with delete-me markers. Cheapest path that earns the "in a box" framing. The `make rip-out-smoke-test` target lands as part of the second batch.
  - #4 Pin Oxygen version vs. latest → Latest, with TODO comment. Pinning before first real install is theater. Pin retroactively in a future plan after first-install captures what version actually worked.
  - #5 Repo name → `stack-in-a-box` stays. No strong opinion either way; rename is a one-plan task if a better name emerges later.
- The dry-run revealed a real sequencing bug. The original TASKS.md ordered the next moves as: decisions → shellcheck → first install → second batch. Code's dry-run showed that first install is impossible until the second batch ships (script 05 dies at missing `config.example.yml`). The actual dependency chain is decisions → second batch → shellcheck → first install. This plan fixes the ordering.
- The orientation honesty disconnect is structural, not cosmetic. CLAUDE.md §1 currently orients the user for a 35-60 minute install that will today fail in 5 minutes. The discipline this platform is built on — honest reporting over clean completion — applied to itself, demands the orientation say what's actually true. Adding a "Current install state" subsection to CLAUDE.md §1 is the working-backwards principle made visible at the place where users first encounter the platform.
- "Out of scope" in the design plan is structurally wrong. When the design plan was first written, the second batch was "out of scope for that plan" — Plan 46 (handoff digest + repo init). Reading the design plan now as the repo's authoritative design document, "out of scope" reads as "not part of the project." It is part of the project. It's required follow-up work. The framing edit is small but consequential.
- The shellcheck pass is opportunistic. Code asked whether to do it before or after the second batch. Before is right because most shellcheck findings are stylistic or robustness issues that won't conflict with second-batch content additions (which are new files, not edits to existing scripts). If shellcheck surfaces something that does conflict with planned second-batch work, that's worth knowing now.
- "More dry-runs" means something different this round. The v4 handoff's 11 iterations dry-ran the scripts in isolation. This plan's dry-runs are flow-level — they test the full path from "user clones the repo, opens Claude Code" through orient → user-says-go → script execution → step-05 honest failure → "what happens next." That's a different lens. The 11 prior iterations don't substitute for it.

## Work

The work is organized as seven phases. Phases A-D are the decisions + housekeeping. Phase E is shellcheck. Phase F is the new flow-level dry-runs. Phase G is the standard plan-ledger close-out.

**Phase A — Resolve the 5 open decisions.**

A1. Update `docs/design/OPEN_DECISIONS.md`. For each of the 5 decisions: change status to "RESOLVED 2026-05-27"; append a resolution paragraph with rationale + forward implications for the second batch. Resolutions per Context above.

A2. Update the file's header paragraph — it currently says these decisions "remain open and need resolution before the first real install plan ships." Replace with a paragraph naming that decisions were resolved 2026-05-27 (this plan).

**Phase B — Reorder TASKS.md and LOG.md Next-Plan-Candidates.**

B1. Update `TASKS.md` "Next Focus": Plan 1 (this one) → decisions + dry-run polish + shellcheck; Plan 2 → the second batch (16 artifacts, 10-14h); Plan 3 → first real install (~90 min); Plan 4 → retroactive Oxygen version pin per Plan 3 findings.

B2. Update `LOG.md` Next-Plan-Candidates to mirror B1.

**Phase C — Fix the small honesty disconnects.**

C1. `05_clone_and_config.sh` — replace placeholder `DEFAULT_REPO_URL` with the real `https://github.com/ironmonkey88/stack-in-a-box.git` + a rename-note comment.

C2. Add a comment to the clone-into-tempdir block explaining why the defensive clone path stays (curl-fetch invocation case).

C3. `CLAUDE.md` §1 — add a "Current install state" subsection before the "ask the user when to begin" step. Honest about steps 00-03 working, step 05 dying. Deleted as part of Plan 2's housekeeping.

C4. `docs/design/STACK_IN_A_BOX_PLAN.md` §8 — reframe "Explicitly out of scope, to be addressed in follow-up plans:" → "Required follow-up work, scoped as separate plans:".

C5. Add `apps/.gitkeep` to surface the apps/ directory DASHBOARDS.md §6 references.

**Phase D — Optional small adjustments surfaced by the dry-run report.** No additional D-phase work unless E/F surface more.

**Phase E — Shellcheck pass.** Run shellcheck on all 13 `.sh` files; categorize findings (real / stylistic / false-positive); fix real, fix-or-suppress stylistic, suppress-with-justification false-positives; re-run; verify `bash -n` still passes.

**Phase F — Flow-level dry-runs (the new pass).** 5 scenarios minimum: F1 orient-then-go; F2 skeptical-user (cross-doc consistency); F3 "what about decision X"; F4 wait-for-Plan-2; F5 rerun-after-fix (checkpoint resume). Findings land in `docs/design/FLOW_DRY_RUN_FINDINGS.md` with severity + outcome per finding.

**Phase G — Housekeeping and ledger.** LOG.md Plan 1 row + Recent Sessions + Last Updated; TASKS.md Plan 1 `[x]`; session file at `docs/sessions/session-1-2026-05-27-plan-1-decisions-and-dry-run-polish.md`; PROMPTS.md references the Plan 43 convention now in active use; prompt + report files; push → PR → merge.

## Verification

Static-artifact gates: prompt + report files exist; OPEN_DECISIONS all RESOLVED; FLOW_DRY_RUN_FINDINGS.md covers 5+ scenarios; PLAN.md §8 reframed; CLAUDE.md §1 has "Current install state"; TASKS/LOG reflect corrected sequence; script 05 has real URL + clone comment; `apps/.gitkeep` exists; session file exists; PROMPTS.md mentions Plan 1; PR merged.

Live-functional gates: all 13 scripts pass shellcheck (or justified disables); all pass `bash -n`; `grep -rn "CHANGE-ME" .` returns nothing; `grep -rn "NOT YET RESOLVED" .` returns nothing; CLAUDE.md §1 caveat present; OPEN_DECISIONS all resolved; F2 confirms no cross-doc contradictions.

## Halt conditions

- Shellcheck surfaces a real bug needing substantial refactoring → halt at Phase E, surface; ship smaller Plan 1 + a Plan 1.5 for the refactor.
- Flow-level dry-runs surface a structural problem with the orient-then-go path → halt at Phase F, surface.
- A previously-unsurfaced decision becomes load-bearing → halt at the dependency, surface.

## Out of scope

Building any second-batch artifact (Plan 2); first real install (Plan 3); pinning Oxygen version (Plan 4); HARDENING.md / SWAP_IN_YOUR_DATA.md / ARCHITECTURE.md / SETUP.md (Plan 2); renaming the repo; changing the discipline structure beyond the §1 caveat + PROMPTS.md Plan-1 note.

## Commit shape

Single PR titled "Plan 1: decisions resolved + dry-run polish + shellcheck pass". Push → `gh pr create` → `gh pr merge --merge --delete-branch` autonomously once gates pass.

## Notes for Code

- Phase A decisions are settled by Chat upstream. Don't relitigate even if shellcheck/dry-runs make you want to reconsider.
- Flow-level dry-runs (Phase F) are a different lens from the v4 script-level dry-runs — cross-document consistency, orientation landing, technically-correct-but-feels-broken failure modes.
- FLOW_DRY_RUN_FINDINGS.md mirrors DRY_RUN_FINDINGS.md's shape; each finding gets severity + outcome (Fixed in-plan / Deferred to Plan 2 / Documented and accepted).
- README + CLAUDE.md cross-reference; when adding the §1 caveat, update README's Status section too.
- The session file matters — it's session 1 in the new repo's history.
- shellcheck disable comments are fine when justified.
- "More dry-runs" acceptance is qualitative: 5 named scenarios pass, can't invent a 6th that finds a real issue, findings doc reads coherent.
- Phase F dry-runs are simulations (Code reading docs/scripts as a user), not actual EC2 installs. Plan 3 is the real install.
- Report-back focus: (a) decisions whose rationale didn't survive contact with implementation; (b) flow findings that changed assumptions about "clean install"; (c) anything surfaced as needing future cleanup (flag, don't fix); (d) FLOW_DRY_RUN_FINDINGS.md size vs DRY_RUN_FINDINGS.md.
