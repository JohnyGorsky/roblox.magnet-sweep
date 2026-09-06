# Decisions — index

Accepted design and architecture decisions. **Never silently overturn one.** If one must change, write a
new record that says so and link it from here.

| # | Decision | Why it matters |
|---|---|---|
| [0001](0001-one-place-not-two.md) | One place, not two | The Arena must be visible from the Workshop and notify you mid-factory |
| [0002](0002-magnet-is-client-felt-server-owned.md) | The magnet is felt on the client, owned by the server | Pull feel is local; collection is a server fact |
| [0003](0003-forward-is-the-only-direction.md) | Forward is the only direction | One continuous corridor, no zone-select menu. **[0021](0021-you-walk-in-nobody-teleports.md) is what makes it true in code** — until job 023 the shipped `sendTo` teleported |
| [0004](0004-parts-are-content-rig-is-the-engine.md) | Parts are content; the rig is the engine | 96+ parts, ~20 animations, no code per part |
| [0005](0005-four-state-scrap-budget.md) | Scrap has four states, one costs physics | Thousands visible, a capped number simulated |
| [0006](0006-the-factory-refreshes.md) | The factory refreshes | Nothing is memorisable; the hunt has a rhythm. **⚠️ Its Factory Cycle clause is superseded by [0020](0020-the-lockdown-replaces-the-factory-cycle.md)** and its **pool-of-8 by [0025](0025-one-plinth-one-item.md)** — only the scrap refresh and the Shift still stand |
| [0007](0007-server-owns-capture-and-reward.md) | The server owns capture and reward | The Arena has a leaderboard; nothing may be forged |
| [0008](0008-secured-at-the-hub-not-in-hand.md) | Secured at the hub, never in hand | The run home is the game; closes the disconnect dupe. **⚠️ Amended by [0022](0022-the-workshop-is-hub-zero.md)** — the Workshop counts as hub 0 |
| [0009](0009-robots-are-animated-not-driven.md) | Robots are animated on a controlled root | Predictable movement, real knockback, server-owned |
| [0010](0010-one-robot-per-player-persistent-arena.md) | One robot per player, persistent arena | Your robot has a name; Heat guarantees turnover |
| [0011](0011-robux-never-buys-arena-power.md) | Robux never buys Arena power | Convenience, cosmetics and spectacle only |
| [0012](0012-mobile-first-quality-tiers.md) | Mobile sets the budget; gloss is a tier | The floor is never optional; measure in the emulator |
| [0013](0013-overclock-not-rebirth.md) | Overclock, not rebirth | The robot survives the reset |
| [0014](0014-the-owning-guardian-chases.md) | The owning guardian chases you | Its territory is the finish line. **⚠️ Its catch outcomes are superseded by [0024](0024-the-guardian-kills.md)** — inert-until-theft still stands |
| [0015](0015-rarity-is-re-graded.md) | Rarity is re-graded | The spec made `Rare` the most common grade in the game |
| [0016](0016-low-tier-drops-the-variant.md) | The Low tier drops the MaterialVariant | Reflectance is inert on `Metal`, so it is not a fallback. Amends 0012 |
| [0017](0017-the-kit-is-generated-from-a-spec.md) | The kit is generated from a spec, on a 4-stud grid | `Workspace` does not sync, so a hand-built kit could never be in git |
| [0018](0018-full-stops-the-pull-not-the-grant.md) | SCRAP FULL stops the pull; Flow does not build during a Rush | Refusing at the grant instead spun the claim loop at 93% rejection, and a charging Rush never ends |
| [0019](0019-hero-geometry-is-editor-placed-and-exported.md) | Hero rooms are placed in the editor, then exported to git; the kit and the zones stay generated. **⚠️ Its split-by-kind is superseded by [0023](0023-the-room-is-placed-the-contents-are-spawned.md)** — all places are placed; only contents are spawned | Job 019's ring failed on *proportion*, which a viewport judges and a spec file cannot — but an unexported room lives only in the unversioned `.rbxl` |
| [0020](0020-the-lockdown-replaces-the-factory-cycle.md) | The ~4 min Factory Cycle becomes a **lethal Lockdown**: alarm, doors closing as a wave toward the Workshop, anyone still inside dies, rooms reset | Supersedes 0006's cycle clause. Chosen with the cost stated: sweeping is no longer unconditionally relaxing |
| [0021](0021-you-walk-in-nobody-teleports.md) | **You walk into the factory; nothing teleports you.** `ZoneManager.sendTo` stops relocating the character; floor 1 is built physically onto the Workshop wall aperture at (1790, 12, 31) | Makes [0003](0003-forward-is-the-only-direction.md) literally true. ⚠️ The teleport is currently the only thing enforcing the Magnet Power gate — it must move to the door |
| [0022](0022-the-workshop-is-hub-zero.md) | **The Workshop is hub 0.** Crossing floor 1's entry doors ends the chase **and** secures the part, in one event | Amends [0008](0008-secured-at-the-hub-not-in-hand.md). Hubs started after zone 2, so a tier-1 part had nowhere to become owned and the Robot Bay had no legitimate supply |
| [0023](0023-the-room-is-placed-the-contents-are-spawned.md) | **The room is placed; the contents are spawned.** Every place is built by hand in the editor and never regenerated; scrap, the item and the guardian spawn into editor-placed markers | Supersedes [0019](0019-hero-geometry-is-editor-placed-and-exported.md)'s split-by-kind. The line is what stands still vs what comes back — not hero room vs zone. ⚠️ The exporter it depends on **still does not exist** |
| [0024](0024-the-guardian-kills.md) | **The guardian kills you.** A ~6-stud radius with a ~0.5 s dwell; death costs the carried item only | Supersedes [0014](0014-the-owning-guardian-chases.md)'s non-lethal catch outcomes and the *"there is no combat"* framing. ⚠️ There is **no `Humanoid.Died` connection anywhere in the codebase** |
| [0025](0025-one-plinth-one-item.md) | **One plinth, one item, one rarity table** — 60/30/8/2, re-rolled on a 30-60 s cooldown | Supersedes [0006](0006-the-factory-refreshes.md)'s pool-of-8. ⚠️ A **second rarity table already ships** in `Config/Zones.luau` and must be deleted, or it silently wins later |

