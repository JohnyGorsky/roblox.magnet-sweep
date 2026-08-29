# VFX & lighting

The full recipe — palette, material kit, lighting values, post chain, VFX vocabulary and quality tiers —
is the [`magnet-sweep-style` skill](../../../.claude/skills/magnet-sweep-style/SKILL.md). Engineering is
the shared `roblox-vfx` skill. This page is the *system* view: what runs, when, and what it costs.

## There are no shaders

Roblox exposes no custom shader language. The glossy metal in the concept art is five layers together:

1. PBR maps — **`MaterialVariant` on Parts, `SurfaceAppearance` on MeshParts.** They are not
   interchangeable: `SurfaceAppearance` parented to a plain `Part` renders nothing. This game is
   parts-first, so `MaterialVariant` is the main path.
2. `LightingStyle = Realistic` (the successor to `Lighting.Technology = Future`)
3. `Lighting.EnvironmentSpecularScale`
4. a `Sky` + `Atmosphere` — **something for the metal to reflect**
5. `BloomEffect` + `ColorCorrectionEffect` + `SunRaysEffect`

The most commonly missed one is the fourth. A windowless factory box needs bright emissive signage and
coloured lights or the chrome dies.

Neither class has scalar metalness/roughness properties — only **uploaded maps**. The numbers in the
style skill are authoring targets for greyscale images, and those images are a costed asset task.

## What runs continuously

| Effect | Where | Cost control |
|---|---|---|
| Magnet field + idle arcs | on the player | one emitter, one beam pair |
| Conveyor motion, fans, machinery | every zone | texture offset and tweens, **not** physics |
| Neon signage + matching `PointLight` | Workshop and every station | `Shadows = false` on all of them |
| Arena combat VFX | the Arena | the single biggest concurrent cost. Budget it first |
| Warning beacons | during a Breach or Refresh | enabled in a batch, disabled in a batch |

## What is a burst

Pull trails, collection pops, the detach flash, the Breach wash, weld sparks, the SECURED banner, robot
damage stages, Arena Core capture. Bursts are pooled emitters that are `Enabled` and disabled, never
created and destroyed at runtime.

## Lighting budget

- ≤ **8 shadow-casting lights** visible at once. Only hero lights cast: the Arena Core, the player's
  magnet, a Service Hub gate.
- Every decorative `PointLight` has `Shadows = false`.
- Decorative lights beyond the tier's range threshold are disabled client-side.

## Quality tiers

The lighting style is place-wide and is **not script-writable at all** (`Lighting.Technology` is
`RobloxScriptSecurity` on read *and* write; its successors are readable but not writable) — Roblox
already degrades lighting on low-end clients. What the tier controls is client-side: the post chain,
PBR versus `Reflectance` fallback, decorative light range, particle rates, and `MaxConcurrentPull`.
Table in the style skill, §8.

## Verification

> 🔴 **Client VFX does not exist in an Edit session.** Every effect here is built by a `LocalScript` or
> created at runtime. An Edit screenshot of a clean scene is not evidence of anything. Verify in **Play,
> at the player's camera angle** — this workspace lost six rounds to exactly that mistake on The Last
> Tide.

> ⚠️ **`screen_capture` timing out means the client is not drawing.** Never drive an effect's finish
> from inside a `RenderStepped` loop that a capture will stall.

> ⚠️ **Keep the "before".** Regressions in look are invisible without a same-camera comparison.
