# Implementation Plan — Job #017

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31
**Status**: Planning (awaiting go-ahead)

## Analysis

### Group 07 is 34 items. This job is not all of them.

[Build group 07](../../docs/build/07-zones-1-2.md) is the largest group in the manifest — **34 items,
27 of them P0** — covering two zones, a gate, a seven-fixture Service Hub, a MagRail, a return lane,
five hazards and two ambience passes. Treating that as one job would produce the same thing job 012
produced when it built a whole room in one pass: a review finding thirteen issues.

**Split, and the split is by dependency rather than by size:**

| Job | Scope | Why it comes when it does |
|---|---|---|
| **017 (this)** | zone manager · Zone 1 · the Workshop connection | Every later item registers with the manager. Zone 1 proves the chunk pattern before it is repeated |
| 018 | the 1→2 gate · Zone 2 · zone 2 scrap set | The gate needs two zones to sit between |
| 019 | Service Hub ×7 fixtures · MagRail · return lane | The hub belongs *after* zone 2, so zone 2 must exist |
| 020 | P1 hazards ×5 · ambience ×2 | Hazards decorate a zone that works; they cannot come first |

### 🔴 Eight of the 34 items are already done, and one more is nearly so

Counted properly — the manifest's `xN` suffix means that line is N items, not one
([PITFALLS](../../docs/PITFALLS.md), the "coverage by link" shape):

- **"Zone 1 scrap set: screws, nuts, washers, bolts, gears, springs, beads, pipes ×8"** — **all eight
  exist** in `Scrap/ScrapSpec.luau` as tier 1, with weights and values, and they are **live**: a BOLT
  was watched going `IDLE → PULL → collected` during job 016's verification.
- **`Config/Zones.luau`** already carries all twelve tiers with `gate`, `guardian` and `hubAfter`,
  from job 003, plus `MVP_TIERS = 2`.

So this job **verifies and wires** those rather than building them. Writing a second tier-1 scrap set
would be the actual failure mode here.

### How the zone gets built: as data, not by hand

