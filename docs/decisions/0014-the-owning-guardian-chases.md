# 0014 — The owning guardian chases you, and its territory is the finish line

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Section 23 says a guardian catch knocks the player down, drops the part, and gives about 5 seconds to
recover it before "security reclaims it". Section 24 adds that a failed recovery makes the part neutral
and another player may take it.

As written that is one flat rule applied everywhere, and it has two problems. The 5-second window is a
lottery — where the part lands decides the outcome. And it gives the long walk home no shape: the
hundredth metre is exactly as dangerous as the first.

Separately, [0003](0003-forward-is-the-only-direction.md) makes the factory one streamed corridor, which
raised a technical question nobody wanted to answer on technical grounds: does a guardian pursue past a
zone boundary?

## Decision

**The steal-an-egg rule.** Only the guardian of the part you took cares about you, and what it can do to
you depends on where it catches you.

```
ZONE 8  ── steal the bucket ──▶   BOUNDARY   ──▶  ZONE 5 … 1  ──▶  SERVICE HUB
          🚜 bulldozer wakes          │                                SECURED
                                      │
  caught inside Zone 8                │       caught outside Zone 8
        ↓                             │              ↓
   RESET — the bucket returns         │      you ragdoll, the bucket DROPS
   to its spawn point. Gone.          │      it lies there, neutral —
                                      │      anyone may take it.
                                      │      The bulldozer gives up and goes home.
```

1. **Guardians are inert until a part is taken.** A player carrying nothing is never threatened. This is
   what keeps the sweep loop — 55 % of playtime — relaxing, and it teaches the rule in one beat:
   *security responds to theft, not to your presence.*
2. **Only the owning guardian activates.** The one whose part you took. Every other zone's guardian
   ignores you completely, even as you run through its territory carrying stolen goods.
3. **It pursues across zone boundaries.** It does not stop at the edge of its zone.
4. **Inside its own territory, a catch RESETS the part** — straight back to its spawn point. No recovery
   window. You lost it; go and take it again.
5. **Outside its territory, a catch DROPS the part.** You ragdoll, the part lands and becomes neutral.
   Any player may pick it up. **The guardian then gives up and returns home** — it does not carry the
   part back and does not guard where it fell.
6. **Reaching a Service Hub is `SECURED`** ([0008](0008-secured-at-the-hub-not-in-hand.md)) and ends the
   chase.

## Consequences

- **The zone boundary becomes the real finish line.** Crossing it converts an unrecoverable loss into a
  recoverable one. Every extraction now has a sprint and then a walk, instead of one flat jog.
- **Once you are out, heavy cargo stops being lethal.** You can take your time. That is what makes the
  −45 % speed penalty on an Extreme part survivable rather than punishing, and it means Magnetic Drive
  buys you *the sprint*, not the whole journey.
- **Exactly one pursuer, ever.** A meaningful performance property in a streamed corridor: no stacking
  of guardians, no crowd of AI following a player through four zones.
- **The neutral drop creates player competition without griefing** (§24). A rival can take what you
  dropped — but only after security already beat you, and only outside the zone that owns it.
- **The 5-second recovery window is gone**, replaced by two clean outcomes. Nothing depends on where a
  ragdoll lands.
- Guardians need a **home territory** and a **give-up-and-return** state. Both are cheap, and the
  give-up state is what stops a guardian being stranded three zones from home.

## What this rejects, and why

- *Any guardian in its own zone can reset any part.* Every zone crossed would be a fresh chance to lose
  the whole run, which contradicts the point of getting out — deep extractions would become brutal.
- *The guardian hauls the dropped part home.* A tempting second chase, but it strands a guardian outside
  its zone, and the part blinks out of the world at a boundary for reasons a player cannot see.
- *Guardians ignore carriers outside the origin zone.* The walk home goes quiet and the return lanes
  lose their teeth.

## The check

**A player carrying nothing must never be knocked down by a guardian.** If that ever happens, either a
guardian is in the wrong state or something is wrongly flagged as carried cargo — and the sweep loop is
being taxed by a system that is supposed to leave it alone.
