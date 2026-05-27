# TASKS.md — Stack-in-a-Box Task Tracker

> Status markers: `[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked
> Claude Code updates this file as work progresses.

---

## Next Focus — Resolve 5 open decisions + shellcheck pass + first real install + second batch

Plan 46 (in `oxygen-mvp`) created this repo and landed the v4 reference materials. The next moves, in expected order:

### 1. Resolve the 5 open decisions

Tracked in [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md). Each one needs a defensible answer before the first real install:

- **Decision #1:** Tailscale required vs. optional. *Chat's lean:* required.
- **Decision #2:** Smoke-test data source (NYC 311 vs. alternative). *Chat's lean:* NYC 311 for v1.
- **Decision #3:** Smoke test in main path vs. `examples/`. *Chat's lean:* main path with delete-me markers.
- **Decision #4:** Pin Oxygen version vs. `get.oxy.tech` latest. *Chat's lean:* pin at publish time.
- **Decision #5:** Repo name (`stack-in-a-box` is a placeholder). *Chat's lean:* none — your call.

This is a Chat-side session, not Code. Once decisions are resolved, a follow-up Code session bakes them into the scripts + docs.

### 2. Shellcheck pass on the 13 setup scripts

Lower-hanging fruit. Each script passes `bash -n` per the handoff; `shellcheck` will likely surface some style + portability findings worth fixing before real execution.

Candidate name: **Plan 1 — Shellcheck pass + idiom cleanup**.

### 3. First real install on a fresh EC2 instance

The validation moment. Budget 90 minutes (60 install + 30 buffer for the one thing we forgot).

Candidate name: **Plan 2 — First real install end-to-end**.

### 4. The second batch — `run.sh` + 16 missing artifacts

Per handoff §9: `run.sh`, `requirements.txt`, `config.example.yml`, `dbt/profiles.example.yml`, `nginx/stack-in-a-box.conf`, 4 systemd units, `portal/index.html`, `dlt/smoke_test_pipeline.py`, dbt models for bronze/gold/admin, semantic-layer YAML for the smoke source, `agents/answer_agent.agent.yml`, the 5 portal generators, `pipeline_run_start/end.py`, `source_health_check.py`, `profile_tables.py`, `check_profile_staleness.py`, `build_limitations_index.py`, `load_dbt_results.py`.

Estimated 10-14 hours per the handoff. Mostly tokenization and parameterization of `oxygen-mvp`'s existing files.

Candidate name: **Plan 3 — The second batch: run.sh + missing artifacts**.

---

## Plans Registry (cross-reference with LOG.md)

| # | Status | Notes |
|---|---|---|
| _none yet_ | | |

---

## Operational checklist (steady-state)

- [ ] LOG.md "Last Updated" timestamp bumped at end of every session.
- [ ] Plans Registry row added for every plan, status accurate.
- [ ] Session file at `docs/sessions/session-NN-...md` for every Code session.
- [ ] Limitations registry index regenerated when a `.md` is added (the `run.sh` step lands with the second batch).
- [ ] `docs/handoffs/` summary written at the end of every multi-plan Chat thread.

---

## Carry-over from `oxygen-mvp` (where the discipline came from)

The discipline + the v4 scripts arrived in this repo via [`oxygen-mvp` Plan 46](https://github.com/ironmonkey88/oxygen-mvp/blob/main/LOG.md). The patterns the scripts encode were earned over `oxygen-mvp`'s 67+ sessions (per the LOG.md at time of repo creation). Citation lineage is preserved in:

- Discipline docs (CLAUDE.md, PROMPTS.md, PHILOSOPHY.md, STANDARDS.md, DASHBOARDS.md) — adaptation notes name oxygen-mvp where the principle came from.
- v4 scripts (`scripts/setup/*`) — inline comments cite specific oxygen-mvp sessions and plans where each pattern was earned.
- Handoff doc (`docs/handoffs/2026-05-26-stack-in-a-box-v4-handoff.md`) — explicit "load-bearing patterns lifted from Somerville" table.

When this repo accumulates its own plans, the lineage continues — the oxygen-mvp pointers stay because they're part of the design's honesty about its origins.
