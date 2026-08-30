# Job #004: Material kit: nine MaterialVariants and their PBR maps

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-29 13:15:51
**Status**: Requirements Gathering (intake)

## Requirements / goal

Build group 02's material system: the nine MaterialVariants (Chrome, SteelBrushed, SteelDark, PaintedGloss, PaintedWorn, HazardStripe, Rubber, Grate, Rust) under MaterialService with correct BaseMaterial and tiling, plus the PBR map sets they need. Parts-first kit, so MaterialVariant is the PBR path - SurfaceAppearance is MeshPart-only and is reserved for hero meshes. Includes a MaterialKit helper so kit geometry gets variants consistently.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** — given the requirement and artifacts, NOT my reasoning.
      It found that two claims this job published were overreach; re-measurement proved one of them
      **wrong**. See `final-summary.md`.
- [x] **Reproduced in PLAY** — Bootstrap boots clean with the kit; `MaterialKit` exercised in the
      Server datamodel including a deliberately-broken variant to prove the audit can fail.
- [x] Implementation plan created & agreed — the four candidate picks were confirmed via the wizard
- [x] Implementation completed
- [x] **Proof it works** — all nine surfaces captured under the §4 lighting recipe; audit proven able
      to fail; tier strip/restore round-trips.
- [x] Final summary + changelog written

## Outcome

Eight `MaterialVariant`s + built-in Metal for Chrome, `MaterialKit`, the lighting recipe applied, and
32 asset ids recorded in two registries. One earlier claim retracted (see the summary).
