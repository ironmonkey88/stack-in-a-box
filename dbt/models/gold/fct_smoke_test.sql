{{ config(materialized='table', schema='gold') }}

-- 🚧 SMOKE TEST — the gold fact the install's verify gates check for
-- (main_gold.fct_smoke_test). Delete with the rest of the smoke test when
-- you connect your own data; your real gold fact takes its place.
--
-- One row per NYC 311 service request (grain: unique_key). Surrogate PK,
-- typed dates, FKs to dim_complaint_type + dim_borough (denormalized labels
-- kept for query convenience). This is the table the Answer Agent queries
-- and that 09_first_run.sh / 10_verify.sh assert is non-empty.
with src as (
    select
        unique_key,
        created_date::TIMESTAMP                               as created_ts,
        closed_date::TIMESTAMP                                as closed_ts,
        agency,
        agency_name,
        coalesce(nullif(trim(complaint_type), ''), 'Unknown') as complaint_type,
        descriptor,
        status,
        coalesce(nullif(trim(borough), ''), 'Unspecified')    as borough,
        incident_zip,
        try_cast(latitude as double)                          as latitude,
        try_cast(longitude as double)                         as longitude
    from {{ ref('raw_nyc_311') }}
)
select
    md5(unique_key)                  as request_sk,
    unique_key,
    created_ts,
    created_ts::DATE                 as created_dt,
    closed_ts,
    closed_ts::DATE                  as closed_dt,
    agency,
    agency_name,
    complaint_type,
    md5(complaint_type)              as complaint_type_id,
    descriptor,
    status,
    borough,
    md5(borough)                     as borough_id,
    incident_zip,
    latitude,
    longitude
from src
