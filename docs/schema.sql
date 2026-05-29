-- =============================================================
-- schema.sql — DDL reference for the Answer Agent
--
-- Loaded as static context by agents/answer_agent.agent.yml so the agent
-- has full table + column shape (broader than the semantic-layer views,
-- which only enumerate query-relevant columns).
--
-- NOT the authoritative source of truth — the dbt model SQL + schema.yml
-- files are the build artifacts. When a model is added or columns change,
-- refresh this file by hand so the agent context tracks the warehouse shape.
--
-- Schema-name convention (dbt-duckdb pattern: default profile `main` +
-- `+schema: X` produces `main_X`): main_bronze, main_gold, main_admin.
-- main_silver is reserved for when you add a cleaning layer.
--
-- 🚧 SMOKE TEST — these tables describe the bundled NYC 311 dataset. Replace
-- with your own DDL when you connect your data; keep the admin tables.
-- =============================================================


-- =============================================================
-- BRONZE — raw source data, dlt-owned mirror of the SODA API.
-- No transforms. Arrival data only. dbt sees these via source().
-- =============================================================

CREATE SCHEMA IF NOT EXISTS main_bronze;

-- Raw NYC 311 service requests as received from the SODA API
-- (https://data.cityofnewyork.us/resource/erm2-nwe9.json). dlt merge target;
-- merge key is unique_key. Column set depends on SMOKE_MODE volume.
CREATE TABLE IF NOT EXISTS main_bronze.raw_nyc_311_raw (
    unique_key          VARCHAR,  -- primary key from source; dlt merge key
    created_date        VARCHAR,  -- request creation timestamp (string at bronze)
    closed_date         VARCHAR,  -- request close timestamp (string, NULL if open)
    agency              VARCHAR,  -- responding agency acronym (e.g. NYPD)
    agency_name         VARCHAR,  -- responding agency full name
    complaint_type      VARCHAR,  -- top-level category (e.g. "Noise - Residential")
    descriptor          VARCHAR,  -- sub-category detail
    status              VARCHAR,  -- Open / Closed / In Progress / ...
    borough             VARCHAR,  -- NYC borough; may be NULL or "Unspecified"
    incident_zip        VARCHAR,  -- ZIP of the incident, sparse
    community_board     VARCHAR,  -- community board, sparse
    latitude            VARCHAR,  -- string at bronze; cast in gold
    longitude           VARCHAR,  -- string at bronze; cast in gold

    -- audit columns emitted by the dlt pipeline, retained at every layer
    _extracted_at       VARCHAR,  -- ISO timestamp of the extract
    _extracted_run_id   VARCHAR,  -- run.sh RUN_ID that produced this row
    _first_seen_at      VARCHAR,  -- first time this unique_key was loaded
    _source_endpoint    VARCHAR,  -- SODA endpoint the row came from
    _dlt_load_id        VARCHAR,  -- dlt load identifier, retained for lineage
    _dlt_id             VARCHAR   -- dlt row identifier, retained for lineage
);

-- Raw dbt run-results, appended by dlt/load_dbt_results.py after each
-- `dbt test` so the admin DQ tables can read test outcomes.
CREATE TABLE IF NOT EXISTS main_bronze.raw_dbt_results_raw (
    run_id              VARCHAR,  -- dbt invocation id for the run
    node_id             VARCHAR,  -- dbt node id (e.g. test.<pkg>.<name>)
    node_name           VARCHAR,  -- short node name
    status              VARCHAR,  -- pass / warn / error / fail / success
    failures            BIGINT,   -- failing row count (0 = pass)
    message             VARCHAR,  -- dbt message, NULL on pass
    loaded_at           TIMESTAMP -- when this result row was landed
);


-- =============================================================
-- GOLD — business-ready star schema over the 311 data.
-- Typed, deduped, surrogate keys. The Answer Agent queries these.
-- =============================================================

CREATE SCHEMA IF NOT EXISTS main_gold;

-- One row per NYC 311 service request (grain: unique_key). The install's
-- verify gates assert this table exists and is non-empty.
CREATE TABLE IF NOT EXISTS main_gold.fct_smoke_test (
    request_sk          VARCHAR,  -- surrogate PK — md5(unique_key)
    unique_key          VARCHAR,  -- natural key from NYC 311
    created_ts          TIMESTAMP,
    created_dt          DATE,     -- request creation date
    closed_ts           TIMESTAMP,
    closed_dt           DATE,     -- request close date (NULL when open)
    agency              VARCHAR,
    agency_name         VARCHAR,
    complaint_type      VARCHAR,  -- denormalized label
    complaint_type_id   VARCHAR,  -- FK to dim_complaint_type — md5(complaint_type)
    descriptor          VARCHAR,
    status              VARCHAR,  -- request status
    borough             VARCHAR,  -- denormalized label
    borough_id          VARCHAR,  -- FK to dim_borough — md5(borough)
    incident_zip        VARCHAR,
    latitude            DOUBLE,
    longitude           DOUBLE
);

-- Distinct complaint types with counts and observed date span.
CREATE TABLE IF NOT EXISTS main_gold.dim_complaint_type (
    complaint_type_id   VARCHAR,  -- surrogate PK — md5(complaint_type)
    complaint_type      VARCHAR,  -- complaint type label
    request_count       BIGINT,   -- requests of this type
    first_seen_dt       DATE,
    last_seen_dt        DATE
);

-- Distinct boroughs with request counts.
CREATE TABLE IF NOT EXISTS main_gold.dim_borough (
    borough_id          VARCHAR,  -- surrogate PK — md5(borough)
    borough             VARCHAR,  -- borough label
    request_count       BIGINT    -- requests originating in this borough
);


-- =============================================================
-- ADMIN — infrastructure + data-quality observability.
-- Keep these when you swap in your own data.
-- =============================================================

CREATE SCHEMA IF NOT EXISTS main_admin;

-- One row per run.sh invocation. Owned by scripts/pipeline_run_start.py
-- (INSERT, status 'in_progress') and pipeline_run_end.py (UPDATE with
-- final status + per-stage outcomes). The /trust + /metrics pages read it.
CREATE TABLE IF NOT EXISTS main_admin.fct_pipeline_run_raw (
    run_id              VARCHAR,  -- PK — ULID minted at run start
    run_type            VARCHAR,  -- manual / daily
    run_status          VARCHAR,  -- in_progress / success / failed
    run_started_at      TIMESTAMP,
    run_ended_at        TIMESTAMP,
    duration_seconds    DOUBLE,
    failed_stage        VARCHAR,  -- name of the stage that halted, NULL on success
    stage_outcomes      VARCHAR,  -- JSON blob of per-stage status
    notes               VARCHAR
);

-- The dbt test catalog — one row per defined test, seeded once and frozen.
CREATE TABLE IF NOT EXISTS main_admin.dim_data_quality_test (
    test_id             VARCHAR,  -- PK — dbt_test.<node_name>
    test_type           VARCHAR,  -- dbt_generic / dbt_singular
    metric              VARCHAR,
    expected_value      VARCHAR,
    is_active           BOOLEAN,
    certified_at        TIMESTAMP,
    certified_by        VARCHAR
);

-- One row per dbt test per run. Append-only. The /trust page reads this.
CREATE TABLE IF NOT EXISTS main_admin.fct_test_run (
    run_id              VARCHAR,  -- dbt invocation id for the run
    test_id             VARCHAR,  -- FK to dim_data_quality_test
    run_at              TIMESTAMP,
    actual_value        VARCHAR,  -- failing row count, as text
    expected_value      VARCHAR,
    status              VARCHAR,  -- pass / warn / fail
    failure_message     VARCHAR
);

-- Per-column profile snapshot. Owned by scripts/profile_tables.py.
-- Observational only — never fails a run. The /profile page reads it.
CREATE TABLE IF NOT EXISTS main_admin.fct_data_profile (
    profiled_at         TIMESTAMP,
    table_schema        VARCHAR,
    table_name          VARCHAR,
    column_name         VARCHAR,
    data_type           VARCHAR,
    row_count           BIGINT,
    null_count          BIGINT,
    pct_null            DOUBLE,
    distinct_count      BIGINT
);
