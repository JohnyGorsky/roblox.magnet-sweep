# 0022 — The Workshop is hub 0

**Status:** Accepted · 2026-09-06 · Job 023
**Amends:** [0008 — a part is secured at the hub, never in your hands](0008-secured-at-the-hub-not-in-hand.md)

## Context

[0008](0008-secured-at-the-hub-not-in-hand.md) fixes ownership to one moment:

> **Ownership transfers at the `SECURED` moment and nowhere else.**

and `SECURED` happens at a **Service Hub**. `docs/systems/factory` places six of them, **after zones
2, 4, 6, 8, 10 and 12** — *"so a rare part is never more than two zones from safety"*.

Count from zone 1 and the rule has a hole in it. **Zone 1 has no hub in front of it and none behind
it.** A part stolen in floor 1 has nowhere to become owned. Under 0008 as written it stays unsecured
indefinitely, is lost on disconnect, and never reaches the profile — so job 022's Robot Bay, which
ships and works, would still have no legitimate supply. `part.grant`, a dev command, would remain the
only way a part enters an inventory.

⚠️ **To be precise about what is new here:** the *index* is not. `Zones.hubTierFor`
(`Config/Zones.luau:76-84`) already returns **0 for the Workshop**, described there as *"always the
fallback"*. What has never existed is the **`SECURED` semantics** — that hub 0 is a place where
ownership actually transfers, rather than merely the answer to "which hub is behind me".

This gap was not noticed when 0008 was written because no zone existed. It surfaced in job 023's
intake only after the owner decided what makes you safe:

> **"Back through the entry doors."** *The room is the danger zone; cross into the Workshop and the
> boss stops.*

That answer is about the **guardian**. It says nothing about ownership — and the two being different
is precisely how a player ends up "safe" and then loses the part anyway to a disconnect, which reads
as the game stealing from them.

## Decision

**The Workshop is a Service Hub.** Hub 0.

Crossing the floor-1 entry doors back into the Workshop is a `SECURED` moment: the chase ends **and**
the part transfers to the profile, in the same instant, for the same reason.

- 0008's table is unchanged in every other row. Carried is still not owned; disconnect while carrying
  still loses the part; the autosave exclusion still stands.
- **The six hubs after zones 2–12 are unchanged.** The Workshop is a seventh, at position zero, which
  is the one place the original count skipped because nobody walks *back* to it — until now, when
  everybody does.
- **The `SECURED` event is not a quiet inventory increment.** 0008 already requires sound, VFX and a
  banner, *"the emotional payoff of the entire loop"*. Zone 1 is where every player meets that moment
  for the first time, so it is where it matters most.
- ⚠️ **The Workshop already has the fixtures.** `Hub.Common.Fixtures` holds the shared stations; the
  Robot Part Secure station is the one §18 names, and hub 0 needs it. It does **not** need MagRail —
  MagRail's whole purpose is to get you back *to* the Workshop.

## Consequences

- **The tier-1 loop closes with no new hub geometry** — the room's exit is a hub because the room's
  exit is home. That is why floor 1 can ship the whole loop in one job.
- 🔴 **Zone 1's run home is short, and every later zone's is not.** In floor 1, "escaped the boss"
  and "banked the part" are the same doorway. From zone 3 onward they are two zones apart, and the
  gap between them *is* §22's escape gameplay. **Zone 1 therefore teaches an easier version of the
  rule than the game actually plays.** That is acceptable — it is the tutorial — but the UI must
  teach `SECURED` as *"reaching a hub"*, never *"getting out of the room"*, or zone 3 will feel like
  the rules changed.
- The distance-to-safety promise gets *better*, not worse: with hub 0 counted, hubs sit at 0, 2, 4, 6,
  8, 10 and 12, and a part is never more than two zones from safety **including from zone 1**.
- **`ZoneManager.zoneContaining` returning `nil` is now meaningful.** 0021 makes the corridor
  physically continuous; `nil` means the Workshop, which means safe and secured. The boss's give-up
  test and the secure test read the same fact.

  🔴 **Which makes zone registration load-bearing, and it currently cannot happen.**
  `ZoneManager.register` has exactly one call site — `ZoneBuilder.luau:334`, inside `ZoneBuilder.build`
  — and that never runs, because `Bootstrap.BUILD_GENERATED_WORLD = false`. **An editor-placed floor 1
  therefore registers with nothing, and `zoneContaining` returns `nil` for every point inside it.**
  Under this decision that means the entire room reads as the Workshop: the guardian gives up
  instantly and the part secures the moment it is detached.

  The failure is silent and it looks like *"the chase is broken"*, not like *"the registry is empty"*.
  So a hand-placed zone needs an explicit registration path — who calls `register`, and where its
  `min`/`max`/`entry`/`exit`/`spawnVolumes` come from now that [0021](0021-you-walk-in-nobody-teleports.md)
  declares `Zone1Spec.ORIGIN` dead. **That is a prerequisite of this decision, not a detail of it.**

## The trap

**Two different things stop at that doorway, and only one of them is the guardian.** The temptation
is to implement the chase first — the boss loses you at the threshold, it feels finished, it demos
well — and to leave `SECURED` for later because the part is visibly in your hands and looks like
yours.

It is not yours. Under 0008, an unsecured part is not written to the profile, so a player who runs
home, feels safe, admires the part and then disconnects loses it. They will report that as a dupe of
their loss, and they will be right.

So: **the chase ending and the transfer are one event, implemented together, or neither.** If job 023
ships the boss without the secure, it has shipped a way to lose parts.

## The check

Steal a part in floor 1, cross the entry doors, then **disconnect immediately**. Rejoin. The part must
be in the profile.

Then steal a part and disconnect **while still inside the room**. It must be gone. If both hold, hub 0
is real; if the second one keeps the part, the autosave exclusion 0008 warns about has broken and the
disconnect dupe is open.
