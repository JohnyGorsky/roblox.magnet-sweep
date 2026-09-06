# FINDING 0006: Players.MaxPlayers reads 60 in the live session, not the decided 12

**Project:** `roblox.magnet-sweep`
**Status:** open
**Severity:** med
**Created:** 2026-09-06 00:45:44

**Symptom:** docs/decisions/INDEX.md lists MaxPlayers = 12 as an accepted decision and docs/systems/places/README.md warns: reopen Studio so its session picks up MaxPlayers = 12, and never publish from a session showing 60. Read back over MCP right now: Players.MaxPlayers = 60. Job 020 builds exactly twelve player bases on the strength of the twelve-player cap, so a 60-player server would put 48 players in a room with no base. Either the setting was never applied or the open session predates it. Needs checking in Game Settings and the session reopened before any publish.
**Where:** live Studio session / game settings
**Repro / notes:** _TODO_
**Fix idea:** _TODO_
