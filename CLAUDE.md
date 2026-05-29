# CLAUDE.md — Operating instructions for Claude Code in this repo

This file is Claude Code's contract with the project. It does three things:

1. **Tells Claude how to orient a new user** before executing anything (the "go button" shape — see §1 below).
2. **Tells Claude the operating discipline** for this codebase: where things live, what conventions exist, how to verify work, how to commit.
3. **Tells Claude how to close** when install + smoke verify complete: a working-backwards question that lands the user where the real work begins.

The repo has a hierarchy of documents — read in this order:

**Convictions (foundational, not authority):**
- `PHILOSOPHY.md` — the principles the platform is built on. Working backwards, stages with verification, durability through metadata, honest reporting, trust contract, modular by design. Not operational — consult as a tiebreaker when a design question is open.

**Strategic + construction (authorities):**
- `STANDARDS.md` — "done done" gates by medallion tier; sign-off checklists. The build's quality contract.
- `DASHBOARDS.md` — design standard for analyst-facing + end-user-facing dashboards.
- `PROMPTS.md` — the shape every Chat-to-Code prompt takes (coding vs. information) and the 9-step receipt workflow Claude runs on every prompt.

**Operational (this file and downstream):**
- `CLAUDE.md` — operating instructions (this file).
- `LOG.md` — current status, decisions, blockers, recent sessions.
- `TASKS.md` — task tracker.
- `docs/sessions/` — per-session narratives.
- `docs/handoffs/` — end-of-thread Code → Chat summaries.
- `docs/limitations/` — the limitations registry.
- `docs/prompts/` — per-work-item Chat-issued prompts + Code-issued reports.
- `docs/design/` — the design plan, dry-run findings (script-level + flow-level), and the 5 design decisions (resolved).

---

## §1 — Orienting a new user (the "go button" shape)

**When a user opens Claude Code in this repo for the first time, Claude's first response is NOT to execute any script.**

Instead, Claude does the orientation workflow:

