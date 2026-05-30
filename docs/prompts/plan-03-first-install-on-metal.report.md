# Report — Plan 3: first install on metal

**Status:** complete. Branch `claude/plan-03-first-install-on-metal`. Surfaced for review (not auto-merged — see below).

## Gate table

| Scope | Status | PR |
|---|---|---|
| Phase 0 — prompt file committed | complete | (this branch) |
| Phase 1 — provision + reach box + clone | complete | — |
| Phase 2 — bootstrap 00→10 all green | complete | — |
| Phase 3 — F6 trust contract on metal | complete | — |
| Phase 4 — findings + housekeeping | complete | — |

## Shipped

- **Green install on a fresh t4g.medium** (Ubuntu 24.04 arm64, Oxygen `0.5.54`): all 10 `bootstrap.sh` steps pass.
- **F6 proven on metal** via `oxy run answer_agent`: "how many 311 service requests are in the warehouse?" → `10000` with SQL + citations; a per-borough breakdown additionally surfaces the `borough-unspecified-bucket` limitation. Row count + answer + citations + limitations all fire correctly.
- **6 fixes (7 commits):** `09f5d4e` config-comment `{{` gate · `d389251` nginx reload-race gate · `dbb20f7` `oxy.service` `%h`→`{{HOME_DIR}}` · `b5c30cc` timer Persistent-catch-up collision + `setsid -w` · `9e58ec2` step-10 timer is-active→is-enabled · `3674088` oxy duckdb `dataset`→`path`.
- **`docs/design/FIRST_INSTALL_FINDINGS.md`** — per-break stage/root-cause/resolution/commit, observed component versions for the Plan-4 pin, F6 evidence, honest validation caveat.
- **`CLAUDE.md` §1** caveat replaced with the "validated on EC2 2026-05-29, Oxygen 0.5.54" note.
- **LOG.md** (Plans Registry, Current Status, Session 3, 4 decisions) + **Session 3** narrative.

## Worth flagging

- **Validation was fix-and-resume on one box, not a clean from-scratch pass** of the corrected scripts. End state is fully green + F6 works, but a fresh-box run of the final branch is the recommended confirmation. In particular, step 08's `enable` (no `--now`) line reached the "already enabled" branch on this box rather than the new line.
- **Finding 6 (the F6 blocker, `dataset`→`path`) was invisible to every install gate** — step 10 only checked `:3000 → 200` and queried DuckDB directly via python, never through oxy. Strongly recommend Plan 4 add (a) the `oxy validate` gate (backlog B1) and (b) an "agent answers a real query" gate to `run.sh`/step 10. Either would have caught it.
- **Default `medium` smoke mode hit NYC 311 SODA read-timeouts**; `small` completed cleanly. Consider `small` as the install default or tuning dlt retry/timeout.
- **Timers activate on next boot, not during install** (deliberate, documented). If same-boot activation is wanted, that needs lock-aware run.sh coordination (out of Plan-3 scope).
- **Did not auto-merge:** per this prompt's own guidance ("Plan 3 is human-in-the-loop… pause and surface rather than auto-merging"), and because this is a 6-fix install PR worth a human read. PR is open for review.
- **Box left running** at `stack-in-a-box.taildee698.ts.net` with install scaffolding (`~/launch_bootstrap.sh`, `~/ask_agent.sh`, `~/run_oxy.sh`, `~/.sib-secrets/`). Remove `~/.sib-secrets/` (holds the API + Tailscale keys, mode 600) if repurposing the box.

## Ready for more work — natural next moves

- Plan 4: pin Oxygen `0.5.54`; add the `oxy validate` + live-query gates; clean from-scratch install confirmation; then backlog B/C/D (HARDENING / SWAP_IN_YOUR_DATA / TEARDOWN docs).
