# MAGNET SWEEP — documentation index

A **physics collection + extraction + robot-building game**. Pull scrap with a magnet, go deeper into a
twelve-tier factory, rip out a ridiculous Robot Part, escape security with it, bolt it onto your
homemade robot, and release that robot into a persistent Arena. Mobile-first. **One place.**

## Read first

1. **[HANDOFF.md](HANDOFF.md)** — where we left off, what is waiting on you, what to do next.
2. **[PITFALLS.md](PITFALLS.md)** — 47 entries: real incidents from the other games here, plus
   anticipatory traps this design invites. **Not optional.**
3. **[build/README.md](build/README.md)** — what to build next, in items sized one at a time.

## What the game is

- [Vision](game/vision.md) — the pitch, the five layers, and what this is *not*
- [Design pillars](game/pillars.md) — five tests every feature must pass
- [Core loop](game/core-loop.md) — the fifteen steps, three nested loops, the first ten minutes
- [Palette & colour language](game/palette.md) — and why "shader" is the wrong word
- [UI direction](game/ui-direction.md) — the clean-screen policy, the HUD, the feedback contract
- [Monetisation stance](game/monetization-stance.md) — the policy, not the price list
- [Naming](game/naming.md) — the fixed vocabulary. Use these words exactly

## Systems — how each is intended to work

| | |
|---|---|
| [Magnet](systems/magnet/README.md) | **The game's verb.** Four stats, four object states, Flow |
| [Scrap](systems/scrap/README.md) | The volume layer, sound families, pooling |
| [Rare cargo & extraction](systems/cargo/README.md) | The 45 seconds the game is arranged around |
| [The factory](systems/factory/README.md) | One corridor, twelve tiers, gates, hubs, three refresh cycles |
| [Guardians](systems/guardians/README.md) | Denial threats, one per zone. No combat |
| [Robot rig](systems/robot-rig/README.md) | **How a fridge door becomes an arm.** The engine |
| [Robot assembly](systems/robot-assembly/README.md) | Seven slots, the Bay, the Archive |
| [The Arena](systems/arena/README.md) | Persistent, 4–6 robots, Heat, repair |
| [Economy](systems/economy/README.md) | **The pinch:** recycle or repair |
| [Save data](systems/save-data/README.md) | What persists, and what must never be written |
| [UI & HUD](systems/ui/README.md) | Screen inventory, diegetic-first |
| [Audio](systems/audio/README.md) | A feature, not polish |
| [VFX & lighting](systems/vfx-lighting/README.md) | What the gloss actually costs |
| [Performance](systems/performance/README.md) | Four budgets, and what must be measured |
| [Places & sync](systems/places/README.md) | One place, and the ⚠️ **unverified** sync layout |
| [Boot & loading](systems/boot/README.md) | Build early. The no-tutorial onboarding |

## Content

- [The twelve zones](content/zones/README.md) — themes, guardians, gates, part pools, six Service Hubs
- [Robot parts — full catalog](content/parts-catalog.md) — **96 parts**, slots, rarities, effects
- [Dynamic events](content/events.md) — the eight, and why Shifts are not events
- [Cosmetics](content/cosmetics.md) — the revenue backbone
- [Endgame](content/endgame.md) — The Foundry Heart, the Endless Line, Overclock, six goals

## Accepted decisions

**[decisions/INDEX.md](decisions/INDEX.md)** — 15 records. Never silently overturn one.

Sixteen open questions were answered on 2026-08-29; two became records
([0014](decisions/0014-the-owning-guardian-chases.md) the steal-an-egg extraction rule,
[0015](decisions/0015-rarity-is-re-graded.md) the rarity re-grade) and the rest went into their system
docs.

The three most easily broken by accident — each is violated by writing the *convenient* code, not by
making a decision: [0004](decisions/0004-parts-are-content-rig-is-the-engine.md) (parts are content),
[0005](decisions/0005-four-state-scrap-budget.md) (the physics budget),
[0003](decisions/0003-forward-is-the-only-direction.md) (no cross-zone references).

## Build

- **[The job ladder](build/job-order.md)** — **the work order.** 28 job-sized slices to the MVP gate,
  in dependency order, with what each needs from you
- [The manifest](build/README.md) — 14 groups, **581 items**, organised by system. The MVP (groups
  01-12) is **358** of them; groups 13-14 are post-gate. `P0` means *required within its group*,
  **not** *in the MVP*
- [Spec coverage](build/spec-coverage.md) — all **87** sections mapped, plus 6 deliberate divergences
  and an honest list of what the spec never specified
- [Features](features/) — units of work and their status. Empty until code exists

## Roadmap

- [MVP](roadmap/mvp.md) — and **[the gate](roadmap/mvp.md#the-gate)**
- [Launch](roadmap/launch.md)

## The art system

The look — palette, PBR material kit, lighting recipe, VFX vocabulary, UI tokens, quality tiers — lives
in the **[`magnet-sweep-style` skill](../.claude/skills/magnet-sweep-style/SKILL.md)**, because that is
what loads automatically when Claude works here.

## Sources of truth

| Question | Authority |
|---|---|
| What the game **should** be, and why | this repo (`docs/`) |
| What **actually exists** right now | the live Roblox Studio session, via MCP |
| The original specification | `assets/MAGNET SWEEP.md` + `assets/concept_art/` — read-only history |

**Documentation existing does not mean code exists.** Documentation missing does not mean code doesn't.
**`IMPLEMENTED` is not `VERIFIED`.**
