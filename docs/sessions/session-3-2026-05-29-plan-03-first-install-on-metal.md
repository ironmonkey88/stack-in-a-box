---
session: 3
date: 2026-05-29
start_time: 15:00 EDT
end_time: 22:00 EDT
type: code
plan: plan-3
layers: [ingestion, bronze, gold, admin, semantic, agent, portal, infra, docs]
work: [feature, bugfix, infra, test, docs]
status: complete
---

## Goal
Run `bootstrap.sh` end-to-end on a fresh `t4g.medium`, walk every break in one pass (fix-or-stub, don't halt), and prove the F6 trust contract on real hardware.

## What shipped
- **A green install on metal:** all 10 `bootstrap.sh` steps pass on a fresh t4g.medium (Ubuntu 24.04 arm64, Oxygen `0.5.54`), driven over SSH then Tailscale.
- **F6 proven:** `oxy run answer_agent` → "how many 311 service requests…" returns `10000` with SQL + citations; a per-borough breakdown surfaces the `borough-unspecified-bucket` limitation. All four trust-contract sections fire correctly.
- **6 fixes, 7 commits** on `claude/plan-03-first-install-on-metal`:
  - `2459cec` Phase 0 prompt file.
  - `09f5d4e` Finding 1 — `config.example.yml` comment tripped the `{{` verify gate.
  - `d389251` Finding 2 — step-07 portal gate raced nginx graceful reload (poll the body).
  - `dbb20f7` Finding 3 — `oxy.service` `ExecStart=%h/...` → `/root` (203/EXEC); `{{HOME_DIR}}` token.
  - `b5c30cc` Finding 4 — `enable --now` fired a Persistent catch-up `run.sh` colliding with the smoke run on the DuckDB lock; `setsid` didn't wait. (enable-only + `setsid -w`).
  - `9e58ec2` Finding 5 — step-10 timer check `is-active` → `is-enabled`.
  - `3674088` Finding 6 — oxy duckdb DB key `dataset` → `path` (the F6 blocker).
- **`docs/design/FIRST_INSTALL_FINDINGS.md`** — every break (stage / root cause / resolution / commit) + observed component versions for the Plan-4 pin + an honest validation caveat.
- **CLAUDE.md §1** "Current install state" caveat replaced with a "validated on EC2" note.
- LOG.md (Plans Registry, Current Status, Session 3, 4 decisions) + `plan-03-first-install-on-metal.report.md`.

## Decisions
- oxy duckdb database uses `path:`, not `dataset:` — `dataset` is a directory-of-files mode; `path` opens the `.duckdb` file.
- Timers enabled but not `--now` during install (Persistent catch-up would collide with the smoke run); they activate on next boot; gates check `is-enabled`.
- `oxy.service` ExecStart uses a `{{HOME_DIR}}` token, not `%h` (which is `/root` for system units).
- F6 validated via `oxy run` CLI (autonomous/re-runnable) rather than the browser SPA — same agent + config.

## Issues encountered
- **DuckDB lock collision (Finding 4):** `run.sh manual` died on `Conflicting lock is held in /usr/bin/python3.12`. `systemctl status` showed `pipeline-refresh.service activating, TriggeredBy pipeline-refresh.timer` — the `enable --now` had fired a Persistent catch-up `run.sh daily`. Resolved by enabling timers without `--now` + `setsid -w`.
- **F6 query failed (Finding 6):** agent produced correct SQL but `execute_sql` reported the DuckDB path "must be a directory containing .csv or .parquet files." Root cause: `dataset:` vs `path:`. Resolved; `oxy validate` → all 5 config files valid; agent then answered correctly.
- **Medium smoke mode flaky:** default `medium` (~250k) hit NYC 311 SODA read-timeouts; `small` (10k) completed cleanly. Used `small` for the F6 proof (count-agnostic). Observation, not a bug.

## Next action
Plan 4 — pin Oxygen `0.5.54`, clear backlog B/C/D (incl. an `oxy validate` gate + an "agent answers a real query" gate in `run.sh`/step 10, which would have caught Finding 6), and run a clean from-scratch install on a new box to confirm the corrected scripts (validation here was fix-and-resume, not a single clean pass).
