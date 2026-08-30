# Job #007: Magnet core: four-state scrap, object pool, capped pull, batched server grant

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-29 21:39:12
**Status**: Complete

## Requirements / goal

Build group 04's core: the IDLE/REACT/PULL/COLLECTED state machine, a server-side object pool that re-poses rather than allocates, the MaxConcurrentPull cap with a REACT waiting queue, client-side pull motion, and a batched server collection grant that validates every claimed id against what the server actually spawned. This is the first playable thing in the game and the first third of the MVP gate.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [x] **Symptom reproduced in PLAY**, at the player's camera, before any fix (GROUND-RULES 7)
- [x] Implementation plan created & agreed
- [x] Implementation completed
- [x] **Proof it works better** captured - before/after from the same camera, in Play
- [x] Final summary + changelog written
