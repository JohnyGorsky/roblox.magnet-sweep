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

`MaxConcurrentPull` is a per-quality-tier config number. Objects over the cap wait in REACT. The
client reports its measured tier over `ReportQuality` and the server holds it to that, clamped to
the `High` ceiling — so a lying client can lower its own cap and never raise it.

### Every state must have an exit

PULL is entered by the server and left by a **successful claim or the reaper**, and the reaper is
not optional. A pull is client-driven, so anything that stops the client driving — death, alt-tab,
streaming, walking away — strands the object: it holds a cap slot forever, and because scrap is
`CanCollide = false` it falls *through* the floor to `FallenPartsDestroyHeight`, where the engine
destroys it. `registry` then pins a destroyed Instance and that player's magnet is dead for the
session. Job #007 measured exactly this: 80 stuck objects, and a pool falling 400 → 320.

The reaper recovers a PULL object when **any** of these is true, and it runs before the per-player
sweep so an object freed this tick can be pulled again in the same tick:

| Condition | Why it exists |
|---|---|
| sank `PULL_FALL_LIMIT` (25) studs below home | **the one that does the work** — a fall reaches the destroy plane in 2.26s, so a clock loses this race and a height bound wins it in ~0.5s |
| owner gone (left, died, no root) | the driver is not coming back |
| `PULL_TIMEOUT` (3.0s) elapsed | backstop only, never the mechanism |
| the Instance is already destroyed | drop the entry rather than pin a corpse |

REACT has an exit too: an object no player is near returns to IDLE. Without it, once REACT always
REACT — every object you ever walked past keeps shaking on every client, and REACT is the state the
client animates per frame.

## Where the work happens

[Decision 0002](../../decisions/0002-magnet-is-client-felt-server-owned.md): the client renders the
pull, the server grants the collection.

- **Client:** REACT and PULL motion, arcs, trails, particles, sound, the field sphere, Flow VFX.
- **Server:** what was spawned where, whether Power clears a detach, the collection grant (batched on a
  tick, never one remote per bolt), Coins, Capacity.

A client cannot collect scrap the server did not place.

### What the server checks on a claim

Two independent gates, because either one alone has a hole.

**Range** — `Magnet.grantRange()` = `TIP_OFFSET 2.6 + ARRIVE_RADIUS 2.5 + LAG_ALLOWANCE 4.0` =
**9.1 studs** from the player's root. Derived from the rig, never scaled off the pull radius: it
was once `radius * 1.35` = 16.2 studs against an arrival of 2.5, which made *entering the field*
the collection and left 13.7 studs of every pull optional.

**Journey time** — the object must have been in PULL for as long as the pull would really have
taken, measured from where the pull **began** to the magnet. Measuring how far it has actually
*moved* makes this vacuous: an object that never moves has travelled 0 studs and needs 0 seconds.

Range alone is not enough because the server judges the position **it has received**, and a
freshly client-owned part replicates with a lag — so the time gate is what constrains a claim the
position cannot.

The reply always fires, even when nothing is accepted. The client hides an object optimistically
the moment it arrives, so a silently dropped claim leaves it invisible for the rest of the session
with nothing logged — a failure that looks exactly like success.

⚠️ **An arrived object must be held.** It is still unanchored, still `CanCollide = false`, and
nothing drives it once it is inside `ARRIVE_RADIUS` — so it free-falls 6.13 studs during the 0.25s
it waits for its batch, straight out of its own grant gate. The client pins it at the tip and
claims on the flush *after* arrival, so the server is judging a position it has actually received.
Without both, 43% of honest collections were refused.

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
| `MIN_TRAVEL_FRACTION` is 0.7 — a starting value. What tolerance does a real low-end client need? | when the journey gate is tuned on hardware |
| Other players cannot see your magnet: the rig is built client-side. Moving it server-side is its own job. | see `Planned/` |
