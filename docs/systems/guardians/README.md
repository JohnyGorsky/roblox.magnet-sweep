# Guardians

One unique threat per zone. The reason extraction is dangerous rather than merely long.

## What a guardian does

A guardian is not a health-bar enemy. It is a **denial threat**, and it follows the steal-an-egg rule —
[decision 0014](../../decisions/0014-the-owning-guardian-chases.md).

- **Inert until a part is taken.** A player carrying nothing is *never* threatened. Guardians patrol,
  look menacing, and ignore you completely while you sweep.
- **Only the owning guardian activates** — the one whose part you took. Every other zone's guardian
  ignores you, even as you run through its territory with stolen cargo.
- **It pursues across zone boundaries.** It does not stop at its own edge.
- **Caught inside its own territory → the part RESETS** to its spawn point. No recovery window.
- **Caught outside its territory → you ragdoll and the part DROPS.** It lies there, neutral; any player
  may take it. The guardian **gives up and returns home**.
- The player loses **no** Coins, **no** magnet progression, **no** secured parts. Ever.

There is no combat. The player has a magnet, not a weapon. The answer to a guardian is always movement,
route choice and Magnetic Drive.

> **Why inert-until-theft.** Sweeping is ~55 % of playtime and it is the ASMR pillar. A guardian that
> harasses a player who has stolen nothing taxes the exact activity the game most wants you doing.

> **The consequence for the world:** a guardian is scenery most of the time. That is intentional, and it
> means guardians must be *interesting to walk past* — a patrol route you learn, an idle animation worth
> watching, a sound that makes you glance up.

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

Depth also lengthens the *dangerous* stretch. A tier-1 theft needs you to clear one small zone; a
tier-11 theft means outrunning an Orbital Defense Drone across the whole of Zone 11 before the reset
stops being possible. That is the risk-versus-reward pillar expressed as distance rather than as
damage.

## The ROBOT BREAKOUT event

Section 54: security robots enter zones they do not belong to. This is the cheapest possible content
multiplier for guardians and should exist from early on.

## States

```
PATROL ──(a part is stolen from MY zone)──▶ PURSUE ──▶ CATCH
   ▲                                          │          │
   │                                          │     in my zone → RESET part
   └────────── RETURN HOME ◀──────────────────┘     outside   → DROP part, then RETURN HOME
                    ▲
                    └── player reached a Service Hub, or died
```

`RETURN HOME` matters more than it looks: without it a guardian that chased a player four zones deep is
stranded there, guarding nothing, in a chunk that may not even be streamed for anyone.

## Open

| Question | When |
|---|---|
| How long is the give-up delay after a drop before the guardian turns for home? Too short and the ragdoll feels unpunished; too long and it loiters in someone else's zone | before the first guardian ships |
| Can a *second* player trip a Breach in the same zone while its guardian is already chasing someone? One guardian, two thieves | before zone 2 ships |
| Guardian speeds, detection ranges and catch radii — none are specified anywhere | per tier, in that tier's build group |
