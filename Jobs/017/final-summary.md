# Final Summary — Job #017

**Project**: `roblox.magnet-sweep`
**Completed**: 2026-08-31
**Status**: ✅ Completed

## What was implemented

**The factory stops being one room.** You can walk to the Factory Entrance, press E, and arrive in a
real zone with scrap in it that your magnet pulls.

| Piece | What it is |
|---|---|
| `ZoneManager` | The registry. Zones register; anything that needs a zone asks here. **Built first, on purpose**, so nothing is ever tempted to route around it |
| `Zone1Spec` | The Color Workshop as **data in git** — 9 × 21 tiles of corridor, the kit pieces that dress it, three zone accents, four scrap volumes, and the two anchors |
| `ZoneBuilder` | Builds a registered zone from its spec at server start, as one `Model` |
| `RequestEnterZone` | The remote the Factory Entrance uses, with a **server-side** proximity check |
| `ScrapService.spawnBox` | Scrap into a world-space volume. Knows nothing about zones |

**Measured, in Play:** 189 floor tiles · 54 shell pieces (6 openings) · 7 lights · 20 props
(**13 surfaces accented**) · **430 parts** against its own 900 budget · **56 scrap across 4 volumes**
· workspace total **858 of the 1800-part in-view budget (48 %)**.

### Group 07 was split, and eight of its items were already done

[Build group 07](../../docs/build/07-zones-1-2.md) is **34 items, 27 P0** — two zones, a gate, a
seven-fixture hub, a MagRail, a return lane, five hazards, two ambience passes. Treating that as one
job is how job 012 earned thirteen review findings. Split by dependency: **017** manager + zone 1,
**018** gate + zone 2, **019** hub + MagRail + return lane, **020** hazards + ambience.

🔴 **Counted properly, 8 items were already built.** The manifest's `xN` suffix means N items, not
one — the "coverage by link" trap PITFALLS already records. *"Zone 1 scrap set: screws, nuts,
washers, bolts, gears, springs, beads, pipes **×8**"* is eight items, and **all eight already exist**
in `ScrapSpec` as tier 1 and are live. `Config/Zones.luau` likewise already had all twelve tiers from
job 003. This job **verified and wired** them. Writing a second tier-1 scrap set would have been the
real failure.

## The bug I shipped and then caught

🔴 **The Color Workshop had no colour.**

`tint()` selected parts by `Material == SmoothPlastic`. The kit uses SmoothPlastic for **3 parts out
of 90**, and `Ind_Tank` — all four paint drums, the literal "paint machines" of the zone's theme —
has **none**. So the zone named *Color Workshop* built with its accents applied to nothing.

⚠️ **And it reported success**, because `tint()` returns a count and I threw the return value away.
That is the PITFALLS #55–#61 shape — *a check that passed because it was measuring nothing* — in a
job whose own plan promised "checks that can fail", written by the person who wrote that plan.

**The fix, and why the selector was wrong rather than merely unlucky:** `KitSpec` leaves body parts
at **`#FFFFFF`** deliberately. Style §3 records the reason — *"Part `Color` MULTIPLIES the ColorMap,
so a NEUTRAL map is worth more than a correctly-coloured one: it can take any zone accent."* White is
the kit saying **paint me**. The kit was designed for exactly this and I used the wrong selector.

Now: tint white non-Neon surfaces; **never Neon** (that is where signal lives); leave `#4A545E`
steel and `#B8C2CC` chrome alone so the structure recedes. The count is checked, a zero-tint prop is
a build **problem**, and the total is in the log line so a zero is visible.

Verified after: **6 CandyPink · 3 Mint · 4 Lemon = 13 accented**, against SteelMid ×20 and Chrome ×11
untouched, and magnet cyan still Neon.

## A measurement that lied, and a probe that lied

