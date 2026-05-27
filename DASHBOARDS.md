# DASHBOARDS.md — Design standard for dashboards

This file is thin at v1. It will fill out as the project accumulates dashboards.

The shape below preserves the structural skeleton from the sibling project's discipline. Sections marked with **(future)** will be populated when this project ships its first dashboard.

---

## 1. Two audiences, two dashboard kinds

Dashboards in this platform serve two distinct audiences:

- **Analysts** — people who need to drill into the data, ask "why," and follow chains of evidence. Analyst dashboards are dense, comprehensive, and include trust-contract receipts on every metric.
- **Residents (or other end-users)** — people who need a verdict and the context that makes it interpretable. Resident dashboards lead with the verdict and surface the question/method/limitations as supporting layers.

These two styles are not opposed — they're for different audiences with different decision contexts. The same data can drive both.

## 2. The purpose+audience step (required for every dashboard)

Before any dashboard is built, the design includes:

- **Purpose** — what decision does this dashboard inform?
- **Audience** — who's reading it, in what context?
- **Trust contract** — what receipts does every number carry?

This is the working-backwards discipline applied to dashboards. Building a dashboard before answering these is the wrong order.

## 3. Analyst dashboards: four-tier structure **(future)**

Analyst dashboards typically organize into four tiers:

- **Headline.** The one-glance summary.
- **Composition.** What makes up the headline.
- **Trend.** How it's changed.
- **Comparison.** How it relates to other slices.

The four-tier structure is a pattern, not a mandate — some dashboards naturally have three tiers, some have five. The structure helps the analyst know where to look.

Full tier conventions will be defined when the first analyst dashboard ships in this project. Until then, refer to the [`oxygen-mvp` DASHBOARDS.md](https://github.com/ironmonkey88/oxygen-mvp/blob/main/DASHBOARDS.md) for the reference implementation.

## 4. Resident dashboards: verdict-first family **(future)**

For resident-facing dashboards, the verdict-first family is the recommended template:

- **Verdict step** — the one-sentence answer with directional framing (good/bad/mixed) calibrated to the data.
- **Recent-situation layer** — what the data actually shows, in plain language.
- **Method step** — what the platform did to arrive at the verdict, in 1-2 sentences.
- **Limitations step** — the relevant limitations, stated plainly.
- **Deeper-dive link** — where to read more.

The verdict-first family was developed in `oxygen-mvp` and lands in detail in that project's `DASHBOARDS.md` §9 + the `docs/dashboard-family-design-2026-05-22.md` family design doc. **Full family infrastructure is documented there.** Adapt as Stack-in-a-Box plans accumulate dashboards.

## 5. Trust-contract receipts on every metric

Every metric a dashboard displays carries:

- The semantic-layer measure it sourced from.
- The query that produced the value (linked or revealed on click).
- The relevant limitations entries.

Trust-contract receipts are non-negotiable on dashboards — the same discipline as the agent's trust contract. If a dashboard's number isn't traceable to a source, the dashboard is a worse product.

## 6. The file contract: `apps/*.app.yml`

Each dashboard lives as a single `.app.yml` file at `apps/<name>.app.yml`. Metadata comment blocks at the top of the file expose the dashboard to the auto-generated `/dashboards` listing:

```yaml
# title: <short human-readable title>
# audience: <analyst | resident>
# topic: <semantic-layer topic the dashboard pulls from>
# status: <stable | wip | deprecated>
```

The metadata format is the contract; the body of the file is the dashboard.

## 7. Operator dashboards (carve-out)

Operator dashboards (e.g. a DBA-style admin page) are exempt from the public-dashboard standards above:

- They don't ship as `.app.yml`.
- They don't require purpose+audience design steps (the audience is the operator running the platform).
- They don't carry the same trust-contract receipts (operators read raw signals directly).
- They live behind a network-level gate (Tailnet-only, not on the public portal).

The carve-out is structural — operator dashboards solve a different problem from analyst/resident dashboards and operate under different constraints.

---

## 8. Sign-off checklist for a dashboard ship **(future)**

When the project's first dashboard ships, this section will define the sign-off gate. Likely shape:

- Purpose+audience step documented.
- Semantic-layer measures used (not hardcoded).
- Trust-contract receipts visible on every metric.
- Rendered-surface verification per `STANDARDS.md` §8.
- Limitations surfaced per the verdict-first / four-tier pattern.

---

*This doc is intentionally thin at v1. It fills out as the project accumulates dashboards.*
