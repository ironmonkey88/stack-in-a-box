# STACK_IN_A_BOX_PLAN.md — Full Design Plan

**Audience:** Code (executor) and the user (decisions). Chat (architect) wrote it.

**Premise:** Package a proven analytics stack — EC2 + Docker + Oxygen + Python + dlt + dbt-duckdb + Tailscale + nginx + systemd + the run.sh contract + the admin observability layer + the five portal generators — as a deployable template. A fresh EC2 with credentials in hand reaches "ask the chat a question, get an answer with a trust contract" in 35–55 minutes.

**Out of scope for this plan:** Postgres/Snowflake support, Kubernetes, multi-workspace Oxygen mode, HTTPS, a Magic Link auth flow, a scaffolding command (`make new-pipeline`). All of those are post-template work.

---

## 1. The 10 Scripts at a Glance

Each script is idempotent (re-running is safe), gated (a verify step at the end either passes or surfaces what failed), and named with a leading two-digit number so they sort in execution order. Each is callable standalone or via the `bootstrap.sh` wrapper.

| # | Script | Time | Walking-away? |
|---|---|---|---|
| 01 | `01_ec2_bootstrap.sh` | 4–6 min | After ~30 sec of prompts |
| 02 | `02_install_docker.sh` | 2–3 min | Yes |
| 03 | `03_install_oxygen.sh` | 1–2 min | Yes |
| 04 | `04_python_venv.sh` | 2–4 min | Yes |
| 05 | `05_clone_and_config.sh` | 1–2 min | Needs API key paste |
| 06 | `06_tailscale_join.sh` | 2–3 min | Needs auth key + AWS SG edit |
| 07 | `07_nginx_site.sh` | 2–3 min | Yes |
| 08 | `08_systemd_units.sh` | 1–2 min | Yes |
| 09 | `09_first_run.sh` | 15–25 min | Yes — this is the smoke test |
| 10 | `10_verify.sh` | 2–3 min | Needs a browser at the end |

Total: 32–53 minutes of wall clock, ~10 minutes of human attention.

---

## 2. The Pre-Install Contract (what the user has to bring)

The plan assumes — and the install fails loud if missing — these are in hand before script 01 runs:

| Item | Where it goes | Acquired from |
|---|---|---|
| AWS account with EC2 permissions | Used to provision; never copied to instance | AWS console |
| SSH keypair `.pem` | User's laptop `~/.ssh/` | AWS console at instance-launch time |
| Anthropic API key | Pasted into script 05's prompt | console.anthropic.com |
| Tailscale auth key (single-use, expiring) | Pasted into script 06's prompt | login.tailscale.com/admin/settings/keys |
| GitHub access to the template repo | `git clone` in script 05 | Public repo, or `gh auth login` for private |

A pre-flight check in `00_preflight.sh` (optional, called by `bootstrap.sh`) verifies these are reachable from the EC2 instance before any state-changing work begins. Fails loud, points at exactly what's missing.

---

## 3. Per-Script Deep Dive

### 01 — `01_ec2_bootstrap.sh`

**Goal:** Get a fresh Ubuntu 24.04 LTS ARM EC2 instance into a state where every later script's prerequisites are installed.

**What it does, in order:**

1. `apt update && apt upgrade -y` — fully patch the box. Reboots if the kernel updated.
2. `apt install -y` the base packages: `git`, `curl`, `wget`, `unzip`, `gcc`, `g++`, `make`, `software-properties-common`, `ufw`, `apache2-utils`, `python3.12`, `python3.12-venv`, `python3.12-dev`. The Oxygen docs list a similar set; `apache2-utils` is added for `htpasswd` (Basic Auth on `/chat` later — even though this plan defers that step, the binary is cheap to install).
3. `chmod 755 /home/ubuntu` — load-bearing for nginx www-data to traverse to in-repo dbt docs. The box pre-empts the default-mode-750 footgun.
4. `mkdir -p /home/ubuntu/stack-in-a-box/{data,scratch}` — scaffold the working directories the rest of the install populates.
5. UFW base posture: allow 22, allow 80, deny everything else. SG rules at AWS layer are stricter; this is defense-in-depth.

