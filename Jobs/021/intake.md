# Job #021: The factory backdrop wall

**Project**: `roblox.magnet-sweep`
**Created**: 2026-09-06
**Status**: Requirements Gathering (intake)

## Requirements / goal

Build a **second, taller wall standing behind the existing perimeter wall**, so the Workshop reads as
a room *inside a much bigger factory* rather than a walled disc under open sky. Pipes, ventilation
ducts, lights, wires, gantries — the industrial mass that says "this room is one corner of something
enormous".

The owner's words: *"another wall behind current — higher... with pipes, ventilations, lights etc,
wires maybe. That will create feeling that this is factory, big wall behind current."*

---

## 🔴 Read this first — the room as it stands

Job 020 built the Workshop and it is **finished and signed off**. This job adds to it and must not
disturb it. Everything below is **measured**, not assumed.

| | |
|---|--:|
| Room shape | regular **12-gon**, centred **(1556, 0, 0)** |
| Apothem (wall face) | **231.35** · circumradius (vertex) **239.5** |
| Facet side | **124** · perimeter **1488** · panel pitch **31** |
| **Existing wall height** | **24** |
| Existing wall radial band | r 233 … 244 |
| Tallest thing in the room | the Arena magnet rig, **Y = 93** |
| Floor | tile 15.8, top at **Y = 0** |
| Player | 5.5 studs tall — 1 stud ≈ 0.28 m |

The full parameter set is in
[`Config/WorkshopLayout.luau`](../../studio_game/ReplicatedStorage/Config/WorkshopLayout.luau).
**Read it before placing anything** — it is the export that makes the room reproducible.

## Why this job exists

Two separate findings point at the same hole, and this wall is the fix for both:

- **No visible map edges** (workspace memory). A 24-stud wall around a 489-stud room does close the
  horizon at eye level, but the room still reads flat and wide, with open sky immediately above the
  wall. There is nothing beyond.
- The room is **2,890 parts of foreground** with nothing behind it. Everything competes for attention
  because there is no background layer to sit against.

## What the concept art actually says

Three sheets in [`assets/concept_art/`](../../assets/concept_art/) are directly about this, and they
were made for it:

| Sheet | What to take from it |
|---|---|
| **`_wall_wall_back_upper.png`** | **The primary reference.** Layered structure receding into deep blue haze; hazard-yellow truss beams overhead; horizontal cyan strip-lights; amber accents far back |
| **`_wall_pipes.png`** | Black rubber cable loops and conduit runs; round blue glowing lamp housings; chrome banded collars |
| **`_wall_column.png`** | Chrome column with black banded collars, yellow/black hazard plate, riveted flanges |

⚠️ **Mockups are direction, not spec** (workspace memory). These set colour, depth and material feel.
Do not build a mechanic because it appears in a painting.

**The single most important read from the art: it is built in LAYERS that recede into blue haze.**
Not one wall — near structure, mid structure, far glow. That layering is what sells scale, and a
single flat taller wall will not do it.

## Assets we already own — check these before generating anything

🔴 **Search the market first** is a standing ground rule. We have a lot already:

**`ServerStorage.Kit`** (generated from `KitSpec`, decision 0017 — still the right way to build
repeated modular pieces):

| Group | Directly useful here |
|---|---|
| `Wall` | `Wall_Pipes`, `Wall_Machine`, `Wall_Solid`, `Wall_Window` |
| `Industrial` | `Ind_PipeRun`, `Ind_Tank`, `Ind_Fan`, `Ind_Generator`, `Ind_ControlPanel` |
| `Structure` | `Struct_Pillar`, `Struct_Bridge`, `Struct_Platform`, `Struct_Corner` |
| `Signage` | `Light_Gantry`, `Sign_NeonSlab` |

**`ServerStorage.ImportedMeshes`** (44 Meshy meshes): `pipe`, `pipes`, `column`, `work_lamp`,
`magnet_coil`, `paint_drum`, `gear`, `golden_gear`.

**`Workspace.DemoRoom.2_WallPatterns`** — the four approved wall patterns: A window bays (16
parts/panel), B tool-board (44), C bar wall (18), D hazard plate (16).

Only after ruling these out should Meshy be considered — and then present the cost first.

## 🔴 Traps this job will walk into

Every one of these has already cost this project time.

1. **`CFrame.fromMatrix(pos, vX, vY, vZ)` needs vX × vY == vZ.** Job 020 got this wrong and
   **mirrored 1,701 parts**, which made every mesh render inside-out — pale, flat, textures apparently
   broken. Plain bricks look fine when mirrored, so it survived review and a dozen screenshots.
   **Prefer the 3-argument form**, and assert the determinant is +1.
   See [finding 0009](../../findings/0009-cframe-frommatrix-with-a-left-handed-bas.md).
2. **The DemoRoom was never rescaled.** The world was scaled ×0.5; the demo room was not. Cloning a
   demo panel at native size gives you a **double-height wall**. Clone at **scale 0.5**.
   See [finding 0008](../../findings/0008-the-workshop-was-built-at-4x-the-decided.md).
3. **Heavy `execute_luau` crashes Studio.** Split placement into one container per call and check what
   survived before re-running.
4. **`Workspace` does not sync.** Anything built here lives only in the unversioned `.rbxl` unless it
   is exported — [decision 0019](../../docs/decisions/0019-hero-geometry-is-editor-placed-and-exported.md)
   requires the export, and `WorkshopLayout.luau` is where it goes.
5. **Lighting is a place setting a human changes.** Bootstrap warns every start that `ClockTime` is
   15.60 (style wants 16.50–18.50) and `EnvironmentSpecularScale` is 0.40 (wants 0.45–0.90).
   `Lighting.Technology` and its successors are `RobloxScriptSecurity` — **no script can set them.**
6. **Verify in Play at eye level.** The editor is never evidence, and a high oblique camera made me
   call two upright buildings "tilted" in job 020 when the measured tilt was 0.0°.

## Questions to settle before building

1. **How tall, and how far back?** The existing wall is 24. The Arena rig is 93. A backdrop that reads
   as "much bigger" probably wants to clear the rig — but it must not turn the room into a well.
2. **How many layers?** The art says at least three (near / mid / far glow). Each layer costs parts.
3. **Does it need Atmosphere to work?** The style skill is emphatic that haze is what creates depth,
   and that a legacy `FogEnd` does nothing once an `Atmosphere` exists. A backdrop without haze may
   just read as a bigger wall.
4. **Is it geometry, or is it a painted backdrop?** A `SurfaceGui`/decal skybox-style panel is a
   fraction of the parts. Cheaper, flatter — and possibly right for the furthest layer.
5. **Does it close overhead?** Pipes and gantries crossing above the room would sell "interior" hard,
   but the Arena rig is 93 tall and needs clearance.

## Checklist

- [ ] Requirements reviewed (this intake)
- [ ] **Independent reviewer agent run** — given the requirement, NOT my theory (GROUND-RULES 8)
- [ ] Concept art re-read and the layer structure agreed
- [ ] Existing kit + meshes checked before any new asset is generated
- [ ] Implementation plan created & agreed
- [ ] Implementation completed
- [ ] **Proof it works better** — before/after from the same camera, in Play, at eye level
- [ ] Exported to `WorkshopLayout.luau` (decision 0019)
- [ ] Final summary + changelog written
