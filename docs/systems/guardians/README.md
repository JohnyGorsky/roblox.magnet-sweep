# Guardians

One unique threat per zone. The reason extraction is dangerous rather than merely long.

## What a guardian does

A guardian is not a health-bar enemy. It is a **denial threat**:

- It patrols or activates on a Salvage Breach.
- If it catches the player, the player is knocked down and **drops the rare part**.
- ~5 seconds to recover it, then security reclaims it, or another player may take it.
- The player loses **no** Coins, **no** magnet progression, **no** secured parts.

There is no combat. The player has a magnet, not a weapon. The answer to a guardian is always movement,
route choice and Magnetic Drive.

## The twelve

| Tier | Zone | Guardian |
|---:|---|---|
| 1 | Color Workshop | Slow Scrap Sweeper Bot |
| 2 | Toy Assembly | Wind-Up Security Bot |
| 3 | Mega Kitchen | Chef Security Bot |
| 4 | Warehouse | Security Forklift |
| 5 | City Storage | Security Patrol Cart |
| 6 | Vehicle Workshop | Security Motorcycle |
| 7 | Car Factory | Autonomous Security Car |
| 8 | Heavy Yard | Autonomous Bulldozer |
| 9 | Power Plant | Electrical Sentinel |
| 10 | Robot Laboratory | Prototype Combat Robot |
| 11 | Space Foundry | Orbital Defense Drone |
| 12 | Quantum Reactor | Quantum Warden |

Tier 1's guardian is deliberately **slow**. It exists to teach the mechanic without punishing the player
who has not yet bought any Drive.

## Behaviour

Follow the shared `roblox-ai` skill. The shape:

```
IDLE / PATROL  →  (Salvage Breach)  →  ALERT  →  PURSUE  →  CATCH  →  RECLAIM
```

- Detection is layered: distance → radius overlap → a line-of-sight raycast. Never magnitude alone.
- Pursuit leads a *moving* target; a guardian that steers to where the player was is trivially outrun in
  a straight corridor.
- `PathfindingService` with `AgentRadius`/`AgentHeight` set for the guardian, not the player.
- Server-authoritative. A guardian catch is a server fact.

## Escalation

Later zones do not simply add health. They add **coverage**: faster movement, wider detection, more of
them, or an ability that closes routes (the Electrical Sentinel disabling a lane, the Bulldozer blocking
one). The player's counter-play stays the same verb — route and speed — while the space to use it
shrinks.

## The ROBOT BREAKOUT event

Section 54: security robots enter zones they do not belong to. This is the cheapest possible content
multiplier for guardians and should exist from early on.

## Open

| Question | When |
|---|---|
| Does a guardian pursue past a zone boundary? Streaming says no; drama says yes | before zone 2 ships |
| Is the knockdown a ragdoll or a scripted stagger? Ragdoll is dramatic but harder to recover from consistently within 5 s | before the first guardian ships |
| Do guardians threaten a player carrying nothing? If not, they are scenery 90 % of the time | before tier 1 is tuned |