**Verify gate:**

- `python3.12 --version` resolves to 3.12.x
- `which htpasswd` resolves
- `stat -c "%a" /home/ubuntu` returns 755
- `[ -d /home/ubuntu/stack-in-a-box ]` succeeds

**Failure modes worth handling:**

- Slow apt mirror — `set -e` will halt; surface "this is mirror speed, not script bug." Retry-friendly: the script is idempotent.
- Kernel update reboot — script exits 100 with "rebooting, rerun me when SSH comes back." `bootstrap.sh` knows to wait + retry.

**Pattern source:** Oxygen's `create-machine.md` deployment doc + the `/home/ubuntu` 750→755 gotcha.

### 02 — `02_install_docker.sh`

**Goal:** Install Docker via the official one-liner and make `ubuntu` user a group member so `docker ps` works without `sudo`.

**What it does:** `curl -fsSL https://get.docker.com | sh` → `sudo usermod -aG docker ubuntu` → `sudo systemctl enable --now docker`.

**Verify gate:** `docker --version`, `docker ps` succeeds, `systemctl is-enabled docker` returns "enabled".

**Pattern source:** Oxygen's container-runtimes doc + the standard Docker official-install one-liner.

### 03 — `03_install_oxygen.sh`

**Goal:** Install Oxygen CLI via the official installer.

**What it does:** `bash <(curl --proto '=https' --tlsv1.2 -LsSf https://get.oxy.tech)` → verify `oxy --version`. Appends `~/.local/bin` to `/etc/environment` PATH (load-bearing per Session 13).

**Decision flag:** pin Oxygen version vs. latest from get.oxy.tech. See §5 Q4.

### 04 — `04_python_venv.sh`

**Goal:** Create the project venv with the exact dlt + dbt + duckdb stack the run.sh pipeline depends on.

**What it does:** `python3.12 -m venv .venv` → `pip install -r requirements.txt`. The template ships a frozen `requirements.txt`:

```
dlt[duckdb]==1.26.0
dbt-core==1.11.9
dbt-duckdb==1.10.1
python-ulid==3.1.0
duckdb>=1.1.0
pyyaml>=6.0
requests>=2.31
```

### 05 — `05_clone_and_config.sh`

**Goal:** Clone the template repo, prompt for the Anthropic API key, write `/etc/environment` correctly.

**What it does:**

1. `git clone https://github.com/<org>/stack-in-a-box.git`.
2. Prompt: paste Anthropic API key (read without echo, validate `sk-ant-` prefix).
3. Write to `/etc/environment`: `ANTHROPIC_API_KEY=<pasted>` + `OXY_DATABASE_URL=postgresql://...`. No `export`, no quotes, no shell expansion. **Critical format detail** — `/etc/environment` is read by PAM as literal `KEY=VALUE` lines.
4. Extend the existing `PATH=` line via `sed` to include `~/.local/bin` and the venv bin.
5. `cp config.example.yml config.yml` + templated-substitute.
6. `cp dbt/profiles.example.yml ~/.dbt/profiles.yml` + templated-substitute.

**Verify gate:** A *fresh* SSH session sees the env vars: `ssh ubuntu@localhost 'echo $ANTHROPIC_API_KEY | head -c 14'` returns `sk-ant-api03-` or similar.

### 06 — `06_tailscale_join.sh`

**Goal:** Install Tailscale, join the user's Tailnet, repoint SSH to the Tailnet hostname.

**What it does:** Install Tailscale → prompt for single-use auth key → `sudo tailscale up --authkey=$KEY --hostname=stack-in-a-box --ssh=false`. **Critical: `--ssh=false`.** Tailscale SSH bypasses OpenSSH PAM, which silently breaks `/etc/environment` env-var loading.

