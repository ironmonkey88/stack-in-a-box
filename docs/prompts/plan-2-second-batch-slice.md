# Prompt — Plan 2: the second batch (contract-critical slice)

**Status:** Code-originated from a confirmed scope decision, not a Chat-issued prompt. The user said "execute"; an `AskUserQuestion` confirmed the target as **Plan 2, contract-critical slice**. This file records that spec per the prompt-file convention so the lineage exists.

**Kind:** coding
**Date:** 2026-05-28
**Plan:** 2 (stack-in-a-box ledger)
**Scope:** new `requirements.txt`, `config.example.yml`, `dbt/` (project + profiles + bronze/gold/admin models), `dlt/` (NYC 311 pipeline + load_dbt_results), `semantics/`, `agents/`, `scripts/` (run helpers + portal generators), `systemd/`, `nginx/`, `portal/`, `run.sh`, `docs/schema.sql`. Housekeeping in LOG/TASKS/CLAUDE.
**Effort:** large (the second batch). This slice defers the B-hardening items + C-docs from `IMPROVEMENTS_BACKLOG.md`.

## Outcome

A fresh-EC2 install no longer dies at step 05. The application layer exists: a user who runs `bootstrap.sh` can get through clone+config (05), venv (04), nginx (07), systemd (08), the smoke-test pipeline (09), and verify (10) — with the warehouse built end-to-end from a real NYC 311 pull and the trust contract firing on the first agent query. This slice ships the artifacts; the first *real* EC2 run is Plan 3.

## Work (the contract-critical artifacts)

Build the minimum from design-plan §9 to make the install runnable end-to-end, honoring the `IMPROVEMENTS_BACKLOG.md` §A contract: gold `main_gold.fct_smoke_test`, admin `main_admin.fct_pipeline_run_raw`, DuckDB `data/stack.duckdb`, config/profiles two-token whitelist, nginx docroot hardcoded `/var/www/stack-in-a-box`, run.sh deploys 5 portal pages to the docroot.

Groups: (1) dbt project + profiles + requirements + config; (2) dlt NYC 311 pipeline + load_dbt_results + bronze/gold/admin dbt models; (3) semantic views + topic + agent + schema.sql; (4) run-helper + portal-generator scripts; (5) run.sh + systemd units + nginx conf + portal index; (6) housekeeping.

## Verification

**This is a local build — no EC2, and dbt/oxy/dlt are not installed here.** Plan 2's gates are STATIC: `py_compile` on Python, YAML parse on configs, `bash -n` + shellcheck on shell, and contract-honored-by-reading. The LIVE-functional gates (`dbt run`, `oxy validate`, `./run.sh manual`, agent smoke) are **Plan 3** on a real t4g.medium. The CLAUDE.md §1 caveat is UPDATED (not removed) to "artifacts present but never EC2-executed."

## Out of scope (deferred per the backlog)

B-items (oxy-validate gate, lock-aware run.sh + orphaned-run cleanup, timer ordering, tailscale-SSH health check, `make rip-out-smoke-test`); C-docs (HARDENING / SWAP_IN_YOUR_DATA / ARCHITECTURE / SETUP / TEARDOWN); the `/chat` Basic-Auth nginx scaffolding; full-fidelity portal generators (lean functional versions for the slice).

## Commit shape

One branch `claude/plan-2-second-batch-slice`, committed in logical groups, single PR, autonomous merge. If the build runs long, ship a `partial` with the groups that landed cleanly and a clear remainder.

## Notes

External-schema best-effort: NYC 311 column names and the exact Oxygen `config.yml` schema are written from documented shape, not live inspection — Plan 3's real run is where they get validated against reality. Smoke-test files carry 🚧 delete-me markers (decision #3).
