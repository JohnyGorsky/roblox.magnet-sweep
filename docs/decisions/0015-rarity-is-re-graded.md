# 0015 — Rarity is re-graded; the spec's grade is kept alongside

**Status:** Accepted · 2026-08-29 · Job 001

## Context

The spec grades all 96 parts across sections 26-37. Counted honestly, the distribution is:

| Rarity | Spec |
|---|--:|
| Common | 20 |
| Uncommon | **13** |
| Rare | **35** |
| Epic | 14 |
| Legendary | 13 |
| Mythic | 1 |

**`Rare` is the most common rarity in the game**, and `Uncommon` is the second *rarest*. That is not a
ramp; it is a label collision. The word is doing two jobs at once — "this is a rare *part*, as opposed
to scrap" and "this is scarce" — and the second meaning is the one the drop weights, the colour ramp and
the Part Archive all need.

Nothing depends on these values yet. No code, no drop table, no UI. This is the cheapest moment this
will ever be fixable.

## Decision

**Re-grade, banded per tier, preserving the spec's ordering within each tier.**

The algorithm, implemented in `tools/gen-content-catalogs.py` so it is reproducible and not hand-typed:

1. Rank a tier's 8 parts by the **spec's own** rarity, stable, so the spec's row order breaks ties.
2. Relabel that ranking against the tier's target band.

The bands shift upward with depth:

| Tiers | Band (8 parts, ascending) |
|---|---|
| 1-3 | 3 Common · 3 Uncommon · 1 Rare · **1 Legendary** |
| 4-6 | 2 Common · 3 Uncommon · 2 Rare · **1 Legendary** |
| 7-9 | 1 Common · 2 Uncommon · 3 Rare · 1 Epic · **1 Legendary** |
| 10-11 | 1 Uncommon · 3 Rare · 3 Epic · **1 Legendary** |
| 12 | 1 Uncommon · 3 Rare · 3 Epic · **1 Mythic** |

Result:

| Rarity | Ours | Spec |
|---|--:|--:|
| Common | 18 | 20 |
| Uncommon | **27** | 13 |
| Rare | **27** | 35 |
| Epic | 12 | 14 |
| Legendary | 11 | 13 |
| Mythic | 1 | 1 |

**The spec's own grade is kept**, in a `Spec rarity` column in
[the catalog](../content/parts-catalog.md) where `=` means unchanged. `tools/verify-catalog-vs-spec.py`
checks *that* column against the spec, so the re-grade can never quietly erase the source data.

## Consequences

- **The colour ramp means something.** Common grey → Uncommon green → Rare cyan → Epic violet →
  Legendary gold → Mythic pink now describes a real curve, in the HUD, the Archive, the Builder and the
  world outline.
- **Drop weights become possible.** They were not, against 35 Rares.
- **Rarity now encodes depth as well as scarcity.** Tiers 1-3 have no Epics at all; tiers 10-12 have no
  Commons. A part's colour tells you roughly how far someone went for it, which is exactly what a player
  wants to read across the Arena.
- **Every tier keeps exactly one top-grade part** — its trophy. Eleven Legendaries, one per tier, plus
  tier 12's Void Magnet as the game's only Mythic.
- The spec's Legendary is always its tier's top grade, because it always ranks highest going in. Nothing
  the spec called out as special was demoted below its own tier-mates.
- **The Giant Spoon stays Uncommon**, which §28 requires — it is meant to be the game's recognisable
  part, and everyone should get one.

## The one thing this loses

Tier 12's **Phase Blade** drops from Legendary to Epic, because tier 12's top slot is taken by the Void
Magnet's Mythic. That is the only part the spec called Legendary that this decision demotes.

## The check

`tools/verify-catalog-vs-spec.py` must keep passing. It diffs part name, tier, slot, **spec rarity** and
effect against the source document and exits non-zero on any drift. If the `Spec rarity` column is ever
dropped from the catalog, that check fails loudly rather than silently passing.
