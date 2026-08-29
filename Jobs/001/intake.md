# Job #001: Repo scaffold, design pack and project skill

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-29 00:14:46
**Status**: Requirements Gathering (intake)

## Requirements / goal

Order the roblox.magnet-sweep repo to workspace convention; redistribute the 87-section MAGNET SWEEP spec into a living docs/ pack; write the magnet-sweep-project and magnet-sweep-style skills; capture the single-place topology, the glossy-metal PBR direction, the mobile-first budget and the robot rig architecture as decision records.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** - given the requirement and the repo, NOT my theory
      (GROUND-RULES 8). It found 7 wrong engine claims and ~20 documentation defects; all verified
      independently and fixed. See `final-summary.md`.
- [~] **Symptom reproduced in PLAY** - **not applicable.** This is a docs-only job: no place, no code,
      nothing to run. Marked rather than ticked, because a ticked box here would be a lie
      (GROUND-RULES 7).
- [x] Implementation plan created & agreed - four blocking decisions asked via the wizard first
- [x] Implementation completed
- [~] **Proof it works better** - **not applicable** for the same reason. What replaces it: five
      re-runnable checks in `tools/` that are capable of failing, and did (the catalog diff, the link
      and anchor checkers, and the two generators). Results in `final-summary.md`.
- [x] Final summary + changelog written

## Outcome

Repo ordered to workspace convention, the 87-section spec redistributed into a living `docs/` pack, two
skills written, 13 decisions recorded, a 572-item manifest generated (MVP: 349).

Two follow-ups were opened outside this project rather than actioned inside it:
`roblox.workspace/findings/0002` (a shared skill states two engine facts backwards) and
`roblox.workspace/todo/0001` (the workspace CLAUDE.md project list is stale).
