# 0004 — Parts are content; the rig is the engine

**Status:** Accepted · 2026-08-29 · Job 001

## Context

The catalog is 96 robot parts across twelve tiers, and the design explicitly wants that number to keep
growing with ridiculous objects forever. Section 39 wants robots that look homemade and asymmetrical,
built from recognisable real-world objects.

The naive reading is that each part is bespoke: its own model, its own mount logic, its own animations.
96 parts times ~20 animations is 1,920 animations, and every new part is an engineering task.

## Decision

**One hidden skeleton. Standardised sockets. Shared animation profiles.**

- Every robot uses the same ~10-joint invisible rig, whatever is bolted to it.
- Every part model carries exactly one `Attachment` named `RobotMount`, positioned at import.
- Every part declares an `AnimationProfile` from a shared set of ~20, plus stats, VFX and sound
  profiles.
- The combat system knows profiles. It has never heard of spoons.

Full architecture: [systems/robot-rig](../systems/robot-rig/README.md).

## Consequences

- Adding a part is: generate the model, add one attachment, fill a stats row, pick a profile. No code.
- A Giant Spoon and an Excavator Bucket share `SweepHeavy`/`SmashHeavy`; the welded object simply
  follows the shoulder.
- Animation count stays near 20 regardless of catalog size.
- Parts are `Massless` and non-colliding — stats come from the data row, never from the geometry. This
  is what lets a Vault Door and a Colander coexist on the same rig.

## The check

**Ask of every proposed part: does adding it require touching a script?** If yes, the part is fine and
the *engine* is wrong — generalise the engine, do not special-case the part.
