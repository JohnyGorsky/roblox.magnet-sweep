# FINDING 0011: Bootstrap wants a ClockTime band whose top half is after sunset

**Project:** `roblox.magnet-sweep`
**Status:** open
**Severity:** medium
**Created:** 2026-09-06

**Symptom:** The Workshop went dark after `Lighting.ClockTime` was set to 17.5 — a value inside the
band `Bootstrap.server.luau` warns for on every start (*"ClockTime 15.60, style wants 16.50–18.50"*),
and the same band the `magnet-sweep-style` skill §4 implies. The owner's words during job 021 were
*"i removed top big panel now we have light, but we need more light"* — the roof was blamed, and it
was only part of it.

**Measured** — `Lighting:GetSunDirection()` swept across the band in the live Edit session:

| ClockTime | sun elevation | floor shadow length |
|--:|--:|--:|
| 14.00 | 52.6° | 0.77 × height |
| **15.60** — what job 020 shipped | **32.6°** | 1.56 × height |
| **16.50** — bottom of the "wanted" band | **20.5°** | 2.67 × height |
| 17.00 | 13.7° | 4.09 × height |
| **17.50** | **6.9°** | 8.29 × height |
| **18.00** | **−0.0° — BELOW THE HORIZON** | — |
| **18.50** — top of the "wanted" band | **−6.9° — below the horizon** | — |

So the warned-for band **16.50–18.50 runs from a low sun to well after sunset**. Anything above
≈17.95 has no direct sun at all. A place set to the middle of the band, 17.5, has a 6.9° sun that
casts shadows 8× the height of whatever throws them — which is why a 24-stud wall blacked out a
large part of a 489-stud room.

The value job 020 actually shipped, **15.60, is the only one in play that lights the floor** — and it
is the value Bootstrap warns *against* on every single start.

**Where:** `Bootstrap.server.luau` (the lighting drift check) and
`.claude/skills/magnet-sweep-style/SKILL.md` §4.

**Why it matters beyond the warning being wrong:** the check trains people to "fix" a correct value
into a broken one. It is the same failure shape as job 020's `StationService` validation block, which
reported twelve errors against a correct room and taught people to ignore station errors.

**Repro / notes:** Set `Lighting.ClockTime = 17.5`, stand in the Workshop, look at the floor. Then
`GetSunDirection()` and read `.Y`.

**Fix idea:** Two coherent resolutions, and the game has to pick one deliberately rather than drift:

1. **Daylight hall** — narrow the band to roughly **15.0–16.5** (sun 20–33°), accept that the sun is
   the room's main light, and keep the sky. Cheapest, brightest, but it is not the "night factory"
   the style skill opens with.
2. **Night factory** — keep the late band, and commit to the room being lit by its own emissive:
   a glazed roof, clerestory, strip-lights and lamp gantries. This is what the concept art shows and
   what §4 of the style skill is implicitly assuming, but it is **not currently true of the place**,
   so the warning fires against a room that has no artificial lighting to fall back on.

Job 021 currently sits at **ClockTime 16.2** (sun 24.6°) as a working compromise, with
`Ambient` raised to 46,54,72 and `ExposureCompensation` 0.35. That is a stopgap, not the decision.

⚠️ Whichever is chosen, the Bootstrap warning must be edited to match, or it will keep telling
everyone the lit value is wrong.
