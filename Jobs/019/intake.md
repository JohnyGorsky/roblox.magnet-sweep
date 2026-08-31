# Job #019: The hub becomes a ring of bases

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31 19:36:15
**Status**: Requirements Gathering (intake)

## Requirements / goal

Replace the single shared Workshop hall with the MapConcept layout: up to 12 per-player bases in a ring around a central Arena, with ONE run lane leading out to the twelve-zone factory corridor. Reference: assets/concept_art/MapConcept.png -- the owner wants nearly identical design. Each base is a walled pocket with its own Robot Bay, Recycler, Magnet Lab and staging pad, and every base is visible from every other because seeing each other is the point. CORRECTIONS TO THE CONCEPT ART, from the owner: ONE run lane, not the four the image shows (the twelve-zone corridor is the single run path, decision 0003 survives); and up to TWELVE bases, not four, matching the server's twelve-player cap. WHAT SURVIVES: the factory corridor, the gates, Zone 1, ZoneManager, ZoneBuilder, ZoneSpec, the kit, MaterialKit, the magnet. WHAT GOES: WorkshopSpec's 13x13 hall and its seven SHARED stations -- stations become per-player and per-base, which is also what makes stealing from another base possible later.

## Checklist

- [ ] Requirements reviewed (this intake)
- [ ] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [ ] **Symptom reproduced in PLAY**, at the player's camera, before any fix (GROUND-RULES 7)
- [ ] Implementation plan created & agreed
- [ ] Implementation completed
- [ ] **Proof it works better** captured - before/after from the same camera, in Play
- [ ] Final summary + changelog written
