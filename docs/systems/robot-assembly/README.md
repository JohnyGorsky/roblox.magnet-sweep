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

Completing a zone's collection awards **cosmetics, never combat power**. The collector track must not
become a power track, or completion stops being optional.

The Archive survives Overclock ([decision 0013](../../decisions/0013-overclock-not-rebirth.md)).

## Naming

Players name their robot — MAGNETRON, SPOONATOR, SCRAP KING, BOB. Shown at Arena entrance, on victory,
on the leaderboard and in the Bay. Filtered through Roblox text filtering
(`TextService:FilterStringAsync`), for every context it is displayed in.

## Build archetypes (section 52)

Not classes — emergent shapes the part pool supports:

**TANK** heavy body, shield, tracks · **SPEED** wheels, light armour, fast weapons · **BRAWLER** spoon,
excavator, hammer, knockback · **RANGED** coil cannon, exhaust cannon, ion lance · **CONTROL** magnet
arm, crane hook, shields — moves enemies around the Arena.

If, after tuning, only one of these wins, the Arena is broken regardless of how good the individual
parts feel.
