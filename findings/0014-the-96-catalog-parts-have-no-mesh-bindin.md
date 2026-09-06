# FINDING 0014: the 96 catalog parts have no mesh binding, so no found part can be mounted

**Project:** `roblox.magnet-sweep`
**Status:** open
**Severity:** high — it blocks the core loop's payoff, not a cosmetic detail
**Created:** 2026-09-06 (job 022, found by a persistence round-trip test)

## Symptom

With the robot now assembled from a saved loadout, an upgrade was tested end to end: set the Arm slot
to `PIPE_WRENCH` (a real tier-1 catalog part), restart, and check the robot. The profile round-tripped
perfectly. The robot came back with **four parts**, and the server said exactly why:

```
[S][Profile]     johnygorsky10: profile loaded (v1, robot present)
[S][RobotSpawn]  bay 3: 1 part(s) did not mount -- Arm/PIPE_WRENCH: PIPE_WRENCH has no mesh field
[S][RobotSpawn]  bay 3: robot placed from saved profile (5 slot(s))
```

## Cause

`Config/PartsCatalog.luau` carries, per part: `partId`, `name`, `tier`, `slot`, `rarity`,
`specRarity`, `animationProfile` / `mobilityProfile`, `zone`, `effect`. It carries **no**:

- `mesh` — which entry in `ServerStorage.ImportedMeshes` this part *is*
- `scale` — the multiplier that makes it the right size on the rig
- `mountFrac` — where its `RobotMount` sits on the part

`Config/StarterRobot.luau`'s five rusty parts have all three, measured off
`DemoRoom.10_Robots.2_Starter`. That is the only reason the starter mounts at all.

So today: **the starter robot works and no found part can ever be equipped.**

## Why it was not obvious

The catalog is complete and correct *as a catalog* — it is generated from
`docs/content/parts-catalog.md` and validated by `PartsCatalog.validate`, which checks slot and
rarity. Nothing in it was wrong. The missing data is the **art binding**, which is a different
concern and lives nowhere yet.

⚠️ It is also invisible until something tries to build a robot from a catalog part, which nothing did
before job 022. `docs/build/spec-coverage.md:124` already flags the `AnimationProfile` column as
**(derived)**; the mesh binding is not flagged anywhere because it was never written down as needed.

## Scale of the gap

There are **96 catalog parts**. `ServerStorage.ImportedMeshes` holds **44 meshes**, of which roughly
a dozen are clearly parts (`pipe`, `column`, `work_lamp`, `magnet_coil`, `paint_drum`, `gear`,
`golden_gear`, `grabber_claw`, `toy_hammer`, `spring_puncher`, `caster_wheels`, `mini_motor`,
`pipe_wrench`, `propeller_pack`, `roller_skates`, `wind_up_key`, `toyrobot`, `toy_camera`, `screw`,
`bolt`, `nut`, `washer`, `spring`, `bead`, `block`, `ingot`, `jack_launcher`, `spring_puncher`).

So this is **not** one task. It is:

1. **Bind the parts that already have a mesh** — a dozen or so tier-1/2 entries. Each needs a
   measured `scale` and `mountFrac`, the same way the rusty five were measured.
2. **Decide where that data lives.** It cannot be hand-added to `PartsCatalog.luau` — that file is
   generated and says "do not hand-edit". Either the generator learns a mesh column (so the binding
   lives in `docs/content/parts-catalog.md`), or a separate `Config/PartArt.luau` maps
   `partId -> { mesh, scale, mountFrac }`. The second keeps art out of a design doc and is probably
   right.
3. **Accept that most of the 96 have no mesh at all** and will need generating. That is a large
   Meshy programme, not a config task.

## Fix idea

Short term, to unblock upgrades: a `Config/PartArt.luau` covering the tier-1 and tier-2 parts whose
meshes already exist, with `scale` and `mountFrac` measured per part. `RobotAssembler.def` already
merges `StarterRobot` and `PartsCatalog`, so it only needs a third lookup.

🔴 **Measure, do not derive.** The rusty five needed a mount point at `(0,0,0)`, `(0,-1,0)` and
`(-0.58,-0.14,0)` respectively — no formula produces those. A bounding-box guess hangs every part by
its middle, half inside the torso, which is job 019's lesson for the third time.

**Until this is done, `RobotAssembler` fails loudly and leaves the socket empty**, which is the
correct behaviour per non-negotiable #10 — an empty slot that announces itself beats a wrong part
that does not.

---

## PROGRESS — 2026-09-06

The owner asked for all three steps. Two are **done**; the third is **partly done and capped by
credits**, which is stated here rather than quietly narrowed.

### ✅ Steps 1 + 2 — done and verified

**`Config/PartArt.luau`** now maps `partId -> { mesh, scale, mountFrac }`, and
`RobotAssembler.def` merges it over the catalog entry (catalog keeps design, PartArt supplies art;
**slot is never overridden**).

Every number was **harvested from the eight demo robots in `Workspace.DemoRoom`** — the assemblies
the owner built and approved — not derived. 15 distinct meshes yielded approved mount data.

**Tiers 1 and 2: 16 of 16 bound.** Verified in Play with a full loadout of real catalog parts,
after a restart:

