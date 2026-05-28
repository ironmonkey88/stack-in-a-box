---
session: 1
date: 2026-05-27
start_time: 14:17 ET
type: code
plan: plan-1
layers: [docs, infra]
work: [hardening, docs]
status: complete
---

## Goal

Plan 1 — the first plan in `stack-in-a-box`'s own ledger. Resolve all 5 design decisions, fix the honesty disconnects surfaced by Code's 2026-05-27 dry-run, run shellcheck on the 13 v4 scripts, and do flow-level dry-runs (a new lens — orient → say-go → install → honest-failure → next-step). Success criterion: the next plan (Plan 2, the second batch) can begin from a known-clean foundation.

## What shipped

**Decisions (Phase A):**

- All 5 decisions in [`docs/design/OPEN_DECISIONS.md`](../design/OPEN_DECISIONS.md) flipped to **RESOLVED 2026-05-27**, each with a rationale + forward-implications-for-Plan-2 paragraph. Header rewritten from "awaiting resolution" to "all resolved." Closing section rewritten to the downstream sequence (Plan 2 → 3 → 4).
- Resolutions: #1 Tailscale **required**; #2 smoke source **NYC 311** (SODA `erm2-nwe9`); #3 smoke in **main path** with delete-me markers + `make rip-out-smoke-test` (Plan 2); #4 Oxygen **latest from get.oxy.tech** with TODO, retroactive pin in Plan 4; #5 repo name **`stack-in-a-box` stays**.

**Sequencing (Phase B):**

- `TASKS.md` Next Focus + Plans Registry rewritten to the corrected dependency chain: Plan 1 (done) → Plan 2 (second batch) → Plan 3 (first install) → Plan 4 (retroactive pin). The original ordering had first-install before the second batch, which the dry-run proved impossible.
- `LOG.md` rewritten with Plan 1 row, decisions resolved in Current Status + Decisions Log, a Next-Plan-Candidates section mirroring TASKS, and the first Recent Sessions entry.

**Honesty disconnects (Phase C):**

- `05_clone_and_config.sh` — placeholder `DEFAULT_REPO_URL` (`CHANGE-ME`) → real `ironmonkey88/stack-in-a-box` URL + rename-note; clone-into-tempdir block gained a comment explaining why the defensive curl-fetch path stays.
- `CLAUDE.md` §1 — new "Current install state" callout (step 6, with the existing steps renumbered to 8). Tells the orienting user that an install completes steps 00-03 and dies at step 05, and to make an informed proceed-or-wait choice. Marked for removal when Plan 2 ships.
- `STACK_IN_A_BOX_PLAN.md` §8 — reframed from "What This Plan Does Not Cover / Explicitly out of scope" to "Required follow-up work (separate plans)."
- `apps/.gitkeep` — surfaces the `apps/` directory DASHBOARDS.md §6 references.
- `README.md` Status section — rewritten to name the not-yet-installable state, Plan 2 as the gate, and the resolved decisions.

**Shellcheck (Phase E):**

- All 13 `.sh` files run through shellcheck 0.11.0 (`-x` to follow sources). Only 3 findings, all in `05_clone_and_config.sh`: two SC2088 (tilde-in-display-string) + one SC2024 (sudo-redirect). Fixed: SC2088 → `$HOME/...` in the two log messages; SC2024 → justified `# shellcheck disable` (the redirect target is a user-owned mktemp file). Re-run: **clean (exit 0)**. All 13 still pass `bash -n`.

**Flow-level dry-runs (Phase F):**

- 5 scenarios walked, captured in [`docs/design/FLOW_DRY_RUN_FINDINGS.md`](../design/FLOW_DRY_RUN_FINDINGS.md): F1 orient-then-go, F2 skeptical-user (cross-doc consistency), F3 "what about decision X", F4 wait-for-Plan-2, F5 rerun-after-fix (checkpoint resume).
- 7 findings: 0 critical, 0 high, 4 medium, 3 low/cosmetic. 4 fixed in-plan (all in F2 — cross-doc inconsistencies), 1 mitigated by the orientation caveat (F1's misleading die message), 2 documented-and-accepted (1 deferred to Plan 2 prep: the "Plan 2 modifies scripts 00-03 → use `--force`" edge case).

**Housekeeping (Phase G):**

- `PROMPTS.md` §5.5 notes Plan 1 as the first use of the prompt-file convention here.
- Prompt file (Phase 0) + this session file + report file (last commit before PR).

## Decisions

The 5 design decisions were settled by Chat upstream and recorded here, not relitigated (the discipline: decisions made with rationale are sticky). The one judgment call inside this plan: **F1's misleading step-05 die message was mitigated, not rewritten.** The message (`config.example.yml missing — was the repo cloned correctly?`) is misleading pre-Plan-2 but *correct* post-Plan-2 (where a missing config.example.yml really would mean a bad clone). Rather than add temporal pre-Plan-2 text to a message that's right post-Plan-2, the temporal context lives in the CLAUDE.md §1 orientation caveat — which is removed when Plan 2 lands. Recorded in FLOW_DRY_RUN_FINDINGS.md F1-1.

## Issues encountered

- **shellcheck not installed locally + brew blocked.** `brew install shellcheck` failed on a non-writable `/usr/local/share/man/man8` (postinstall), and the `sudo chown` fix needs a TTY password. Resolved by `pip3 install --user shellcheck-py`, which vendors the binary at `~/.local/bin/shellcheck`. Worked cleanly (shellcheck 0.11.0).
- **Cross-doc staleness was the bulk of the flow findings** — exactly as the prompt predicted. PLAN.md §5 still framed the decisions as open; README's "Working placeholder name" callout was stale; two doc-tour lines called the decisions "open." All fixed. This is the signal that flow-level dry-runs find different things than script-level: cross-document drift, not script edge cases.
- **No halt conditions fired.** Shellcheck found no refactor-grade bug; the orient-then-go path is sound; no previously-unsurfaced decision became load-bearing.

## Next action

Plan 2 — the second batch. Build the 16 missing artifacts per `STACK_IN_A_BOX_PLAN.md` §9 against the now-settled decisions (NYC 311 smoke source, Tailscale required, main-path smoke with delete-me markers). Plan 2's housekeeping must remove the CLAUDE.md §1 "Current install state" caveat and — per FLOW_DRY_RUN_FINDINGS.md F5-b — note that if it modifies scripts 00-03, partial-install users need `bootstrap.sh --force`.
