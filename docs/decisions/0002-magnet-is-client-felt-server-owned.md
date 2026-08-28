# 0002 — The magnet is felt on the client and owned by the server

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Section 66 of the spec says the visual magnet physics may be client-assisted. Section 67 says the server
stays authoritative for ownership, rare-part capture, Coins, zone unlock, robot inventory and Arena
rewards.

These are easy to state and easy to blur. A pull that is simulated on the server feels laggy on a phone
and costs the server dearly. A pull that is *decided* on the client is a free-money exploit.

## Decision

Split by question, not by system:

| Question | Answered by |
|---|---|
| Where is this bolt right now, and what does the arc look like? | **client** |
| Did it shake, spark, spin and make a noise? | **client** |
| Does this player now have one more bolt? | **server** |
| Is this player's Magnet Power enough to detach the Giant Spoon? | **server** |
| Who owns the detached spoon, and is it secured? | **server** |
| How many Coins did that recycle produce? | **server** |

The client renders and reports **intent** (I am sweeping, here, with this magnet). The server validates
against the player's real stats, its own scrap spawn record, and a rate limit, and then grants.

## Consequences

- Sweeping feels instant on any connection, because motion is local.
- A client claiming impossible collections is checked against what the server actually spawned. Scrap
  that the server did not place cannot be collected.
- Collection is granted in **batches** on a short tick, not one remote per bolt. A magnet rush pulling
  200 objects must not send 200 remotes.
- The server never simulates pulled scrap physics. It tracks a set of ids and a radius.

## Failure mode this exists to prevent

"The client said it collected 4,000 scrap" is the single most likely exploit in a magnet game. The rule
that catches it: **the server can always name the specific object it spawned.** Anything else is
rejected silently and rate-limited.