**The big one:** if Tailnet SSH doesn't work *before* the user closes public SSH, they lock themselves out. The script explicitly does not close the SG itself — it prints instructions and forces the user to verify.

### 07 — `07_nginx_site.sh`

**Goal:** Install nginx, drop the site config, make the portal reachable at `http://<public-ip>/`.

**What it does:** Install nginx → create `/var/www/stack-in-a-box` → copy first-boot `portal/index.html` → copy site config → `sudo ln -sf` into `sites-enabled` → `sudo rm -f /etc/nginx/sites-enabled/default` → `sudo nginx -t` → `sudo systemctl reload nginx`.

### 08 — `08_systemd_units.sh`

**Goal:** Install the four systemd units (`oxy.service`, `pipeline-refresh.timer/service`, `source-health-check.timer/service`, `profile-tables.timer/service`), enable them.

**The reboot-race-condition class:** `oxy.service` *must* have `After=docker.service` and `Requires=docker.service`. The unit files in the template are pre-hardened against the race.

### 09 — `09_first_run.sh`

**Goal:** Run the smoke-test pipeline end-to-end. Prove the box works on real data.

**Default smoke test:** NYC 311 service requests, last 90 days (~200–300k records). User can pick a different cut via `--smoke-mode={small,medium,large,custom}`.

**What it does:** `./run.sh manual` — fires the 10-stage pipeline (`pipeline_run_start` → dlt → dbt run bronze+gold → dbt test → load_dbt_results → dbt run admin → dbt test admin → dbt docs generate → portal generators → limitations index → profile staleness check → `pipeline_run_end`).

**Open question — see §5:** Where does the smoke-test pipeline live in the template repo? `examples/smoke-test/` (extracted) vs. `dlt/smoke_test_pipeline.py` (in the main path with a clear "delete me" marker)?

### 10 — `10_verify.sh`

**Goal:** End-to-end functional check. Exit 0 with a green checkmark, or exit 1 with a list of what's broken.

**Checks (one per line, each with a clear pass/fail):** systemd services active → curl every route 200 → DuckDB row counts > 0 → public SG verification → browser-required final check (Answer Agent with trust contract).

---

## 4. What the Template Repo Looks Like

Anchored on a proven structure, with the dataset-specific content tokenized or removed:

```
stack-in-a-box/
├── README.md
├── QUICKSTART.md
├── bootstrap.sh
├── scripts/setup/                  ← the 10 scripts
├── requirements.txt
├── config.example.yml
├── run.sh
├── nginx/stack-in-a-box.conf
├── systemd/                        ← 4 units, tokenized
├── dbt/                            ← bronze + gold + admin models for the smoke source
├── dlt/                            ← smoke_test_pipeline.py + load_dbt_results.py
├── semantics/                      ← views + topics for smoke
├── agents/                         ← answer_agent.agent.yml (generic)
├── portal/                         ← first-boot index.html + generated routes
├── scripts/                        ← portal generators + run helpers
└── docs/
    ├── ARCHITECTURE.md
    ├── SETUP.md
    ├── HARDENING.md                ← HTTPS, Basic Auth, backups (post-install)
    └── SWAP_IN_YOUR_DATA.md        ← the "just add data" doc
```

