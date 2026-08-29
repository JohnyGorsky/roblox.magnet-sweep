# The job ladder — proposed work order

[The manifest](README.md) is organised **by system**, which is how you find things. It is not a work
order: group 04 alone is 37 items, far more than one job.

This page slices the same items into **job-sized pieces in dependency order**. One row = one
`python tools/job.py new --project magnet-sweep "..."`. Each names what it delivers, what must exist
first, and what it needs from a human.

**28 jobs to the MVP gate.** Numbering starts at 002 because
[job 001](../../Jobs/001/final-summary.md) was the repo and design pack.

> **Sizing rule:** a job is one sitting to a few. If a row starts feeling like two things, it is two
> jobs. Splitting late is cheap; a half-finished job is not.

---

## Phase A — nothing else can start (jobs 002-003)

| # | Job | Delivers | Needs first | Needs you |
|---|---|---|---|---|
| **002** | **Place + sync probe** | The place exists and its id is recorded. `.jobconfig.json` rewritten with an **observed** layout, `UNVERIFIED` cleared. Flat vs nested, which service folders sync, which suffix makes which class, whether `.client.luau` runs twice | — | **Create the place, give me the id, keep Studio open on it.** Decide access + social slots (`MaxPlayers` is settled at 12) |
| **003** | **Config skeleton** | Six config modules, the remote-definitions module, the server rate limiter, the logging helper, and the **dev/test tools** — forced Shift, jump-to-zone, grant Power, spawn a named part | 002 | — |

> Job 003's dev tools are not "later". This game has three overlapping randomised cycles; without forced
> seeds and a jump-to-zone, every bug from job 008 onward is unreproducible.

## Phase B — the look, before any room is built (jobs 004-007)

70-80 % of the world is kit. Building rooms before the kit means rebuilding them.

| # | Job | Delivers | Needs first | Needs you |
|---|---|---|---|---|
| **004** | **Material kit** | The nine `MaterialVariant`s and their PBR texture sets. Includes the 18 flat greyscale metalness/roughness maps | 002 | Approve generating or sourcing 9 texture sets |
| **005** | **Kit geometry** | Floors, walls, structures, industrial props, the neon slab sign, hazard-stripe tiling that survives scaling | 004 | — |
| **006** | **Lighting & atmosphere** | `LightingStyle = Realistic`, Atmosphere, Sky, `EnvironmentSpecularScale` tuned against a chrome test object, the Bloom/ColorCorrection/SunRays chain | 005 | Set the lighting style in Studio — it is not script-writable |
| **007** | **Quality tiers** | **The reference device and the frame-time / memory / draw-call budgets chosen**, then the tier detector and the client tier controller, measured at all three tiers | 006 | **Device Emulator** — I ask before switching your Studio into it |

> Job 007 picks the numbers every later measurement is compared against. Doing it here means "is this
> fast enough?" has an answer for the rest of the project.

## Phase C — THE GATE (jobs 008-010)

The whole project is gated on one question. These three jobs answer it, in a grey room with a pile of
bolts. **If the answer is no, jobs 011 onward are wasted.**

| # | Job | Delivers | Needs first | Needs you |
|---|---|---|---|---|
| **008** | **Magnet core** | The four-state machine, the object pool, `MaxConcurrentPull` with a REACT queue, client pull motion, batched server grant + spawn validation | 003, 007 | — |
| **009** | **Magnet feel** | The pull-force curve (fast → straining → **shakes and refuses**), Radius driving both ranges with REACT ~40 % wider, the four stats, Capacity + SCRAP FULL, Flow x1-x5, MAGNET RUSH, all five VFX states | 008 | — |
| **010** | **Magnet sound** | The nine sound families with Flow-driven pitch rise, the strain/release pair, the collection layer | 009 | **Sound ids** — I search and write the spec, you supply |

### 🔴 GATE — play it before job 011

> **When you see a strange object across the room, do you want it?**
> **Does pulling a hundred bolts feel good enough to do for an hour?**

A *feel* judgement, and yours, not mine. If it is not a strong yes, the fix is in jobs 008-010 — pull
weight, the arc into the magnet, the strain audio, the break-free half-second — not in more content.

## Phase D — the loop closes (jobs 011-017)

