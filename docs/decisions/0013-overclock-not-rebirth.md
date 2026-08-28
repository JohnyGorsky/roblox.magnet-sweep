# 0013 — Overclock, not rebirth; the robot survives the reset

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Section 79 rejects a generic REBIRTH in favour of **OVERCLOCK THE FACTORY**, and is specific about what
resets and what does not.

## Decision

Overclock resets: zone access, Coins, magnet upgrade levels, Drive and Capacity upgrades.

Overclock **keeps**: robot parts, the collection archive, cosmetics, Arena statistics, the robot's name,
and awards a permanent **Magnet Core Level** giving starting bonuses.

## Consequences

- The player's robot — the thing with a name, a face and a leaderboard history — is never taken away.
  Resetting it would reset the emotional attachment the entire second half of the game is built on.
- Subsequent runs are faster and more chaotic, which is the intended prestige feel.
- The Part Archive keeps its ticks. Collection is a permanent track, parallel to the reset track.
- Zone gates must therefore be re-clearable quickly, and the power curve must scale with Magnet Core
  Level rather than being re-walked at the original pace.

## The naming rule

Never write "rebirth" in the UI, the code or these docs. The mechanic is **Overclock**, the currency of
prestige is **Magnet Core Level**, and the tone is a factory being pushed past its rating — not a
spiritual do-over.