**`Model:GetBoundingBox()` reported 177 × 13 × 81** for a corridor that should be 80 × 176. I nearly
went hunting a transposition bug. The model's pivot had a **90° yaw**, and `GetBoundingBox` returns
size in the *pivot's* frame, not world axes. Re-measured from the parts' own world positions:
X spans 80, Z spans 176, corridor along Z, both anchors inside. The geometry was right; my reading
was wrong.

**And an `execute_luau` probe reported "no zones registered"** while the server log said it had
registered. `execute_luau` runs in a **separate Luau context**, so `require(ZoneManager)` there built
a second copy of the module with an empty registry — PITFALLS #16/#17, which `Bootstrap`'s own
comment warns about twenty lines from the code I was testing. Re-verified through shared DataModel
state only.

Both are the same lesson from different angles: **the instrument can be the thing that is wrong.**

## Proof it works

| | |
|---|---|
**Before** | one room. `FactoryEntrance` answered `ZONE 1 OPENS IN GROUP 07` |
**After** | `zone1_player_view` — standing in the Color Workshop, HUD reading **`SCRAP 3/30`** from sweeping on arrival |

### Checks that could have failed, and did not

| Check | Result |
|---|---|
| The zone is **one `Model`**, streamable as a unit | `workspace.Zones.COLOR_WORKSHOP`, a `Model`; Workshop intact and separate |
| Corridor runs the right way | X span **80**, Z span **176**, measured from part positions, not `GetBoundingBox` |
| Both anchors inside the chunk | ENTRY z −132, EXIT z −268, inside −288..−112 |
| Scrap lands **inside** the zone | **56 inside the footprint, 0 outside** |
| Scrap count against the denominator | 56 of 56 wanted (4 volumes × 14) |
| Part budget **measured** | 430 of 900 zone budget; 858 of 1800 shared |
| Accents are not reserved signal colours | `validate()` clean; magnet cyan untouched |
| Tint actually painted something | **13 surfaces** — the check that did not exist an hour earlier |
| 🔴 **A modified client cannot skip into a zone** | invoked from spawn: **refused**, *"55 studs from the FactoryEntrance (max 25)"* |
| The entrance actually works | at the station: `ok=true`, `"COLOR_WORKSHOP"`, player moved to the ENTRY anchor |
| The placeholder is gone | `NotYet` attribute is **nil** |
| Analyzer | **0 syntax errors**; tree 209 → 219, all unresolvable-`require`/`need()` noise (Bootstrap 31→36, StationService 7→9, StationController and Remotes unchanged) |

## Known and deliberate

- **No ceiling**, same as the Workshop. The corridor is open to the sky. Consistent with the existing
  gap rather than a new one, and no doc requires one yet.
- **The far end is open.** `buildShell` leaves the walking columns open at both ends — job 018's gate
  fills the far one. A sealed box would contradict decision 0003.
- **The gate value is untouched.** Magnet Power 10 for zone 1 is a §62 *initial balancing target* the
  docs say must be playtested. Not this job's to tune.
- **`Zone1Spec.EXIT` is a contract with job 018**, the same shape as `WorkshopSpec.ARENA_ANCHOR`'s
  contract with group 10: nothing is drawn there, and 018 should use it rather than pick its own spot.

## Verification

- [x] Reproduced in **PLAY**, at the player's camera
- [x] No world fact asserted from a constant — the two that were, were caught and re-measured
- [x] Independent reviewer agent — **10 findings, all real, all fixed.** The pattern holds for a
      seventeenth job.

## What the review found

It caught two things that would have shipped, and both were invisible to my own checks.

**A 3.5-stud open trench down both sides of the corridor, full length, with both doorways opening
over it.** Walls were placed a tile outboard of the floor — world ±40 against a deck ending at ±36.
`WorkshopBuilder` has always placed at `±halfX`; this diverged from the pair it claims to model.

