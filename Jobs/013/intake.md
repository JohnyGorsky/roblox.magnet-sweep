# Job #013: Make the Workshop stations work: Magnet Lab terminal, Recycler, Repair, Robot Bay shell and the first-time prompt

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31 00:01:17
**Status**: ✅ **Complete** — see [final-summary.md](final-summary.md) and [changelog.md](changelog.md).
Prompts on all 7 stations; Magnet Lab reuses the job-011 panel; the Recycler transaction is wired and
verified in Play. The MOVE NEAR SCRAP first-time prompt is deliberately deferred to the boot job.

## Requirements / goal

Build group 05's BEHAVIOUR half. Job 012 built the room and every station is currently scenery - walking up to the Recycler does not recycle. Scope: give each of the seven stations a proximity interaction and wire the three that have real transactions. The Magnet Lab terminal only has to OPEN the upgrade panel job 011 already built, tested and attacked - it must not reimplement it. The Recycler is the real work: RequestRecycle is an unbound remote, and Economy.previewChoice already exists to show scrap-to-Coins and scrap-to-robot-HP side by side with real numbers and NEITHER pre-selected, because decision 0007's economy pinch is that choice. The Repair Station binds RequestRepair but has no robot to repair until group 09, so it must announce that honestly rather than pretend. Robot Bay and Part Archive get their shells and a prompt that says what they will be. Factory Entrance gets the MOVE NEAR SCRAP first-time prompt. HARD CONSTRAINTS. The server owns every currency change - decision 0007 - and the client sends intent only; the RequestUpgrade handler from job 011 is the pattern to follow, including that the price shown is the price charged and no cost ever crosses the wire from the client. Every station's interaction is found BY NAME or by the StationId attribute the builder already stamps, never by a computed offset, because the room is regenerated from a spec and positions move. ProximityPrompt is the mechanism and screen_capture CANNOT render prompt bubbles - PITFALLS #20 - so verify by pressing the key or by reading PlayerGui, never by screenshotting and concluding it is missing. No placeholder behaviour: a station that cannot work yet must say so, not fake it. Verify in PLAY at the player's camera, and run the repo analyzer before any playtest.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [x] **Verified in PLAY** — prompts triggered by key press, not by screenshot (PITFALLS #20), at the player's camera, before any fix (GROUND-RULES 7)
- [x] Implementation plan created & agreed
- [x] Implementation completed
- [x] **Proof it works** captured — +1,920 coins banked end to end, screenshots of both screens - before/after from the same camera, in Play
- [x] Final summary + changelog written
