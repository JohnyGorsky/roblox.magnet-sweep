# Implementation Plan — Job #015

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31
**Status**: ✅ Executed. See [final-summary.md](final-summary.md).

## Analysis

### What §7 asks for, and what is actually on screen

[`docs/systems/boot/README.md`](../../docs/systems/boot/README.md) asks for two things, and the
second one is the one that has been quietly dropped:

> **It should already feel interactive.** Show: the player, a glowing magnet, scrap flying, a robot
> in the background, and a factory corridor continuing into the distance.
>
> **Progress is represented by objects flying into the magnet:** `🔩 → ⚙️ → 🪙 → 🧲`

Job 014 built everything *around* that and shipped without it. What is on screen is a title card, a
tagline, a progress bar that is genuinely driven by real stage completion, and **four emoji in a row
that dim and brighten**. [`BootScreen.local.luau`](../../studio_game/ReplicatedFirst/BootScreen.local.luau) (line 537 as of writing; the warn was replaced by this job)
warns `ART MISSING` by name at every startup so those four glyphs cannot read as finished.

### The approach changed mid-plan, and the new one is better

The first version of this plan generated a 2D key-art illustration with Meshy and hung it behind the
existing UI. **No credits were spent** — the owner stopped it before it ran, on the principle that
Roblox objects or the Creator Store should be tried first.

That is the right call here for a reason beyond cost: **a painted backdrop cannot satisfy either
sentence of §7.** It cannot "feel interactive", and it cannot make progress be *objects flying into
a magnet* — it would have sat behind four emoji still doing that job as static glyphs. Built from
Roblox parts inside a `ViewportFrame`, the four objects become real geometry that really does fly
into a real magnet as each stage lands. That is the spec, rather than a picture of the spec.

It also drops both risks the Meshy version carried:

- **Moderation.** An uploaded image is moderated. It commonly renders for the uploading owner in
  Studio while staying blank for everyone else, so "it looked right in my Play session" would not
  have been proof it ships. A part built in code has no such gap.
- **Irreversibility.** A published Roblox asset cannot be unpublished. Parts can be deleted.

**Creator Store was checked, not assumed.** `search_asset` for factory/corridor/industrial
backgrounds (`assetType = Image`, `creator_store`, 10 results) returned untitled user screenshots, a
"Backroom" decal and a Skibidi Toilet door. Nothing in this game's art direction. The store is a
real option for props and audio; it is not a source of bespoke key art. Recorded so nobody re-runs
the search expecting a different answer.

**Meshy is not ruled out — it is deferred to where §3 already puts it:** hero *meshes* (the Giant
Spoon, guardians, robot parts), not this screen.

### What has to be built from primitives, and why that is forced

🔴 **This file runs in `ReplicatedFirst`, ahead of `ReplicatedStorage`.** Its own header says it may
assume nothing — no `Config`, no `Remotes`, no `Ui`, no kit. So the diorama **cannot** `require`
`KitSpec` or clone a model out of `ReplicatedStorage`; it has to build itself from `Instance.new`
primitives, in-file. That is a constraint, not a preference, and it happens to land exactly on the
repo's parts-first architecture (style §3: 70–80 % primitives).

### Engine facts, separated into what is confirmed and what must be measured

**Confirmed from the official `ViewportFrame` reference:** it exposes exactly six properties —
`Ambient`, `CurrentCamera`, `ImageColor3`, `ImageTransparency`, `LightColor`, `LightDirection`.
It therefore carries **its own lighting**, and 3D objects are parented to it as children.

