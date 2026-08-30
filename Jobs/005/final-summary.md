# Job #005 — final summary

**Project:** `roblox.magnet-sweep` · **Status:** complete · 2026-08-29

## What was delivered

**24 kit pieces / 85 parts**, generated from data:

| Category | Pieces |
|---|---|
| Floor | Plain · Grated · Hazard · Conveyor |
| Wall | Solid · Pipes · Window · Machine |
| Structure | Pillar · Corner · Gate · Bridge · Ramp · Platform |
| Industrial | Conveyor · Generator · Tank · PipeRun · ControlPanel · Fan |
| Signage | NeonSlab |
| Prop | Beacon · Crate · RobotArm |

- **[`KitSpec`](../../studio_game/ReplicatedStorage/Kit/KitSpec.luau)** — every piece as data: sizes,
  offsets, surfaces, colours, shapes, rotations.
- **[`KitBuilder`](../../studio_game/ReplicatedStorage/Kit/KitBuilder.luau)** — realises the spec into
  `ServerStorage.Kit`. Idempotent, validates first, refuses to build on failure.
- **[Decision 0017](../../docs/decisions/0017-the-kit-is-generated-from-a-spec.md)** — generated from
  spec, 4-stud grid.

Every part is surfaced through `MaterialKit` (never a raw Material) and stamped with an `MSSurface`
attribute; the 12 neon panels are correctly excluded and their lights are tagged `Decorative` so the
quality-tier controller can cull them by range.

`MS_HazardStripe` was re-tiled 6 → 4 studs so the stripe repeat lands on module boundaries.

## Verification

**The proof of a modular kit is not a lineup of pieces — it is pieces meeting with no gaps.**

An 8-module corridor was assembled from 41 instances and showed continuous wall runs with no gaps.
⚠️ **That proof did not survive review** — it was built against a stale palette and contained none of
the four pieces that turned out to be broken. See the review section below. The current build is
verified **numerically**: footprints, world extents, pivots and part flags read back from the live
`ServerStorage.Kit`.

## 🔴 My validator enforced the wrong invariant

The first version required **every** size and offset to be grid-aligned. It rejected **67 values** — a
0.4-stud neon inset, a 1.2-stud pipe, a crate's 0.5-stud wall thickness. None of those ever meets a
neighbouring piece. Following it would have forced a crude kit.

A grid constrains **footprints**, not internal detail. The rule that shipped: each piece declares which
axes it tiles on.

```lua
tiles = { "X", "Z" }   -- a floor: meets neighbours on both ground axes
tiles = { "X" }        -- a wall: tiles along its run; Z is its THICKNESS
-- omitted             -- a free-standing prop: tiles on nothing
```

**The corrected rule then found 3 real bugs the first had buried in 67 lines of noise:**

| Piece | Bug | Consequence |
|---|---|---|
| `Floor_Conveyor` | rails overhung the deck → **9** wide | half-stud gap at every junction |
| `Struct_Bridge` | rails on the edge → **8.5** deep | same |
| `Struct_Gate` | posts overhung → **18** wide, not 16 | gate would not meet a wall run |

All three would have shipped a kit that *looked* modular.

## 🔴 The stale-`require` cache bit twice

