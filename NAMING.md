# NAMING.md: naming standard for every stack instance

**Status:** standard as of 2026-11-19 (Gordon's decision). It is taken from **wong-way-warehouse**, the instance that runs
in production every day (about 40 silver and 50 gold models), and it replaces the `raw_`/`stg_` scheme that
used to live in `CLAUDE.md` §6. **Read this before generating any model, table or column (R14).** If an instance
disagrees with this file, that's a drift finding (R13): fix the instance in its next plan rather than renaming in passing.

## Schemas

| Schema | Holds | Written by |
|---|---|---|
| `bronze` | Each source exactly as it arrived, tagged with its load (R9, R10) | dlt |
| `silver` | The warehouse proper (METHODOLOGY R19): typed, deduped, current-load, rules applied, quality flags, PII/coordinates removed, and related: keys, facts and conformed dimensions at detail grain | dbt |
| `gold` | Easy to use: marts for readers, detail allowed, rolled up where it helps; metric tables from the semantic layer ("gold plus") | dbt |
| `admin` | Run log, load audit, diagnosis, health, test results | dbt + run tools |

Never create a new schema from a model. Schemas, and the grants on them, are declared in the server's database setup first.

## Relations

| Layer | Pattern | Examples |
|---|---|---|
| bronze | `<source>_<entity>`, the dlt resource name. No prefix, because the schema already says bronze. | `weightgurus_operations`, `garmin_raw`, `gym_sessions` |
| silver (source-aligned) | `<source>_<entity>` for one source. A plain concept name when it merges sources. | `garmin_hrv`, `weight_weighins`, `daily_metric_values` |
| silver (integrated, R19) | `fct_<grain or event>`, `dim_<entity>`, `bridge_<a>_<b>`: conformed dimensions and facts keyed to them | `dim_date`, `dim_ward`, `fct_311_request` |
| gold marts | `mart_<audience or topic>_<grain>`, or `fct_`/`dim_` when gold re-exposes a silver star for readers |  `mart_wheelhouse_block_year` |
| gold facts | `fct_<grain or event>` | `fct_daily_health`, `fct_activity_minute`, `fct_sleep_night` |
| gold dimensions | `dim_<entity>` | `dim_date`, `dim_person`, `dim_place` |
| gold bridges | `bridge_<a>_<b>` | `bridge_dish_ingredient` |
| gold metric tables | `metrics_<period>` (materialised from the semantic layer) | `metrics_daily`, `metrics_weekly` |
| admin | `admin_<thing>`, or the plain name of a run table | `admin_run_freshness`, `load_audit`, `run_log` |

- `<source>` is one snake_case slug per source. The same slug names the pull script, the dlt pipeline, the landing folder
  and the bronze tables: `pull/<source>.py`, `dlt/pipelines/<source>.py`, `landing/<source>/`.
- Landed files: `<entity>-<YYYY-MM-DD>.json` (one per pull), never edited.

## Columns

| Kind | Convention | Example |
|---|---|---|
| Gold surrogate / foreign key | `<entity>_key` | `date_key`, `person_key` |
| Source's natural ID | `<entity>_id` | `activity_id` |
| Date | `_date` | `weighed_date` |
| Timestamp | `_at`, with time zone stated: `_utc` / `_local` where both exist | `weighed_at`, `start_local` |
| Units | Unit as suffix. Never a bare number. | `weight_lb`, `duration_min`, `distance_km` |
| Quality flag | `<measure>_quality` or `flag`, values `ok` / `suspect` / `invalid` / `missing` (plus source-specific verdicts documented in the context file) | `hrv_quality` |
| Boolean | `is_` / `has_` | `is_asleep`, `is_current` |
| Load tag (bronze) | `file_name` or `_dlt_load_id` | |

Everything is snake_case. For minutes, prefer `_min`. Instances that also use `_minutes` should converge on `_min` in their
next plan (a known drift in wong-way-warehouse).

## Exceptions in this repo
`dbt/models/bronze/raw_nyc_311.sql` (the smoke dataset) still uses the old `raw_` prefix. Renaming it is a TASKS item,
not a passing edit, because it touches the smoke run and its verify gates.
