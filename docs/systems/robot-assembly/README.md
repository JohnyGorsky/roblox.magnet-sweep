# Robot assembly

The Robot Bay: where a fridge door becomes armour. The rig itself is
[systems/robot-rig](../robot-rig/README.md); this is the player-facing half.

## Seven slots

| Slot | Role |
|---|---|
| **Head** | targeting / intelligence |
| **Core** | primary energy and power |
| **Body** | HP and armour |
| **Left Arm** | weapon or utility |
| **Right Arm** | weapon or utility |
| **Mobility** | legs, wheels, tracks, hover |
| **Back Module** | support ability |

Arms are interchangeable. **Giant Spoon + STOP Sign** is a legal build and the design actively wants it.

## The starter robot — decided 2026-09-05

**The game GIVES a new player a fixed, assembled robot.** Head, Core, Body, one Arm and one Mobility,
already bolted together. Everything found afterwards *replaces* a piece.

🔴 **This exists because the catalog cannot supply a first robot on its own.** Measured against
`docs/content/parts-catalog.md`:

| Tier | Slots with a Common part | Slots with **none** |
|---|---|---|
| 1 | Body, Core, Head | **Arm, Back, Mobility** |
| 2 | Arm, Body, Head | **Back, Core, Mobility** |
| 3 | Core, Head, Mobility | **Arm, Back, Body** |
| 4 | Core, Head | **Arm, Back, Body, Mobility** |

**No tier has a Common for every slot.** A robot built only from Commons in the Color Workshop is a
head, a core and a torso — it cannot move and it cannot fight. Standing one on a pad, it reads as
broken rather than as unfinished, which is exactly how it was received.

⚠️ `docs/systems/boot` defines the starter **magnet** (Power 10 · Radius 12 · Drive 16 · Capacity 30)
and says nothing about a starter **robot**. That gap is what this section closes.

**Why "given" rather than "add Common parts to every tier":**
- Swapping your first *found* part into a working robot reads as an upgrade. Finding the piece that
  finally makes your robot able to move reads as having been broken until then.
- Filling the holes would need a Common Arm, Back and Mobility in tier 1 alone, and the same again in
  tiers 2, 3 and 4 — a dozen catalog entries and a dozen models to fix a first-five-minutes problem.

**Still to decide:** which specific parts the starter loadout uses, and whether they are real catalog
entries (findable, recyclable) or a distinct "rusty starter" set that exists only at spawn.

## The visual philosophy (section 39)

Robots must look **homemade**. Not sleek humanoid sci-fi.

> asymmetrical · ridiculous · recognisable objects · mismatched colours · chunky · physical · funny

Traffic Light head + Refrigerator body + Spoon arm + Excavator Bucket + Motorcycle wheels + Turbocharger
is **good**. If a build starts looking coherent and designed, something has gone wrong.

## Installation (section 42)

The robot physically stands in the Bay. Installing a part is a sequence, not a menu confirm:

```
crane descends → grabs the old part → KRRRK → detaches
new part lowers → VRRRR → RobotMount aligns to the socket → CLUNK
bolts spin → ⚡ electricity
robot tests the component: one huge practice sweep
        ↓
GIANT SPOON INSTALLED
```

The practice swing plays the part's actual `AnimationProfile`, so it costs nothing and it is the payoff —
the game showing you that the absurd object you dragged home is now genuinely part of your machine.

Bay machinery is `TweenService` + constraints, not robot animation.

## Duplicates (section 40)

A duplicate part is never wasted. Two exits, another real decision:

| | |
|---|---|
| **REINFORCE** | Mk I → Mk II → Mk III. A small stat increase |
| **RECYCLE** | a substantial Coin payout |

## Part Archive (section 41)

The Workshop wall showing every zone's parts as silhouettes:

```
MEGA KITCHEN
Colander ✅   Blender Motor ✅   Fridge Door ❓   Giant Spoon ✅
Frying Pan ❓  Serving Cart ✅   Toaster Coil ❓  Golden Tenderizer ❓
```

A silhouette fills in on **`SECURED`** — reaching a Service Hub — not on sighting the part. The Archive
records what you brought home, not what exists.

Completing a zone's collection awards **cosmetics, never combat power**. The collector track must not
become a power track, or completion stops being optional.

The Archive survives Overclock ([decision 0013](../../decisions/0013-overclock-not-rebirth.md)).

## Naming

Players name their robot — MAGNETRON, SPOONATOR, SCRAP KING, BOB. Shown at Arena entrance, on victory,
on the leaderboard and in the Bay.

Filtering is **two calls, not one**, and Roblox removes games that skip it:

1. `TextService:FilterStringAsync(text, fromUserId, Enum.TextFilterContext.PublicChat)` →
   a `TextFilterResult`. This is **not** displayable text.
2. `result:GetNonChatStringForUserAsync(viewerUserId)` — the documented case for exactly this
   ("non-chat text that one specific user can see, **such as the name of a pet**"). It is age-aware per
   recipient, so a nameplate is filtered per viewer.
   Use `GetNonChatStringForBroadcastAsync()` **only** for text baked into something server-wide and
   persistent that outlives its author.

Server-only. Never per-keystroke. Wrap in `pcall` and **never display the name if filtering fails**.

> ⚠️ `FilterStringAsync` **throws if `fromUserId` is not on the server** — so re-filtering a saved robot
> name when its owner is absent (a leaderboard, an Arena robot whose owner left) will error. Decide the
> storage form now: filter on *write* and store the filtered string, or accept that display needs the
> owner present.
>
> `TextService:FilterAndTranslateStringAsync` is dead — all calls return an empty object.

## Build archetypes (section 52)

Not classes — emergent shapes the part pool supports:

**TANK** heavy body, shield, tracks · **SPEED** wheels, light armour, fast weapons · **BRAWLER** spoon,
excavator, hammer, knockback · **RANGED** coil cannon, exhaust cannon, ion lance · **CONTROL** magnet
arm, crane hook, shields — moves enemies around the Arena.

If, after tuning, only one of these wins, the Arena is broken regardless of how good the individual
parts feel.
