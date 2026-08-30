# 03 -- Lighting, atmosphere & quality tiers

This is the group that makes the game look like the concept art. It is early because every subsequent
visual decision is judged against it.

## Items

- [ ] **P0** `LightingStyle = Realistic` (the successor to `Lighting.Technology = Future`; neither is script-writable, so this is set in Studio) + the ambient/brightness/exposure baseline
- [ ] **P0** `Atmosphere` configured -- density, haze, colour, decay, glare
- [ ] **P0** `Sky` -- the thing chrome actually reflects
- [ ] **P0** `EnvironmentSpecularScale` / `EnvironmentDiffuseScale` tuned against a chrome test object
- [ ] **P0** Post chain: BloomEffect, ColorCorrectionEffect, SunRaysEffect x3
- [ ] **P0** **Choose the reference device and the memory / draw-call / frame-time budgets.** Every later measurement is meaningless without them
- [ ] **P0** Quality tier detector -- measured frame time, NOT `TouchEnabled`
- [ ] **P0** Tier controller (client): post chain on/off, PBR variant on/off (Low drops it entirely -- Reflectance is inert on Metal, decision 0016), light range cull, particle rate, `MaxConcurrentPull` x5
- [ ] **P0** Measure LAYOUT for the three tiers in the Device Emulator -- it gives real TouchEnabled, ViewportSize and safe area, but it renders on the dev GPU and CANNOT measure device frame time
- [ ] **P0** Record which performance questions need REAL HARDWARE (Config/Perf.REGISTER) so none is quietly closed from a Studio reading
- [ ] **P1** `DepthOfFieldEffect` for the Robot Bay install cinematic only
- [ ] **P1** Shadow-casting light budget audit tool
- [ ] **P2** A lighting-preset module if zones need to differ (Power Plant vs Space Foundry)

---

**19 items** — P0 16 · P1 2 · P2 1

> Counted by `tools/gen-build-manifest.py`. The last `xN` on a line is that line's count.
