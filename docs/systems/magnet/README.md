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

## Pull force: strain, then refuse

Decided. Weight relative to Magnet Power drives a curve with a hard wall at the top:

```
POWER 80

bolt   (w 2)    ●━━━━━━━━▶🧲   snaps in, instant
crate  (w 60)   ●━━━ ━━ ━ ▶🧲   slow, straining, arcs
SPOON  (w 120)  ●∿∿∿  ✦✦✦       shakes, sparks, GRRRRRR — never moves
                                "MAGNET POWER 120 REQUIRED"
```

- **Well under your Power** — fast, snappy, satisfying. This is most of the sweep.
- **Near your limit** — visibly slower, with strain audio and heavier arcs. The object is *coming*, and
  you can feel that it is hard work.
- **Over your limit** — it reacts violently and never breaks free.

The third band is the important one. A hard step with no reaction would read as scenery or as a bug; a
pure curve with no wall would dissolve the Magnet Power gate and with it the whole progression spine.
**The object itself teaches you what to upgrade** — no tooltip required.

## Radius: both ranges, REACT wider than PULL

Upgrading Magnet Radius grows both, with **REACT sitting ~40 % beyond PULL** at every level.

```
        ╭──────── REACT ────────╮
        │   ╭──── PULL ────╮    │
        │   │      🧲      │    │
        │   ╰──────────────╯    │
        ╰───────────────────────╯
     things shake here    things come here
```

Objects start shaking and sparking before they are in collection range, so the field reads bigger than
it is, and you can *see* your reach arriving before it arrives. That shake ring is free advertising for
the next Radius upgrade, and REACT is the cheap state
([decision 0005](../../decisions/0005-four-state-scrap-budget.md)) — so the spectacle costs almost
nothing.

## Open — needs measurement, not a decision

| Question | When |
|---|---|
| What is `MaxConcurrentPull` on a mid-range phone during a Rush? **Measure in the Device Emulator** | before the Rush ships |
| Does the ~40 % REACT margin hold up at large Radius values, or does it need to taper? | when Radius upgrades are tuned |
