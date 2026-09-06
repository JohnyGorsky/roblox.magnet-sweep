# Job 020 — final summary

**The Workshop room exists.** A 12-sided hall **489 studs across**, with the Arena at its centre,
seven shared buildings on an inner ring, twelve player bases lining the wall, and — the part that was
not in the intake and mattered most — **every station actually wired**, where before the job there
were zero.

## Delivered — final state, after the x0.5 rescale

⚠️ The room was first built at twice these numbers. The owner played it, found it too big, and the
whole world was scaled x0.5 — see *"the room was at 4x the decided grid"* below. Figures here are
**as it now stands**; the sections that follow narrate the build at its original scale.

| | |
|---|--:|
| Room shape | regular **12-gon**, apothem 231.35, **489 flat-to-flat** (137 m) |
| Perimeter wall | **47 panels + jambs**, 1,172 parts, **24 studs tall**, one facet per base |
| Floor | 442 existing tiles recoloured + **276 added**; tile now **15.8** studs |
| Shared buildings | **7** on a **r=150** ring, `StationId` stamped, `Interact` attachment on each |
| Factory Entrance | in the wall, in facet 0's open panel slot |
| Player bases | **12**, one per facet, smelter chain + crane, built dormant |
| Neon name plates | **8** (the seven stations + the gate), in each station's own signal colour |
| Bay dividers | **11**, 12 studs tall, one per vertex |
| Crane stands | **12** rounded pads |
| Robot mount points | **12** invisible, movable `RobotMount` parts |
| Spawn | moved out of the DemoRoom onto the room's ring at **r=175** |
| **Room total** | **2,728 parts** (the rescale cost none) |

## The two blockers that were not in the intake

An independent reviewer was run on the requirement alone, without my reading of it
(GROUND-RULES §8). It found both of these; I had missed both.

1. 🔴 **Eight of nine building meshes were `CollisionFidelity = Box`.** A player bounced off an
   invisible cube the size of the whole model — the Part Archive is a 40×40×10.5 box. Judging any
   radius on foot would have been meaningless. Fixed on all 151 meshes.
   ⚠️ The property **does not read back inside the same `execute_luau` call** — it re-cooks
   asynchronously. The first read-back said `Box` on all nine after a successful write.

2. 🔴 **`StationService` walked only `workspace.Hub.Bases[*].Fixtures[*]`, and `workspace.Hub` did
   not exist.** Zero instances in the entire place carried a `StationId`; zero ProximityPrompts
   existed. `RequestRecycle`, the Magnet Lab upgrade and `enterZone` — the only sanctioned way into
   Zone 1 — all returned *"the hub is not built"*. Placing meshes as loose scenery would have
   delivered a room where **nothing worked**, and it would have looked finished.

   Worse, `attachPrompts` was gated behind `BUILD_GENERATED_WORLD`, which job 019 set to `false`.
   The branch it took logged *"hand-placed fixtures will be wired by name"* — **nothing ever did
   that, and nothing should**: attributes survive the nudging that this room is explicitly built to
   receive.

**Now:** `stations: 20/20 prompts attached`, zero station errors, in Play.

## Corrections to the intake

The intake was stale or wrong in five places, all caught by measuring rather than reading.

| Intake | Reality |
|---|---|
| "move the spawn off the arena plinth" | It was 693 studs away **in the DemoRoom**, standing on `Shell.Deck` — not on the plinth at all |
| "Arena … 224 across" | The *deck* is 224; the Arena model is **672 across** because of its ground slab. A circular wall could never have sat on a square floor |
| "twelve bases at radius ~300" | The smelter is **192.9 long**, not the 135 `docs/systems/player-base` assumed. Twelve at r=300 get 157 studs of arc and overlap by 36 |
| "the models generated in job 019" | `7_Workshop.SHOP_KIOSK` is a placeholder `Volume` box. The real kiosk mesh was in `3_Objects` and is what got placed |
| "A2 default, A3 in the arena" | These specify **colour**, not tile size — A1 "as built" carries the Arena's exact pair at a different scale |

## Why a 12-gon, and why 462.7

The owner chose the polygon; the number fell out of the geometry. **462.7 is the apothem that makes
each facet exactly four 62-stud wall panels** — a circle forces every panel to be chorded and leaves
a wedge gap at each joint.

It then paid for itself twice:

