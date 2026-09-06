# FINDING 0012: the sky-fan measures occlusion, not appearance — it passed while the view failed

**Project:** `roblox.magnet-sweep`
**Status:** open
**Severity:** medium — it is a *verification* defect, which is worse than a content defect
**Created:** 2026-09-06 (job 021, Play pass)

**Symptom:** Job 021's headline proof is a 48×27 raycast sky-fan counting rays that hit nothing.
With the glazed roof standing it read **0.0 % sky** from a player base looking across the room — a
full pass. The screenshot from that exact camera still showed a **wide pale blue band across the
horizon that reads as sky.**

**Measured.** An elevation sweep from the same camera, reporting what each ray hits and how far:

| elevation | hits | distance |
|--:|---|--:|
| −6° … −1° | room floor, plinth | 81 … 185 |
| **0° … +2°** | **`Node0`, `PlateBack` — the far side of the Arena** | **404** |
| +3° … +5° | backdrop pipe collars | 440 |
| +6° … +12° | `L2` main backdrop, `Clere` clerestory | 462 … 468 |
| +15° | roof skirt | 492 |

**Nothing is sky.** The band is the far side of the room at 400–470 studs, hazed to nearly the same
value as the sky above it.

**Why this matters.** `sky %` was chosen as the metric precisely because it *can* fail, per
GROUND-RULES §7. It can — but it answers *"is there a hole?"*, and the owner's complaint was
*"the room reads flat"*, which is a question about **value contrast**, not holes. A metric that
passes while the reported symptom persists is the same shape as the Tide failure: measuring the
thing that is easy to measure rather than the thing that was reported.

**The physical cause.** `Atmosphere` fades distant geometry toward the haze colour. The style skill
§4 specifies `Density 0.32 / Haze 1.4 / Color 32,42,64`, which is authored for the factory
**corridors** — a zone you see 60–120 studs down. The Workshop is **489 studs across**, so the far
wall sits at 450+ and is almost fully fogged. Confirmed both directions:

- Haze colour moved toward the sky → the far wall **lifted out of black to pale blue**.
- Density dropped 0.32 → 0.11 → only a **small** gain; density alone is not the lever.

So the far wall's value tracks the haze colour and the sky's brightness, and under a **bright
daylight skybox** it lands at sky value no matter which way it is pushed. This is
[finding 0011](0011-bootstrap-wants-a-clocktime-band-whose-t.md)'s daylight-vs-night conflict
appearing visually.

**Where:** `Jobs/021`, the style skill §4 Atmosphere block, and any future job that reuses the
sky-fan as a proof.

**Fix idea:**
1. **Add a second metric that measures value, not occlusion** — e.g. sample rendered luminance in a
   horizon band vs a sky band and require a minimum contrast ratio. Until then, the sky-fan must be
   reported *alongside* a screenshot, never instead of one.
2. **The Atmosphere block needs a per-space value**, not one global. A 489-stud room and a 120-stud
   corridor cannot share `Density 0.32`.
3. The real resolution is finding 0011's: pick daylight hall or night factory. Under a dark sky the
   far wall reading dark is correct atmospheric perspective; under a bright sky it is a bug.