| # | Job | Delivers | Needs first | Needs you |
|---|---|---|---|---|
| **011** | **Workshop** | Layout, the seven stations, neon signage, the Arena sightline, spawn point, the MOVE NEAR SCRAP prompt | 005, gate | — |
| **012** | **Boot & HUD** | `ReplicatedFirst` handoff, the loading screen driven by real stage completion, the title card, the main HUD, the banner system, mobile safe-area layout | 011 | Emulator for the safe-area pass |
| **013** | **Zones 1-2** | Both zones as self-contained streamable chunks, their scrap sets, the zone manager, the 1→2 gate with its physical pull | 011 | — |
| **014** | **Hub & return** | The Service Hub after zone 2 with all seven fixtures, MagRail home, the return lane distinct from the outbound route | 013 | — |
| **015** | **Rare cargo** | Physical carried cargo, one at a time, the four weight classes with a speed floor, the detach sequence, the server Power check, SALVAGE BREACH | 014 | — |
| **016** | **Guardians** | Both MVP guardians, layered detection, **inert until theft**, owning-guardian-only pursuit across zones, territory reset vs outside drop, give-up-and-return-home | 015 | — |
| **017** | **SECURED** | The payoff moment — banner, sound, light, VFX — the profile write that happens **only** here, and the cargo HUD | 016 | — |

## Phase E — the robot (jobs 018-020)

| # | Job | Delivers | Needs first | Needs you |
|---|---|---|---|---|
| **018** | **Rig engine** | The ten-joint skeleton, `AnimationController` + `Animator`, seven sockets, the `RobotMount` convention, mount/weld with `Massless`/`CanCollide=false`, the part schema | 003 | — |
| **019** | **The first 16 parts** | 12-16 MVP parts modelled, mounted, with stats. **The first job that needs per-part balance numbers** | 018 | Meshy generation and import; supply ids |
| **020** | **Robot Bay** | The Builder GUI with its 3D preview, the install sequence (crane → CLUNK → practice swing), robot naming with two-call text filtering | 019 | — |

> Job 018 must land before job 019. Build the engine, then the content — otherwise the sixteenth part
> teaches you the engine was wrong.

## Phase F — the Arena (jobs 021-024)

| # | Job | Delivers | Needs first | Needs you |
|---|---|---|---|---|
| **021** | **Arena shell** | Geometry, the Arena Core, release/withdraw with a queue, the disposable robot clone, `AlignPosition` movement on a server-owned unanchored root | 020 | — |
| **022** | **Combat** | The AI priority ladder, **scripted hitboxes from AI state — never from limb positions**, server-authoritative resolution, knockback via aligner `MaxForce` + impulse | 021 | — |
| **023** | **Robot animation** | 10 combat clips + 12 shared clips, played **on the server** so they replicate, priorities set with `Core` understood as *lowest* | 022 | Publish animations, supply ids |
| **024** | **Control & Heat** | Core control detection, the hold timer, the four Heat bands, damage visual stages, ROBOT DISABLED, the ~2 min owner-left grace period. **Measure the concurrent robot count here** | 023 | Emulator |

## Phase G — the economy closes (jobs 025-028)

| # | Job | Delivers | Needs first | Needs you |
|---|---|---|---|---|
| **025** | **Economy** | Recycler with the repair alternative shown side by side, repair, upgrade costs for all four stats | 024 | — |
| **026** | **Persistence** | Profile schema + version, session locking, `UpdateAsync`, **never overwrite a failed load**, `BindToClose`, idempotent grants, scrap auto-recycle on disconnect | 025 | — |
| **027** | **Refresh** | Scrap Refresh, the ~4 min Factory Cycle with its 20-second warning, per-zone pools weighted by the re-graded rarity | 026 | — |
| **028** | **Shifts** | The five Factory Shifts, LEGENDARY PART DETECTED | 027 | — |

### 🔴 MVP GATE — the nine-step check

A new player, unassisted, reaches all nine steps of §84 within ten minutes: collect → upgrade → find →
pull → escape → install → release → repair → *want the next zone*.

If any step needs explaining, the **game** is missing a signal — not the player a tutorial.

## Phase H — post-gate only

Groups [13](13-zones-3-12.md) (zones 3-12, 223 items) and [14](14-endgame-and-launch.md) (endgame,
monetisation, launch). **Do not start these until the MVP gate returns a yes.** Ten more zones do not
fix a loop that is not fun.

---

## The three sequencing rules worth defending

1. **The kit and the lighting come before any room.** Building rooms first means rebuilding them, and
   every visual judgement made before job 006 is made under the wrong light.
2. **The gate sits at job 010, not at the end.** It costs three jobs to find out whether the core works.
   Finding out at job 028 costs twenty-five.
3. **The engine precedes its content, every time.** 018 before 019, 021 before 023, 003 before
   everything. This is [decision 0004](../decisions/0004-parts-are-content-rig-is-the-engine.md) applied
   to scheduling.

## What is deliberately not scheduled

- **Per-part combat stats** — 96 rows of balance work. It first bites at job 019 (16 parts) and
  properly at group 13. It is not a job of its own; each tier's stats belong with that tier's build.
- **Relic Parts** — seven names and nothing else. Its own job, before the Endless Line, well after MVP.
- **Asset sourcing** — no id is sourced until a slot needs one. Jobs 004, 010, 019 and 023 are the four
  that will ask you for assets.
