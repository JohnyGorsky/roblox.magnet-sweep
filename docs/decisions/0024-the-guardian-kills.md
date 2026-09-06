# 0024 — The guardian kills you

**Status:** Accepted · 2026-09-06 · Job 023
**Supersedes:** the non-lethal catch outcomes of
[0014 — the owning guardian chases](0014-the-owning-guardian-chases.md), and the *"no combat"* framing
in [`docs/systems/guardians`](../systems/guardians/README.md)

## Context

The owner's mechanic, verbatim:

> *"boss only atacks you if you pick up item, and picking up item will require like 5 seconds, once
> you got part you have to run outside area, **if boss catches you he kills you**"*

Everything shipped says a guardian cannot do that:

| Source | What it says |
|---|---|
| [0014](0014-the-owning-guardian-chases.md) | caught **inside** its territory → the part **resets** to its spawn; caught **outside** → you **ragdoll**, the part drops neutral |
| `docs/systems/guardians/README.md` | *"a **denial threat**, not a health-bar enemy … There is no combat."* |
| same, and load-bearing | *"The player loses **no** Coins, **no** magnet progression, **no** secured parts. **Ever**."* |
| `docs/build/08-cargo-and-escape.md` | both 0014 outcomes are **P0**; *"Death: respawn at last hub"* is **P1** |

Two independent reviewers flagged this collision without being told to look for it, and the intake had
noticed it, asked *"and then what happens to the part?"*, and then never answered it.

Put to the owner with 0014's wording in front of them, they chose the kill.

## Decision

**A guardian that catches a thief kills them.**

- **The catch test** is a server-side **radius, ~6 studs, with a ~0.5 s dwell** — not a `Touched`
  event. Robust under lag and on mobile; it never kills on a graze, and it cannot be walked through by
  a modified client.
- **Death costs the carried item and nothing else.** Coins, magnet progression, swept scrap and every
  secured part are untouched. The *"Ever"* promise above **survives in the part that matters** — what
  you own is still never taken. What is lost is what was never yours
  ([0008](0008-secured-at-the-hub-not-in-hand.md): a part in hand is not owned).
- **Respawn at the Workshop**, which is also hub 0 ([0022](0022-the-workshop-is-hub-zero.md)).
- **0014's trigger survives untouched:** the guardian is **inert until you steal**, and a player
  carrying nothing is never threatened. Sweeping stays safe from the *boss*. (The *room* is a separate
  threat with separate rules — see [0020](0020-the-lockdown-replaces-the-factory-cycle.md).)

What is superseded is narrow and specific: 0014's **part-resets / ragdoll-and-drop** outcomes, and the
*"no combat"* framing. Its territory model, its inert-until-theft rule and its chase behaviour all
stand.

## Consequences

- 🔴 **Death handling does not exist anywhere in the codebase.** There is **no `Humanoid.Died`
  connection in `studio_game/` at all**. Respawn, what it costs, and telling the player why they died
  are now **P0 for job 023**, having been P1 in a build doc for a later group. This is a real,
  unbudgeted addition to the job.
- **It aligns the guardian with the Lockdown.** After 0020 the room can kill you; it would be
  incoherent for the thing actively chasing you to be the *less* dangerous of the two. One rule —
  *get caught, lose the run* — instead of two.
- **The 20–45 second escape now has teeth**, which is what §22 always assumed and 0014 never quite
  delivered: a chase you can lose only by having a part snatched back is a slower kind of stakes.
- ⚠️ **`docs/systems/guardians/README.md` and `docs/build/08-cargo-and-escape.md` are now wrong** and
  must be updated in this job. An Accepted decision contradicting a system doc, with the doc left
  standing, is precisely the drift `INDEX.md` exists to prevent — and 0020 has *already* left
  `docs/systems/factory` and `Config/Zones` un-updated. Do not make it twice.

## The trap

**A player must never be killed without having understood it was coming.** This is 0020's trap
restated, and it is sharper here because the guardian is a *character* — players extend intent to it
and will read an unexplained kill as the game cheating rather than as a rule.

So the wake must be unmistakable: the eye goes from cyan to `#E03A2F`, the beacon spins, the siren
starts, and the chase begins **visibly at the moment of the steal**, not silently three seconds later.
The 5-second channel exists to make that legible — it is the window where the alarm starts and you
cannot yet run.

⚠️ And the guardian must be **slower than a free player and faster than a carrying one**, which
depends on cargo weight data that **no part in the catalog carries** (`Config/Parts.luau:34-35`
defines `weight` and `powerRequired`; `PartsCatalog.luau:25-39` sets neither, and `validate()` does not
check). Without it there is no slowed player to be faster than, and the chase is either unloseable or
unwinnable.

## The check

Steal the item and stand still: you die. Steal it and run straight for the doors: you live. **Both
outcomes must be reachable by a competent player** — if either is impossible, the speed numbers are
wrong and the chase is theatre.

Then: sweep the room for two minutes carrying nothing, with the guardian awake from a previous theft
by another player. It must never touch you.
