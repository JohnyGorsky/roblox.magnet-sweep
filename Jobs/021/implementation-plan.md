# Job 021 — implementation plan

**Project**: `roblox.magnet-sweep` · **Status**: agreed design, not yet built
**Agreed with the owner 2026-09-06** via wizard: roof + trusses · main wall **130** · **full detail all
round** · **generate 3 Meshy hero pieces (~90 credits)**.

---

## 1. The requirement, restated as something measurable

The owner's words: *"another wall behind current — higher... with pipes, ventilations, lights etc,
wires maybe. That will create feeling that this is factory, big wall behind current."*

🔴 **The deliverable is an angle, not a wall.** An independent reviewer (GROUND-RULES §8, given only
the requirement) established this with a raycast sky-fan at eye height 5, 70° vertical FOV, and it is
the single most important number in this job:

| viewpoint (eye y=5, level) | sky % of frame |
|---|--:|
| at a base r=200 → **across the room** | **45.7** |
| plaza r=120 → outward | 37.8 |
| arena edge r=60 → outward | 41.1 |
| at a base r=190 → outward | 13.3 |

A pinhole model `sky = (tan35° − tanθ) / (2·tan35°)` predicts 37.8 % against 37.8 % measured, so the
model is validated and sizes the wall **before** anything is placed.

**And it says a second wall alone does not work:**

| backdrop | far-view sky % | gain |
|---|--:|--:|
| today (24 tall @ r=231) | 46.9 | — |
| **48 tall @ 260 — double the existing wall** | **43.3** | **3.5 pts** |
| 96 @ 260 | 35.9 | 11.0 |
| 130 @ 270 | 30.0 | 16.9 |
| **roof** | **0** | **46.9** |

Doubling the wall height changes **3.5 % of the screen** from where the owner is standing when they
complain. That is the trap this job had to avoid: a correct-looking, expensive, on-palette second wall
that moves the actual view by nothing.

## 2. What was measured in the live place

All over MCP in Edit, `placeId 111667188608192`. **Corrections to the intake in bold.**

| | |
|---|--:|
| Existing wall | Y 0…24 |
| **Existing wall outer face** | **249.8**, not the 244 the intake states — type-C bar panels stand 11.1 deep |
| **Floor runs out to** | **r = 260.2.** Beyond that is void — the 2048² Baseplate ends 292 studs west of the room |
| Arena rig top (highest thing) | Y = 93 |
| **Highest standable point** | **Y = 93**, the Arena rig — decides whether upper layers may be hollow |
| Room parts | **2,586** BaseParts (Hub 1,894 + Arena 692), not ~2,890 |
| Part budget | `Config/Perf.luau:62` `MAX_PARTS_IN_VIEW = 1800` → already **144 %** |
| Sun | elevation **32.6°**, azimuth **208°**; floor shadow = 1.56 × height |

🔴 **All 12 facets are open sky above Y=24.** A ray outward at Y=40 on every facet hits nothing.

🔴 **Facets 5, 7 and 11 are open sky at EYE HEIGHT.** They are bar wall (pattern C), whose own config
comment says *"the factory shows through"* — but there is no factory behind it. A ray at Y=12 through
each of those three facets exits to the skybox. That is **25 % of the perimeter, at standing height**,
and it is a stronger statement of the problem than "the room has no background".

⚠️ **The DemoRoom is visible over the wall** — 933 parts, 78.5 tall, 1,225 studs west. Rays at eye
height from the east half of the room, at +4° elevation, hit it.

## 3. Three scale factors coexist — get one wrong and the piece is half or double

This has already cost the project two jobs and it is the most likely way this one goes wrong quietly.

| Source | → world | Because |
|---|--:|---|
| `Workspace.DemoRoom` patterns (48 tall) | **× 0.5** | the world was rescaled ×0.5, the demo room was not |
| `ServerStorage.Kit` (`KitSpec` TILE 8, WALL_H 12) | **× 2.0** | the world runs at tile 15.8 / wall 24 = 2× the 0017 grid |
| `ServerStorage.ImportedMeshes` | normalised to ~1 stud | scale at placement |

