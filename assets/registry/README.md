# Asset registry — MAGNET SWEEP

What this game **needs** and what it **uses**. Grep this before sourcing anything, then the shared
workspace catalog at `roblox.workspace/Assets/registry/`.

**Nothing is sourced yet.** No ids exist, and none should until a slot needs one.

## Created by us

| Id | Type | Name | Where used | Notes |
|---|---|---|---|---|
| — | | | | *(none yet)* |

## Used from elsewhere

| Id | Type | Name | Source | Licence | Where used | Scanned? |
|---|---|---|---|---|---|---|
| — | | | | | | *(none yet)* |

## Per-type registries

| File | Covers | Status |
|---|---|---|
| [materials.md](materials.md) | the 8 PBR `MaterialVariant`s (32 texture ids) | **landed** — job 004 |
| [sounds.md](sounds.md) | the 14 sound slots: 9 object families + 5 magnet states | **14 empty**, spec written, awaiting ids |

## Needed — the standing shortlist

Filled from the build manifest as slots open. Not a shopping list to work through now.

| Type | Slot | Must contain | Must **not** contain |
|---|---|---|---|
| sound | scrap pickup — bolt (*tik*) | a single short metallic tick, dry | reverb, music, a tail |
| sound | scrap pickup — coin, gear, spring, tool, barrel, vehicle, huge machine | one per family, pitch-shiftable | anything baked in that is levelled separately |
| sound | rare part strain (**GRRRRRR**) | a building metal strain, loopable | the release hit |
| sound | rare part release (**CLANG**) | one heavy impact | the strain |
| sound | Salvage Breach klaxon | a loopable industrial alarm | speech, sirens with a fixed pattern length |
| sound | SECURED | the payoff chord. The best sound in the game | — |
| texture | 9 PBR sets — colour/normal/metalness/roughness | tileable, neutral colour | baked lighting, baked dirt |
| mesh | hero props: magnet, Recycler, install machine, Arena Core, gate, guardians | `PreciseConvexDecomposition`-friendly geometry | pre-attached scripts |
| mesh | 96 robot parts | one `RobotMount` `Attachment` each | mass or collision that matters |

## Meshy

Prompts and import notes live in `../meshy/`. Per-part import checklist:

1. Generate, remesh to a sane tri budget, texture.
2. Import. **At import time** (a script cannot do this — the property is `PluginSecurity`), set
   `CollisionFidelity`: `PreciseConvexDecomposition` only if a player passes through a gap in it,
   otherwise leave `Default`. Meshy imports arrive as `Box`, which is wrong for both
   ([PITFALLS #21](../../docs/PITFALLS.md#21-collision-fidelity--a-pipeline-default-and-a-property-scripts-cannot-set)).
3. Add the `RobotMount` `Attachment` — position and orientation define how the part hangs.
4. Do **not** rely on `PivotTo` for mounting; a `PrimaryPart` silently overrides `WorldPivot`
   ([PITFALLS #22](../../docs/PITFALLS.md#22-pivotto-vs-primarypart)).
5. Set `Massless = true`, `CanCollide = false`, `CanQuery = false`, `CanTouch = false`.
6. Fill the part's stat row and pick its `AnimationProfile`.
7. Log it here.
