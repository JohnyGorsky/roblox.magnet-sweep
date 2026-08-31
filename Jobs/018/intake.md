# Job #018: The gate and Zone 2

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31 19:14:13
**Status**: Requirements Gathering (intake)

## Requirements / goal

Build the zone 1 -> 2 gate and Zone 2 (Toy Assembly), continuing group 07. SCOPE: (a) the physical gate at Zone1Spec.EXIT_LOCAL -- a giant locking mechanism the player PULLS when their Magnet Power meets the requirement, per docs/systems/factory: 'Required: 150 / Current: 137' then GRRRRR, the pin moves, BOOM, the gate opens; (b) the gate requirement readout ON the gate itself; (c) Zone 2 Toy Assembly as a second spec of Zone1Spec's shape -- cobalt 2F6BE8, lime 8FD63F, coral FF8A6B accents per style section 2, none of which may be a reserved signal colour; (d) zone 2's scrap set x5. HARD CONSTRAINTS: zone 2 registers with ZoneManager exactly as zone 1 does and no script may resolve a zone by Workspace path; use Zone1Spec.exitWorld() for the gate position, never a hand-written coordinate; the Magnet Power gate in ZoneManager.sendTo was added by job 017's review and has NEVER been exercised because tier 2 did not exist -- this job is what arms it, so test it. ALSO CHECK BEFORE BUILDING: how many of zone 2's scrap types already exist in ScrapSpec (all 8 tier-1 types already existed when job 017 started, and the manifest xN suffix is a COUNT).

## Checklist

- [ ] Requirements reviewed (this intake)
- [ ] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [ ] **Symptom reproduced in PLAY**, at the player's camera, before any fix (GROUND-RULES 7)
- [ ] Implementation plan created & agreed
- [ ] Implementation completed
- [ ] **Proof it works better** captured - before/after from the same camera, in Play
- [ ] Final summary + changelog written
