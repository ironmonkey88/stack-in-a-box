# IMPROVEMENTS_BACKLOG.md — consolidated recommended improvements

One place for every recommended improvement surfaced across all dry-run work and the v4 handoff, de-duplicated and tagged to the plan that should execute it. Before this doc, these were scattered across `DRY_RUN_FINDINGS.md` (11 script-level iterations), `FLOW_DRY_RUN_FINDINGS.md` (18 flow-level scenarios, F1-F18), the v4 handoff's cross-batch flags (§10) and out-of-scope list (§11), and the resolved open decisions.

**Already shipped (not in this backlog):** the in-plan fixes from the dry-run passes — `PROJECT_ROOT` auto-derivation, `curl -sI` preflight, `flock`, cloud-init wait, env-var secret override, `setsid` smoke test, IMDSv2 SG check (all script-level v1-v4); and from the flow passes: design-plan §4 token-convention correction (F6-3), `10_verify` SG self-check best-effort labeling (F7-3), Oxygen-installer `curl` timeout (F11), `PROJECT_NAME` sed-injection guard (F18), README count (F15), CLAUDE.md §1 orientation-timing honesty (F16). Those are done; what follows is what remains.

**Priority key:** P0 = hard contract / install-blocking · P1 = real robustness or correctness gap · P2 = polish / docs / nice-to-have.

---

## A. Plan 2 — contract the second batch MUST honor (P0)

These aren't "improvements to add" — they're constraints. The v4 setup scripts already hard-code these names/paths in their verify gates; if the second-batch artifacts don't match, the install fails even when it "worked." Source: dry-run F6.

| ID | Requirement | Source |
|---|---|---|
| C1 | Gold smoke model is exactly `main_gold.fct_smoke_test`; admin pipeline-run table is exactly `main_admin.fct_pipeline_run_raw`. (Hard-coded in `09_first_run.sh` + `10_verify.sh`.) | F6-1 |
| C2 | DuckDB file is `$PROJECT_ROOT/data/stack.duckdb` — `run.sh`, `config.yml`, and `dbt/profiles.yml` must all resolve to it. | F6-2 |
| C3 | `config.example.yml` and `dbt/profiles.example.yml` may use ONLY `{{PROJECT_NAME}}` and `{{DUCKDB_PATH}}` tokens — any other `{{...}}` trips `05`'s unsubstituted-token die. | F6-5 |
| C4 | `nginx/stack-in-a-box.conf` must hardcode docroot `/var/www/stack-in-a-box` (script `07` copies it verbatim — no token substitution). | F6-3, F6 |
| C5 | `run.sh manual` must populate C1's two tables AND deploy the 5 portal pages (`/metrics`, `/trust`, `/profile`, `/erd`, plus dbt `/docs/`) to `/var/www/stack-in-a-box/` — NOT to `$PROJECT_ROOT/portal/`. (`10_verify` checks these routes return 200.) | F6-4, handoff §10.1 |

---

## B. Plan 2 — improvements to build into the second batch (P1)

Concrete additions that belong with the artifacts they touch (mostly `run.sh` and the helper scripts, which don't exist yet — that's why these are Plan 2, not now).

| ID | Improvement | Source | Notes |
|---|---|---|---|
| B1 | **`oxy validate` gate.** `run.sh` (or a pre-smoke step) must validate the semantic layer + agent config and fail loud. Today a malformed `agent.yml` / `view.yml` / `topic.yml` passes every automated gate and only surfaces at `10`'s manual browser step. | F10-c | Closes the one automated-coverage blind spot (config validity vs. data/routes/services). |
| B2 | **DuckDB-lock-aware `run.sh` + orphaned-run cleanup.** `run.sh` must (a) detect/skip-or-retry when another run holds the single-writer DuckDB file, and (b) on startup, mark in-progress `fct_pipeline_run_raw` rows with no end-time (from a killed pipeline) as `crashed`. | F12-b, handoff §10.2, iter #66 | The timer-vs-manual collision window is real once timers fire (post-Plan-2). |
| B3 | **Timer ordering.** Consider enabling the `pipeline-refresh` / `source-health-check` / `profile-tables` timers *after* the first smoke run completes, rather than in step `08` before it — so a scheduled run can't collide with the manual smoke test. | F12-b | Alternative/complement to B2. A `08`-vs-`09` ordering tweak. |
| B4 | **`source_health_check.py` should flag post-install `tailscale set --ssh=true`.** An operator re-enabling Tailscale SSH silently re-breaks `/etc/environment` env-var loading; the health check should detect and warn. | iter #63 | Belongs with the admin/observability helpers Plan 2 builds. |
| B5 | **`make rip-out-smoke-test` target.** Per resolved decision #3 (smoke lives in main path with delete-me markers), ship the clean-removal target so a user can strip the NYC 311 smoke files when wiring their own data. | decision #3 | Pairs with the 🚧 delete-me markers in the smoke-test file headers. |

