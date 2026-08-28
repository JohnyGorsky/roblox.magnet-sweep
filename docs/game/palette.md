# Palette & colour language

The full art system — palette, PBR material kit, lighting recipe, VFX vocabulary, UI tokens and quality
tiers — lives in the **[`magnet-sweep-style` skill](../../.claude/skills/magnet-sweep-style/SKILL.md)**,
because it is what loads automatically when Claude works in this repo.

This page exists so a human reading `docs/` is not sent somewhere unexpected. Do not duplicate the
tables here; they will drift.

## The short version

**The look:** a bright, glossy, slightly absurd toy factory at night. Hard industrial shapes, saturated
signal colours, chrome catching coloured light, electric-blue arcs, neon signs naming every station.

**There are no shaders.** Roblox exposes no custom shader language. "Glossy metal" means five things
together: PBR `SurfaceAppearance`/`MaterialVariant` with metalness and low roughness; `Future` lighting;
`EnvironmentSpecularScale`; a `Sky` + `Atmosphere` for the metal to actually reflect; and a
Bloom + ColorCorrection + SunRays post chain. Miss one and metal reads as flat paint.

**Colour is a gameplay system.** Each signal colour owns exactly one meaning and is never reused for
decoration:

| Colour | Means |
|---|---|
| electric cyan `#41D8FF` | magnet, pull, electricity |
| signal red `#E03A2F` | the magnet's south pole, alarm, Salvage Breach |
| recycler green `#3FD64B` | recycle, Coins in |
| weld orange `#FF7A1A` | repair, robot HP |
| crown gold `#FFC21A` | Arena control — and hazard stripe |
| violet `#C46BFF` | epic rarity |

The magnet is **red and cyan, always** — it is the logo, the icon, the Arena Core and the cursor.

Rarity ramp, used identically in the HUD, the Part Archive, the Robot Builder and world outlines:
`Common` grey → `Uncommon` green → `Rare` cyan → `Epic` violet → `Legendary` gold → `Mythic` pink.
