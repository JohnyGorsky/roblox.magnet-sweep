# 0021 — You walk into the factory; nothing teleports you

**Status:** Accepted · 2026-09-06 · Job 023
**Makes literal:** [0003 — forward is the only direction](0003-forward-is-the-only-direction.md)
**Changes:** `ZoneManager.sendTo`, a shipped function, and the gate enforcement that lives inside it

## Context

[0003](0003-forward-is-the-only-direction.md) is unambiguous:

> *"The factory is **one physically continuous corridor**, zone 1 through zone 12 … There is no
> zone-select menu. You reach zone 5 by walking through zones 1 to 4."*

The shipped code does the opposite. `ZoneManager.sendTo` ends with:

```lua
char:PivotTo(CFrame.lookAt(z.entry, Vector3.new(z.entryLook.X, z.entry.Y, z.entryLook.Z)))
```

That is a hub-and-spoke teleport wearing a corridor's clothes. It was reasonable when it was written —
no zone existed, `Workspace.Zones` still does not exist, and a registry that can put a player at a
zone's entry point is the obvious way to test one. Nothing had a physical location to walk to.

Job 023 is the first job that builds a room, so it is the first job where the difference is
observable. The owner described the factory as *"long corridor, with multiple zones, each has doors
like the first ones"* and, asked directly, chose **walk**.

The choice had to be made before anything was built, because it decides **where floor 1 physically
goes**, and that is not a thing to discover halfway through placing a room.

## Decision

**A player enters a zone by walking through a door.** No script relocates a character to reach
content.

1. **Floor 1 is built physically attached to the Workshop**, its entry aligned to the real clear
   opening in `Hub.Room.Wall.F00_GATE_FRAME`.

   🔴 **That opening is 42 wide, centred z = 41, with 22 studs of head height — NOT the frame's
   62 × 24 bounding box at z = 31.** An earlier draft of this record said the latter, and it was
   wrong. Measured in Edit 2026-09-06:

   | | Measured |
   |---|---|
   | Frame bounding box | centre (1790.7, 12, **31**), size 62 × 24 × 7.5 |
   | `Infill` — solid, **`CanCollide = true`** | 20 × 24 at z = **10** — it fills a third of that box |
   | `Header` — the true lintel | 42 × 2 at z = **41**, underside y = 22 |
   | Character-box sweep across the door plane | **32 of 36 slots blocked** |

   Build to the bounding box and the corridor centreline lands **10 studs off**, a third of its mouth
   opens onto a collidable metal slab, and the clear height is 2 studs short. This is the workspace's
   own *"a bounding box says where the OBJECT is, not its mouth"* rule, and it very nearly went into
   an Accepted record as a build instruction. `Config/WorkshopLayout.luau:194` already had the right
   number — `FACTORY_ENTRANCE.alongFacet = 41`.

   **Mark the opening with an Attachment at placement time** rather than re-deriving it from a
   bounding box in any later job.

   The corridor runs outward from there, and zones 2–12 continue outward from zone 1.
2. **`ZoneManager.sendTo` stops moving the player.** What survives is the half that matters: the
   **Magnet Power gate check** (see *The trap* below).
3. **The Factory Entrance station stops being a transport** and becomes what §61 already describes —
   the thing you pull to open the door. `StationService.enterZone`'s server-side proximity check
   stays exactly as it is; only its effect changes, from "place the player at the entry" to "open
   this gate for them".
4. **`Zone1Spec`'s `ORIGIN (0, 0, -200)` is dead.** It predates the Workshop moving to x ≈ 1556 in
   job 020, and under this decision a zone's origin is no longer free to choose — it is dictated by
   the door it hangs off.
5. **Teleporting a character remains legal for exactly one thing: respawn.** Dying to a guardian or,
   once [0020](0020-the-lockdown-replaces-the-factory-cycle.md) lands, to the Lockdown, returns you
   to the Workshop. That is a death, not travel, and the player understands it as one.

**MagRail is untouched.** 0003 already carved out the one-way inbound ride home from a Service Hub;
this decision is about how you go *out*, and the answer has always been *on foot*.

## What is on the other side of that door today — measured, not assumed

Because "a door frame with nothing behind it" turned out to be wrong in **both** halves:

