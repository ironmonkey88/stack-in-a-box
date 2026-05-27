# Stack-in-a-Box — Executive Handoff

**Date:** 2026-05-26
**Origin:** Chat session with the user
**Status:** Setup scripts v4 complete and dry-run-validated; awaiting real-EC2 execution and the second batch (run.sh + content)

---

## 1. What this project is

**Stack-in-a-Box** packages a proven analytics stack into a deployable, dataset-agnostic template. The promise is "analytics stack in a box, just add data."

The box includes:

- EC2 + Docker + Oxygen (`oxy start --local`)
- Python venv with pinned dlt + dbt-duckdb stack
- Tailscale lockdown + AWS SG posture
- nginx with the 6-route portal shell (`/`, `/docs`, `/metrics`, `/trust`, `/profile`, `/erd`)
- `run.sh` 10-stage orchestrator with captured-exit DQ contract
- Admin observability tables (pipeline runs, source health, profile, DQ stars)
- 4 systemd units (oxy + 3 timers: pipeline-refresh, source-health, profile-tables)
- Portal generators for all 5 doc surfaces
- Limitations registry mechanics
- Mermaid warehouse + semantic-layer ERD generators
- Answer Agent skeleton + Airlayer view shape + Anthropic API wiring

The empty slots (where users plug in their data) are: one dlt pipeline, dbt models, semantic-layer YAML, agent prompt, dataset-specific portal copy.

---

## 2. Effort and time estimates (settled)

**Build effort:** ~40 hours / ~10 sessions / ~1–1.5 weeks calendar.

Earlier estimates of 3 weeks were revised down after challenge. The work is replaying a proven path, not rediscovering it. The estimate holds a non-negotiable buffer (~8–10 hours) for "the one thing we forgot," which is only findable by real EC2 execution.

**Install-time on a fresh EC2** (with credentials in hand):

| Stage | Wall time | Human attention |
|---|---|---|
| Preflight + cloud-init wait | 0–3 min | 0 |
| EC2 bootstrap (apt update + base packages) | 4–6 min | 0 |
| Docker | 2–3 min | 0 |
| Oxygen | 1–2 min | 0 |
| Clone + API key + /etc/environment | 1–2 min | ~30s (paste key) |
| Python venv + pinned packages | 2–4 min | 0 |
| **Tailscale join + script pauses** | 2–3 min | **~3 min (laptop SG edit + verify)** |
| nginx | 2–3 min | 0 |
| systemd + wait for :3000 ready | 2–4 min | 0 |
| **Smoke test (run.sh manual)** | **8–25 min** | 0 |
| Final verify | 2–3 min | ~1 min (browser check) |

Total: **35–60 minutes** on the happy path. The smoke test in step 09 dominates the wall clock.

---

## 3. Deliverables produced this session

Three artifacts:

### 3.1 `STACK_IN_A_BOX_PLAN.md`

Full design doc covering: 10 setup scripts at a glance, pre-install contract, per-script deep dive (goal/work/verify gate/failure modes/pattern source), template repo layout, 5 open decisions, defended time estimate, 30-minute happy-path user story, explicit out-of-scope items.

### 3.2 `stack-in-a-box-setup-scripts-v4.tar.gz`

13 files, all pass `bash -n` syntax check:

- `scripts/setup/bootstrap.sh` — orchestrator with flock + checkpointing + resume
- `scripts/setup/00_preflight.sh` — OS/arch/network/disk/RAM/cloud-init/snap-docker checks
- `scripts/setup/01_ec2_bootstrap.sh` — apt update + base packages + UFW + /home/ubuntu 755
- `scripts/setup/02_install_docker.sh` — official Docker install + group + enable
- `scripts/setup/03_install_oxygen.sh` — get.oxy.tech installer; verifies --version after
- `scripts/setup/04_python_venv.sh` — venv + pinned dlt/dbt/duckdb from requirements.txt
- `scripts/setup/05_clone_and_config.sh` — git clone, API key prompt, /etc/environment
- `scripts/setup/06_tailscale_join.sh` — tailscale up --ssh=false + AWS SG instructions
- `scripts/setup/07_nginx_site.sh` — nginx install + site config + first-boot portal
- `scripts/setup/08_systemd_units.sh` — 4 systemd units; waits for :3000 ready (not just is-active)
- `scripts/setup/09_first_run.sh` — verifies oxy ready, runs run.sh manual under setsid
- `scripts/setup/10_verify.sh` — every route + DuckDB rowcount + mandatory SG check
- `scripts/setup/lib/common.sh` — logging, idempotency, env-aware secret reading
- `scripts/setup/README.md` — user-facing install guide

