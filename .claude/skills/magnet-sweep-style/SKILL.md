---
name: magnet-sweep-style
description: MAGNET SWEEP art, material and UI design system — the "glossy industrial toy factory" look from the concept art. Carries the palette, the PBR material kit that makes metal read as metal (MaterialVariant/SurfaceAppearance, metalness/roughness targets), the Future-lighting + Atmosphere + post-processing recipe that produces the gloss, the neon/hazard-stripe signage language, the electric-arc VFX vocabulary, and the mobile quality tiers that keep all of it affordable. Use when building or restyling ANY model, prop, room, GUI, HUD, sign, VFX, light or scene in roblox.magnet-sweep so it matches the concept art. Roblox has no custom shaders — this skill is what "shader" means here.
---

# MAGNET SWEEP — art & material style

**The look:** a bright, glossy, slightly absurd toy factory at night. Hard industrial shapes, saturated
signal colours, chrome and painted metal catching coloured light, electric-blue arcs, and neon signage
naming everything in the room. Chunky and readable, never grimy realism.

Reference: `assets/concept_art/` — `Arena.png` (the Workshop hub), `Robot.png` (the pull moment),
`Robot2.png` (the Robot Bay), `Robot3.png` (arena key art), `Logo.png`.

> ⚠️ **Mockups are direction, not spec.** The concept art sets colour, mood and material feel. It is
> not a feature list — never build a mechanic because it appears in a painting.

---

## 1. There are no shaders

Roblox exposes **no** custom shader language — no HLSL, no GLSL, no post-process you can author. When
this repo says "glossy metal shader" it means exactly five things, and nothing else:

| Layer | What produces the gloss |
|---|---|
| **PBR surface** | `SurfaceAppearance` / `MaterialVariant` with a **MetalnessMap** and a low-value **RoughnessMap** |
| **Lighting technology** | `Lighting.Technology = Future` — per-pixel lighting, real specular highlights from every light |
| **Environment response** | `Lighting.EnvironmentSpecularScale` — how much of the sky the metal reflects |
| **What there is to reflect** | a `Sky` + `Atmosphere`. Chrome with nothing to reflect looks like grey plastic |
| **Post-processing** | `BloomEffect` + `ColorCorrectionEffect` + `SunRaysEffect` |

Miss any one and metal reads as flat paint. The most commonly missed one is the fourth: **reflective
material is only as interesting as its environment**, which is why a windowless factory box needs
bright emissive signage and coloured lights to give the chrome something to catch.

---

## 2. Palette

Colours are a **gameplay language**, not decoration. A player must be able to tell what a thing does
from its colour before reading a word.

### Structural

| Role | Hex | `Color3.fromHex` | Where |
|---|---|---|---|
| Factory dark | `#0E1526` | deep navy-slate | background walls, far machinery, void |
| Steel mid | `#4A545E` | brushed dark steel | frames, gantries, conveyor bodies |
| Chrome light | `#B8C2CC` | polished steel | pipes, rails, rare-part metal, the spoon |
| Hazard yellow | `#FFC21A` | signal yellow | stripes, gantry rails, robot-arm housings |
| Hazard black | `#14161C` | near-black | the other half of every stripe |
| Rust | `#8A4B2A` | oxide brown | wear, salvage, the *homemade* robot |

### Signal (each owns one meaning — never reuse)

| Meaning | Hex | Used by |
|---|---|---|
| **Magnet / pull / electricity** | `#41D8FF` electric cyan | magnet field, arcs, trails, the north pole |
| **Magnet south pole / danger** | `#E03A2F` signal red | the red half of every magnet, alarms, Salvage Breach |
| **Recycle / money in** | `#3FD64B` recycler green | Recycler, Coin gain, scrap conversion |
| **Repair / robot health** | `#FF7A1A` weld orange | Repair Station, weld sparks, HP restore |
| **Rare / legendary** | `#C46BFF` violet → `#FFC21A` gold | part rarity ramps, LEGENDARY DETECTED |
| **Arena control** | `#FFC21A` crown gold | Arena Core when held, control timer |

The magnet is **red + cyan, always, everywhere** — the poles are the game's logo, its icon, its Arena
Core and its cursor. Never render a magnet in other colours except as a purchased skin.

### Rarity ramp

`Common #B8C2CC` → `Uncommon #3FD64B` → `Rare #41D8FF` → `Epic #C46BFF` → `Legendary #FFC21A` →
`Mythic #FF3D7F`. Used identically in the HUD, the Part Archive, the Robot Builder and the world
outline on an uncollected part.

