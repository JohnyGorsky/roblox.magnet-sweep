--!strict
--[[
	Theme — the UI half of the style skill, in code, once.

	Every colour, typeface and timing the HUD uses lives here so that the design system and the
	game cannot drift apart one hardcoded `Color3.fromRGB` at a time. That is not hypothetical:
	PITFALLS #39 is the colour language decaying exactly that way, and #38 is config-first
	decaying one constant at a time.

	🔴 TWO ENGINE TRAPS ARE ENCODED HERE, and both are silent.

	1. **`Enum.Font.Gotham` / `GothamBold` were removed in May 2024** and now map to Montserrat.
	   The code compiles, runs, carries no deprecation tag, and renders the wrong typeface.
	   Nothing warns you. So this file sets `FontFace`, never `Font`, and `Theme.audit()`
	   fails loudly if a font family fails to resolve.

	2. **A signal colour means exactly one thing.** Green is recycle, orange is repair, cyan is
	   the magnet, red is alarm and the south pole, gold is Arena control and Legendary. They
	   are named for their MEANING below, not for their hue, so a call site asking for
	   `Theme.color.alarm` cannot accidentally be "a nice red".

	Sources: .claude/skills/magnet-sweep-style/SKILL.md §2, §7 · docs/game/ui-direction.md
]]

local Theme = {}

local function hex(s: string): Color3
	return Color3.fromHex(s)
end

--------------------------------------------------------------------------------
-- Colour. Named by meaning; never by hue.
--------------------------------------------------------------------------------

Theme.color = {
	-- structural
	factoryDark = hex("0E1526"),
	steelMid = hex("4A545E"),
	chrome = hex("B8C2CC"),
	hazardBlack = hex("14161C"),
	panel = hex("141B2B"),

	-- signal — one meaning each
	magnet = hex("41D8FF"), -- pull, electricity, the north pole
	alarm = hex("E03A2F"), -- the south pole, Salvage Breach, SCRAP FULL
	recycle = hex("3FD64B"), -- coins in, scrap converted
	repair = hex("FF7A1A"), -- robot HP
	arena = hex("FFC21A"), -- Arena control — and Legendary
	epic = hex("C46BFF"),
	mythic = hex("FF3D7F"),

	-- type
	text = hex("F2F6FA"),
	textDim = hex("9AA7B8"),
	textOnLight = hex("14161C"),
}

--- The rarity ramp, used identically in the HUD, the Part Archive, the Robot Builder and the
--- world outline on an uncollected part.
Theme.rarity = {
	Common = Theme.color.chrome,
	Uncommon = Theme.color.recycle,
	Rare = Theme.color.magnet,
	Epic = Theme.color.epic,
	Legendary = Theme.color.arena,
	Mythic = Theme.color.mythic,
}

--------------------------------------------------------------------------------
-- Type.
--------------------------------------------------------------------------------

local BUILDER_SANS = "rbxasset://fonts/families/BuilderSans.json"
local BANGERS = "rbxasset://fonts/families/Bangers.json"

--- ⚠️ `FontFace`, never `Font`. See the header — the `Enum.Font` path is legacy and the two
--- names this design system would reach for first were silently redirected in 2024.
Theme.font = {
	--- Data: coins, scrap, stat values. Bold BuilderSans, Roblox's own replacement for Gotham.
	data = Font.new(BUILDER_SANS, Enum.FontWeight.Bold),
	--- Labels and units, one weight down so the number is the hero.
	label = Font.new(BUILDER_SANS, Enum.FontWeight.Medium),
	--- All-caps display: MAGNET RUSH!, SALVAGE BREACH, SECURED, SCRAP FULL.
	display = Font.new(BANGERS, Enum.FontWeight.Regular),
}

--------------------------------------------------------------------------------
-- Shape and motion.
--------------------------------------------------------------------------------

Theme.shape = {
	corner = 8, -- px
	stroke = 2, -- px
	strokeTransparency = 0.4,
	panelTransparency = 0.2, -- #141B2Bcc
	pad = 10, -- px inside a panel
}

Theme.motion = {
	--- Every button: pressed state + this scale tween + a sound. Silence reads as broken.
	press = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	--- A number's scale punch, after it has finished counting up.
	punch = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	punchScale = 1.14,
	--- How long a counter takes to travel to its new value.
	countUp = 0.22,
	--- ⚠️ A MAGNET RUSH changes Coins many times a second. Without a floor between punches the
	--- number vibrates and reads as broken rather than as fast. Measured against the Rush, not
	--- chosen: `Magnet.RUSH` collects in batches every ~0.25 s.
	punchCooldown = 0.18,
	fade = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

Theme.banner = {
	hold = 1.5, -- seconds fully visible
	inTime = 0.14,
	outTime = 0.30,
	--- Two identical banners inside this window are one banner.
	dedupe = 1.0,
}

--------------------------------------------------------------------------------

--- The two families this design system ships, and the ONLY two any `Theme.font` entry may name.
---
--- 🔴 MEASURED: `Font.new("rbxasset://fonts/families/NotARealFamily.json", ...)` constructs
--- happily, applies to a `TextLabel` without error, and reports `.Family` back as the exact
--- string you passed. **Roblox gives no runtime signal that a font failed to resolve** — the
--- label just renders in the default face and looks slightly off.
---
--- So there is no way to verify a family EXISTS from code. What can be verified is that we only
--- ever name one we have actually confirmed in Studio, which is what this list is.
local VERIFIED_FAMILIES: { [string]: boolean } = {
	[BUILDER_SANS] = true, -- confirmed in Studio, 2026-08-30
	[BANGERS] = true, -- confirmed in Studio, 2026-08-30
}

--- Fails when a `Theme.font` entry names a family nobody has confirmed exists.
---
--- ⚠️ An earlier version of this function checked `face.Family == ""` and claimed that caught the
--- silent Gotham → Montserrat redirect. It caught nothing: `Family` is whatever string was passed,
--- so it is never empty, and the function returned an empty table for every possible input
--- including a typo. It was a verification that could not fail, in the file whose header is about
--- silent font substitution (PITFALLS #2).
---
--- This version fails on a typo, on a family added without being checked in Studio, and on a
--- non-`Font` value. It cannot detect Roblox dropping a family it used to ship — nothing can, from
--- code — and it says so rather than implying otherwise.
function Theme.audit(): { string }
	local problems = {}
	for name, face in pairs(Theme.font) do
		if typeof(face) ~= "Font" then
			table.insert(problems, ("Theme.font.%s is a %s, not a Font"):format(name, typeof(face)))
		elseif not VERIFIED_FAMILIES[face.Family] then
			table.insert(problems, ("Theme.font.%s names %q, which is not in VERIFIED_FAMILIES -- confirm it renders in Studio and add it there, do not assume")
				:format(name, face.Family))
		end
	end
	return problems
end

return Theme
