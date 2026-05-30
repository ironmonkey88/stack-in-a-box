# First Install on Metal — Findings (Plan 3)

**Date:** 2026-05-29
**Instance:** fresh AWS `t4g.medium`, Ubuntu 24.04.4 LTS (arm64), driven over SSH/Tailscale from a laptop.
**Outcome:** **SUCCESS.** `bootstrap.sh` runs all 10 steps green and the F6 trust contract fires end-to-end on real hardware. Six install bugs were found and fixed (all real fixes, no stubs).

This is the validation no dry run could substitute for. Plans 1–2 assembled and statically checked the platform; this is the first time it actually ran on metal.

---

## Working component versions (observed on this install)

Plan 4 will use these for the retroactive version pin (decision #4).

| Component | Version |
|---|---|
| **Oxygen (`oxy`)** | **0.5.54** (`oxy-app version: 0.5.54`, aarch64-unknown-linux-gnu) |
| Ubuntu | 24.04.4 LTS (Noble), arm64 |
| Docker | 29.5.2 |
| Tailscale | 1.98.4 |
| nginx | 1.24.0 |
| Python | 3.12.3 |
| dlt | 1.26.0 |
| duckdb (python) | 1.5.3 |
| duckdb (dbt adapter runtime) | 1.10.1 |
| dbt-core | 1.11.9 |

---

## The dependency chain, walked

The prompt framed the unproven assumptions as a chain (wrong data shape → dbt fails → warehouse empty → agent can't answer). In practice the breaks were spread across the install, not a single data-shape cascade: the data path (dlt/dbt) was clean on the first try; the breaks clustered in **config substitution, systemd, service orchestration, and the oxy↔DuckDB connection.** Each was fixed in repo, pushed, pulled on the box, and the step resumed.

---

## Findings

### Finding 1 — `config.yml` verify gate tripped by its own template comment
- **Stage:** 05 (clone + config), verify gate.
- **Symptom:** `config.yml has unsubstituted {{tokens}}` → step 05 fails.
- **Root cause:** `config.example.yml`'s line-6 comment documenting the gate literally contained `{{...}}`. `sed` substitutes the two real tokens (`PROJECT_NAME`, `DUCKDB_PATH`) even inside comments, so only the meta-comment's braces survived, and the gate's `grep -q '{{'` flagged them. Would fail every install.
- **Resolution:** reworded the comment to drop the literal braces. **Commit `09f5d4e`.**
- **Secondary note (not fixed, backlog):** the gate greps bare `{{`, so any user comment containing double-braces would false-positive. Tightening to `{{[A-Z_]\+}}` (real token shape) would be more robust.

### Finding 2 — step 07 portal gate raced nginx graceful reload
- **Stage:** 07 (nginx), verify gate.
- **Symptom:** `portal body looks like default nginx welcome, not our portal` — intermittently — despite the portal being deployed correctly (the docroot file and a later curl both showed our portal).
- **Root cause:** the gate curled `localhost/` exactly once, immediately after `systemctl reload nginx`. Reload is graceful — old workers can keep serving the prior (default-site) config during cutover — so the single curl raced it.
- **Resolution:** poll the body check up to 10×/0.5s until the marker appears. **Commit `d389251`.**

### Finding 3 — `oxy.service` ExecStart used `%h` → `/root` (203/EXEC)
- **Stage:** 08 (systemd units).
- **Symptom:** `oxy.service` restart-loops with `status=203/EXEC`; `systemctl show` resolved `ExecStart` to `/root/.local/bin/oxy`.
- **Root cause:** the unit used `ExecStart=%h/.local/bin/oxy`. systemd's `%h` resolves to the **service manager's** home (`/root` for system units), **not** the `User=ubuntu` home — a documented systemd gotcha the unit's own comment got wrong. The binary is at `/home/ubuntu/.local/bin/oxy`.
- **Resolution:** replaced `%h` with a `{{HOME_DIR}}` token that script 08 substitutes with the install user's real home, parallel to `{{PROJECT_ROOT}}`. **Commit `dbb20f7`.**

### Finding 4 — timer/​smoke-run DuckDB collision + step 09 didn't wait
- **Stage:** 08 → 09.
- **Symptom:** step 09 `run.sh` died on its first line: `Could not set lock on file stack.duckdb: Conflicting lock is held in /usr/bin/python3.12`. `fct_smoke_test` empty; step 09 "elapsed 1s".
- **Root cause (4a):** step 08 enabled the timers with `systemctl enable --now`. `pipeline-refresh.timer` has `Persistent=true`, so activating it after its `06:00` `OnCalendar` fired an immediate **catch-up `run.sh daily`** *during* install (confirmed: `pipeline-refresh.service activating since 20:04, TriggeredBy pipeline-refresh.timer`). That collided with step 09's `run.sh manual` on DuckDB's single-writer lock — a violation of the sequential-DuckDB rule.
- **Root cause (4b):** independently, step 09 launched `run.sh` with `setsid` **without `-w`**, which returns the instant it forks the child into a new session rather than waiting. So the verify gate ran ~1s in, against an empty warehouse, even absent the collision. The unit comment claimed it "blocks on completion" — it didn't.
- **Resolution:** (4a) step 08 enables timers for boot persistence but **not `--now`**; they activate on next boot, when the Persistent catch-up runs with no concurrent manual run; verify checks `is-enabled`. (4b) `setsid -w`. **Commit `b5c30cc`.**
- **Validation choice:** the re-run used `SMOKE_MODE=small` (10k rows) rather than the default `medium` (~250k), because medium was hitting NYC 311 SODA API read-timeouts (retry 1/4, 2/4). The F6 contract is proven identically at any row count. **Observation (not a bug):** the default `medium` smoke against the live SODA API was slow/flaky on this run; worth considering `small` as the install default or tuning the dlt retry/timeout (backlog).

### Finding 5 — step 10 verify required timers active (consequence of 4a)
- **Stage:** 10 (final verify).
- **Symptom:** 3 failures — `pipeline-refresh.timer / source-health-check.timer / profile-tables.timer NOT active`.
- **Root cause:** after Fix 4a the timers are enabled-but-not-active during install (by design); step 10 still asserted `is-active`.
- **Resolution:** added a `check_enabled` helper; step 10 now verifies the timers are **enabled** (boot-persistent), consistent with step 08. **Commit `9e58ec2`.**
- **Design note (documented, not a stub):** the install leaves the 3 timers enabled but inactive in the install boot; they activate on next reboot. This deliberately avoids re-introducing the Persistent catch-up collision. Same-boot activation with proper run.sh/oxy lock coordination is backlog ("lock-aware run.sh" is out of Plan-3 scope).

### Finding 6 — oxy DuckDB database used `dataset:` instead of `path:` (the F6 blocker)
- **Stage:** Phase 3 (F6 query) — *not* caught by any install gate.
- **Symptom:** the agent generated correct SQL but `execute_sql` failed: `DuckDB path '…/stack.duckdb' must be a directory containing .csv or .parquet files.`
- **Root cause:** `config.example.yml` declared the warehouse DB with `dataset: <file>`. oxy's duckdb connector treats `dataset:` as a **directory of CSV/parquet files**; to open an existing `.duckdb` database **file** it needs `path:` (confirmed against the proven `oxygen-mvp` config). Shared by `oxy.service`, so the browser chat would fail identically.
- **Why no gate caught it:** step 10 only checked `:3000 → 200` (SPA static) and queried DuckDB **directly via python**, never **through oxy**. This is exactly the gap the missing `oxy validate` gate (backlog B1) and an "agent answers a real query" gate would close.
- **Resolution:** `dataset:` → `path:`. **Commit `3674088`.** Post-fix, `oxy validate` → "All 5 config files are valid", and the agent answers correctly.

---

## F6 trust contract — proven on metal

Asked via `oxy run agents/answer_agent.agent.yml` against the running install:

**Q: "how many 311 service requests are in the warehouse?"**
- SQL: `SELECT COUNT(*) AS total_requests FROM main_gold.fct_smoke_test;`
- Result: **10000**
- Reply: row-count line + plain answer + `Citations:` (`main_gold.fct_smoke_test`, `smoke_test` view). No limitations section — correct: none of the registry entries apply to a bare count.

**Q: "how many 311 service requests are there in each borough?"** (to exercise limitation surfacing)
- SQL: `SELECT borough, COUNT(*) … GROUP BY borough ORDER BY … DESC`
- Result: Brooklyn 3281, Queens 2309, Manhattan 2145, Bronx 1616, Staten Island 427, Unspecified 222 (6 rows)
- Reply: row count + answer + `Citations:` (incl. `borough-unspecified-bucket`) + **Known limitations** section correctly surfacing the borough-unspecified caveat with its analyst-facing impact.

All four trust-contract sections (row count, answer, citations, limitations) fire when relevant and stay silent when not. **F6 met.**

---

## Honest validation caveat

The install was validated by **fix-and-resume** on a single instance, not by a clean from-scratch run of the final corrected scripts. Each fix is committed and the end state is proven (all 10 gates green, F6 works), but two specific code paths were not re-exercised on a pristine box:
- **Step 08's `enable` (no `--now`) line** — on the live box the timers were already enabled (from the original `--now`) then stopped, so the new code path reached the "already enabled" branch rather than the new `enable` line. Logically equivalent end-state, but the exact line wasn't run.
- **A single clean pass of 00→10** with all six fixes present from the start.

**Recommended confirmation:** a from-scratch install on a new t4g.medium with the corrected branch (expected clean). Cheap insurance before declaring the template battle-tested.

---

## Operational notes

- Box reachable on the tailnet at `stack-in-a-box.taildee698.ts.net` (`100.81.97.55`); public SSH (22) + 3000 closed at the AWS SG; only 80 public.
- Install scaffolding left on the box (not part of the repo): `~/launch_bootstrap.sh`, `~/ask_agent.sh`, `~/run_oxy.sh`, and `~/.sib-secrets/` (the Anthropic + Tailscale keys, mode 600). Remove `~/.sib-secrets/` if the box is repurposed.
</content>
