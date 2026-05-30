# Stack-in-a-Box — Handoff: Plan 3 (first install on metal) + portal design questions

**Date:** 2026-05-30
**Origin:** Code session (continued from the Plan 2 thread)
**Status:** Plan 3 **done and merged** (PR [#7](https://github.com/ironmonkey88/stack-in-a-box/pull/7), `main` @ `7ebec07`). The box is **proven on metal** — `bootstrap.sh` runs all 10 steps green on a fresh `t4g.medium` and the F6 trust contract fires live. Site is up.

This supersedes the "built and statically verified, never run on EC2" status of [`2026-05-28-plan-2-second-batch-slice.md`](2026-05-28-plan-2-second-batch-slice.md). The "first real run is Plan 3" it named has now happened.

---

## 1. What landed (Plan 3)

First install on a fresh `t4g.medium` (Ubuntu 24.04 arm64), driven over SSH then Tailscale. All 10 `bootstrap.sh` steps green; **Oxygen 0.5.54** observed (captured for the Plan-4 pin). Six install bugs found and fixed, one commit each:

| # | Break | Fix | Commit |
|---|---|---|---|
| 1 | `config.example.yml` comment tripped step-05's `{{` verify gate | reword comment | `09f5d4e` |
| 2 | step-07 portal gate raced nginx graceful reload | poll body until marker | `d389251` |
| 3 | `oxy.service` `ExecStart=%h/...` → `/root` (203/EXEC) | `{{HOME_DIR}}` token (`%h` ≠ User= home for system units) | `dbb20f7` |
| 4 | `enable --now` fired a `Persistent` catch-up `run.sh` colliding with the smoke run on the DuckDB lock; `setsid` didn't wait | enable-only (activate on boot) + `setsid -w` | `b5c30cc` |
| 5 | step-10 verify required timers *active* | check `is-enabled` | `9e58ec2` |
| 6 | **F6 blocker:** oxy duckdb DB used `dataset:` (directory mode) not `path:` | `dataset`→`path` | `3674088` |

Full per-break detail (stage / root cause / resolution) + observed component versions: [`docs/design/FIRST_INSTALL_FINDINGS.md`](../design/FIRST_INSTALL_FINDINGS.md).

## 2. F6 proven on metal

Via `oxy run agents/answer_agent.agent.yml`:
- **"how many 311 service requests are in the warehouse?"** → SQL `SELECT COUNT(*) … fct_smoke_test`, result **10000**, row-count line + answer + citations. No limitations section (correct — none apply to a bare count).
- **"…in each borough?"** → 6-row breakdown (Brooklyn 3281 … Unspecified 222) with the **`borough-unspecified-bucket`** limitation surfaced. All four trust-contract sections fire when relevant.

## 3. Live state

- Public portal: `http://18.219.78.136/` → 200 (nginx, port 80, public).
- Oxygen SPA: `http://stack-in-a-box.taildee698.ts.net:3000/` → 200 (Tailnet only).
- Public SSH (22) + 3000 closed at the AWS SG; only 80 public.
- Box left running; install scaffolding + `~/.sib-secrets/` (keys, mode 600) on the box — remove if repurposing.

## 4. Validation caveat (honest)

Validation was **fix-and-resume on one instance**, not a clean from-scratch pass of the corrected scripts. End state is fully green + F6 works, but a fresh-box run of `main` is the recommended final confirmation (folded into Plan 4). Notably, step 08's new `enable` (no `--now`) line reached the "already enabled" branch on this box rather than the new line.

---

## 5. Gordon's portal suggestions (this thread — for Code to implement after Chat weighs in)

1. **Keep the basic portal as the simple default** out of the box — don't over-build it.
2. **dbt docs `/docs/` is missing a "return to portal" link.** Fix path: a dbt overview doc (`{% docs __overview__ %}`) with plain-Markdown `[← Back to portal](/)` (dbt-docs sanitizes raw HTML — CLAUDE.md §10).
3. **Add a portal documentation page** describing the portal + the solution. Proposed: a static `portal/about.html` + an "About" item in `scripts/_nav.py`, synced by `run.sh` like `index.html` (no generator, no warehouse dependency).

## 6. Code's observations (design-worthy, surfaced during the install)

- **The install can pass fully green while the core feature is broken.** Finding 6 made every agent query fail, yet steps 00–10 were green — nothing ever queried *through* oxy (step 10 only checked `:3000 → 200` and read DuckDB directly via Python).
- **DuckDB single-writer contention is structural.** The daily `pipeline-refresh` (writes), the timers, and `oxy` (serves reads) share one `.duckdb` file. We dodged it at install (timers deferred to next boot), but a heavy refresh holding the write lock can block the agent mid-query in steady state. "Lock-aware run.sh" is backlog — really an architecture decision.
- **Timers activate on next boot, not at install** — a deliberate workaround for the above, not a designed end-state.
- **Default smoke mode (`medium`, ~250k) hit NYC 311 SODA read-timeouts;** `small` (10k) was clean.
- **Public portal is raw-IP, HTTP-only.**

---

## 7. Open design questions for Chat

1. **Serving vs refresh on one DuckDB file** — how should `oxy` (reads) and `run.sh` (writes) coordinate so the daily refresh doesn't block the agent? Options: `flock` around refresh + oxy retry, stop-oxy-during-refresh, or a snapshot/read-replica split. This decision unblocks activating the timers for real (currently boot-deferred).
2. **Should the install's success gate include a live agent query** (ask a canned question, assert a number returns), not just `:3000 → 200`? Would have caught Finding 6. Pairs with adding an `oxy validate` gate (backlog B1).
3. **How much should the default portal document the solution** — minimal (Gordon's stated preference) vs a fuller about/architecture page? Where's the "out of the box" line?
4. **Public-side posture** — stay raw-IP HTTP, or bring a domain/TLS story into scope?
5. **Smoke default** — keep `medium` or drop to `small`; tune dlt retry/timeout against SODA?

## 8. Next

Plan 4 (queued in [`TASKS.md`](../../TASKS.md)): pin Oxygen 0.5.54; add the `oxy validate` + live-query gates; clean from-scratch install confirmation; then backlog B/C/D (HARDENING / SWAP_IN_YOUR_DATA / TEARDOWN docs). Portal items (§5) await Chat's read on the §7 questions, especially #3.
