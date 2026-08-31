# Final Summary — Job #015

**Project**: `roblox.magnet-sweep`
**Completed**: 2026-08-31
**Status**: ✅ Completed

## What was implemented

**The loading screen has art, and it is not a picture — it is the scene, running.**

§7 asks for two things that a flat backdrop could never deliver: the screen *"should already feel
interactive"*, and *"progress is represented by objects flying into the magnet: `🔩 → ⚙️ → 🪙 → 🧲`"*.
What shipped in job 014 was a title card, a tagline, a real progress bar, and **four emoji that dimmed
and brightened**. Line 537 warned `ART MISSING` by name at every startup so those glyphs could not
read as finished.

The screen is now three layers:

| Layer | What it is |
|---|---|
| `Backdrop` | flat factory dark, sinks input (unchanged) |
| `Plate` | a **blurred frame of the game's own concept art** — `Arena.png` at radius 16, 42 % brightness, uploaded as `rbxassetid://88620361473282` |
| `Glow` | a 2D cyan halo — **sixteen** concentric circles — painted **behind** the viewport |
| `Diorama` | a `ViewportFrame` on a **transparent** background: the magnet, a receding corridor, a homemade robot, the player in silhouette, and three pieces of scrap |
| `Scrim` | a vertical `UIGradient` darkening the lower frame so the bar and status line stay legible |

The three scrap pieces start **off-frame** and fly into the magnet's mouth, one per completed boot
stage, on the existing `tik`. The fourth stage has no piece — it is the magnet itself surging to full
power, which is §7's `🧲`, landing on the same beat as the `CLANG`. The halo ramps with real stage
completion, so the magnet visibly powers up as the game actually loads.

**The emoji row is gone**, per the owner's decision. Two indicators for the same progress contradicted
§7's *"that is the whole screen"*, and geometry cannot have emoji-rendering bugs — which turned out to
matter more than expected (see the finding below).

### The approach changed mid-job, and the owner was right

The plan's first version generated a 2D key-art illustration with Meshy. The owner stopped it before
it ran — **no credits were spent, balance is still 1,240** — with *"generate from meshy only if it
needed, you mostly can recreate with roblox objects or search in store."*

That was the better call on the merits, not just on cost. A painted backdrop satisfies neither
sentence of §7. It also carried two risks this route does not: **moderation** (an uploaded image
commonly renders for the uploading owner in Studio while staying blank for everyone else, so "it
looked right in my Play session" would not have been proof it ships) and **irreversibility** (a
published Roblox asset cannot be unpublished).

**Creator Store was checked, not assumed.** `search_asset` for factory/corridor/industrial
backgrounds (`assetType = Image`, `creator_store`, 10 results) returned untitled user screenshots, a
"Backroom" decal and a Skibidi Toilet door. The store is a real source for props and audio; it is not
a source of bespoke key art. Recorded so nobody runs the search again expecting a different answer.

Meshy is not ruled out — it is deferred to where style §3 already puts it: hero **meshes**.

### Files changed

- `studio_game/ReplicatedFirst/BootScreen.local.luau` — the diorama, the halo, the scrim, the plate,
  the arrival animation, the palette additions, and the guard that replaced `ART MISSING`
- `assets/generated/loading-backdrop.png` — the blurred plate, reproducible from `Arena.png`
- `assets/generated/magnet-ref.png`, `assets/generated/magnet/` — job 016's inputs, generated here
- `docs/PITFALLS.md` — **#62**, the measured ViewportFrame constraint
- `findings/0003-…` — the tofu coin, still broken, contradicting job 014's summary
- `docs/HANDOFF.md` — state

## What the probe measured, before any art existed

The plan refused to guess at three things, and all three changed the design:

