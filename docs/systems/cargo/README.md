# Rare cargo & extraction

The 45 seconds that the entire game is arranged around.

## Rare cargo is not inventory

Normal scrap enters Capacity as a number. A **Robot Part** does not. It stays a physical object:

- it **floats, drags, swings and follows** the magnet
- it produces electricity
- it is visible to every other player
- **you can carry exactly one**

That visibility is the point. Another player seeing you drag an engine down a corridor is the game
advertising itself.

## Weight

| Class | Speed penalty |
|---|---|
| Small | -5 % |
| Medium | -15 % |
| Heavy | -25 % |
| Extreme | -35 % to -45 % |

**Minimum speed must never become painfully slow.** A -45 % penalty on a player who never invested in
Magnetic Drive should still be a tense run, not a punishment. Drive investment is *rewarded*; its absence
is not *punished*.

## Taking a part (section 21)

```
GIANT SPOON — requires Magnet Power 80
        ↓
player pulls · the spoon shakes · electricity forms
        ↓
GRRRRRRR ... CLANG
        ↓
🚨 SALVAGE BREACH — security activates
```

The detach check is server-side. The wind-up must be long enough to be a moment — the player should have
time to realise what they have started.

## The escape (section 22)

> The return must **not** be "hold W backward for three minutes."

Zones have **RETURN LANES** — a distinct route home, not a retraced path. Hazards along it: moving
conveyors, closing security doors, crushers, electric floors, rotating arms, security lasers, giant
factory magnets, guardian robots.

Target: **20-45 seconds**. This is where Magnetic Drive stops being a comfort stat.

## Getting caught

[Decision 0014](../../decisions/0014-the-owning-guardian-chases.md) — the steal-an-egg rule. What a
catch costs you depends entirely on **which side of the zone boundary** it happens.

| Where | Outcome |
|---|---|
| **Inside the guardian's own zone** | the part **RESETS** to its spawn point. No recovery window. Go and take it again |
| **Anywhere else** | you ragdoll, the part **DROPS** and goes neutral. Any player may take it. The guardian gives up and goes home |

So the escape has two halves:

```
🚨 BREACH ──── sprint ────▶ BOUNDARY ──── walk ────▶ 🏠 SERVICE HUB
   the part can still be           the part can only be
   taken back entirely             dropped, never reset
```

**Getting out of the origin zone is the real objective.** Once you are across, heavy cargo stops being
lethal and you can take your time — which is what makes an Extreme part's −45 % speed penalty survivable
rather than punishing.

Magnetic Drive therefore buys you **the sprint**, not the whole journey. That is a much better shape for
an upgrade than "walk home slightly faster".

The player never loses Coins, magnet progression or previously secured parts.

## SECURED

[Decision 0008](../../decisions/0008-secured-at-the-hub-not-in-hand.md). Reaching a Service Hub is the
**only** moment ownership transfers.

| Moment | State |
|---|---|
| Detached | carried, protected, **not saved** |
| Knocked down | dropped, ~5 s window, then neutral |
| Disconnect while carrying | **lost** — nothing written to the profile |
| Service Hub reached | **SECURED** — written, permanent |

> The `SECURED` moment must be a real event: banner, sound, light, VFX. It is the emotional payoff of
> the entire loop. A quiet inventory increment throws away the whole run.

> ⚠️ **Autosave must not run while a part is in hand**, or a well-timed disconnect writes it.