Token convention: the v4 setup scripts actually substitute **three** tokens via `sed` at install time — `{{PROJECT_NAME}}` + `{{DUCKDB_PATH}}` (script 05, into `config.yml` and `dbt/profiles.yml`) and `{{PROJECT_ROOT}}` (script 08, into the systemd units). The nginx docroot (`/var/www/stack-in-a-box`) is **hardcoded** in `07_nginx_site.sh` and must be hardcoded literally in `nginx/stack-in-a-box.conf` (script 07 copies the conf verbatim, no substitution). The Tailnet hostname is **derived at runtime** and written to `scratch/tailnet_identity.env` — no file is token-substituted with it. (Dry-run #6, 2026-05-28, found the earlier "`{{NGINX_DOCROOT}}` + `{{TAILNET_HOSTNAME}}`" convention claim was wrong: no script substitutes those two, and the claim omitted `{{DUCKDB_PATH}}` which is substituted. Plan 2's second-batch artifacts must not rely on those two phantom tokens being auto-filled.)

---

## 5. Decisions That Needed the User's Call (RESOLVED 2026-05-27)

> **All five were resolved 2026-05-27 (Plan 1) — see [`OPEN_DECISIONS.md`](OPEN_DECISIONS.md) for the resolutions, rationale, and forward implications.** The framing below is the design-time snapshot, preserved as a record of what the trade-off space looked like before the calls were made.

Five questions worth resolving before scripts go to production:

**Q1. Tailscale required, or optional?**

- *Required* — cleanest security posture. Cost: user needs a free Tailscale account.
- *Optional* — script 06 becomes "either Tailscale OR Basic Auth on `:3000`." Doubles the surface area of scripts 06 + 07.
- **Chat's lean:** required.

**Q2. Smoke-test data: NYC 311 (preferred), USGS Earthquakes, or something else?**

- NYC 311: clean SODA endpoint, well-documented schema, generous rate limits; one config file change to point the dlt pipeline at it.
- USGS: different API shape, validates the template isn't accidentally SODA-coupled.
- **Chat's lean:** NYC 311 for v1, document "swap in any SODA dataset by changing 3 lines."

**Q3. Smoke test in main path or `examples/smoke-test/`?**

- *Main path* with delete-me markers: faster to draft.
- *Extracted* to `examples/`: cleaner conceptual story.
- **Chat's lean:** main path with prominent "🚧 Delete this when connecting your data" markers.

**Q4. Pin Oxygen version, or use latest from get.oxy.tech?**

- *Latest:* always current, may break with upstream changes.
- *Pin:* reproducible installs, but the template ages.
- **Chat's lean:** pin to a known-good Oxygen version at template publish time.

**Q5. Project name for the template repo?**

- Candidates: `stack-in-a-box`, `oxygen-starter`, `warehouse-kit`, `analytics-box`, `instant-warehouse`.
- **Chat has no strong opinion** — the user's call. The plan uses `stack-in-a-box` as a placeholder throughout.

---

## 6. Time Estimate, Defended

Plan-to-shipped: **~40 hours, ~10 sessions, ~10 days calendar.**

| Block | Hours |
|---|---|
| Strip dataset-specific content, tokenize the templates | 4–6 |
| Write 10 setup scripts | 10–14 |
| Build smoke-test pipeline (dlt + bronze + gold + view + topic + agent prompt) | 5–7 |
| Parameterize `run.sh` + admin tables + generators for the smoke schema | 4–6 |
| First-boot portal, README, QUICKSTART, HARDENING, SWAP_IN_YOUR_DATA | 5–8 |
| Test on a fresh EC2 (the one thing we forgot) | 8–10 |

Last row is non-negotiable. Every real install hits one assumption nobody coded for. The box is no different.

---

## 7. What the User Actually Experiences

The 30-minute happy path, told as a story:

> User launches a t4g.medium with the AMI ID from the README. SSHes in with the .pem key. Runs `curl -fsSL https://raw.githubusercontent.com/<org>/stack-in-a-box/main/bootstrap.sh | bash`. Pastes their Anthropic API key when prompted, pastes a Tailscale auth key when prompted, accepts the printed AWS SG instructions and edits the SG on their laptop, verifies Tailnet SSH works.
>
> Walks away for 15 minutes while the smoke test pulls 200k NYC 311 records, builds bronze/gold, runs dbt tests, generates the trust page, builds the ERD.
>
> Comes back, opens `http://<tailnet-hostname>:3000/` in their browser, asks the chat "how many records?" and sees `200,847` with a SQL block, a row count, and a citation to `main_gold.fct_smoke_test`.
>
> Total elapsed: 32 minutes. Total typing: ~8 commands and 2 paste-ins.
>
> They open `SWAP_IN_YOUR_DATA.md`, see an 8-step checklist of which files to edit to point the pipeline at their real source, get to work.

That's the product.

---

## 8. Required follow-up work (separate plans)

Required follow-up work, scoped as separate plans:

- **Multi-workspace Oxygen mode** — requires Oxygen's wizard to grow an "existing DuckDB" path.
- **HTTPS** — Caddy or Let's Encrypt + nginx. Documented in `HARDENING.md`.
- **Basic Auth on `/chat`** — nginx + htpasswd. Documented in `HARDENING.md`.
- **Backups** — DuckDB file snapshots. Documented in `HARDENING.md`.
- **Multi-source pipelines** — the template ships one smoke-test source.
- **Alternative warehouses** — Postgres, Snowflake, BigQuery.
- **CI/CD** — GitHub Actions for the template repo itself.

---

## 9. The second batch — artifacts still to build (Plan 2)

The v4 setup scripts reference these files but they haven't been built yet. Until they exist, `09_first_run.sh` fails at its `[[ ! -x "$RUN_SH" ]]` precondition (and `05`/`07`/`08` die earlier on their own missing inputs). Building these is **Plan 2's** core scope; the additional hardening + docs to fold in alongside them are consolidated in [`IMPROVEMENTS_BACKLOG.md`](IMPROVEMENTS_BACKLOG.md).

| File | Purpose | Read by |
|---|---|---|
| `requirements.txt` | Pinned dlt/dbt/duckdb/python-ulid versions | script 04 |
| `config.example.yml` | Oxygen config template (`{{PROJECT_NAME}}` + `{{DUCKDB_PATH}}` only) | script 05 |
| `dbt/profiles.example.yml` | dbt profile template (same token whitelist) | script 05 |
| `nginx/stack-in-a-box.conf` | nginx site config (docroot hardcoded `/var/www/stack-in-a-box`) | script 07 |
| `portal/index.html` | first-boot portal | script 07 |
| `systemd/oxy.service` + 3 timer/service pairs | the 4 systemd units (`{{PROJECT_ROOT}}` token) | script 08 |
| `run.sh` | the 10-stage orchestrator (`run.sh manual`) | script 09 |
| `dlt/smoke_test_pipeline.py` | NYC 311 SODA pull | run.sh stage 1 |
| `dlt/load_dbt_results.py` | append run_results.json → admin | run.sh |
| `dbt/models/{bronze,gold,admin}/*.sql` | warehouse models — gold **must** produce `main_gold.fct_smoke_test`; admin **must** produce `main_admin.fct_pipeline_run_raw` | run.sh stages 2 + 5 |
| `semantics/views/smoke_test.view.yml` + `topics/smoke_test.topic.yml` | semantic layer for the smoke data | agent |
| `agents/answer_agent.agent.yml` | trust-contract-bearing agent prompt | run.sh / agent |
| `scripts/pipeline_run_start.py` + `pipeline_run_end.py` | run envelope | run.sh |
| `scripts/source_health_check.py` | hourly source liveness | timer |
| `scripts/profile_tables.py` + `check_profile_staleness.py` | profiling helpers | run.sh / timer |
| `scripts/generate_*.py` (5 portal generators) | `/metrics` `/trust` `/profile` `/erd` pages | run.sh |
| `scripts/build_limitations_index.py` | limitations registry index | run.sh |

Estimated ~10-14 hours, mostly tokenization + parameterization of a proven stack. See `IMPROVEMENTS_BACKLOG.md` §A for the hard interface contract these must honor.

---

*Plan written 2026-05-13 by Chat. §5 decisions resolved 2026-05-27 (Plan 1). §9 added 2026-05-28 (the missing-artifacts list was previously only in the v4 handoff §9 — surfaced as a broken cross-reference while batching the improvements backlog). Hand to Code for execution per the Plans Registry.*
