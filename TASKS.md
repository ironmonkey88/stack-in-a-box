# TASKS.md — Task Tracker

> Status markers: `[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked
> Claude Code updates this file as work progresses.

---

## Next Focus

The dependency chain below is the corrected ordering after Plan 1's dry-run surfaced that a first install is impossible until the second batch ships (script 05 dies at missing `config.example.yml`). The actual chain is: decisions → second batch → shellcheck → first install. Shellcheck folds into Plan 1 (it's a fast pre-second-batch win against the existing scripts).

**Plan 1 done 2026-05-27** — [x] Decisions resolved + dry-run polish + shellcheck pass. All 5 open decisions in [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md) RESOLVED; honesty disconnects fixed (CLAUDE.md §1 "Current install state" caveat, design plan §8 reframe, script 05 real repo URL); 13 v4 scripts pass shellcheck; flow-level dry-runs in [`docs/design/FLOW_DRY_RUN_FINDINGS.md`](docs/design/FLOW_DRY_RUN_FINDINGS.md).

**Plan 2 (next)** — [ ] The second batch. Build the 16 missing artifacts per [`docs/design/STACK_IN_A_BOX_PLAN.md`](docs/design/STACK_IN_A_BOX_PLAN.md) §9 (run.sh, requirements.txt, config.example.yml, dbt models, dlt smoke pipeline for NYC 311, semantic-layer YAML, agent YAML, systemd units, portal generators, helper scripts) + the `make rip-out-smoke-test` target. Estimated 10-14 hours. Unblocks a real end-to-end install. Removes the CLAUDE.md §1 "Current install state" caveat as part of its housekeeping.

**Plan 3** — [ ] First real install on a fresh t4g.medium EC2. Budget ~90 minutes (60 install + 30 buffer for "the one thing we forgot"). Captures which Oxygen version actually works end-to-end.

**Plan 4** — [ ] Retroactive Oxygen version pin in `03_install_oxygen.sh`, per decision #4 and Plan 3's first-install findings.

---

## Plans Registry (cross-reference with LOG.md)

| # | Status | Notes |
|---|---|---|
| 1 | done | Decisions resolved + dry-run polish + shellcheck — Session 1, 2026-05-27 |

---

## Operational checklist (steady-state)

- [ ] LOG.md "Last Updated" timestamp bumped at end of every session.
- [ ] Plans Registry row added for every plan, status accurate.
- [ ] Session file at `docs/sessions/session-NN-...md` for every Code session.
- [ ] Limitations registry index regenerated when a `.md` is added (the `run.sh` step lands with the second batch).
- [ ] `docs/handoffs/` summary written at the end of every multi-plan Chat thread.
