# 0001 — One place, not two

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Every other game in this workspace that has a hub is a **two-place** game. The Last Tide splits Lobby
and Game; ELEVATOR 13 does the same and makes the Lobby the start place. The `roblox.magnet-sweep`
repo was even created with empty `studio_game/` and `studio_lobby/` folders, inheriting that shape.

MAGNET SWEEP does not fit it. Two sections of the spec make the Arena and the factory a single
continuous experience:

- **Section 8** — "The Arena should be physically visible from much of the Workshop. Players should
  constantly hear distant CLANG, BOOM, ZAP from robots fighting."
- **Section 51** — while the player is deep in the factory, their robot sends live notifications:
  *YOUR ROBOT DEFEATED SCRAPPER*, *ROBOT HP: 22%*, *ARENA CONTROL LOST*.

The Arena is also **persistent per server** (section 43) and holds 4-6 robots belonging to the players
currently on that server. It is not matchmade.

## Decision

**MAGNET SWEEP is one place.** The Workshop hub, the Scrap Arena, all twelve factory zones and the
Service Hubs live in a single place, carried by **Instance Streaming** over the long corridor.

`studio_game/` is the single sync root. `studio_lobby/` is kept as an empty stub and syncs nothing.

## Consequences

**Good**

- The Arena is genuinely visible and audible from the Workshop. It is a window, not a screen.
- Arena notifications are ordinary server events. No `MessagingService`, no `MemoryStore`, no
  cross-server robot state to reconcile.
- The player never loads a second place mid-loop. The loop is already long: sweep, extract, escape,
  install, release, return.
- One save profile, one server, one economy tick.

**Costs, accepted**

- The whole world is one streaming budget. The factory must be authored as streamable chunks from the
  first zone, not retrofitted. See [systems/performance](../systems/performance/README.md).
- No cheap "lobby is calm, game is loaded" split. Workshop performance is affected by whatever the
  Arena is doing.
- Player count is one number for both activities.

## What would overturn this

A measured streaming or memory failure — not a preference. Specifically: if the Workshop plus the Arena
plus two loaded zones cannot hold a mid-range phone at 30 fps, the factory is the half that splits out,
**not** the Arena. The Arena must stay with the Workshop, because that adjacency is the reason for this
decision.

`studio_lobby/` exists so that split stays cheap.
