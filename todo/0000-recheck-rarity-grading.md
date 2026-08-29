# TODO 0000 — Re-check the rarity grading of the part catalog

**Status:** open
**Opened:** 2026-08-29 (job 001)

The 96-part catalog transcribed from the spec grades **35 parts as `Rare`** and only **13 as
`Uncommon`**. `Rare` is therefore the single most common rarity in the game.

That may be intentional — "rare" could simply mean "a rare *part*" as opposed to scrap — but if the
rarity ramp is meant to drive drop rates and the UI colour ramp, the distribution needs re-grading
before drop weights are set.

| Rarity | Count |
|---|--:|
| Common | 20 |
| Uncommon | 13 |
| Rare | 35 |
| Epic | 14 |
| Legendary | 13 |
| Mythic | 1 |

Numbers are computed in [parts-catalog.md](../docs/content/parts-catalog.md#rarity-distribution).