1. **Acknowledge the repo and the user.** "You're in `stack-in-a-box`. I see you've cloned it to a fresh EC2 instance. Before I run anything, let me orient you."
2. **Describe what Stack-in-a-Box is — in 1-2 sentences.** "A reference implementation of a trustworthy data analytics platform: EC2 + Docker + Oxygen + Python + dlt + dbt + nginx + an analyst-facing chat agent with a trust contract. The product is the discipline, not the scripts."
3. **Walk through the major sections of the repo at a high level.** The five discipline docs (CLAUDE.md, PROMPTS.md, PHILOSOPHY.md, STANDARDS.md, DASHBOARDS.md), the 13 setup scripts at `scripts/setup/`, the design materials at `docs/design/`, the handoff history at `docs/handoffs/`. A sentence or two each. Don't recite the README; point at it.
4. **Describe the working-backwards discipline.** Two or three sentences: "The platform is built on a discipline — every layer has a verification gate, every stage trusts upstream stages' verified outputs, every answer the chat agent gives carries a trust contract (SQL + row count + citations + relevant limitations). Honest reporting beats clean completion."
5. **Describe what the install process does at a high level.** "The install runs 13 scripts in order: preflight → EC2 base packages → Docker → Oxygen → Python venv → clone + config + API key → Tailscale → nginx → systemd → first smoke-test pipeline → verify. Wall clock: 35-60 minutes on a fresh EC2 instance *once the platform is complete* (see step 6 for what actually runs today), dominated by the smoke-test pipeline. ~10 minutes of human attention — mostly the AWS Security Group lockdown step in the middle." Do not present the 35-60 minute figure as today's reality — it's the figure for a finished platform; step 6 states the current truth.
6. **State the current install state honestly.** (See the callout below — this is the working-backwards discipline applied to the platform's own front door.)
7. **Ask the user when they want to begin.** "Read the orientation, ask any questions, and when you're ready, tell me to begin. I'll run the install with verify gates respected at every stage."
8. **Wait for the user's answer before doing anything else.**

> **Current install state (as of this commit):** Both batches are now in the repo. The setup scripts (batch 1) are dry-run-validated across 11+ iterations and pass shellcheck; the **application layer** (batch 2 / Plan 2 — `run.sh`, dbt bronze/gold/admin models, the dlt NYC 311 smoke pipeline, `config.example.yml` + `dbt/profiles.example.yml`, the semantic layer + Answer Agent, the run-observability + profiling + portal-generator scripts, `nginx/stack-in-a-box.conf`, the systemd units, and the first-boot portal) is **built and statically verified** (py_compile, YAML parse, `bash -n`, shellcheck, and a contract cross-check against scripts 07/09/10). **It has never been executed on a real EC2 instance** — there is no live-functional evidence yet that a clean install runs end-to-end. So: a real install *should* now proceed past step 05 and through the smoke test (DuckDB populated, `main_gold.fct_smoke_test` non-empty, the five portal routes serving, the agent answering with its trust contract), but the first real EC2 run is **Plan 3** and may surface integration issues the static checks can't (dlt against the live SODA API, dbt-duckdb schema materialization, `oxy start --local` readiness, docroot write permissions). Tell the user this plainly: the box is *assembled and checked*, not yet *proven on metal*. **This caveat is replaced by a "validated on EC2" note when Plan 3 lands.**

The orientation is the first lesson in working-backwards. By the time the user says go, they understand what's about to happen. **Do not skip this step**, even if the user seems impatient. Skipping orientation skips the discipline.

If the user has clearly been here before (repo already partly installed, `bootstrap.sh` checkpoints exist), still acknowledge — briefly — but you can be tighter ("welcome back; resuming from step N, here's what's left"). Even returning users benefit from a quick re-orientation.

## §2 — Operating discipline (how to work in this repo)

### Configuration over code

**Use declarative files first.** The platform's strength is that the discipline lives in config (YAML, SQL, bash scripts with verify gates) rather than custom code. Before writing any new Python, ask: can a config file express this? Most of the time the answer is yes.

### Stages with verification

Every layer of the pipeline has a role and a contract. Bronze trusts the source's shape. Silver trusts bronze's arrival audit. Gold trusts silver's cleanup. Admin observability records what each stage did. Each stage's *verified output* is what the next stage trusts — not the stage itself.

The captured-exit pattern in `run.sh` is load-bearing: dbt tests don't halt the pipeline; the run completes, records its DQ status, and surfaces the failure visibly. Silent test failures are the bug; visible failures are the discipline working.

### Durability through metadata

The warehouse remembers everything that happened to it. `fct_pipeline_run_raw`, `fct_source_health_raw`, `fct_data_profile`, `fct_test_run`, `dim_data_quality_test` — these admin tables are the audit trail. Any change to the platform that doesn't write to one of these surfaces is invisible.

### Honest reporting

A `partial` with a documented finding outranks a `complete` that papered over a problem. Status vocabulary: `complete`, `partial`, `blocked`, `deferred`. Pick the honest one.

### Trust contract on every answer

The chat agent's reply must always carry: SQL (rendered by the runtime), row count, citations (qualified table names + view names + relevant limitations entries), known limitations affecting the answer. Never paraphrase the methodology away. Never state a number without naming what it counts.

### Working backwards

Start from "what report do you want, who's reading it, what decision does it inform?" Build the warehouse and dashboards backwards from that. **The user-facing surface is the design — not a downstream consequence of the data.**

---

## §3 — Receiving prompts from Chat

When receiving a prompt from Chat, follow the workflow in [`PROMPTS.md`](PROMPTS.md) §5. Read the header, verify state, branch on kind, run the steps in order. Coding requests get the full 9-step flow; information requests skip to execution.

Four rules worth internalizing:

- **Code/config changes commit only after their verification gate passes.** Documentation changes (LOG.md, TASKS.md, session notes, handoffs, limitations) commit without a gate — the artifact existing in the committed state is the gate.
- **A partial completion with a documented finding outranks a fake-clean `complete`.** Pick the honest status vocabulary value.
- **The report-back (PROMPTS.md §5 Step 9) is the last thing Code emits in the session.** No afterthoughts, no "one more thing." If something surfaces after the report, it goes into the next session's report.
- **Prompts may arrive as files in `docs/prompts/plan-NN-<slug>.md`** rather than as pasted text. When they do, execution still follows PROMPTS.md §5, with Step 4's restatement and Step 9's report-back additionally written to the sibling `.report.md` file. See `docs/prompts/README.md` for the full convention.

### Autonomous PR-merge policy

After a piece of work has passed its verification gates and been committed, run `git push` → `gh pr create` → `gh pr merge --merge --delete-branch` in one autonomous flow on this repo. Don't pause to ask "want me to merge?" — the autonomy is the standing instruction.

**Pause and surface (do NOT auto-merge) when:**

- Status is `partial` or `blocked`.
- A live-functional verification gate couldn't be cleared in-session.
- A prompt's halt conditions fired.
- PR checks failed.
- The PR targets a repo other than this one.
- The user has explicitly asked you to pause before merge.

Cross-repo PRs, force-merges over failed checks, sending messages (Slack/email/PR comments), and any deploys to systems other than this project still require explicit instruction.

---

## §4 — Rules

- **Discipline-first.** Use the declarative config + verify-gate path before writing any procedural code.
- **DuckDB file locking.** dlt, dbt, and Oxygen share the warehouse file; run them sequentially, never concurrently. Order: dlt → dbt → oxy.
- **Semantic layer is the metric source of truth.** Never hardcode metrics in SQL or app configs.
- **PII redaction in silver tier.** Required before any analyst-facing surface that could carry it.
- **Flag platform-level limitations immediately.** Surface problems before building workarounds.
- **Update TASKS.md as work completes** — `[x]` done · `[~]` in progress · `[!]` blocked. Update as you go, not at end of session.
- **Update LOG.md after completing tasks, making decisions, or hitting blockers.**

### Allowlist policy (Claude Code permissions)

This repo's `.claude/settings.json` (when present — not yet committed at v1) governs which bash commands Claude Code runs without prompting. Three tiers, never mixed:

- **`settings.json` (committed, git-tracked):** universal patterns — tool-family wildcards, verification idioms, deny list. Any pattern needed across sessions, machines, or future teammates belongs here.
- **`settings.local.json` (per-machine, gitignored):** machine-specific only — SSH key paths, local MCP tools. Claude may self-amend this file freely.
- **Worktree settings.local.json (also gitignored):** must mirror canonical `settings.local.json`. Worktree drift is the bug.

Destructive subcommands (`git reset --hard`, `git push --force`, `git branch -D`, `rm -rf`, `sudo`) are explicitly denied and will always prompt regardless of allow list.

---

## §5 — Bash safety

The Claude Code permission system evaluates each Bash tool call as a single string. A hook (`.claude/hooks/block-dangerous.sh`, when configured) enforces these rules structurally:

- **Never chain commands** with `&&`, `;`, or `||`. One Bash tool call = one command. Issue follow-up commands as separate tool calls.
- **Never use command substitution** (`$(...)` or backticks). Arithmetic `$((...))` is fine.
- **Never use process substitution** (`<(...)`, `>(...)`). Write to a temp file instead.
- **Never start a command with `cd`.** Use `git -C <path> ...` or absolute paths.
- **Never use shell redirects to create files.** Use the Write tool.
- **Never use `export VAR=...`.** Use inline prefixing: `PATH=/opt/bin:$PATH command`.
- `for`/`while`/`if` loops ARE allowed.
- `sed -i` IS allowed — destructive-deny still bounds the blast radius.
- Pipes `|` ARE allowed.

The hook fires *before* Claude Code's built-in auto-allow — even a command whose leading token would normally auto-allow (`ls`, `grep`, `cat`) gets hook-denied if the command string contains a hook-blocked operator.

---

## §6 — Naming standards

### Schemas

| Schema | Purpose |
|---|---|
| `bronze` | Raw source data — arrival shape, minimal cleanup. |
| `silver` | Cleaned, typed, PII-redacted. |
| `gold` | Business-ready facts + dims. |
| `admin` | Pipeline + DQ observability. |

### Table prefixes

| Prefix | Schema | Example |
|---|---|---|
| `raw_` | bronze | `raw_<source>_<entity>` |
| `stg_` | silver | `stg_<source>_<entity>` |
| `fct_` | gold | `fct_<entity>` |
| `dim_` | gold | `dim_<entity>` |
| `fct_` | admin | `fct_pipeline_run_raw`, `fct_data_profile`, `fct_test_run` |

### Column conventions

- Snake case everywhere: `request_type`, `opened_dt`.
- Primary keys: `<table>_id` e.g. `request_id`.
- Surrogate keys: `<table>_sk`.
- Dates/timestamps: `_dt` suffix (date) / `_ts` suffix (timestamp).
- Booleans: `is_` prefix.
- Percentages: `pct_` prefix.
- Counts: `_count` suffix.

---

## §7 — Read the data first

**Before writing any dbt model columns**, query the actual source data:

```sql
DESCRIBE SELECT * FROM read_parquet('data/raw/<source>/**/*.parquet');
SELECT * FROM read_parquet('data/raw/<source>/**/*.parquet') LIMIT 5;
```

Never assume column names from API documentation. Always derive from actual data.

---

## §8 — LOG.md and sessions logging protocol

Captain's log is split: a bounded `LOG.md` summary (state) and `docs/sessions/` archive (narrative).

### LOG.md

Single-screen view of project state:

- Plans Registry: chronological table of plans with status.
- Current Status: active phase, open security gaps, last-updated timestamp.
- Recent Sessions: 5-line summary per session, linking to the full narrative.
- Earlier Sessions: one-liner summaries (rotated out of Recent when count > 5).

Target ~150 lines, hard ceiling ~250.

### Session files

Per-session narrative at `docs/sessions/session-NN-YYYY-MM-DD-<slug>.md`. Required frontmatter (controlled vocabulary):

```
---
session: <integer>
date: YYYY-MM-DD
start_time: HH:MM <TZ>
end_time: HH:MM <TZ>
type: <planning | code | hybrid | overnight>
plan: <plan-N | none>
layers: [<zero or more of: ingestion, bronze, silver, gold, admin, semantic, agent, portal, infra, docs>]
work: [<one or more of: feature, bugfix, refactor, planning, hardening, infra, docs, test>]
status: <complete | partial | blocked>
---
```

Body: five fixed sections — Goal, What shipped, Decisions, Issues encountered, Next action. Target ~100 lines per session, soft ceiling 300.

### `[x]` evidence rule

Every `[x]` in TASKS.md should be backed by one of: a commit hash, verification command output, or a file path + line range. Bare `[x]` based on "I did the thing" is not enough.

### Verification gates for `[x]` ticks

Distinguish:

- **Static-artifact boxes** — satisfied by a file existing in the committed state. Tick once on a commit hash.
- **Live-functional boxes** — satisfied by something running correctly. The `[x]` must reference a re-runnable verification command. At sign-off, re-verify in the sign-off session — inherited ticks from earlier sessions are not sufficient.

---

## §9 — Closing ritual (when install + smoke verify complete)

When the full install completes with all gates green — `bootstrap.sh` exit 0, all 13 scripts passed, smoke-test pipeline produced rows in the warehouse, the trust contract fired on the smoke-test agent query — **Claude does NOT terminate with "you're set up, goodbye."**

Claude's final action is to ask the user a working-backwards question. Close-paraphrase one of the following — Claude's own phrasing each time, never the same form twice in a row across multiple installs:

- "What's the first report you want this platform to produce?"
- "What question do you want the chat agent to answer first — and who's the analyst asking it?"
- "Who's going to read what this platform produces, and what decision does it inform for them?"
- "Pick one real question. What is it, and which dataset would it touch?"
- "If the platform answered exactly one question well this week, which one?"

The phrasing should fit the conversation's tone. Pick the framing that lands where the user is — not where the install scripts left off. The user has just watched the platform install itself; the closing ritual returns them to the discipline that made the install meaningful.

**The user should feel the discipline as a question, not a checklist.**

If the user has already named a use case during orientation (§1), the closing question pulls on that thread directly. If they were exploring the repo with no specific dataset in mind, the question opens the design space ("here's what you have now — what would you point it at?").

The closing ritual is short. One question, then wait. Don't lecture.

---

## §10 — Known gotchas

These accumulate over time as the project encounters them. The starter set covers known load-bearing operational patterns the v4 scripts depend on:

- **`/etc/environment` for env vars, NOT `~/.bashrc`.** Non-interactive SSH (`ssh ec2 'cmd'`) does not read `~/.bashrc` — Ubuntu's default `.bashrc` early-returns. `/etc/environment` is read by PAM at session setup and works for both login and non-login shells. Format: literal `KEY=VALUE`, no `export`, no quotes, no shell expansion.
- **Tailscale `--ssh=false` is load-bearing.** Tailscale SSH preempts port 22 for Tailnet peers via tailscaled, bypassing OpenSSH PAM — silently breaking `/etc/environment` env-var loading. Always pass `--ssh=false` on `tailscale up`.
- **`/home/ubuntu` must be chmod 755** for nginx www-data to traverse it (default Ubuntu is 750).
- **Disable the default nginx site explicitly.** Its `/var/www/html` docroot will shadow your config if left enabled.
- **`oxy.service` must have `Requires=docker.service` + `After=docker.service`.** Otherwise it races docker on reboot and crashes bringing up the postgres container.
- **dbt-docs uses marked.js with `sanitize: true`.** Raw HTML in dbt model overview.md gets escaped. Use plain Markdown for back-links and styled elements.
- **The bash safety hook fires *before* Claude Code's built-in auto-allow.** A command whose leading token would normally auto-allow (`ls`, `grep`, `cat`) gets hook-denied if the command string contains a hook-blocked operator. Don't use `command || fallback` thinking the auto-allow handles it.

Future gotchas should land in this section as they're discovered, with the source named (which session / which plan).
