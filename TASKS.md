# TASKS.md — Task Tracker

> Status markers: `[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked
> Claude Code updates this file as work progresses.

---

## Next Focus

The dependency chain below is the corrected ordering after Plan 1's dry-run surfaced that a first install is impossible until the second batch ships (script 05 dies at missing `config.example.yml`). The actual chain is: decisions → second batch → shellcheck → first install. Shellcheck folds into Plan 1 (it's a fast pre-second-batch win against the existing scripts).

**Plan 1 done 2026-05-27** — [x] Decisions resolved + dry-run polish + shellcheck pass. All 5 open decisions in [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md) RESOLVED; honesty disconnects fixed (CLAUDE.md §1 "Current install state" caveat, design plan §8 reframe, script 05 real repo URL); 13 v4 scripts pass shellcheck; flow-level dry-runs in [`docs/design/FLOW_DRY_RUN_FINDINGS.md`](docs/design/FLOW_DRY_RUN_FINDINGS.md).

**Plan 2 contract-critical slice done 2026-05-28** — [x] The second batch's 16 core artifacts + the F6 hard contract. Built in 5 commit groups on `claude/plan-2-second-batch-slice` (G1 config templates `355691b`, G2 dlt + dbt models `c69027b`, G3 semantic layer + agent + limitations `7cc46d7`, G4 observability + portal generators `0f8489b`, G5 run.sh + nginx + systemd + portal `2e68391`, G6 docs). Backlog §A (C1-C5) SATISFIED — verified by read-cross-check against scripts 07/09/10. Static-verify only (py_compile, YAML parse, `bash -n`, shellcheck) — **never run on EC2**; live gates are Plan 3.

**Plan 2 follow-on (open)** — [ ] B/C/D from [`docs/design/IMPROVEMENTS_BACKLOG.md`](docs/design/IMPROVEMENTS_BACKLOG.md), deferred from the slice: B = oxy-validate gate, lock-aware run.sh + orphaned-run cleanup, timer ordering, tailscale-SSH health check, `make rip-out-smoke-test`; C = HARDENING / SWAP_IN_YOUR_DATA / ARCHITECTURE / SETUP / TEARDOWN docs; D = preflight proxy hint, `--force` note. Can fold into Plan 3's hardening pass.

**Plan 3 (next)** — [ ] First real install on a fresh t4g.medium EC2. Budget ~90 minutes (60 install + 30 buffer for "the one thing we forgot"). Captures which Oxygen version actually works end-to-end. Full removal of the CLAUDE.md §1 caveat lands here once the install completes green. **Next-Code handoff written:** [`docs/prompts/plan-3-first-real-install.md`](docs/prompts/plan-3-first-real-install.md) — read it first; it carries the preconditions (human provisions EC2 + keys), the ranked carried-risks (docroot sudo seam, external-schema guesses, no oxy-validate gate), and the in-repo gotchas.

**Plan 4** — [ ] Retroactive Oxygen version pin in `03_install_oxygen.sh`, per decision #4 and Plan 3's first-install findings.

---

## Plans Registry (cross-reference with LOG.md)

| # | Status | Notes |
|---|---|---|
| 1 | done | Decisions resolved + dry-run polish + shellcheck — Session 1, 2026-05-27 |
| 2 | done (slice; B/C/D deferred) | Second batch contract-critical slice — 16 artifacts + F6 contract, static-verified — Session 2, 2026-05-28 |

---

## Operational checklist (steady-state)

- [ ] LOG.md "Last Updated" timestamp bumped at end of every session.
- [ ] Plans Registry row added for every plan, status accurate.
- [ ] Session file at `docs/sessions/session-NN-...md` for every Code session.
- [ ] Limitations registry index regenerated when a `.md` is added (the `run.sh` step lands with the second batch).
- [ ] `docs/handoffs/` summary written at the end of every multi-plan Chat thread.