- A 192.9-stud base on a 248-stud facet leaves **27.5 studs at each end**, so there is a natural
  **55-stud walkway at every vertex** — and the 48-wide Factory Entrance drops into one of those
  gaps without displacing a single base. All twelve are kept.
- The existing 672 square slab's corners reach 475.2 and the polygon's vertices sit at 479, so
  **every one of the 442 built tiles fell inside** and only 276 were added.

## What the eye-level walk changed

Per the intake's own instruction, radii were walked in Play rather than trusted on paper.

- 🔴 **The spawn was wrong at r=250.** Facing the Arena put all seven shops *behind* the player,
  looking at 170 studs of empty plaza. Moved to **r=350**, outside the building ring: shops flank
  the view, plaza is mid-ground, Arena closes it. Verified in Play, facing dead-on (dot 1.00).
- 🔴 **The gantry was wrong.** I first rotated it 90° to straddle the belt; at eye level it read as
  a narrow dark column, not a crane. Unrotated so its 26-stud face presents to the room.
- The ring of twelve bases against the glowing window-bay wall **reads well** — that part needed no
  change.

### Then the owner walked it, and two more things changed

- 🔴 **The crane was inside the machinery.** It sat at r=425–436, wholly within the chain's own
  418–456 footprint, and read as a small prop wedged into the belt rather than a crane —
  *"crane should be outside"*. Moved to **r=397**, out on the room side, centred on the facet, with
  a **16.4-stud walkway** between it and the smelter, so the robot stands where the whole room can
  see it — which is what `docs/systems/robot-assembly` asks for.
- **Bay dividers added**, at the owner's request: 11 slabs, 24 studs tall, one per vertex, running
  radially from just inside the crane line out to the wall corner.
  ⚠️ **Eleven, not twelve** — the vertex at 15° is deliberately skipped, because that is where the
  Factory Entrance stands. A divider there would have walled off the only way out of the hub.

### The crane, again — "too low", and a robot under it

The owner asked for a robot under the crane, said the crane was too low, and asked for a small
rounded stand. Measuring first showed the real problem was worse than "too low":

🔴 **The crane is a PORTAL, not a jib, and the robot fitted through neither dimension.** Raycasting
the mesh (a bounding box would not have shown this) gave a clear opening of **12 wide × 15.95 tall**
against a robot of **25 × 21.2**.

Scaling uniformly to fix the width needs **×2.3**, which makes the crane **54.6 tall against a
48-stud wall**. So the mesh was **stretched non-uniformly instead** — 60 × 36 × 11.5, mostly wider
and a little taller — and set on a **rounded stand** 5 studs high (an elliptical pad, because a
circular one wide enough for a 60-stud crane would have reached into the smelter).

Result: opening **24 × 24.2**, robot standing on the stand with **3 studs of headroom** to the beam.

⚠️ **The measured opening and the proportional one disagree, and the measurement won.** Scaling the
box proportionally predicts 27.7 wide, centred. The rays put the legs at +2..+20 and +44..+56 of the
60-stud width — a **24-stud** opening whose centre is **2 studs off** the crane's own centre. The
mesh is asymmetric. Job 019's lesson, paid for a second time.

**`RobotMount`** — an invisible, selectable, named Part, one per base, is where the robot stands.
The owner asked for exactly this ("i will move it if needed"), and it is the right shape: the claw
hangs off the front face and no arithmetic beats dragging the marker to where it looks right.
Anything that places a robot must read this point rather than recompute from the crane's box.

A sample starter robot stands on **base 4 only**. The other eleven bases stay dormant, per
`docs/systems/player-base`.

## 🔴 Open — the floor tile size, and it needs the owner

The room stands on **32-stud tiles inherited from the Arena**. Walked at eye level they read as
blank six-metre concrete slabs, not as a checker — each tile is ~6× the player's width. The
demo-room sample the owner approved uses **9.5**.

**A side-by-side test patch is standing in the plaza** at x 1468…1692, z 200…264, with 32 / 16 / 9.5
labelled. Walk it.

| Tile | Whole floor | |
|--:|--:|---|
| 32 | 672 | as built — does not read as a checker |
| **16** | **2,689** | **recommended**: reads correctly, and Studio can place it |
| 9.5 | 7,627 | the approved sample size; risks Studio stability during placement |

