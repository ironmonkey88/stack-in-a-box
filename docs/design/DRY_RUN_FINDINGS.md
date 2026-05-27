# DRY_RUN_FINDINGS.md — 11 iterations of simulated execution

11 passes through the bundle. Each simulated a different scenario; each fixed what it found before the next.

**Final tally: 79 issues surfaced across 11 iterations. 33 real, fixed. 46 cancelled after deeper inspection or judged not-a-bug.**

Bundle growth:
- v1: 19,617 bytes (after iters 1-5)
- v2: 21,852 bytes
- v3: 26,272 bytes (after iters 6-8)
- **v4: 28,026 bytes (after iters 9-11, current)**

---

## Iteration themes at a glance

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

---

## Highlights from iters 1-8 (previously documented)

- **Iter 1 critical:** `PROJECT_ROOT` was hardcoded to `/home/ubuntu/stack-in-a-box`, breaking the install on non-default paths. Fixed with auto-derivation from script location.
- **Iter 5 critical:** `curl -fsS` failed preflight on every install because API gateways and download endpoints return 4xx to bare-domain requests. Fixed by treating any HTTP response as "reachable."
- **Iter 7 medium x3:** flock on bootstrap.sh, cloud-init wait, sudo timeout — all real cloud quirks.

---

## Iteration 9 — Security boundary review

**Scenario:** Read the bundle as an attacker. Secret leakage paths, MITM risks, public-port exposure, integrity verification.

| # | Bug | Severity | Outcome |
|---|---|---|---|
| 58 | `sed -i` exposes API key in argv to `ps auxww` momentarily | Low | **FIXED** — use grep-v + tee pattern, value never in argv |
| 60 | `/etc/environment` is 644 (world-readable) | Cosmetic | Documented single-user assumption |
| 61 | `curl \| bash` installs have no integrity verification | Medium | **FIXED** — added trust-assumption comments + pointers to apt-repo alternatives |
| 63 | Operator could later `tailscale set --ssh=true` post-install | Cross-batch | Flagged for source-health-check (next batch) |
| 64 | AWS SG public-port check was optional; user could end up internet-exposed | **High** | **FIXED** — auto-detect public IP via IMDSv2, fail loud if open |

**Theme: Defense-in-depth.** Two real fixes (argv leak, mandatory SG check) and several documented assumptions. The mandatory SG check is the most consequential — installs no longer silently complete with public ports open.

---

## Iteration 10 — User impatience and SSH fragility

**Scenario:** What if the user is impatient, makes typos under pressure, has aggressive SSH timeouts? The 8-25 minute smoke test is long enough for many things to go wrong.

| # | Bug | Severity | Outcome |
|---|---|---|---|
| 66 | run.sh has no orphaned-run cleanup (in-progress rows from killed pipelines) | Cross-batch | Flagged for next batch |
| 67 | Smoke test dies with SSH disconnect; user loses 15 min on retry | **High** | **FIXED** — wrap with `setsid` to detach |
| 68 | API key with embedded whitespace passes prefix check, fails 15 min later | Medium | **FIXED** — validate "no whitespace" at paste time |
| 69 | Cloud-init wait may confuse impatient users into Ctrl-C | Low | **FIXED** — explanatory log line |
| 70 | No uninstall script for cleaning up the box | Cross-batch | Noted for product roadmap |
| 71 | logs/run.sh.log is world-readable; could leak key if accidentally logged | Low | **FIXED** — chmod 600 after run |

**Theme: A 15-25 minute install is long enough for things to break.** Defensive wrapping (setsid, chmod 600, paste validation) prevents 5-15 minute "wait what?" debug sessions.

---

## Iteration 11 — Subtle wrong-but-runs

**Scenario:** Stop asking "can it run?" Ask "what does it get subtly wrong even when it runs?"

| # | Bug | Severity | Outcome |
|---|---|---|---|
| 72 | Re-running venv install accumulates removed-from-requirements packages | Low | Documented; FORCE=1 is the clean-slate path |
| 73 | Unit-file template substitution only handles {{PROJECT_ROOT}} | Cosmetic | Defensive `grep '{{'` catches future tokens |
| 74 | nginx docroot hardcoded; multi-instance impossible | Cosmetic | Documented assumption: one box per host |
| 75 | Portal is public on port 80 | Documented | Deployment posture, not a bug |
| 76 | Env-var override path skipped whitespace check (inconsistent with interactive) | Low | **FIXED** — added whitespace reject to env path |
| 77 | README CI section glossed over the manual SG pause | Medium | **FIXED** — clarified two-phase CI flow |

