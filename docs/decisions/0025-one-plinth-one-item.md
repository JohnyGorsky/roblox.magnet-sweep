# 0025 — One plinth, one item, one rarity table

**Status:** Accepted · 2026-09-06 · Job 023
**Supersedes:** the *pool-of-8 / spawn-3-per-cycle* clause of
[0006 — the factory refreshes](0006-the-factory-refreshes.md), and the duplicate rarity table in
`Config/Zones.luau`

## Context

The owner's room has **one boss guarding one item**:

> *"each zone is not long but full of scraps, boss guarding it and item"*
>
> *"we have area where boss sits and guards it item"*

Both concept sheets draw it the same way: a single raised, lit, bannered plinth, with the guardian
posted near it.

The shipped design is different, and job 023's intake asserted *"nothing has to be overturned"*
without noticing:

| Source | What it says |
|---|---|
| [0006](0006-the-factory-refreshes.md) | *"Each zone owns a pool of **8 possible parts**; a refresh spawns only some of them."* |
| `docs/systems/factory/README.md` | *"A refresh spawns only some — typically 2 normal, 1 uncommon, and a chance at 1 rare."* |
| `Config/Zones.luau:113-116` | `SPAWN_PER_CYCLE = { COUNT = 3, BONUS_ROLL_CHANCE = 0.35 }` |

And there is a **second rarity table nobody knew about**: `Zones.RARITY_WEIGHT`
(`Config/Zones.luau:122-129`) — Common 100 / Uncommon 55 / Rare 22 / Epic 7 / Legendary 2. Normalised
across tier 1's 3 Common / 3 Uncommon / 1 Rare / 1 Legendary it comes out ≈ **61 / 34 / 4.5 / 0.4** —
roughly **half** the intended Rare rate and **a fifth** of the Legendary rate.

An adversarial audit found it. The intake had written *"the roll table and its rarity weights still
need writing down"* while one already shipped.

## Decision

**One plinth. One item. First grab wins.**

- The room holds **exactly one** robot part at a time, on an editor-placed plinth
  ([0023](0023-the-room-is-placed-the-contents-are-spawned.md): the plinth is placed, the part on it is
  spawned).
- Taking it is a **5-second channel**; moving cancels it and resets it to zero; the plinth **locks to
  the first player who starts**, so a second player cannot channel it until the first stops.
- After a successful steal the plinth **re-rolls a new part on a 30–60 s cooldown**, matching 0006's
  scrap-refresh cadence, which 0020 left standing.
- **One rarity table**, and it is this one:

  | | Common | Uncommon | Rare | Legendary |
  |---|--:|--:|--:|--:|
  | Tier 1 | **60 %** | **30 %** | **8 %** | **2 %** |

  Per part: `WORK_LAMP` · `MINI_MOTOR` · `PAINT_DRUM` 20 % each; `PIPE_WRENCH` · `SPRING_PUNCHER` ·
  `CASTER_WHEELS` 10 % each; **`MAGNET_COIL` 8 %**; **`GOLDEN_GEAR` 2 %** — a genuine event roughly
  one steal in fifty. The concept banner's `WORK_LAMP` stays honest as the typical roll.

🔴 **`Zones.RARITY_WEIGHT` and `Zones.SPAWN_PER_CYCLE` must be deleted or repointed in this job.**
Two rarity tables in two files is [PITFALLS #38 and #52](../PITFALLS.md) by construction: the one
nobody remembers is the one that silently wins six months from now.

## Consequences

- **The mechanic becomes legible.** A guardian cannot meaningfully *guard* three parts scattered
  across a room; it can guard one lit pedestal. The 5-second channel, the wake, the chase and "first
  grab wins" all depend on there being a single thing to take.
- **The concept art is buildable as drawn** — one plinth, raised, spot-lit, with a banner naming the
  part.
- ⚠️ **Supply is now one part per 30–60 s per room, server-wide**, not three per 4-minute cycle. For a
  shared server that is *more* generous than 0006 in throughput and far more contested moment to
  moment — two players who both want a part queue rather than each finding their own. That contest is
  the point, but it is the first thing to watch when more than four people are in a room.
- ⚠️ **0006's "the spoon is always here" protection weakens.** 0006 spawned a random subset of 8 so no
  player could memorise the room. One plinth is always in the same place; only *what is on it*
  changes. The variety has to come from the roll, not the position — and if the room becomes
  memorisable, moving the plinge between a few placed positions is the cheap fix, not returning to a
  scatter.
- ⚠️ **`docs/systems/factory/README.md` still documents the pool-of-8** and must be updated in this
  job. 0020 has already left that file and `Config/Zones` un-updated once.

## The trap

**A single plinth makes the item's `powerRequired` load-bearing, and no part has one.**
`Config/Parts.luau:34-35` defines `weight` and `powerRequired`; **no row in `PartsCatalog.ALL` sets
either**, and `PartsCatalog.validate()` checks only `slot` and `rarity`, so the gap is silent at boot.

With a pool of 3 spawns, a part the player cannot lift is a minor disappointment among several. With
**one** plinth, rolling a `GOLDEN_GEAR` that a Power-10 player cannot detach means the room's only
prize is inert until they leave and come back. Either tier 1's parts are all detachable at Power 10,
or the roll must respect the player who is channelling — and that is a decision, not an implementation
detail.

## The check

Steal the item ten times in a row on a test server and record the roll. The distribution must be
recognisably 60/30/8/2 — and crucially, **`grep` the codebase afterwards for a second rarity table.**
If `RARITY_WEIGHT` still exists anywhere, this decision has not landed; it has merely been written
down next to the thing it was supposed to replace.
