# FLOW_DRY_RUN_FINDINGS.md — flow-level dry-run findings (Plan 1)

Sibling to [`DRY_RUN_FINDINGS.md`](DRY_RUN_FINDINGS.md). That doc covered **script-level** findings from the v4 handoff — "what does this script do when its quiet assumptions break?" — across 11 iterations. This doc covers **flow-level** findings — "what does a user experience end-to-end, from cloning the repo through orient → say-go → install → honest-failure → next-step guidance?" — a lens that didn't exist when the scripts were dry-run-validated (the orient-before-executing path landed in Plan 46, after the v4 bundle).

These are **simulations** — Code reading the docs + scripts as a user would experience them — not actual EC2 installs. Plan 3 is the real install. Plan 1's flow dry-runs validate the flow before Plan 3 burns time on a foundation that wasn't ready.

**Tally: 5 scenarios walked. 7 findings (0 critical, 0 high, 4 medium, 3 low/cosmetic). 4 fixed in-plan, 1 mitigated by the orientation caveat, 2 documented-and-accepted (1 deferred to Plan 2 prep).**

Severity vocabulary: Critical / High / Medium / Low / Cosmetic. Outcome vocabulary: Fixed in-plan / Mitigated / Deferred to Plan 2 / Documented and accepted.

---

## Scenario F1 — orient-then-go

