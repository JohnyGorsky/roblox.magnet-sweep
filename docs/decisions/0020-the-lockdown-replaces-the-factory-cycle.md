# 0020 — The Lockdown replaces the Factory Cycle, and it is lethal

**Status:** Accepted · 2026-09-06 · Job 023
**Supersedes:** the Factory Cycle clause of
[0006 — the factory refreshes](0006-the-factory-refreshes.md). 0006's *Scrap refresh* and *Factory
Shift* stand unchanged.

## Context

[0006](0006-the-factory-refreshes.md) shipped three overlapping cycles, and defined the middle one —
the **Factory Cycle**, ~4 minutes — as a **harmless re-roll**:

> *"The warning creates a real decision, but **not** about a part you are already holding … Anything
> already carried is safe from the timer."*
> *"Only unclaimed parts retract. Nothing already carried is taken by the timer."*

Designing floor 1 (job 023), the owner specified a different mechanic in its place:

> *"i think we need global timer, like steal an egg, doors start closing from farthest bay, and each
> player still inside it dies. Rooms starts playing alarm, red colors and sounds, and you have limited
> time to run"*

These are not compatible. A timer that kills you is not a timer that politely re-rolls scenery. The
choice was put to the owner with the cost stated, and they chose the lethal version.

## Decision

**The Factory Cycle becomes the Lockdown.** One server-wide timer, and when it fires:

1. Every factory room enters **alarm** — `#E03A2F` signal red light, siren, `Prop_Beacon` rotating.
2. **Doors begin closing as a wave that travels from the deepest room toward the Workshop**, herding
   players ahead of it. The deepest players get the earliest warning; the closure is visible and can be
   outrun.
3. Players have a **limited, readable countdown** to get out.
4. **Anyone still inside when their door shuts dies.** Everyone, not only players carrying an item.
5. Doors shut, the rooms **reset**: scrap, the item and the boss all return fresh.

The 20-second warning requirement from 0006 survives and gets stricter: it must be **audible and
visible from anywhere in a room, including while running**. `FactoryCycleWarning` already exists in
`Remotes.SPECS` for exactly this and is the endpoint it lands on.

**Kept from 0006, unchanged:** the **Scrap refresh** (30–60 s, silent, continuous) and the **Factory
Shift** (~12 min, server-wide re-weighting). Only the middle cycle changes.

## Consequences

- 🔴 **Sweeping is no longer unconditionally relaxing, and that is a real cost.** Sweeping is ~55 % of
  playtime and must stay relaxing, and the vision calls the sweep layer "the ASMR layer". A lethal
  global timer puts a clock on all of it.
  *(⚠️ Attribution corrected 2026-09-06: the 55 % is `docs/game/core-loop.md`, which labels it
  **"derived — a target to test against, not a spec value"**. An earlier draft of this record cited
  spec §84, which is actually MVP Success Criteria. The number is a target we set, not a requirement
  the spec handed us — which matters, because it is the number this decision trades against.)* **This was chosen deliberately with that trade-off on the
  table** — but it is the thing to watch in the first playtest, and the thing to reverse first if the
  game stops being pleasant to potter about in.
- **It partially contradicts [0014](0014-the-owning-guardian-chases.md)'s promise** that *"a player
  carrying nothing is never threatened"*. That promise still holds for **guardians** — the boss only
  wakes if you steal. It no longer holds for the **room**. Two different threats with two different
  rules, and the UI has to make that legible.
- The factory gains a heartbeat every player in the server shares, which is strong social glue and
  free drama — the "steal an egg" pattern the owner named.
- **Nothing secured is ever at risk** — [0008](0008-secured-at-the-hub-not-in-hand.md) is untouched.
  What you have banked stays banked.
- Rooms get a natural, cheap reset point, which is why job 023 asked the question at all: the room
  contents no longer need per-object lifetime management.
- ⚠️ **Death is now a normal, frequent event.** Respawn, what it costs (job 023: the carried item
  only), and how the player is told why they died all become P0, not polish.
- ⚠️ Deep zones become genuinely dangerous rather than merely long. Zone 1 is nearest the Workshop, so
  the Lockdown will barely bite there — it becomes real at zone 4+.

## The trap

**A player must never die to this without having understood it was coming.** 0006's original trap note
was that a silent refresh eating a part *"reads as a bug, not a rule"*. Killing someone silently is
that failure with the volume turned up: it will read as the game being broken, and it will be the
first thing a review mentions.

So the alarm is not decoration and not a P1: red light, siren, spinning beacons, a readable countdown
and a visible advancing wall of closing doors are all part of shipping this at all.
