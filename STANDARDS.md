# STANDARDS.md — "Done done" gates by layer

This file is the build's quality contract. Each layer has a checklist that must clear before work in that layer is considered done. Sign-off checklists at the end define the gates for end-to-end platform milestones.

`CLAUDE.md` §2 (Operating discipline) and `PHILOSOPHY.md` §2 (Stages with verification) underlie this doc — the standards are the gate-by-gate expression of those principles.

---

## 1. Structure of the standards

Each layer's standards are stated as a checklist. An item is `done done` only when:

- The artifact exists in the committed state.
- A verification command (where applicable) has been run and produced a clean output.
- The committed state (the artifact + the verification output) is referenced from the relevant TASKS.md / LOG.md row.

Static-artifact items can be verified by `git show`. Live-functional items must be re-runnable — the verification command goes in the TASKS row.

---

## 2. Bronze tier standards

Bronze is the arrival layer. The standard: every source has a discoverable shape, an arrival audit, and a documented contract with the source.

- [ ] Source endpoint documented in `dlt/<source>_pipeline.py` header (URL, dataset ID, source documentation link).
- [ ] dlt pipeline runs end-to-end and writes to `main_bronze.raw_<source>_<entity>_raw`.
- [ ] Bronze view `bronze.raw_<source>_<entity>` exists at the dbt layer, passing through the raw + audit columns.
- [ ] schema.yml has model description + per-column descriptions for every analyst-relevant column.
- [ ] Audit columns present and populated: `_extracted_at`, `_extracted_run_id`, `_first_seen_at` (for merge mode), `_source_endpoint`.
- [ ] At least one bronze test that asserts the source contract (typically `unique` + `not_null` on the source's primary key).
- [ ] Source-shape limitations documented in `docs/limitations/<source>-<aspect>.md` and surfaced in the limitations index.

---

## 3. Silver tier standards

Silver is the cleanup layer. The standard: every silver model is one row per business entity, type-clean, PII-redacted, with a documented curation discipline.

- [ ] Silver model `silver.stg_<source>_<entity>` at `dbt/models/silver/stg_<source>_<entity>.sql`.
- [ ] Materialization: `table` (silver default per dbt_project.yml).
- [ ] Grain stated in the model description (one row per X, where X is the business-entity primary key).
- [ ] All bronze VARCHAR columns cast to analytical types (INTEGER, DOUBLE, DATE, TIMESTAMP, BOOLEAN) via `TRY_CAST` where source could have malformed values.
- [ ] PII columns redacted, hashed, or excluded — discipline named in the model description.
- [ ] schema.yml has model description naming curation discipline + per-column descriptions.
- [ ] At least one silver test that asserts the grain (unique on primary key, not_null on grain columns).
- [ ] Any silver-specific limitations documented (cross-wave drift, source DQ issues that survive into silver, etc.).

> **Status note:** silver-tier standards are still developing — this section will fill out as the project accumulates silver models. The structural shape above is the minimum; specific patterns (k-anonymity gates, suppression logic, dedup discipline) will be added as the work surfaces them.

---

## 4. Gold tier standards

Gold is the business-ready layer. The standard: every gold model is analyst-facing, fully tested, and consumable through the semantic layer.

- [ ] Gold model at `dbt/models/gold/{fct,dim}_<entity>.sql`.
- [ ] Materialization: `table`.
- [ ] Surrogate PK using md5 of the natural-key tuple, named `<entity>_id` (PK) or `<entity>_sk` (SK).
- [ ] Grain stated clearly in the model description.
- [ ] schema.yml has model description + per-column descriptions + `data_type:` annotations on every column.
- [ ] Tests:
  - `unique` + `not_null` on the surrogate PK.
  - `not_null` on every column the analyst's typical query would require.
  - `accepted_values` on every column with a known categorical domain.
  - `relationships` between facts and dims, with `config: where:` predicates to handle expected NULL FKs.
- [ ] Semantic-layer view at `semantics/views/<entity>.view.yml` exposes the model's dimensions and measures.
- [ ] Gold-level limitations documented (deliberate scope choices, mean-of-means caveats, geographic coverage gaps).

---

## 5. Admin tier standards

Admin is the observability layer. The standard: the warehouse audits itself.

- [ ] `fct_pipeline_run_raw` populated on every `run.sh` invocation, with start time, end time, run_status, and stage outcomes.
- [ ] `fct_source_health_raw` populated by hourly source-liveness checks, with HTTP code, row count, freshness.
- [ ] `fct_data_profile` regenerated on schema changes (column distributions snapshot).
- [ ] `fct_test_run` appended from `dbt/target/run_results.json` after every `dbt test` invocation.
- [ ] `dim_data_quality_test` catalogues the test definitions + baseline expectations.
- [ ] All admin tests pass (the DQ drift guardrail and the test-run integrity tests).

The admin tier is the project's audit trail. If the warehouse can't tell you when it last refreshed and what its DQ status was, the discipline is broken.

---

## 6. Semantic layer standards

The semantic layer is the metric source of truth. No hardcoded metrics in SQL or app configs.

- [ ] One `.view.yml` per gold model.
- [ ] One `.topic.yml` per analytical domain, naming the views that compose it.
- [ ] Entities, dimensions, and measures all stated.
- [ ] `oxy validate` passes (all config files valid).
- [ ] Measure types from the controlled vocabulary: `count`, `sum`, `average`, `min`, `max`, `count_distinct`, `median`, `custom`. No `avg`.
- [ ] Dimension types from the controlled vocabulary: `string`, `number`, `date`, `datetime`, `boolean`. No `timestamp`.
- [ ] Measure descriptions surface any mean-of-means caveats or grain-related quirks.

---

## 7. Agent standards

The chat agent is the user-facing surface. It carries the trust contract per `PHILOSOPHY.md` §6.

- [ ] `agents/answer_agent.agent.yml` exists with `system_instructions` carrying the trust contract.
- [ ] `context.topic` glob loads every topic file in the semantic layer.
- [ ] `context.limitations` loads `docs/limitations/_index.yaml`.
- [ ] Agent always uses `execute_sql` against the warehouse. Never answers from memory.
- [ ] Every reply contains: row count, answer, citations, known limitations (when applicable).
- [ ] Smoke test passes — at least one canonical question per topic, with expected count and trust-contract sections all firing.

---

## 8. Rendered-page verification

When a verification gate depends on rendered output (a dashboard, an admin page, a documentation site), use a rendered-page helper rather than `curl + grep`. Curl checks the bytes the server delivered; the user sees what the SPA renders, which is often different.

Pattern:

- `test_page(url, assertions, screenshot_path) -> TestResult` — pass/fail assertions on a rendered DOM.
- `review_page(url, output_dir, focus) -> ReviewArtifact` — capture screenshot + annotated screenshot + network log + window globals + DOM samples for a design review.

A rendered-page tool earns its keep on any project that ships analyst-facing surfaces. The reference toolchain is Playwright + Pillow; alternatives are fine if they deliver the same evidence shape.

> **Status note:** this section's reference implementation will be added when the first dashboard plan ships in this repo.

---

## 9. File-organization standards

- `dbt/models/{bronze,silver,gold,admin}/*.sql` — dbt models, one per file.
- `dbt/models/{bronze,silver,gold,admin}/schema.yml` — model + column docs + tests.
- `dlt/<source>_pipeline.py` — one per source.
- `semantics/views/<entity>.view.yml` — one per gold model.
- `semantics/topics/<domain>.topic.yml` — one per analytical domain.
- `agents/<agent_name>.agent.yml` — agent definitions.
- `scripts/` — Python helpers (run.sh orchestrator helpers, portal generators, ingestion helpers).
- `scripts/setup/` — the install scripts (this repo's reference implementation).
- `nginx/<project>.conf` — nginx site config.
- `systemd/<unit>.{service,timer}` — systemd unit files.
- `portal/<route>.html` — generated portal pages (committed when stable; regenerated on `run.sh`).
- `docs/<convention>/<file>.md` — see `CLAUDE.md` §8 for the conventions.
- `config.example.yml` — Oxygen config template (committed); `config.yml` is gitignored (per-machine).

---

## 10. Project-state-document maintenance

LOG.md and TASKS.md are load-bearing. They drift if not maintained.

- LOG.md "Last Updated" timestamp bumped at the end of every session.
- LOG.md Plans Registry has a row for every plan.
- LOG.md Recent Sessions holds 5 entries; older ones rotate to Earlier Sessions as one-liners.
- TASKS.md "Next Focus" reflects the actual next-eligible work.
- Session files at `docs/sessions/session-NN-YYYY-MM-DD-<slug>.md` — frontmatter from the controlled vocabulary in `CLAUDE.md` §8.
- Session counter is contiguous 1-N, tracked by Code. Chat-side sessions have their own threading and may diverge.

---

## 11. Sign-off checklists

> Sign-off checklists land here as the project accumulates MVP milestones. The first will be **Plan 1 sign-off** (shellcheck pass + first real install). The structure of an MVP sign-off:
>
> - Foundations: environment + setup + access posture.
> - Pipeline: end-to-end run + DQ contract + admin observability.
> - Semantic + agent: layer + trust contract + smoke tests.
> - Portal: every route reachable + correctly rendering.
> - Documentation: LOG / TASKS / session file / handoff.
>
> Each MVP's checklist is the union of its layers' standards (sections 2-10 above) plus any MVP-specific items.
