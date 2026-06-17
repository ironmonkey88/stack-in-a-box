# Report — Plan 9: APPROACH design-reasoning ("breadcrumbs") doc

**Status:** complete
**Date:** 2026-06-17
**Repo:** `stack-in-a-box` (Plan 9) — with a small cross-repo mirror edit in `oxygen-mvp` (footer only, not a numbered oxygen-mvp plan).

## PRs

| Repo | Branch | PR | Scope |
|------|--------|----|-------|
| `stack-in-a-box` | `claude/plan-09-approach-design-reasoning` | [#13](https://github.com/ironmonkey88/stack-in-a-box/pull/13) | design-reasoning doc + footer + session-starter + LOG/TASKS |
| `oxygen-mvp` | `claude/approach-provenance-footer` | [#82](https://github.com/ironmonkey88/oxygen-mvp/pull/82) | APPROACH.md provenance footer only (byte-identity mirror) |

Plan slot: boot-audit of stack-in-a-box LOG.md Plans Registry — highest used = 8, Plan 4 reserved/in-flight → **9** is the next contiguous free slot. No ambiguity; plan-number halt did not fire.

## Halt condition resolved (Gordon's call)

The byte-identical-APPROACH.md constraint was surfaced before Work item 2. Gordon chose **option (a): add the provenance footer to both repos' APPROACH.md to preserve byte-identity.** The design-reasoning doc itself stays single-home in `stack-in-a-box`; only the one-line pointer is duplicated, and it names the `stack-in-a-box` path so the pointer is accurate read from either repo.

- Post-edit byte-identity confirmed: `diff` clean, `shasum` `c6e27ce1aa8ee8e6e8559cb156ddbd5b7ef230cc` in both repos.
- The oxygen-mvp footer landed as a small mirror PR (#82), commit message cross-references this plan. It was **not** given an oxygen-mvp plan number — it is a sibling-repo mirror of this plan's footer, recorded as such, not standalone oxygen-mvp work.

## What shipped (stack-in-a-box)

1. **Phase 0** — this prompt verbatim at `docs/prompts/plan-09-approach-design-reasoning.md`.
2. **`docs/design/APPROACH_DESIGN_REASONING.md`** — reconstructed; `Status: reconstructed` note + source list; short intro + 8 decision entries in decision→why→alternatives shape.
3. **APPROACH.md provenance footer** (both repos — see above).
4. **`session-starter.md`** — "Key Files to Know" pointer, placed after the APPROACH.md row as its reasoning companion.
5. **LOG.md + TASKS.md** — Plans Registry rows + Last Updated bump + Next Focus block.

## Verification (all static — nothing executes)

- `docs/design/APPROACH_DESIGN_REASONING.md` exists, carries the `Status: reconstructed` note, lists its sources, contains all 8 decision entries. ✅
- **Traceability spot-check** (re-read the cited source for 3 entries):
  - Entry 4 (hypothesis/result terminology) — confirmed against `METHODOLOGY.md` R5 (Klein basis; trust contract = peer review) and `APPROACH.md` "How we think." ✅
  - Entry 6 (declarative-first as accessibility strategy + ladder) — confirmed against `APPROACH.md` "Why we design for declarative use" (airplane/elevator/oncology ladder verbatim from the source). ✅
  - Entry 8 (R7→R7/R8 split) — confirmed against `METHODOLOGY.md` R8 Origin row ("Split from R7 because idempotency is a distinct, separately-testable property"). ✅
- `session-starter.md` references the new doc. ✅
- LOG.md + TASKS.md updated. ✅

## Entries flagged as not fully recoverable

- **Entry 7 (capability-to-scope law).** The Situational-Leadership and agent-surface halves are directly supported by `APPROACH.md` ("How much to specify depends on the builder") and `METHODOLOGY.md` R7 (which names the capability-to-scope ratio). The *broader* unification claimed in the design session — that the same law also unifies hardware-abstraction layers and control-theory altitude — is recorded in `docs/MIGRATION_SUMMARY.md` §5/§8 but is only lightly attested in the named core docs. Per the reconstruction discipline, that breadth is preserved in the entry with an explicit sourcing note flagging it as design-session reasoning for Gordon to confirm or refine — **not invented, not silently asserted.**

No entry was fully unrecoverable; all 8 landed with real sourcing.

## Out of scope (honored)

No edits to PHILOSOPHY.md, METHODOLOGY.md, or the creed/principles themselves. No `.docx`/export. Nothing landed in oxygen-mvp except the APPROACH.md footer (the explicitly-carved-out exception under option (a)).
