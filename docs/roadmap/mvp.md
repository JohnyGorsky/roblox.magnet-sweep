# MVP

Section 83 is explicit: **do not build twelve zones first.**

## Scope

| In | Out |
|---|---|
| The Workshop | zones 3-12 |
| The Scrap Arena | the Endless Line |
| **Zone 1** — Color Workshop | Overclock |
| **Zone 2** — Toy Assembly | most cosmetics |
| **One Service Hub** | most events |
| **12-16 Robot Parts** | leaderboards |
| **2 Guardians** | the Foundry Heart |
| Robot assembly | Relic Parts |
| Arena combat | |
| Repair | |
| Factory Refresh | |
| Magnet progression | |
| Magnetic Drive | |
| Rare cargo + escape | |

**Factory Refresh is in the MVP.** It is tempting to defer, and deferring it means building every system
on static spawns and then breaking them — see
[decision 0006](../decisions/0006-the-factory-refreshes.md).

## Success criteria (section 84)

The player should naturally understand, without being told:

1. Collect scrap.
2. Upgrade the magnet.
3. Find a rare part.
4. Pull it.
5. Escape.
6. Install it.
7. Release the robot.
8. Repair the robot.
9. Want to reach the next zone.

If any step needs explaining, the *game* is missing a signal — not the player a tutorial.

## Midgame — what a player is doing once the loop lands (§75)

Past the first hour the player is making strategic decisions rather than learning. The spec names seven
things they are pursuing at once:

- reach deeper zones
- collect missing parts
- create a robot build
- improve Drive
- improve Magnet
- hold the Arena longer
- hunt Factory Cycle timings

Note that only two of those are "buy the next upgrade". The midgame health check is whether the other
five are legible and worth doing — if a player's answer to "what now?" is only ever *grind Coins*, the
[pinch](../systems/economy/README.md) has collapsed into a single track.

## The gate

Before building zone 3, answer this honestly:

> ## When the player sees a strange object in the distance, do they think **"I want that on my robot"**?

If the answer is not a strong yes, ten more zones will not fix it. What to fix instead, in order:

1. **The pull feel** — weight, acceleration, the arc into the magnet.
2. **The sound** — object families, the Flow pitch rise, the strain before a part breaks free.
3. **The break-free moment** — GRRRRR → CLANG. This is the single most important half-second in the game.
4. **The alarm and the run home** — does the escape have shape, or is it a corridor?
5. **The install animation** — does bolting the thing on feel like a reward?
6. **The Arena's readability** — can you tell what your robot is doing and why?

This is a *feel* question, judged by a human playing it. It is not something Claude can sign off.

## What "done" means for the MVP

Not "the systems exist". Two things:

- A new player reaches step 9 of the loop within ten minutes, unassisted
  ([core loop](../game/core-loop.md#the-first-ten-minutes-section-74)).
- The gate question gets a yes.