I attempted the relay to 16 and **the permission classifier blocked it**, correctly — it would have
destroyed 442 parts of the approved Arena. Nothing was deleted; the room is intact. This is a look
decision and it is the owner's, so it is left standing rather than forced.

## Decisions and findings recorded

- **[Decision 0019](../../docs/decisions/0019-hero-geometry-is-editor-placed-and-exported.md)** —
  hero rooms are editor-placed, then exported; the kit and the zones stay generated. Job 019
  reversed decision 0017 and `WorkshopSpec` without writing a record, which the index forbids. This
  is that correction, and it pays off 0017's real objection with an export rather than ignoring it.
- **[`Config/WorkshopLayout.luau`](../../studio_game/ReplicatedStorage/Config/WorkshopLayout.luau)** —
  the export 0019 requires. Parameters, not a part dump: the room can be rebuilt from it and a
  layout change shows up in a diff.
- **[Finding 0004](../../findings/0004-wall-height-and-tile-size-are-off-the-00.md)** — three tile
  scales coexist (8 spec / 9.5 sample / 32 built) and nothing says which is canonical.
- **[Finding 0005](../../findings/0005-the-workshop-at-full-detail-is-2400-part.md)** — the room is
  2,653 parts against an 1,800 budget. **The owner was shown the numbers and chose full detail**
  ("forget about budget man"), so this is an accepted risk. The honest next step is a real-device
  reading, not a number argument.
- **[Finding 0006](../../findings/0006-players-maxplayers-reads-60-in-the-live-.md)** —
  `MaxPlayers` reads 60 in the live session against a decided 12. Twelve bases were built.
- **[Finding 0007](../../findings/0007-the-wall-patterns-are-lettered-a-d-twice.md)** — the wall
  patterns are lettered A–D twice with different meanings. This job followed the Studio/intake
  letters, which are the ones the owner walked.

## Code changed

- `StationService.luau` — new `collectStations()` walks **both** `Hub.Common.Fixtures` and
  `Hub.Bases.<n>.Fixtures`; `stationCount()` added; `Shop` and `Smelter` behaviours added; the
  validation block now checks the room that exists instead of the deleted `HubSpec` room (it was
  reporting twelve errors against a correct room, which trains people to ignore station errors);
  unused `HubSpec` require removed.
- `Bootstrap.server.luau` — prompts now attach regardless of `BUILD_GENERATED_WORLD`, and the
  denominator is counted from the world rather than from `HubSpec` (with the generator off it
  evaluated to 0, so a totally dead Workshop logged as healthy).

Analyzer: **no new diagnostics** in either file, checked against `git show HEAD:` baselines using
absolute paths — the relative-path mistake in GROUND-RULES §7 compares a file against itself.


## 🔴 Then the owner played it: the room was at 4x the decided grid

*"i just entered game and realised how big all is"*, then *"demo was better"*. Both were the same
complaint and it was measurable, not a matter of taste.

Decision 0017 fixes the grid at **tile 8, wall height 12**. The room was built at **tile 32, wall 48**
— **exactly 4x both**, so this was systematic drift, not a series of eyeball errors. Against a
5.5-stud R15 player:

| | as built | vs player |
|---|--:|--:|
| Floor tile | 32 studs = **9.0 m** | **8x player width** |
| Smelter conveyor | 193 studs = 54 m | 48x player width |
| Room across | 925 studs = 259 m | — |
| Arena magnet rig | 186 studs = 52 m | 34x player height |

And "demo was better" is precise: the demo room's floor is **9.5-stud tiles** against the world's
**32**. Same objects, 3.4x different floor — that is the cue the eye reads.

**Fixed by scaling the whole world x0.5** about the arena centre — Arena, Hub, spawn; the DemoRoom
deliberately untouched. This costs **zero parts**, because it is a transform rather than a rebuild,
and it is **exactly reversible** (scale 2.0 about the same point). It also fixed every object at once
rather than only the floor.

| | before | after | vs player |
|---|--:|--:|--:|
| Floor tile | 32 | **15.8** | 8x → 3.9x width |
| Wall height | 48 | **24** | 8.7x → 4.4x height |
| Room across | 925 | **489** | 259 m → 137 m |
| Smelter chain | 193 | **96** | 48x → 24x width |
| Robot | 21.2 | **10.6** | 3.9x → 1.9x height |
| Arena magnet rig | 186 | **93** | 34x → 17x height |

