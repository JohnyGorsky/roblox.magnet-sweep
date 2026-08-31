# Job #014: Boot and the loading screen: ReplicatedFirst handoff, real stage progress, the title card and the first-time prompt

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31 00:15:45
**Status**: ✅ **Complete** — see [final-summary.md](final-summary.md) and [changelog.md](changelog.md).
Boot screen with real stage completion, the title card, and the MOVE NEAR SCRAP hint. The
joined-mid-Refresh failure path is deliberately not built: the Factory Refresh does not exist yet.

## Requirements / goal

Build group 06's remaining half - the boot experience. The manifest opens with the reason this goes NOW rather than at the end: a loading screen retrofitted over a running game fights every system it wraps, and there is finally a running game to wrap. Scope: the ReplicatedFirst handoff that removes Roblox's default loading screen immediately; a loading screen showing the player, the magnet, flying scrap and the corridor; a progress bar driven by REAL stage completion and never by a timer; an object-per-tick loading sound with a CLANG on complete; the title card; and the MOVE NEAR SCRAP first-time prompt that job 013 deliberately deferred so the has-this-player-played-before state is built once rather than twice. Also the P1 failure paths: profile load failed, streaming slow, joined mid-Refresh. HARD CONSTRAINTS. Progress must be driven by real stage completion - PITFALLS #2 and #54 are both about checks and measurements that report success while measuring nothing, and a fake progress bar is exactly that shape. PITFALLS #54 is specifically about this moment: the quality tier was measured DURING the loading screen while nothing was drawn, so any device measurement must be gated on game.Loaded, the character existing and a settle delay. ReplicatedFirst scripts run before almost everything, so nothing here may assume Remotes, Config or the Workshop exist yet - every wait needs a timeout and a real failure path, the way Bootstrap does it. No placeholder art or sound: an empty slot announces itself. The loading screen is the FIRST thing a new player ever sees, so verify it in Play at the player's camera with screenshots read as images, and verify the mobile layout against the measured canvas rather than a desktop viewport.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [x] **Verified in PLAY** — stage timings from the log, and the screen photographed with temporary instrumentation, at the player's camera, before any fix (GROUND-RULES 7)
- [x] Implementation plan created & agreed
- [x] Implementation completed
- [x] **Proof it works** captured — boot screen at rest and mid-progress, plus the first-run hint - before/after from the same camera, in Play
- [x] Final summary + changelog written
