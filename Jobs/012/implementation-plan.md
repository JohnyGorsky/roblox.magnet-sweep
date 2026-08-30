# Job #012 — implementation plan

**Project**: `roblox.magnet-sweep` · **Drafted**: 2026-08-30

## The constraint that decides the whole shape of this job

`Workspace` **does not sync** ([job 002](../002/final-summary.md)). Geometry built by hand in Studio
exists only inside the unversioned `.rbxl`: it cannot be diffed, reviewed, regenerated after a
material change, or recovered if the file is lost.

[Decision 0017](../../docs/decisions/0017-the-kit-is-generated-from-a-spec.md) already answered this
for the industrial kit, and it answers it here too — **the Workshop is data.** A `WorkshopSpec` in
git describes the room; a builder realises it. There is no hand-placement step and no "nudge it in
Studio" (a nudged part is overwritten on the next build; the fix goes in the spec).

> This deliberately diverges from how Jungle's lobby is built, where objects are hand-placed and
> scripts find them by name. That is the right call there and the wrong one here, and the reason is
> the sync layout, not taste.

## What exists to build from

24 kit pieces / 83 parts, already generated and tiling-verified ([job 005](../005/final-summary.md)),
on a **4-stud grid** — tile 8, wall height 12. The ones this job leans on:

| Need | Piece |
|---|---|
| Floor | `Floor_Plain` · `Floor_Grated` · `Floor_Hazard` |
| Enclosure | `Wall_Solid` · `Wall_Window` (the Arena sightline) · `Wall_Machine` |
| Structure | `Struct_Pillar` · `Struct_Corner` · `Struct_Gate` (Factory Entrance) · `Struct_Platform` (plinths) |
| Station dressing | `Ind_ControlPanel` · `Ind_Generator` · `Ind_Tank` · `Prop_RobotArm` |
| **Signage** | **`Sign_NeonSlab`** — one per station, seven of them |
| Hazard | `Prop_Beacon` · `Prop_Crate` |

## The seven stations (spec §8)

Each gets a plinth, a neon slab sign in **its own signal colour**, and a matching `PointLight`.

| Station | Sign colour | Why that colour |
|---|---|---|
| 🧲 MAGNET LAB | magnet cyan `#41D8FF` | it is the magnet |
| ♻ RECYCLER | recycler green `#3FD64B` | green means *recycle / coins in*, and nothing else |
| 🔧 REPAIR | weld orange `#FF7A1A` | orange means *repair / robot HP*, and nothing else |
| 🤖 ROBOT BAY | chrome `#B8C2CC` | deliberately neutral — the robot is not a signal |
| ⚔️ SCRAP ARENA | crown gold `#FFC21A` | gold is Arena control |
| 🏆 PART ARCHIVE | violet `#C46BFF` | the rarity ramp's own colour |
| 🚪 FACTORY ENTRANCE | signal red `#E03A2F` | danger, and the only way out of the safe hub |

⚠️ **A station sign may not borrow another station's colour**, and a kit piece may not wear a signal
colour at all ([PITFALLS #39](../../docs/PITFALLS.md#39-the-colour-language-decays-one-green-pipe-at-a-time)). `WorkshopSpec.validate()` enforces both.

## Files

| File | What |
|---|---|
| `ReplicatedStorage/Workshop/WorkshopSpec.luau` | The room as data: floor plan on the grid, wall runs, the seven stations, the spawn, the Arena aperture |
| `ReplicatedStorage/Workshop/WorkshopBuilder.luau` | Realises it into `Workspace`. Idempotent, like `KitBuilder.buildAll` |
| `ServerScriptService/WorkshopService.luau` | Builds at server start; owns the spawn |
| `ServerScriptService/Bootstrap.server.luau` | One call + the audit lines |

## Verification — and what failure looks like

Nothing here is verifiable in Edit. Almost nothing in this game exists in an Edit session, and the
Workshop's lighting, signage glow and post chain are all runtime.

| Check | Passes when | **Fails when** |
|---|---|---|
| `validate()` | Zero problems | A sign wears another station's colour · a kit piece wears a signal colour · two stations overlap · a footprint is off the 4-stud grid |
| Idempotence | Building twice leaves the same part count | The second build duplicates or orphans geometry |
| **Arena sightline** | A raycast from the spawn to the Arena anchor is **unobstructed**, measured | It hits a wall — decision 0001's whole justification is that the Arena is visible from here |
| Signage | Seven signs, seven distinct colours, each with a light | Six lights and nobody notices |
| Shadow budget | ≤ 8 shadow-casting lights visible at once, **counted** | Every sign light casts shadows |
| **Draw calls + frame time** | Measured and recorded in the Workshop with full signage | Not measured — `systems/performance` names this an open question that must be answered *before the Workshop is signed off* |
| Screenshots | Read as images, from the player's camera in Play | Reported from numbers alone |

## Independent review

Given the requirement and the repo, never my theory (GROUND-RULES 8).

## Out of scope — this is job 013

Making the stations *do* anything: the Magnet Lab terminal (the upgrade panel from job 011 already
exists and works — this is only the world object that opens it), the Recycler transaction
(`RequestRecycle` is still unbound), the Repair Station, the Robot Bay's contents, the Part Archive
wall's data, and the MOVE NEAR SCRAP first-time prompt.

**Group 05 is 18 items.** The job ladder's own sizing rule says a row that starts feeling like two
things *is* two things, and it cites group 04 — planned as one job, actually run as three — as the
precedent. Splitting at the line between "the room exists" and "the room works" is the cheapest
place to cut it.