| part | slot | socket | offset |
|---|---|---|--:|
| `BUILDING_BLOCK_CHEST` | Body | `BodySocket` | 0.0000 |
| `WIND_UP_KEY` | Core | `CoreSocket` | 0.0000 |
| `TOY_CAMERA` | Head | `HeadSocket` | 0.0000 |
| `ROLLER_SKATES` | Mobility | `MobilitySocket` | 0.0000 |
| `TOY_HAMMER` | Arm | `LeftArmSocket` | 0.0000 |
| `PROPELLER_PACK` | Back | `BackSocket` | 0.0000 |

**6 of 6, all keeping their paint** (only the rusty set is stripped). `PROPELLER_PACK` proves the
design boundary: the demos mount it on the torso, the catalog says `Back`, and the catalog won.

Bootstrap now reports the remaining gap as a number on every boot, so it can never be a discovery.

### ⚠️ Step 3 — tier 3 generated; tiers 4-12 deliberately not

**The full 80 was not affordable.** 80 x 30 credits = **2,400** against a balance of **1,833** —
short by 567, before retries. Options were put to the owner (meshy-5 at 15/part, or untextured at
20/part, both of which would have fitted) and they chose **tier 3 only at full quality**.

The sequencing argument that supported it: **zone 1 is the only built zone**, so every missing mesh
is art for zones that do not exist yet.

**Tier 3 (Mega Kitchen) — 8 of 8 generated, 240 credits, zero failures:**

`colander` · `blender_motor` · `refrigerator_door` · `giant_spoon` · `frying_pan` ·
`serving_cart_wheels` · `toaster_coil` · `golden_tenderizer`

At `assets/generated/tier3/`, GLB + 5 PBR maps each, textured to zone 3's steel-white `#E8EEF2` and
copper `#C77B3A`. ⚠️ `.gitignore` excludes `*.glb`, so they exist **on disk only**.

**Remaining: 72 parts, tiers 4-12, ~2,160 credits.** Balance after this run: **1,593**.

### Still to do for tier 3

- [ ] **Human step: import the 8 GLBs**, then they get staged in the DemoRoom for approval as usual.
- [ ] 🔴 **Measure `scale` and `mountFrac` for each, and only then add them to `PartArt`.** They are
      deliberately absent right now: guessing them would be the bounding-box mistake this whole
      finding is about. Until they are bound, `RobotAssembler` reports them by name and leaves the
      socket empty.

---

## TIER 3 BOUND FROM THE OWNER'S OWN PLACEMENT — 2026-09-06

The owner imported the eight meshes, put the parts where they belong on
`DemoRoom.10_Robots.5_Tier3Kitchen`, and those positions were then **measured back into
`Config/PartArt`** rather than argued about.

**Four of seven needed correcting from my slot-convention guess:**

| Part | mountFrac | mountRot | vs my guess |
|---|---|---|---|
| `REFRIGERATOR_DOOR` | (0, 0, 0) | — | already right |
| `COLANDER` | (0, −1, 0) | — | already right |
| `SERVING_CART_WHEELS` | (0, 1, 0) | — | already right |
| `BLENDER_MOTOR` | (0, 0.0953, −0.006) | **92.08° X** | arrived lying down |
| `TOASTER_COIL` | (0, 0, **−0.4405**) | — | pulled off the face from −1 |
| `GIANT_SPOON` | (**0.3723, 1.1289**, 0) | **102.63° Z** | re-hung entirely |
| `GOLDEN_TENDERIZER` | (**0.4898, −0.5025**, 0) | **64.50° Z** | re-hung entirely |

🔴 **The two arms are NOT mirror images of each other** — 102.63° vs 64.50°, and different mount
points. Job 022 had derived an analytic rule (one roll magnitude, sign mirrored per side) that
measured correctly on a sweep and is still **wrong**: a human placing parts where they look right
does not produce a mirror. Each is recorded with the socket it was measured in
(`measuredIn`), and putting either in the opposite arm socket is explicitly unverified.

🔴 **`mountRot` had to widen from one axis to three.** It began as a single Z roll, which could not
express the blender motor's 92° about X. A single-axis rotation with a mirrored sign was an
over-fit to the two examples that existed at the time.

⚠️ `mountRot` is measured **relative to the socket**, so it is independent of the stance: the rig
these came off still carried a 62° shoulder roll and it cancels out of the maths. That is what lets
`RobotSpawner.STANCE` stay in code without double-counting.

### Verified by round-trip, not by eye

A throwaway rig was rebuilt purely from `Config/PartArt` and every part compared to the owner's, in
torso-local space:

| part | delta |
|---|--:|
| `REFRIGERATOR_DOOR` | 0.0000 |
| `SERVING_CART_WHEELS` | 0.0001 |
| `TOASTER_COIL` | 0.0005 |
| `COLANDER` | 0.0023 |
| `BLENDER_MOTOR` | 0.0070 |
| `GIANT_SPOON` | 0.0116 |
| `GOLDEN_TENDERIZER` | 0.0184 |

**Worst 0.0184 studs.** ⚠️ The first run of this check reported `SERVING_CART_WHEELS` off by
**0.1499** and I nearly filed it as a config error. It was the check: I had omitted `Waist` from the
verification rig's stance, and the mobility chain hangs below the waist joint — 0.15 is exactly the
waist offset. A check that does not reproduce the exact rig state measures its own difference.

### Coverage now

**Tier 1: 8/8 · Tier 2: 8/8 · Tier 3: 8/8** (7 measured, `FRYING_PAN` inherits the spoon's values
because the rig has only two arm sockets and it could not be placed — still `[UNTUNED]`).
**Tiers 4-12: 0 of 72**, ~2,160 credits, art for zones that do not exist.
