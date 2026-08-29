# Economy

One dilemma, repeated forever.

## The pinch

```
        150 SCRAP
        /        \
   ♻ RECYCLE     🔧 REPAIR
   3,600 Coins   +900 Robot HP
        │             │
   magnet upgrades   your robot stays in the Arena
   (go deeper)       (hold the Core)
```

The game never resolves this. It is the reason the loop repeats, and every other economic decision is
arranged to keep it live.

## Currencies

| | Source | Spent on |
|---|---|---|
| **Scrap** | sweeping | recycling → Coins, or repair → robot HP |
| **Coins** | recycling | Magnet Power, Radius, Drive, Capacity |
| **Robot HP** | repair | staying in the Arena |
| **Arena Fame** | Arena control | cosmetic progression |
| **Magnet Core Level** | Overclock | permanent starting bonuses |

## Rare part economics

A rare part is a third fork:

| | |
|---|---|
| **INSTALL** | improve the robot |
| **REINFORCE** | Mk I → Mk II → Mk III on a part you already own |
| **RECYCLE** | a large Coin payout |

## Upgrade costs

Magnet Power gates zones, so its cost curve *is* the pacing curve. Zone power requirements rise roughly
×1.5 per zone (10 → 1,500 over twelve zones); Coin costs must be set against that curve, not
independently, or the gates land in the wrong place.

Balancing constraints, in priority order:

1. The first upgrade must be affordable **within ~2 minutes** of first play (section 74).
2. Every zone must be reachable by sweeping alone, without any Arena income.
3. Repairing a robot must always be a *tempting* alternative to upgrading — if repair is obviously
   correct or obviously wrong, the pinch is dead.
4. Recycling a duplicate legendary should feel like a genuine windfall.

All values live in shared config modules. Balance without touching gameplay code.

## Dynamic events (section 54)

Server-wide, some free and some purchasable:

**SCRAP RAIN** hundreds of objects drop · **GOLD RUSH** high-value scrap · **MAGNETIC STORM** objects
float · **CARGO DROP** a large crate lands · **SECURITY FAILURE** rare-part spawn rate rises ·
**ROBOT BREAKOUT** security robots enter zones · **HEAVY DELIVERY** large industrial objects arrive ·
**LEGENDARY SIGNAL** one special part appears.

Purchasable events are deliberately the shape of monetisation we want: one player pays, the whole server
benefits ([monetisation](../../game/monetization-stance.md)).

## Leaderboards (section 81)

Daily: **LONGEST ARENA HOLD** · **FURTHEST DISTANCE** (Endless Line) · **ROBOTS DEFEATED** ·
**RARE PARTS RECOVERED** · **LARGEST OBJECT PULLED**.

Five boards, five different playstyles rewarded. Use `OrderedDataStore`; see the `roblox-data` skill.

## Overclock (section 79)

[Decision 0013](../../decisions/0013-overclock-not-rebirth.md). Resets four things — zone access,
Coins, magnet upgrade levels and Drive upgrades. **Keeps** robot parts, the collection archive,
cosmetics, Arena stats and the robot's name. Awards a permanent **Magnet Core Level**.

The gate power curve must scale with Magnet Core Level, or the second run is the first run again.
