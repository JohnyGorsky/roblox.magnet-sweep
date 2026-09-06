# FINDING 0004: Wall height and tile size are off the 0017 4-stud grid

**Project:** `roblox.magnet-sweep`
**Status:** open
**Severity:** med
**Created:** 2026-09-06 00:45:23

**Symptom:** Decision 0017 fixes a 4-stud grid: standard tile 8, wall height 12. The floor and wall patterns the owner approved in the demo room are neither. Measured in Studio: floor sample tiles are 9.5 x 2.0 x 9.5 (not 8, not a multiple of 4) and all four wall patterns stand 60 studs tall (5x the 12-stud wall height). The Arena Ground as actually built uses 32-stud tiles, a third scale again. 0017 says the grid constrains FOOTPRINTS not internal detail, and meshes were always exempt, so this may be legitimate drift rather than a violation - but three different tile scales (8 spec / 9.5 sample / 32 built) cannot all be right, and nothing records which one the Workshop should use. Decide the canonical floor tile size and either bring the patterns onto the grid or amend 0017 to say the grid applies to kit pieces only.
**Where:** docs/decisions/0017-the-kit-is-generated-from-a-spec.md + DemoRoom.1_FloorPatterns / 2_WallPatterns
**Repro / notes:** _TODO_
**Fix idea:** _TODO_
