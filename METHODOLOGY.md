# METHODOLOGY — shared whiteboard (oxygen-mvp ⇄ stack-in-a-box)

**What this is.** The distilled, reusable *rules* and *architecture findings* learned while building both repos — the "what to always/never do," extracted from experience. This is **not** a changelog (that's `LOG.md`) and **not** narrative history (that's session handoffs). Each entry here is a rule you could hand to someone with no context and they'd know what to do.

**Why it lives in both repos.** oxygen-mvp and stack-in-a-box share a *foundation* and a *methodology*, even though their project-specific code deliberately diverges. Rules are the one layer that is genuinely identical across both (a rule like "never use `%h` in a system unit" is true verbatim in each). So this file is meant to be **kept consistent across both repos**, eventually — not byte-locked in real time, but reconciled on a regular cadence.

**Two-way, eventually consistent.** Either repo can discover a rule. Each entry is tagged with where it came from and whether it's reached the other repo yet. The `Sync` field is the propagation to-do list — it tells you (or a future Code sync task) what's pending in each direction. Reconciliation is **Code-proposes / human-approves**, never auto-committed: the whole point of this file is distilled judgment, so a human ratifies every merge.

## How to use
- **Adding a rule:** write it as an imperative rule, not a story. Tag `Origin` (repo + plan) and set `Sync` to `<origin>-only`.
- **Propagating:** when a rule is confirmed/applied in the other repo, set `Sync: synced` and note the other repo's plan if relevant.
- **Provenance matters:** keep the one-line origin so "why do we have this rule" is answerable later.

## Sync states
- `stack-only` — born in stack-in-a-box, not yet carried to oxygen-mvp.
- `oxygen-only` — born in oxygen-mvp, not yet carried to stack-in-a-box.
- `synced` — present and honored in both.
- `n/a` — genuinely project-specific; documented here only so we don't keep re-evaluating whether it should propagate.

---

## The sync process (how this file stays consistent across both repos)

This file is the **home of record** for both the rules *and* the procedure that keeps them in sync. A one-line pointer in each repo's `CLAUDE.md` routes here; the procedure itself lives only here so the two copies can't drift on *how* they sync.

**Principles**
- **Eventually consistent, not real-time.** Methodology is not latency-sensitive. A rule can sit `stack-only` for a while; the cost of lag is low, the cost of a bad auto-merge is high.
- **Bidirectional.** Either repo can *discover* a rule. oxygen-mvp is the canonical *store* if a tie-breaker is ever needed, but it is not the sole *author* — stack-in-a-box is the only place the foundation is exercised cold/from-scratch, so it genuinely originates rules (R1–R3 did).
- **Code-proposes / human-approves.** Reconciliation is never auto-committed. The whole value of this file is distilled judgment; a human ratifies every merge. Code may *prepare* the diff; the approval is where taste enters.
- **Capture at the moment of discovery.** The failure mode is learnings piling up in `LOG.md` as narrative and never getting distilled. After each significant plan in either repo, ask: *"did this produce a general rule?"* If yes, it goes here immediately, tagged `<origin>-only`. That habit — not this file — is what keeps the whiteboard alive.

**Procedure (per sync pass)**
1. **Trigger:** after a significant plan lands in either repo, or on a periodic check (whichever comes first). Not a fixed calendar cadence yet — formalize into a named recurring plan type only once churn justifies it.
2. **Prepare (Code):** read both repos' `METHODOLOGY.md`. Produce a proposed reconciliation diff for *each* repo:
   - `stack-only` / `oxygen-only` rules → propose adding to the other repo (with any genericization needed to make the rule project-agnostic — though most rules are born generic).
   - rules present in both but worded differently → surface for human reconciliation; do not silently pick one.
   - flag rules whose `Sync` state changed.