| | Measured in Edit, 2026-09-06 |
|---|---|
| **The door is shut** | `Hub.Common.Fixtures.FACTORY_ENTRANCE.mesh` is a `CanCollide` MeshPart filling the aperture — a ray up from the threshold hits it at y = 15. It has a `SurfaceAppearance`, so a script cannot re-skin a replacement |
| **There is no floor outward of it** | floor at x = 1780 → `Tile` y = 0; at x = **1795, 1840, 1900 → VOID.** `FallenPartsDestroyHeight` is −500 |
| **Job 021's collar is in the way** | a downward ray at x = 1810 hits `Backdrop.L1_F00` at y = 48 — 20 studs out from the door, across the path |
| **A gap in the perimeter beside the door** | the only free slots in the whole door-plane sweep are z = 69–75 — outside the frame, over that void |

So three of this job's first tasks are *making the door open*, *making a floor exist*, and *cutting the
backdrop* — none of which is "build a room".

## Consequences

- **Zone placement becomes load-bearing geometry.** Every zone's entry must physically meet the
  previous zone's exit. A misalignment is now a visible hole in the world instead of a wrong number
  in a registry, which is strictly better — the editor shows it.
- 🔴 **Streaming gets harder in exactly the way 0003 predicted.** Adjacent chunks are now genuinely
  adjacent, so two zones will be in view together at a door. The Workshop is already **3,595 parts**
  against `MAX_PARTS_IN_VIEW` **1800**; a teleport meant the two never had to coexist and a doorway
  means they do. **Job 023 must measure this at the door**, not assume it.
- **The registry keeps its real job.** `zoneContaining`, `zoneOf` and the AABB bounds are used more,
  not less: "am I inside the room" is now what decides whether a guardian chases you and whether you
  have reached safety.
- **`Registered.entry` / `entryLook` stop being a teleport target** and become what the door frame
  is, which is where a zone's chunk begins.
- The player can see zone 2's door from inside zone 1. Depth becomes legible with no UI, which is the
  whole reason 0003 exists.

## The trap

🔴 **The teleport is currently the only thing enforcing the Magnet Power gate.** `sendTo` checks
`MagnetState.stats(player).Power` against `Config/Zones`'s `gate` and refuses with
`MAGNET POWER %d REQUIRED — YOU HAVE %d`. Delete the `PivotTo` carelessly and the gate goes with it,
and the physical door becomes decoration — which is [PITFALLS #52](../PITFALLS.md), a producer with no
consumer, in reverse.

So the gate check has to **move to the door**, server-side, before the door can open. And it must be
the *server* that decides the door opens: `StationService.enterZone`'s comment records that the first
version took a tier number off the wire, and that the proximity check was the only reason a modified
client could not walk into any zone from anywhere. A door that opens because a client asked it to is
that bug again, with a hinge on it.

⚠️ Note also that this has **never been exercised**. Only tier 1 exists, so every wrong tier is
refused by the `byTier` lookup before the gate check runs, and the test passes for the wrong reason.
The first zone-2 door is what arms it.

## The check

🔴 **First, make the check able to fail.** `Magnet.START.Power` is **10** and zone 1's `gate` is
**10**, so *every player is at or above the gate from their first second alive*. A test that walks a
default player at the door and watches them get in proves nothing — it passes identically whether the
gate works or has been deleted. That is
[PITFALLS #2](../PITFALLS.md) and the workspace's own *"a verification must be able to fail"* rule.

So the test starts by **lowering** the subject's Power below 10 with `power.grant`, and only then:

A player with Magnet Power **below 10** must be unable to reach floor 1 **by any means** — walking
into the door, pressing the station prompt, or firing `RequestEnterZone` directly. Verify all three in
Play, not in Edit. If any lets them through, this decision has traded a working gate for a prettier
transition.

⚠️ **`zone.jump` is a second sanctioned teleport.** `DevTools.luau:69` registers it, and the *"exactly
one thing: respawn"* carve-out above does not cover it. It is a dev command and may stay — but it must
be named as an exception rather than quietly contradicting this record.

⚠️ **`RequestEnterZone`'s own spec note goes stale here.** `Remotes.luau:92` still reads *"Move the
player into a built zone"*; under this decision it opens a door. Left unedited that is
[PITFALLS #52](../PITFALLS.md) — a lie in a table — which is the pitfall this record cites against
losing the gate.