**Not confirmed, and not going to be asserted — each is measured in step 3.**
✅ **ANSWERED, in Play, 2026-08-31.** All three came back *no*, and between them they forced the
three-layer design: **Bloom does not apply** (flat, hard-edged `Neon` in the same frame the world
part bloomed), **`Beam` does not render**, **`ParticleEmitter` does not render** — both `Enabled` and
inside the frustum. Recorded as [PITFALLS #62](../../docs/PITFALLS.md). Perf: an 840 × 1129 viewport
holding 6 parts measured a **−0.0 ms** delta, but the machine was pegged at 66.7 ms/frame either way,
so that is weak evidence, not proof.

| Question | Why it decides the design | How it is measured |
|---|---|---|
| Does `BloomEffect` apply inside a ViewportFrame? | Style §3: *"the glow the player sees is the Bloom pass, not the material."* If Bloom does not reach inside, `Neon` renders bright but **flat**, and the magnet's cyan glow needs a 2D fake behind it | screenshot a Neon part in the viewport against the same part in the world |
| Do `Beam` / `ParticleEmitter` render inside one? | §6's electric arcs are *"always `Beam` with a jagged texture"*. If Beams do not render, the arcs must be thin `Neon` parts instead | put one of each in the scene and look |
| What does it cost on the phone preset? | It is a second render pass, on a mobile-first game, on the one screen every player sees | frame time on the phone preset, viewport on vs off |

Three plausible outcomes, three different designs. Guessing one and building on it is how job 012
produced a black room — it built to a sentence in a doc instead of to the reference beside it.

### The emoji row gets replaced, not kept alongside

If real objects fly into a real magnet, four emoji doing the same job below them is a second
progress indicator for the same progress. §7 is explicit that the screen is only what it lists —
*"That is the whole screen. No tips carousel, no lore."*

So the row goes and the 3D objects take over its role. Two things soften the risk:

- **The bar stays.** It is real, verified, and it is the fallback if the viewport renders as an empty
  rectangle on some device — progress is still legible.
- **Job 014's three fixes in that row do not get thrown away, they get retired.** The tofu coin, the
  vanishing glyph at transparency 0.82 and the fixed-64px row were all *emoji-rendering* problems.
  Geometry has none of them — which is itself an argument for the change.

### Layering without touching what works

`ScreenGui.ZIndexBehavior` defaults to `Sibling`, where equal-`ZIndex` siblings draw in child order.
`backdrop` is created before the title, tagline, bar and status. So parenting the **ViewportFrame**
inside `backdrop` puts it under all of them automatically — **no `ZIndex` edits to any existing
element** — and `backdrop.Active` keeps sinking input exactly as it does now.

Text readability is still bought with a **scrim**, not with luck: a frame in `PALETTE.background`
carrying a vertical `UIGradient`, densest across the text band (`y ∈ [0.18, 0.70]` — title `0.24`,
tagline `0.335`, bar `0.62`, status `0.68`) and clearing toward the top and bottom edges where the
diorama shows. Using `PALETTE.background` matters: the file's contract is that every duplicated
colour in it is checked against `Ui.Theme` by `auditPalette`. A newly invented hex would be the one
colour nothing checks — the mistake `barTrack`'s own comment records.

### Composition, against a canvas that is measured rather than assumed

The file's own measurement is `666 × 374`
on the phone preset — this screen sets `ScreenInsets.None`, so its canvas is the whole viewport.
⚠️ The `666 × 316` and `1825 × 1255` figures in HANDOFF are the **HUD's** canvas under
`CoreUISafeInsets` — a different screen in a different inset mode. They must not be reused here.
Step 1 measures this screen's real canvas on both presets.

A ViewportFrame does not crop like an image — the **camera FOV and distance** frame the scene — so
the composition risk is not clipping but the subject drifting out of frame on a very wide or very
tall viewport. Camera pulls back on aspect, checked on both presets.

## Implementation steps

1. **Measure the real canvas.** In Play, read `BootScreen.AbsoluteSize` on desktop and on the phone
   preset. Replaces every assumed number above.
2. **Build a throwaway probe viewport** — a Neon part, a `Beam`, a `ParticleEmitter`, and the same
   three in the world for comparison. Screenshot both. This answers the three unknowns in the table
   before any real geometry exists.
   ⚠️ Deleted when done. Job 014 left `SyncProbe.luau` on disk and it got swept into a commit.
3. **Decide the glow treatment from what step 2 showed**, and write the answer into the plan rather
   than into my head.
4. **Build the diorama** from primitives, in-file, no `ReplicatedStorage` dependency:
   the magnet (red body, chrome pole tips, cyan north / red south per §2 — *"the poles are the
   game's logo"*), a receding hazard-striped corridor for depth, a blocky homemade robot in the
   background (§9: *never a sleek humanoid robot*), a small figure seen from behind, and the four
   scrap objects staged off-camera.
5. **Wire the objects to the real stages.** One object flies in per completed stage, each arrival
   keeping the existing `tik`; the magnet flashes on the existing `CLANG`. Reuses job 014's stage
   completion — no new timer, and nothing that reports progress it has not measured.
6. **Remove the emoji row**; keep title, tagline, bar and status untouched.
7. **Replace the `ART MISSING` warn** with a check that can still fail: the viewport is warned about
   when it has no children or the camera is unset by the time the screen is done.
8. **`tools/luau-analyze.sh`** before any playtest — it has caught a syntax error in three of the
   last four jobs.
9. **Verify in Play**, both presets, screenshots kept, including the before.
10. Summary, changelog, HANDOFF update, and the P0 marked closed in the roadmap.

## Independent review (GROUND-RULES 8)

Every job gets at least one agent, handed the symptom and the repo but NOT my hypothesis - the whole value
is that it is not anchored to my theory. A second agent is mandatory after one failed fix.

- [x] Agent run, without being told my theory
- **What it said to check first**: the ordering of the new code against the file's own safety nets —
  it went straight to *"150 lines of new unguarded construction now sit ahead of every safety net in
  the file"*, which is not something I had considered at all.
- **What came of it**: **8 findings, 7 of them real and all 7 fixed.** Three were rated HIGH and two
  of those were defects I had introduced and verified around:
  1. **The unguarded prologue.** `RemoveDefaultLoadingScreen` has already run and the opaque,
     input-sinking backdrop is already parented, and my ~300 lines of construction sat *before* the
     watchdog was spawned and before `pcall(runStages)`. A throw anywhere in it would leave the
     player behind an opaque frame permanently — the exact disaster the file's header exists to
     prevent. Fixed by putting the whole scene build under `pcall`, so it degrades to title/bar/
     status instead of dying.
  2. **The scrim never faded.** `release()` tweens the *parent*, and tweening a parent's
     `BackgroundTransparency` does nothing to a child — so a 56 %-opaque band held over the lower
     third for the entire out-tween and then vanished on `Destroy`. A hard cut on every boot.
     Measured after the fact: parent → child stayed `0.00`; the child's own property → `1.00`.
  3. **My `DIORAMA EMPTY` guard was worthless.** `built < 20` against 42 actual parts meant the
     magnet, the robot and the player figure could *all* be deleted and it would stay silent — and
     its documented failure mode ("built nothing") was unreachable, because an unguarded throw
     aborted before the guard ran. Replaced with a check that names §7's five subjects. Both halves
     of that are the PITFALLS #55–#61 shape appearing **inside the check written to prevent it.**
  Also fixed: three signal-colour reuses against style §2 (gold decorative lamps, cyan robot eyes),
  an invented colour that escaped the audited `PALETTE`, an audit skip-branch that could not tell
  "no token by design" from "token renamed", a stale comment claiming 13° where the code said 8°,
  and a floor whose corners entered frame against a comment claiming they never did.
- **The one finding I rejected, with evidence**: it called the gold `Coin` scrap piece a signal-colour
  violation and wanted recycler green. `Hud.local.luau:100-103` already paints **both** the Coins icon
  and the Coins counter in `Theme.color.arena` gold. Matching shipped precedent is consistency;
  changing it would have made the loading screen contradict the HUD. Left gold.
- **What it confirmed clean, checked rather than assumed**: no `require`/yield/`WaitForChild`
  introduced into `ReplicatedFirst`; no leaks (every new instance is a descendant of `gui`); the
  stage↔event assertion is *stronger* than the one it replaced; and the diorama frames identically
  on both canvases because `FieldOfView` is vertical. It also verified the analyzer genuinely covers
  this file by injecting a type error and watching it fail.

> ⚠️ **Blocked on you, and worth knowing about.** This session was started with an explicit
> instruction not to spawn agents unless you ask for one. GROUND-RULES 8 makes an independent
> reviewer mandatory on every job. I am not going to quietly drop a ground rule or quietly break a
> session instruction — say the word and I run the reviewer.

## What I need from you

- [x] **Go-ahead on the approach change** — a live `ViewportFrame` diorama instead of a flat image,
      and the emoji row retired rather than kept beside it.
- [ ] 🔴 **STILL OPEN.** **Flip the Device Emulator** to the phone preset for steps 1 and 9. It has no scripting API.
- [x] **Say whether the independent reviewer runs** (see the note above).
- [x] Nothing to buy, nothing to upload, **no Meshy credits** — balance stays at 1,240.

## Verification - MANDATORY GATES (GROUND-RULES 7)

None of these may be ticked from an Edit session. Edit does not run LocalScripts and has nothing created at
runtime, so it cannot show a whole class of bug.

- [x] **Reproduced in PLAY**, at the player's camera angle, BEFORE attempting a fix
- [~] **N/A** — this job added a missing deliverable, it did not fix a "works in X, broken in Y". Environments diffed FIRST - client scripts and their VFX,
      runtime-created instances, tick-driven systems, place settings
- [x] Every check below says what a FAILURE would have looked like
- [x] Before/after from the SAME camera, and the "before" is kept
- [x] No world fact asserted from a constant - measured instead
- [x] The fix accounts for the REPORTED symptom (the missing P0 art), not just for real bugs found on the way — the tofu coin found en route was logged as `finding 0003`, not silently folded in

### Checks

- [x] **Before screenshot kept** — the current title-card-and-four-emoji screen, in Play. *Failure:
      no before, so "better" is unfalsifiable.*
- [x] **Canvas measured, not assumed** — `AbsoluteSize` read in Play on both presets. *Failure: the
      numbers come back as `666×316` / `1825×1255`, proving I read the HUD's canvas, not this one.*
- [x] **The viewport actually renders** — the diorama is visible in a Play screenshot, not an empty
      rectangle. *Failure: a flat `#0E1526` box, i.e. camera unset or geometry behind the near
      plane. This is the single most likely way this job fails silently.*
- [x] **Bloom/Beam/particle behaviour recorded from the probe, not assumed.** *Failure: shipping a
      `Beam` arc that renders in the world screenshot and is invisible in the viewport — the exact
      shape of a check agreeing with the bug it was written to catch.*
- [x] **An object arrives per stage, and only on real completion** — count arrivals against stage
      transitions in the log. *Failure: four objects arrive in a smooth 2 s sweep regardless of load
      time, i.e. it became a timer again.*
- [x] **Every text element still reads over the diorama** — title, tagline, bar, status, judged on
      the screenshots at both presets. *Failure: the tagline sits over the lit magnet and is gone.*
- [x] **The bar is still visible when empty** — over the diorama, not over flat `#0E1526`.
      *Failure: the first second of the game has no visible progress indicator.*
- [ ] 🔴 **NOT DONE — needs you.** **Phone frame time measured with the viewport on vs off.** *Failure: the one screen every
      player sees is the most expensive frame in the game, on a mobile-first title.*
- [x] **The warn can still fire** — force it by building the viewport with no children. *Failure: it
      stays silent, and the check is decorative.*
- [x] **`auditPalette` still clean** — no new colour outside `PALETTE`. *Failure: a drift warn, or
      worse, silence because the colour was never added to the audited table.*
- [x] **No probe left on disk** — `git status` clean of step 2's scaffolding. *Failure: a second
      `SyncProbe` in the next commit.*
