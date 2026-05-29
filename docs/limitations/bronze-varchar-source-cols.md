---
id: bronze-varchar-source-cols
title: Bronze keeps source columns as VARCHAR — no type coercion
severity: info
affects:
  - main_bronze.raw_nyc_311_raw
  - raw_nyc_311
since: 2026-05-28
status: active
---

# Bronze keeps source columns as VARCHAR

`main_bronze.raw_nyc_311_raw` is an exact mirror of the NYC 311 SODA feed.
Dates, coordinates, and IDs all arrive as `VARCHAR`. Type casting and value
normalization are deferred to gold (`main_gold.fct_smoke_test`), where
`created_date`/`closed_date` become `TIMESTAMP`/`DATE` and lat/long become
`DOUBLE`.

## Impact

- Querying bronze directly requires explicit casts:
  `CAST(created_date AS TIMESTAMP)`, `TRY_CAST(latitude AS DOUBLE)`, etc.
- Date filters using string comparison work for ISO-8601 dates only.

## Workaround

Don't query bronze for analyst questions — query `main_gold.fct_smoke_test`
and the gold dims, which carry typed columns. Bronze exists for lineage and
reprocessing, not analysis.

## Resolution path

None planned for the smoke test. When you add a silver layer, land typed,
deduplicated, PII-redacted versions of the source columns there.
