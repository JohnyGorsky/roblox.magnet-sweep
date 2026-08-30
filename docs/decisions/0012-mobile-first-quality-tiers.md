# 0012 — Mobile sets the budget; the gloss is a tier

**Status:** Accepted · 2026-08-29 · Job 001

## Context

The concept art is glossy: chrome, coloured light, bloom, reflections. Roblox has no custom shaders, so
that look is `SurfaceAppearance` PBR plus `Future` lighting plus post-processing — the expensive end of
the engine. Meanwhile the majority of the audience is on phones, and this game is *already* spending its
frame budget on pulled-object physics.

Defender burned four rounds of rework by deferring phone questions that Studio's Device Emulator would
have answered immediately.

> ⚠️ **Amended by [decision 0016](0016-low-tier-drops-the-variant.md) (2026-08-29).** This record
> originally said the Low tier swaps PBR for a `Reflectance` fallback. Measurement showed Reflectance is
> **inert on `Metal`**, the base material of five of the nine kit surfaces, so the Low tier **drops the
> `MaterialVariant` entirely** instead. Everything else here stands.

## Decision

- **Design to a mid-range phone.** That is the floor, and the floor is never optional.
- The glossy look ships as a **quality tier** on top of that floor, not as the baseline.
- The lighting style is a **place** setting, chosen in Studio by a human. `Lighting.Technology` has been
  superseded by `LightingStyle` (`Realistic` now carries the old `Future` role), and **none of these are
  script-writable** — `Lighting.Technology` is `RobloxScriptSecurity` on read *and* write. Roblox already
  degrades lighting on low-end clients. Everything else the tier controls is client-side and switchable
  by a `LocalScript`: post-processing effects, decorative light range, particle rates,
  `MaterialVariant` PBR on or off (see the amendment above), and `MaxConcurrentPull`.
- The tier is chosen from a **measured frame time**, never from `TouchEnabled` alone. A tablet is not a
  low-end phone; a cheap laptop is not a high-end PC.
- **Mobile questions are measured in the Device Emulator**, which gives real `TouchEnabled`, real
  `ViewportSize`, real safe-area canvas and Roblox's own `TouchGui` rects. Ask before switching Studio
  into it — it takes over the human's session.

Tier table: [`magnet-sweep-style` skill, section 8](../../.claude/skills/magnet-sweep-style/SKILL.md).

## Consequences

- Every visual feature is specified twice: what it is, and what it degrades to.
- The HUD must be laid out against the emulator's real safe area and Roblox's reserved thumbstick and
  jump-button regions, from the first HUD item.
- Pull-object caps and light counts are per-tier config values, not constants.

## The check

A visual item is not done until it has been **seen in the Device Emulator at the low tier**. "It should
be fine on mobile" is not a measurement.