## Answered by the user, 2026-08-29

Sixteen open questions were put through the wizard and settled. The load-bearing ones became
[0014](0014-the-owning-guardian-chases.md) and [0015](0015-rarity-is-re-graded.md); the rest were
written into their system docs:

| Answer | Where it lives |
|---|---|
| Pull force strains, then refuses | [magnet](../systems/magnet/README.md#pull-force-strain-then-refuse) |
| Radius grows both ranges, REACT ~40 % wider | [magnet](../systems/magnet/README.md#radius-both-ranges-react-wider-than-pull) |
| Guardians are inert until a part is stolen | [0014](0014-the-owning-guardian-chases.md) |
| Uncollected scrap auto-recycles on disconnect | [save-data](../systems/save-data/README.md) |
| Every Arm part takes one socket; no two-handed parts | [robot-rig](../systems/robot-rig/README.md) |
| One locomotion clip, four mobility sub-rigs | [robot-rig](../systems/robot-rig/README.md) |
| A deployed robot gets a ~2 min grace period when its owner leaves | [arena](../systems/arena/README.md#when-the-owner-leaves) |
| The Part Archive records **secured**, not discovered | [save-data](../systems/save-data/README.md#the-part-archive-stores-secured-not-discovered) |
| Six Service Hubs, after zones 2/4/6/8/10/12 | [factory](../systems/factory/README.md#service-hubs-section-18) |
| `MaxPlayers` = **10** (was 12; two facets became shop frontage, 2026-09-06) | [places](../systems/places/README.md) |
| Robot paints apply **per part** | [cosmetics](../content/cosmetics.md) |
| Magnet Core Level = starting Power + a gate discount | [0013](0013-overclock-not-rebirth.md#how-magnet-core-level-bends-the-curve) |

## The three most easily broken by accident

Each of these is violated by writing the *convenient* code, not by making a decision:

- **[0004](0004-parts-are-content-rig-is-the-engine.md)** — the first time someone special-cases one
  part in a script, the engine is gone.
- **[0005](0005-four-state-scrap-budget.md)** — one forgotten `Anchored = true` on return to the pool
  and the cap silently stops meaning anything.
- **[0003](0003-forward-is-the-only-direction.md)** — one hardcoded path into another zone and
  streaming turns it into a nil-index crash.
- **[0018](0018-full-stops-the-pull-not-the-grant.md)** — refusing a full magnet at the *grant* is the
  obvious implementation and it is wrong twice: it reads as a broken magnet, and it fires a remote four
  times a second that can never succeed.
