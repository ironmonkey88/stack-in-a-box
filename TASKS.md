# TASKS.md — Task Tracker

> Status markers: `[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked
> Claude Code updates this file as work progresses.

---

## Next Focus

The dependency chain below is the corrected ordering after Plan 1's dry-run surfaced that a first install is impossible until the second batch ships (script 05 dies at missing `config.example.yml`). The actual chain is: decisions → second batch → shellcheck → first install. Shellcheck folds into Plan 1 (it's a fast pre-second-batch win against the existing scripts).

**Plan 1 done 2026-05-27** — [x] Decisions resolved + dry-run polish + shellcheck pass. All 5 open decisions in [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md) RESOLVED; honesty disconnects fixed (CLAUDE.md §1 "Current install state" caveat, design plan §8 reframe, script 05 real repo URL); 13 v4 scripts pass shellcheck; flow-level dry-runs in [`docs/design/FLOW_DRY_RUN_FINDINGS.md`](docs/design/FLOW_DRY_RUN_FINDINGS.md).

**Plan 2 contract-critical slice done 2026-05-28** — [x] The second batch's 16 core artifacts + the F6 hard contract. Built in 5 commit groups on `claude/plan-2-second-batch-slice` (G1 config templates `355691b`, G2 dlt + dbt models `c69027b`, G3 semantic layer + agent + limitations `7cc46d7`, G4 observability + portal generators `0f8489b`, G5 run.sh + nginx + systemd + portal `2e68391`, G6 docs). Backlog §A (C1-C5) SATISFIED — verified by read-cross-check against scripts 07/09/10. Static-verify only (py_compile, YAML parse, `bash -n`, shellcheck) — **never run on EC2**; live gates are Plan 3.

**Plan 2 follow-on (open)** — [ ] B/C/D from [`docs/design/IMPROVEMENTS_BACKLOG.md`](docs/design/IMPROVEMENTS_BACKLOG.md), deferred from the slice: B = oxy-validate gate, lock-aware run.sh + orphaned-run cleanup, timer ordering, tailscale-SSH health check, `make rip-out-smoke-test`; C = HARDENING / SWAP_IN_YOUR_DATA / ARCHITECTURE / SETUP / TEARDOWN docs; D = preflight proxy hint, `--force` note. Can fold into Plan 3's hardening pass.

**Plan 3 done 2026-05-29** — [x] First real install on a fresh t4g.medium EC2. All 10 `bootstrap.sh` steps green; F6 trust contract proven on metal (agent answered `10000` + per-borough breakdown with limitation surfaced). 6 bugs found+fixed across 7 commits on `claude/plan-03-first-install-on-metal` (config-comment gate `09f5d4e`, nginx reload race `d389251`, oxy.service `%h`→`{{HOME_DIR}}` `dbb20f7`, timer/​smoke DuckDB collision + `setsid -w` `b5c30cc`, step-10 timer is-enabled `9e58ec2`, oxy duckdb `dataset`→`path` `3674088`). Findings: [`docs/design/FIRST_INSTALL_FINDINGS.md`](docs/design/FIRST_INSTALL_FINDINGS.md). §1 caveat replaced with "validated on EC2". Oxygen `0.5.54` captured. Validation was fix-and-resume on one box — a clean from-scratch run is recommended (rolled into Plan 4).

**Plan 4 (next)** — [ ] Retroactive Oxygen `0.5.54` pin in `03_install_oxygen.sh` (decision #4). Add the gates Finding 6 exposed: `oxy validate` (backlog B1) + an "agent answers a real query" check in `run.sh`/step 10. Run a clean from-scratch install on a new box to confirm the corrected scripts. Then backlog B/C/D.

**Plan 5 done 2026-06-10** — [x] APPROACH.md cross-repo reference standard (documentation-only; landed off `main` in parallel with the in-flight Plan 4). New `APPROACH.md` at repo root — plain-language "how we build" (empathy/honesty/optimism, trust contract, hypothesis-then-result, decide-then-build, declarative/reconciliation), tool/dataset-agnostic, **byte-identical to oxygen-mvp's** (`diff` clean; oxygen-mvp Plan 48 — landed as 47 then renumbered after a collision with its older open PR #76 / this repo Plan 5). Sits above PHILOSOPHY.md (this repo's specialization). Wiring: CLAUDE.md reading hierarchy gains a "Reference standard (cross-repo, above the convictions)" tier with the reconciliation rule; **new `session-starter.md`** created (this repo had none) per Gordon's direction, carrying the Chat-side APPROACH/PHILOSOPHY/METHODOLOGY pointers. Canonical body delivered Chat-side + an aligned Google Doc; Gordon approved a merge (pasted body's reconciliation closer + the Doc's newcomer intro line). PHILOSOPHY.md + METHODOLOGY.md read in full → compatible (contradiction halt did not fire). Prompt+report at `docs/prompts/plan-05-approach-reference-standard.{md,report.md}`.

---

## Plans Registry (cross-reference with LOG.md)

| # | Status | Notes |
|---|---|---|
| 1 | done | Decisions resolved + dry-run polish + shellcheck — Session 1, 2026-05-27 |
| 2 | done (slice; B/C/D deferred) | Second batch contract-critical slice — 16 artifacts + F6 contract, static-verified — Session 2, 2026-05-28 |
| 3 | done | First install on metal — 10 steps green, F6 proven, 6 fixes, Oxygen 0.5.54 — Session 3, 2026-05-29 |
| 5 | done | APPROACH.md cross-repo reference standard + CLAUDE.md tier + new session-starter.md — doc-only, off `main` parallel to in-flight Plan 4 — 2026-06-10 |

---

## Operational checklist (steady-state)

- [ ] LOG.md "Last Updated" timestamp bumped at end of every session.
- [ ] Plans Registry row added for every plan, status accurate.
- [ ] Session file at `docs/sessions/session-NN-...md` for every Code session.
- [ ] Limitations registry index regenerated when a `.md` is added (the `run.sh` step lands with the second batch).
- [ ] `docs/handoffs/` summary written at the end of every multi-plan Chat thread.