---

## 3. The material kit

Build the factory from **Parts**, not meshes (§64 of the spec: 70–80 % reusable primitives). Parts take
`MaterialVariant` too — a parts-first kit is not a low-fidelity kit.

Nine variants cover almost the whole game. Each is a `MaterialVariant` under `MaterialService`, applied
by setting `part.Material = <BaseMaterial>` + `part.MaterialVariant = "<name>"`.

| Variant | Base | Metalness | Roughness | Reads as |
|---|---|---:|---:|---|
| `MS_Chrome` | Metal | 1.0 | 0.08 | mirror chrome — the Giant Spoon, hero pipes |
| `MS_SteelBrushed` | Metal | 1.0 | 0.35 | machine housings, gantries |
| `MS_SteelDark` | Metal | 1.0 | 0.55 | structure, the parts that must recede |
| `MS_PaintedGloss` | SmoothPlastic | 0.0 | 0.15 | painted machine panels, toy-factory colour |
| `MS_PaintedWorn` | Metal | 0.8 | 0.45 | the robot's salvaged body panels |
| `MS_HazardStripe` | Metal | 0.9 | 0.30 | tiled yellow/black — **the game's signature texture** |
| `MS_Rubber` | Rubber | 0.0 | 0.90 | conveyor belts, tyres, grips |
| `MS_Grate` | DiamondPlate | 1.0 | 0.40 | walkways, floors, vents |
| `MS_Rust` | CorrodedMetal | 0.7 | 0.75 | salvage, old parts, the Heavy Yard |

**Rules**

- **Roughness is the whole game.** The difference between "toy" and "grimy" is one number. Hero objects
  (rare parts, the magnet, the Arena Core) sit at **0.05–0.20**. Background structure sits at
  **0.45–0.70**. If everything is glossy, nothing is.
- **`Neon` never takes a `SurfaceAppearance`.** Emissive signage is plain `Neon` + a matching
  `PointLight`. The glow the player sees is the Bloom pass, not the material.
- **`Reflectance` is the cheap fallback**, not the goal. A `BasePart.Reflectance` of 0.2–0.4 mirrors the
  skybox with no texture upload and no PBR cost — correct for the lowest quality tier and for distant
  background metal. It is *not* correct for a hero prop.
- **Meshy imports:** set `CollisionFidelity = PreciseConvexDecomposition` on anything a player can walk
  under or through a gap in. Box is the default and it is wrong for spoons, forks and crane hooks.

---

## 4. Lighting recipe

```
Lighting.Technology            = Future
Lighting.Ambient               = 20, 24, 34      -- cold shadow, never black
Lighting.OutdoorAmbient        = 28, 34, 48
Lighting.Brightness            = 2
Lighting.EnvironmentDiffuseScale  = 0.55
Lighting.EnvironmentSpecularScale = 1.0          -- << the gloss lever
Lighting.ExposureCompensation  = 0.15
Lighting.GlobalShadows         = true

Atmosphere.Density  = 0.32     Atmosphere.Haze = 1.4
Atmosphere.Color    = 32,42,64 Atmosphere.Decay = 92,110,150
Atmosphere.Glare    = 0.5      Atmosphere.Offset = 0.15
```

Post-processing chain, in this order:

| Effect | Settings | Why |
|---|---|---|
| `BloomEffect` | Intensity `0.8` · Size `20` · Threshold `1.6` | makes Neon signage and electric arcs bloom |
| `ColorCorrectionEffect` | Saturation `+0.18` · Contrast `0.10` · Tint `240,246,255` | the concept art's punch |
| `SunRaysEffect` | Intensity `0.08` · Spread `0.6` | only where a zone has a sky window |
| `DepthOfFieldEffect` | **off in gameplay** | reserved for the Robot Bay install cinematic |

**Atmosphere is not optional.** A legacy `FogEnd` does nothing once an `Atmosphere` exists, and without
one the long factory corridor has no depth cue and the chrome has nothing soft to reflect.

**Lights**

- Every Neon sign gets a `PointLight` of the same colour, `Brightness 2–4`, `Range 16–28`.
- `Shadows = false` on all decorative lights. Only hero lights (the Arena Core, the magnet, a Service
  Hub gate) cast shadows.
- Budget: **≤ 8 shadow-casting lights visible at once**, checked in the Device Emulator, not guessed.

---

## 5. Signage & the industrial kit

Every functional station in the Workshop names itself with a **neon slab sign** — that is the single
strongest identity cue in `Arena.png`:

