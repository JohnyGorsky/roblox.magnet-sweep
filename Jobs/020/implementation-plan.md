# Implementation Plan — Job #020: Build the Workshop room

**Project**: `roblox.magnet-sweep`
**Created**: 2026-09-06
**Status**: Agreed on the three owner decisions; building.

Owner decisions taken this session (via the wizard):

| Question | Answer |
|---|---|
| How to pay for the wall + output bay (room is 133 % of the part budget) | **"forget about budget man"** — build at full detail. Logged as [finding 0005](../../findings/0005-the-workshop-at-full-detail-is-2400-part.md) |
| Room shape (the arena floor is a 672 square, the wall was specified as a ring) | **12-sided polygon** |
| Where the spawn goes | **Common buildings ring**, facing the Arena |

Plus, mid-session: *"increase base if needed"* — the ring may grow past 760 studs across.
And: *"i will go to sleep, so keep building"*.

---

## What is actually there right now (measured over MCP, not assumed)

| | |
|---|---|
| `Workspace.Arena` | 692 parts, centred **(1556, 0, 0)** — disc r 115.5, collar r 126.5, magnet rig 186 tall |
| `Workspace.Arena.Ground` | a **672 × 672 square** checker slab: 441 tiles of **32 studs** + one slate underlay. Colours `#62626A` / `#6E6E76` |
| `Workspace.DemoRoom` | 933 parts, x −266…938 — the staging room, not part of the Workshop |
| `Workspace.SpawnLocation` | **(896, −1, 210)** — 693 studs from the arena centre, standing on `DemoRoom.Shell.Deck` |
| `workspace.Hub` | **nil**. 0 instances carry `StationId`; 0 ProximityPrompts exist anywhere |
| Building meshes | all 13 present in `ServerStorage.ImportedMeshes`, at unit scale |
| `Players.MaxPlayers` | **60** in this session, not the decided 12 — [finding 0006](../../findings/0006-players-maxplayers-reads-60-in-the-live-.md) |

**The Workshop room does not exist in any form.** This job creates it.

## Corrections to the intake

The intake is stale or wrong in five places. Building it as written would have produced a broken room.

1. **"Move the spawn point off the arena plinth."** It is not on the plinth. It is 693 studs away in
   the DemoRoom, which is 280 studs *outside* even the new ring. The real task is to bring it into the
   Workshop, not nudge it off a plinth.
2. **"Arena … 224 across."** The *deck* is 224; the Arena model is **672 across** because of its ground
   slab. A circular wall could not have sat on a square floor — which is what the 12-gon answer fixes.
3. **"Twelve player bases at radius ~300."** The smelter chain measures **193 studs long**. Twelve of
   those at r=300 get 157 studs of arc each and overlap by 36. Corrected below.
4. **"Using the models generated in job 019."** 8 of the 9 building meshes are
   `CollisionFidelity = Box` — a player bounces off an invisible cube the size of the whole model.
   Fixed as step 1, before anything is judged on foot.
5. **Floor patterns A2 / A3.** These specify **colour**, not tile size: A1 "as built" carries the
   arena's exact colours but is drawn with 9.5-stud tiles while the arena uses 32. So "A2 default,
   A3 in the arena" is a **recolour** of the 442 existing tiles plus an extension — not a rebuild.
   Three tile scales now exist in the repo — [finding 0004](../../findings/0004-wall-height-and-tile-size-are-off-the-00.md).

## The geometry

A regular **12-gon centred on the Arena at (1556, 0, 0)**, floor top at **Y = 0**.

```
  apothem (wall face)   462.7        side = 248.0 = exactly 4 x 62-stud wall panels
  circumradius          479.0        perimeter = 2976  ->  48 panels
  flat-to-flat          925          corner-to-corner  958
  area                  688,387 sq studs
```

Why 462.7 and not the intake's 380: the side comes out at **exactly four 62-stud wall panels**, so the
wall tiles the polygon with no chording and no wedge gaps, and each facet is long enough to hold a
base. The existing 672 slab's corners reach 475.2, just inside the 479 vertices — **so all 442 built
tiles are kept** and only ~231 are added to fill out to the wall.

### One base per facet — the reason the 12-gon works

Each facet is 248 studs of straight wall; the base chain is 193. That leaves **27.5 studs clear at
each end of every facet**, so at every vertex there is a natural **55-stud walkway** between
neighbouring bases. The Factory Entrance gate is 48 wide and drops into one of those vertex gaps —
no irregular facet, no base displaced, all twelve kept.

### Rings, outward from the centre — PROVISIONAL

The intake is emphatic that radii must be walked before they are trusted, so these are starting
values to be adjusted from eye level, not commitments.

| Ring | r | Note |
|---|--:|---|
| Arena deck + collar | 0 – 127 | as built |
| Arena plaza | 127 – 300 | viewing floor; the run lane crosses it |
| **Common buildings** | **300** | 7 shared buildings on facet bearings |
| Base approach | 322 – 415 | open floor |
| **Player bases** | **415 – 450** | laid *along* each facet, outer edge 12 studs off the wall |
| **Wall face** | **462.7** | 48 panels |