The intake lists `Wall_Pipes`, `Ind_PipeRun`, `Struct_Pillar`, `Light_Gantry` as "directly useful"
with **no scale note**. Cloned at 1.0 they are half height.

## 4. The design

Everything below was massed as 31 throwaway parts in `workspace.__MassingTest` and photographed from
the spawn diagonal before being agreed. Radii are to the layer's **inner face**.

| Layer | radius | Y | what it is |
|---|--:|--:|---|
| *(existing wall)* | 231 … 249.8 | 0 … 24 | untouched |
| **L1 — near collar** | 266 | 0 … 48 | **the detail layer.** Pipes, vent ducts, cable loops, hazard columns, lamp housings, cyan strip-lights. 16.2 studs of clear depth in front of it for props |
| **L2 — main backdrop** | 284 | 40 … 130 | the mass. Panel structure, gantry bands, emissive dots |
| **L3 — clerestory** | 284 | 130 … 168 | 🔴 **glowing window band.** Fills the 38-stud slot between wall-top and roof that would otherwise still show sky — and it is the strongest element in `_wall_wall_back_upper.png` |
| **L4 — roof + trusses** | to r≈300 | roof 168, trusses 120 | closes the sky. Trusses clear the Arena rig (93) by 27 |

**Why 130 and why close in.** 489 wide : 130 tall ≈ **3.8 : 1**, a real large-hall proportion; today
it is **20 : 1**, a plaza with a curb. And *closer beats farther for frame-fill* — H=130 at r=284 and
at r=430 differ by 0.6 % of screen, so the mass goes close and **depth is bought with haze, not
distance**.

**Not a well.** From the room centre L2 subtends `atan(125/284) = 23.8°`. A well starts above ~45°,
which would need H > 325.

### The two things the roof creates, and their answers

1. 🔴 **The room goes dark.** Confirmed in the massing capture — the roof blocks a sun at 32.6°. The
   answer is **L3 the clerestory plus L1's lamp gantries**, which are therefore *load-bearing, not
   decoration*. Roof glazing is what lights a real factory and it is in the art.
2. 🔴 **Decorative lights are useless here.** `QualityController.local.luau:123-131` clamps every
   non-`Hero` `PointLight`/`SpotLight`/`SurfaceLight` range to **10 studs on Low**, 15 on Medium.
   A backdrop 30–300 studs away gets **nothing** from them on the reference device.
   **The backdrop must read from `Neon` + `BloomEffect`** — the only post-effect the Low tier keeps —
   and never from light spill. Add `PointLight`s only as a High-tier garnish.

### Lighting

Already applied to the live place and **backed up** at `workspace.__MassingTest.__LightingBackup`:
the style skill's own §4 recipe (Atmosphere Density 0.32 / Haze 1.4 / Glare 0.5, EnvSpecular 1.0,
EnvDiffuse 0.55, Exposure 0.15, Brightness 2, ClockTime 17.5, Bloom 0.8/20/1.6). Bootstrap has been
warning that these had drifted since job 020.

⚠️ **Measured and worth recording: Atmosphere cannot substitute for the roof.** Pushed to Density
0.50 to try to fog the daylight skybox into a dark upper volume, the haze **erased the backdrop
itself** — haze acts on distance and the backdrop is at that distance. Screenshot kept. The sky is
closed with geometry or not at all.

## 5. Assets to generate — 3 Meshy hero pieces, 90 credits

Market searched first per GROUND-RULES §4: the kit covers pipe runs, tanks, fans, pillars and light
gantries; the 44 imported meshes cover `pipe`, `pipes`, `column`, `work_lamp`, `gantry`. Creator Store
free results for industrial pipes/ducts were generic realistic kits that would read as borrowed next
to 44 stylised meshes — the same conclusion job 020 reached about free gantries.

