# FLOW_DRY_RUN_FINDINGS.md — flow-level dry-run findings (Plan 1)

Sibling to [`DRY_RUN_FINDINGS.md`](DRY_RUN_FINDINGS.md). That doc covered **script-level** findings from the v4 handoff — "what does this script do when its quiet assumptions break?" — across 11 iterations. This doc covers **flow-level** findings — "what does a user experience end-to-end, from cloning the repo through orient → say-go → install → honest-failure → next-step guidance?" — a lens that didn't exist when the scripts were dry-run-validated (the orient-before-executing path landed in Plan 46, after the v4 bundle).

These are **simulations** — Code reading the docs + scripts as a user would experience them — not actual EC2 installs. Plan 3 is the real install. Plan 1's flow dry-runs validate the flow before Plan 3 burns time on a foundation that wasn't ready.

**Tally (Plan 1, scenarios F1-F5): 5 scenarios, 7 findings (0 critical, 0 high, 4 medium, 3 low/cosmetic). 4 fixed in-plan, 1 mitigated, 2 documented-and-accepted (1 deferred to Plan 2 prep).**

**Tally (2026-05-28 follow-up, scenarios F6-F8): 3 scenarios, 9 findings (0 critical, 1 high, 5 medium, 3 low/cosmetic). 2 fixed in-plan, 7 surfaced as Plan-2-prep contract requirements or documented-and-accepted. The high (F6-1) is a hard interface contract Plan 2 must honor, not a current bug.**

**Tally (2026-05-28 batch 2, scenarios F9-F18): 10 scenarios, 11 findings (0 critical, 0 high, 5 medium, 6 low/cosmetic). 4 fixed in-plan (F11, F15, F16, F18), 4 deferred to Plan 2 prep (F10, F12, F14 + the F9 proxy gap), 3 documented-and-accepted. Four of the ten lenses (F9, F13, F16-base, F17) substantially *validated* existing behavior rather than finding defects — the diminishing-returns signal is now empirical: new lenses still pay off, but the yield-per-lens has dropped from ~3 findings (F6-F8) to ~1.1 (F9-F18), and zero critical/high. This is the point to stop simulating and start the real install (Plan 3).**

Severity vocabulary: Critical / High / Medium / Low / Cosmetic. Outcome vocabulary: Fixed in-plan / Mitigated / Deferred to Plan 2 / Documented and accepted.

---

## Scenario F1 — orient-then-go

