# Stack-in-a-Box

A reference implementation of a trustworthy data analytics platform — modular, durable, designed around working backwards from real problems.

The repo holds two things: **a discipline** (how to build platforms that produce answers an analyst can trust) and **a reference implementation** (one valid instantiation of that discipline on EC2 + Docker + Oxygen + Python + dlt + dbt-duckdb + Tailscale + nginx + systemd). The discipline is the product. The implementation demonstrates how it plays out concretely. Anyone with different infrastructure can swap components and the platform still works because the design transfers, not the technology.

> **Working placeholder name.** `stack-in-a-box` is one of five open design decisions tracked in [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md). A future plan resolves the name; until then, the placeholder is deliberate.

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
| `DASHBOARDS.md` | Design standard for analyst-facing and resident-facing dashboards. Thin in v1; fills out as the project accumulates dashboards. |
| `LOG.md` | Captain's log — running record of sessions, decisions, blockers. Empty at repo creation; plans accumulate. |
| `TASKS.md` | Task tracker — granular checkpoints with status markers. |
| `scripts/setup/` | 13 v4 bash scripts that install the reference platform end-to-end on a fresh Ubuntu 24.04 ARM EC2 instance. Dry-run-validated (11 iterations); not yet executed on real EC2. |
| `docs/design/` | The full design plan, the dry-run findings log, and the 5 open decisions. |
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

**Reference implementation v4.** Setup scripts are dry-run-validated (11 iterations, 79 issues surfaced, 33 fixed, 46 cancelled — see [`docs/design/DRY_RUN_FINDINGS.md`](docs/design/DRY_RUN_FINDINGS.md)). They have **not yet been executed on real EC2**. The first real install is the next plan.

**Five design decisions remain open** — see [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md). They need resolution before the first real install plan ships.

**The 16 missing artifacts** named in handoff §9 (`run.sh`, `requirements.txt`, `config.example.yml`, dbt models, systemd units, etc.) are also pending. The setup scripts in `scripts/setup/` reference them; they land in a future plan ("the second batch" per the handoff).

## How this connects to oxygen-mvp

The discipline was earned through the [oxygen-mvp](https://github.com/ironmonkey88/oxygen-mvp) project — a civic-analytics platform for Somerville, MA open data, built over dozens of sessions and many plans. The patterns here (`/etc/environment` over `~/.bashrc`, `--ssh=false` on Tailscale, captured-exit DQ contract, trust contract on agent answers, the 10-stage run.sh shape, etc.) are lifted from that project's LOG.md. The v4 setup scripts cite specific sessions and plans in their comments — those citations are intentional: the discipline transfers, the lineage transfers with it.

## License

MIT. See [`LICENSE`](LICENSE).
