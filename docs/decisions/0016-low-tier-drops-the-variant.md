# 0016 — The Low tier drops the MaterialVariant; Reflectance is not a fallback

**Status:** Accepted · 2026-08-29 · Job 004
**Amends:** [0012 — Mobile sets the budget; the gloss is a tier](0012-mobile-first-quality-tiers.md)

## Context

Decision 0012 said the Low quality tier swaps PBR for a **`Reflectance` fallback**. That was written
before any material existed, from the reasonable-sounding idea that `Reflectance` mirrors the skybox
cheaply and would stand in for a PBR surface.

Job 004 built the nine surfaces and measured it.

## What was measured

Under the [style skill §4 lighting recipe](../../.claude/skills/magnet-sweep-style/SKILL.md) —
`LightingStyle = Realistic`, Brightness 2, dark cool ambient, `EnvironmentSpecularScale = 1`,
Atmosphere and ColorCorrection present — a two-material sweep of `Reflectance` at 0.0 / 0.35 / 0.70 / 1.0:

| Material | Result |
|---|---|
| `Metal` | **no visible change across the whole range** |
| `SmoothPlastic` | **clear progression** — pale and diffuse at 0.0, dark with strong saturated reflection at 1.0 |

This matches Roblox's own documentation, which says Reflectance *"may or may not be ignored depending on
the `Material` of the part."*

**Five of the nine kit surfaces are Metal-based** (Chrome, SteelBrushed, SteelDark, PaintedWorn,
HazardStripe). A Reflectance fallback would therefore be a no-op on the majority of the world — a saving
that *looked* like one in the tier table and did nothing on screen.

## Decision

**The Low tier drops `MaterialVariant` entirely** and renders the built-in base material with the flat
palette colour. `Reflectance` is not used as a quality lever anywhere.

The saving is direct and real: no texture fetches, no PBR sampling. The palette colour still carries the
read, which is what makes the tier acceptable rather than merely cheap.

## Consequences

- `MaterialKit.apply` must become tier-aware, and must record which surface a part carries so the tier
  controller can strip and restore it. Without that record, a client-side tier change cannot find the
  parts it needs to touch, and retrofitting it after the world is built means re-walking every model.
- `Config/Quality.Tier.usePBR` becomes a flag something actually reads.
- `Reflectance` remains available as an *authoring* choice on non-metal surfaces, judged per material.
  It is simply not a tier mechanism.

## What this does not claim

An earlier draft of the style skill said Reflectance was **inert everywhere**. That was a Metal-only
test generalised to the whole place, and it was wrong — the `SmoothPlastic` row disproves it.

Both measurements were taken in **Edit**. Edit is legitimate for material appearance in a way it is not
for client VFX, because the same renderer draws it — but
[PITFALLS #1](../PITFALLS.md#1-verified-in-edit-where-the-bug-could-not-appear) still applies, and
neither result has been confirmed in Play.

## The check

Before the tier controller ships, confirm in **Play** on the reference device that dropping the variant
measurably reduces frame time. If it does not, this decision has bought nothing and the Low tier should
take its savings from lights and particles instead.
