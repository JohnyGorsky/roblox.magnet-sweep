# Job #006: Quality tiers: reference device, performance budgets, tier detector and controller

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-29 20:58:02
**Status**: Requirements Gathering (intake)

## Requirements / goal

Choose the reference device and the frame-time / memory / draw-call budgets that every later measurement is compared against, then build the client quality-tier detector (measured frame time, never TouchEnabled) and the tier controller that switches post-processing, PBR variants, decorative light range, particle rate and MaxConcurrentPull. Low tier drops the MaterialVariant entirely per decision 0016.

## Checklist

- [x] Requirements reviewed (this intake)
- [~] **Independent reviewer agent run** — a reviewer is running against job 005's kit; this job's
      own review is **outstanding** and should happen before job 008 builds on the tier system.
- [x] **Reproduced in PLAY** — Bootstrap clean, QualityController measures real frame time, tier
      switch verified to strip and restore MaterialVariants.
- [x] Implementation plan created & agreed
- [x] Implementation completed
- [x] **Proof it works** — see `final-summary.md`
- [x] Final summary + changelog written

## Outcome

Reference device and budgets chosen and recorded honestly by kind (TARGET / MEASURED / DEVICE), the
lighting recipe completed, and a working client quality-tier detector + controller.
