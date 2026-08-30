# FINDING 0001: The client performance budget has no client-side reporter

**Project:** `roblox.magnet-sweep`
**Status:** open
**Severity:** med
**Created:** 2026-08-30 11:24:25

**Symptom:** Config/Perf.BUDGET names CLIENT_MEMORY_MB 700 and TEXTURE_MEMORY_MB 180 for the reference PHONE, and Perf.sample can read exactly those numbers - but the only caller is the perf.sample dev command, and DevTools handlers run on the SERVER. So the figures it returns are the server process, which on a real deployment has nothing to do with the phone the budget describes. In Studio Play Solo the two are the same process, which makes the mistake invisible in exactly the place a developer would check it. perf.sample now states which process it measured and deliberately does NOT compare server memory against the client budget. What is still missing: a client-side reporter that samples Stats on the CLIENT and reports against CLIENT_MEMORY_MB and TEXTURE_MEMORY_MB. Until that exists, Perf.REGISTER's kit-texture-memory entry - whose note literally reads 'Stats:GetMemoryUsageMbForTag(GraphicsTexture), kit loaded vs not' - cannot be answered by anyone. Natural home is the DevConsole LocalScript, which is already client-side, or a client half of quality.set. Related: Perf.BUDGET has ONE FRAME_MS 33.3 for a game with three quality tiers, so 'does the reference device hold 33.3ms' has three answers and the budget records one; and the draw-call budget named in build group 03 and job-order still does not exist - MAX_PARTS_IN_VIEW is labelled a proxy for it.
**Where:** _TODO: file / system_
**Repro / notes:** _TODO_
**Fix idea:** _TODO_
