# Job #003: Config skeleton, remotes, rate limiter, logging and dev tools

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-29 12:41:36
**Status**: Requirements Gathering (intake)

## Requirements / goal

Build group 01's remaining items: six shared config modules, a single remote-definitions module, a server-side rate limiter used by every remote, a logging helper with a level switch, and the dev/test tools (forced Factory Shift, jump-to-zone, grant Magnet Power, spawn a named part). Everything lands on the FLAT sync layout verified in job 002.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** — given the requirement and the repo, NOT my reasoning
- [x] **Reproduced in PLAY** / exercised in a live Studio session
- [x] Implementation plan created & agreed
- [x] Implementation completed
- [x] **Proof it works** — see `final-summary.md`
- [x] Final summary + changelog written

## Outcome

Repo-wide foundation: 6 config modules, 20 remotes, structural rate limiting, logging, dev
tools and a client console. Two failed Play runs surfaced a 7-file syntax error and an economy curve
that made the game uncompletable.
