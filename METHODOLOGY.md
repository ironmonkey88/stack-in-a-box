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

*R1–R4 are install/infra-operational rules drawn from field experience (a plan hit them). R5–R8 are reasoning/build disciplines drawn from design — ratified, but not yet exercised in a plan; their Origin says so.*

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

*(When this file is instantiated in oxygen-mvp, this table is where oxygen-origin rules pending downward propagation to stack will also be tracked.)*
