# The factory

One continuous corridor, twelve tiers deep. [Decision 0003](../../decisions/0003-forward-is-the-only-direction.md).

## Shape

The factory turns, rises, descends, goes outdoors, enters elevators and crosses bridges — but
psychologically **forward = better stuff**. There is no zone-select menu. You reach zone 5 by walking
through zones 1 to 4.

Zones are authored as **self-contained streamable chunks**. No script may hold a hardcoded instance path
into another zone; zones talk to the zone manager only. Under Instance Streaming that coupling is not a
smell, it is a nil-index crash.

## Zone gates (section 61)

Each gate requires **Magnet Power**. When the requirement is met, the player does not press Unlock —
they physically pull a giant locking mechanism:

```
Required: 150      Current: 137
        ↓  (at 150)
GRRRRR ... the pin moves ... BOOM ... the gate opens
```

Power curve (initial balancing target only, section 62):

| Zone | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Power | 10 | 20 | 35 | 55 | 85 | 130 | 200 | 300 | 450 | 675 | 1,000 | 1,500 |

Roughly ×1.5 per zone. **Final values must be playtested.**

## Service Hubs (section 18)

One approximately every two zones. Each contains: Recycler · Magnet Upgrade terminal · Repair terminal ·
**Robot Part Secure station** · Checkpoint · Arena status display · **MagRail** connection back to the
Workshop.

MagRail is one-way inbound. You ride home; you always walk out. That asymmetry is what keeps depth
meaningful while removing the boring half of the round trip.

## The three cycles

[Decision 0006](../../decisions/0006-the-factory-refreshes.md). All three ship in the MVP.

| Cycle | Period | What happens |
|---|---|---|
| **Scrap Refresh** | 30-60 s | pooled scrap re-poses. Silent, continuous |
| **Factory Cycle** | ~4 min | 20 s warning → machinery activates, lights flash → **unclaimed** parts retract → a new set spawns |
| **Factory Shift** | ~12 min | a server-wide modifier changes |

Shifts: **HEAVY** (more heavy parts) · **ELECTRIC** (more power components) · **GOLD** (higher-value
scrap) · **SECURITY** (more dangerous, better parts) · **CHAOS** (more world events).

> The 20-second warning must be audible and visible from anywhere in the zone, including while running.
> A refresh that silently eats a part the player was walking toward reads as a bug.

## Rare part spawn rules (section 20)

Each zone owns a pool of **8 possible parts**. A refresh spawns only some — typically 2 normal, 1
uncommon, and a chance at 1 rare, re-weighted by the active Shift. An extremely valuable spawn fires a
server-wide **⚡ LEGENDARY PART DETECTED**.

Parts exist physically. There are no loot boxes.

## Modular construction (section 64)

70-80 % of the environment is reusable primitives. Build a kit, not rooms:

**Floors** plain · hazard · conveyor · grated  ·  **Walls** solid · pipes · windows · machines  ·
**Structures** pillar · corner · gate · bridge · ramp · platform  ·  **Industrial** conveyors ·
generators · tanks · pipes · control panels · fans  ·  **FX** sparks · electricity · smoke · warning
lights · magnetic trails

Custom, high-quality assets are reserved for: magnets, the Recycler, the robot installation machine, the
Arena Core, gates, guardians and rare Robot Parts (section 65).

## The twelve zones

Catalog with themes, guardians and part pools: [content/zones](../../content/zones/README.md).
