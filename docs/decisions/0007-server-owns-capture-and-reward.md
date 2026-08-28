# 0007 — The server owns capture, currency and Arena outcome

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Section 67 lists what the server must own: ownership, rare-part capture, Coins, zone unlock, robot
inventory, Arena HP, Arena rewards. This decision records it as a rule with a boundary, because the
client legitimately owns a great deal of this game's *feel* — see
[0002](0002-magnet-is-client-felt-server-owned.md).

Section 24 adds a competitive edge: a detached part can become neutral and another player may take it.
That makes capture adversarial, not just anti-cheat hygiene.

## Decision

The server is the sole authority for:

- **Detachment** — whether this player's Magnet Power clears the part's requirement.
- **Ownership and the protection window** after detachment.
- **Neutrality** — when a dropped part becomes available to others.
- **`SECURED`** — the Service Hub moment, and the only moment inventory changes.
- **Coins, scrap totals, upgrade levels, zone unlocks.**
- **Arena HP, damage, control time and rewards.**

The client requests. The server validates and replies. There is no path where a client statement becomes
a fact.

## Consequences

- Arena outcomes cannot be forged, which matters because the Arena has a public leaderboard.
- Two players contesting a neutral part is resolved server-side with no ambiguity.
- Every grant is idempotent and logged, so a duplicate remote cannot double-pay.
- Dev product purchases go through the standard `ProcessReceipt` grant-exactly-once pattern.

## The check

**Never trust "I completed / I collected / I secured."** For each remote, ask: could a modified client
send this to gain something? If yes, the server is missing a validation, not the client missing
politeness.
