# Plan 13 — Pipeline-operations rules from a production instance (R9–R13)

**Kind:** coding (docs + config). **Source:** Gordon, 2026-11-18, in a wong-way-warehouse session after a failed run:

> raw needs to reflect the sources … problems in raw should not fail runs. Bad runs need to be self cleansing. data quality
> should be handled in the transform from raw to silver. This logic should be in our actual pipelines and also as a basic
> principle in stack-in-a-box … we also need self healing from fails like this … We need to do hygiene sweeps …
> Its important that we write back improvements to that repo.

Approved: the wong-way-warehouse plan (`docs/plans/2026-11-18-warehouse-resilience.md` there), section 9, which includes
Plan E (this write-back) and the new METHODOLOGY rules.

**Do:** add R9–R13 to METHODOLOGY.md (`stack-only`, propagation rows); STANDARDS §2/§3/§5 and a new Operations section;
bronze tests warn in `dbt/dbt_project.yml`; a CLAUDE.md §10 gotcha; LOG + TASKS. **Gate:** `dbt parse`, bronze tests warn,
others error. **Out of scope:** porting the scripts (tracked as a follow-on).
