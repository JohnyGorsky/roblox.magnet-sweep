# Monetisation stance

The policy, not the price list. The binding rule is
[decision 0011](../decisions/0011-robux-never-buys-arena-power.md).

## The one test

> **Could two identical players, one paying, produce a different Arena outcome?**

If yes, it is not sellable.

## What we sell

**Permanent passes**

- **2x Coins** — accelerates self-progression, which feeds back into the factory, not the Arena.
- **Super Magnet Radius** (+25-30 %) — sweeping convenience.
- **Auto Recycler** — normal scrap only. Never rare parts.
- **VIP** — mostly cosmetic.

**Developer products**

- **Magnet Overcharge** — a temporary PvE magnet boost. **Must be code-gated so it cannot touch a
  deployed robot.**
- **Server events** — Scrap Rain, Gold Rush, Heavy Delivery. One player pays, the whole server benefits.
  This is the shape we want: spending that is visible and *popular* rather than resented.

**Cosmetics** — the revenue backbone, so they have to be genuinely good:
magnet skins (Candy, Electric, Lava, Galaxy, Gold, Glitch, Rainbow) · robot paints (construction yellow,
candy, military, chrome, neon, galaxy) · robot VFX (electricity, fire, bubbles, pixels, stars) · victory
animations · arena entrances · trails · sound packs.

## What we never sell

Robot damage, HP or armour. Instant or guaranteed legendary parts. Arena wins, control time or
leaderboard position. Any permanent Arena advantage. Bypassing Arena Heat or the field-repair rate limit.

## Why the limits are mechanical, not just stated

Arena Heat and the repair rate cap ([decision 0010](../decisions/0010-one-robot-per-player-persistent-arena.md))
exist partly so that *no amount of scrap or money* holds the Core indefinitely. The anti-pay-to-win
promise is enforced by the simulation, not by a pricing choice we could quietly revisit.

## Implementation

Purchases follow the standard `MarketplaceService` + `ProcessReceipt` grant-exactly-once pattern — see
the shared `roblox-monetization` skill. Every grant is idempotent and server-side.

> ⚠️ **Audit live listings before launch.** A game pass that is `IsForSale` but unwired is buyable from
> the website store page and delivers nothing. Sweep every listing against what the code actually
> grants.
