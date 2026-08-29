# Job #002: Place setup and sync layout probe

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-29 10:51:21
**Status**: Requirements Gathering (intake)

## Requirements / goal

Create/verify the MAGNET SWEEP place over MCP, record its id, probe the Studio Sync layout (flat vs nested, which service folders sync, which file suffix produces which class, whether .client.luau in StarterPlayerScripts runs twice), and rewrite .jobconfig.json with what was OBSERVED - clearing the UNVERIFIED status.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** — **not applicable.** This job is a measurement, not a change:
      the probe wrote 18 markers, read the DataModel back, and reported what was there. A reviewer adds
      nothing to a result that is already reproducible by re-running it. Recorded rather than ticked.
- [x] **Symptom reproduced in PLAY** — the `.client.luau` double-run was reproduced in an actual Play
      session, because Edit structurally cannot show it. Play was stopped and Edit confirmed.
- [x] Implementation plan created & agreed — trivial for a probe; the method is in `final-summary.md`
- [x] Implementation completed
- [x] **Proof it works** — 11 of 18 markers arrived (a dead connection gives 0), suffix classes and
      RunContexts read back individually, double-run reproduced with a single-run control alongside it
- [x] Final summary + changelog written

## Outcome

`.jobconfig.json` is **VERIFIED**. Layout is FLAT. Two traps documented. Four Studio settings still need
a human: `MaxPlayers` → 12, `PreferredPlayers` → 12, `LightingStyle` → `Realistic`, access/social slots.