---

## C. Plan 2 — documentation to write (P2)

The doc files named in design-plan §4 as part of the second batch, plus teardown.

| ID | Doc | Source | Notes |
|---|---|---|---|
| D1 | **`HARDENING.md`** — post-install steps deliberately out of the install path: HTTPS (Caddy / Let's Encrypt + nginx), Basic Auth on `/chat` (htpasswd; `apache2-utils` is already installed by `01`), backups (DuckDB file snapshots + off-instance retention). | handoff §11 | Named in §4's repo layout. |
| D2 | **`SWAP_IN_YOUR_DATA.md`** — the "just add data" 8-step checklist: which files to edit to point the pipeline at a real source instead of NYC 311. | design plan §4, §7 | The headline value-prop doc. |
| D3 | **`ARCHITECTURE.md`** + **`SETUP.md`** — what's wired and why; long-form install (the scripts are the short form). | design plan §4 | |
| D4 | **`TEARDOWN.md`** (or `make teardown`) — there is no clean-slate path today. A `rm -rf repo && re-clone` leaves `/etc/environment`, systemd units, Docker containers, the Tailscale node, nginx config, and `/var/www/stack-in-a-box/`. Document (or script) the teardown. | F14-a, iter #70 | Re-install is idempotent, so this is P2, but the absence should be documented not discovered. |

---

## D. Plan 2 — small now-or-then fixes (P2)

Cheap items against *existing* scripts. Deferred to Plan 2 only because Plan 2 will likely touch the same scripts — fold them in rather than make a separate pass. (Any of these could also be done standalone if desired.)

| ID | Fix | Source | Notes |
|---|---|---|---|
| E1 | **Preflight proxy hint.** Add "if you're behind an HTTP proxy, `export https_proxy` before running" to `00_preflight.sh`'s network-failure message. Today a filtered-egress VPC sees 6 "unreachable" failures with no hint why. | F9-b | One log line. |
| E2 | **`--force` note for partial-install reruns.** If Plan 2 modifies any of scripts `00-03`, document that partial-install users must `bootstrap.sh --force` (or clear `scratch/checkpoints/`) to pick up the change — checkpointed steps are otherwise skipped silently. | F5-b | A README/CLAUDE note, contingent on Plan 2 touching 00-03. |
| E3 | **Remove the CLAUDE.md §1 "Current install state" caveat** as part of Plan 2's housekeeping, once the install actually completes end-to-end. | Plan 1 (C3) | The caveat is self-marked "removed when Plan 2 lands." |

---

## E. Plan 3 — first real install (P1, but gated on Plan 2)

| ID | Item | Source | Notes |
|---|---|---|---|
| F1 | **Run `bootstrap.sh` end-to-end on a fresh t4g.medium.** Budget ~90 min (60 install + 30 buffer for "the one thing we forgot"). Capture the first real failure, fix, iterate 2-3×. This is the validation no dry run can substitute for — external-service behavior, real hardware timing, NYC 311 under load, the actual `get.oxy.tech` installer behavior. | handoff §7-8, all flow docs' "stop signal" | The dry-run campaign explicitly converged here. |
| F2 | **Capture the working Oxygen version** during F1 (feeds Plan 4). | decision #4 | |

---

## F. Plan 4+ / optional (P2)

| ID | Item | Source | Notes |
|---|---|---|---|
| G1 | **Retroactive Oxygen version pin** in `03_install_oxygen.sh`, using the version Plan 3's first install proved out. Replaces the `get.oxy.tech` latest + TODO. | decision #4 | Plan 4. |
| G2 | **USGS (or other non-SODA) alt-smoke-test in `examples/`** — validates the template isn't accidentally SODA-coupled. | decision #2 | Post-v1, optional. |
| G3 | **Repo rename**, if a better name than `stack-in-a-box` emerges. Contained one-plan task (rename + update README/CLAUDE/script `PROJECT_NAME` defaults + the `05` repo URL). | decision #5 | Only if desired. |
| G4 | **`shellcheck` in CI + branch protection** on the repo, once it has accumulated content. | handoff §11 | Day-N infrastructure. |

---

## How to use this backlog

- **Plan 2 picks up A (honor as constraints) + B + C + D.** A is non-negotiable; B/C/D are the improvement content. The 16 missing artifacts from design-plan §9 are Plan 2's core build — this backlog is the *additional* hardening + docs to fold in alongside them.
- **Plan 3 is E.** It's gated on Plan 2 (no install completes until the second batch ships).
- **Plan 4+ is F.**
- Each item cites its source finding so the full context is one grep away (`grep -rn "F12-b\|§10" docs/design/`).
- When an item ships, strike it here (or note the commit) so the backlog stays a live punch-list, not a stale wish-list.
