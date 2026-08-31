# Job #017: Zone 1 and the zone manager

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31 13:34:39
**Status**: Requirements Gathering (intake)

## Requirements / goal

Build the first real zone and the infrastructure every later zone depends on. SCOPE: (a) the ZONE MANAGER -- zones register with it and talk only to it, never to each other, because under Instance Streaming a cross-zone instance path is a nil-index crash not a smell (docs/systems/factory); (b) ZONE 1 COLOR WORKSHOP as a self-contained streamable chunk, generated from a spec in git the way the Workshop is (decision 0017), built from the 27-piece kit -- if a room needs a bespoke asset the kit is wrong; (c) the connection from the Workshop's Factory Entrance station, which already reads ZONE 1 OPENS IN GROUP 07; (d) zone 1 scrap actually spawning in zone 1 via the zone manager. NOT IN SCOPE, deliberately: the 1->2 gate, zone 2, the Service Hub, MagRail, the return lane, hazards and ambience -- group 07 is 34 items and splitting it is honest rather than pretending otherwise. Zone 1 theme per docs/content/zones: cyan/pink/yellow, small conveyors, paint machines, bright toy-like machinery; zone accents candy pink FF6FB5, mint 7FE6C4, lemon FFE066 per style section 2, which may NOT use any reserved signal colour. ALREADY DONE, verify rather than rebuild: all 8 tier-1 scrap types exist in ScrapSpec, and Config/Zones.luau has all 12 tiers with gates and guardians.

## Checklist

- [ ] Requirements reviewed (this intake)
- [ ] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [ ] **Symptom reproduced in PLAY**, at the player's camera, before any fix (GROUND-RULES 7)
- [ ] Implementation plan created & agreed
- [ ] Implementation completed
- [ ] **Proof it works better** captured - before/after from the same camera, in Play
- [ ] Final summary + changelog written