| Type | Name | Fills | Reference | Settings |
|---|---|---|---|---|
| model | `vent_airhandler` | the "ventilations" the owner asked for. The kit has a 6×6 fan, no duct run | `_wall_wall_back_upper.png` | meshy-6, preview 20 + PBR refine 10 |
| model | `cable_bundle` | the "wires maybe" — black rubber cable loops with chrome banded collars | `_wall_pipes.png` | as above |
| model | `wall_machine_column` | a big background machine mass, chrome with black banded collars and a yellow/black hazard plate | `_wall_column.png` | as above |

**30 credits each, 90 total, of 1,923.** `target_formats` must be **GLB** and is set at creation —
it cannot be changed afterwards. All three are placed on **L1 only**, where they are seen at ~60
studs through the bar wall and detail actually survives; at 300 studs a 1-stud pipe is **2.9 px** at
1080p and under 2 px on a phone.

Import discipline: `CollisionFidelity` is irrelevant here because **the entire backdrop is
`CanCollide = false`** — no collision geometry gets cooked at all. Security-scan and log to the shared
registry per the asset policy.

## 6. Build order

Each step is one `execute_luau` call with one container, because heavy calls crash Studio (PITFALLS).
Check what survived before re-running.

1. **Extend the floor / plinth** — L1 at r=266 stands past the floor's 260.2 edge. Give it a dark
   plinth ring rather than relaying tiles.
2. **L1 shell**, 12 facets. 3. **L2 shell.** 4. **L3 clerestory** (Neon). 5. **L4 roof + trusses.**
6. **L1 detail pass** — kit pieces at **×2.0**, imported meshes, then the 3 Meshy pieces.
7. **Determinant census** over every placed part (see below).
8. **Export to `Config/WorkshopLayout.luau`** — decision 0019. `Workspace` does not sync; unexported,
   this job is unreviewable and one crash from gone.

🔴 **Use `CFrame.lookAt`, never `CFrame.fromMatrix`.** Finding 0009: a left-handed basis mirrored
1,701 parts, every mesh rendered inside-out, and it survived four review rounds and a dozen
screenshots because plain bricks look fine mirrored. A dark, distant, hazy backdrop is the worst
possible place to spot it. `lookAt` is right-handed by construction. The massing rig already asserts
`det(R) == +1` on every part and reported **0 mirrored**.

## 7. Proof — each row names what failure looks like

| # | Proof | Fails if |
|---|---|---|
| 1 | Re-run the raycast sky-fan, same 5 viewpoints, **in Play** | far-view sky does not fall 45.7 → ≤ 10 %; any viewpoint above 15 % |
| 2 | Before/after in Play, same camera, 3 spots — at a base outward, plaza outward, **at a base looking across the room** | the third is skipped; it is the one that matters and the easiest to drop |
| 3 | Determinant census over every new BasePart | any part with det = −1 |
| 4 | Elevation sweep 0–20° from ≥5 positions | `DemoRoom` or `Baseplate` appears in any hit |
| 5 | Under-hang sweep from the highest standable point (Y=93) and through the gate opening | a floating bottom edge of L2/L3 is visible |
| 6 | Low-tier pass with `decorativeLightRange = 10` | the backdrop goes dark because it was lit with PointLights instead of Neon |
| 7 | Screenshot the SW base ring after the roof lands | the base ring is unreadably dark and no lamp layer was added |
| 8 | Part count + delta vs 2,586 | (recorded, not a pass/fail — the owner has chosen full detail with the numbers in front of them) |
| 9 | The owner walks it | they repeat the sentence unchanged — which per PITFALLS #6 means re-open the diagnosis from zero, and a fresh reviewer is mandatory before a second attempt |

⚠️ Rows 1, 2, 6 and 7 are **Play**, not Edit. Every screenshot in this plan is an Edit capture and is
therefore a first read, not evidence.

## 8. Needed from the human

- **Nothing to start.** Studio stays open on the place.
- Later: `MaxPlayers` on the Creator Hub still reads 12 and should be 10 (carried over from job 020).
- Judgement calls on look, once the sample facet is standing.

## 9. Open, and deliberately not decided here

