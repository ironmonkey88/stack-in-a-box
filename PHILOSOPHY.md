# PHILOSOPHY.md — The principles the platform is built on

This is the *why beneath the why*. Not operational — `STANDARDS.md` and `CLAUDE.md` are the authorities on what to do and how. Consult this doc as a tiebreaker when a design question is genuinely open.

The principles below are properties of any honest data platform, not specific to a particular dataset or domain.

---

## The creed — empathy, honesty, optimism

Three words name the conviction the numbered principles below implement — the same creed the reference standard carries:

- **Empathy.** The answer has to fit the person asking and their situation; context is part of being correct, not a nicety. This is the *facts-vs-answers* point in §1 — an answer carries the question's context, a fact doesn't.
- **Honesty.** Every answer carries its evidence, and the platform says plainly what it cannot show. Honesty is the rule the other two answer to — it is carried by §4 (honest reporting) and §6 (the trust contract).
- **Optimism.** A platform built on incident and complaint feeds inherits a negativity bias *by construction* — its source data is mostly a record of problems. Correcting that bias by deliberately surfacing genuine progress is part of honest reporting, not editorializing; optimism here is earned — a conclusion the evidence supports, never a mood applied on top.

These are properties of any honest data platform; the numbered principles that follow are how it implements them.

---

## §1 — Working backwards from real problems

The platform's first move is not "what data do we have?" It's "what report do you want, who's reading it, what decision does it inform for them?"

This is the discipline. Every layer of the platform exists to deliver answers that are honest about what they can and can't say. If you start from "we have data, let's see what it tells us," you build a warehouse that produces facts. If you start from "someone needs to make a decision; what do they need to know?", you build a warehouse that produces answers.

Facts and answers aren't the same thing. Answers carry the question's context. Facts don't.

The closing ritual at the end of a fresh install (per `CLAUDE.md` §9) is the discipline made visible at the moment the user is about to start the real work: *what report do you want this platform to produce? what question is it answering? who's asking?*

---

## §2 — Stages with verification

Every layer of the pipeline has a role and a contract. Each stage's *verified output* is what the next stage trusts — not the stage itself.

| Stage | Role | What the next stage trusts |
|---|---|---|
| Ingest (dlt) | Pull raw data from source. | The arrival audit columns + the raw row count. |
| Bronze | Pass-through view + minimal type discipline. | The arrival audit, propagated. |
| Silver | Clean, type, redact PII, dedupe. | The clean shape + PII assurance. |
| Gold | Business-ready facts + dims. | The semantic contract + tests passing. |
| Admin | Pipeline + DQ observability. | The audit trail of what happened and what passed/failed. |
| Semantic layer | Single metric source of truth. | Measure definitions that don't drift. |
| Agent | Natural-language interface with trust contract. | Every answer carries SQL + count + citations + limitations. |

The captured-exit pattern in the orchestrator (`run.sh`) is load-bearing: dbt tests don't halt the pipeline; the run completes, records its DQ status, and surfaces the failure visibly. Silent test failures are the bug; visible failures are the discipline working.

Stages-with-verification means a downstream stage can pick up where an upstream stage left off without re-doing the upstream work. The verification gate is the handshake.

---

## §3 — Durability through metadata

The warehouse remembers everything that happened to it.

- `fct_pipeline_run_raw` — every run, with start time, end time, status, stage outcomes.
- `fct_source_health_raw` — every source liveness probe, with HTTP code, row count, freshness.
- `fct_data_profile` — every column's distribution snapshot, refreshed when the schema changes.
- `fct_test_run` — every dbt test execution, with pass/fail/warn.
- `dim_data_quality_test` — the test catalog with baseline expectations.

These tables are the audit trail. Any change to the platform that doesn't write to one of these surfaces is invisible. *If the warehouse doesn't remember it, it didn't happen.*

