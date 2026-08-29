# 0006 — The factory refreshes; nothing is memorisable

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Section 19 defines three overlapping cycles: scrap repopulates every 30-60 s, a Factory Cycle re-rolls
robot parts about every 4 minutes with a 20-second warning, and a Factory Shift changes a server-wide
modifier about every 12 minutes.

Section 20 makes the reason explicit: players must not be able to learn "the spoon is always here."

## Decision

All three cycles ship, and they ship **early** — the refresh is in the MVP, not a live-ops feature added
later. A part hunt with static spawns is a different, worse game, and building on static spawns bakes in
assumptions that the refresh then breaks.

- **Scrap refresh** (30-60 s): pooled objects re-pose in the current zone. Silent, continuous.
- **Factory Cycle** (~4 min): 20-second warning, machinery activates, lights flash, **unclaimed** robot
  parts retract, a new set spawns from the zone pool.
- **Factory Shift** (~12 min): server-wide re-weighting — Heavy, Electric, Gold, Security, Chaos.

Each zone owns a pool of 8 possible parts; a refresh spawns only some of them, weighted by rarity and
the active Shift.

## Consequences

- Rare-part hunting has a rhythm. Players learn the *cycle*, not the *map* — which is the intended
  skill.
- The warning creates a real decision, but **not** about a part you are already holding: it is about
  whether to commit to a part you can *see* and have not yet detached. Anything already carried is safe
  from the timer.
- Only unclaimed parts retract. Nothing already carried is taken by the timer, and nothing secured is
  ever at risk. See [0008](0008-secured-at-the-hub-not-in-hand.md).
- The Shift gives the server a shared conversation topic every twelve minutes, which is cheap social
  glue.

## The trap

The 20-second warning must be **audible and visible from anywhere in the zone**, including while
running. A refresh that silently eats a part the player was walking toward reads as a bug, not a rule.
