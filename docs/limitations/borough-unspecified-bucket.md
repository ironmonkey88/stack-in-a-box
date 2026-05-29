---
id: borough-unspecified-bucket
title: NYC 311 borough is often "Unspecified" or NULL
severity: warning
affects:
  - smoke_test
  - smoke_test.borough
  - boroughs
  - main_gold.dim_borough
since: 2026-05-28
status: active
---

# Borough is frequently missing in NYC 311

A meaningful share of NYC 311 service requests carry no usable borough — the
source value is NULL, blank, or the literal `"Unspecified"`. Gold collapses all
of these into a single `Unspecified` bucket (`md5('Unspecified')`).

## Impact

- Per-borough counts under-report real geographic distribution: requests with a
  missing borough are not redistributed, they sit in `Unspecified`.
- `dim_borough` therefore contains an `Unspecified` row whose `request_count`
  can be large. Treat it as "unknown location", not a real borough.

## Workaround

When answering "which borough has the most X", exclude the `Unspecified` bucket
explicitly (`WHERE borough <> 'Unspecified'`) and state that you did so, or
report it as a distinct "unknown" category. Do not present `Unspecified` as if
it were a borough.

## Resolution path

None for the smoke test. A real pipeline could backfill borough from
`incident_zip` or lat/long via a spatial join.
