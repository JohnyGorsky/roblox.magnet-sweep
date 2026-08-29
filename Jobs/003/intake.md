# Job #003: Config skeleton, remotes, rate limiter, logging and dev tools

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-29 12:41:36
**Status**: Requirements Gathering (intake)

## Requirements / goal

Build group 01's remaining items: six shared config modules, a single remote-definitions module, a server-side rate limiter used by every remote, a logging helper with a level switch, and the dev/test tools (forced Factory Shift, jump-to-zone, grant Magnet Power, spawn a named part). Everything lands on the FLAT sync layout verified in job 002.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** — given the requirement and the repo, NOT my reasoning.
      Found 20 findings; the two most severe were verified independently and were real.
- [x] **Reproduced in PLAY** — three Play cycles. The first crashed on a syntax error, the second
      exposed a broken economy curve, the third passed. Studio returned to Edit each time.
- [x] Implementation plan created & agreed
- [x] Implementation completed
- [x] **Proof it works** — server boots with 0 fatal / 4 [UNTUNED] warnings, 20 remotes created,
      dev command invoked end-to-end from the client, rate limiter refused 5 of 30 rapid calls,
      DevConsole confirmed as exactly 1 LocalScript instance (no double-run).
- [x] Final summary + changelog written

## Outcome

12 files. The foundation is live and verified in Play, not merely written.