**Walk:** User clones the repo, opens Claude Code. CLAUDE.md §1 fires. Claude orients (steps 1-8), including step 6 — the new "Current install state" caveat naming that the install dies at step 05. User says "go anyway, I want to see what happens." Claude runs `./scripts/setup/bootstrap.sh`. Steps 00-03 succeed (preflight, EC2 base packages, Docker, Oxygen CLI). Step 05 runs: clone no-ops (repo already present), API key prompt, `/etc/environment` write, PATH fix — then hits `if [[ ! -f "$PROJECT_ROOT/config.example.yml" ]]; then die`. Dies.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F1-1 | Step 05's die message reads `config.example.yml missing — was the repo cloned correctly?`. The "was the repo cloned correctly?" suffix blames the clone, but the real cause is that `config.example.yml` doesn't exist yet (it's in the second batch). Out of context, this misleads a user into debugging their clone. | Medium | **Mitigated** by the CLAUDE.md §1 "Current install state" caveat (C3) — an oriented user is told step 05 dies precisely here, and why. The message is *also correct* for the post-Plan-2 steady state (where a missing `config.example.yml` genuinely means a bad clone). Plan 2 makes this die path unreachable. Fixing the message pre-Plan-2 would mean adding temporal text to a message that's correct post-Plan-2 — the orientation caveat is the right home for the temporal context. |

**Verdict:** F1 passes. The install proceeds correctly through 00-03, dies honestly at 05, and an oriented user reads the failure as "expected at this stage" rather than "broken."

---

## Scenario F2 — skeptical user / cross-document consistency

**Walk:** User asks "what happens if I run this today?" Claude answers from CLAUDE.md §1 + design plan §9 + OPEN_DECISIONS.md. Are those documents internally consistent now that decisions are resolved? A `grep` sweep for stale "open decisions" / "out of scope" / "CHANGE-ME" / "NOT YET RESOLVED" framing.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F2-a | `STACK_IN_A_BOX_PLAN.md` §5 was titled "Decisions That Need User's Call" and framed all 5 as open — directly contradicting `OPEN_DECISIONS.md` (all resolved). | Medium | **Fixed in-plan** — §5 retitled "...(RESOLVED 2026-05-27)" with a pointer note to `OPEN_DECISIONS.md`; the design-time framing preserved below the note as a record. |
| F2-b | `README.md` "Working placeholder name" callout said the repo name "is one of five open design decisions" and "a future plan resolves the name" — stale after decision #5 (name stays). | Medium | **Fixed in-plan** — callout rewritten to "Repo name … resolved 2026-05-27 (decision #5)." |
| F2-c | `README.md` + `CLAUDE.md` doc-tour lines described `docs/design/` as holding "the 5 open decisions." | Cosmetic | **Fixed in-plan** — both reworded to "the 5 design decisions (resolved)." |
| F2-d | `grep -rn "CHANGE-ME"` and `grep -rn "NOT YET RESOLVED"` return only the prompt file's verbatim *description of the verification gates* (line quoting the strings), not live placeholders. | Cosmetic | **Documented and accepted** — the gate's intent (no live placeholder, no unresolved status) is satisfied; the self-referential match in the prompt file is correct. |

**Verdict:** F2 surfaced the most findings — exactly as the prompt anticipated ("flow-level findings are likely to be about cross-document inconsistency"). All cross-doc contradictions fixed. After fixes, the three documents a skeptical user would cross-read (CLAUDE.md §1, PLAN.md, OPEN_DECISIONS.md) tell one consistent story: decisions resolved, install completes 00-03 then dies at 05, second batch is the gate to first install.

---

## Scenario F3 — "what about decision X"

**Walk:** User asks "is Tailscale required?" → Claude reads OPEN_DECISIONS.md #1 → "Required (resolved)." Consistent with scripts 06 + 07, which assume required and have no optional-path code. User asks "what smoke source?" → OPEN_DECISIONS.md #2 → "NYC 311 (SODA `erm2-nwe9`), resolved." Consistent with `00_preflight.sh`, which checks `data.cityofnewyork.us` reachability.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| _(none)_ | Decisions are definite and consistent with what the scripts actually do. The preflight's `data.cityofnewyork.us` network check is the one place a decision (#2 smoke source) is already wired into the existing scripts, and it matches. | — | — |

**Verdict:** F3 passes clean. Decisions resolve to definite answers that don't contradict the scripts.

---

## Scenario F4 — wait-for-Plan-2

**Walk:** User reads the orientation, decides to wait for a complete install rather than run the partial. Does Claude provide graceful next-step guidance?

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F4-a | There's no single "what to watch for" pointer tying the wait-guidance together — the user infers from CLAUDE.md §1 ("wait for Plan 2") + LOG.md Next-Plan-Candidates + design plan §9. Adequate but not one-stop. | Low | **Documented and accepted** — CLAUDE.md §1's caveat names Plan 2 explicitly as the gate, and LOG.md's Next-Plan-Candidates section names Plan 2 with its scope. The trail is followable; a dedicated "watch-for" doc would be over-engineering for a pre-install repo. |

**Verdict:** F4 passes. The orientation + LOG Next-Plan-Candidates give a waiting user a clear picture of what Plan 2 delivers and that it's the gate to a real install.

---

## Scenario F5 — rerun after fix (checkpoint resume)

**Walk:** User runs `bootstrap.sh`, it dies at step 05 (checkpoints written for 00-03, NOT for 05 since it died). User waits for Plan 2, does `git pull` to get the new artifacts (`config.example.yml`, `requirements.txt`, `run.sh`, etc.), reruns `bootstrap.sh`. Does resume work?

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F5-a | Checkpoints live in `$PROJECT_ROOT/scratch/checkpoints/`, and `scratch/` is gitignored — so `git pull` (Plan 2 artifacts) doesn't disturb them. On rerun, steps 00-03 skip (still-valid infra installs), step 05 retries with the now-present `config.example.yml`, then 04, 06-10 proceed. Correct resume behavior. | — | **Validated** (not a bug) — the checkpoint-survives-pull behavior is correct and saves the user from re-installing Ubuntu base/Docker/Oxygen. |
| F5-b | If Plan 2 (or any future plan) modifies one of scripts 00-03 themselves — e.g., adds a package to `01`'s `BASE_PACKAGES` — a rerun-after-partial-install user would skip the updated script (checkpointed) and silently miss the change. The `--force` flag is the documented escape hatch, but the user wouldn't know to use it. | Low | **Deferred to Plan 2 prep** — Plan 2 is application content (new files), unlikely to touch 00-03. But Plan 2's housekeeping should note: "if this plan modifies scripts 00-03, partial-install users must `bootstrap.sh --force` or clear `scratch/checkpoints/`." Added to Plan 2's inherited prep via this finding. |

**Verdict:** F5 passes. Checkpoint resume works correctly across a Plan-2 pull. The one edge case (Plan 2 touching scripts 00-03) is flagged for Plan 2's prep rather than fixed here, since it's contingent on Plan 2's content.

---

# 2026-05-28 follow-up — three more dry runs (F6-F8)

Three additional flow-level passes, each a lens the Plan 1 set (F1-F5) didn't cover. F6 is a *forward* dry-run — simulating the install **after** the second batch ships — to surface interface-contract requirements before Plan 2 builds the 16 artifacts. F7 traces the one irreversible-mistake surface (the AWS Security Group transition). F8 traces the secrets lifecycle end-to-end. Still simulations, not EC2 installs.

## Scenario F6 — post-Plan-2 forward contract check

**Walk:** Assume Plan 2 has shipped the 16 second-batch artifacts. Trace the install end-to-end *on paper* and ask: do the v4 scripts and the (not-yet-built) artifacts agree on their interfaces? The scripts hard-code names and paths that the second-batch content must produce exactly, or the verify gates fail. Traced via `grep` across `scripts/setup/` for the load-bearing contract values.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F6-1 | **Hard table-name contract.** `09_first_run.sh` (lines 151, 169) and `10_verify.sh` (lines 46-47) verify exactly `main_gold.fct_smoke_test` and `main_admin.fct_pipeline_run_raw`. Plan 2's dbt gold model **must** be named `fct_smoke_test` in schema `main_gold`, and the admin pipeline-run table **must** be `fct_pipeline_run_raw` in `main_admin`. If Plan 2 names the gold model after the dataset (e.g. `fct_nyc_311`), the smoke-test verify gate fails even though the install worked. | High | **Deferred to Plan 2 prep** — not a current bug; it's a contract requirement. Plan 2 must honor these exact names (or update 09 + 10 in lockstep). Documented here as the canonical interface. |
| F6-2 | **DuckDB path is consistent** across 05 (`DUCKDB_PATH="$PROJECT_ROOT/data/stack.duckdb"`), 09, and 10 — all three agree. Plan 2's `run.sh`, `config.yml` (via `{{DUCKDB_PATH}}`), and `dbt/profiles.example.yml` (via `{{DUCKDB_PATH}}`) must all resolve to `data/stack.duckdb`. The token wiring in 05 already enforces this for config + profiles. | — | **Validated** — no action; the path contract is internally consistent. |
| F6-3 | **Token-convention claim in design plan §4 was wrong.** §4 listed `{{PROJECT_NAME}}`, `{{PROJECT_ROOT}}`, `{{NGINX_DOCROOT}}`, `{{TAILNET_HOSTNAME}}` as sed-substituted. Reality: scripts substitute `{{PROJECT_NAME}}` + `{{DUCKDB_PATH}}` (05) + `{{PROJECT_ROOT}}` (08) — three tokens, and `{{DUCKDB_PATH}}` wasn't even in §4's list. `{{NGINX_DOCROOT}}` is hardcoded in 07 (the nginx conf is copied verbatim, no substitution); `{{TAILNET_HOSTNAME}}` is derived at runtime into `scratch/tailnet_identity.env`, never substituted into a file. A Plan 2 author trusting §4 might ship `nginx/stack-in-a-box.conf` with a `{{NGINX_DOCROOT}}` token expecting substitution — it would deploy unsubstituted and nginx would fail. | Medium | **Fixed in-plan** — `STACK_IN_A_BOX_PLAN.md` §4 rewritten to name the 3 real tokens, mark the docroot as hardcoded-literal, and warn Plan 2 off the 2 phantom tokens. |
| F6-4 | **run.sh stage contract.** `09_first_run.sh` invokes `run.sh manual` and expects it to (a) populate `fct_pipeline_run_raw` + `fct_smoke_test`, (b) deploy portal pages to the docroot. `10_verify.sh` then checks routes `/`, `/docs/`, `/metrics`, `/trust`, `/profile`, `/erd` + `:3000`. So Plan 2's `run.sh` must generate-and-deploy all five portal pages **to `/var/www/stack-in-a-box/`** (not `$PROJECT_ROOT/portal/`) — which matches the cross-batch flag already recorded in the v4 handoff §10 item 1. | Medium | **Deferred to Plan 2 prep** — consistent with handoff §10; re-confirmed here as a verify-gate-enforced contract. |
| F6-5 | **`config.example.yml` token surface.** Script 05 runs `sed -e "s\|{{PROJECT_NAME}}\|...\|g" -e "s\|{{DUCKDB_PATH}}\|...\|g"` then verify-gates on `grep -q '{{'` (dies if any token remains). So Plan 2's `config.example.yml` may **only** use `{{PROJECT_NAME}}` and `{{DUCKDB_PATH}}` — any other `{{TOKEN}}` trips the "unsubstituted tokens" die in 05's verify gate. Same constraint on `dbt/profiles.example.yml`. | Medium | **Deferred to Plan 2 prep** — documented token whitelist for the two templated config files. |

**Verdict:** F6 is the highest-value of the three. It converts "the second batch is missing" from a vague gap into a precise interface spec: exact table names, exact DuckDB path, exact token whitelist, exact docroot, exact run.sh outputs. Plan 2 now has a contract to build against, and one real design-doc error (F6-3) is fixed.

## Scenario F7 — AWS Security Group lockout / network-transition sequence

**Walk:** The scariest real-world step. Trace step 06 → manual SG edit on the user's laptop → resume → step 10's SG verification. Where can a user lock themselves out, and does the design prevent it?

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F7-1 | **Lockout-prevention ordering is correct.** `06`'s printed instructions (lines 118-136) put "VERIFY Tailnet SSH works" *first* with an explicit "If that fails — STOP. Do not close the AWS SG until it works," then the SG-close steps second, keeping HTTP/80. Following the instructions in order cannot lock the user out. | — | **Validated** — the ordered instructions are the right design. |
| F7-2 | **The script cannot enforce the ordering** — the SG edit happens on the user's laptop via the AWS Console, outside the script's reach. A user who closes the SG *before* verifying Tailnet SSH, and whose Tailnet SSH then doesn't work, is locked out (only port 80 remains, which is no shell). This is inherent: the script deliberately does NOT touch the SG itself (touching it programmatically is the bigger lockout risk). | Medium | **Documented and accepted** — the printed warning is the mitigation. Inherent to the "user owns the irreversible step" design. A future enhancement could have the script poll "can you still SSH in?" after a timeout, but that adds complexity for marginal gain. |
| F7-3 | **Step 10's SG self-check is best-effort, not authoritative.** `10_verify.sh` (when IMDSv2 yields the public IP) does `timeout 5 bash -c "</dev/tcp/$public_ip/22"` — connecting to the instance's *own* public IP from *inside* the instance. AWS may hairpin this, so the result doesn't reliably reflect the external view: a port could read "closed" here yet be open to the world (or vice versa). The authoritative check is from the user's laptop. | Medium | **Fixed in-plan** — added a comment + a "(best-effort, from inside the instance)" log qualifier to `10_verify.sh`, and the existing manual-verify fallback + browser step (which the laptop exercises) covers the gap. |
| F7-4 | **Resume after the pause works both ways.** `bootstrap.sh` exits 0 after step 06 with the PAUSED banner. The user can resume via `--from 07` *or* a bare rerun (00-06 are checkpointed and skip, landing on 07). Both reach 07 correctly. | — | **Validated** — no single-path fragility. |

**Verdict:** F7 passes. The one residual risk (F7-2, user closes SG out of order) is inherent and correctly mitigated by ordered instructions; the unreliable self-check (F7-3) is now honestly labeled best-effort.

## Scenario F8 — secrets lifecycle end-to-end

**Walk:** Three secrets flow through the install — Anthropic API key (05), Tailscale auth key (06), SSH keypair (pre-existing, user-managed). Trace each: entry → validation → storage → leak surface → bad/expired/malformed-key behavior.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F8-1 | **Both prompted keys are read without echo and validated.** `read_secret` (lib/common.sh) uses `read -rs` (no echo), rejects empty + whitespace-containing values, and enforces a prefix (`sk-ant-` / `tskey-auth-`) with up to 3 retries. A pasted-with-trailing-space key is caught at entry, not 15 minutes later. | — | **Validated** — solid entry-time validation. |
| F8-2 | **`/etc/environment` write avoids argv exposure.** `write_env_var` (05) filters with `grep -v` to a user-owned `mktemp` then `install`s it, rather than `sed -i "s/.../$secret/"` — so the key value never appears in a process's argv (`ps auxww`). The SC2024 shellcheck disable on that line is justified (Plan 1). | — | **Validated** — the argv-leak fix from v4 iter-9 holds. |
| F8-3 | **Env-var override path puts the key in the process environment.** For non-interactive installs, `ANTHROPIC_API_KEY` / `TAILSCALE_AUTHKEY` are read from the environment (`${!env_override}`), which means the key is in the install process's environment and inherited by child processes (Docker installer, Oxygen installer) and readable via `/proc/self/environ` to the same user during the run. | Low | **Documented and accepted** — single-user EC2; this is the standard CI trade-off and the documented non-interactive path. The interactive path (no env var) avoids it. |
| F8-4 | **`09_first_run.sh` logs the first 14 chars of the API key** (`head -c 14` → `sk-ant-api03-X`) as a "key present" confirmation, and `chmod 600`s the run log. 14 chars is the public-ish key prefix, not the secret body. | Low | **Documented and accepted** — prefix-only disclosure to a 600 log; not a meaningful exposure. |
| F8-5 | **Tailscale auth key is single-use + expiring by design** (the instructions tell the user to generate a single-use key). A reused/expired key fails at `tailscale up` with a clear die, and the user generates a fresh one — no silent half-join. The key is passed to `sudo tailscale up --authkey="$KEY"` which *does* put it in argv briefly (visible to root-capable `ps` during the call). | Low | **Documented and accepted** — single-use + short-lived key; the argv window is seconds and the key is spent on use. Tailscale's CLI offers no stdin-key alternative, so this is the standard invocation. |
| F8-6 | **SSH keypair never touches the instance.** The `.pem` stays on the user's laptop (pre-install contract); the install never reads, copies, or references private key material. | — | **Validated** — correct posture; no private-key handling on the box. |

**Verdict:** F8 passes. The secrets posture is sound — no-echo entry, prefix validation, argv-safe `/etc/environment` write, no private-key-on-box. The residual exposures (F8-3 env-var inheritance, F8-5 Tailscale argv window) are inherent to the respective tools' interfaces and acceptable on single-user EC2; both are documented rather than papered over.

---

# 2026-05-28 batch 2 — ten more dry runs (F9-F18)

Ten further passes, each a lens not used in F1-F8. Honest framing up front: the yield dropped sharply. F6-F8 averaged ~3 findings each (one high); F9-F18 averaged ~1.1, none critical or high, and four lenses mostly *validated* existing behavior. The new-lens principle still held (every lens found *something* or confirmed *something* worth recording), but the curve has clearly flattened. Recorded in full anyway — including the "no defect found" results, because a validated lens is a real result.

## Scenario F9 — wrong-environment matrix

**Walk:** Run `00_preflight.sh` (and step 01) against the off-happy-path environments: Ubuntu 22.04, x86_64, t4g.small (2 GB RAM, below the 3500 MB floor), a 8 GB root volume (below the 10 GB floor), running as root, and behind a corporate HTTP proxy.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F9-a | 22.04 → `log_warn` "supported but 24.04 preferred", proceeds. x86_64 → `log_ok` (both arches accepted). RAM < 3500 MB → hard fail with the MB count. Disk < 10 GB → hard fail with the GB count. Root → hard fail "do not run as root". Each gives an actionable message and the right pass/warn/fail disposition. | — | **Validated** — preflight handles the wrong-environment matrix correctly; no defect. |
| F9-b | **Corporate-proxy / egress-filtered network** is the one gap. The 6 network-reachability probes use plain `curl -sI` with no proxy awareness. Behind a proxy that requires `https_proxy`, all 6 read `000` and preflight hard-fails with "unreachable" — technically correct (the box genuinely can't reach them directly) but the message doesn't hint "are you behind a proxy?". A user on a filtered VPC would see 6 failures and not know why. | Low | **Deferred to Plan 2 prep** — add a one-line "if you're behind an HTTP proxy, export https_proxy before running" hint to the preflight failure path. Not fixed now: it's a message tweak in a script Plan 2 may otherwise touch, and the failure is at least loud + correct today. |

**Verdict:** F9 mostly validates. Preflight is well-built for the common wrong-env cases; the proxy hint is the only gap, and it's cosmetic.

## Scenario F10 — second batch shipped but subtly wrong

**Walk:** Complement to F6. F6 asked "what contract must Plan 2 honor?" F10 asks "if Plan 2 honors the names/paths but makes *plausible* mistakes, does the install degrade honestly or fail silently?" Traced each plausible Plan-2 error against the existing verify gates.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F10-a | **Wrong dlt/dbt version in requirements.txt** → `04`'s verify gate runs `dlt --version` + `dbt --version` + the `python-ulid` import/construct check, so a version whose CLI/API changed is caught at step 04, not 15 minutes later. Covered. | — | **Validated** — the 04 verify gate is the guard. |
| F10-b | **Smoke pull returns 0 rows** (NYC 311 API empty/filtered) → `09`'s `gold_count > 0` check fails → install reports failure honestly. **dbt test fails on smoke data** → captured-exit contract: run.sh completes, records the DQ failure, install "succeeds" with a trust-page caveat (the designed visible-failure behavior). Both degrade honestly. | — | **Validated** — data-shape failures surface, they don't hide. |
| F10-c | **Malformed `agent.yml` / `view.yml` / `topic.yml`** is the real gap: **no setup script validates the semantic layer or agent config.** `09` runs `run.sh` (which builds the warehouse) and checks tables/rows, but nothing runs `oxy validate`. A syntactically broken agent or view passes every automated gate and only surfaces at `10`'s *manual browser* step ("ask the chat a question"). A user could see "10 — all curl-able checks passed" and a green install, then find the chat agent errors on first query. | Medium | **Deferred to Plan 2 prep** — Plan 2's `run.sh` (or a new pre-smoke step) should run `oxy validate` and fail loud on a bad semantic/agent config, so the automated gates cover config validity, not just data + routes + services. |

**Verdict:** the verify gates cover data, routes, and services well; the blind spot is semantic-layer/agent-config *validity*, which currently only the manual browser step catches. One real deferred finding (F10-c).

## Scenario F11 — network degradation / partial connectivity

**Walk:** Not "no network" (preflight catches that) but degraded: slow-but-up `get.oxy.tech`, `apt` mirror flaking, IMDS disabled on a hardened AMI, Tailscale control-plane reachable but DERP relay blocked.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F11-a | **`03`'s Oxygen-installer fetch had no timeout** — `bash <(curl ... -LsSf "$OXY_INSTALLER_URL")` would hang indefinitely against a slow-but-reachable endpoint, with no way for the user to tell "hung" from "working." | Medium | **Fixed in-plan** — added `--connect-timeout 10 --max-time 120` to the installer curl; the die message now names a timeout/reachability cause. |
| F11-b | Flaky apt → `set -e` halts step 01; idempotent re-run recovers. IMDS disabled → step 10's SG check already falls to the loud manual-verify warning (F7-3). Tailscale DERP blocked → `tailscale up` succeeds on the control plane and the verify checks backend-Running + Tailnet-IP (not end-to-end reachability, which is client-side anyway, consistent with F7). | — | **Validated** — the other degradation modes already degrade acceptably. |

**Verdict:** one real fix (the installer timeout); the rest of the degradation surface was already handled.

## Scenario F12 — concurrency / timer collision

**Walk:** Two interacting concurrency surfaces: (a) two SSH sessions both run `bootstrap.sh`; (b) a systemd timer fires during the step-09 manual smoke test, putting two `run.sh` processes against one DuckDB file.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F12-a | **Double bootstrap** → `bootstrap.sh`'s `flock -n` on `/tmp/stack-in-a-box-bootstrap.lock` rejects the second invocation with a clear message. Covered. | — | **Validated** — the flock guard works. |
| F12-b | **Timer-vs-manual collision.** Step 08 enables `pipeline-refresh.timer` (daily) + `source-health-check.timer` (hourly) + `profile-tables.timer` (weekly) *before* the step-09 smoke test runs. The hourly source-health timer can plausibly fire during a 15-25 min smoke test → two processes writing the DuckDB file → single-writer lock contention. (Today this is inert: the timers' ExecStart points at `run.sh`/helpers that don't exist until Plan 2, so they fail harmlessly. Post-Plan-2 the window is real.) Compounds with the v4 handoff §10 item 2 (run.sh needs orphaned-run cleanup for killed pipelines). | Medium | **Deferred to Plan 2 prep** — Plan 2's `run.sh` needs (1) a DuckDB-lock-aware retry/skip when another run holds the file, and (2) the orphaned-run cleanup already noted in handoff §10. Optionally, step 08 could enable timers *after* the first smoke run rather than before. |

**Verdict:** bootstrap concurrency is guarded; the timer-vs-manual window is a real post-Plan-2 contract item, consistent with handoff §10.

## Scenario F13 — reboot / stop-start / public-IP change

**Walk:** A reboot at each stage; an EC2 stop-start (which changes the public IPv4 unless an Elastic IP is attached).

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F13-a | **Reboot mid-install** → step 01 already handles the kernel-update reboot via `exit 100` + bootstrap's resume. A reboot at any other stage: checkpoints live in `scratch/checkpoints/` (survive reboot), services are `enable`d (come back), user reconnects and reruns bootstrap (skips checkpointed steps). Resilient. | — | **Validated** — reboot resilience is built in. |
| F13-b | **Stop-start changes the public IP** — and nothing in the install hardcodes the public IP into any persistent config. The portal binds `0.0.0.0:80` (reachable on whatever the current IP is); Tailnet access uses the stable Tailnet hostname/IP (written to `scratch/tailnet_identity.env`); step 10's SG check re-derives the *current* public IP from IMDS each run. So a public-IP change breaks nothing. This is a genuinely good property worth recording. | — | **Validated** — the install is correctly resilient to public-IP churn because it never pins the public IP. |

**Verdict:** F13 fully validates. Both reboot and IP-change resilience are real and correct. Zero findings — recorded because "we checked and it's robust" is the result.

## Scenario F14 — teardown / re-install from scratch

**Walk:** A user wants to start over. There is no uninstall script (v4 handoff §11 lists it as out of scope). Trace what persists and whether a re-install collides with stale state.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F14-a | **No teardown story, and a `rm -rf repo && re-clone` leaves all system-level state**: `/etc/environment` (API key + OXY_DATABASE_URL + PATH edits), `/etc/systemd/system/*` units, the Docker engine + the oxy postgres container, the Tailscale node registration, the `/etc/nginx/sites-*` config, `/var/www/stack-in-a-box/`. A naive re-clone wipes only the repo (and its `scratch/checkpoints/`, forcing a full re-run from 00). | Low | **Deferred to Plan 2 prep** — a `TEARDOWN.md` checklist (or a `make teardown` / uninstall script) belongs with the HARDENING.md/SWAP_IN_YOUR_DATA.md doc batch in Plan 2. Not urgent (re-install is mostly idempotent), but the absence should be documented rather than discovered. |
| F14-b | **Re-install on top is mostly idempotent** — `05` detects the existing `/etc/environment` key and *prompts to replace* (doesn't silently clobber); `07`/`08` re-deploy nginx + units idempotently. The one rough edge: re-running `06` with a *new* single-use Tailscale key when the node already exists may register a duplicate Tailnet node (cosmetic; the old node goes stale). | Cosmetic | **Documented and accepted** — duplicate-node is a Tailscale-admin cleanup, not an install bug. |

**Verdict:** re-install is safer than expected (idempotent, prompts before clobbering the key); the gap is the *absence of a documented teardown*, deferred to Plan 2's doc batch.

## Scenario F15 — docs read in natural order

**Walk:** Read the docs in the order a new user hits them — README → CLAUDE.md → design plan / OPEN_DECISIONS — and check for internal contradictions now that Plan 1 + F6-F8 have edited several of them.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F15-a | README's `scripts/setup/` table row said "Dry-run-validated (11 iterations)" while the Status section said "11 script-level iterations + flow-level dry-runs." After F6-F8 + F9-F18, "(11 iterations)" undercounts (it's now 11 script + 18 flow). Minor internal inconsistency, and an undersell. | Cosmetic | **Fixed in-plan** — README table row reworded to "dry-run-validated at script + flow level and shellcheck-clean" (no brittle count). |
| F15-b | The rest of the reading path coheres: README §Status, CLAUDE.md §1 caveat, design plan §8 ("required follow-up work"), and OPEN_DECISIONS (all RESOLVED) agree that the second batch is the gate to first install and that decisions are settled. The repo-name note (README line 7, decision #5) is consistent. No forward-reference-to-unexplained-thing problems. | — | **Validated** — cross-doc narrative is consistent. |

**Verdict:** one cosmetic count-staleness fix; the rest of the doc narrative holds together.

## Scenario F16 — orientation quality (what Claude would actually say)

**Walk:** Not "does Claude orient" (F1) but "is the orientation CLAUDE.md §1 produces accurate and well-calibrated?" Simulated the literal orientation and graded it for over/under-claiming.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F16-a | Orientation step 5 stated "Wall clock: 35-60 minutes on a fresh EC2 instance" with no qualifier, then step 6 + the callout correctly say the install dies at step 05 today (~5 min). A Claude reciting both could lead with a 35-60 min figure that's currently false before the step-6 correction lands. | Low | **Fixed in-plan** — step 5 now reads "35-60 minutes ... *once the platform is complete* (see step 6 for what actually runs today)" + an explicit "do not present the 35-60 minute figure as today's reality." |
| F16-b | The rest of §1 is well-calibrated: the discipline summary (step 4) is accurate, the Current install state callout is honest and even hands the user the literal die message, and the "let them make an informed choice" framing is right. | — | **Validated** — the orientation is honest once F16-a is fixed. |

**Verdict:** one calibration fix to prevent a transient over-claim; otherwise the orientation is sound.

## Scenario F17 — cost / resource consumption

**Walk:** What does running this actually cost, and is the user informed / protected from runaway cost?

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F17-a | Install-time cost is trivial: t4g.medium (~$0.034/hr), the NYC 311 SODA pull is free, the single first-query Anthropic spend is cents. Ongoing: the instance left running is ~$24/mo; the daily `pipeline-refresh` timer accrues compute only (free API). **No runaway-cost risk** — no timer calls the paid LLM, and the smoke source is free. The one un-stated cost is "you left a t4g.medium running 24/7," which is the user's own provisioning decision. | Low | **Documented and accepted** — a one-line cost note could go in README/HARDENING in Plan 2's doc batch, but there's no runaway risk and the user owns the EC2 lifecycle. Thin lens. |

**Verdict:** validated — no runaway-cost surface. The lens was worth one pass to confirm the daily timer doesn't quietly burn LLM spend (it doesn't).

## Scenario F18 — careless / malicious input

**Walk:** Adversarial / clumsy inputs: wrong key type, key with trailing whitespace, `PROJECT_NAME` with shell/sed metacharacters, `SMOKE_MODE=large` on an undersized box, a typosquatted `TEMPLATE_REPO_URL`.

| # | Finding | Severity | Outcome |
|---|---|---|---|
| F18-a | **`PROJECT_NAME` with sed-delimiter chars** (`\|`, `&`, `\`) would silently mangle `config.yml` + `dbt/profiles.yml`, because `05` interpolates it into `sed s\|...\|$PROJECT_NAME\|`. Default (`stack-in-a-box`) is safe; the risk is a `PROJECT_NAME=...` override. | Medium | **Fixed in-plan** — `05` now rejects a `PROJECT_NAME` containing `\| & \\` up front with a clear die, before any substitution. |
| F18-b | Wrong key type / trailing whitespace → `read_secret` rejects at entry (prefix check + whitespace check), already validated in F8. `SMOKE_MODE=large` on a 2 GB box → a run.sh/dlt concern (Plan 2), not a setup-script gap; the smoke modes are documented. Typosquatted `TEMPLATE_REPO_URL` → the user supplies it; the documented flow is clone-first (so the override rarely fires), and the `curl|bash` deny-list + the HTTPS-only Oxygen/Docker/Tailscale installers bound the blast radius. | — | **Validated / documented** — entry validation covers the key cases; the repo-URL trust is the user's (clone-first flow makes it largely moot). |

**Verdict:** one real fix (the `PROJECT_NAME` sed-injection guard); the rest of the input surface was already validated at entry.

---

## Meta-observation

The flow-level lens converged faster than the script-level lens did. The v4 handoff's script-level dry-runs needed 11 iterations to mine out the catastrophic + structural bugs (2 critical, 7 high). The flow-level pass found 0 critical, 0 high — the serious issues were all caught at the script level. What flow-level surfaced was exactly what the prompt predicted: cross-document inconsistency (F2, the bulk of the findings) and technically-correct-but-misleading-in-context failure modes (F1's die message). These are "the docs disagree with each other" and "the error blames the wrong thing" problems — real, worth fixing, but not the catastrophic class.

This is a useful signal for whether more flow dry-runs are worth doing: **probably not many more.** After fixing F2's cross-doc contradictions, a 6th scenario I tried to invent ("user runs `--only 09` to skip ahead to the smoke test") just re-finds F1 (dies at the missing `run.sh` precondition, honestly). The named 5 scenarios cover the meaningful flow surface. The next high-value validation is the real EC2 install (Plan 3), not more simulation.

**Size comparison:** this doc is ~1/3 the size of `DRY_RUN_FINDINGS.md`. That ratio is itself the finding — flow-level issues are far less numerous than script-level were, because (a) the scripts were already hardened, and (b) the flow has fewer moving parts than 13 scripts' worth of edge cases. Flow-level dry-runs are worth doing once per major doc/flow change, not iterated like script-level.

**2026-05-28 follow-up (F6-F8):** the Plan 1 meta-observation said "probably not many more [dry runs]" — and within the *same lens* (cross-doc consistency, orientation), that held. But F6-F8 deliberately opened **new lenses**, and each paid off: F6 (forward contract) was the highest-value pass of all eight because it converted the missing second batch into a precise interface spec and caught a real design-doc error (F6-3); F7 confirmed the lockout design is sound and labeled the one unreliable check; F8 confirmed the secrets posture. The lesson refines: *iterating the same lens* hits diminishing returns fast, but *a genuinely new lens* on the same artifacts can still surface a high-severity contract item. F6's contract spec is the single most useful output for Plan 2.

**2026-05-28 batch 2 (F9-F18) — the curve flattened, empirically.** Ten more *new* lenses. The new-lens principle held in the weak sense (every lens recorded something), but the yield collapsed: ~1.1 findings/lens vs F6-F8's ~3, **zero critical or high**, four lenses (F9, F13, F16-base, F17) mostly *validated* existing behavior rather than finding defects. The findings that did land are a tier lower in severity — a missing curl timeout (F11, fixed), a sed-injection guard (F18, fixed), two doc/orientation calibrations (F15, F16, fixed), and three Plan-2-prep deferrals (F10-c `oxy validate` gate, F12-b timer-vs-manual collision, F14-a teardown doc). **This is the stop signal.** Across all 29 dry runs (11 script + 18 flow), the last 10 produced no critical/high and four pure validations. Continuing to simulate is now lower-value than the real EC2 install. **Recommendation: stop dry-running; the next move is Plan 2 (build the second batch against F6's contract), then Plan 3 (first real install).** A real install will find the class of bug no amount of reading can — external-service behavior, real timing, API-under-load — which is exactly the residue F9-F18 kept gesturing at ("this is a Plan 2 / run.sh concern") without being able to test.

---

*Flow dry-runs F1-F5 completed 2026-05-27 (Plan 1, Session 1). Follow-ups F6-F8 and F9-F18 completed 2026-05-28. All simulations, not EC2 installs. Plan 3 is the real install — and per the F9-F18 stop signal, the next high-value validation step.*
