# Magnet

The game's verb. Everything else is downstream of whether this feels good.

## The four player stats

| Stat | Controls | The question it answers | Start | Endgame |
|---|---|---|---:|---:|
| 🧲 **Magnet Power** | maximum object weight, ability to detach rare parts, **every zone gate** | *What can I take?* | 10 | 1,500 |
| 🌀 **Magnet Radius** | how far objects begin being pulled | *How much can I sweep?* | 12 | tuned |
| ⚡ **Magnetic Drive** | movement speed | *Can I escape?* | 16 | 34-36+ |
| 📦 **Capacity** | ordinary scrap carried | *How long between recycles?* | 30 | tuned |

Capacity does **not** govern rare cargo — see [cargo](../cargo/README.md).

Magnet Power is the spine. It is the gate stat, the detach check and the visible progression. The other
three are pace.

## Object states

Four states, and only one of them costs physics. This is
[decision 0005](../../decisions/0005-four-state-scrap-budget.md) and it is a hard budget, not a
guideline.

| State | What the player sees | Anchored | Cost |
|---|---|---|---|
| **IDLE** | resting | yes | a transform |
| **REACT** | shakes, tilts, sparks | yes | a local tween |
| **PULL** | slides, lifts, rotates, accelerates, trails | **no** | real physics, **capped** |
| **COLLECT / CARGO** | scrap collected, or a rare part becomes cargo | pooled | — |

`MaxConcurrentPull` is a per-quality-tier config number. Objects over the cap wait in REACT.

## Where the work happens

[Decision 0002](../../decisions/0002-magnet-is-client-felt-server-owned.md): the client renders the
pull, the server grants the collection.

- **Client:** REACT and PULL motion, arcs, trails, particles, sound, the field sphere, Flow VFX.
- **Server:** what was spawned where, whether Power clears a detach, the collection grant (batched on a
  tick, never one remote per bolt), Coins, Capacity.

A client cannot collect scrap the server did not place.

## Magnet Flow

```
x1 → x2 → x3 → x4 → x5 → MAGNET RUSH
```

Continuous collection builds Flow; stopping decays it. Benefits: slightly faster pull, a Coin
multiplier, stronger VFX, a rising musical pickup pitch, a larger visible field.

Flow is the cheapest tension in the game — it costs almost nothing to run and it turns walking around
into a rhythm with a fail state.

## Visual states

| State | Look |
|---|---|
| Idle | glowing poles, small electricity, quiet hum |
| Pulling | stronger arcs, directional particles |
| High Flow | larger aura, brighter electricity, more trails |
| Magnet Rush | shockwaves, strong trails, a lighting pulse, intensified sound |
| Overcharge | maximum state — everything nearby reacts at once |

Full VFX vocabulary: [`magnet-sweep-style` skill](../../../.claude/skills/magnet-sweep-style/SKILL.md).

## The starter magnet

Power 10 · Radius 12 · Drive 16 · Capacity 30. Enough to pull screws, nuts and washers, and nothing
else. That limitation is the tutorial.

## Open

| Question | When |
|---|---|
| Is pull force a curve or a step at the weight threshold? A hard threshold reads as broken; a soft one makes gates fuzzy | before the first prototype is tuned |
| Does Radius affect REACT range, PULL range, or both? | same |
| What is `MaxConcurrentPull` on a mid-range phone during a Rush? **Measure** | before the Rush ships |
