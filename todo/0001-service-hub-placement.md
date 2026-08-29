# TODO 0001 — Confirm Service Hub placement

**Status:** resolved
**Opened:** 2026-08-29 (job 001)

Section 18 says "approximately every two zones" and never enumerates them. `docs/` currently marks
after-zone-2/4/6/8/10/12 as **(derived)**.

Confirm or change it before the second hub is built, because the hub interval sets how long an
extraction run can be, and therefore how far a rare part can spawn from safety.

---

**RESOLVED 2026-08-29.** Six hubs, after zones **2, 4, 6, 8, 10 and 12** — evenly spaced, so a rare
part is never more than two zones from safety and the longest extraction stays inside the 20-45 second
target. See [systems/factory](../docs/systems/factory/README.md#service-hubs-section-18).
