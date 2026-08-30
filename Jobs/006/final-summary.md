# Job #006 — final summary

**Project:** `roblox.magnet-sweep` · **Status:** complete · 2026-08-29

Covers build group 03 — the lighting items plus the quality-tier system. The job ladder split these
across 006/007; they merged because the lighting recipe had already been applied during job 004 (see
below), and the tier system cannot be judged without it.

## 🔴 The finding that reshaped the job

The manifest said: *"Measure the three tiers in the Device Emulator and record the numbers."*

**The Device Emulator cannot measure performance.** It gives real `TouchEnabled`, real `ViewportSize`,
real safe-area canvas and Roblox's own `TouchGui` rects — which answer **layout** questions completely,
and are the reason the `mobile` skill insists on using it. But it renders on the developer's GPU at a
small viewport, so its frame rate is the developer's frame rate. A "30fps in the emulator" reading says
nothing about a phone.

That item conflated two different things, and following it would have produced confident, meaningless
numbers. Corrected in the manifest and generalised into `Config/Perf`.

## What was delivered

**[`Config/Perf`](../../studio_game/ReplicatedStorage/Config/Perf.luau)** — the reference device, the
budgets, and a **measurement register** that labels every performance claim by kind:

| Kind | Meaning |
|---|---|
| `TARGET` | a design decision. Not measured, not measurable here |
| `MEASURED` | readable in Studio now. Absolutes are dev-machine values; **relatives** are meaningful |
| `DEVICE` | answerable **only** on real hardware. A human action |

**Reference device:** mid-range Android ~2021, 30 fps / 33.3 ms — the middle of the mobile audience
rather than its floor. If the game only holds on a flagship, the design is wrong.

**Four `DEVICE` questions are open and Bootstrap says so at every startup**, so none can be quietly
closed from a Studio reading:

```
[S][Bootstrap] CONFIG [DEVICE] 4 performance question(s) can only be answered on real hardware:
  max-concurrent-pull, arena-robot-count, workshop-plus-two-zones, low-tier-saving
```

That last one is decision 0016's own stated check — if dropping the `MaterialVariant` does not
measurably reduce frame time, the Low tier bought nothing.

**[`QualityController.local.luau`](../../studio_game/StarterPlayerScripts/QualityController.local.luau)**
— measures real frame time over a sampled window (with warm-up), classifies with tier-signed hysteresis,
and applies: post-processing chain, decorative light range (skipping lights tagged `Hero`),
particle rate scaling from a remembered base, and `MaterialVariant` on/off.

`.local.luau` deliberately — a `.client.luau` here runs twice, which would mean two competing tier
controllers.

**Lighting completed.** `Sky` configured dark and cool with celestial bodies off; the rest of the recipe
(Brightness 2, dark cool ambient, exposure, Atmosphere, ColorCorrection, Bloom, SunRays) was applied
during job 004 because material judgement was impossible without it — job-order rule 1, learned the hard
way in that job.

## Verification

```
[S][Bootstrap] ready. 12 zones, arena cap 6, pull caps 40/80/160 | fatal 0, warnings 4
[C][Quality] tier=Medium | pbr=true | pullCap=80
[C][Quality] touch=false (a hint only, never the decision)
[C][Quality] frame time 16.6ms, staying on Medium
```

Tier mechanism proven to actually do something:

| Tier | Chrome | HazardStripe | Rust | SteelBrushed |
|---|---|---|---|---|
| start | `""` | `MS_HazardStripe` | `MS_Rust` | `MS_SteelBrushed` |
| **Low** | `""` | `""` | `""` | `""` |
| **High** | `""` | `MS_HazardStripe` | `MS_Rust` | `MS_SteelBrushed` |

Chrome correctly stays empty throughout — it has no variant by design (decision 0016).

## 🔴 I repeated a trap I had already fixed and documented

`Perf.REGISTER: { Measurement } = {` — a type annotation on a **table field**, which is a syntax error.
The identical mistake took down seven files in job 003, was fixed, and was written up. Then I did it
again three jobs later.

Now [PITFALLS #47](../../docs/PITFALLS.md#47-a-type-annotation-on-a-table-field-is-a-syntax-error-and-it-looks-fine),
with a grep that catches it before running:

```
grep -rn "^[A-Za-z_][A-Za-z0-9_.]*\.[A-Za-z0-9_]*\s*:\s*[^=]*=\s*{" studio_game --include=*.luau
```

Currently returns nothing across all 18 modules.

## Deduplicated

`Quality.BUDGET` previously carried its own empty budget fields. It now defers to `Config/Perf`, which
is the single source of truth — the same drift that decision 0005's pull cap had to be rescued from.

## Outstanding

- **This job has had no independent review.** Given that jobs 003, 004 and 005 each had a real defect
  found by one, it should get one before job 008 builds on the tier system.
- The four `DEVICE` questions need a published place and a real phone.
- `DepthOfFieldEffect` (P1, Robot Bay cinematic) and the shadow-light audit tool (P1) are not built.

## Next

**Job 007 — the magnet core.** The four-state machine, the object pool, the capped pull, batched server
grants. It is the first job that produces something a player can do, and jobs 007-009 are
[the gate](../../docs/roadmap/mvp.md#the-gate).
