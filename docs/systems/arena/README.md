# The Scrap Arena

Persistent, server-wide, and visible from the Workshop. Not matchmaking.
[Decision 0010](../../decisions/0010-one-robot-per-player-persistent-arena.md).

## Shape

- Target **4-6 active robots**. That number is a **measured performance budget**, not a design constant.
- Each player may release **one** robot.
- Robots fight automatically. The player never controls one in combat.
- If the Arena is full, the player enters a short queue.
- The Arena persists for the life of the server. Robots come and go; it does not reset.

## The objective

A central **ARENA CORE**. Robots contest control of it. Combat matters, but so do position, knockback,
speed and durability — a build that only deals damage does not hold ground.

```
👑 ARENA CONTROL
MAGNETRON  ·  Owner: Player  ·  Hold: 02:42
```

Rewards accumulate over hold time: Coins, Arena Fame, a temporary factory bonus, cosmetic progression.

> **The Arena never gates factory zones.** A player who ignores the Arena entirely must still be able to
> reach zone 12. The Arena is a parallel track, not a tax.

## Robot AI

No player input. The robot:

1. moves toward the objective
2. selects a threat
3. uses its weapon
4. uses abilities
5. tries to stay near the Core
6. reacts to knockback
7. retargets

Different builds produce different behaviour because the profiles and stats differ, not because there
are AI presets to choose.

Movement is a controlled root, not driven wheels —
[decision 0009](../../decisions/0009-robots-are-animated-not-driven.md).

## HP, damage and death

HP persists across the deployment. It does not regenerate.

```
3,200  →  2,450  →  1,650  →  840  →  0
                                      ↓
                            ROBOT DISABLED
                     sparks · smoke · the crane removes it
```

Damage visuals: clean at high HP → sparks at 75 % → scratches and sparks at 50 % → smoke at 25 % →
heavy electricity at 10 % → collapse at 0.

> 🔴 **Parts are never permanently lost.** Decorative panels may pop off on death; the *owned* part is
> untouched. The Arena robot is a disposable instance built from the Bay's robot. Death costs repair
> scrap, never inventory.

## Repair

**In the Bay:** scrap converts to HP. This is the pinch — see [economy](../economy/README.md).

**In the field (section 49):** the **REPAIR CHUTE** feeds scrap to a robot that is still fighting. Scrap
travels visibly through a pipe; the robot gets +250 HP with welding and electrical VFX.

Field repair is **rate-limited on purpose**: a cooldown, reduced efficiency, and a cap per time window.
Without those, a wealthy player holds the Arena forever.

## Arena Heat (section 50)

The turnover guarantee. The longer a robot holds the Core, the harder it is to keep:

| Hold time | Damage taken |
|---|---|
| 0-90 s | normal |
| 90-180 s | +10 % |
| 180-300 s | +20 % |
| 300 s+ | +35 % |

Repair efficiency drops alongside. Combined with the field-repair cap, this makes indefinite control
mechanically impossible — which is the enforcement half of
[decision 0011](../../decisions/0011-robux-never-buys-arena-power.md).

## Notifications (section 51)

While the player is deep in the factory:

```
🤖 YOUR ROBOT DEFEATED SCRAPPER
⚠ ROBOT HP: 22%
👑 ARENA CONTROL LOST
```

These are ordinary server events because the game is one place
([decision 0001](../../decisions/0001-one-place-not-two.md)). They are the thread that ties the two
halves of the game together, and they are what makes a player turn around and walk home.

## Open

| Question | When |
|---|---|
| Can 6 robots with parts, actuators and VFX render at 30 fps on a mid phone? **Measure before committing** | before the Arena ships |
| What happens to a deployed robot when its owner leaves the server? | before the Arena ships |
| Is there a spectator camera, or is watching strictly from the Workshop floor? | before launch |
