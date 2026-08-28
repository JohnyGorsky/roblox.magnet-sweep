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

| Measure | Before |
|---|---|
| `MaxConcurrentPull` at 30 fps on a mid phone, during a Rush | the Rush ships |
| Concurrent Arena robots at 30 fps, with parts, actuators and VFX | committing to 6 |
| Workshop + Arena + two loaded zones, memory and frame time | the second zone ships |
| HUD against the real safe area and reserved touch regions | the first HUD element ships |
| Draw calls in the Workshop with full signage and PBR | the Workshop is signed off |

Each of these has a stated failure condition, so the check can actually fail.