Every script is idempotent, gated (verify_gate function), and `set -euo pipefail` clean. None have been executed on a real EC2.

### 3.3 `DRY_RUN_FINDINGS.md`

Log of 11 dry-run review iterations. 79 issues surfaced, 33 real and fixed, 46 cancelled on deeper inspection. Includes the bug discovery curve, methodological observations, and the recommendation to stop dry-running.

---

## 4. Load-bearing patterns encoded in the v4 bundle

Every one of these is a hard-won operational lesson, encoded into one line of bash:

| Pattern | Why it matters |
|---|---|
| `/etc/environment` (not bashrc) for non-interactive SSH env vars | `~/.bashrc` early-returns under `ssh host 'cmd'`; PAM reads `/etc/environment` |
| `--ssh=false` on `tailscale up` | Tailscale SSH preempts OpenSSH PAM and silently breaks env-var loading |
| User does AWS SG edit themselves (lockout protection) | Script-driven SG closure before Tailnet SSH verify = lockout |
| `/home/ubuntu` chmod 755 for nginx traversal | Default Ubuntu mode 750 silently breaks docroot traversal |
| Disable default nginx site explicitly | Default site's `/var/www/html` shadows the project docroot |
| `Requires=docker.service` + `After=docker.service` on oxy.service | Otherwise oxy.service races docker on reboot and crashes |
| Captured-exit DQ contract in run.sh | dbt test failures should surface visibly, not halt the pipeline |
| `pipeline_run_start/end.py` envelope | Every run leaves an admin-table audit trail |
| 10-stage run.sh contract | Stable contract analysts and operators can rely on |
| Poll `:3000` HTTP code (not `systemctl is-active`) for readiness | "active" fires before the SPA actually listens; HTTP probe is the truth |
| `curl -sI` not `curl -fsS` for preflight (4xx is reachable) | Bare-domain API endpoints commonly return 4xx without auth |
| `flock` on bootstrap.sh to prevent concurrent installs | Concurrent installs race on apt locks and `/etc/environment` |
| Wait for cloud-init before apt-get | Fresh EC2 cloud-init holds the dpkg lock for ~60-90s |
| `read_secret` accepts env-var override for non-interactive installs | Unblocks CI / unattended install paths |
| `require_not_root` on scripts that write to $HOME | `sudo bash bootstrap.sh` would put $HOME=/root and misconfigure |
| Position-based step-id filtering (not lex compare) for --from | The STEPS array isn't in numeric order (05 before 04) |
| `setsid` for the smoke test so it survives SSH disconnect | 8-25 minute pipelines shouldn't die when SSH drops |
| IMDSv2-based auto-detection of EC2 public IP for SG verification | Final verify must fail loud if public ports are still open |

---

## 5. Open decisions

The v4 scripts ship with defensible defaults for all five. Any can be changed via `sed` over the bundle.

| # | Decision | Chat's default | Chat's lean |
|---|---|---|---|
| 1 | Tailscale required vs. optional | Required | Keep required (Basic Auth is a worse story) |
| 2 | Smoke-test data source | NYC 311 SODA | Keep NYC 311 for v1 (clean SODA endpoint, well-documented schema, generous rate limits) |
| 3 | Smoke test in main path vs. `examples/` | Main path with delete-me markers | Keep main path; cheapest path that earns the "in a box" framing |
| 4 | Pin Oxygen version vs. `get.oxy.tech` latest | Latest (with TODO comment) | Pin at publish time once a known-good version is identified |
| 5 | Repo name | `stack-in-a-box` placeholder | No strong opinion — the user's call |