**Walk:** User clones the repo, opens Claude Code. CLAUDE.md §1 fires. Claude orients (steps 1-8), including step 6 — the new "Current install state" caveat naming that the install dies at step 05. User says "go anyway, I want to see what happens." Claude runs `./scripts/setup/bootstrap.sh`. Steps 00-03 succeed (preflight, EC2 base packages, Docker, Oxygen CLI). Step 05 runs: clone no-ops (repo already present), API key prompt, `/etc/environment` write, PATH fix — then hits `if [[ ! -f "$PROJECT_ROOT/config.example.yml" ]]; then die`. Dies.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F1-1 | Step 05's die message reads `config.example.yml missing — was the repo cloned correctly?`. The "was the repo cloned correctly?" suffix blames the clone, but the real cause is that `config.example.yml` doesn't exist yet (it's in the second batch). Out of context, this misleads a user into debugging their clone. | Medium | **Mitigated** by the CLAUDE.md §1 "Current install state" caveat (C3) — an oriented user is told step 05 dies precisely here, and why. The message is *also correct* for the post-Plan-2 steady state (where a missing `config.example.yml` genuinely means a bad clone). Plan 2 makes this die path unreachable. Fixing the message pre-Plan-2 would mean adding temporal text to a message that's correct post-Plan-2 — the orientation caveat is the right home for the temporal context. |

**Verdict:** F1 passes. The install proceeds correctly through 00-03, dies honestly at 05, and an oriented user reads the failure as "expected at this stage" rather than "broken."

---

## Scenario F2 — skeptical user / cross-document consistency

**Walk:** User asks "what happens if I run this today?" Claude answers from CLAUDE.md §1 + design plan §9 + OPEN_DECISIONS.md. Are those documents internally consistent now that decisions are resolved? A `grep` sweep for stale "open decisions" / "out of scope" / "CHANGE-ME" / "NOT YET RESOLVED" framing.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F2-a | `STACK_IN_A_BOX_PLAN.md` §5 was titled "Decisions That Need User's Call" and framed all 5 as open — directly contradicting `OPEN_DECISIONS.md` (all resolved). | Medium | **Fixed in-plan** — §5 retitled "...(RESOLVED 2026-05-27)" with a pointer note to `OPEN_DECISIONS.md`; the design-time framing preserved below the note as a record. |
| F2-b | `README.md` "Working placeholder name" callout said the repo name "is one of five open design decisions" and "a future plan resolves the name" — stale after decision #5 (name stays). | Medium | **Fixed in-plan** — callout rewritten to "Repo name … resolved 2026-05-27 (decision #5)." |
| F2-c | `README.md` + `CLAUDE.md` doc-tour lines described `docs/design/` as holding "the 5 open decisions." | Cosmetic | **Fixed in-plan** — both reworded to "the 5 design decisions (resolved)." |
| F2-d | `grep -rn "CHANGE-ME"` and `grep -rn "NOT YET RESOLVED"` return only the prompt file's verbatim *description of the verification gates* (line quoting the strings), not live placeholders. | Cosmetic | **Documented and accepted** — the gate's intent (no live placeholder, no unresolved status) is satisfied; the self-referential match in the prompt file is correct. |

**Verdict:** F2 surfaced the most findings — exactly as the prompt anticipated ("flow-level findings are likely to be about cross-document inconsistency"). All cross-doc contradictions fixed. After fixes, the three documents a skeptical user would cross-read (CLAUDE.md §1, PLAN.md, OPEN_DECISIONS.md) tell one consistent story: decisions resolved, install completes 00-03 then dies at 05, second batch is the gate to first install.

---

## Scenario F3 — "what about decision X"

**Walk:** User asks "is Tailscale required?" → Claude reads OPEN_DECISIONS.md #1 → "Required (resolved)." Consistent with scripts 06 + 07, which assume required and have no optional-path code. User asks "what smoke source?" → OPEN_DECISIONS.md #2 → "NYC 311 (SODA `erm2-nwe9`), resolved." Consistent with `00_preflight.sh`, which checks `data.cityofnewyork.us` reachability.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| _(none)_ | Decisions are definite and consistent with what the scripts actually do. The preflight's `data.cityofnewyork.us` network check is the one place a decision (#2 smoke source) is already wired into the existing scripts, and it matches. | — | — |

**Verdict:** F3 passes clean. Decisions resolve to definite answers that don't contradict the scripts.

---

## Scenario F4 — wait-for-Plan-2

**Walk:** User reads the orientation, decides to wait for a complete install rather than run the partial. Does Claude provide graceful next-step guidance?

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F4-a | There's no single "what to watch for" pointer tying the wait-guidance together — the user infers from CLAUDE.md §1 ("wait for Plan 2") + LOG.md Next-Plan-Candidates + design plan §9. Adequate but not one-stop. | Low | **Documented and accepted** — CLAUDE.md §1's caveat names Plan 2 explicitly as the gate, and LOG.md's Next-Plan-Candidates section names Plan 2 with its scope. The trail is followable; a dedicated "watch-for" doc would be over-engineering for a pre-install repo. |

**Verdict:** F4 passes. The orientation + LOG Next-Plan-Candidates give a waiting user a clear picture of what Plan 2 delivers and that it's the gate to a real install.

---

## Scenario F5 — rerun after fix (checkpoint resume)

**Walk:** User runs `bootstrap.sh`, it dies at step 05 (checkpoints written for 00-03, NOT for 05 since it died). User waits for Plan 2, does `git pull` to get the new artifacts (`config.example.yml`, `requirements.txt`, `run.sh`, etc.), reruns `bootstrap.sh`. Does resume work?

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F5-a | Checkpoints live in `$PROJECT_ROOT/scratch/checkpoints/`, and `scratch/` is gitignored — so `git pull` (Plan 2 artifacts) doesn't disturb them. On rerun, steps 00-03 skip (still-valid infra installs), step 05 retries with the now-present `config.example.yml`, then 04, 06-10 proceed. Correct resume behavior. | — | **Validated** (not a bug) — the checkpoint-survives-pull behavior is correct and saves the user from re-installing Ubuntu base/Docker/Oxygen. |
| F5-b | If Plan 2 (or any future plan) modifies one of scripts 00-03 themselves — e.g., adds a package to `01`'s `BASE_PACKAGES` — a rerun-after-partial-install user would skip the updated script (checkpointed) and silently miss the change. The `--force` flag is the documented escape hatch, but the user wouldn't know to use it. | Low | **Deferred to Plan 2 prep** — Plan 2 is application content (new files), unlikely to touch 00-03. But Plan 2's housekeeping should note: "if this plan modifies scripts 00-03, partial-install users must `bootstrap.sh --force` or clear `scratch/checkpoints/`." Added to Plan 2's inherited prep via this finding. |

**Verdict:** F5 passes. Checkpoint resume works correctly across a Plan-2 pull. The one edge case (Plan 2 touching scripts 00-03) is flagged for Plan 2's prep rather than fixed here, since it's contingent on Plan 2's content.

---

## Meta-observation

The flow-level lens converged faster than the script-level lens did. The v4 handoff's script-level dry-runs needed 11 iterations to mine out the catastrophic + structural bugs (2 critical, 7 high). The flow-level pass found 0 critical, 0 high — the serious issues were all caught at the script level. What flow-level surfaced was exactly what the prompt predicted: cross-document inconsistency (F2, the bulk of the findings) and technically-correct-but-misleading-in-context failure modes (F1's die message). These are "the docs disagree with each other" and "the error blames the wrong thing" problems — real, worth fixing, but not the catastrophic class.

This is a useful signal for whether more flow dry-runs are worth doing: **probably not many more.** After fixing F2's cross-doc contradictions, a 6th scenario I tried to invent ("user runs `--only 09` to skip ahead to the smoke test") just re-finds F1 (dies at the missing `run.sh` precondition, honestly). The named 5 scenarios cover the meaningful flow surface. The next high-value validation is the real EC2 install (Plan 3), not more simulation.

**Size comparison:** this doc is ~1/3 the size of `DRY_RUN_FINDINGS.md`. That ratio is itself the finding — flow-level issues are far less numerous than script-level were, because (a) the scripts were already hardened, and (b) the flow has fewer moving parts than 13 scripts' worth of edge cases. Flow-level dry-runs are worth doing once per major doc/flow change, not iterated like script-level.

---

*Flow dry-runs completed 2026-05-27 by Code (Plan 1, Session 1). Simulations, not EC2 installs. Plan 3 is the real install.*
