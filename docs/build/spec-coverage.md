# Spec coverage

The source of record is `assets/MAGNET SWEEP.md` — **87 numbered sections**. This table says where each
one's content landed.

> 🔴 **A link is not coverage.** ELEVATOR 13's equivalent table marked three sections covered because a
> link *resolved*; the linked page did not contain the content
> ([PITFALLS #9](../PITFALLS.md#9-coverage-by-link-is-not-coverage)). The "What arrived" column below
> names the specific content, so the claim can be checked and can fail.

## The table

| § | Section | Landed in | What arrived |
|--:|---|---|---|
| 1 | High-Level Concept | [game/vision.md](../game/vision.md) |  |
| 2 | Primary Player Fantasy | [game/vision.md](../game/vision.md) |  |
| 3 | Core Pillars | [game/pillars.md](../game/pillars.md) | 5 pillars, each with a test |
| 4 | Roblox Store Description | [roadmap/launch.md](../roadmap/launch.md) | the description **verbatim**, all 8 bullets |
| 5 | Game Icon | [roadmap/launch.md](../roadmap/launch.md) | icon spec |
| 6 | Thumbnail Set | [roadmap/launch.md](../roadmap/launch.md) | 4 thumbnails |
| 7 | Loading Screen | [systems/boot](../systems/boot/README.md) |  |
| 8 | Initial Spawn | [systems/places](../systems/places/README.md) + [build/05](05-workshop.md) | and it is the reason for decision 0001 |
| 9 | First-Time Player Experience | [systems/boot](../systems/boot/README.md) | the no-tutorial onboarding |
| 10 | Main Gameplay Loop | [game/core-loop.md](../game/core-loop.md) | all 15 steps |
| 11 | Player Upgrade Systems | [systems/magnet](../systems/magnet/README.md) | 4 stats |
| 12 | Rare Cargo | [systems/cargo](../systems/cargo/README.md) | weight classes |
| 13 | Magnet Physics States | [systems/magnet](../systems/magnet/README.md) + [decision 0005](../decisions/0005-four-state-scrap-budget.md) | the 4 states, with a physics budget attached |
| 14 | Magnet VFX | [systems/magnet](../systems/magnet/README.md) + [style skill §6](../../.claude/skills/magnet-sweep-style/SKILL.md) | all 5 magnet states incl. Overcharge |
| 15 | Sound Design | [systems/audio](../systems/audio/README.md) | all 9 sound families |
| 16 | Magnet Flow | [systems/magnet](../systems/magnet/README.md) | Flow x1-x5 and Rush |
| 17 | Factory Structure | [systems/factory](../systems/factory/README.md) + [decision 0003](../decisions/0003-forward-is-the-only-direction.md) |  |
| 18 | Service Hubs | [systems/factory](../systems/factory/README.md) | all 7 hub contents (MagRail is one of them) |
| 19 | Factory Reset System | [systems/factory](../systems/factory/README.md) + [decision 0006](../decisions/0006-the-factory-refreshes.md) | all 3 cycles, all 5 Shifts |
| 20 | Rare-Part Spawn Rules | [systems/factory](../systems/factory/README.md) |  |
| 21 | Taking a Robot Part | [systems/cargo](../systems/cargo/README.md) |  |
| 22 | Escape Gameplay | [systems/cargo](../systems/cargo/README.md) | return lanes + 8 hazards |
| 23 | Guardians | [systems/guardians](../systems/guardians/README.md) |  |
| 24 | Player Competition | [systems/cargo](../systems/cargo/README.md) + [decision 0007](../decisions/0007-server-owns-capture-and-reward.md) |  |
| 25 | Zone / Tier Progression | [content/zones](../content/zones/README.md) | all 12 tiers |
| 26 | Tier 1 - COLOR WORKSHOP | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 27 | Tier 2 - TOY ASSEMBLY | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 28 | Tier 3 - MEGA KITCHEN | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 29 | Tier 4 - WAREHOUSE | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 30 | Tier 5 - CITY STORAGE | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 31 | Tier 6 - VEHICLE WORKSHOP | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 32 | Tier 7 - CAR FACTORY | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 33 | Tier 8 - HEAVY YARD | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 34 | Tier 9 - POWER PLANT | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 35 | Tier 10 - ROBOT LABORATORY | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 36 | Tier 11 - SPACE FOUNDRY | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 37 | Tier 12 - QUANTUM REACTOR | [content/zones](../content/zones/README.md) + [content/parts-catalog.md](../content/parts-catalog.md) | 8 parts, guardian, theme |
| 38 | Robot Slots | [systems/robot-assembly](../systems/robot-assembly/README.md) | 7 slots |
| 39 | Robot Visual Philosophy | [systems/robot-assembly](../systems/robot-assembly/README.md) | the homemade rule |
| 40 | Duplicate Parts | [systems/robot-assembly](../systems/robot-assembly/README.md) | Reinforce / Recycle |
| 41 | Part Collection | [systems/robot-assembly](../systems/robot-assembly/README.md) | Part Archive |
| 42 | Robot Assembly | [systems/robot-assembly](../systems/robot-assembly/README.md) | install sequence |
| 43 | Arena | [systems/arena](../systems/arena/README.md) + [decision 0010](../decisions/0010-one-robot-per-player-persistent-arena.md) |  |
| 44 | Arena Objective | [systems/arena](../systems/arena/README.md) |  |
| 45 | Arena Control | [systems/arena](../systems/arena/README.md) |  |
| 46 | Robot AI | [systems/arena](../systems/arena/README.md) + [systems/robot-rig](../systems/robot-rig/README.md) | the 7-step AI ladder |
| 47 | Robot Damage | [systems/arena](../systems/arena/README.md) |  |
| 48 | Robot Repair | [systems/economy](../systems/economy/README.md) | the pinch |
| 49 | Active Arena Repair | [systems/arena](../systems/arena/README.md) | Repair Chute + rate limits |
| 50 | Arena Heat | [systems/arena](../systems/arena/README.md) | all 4 Heat bands |
| 51 | Arena Notifications | [systems/arena](../systems/arena/README.md) |  |
| 52 | Robot Build Archetypes | [systems/robot-assembly](../systems/robot-assembly/README.md) | all 5 archetypes |
| 53 | Resource Decision Loop | [systems/economy](../systems/economy/README.md) |  |
| 54 | Dynamic Events | [content/events.md](../content/events.md) | all 8 events |
| 55 | GUI - Main HUD | [game/ui-direction.md](../game/ui-direction.md) | the full HUD table |
| 56 | Rare Cargo HUD | [game/ui-direction.md](../game/ui-direction.md) |  |
| 57 | Robot Builder GUI | [game/ui-direction.md](../game/ui-direction.md) + [systems/ui](../systems/ui/README.md) |  |
| 58 | Arena GUI | [systems/arena](../systems/arena/README.md) + [systems/ui](../systems/ui/README.md) |  |
| 59 | Robot Naming | [systems/robot-assembly](../systems/robot-assembly/README.md) | incl. text filtering |
| 60 | Robot Damage Visuals | [systems/arena](../systems/arena/README.md) + [systems/robot-rig](../systems/robot-rig/README.md) | all 6 damage stages |
| 61 | Gate Progression | [systems/factory](../systems/factory/README.md) | physical gate pull |
| 62 | Suggested Initial Power Curve | [systems/factory](../systems/factory/README.md) | the full 12-zone power table |
| 63 | Speed Progression | [systems/magnet](../systems/magnet/README.md) | speed progression |
| 64 | Environment Construction | [systems/factory](../systems/factory/README.md) + [build/02](02-industrial-kit.md) | the full modular kit |
| 65 | Asset Priorities | [systems/factory](../systems/factory/README.md) | asset priorities |
| 66 | Performance | [systems/performance](../systems/performance/README.md) + [decision 0005](../decisions/0005-four-state-scrap-budget.md) |  |
| 67 | Multiplayer Physics | [decision 0002](../decisions/0002-magnet-is-client-felt-server-owned.md) + [0007](../decisions/0007-server-owns-capture-and-reward.md) |  |
| 68 | Saving | [systems/save-data](../systems/save-data/README.md) | the full persist list |
| 69 | Death / Reset | [systems/save-data](../systems/save-data/README.md) |  |
| 70 | Monetization | [game/monetization-stance.md](../game/monetization-stance.md) |  |
| 71 | Developer Products | [game/monetization-stance.md](../game/monetization-stance.md) |  |
| 72 | Cosmetics | [content/cosmetics.md](../content/cosmetics.md) | all 7 categories |
| 73 | What NOT to Sell | [decision 0011](../decisions/0011-robux-never-buys-arena-power.md) | turned into a test |
| 74 | First 10 Minutes | [game/core-loop.md](../game/core-loop.md) | the full 10-minute table |
| 75 | Midgame | [roadmap/mvp.md](../roadmap/mvp.md) | all 7 midgame goals |
| 76 | First "Ending" | [content/endgame.md](../content/endgame.md) | The Foundry Heart |
| 77 | Endless Line | [content/endgame.md](../content/endgame.md) | Endless Line |
| 78 | Endgame Parts | [content/endgame.md](../content/endgame.md) | all 7 Relic Parts named |
| 79 | Overclock / Prestige | [decision 0013](../decisions/0013-overclock-not-rebirth.md) + [content/endgame.md](../content/endgame.md) |  |
| 80 | Endgame Goals | [content/endgame.md](../content/endgame.md) | all 6 goals |
| 81 | Daily Leaderboards | [content/endgame.md](../content/endgame.md) | all 5 boards |
| 82 | Daily / Weekly Content | [content/endgame.md](../content/endgame.md) + [roadmap/launch.md](../roadmap/launch.md) |  |
| 83 | MVP | [roadmap/mvp.md](../roadmap/mvp.md) | full MVP scope |
| 84 | MVP Success Criteria | [roadmap/mvp.md](../roadmap/mvp.md) | the gate |
| 85 | Recommended Build Order | [build/README.md](README.md) | **deliberately re-ordered** -- see divergences |
| 86 | Core Design Rule | [game/pillars.md](../game/pillars.md) | the core design rule |
| 87 | Final Game Identity | [game/vision.md](../game/vision.md) |  |

**87 of 87 sections mapped.**

## Deliberate divergences

Places where `docs/` does **not** match the spec, on purpose. Each has a decision record.

| § | The spec says | We do | Why |
|--:|---|---|---|
| 8, 43, 51 | Workshop, Arena and factory are described together, with no place topology stated | **One place**, explicitly, with `studio_lobby/` a stub | The Arena must be visible from the Workshop and notify mid-factory. [0001](../decisions/0001-one-place-not-two.md) |
| 66, 13 | "Do not simulate thousands of objects"; four object states | The same four states, plus a **hard `MaxConcurrentPull` cap** and mandatory pooling from the first prototype | An intention is not a budget. [0005](../decisions/0005-four-state-scrap-budget.md) |
| 19 | The refresh is described as a system, with no build priority | The refresh is **P0, in the MVP** | Building on static spawns bakes in assumptions the refresh then breaks. [0006](../decisions/0006-the-factory-refreshes.md) |
| 46 | Robot AI is described; movement is not specified | Movement is **`AlignPosition` on an unanchored root**, not driven wheels | Predictable balance and real knockback. [0009](../decisions/0009-robots-are-animated-not-driven.md) |
| 85 | A 13-phase build order starting from magnet physics | **14 groups, re-ordered MVP-first around §84's gate** | The spec's order builds outward without ever asking whether the game is fun yet. [build/README](README.md#the-order-and-why) |
| — | Not mentioned | A **quality-tier system** and a mobile floor | Roblox is majority mobile and this game spends its budget on physics *and* PBR. [0012](../decisions/0012-mobile-first-quality-tiers.md) |

## What the spec does not specify, and we have not invented

Recorded rather than filled in, so nobody mistakes a gap for a decision:

- **Per-part combat stats.** All 96 parts have a slot, a rarity and an effect *phrase*. None has damage,
  attack speed, knockback, range, HP, armour, weight class or a Magnet Power requirement.
- **Animation profiles.** The `AnimationProfile` column in the parts catalog is marked **(derived)** —
  it is job 001's proposal, not a spec value.
- **Service Hub placement.** "Approximately every two zones" is all the spec says; the specific
  after-2/4/6/8/10/12 placement is marked *(derived)*.
- **Relic Part slots, rarities and effects.** Seven are named; nothing else about them exists.
- **Coin costs for upgrades.** The Magnet Power *requirement* curve is given (§62); the *price* curve is
  not.
- **Arena reward rates.** "Rewards accumulate over time" with no numbers.
- **Guardian speeds, detection ranges and catch radii.**
- **Scrap values** per object type.

