# TODO 0001 — Confirm Service Hub placement

**Status:** open
**Opened:** 2026-08-29 (job 001)

Section 18 says "approximately every two zones" and never enumerates them. `docs/` currently marks
after-zone-2/4/6/8/10/12 as **(derived)**.

Confirm or change it before the second hub is built, because the hub interval sets how long an
extraction run can be, and therefore how far a rare part can spawn from safety.
