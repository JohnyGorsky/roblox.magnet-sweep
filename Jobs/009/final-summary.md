# Job #009 — final summary

**Project**: `roblox.magnet-sweep`
**Status**: complete for the confirmed defects; three items carried forward
**Origin**: an independent review of job 006, given the requirement and never my theory.

Job 006's tier *machinery* was sound — measurement, hysteresis, idempotence, the server-side
pull cap, the `.local.luau` choice. Its **wiring to the world** was not. Of the four things a
tier is supposed to change, three did nothing.

## Before and after, measured in Play

| | before | after |
|---|---|---|
| Low vs Medium | differed **only** in the pull cap | no colour grading, no PBR on scrap, lights clamped to 10 |
| Medium vs High | differed **only** in SunRays + cap | + SunRays **+ depth of field** |
| Scrap carrying PBR on Low | 0 → **37** as soon as the server spawned more | **0 of 60**, and 0 of 106 |
| Light cull | clamped **0** lights, at every tier, forever | Low 10 / Medium 15 vs a kit whose largest light is 18 |
| Post-processing chain | never audited | `post=complete`, and `Log.error` when it is not |
| First tier decision | taken in the first 2–6s of the session | after `game.Loaded`, the character, and a 3s settle |

## The three confirmed defects

**The decorative-light cull could never fire.** Every light range in the kit is 4, 5, 12, 14, 16
or a default of 18 — and the lowest threshold was **40**. `keep` was true for every light in the
game at every tier, on every device, forever, and the function logged `lights toggled=0` on a
healthy run and a broken one alike. Two files chose numbers that never met.

It also read a `Hero` attribute **nothing in the repository ever writes**, while `KitBuilder`
stamps every light it creates with `Decorative` — an attribute nothing ever reads. The two halves
of the contract did not meet either.

Fixed by **clamping Range instead of switching lights off**, which fixes a second problem in the
same function: writing `Enabled` made the tier controller the sole owner of a property the
Salvage Breach needs (`Prop_Beacon`, range 16, "rotates during a Salvage Breach"). A tier
re-evaluation would have relit every beacon in the world with no breach running — and it would
have been blamed on the Breach system. Clamping never touches `Enabled`. Cost scales with range,
so it still saves, and the room stays lit — which matters, because the big lights are the ones
that define a space.

`Bootstrap` now reads the kit's largest authored range and each tier's threshold and states both:
`light clamp: kit max 18 studs vs Low 10 / Medium 15 / High 10000`. It logs an **error** if any
tier's threshold is at or above the largest light, so this cannot silently go inert again.

**The Low tier's PBR drop was undone by the server on every scrap spawn.** `MaterialVariant` is a
replicated, server-owned property; `setUsePBR` flips a module-level local and modules are per-VM,
so a Low-tier client's decision never reaches the server, whose `usePBR` is permanently true.
`MaterialKit.refresh` is one-shot with no hook for anything arriving later.

Reproduced exactly: a client stripped 37 variants to 0, the server spawned 60 more pieces, and
the client was back to **37**. Scrap is the highest-count object class in the game and its parts
are pooled and re-spawned continuously, so the Low tier's saving decayed toward zero over a
session and was worst exactly when the field was densest — while decision 0016 claimed "no
texture fetches, no PBR sampling".

Fixed with `MaterialKit.enforce`, run once a second against the Scrap folder. A poll rather than
a signal, deliberately: the parts are **pooled**, so they are re-stamped while already parented
and `DescendantAdded` never fires for them.

**`depthOfField` was `true` on High and the code wrote `false` regardless.** Configured, and then
enforced to the opposite value — worse than not enforced at all.

## Also fixed

- **The documented frame-time thresholds were dead.** `apply(Quality.default())` set `current`
  before the first classification, so `classify` always took the hysteresis path: `26.0` and
  `12.0` were constants no client ever used and the real gates were 29 and 9. A device holding
  27.5 ms — worse than the reference device's own budget — classified Medium and stayed there.
  The bootstrap apply no longer records a tier.
- **The tier was decided in the least representative seconds of the session** — textures
  decompressing, world streaming, often no character, so the camera draws almost nothing and
  frames look cheap. A phone could classify **High** and hold a 160-object pull cap through the
  whole first minute. Now gated on `game.Loaded`, `CharacterAdded`, and `SETTLE_SECONDS`.
- **`quality.set` was documented in the file and registered nowhere.** The only working path was
  a `_G` global, which lives in the LocalScript's own Lua context and is invisible to every other
  script and to `execute_luau`. Now a real dev command, and a pinned tier **stays** pinned —
  `_G.setQuality` used to be reverted by the next re-check 60s later, exactly long enough to take
  one screenshot, change nothing, and take a second identical one.
- **`Perf.sample` had no caller** — the whole MEASURED half of the register was unreachable.
- **`Quality.BUDGET.CHOSEN = true`** sat three lines under a "NOT YET CHOSEN" banner and Bootstrap
  printed it as `budgets=%s`. No state of the world could make it print false. Removed.
- Weak-keyed tables for the remembered light ranges and particle rates, so a destroyed instance
  is not pinned in memory forever.
- The log line now counts what actually changed (`lights clamped=`, `post=`) instead of
  restating the tier name — a line that reads identically whether the tier did everything or
  nothing is how this survived a review in the first place.

## Where the review was wrong, and why it matters

It reported `ColorCorrectionEffect` as **missing from `Lighting`** — which would have meant the
Low/Medium boundary had no visible difference at all, since `postColorCorrection` is the only
post field separating them. I checked the live place: **all six effects are present**, colour
correction included.

The reviewer inferred its absence from `docs/systems/places/README.md`, which listed five effects
and omitted it — and had the same paragraph duplicated verbatim. That line has been corrected,
dated, de-duplicated, and annotated: an inventory of what lives inside the `.rbxl` is
unfalsifiable from the repository, so it must say how and when it was checked, or not be written
down. A stale doc cost a reviewer a CRITICAL finding.

## Carried forward

- **`meshSurfaceAppearance` and `trails`** are still read by no code at all. They belong to the
  VFX job, which needs asset ids from a human first. Left in the config rather than removed
  because they are that job's contract — but they are a promise nothing keeps today.
- **`findings/0001`** — the client performance budget has no client-side reporter. `perf.sample`
  runs in a DevTools handler, which is the **server**, so its memory figures describe the wrong
  process. In Studio Play Solo they are the same process, which hides the mistake exactly where
  a developer would check it. The command now says which process it measured and refuses to
  compare server memory against a phone budget.
- `Perf.BUDGET` has one `FRAME_MS` for a game with three tiers, and the draw-call budget named
  in build group 03 still does not exist.
- `docs/systems/performance/README.md` still says the reference device and budgets are "not yet
  chosen"; job 006 wrote them into `Config/Perf` and never updated the doc it cites as its source.

## Regression

Jobs 007 and 008 still hold with all of this in the path: **244 asked, 244 granted, 0.0% turned
away**, unanchored 0, destroyed 0, parts 400/400.