| Question | Answer | Consequence |
|---|---|---|
| Does Bloom apply inside a `ViewportFrame`? | **No.** A `Neon` part is flat with a hard edge, in the same frame the identical world part blooms | The glow had to be painted in 2D behind a transparent viewport |
| Do `Beam`s render inside one? | **No.** `Enabled`, inside the frustum, drew nothing | §6's *"arcs are always a `Beam`"* is unavailable here |
| Do `ParticleEmitter`s? | **No.** `Enabled` at `Rate` 60, nothing | No sparks |

Also measured: the `ScreenInsets.None` canvas is **1825 × 1313** (aspect 1.390). The `1825 × 1255` on
record in HANDOFF is the **HUD's** canvas under `CoreUISafeInsets` — a different screen in a different
inset mode. Had that number been reused, the composition would have been fitted to a canvas 58 px
shorter than the real one.

## Proof it works better - MANDATORY (GROUND-RULES 7)

| | |
|---|---|
**Before** | `boot_BEFORE` — title card, tagline, four emoji, full bar. Captured in Play at 1825 × 1313 |
**After** | `boot_AFTER_desktop_final` — same screen, same canvas, same state (all four stages complete) |
**What failure would have looked like** | An empty `ViewportFrame` renders as a hole the exact colour of the backdrop — indistinguishable from the screen working. That is why the guard counts parts |

⚠️ **How the before/after were captured, stated plainly.** The screen's natural life is
**1.50–1.78 s**, shorter than an MCP round-trip, so both shots were taken with a temporary
`task.wait` at the top of `release()`. The screen's *appearance* is untouched by that — only its
duration. The hold was reverted, and the shipped file was confirmed **byte-identical** to the
verified one afterwards.

- [x] Captured in **PLAY**, not the editor
- [x] Same camera and same game state in both
- [x] Numbers where numbers are possible, not only screenshots

### Checks that could have failed, and did not

| Check | Result |
|---|---|
| Canvas measured, not assumed | **1825 × 1313**, not the HUD's 1825 × 1255 — proving the right screen was read |
| The arrival animation actually ran | all three pieces travelled **44–51 studs** from off-frame and faded out |
| Scrap landed **inside the mouth**, not mid-air | y 0.77, between pole strip 0.11 and leg centre 2.34 |
| The magnet surge fired on stage 4 | pole strips **0.276 → 0.386**, exactly the 1.4× |
| The halo ramped to full | core transparency **0.860** (dark 0.983 → full 0.860) |
| `auditPalette` still clean | four new colours mapped to real `Ui.Theme` tokens, **no drift warn** |
| **The guard can still fire** | forced, and it warned. ⚠️ That guard was then **replaced** after review — see below |
| No probe left behind | `_Probe015` gone from **disk and the DataModel** |

### ✅ The phone preset — done, and it found something