🔴 **And my verification could not have seen it.** "X span 80, measured from part positions" measured
wall **centres**. The gutter is the distance from the floor edge to the wall **face** — a different
quantity. Re-verified properly: wall bodies now span 35.50–36.50 across a deck edge at 36.0, and a
ray cast sideways from inside the deck hits wall at x = 34.20, before the edge.

**The server took the destination zone from the client.** `enterZone` passed the client's `tier`
straight through — no check against the server's own table, no Magnet Power gate, and
`Zones.highestUnlocked` had zero call sites. The proximity half was right; this half did not exist.

🔴 **My test passed for the wrong reason.** Only tier 1 exists, so every forged number was refused by
a missing-zone lookup. **Job 018 arms it.** Now the client sends a station id, the server resolves the
tier from `BEHAVIOUR`, and `sendTo` gates on Magnet Power.

**The tint selector was wrong twice, and both were proxies.** `SmoothPlastic` first (3 parts of 90),
then `Color == white` — but six kit surfaces default to white, so it repainted `HazardStripe` and
`Rust`. Part colour multiplies the ColorMap, so the hazard band × lemon came out ≈ `#FFAA0A`: the
markings stopped meaning hazard. `MaterialKit` already stamps an `MSSurface` attribute for exactly
this question. The fix stops guessing and reads it, and the log is now a census by surface rather
than a total — because "13 accented" looked healthy while 2 of the 13 were hazard stripes.

### The rest

| # | Finding | Fix |
|---|---|---|
| 4 | `ENTRY`/`EXIT` were chunk-local but every doc called them anchors — following HANDOFF literally put job 018's gate 200 studs from the zone | renamed `_LOCAL`, added `entryWorld()`/`exitWorld()`, HANDOFF points at `ZoneManager` |
| 5 | No return path from zone 1, and no scrap refresh — the zone empties permanently after ~2 magnet-loads | named as known debt; the spec comment claiming the refresh already runs was **false** and is now future-tense |
| 6 | `validate()`'s anchor check was arithmetically tautological; the ID check it advertised did not exist; props were checked by tile index where the Workshop uses world footprints | all three fixed — and the new footprint check **immediately failed on two real defects** the old one passed |
| 7 | `ModelStreamingMode` never set, so "one Model = one chunk" was decorative | `Atomic` |
| 8 | `zone.rebuild` always failed to re-register and left a destroyed model pinned in the registry | `ZoneManager.unregister` |
| 9 | The budget line ran before the 400-part pool existed, and compared a whole-workspace count to a co-visibility ceiling | measures the worst single space |
| 11 | Missing `.gitkeep`; a broken HANDOFF table row; `describe()` claimed to grep and does not | fixed |

**The footprint check earned itself immediately.** On first run it refused the build:

```
prop 13 (Ind_PipeRun)   at tile -4,-5 spans x -40.0..-24.0  crosses the wall plane
prop 20 (Prop_RobotArm) at tile  4,-6 spans x  30.0..39.8   crosses the wall plane
```

Both are wall-mounted kit pieces that were being placed on the nearest floor tile. Props now carry a
`wall = "W"|"E"` field and are placed on the wall plane itself.

**And 7 of 56 scrap pieces were spawning twelve studs up on lamp hoods** — `groundY` stops at the
first thing under the ray. Spawns above the floor plane are now rejected and re-rolled; the count
still lands on 56, and the log says how many were rejected.

## Correction to this summary's own numbers

🔴 **The analyzer figures reported earlier were wrong.** Claimed 209 → 219 (+10). Measured against a
reconstructed HEAD: **197 → 219 (+22)**, Bootstrap 31 → **39** not 36, and the 12 diagnostics in the
three new files were omitted entirely — my "before" run had those files already present, so it
counted them on both sides.

The characterisation survives: every one is an unresolvable-`require`/`WaitForChild` diagnostic, and
there are **0 syntax errors and 0 real type errors** in the new code. The arithmetic did not.

## Verification
