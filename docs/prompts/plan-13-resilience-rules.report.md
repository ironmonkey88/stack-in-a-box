# Report — Plan 13: pipeline-operations rules (R9–R13)

**Status:** complete (docs + config). Porting the reference scripts to the DuckDB shape is a tracked follow-on (TASKS.md).

## What shipped
- METHODOLOGY.md: R9 raw never fails a run / no `--fail-fast`; R10 append-by-load, self-cleansing bronze (+ incremental
  pulls, no retry loops); R11 evidence before cause, diagnose where the evidence is; R12 scheduled hygiene; R13 instance
  drift audit. All `stack-only`; five propagation rows.
- STANDARDS.md: §2 bronze (warn severity judged on the newest load, append-by-load, arrival audit, pulls); §3 silver dedup
  discipline (fills the placeholder); §5 admin (`fct_load_audit`, `fct_run_diagnosis`, `fct_db_health`); new §11 Operations
  (outcome ok/partial/failed, no fail-fast, diagnosis, playbook, hygiene, Postgres baseline, drift audit); sign-off → §12.
- `dbt/dbt_project.yml`: `data_tests: stack_in_a_box: bronze: +severity: warn`.
- CLAUDE.md §10: `--fail-fast` reports cancelled nodes as ERROR.

## Verification gate
`dbt parse` with the pinned dbt-core 1.11.9 / dbt-duckdb 1.10.1: the 3 bronze tests resolve to `warn`; all 19 admin and
gold tests stay `ERROR`.

## Evidence behind the rules (from the instance, proven there on a scratch Postgres)
A rerun of the same pull replaced itself; retention kept the newest N pulls; a truncated pull was rejected and silver kept
the previous one; a record sent three times came out once; diagnosis named the failing test first with the other
evidence after it; hygiene kept failing tests' tables and snapshots and dropped only empty and orphaned ones.

## Next
Plan 13 follow-on: port `diagnose.py`, `hygiene.py`, `build_report.py`, `load_audit` and `current_load` to this stack.
