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

## The three most easily broken by accident

Each of these is violated by writing the *convenient* code, not by making a decision:

- **[0004](0004-parts-are-content-rig-is-the-engine.md)** — the first time someone special-cases one
  part in a script, the engine is gone.
- **[0005](0005-four-state-scrap-budget.md)** — one forgotten `Anchored = true` on return to the pool
  and the cap silently stops meaning anything.
- **[0003](0003-forward-is-the-only-direction.md)** — one hardcoded path into another zone and
  streaming turns it into a nil-index crash.
