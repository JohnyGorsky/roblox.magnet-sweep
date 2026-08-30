# Job #005: Industrial kit geometry: floors, walls, structures, props, neon signage

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-29 20:15:39
**Status**: Requirements Gathering (intake)

## Requirements / goal

Build group 02's remaining items: the floor/wall/structure/industrial kits, the neon slab sign component, hazard-stripe tiling that survives scaling, warning beacon, scrap crates, robot arm prop, and conveyor motion by texture offset. Everything surfaced through MaterialKit.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** — given the requirement and the repo, NOT my reasoning
- [x] **Reproduced in PLAY** / exercised in a live Studio session
- [x] Implementation plan created & agreed
- [x] Implementation completed
- [x] **Proof it works** — see `final-summary.md`
- [x] Final summary + changelog written

## Outcome

24 kit pieces / 83 parts generated from `KitSpec`, tiling verified by an assembled corridor.
My first validator enforced the wrong invariant; the corrected one found 3 real overhang bugs.
