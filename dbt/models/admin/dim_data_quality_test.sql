{{ config(
    materialized='incremental',
    schema='admin',
    incremental_strategy='append',
    unique_key='test_id'
) }}

-- The dbt test catalog. One row per defined test, seeded once and frozen
-- (the is_incremental filter excludes already-known test_ids). Built from
-- dbt run-results landed by dlt/load_dbt_results.py.
--
-- Lean version for the smoke test: dbt tests only, no dataset-specific
-- row-count baselines (the baseline-comparison machinery is a hardening
-- item — see IMPROVEMENTS_BACKLOG.md). Your real platform can add baselines
-- here.
with dbt_tests as (
    select distinct
        'dbt_test.' || node_name as test_id,
        case
            when node_id like 'test.%singular%' then 'dbt_singular'
            else                                     'dbt_generic'
        end                      as test_type,
        node_name                as metric,
        '0'                      as expected_value,
        true                     as is_active,
        now()                    as certified_at,
        'system'                 as certified_by
    from main_bronze.raw_dbt_results_raw
    where node_id like 'test.%'
)
select * from dbt_tests
{% if is_incremental() %}
where test_id not in (select test_id from {{ this }})
{% endif %}
