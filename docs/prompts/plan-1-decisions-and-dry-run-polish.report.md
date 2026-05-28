# Report — Decisions resolved + dry-run polish + shellcheck

**Companion to:** [`plan-1-decisions-and-dry-run-polish.md`](plan-1-decisions-and-dry-run-polish.md)
**Session:** [1](../sessions/session-1-2026-05-27-plan-1-decisions-and-dry-run-polish.md)
**PR:** [#1](https://github.com/ironmonkey88/stack-in-a-box/pull/1)
**Date:** 2026-05-27

---

## Gate table

| Scope | Status | Where |
|---|---|---|
| Phase 0 — prompt file | complete | `66c90da` |
| Phase A — 5 decisions resolved | complete | OPEN_DECISIONS.md, `cafe49f` |
| Phase B — TASKS/LOG reorder | complete | `cafe49f` |
| Phase C — honesty disconnects (URL, §1 caveat, §8 reframe, apps/.gitkeep, README) | complete | `cafe49f` |
| Phase E — shellcheck | complete | clean (exit 0); all 13 pass `bash -n` |
| Phase F — flow dry-runs (5 scenarios) | complete | FLOW_DRY_RUN_FINDINGS.md, `cafe49f` |
| Phase G — LOG/TASKS/session/PROMPTS + prompt+report files | complete | `cafe49f` + this commit |

## Shipped

**Decisions (A):** all 5 RESOLVED 2026-05-27 in [`OPEN_DECISIONS.md`](../design/OPEN_DECISIONS.md), each with rationale + Plan-2 forward implications. #1 Tailscale required; #2 NYC 311 smoke source; #3 main-path smoke + delete-me markers + `make rip-out-smoke-test`; #4 Oxygen latest+TODO, pin in Plan 4; #5 name `stack-in-a-box` stays.

**Sequencing (B):** `TASKS.md` + `LOG.md` reordered to decisions → second batch → first install → retroactive pin, fixing the dry-run-discovered bug (original ordering put first-install before the second batch it depends on).

**Honesty disconnects (C):** `05_clone_and_config.sh` real repo URL (was `CHANGE-ME`) + clone-block comment; `CLAUDE.md` §1 "Current install state" caveat; `STACK_IN_A_BOX_PLAN.md` §8 reframe + §5 resolved-pointer; `README.md` Status rewrite; `apps/.gitkeep`.

**Shellcheck (E):** shellcheck 0.11.0 `-x` on all 13 scripts → 3 findings, all in `05_clone_and_config.sh` (2× SC2088 display-string → `$HOME`; 1× SC2024 sudo-redirect → justified disable). Re-run clean (exit 0). All 13 still pass `bash -n`.

**Flow dry-runs (F):** [`FLOW_DRY_RUN_FINDINGS.md`](../design/FLOW_DRY_RUN_FINDINGS.md) — 5 scenarios, 7 findings (0 critical, 0 high, 4 medium, 3 low). 4 fixed in-plan (all cross-doc inconsistency in F2), 1 mitigated (F1 die message), 2 accepted (1 deferred to Plan 2 prep).

**Housekeeping (G):** `PROMPTS.md` §5.5 notes Plan 1 as first use of the convention; session file; this report.

## Worth flagging

*(per the prompt's report-back focus)*

- **(a) Did any decision's rationale not survive contact with implementation?** No. All 5 decisions held. The closest test was decision #1 (Tailscale required) — shellcheck on scripts 06/07 was clean, so there was no "the optional path would've been simpler" pressure. Decisions stuck as intended.
- **(b) Flow findings that changed assumptions about "clean install"?** One reframing: "clean baseline" for Plan 2 turned out to mean *cross-document consistency*, not *script correctness*. The scripts were already clean (shellcheck found 3 cosmetic issues, zero bugs). The real debt was four documents telling slightly different stories about whether decisions were open. "Clean foundation for Plan 2" is now: scripts shellcheck-clean **and** every doc agrees on the resolved state + the not-yet-installable reality.
- **(c) Surfaced-but-not-fixed (flagged for future):**
  - **F5-b:** if Plan 2 (or any future plan) modifies scripts 00-03, partial-install users who rerun `bootstrap.sh` will skip the updated script (checkpointed) and silently miss the change. Escape hatch is `--force`. Deferred to Plan 2 prep — Plan 2's housekeeping should carry a note. Not fixed here because it's contingent on Plan 2's content.
  - **F1-1:** step 05's die message (`config.example.yml missing — was the repo cloned correctly?`) is misleading pre-Plan-2 but correct post-Plan-2. Mitigated by the §1 orientation caveat rather than rewritten; becomes moot when Plan 2 ships `config.example.yml`. No action needed, but worth knowing the message exists on a soon-to-be-unreachable path.
  - **Not a bug, worth noting:** the v4 `DRY_RUN_FINDINGS.md` references a `stack-in-a-box-setup-scripts-v4.tar.gz` bundle that doesn't exist in this repo (the scripts ship as a source tree, not a tarball). That's a historical-artifact reference in a dated findings doc; left as-is (the doc is a snapshot). Flagging in case a future cleanup wants to reconcile.
- **(d) FLOW_DRY_RUN_FINDINGS.md size vs DRY_RUN_FINDINGS.md:** ~1/3 the size. The ratio is itself a finding — flow-level issues are far less numerous than script-level were, because the scripts were already hardened and the flow has fewer moving parts than 13 scripts' worth of edge cases. Signal: flow-level dry-runs are worth doing **once per major doc/flow change**, not iterated like the script-level 11. A 6th scenario (`--only 09` skip-ahead) just re-found F1. The next high-value validation is the real EC2 install (Plan 3), not more simulation.

## Ready for more work — natural next moves

1. **Plan 2 — The second batch.** Build the 16 artifacts per `STACK_IN_A_BOX_PLAN.md` §9 against the settled decisions. Housekeeping must (i) remove the CLAUDE.md §1 "Current install state" caveat, and (ii) per F5-b, note if it touches scripts 00-03 that partial-install users need `bootstrap.sh --force`.
2. **Plan 3 — First real install** on a fresh t4g.medium. Captures the working Oxygen version.
3. **Plan 4 — Retroactive Oxygen pin** per decision #4 + Plan 3 findings.