3. **Approve (human):** ratify, edit, or reject each proposed change. On acceptance, update the `Sync` field (→ `synced`, with the other repo's plan noted) and clear the pending-propagation row.
4. **Project-specific instantiations stay local.** A rule here is general; its concrete local values (e.g. stack's lock-hold threshold numbers) live in that repo's operational docs (`IMPROVEMENTS_BACKLOG.md`, `FIRST_INSTALL_FINDINGS.md`), **not** here. Keep the rule portable; keep the numbers where they apply.

**What does NOT go through this process**
- Project-specific code (genericized differently per repo) — that's manual curation, not methodology sync.
- Chronological history — that's `LOG.md`.
- Concrete operational values/thresholds — those live in the originating repo's docs.

---

## Rules

*R1–R4 are install/infra-operational rules drawn from field experience (a plan hit them). R5–R8 are reasoning/build disciplines drawn from design — ratified, but not yet exercised in a plan; their Origin says so. R9–R13 are pipeline-operations rules from a production instance's failure (wong-way-warehouse, 2026-11-18), approved by Gordon the same day.*

### R1 — Test the contract, not just the components
**Rule:** A verify suite that checks components (port open, service active, file present) can pass *while the actual product is broken*. Every install/CI gate must include at least one end-to-end check that exercises the real contract — e.g. ask the agent a canned question and assert a real answer returns, not just `:3000 → 200`.
**Origin:** stack-in-a-box, Plan 3 (Finding 6 — the `dataset:`/`path:` blocker made every agent query fail while steps 00–10 stayed green).
**Sync:** `stack-only` → **propagate to oxygen-mvp.** Oxygen almost certainly has the same gap; its verify steps should be audited for a test-the-contract gate.

### R2 — DuckDB single-writer contention between serving and refresh is structural
**Rule:** When one process serves reads (oxy) and another writes on a schedule (run.sh refresh / timers) against a single `.duckdb` file, they contend on DuckDB's single-writer lock. Default mitigation: `flock` around the refresh + read-side retry with backoff. Instrument it from day one — record writer **lock-hold duration** and reader **retry-wait** into the admin/observability schema — and define a named threshold (hold > N s, or reader p95 wait > M ms) that triggers the upgrade to a snapshot/atomic-swap read path. Don't pre-build the snapshot split; do make its trigger data-driven.
**Origin:** stack-in-a-box, Plan 3 (surfaced during install; dodged by deferring timers to next boot). Build lands in stack Plan 4.
**Sync:** `stack-only` → **check oxygen-mvp** for the same serve+refresh-on-one-DuckDB pattern; if present, it has the same latent contention. The *pattern + metric + threshold* is the shared learning even if the code differs.

### R3 — `%h` ≠ `User=` home in systemd system units
**Rule:** In a systemd **system** unit, `%h` in `ExecStart`/paths resolves to the service manager's home (`/root`), **not** the home of the `User=` you set. Using `%h` for a user-owned binary path causes `203/EXEC` in a restart loop. Use an explicit, substituted home path (e.g. a `{{HOME_DIR}}` token) instead.
**Origin:** stack-in-a-box, Plan 3 (`dbb20f7`).
**Sync:** `stack-only` → **check oxygen-mvp** — if its `oxy.service` is a system unit referencing `%h`, it has the same latent bug (or hardcoded around it, which stack's tokenization re-exposed).

### R4 — Attended installs are definitive; unattended refreshes defer-and-resume
**Rule:** Same data path, two resilience postures by *who's waiting*. An **attended** first-run (a human watching `bootstrap.sh`) must give a clean one-sitting pass/fail — keep its volume small (smoke = `small`) and use immediate backoff-retry for transient blips; never "it'll finish later." An **unattended** scheduled refresh (no human waiting) should tolerate partial failure and self-heal on the next tick via idempotent merge-on-key. Verify the resume path with a forced mid-run failure test.
**Origin:** stack-in-a-box, Plan 3 / Plan 4 (NYC 311 SODA timeouts; `medium` failed, `small` clean).
**Sync:** `n/a` for the SODA specifics (project-specific source), but the **attended-vs-unattended resilience principle** is general → consider for oxygen-mvp's own ingestion. Tag the principle `oxygen`-worth-reviewing, the SODA tuning `n/a`.

### R5 — Hypothesis and result are separate tiers; the gate is at the lab door
**Rule:** Run data-to-understanding as two labeled tiers. A **hypothesis** may be quick, rough, and reason ahead of full evidence — but it always wears the label "hypothesis." A **result** pays the full trust contract (SQL, row counts, citations, limitations). Promote hypothesis → result *only* by passing the evidence gate; if it can't pass, surface it as a stated open question — never strip the label and let it read as a finding. The looseness lives in the hypothesis tier's evidentiary *cost*, **never** in the labeling. This blocks the failure mode where frame-based/abductive reasoning (confidence scores, parallel hypotheses) launders speculation past verification by shedding its label before the reader sees it. Two tiers and not one strict gate, because both humans and LLMs given data with no frame either freeze or confabulate — the cheap labeled hypothesis tier is where exploration safely lives (a conjecture isn't held to publication standard).
**Origin:** design session 2026-06-10, ratified by Gordon; not yet exercised in a plan. Basis: Klein's Data-Frame Theory. Maps onto the existing stack: the trust contract = peer review, the limitations registry = threats to validity.
**Sync:** `stack-only` → carry to oxygen-mvp when its METHODOLOGY.md is instantiated.

### R6 — Manufacture operator expertise into the product behind a constrained agent surface
**Rule:** A product that works only with a human expert in the loop has been *operated*, not *built*. To make it stand without the operator, decompose that expertise and manufacture it into the product as three parts: (1) a domain-neutral **authored spine** — the standardized terms, joins, and structure the expert would otherwise supply by hand; (2) **structural verification** — tests and gates that hold what must stay true; (3) a **constrained agent surface** — the agent may act only within the rail the spine defines, never beyond it. Binding invariant that makes it safe: the constrained agent must not be able to emit output the structural verification can't check. (This is the build-discipline half of system humanism; the conviction half — human dignity/agency as the measure, dignity/privacy/honesty bounding the trade-off space — stays in PHILOSOPHY.md.)
**Origin:** design session 2026-06-10, ratified by Gordon; not yet exercised in a plan. Load-bearing for the desktop/local-app MVP-0 concept, whose whole thesis is this rule applied.
**Sync:** `stack-only` → carry to oxygen-mvp when its METHODOLOGY.md is instantiated.

### R7 — Declarative/desired-state first; reconcile actual to desired
**Rule:** State the desired end-state (the outcome plus the tests that prove it), not the imperative steps; let the build reconcile actual → desired. Treat the spec as a **standing description continuously enforced** (check → diff → execute), not a one-time instruction — that loop is reconciliation, and the tests + docs are its mechanism (they declare what must stay true and drive the system back on drift). Where actual diverges from desired on anything judgment-bearing, **report the diff and let a human decide** (the Code-proposes/human-approves posture). Do **not** over-rotate on declarative purity: it leaks at complexity and is imperative underneath — stay declarative in the data layer (specs, SQL, tests) and accept imperative control where the abstraction genuinely can't express the need. How declarative the agent surface can safely be tracks the executor's **capability-to-scope ratio**; a well-constrained, well-tested surface (R6's authored spine) raises that ratio, which is what lets a user state outcomes and trust the answer.
**Origin:** design session 2026-06-10, ratified by Gordon; not yet exercised in a plan. Basis: desired-state infra (Kubernetes/Terraform reconciliation); Situational Leadership for the coaching-vs-directing/capability framing. Connects to R6 — the spine is what makes the surface safe to operate declaratively.
**Sync:** `stack-only` → carry to oxygen-mvp when its METHODOLOGY.md is instantiated.

### R8 — Keep desired-state specs idempotent
**Rule:** Write every desired-state spec so applying it repeatedly equals applying it once. Idempotency is what makes reconciliation (R7) safe to re-run: re-applies, retries, and crash-recovery must converge to the same end-state without duplicating work or corrupting state. Build it in (merge-on-key, create-if-absent, check-before-write) rather than bolting it on — a spec that isn't idempotent can't be safely reconciled on a schedule or resumed after a mid-run failure.
**Origin:** design session 2026-06-10, ratified by Gordon; not yet exercised in a plan. Split from R7 because idempotency is a distinct, separately-testable property. Basis: desired-state infra idempotency.
**Sync:** `stack-only` → carry to oxygen-mvp when its METHODOLOGY.md is instantiated.

### R9 — Raw reflects the source; problems in raw never fail a run
**Rule:** Bronze keeps what the source sent, including its duplicates, nulls and odd shapes, so every bronze test is `severity: warn`: it records what the source did and never stops the pipeline. Silver decides what is true (current load, dedup, deletes) and its grain tests stay `error`. Never run the nightly build with `--fail-fast`: it cancels in-flight nodes (reported as ERROR, hiding the real one) and skips everything downstream of one bad row. Without it, a failure skips only its own dependents.
**Origin:** wong-way-warehouse (a personal Postgres instance of this stack), 2026-11-18: a vendor API returned one record three times; a bronze uniqueness test failed, `--fail-fast` cancelled the build and every downstream output went stale. Note this stack's own run.sh already had the captured-exit pattern; the instance had drifted from it (see R13).
**Sync:** `stack-only` → **propagate to oxygen-mvp** (check its build flags and bronze test severities).

### R10 — Bronze is append-by-load and self-cleansing
**Rule:** Tag every bronze row with the load that brought it (dlt `_dlt_load_id`, or the landed file's name). Load with delete-insert on the load key (dlt `merge` + `merge_key`), so a rerun or a half-finished load of the same pull replaces itself. Judge each load on arrival (not empty; not much smaller than recent loads for a snapshot source) in an admin load-audit table, and have silver read only the newest *good* load. A bad load is kept, flagged and expires with retention; the next good pull supersedes it with no human step. Keep a bounded history per source (e.g. the last 14 loads of a snapshot source) and the landed files forever, so everything is rebuildable. Pull incrementally where the API allows (a window plus overlap); otherwise one request per source per day, and never loop retries against a vendor.
**Origin:** wong-way-warehouse, 2026-11-18 (pilot on one snapshot source: proven that a rerun replaces itself, a truncated pull is rejected and silver keeps the previous one, a tripled record comes out once).
**Sync:** `stack-only` → propagate to oxygen-mvp.

### R11 — Evidence before cause; diagnose where the evidence is
**Rule:** When a run fails, collect the evidence on the machine that ran it, automatically, before anyone is alerted: the build's own artifact (`run_results.json`: first real failure, excluding skipped and cancelled nodes), disk, database reachability, each source's last success, and what changed since the last good run. Classify it against a short playbook (disk / transient / model_error / test_failure / source / gate / unknown), store the verdict in an admin table and make it the alert's text. Automatic action only where it is safe (one retry for a transient failure). Whoever triages quotes the verdict and never names a cause it doesn't show; a guess is labelled as one and never shipped as a fix. A new failure class becomes a playbook row.
**Origin:** wong-way-warehouse, 2026-11-18: the cause took four rounds to find from a remote session that could only see one log line; two wrong guesses were made, and a fix for the first guess was shipped.
**Sync:** `stack-only` → propagate to oxygen-mvp. Connects to R5 (a guess is the hypothesis tier and wears its label).

### R12 — Hygiene is scheduled, not remembered
**Rule:** Every run ends with a sweep: drop failure tables of tests that passed (only failing tests keep a table), drop orphaned relations that no dbt node or named tool owns (dbt never drops a deleted model's table), ANALYZE what was rebuilt, and record a database-health row (size, temp spill, relations per schema, disk). The host gets a daily disk check with an alert at 80%, capped logs, and a weekly sweep of unused container images and build cache (never volumes). Tune the database for the workload instead of running on defaults: per-role `work_mem`, `temp_file_limit` and timeouts for the build user.
**Origin:** wong-way-warehouse, 2026-11-18: ~1,000 test tables (about 190 of them orphaned) in a 6 GB warehouse; default `work_mem` caused ~140 GB/day of temp-file churn on a shared 38 GB disk at 88%.
**Sync:** `stack-only` → propagate to oxygen-mvp.

### R13 — Audit each instance against the reference
**Rule:** A reference stack's principles only protect the instances that still follow them. Periodically diff each instance's run script, build flags, test severities and standards against the reference, and treat a drift as a finding. When an instance learns something, write it back to the reference in the same week (this file is where it lands).
**Origin:** wong-way-warehouse, 2026-11-18: the instance used `--fail-fast` although this stack's run.sh says "dbt tests don't halt the pipeline".
**Sync:** `stack-only` → applies to every instance (oxygen-mvp, wong-way-warehouse).


*R14–R18 are agent-build disciplines adopted 2026-11-19 from two outside write-ups (GoDaddy's pipeline-creation agent, and lelouvincx's zero-dollar data stack) and wong-way-warehouse's "Yu Bei" new-source flow. Gordon approved them the same day. Not yet exercised in a plan.*

### R14 — Standards before generating
**Rule:** An agent reads the naming standard (`NAMING.md`), the quality gates (`STANDARDS.md`) and the instance's binding context file *before* it writes any model, pipeline or column. It does not generate first and check for violations afterwards. Put the standards in the agent's early context so the first draft complies. A generate-then-fix loop costs extra commits and review cycles, and misses whatever the check doesn't cover.
**Origin:** GoDaddy's data-pipeline agent: naming compliance on the first pass only arrived once its specialists queried the standards before generating. Adopted 2026-11-19.
**Sync:** `stack-only` → propagate to oxygen-mvp and every instance.

### R15 — Cross-check every new number against raw SQL
**Rule:** Before a new metric or silver model is called done, recompute at least one count and one total straight from bronze with plain SQL and compare them to the modelled result. Explain any difference, or fix it. Keep the check as a singular dbt test (a reconciliation or known-answer test) so it runs on every build.
**Origin:** lelouvincx's zero-dollar data stack: a plain-SQL cross-check found one tool's community share was 85% when the correct figure was 0.2% (hidden org membership plus an automation account). wong-way-warehouse already does this as silver→gold reconciliation and known-answer tests. Adopted 2026-11-19.
**Sync:** `stack-only` → propagate to oxygen-mvp.

### R16 — One classification rule, one macro
**Rule:** Any rule that classifies rows and feeds more than one model or metric (who counts as core team; whether the watch was being worn; what counts as a workout) lives in exactly one macro or one silver model. Everything else reads it there. A fix in one place then fixes every metric that depends on it. Never copy the CASE expression into a second model.
**Origin:** lelouvincx's zero-dollar data stack (`author_type()` macro). Adopted 2026-11-19.
**Sync:** `stack-only` → propagate to oxygen-mvp.

### R17 — Snapshot what the source forgets, from day one
**Rule:** If a source only reports its current state (balances, counts, statuses, star totals), history exists only from the first day you snapshot it. Add a dbt snapshot, or an append-by-load bronze table (R10), when the source is added, not when someone first asks for a trend.
**Origin:** lelouvincx's zero-dollar data stack: star history begins when the pipeline first ran. Adopted 2026-11-19.
**Sync:** `stack-only` → propagate to oxygen-mvp.

### R18 — New sources: ask first, build once, one order per source
**Rule:** Adding a source is a conversation, then one build. (1) Intake: who uses it and for what question, how it arrives, the credential *file* (never the secret), freshness, grain and natural key, timezones, sensitivity, quirks. All questions in one batch. (2) Look at real data and agree the names (R14). (3) Write it as one work order, and build it from a checklist that lives in the instance's repo, copying the closest existing source rather than inventing a pattern. (4) Verify on real data, including R15, before calling it done. Report an honest `partial` if verification couldn't run. Fixes are later commits under the same order, never a second order. Narrow agents per job (new source vs. schema change) beat one large agent.
**Origin:** GoDaddy's pipeline agent (conversational intake, one PR per run, narrow specialist agents), adapted as wong-way-warehouse's Yu Bei flow (`docs/yu-bei.md`, `yb-` orders in ORDERS.md), 2026-11-19.
**Sync:** `stack-only` → instance: wong-way-warehouse (adopted). Propagate to oxygen-mvp.

---

## Pending propagation (the to-do view)

| Rule | Direction | Action | Status |
|---|---|---|---|
| R1 test-the-contract gate | stack → oxygen | Audit oxygen verify steps; add live-query gate | open |
| R2 DuckDB contention pattern | stack → oxygen | Check oxygen for serve+refresh-on-one-file; share metric/threshold pattern | open |
| R3 `%h` systemd trap | stack → oxygen | Inspect oxygen `oxy.service` for `%h` in a system unit | open |
| R4 attended/unattended principle | stack → oxygen | Review oxygen ingestion against the principle (SODA specifics excluded) | open |
| R5 hypothesis/result two-tier gate | stack → oxygen | Carry over when oxygen-mvp METHODOLOGY.md is instantiated | open |
| R6 manufacture-expertise / constrained-agent surface | stack → oxygen | Carry over when oxygen-mvp METHODOLOGY.md is instantiated (the destination of oxygen-mvp's deferred system-humanism split) | open |
| R7 declarative / desired-state / reconciliation | stack → oxygen | Carry over when oxygen-mvp METHODOLOGY.md is instantiated | open |
| R8 idempotent specs | stack → oxygen | Carry over when oxygen-mvp METHODOLOGY.md is instantiated | open |
| R9 raw never fails a run / no fail-fast | stack → oxygen | Check oxygen's build flags and bronze test severities | open |
| R10 append-by-load, self-cleansing bronze | stack → oxygen | Review oxygen's dlt write dispositions and silver load selection | open |
| R11 diagnose where the evidence is | stack → oxygen | Add on-box diagnosis + playbook to oxygen's run | open |
| R12 scheduled hygiene | stack → oxygen | Add the post-run sweep and host checks | open |
| R13 instance drift audit | stack → all | Diff each instance against the reference periodically | open |
| R14 standards before generating | stack → all | Point each instance's CLAUDE.md at NAMING/STANDARDS before generation | open |
| R15 raw-SQL cross-check | stack → oxygen | Add a reconciliation / known-answer test per gold metric | open |
| R16 one rule, one macro | stack → oxygen | Audit duplicated CASE classifications | open |
| R17 snapshot from day one | stack → oxygen | List state-only sources; add snapshots | open |
| R18 new-source intake → order → build | stack → oxygen | Adopt an intake + order flow (wong-way-warehouse: done, docs/yu-bei.md) | open |

*(When this file is instantiated in oxygen-mvp, this table is where oxygen-origin rules pending downward propagation to stack will also be tracked.)*
