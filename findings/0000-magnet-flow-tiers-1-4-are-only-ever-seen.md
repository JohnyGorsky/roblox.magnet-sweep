# FINDING 0000: Magnet Flow tiers 1-4 are only ever seen on the way DOWN

**Project:** `roblox.magnet-sweep`
**Status:** open
**Severity:** med
**Created:** 2026-08-30 11:13:23

**Symptom:** Collection is batched on a 0.25s tick (Magnet.GRANT.TICK), so a single flush grants tens of objects at once. Flow advances by object count, and a Rush needs MAX_TIER 5 x PICKUPS_PER_TIER 8 = 40 pickups. Measured in Play: a dense field goes 0 -> RUSH in under one second, and a deliberately sparse 26-object field jumps straight from tier 0 to tier 3 in one batch. The x1-x5 ladder is therefore never experienced while building - only while decaying, where it steps 3-2-1-0 correctly. The build item says 'Magnet Flow x1-x5 with decay'; the decay half is real and the build half is not legible. This is TUNING and a feel judgement, so it needs a human playing it, not a number picked here. Options: raise PICKUPS_PER_TIER well above a typical batch; advance flow once per FLUSH rather than per object; or accept that Flow is a fast fuse and make tiers 1-4 purely a VFX ramp. Config is marked UNTUNED and Economy.TUNED is false, so nothing is being hidden - but do not call group 04 done on this item without deciding.
**Where:** _TODO: file / system_
**Repro / notes:** _TODO_
**Fix idea:** _TODO_
