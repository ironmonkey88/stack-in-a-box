{{ config(materialized='view', schema='bronze') }}

-- 🚧 SMOKE TEST — bronze view over the NYC 311 SODA mirror. Delete with the
-- rest of the smoke test when you connect your own data.
--
-- Source is dlt-owned (main_bronze.raw_nyc_311_raw). This view passes the
-- columns through and casts the date strings to VARCHAR (bronze arrival
-- discipline — type casts happen in gold). All audit/lineage columns retained.
select
    unique_key,
    created_date::VARCHAR        as created_date,
    closed_date::VARCHAR         as closed_date,
    agency,
    agency_name,
    complaint_type,
    descriptor,
    status,
    borough,
    incident_zip,
    community_board,
    latitude,
    longitude,
    _extracted_at,
    _extracted_run_id,
    _first_seen_at,
    _source_endpoint,
    _dlt_load_id,
    _dlt_id
from {{ source('bronze_raw', 'raw_nyc_311_raw') }}