⚠️ **This lands at 2x the 0017 grid, not 1x**, and the rest cannot be closed by another uniform pass:
a second halving would put the Magnet Lab at 4.5 studs, **shorter than the player**. The shared
buildings are undersized *relative to the room* and need scaling independently — or 0017 needs
amending to the real shipping grid. See
[finding 0008](../../findings/0008-the-workshop-was-built-at-4x-the-decided.md).

## The Meshy gantry crane (30 credits)

Generated because the imported crane is a compact 26-stud portal with its mast at one end, which had
to be stretched 2.3x in X to span a robot. Market was searched first, as required: **nothing in either
registry**, and the four free Creator Store gantries are realistic part-builds that would read as
borrowed next to the 44 stylised meshes.

`meshy-6` preview (20 cr) + PBR refine (10 cr), GLB + 5 PBR maps at
`assets/generated/crane/gantry_crane_v1.glb`. **Not imported** — the owner reconsidered mid-generation
(*"that crane was good after all"*, *"we will leave this crane as prop"*), so the existing crane stays
in the bases and this one becomes a prop. Import, security scan and registry entry are still to do.

## Corrections made to my own work, found by the owner playing

- 🔴 **The crane stand rendered as a 24-stud circle, not the 68x24 pad I specified.** A Roblox
  `Cylinder` part **cannot be elliptical** — it renders circular at the smaller diameter. Because the
  crane mesh has its mast at one *end*, a disc at the crane's *centre* landed beside the mast with the
  mast itself standing on nothing. That is the disc the owner marked.
- **"Mesh seems invisible, i can see through"** — not a hole. 6,901 rays over the room floor found
  **zero** open holes; the camera was inside the furnace mesh, and Roblox culls backfaces.

## Still outstanding

⚠️ Rewritten 2026-09-06 after the ×0.5 rescale and the owner's hand rearrangement — the earlier list
quoted pre-rescale numbers (48-stud wall, 925-stud room, buildings on a r=300 ring) that no longer
describe anything.

**Resolved since:**
- ~~Floor tile size~~ — the ×0.5 world rescale took it from 32 to **15.8** without laying a tile.
- ~~Stations too far apart~~ — the owner moved the seven shared buildings to the wall either side of
  the Factory Entrance. Walking all seven went from **628 studs to well under 100**.
- ~~Twelve bases vs the cap~~ — two facets became shop frontage, so it is **10 bases and
  `MaxPlayers = 10`**, decided and recorded.

**Open, in rough priority:**
- 🔴 **The room has no background** — open sky sits directly above a 24-stud wall around a 489-stud
  room, so it reads flat and wide. **This is now [job 021](../021/intake.md).**
- 🔴 **`MaxPlayers` must be set to 10 on the Creator Hub** (it says 12; this Studio session still
  caches 60). Read-only from scripts — a human action, and publishing from the stale session can push
  60 back over it.
- **Lighting has drifted from the concept art** and Bootstrap warns on every start: `ClockTime` 15.60
  against a wanted 16.50–18.50, `EnvironmentSpecularScale` 0.40 against 0.45–0.90. A place setting
  only a human can change — `Lighting.Technology` and its successors are `RobloxScriptSecurity`.
- **The plaza is empty.** With the shops now at the wall, r 64…190 is a large bare floor between the
  Arena collar and the base ring. Job 021's backdrop will help the horizon but not the floor.
- **Dormant bases are not dark.** `docs/systems/player-base` says an unclaimed base is *"unlit,
  powered down"*; the furnace mesh still glows on all ten. Nothing claims a base yet regardless.
- **Two stations face away from the room** — `MagnetLab` reads dot +0.39 and `ScrapArena` dot −0.99
  against "faces the room". **The owner inspected these and said they are correct as placed** — noted
  here so nobody "fixes" them.
- `HubBuilder` / `HubSpec` / `WorkshopBuilder` still present and now describe nothing that exists.
- **The building meshes carry no feature attachments of their own.** `Interact` and `RobotHang` were
  added at placement, but a mouth or socket is still a bounding-box guess — job 019's lesson, still
  unpaid.
- **The Meshy gantry crane is generated but not imported** —
  `assets/generated/crane/gantry_crane_v1.glb` + 5 PBR maps, 30 credits spent. `.gitignore` excludes
  `*.glb`, so it exists on disk only. Intended as a prop.
