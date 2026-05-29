# Stack-in-a-Box

A reference implementation of a trustworthy data analytics platform — modular, durable, designed around working backwards from real problems.

The repo holds two things: **a discipline** (how to build platforms that produce answers users can trust) and **a reference implementation** (one valid instantiation of that discipline on EC2 + Docker + Oxygen + Python + dlt + dbt-duckdb + Tailscale + nginx + systemd). The discipline is the product. The implementation demonstrates how it plays out concretely. Anyone with different infrastructure can swap components and the platform still works because the design transfers, not the technology.

> **Repo name.** `stack-in-a-box` is the repo name — resolved 2026-05-27 (decision #5 in [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md)). A rename remains a contained future plan if a better name emerges.

---

## Who this is for

Someone who wants to stand up a data warehouse + analyst-facing chat agent + trust contract on a fresh EC2 instance, where Claude (the AI coding assistant) does the install end-to-end — but only after orienting them on what's about to happen. The orientation is the first lesson in the discipline.

If you want to skip orientation and just run a script, this repo isn't for you. The skip-orientation path doesn't produce a trustworthy platform; it produces a working one. Different thing.

## What's in here

| Path | What's there |
|---|---|
| `CLAUDE.md` | Operating discipline for Claude in this repo — including the orient-before-executing instruction and the closing-ritual instruction. Read this first if you're a future Claude opening this repo. |
| `PROMPTS.md` | The shape every coding/information request takes when handed to Claude, plus the 9-step receipt workflow Claude runs on every prompt. |
| `PHILOSOPHY.md` | The principles the platform is built on — working backwards, stages with verification, durability through metadata, honest reporting, trust contract on every answer, modular by design. |
| `STANDARDS.md` | The "done done" gates by layer (bronze/silver/gold/admin), file-organization rules, and project-state-document maintenance. |
| `DASHBOARDS.md` | Design standard for analyst-facing and end-user-facing dashboards. Thin in v1; fills out as the project accumulates dashboards. |
| `LOG.md` | Captain's log — running record of sessions, decisions, blockers. Empty at repo creation; plans accumulate. |
| `TASKS.md` | Task tracker — granular checkpoints with status markers. |
| `scripts/setup/` | 13 v4 bash scripts that install the reference platform end-to-end on a fresh Ubuntu 24.04 ARM EC2 instance. Dry-run-validated at script + flow level and shellcheck-clean; not yet executed on real EC2. |
| `docs/design/` | The full design plan, the dry-run findings logs, and the 5 design decisions (resolved). |
| `docs/handoffs/` | End-of-thread Code → Chat summaries spanning multiple plans. |
| `docs/prompts/` | Per-work-item Chat-issued prompts + Code-issued reports. |
| `docs/sessions/` | Full session narratives — the bronze layer behind LOG.md. |
| `docs/limitations/` | The limitations registry — honest documentation of what the platform cannot say. |

## How to use it

1. Launch a fresh Ubuntu 24.04 LTS ARM EC2 instance (`t4g.medium` is the reference size).
2. SSH in as the `ubuntu` user.
3. Clone this repo to `~/stack-in-a-box`.
4. Install Claude Code on the instance.
5. Open Claude Code in the repo's directory.
6. **Do not run `bootstrap.sh` directly.** Let Claude orient you first.

When Claude reads `CLAUDE.md` on session start, it will introduce itself: what this repo is, the discipline it's built on, what the install process does at a high level, and when you want to begin. Read the orientation, ask questions, and when satisfied, tell Claude to go. The orientation is the first lesson in working-backwards — skipping it skips the lesson.

When install + smoke verify complete, Claude returns to a working-backwards question — *what report do you want this platform to produce? what question is it answering? who's asking?* — in its own words. That's the closing ritual. The discipline made visible at the moment you're about to start the real work.

## Status

**Reference implementation v4.** Setup scripts are dry-run-validated (11 script-level iterations + flow-level dry-runs, see [`docs/design/DRY_RUN_FINDINGS.md`](docs/design/DRY_RUN_FINDINGS.md) and [`docs/design/FLOW_DRY_RUN_FINDINGS.md`](docs/design/FLOW_DRY_RUN_FINDINGS.md)) and pass shellcheck. They have **not yet been executed on real EC2**.

**Not yet installable end-to-end.** A real install today completes steps 00-03 (Ubuntu base, Docker, Oxygen CLI) and then dies at step 05, because the application layer (`run.sh`, dbt models, dlt smoke pipeline, nginx site config, systemd units, portal HTML) hasn't been built yet — that's **Plan 2 (the second batch)**, the gate to a first real install. CLAUDE.md §1 orients users honestly about this; see `docs/design/STACK_IN_A_BOX_PLAN.md` §9 for the full artifact list.

**Five design decisions resolved** (2026-05-27, Plan 1) — see [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md): NYC 311 smoke source, Tailscale required, smoke in main path with delete-me markers, repo name `stack-in-a-box`, Oxygen version pinned after first real install.

## License

MIT. See [`LICENSE`](LICENSE).
