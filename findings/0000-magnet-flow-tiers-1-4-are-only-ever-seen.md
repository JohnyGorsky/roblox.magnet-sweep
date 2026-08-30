# FINDING 0000: Magnet Flow tiers 1-4 are only ever seen on the way DOWN

**Project:** `roblox.magnet-sweep`
**Status:** open
**Severity:** med
**Created:** 2026-08-30 11:13:23

**Symptom:** Collection is batched on a 0.25s tick (Magnet.GRANT.TICK), so a single flush grants tens of objects at once. Flow advances by object count, and a Rush needs MAX_TIER 5 x PICKUPS_PER_TIER 8 = 40 pickups. Measured in Play: a dense field goes 0 -> RUSH in under one second, and a deliberately sparse 26-object field jumps straight from tier 0 to tier 3 in one batch. The x1-x5 ladder is therefore never experienced while building - only while decaying, where it steps 3-2-1-0 correctly. The build item says 'Magnet Flow x1-x5 with decay'; the decay half is real and the build half is not legible. This is TUNING and a feel judgement, so it needs a human playing it, not a number picked here. Options: raise PICKUPS_PER_TIER well above a typical batch; advance flow once per FLUSH rather than per object; or accept that Flow is a fast fuse and make tiers 1-4 purely a VFX ramp. Config is marked UNTUNED and Economy.TUNED is false, so nothing is being hidden - but do not call group 04 done on this item without deciding.
**Where:** _TODO: file / system_
**Repro / notes:** _TODO_
**Fix idea:** _TODO_

---

## RESOLVED — 2026-08-30

Measured first, then tuned. On a dense field: **20.6 objects/sec, median batch 18, largest batch 51.**
Against the old `PICKUPS_PER_TIER = 8` that made the median batch 2.25 tiers and the largest batch
enough to go from nothing to MAGNET RUSH in a single flush.

`PICKUPS_PER_TIER` is now **60** — above the largest observed batch, so no single flush can skip a
tier. A Rush is 300 pickups, about 15 seconds of sustained sweeping.

`DECAY_PER_SECOND` is now **derived** from a new `DECAY_TIERS_PER_SECOND` rather than being an
independent constant. Raising the tier size without that would have stretched a full decay from 27
seconds to 200 — a combo you cannot lose, which is exactly what
[decision 0018](../docs/decisions/0018-full-stops-the-pull-not-the-grant.md) says a combo must never
be. One tier still decays in 5.3s, unchanged.

**Verified in Play:** the ladder now reads `0 -> 1 -> 2` while building, where it previously jumped
straight to 3.

⚠️ **One consequence to watch when the real zones land.** 15 seconds of *sustained* sweeping means
the world has to keep feeding the player — a single 250-object dev field is exhausted at about tier
2, so a Rush now depends on field density and refresh rate rather than on one lucky pile. That is
arguably correct (a Rush should be earned), but it is a load the Factory Refresh in group 12 has to
carry, and it was not a constraint before.

