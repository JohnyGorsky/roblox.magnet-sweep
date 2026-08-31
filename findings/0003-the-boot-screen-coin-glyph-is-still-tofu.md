# FINDING 0003: The boot screen coin glyph is still tofu; job 014's font fix could not have worked

**Project:** `roblox.magnet-sweep`
**Status:** fixed (2026-08-31) — Fixed 2026-08-31. Swapped U+1FA99 for U+1F4B0 at all THREE live sites -- and there were three, not one: Hud.local.luau:100 (the Coins icon), Hud.local.luau:466 (the upgrade panel price) and StationController.local.luau:219 (the station coins readout). Every place the game displayed a coin amount was rendering a .notdef box. Verified in Play with the same falsifiable measurement that found it: at a fixed TextSize 64 the new glyph measures 59px, identical to the known-good bolt U+1F529, against the old coin's 31px and a deliberately-absent codepoint's 34px. Analyzer: 27 issues across both files before, 27 after. Chose the money bag over the yellow circle U+1F7E1 -- also 59px -- because a plain gold disc risks reading as a status indicator in a factory game whose style guide calls for caged amber warning beacons. The only remaining U+1FA99 is a comment in BootScreen quoting section 7's diagram, which renders nowhere.
**Severity:** med
**Created:** 2026-08-31 10:26:24

**Symptom:** Job 014 reported the tofu coin fixed by setting an explicit FontFace (BuilderSans). Measured in Play at 1825x1313 on 2026-08-31, it is still a .notdef box. Evidence, same font, TextSize 64: bolt U+1F529 = 59px, gear U+2699 = 59px, magnet U+1F9F2 = 59px, moneybag U+1F4B0 = 59px, yellow-circle U+1F7E1 = 59px -- but coin U+1FA99 = 31px, against a deliberately absent codepoint U+10FFFD measuring 34px. In the live row, Icon1/2/4 report TextBounds 91x100 and Icon3 reports 48x100. FontFace selects a typeface; it cannot add a codepoint no Roblox font contains, so the fix addressed the wrong cause and the verification (looking at a screenshot and seeing four shapes) agreed with the bug. U+1FA99 is a Unicode 14 (2021) emoji and is simply not in the atlas. Fix if the row survives: swap to U+1F4B0 or U+1F7E1, both measured as rendering. Job 015 retires the emoji row for 3D geometry, which makes it moot for the product but leaves job 014's summary wrong on the record.
**Where:** studio_game/ReplicatedFirst/BootScreen.local.luau:128
**Repro / notes:** _TODO_
**Fix idea:** _TODO_

## ⬆️ ESCALATED, same day — this is live in the HUD, not just the boot screen

The boot screen's emoji row is retired by job 015, which looked like it made this moot. It does not.

`studio_game/StarterPlayerScripts/Hud.local.luau:100` sets the **Coins icon** to the same codepoint:

```lua
local coinsIcon = Components.label("Icon", coinsPanel, {
    text = "🪙",                       -- U+1FA99, measured absent from the atlas
    color = Theme.color.arena,
```

So the currency indicator on the **shipped HUD**, top-left, visible for the entire session, is
rendering a `.notdef` box rather than a coin. That is a player-visible defect in code job 015 never
touched, and it survived every previous job's review.

**Severity raised: med → high.** The boot-screen half is gone; the HUD half is live.

**Fix:** swap `U+1FA99` for `U+1F4B0` 💰 or `U+1F7E1` 🟡 — both measured at 59 px against the coin's
31 px, i.e. both actually render. Do **not** "fix" it by setting a font: the whole point of this
finding is that `FontFace` cannot add a codepoint no Roblox font contains.

⚠️ Whoever fixes it should grep the whole tree for other Unicode-14-era emoji before assuming the
Coins icon is the only one.
