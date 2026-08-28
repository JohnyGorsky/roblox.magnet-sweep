# 0003 — Forward is the only direction

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Section 17: the factory behaves like one continuous journey. It may turn, rise, descend, go outdoors,
enter elevators and cross bridges — but psychologically, **forward means better stuff**.

The temptation is a hub-and-spoke world: pick a zone from a menu, teleport in. It is easier to build and
easier to stream. It also destroys the thing the game is selling, which is the feeling of having walked
somewhere dangerous.

## Decision

The factory is **one physically continuous corridor**, zone 1 through zone 12, authored as streamable
chunks. There is no zone-select menu. You reach zone 5 by walking through zones 1 to 4.

Gates between zones are physical (see section 61): you pull a locking mechanism with your magnet. There
is no Unlock button.

**MagRail** (section 18) is the concession to travel time: Service Hubs connect back to the Workshop,
one-way inbound. You ride home; you always walk out.

## Consequences

- Depth is legible without any UI. The player can see how far they have come.
- Streaming is the core technical constraint of the whole project, from day one, not a later
  optimisation. Zones must be self-contained chunks with no cross-zone instance references.
- Returning with heavy cargo is a real journey, which is what makes section 22's escape gameplay mean
  anything.
- Adding zone 13 is appending to a corridor, not editing a hub.

## The rule that keeps it true

**No script may hold a hardcoded instance path into another zone.** Zones talk to the zone manager;
they never reach across. This is the same failure that produced a Tide finding, and streaming turns it
from a coupling smell into a nil-index crash.
