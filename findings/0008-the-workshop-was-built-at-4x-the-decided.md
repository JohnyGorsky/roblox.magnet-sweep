# FINDING 0008: The Workshop was built at 4x the decided grid; rescaled to 2x, still not 1x

**Project:** `roblox.magnet-sweep`
**Status:** open
**Severity:** high
**Created:** 2026-09-06 10:10:48

**Symptom:** Decision 0017 fixes the grid at standard tile 8 and wall height 12. The Workshop as first built used tile 32 and wall 48 - EXACTLY 4x both, so the drift was systematic rather than a series of eyeball errors. Consequences measured against a 5.5-stud R15 player: one floor tile was 9.0 metres across and 8x the player's width, the smelter conveyor 54 metres, the room 259 metres, the arena magnet rig 52 metres tall. The owner found it by playing: i just entered game and realised how big all is, followed by demo was better - the demo room uses 9.5-stud floor tiles against the world's 32, which is the same complaint stated twice. FIXED PARTIALLY on 2026-09-06: the whole world (Arena, Hub, spawn - not the DemoRoom) was scaled x0.5 about the arena centre at (1556,0,0). Costs zero parts because it is a transform, not a rebuild, and is exactly reversible by scaling 2.0 about the same point. Tile is now 15.8, wall 24, room 489 across, robot 1.9x player height. STILL OPEN: that is 2x the 0017 grid, not 1x. A second uniform halving would put the Magnet Lab at 4.5 studs - shorter than the player - so the remaining gap cannot be closed by another uniform pass; the shared buildings are undersized RELATIVE to the room and need scaling independently. Either do that, or amend 0017 to state the real shipping grid.
**Where:** Workspace (job 020) + docs/decisions/0017 + Config/WorkshopLayout.luau
**Repro / notes:** _TODO_
**Fix idea:** _TODO_
