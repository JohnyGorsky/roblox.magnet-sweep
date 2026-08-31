# Job #012 — final summary

**Project**: `roblox.magnet-sweep`
**Status**: the Workshop **room** is built, lit and verified in Play. Stations are scenery until job 013.

Build group 05's physical half. The Workshop is the central safe hub (spec §8) and the proof of
[decision 0001](../../docs/decisions/0001-one-place-not-two.md) — the Arena has to be visible from
it, which is the entire reason this game is one place instead of two.

---

## The constraint that decided the shape of the job

`Workspace` **does not sync** ([job 002](../002/final-summary.md)). A room built by hand in Studio
lives only in the unversioned `.rbxl`: not diffable, not reviewable, not regenerable after a material
change, and gone with the file. [Decision 0017](../../docs/decisions/0017-the-kit-is-generated-from-a-spec.md)
had already answered this for the kit, so the Workshop follows it: `WorkshopSpec` is the room as data,
`WorkshopBuilder` realises it.

**The cost that decision did not weigh, and the owner named immediately: you cannot see it.** A hub a
human has to art-direct that cannot be looked at or selected without pressing Play is a real problem.
The answer is to materialise it into the editor on command — which works, and then goes stale, because
Studio caches required modules for a whole Edit session. Written up as
[PITFALLS #61](../../docs/PITFALLS.md#61-a-generated-world-is-invisible-in-the-editor-and-the-editors-copy-goes-stale).

## What was built

| | |
|---|---|
| `ReplicatedStorage/Workshop/WorkshopSpec.luau` | The room as data — a 13 × 13 tile grid, seven stations with signal **and** housing colours, the lamp runs, the spawn, the Arena aperture, the anchor group 10 must build to, and a `validate()` |
| `ServerScriptService/WorkshopBuilder.luau` | Realises it. Rebuilds the kit first, places floor/shell/lamps/stations, dresses each machine and sign, resolves ground conflicts, samples the sightline |
| `Kit/KitSpec.luau` | **+2 pieces**: `Light_Gantry` (the hall lighting) and `Station_Machine` (the body of a station). `Sign_NeonSlab` rebuilt — see below |
| `ServerScriptService/Bootstrap.server.luau` | Builds at start, reports parts against the budget, asserts the lighting, registers `workshop.rebuild` |

## Measured in Play

| | |
|---|---|
| Workshop | **425 parts** — 24 % of the 1800-part in-view budget |
| Shadow-casting lights | **0** against a budget of 8 |
| Signs | 7, in 7 distinct colours, each lit, each labelled, **each with a clear line of sight from 22 studs** |
| Arena visible from | **56 % of the floor** (14 of 25 sample points), and unobstructed from the spawn |
| Idempotence | 3 consecutive rebuilds: workspace 785 → 785 → 785 parts |
| Live spawns | exactly 1 |
| Side effect | `lights clamped=35` — the quality-tier light cull that [#52](../../docs/PITFALLS.md#52-a-threshold-chosen-in-one-file-against-values-chosen-in-another) recorded as permanently inert now has real work to do |

---

## I built to a sentence instead of to the picture, and it was wrong

The style skill opens with *"a bright, glossy, slightly absurd toy factory **at night**"*. I read that
literally, set `ClockTime` to 1.5, and produced a black room. The owner's response was *"it totally
off"* and a pointer at `assets/concept_art/`.

**The painting that sentence describes is a brightly lit interior.** Light-grey concrete floor,
nothing in shadow, saturated colour on the machines, neon reading as *signage* rather than as the only
light source. "At night" describes the world outside the building.

I should have opened the reference before touching the lighting. Three things came out of it:

| | Was | Now |
|---|---|---|
| `ClockTime` | 14.5, then 1.5 (black) | **14** |
| `Ambient` | 20, 24, 34 | **70, 76, 90** — nothing in the room is black |
| `EnvironmentSpecularScale` | **1.00** | **0.30** |

That last one is the one worth remembering: at 1.00 polished metal mirrors the sky, which blew the
grated walkway out to **pure white** while the floor read near-black. It looked like a texture bug and
was a lighting value.

`Lighting` does not sync, so none of this can live in git. Bootstrap now **asserts** it against ranges
read off the concept art and warns when the place drifts ([#33](../../docs/PITFALLS.md#33-place-settings-nobody-chose)).

## The stations were market stalls; they are machines now

The first version gave each station a raised `Struct_Platform` with a sign on poles behind it. The
concept art's stations are **wall-sized built machines** — a painted housing with a glowing recessed
face, flanked by coloured buttresses, on a hazard-striped plinth, with the sign mounted on top.

So `Station_Machine` was added to the kit, and each station now carries **two** colours: its `color`
(the signal colour, on the sign rim and the glowing face) and its `accent` (the painted housing).
`Color` multiplies the ColorMap, so a neutral variant takes any accent.

**`Sign_NeonSlab` was rebuilt too.** It was a solid neon slab with dark text — every sign rendered as a
flat rectangle of saturated colour. The concept art's signs are a **dark navy face carrying white text
inside a bright coloured rim**. The station colour belongs in the rim, where it identifies without
fighting the words.

---

## The ground was visibly broken, and my own summary said it was fine

The owner reported the floor as "glitchy". Measured: **the Baseplate's top and every floor tile's top
were both at exactly y = 0.000. Gap: 0.0000 studs.** Two coplanar surfaces give the GPU no way to
decide which is in front, so it picks differently per pixel and per frame.

An earlier draft of *this document* called that arrangement safe — *"it is not in the way (its top and
the floor's top are both y = 0)"* — which is precisely backwards. Coplanar is the worst case, not a
clearance. [PITFALLS #59](../../docs/PITFALLS.md#59-what-is-painted-now-and-where-the-controls-are-are-different-questions) neighbours it; the ground case is [#55–#58](../../docs/PITFALLS.md#55-a-disabled-screengui-reports-800--600-forever)'s family.

`resolveGroundConflicts` now lowers offenders clear of the floor — and immediately taught its own
lesson: **it moved `Workspace.Terrain`**, because `Terrain` inherits from `BasePart`. No damage (the
terrain is empty, 0 voxel cells, and `Position` reset clean) but `IsA("BasePart")` is a far wider net
than it reads as, and `SpawnLocation` is in it too.

## The independent review found 13, and 11 were real

Run per [GROUND-RULES 8](../../../roblox.workspace/GROUND-RULES.md) on the requirement alone. It
rebuilt the placement maths in a standalone model and reproduced the code's own numbers, so its
findings are measured rather than eyeballed.

| Finding | What it caught | Fix |
|---|---|---|
| **D1** | Two dressing pieces **land through the walls** every build — the Recycler's tank 60 studs³ inside a wall panel, the Robot Bay's platform cantilevered 12 studs outside the room on legs standing on nothing. The offset is rotated by `facing`, so "away from the wall" points *at* it for facing 90/180 | `validate()` now computes **where the piece actually lands** and bounds it against the room. The old check asked only whether each number divided by 4 — it measured divisibility, never meaning. It then caught **four more** offsets in my own replacement table, including a crate headed through the west wall |
| **D6** | The plinth stood **between the player and the sign on all seven stations**. From eye height the bottom of the panel only cleared the deck from 151 studs away — further than the room is wide | Gone with the plinth. Verified: all 7 signs have a clear line of sight from 22 studs |
| **D2/D3** | The sightline "passed by construction" — spawn, anchor and aperture all sit at z = 0, so the ray was aimed straight down the axis the gap was cut on. Review solved the real region: **29.5 %** of the floor, while the check said "clear" | Now **samples 25 points across the floor** and reports the fraction. It measured 32 %, agreeing with the review's maths. So the aperture was widened 3 → 7 tiles, and it now reads **56 %** — §8 asks for "visible from **much of** the Workshop", and 32 % was not that |
| **D3b** | The raycast **excluded Terrain** — the single most likely real occluder of a 256-stud outdoor sightline was the one thing filtered out | No longer excluded |
| **D4** | A blocked sightline was **only a log line**: `build()` returns a non-nil root on a check failure and Bootstrap only errored on nil. `workshop.rebuild` reported "idempotent: YES" while hiding every problem | Any problem is now fatal in Studio, and the dev command reports problems on success too |
| **D7** | The aperture pillars were placed at the **centre of the neighbouring wall tile** — 36 studs³ buried in wall, framing nothing | Placed at the gap's real edges |
| **D8** | Factory Entrance's gate and its sign were given the **same offset**, so both gate posts passed through the sign housing | Dressing reworked; beacons stand clear |
| **D10** | `resolveGroundConflicts` had a **guard that could never be false**, walked only top-level children, ignored a part poking *above* the floor, and used raw `Size` with no rotation | All four fixed; plus the `Terrain`/`SpawnLocation` exclusion I found myself |
| **D11** | **Nothing owned "there is one spawn."** The stock template ships a `SpawnLocation` inside this room and Roblox picks at random — so the player might never stand at the only point the sightline is gated on | Other spawns are disabled (not deleted — it is the user's place content) |
| **D9** | `signalColors()` was **dead code that made a constraint look policed**. And a real check cannot be written, because PITFALLS #39 and style §5 genuinely contradict each other on whether a kit piece may wear a signal colour | Deleted, and replaced with a written note naming the tension |
| **D5** | The "outside the room" bound first tripped at tile 7 — outside the wall loop's own range, so it could never fire | Calibrated to the wall minus the machine's depth |

Two more I found while fixing: the sign label went onto the **neon rim behind the dark face**, so all
seven signs read as black rectangles — and the check I wrote to verify it used `CFrame.LookVector`,
which is **-Z**, the same wrong axis as the bug, so it confirmed the fault. Working in the sign's own
object space removes the axis question entirely.

**Security / clean, per the review:** part budget real and checkable, zero shadow-casters, no raw
materials bypassing `MaterialKit`, rotation maths correct for all four facings, `PivotTo` handled per
[#22](../../docs/PITFALLS.md#22-pivotto-vs-primarypart), idempotence genuine, no hand-placement.

## What is **not** done

- **No station does anything** — job 013.
- **No ceiling.** The hall is open to the sky. The concept art is an enclosed interior; this is the
  largest remaining gap to it.
- **The floor is lighter than the reference** and there are no conveyor runs, floor arrows or ground
  crates. The concept's density is a look pass, not a blockout.
- **The aperture looks out at nothing** until group 10 builds the Arena at `ARENA_ANCHOR`.
- **The editor copy was removed** rather than left stale — see PITFALLS #61. Play always builds it
  fresh; to see it in the editor, reopen the place first, then
  `require(game.ServerScriptService.WorkshopBuilder).build()`. A `README_WORKSHOP` marker in Workspace
  says so.