- Dark slate housing with a chamfered chrome bezel.
- `Neon` text panel in the station's signal colour, all-caps, wide tracking: **MAGNET LAB**, **RECYCLER**,
  **ROBOT BAY**, **SCRAP ARENA**, **REPAIR**.
- A matching `PointLight` behind it, and hazard stripe on the plinth below.

Recurring kit pieces, reused everywhere: hazard-striped floor edging · yellow tubular guard rails ·
chrome pipe runs with red valve wheels · yellow robot arms with black joints · slate control panels with
cyan screens · floor arrows in white · caged amber warning beacons · open scrap crates in red/blue/yellow.

---

## 6. VFX vocabulary

| Moment | Effect |
|---|---|
| Magnet idle | slow `#41D8FF` pulse on the poles, faint hum, tiny `ParticleEmitter` sparks |
| Object REACT | object shakes, small white sparks at the contact face |
| Object PULL | `Trail` in cyan behind each object; `Beam` arc from magnet to the heaviest one |
| Magnet Flow x2–x5 | field radius sphere grows, arc `Beam` count rises, pickup pitch rises |
| MAGNET RUSH | ground shockwave ring, screen-edge cyan vignette, light pulse |
| Part breaks free | white flash → `#E03A2F` alarm wash → screen shake → debris burst |
| Salvage Breach | rotating amber beacons enable across the zone, red edge vignette |
| Weld / repair | `#FF7A1A` sparks, a short `Beam` from the chute, metal *tzzzt* |
| Arena Core held | gold volumetric column, slow rotation, crown particles |
| Robot damaged | sparks at 50 %, smoke at 25 %, arcing electricity at 10 % |

Electric arcs are always **`Beam` with a jagged texture + white core + cyan outer**, never a particle
spray. That white-hot core is what sells the voltage in `Robot.png`.

---

## 7. UI

Follow `roblox-ui` for engineering (UDim2 scale, `UIAspectRatioConstraint`, safe areas) and `mobile`
for measurement. The visual layer:

- **Panel:** `#141B2Bcc` fill, 2 px `#41D8FF` stroke at 40 % transparency, `UICorner` 8 px, a 1 px inner
  chrome highlight on the top edge.
- **Type:** `Gotham`/`GothamBold` for data, all-caps `Bangers`-weight display for banners
  (**MAGNET RUSH!**, **SALVAGE BREACH**, **SECURED**). Never mix more than two.
- **Numbers are hero.** Coins, scrap and Arena timer are large, monospaced-feeling, and animate on
  change (count-up, then a scale punch).
- **Keep the screen clean** (§55). Coins top-left, Flow top-centre *only while active*, Scrap
  bottom-centre, robot/Arena widget compact on the side. This is not a simulator wall of buttons.
- Every button has a pressed state, a sound and a 0.08 s scale tween. Silence reads as broken.

---

## 8. Quality tiers

Mobile-first ([decision 0012](../../../docs/decisions/0012-mobile-first-quality-tiers.md)). One place
setting, three client profiles. `Lighting.Technology` is place-wide and **cannot** be set per player —
Roblox already degrades it on low-end clients — so the tier controls what a `LocalScript` can actually
change.

| | Low (phone floor) | Medium | High (PC) |
|---|---|---|---|
| Post-processing | Bloom only | Bloom + ColorCorrection | full chain |
| PBR `SurfaceAppearance` | swapped for `Reflectance` | on hero props | everywhere |
| Decorative `PointLight`s | disabled beyond 40 studs | 60 studs | all |
| Particle emitters | halved `Rate` | normal | normal + trails |
| Concurrent PULL objects | see [0005](../../../docs/decisions/0005-four-state-scrap-budget.md) | | |

The tier is chosen from a measured frame time, never from `UserInputService.TouchEnabled` alone — a
tablet is not a low-end phone and a low-end laptop is not a high-end one.

---

## 9. Hard don'ts

- ❌ Don't say "shader". There isn't one. Say which of the five layers you mean.
- ❌ Don't make everything glossy — roughness contrast *is* the material read.
- ❌ Don't build a factory room with no emissive light source; the chrome will die.
- ❌ Don't recolour the magnet away from red/cyan outside a cosmetic skin.
- ❌ Don't reuse a signal colour for decoration. Green means recycle. Orange means repair.
- ❌ Don't ship a sleek humanoid robot. Homemade, asymmetric and ridiculous is the point (§39).
- ❌ Don't add a UI element without a sound and a state change.
