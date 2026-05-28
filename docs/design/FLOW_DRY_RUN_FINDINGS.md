# FLOW_DRY_RUN_FINDINGS.md — flow-level dry-run findings (Plan 1)

Sibling to [`DRY_RUN_FINDINGS.md`](DRY_RUN_FINDINGS.md). That doc covered **script-level** findings from the v4 handoff — "what does this script do when its quiet assumptions break?" — across 11 iterations. This doc covers **flow-level** findings — "what does a user experience end-to-end, from cloning the repo through orient → say-go → install → honest-failure → next-step guidance?" — a lens that didn't exist when the scripts were dry-run-validated (the orient-before-executing path landed in Plan 46, after the v4 bundle).

These are **simulations** — Code reading the docs + scripts as a user would experience them — not actual EC2 installs. Plan 3 is the real install. Plan 1's flow dry-runs validate the flow before Plan 3 burns time on a foundation that wasn't ready.

**Tally (Plan 1, scenarios F1-F5): 5 scenarios, 7 findings (0 critical, 0 high, 4 medium, 3 low/cosmetic). 4 fixed in-plan, 1 mitigated, 2 documented-and-accepted (1 deferred to Plan 2 prep).**

**Tally (2026-05-28 follow-up, scenarios F6-F8): 3 scenarios, 9 findings (0 critical, 1 high, 5 medium, 3 low/cosmetic). 2 fixed in-plan, 7 surfaced as Plan-2-prep contract requirements or documented-and-accepted. The high (F6-1) is a hard interface contract Plan 2 must honor, not a current bug.**

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

## Meta-observation

The flow-level lens converged faster than the script-level lens did. The v4 handoff's script-level dry-runs needed 11 iterations to mine out the catastrophic + structural bugs (2 critical, 7 high). The flow-level pass found 0 critical, 0 high — the serious issues were all caught at the script level. What flow-level surfaced was exactly what the prompt predicted: cross-document inconsistency (F2, the bulk of the findings) and technically-correct-but-misleading-in-context failure modes (F1's die message). These are "the docs disagree with each other" and "the error blames the wrong thing" problems — real, worth fixing, but not the catastrophic class.

This is a useful signal for whether more flow dry-runs are worth doing: **probably not many more.** After fixing F2's cross-doc contradictions, a 6th scenario I tried to invent ("user runs `--only 09` to skip ahead to the smoke test") just re-finds F1 (dies at the missing `run.sh` precondition, honestly). The named 5 scenarios cover the meaningful flow surface. The next high-value validation is the real EC2 install (Plan 3), not more simulation.

**Size comparison:** this doc is ~1/3 the size of `DRY_RUN_FINDINGS.md`. That ratio is itself the finding — flow-level issues are far less numerous than script-level were, because (a) the scripts were already hardened, and (b) the flow has fewer moving parts than 13 scripts' worth of edge cases. Flow-level dry-runs are worth doing once per major doc/flow change, not iterated like script-level.

**2026-05-28 follow-up (F6-F8):** the Plan 1 meta-observation said "probably not many more [dry runs]" — and within the *same lens* (cross-doc consistency, orientation), that held. But F6-F8 deliberately opened **new lenses**, and each paid off: F6 (forward contract) was the highest-value pass of all eight because it converted the missing second batch into a precise interface spec and caught a real design-doc error (F6-3); F7 confirmed the lockout design is sound and labeled the one unreliable check; F8 confirmed the secrets posture. The lesson refines: *iterating the same lens* hits diminishing returns fast, but *a genuinely new lens* on the same artifacts can still surface a high-severity contract item. The remaining lenses worth a future pass are narrow (e.g., a v22.04 / x86 / undersized-instance "wrong environment" walk), and none should block — the next high-value validation is still the real EC2 install (Plan 3). F6's contract spec is the single most useful output for Plan 2.

---

*Flow dry-runs F1-F5 completed 2026-05-27 (Plan 1, Session 1). Follow-up F6-F8 completed 2026-05-28. All simulations, not EC2 installs. Plan 3 is the real install.*
