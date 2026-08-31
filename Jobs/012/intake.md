# Job #012: The Workshop room: generated from a spec, seven stations, neon signage, spawn and the Arena sightline

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-30 23:02:50
**Status**: ✅ **Complete** — see [final-summary.md](final-summary.md) and [changelog.md](changelog.md).
Room built, lit and verified in Play; 11 real defects from the independent review fixed and
re-verified. Stations are scenery until job 013.

## Requirements / goal

Build group 05's PHYSICAL half. The Workshop is the central safe hub and the proof of decision 0001 - the Arena has to be visible and audible from it. Scope: a WorkshopSpec module plus a builder, following decision 0017 exactly as the industrial kit does - geometry is DATA in git, realised by code, never hand-built in Studio, because Workspace does not sync and anything hand-placed exists only in the unversioned .rbxl. Deliverables: the room shell assembled from the 24 existing kit pieces on the 4-stud grid; the seven station positions from spec section 8 (Magnet Lab, Robot Bay, Arena, Recycler, Repair Station, Collection Wall, Factory Entrance) each as a plinth with a neon slab sign in that station's SIGNAL colour; the player spawn point; and a real sightline from the Workshop floor to where the Arena will stand. OUT OF SCOPE, and they are job 013: making any station DO anything - the Magnet Lab terminal, the Recycler transaction, the Repair Station, the Robot Bay shell contents, and the MOVE NEAR SCRAP first-time prompt. HARD CONSTRAINTS. Every surface goes through MaterialKit and is named, never a raw material, so the room re-skins when a variant changes. Signage is plain Neon plus a matching PointLight, never a PBR override, and only hero lights cast shadows with a budget of 8 shadow-casters visible at once. The signal colours mean one thing each and a station sign may not borrow another station's colour. The build must be idempotent like KitBuilder.buildAll, and it must have a validate() that can actually fail. Verify in PLAY with screenshots read as images, not in Edit, and measure the draw calls and frame time in the Workshop before calling it done - performance says the Workshop draw-call count is an open question that must be answered before the Workshop is signed off.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [x] **Verified in PLAY**, at the player's camera, before any fix (GROUND-RULES 7)
- [x] Implementation plan created & agreed
- [x] Implementation completed
- [x] **Proof it works** captured — screenshots at every stage, read as images - before/after from the same camera, in Play
- [x] Final summary + changelog written
