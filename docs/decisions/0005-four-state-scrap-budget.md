# 0005 — Scrap has four states, and only one of them costs physics

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Section 66 is blunt: do not simulate thousands of objects simultaneously. The visual world may contain
thousands. The simulated world may not.

Section 13 already defines the states the *design* needs — IDLE, REACT, PULL, COLLECT — and section 16
wants a Magnet Rush that makes hundreds of objects react at once. The two have to be reconciled
numerically, not by intention.

## Decision

Every magnet-compatible object is in exactly one of four states, and the cost of each is fixed:

| State | Physics | Anchored | Cost |
|---|---|---|---|
| **IDLE** | none | yes | a transform. Thousands are fine |
| **REACT** | none | yes | a local shake/tilt tween + sparks. Hundreds are fine |
| **PULL** | real, unanchored | no | **capped by a config number** |
| **COLLECTED** | none | pooled | returned to the pool, never destroyed |

`MaxConcurrentPull` is a config value per quality tier. When the cap is reached, additional objects
inside the radius stay in REACT and enter PULL as slots free. A Magnet Rush raises the *visual* drama
(radius, arcs, sound, light) and only modestly raises the cap.

**Object pooling is mandatory from the first prototype**, not added later. Collected scrap is returned
to a pool and reused by the next refresh.

## Consequences

- The dramatic moment is affordable, because most of the drama is REACT, which is free.
- Performance is a number a designer can tune, and a number that can be measured in the emulator.
- A refresh does not allocate: it re-poses pooled objects.

## The check

The failure condition is stated so the verification can fail: **during a Magnet Rush at the cap, count
unanchored parts in the workspace.** If that count exceeds `MaxConcurrentPull`, the state machine has a
leak — most likely a COLLECTED object that was never re-anchored on return to the pool.
