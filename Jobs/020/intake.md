# Job #020: Build the Workshop room

**Project**: `roblox.magnet-sweep`
**Created**: 2026-09-06 00:23:44
**Status**: Implemented — see final-summary.md. One open decision: the floor tile size.

## Requirements / goal

Lay out the Workshop as a 760-stud ring, using the models generated in job 019. Arena at the centre (already built, 224 across). Common buildings at radius ~200: Magnet Lab, Recycler, Robot Bay, Shop Kiosk, Repair Station, Part Archive Wall, Arena Status Display. Twelve player bases at radius ~300, each a Gantry (crane arm over the player's own smelter: hopper, belt sections, furnace, output bay). Perimeter wall at ~380 using wall type A (glowing window bays) for most of the run, B (tool-board panels) behind the shops, C (bar wall) where the factory should show through, D (hazard plate) at the Factory Entrance gate. Floors: A2 medium checker as default ground, A3 strong checker inside the arena, B hazard borders at thresholds, E bay rings under shops and staging pads, C big plates for the run lane. ALL RADII ARE PROVISIONAL and must be walked at eye level before being trusted. Everything is placed in the editor, not generated at runtime. Also outstanding: move the spawn point off the arena plinth, and add the seven neon station name plates.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** - given the requirement only, not my reading. Found the Box collision fidelity and the dead station contract; both real, both missed by me
- [x] **Walked in PLAY at eye level** before trusting any radius - which moved the spawn and re-oriented the gantry
- [x] Implementation plan created; three owner decisions taken via the wizard
- [x] Implementation completed (floor tile size left open for the owner - test patch standing in the plaza)
- [x] **Proof captured in Play**: stations 20/20 prompts attached (was 0), spawn facing the Arena dot=1.00, eye-level captures of the arrival view and the base ring
- [x] Final summary + changelog written
