# FINDING 0005: The Workshop at full detail is ~2400 parts against an 1800 budget - owner accepted

**Project:** `roblox.magnet-sweep`
**Status:** open
**Severity:** high
**Created:** 2026-09-06 00:45:37

**Symptom:** Perf.BUDGET.MAX_PARTS_IN_VIEW is 1800 for a zone chunk plus the Workshop, and Zone1Spec already claims 900 of it. Measured densities from the approved demo patterns put the Workshop at roughly: arena excluding ground 250, floor at 32-stud tiles out to the 12-gon 672, perimeter wall 48 panels of pattern A at 17 parts each 816, twelve bases at 54 static parts each 648, seven common buildings 28, name plates 14 - about 2430, or 135 percent of the whole budget with the zone excluded entirely. The two heavy items are the wall (48 x 17) and the per-base output bay (26 primitives of rails, posts and hazard stripes; hopper, belt and furnace are single meshes). Cheap fixes exist and were costed: a Meshy wall module takes the wall from 816 to 96, and a meshed output bay takes the bases from 648 to 360, landing the room near 1035. THE OWNER WAS SHOWN THESE NUMBERS AND CHOSE TO BUILD AT FULL DETAIL - forget about budget man - so this is an accepted risk, not an oversight. Logged because MAX_PARTS_IN_VIEW is a MEASURED-kind budget on a dev machine and has never been checked on the reference device; the honest next step is a real-device reading, not a number argument.
**Where:** Config/Perf.luau MAX_PARTS_IN_VIEW + Workspace.Hub (job 020)
**Repro / notes:** _TODO_
**Fix idea:** _TODO_
