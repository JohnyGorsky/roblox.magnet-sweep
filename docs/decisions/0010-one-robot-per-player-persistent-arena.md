# 0010 — One robot per player, in a persistent arena

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Section 43 sets the shape: the Arena is persistent, not matchmade; 4-6 active robots; each player may
release one. Sections 45, 49 and 50 add control rewards, live field repair, and an escalating Arena Heat
that guarantees turnover.

## Decision

- **One robot per player.** Not a squad, not a roster.
- The Arena is **persistent for the life of the server**. Robots enter and leave; the Arena does not
  reset.
- Target **4-6 concurrent robots**; the exact number is a measured performance budget, not a design
  constant. See [systems/performance](../systems/performance/README.md).
- If the Arena is full, the player enters a short queue.
- **Arena Heat** escalates damage taken and reduces repair efficiency the longer a robot holds the Core
  (0-90 s normal, then +10 %, +20 %, +35 %). This is the turnover guarantee.
- Field repair via the Repair Chute is rate-limited: cooldown, reduced efficiency, and a cap per time
  window.

## Consequences

- Your robot is *your* robot. It has a name, it is on the leaderboard, and it is the thing you have been
  building toward. A roster would dilute that completely.
- Watching the Arena is a spectator activity in the hub, which is why [0001](0001-one-place-not-two.md)
  keeps them adjacent.
- Heat plus repair limits mean a rich player cannot buy permanent control. This is the mechanical half
  of [0011](0011-robux-never-buys-arena-power.md).
- A robot's HP persists across its deployment. It degrades, and repairing it competes with upgrading
  yourself. That competition is the game's central economic decision.

## Open

Whether 4-6 survives measurement on a mid-range phone, with parts, actuators and combat VFX. **Measure
before committing to 6.**
