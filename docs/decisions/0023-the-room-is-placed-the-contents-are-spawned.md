# 0023 — The room is placed; the contents are spawned

**Status:** Accepted · 2026-09-06 · Job 023
**Supersedes:** the *"Zones stay generated"* clause and the split-by-kind table of
[0019 — hero geometry is editor-placed and exported](0019-hero-geometry-is-editor-placed-and-exported.md)

## Context

[0019](0019-hero-geometry-is-editor-placed-and-exported.md) divided the world by **kind**: hero rooms
placed in the editor, zones generated from a spec, because *"they must re-roll; a hand-built zone
cannot refresh"* ([0006](0006-the-factory-refreshes.md)).

That division is wrong, and the owner said so directly:

> *"all places must be built in editor"* · *"not with scripts"* · *"so i can fix them"*
>
> *"whole room must be built, but items they are scripted of course"*

The dividing line is not **hero room vs zone**. It is **what stands still vs what comes back.**

🔴 Two independent reviewers found job 023's intake citing 0019 *approvingly* as its licence to
hand-place floor 1, when 0019 explicitly forbids it for zones. A decision quoted in support of the
thing it forbids is the failure `INDEX.md` opens by warning about — and the fix is not an exception
for zone 1, it is a better line.

## What dissolves the original objection

0019 kept zones generated so they could refresh. [0020](0020-the-lockdown-replaces-the-factory-cycle.md)
changed what a refresh *is*: the Lockdown resets **scrap, the item and the boss** — never the shell.

**Geometry was never the thing that needed to re-roll. The loot was.** An authored room and a
resetting room were never in tension; nobody had written that down.

## Decision

**Every place is built in the editor, by hand, and is never regenerated. Its contents are spawned by
script into markers placed with the room.**

| | Placed in the editor — permanent, hand-editable, exported | Spawned by script at runtime |
|---|---|---|
| **What** | floor, walls, backdrop, roof, doors, conveyors, crates, machinery, signage, the plinth, the boss's post, the room's lighting | scrap, the robot part on the plinth, the guardian |
| **Why** | it is looked at, judged by proportion, and fixed by hand | it respawns, resets and re-rolls |
| **Lifetime** | forever, until a human moves it | until the next refresh or Lockdown |

Three rules follow:

1. 🔴 **Nothing regenerates a room.** `Bootstrap.BUILD_GENERATED_WORLD` stays **false** permanently.
   `ZoneBuilder` and `Zone1Spec` retire as world builders. Any placement work is **one-shot** — a
   script that could be re-run over a room is a script that can erase the owner's fixes, which is the
   whole reason for this decision.
2. 🔴 **Contents reach the world through markers, not coordinates.** Scrap spawn volumes, the plinth,
   the guardian's post and the door leaves are **editor-placed parts and Attachments carrying
   attributes**, and the spawners read them. No script computes where the plinth is from a bounding
   box — *a bounding box says where the object is, not its mouth*, which this job has already been
   bitten by once at the factory door.
3. 🔴 **The room is built at the world's scale, not the kit's.** `KitSpec.TILE` is **8** and
   `KitSpec.WALL_H` is **12**; the built Workshop tile is **15.8** and its wall **24**
   (`WorkshopLayout.luau:64,432`). Building from `ServerStorage.Kit` yields a **half-height tunnel
   butted onto a 24-stud wall** at the one place both are in view — `findings/0008` repeated. Use the
   **DemoRoom patterns at `SOURCE_SCALE = 0.5`**.

**[0017](0017-the-kit-is-generated-from-a-spec.md) survives untouched.** The *kit* is a generated
source **library** — a shelf of parts — and a shelf is not a place. It stays generated for exactly
0017's reason: a hand-built kit could never be in git. What is now forbidden is generating **rooms**
from it.

## Consequences

- 🔴 **The exporter is now the only path the world has into git, and it does not exist.** 0019 already
  demanded it — *"the export must actually be written and actually be run, or this record is just
  permission to lose the room"* — and it was never written. `Config/WorkshopLayout.luau` is a
  hand-typed snapshot, not an export, and it has **already drifted**: it documents `L1_COLLAR`…
  `L5_ROOF` while the world contains `Backdrop.L7_roof`. **This is step zero of job 023**, not step
  eight.
- 🔴 **A placed room must acquire a zone identity.** `ZoneManager.register`'s only caller is inside
  `ZoneBuilder.build`, which never runs — so a placed room registers with nothing and
  `zoneContaining` returns `nil` inside it. Under [0022](0022-the-workshop-is-hub-zero.md) `nil` means
  *the Workshop, safe and secured*: the guardian would give up instantly and the part would secure on
  detach, **both tests passing while doing nothing**. The room carries a `Bounds` part with
  `ZoneId`/`ZoneTier` attributes and a server script registers it.
- ⚠️ **`Zone1Spec` is still live and still dangerous.** It passes `validate()`, and `zone.rebuild`
  will materialise a 430-part room ~1,800 studs away **and register it** — after which
  `zoneContaining` returns `COLOR_WORKSHOP` for a region no player occupies. Fence it or neuter it;
  ignoring it is not enough.
- ⚠️ **§64 says the opposite and is untouched:** *"70-80 % of the environment is reusable primitives.
  Build a kit, not rooms."* Reconcilable — placed shell, kit-sourced pieces — but say it out loud or
  **room 2 costs what room 1 cost**, twelve times over.
- The staging loop the owner already requires — new objects stand in `DemoRoom` for approval, eye-level
  screenshots, before anything enters the world — is now the workflow for *all* places.

## The trap

**"Placed in the editor" quietly means "not in git" until the exporter runs.** Every hazard this
project has already met applies at once: Studio crashing on a heavy `execute_luau` (recovery is *check
what survived*, not *re-run the build* — and under rule 1 re-running is forbidden anyway), Studio Sync
deleting the **source file** when an instance is deleted, and a place restarted mid-session with
unsaved hero assets.

## The check

In a scratch copy of the place, delete the room and rebuild it from the exporter's output. Until that
round-trip has worked once, the room is not exported — it is merely saved, and one crash from being
built twice by hand.
