# OPEN_DECISIONS.md — The 5 design decisions (RESOLVED)

These were extracted from `STACK_IN_A_BOX_PLAN.md` §5 and surfaced as a dedicated doc. **All five were resolved 2026-05-27** (Plan 1) from Chat's rationale in response to Code's session-2026-05-27 dry-run findings.

Each decision below keeps its original framing (the trade-off space, the alternatives, the costs) as a record, followed by a **RESOLVED** paragraph naming the choice, the rationale, and the forward implications for the second batch (Plan 2). The framing is preserved deliberately — a future reader who wants to revisit a decision can see what the trade-off looked like at resolution time.

> **Status: ALL RESOLVED 2026-05-27 (Plan 1).** The scripts in `scripts/setup/` carry defaults consistent with these resolutions. A future plan may revisit any decision with its own rationale — decisions are sticky, not permanent.

---

## Decision #1 — Tailscale required vs. optional

**Framing:** The setup scripts assume Tailscale is required. The user joins their Tailnet via `06_tailscale_join.sh`, gets a Tailnet IP, and from then on accesses the Oxygen SPA (`:3000`) and SSH only over the Tailnet. The AWS Security Group locks down public `:22` and `:3000`.

**Alternative:** Tailscale is optional. The user can choose nginx Basic Auth on `:3000` instead (the `htpasswd` binary is already installed in script 01 for this reason). Script 06 becomes "either Tailscale OR Basic Auth"; script 07 grows the conditional nginx block.

**Cost of "optional":** doubles the surface area of scripts 06 + 07, doubles the verify gates, doubles the failure modes the README has to cover.

**Cost of "required":** the user needs a free Tailscale account before the install starts. This is the only third-party account required beyond AWS and Anthropic.

**RESOLVED 2026-05-27 → Required.** Rationale: cleaner security posture, free-tier Tailscale (3 users / 100 devices) handles the audience size, and Basic Auth is a weaker security story not worth doubling the surface area of scripts 06 + 07. **Forward implications for Plan 2:** scripts 06 + 07 stay exactly as written; no alternative-path code lands; `HARDENING.md` (when it ships in the second batch) does NOT need a "Tailscale-optional install" section — it can document Basic Auth purely as an additional hardening layer on top of Tailscale, not as a substitute.

---

## Decision #2 — Smoke-test data source

**Framing:** The smoke-test pipeline pulls real data to prove the platform works end-to-end. The default is **NYC 311 service requests** (SODA API, `https://data.cityofnewyork.us/resource/erm2-nwe9.json`). Clean endpoint, well-documented schema, generous rate limits — a low-friction live source for the smoke test.

**Alternatives:**

- **USGS Earthquakes** (different API shape — REST JSON, not SODA). Validates the template isn't accidentally SODA-coupled. Adds ~3 hours of dlt work.
- **A federal-data smoke** (e.g., a bulk-download CSV from a government open-data portal). Removes the "live API" dependency; the file is cached in the repo. Faster smoke test, but less honest about what real pipelines deal with.
- **A synthetic CSV** (committed to the repo). Fastest, least honest.

**Why a real API source matters:** the smoke test exercises the dlt → bronze → gold → admin → portal chain. If the smoke source is a static CSV, the chain doesn't exercise the SODA pull retry logic, the auto-pagination, or the source-health checker — three patterns the template's value-prop depends on.

**RESOLVED 2026-05-27 → NYC 311 (SODA `erm2-nwe9`).** Rationale: the highest pipeline-shape reuse from existing civic-data SODA pipeline code (~90%); well-documented public API; volume scales appropriately across the small / medium / large smoke modes. **Forward implications for Plan 2:** the second-batch `dlt/smoke_test_pipeline.py` targets `https://data.cityofnewyork.us/resource/erm2-nwe9.json`; the bronze + gold dbt models reflect the 311 service-request schema; the semantic-layer view and the agent's canonical smoke question both anchor on NYC 311. "Swap in any SODA dataset by changing 3 lines" is the documented headline; USGS / alternate sources can land later under `examples/alt-smoke-tests/` if the SODA-coupling concern needs addressing.

---

## Decision #3 — Smoke test in main path vs. `examples/`

**Framing:** Once decision #2 picks a smoke source, where does the smoke-test pipeline live in the template repo?

**Option A — Main path with delete-me markers:**

- `dlt/smoke_test_pipeline.py`, `dbt/models/{bronze,gold}/smoke_test_*.sql`, `semantics/views/smoke_test.view.yml`, etc.
- Files have prominent `🚧 Delete this when connecting your data` markers at the top.
- A `make rip-out-smoke-test` target removes all smoke-test files cleanly.
- Risk: users keep the smoke test running alongside their real data, polluting the warehouse.