Full framing of each in `docs/design/OPEN_DECISIONS.md`.

---

## 6. Dry-run review summary

11 simulated-execution passes, each with a different lens:

| Iter | Theme | Critical | High | Medium | Low/Cosmetic |
|---|---|---|---|---|---|
| 1 | Entry-point and ordering integrity | 1 | 2 | 1 | 1 |
| 2 | Error masking and false-success | 0 | 1 | 2 | 3 |
| 3 | Timing and readiness semantics | 0 | 1 | 1 | 0 |
| 4 | Resume robustness and automation | 0 | 1 | 0 | 0 |
| 5 | Real-world HTTP response codes | 1 | 0 | 1 | 0 |
| 6 | Cross-script contracts | 0 | 1 | 0 | 2 |
| 7 | Real-world cloud quirks | 0 | 0 | 3 | 2 |
| 8 | Documentation drift | 0 | 1 | 2 | 1 |
| 9 | Security boundaries | 0 | 1 | 1 | 1 |
| 10 | User-impatience and SSH fragility | 0 | 1 | 1 | 2 |
| 11 | Subtle wrong-but-runs | 0 | 0 | 1 | 3 |

**Two critical bugs found**, both early. **Zero critical bugs in the last six iterations** — clear diminishing-returns signal.

**The two critical bugs were:**

1. **Iter 1:** `PROJECT_ROOT` was hardcoded to `/home/ubuntu/stack-in-a-box`, breaking the install on non-default paths. Fixed with auto-derivation from script location.
2. **Iter 5:** `curl -fsS` in preflight failed on every install because API gateways and download endpoints return 4xx to bare-domain requests. Fixed by treating any HTTP response as "reachable."

---

## 7. Recommendation: stop dry-running, start real-installing

Five reasons (per the final findings doc):

1. **Zero critical bugs in the last 6 iterations.** The catastrophic class is empty.
2. **The bug profile has shifted to polish.** Iters 9–11 fixes were small.
3. **Remaining unknowns can only be found by execution.** Three classes of bug — external service behavior, real hardware timing, API-under-load — are not findable by reading.
4. **Bugs that could exist via more dry-run are increasingly improbable.** "What if /etc/environment has CRLF?" — theoretically yes, practically no.
5. **The bundle grew 43% from defensive code.** Additional defenses become a maintenance burden in their own right.

---

## 8. Next steps, in order

1. **Hand v4 bundle to Code** for a `shellcheck` pass + idiom review. Code has access to a real shell environment Chat doesn't.
2. **Provision a fresh t4g.medium and run `bootstrap.sh` end-to-end.** Budget 90 minutes. Capture first real failure, fix, iterate 2–3 times.
3. **Build the second batch** — see §9 below.

---

## 9. The second batch — what's still missing

These are referenced by the v4 scripts but live elsewhere in the template repo and haven't been built yet. Until they exist, `09_first_run.sh` will fail at its precondition check `[[ ! -x "$RUN_SH" ]]`.

| File | Purpose |
|---|---|
| `requirements.txt` | Pinned dlt/dbt/duckdb versions; script 04 reads this |
| `config.example.yml` | Oxygen config template; script 05 substitutes tokens |
| `dbt/profiles.example.yml` | dbt profile template; script 05 substitutes the DuckDB path |
| `nginx/stack-in-a-box.conf` | nginx site config; script 07 deploys this |
| `systemd/oxy.service` + 3 timer/service pairs | 4 systemd units; script 08 deploys these |
| `portal/index.html` | First-boot portal; script 07 deploys this |
| `dlt/smoke_test_pipeline.py` | NYC 311 SODA pull; run.sh stage 1 |
| `dbt/models/{bronze,gold,admin}/*.sql` | run.sh stages 2 + 5 |
| `semantics/views/smoke_test.view.yml` | semantic layer for smoke data |
| `semantics/topics/smoke_test.topic.yml` | topic group |
| `agents/answer_agent.agent.yml` | trust-contract-bearing agent prompt |
| `scripts/pipeline_run_start.py` + `pipeline_run_end.py` | envelope helpers |
| `scripts/source_health_check.py` | hourly source liveness |
| `scripts/profile_tables.py` + `check_profile_staleness.py` | profiling helpers |
| `scripts/generate_metrics_page.py` etc. | 5 portal generators |
| `scripts/build_limitations_index.py` | limitations registry |
| `run.sh` | the 10-stage orchestrator |

