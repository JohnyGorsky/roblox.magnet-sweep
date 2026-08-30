# Decisions — index

Accepted design and architecture decisions. **Never silently overturn one.** If one must change, write a
new record that says so and link it from here.

| # | Decision | Why it matters |
|---|---|---|
| [0001](0001-one-place-not-two.md) | One place, not two | The Arena must be visible from the Workshop and notify you mid-factory |
| [0002](0002-magnet-is-client-felt-server-owned.md) | The magnet is felt on the client, owned by the server | Pull feel is local; collection is a server fact |
| [0003](0003-forward-is-the-only-direction.md) | Forward is the only direction | One continuous corridor, no zone-select menu |
| [0004](0004-parts-are-content-rig-is-the-engine.md) | Parts are content; the rig is the engine | 96+ parts, ~20 animations, no code per part |
| [0005](0005-four-state-scrap-budget.md) | Scrap has four states, one costs physics | Thousands visible, a capped number simulated |
| [0006](0006-the-factory-refreshes.md) | The factory refreshes | Nothing is memorisable; the hunt has a rhythm |
| [0007](0007-server-owns-capture-and-reward.md) | The server owns capture and reward | The Arena has a leaderboard; nothing may be forged |
| [0008](0008-secured-at-the-hub-not-in-hand.md) | Secured at the hub, never in hand | The run home is the game; closes the disconnect dupe |
| [0009](0009-robots-are-animated-not-driven.md) | Robots are animated on a controlled root | Predictable movement, real knockback, server-owned |
| [0010](0010-one-robot-per-player-persistent-arena.md) | One robot per player, persistent arena | Your robot has a name; Heat guarantees turnover |
| [0011](0011-robux-never-buys-arena-power.md) | Robux never buys Arena power | Convenience, cosmetics and spectacle only |
| [0012](0012-mobile-first-quality-tiers.md) | Mobile sets the budget; gloss is a tier | The floor is never optional; measure in the emulator |
| [0013](0013-overclock-not-rebirth.md) | Overclock, not rebirth | The robot survives the reset |
| [0014](0014-the-owning-guardian-chases.md) | The owning guardian chases you | Its territory is the finish line; outside it, the part can only be dropped |
| [0015](0015-rarity-is-re-graded.md) | Rarity is re-graded | The spec made `Rare` the most common grade in the game |
| [0016](0016-low-tier-drops-the-variant.md) | The Low tier drops the MaterialVariant | Reflectance is inert on `Metal`, so it is not a fallback. Amends 0012 |
| [0017](0017-the-kit-is-generated-from-a-spec.md) | The kit is generated from a spec, on a 4-stud grid | `Workspace` does not sync, so a hand-built kit could never be in git |
| [0018](0018-full-stops-the-pull-not-the-grant.md) | SCRAP FULL stops the pull; Flow does not build during a Rush | Refusing at the grant instead spun the claim loop at 93% rejection, and a charging Rush never ends |

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
| `MaxPlayers` = 12 | [places](../systems/places/README.md) |
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