**Theme: Looking for the *opposite* class of bug.** This pass deliberately looked for things the install gets *wrong* in correct-ish ways, vs. things that fail outright.

---

## The bug discovery curve, updated

```
Iter:   1   2   3   4   5   6   7   8   9   10  11
Critical: ●   ·   ·   ·   ●   ·   ·   ·   ·   ·   ·
High:   ●●  ●   ●   ●   ·   ●   ·   ●   ●   ●   ·
Medium: ●   ●●  ●   ·   ●   ·   ●●● ●●  ●   ●   ●
Low:    ●   ●●● ·   ·   ·   ●●  ●●  ●   ●   ●●  ●●●
```

Visualized:

- **Critical bugs**: 2 total, both in iters 1 and 5. **No critical bugs in iters 6-11.**
- **High bugs**: 7 total, spread across iters 1, 2, 3, 4, 6, 8, 9, 10. **None in iters 7 or 11.**
- **Medium/low**: steady throughout.

The flat-lining of critical bugs after iter 5 is the strongest signal. **The infrastructure-level catastrophic bugs have been found.**

---

# Recommendation: are more dry-runs needed?

**No. Five reasons.**

## 1. Zero critical bugs in iters 6-11

Six consecutive iterations without finding a critical bug.

## 2. The bug profile has shifted decisively to polish

Iters 9-11 found:
- 1 security improvement (argv leak fix; near-zero real-world risk)
- 1 user-facing improvement (mandatory SG check; real value)
- 2 SSH-fragility fixes (setsid, chmod 600; real value)
- 1 paste-validation tweak (whitespace; defensive)
- 1 README clarification (CI flow; doc accuracy)

None are "the install fails." All are "the install is slightly better."

## 3. The classes I haven't covered are NOT findable by dry-run

I've now done passes for: orchestration, error handling, readiness semantics, automation/CI, real-world HTTP, cross-script contracts, real-world cloud quirks, documentation drift, security boundaries, user-impatience, subtle wrong-but-runs.

What I have NOT done — and cannot do via dry-run — is execute against the actual external services. **Three classes of bug remain hidden:**

- Behavior of `get.oxy.tech` installer in current version.
- Actual timing of `oxy.service` startup on real hardware.
- NYC 311 SODA API throttling behavior under real load.

A 12th dry-run won't find these. A real install on a t4g.medium will find them in 30 minutes.

## 4. The remaining bugs that COULD exist by dry-run are increasingly improbable

The bugs I've been finding are at the level of "what if the user has an unusual sudoers config" or "what if the API key has whitespace." Each iteration goes one level deeper into "what if X is slightly weird." 

## 5. The bundle is now at the size where additional defensive code increases its own bug surface

The v1 bundle was 19,617 bytes. v4 is 28,026 bytes — **43% growth** from defensive code. At some point the defenses become a thing to maintain in their own right.

---

## What to do instead

1. **Hand v4 bundle to Code** for shellcheck + idiom review. Code has access to a real shell environment Chat doesn't.
2. **Provision a fresh t4g.medium and run bootstrap.sh end-to-end.** This is the *only* way to find the remaining unknowns. Budget 90 minutes.
3. **Then move to the second batch.**

---

## A meta-observation

The dry-run technique has a clear **shape of useful application**:

- **Iters 1-2** are essential. They find catastrophic and structural bugs.
- **Iters 3-5** are very valuable. They find cross-cutting concerns.
- **Iters 6-8** are valuable. They find real-world frictions.
- **Iters 9-10** are valuable. They find security/UX cliffs.
- **Iter 11** is marginal. Mostly documentation and consistency.
- **Iter 12+** would be wasted effort.

If you have a similar bundle to review in the future, **5-8 iterations is the right depth for the technique.** Fewer leaves bugs on the table; more is reading the same code for the same kinds of bugs that aren't there anymore.

---

*Review completed 2026-05-13 by Chat after 11 iterations. v4 bundle: `stack-in-a-box-setup-scripts-v4.tar.gz`.*

**The technique was the right call. The diminishing returns are real and now demonstrated. The next move is real-world validation.**
