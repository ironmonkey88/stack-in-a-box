{{ config(materialized='table', schema='gold') }}

-- 🚧 SMOKE TEST. One row per distinct NYC borough observed in bronze.
with src as (
    select coalesce(nullif(trim(borough), ''), 'Unspecified') as borough
    from {{ ref('raw_nyc_311') }}
)
select
    md5(borough)   as borough_id,
    borough,
    count(*)       as request_count
from src
group by borough
