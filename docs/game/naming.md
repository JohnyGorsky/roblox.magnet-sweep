# Naming

## The game

The game is **MAGNET SWEEP**. The repo is `roblox.magnet-sweep`. Never write "Magnet Sweep" in UI
display text — the logo and all banners are all-caps.

Taglines: *Find it. Pull it. Bring it home. Bolt it on.* · *Build the craziest robot in the factory.*

## Fixed terms

Use these exactly. Consistency here is what makes the UI, the docs and the code searchable.

| Term | Means | Never call it |
|---|---|---|
| **Scrap** | ordinary collectable material | junk, materials, resources |
| **Robot Part** | a rare, physically retrievable component | item, loot, drop |
| **Coins** | the soft currency, from recycling | cash, money, gold |
| **Magnet Power** | max liftable weight; the gate stat | strength, level |
| **Magnet Radius** | pull range | magnetism, area |
| **Magnetic Drive** | movement speed | speed upgrade |
| **Capacity** | ordinary scrap carried | inventory, bag |
| **Magnet Flow** | the x1-x5 combo | combo, streak |
| **MAGNET RUSH** | the state past Flow x5 | frenzy, overdrive |
| **Salvage Breach** | the alarm when a part is torn free | alert, alarm state |
| **SECURED** | a part reaching a Service Hub | banked, saved, deposited |
| **Service Hub** | the mid-factory safe station | checkpoint, outpost |
| **Factory Refresh** | the ~4 min part re-roll | reset, respawn |
| **Factory Shift** | the ~12 min server modifier | event, buff |
| **Arena Core** | the contested centre | objective, point |
| **Arena Heat** | escalating damage while holding | decay, timer |
| **Overclock** | the prestige reset | rebirth, prestige, ascend |
| **Magnet Core Level** | permanent prestige bonus | prestige level |
| **Endless Line** | the post-zone-12 endgame | infinite mode |

## Places in the world

**The Workshop** (the hub) contains: **Magnet Lab**, **Robot Bay**, **Scrap Arena**, **Recycler**,
**Repair Station**, **Part Archive**, **Factory Entrance**.

The twelve zones keep their spec names: Color Workshop, Toy Assembly, Mega Kitchen, Warehouse, City
Storage, Vehicle Workshop, Car Factory, Heavy Yard, Power Plant, Robot Laboratory, Space Foundry,
Quantum Reactor. The finale room is **The Foundry Heart**.

## Code naming

`PascalCase` for modules and instances, `camelCase` for locals, `SCREAMING_SNAKE` for config constants.
Part ids are `SCREAMING_SNAKE`: `GIANT_SPOON`, `STOP_SIGN`, `EXCAVATOR_BUCKET`. Animation profiles are
`PascalCase`: `SweepHeavy`, `RangedCannon`.
