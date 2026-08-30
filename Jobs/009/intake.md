# Job #009: Quality tiers must actually change the world

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-30 11:16:20
**Status**: Complete

## Requirements / goal

An independent review of job 006 found that the tier MACHINERY is sound - measurement, hysteresis, idempotence, the server-side pull cap, the .local.luau choice - but the WIRING TO THE WORLD is not. Of the four things a tier is supposed to change, three do nothing. VERIFIED IN PLAY BY ME: (1) the decorative-light cull can never fire - the largest light range in the shipped kit is 18 and the lowest threshold is 40, and separately KitBuilder stamps every light with a Decorative attribute while QualityController reads a Hero attribute that nothing in the repo ever writes; (2) the Low tier's PBR drop is undone by the server on every scrap spawn - a client-side strip went 37 to 0 to 37 as soon as the server spawned more scrap, because MaterialVariant is a replicated property the server owns and MaterialKit.refresh is one-shot with no DescendantAdded hook. Also reported and worth fixing: three Quality.TIERS fields are read by no code at all (depthOfField, meshSurfaceAppearance, trails) and depthOfField is true on High while applyPostChain hardcodes Enabled=false; the documented frame-time thresholds LOW_IF_MS_ABOVE and HIGH_IF_MS_BELOW are dead because apply(Quality.default()) sets current before the first classify, so hysteresis always applies and the real gates are 29ms and 9ms not 26 and 12; frame time is measured in the first 2-6 seconds of the session, before the character exists and while the kit textures are still decompressing, which is the least representative window in the whole session; the post-processing chain has no startup audit even though MaterialKit.audit is fatal for the equivalent material failure. NOTE the reviewer also claimed ColorCorrectionEffect is missing from Lighting - that is WRONG, I checked the live place and all six effects are present; it inferred absence from a stale line in docs/systems/places/README.md, which should be corrected.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [x] **Symptom reproduced in PLAY**, at the player's camera, before any fix (GROUND-RULES 7)
- [x] Implementation plan created & agreed
- [x] Implementation completed
- [x] **Proof it works better** captured - before/after from the same camera, in Play
- [x] Final summary + changelog written