This isn't paranoia — it's the price of operating a platform that produces answers people will act on. The user asking "is this data up to date?" deserves a SQL-queryable answer, not "yeah I think so."

---

## §4 — Honest reporting

A `partial` with a documented finding outranks a `complete` that papered over a problem.

Status vocabulary:

- `complete` — the work shipped and the verification gate passed.
- `partial` — some sub-items landed; others didn't. The unfinished work is named with what blocks it.
- `blocked` — the work halted at a stage where progress requires a decision.
- `deferred` — the work was scoped out intentionally.

Pick the honest value. The cost of a "complete" that wasn't is much higher than the cost of admitting "partial."

This applies to every stage of the work — pre-flight findings, mid-execution surprises, post-merge verifications. If the answer isn't `complete`, name what it is and why.

The principle extends to the chat agent's trust contract: every answer carries the row count, the SQL, the citations, and the relevant limitations. The agent does not paraphrase its methodology away.

---

## §5 — Modular by design

The platform is built so components can be swapped without losing the discipline.

This repo's reference implementation uses EC2 + Docker + Oxygen + DuckDB + Tailscale + nginx + systemd. A different deployment might use GCP + Kubernetes + ClickHouse + WireGuard + Caddy + a cron daemon. The *design* transfers — the *technology* is replaceable.

The discipline lives in:

- `CLAUDE.md` — operating instructions.
- `PROMPTS.md` — the prompt shape + receipt workflow.
- `PHILOSOPHY.md` — this doc.
- `STANDARDS.md` — done-done gates.
- `DASHBOARDS.md` — dashboard design.

The implementation lives in:

- `scripts/setup/` — the install path.
- `run.sh` — the orchestrator (lands in a future plan).
- `dbt/`, `dlt/`, `semantics/`, `agents/` — the data path (also future plans).

A future user with different infrastructure rewrites the implementation, keeps the discipline, and gets the same trustworthy platform. The 13 setup scripts here are *one valid reference instantiation* of the design — not the design itself.

---

## §6 — Trust contract on every answer

The chat agent's reply must always carry:

1. **Row count.** "Returned N rows."
2. **Answer.** Two to four sentences of plain prose, stating the number or finding directly. No marketing tone. No paraphrasing the methodology away.
3. **Citations.** Every source table referenced (qualified: `main_gold.fct_<entity>`), every semantic-layer view, every limitations entry whose `affects:` list matches a column / view / measure / table the answer used.
4. **Known limitations affecting this answer.** Only present if at least one limitation surfaced in citations. One to two sentences each, naming the limitation by title and stating the user-facing impact.

Hard rules:

- Always query the database. Never answer from memory.
- Always include the row count. "Returned 0 rows" is valid; silently producing 0-row claims is not.
- Always include `**Citations:**`, even when the question seems trivial.
- Never soften or omit limitations when they apply.
- Never state a calendar year in prose unless the SQL queried it. Knowledge cutoffs are a real failure mode; the database is the source of truth for the current date.

The trust contract is the user's protection against the platform telling them something false. It costs the agent ~3 extra paragraphs per reply. It earns the user's trust.

---

## §7 — Boundary constraints

Some constraints are not in the trade-off space. The specific constraints depend on what the platform is being used for; each implementation must identify its own — the discipline is naming them explicitly, not pretending they don't exist.

Examples:

- **k-anonymity on survey/demographic data.** Thin cells (a single respondent or two identifiable by demographic intersection) are protected by absence — the dimensions aren't surfaced in gold rather than relying on suppression logic that can be defeated.
- **PII redaction in silver.** Names, emails, addresses redacted at the silver tier before any user-facing surface touches them.
- **Honest reporting on uncertainty.** When the data can't answer the question, the agent says so. It does not invent confidence.

When you build your own platform on this discipline, identify your boundary constraints early. Name them. Don't pretend they're trade-offs. Trade-offs imply you might trade them away under pressure; boundary constraints are the ones you don't.
