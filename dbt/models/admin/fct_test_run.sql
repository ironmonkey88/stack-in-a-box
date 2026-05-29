{{ config(
    materialized='incremental',
    schema='admin',
    incremental_strategy='append'
) }}

-- One row per dbt test per run. Append-only with an is_incremental filter on
-- run_id so a run's results are never duplicated. Source: the dbt run-results
-- landed by dlt/load_dbt_results.py. The /trust page reads this table.
--
-- Lean version for the smoke test: dbt test results only (no baseline
-- comparisons — see dim_data_quality_test).
with latest_run as (
    select run_id, max(loaded_at) as run_at
    from main_bronze.raw_dbt_results_raw
    group by run_id
    order by run_at desc
    limit 1
),

dbt_test_runs as (
    select
        r.run_id                                   as run_id,
        'dbt_test.' || r.node_name                 as test_id,
        r.loaded_at                                as run_at,
        cast(r.failures as varchar)                as actual_value,
        '0'                                        as expected_value,
        case r.status
            when 'pass'    then 'pass'
            when 'success' then 'pass'
            when 'warn'    then 'warn'
            when 'error'   then 'fail'
            when 'fail'    then 'fail'
            else r.status
        end                                        as status,
        r.message                                  as failure_message
    from main_bronze.raw_dbt_results_raw r
    inner join latest_run lr on r.run_id = lr.run_id
    where r.node_id like 'test.%'
)

select * from dbt_test_runs
{% if is_incremental() %}
where run_id not in (select distinct run_id from {{ this }})
{% endif %}
