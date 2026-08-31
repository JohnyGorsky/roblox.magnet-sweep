# FINDING 0003: The boot screen coin glyph is still tofu; job 014's font fix could not have worked

**Project:** `roblox.magnet-sweep`
**Status:** open
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
