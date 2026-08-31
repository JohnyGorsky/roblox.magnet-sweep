# Job #015: The loading screen gets its art

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31 10:11:05
**Status**: Requirements Gathering (intake)

## Requirements / goal

Close the one P0 deliverable knowingly skipped: the loading screen has no art. Generate a hero 16:9 illustration with Meshy image_to_image, style-matched to assets/concept_art/Robot.png (glowing red+chrome horseshoe magnet, cyan arcs, scrap in flight, a robot in the background, a factory corridor receding). Upload to Roblox, wire it into ReplicatedFirst/BootScreen.local.luau as a full-bleed backdrop that the title card and progress row still read against, and remove the ART MISSING warn only once there is real art behind it. Loading screen ONLY -- the ceiling, conveyors, floor arrows and ground crates are parts work for KitSpec, not Meshy, and are out of scope.

## Amendment, same day — the approach changed before anything was built

The owner stopped the Meshy route before it ran (**no credits spent**) with: *try Roblox objects or
the Creator Store first.* On investigation that is the better route on the merits, not just on cost:

- §7 asks the screen to *"feel interactive"* and to represent progress as *objects flying into the
  magnet*. A flat image can do neither — it would have hung behind four emoji still doing that job.
- Creator Store was searched (`Image`, `creator_store`, 10 results) and has no bespoke key art —
  untitled screenshots, a "Backroom" decal, a Skibidi Toilet door.
- A generated image also carried **moderation** risk (renders for the owner, blank for players) and
  was **irreversible** once published.

**Revised goal:** build the scene as a live `ViewportFrame` diorama from primitives, in-file (this
runs in `ReplicatedFirst` and may not touch `ReplicatedStorage`), with the four progress objects
flying into the magnet on real stage completion. Meshy stays available for hero *meshes* later,
which is where style §3 puts it anyway.

## Checklist

- [ ] Requirements reviewed (this intake)
- [ ] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [ ] **Symptom reproduced in PLAY**, at the player's camera, before any fix (GROUND-RULES 7)
- [ ] Implementation plan created & agreed
- [ ] Implementation completed
- [ ] **Proof it works better** captured - before/after from the same camera, in Play
- [ ] Final summary + changelog written
