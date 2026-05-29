# Prompt — Plan 3: first real install (handoff to next Code)

**Status:** Next-Code handoff, written at the end of the Plan 2 session. Not yet started. This is the authoritative "here's your job" briefing for the Code instance that picks up Plan 3.
**Kind:** coding + ops (human-in-the-loop — not fully autonomous)
**Date written:** 2026-05-28
**Plan:** 3 (stack-in-a-box ledger)
**Effort:** ~90 min wall clock on a real t4g.medium (60 install + 30 buffer for "the one thing we forgot"), plus fix/iterate cycles.

---

## Where things stand (read this first)

Plan 2's contract-critical slice **shipped and merged** (PR #6, `de56048`). The application layer now exists and is on `main`: dlt NYC 311 pipeline, dbt bronze/gold/admin models, semantic layer + Answer Agent, run-observability + profiling + portal-generator scripts, `run.sh`, `nginx/stack-in-a-box.conf`, 7 systemd units, first-boot `portal/index.html`.

**Critical:** none of it has run on EC2. It passed static checks only (py_compile, YAML parse, `bash -n`, shellcheck, contract cross-check). Plan 3 is the first time the box actually runs. Treat every external-facing assumption as unverified until this run proves it.

**Read before starting:** `LOG.md` (state + 3 decisions from Session 2), `docs/handoffs/2026-05-28-plan-2-second-batch-slice.md` (§4 risks, §5 deferred), `docs/design/IMPROVEMENTS_BACKLOG.md` (§A satisfied; §E is this plan), `scripts/setup/README.md` (the install flow + bootstrap flags).

## Preconditions (human, before Code can run anything)

This plan is **not** auto-executable — the user must provision and supply:

1. A fresh **t4g.medium** EC2 instance (Ubuntu), reachable. `bootstrap.sh` is the entry point; it runs scripts 00→10 with checkpoints in `scratch/checkpoints/`.
2. An **Anthropic API key** (script 05 writes it to `/etc/environment`).
3. **Tailscale auth** (script 06 — `--ssh=false` is load-bearing; see CLAUDE.md §10).
4. **AWS Security Group access** — the user closes public 22 + 3000 mid-install (script 06 prints the manual step; script 10 re-checks).

Confirm these are in hand before invoking `bootstrap.sh`. If the user opens Code cold in this repo, run the CLAUDE.md §1 orientation first — do **not** start the install unprompted.

## The job

Run `bootstrap.sh` end-to-end on the fresh instance. Capture the first real failure, fix it, re-run (use `bootstrap.sh --only N` to resume at a step, `--force` to re-run a checkpointed step after editing scripts 00–03). Iterate 2–3× until all 11 steps pass and script 10's gate is green. This is the validation no dry run can substitute for.

## Watch these carried risks (ranked)

1. **Docroot write-permission seam (highest-probability break).** Script 07 creates `/var/www/stack-in-a-box` as `www-data:755`. `run.sh` runs as `ubuntu` and writes the 5 portal pages there. `deploy_html` (and the dbt-docs copy in run.sh stage 6) fall back to `sudo` when the dir isn't writable — this assumes default-EC2 passwordless sudo for `ubuntu`. If `cp`/`mkdir` into the docroot fails during run.sh stages 6–9e, this is why; the fix is either the sudo path working or making 07 chown the docroot `ubuntu:www-data`. **Verify the portal actually deploys, don't just trust exit 0.**
2. **External-schema guesses, now testable against reality:**
   - NYC 311 column names in `dlt/smoke_test_pipeline.py` `COLUMNS` (best-effort; the SODA API is authoritative — if a column 400s, trim it).
   - `oxy start --local` readiness timing (script 08 polls :3000 up to 90s; real cold-start with the postgres container may differ).
   - `oxy validate` / the `config.yml` + agent + view/topic grammar — **there is no `oxy validate` gate in run.sh yet** (backlog B1), so a malformed YAML first surfaces at script 10's manual browser step. Consider adding the gate early in this plan.
   - dbt-duckdb schema materialization: confirm `+schema: gold` → `main_gold` (not bare `gold`) on this dbt-duckdb version, and that `fct_smoke_test` lands in `main_gold`.
3. **The agent smoke (script 10's manual browser step).** Ask the chat "how many records are in the warehouse?" — expect SQL `SELECT COUNT(*) FROM main_gold.fct_smoke_test`, a row count, and a citation. This is the trust-contract proof and the real sign-off moment.

## Deliverables

- A green `bootstrap.sh` run (all 11 steps; script 10 all curl-able checks pass + the manual agent step confirmed).
- **The working Oxygen version** captured (feeds Plan 4's retroactive pin — decision #4). Read it from `oxy --version` and `/api/health` on the running instance.
- CLAUDE.md §1 caveat **fully removed / replaced** with a "validated on EC2 <date>, Oxygen <version>" note (it currently reads "assembled and checked, not yet proven on metal").
- LOG.md + TASKS.md + a Session 3 file + this prompt's sibling `plan-3-first-real-install.report.md`.
- Fold in any backlog B/D items that the real run makes obviously necessary (especially B1 `oxy validate` if a YAML bug bites).

## Notes / in-repo gotchas for the next Code

- **Bash safety hook (when settings land):** no `&&`/`;`/`||` chains, no `$(...)`, no leading `cd`, no shell redirects to create files — one command per Bash call, use the Write tool for files. (Settings.json isn't committed in this repo yet — CLAUDE.md §4 notes this.)
- **Stale-tracking-ref pattern:** after `gh pr merge`, local `main` is behind — `git pull origin main` to fast-forward before more work.
- **PR numbering:** issues + PRs share numbers here; the Plan 2 PR was #6, not #2. Check the actual number after `gh pr create`.
- **Autonomous merge** applies to verified work on this repo (CLAUDE.md §3) — but Plan 3 is human-in-the-loop and likely lands `partial`/iterative, so pause and surface rather than auto-merging a half-validated install.
- **Don't re-run the dry-run campaign.** It explicitly converged on "the next validation is metal." 29 dry runs found the static issues; the remaining unknowns are only findable by running.
