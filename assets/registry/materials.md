# Material registry — the nine kit surfaces

**Why this file exists.** The `MaterialVariant` instances live in the place file (`MaterialService`
does not sync — see [systems/places](../../docs/systems/places/README.md)), so without this page the
32 texture asset ids exist in exactly one unversioned binary. Regenerate a variant and there would be
nothing to restore it from.

Created by **job 004**, 2026-08-29, using Roblox's in-Studio AI material generator
(`generate_material`). Each generation produced 4 candidates; the chosen one was promoted to a direct
child of `MaterialService` and the other 28 deleted.

Applied only through
[`MaterialKit`](../../studio_game/ReplicatedStorage/MaterialKit.luau) — never by hand.

## The eight generated variants

| Variant | BaseMaterial | Pattern | StudsPerTile | AlphaMode |
|---|---|---|---:|---|
| `MS_Grate` | DiamondPlate | Regular | 8 | Opaque |
| `MS_HazardStripe` | Metal | Regular | **6** | Opaque |
| `MS_PaintedGloss` | SmoothPlastic | Regular | 12 | Opaque |
| `MS_PaintedWorn` | Metal | Organic | 10 | Opaque |
| `MS_Rubber` | Rubber | Regular | 6 | Opaque |
| `MS_Rust` | CorrodedMetal | Organic | 10 | Opaque |
| `MS_SteelBrushed` | Metal | Regular | 8 | Opaque |
| `MS_SteelDark` | Metal | Regular | 10 | Opaque |

`MS_HazardStripe` at **StudsPerTile 6** is what delivers build group 02's *"hazard-stripe tiling that
survives scaling"* — tiling is per world-stud, so a stripe stays the same physical size however large
the part is. Do not change that value casually.

> ⚠️ **`AlphaMode` must stay `Opaque`.** Part `Color` multiplying the ColorMap is how `MS_SteelDark`
> and `MS_Rubber` are dark at all; a variant switched to `Transparency` breaks that tinting model.

## Texture asset ids

All 32 uploaded to `johnygorsky10` by the generator. **These properties are `PluginSecurity` on read**
— no runtime script can inspect them, which is why they are written down here.

| Variant | ColorMap | MetalnessMap | RoughnessMap | NormalMap |
|---|---|---|---|---|
| `MS_Grate` | `100119051349971` | `132053598171455` | `78256880787920` | `137375523932036` |
| `MS_HazardStripe` | `103050299200645` | `117906733335492` | `134330463575716` | `83184191742997` |
| `MS_PaintedGloss` | `111026565076154` | `87609501643080` | `123751890194778` | `89586080218274` |
| `MS_PaintedWorn` | `124108636299304` | `114284043803829` | `79490079202981` | `124715682578441` |
| `MS_Rubber` | `74703843274122` | `140307446791387` | `90679658033575` | `137841782403441` |
| `MS_Rust` | `81056345994054` | `99395386129739` | `102414771701915` | `103451965489156` |
| `MS_SteelBrushed` | `116298729078775` | `83981204598228` | `115986479017417` | `110127036576212` |
| `MS_SteelDark` | `135097875820869` | `87513260802763` | `93359546170082` | `79095706302185` |

Prefix each with `rbxassetid://`.

## The ninth surface has no variant

**`Chrome` is built-in `Metal` with no `MaterialVariant`.** Under the style skill's lighting recipe,
built-in Metal shows tight specular points where every generated variant showed a broad soft wash.
See [decision 0016](../../docs/decisions/0016-low-tier-drops-the-variant.md) and the style skill §3.

## Known issues

| Issue | Detail |
|---|---|
| **`MS_PaintedGloss` cannot take a zone accent** | Its ColorMap has a strong red baked in. Part `Color` multiplies, so a pink accent renders red. Regenerate with a **neutral** prompt when zone colour work starts — a neutral map is worth more than a correctly-coloured one. |
| **`MS_Rubber` has no belt ribbing** | Short prompts succeed but produce featureless output. Ribbing comes from geometry + texture offset, as the style skill already specifies. |
| **The 18 flat greyscale metalness/roughness maps were never authored** | `docs/build/job-order.md` lists them as a job-004 deliverable. Generated maps were used instead, so the style skill's Metalness/Roughness columns are **authoring intent, not shipped values**. Hand-authoring them remains the untested route to a true PBR mirror. |

## Regenerating a variant — what job 004 learned

- **Long prompts fail.** `MaterialGenTool:650: invalid argument #2 to 'assert'`. Shortening the same
  prompt succeeds. Four of the nine needed a retry.
- **The word "hazard" trips a filter.** "industrial hazard warning stripes" failed twice;
  "alternating diagonal yellow and black painted bands on worn steel plate" worked first time.
- **Short prompts produce bland output.** There is a real tradeoff between "succeeds" and "detailed".
- Generation creates **4 candidates** in `MaterialService/AssistantMaterials/Material: <id>/`. They
  resolve by name even while nested, but the chosen one should be promoted to a **direct child** of
  `MaterialService` — `MaterialKit.audit()` uses `FindFirstChild`, which only sees direct children.
- **A variant resolves by name AND `BaseMaterial`.** Right name, wrong base material = renders as the
  plain built-in material, silently. `MaterialKit.audit()` checks both, and Bootstrap treats a
  mismatch as fatal in Studio.