Estimated effort for the second batch: ~10–14 hours of tokenization, parameterization, and content authoring.

---

## 10. Cross-batch flags surfaced during dry-runs

Two items found during dry-run reviews that belong in the second batch:

1. **`run.sh` must write portal output to `/var/www/stack-in-a-box/`, not to `$PROJECT_ROOT/portal/`.** The setup scripts deploy `portal/index.html` once to the docroot during install; the runtime portal-generators are expected to write to the docroot directly. (Surfaced iter 6.)

2. **`run.sh` needs orphaned-run cleanup.** If the smoke test is killed mid-execution (SSH drop, Ctrl-C), `fct_pipeline_run_raw` has an in-progress row with no end_time. `run.sh` should detect these on startup (e.g., `ran_at_utc < now() - 1 hour AND end_time IS NULL`) and mark them as `crashed`. (Surfaced iter 10.)

---

## 11. Out of scope (deliberate)

These are documented as not-in-this-template, to be addressed by follow-up plans:

- **Multi-workspace Oxygen mode** (current install uses `oxy start --local`)
- **HTTPS** (documented in `HARDENING.md` as a recommended post-install step)
- **Basic Auth on `/chat`** (documented in `HARDENING.md`)
- **Backups** (documented in `HARDENING.md`)
- **Multi-source pipelines** (the template ships one smoke-test source)
- **A scaffolding command** (`make new-pipeline`) — chose to ship cookiecutter-style tokens instead
- **Alternative warehouses** (Postgres, Snowflake, BigQuery)
- **CI/CD** (GitHub Actions for the template repo itself)
- **An uninstall script** (surfaced iter 10; noted for product roadmap)

---

## 12. Process observations worth carrying forward

### The dry-run technique has a clear shape of useful application

- Iters 1–2 are essential (catastrophic and structural bugs)
- Iters 3–5 are very valuable (cross-cutting concerns)
- Iters 6–8 are valuable (real-world friction)
- Iters 9–10 are valuable (security/UX cliffs)
- Iter 11 is marginal
- Iter 12+ would be waste

**5–8 iterations is the right depth for the technique on similar bundles.**

### What dry-runs found that syntax checks didn't

Every iteration's bugs passed `bash -n`. The bugs were only visible when asking, repeatedly, "what does this script *do* when its quiet assumptions break?" — wrong path, wrong stdin, wrong HTTP response code, wrong systemd readiness signal.

### Themes that recurred across multiple iterations

1. **Orchestration hides scarier bugs than the scripts themselves.** Most critical bugs were in the wiring between scripts, not in individual scripts.
2. **Silent successes outnumber loud crashes.** Every iter found at least one `|| true` swallowing a real failure.
3. **"Configured" ≠ "ready" ≠ "reachable."** Three layers, three signals, easy to conflate.
4. **TTY assumptions block automation.** ~20 lines of env-var-override code unlocks CI.
5. **The most defensible-looking code hides the worst bugs.** Preflight, "already-installed" checks — these look bulletproof until they meet a 403 response.

---

## 13. Files for handoff

All landed in the `stack-in-a-box` repo on 2026-05-27:

- This doc — `docs/handoffs/2026-05-26-stack-in-a-box-v4-handoff.md`
- `docs/design/STACK_IN_A_BOX_PLAN.md` — full design plan
- `docs/design/DRY_RUN_FINDINGS.md` — review log + recommendation
- `docs/design/OPEN_DECISIONS.md` — the 5 decisions, dedicated doc
- `scripts/setup/*` — the 13 v4 scripts as a real source tree

---

*Handoff doc generated 2026-05-26. Landed in the stack-in-a-box repo on 2026-05-27. Next session can pick up at §8 (next steps) without re-deriving context.*