Facet centres at bearings 0°, 30° … 330°; vertices at 15°, 45° … The run lane leaves at the **15°
vertex**.

### Wall types

Following the **Studio / intake lettering**, because those are the folders the owner walked and
approved. `Jobs/019/wall-research.md` letters them differently and would send someone to the wrong
and most expensive pattern — [finding 0007](../../findings/0007-the-wall-patterns-are-lettered-a-d-twice.md).

| Type | Pattern | Where | Parts/panel |
|---|---|---|--:|
| **A** | window bays | most of the run | 17 |
| **B** | tool-board panels | behind the shops | 45 |
| **C** | bar wall | where the factory should show through | 19 |
| **D** | hazard plate | the Factory Entrance gate | 17 |

## 🔴 The blocker the intake does not mention

`StationService.playerIsAt` and `StationService.attachPrompts` both walk
**`workspace.Hub.Bases[*].Fixtures[*]`** and match a **`StationId`** attribute. Neither the folder nor
a single stamped attribute exists. Until they do, `RequestRecycle`, the Magnet Lab upgrade and
`enterZone` — the only sanctioned way into Zone 1 — all return *"the hub is not built"*.

So placing meshes as loose scenery delivers a room where **nothing works**. This job must build into
that contract.

One mismatch to resolve: that contract is the *per-base* design job 019 rejected. The seven buildings
are now **shared**. So:

- `Hub.Common.Fixtures.*` — the 7 shared buildings, `StationId` stamped
- `Hub.Bases.<1..12>.Fixtures.*` — each player's smelter + gantry, `StationId` + `BaseIndex`
- `StationService` learns to walk **both** (a small edit in the file that owns the contract)
- `BEHAVIOUR` gains a **`Shop`** entry — there is none today, so the kiosk would log a problem. It gets
  a `notYet`, per non-negotiable #10: announce the empty slot rather than fake it

## Build order

Split into small `execute_luau` calls — one folder per call. Heavy scripts crash Studio (job 019).

| # | Step | Verify by |
|--:|---|---|
| 1 | `CollisionFidelity = PreciseConvexDecomposition` on the 8 Box meshes | read back the property; walk into one in Play |
| 2 | `Hub` folder skeleton: `Common/Fixtures`, `Bases/1..12/Fixtures` | `search_game_tree` |
| 3 | Floor — recolour 442 tiles to A2, arena interior to A3, extend ~231 tiles to the 12-gon | tile count + colour census |
| 4 | Perimeter wall — 48 panels, A/B/C/D by facet | panel count; screenshot each quadrant |
| 5 | 7 common buildings at r=300, `StationId` stamped, `Attachment`s marking their faces | attribute census |
| 6 | 12 bases along the facets — smelter chain + gantry, `StationId` + `BaseIndex` | per-base part count |
| 7 | Factory Entrance in the 15° vertex gap, wall D either side | screenshot |
| 8 | Spawn on the common ring facing the Arena; 7 neon name plates | Play: where do I land, what do I see |
| 9 | `StationService` walks `Hub.Common` too; `Shop` behaviour added | `attachPrompts` returns 0 problems |
| 10 | **Export the room to git** — [decision 0019](../../docs/decisions/0019-hero-geometry-is-editor-placed-and-exported.md) requires it | the file exists and round-trips |

## Verification

Per GROUND-RULES §7 — the editor is not evidence.

- Every radius judged **in Play, at eye level**, standing on the floor. Not from a top-down Edit camera.
- **What failure looks like**, stated up front: the room reads as scattered kiosks on an empty plain
  (this is what killed job 019's ring, in reverse — it was too crowded); or a 60-stud wall fails to
  enclose a 925-stud room under open sky and the map edge shows.
- Before/after from the same camera for anything changed twice.

## Deliberately NOT in this job

- The exporter's *format* beyond what step 10 needs — a snapshot is enough.
- Deleting `HubBuilder` / `HubSpec` / `WorkshopBuilder`. They are disabled and misleading, but deleting
  them is its own job.
- Base **claiming** — bases are built dormant; nothing assigns one to a player yet.
- The Shop Kiosk's actual behaviour (P2 in `docs/build/05-workshop.md`); it gets a `notYet`.

## Open — needs the owner, does not block

1. **Floor tile size.** 32 studs as built reads coarse in a 925-stud room; the approved sample is 9.5.
   I will stand patches of 32 / 16 / 9.5 in situ and screenshot at eye level rather than guess.
2. **No ceiling, open sky, `FogEnd = 100000`.** A 60-stud wall does not enclose a 925-stud room, and
   the Baseplate's hard edge and the DemoRoom shell are both visible from the arena floor. Violates the
   *no visible map edges* rule. Probably its own job.
3. **`MaxPlayers = 60`** in this session versus the decided 12.
