# Job 021 — final summary

**The Workshop has a background.** It was a 489-stud room with a 24-stud wall and open sky above it;
it is now a factory interior with a glazed roof, a truss grid, a lit clerestory and twelve detailed
facet bands. Measured from the view the owner complained from, sky went **45.7 % → 0.0 %**.

## The one idea the job turned on

🔴 **The deliverable was an angle, not a wall.**

An independent reviewer, given only the requirement and never my reading of it (GROUND-RULES §8),
established this with a 48×27 raycast sky-fan before anything was built:

| backdrop | sky % across the room | gain |
|---|--:|--:|
| as built (24 tall @ r=231) | 46.9 | — |
| **double the wall — 48 tall @ 260** | **43.3** | **3.5 pts** |
| 96 @ 260 | 35.9 | 11.0 |
| 130 @ 270 | 30.0 | 16.9 |
| **close overhead** | **0** | **46.9** |

**Doubling the wall height moves 3.5 % of the screen.** The owner asked for "another wall behind
current — higher"; a taller wall alone would have been handsome, on-palette, expensive and nearly
useless from where the complaint was made. The reviewer also read the concept sheet correctly where I
had not: `_wall_wall_back_upper.png` is *a view looking up at a ceiling*, and a room with no roof is
outdoors however tall its walls are.

## Delivered

| Layer | | parts |
|---|---|--:|
| L1 collar | r 254, y 0–48 | 9 |
| L2 wall | r 268, y 40–130 | 12 |
| L3 clerestory + strips | glowing window band, cyan strips, amber accents | 108 |
| L4 trusses | a **grid** at y 122/130 with hazard bands + 25 lamp gantries | 106 |
| L5 roof | **glazed** — 49 glowing panes at y 150 in a dark deck | 168 |
| Facet bands ×12 | five types, no two neighbours alike | 476 |
| Meshy pieces | 3 generated, tiled into runs | 28 |
| Bay lighting | 3 recessed machinery bays lit from within | 117 |
| **Total** | in `Hub.Room.Backdrop` | **1024** (185 Neon) |

Facet plan: `W · P · V · C · M · bay+P · V · bay+M · C · P · W · bay+V` — pipe wall, vent/duct,
cable, machine faces, window wall, plus recessed bays on the three see-through bar-wall facets.

**Verified in Play**, not Edit: across the room 0.0 %, plaza 0.0 %, arena edge 0.5 %, spawn west
0.1 %. Client sees all 1024 parts, so the horizon does not stream in piecewise. Determinant census
**0 mirrored of 1024** — every placement used `CFrame.lookAt`, never `fromMatrix` (finding 0009).

## Assets — 90 Meshy credits, exactly as budgeted

`vent_duct_v1`, `cable_bundle_v1`, `machine_column_v1` — GLB + 5 PBR maps each, staged in the
DemoRoom for approval before entering the world, security-scanned (0 scripts), normalised originals
archived to `ServerStorage.ImportedMeshes`. The market was searched first: the free Creator Store
industrial kits would have read as borrowed next to 44 stylised meshes.

⚠️ One prompt failed with `image_too_complex` and was **charged 0**. Lesson: one object, few
features.

## What was measured and disproved

- 🔴 **Atmosphere cannot substitute for the roof.** Pushed to Density 0.50 to fog the daylight
  skybox into a dark upper volume, the haze **erased the backdrop itself** — haze acts on distance
  and the backdrop is at that distance. The sky closes with geometry or not at all.
- 🔴 **The room going dark was my own doing.** `ClockTime 17.5` puts the sun **6.9°** above the
  horizon. Bootstrap warns for 16.50–18.50, but **18.00 is already below the horizon** — the top
  half of our own "wanted" band is after sunset, and the value job 020 shipped (15.60) is the only
  one that lights the floor. [Finding 0011](../../findings/0011-bootstrap-wants-a-clocktime-band-whose-t.md).
- 🔴 **`PointLight`s are useless on a backdrop.** `QualityController.local.juau:123-131` clamps
  every non-`Hero` light to 10 studs on Low — measured in Play with all 150 room lights at range 10.
  185 of the backdrop's parts are `Neon`, which is the only lighting that survives every tier.
- ⚠️ My `Hero` attributes were set on the parent Part while the clamp reads the `Light`. All 34 did
  nothing — and *should* do nothing, so they were removed rather than relocated.

## The finding that matters most

🔴 **[Finding 0012](../../findings/0012-the-sky-fan-measures-occlusion-not-appea.md) — the sky-fan
passed while the view failed.** At 0.0 % sky the screenshot still showed a pale band across the
horizon that reads as sky. An elevation sweep proved nothing *is* sky: 0–2° hits the far Arena at
404 studs, 6–12° the wall and clerestory at 462–468. The band is the far side of the room **hazed to
the same value as the sky**.

The metric answers *"is there a hole?"*. The complaint was *"it reads flat"*, which is about **value
contrast**. A check that passes while the reported symptom persists is the Tide failure's shape, and
it is the single most useful thing this job produced.

Cause: the style skill's `Atmosphere Density 0.32 / Haze 1.4` is authored for 60–120-stud corridors.
This room is **489 across**.

## Cost, stated plainly

**Room total 3,595 parts — exactly 200 % of `MAX_PARTS_IN_VIEW`.** The owner accepted the backdrop
with that projection in front of them, the same posture as finding 0005.

⚠️ **Performance has still never been measured.** Job 022's frame readings were a Studio artefact —
a hard 15 fps whether the backdrop was present or not, unchanged by removing all 1024 parts, by
shadows, or by post-processing. Studio throttles an unfocused viewport. No performance conclusion has
been drawn, and `QualityController` was itself fooled into selecting the Low tier by that same false
reading.

## Exported

Per [decision 0019](../../docs/decisions/0019-hero-geometry-is-editor-placed-and-exported.md):
`WorkshopLayout.BACKDROP` records every layer's radius and height, the facet type map, the Neon
count, and the before/after sky percentages. `Workspace` does not sync, so without this the job
would exist only in the unversioned `.rbxl`.

⚠️ **The geometry itself is still `.rbxl`-only** — that is what decision 0019 accepts, and the export
is how the objection is paid off: the room can be rebuilt from the numbers.

## Still open

- 🔴 **Findings 0011 + 0012 are one decision:** daylight hall or night factory. Everything odd about
  the lighting traces to it, and it blocks a per-space Atmosphere.
- **A real-device performance reading.** Unavailable from here.
- `LEVEL_OF_DETAIL` / occlusion tuning for a permanently-in-view 1024-part layer: never considered.
- The plaza floor (r 64…190) is still bare; the backdrop fixed the horizon, not the ground.
