# Job #010: Magnet VFX states and the nine sound families

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-30 13:11:54
**Status**: System complete, awaiting sound ids

## Requirements / goal

The rest of build group 04, and the half of it the MVP gate actually turns on: the magnet's five VFX states (idle, pulling, high flow, MAGNET RUSH, overcharge) and the nine object sound families with a Flow-driven pitch rise. Sections 15 and 16. The gate question lists sound as items 2 and 3 of what to fix if sweeping is not satisfying, and the store page recommends headphones, so this is not polish. AUDIO HAS A HARD RULE (docs/systems/audio): no placeholder sounds - leave the slot empty and make it announce itself, because a wrong sound is much harder to notice than a missing one and placeholders are how the wrong asset ships. So this job builds the SYSTEM - a data-driven registry, the per-family voice selection, the Flow pitch driver, the state-driven emitters - with every sound slot empty and loudly reported at startup, and produces a searchable asset table for the human to fill. Per GROUND-RULES section 4 the division of labour is: I search our registry and the Creator Store first and write the spec (length, loop, what it must NOT contain, how it is judged in context); the human finds and supplies the ids. Also in scope: nothing baked in - a magnet hum must not have sparks in it, anything levelled independently is a separate asset.

## Checklist

- [ ] Requirements reviewed (this intake)
- [ ] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [ ] **Symptom reproduced in PLAY**, at the player's camera, before any fix (GROUND-RULES 7)
- [ ] Implementation plan created & agreed
- [ ] Implementation completed
- [ ] **Proof it works better** captured - before/after from the same camera, in Play
- [ ] Final summary + changelog written
