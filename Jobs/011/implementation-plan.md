# Job #011 — implementation plan

**Project**: `roblox.magnet-sweep` · **Agreed**: 2026-08-30

## The two calls made at intake

| Question | Answer | Consequence |
|---|---|---|
| May I drive the Device Emulator? | **Yes, standing for the session** — switch it back after | The layout is measured, not reasoned about (mobile skill §1) |
| What does the upgrade button do? | **Wire `RequestUpgrade` for real** | ~40 lines server-side on the existing `Economy` cost curves. Coins buy something. Group 05 puts a bench around it rather than building it |

## The conflict this job has to resolve

`docs/game/ui-direction.md` places **Scrap bottom-centre** and **Upgrade bottom-right**. The `mobile`
skill's measured reservations say bottom-left is `DynamicThumbstickFrame` (to x=266 of 666) and
bottom-right is the jump button (x 571..641). The free bottom band is x 266..571, whose centre is
**x≈418, not the canvas centre 333** — so a bottom-centre panel of any useful width sits inside the
thumbstick region, and a bottom-right button sits under jump.

**Resolution: two layouts, one HUD.** Desktop keeps `ui-direction.md` exactly. Touch moves Scrap into
a top-left vitals column under Coins (the mobile skill's own recommendation for glanceable readouts)
and moves Upgrade to the right edge at mid-height, clear of jump and reachable by the right thumb.
Recorded in the final summary and back-annotated into `ui-direction.md` — not silently diverged.

## Files

| File | New? | What |
|---|---|---|
| `ReplicatedStorage/Ui/Theme.luau` | new | The style skill's §7 tokens in one place — colours, `FontFace` (never `Enum.Font`), corner/stroke recipe, tween timings |
| `ReplicatedStorage/Ui/Layout.luau` | new | The **measured** canvas. Reads `AbsoluteSize`, `TouchEnabled`, and Roblox's own `TouchGui` rects; re-fires on every `AbsoluteSize` change so orientation and the emulator are free |
| `ReplicatedStorage/Ui/Components.luau` | new | panel · label · bar · button (pressed state + scale tween + sound) · **counter** (count-up then scale punch) |
| `ReplicatedStorage/Ui/Banner.luau` | new | One line, all caps, short-lived, queued and de-duped |
| `StarterPlayerScripts/Hud.local.luau` | new | Builds and drives the HUD from `StatsChanged`. `.local.luau`, never `.client.luau` (PITFALLS #13) |
| `ReplicatedStorage/SoundKit.luau` | edit | Add a `UI.Press` slot, `id = ""` so it announces itself at startup. No placeholder (ground rule 10) |
| `ServerScriptService/MagnetState.luau` | edit | `MagnetState.upgrade(player, track)` — the one place a level is bought |
| `ServerScriptService/Bootstrap.server.luau` | edit | Bind `RequestUpgrade`; fix a leaked Python artifact in a comment |

## Rules this job is bound by

1. **The client renders `StatsChanged`; it never derives it.** `flowProgress`/`flowNeeded` are already
   a numerator and denominator — the bar does no arithmetic. `full` is already computed server-side.
2. **Decision 0018:** the HUD *reinforces* SCRAP FULL, never replaces it. Verification includes
   playing with the HUD hidden and confirming the magnet still teaches it.
3. **No placeholder content.** The robot/Arena widget is real code bound to `ArenaStateChanged` and
   stays hidden because nothing fires that remote yet — it does not draw invented HP or a fake timer.
4. **No hard pixel floor sized against a desktop viewport** (mobile §2). Sizes are a fraction of the
   measured canvas, clamped, and recomputed on `AbsoluteSize`.
5. **Numbers are not enough** (mobile §4b). Every state gets a screenshot that is actually read.

## Verification — and what failure looks like

| Check | Passes when | **Fails when** |
|---|---|---|
| Probe in the emulator | `TouchEnabled = true`, canvas recorded | Reports `false` — we measured desktop and learned nothing |
| Rect diff vs **every** `TouchGui` child | No HUD element intersects the thumbstick frame or jump | Any overlap, incl. `DynamicThumbstickFrame`, not just `ThumbstickStart` (mobile §3) |
| Tap targets | Every `GuiButton`, transparent ones included, ≥58 px | Anything under 58 that is not a documented 44 |
| Screenshots, read with eyes | Six states: idle · sweeping · Flow ×N · RUSH · SCRAP FULL · upgrade panel | Clipped text, an empty-looking box, a control under a thumb |
| SCRAP FULL with the HUD off | Still obvious from the magnet | Only the HUD says it → decision 0018 broken |
| Upgrade | Coins fall, stat rises, `StatsChanged` follows | Server accepts a client price, or a level rises without payment |
| Rush spam | Counter does not vibrate through a Rush | A punch per collection |

## Independent review

A reviewer agent is given **the requirement and the screenshots**, never my theory (GROUND-RULES 8).