- `Workspace.StreamingEnabled = true` but `docs/build/01-foundation.md:10` still has the streaming
  radii **unchecked** — the backdrop is being planned onto engine defaults nobody chose. A horizon
  that streams in piecewise is worse than no horizon. Worth a finding.
- The backdrop takes the room to ~190 % of `MAX_PARTS_IN_VIEW`. The owner chose full detail with that
  number in front of them; the honest next step is a real-device reading, not a number argument
  (same posture as finding 0005).

---

# BUILD LOG — 2026-09-06

## What changed against the plan

🔴 **The owner removed the roof panel** mid-build (*"i removed top big panel now we have light,
but we need more light"*). The solid roof is therefore **out**; the truss grid stayed. Everything
below is measured with the sky open.

🔴 **The room going dark was mostly my fault, not the roof's.** I had set `ClockTime = 17.5`, which
puts the sun **6.9°** above the horizon. See [finding 0011](../../findings/0011-bootstrap-wants-a-clocktime-band-whose-t.md):
Bootstrap warns for a band of 16.50–18.50, but **18.00 is already below the horizon**, so the top
half of our own wanted band is after sunset. Now at **16.2** (sun 24.6°), `Ambient` 46,54,72,
`ExposureCompensation` 0.35, `EnvironmentDiffuseScale` 0.70.

## Built

| Layer | parts |
|---|--:|
| L1 collar (r254) + L2 main backdrop (r268) | 23 |
| L3 emissive — clerestory windows, cyan strip-lights, amber accents | 108 |
| L4 overhead — truss **grid** with hazard bands + 25 warm lamp gantries | 106 |
| 12 facet bands, five types so no two neighbours match | 449 |
| 3 recessed machinery bays on the see-through bar walls (facets 5/7/11) | 53 |
| **Backdrop total** | **739** (155 Neon) |

**Facet plan** — `0 W · 1 P · 2 V · 3 C · 4 M · 5 bay+P · 6 V · 7 bay+M · 8 C · 9 P · 10 W · 11 bay+V`
where P = pipe wall, V = vent/duct wall, C = cable wall, M = machine faces, W = window wall.
No two adjacent facets share a type, so the ring reads as a factory rather than as wallpaper.

## Measured result — the 48×27 raycast sky-fan, eye height 5, level gaze

| viewpoint | before | after | gain |
|---|--:|--:|--:|
| at a base → **across the room** (the owner's own view) | 44.7 % | **14.0 %** | 30.6 |
| plaza r120 → outward | 37.5 % | **0.0 %** | 37.5 |
| arena edge r60 → outward | 41.0 % | **4.5 %** | 36.5 |
| spawn → west | 43.4 % | **12.3 %** | 31.1 |
| at a base → outward | 15.4 % | **0.0 %** | 15.4 |

Plan target was ≤ 25 % with the sky open. **Worst case is 14.0 %**, achieved without a roof —
the truss grid and clerestory do most of the occluding that the roof would have.

Determinant census: **0 mirrored** of 739 (finding 0009 guard). Every placement uses
`CFrame.lookAt`; `CFrame.fromMatrix` was never called.

Kit clones verified at **×2.0** by measurement, not assumption: `Ind_Tank` source 6×12×6 →
placed 13×24×13.

## Bugs found in my own work, and fixed

1. **The first "pipes" were box Parts** — not pipes at all. Now `Shape = Cylinder`, axis along the
   facet, which falls out of `CFrame.lookAt(pos, pos - N)` putting local X in the wall plane.
2. **The first vent facet's fan cage** was built with a malformed CFrame expression and rendered as
   a flat starburst. Cage bars now spin about local Z (out of the wall) via `CFrame.Angles(0,0,θ)`.
3. **The first vent ducts were invisible behind their own ribs** — ribs were as large as the duct
   and darker. Ribs thinned to 2.2 at a 19-stud pitch, duct body lightened to `#4A545E`.

## Assets generated — 90 credits, exactly as budgeted

| File | Task | Credits |
|---|---|--:|
| `assets/generated/backdrop/vent_duct_v1.glb` + 5 PBR maps | preview + PBR refine | 20 + 10 |
| `assets/generated/backdrop/cable_bundle_v1.glb` + 5 PBR maps | preview + PBR refine | 20 + 10 |
| `assets/generated/backdrop/machine_column_v1.glb` + 5 PBR maps | preview + PBR refine | 20 + 10 |

⚠️ The first vent prompt failed with `image_too_complex` and was **charged 0**; it succeeded on a
simplified prompt. Lesson for future Meshy prompts: one object, few features.
⚠️ `.gitignore` excludes `*.glb`, so these exist **on disk only**.

## Still to do

- [ ] **Human step: import the 3 GLBs** via Studio's 3D Importer, then security-scan and log to the
      shared registry. Nothing in the backdrop uses them yet — it is all primitives and kit clones.
- [ ] **Play verification.** Every number and screenshot above is **Edit**. Proof rows 1, 2, 6 and 7
      in §7 require Play and have not been run.
- [ ] **Low-tier pass** with `decorativeLightRange = 10`. 155 of 739 backdrop parts are Neon, which
      is the tier-proof lighting, but this has not been measured.
- [ ] **Move the backdrop out of `workspace.__MassingTest`** into `Hub.Room.Backdrop`. It is still
      sitting in the throwaway folder it was massed in.
- [ ] **Export to `Config/WorkshopLayout.luau`** — decision 0019. Not yet done, so this build is
      currently unreviewable and lives only in the `.rbxl`.
- [ ] **Decide the roof.** A *glazed* roof — dark structure with glowing panels — would take the
      worst view from 14.0 % to ~0 and add light rather than remove it. Not built; the owner removed
      the solid one and has not seen this version.
- [ ] **Finding 0011 needs a decision**, not a stopgap: daylight hall (ClockTime ~15–16.5) or night
      factory (late band + committed artificial lighting). Bootstrap's warning must then be edited
      to match, or it will keep flagging the correct value.

## Part budget

**3,329 total** (room 2,590 + backdrop 739) against `MAX_PARTS_IN_VIEW = 1800` — **185 %**.
The owner chose full detail with the projection in front of them. Same posture as finding 0005: the
honest next step is a real-device reading, not a number argument.

---

# BUILD LOG 2 — meshes placed, 2026-09-06

## Staging first, then placement

The owner's standing rule was applied: **every new object stands in the DemoRoom for approval before
it enters the world.** All three imports were staged in `workspace.DemoRoom.12_BackdropStaging`
(clear deck at `z = -262`), each beside a cyan **5.5-stud player-height post**, and only placed after
the owner approved them.

| Piece | Staged size | Scale | Verdict |
|---|--:|--:|---|
| `vent_duct_v1` | 30 × 18 × 21 | ×16 | ribbed duct, bolted flanges, hazard stripe in the mouth |
| `cable_bundle_v1` | 34 × 17 × 7 | ×18 | glossy black loops + chrome banded collars — matches `_wall_pipes.png` |
| `machine_column_v1` | 15 × 40 × 21 | ×21 | chrome drum stack, black collars, hazard bands, corner frame |

**Security scan: 0 `LuaSourceContainer`s** across all three (GLB cannot carry scripts, but the rule
is scan-everything and the check reports a count, so it could have failed).

**Normalised originals archived** to `ServerStorage.ImportedMeshes` alongside the existing 44;
everything placed is a scaled *clone*, matching the convention for every other mesh in the game.

## Placed

| Piece | Where | Count |
|---|---|--:|
| `machine_column_v1` | standing in the three recessed bays (facets 5, 7, 11) | 3 |
| `vent_duct_v1` | **tiled into 88-stud runs** on the vent facets (2, 6, 11), 3 segments + 4 joint collars each | 9 |
| `cable_bundle_v1` | hung on the cable facets (3, 8), two gauges each | 4 |

⚠️ **A single mesh is a module, not a run.** The first placement dropped one 30-stud duct into a band
where the primitive run had been 118 — leaving gaps either side that read as a mistake. Fixed by
tiling at a **29.5 pitch on a 30.4-long mesh** (deliberate overlap, no seam) with dark collar rings
over each joint so the tiling reads as flanges.

**Orientation is measured, not assumed.** Each placement measures its own world extent along the
facet tangent vs the facet normal, and **auto-yaws 90° if the long axis is poking into the room**.
All three columns triggered it; the ducts and cables did not. This is the same class of bug as
job 019's bounding-box lesson: the mesh's local axes are not knowable from its name.

`CollisionFidelity = Box` on every placed MeshPart — the whole backdrop is `CanCollide = false`, so
the cheapest hull is the correct one. This is the **opposite** of the usual advice in
PITFALLS #21, and deliberately so.

## The bays were a dark hole — fixed

Looking through the bar wall showed vague shapes in blackness, which defeats the point of a
see-through facet. Added a **bay lighting layer** (117 parts, `L6_baylight`): a bright `Neon`
"beyond" panel with silhouette bars and machine shapes across it so it reads as *depth* rather than
a light box, bay ceiling strips, an amber floor wash, hazard kerbs, and cyan rim lights on the bay
returns. Facets 5, 7 and 11 now read as openings into a lit hall.

## Final state

| Layer | parts |
|---|--:|
| L1 collar + L2 main backdrop | 21 |
| L3 emissive (clerestory, strips, accents) | 108 |
| L4 overhead (truss grid + 25 lamp gantries) | 106 |
| L1 facet bands ×12, five types | 476 |
| L5 Meshy meshes | 28 |
| L6 bay lighting | 117 |
| **Backdrop total** | **856** — 185 Neon, 16 MeshParts |
| Room | 2,590 |
| **In place** | **3,446** vs `MAX_PARTS_IN_VIEW` 1800 (191 %) |

**Sky-fan, unchanged from the previous measurement** (the meshes add detail, not occlusion):
across the room **44.7 % → 14.0 %**, plaza **37.5 % → 0.0 %**, arena edge **41.0 % → 4.5 %**,
spawn west **43.4 % → 12.3 %**.

**Determinant census: 0 mirrored of 856.**

---

# PLAY PASS — 2026-09-06

Studio Play, one client, then stopped. Everything below is from the running game, not Edit.

## What passed

| Check | Result |
|---|---|
| Does the backdrop replicate under streaming? | ✅ **client sees 856 of 856** — no piecewise horizon |
| Sky-fan in Play vs Edit | ✅ **identical**: 14.0 / 0.0 / 4.5 / 12.3 / 0.0 — the Edit geometry measurement was sound |
| Sky-fan **with a glazed roof** | ✅ **0.0 / 0.0 / 0.5 / 0.1** |
| Determinant census | ✅ 0 mirrored of 856 |
| Station wiring after the build | ✅ `stations: 18/18 prompts attached`, `fatal 0` |
| The wall at close range (plaza, 130 studs) | ✅ reads exactly as intended — duct, fan, machine faces, clerestory, zero sky |
| Play-time changes leaking into Edit | ✅ none; the roof test was Play-only and is gone |

## What failed, and it is a *verification* failure

🔴 **[Finding 0012](../../findings/0012-the-sky-fan-measures-occlusion-not-appea.md) — the sky-fan
passed while the view failed.** At 0.0 % sky the screenshot still showed a wide pale band across the
horizon that reads as sky. An elevation sweep proved **nothing is sky**: 0–2° hits the far Arena at
404 studs, 3–5° the backdrop pipes at 440, 6–12° the main wall and clerestory at 462–468. The band
is the far side of the room **hazed to the same value as the sky**.

The metric answers *"is there a hole?"*. The owner's complaint was *"it reads flat"*, which is about
**value contrast**. This is the Tide failure's shape — measuring what is easy to measure rather than
what was reported — and it is the most important thing this Play pass found.

Cause: the style skill's `Atmosphere Density 0.32 / Haze 1.4` is authored for 60–120-stud
**corridors**. This room is **489 across**, so the far wall sits at 450+ and fogs out. Tested both
ways: moving the haze colour toward the sky **lifted the wall out of black**; dropping density
0.32 → 0.11 gained **only a little**. Under a bright daylight skybox the far wall lands at sky value
whichever way it is pushed — which is [finding 0011](../../findings/0011-bootstrap-wants-a-clocktime-band-whose-t.md)
showing up visually.

## Frame rate could not be measured, and the tier system was fooled by that

`[C][Quality] frame time 66.7ms -> tier Low`. Measured directly: **14.9 fps**. But an A/B that could
have failed says it is not real load:

| | fps |
|---|--:|
| everything on | 14.9 |
| **entire backdrop removed** | **15.0** |
| shadows off | 15.0 |
| post-processing off | 14.9 |

Removing 856 parts changed nothing, and every reading lands on exactly 15. **Studio throttles the
Play viewport to ~15 fps when its window is not focused.** So:

- No performance conclusion can be drawn from this session. Finding 0005's "needs a real-device
  reading" still stands, now for the backdrop too.
- ⚠️ **`QualityController` picked `Low` from a throttled reading.** Any tier decision measured in an
  unfocused Studio window will be wrong. Worth a guard, or at least awareness.

Silver lining: it gave a free **Low-tier** pass. At Low, `MaterialVariant`s are stripped (0 applied),
`ColorCorrection`/`SunRays`/`DepthOfField` are off (Bloom only), and **all 150 lights clamp to ≤10
studs**. The wall still reads at close range, because it is carried by `Neon` + Bloom exactly as the
plan required.

## A bug in my own work

🔴 **My `Hero` attributes were on the wrong instance.** `QualityController.local.luau:124` checks
`d:GetAttribute("Hero")` on the **`Light`**; I set it on the parent glow `Part`. All 34 did nothing.

The correct fix is **not** to move them — a backdrop lamp *should* be clamped on Low, and the tier
system giving it 10 studs on Low and full range on High is exactly the wanted behaviour. So the 34
stray attributes were **removed** (verified 0 remaining in Edit) rather than relocated, so nobody
later reads them as an exemption that exists.

## Still to do

- [ ] **Decide the roof.** Measured: it takes the worst view from 14.0 % to **0.0 %**, and the glazed
      version adds light instead of removing it. Built and photographed in Play; **not** in Edit.
- [ ] **Findings 0011 + 0012 are the same decision.** Daylight hall or night factory, then set
      Atmosphere per-space rather than one global, and edit Bootstrap's warning to match.
- [ ] Move the backdrop out of `workspace.__MassingTest` into `Hub.Room.Backdrop`.
- [ ] Export to `Config/WorkshopLayout.luau` (decision 0019). Still only in the `.rbxl`.
- [ ] Real-device perf reading — unavailable from here, for the reason above.

---

# GLAZED ROOF + DIM PASS — 2026-09-06

The owner saw the glazed roof in Play and chose it (*"i like how it is right now (roof)"*), so it is
now built for real in Edit: **168 parts, 49 glowing panes at Y=150**, dark deck grid around each pane
(the only shadow casters, which is what keeps the floor lit), deep beams at 137.5–148.5 below the
glazing, and a skirt closing wall-top 130 → roof 150.

| sky %, Edit, roof real | |
|---|--:|
| at a base → across the room | **0.0** |
| plaza → outward | **0.0** |
| arena edge → outward | **0.5** |
| spawn → west | **0.1** |
| room centre → straight up | **0.0** |

Clearance verified by ray: first thing above the Arena rig (Y=93) is a lamp glow at **Y=110** — 17
studs clear. Beams sit at 137.5, above the cross trusses' 133.

**Then: "lights are little bit toooo much, can you decrease them like 50%".** Done —
**234 Neon parts** halved and **46 PointLights** halved. A Neon part's emission *is* its `Color`, so
halving the colour halves the light it throws.

⚠️ Every original is stored on the part as a **`NeonBase` / `BrightBase` attribute**, so this is
exactly reversible and re-tunable to any factor without rebuilding. Do not hand-edit the colours —
re-scale from the attribute, or two passes will compound.

**Totals: backdrop 1,024 parts (234 Neon) + room 2,590 = 3,614 in place.**
