# Stack-in-a-Box — Setup Scripts (v4)

Companion to `docs/design/STACK_IN_A_BOX_PLAN.md` and `docs/design/DRY_RUN_FINDINGS.md`. These are the 10 setup scripts + shared library + bootstrap wrapper. Together they drop a fresh Ubuntu 24.04 EC2 into a state where the Oxygen SPA + dlt + dbt + portal are all wired up and a smoke-test pipeline has run end-to-end.

This is the v4 bundle, reflecting **11 dry-run iterations** that surfaced 79 issues (33 real fixes, 46 cancelled) and validated the orchestration end-to-end. See `docs/design/DRY_RUN_FINDINGS.md` for the full iteration log.

## What's here

```
scripts/setup/
├── bootstrap.sh                ← run this; orchestrates the rest with flock + checkpointing
├── 00_preflight.sh             ← OS/arch/network/disk/RAM + cloud-init wait + snap-docker warning
├── 01_ec2_bootstrap.sh         ← apt update + base packages + UFW + /home/ubuntu 755
├── 02_install_docker.sh        ← official Docker install + group + enable
├── 03_install_oxygen.sh        ← get.oxy.tech installer; verifies --version after install
├── 04_python_venv.sh           ← venv + pinned dlt/dbt/duckdb from requirements.txt
├── 05_clone_and_config.sh      ← git clone, ANTHROPIC_API_KEY prompt (or env), /etc/environment
├── 06_tailscale_join.sh        ← tailscale up --ssh=false + prints AWS SG instructions
├── 07_nginx_site.sh            ← nginx install + site config + first-boot portal
├── 08_systemd_units.sh         ← 4 systemd units; waits for :3000 (not just is-active)
├── 09_first_run.sh             ← verifies oxy ready, then runs run.sh manual (the smoke test)
├── 10_verify.sh                ← curl every route + DuckDB rowcount + browser instructions
└── lib/
    └── common.sh               ← logging, idempotency, env-aware secret reading
```

Every script passes `bash -n` syntax check. Each is idempotent (re-runs are safe), gated (verify_gate function at the end), and `set -euo pipefail` clean. The scripts have been dry-run reviewed but **never executed on a real EC2** — the "buffer for the one thing we forgot" still applies.

## What's NOT here (still in the second batch)

These are referenced by the scripts but live elsewhere in the template repo:

- `requirements.txt` (script 04 reads this)
- `config.example.yml` (script 05 templates this)
- `dbt/profiles.example.yml` (script 05 templates this)
- `nginx/stack-in-a-box.conf` (script 07 deploys this)
- `systemd/oxy.service` + 3 timer/service pairs (script 08 deploys these)
- `portal/index.html` first-boot copy (script 07 deploys this)
- `dlt/smoke_test_pipeline.py` (the smoke source pull)
- `dbt/models/{bronze,gold,admin}/*.sql`
- `semantics/views/smoke_test.view.yml`, `topics/smoke_test.topic.yml`
- `agents/answer_agent.agent.yml` (the trust-contract-bearing prompt)
- `scripts/*.py` generators and pipeline-run helpers
- `run.sh` itself (the 10-stage orchestrator)

## Time estimate (revised after iter 7)

Total wall clock: **35-60 minutes** on the happy path, with ~10 minutes of human attention.

| Stage | Wall time | Human attention |
|---|---|---|
| Preflight + cloud-init wait | 0-3 min | 0 |
| EC2 bootstrap | 4-6 min | 0 |
| Docker | 2-3 min | 0 |
| Oxygen | 1-2 min | 0 |
| Clone + API key + /etc/environment | 1-2 min | ~30s (paste key) |
| Python venv + pinned packages | 2-4 min | 0 |
| **Tailscale join + script pauses** | 2-3 min | **~3 min (laptop SG edit + verify)** |
| nginx | 2-3 min | 0 |
| systemd + wait for :3000 ready | 2-4 min | 0 |
| **Smoke test (run.sh manual)** | **8-25 min** | 0 |
| Final verify | 2-3 min | ~1 min (browser check) |

## Pre-install contract

| Item | Where it goes | How to get it |
|---|---|---|
| AWS account with EC2 permissions | Used to provision | AWS console |
| SSH keypair `.pem` | Your laptop `~/.ssh/` | At instance-launch time |
| Anthropic API key | Pasted at script 05, or env: `ANTHROPIC_API_KEY` | console.anthropic.com |
| Tailscale auth key | Pasted at script 06, or env: `TAILSCALE_AUTHKEY` | login.tailscale.com/admin/settings/keys |
| **A Tailnet** you can join | (just need the account) | tailscale.com |

The install is **interactive by default** (TTY prompts for the two keys) but **fully scriptable** if you pre-set `ANTHROPIC_API_KEY` and `TAILSCALE_AUTHKEY` env vars.

## How to use

```bash
cd ~/stack-in-a-box
./scripts/setup/bootstrap.sh
```

bootstrap.sh runs scripts 00–10 in order. **It stops twice for human action:**

1. **After step 06 (Tailscale):** prints AWS SG lockdown instructions. Edit the SG on your laptop, verify Tailnet SSH works, then resume with `./bootstrap.sh --from 07`.
2. **After step 10 (final verify):** prints browser instructions to manually test the chat agent. No more scripts to run after this — the box is yours.

## Flags

```bash
./scripts/setup/bootstrap.sh --dry-run      # print plan, do nothing
./scripts/setup/bootstrap.sh --from 09      # resume from a specific step
./scripts/setup/bootstrap.sh --only 09      # run a single step (bypasses checkpoint)
./scripts/setup/bootstrap.sh --force        # ignore checkpoints, re-run everything
```

**Note: the plan dry-run prints step 05 before step 04.** Intentional — clone (05) deposits the requirements.txt that venv-install (04) reads.

## Caveats

- These scripts have been **dry-run reviewed** but never executed end-to-end on a real EC2. A real install will surface 1-2 issues that no amount of reading could catch.
- The smoke test in step 09 assumes the `run.sh` + dbt models + dlt pipeline + view YAML + agent prompt all exist in the cloned repo. They're the second batch of work.
- Oxygen is installed from `get.oxy.tech` latest. For reproducible installs, pin a version when the template is published.
- This bundle assumes Tailscale is required. There's a documented alternative (Basic Auth on `:3000` via nginx) but it's not implemented.

---

*Next plan: shellcheck pass + first real install on a fresh EC2.*
