# OPEN_DECISIONS.md — The 5 design decisions awaiting resolution

These are extracted from `STACK_IN_A_BOX_PLAN.md` §5 and surfaced here as a dedicated doc because resolving them is the next eligible Chat-side session before the first real install plan ships.

Each decision is named with its framing, Chat's lean (from the v4 handoff), and rationale. **None are resolved.** A future Chat-side session works through them; a follow-up Code session bakes the resolutions into the scripts + docs.

> **Status: NOT YET RESOLVED.** As of repo creation (2026-05-27, via `oxygen-mvp` Plan 46). Until these are resolved, the scripts in `scripts/setup/` carry the v4 defaults — which are defensible placeholders, not decisions.

---

## Decision #1 — Tailscale required vs. optional

**Framing:** The setup scripts assume Tailscale is required. The user joins their Tailnet via `06_tailscale_join.sh`, gets a Tailnet IP, and from then on accesses the Oxygen SPA (`:3000`) and SSH only over the Tailnet. The AWS Security Group locks down public `:22` and `:3000`.

**Alternative:** Tailscale is optional. The user can choose nginx Basic Auth on `:3000` instead (the `htpasswd` binary is already installed in script 01 for this reason). Script 06 becomes "either Tailscale OR Basic Auth"; script 07 grows the conditional nginx block.

**Chat's lean:** Required. Tailscale's free tier handles up to 3 users / 100 devices, which is the audience of this template. Basic Auth is a worse experience and a weaker security story.

**Cost of "optional":** doubles the surface area of scripts 06 + 07, doubles the verify gates, doubles the failure modes the README has to cover.

**Cost of "required":** the user needs a free Tailscale account before the install starts. This is the only third-party account required beyond AWS and Anthropic.

---

## Decision #2 — Smoke-test data source

**Framing:** The smoke-test pipeline pulls real data to prove the platform works end-to-end. The default is **NYC 311 service requests** (SODA API, `https://data.cityofnewyork.us/resource/erm2-nwe9.json`). 90% pipeline-shape reuse from Somerville (which also pulls 311 from a SODA endpoint).

**Alternatives:**

- **USGS Earthquakes** (different API shape — REST JSON, not SODA). Validates the template isn't accidentally SODA-coupled. Adds ~3 hours of dlt work.
- **A federal-data smoke** (e.g., a bulk-download CSV from a government open-data portal). Removes the "live API" dependency; the file is cached in the repo. Faster smoke test, but less honest about what real pipelines deal with.
- **A synthetic CSV** (committed to the repo). Fastest, least honest.

**Chat's lean:** NYC 311 for v1. Document "swap in any SODA dataset by changing 3 lines" as the headline. USGS as an `examples/alt-smoke-tests/` once the template is real.

**Why a real API source matters:** the smoke test exercises the dlt → bronze → gold → admin → portal chain. If the smoke source is a static CSV, the chain doesn't exercise the SODA pull retry logic, the auto-pagination, or the source-health checker — three patterns the template's value-prop depends on.

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

**Chat's lean:** Main path with prominent markers + `make rip-out-smoke-test`. Cheapest path that earns the "in a box" framing.

**Tension:** Option A is "the box arrives with one example running so you can verify the box works." Option B is "the box arrives empty; the example shows you how to fill it." Both are honest framings of the same trade-off.

---

## Decision #4 — Pin Oxygen version vs. `get.oxy.tech` latest

**Framing:** `03_install_oxygen.sh` runs `bash <(curl --proto '=https' --tlsv1.2 -LsSf https://get.oxy.tech)` — the official installer, which fetches the *latest* Oxygen release.

**Alternative:** Pin to a known-good Oxygen version, replacing the installer URL with a versioned tarball or release-tagged installer URL.

**Chat's lean:** Pin to the version `oxygen-mvp` is running today (whatever's current per Session 30+ — Code should verify). Document the upgrade path.

**Why pin:** reproducibility. A template repo's value-prop is "install this and it works." If Oxygen ships a breaking change tomorrow, the template breaks for every new user until the maintainer updates the URL. Pinning makes the template stable; upgrades are explicit.

**Why latest:** the template never ages. Users always get current Oxygen features. The cost is the "Oxygen broke our template" failure mode.

**Cost of resolving:** identify the current Oxygen version, find the versioned-installer URL (or release tarball with SHA256), update script 03, document the upgrade procedure.

---

## Decision #5 — Repo name

**Framing:** The working name is `stack-in-a-box`. It's a placeholder. The repo lives at `https://github.com/ironmonkey88/stack-in-a-box` as of 2026-05-27.

**Candidates discussed:**

- `stack-in-a-box` — the current placeholder. Clean, descriptive, slightly cute.
- `oxygen-starter` — names the underlying technology. Couples the repo to Oxygen forever.
- `warehouse-kit` — generic, technology-agnostic. Less distinctive.
- `analytics-box` — emphasizes the analyst-facing surface. OK.
- `instant-warehouse` — overpromises ("instant" isn't honest about the 35-60 minute install).

**Chat's lean:** None — the user's call.

**Cost of resolving:** rename the GitHub repo (one click, but breaks any external links/clones). Update README, LOG.md, CLAUDE.md, internal references in scripts (`PROJECT_NAME` defaults, hostname defaults, etc.). Estimated 1-2 hours of follow-up work after the rename.

---

## How these resolve

A future Chat-side session works through the 5 decisions. The shape of that session:

1. Each decision gets ~10 minutes of consideration.
2. Resolution is recorded in this file: "Decided: <choice>. Rationale: <one paragraph>."
3. A follow-up Code plan ("Plan 1 — Bake design decisions + shellcheck") updates the v4 scripts to reflect the chosen options, runs shellcheck, and prepares the bundle for first real install.
4. After Plan 1, "Plan 2 — First real install end-to-end" provisions a fresh EC2 and runs `bootstrap.sh`.

Until then, the v4 scripts ship with the placeholder defaults named above, and the README + LOG.md flag them as not-yet-resolved.