[PITFALLS #15](../../docs/PITFALLS.md). `require` is cached per Luau context for the whole Edit session,
and `execute_luau` runs in its own context.

**First:** the rewritten validator produced byte-identical output to the old one. I checked the
`.Source` of the synced ModuleScript before blaming the cache — the new code *was* there. Cloning the
folder gave fresh module identities and it ran correctly.

**Second, and worse:** the kit built with **zero `MSSurface` attributes**. The cloned `KitBuilder`
required the *real* `ReplicatedStorage.MaterialKit`, which this context had cached from before the
attribute existed. Verified rather than assumed:

```
cached MaterialKit.ATTRIBUTE = nil | cached has refresh() = false | ON-DISK source has SetAttribute = true
```

**Fix:** `KitBuilder` now stamps the attribute itself. It knows the surface, so it no longer depends on
which `MaterialKit` version happens to be loaded — better design regardless of the cache, because the
attribute is load-bearing for the quality-tier controller.

## Known gaps vs `docs/build/02-industrial-kit.md`

- **Scrap crates x3** — one `Prop_Crate` exists; the manifest wants red/blue/yellow. Trivial: three
  colour variants of one spec entry.
- **Conveyor motion by texture offset** — the belt geometry exists; nothing animates it yet. That is a
  runtime script, not a kit piece.
- **Kit placement tool** (P2) — not started.
- The kit is **24 pieces where the manifest counts 47 items**, because several manifest rows are
  `xN` groupings that map to one spec entry each.

## Independent review — 27 findings, and what they cost

A reviewer was run against the built kit with read-only Studio access. **Three S1 findings meant the kit
was not usable as built.** All were verified independently before acting.

### 🔴 Every cylinder was broken, and worse than reported

A Roblox `Cylinder`'s length is **always `Size.X`** (`enums/PartType.yaml`: *"oriented along the X
axis"*); `Size.Y`/`Z` are the cross-section. The spec wrote `{1.5, 1.5, 16}` for a 16-stud pipe and
rotated it. Measured:

```
Cylinder Size(10,2,2) unrotated -> ExtentsSize 10,2,2   (length axis = X)
Ind_PipeRun_1  Size=1.5,1.5,16  ->  ExtentsSize 1.5,1.5,1.5
```

The 16 was **ignored outright** — a 1.5-stud nub, not a column. `rot = {90,0,0}` also cannot move an
X-aligned axis, so four of eight cylinders were never rotated at all. `Ind_Tank` floated 2.65 studs.

**Fix:** cylinders declare `size = { length, dia, dia }` plus `along = "X"|"Y"|"Z"`, and one helper
(`orientationOf`) turns that into a rotation. `validate()` now rejects a cylinder with a hand-rolled
`rot`. Measured after: `Ind_PipeRun` 16 studs in Z, `Ind_Tank` y 0..12 sitting on the floor.

### 🔴 The built kit had drifted from source inside one day

`MaterialKit`'s three non-white `defaultColor`s were re-pointed at the palette **after** the kit was
built, and nothing re-ran `buildAll`. 33 of 83 parts carried colours the source could no longer
produce — every conveyor belt was mid-grey where the source said near-black. Decision 0017's whole
premise is "the spec is in git; the geometry is a build artifact", and the artifact silently diverged.
Rebuilt.

### 🔴 `PrimaryPart` made `PivotTo` unusable — PITFALL #22, walked straight into

Setting `PrimaryPart = parts[1]` gives each piece a different pivot height, because a Model with a
PrimaryPart pivots there and **ignores `WorldPivot`**. Measured spread: 0.00 to 10.00, with
`Wall_Window` at 1.00 while every other wall was 6.00 — so not even one rule per category worked.
**Fix:** no `PrimaryPart` on these static models; `WorldPivot = CFrame.new()`. All 24 pivots now 0.

### A design bug my own re-test then found

Testing the corner against a wall run — the combination the original corridor proof never included —
showed a **2.00 stud gap that no placement could close**. A 4-wide corner centred on multiples of 4
spans (4k−2, 4k+2), half-offset from an 8-wide wall spanning (8m−4, 8m+4). A junction is a **tile**, not
a post. Rebuilt as a full-tile junction post: corner now spans exactly −4..4, gap **0.00**.

### Also fixed

| | |
|---|---|
| Floor decks straddled y=0, so the walking surface was +0.5 and the ramp was flush with nothing | decks moved to y=−0.5; surface is exactly 0 |
| `Prop_Crate` base was **coplanar** with the floor tile — guaranteed z-fighting | lifted to 0.10 |
| `Ind_Fan` coplanar with the wall it mounts to; `Wall_Window` mullions z-fought the panels | both pushed clear |
| `footprint()` ignored rotation, so a rotated part at a tiling edge could pass falsely | projects through the rotation now |
| `validate()` checked neither `shape` nor `color` — an unknown shape silently built a **Block**, which is how the cylinder bug shipped; a bad hex threw *after* the old kit was destroyed | both checked before anything is destroyed |
| `buildAll` returned `nil :: any` typed as non-optional `Folder` — the cast laundered it past the type checker | returns `Folder?` |
| 21 `--!strict` errors (optional `surface`, untyped `buildPart` param, `local p` inferred as WedgePart) | typed |
| All 83 parts `CanQuery = true` — the magnet runs `GetPartBoundsInRadius` continuously | `CanQuery = false`; collide/shadow only on parts ≥1 stud |
| Three indicator lamps at Range 18 per control panel; 8 wall tiles = 24 overlapping room-lights | Range 4–5, and every light tagged `Decorative` so the tier controller can cull it |
| Signal colours as decoration: green/red status lamps, a **solid gold** gate slab, an entire crate in signal red | neutral lamps, crate in zone-accent blue, gold reserved for stripes. The beacon **keeps** signal red — it fires on a Salvage Breach, which red owns |
| `KitSpec.PALETTE` was dead code with 20 duplicated hex literals | now used |

### Not fixed, and now honestly listed

- **The neon sign has no text and no station colour.** §5 wants `MAGNET LAB` / `RECYCLER` in the
  station's signal colour; it is a blank cyan slab with no `SurfaceGui` and no per-instance hook. The one
  thing the sign exists to do is absent.
- **`Prop_RobotArm` is not animatable** (no `Motor6D`) and **`Prop_Beacon` does not rotate**, though both
  `desc` strings claim the behaviour.
- **The conveyor has no `Texture` to offset** — `MaterialVariant` has no `OffsetStudsU/V`, so belt motion
  needs a `Texture` instance the spec cannot yet express.
- Crates ×3, kit placement tool (P2).

### The verification that did not survive

The original corridor proof left no artifact, was built against the pre-drift palette, and contained
none of the four broken pieces — it tested walls and floors, which were the parts that were already
correct. A `screen_capture` for the fixed build timed out repeatedly (the renderer was not producing
frames), so this pass is verified **numerically**: footprints, world extents, pivots and part flags all
read back from the live build.

## Next

Job 006/007 — the Sky, and choosing the reference device and performance budgets.
