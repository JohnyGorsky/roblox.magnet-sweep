# 0013 — Overclock, not rebirth; the robot survives the reset

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Section 79 rejects a generic REBIRTH in favour of **OVERCLOCK THE FACTORY**, and is specific about what
resets and what does not.

## Decision

Overclock resets exactly four things: **zone access, Coins, magnet upgrade levels, Drive upgrades.**

⚠️ **Capacity is not on that list.** The spec does not reset it, and this repo must not quietly add it.
Whether Capacity *should* also reset is an open balance question — if it is ever changed, that needs a
new decision record saying so, not an edit to this line.

Overclock **keeps**: robot parts, the collection archive, cosmetics, Arena statistics, the robot's name,
and awards a permanent **Magnet Core Level** giving starting bonuses.

## Consequences

- The player's robot — the thing with a name, a face and a leaderboard history — is never taken away.
  Resetting it would reset the emotional attachment the entire second half of the game is built on.
- Subsequent runs are faster and more chaotic, which is the intended prestige feel.

## How Magnet Core Level bends the curve

Each Core Level grants **starting Magnet Power** and applies a **percentage discount to every zone
gate's requirement**. Run 2 opens with the early zones effectively free and reaches zone 12 far faster.

```
gate requirement

1500 ┤                                    ╭─ run 1
     │                          ╭─────────╯
     │              ╭───────────╯
     │      ╭───────╯          ╭──────────── run 3 (Core 2)
  10 ┼──────╯───────────╯──────╯
     └──1──2──3──4──5──6──7──8──9──10──11──12──  zone
        ▲ you start here on run 3
```

**The curve visibly bends** — that is the prestige feeling — but the gates never disappear. Every zone
is still a physical lock you pull; you just clear the early ones in minutes instead of an hour.

Rejected: a flat income multiplier. It compounds cleanly and is trivial to build, but the run stays the
same *shape* at a higher speed, so the twelfth Overclock feels exactly like the second. Also rejected
for now: a unique unlockable perk per Core Level — the most replayable option and by far the most
content to design, balance and keep fair. It stays open as a later addition on top of the discount.
- The Part Archive keeps its ticks. Collection is a permanent track, parallel to the reset track.
- Zone gates must therefore be re-clearable quickly, and the power curve must scale with Magnet Core
  Level rather than being re-walked at the original pace.

## The naming rule

Never write "rebirth" in the UI, the code or these docs. The mechanic is **Overclock**, the currency of
prestige is **Magnet Core Level**, and the tone is a factory being pushed past its rating — not a
spiritual do-over.