The owner flipped the Device Emulator. Measured with `TouchEnabled = true`, canvas **666 × 374**
(aspect 1.781, against desktop's 1825 × 1313 / 1.390):

| Check | Result |
|---|---|
| **The halo is still a circle** | **209 × 209 px, aspect 1.0000.** The `UIAspectRatioConstraint` held, at 56.0 % of canvas height exactly as intended |
| Magnet fully in frame | yes |
| Clear of the progress bar | yes |
| **Clear of the tagline** | 🔴 **NO — overlapped by ~3 px** |

The halo was the thing this section said was reasoned about but not measured. It is confirmed.

🔴 **The overlap was real and was fixed.** The magnet's arm nub projected to screen y **0.349**
against a tagline box ending at **0.3575**. ⚠️ And it was never a phone problem: `FieldOfView` is
*vertical*, so the magnet's screen span is identical on both canvases — it had been overlapping on
desktop too, and eyeballing screenshots had not caught it. `MAGNET_Y` 3.5 → **2.9** puts the span at
**0.367 .. 0.587**: 3.5 px clear of the tagline, 8.3 px clear of the bar.

**The derived halo position proved itself here.** Moving the magnet moved the halo with it, to
y 0.4675, with no second edit — exactly the failure mode the reviewer's finding #6 predicted for a
hand-written constant.

## A defect found on the way, in code this job did not touch

**The 🪙 coin glyph was still tofu.** Job 014 reported it fixed by setting an explicit `FontFace`.
Measured in Play, same font, `TextSize` 64:

| glyph | width |
|---|---|
| 🔩 `U+1F529` · ⚙️ `U+2699` · 🧲 `U+1F9F2` | **59** |
| 🪙 `U+1FA99` | **31** |
| a deliberately absent codepoint `U+10FFFD` | **34** |
| 💰 `U+1F4B0` · 🟡 `U+1F7E1` | **59** |

`FontFace` selects a typeface; it **cannot add a codepoint no Roblox font contains**. The fix
addressed the wrong cause, and the verification — looking at a screenshot and seeing four shapes —
agreed with the bug. `U+1FA99` is a Unicode 14 (2021) emoji and is simply not in the atlas.

Retiring the row makes it moot for the product, but job 014's summary is wrong on the record, so it
is logged as **finding 0003** rather than quietly buried by the rewrite.

## The plate — the owner's second idea, and it cost nothing

Mid-job: *"maybe loading background can be blurred image from our concept art."* We already own
`Arena.png`, so this needed no generation at all — just PIL: downscale to 640 × 360, Gaussian blur,
darken, upload.

Three strengths were rendered and compared rather than picked: **radius 10 / 55 % brightness** still
had readable detail and fought the text; **radius 26 / 34 %** was indistinguishable from flat black;
**radius 16 / 42 %** kept the Magnet Lab's blue and the Recycler's green as soft colour pools while
staying well under the type. That one shipped.

It is `Arena.png` specifically, and that is the point — the Workshop is the room the status line says
the player is entering, so it is the right thing to be looking at while they wait for it. `Robot.png`
was rejected for doubling up on the magnet the diorama already stars.

⚠️ **It degrades safely.** A freshly uploaded image is moderated, and until it passes it renders as
nothing for other players. So it is an `ImageLabel` *over* the existing `Frame`, never a replacement
for it: if the asset never loads, the screen is exactly the flat factory dark it was before.

## What the picture cost to get right

Worth recording because the first version was not close. Six passes, each fixing something the
previous one proved:

1. Magnet filled the frame as a red wall; halo trapped inside its slot.
2. Halo rendered as a **countable bullseye** — six rings at 0.8 was not a glow.
3. Corridor arches *surrounded* the magnet, putting steel on every side of its outline: it read as a
   torii gate. Moved out and down to flank the frame.
4. A full crane arm ran straight up through the title. Cut to a chrome nub.
5. 45° chamfer blocks meant to fake a horseshoe's round shoulders read as **ears**. Removed — large
   enough to see meant large enough to protrude.
6. The south pole was painted alarm red **onto a red body** and vanished, so half the game's logo was
   invisible. Pole shoes became chrome with a thin lit strip.

The lesson that generalises: **a horseshoe's proportions are the entire silhouette.** Three passes
made it taller than wide with a narrow slot and every one read as a doorway. Wider than tall, with an
opening 47 % of the width, reads as a magnet immediately.

## Verification

- [x] All mandatory gates in the implementation plan are ticked, **except the phone preset**
- [x] Independent reviewer agent run — **8 findings, 7 real, all 7 fixed; 1 rejected with evidence.**
      Full detail in [implementation-plan.md](implementation-plan.md). The pattern held for a
      fifteenth job: it found two HIGH defects I had built *and verified around*, including a guard
      of mine that was itself an instance of the failure mode it was written to catch.
- [x] Re-verified in Play after the fixes: scene renders, 42 parts, all five §7 subjects present,
      derived glow Y **0.4495**, robot eye `#FF7A1A`, lamp `#B8C2CC`, **zero boot warnings**
- [x] `tools/luau-analyze.sh` clean for this file
- [x] Shipped file byte-identical to the verified one
