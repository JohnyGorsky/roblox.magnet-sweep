# Job 023 — implementation plan

**Project**: `roblox.magnet-sweep` · Written 2026-09-06, after two independent reviewers and five
decision records (0021–0025).

## The order, and why it is this order

Reviewer 1's build order, adopted. It front-loads three tasks that are **not room design at all**,
because the premise this job was written on turned out to be false:

> *"There is a door frame in the Workshop wall and nothing behind it."*

Measured: the frame holds a **closed, collidable door**, there is **no floor** outward of it, and job
021's backdrop collar sits **across the path 20 studs out**. So:

| # | Step | Ends when |
|---|---|---|
| **0** | **Settle & de-risk. No geometry.** The exporter, the registration path, the parts data | The round-trip in 0023's check passes once |
| **1** | **Open the door, stand on a floor, cut the backdrop** | You can walk out of the Workshop and back in, in Play, on a phone preset |
| **2** | **Zone identity + the streaming measurement** | `zoneContaining` answers correctly **both ways**, proven in Play |
| **3** | **Room shell + static dressing** | The owner has walked it and said the proportion is right |
| **4** | **Scrap** — the room becomes playable | You can sweep a real room. **Stop here and let the owner play it** |
| **5** | **The item** — plinth, 5-second channel, SECURED | 0022's check passes both ways |
| **6** | **The boss** — inert first, then lethal | Both outcomes reachable: stand still and die, run and live |
| **7** | **Export, and stub the zone-2 door** | The room exists in git |

**The Lockdown is job 024** (decision 0020, deferred). ⚠️ 0020 is Accepted and currently **unowned** —
job 024 does not exist yet. Create it, or 0020 is a decision nobody is carrying.

🔴 **Steps 4 and 5 answer the question the whole game rests on** — *do they think "I want that on my
robot"?* Steps 6–7 are much cheaper to tune once that is a yes. Building the chase before the room is
worth being in optimises the wrong thing.

---

## Step 0 — Settle & de-risk (no geometry)

Nothing here places a wall. Every item is a prerequisite that a later step silently fails without.

### 0.1 🔴 The exporter — `Tools/export-room.luau`

[0023](../../docs/decisions/0023-the-room-is-placed-the-contents-are-spawned.md) makes hand-placed
geometry the **only** way the world is built, which makes the exporter the **only** path it has into
git. 0019 demanded it a job ago — *"or this record is just permission to lose the room"* — and it was
never written. `Config/WorkshopLayout.luau` is the hand-typed stand-in, and it has **already drifted**
(documents `L1_COLLAR`…`L5_ROOF`; the world contains `Backdrop.L7_roof`).

