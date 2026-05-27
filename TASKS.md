# TASKS.md — Task Tracker

> Status markers: `[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked
> Claude Code updates this file as work progresses.

---

## Next Focus

The repo is freshly initialized. No plans have started yet. The next moves, in expected order:

1. **Resolve the 5 open decisions** in [`docs/design/OPEN_DECISIONS.md`](docs/design/OPEN_DECISIONS.md). Each needs a defensible answer before the first real install.
2. **Shellcheck pass + idiom cleanup** on the 13 v4 setup scripts at `scripts/setup/`.
3. **First real install** on a fresh EC2 instance. Budget 90 minutes (60 install + 30 buffer).
4. **The second batch** — `run.sh` + the missing artifacts referenced by the v4 setup scripts (see `docs/design/STACK_IN_A_BOX_PLAN.md` §9 for the full list).

---

## Plans Registry (cross-reference with LOG.md)

| # | Status | Notes |
|---|---|---|
| _none yet_ | | |

---

## Operational checklist (steady-state)

- [ ] LOG.md "Last Updated" timestamp bumped at end of every session.
- [ ] Plans Registry row added for every plan, status accurate.
- [ ] Session file at `docs/sessions/session-NN-...md` for every Code session.
- [ ] Limitations registry index regenerated when a `.md` is added (the `run.sh` step lands with the second batch).
- [ ] `docs/handoffs/` summary written at the end of every multi-plan Chat thread.