`Workspace` does not sync (job 002, probed). Geometry placed by hand lives only in the unversioned
`.rbxl` — it cannot be diffed, reviewed or regenerated, and the editor's copy goes stale
([#61](../../docs/PITFALLS.md)). [Decision 0017](../../docs/decisions/0017-the-kit-is-generated-from-a-spec.md)
settled this for the kit and `WorkshopSpec` applied it to a room; a zone is the same shape of thing.

So: **`Zone1Spec.luau` in `ReplicatedStorage`, built at server start by a `ZoneBuilder`**, exactly as
`WorkshopSpec` + `WorkshopBuilder` already do. ⚠️ Including the consequence — the zone is invisible in
the editor until it is built, and the editor copy goes stale the moment the builder changes.

### The constraint that shapes the architecture

> *"Zones are authored as self-contained streamable chunks. No script may hold a hardcoded instance
> path into another zone; zones talk to the zone manager only. Under Instance Streaming that coupling
> is not a smell, it is a nil-index crash."* — `docs/systems/factory`

`StreamingEnabled` is **on** for this place. That single sentence is the whole reason the zone manager
exists and why it is built first rather than last: it is not a convenience layer, it is what stops a
zone-to-zone reference from being a crash on someone else's machine when their client has not streamed
the far zone in.

**Design:** zones *register* with the manager (id, tier, bounds, spawn points, entry/exit anchors).
Anything that needs another zone asks the manager. Nothing holds a path across a chunk boundary.

### Budget, and the kit rule

`Perf.BUDGET.MAX_PARTS_IN_VIEW` is **1800**, and its own comment reads *"a zone chunk plus the
Workshop"* — the Workshop is **425**, so a zone chunk that can be co-visible with it has roughly
**1375** to work in, and should aim far below that since the whole point of the corridor is that you
can see forward into the next space.

> *"Built from the group 02 kit; if a room needs a bespoke asset, the kit is wrong."*

27 pieces exist. If Zone 1 cannot be built from them, the honest output of this job is a **finding
about the kit**, not a bespoke part quietly added.

### Colour: the one rule that is easy to break here

Style §2 gives Zone 1 (Color Workshop) **candy pink `#FF6FB5` · mint `#7FE6C4` · lemon `#FFE066`**,
and every zone accent is checked against the **reserved set** it may never use:
`#41D8FF` `#E03A2F` `#3FD64B` `#FF7A1A` `#C46BFF` `#FFC21A` `#FF3D7F` `#B8C2CC`.

🔴 **Lemon `#FFE066` is not hazard gold `#FFC21A`, and the difference matters.** They are close enough
to look like a typo and far enough apart to mean different things — gold means *Arena / Legendary /
most valuable thing here*. A zone painted in gold would say "treasure" in every room. The three zone
accents go in `Zone1Spec` as named constants and are asserted against the reserved list, so this
cannot decay quietly (the shape [PITFALLS #39](../../docs/PITFALLS.md) already describes).

⚠️ These colours are **not** in `Ui.Theme` — Theme carries structural and signal tokens, not zone
accents. So they are a genuine new duplication and the spec is where they live.

## Implementation steps

1. **Verify before building.** Confirm in Play that all eight tier-1 scrap types spawn and are
   collectable, and that `Zones.byTier(1)` returns the Color Workshop with `gate = 10`. Anything
   already true gets ticked, not rebuilt.
2. **`ZoneManager`** (`ServerScriptService`): a registry — `register(zone)`, `byTier`, `byId`,
   `current(player)`. No zone may resolve another zone except through it. Client-facing state via a
   remote, not by reading Workspace.
3. **`Zone1Spec.luau`** (`ReplicatedStorage/Zones/`): the Color Workshop as data — floor plan, walls,
   the forward corridor, machinery from the kit, the three accent colours, scrap spawn volumes, the
   entry anchor from the Workshop and the exit anchor toward the (future) gate.
4. **`ZoneBuilder`**: builds a registered zone from its spec, the way `WorkshopBuilder` builds the hub.
   One `Model` per zone, so it is a chunk.
5. **Wire `FactoryEntrance`.** It currently answers `ZONE 1 OPENS IN GROUP 07`; it should move the
   player to Zone 1's entry anchor. The `notYet` string goes away only when the destination exists.
6. **Scrap in the zone**: `ScrapService` spawns tier-1 scrap into Zone 1's volumes via the manager,
   not by a hardcoded path.
7. `tools/luau-analyze.sh`, then verify in **Play**.
8. Independent reviewer agent.

## What I need from you

- [ ] **Go-ahead on the split** — this job is the manager + Zone 1, not all 34 items of group 07.
- [ ] Nothing to buy, nothing to import, no Meshy. Everything here is kit pieces and code.
- [ ] ⚠️ Later, not now: the **gate value** (Magnet Power 10 for zone 1) and the whole power curve are
      §62 *initial balancing targets* that the docs say must be playtested. This job will not tune them.

## Verification - MANDATORY GATES (GROUND-RULES 7)

- [ ] **Reproduced in PLAY**, at the player's camera angle
- [ ] Before/after from the SAME camera, and the "before" is kept
- [ ] No world fact asserted from a constant - measured instead

### Checks

- [ ] **The eight scrap types are verified, not assumed** — each of SCREW, NUT, WASHER, BOLT, GEAR,
      SPRING, BEAD, PIPE observed spawning in Zone 1. *Failure: a set that exists in config and never
      reaches the world, which is what "coverage by link" means.*
- [ ] **No cross-zone instance path exists** — grep the tree for any script resolving a zone by
      `Workspace` path rather than through the manager. *Failure: it works today with one zone and
      becomes a nil-index crash the moment zone 2 streams out.*
- [ ] **Part count measured against the budget**, not estimated. *Failure: "it looks fine" on a
      desktop that never streams anything out.*
- [ ] **Zone accents checked against the reserved set** programmatically. *Failure: lemon `#FFE066`
      silently becomes hazard gold `#FFC21A` and the colour language loses a meaning.*
- [ ] **Built only from the 27 kit pieces** — asserted by the builder, which should refuse an id the
      kit does not define. *Failure: a bespoke part appears and the kit rule erodes without a
      decision being taken.*
- [ ] **The Factory Entrance actually takes you there**, in Play, and its `notYet` text is gone.
      *Failure: a station that answers "ENTER" and does nothing.*
- [ ] **The zone is a single Model** and removing it leaves the Workshop intact. *Failure: it is not
      a chunk, and streaming will not treat it as one.*
