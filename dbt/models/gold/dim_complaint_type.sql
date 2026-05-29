{{ config(materialized='table', schema='gold') }}

-- 🚧 SMOKE TEST. One row per distinct NYC 311 complaint type observed in
-- bronze. Surrogate key md5(complaint_type) for stable joins.
with src as (
    select
        coalesce(nullif(trim(complaint_type), ''), 'Unknown') as complaint_type,
        created_date::TIMESTAMP                               as created_ts
    from {{ ref('raw_nyc_311') }}
)
select
    md5(complaint_type)        as complaint_type_id,
    complaint_type,
    count(*)                   as request_count,
    min(created_ts)::DATE      as first_seen_dt,
    max(created_ts)::DATE      as last_seen_dt
from src
group by complaint_type
