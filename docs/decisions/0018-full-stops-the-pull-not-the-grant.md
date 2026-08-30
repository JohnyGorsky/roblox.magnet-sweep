# 0018 — SCRAP FULL stops the pull; Flow does not build during a Rush

**Status:** Accepted · 2026-08-30 · Jobs 007, 008
**Depends on:** [0005 — four-state scrap budget](0005-four-state-scrap-budget.md) ·
[0002 — the magnet is client-felt, server-owned](0002-magnet-is-client-felt-server-owned.md)

Three rules that look like implementation detail, were each arrived at by measuring a bug, and each of
which a future change will be tempted to "fix" back.

---

## 1. A full magnet stops PULLING, it does not refuse at the door

**The obvious implementation is to keep pulling and reject the collection.** It is wrong twice.

*As feel:* a magnet that still drags objects across the room and then refuses them at the last moment
reads as broken. One that visibly stops lifting — while everything in range still rattles — reads as
*I am full*, and sends the player to a recycler without a word of UI. The signal has to be the thing
that stops.

*As cost:* objects already in flight kept arriving at a magnet with no room, were refused, restored by
the client, and arrived again. Measured before this rule existed: **329 of 355 claims refused, a 93%
rejection rate, and a remote fired four times a second** for as long as the player stood in the field.

**So:** when a player is full, the server refuses to enter `PULL` at all, *and* recovers everything
already in flight, *and* the client stops sending claims. Measured after: `asked=0` over four seconds
in the same field.

## 2. Flow does not build during a MAGNET RUSH

The Rush is what the combo pays out. If Flow keeps charging while it runs, it is full again the instant
the Rush ends and re-triggers on the very next pickup — one dense field becomes a permanent Rush, and
the game's signature moment becomes its resting state.

Measured before this rule: flow ran to **101** during an 8-second Rush and came out the far side still
at tier 5.

Flow is also **capped at the trigger threshold**. Uncapped, a dense field banks a combo that then takes
67 seconds to decay at 1.5/s. A combo you cannot lose is not a combo.

## 3. Flow counts PICKUPS, not scrap value

One heavy pipe is worth five screws of income and **one** screw of combo. Weighting Flow by value would
make the combo a second income stat; counting objects makes it a rhythm of collection, which is what
§16 describes and what the rising pitch communicates.

---

## Consequences

- The `SCRAP FULL` state is a **gameplay signal carried by the magnet's own behaviour**, not by a HUD
  element. When the HUD arrives (group 06) it should *reinforce* that, never replace it — if the HUD is
  the only way to know you are full, the magnet has stopped teaching.
- `MagnetState.collect` is the only place Flow advances, and it must stay that way. A second call site
  that adds Flow — a bonus, an event, a daily modifier — reintroduces rule 2 as a bug.
- Anything that makes objects enter `PULL` while full (a future magnet upgrade, an event) must go
  through `MagnetState.isFull`, not around it.

## What would make this wrong

Rule 1 assumes recycling is **nearby and cheap**. If a later zone puts the recycler far away, "the
magnet stops working and you walk back" becomes a punishment rather than a beat — and the answer is
probably a bigger Capacity or a closer Service Hub, not refusing at the grant instead.

Rule 2 assumes a Rush is **frequent enough to feel earned rather than rare**. If tuning makes Rushes
scarce, freezing Flow during one costs the player a combo they were mid-way through building, and it
may be better to freeze *decay* rather than *gain*.

Both are tuning questions, and both are open: `Economy.TUNED` is `false` and
[findings/0000](../../findings/0000-magnet-flow-tiers-1-4-are-only-ever-seen.md) records that Flow's
tiers 1–4 are currently only ever seen on the way **down**, because a single batched flush jumps
straight past them.
