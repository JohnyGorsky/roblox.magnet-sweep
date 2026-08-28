# 0011 — Robux never buys Arena power

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Sections 70-73 are unusually specific about monetisation, and section 73 names what must never be sold:
+50 % robot damage, instant legendary parts, instant Arena champion, permanent Arena HP advantage.

The Arena has a public leaderboard and persistent control. It is exactly the system where pay-to-win is
most tempting and most corrosive.

## Decision

**Robux buys convenience in the factory, cosmetics, and spectacle. It never buys Arena outcome.**

| Sellable | Not sellable |
|---|---|
| 2x Coins (permanent) | Robot damage, HP or armor |
| Super Magnet Radius (+25-30 %) | Instant or guaranteed legendary parts |
| Auto Recycler (normal scrap only) | Arena wins, control time or leaderboard position |
| VIP (mostly cosmetic) | Permanent Arena advantage of any kind |
| Magnet Overcharge (temporary, **PvE only**) | Anything that buffs a deployed robot |
| Server events: Scrap Rain, Gold Rush, Heavy Delivery | Bypassing Arena Heat or the repair rate limit |
| Cosmetics: magnet skins, robot paints and VFX, victory animations, arena entrances, trails, sound packs | |

Server events are the deliberate design here: they cost one player Robux and benefit everyone on the
server, which makes spending visible and *popular* rather than resented.

## Consequences

- Magnet Overcharge must be explicitly gated so it cannot affect a deployed robot. That is a code
  constraint, not a wording one.
- 2x Coins accelerates *self* progression, which loops back into the factory, not the Arena.
- Cosmetics carry the revenue, which means the cosmetic set has to be genuinely good — it is not a
  side dish.

## The check

For any proposed purchase, ask: **could two identical players, one paying, produce a different Arena
outcome?** If yes, it is not sellable.