- Walks a model, emits a Luau module of `{name, class, size, cframe, material, colour, attributes}`.
- Round-trips: a rebuild script reads the module and reproduces the model.
- **The check (0023's):** in a scratch copy, delete the room, rebuild from the export, compare part
  counts and a bounding box. Until that works once, the room is *saved*, not *exported*.

⚠️ This is a one-shot **rebuild** tool for disaster recovery, not a build pipeline. Re-running it over
a live room is exactly what 0023 forbids — it would erase the owner's fixes. Name it so nobody
mistakes it: `restore-room`, not `build-room`.

### 0.2 🔴 Zone registration for a placed room

`ZoneManager.register`'s only call site is `ZoneBuilder.luau:334`, inside `ZoneBuilder.build`, which
never runs (`BUILD_GENERATED_WORLD = false`). **A placed room therefore registers with nothing.**

Under [0022](../../docs/decisions/0022-the-workshop-is-hub-zero.md), `zoneContaining` returning `nil`
means *the Workshop — safe and secured*. So without this, standing in floor 1:

- the guardian gives up **instantly**, and
- the part secures **the moment it is detached**,

and **both tests pass while doing nothing.** This is the single most dangerous silent failure in the
job.

**Build:** `ZoneRegistrar.server.luau`. Finds every model under `Workspace.Zones` carrying a `Bounds`
part with `ZoneId` / `ZoneTier` attributes, derives `min`/`max` from that part, reads `Entry`,
`EntryLook` and `Exit` **Attachments**, and calls `ZoneManager.register`.

🔴 **Attachments, not bounding boxes.** This job has already been bitten once: the factory doorway's
62 × 24 "aperture" was the model's bounding box, and the real opening is 42 wide at a different
centre. Mark features at placement time.

### 0.3 🔴 `weight` and `powerRequired` on the parts catalog

`Config/Parts.luau:34-35` defines both. **No row in `PartsCatalog.ALL` sets either**, and
`PartsCatalog.validate()` checks only `slot` and `rarity` — so the gap is silent at boot.

Three things depend on it:

| Depends on | Without the data |
|---|---|
| `RequestDetach`'s declared contract (*"checks Magnet Power against the part's requirement"*) | no threshold to compare against |
| `MagnetState.setCargo` → `Magnet.carrySpeed` — **already implemented**, waiting for a caller | the carrier is never slowed |
| 0024's *"slower than a free player, faster than a carrying one"* | **no slowed player to be faster than.** The chase is unloseable or unwinnable |

Author all 8 tier-1 rows, and **extend `validate()` to require them**, so the next tier cannot repeat
the omission silently.

⚠️ [0025](../../docs/decisions/0025-one-plinth-one-item.md)'s trap: with **one** plinth, a
`GOLDEN_GEAR` that a Power-10 player cannot detach leaves the room's only prize inert. Either every
tier-1 part is detachable at Power 10, or the roll respects the channeller.

### 0.4 Config and doc reconciliation

Accepted decisions currently contradict shipped files. 0020 already left two un-updated; do not make
it three.

| File | Change |
|---|---|
| `Config/Zones.luau` | delete/repoint `RARITY_WEIGHT` and `SPAWN_PER_CYCLE` (0025); annotate `CYCLE_PERIOD`/`CYCLE_WARNING` as 0020's, not 0006's |
| `docs/systems/guardians/README.md` | *"there is no combat"* → 0024 |
| `docs/build/08-cargo-and-escape.md` | catch outcomes → 0024; death promoted P1 → **P0** |
| `docs/systems/factory/README.md` | pool-of-8 → 0025; three-cycle model → 0020 |
| `Remotes.luau:92` | `RequestEnterZone` says *"Move the player into a built zone"*; under 0021 it opens a door |
| `0006`, `0008`, `0014`, `0019` | add supersession banners in the file, house style per `0012:15-18`. `INDEX.md` alone is not enough — the audit found `0006` had none |
| `0020` | fix the §84 misattribution (it is `docs/game/core-loop.md:70`, *"derived — not a spec value"*) |
| `Zone1Spec.luau` | 🔴 **fence it.** It still passes `validate()`, and `zone.rebuild` will materialise a 430-part room 1,800 studs away **and register it**, after which `zoneContaining` returns `COLOR_WORKSHOP` for a region nobody is in |

---

## Step 1 — Open the door, stand on a floor, cut the backdrop

The three tasks that are not room design. **Measured facts this step is built on:**

| | Measured in Edit, 2026-09-06 |
|---|---|
| Real clear opening | **42 wide, centred z = 41, head height 22** (`Header` 42 × 2 at z 41, underside y 22) |
| `Infill` | 20 × 24 at z = **10**, `CanCollide = true` — fills a third of the frame's bounding box |
| The door itself | `FACTORY_ENTRANCE.mesh`, collidable, **32/36 slots blocked**, carries a `SurfaceAppearance` |
| Floor outward | x = 1795 / 1840 / 1900 → **VOID**, over a 2,000-stud drop |
| Job 021's collar | `Backdrop.L1_F00` at x ≈ 1810, y 0–48, across the path; L2 at 1826; roof deck to x ≥ 1850 |

### 1.1 The door leaves

🔴 **Human work in Studio, not a script.** The door is a single closed MeshPart with a
`SurfaceAppearance`, and a script cannot re-skin a replacement (PITFALLS #63). It needs authoring as
**two leaves** that slide or swing, keeping the existing surface.

Server-gated through `StationService.playerIsAt` — the existing proximity check, which
`StationService.enterZone`'s own comment records as *the only thing* standing between a modified
client and every economy remote. The Magnet Power gate that currently lives inside `sendTo` **moves
here** ([0021](../../docs/decisions/0021-you-walk-in-nobody-teleports.md)'s trap: delete the `PivotTo`
carelessly and the gate goes with it).

⚠️ **`zone.jump`** (`DevTools.luau:69`) is a second sanctioned teleport 0021 does not carve out. Keep
it, but name it as a dev exception.

### 1.2 Floor and shell outward of x ≈ 1790

Placed, at the world's scale. **Not from `ServerStorage.Kit`** — see the scale trap below.

### 1.3 The backdrop cut — **decided: a visible opening**

The owner chose to cut through rather than tunnel behind, which fits the approved "bar wall, the
factory shows through" facet.

🔴 **Consequence, not polish:** job 021's headline result was sky **45.7 % → 0.0 %**. Cutting
`L1_F00` re-opens sky at the exact spot every player looks when leaving. **The corridor's own roof
goes in during this step**, not later. Re-measure the sky fan at the threshold before step 1 is
called done.

### 1.4 The perimeter gap

A ~2.5-stud full-height slot at z ≈ 69–75 beside the entrance, over open void — the only free slots in
the whole door-plane sweep. Workspace rule: **never leave a flat fall-off edge.** Close it or confirm
it is intended.

**Step 1 is done when:** you walk out of the Workshop and back in, in Play, on a phone preset, and the
sky fan at the threshold still reads 0 %.

---

## Step 2 — Zone identity and the streaming measurement

### 2.1 Registration, verified both ways

Place the `Bounds` part and the Entry/Exit Attachments; `ZoneRegistrar` registers the room.

🔴 **The check must be able to return the wrong answer.** `zoneContaining` must return
`COLOR_WORKSHOP` **inside** the room and `nil` **in the Workshop** — test *both*, in Play. Testing only
the inside cannot distinguish "registered correctly" from "returns nil everywhere", which is the
failure mode.

### 2.2 The streaming measurement 0021 asked for

Already taken, and it is bad:

| Radius from the door | BaseParts |
|---|--:|
| 300 | 1,697 |
| **500** | **3,523** |
| 800 | 3,597 |

against `Perf.BUDGET.MAX_PARTS_IN_VIEW` = **1800** — **196 % before floor 1 exists.** Aggravating
factors: `Workspace.Hub` is a **Folder** holding 1,228 loose BaseParts that stream individually, plus
178 lights.

Re-measure **with the corridor present**, and act on it here rather than discovering it at step 7:
the room as one `Model` with an explicit `ModelStreamingMode`, and the Hub's loose parts grouped so
they stream as units.

⚠️ Mobile has still **never been measured on a device**, and `findings/0005` records the budget being
knowingly exceeded 2× with the honest next step named as *"a real-device reading, not a number
argument"*. The Device Emulator has no scripting API — **this one needs the owner.**

---

## Step 3 — Room shell and static dressing

Placed by hand, staged in `DemoRoom` for approval, eye-level screenshots, before anything enters the
world.

🔴 **Scale.** `KitSpec.TILE` is **8** and `KitSpec.WALL_H` is **12**; the built Workshop tile is
**15.8** and its wall **24**. Building from the kit produces a **half-height tunnel butted onto a
24-stud wall** at the one place both are visible — `findings/0008` (*"i just entered game and realised
how big all is"*) repeated. **Use the DemoRoom patterns at `SOURCE_SCALE = 0.5`.**

The owner's five requirements are build requirements, not suggestions:

| # | Requirement | How |
|---|---|---|
| 1 | The path is not always straight | the diagonal from both concept sheets |
| 2 | Big walls like the main building | job 021's layering recipe, adapted to a non-circular room |
| 3 | Crates and static elements with scrap around them | `Prop_Crate`, `Prop_RobotArm`, `Ind_Conveyor`, `Ind_Tank`, `Ind_Fan` |
| 4 | An area where the boss sits and guards its item | 🔴 **mid-room** — the owner overruled both sheets, which post it at the far exit |
| 5 | Doors through to the next area | `Struct_Gate` + `Struct_Ramp`, stubbed at step 7 |

**Colour — signal colours win.** Structure stays industrial; accents are candy pink `#FF6FB5`, mint
`#7FE6C4`, lemon `#FFE066` on the paint machines, panels, plinth and light gels. 🔴 **The gold plinth
and green chevrons from the art do not survive** — `#FFC21A` is Legendary/Arena and `#3FD64B` is
Recycle/Uncommon, and `Zone1Spec.luau:117-121` already warns about the gold case in almost these words.
Crates lose green and orange.

⚠️ `ZoneSpec.RESERVED` enforces this — **but only on generated specs.** A placed room has no
validator. The discipline is human here.

**Lighting:** the corridor is an **interior**, lit by its own lights and roof. Live `ClockTime` is
16.2 against a Bootstrap assertion of 14, and a 24-stud wall at 16.5 casts a shadow 2.67× its height —
a long corridor is the worst possible geometry for a low sun.

**Signage:** the 10 slogans from the sheets, via `Sign_NeonSlab`. Cheap, and most of what makes the
room read as authored.

---

## Step 4 — Scrap (the room becomes playable)

Contents, so **spawned** — into editor-placed volumes ([0023](../../docs/decisions/0023-the-room-is-placed-the-contents-are-spawned.md)).

- Place `ScrapVolume` parts; a server script reads their world-space bounds and calls
  `ScrapService.spawnBox(centre, halfX, halfZ, count, tier)`, which already takes world space and just
  needs a caller. Today its only callers are behind the dead `BUILD_GENERATED_WORLD` flag and the
  `scrap.spawn` dev command — **the sweep layer currently only exists behind a dev command.**
- 🔴 **Scrap renders as grey primitives today.** `ScrapSpec` has **no `mesh` field** — each def is
  `size` + `shape = "Cylinder" | "Ball"` — and `ScrapService.newPart()` does `Instance.new("Part")`.
  The eight `.glb` meshes exist (`assets/generated/scrap/`), but nothing binds them. Getting from
  primitives to recognisable screws and gears means **per-type pooling**, against decision 0005's
  mandatory-pooling rule. *"Nothing to generate"* was true; *"nothing to build"* is what it will be
  read as, and that is false.
- 🔴 **The `PIPE` teaching object will not appear by chance.** `weightShare = 1` against a tier total
  of 100, ~56 pieces per room → **~0.6 expected pipes**. The first thing in the game you are meant to
  visibly fail to lift is usually absent. Give the volume a `ForceType` attribute and place a few
  deliberately, early and in plain sight.

**Step 4 is done when the owner has played it.** Stop here.

---

## Step 5 — The item

Plinth **placed**; the part on it **spawned** and re-rolled on a **30–60 s cooldown**
([0025](../../docs/decisions/0025-one-plinth-one-item.md)).

1. **Roll** — 60 / 30 / 8 / 2 across Common / Uncommon / Rare / Legendary. One table. `grep` afterwards
   to prove `RARITY_WEIGHT` is gone.
2. **The 5-second channel** — server-timed. Moving cancels and resets to zero. The plinth **locks to
   the first player who starts**; a second player cannot channel until the first stops. Never trust a
   client-side timer.
3. **Bind `RequestDetach`** — the first of the four unbound remotes. Checks Power against the part's
   `powerRequired` (step 0.3).
4. **Carry** — `MagnetState.setCargo`, which already applies `Magnet.carrySpeed`. Fire
   `CargoStateChanged`.
5. **`SalvageBreach`** — the alarm, and the guardian's wake trigger.
6. **SECURED at the entry doors** — `PartSecured`, profile write, banner + sound + VFX. 0008 requires
   it be *"a genuine event… not a quiet inventory increment"*.

🔴 **0022's trap: the chase ending and the transfer are one event, or neither.** Ship the boss without
the secure and the job has shipped a way to lose parts — run home, feel safe, disconnect, part gone,
because an unsecured part is never written to the profile.

**The check (0022's), both directions:** steal → cross the doors → disconnect → rejoin: the part is in
the profile. Steal → disconnect **inside** the room: it is gone.

---

## Step 6 — The boss

**Inert first.** It is scenery ~95 % of the time and must be *interesting to walk past* before it is
dangerous.

### 6.1 The asset

**The market is empty** — five Creator Store searches (sweeper robot / roomba / security robot /
cleaning drone / the owner's own inventory) returned nothing usable; relevance collapses after ~2 hits
in every query. So: **Meshy, meshy-6 + refine, 30 credits, approved.** Concept image first (3 cr) for
approval before the mesh spend.

🔴 **Body only.** The brush roller, beacon and eye must be **separate parts** to rotate — a cylinder,
a dome and a neon disc, which the kit already has. One clean body mesh beats gambling on Meshy
separating moving pieces.

### 6.2 Movement — [0009](../../docs/decisions/0009-robots-are-animated-not-driven.md)'s pattern

One unanchored assembly, `AlignPosition` + `AlignOrientation` toward an AI goal,
`SetNetworkOwner(nil)`. Brush and beacon are `HingeConstraint` motors — **decorative actuators that
never propel it.** No R15 rig, no Motor6D skeleton, no skinned mesh, no animation uploads.

⚠️ **0009 has no code behind it** — the Arena does not exist. This is its first implementation, not a
reuse.

### 6.3 Behaviour

| State | Rule |
|---|---|
| Inert | until a part is stolen ([0014](../../docs/decisions/0014-the-owning-guardian-chases.md), still standing) |
| Wake | eye cyan → `#E03A2F`, beacon spins, siren — **visibly at the moment of the steal** |
| Chase | slower than a free player, faster than a carrying one (needs step 0.3's data) |
| Catch | **server radius ~6 studs, ~0.5 s dwell.** Not `Touched` |
| Kill | [0024](../../docs/decisions/0024-the-guardian-kills.md) — costs the **carried item only** |
| Give up | at the entry-door threshold, `zoneContaining` → `nil` |

### 6.4 🔴 Death does not exist anywhere

There is **no `Humanoid.Died` connection in `studio_game/` at all**. Respawn at the Workshop, the cost,
and **telling the player why** are all new and all P0 under 0024. An unexplained kill reads as the
game cheating, not as a rule.

⚠️ `docs/systems/guardians` flags *"two thieves, one guardian"* as unanswered *"before zone 2 ships"* —
floor 1 with 10 players hits it first.

**The check:** steal and stand still → you die. Steal and run for the doors → you live. **Both must be
reachable by a competent player**, or the speed numbers are wrong and the chase is theatre. Then sweep
for two minutes carrying nothing with the guardian awake: it must never touch you.

---

## Step 7 — Export and stub

- Run the exporter (step 0.1) and commit the room.
- Stub the zone-1 → zone-2 door so zone 2 has a contract to build against.
- Update `ASSETS`/registry with the Meshy boss and its security scan.

---

## Traps, collected

1. **Heavy `execute_luau` crashes Studio** — one folder per call, check what survived. And under 0023
   a re-run is forbidden anyway.
2. **Studio Sync is two-way** — deleting an instance deletes the source file.
3. **No hardcoded instance path into another zone** — under streaming that is a nil-index crash
   (0003's own rule).
4. **Coplanar faces** — separate same-facing surfaces by 0.06.
5. **Verify in Play at eye level.** Edit is never evidence.
6. **`PointLight`s are useless on a backdrop** — `QualityController` clamps non-`Hero` lights to 10
   studs on Low. `Neon` is the only lighting that survives every tier.
7. **Atmosphere cannot substitute for a roof** — haze acts on distance and erases the backdrop with it.
8. 🔴 **The zone-1 gate can refuse nobody** — starting Power is 10 and the gate is 10, and
   `Bootstrap.server.luau:111` asserts it must be so. Any test of it must **lower Power first** with
   `power.grant`, or it passes whether the gate works or has been deleted.
