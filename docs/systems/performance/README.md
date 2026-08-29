# Performance

This game spends its frame budget on **physics** and **reflective materials** at the same time, in
**one place** that holds a hub, an arena and a twelve-zone corridor, targeting **phones**. Performance is
not a phase at the end; it is a constraint on every design decision here.

Follow the shared `roblox-optimization` skill for profiling and technique.

## The four budgets

| Budget | Governed by | Enforced by |
|---|---|---|
| **Simulated objects** | `MaxConcurrentPull` per tier | [decision 0005](../../decisions/0005-four-state-scrap-budget.md) |
| **Streamed world** | Instance Streaming over the corridor | [decision 0003](../../decisions/0003-forward-is-the-only-direction.md) |
| **Arena robots** | 4-6 concurrent, **measured** | [decision 0010](../../decisions/0010-one-robot-per-player-persistent-arena.md) |
| **Visual tier** | post chain, PBR, lights, particles | [decision 0012](../../decisions/0012-mobile-first-quality-tiers.md) |

## Streaming

The single most important technical property of the project. One place holds everything
([decision 0001](../../decisions/0001-one-place-not-two.md)), so:

- Zones are **self-contained chunks**. No cross-zone instance references, ever.
- Scripts must survive their target not being streamed in. `WaitForChild` with a timeout and a real
  failure path, never an infinite yield.
- The Workshop and the Arena are persistent; the factory streams.

> 🔴 **Do not build before terrain and geometry stream in.** Jungle lost work to props placed at a clear
> height before the chunk existed, and buried. Probe that the ground is there before placing anything at
> runtime.

## Object pooling

Mandatory from the first prototype, not retrofitted. Scrap, VFX emitters, and Arena robot instances are
all pooled. Nothing gameplay-relevant is created or destroyed in a hot path.

## The far world

Section 66: the visual world may contain thousands of objects. Far objects are anchored and passive.
Near the player they enter REACT. Only pulled objects are simulated. Collected objects are pooled.

Distant machinery animates by texture offset and tween, never by physics.

> ⚠️ **`LevelOfDetail = StreamingMesh` renders an imposter where nothing exists in the DataModel.** If
> something appears in a screenshot that the tree says is absent, check that before assuming a bug.

## Mobile

Measured in Studio's **Device Emulator**, which gives real `TouchEnabled`, real `ViewportSize`, real
safe-area canvas and Roblox's own `TouchGui` rects. Ask the human before switching Studio into it — it
takes over their session — and say what is being measured.

"It should be fine on mobile" is not a measurement. Defender burned four rounds of rework on that
sentence.

## The measurements that must happen, and when

| Measure | Fails if | Before |
|---|---|---|
| `MaxConcurrentPull` during a Rush | frame time > 33 ms on the reference mid-range phone | the Rush ships |
| Concurrent Arena robots, with parts, actuators and VFX | 6 robots cannot hold 33 ms; then the number drops to whatever does | committing to 6 |
| Workshop + Arena + two loaded zones | client memory exceeds the mobile budget, **or** frame time > 33 ms while standing in the Workshop looking at the Arena | the second zone ships |
| HUD vs the real safe area and Roblox's reserved touch regions | any interactive element overlaps the thumbstick or jump-button rect, or falls outside the safe-area canvas, in the Device Emulator | the first HUD element ships |
| Draw calls in the Workshop with full signage and PBR | the count rises above the budget set when the kit is signed off — **that budget does not exist yet and must be set first** | the Workshop is signed off |

Each row states what failure looks like, so the check can actually fail
([PITFALLS #2](../../PITFALLS.md#2-a-verification-that-could-not-fail)). The reference device and the
memory and draw-call budgets are **not yet chosen** — choosing them is the first item of this list, not
an implied prerequisite.