**Option B — Extracted to `examples/`:**

- `examples/smoke-test/dlt/...`, `examples/smoke-test/dbt/...`, etc.
- Main `dlt/`, `dbt/models/`, `semantics/` directories are empty.
- A user's first move is to copy from `examples/smoke-test/` into the main path and customize.
- Cleaner conceptual story ("the box is empty, the example shows you how to fill it"). Doubles doc surface.

**Tension:** Option A is "the box arrives with one example running so you can verify the box works." Option B is "the box arrives empty; the example shows you how to fill it." Both are honest framings of the same trade-off.

**RESOLVED 2026-05-27 → Main path with delete-me markers (Option A).** Rationale: cheapest path that earns the "in a box" framing — the box arrives with one working example so the user can verify it works end-to-end before connecting their own data. **Forward implications for Plan 2:** second-batch smoke files (`dlt/smoke_test_pipeline.py`, `semantics/views/smoke_test.view.yml`, `semantics/topics/smoke_test.topic.yml`, `dbt/models/bronze/smoke_test_*.sql`, `dbt/models/gold/smoke_test_*.sql`) live in their natural locations with prominent `🚧 Delete this when connecting your data` markers in each file header. A `make rip-out-smoke-test` target ships with the second batch to remove all smoke files cleanly in one command.

---

## Decision #4 — Pin Oxygen version vs. `get.oxy.tech` latest

**Framing:** `03_install_oxygen.sh` runs `bash <(curl --proto '=https' --tlsv1.2 -LsSf https://get.oxy.tech)` — the official installer, which fetches the *latest* Oxygen release.

**Alternative:** Pin to a known-good Oxygen version, replacing the installer URL with a versioned tarball or release-tagged installer URL.

**Why pin:** reproducibility. A template repo's value-prop is "install this and it works." If Oxygen ships a breaking change tomorrow, the template breaks for every new user until the maintainer updates the URL.

**Why latest:** the template never ages. Users always get current Oxygen features. The cost is the "Oxygen broke our template" failure mode.

**RESOLVED 2026-05-27 → Latest from `get.oxy.tech`, with a TODO comment.** Rationale: pinning before there's evidence of which version actually works end-to-end on a real install is theater — you'd be pinning to a version nobody has verified against the full pipeline. **Forward implications:** script 03 keeps the current `https://get.oxy.tech` URL but gains a TODO comment naming that the first real install (Plan 3 in the candidate sequence) is where the working Oxygen version gets captured, and a follow-up plan (Plan 4) retroactively pins to that known-good version. Pinning is deferred to *after* evidence, not before.

---

## Decision #5 — Repo name

**Framing:** The working name is `stack-in-a-box`. It's a placeholder. The repo lives at `https://github.com/ironmonkey88/stack-in-a-box` as of 2026-05-27.

**Candidates discussed:**

- `stack-in-a-box` — the current placeholder. Clean, descriptive, slightly cute.
- `oxygen-starter` — names the underlying technology. Couples the repo to Oxygen forever.
- `warehouse-kit` — generic, technology-agnostic. Less distinctive.
- `analytics-box` — emphasizes the analyst-facing surface. OK.
- `instant-warehouse` — overpromises ("instant" isn't honest about the 35-60 minute install).

**RESOLVED 2026-05-27 → `stack-in-a-box` stays.** Rationale: no strong reason to change; the name is clean and descriptive, and a rename is a contained one-plan task if a better name emerges later. **Forward implications:** no current work; the "this is one of the open decisions" framing about the name is removed from the repo's docs in favor of "this is the repo name." `05_clone_and_config.sh`'s `DEFAULT_REPO_URL` now points at the real `ironmonkey88/stack-in-a-box` URL (Plan 1 Phase C1), with a comment noting that a future rename would update it.

---

## How these resolved

The 5 decisions were resolved by Chat on 2026-05-27, in response to Code's dry-run findings from the same day, and baked into the repo by Plan 1. The downstream sequence those resolutions unlock:

1. **Plan 2 — The second batch:** build the 16 missing artifacts (`run.sh`, `requirements.txt`, `config.example.yml`, dbt models, dlt smoke pipeline, semantic-layer YAML, agent YAML, systemd units, portal generators, helper scripts) per `STACK_IN_A_BOX_PLAN.md` §9. Scoped against the settled inputs above.
2. **Plan 3 — First real install:** provision a fresh t4g.medium and run `bootstrap.sh` end-to-end. Captures which Oxygen version actually works.
3. **Plan 4 — Retroactive Oxygen version pin:** per decision #4, pin script 03 to the version Plan 3 verified.
