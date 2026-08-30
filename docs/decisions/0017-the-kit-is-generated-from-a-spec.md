# 0017 — The kit is generated from a spec, on a 4-stud grid

**Status:** Accepted · 2026-08-29 · Job 005

## Context

Section 64 wants 70-80 % of the factory built from a reusable modular kit. That kit has to live
somewhere, and Roblox gives two options with very different consequences.

`Workspace` and `ServerStorage` **do not sync** ([job 002](../../Jobs/002/final-summary.md)). Geometry
built by hand in Studio therefore exists only inside the unversioned `.rbxl`: it cannot be diffed,
cannot be reviewed, cannot be regenerated after a material change, and is lost if the file is.

## Decision

**The kit is data.** [`KitSpec`](../../studio_game/ReplicatedStorage/Kit/KitSpec.luau) describes every
piece — sizes, offsets, surfaces, colours, shapes — and
[`KitBuilder`](../../studio_game/ReplicatedStorage/Kit/KitBuilder.luau) realises it into
`ServerStorage.Kit`. The spec is in git; the geometry is a build artifact.

**The grid is 4 studs.** Standard tile 8 (2 units), wall height 12 (3 units).

**Surfaces are named, never raw materials.** Every part goes through `MaterialKit`, which is what lets
the whole factory re-skin when a variant changes.

## Consequences

**Good**

- The kit is reviewable in a pull request. A piece's proportions are readable as numbers.
- Regenerating after a material or palette change is one call, and `buildAll` is idempotent.
- `KitBuilder.validate()` can enforce invariants that a hand-built kit could only hope for.
- Every part is stamped with an `MSSurface` attribute, so the quality-tier controller can find and
  strip variants later ([0016](0016-low-tier-drops-the-variant.md)).

**Costs, accepted**

- No hand-tweaking. A piece nudged in Studio is overwritten on the next build; the fix goes in the spec.
- Composite curves and organic shapes are awkward to express as boxes. Hero props that need an artist's
  eye should be Meshy meshes, not kit pieces.

## The grid rule, and the mistake that shaped it

**The grid constrains FOOTPRINTS, not internal detail.**

The first validator required every size and offset to be grid-aligned. It rejected **67 values** — a
0.4-stud neon inset, a 1.2-stud pipe, a crate's 0.5-stud wall — none of which ever meets a neighbouring
piece. It was enforcing the wrong invariant, and following it would have produced a crude kit.

The rule that shipped: **each piece declares which axes it tiles on.**

```lua
tiles = { "X", "Z" }   -- a floor: meets neighbours on both ground axes
tiles = { "X" }        -- a wall: tiles along its run; Z is its THICKNESS
-- omitted             -- a free-standing prop: tiles on nothing
```

Only declared axes are checked. Internal parts are unconstrained.

That second pass found **3 real bugs** the first had buried in noise: `Floor_Conveyor` was 9 studs wide
because its rails overhung the deck, `Struct_Bridge` was 8.5 deep for the same reason, and `Struct_Gate`
was 18 wide instead of 16. All three would have produced a kit that *looked* modular and left half-stud
gaps at every junction.

## The check

`KitBuilder.validate()` runs before every build and **refuses to build** on any failure — a misaligned
kit is worse than no kit, because it looks nearly right. It also verifies every surface name against
`MaterialKit`, so a typo cannot ship a grey part.

The proof that matters is not a lineup of pieces; it is an **assembled corridor** with no gaps at any
junction. Build one after any change to `GRID`, `TILE` or a tiling piece's footprint.
