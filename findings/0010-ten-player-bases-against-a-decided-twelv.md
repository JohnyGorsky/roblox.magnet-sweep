# FINDING 0010: Ten player bases against a decided twelve-player cap

**Project:** `roblox.magnet-sweep`
**Status:** resolved
**Severity:** high
**Created:** 2026-09-06 13:10:12

**Symptom:** The owner rearranged the Workshop by hand: the seven shared upgrade stations were moved out of the ring and clustered along the perimeter wall either side of the Factory Entrance, which reads far better and cuts the walk between them to almost nothing. To make room, TWO of the twelve facets gave up their player base. Workspace.Hub.Bases now holds TEN bases, and the two empty base folders were removed. StationService.EXPECTED_BASES was updated 12 to 10 so attachPrompts stops erroring on every start; verified in Play as stations 18/18 prompts attached with zero station errors, where 18 = 8 shared plus 10 smelters. THE OPEN PROBLEM: docs/decisions/INDEX.md and docs/systems/places both record MaxPlayers = 12, and the whole one-base-per-facet design came from matching the twelve-player cap. Ten bases cannot house twelve players, so two players would arrive with nowhere to smelt. Three ways out, none of them free: drop the cap to 10, which is a decision record and changes server economics; put two bases somewhere other than a facet, which breaks the one-base-per-facet symmetry that makes the ring readable; or move the shops off the wall again, which undoes a layout the owner just judged better by playing it. Related: findings 0006 says the live session still reports MaxPlayers = 60, so the cap has never actually been applied either way. Do not resolve this by quietly setting EXPECTED_BASES back to 12.
**Where:** Workspace.Hub.Bases + docs/systems/places + docs/decisions/INDEX.md + StationService.EXPECTED_BASES
**Repro / notes:** _TODO_
**Fix idea:** _TODO_


---

## RESOLVED — 2026-09-06: ten is the design

The owner settled it directly: **"Let there be 10."** Ten player bases is the intended shape of the
room, not a casualty of moving the shops. `StationService.EXPECTED_BASES = 10` is correct and should
stay; the two empty base folders are gone.

**What this leaves open, and it is now a DOCS problem rather than a world problem:**
`docs/decisions/INDEX.md` and `docs/systems/places` still record `MaxPlayers = 12`. That number came
from one-base-per-facet, and one-base-per-facet is no longer the rule — two facets are shops. The cap
should come down to **10**, or the docs should say explicitly that two players can be in the server
without a base. Note [finding 0006](0006-players-maxplayers-reads-60-in-the-live-.md): the live
session still reports 60, so the cap has never actually been applied in either direction.

Verified in Play after the change: **stations 18/18 prompts attached, zero station errors, fatal 0**
(8 shared + 10 smelters).
