# 0008 — A part is secured at the hub, never in your hands

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Sections 18, 23, 68 and 69 all touch the same rule from different angles: a rare part reaching a Service
Hub is `SECURED` and cannot be lost; a guardian knocking you down drops it with about 5 seconds to
recover; unsafely carried parts must not save on disconnect, because that is an extraction exploit; and
death respawns you at the last Service Hub having lost only unsecured cargo.

## Decision

**Ownership transfers at the `SECURED` moment and nowhere else.**

| Moment | State |
|---|---|
| Part detached | carried, owned-with-protection, **not saved** |
| Knocked down | dropped, ~5 s recovery window, then neutral |
| Disconnect while carrying | part is **lost**; nothing is written to the profile |
| Reached a Service Hub | `SECURED` — written to the profile, permanent |

Normal scrap is different and deliberately milder: on death it auto-recycles at reduced value rather
than vanishing (section 69).

## Consequences

- The run home is the *game*, not an epilogue. Section 22's 20-45 second extraction has stakes.
- Disconnect-to-keep is impossible, which closes the obvious dupe.
- The `SECURED` moment needs to be a genuine event — sound, VFX, a banner. It is the emotional payoff of
  the entire loop and must not be a quiet inventory increment.
- Progression is never punished: Coins, magnet upgrades and previously secured parts are always safe.
  You lose the thing you were carrying, never the things you own.

## The trap

**Autosave must not run while a part is in hand**, or a well-timed disconnect writes it. The profile
write happens on `SECURED`, and the carried slot is explicitly excluded from every other save path.
