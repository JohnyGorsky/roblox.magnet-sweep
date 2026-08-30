--!strict
--[[
	Config/Quality — the three client quality tiers.

	Mobile sets the budget (decision 0012). The glossy look ships as a TIER on top of a
	phone floor that is never optional.

	MEASURED IN STUDIO, job 004 (in EDIT -- not yet confirmed in Play):
	  * BasePart.Reflectance is MATERIAL-DEPENDENT, as Roblox's docs state. Inert on Metal;
	    clearly active on SmoothPlastic. Five of the nine kit surfaces are Metal-based, so it is
	    not a usable global fallback -- the Low tier drops MaterialVariant entirely instead
	    (decision 0016). An earlier note here claimed it was inert everywhere; that was a
	    Metal-only test generalised to the whole place.
	  * Part Color MULTIPLIES the ColorMap, so a neutral map takes any palette colour.

	MEASURED IN STUDIO, job 002:
	  * Lighting.Technology cannot be READ OR WRITTEN by any script (RobloxScriptSecurity).
	  * Lighting.LightingStyle and PrioritizeLightingQuality are readable but NOT writable.
	  * The streaming radii are not valid members of Workspace at all.
	So the lighting STYLE is a permanent human action in Studio. Nothing in this module can
	change it, and nothing should try. What a tier controls is only what a LocalScript can
	actually change.

	Sources: docs/systems/performance/README.md · .claude/skills/magnet-sweep-style/SKILL.md §8
	         decision 0012 · Jobs/002/final-summary.md
]]

export type TierName = "Low" | "Medium" | "High"

export type Tier = {
	name: TierName,
	postBloom: boolean,
	postColorCorrection: boolean,
	postSunRays: boolean,
	depthOfField: boolean,
	usePBR: boolean, -- MaterialVariant maps vs built-in material + flat palette colour
	meshSurfaceAppearance: boolean, -- SurfaceAppearance is MeshPart-only
	--- Studs. A decorative light's Range is CLAMPED to this; it is never switched off (see
	--- QualityController.applyLights). ⚠️ It must sit BELOW the largest authored light range
	--- in the kit or the tier does nothing: it was 40/60/10000 against a kit whose biggest
	--- light is 18, so the cull was inert at every tier. Bootstrap now asserts this.
	decorativeLightRange: number,
	particleRateScale: number,
	trails: boolean,
	maxConcurrentPull: number,
}

local Magnet = require(script.Parent.Magnet)

local Quality = {}

Quality.TIERS = {
	Low = {
		name = "Low",
		postBloom = true,
		postColorCorrection = false,
		postSunRays = false,
		depthOfField = false,
		usePBR = false,
		meshSurfaceAppearance = false,
		decorativeLightRange = 10, -- [UNTUNED] clamps the kit's 12/14/16/18 lights
		particleRateScale = 0.5,
		trails = false,
		maxConcurrentPull = Magnet.MAX_CONCURRENT_PULL.Low,
	},
	Medium = {
		name = "Medium",
		postBloom = true,
		postColorCorrection = true,
		postSunRays = false,
		depthOfField = false,
		usePBR = true,
		meshSurfaceAppearance = true,
		decorativeLightRange = 15, -- [UNTUNED] clamps only the 16 and 18 lights
		particleRateScale = 1.0,
		trails = false,
		maxConcurrentPull = Magnet.MAX_CONCURRENT_PULL.Medium,
	},
	High = {
		name = "High",
		postBloom = true,
		postColorCorrection = true,
		postSunRays = true,
		depthOfField = true, -- reserved for the Robot Bay install cinematic
		usePBR = true,
		meshSurfaceAppearance = true,
		decorativeLightRange = 10000, -- above any authored range: High clamps nothing
		particleRateScale = 1.0,
		trails = true,
		maxConcurrentPull = Magnet.MAX_CONCURRENT_PULL.High,
	},
} :: { [TierName]: Tier }

--------------------------------------------------------------------------------
-- Tier selection is by MEASURED FRAME TIME, never by TouchEnabled alone -- a tablet is
-- not a low-end phone and a cheap laptop is not a high-end PC.
--------------------------------------------------------------------------------

Quality.DETECT = {
	SAMPLE_SECONDS = 4.0, -- how long to watch before deciding
	WARMUP_SECONDS = 2.0, -- ignored while the client settles
	LOW_IF_MS_ABOVE = 26.0, -- ~38fps or worse -> Low
	HIGH_IF_MS_BELOW = 12.0, -- ~83fps or better -> High
	RECHECK_INTERVAL = 60, -- re-evaluate periodically; a zone change can shift the load
	HYSTERESIS_MS = 3.0, -- avoid flapping between tiers
	--- Seconds to wait after the world has loaded and the character exists, before the first
	--- measurement. ⚠️ Without this the sample lands in the first seconds of the session --
	--- textures decompressing, world streaming, often no character yet and almost nothing being
	--- drawn -- which is the least representative window in the whole session and the one the
	--- entire tier decision used to be taken in.
	SETTLE_SECONDS = 3.0,
}

--------------------------------------------------------------------------------
-- The reference device and the budgets.
--
-- The budget lives in Config/Perf, which is its single source of truth and which is honest
-- about which numbers are TARGETs, which are MEASURED, and which can only be answered on real
-- hardware. Do not duplicate it here.
--
-- ⚠️ This block carried a "NOT YET CHOSEN -- until they are set, is this fast enough has no
-- answer" banner three lines above `CHOSEN = true`, and Bootstrap printed that constant as
-- `budgets=%s`. No state of the world could ever have made it print false. A world fact
-- asserted from a literal is not a fact (PITFALLS #3), so the flag is gone: whether budgets
-- exist is answered by reading Config/Perf, where they either are or are not.
--------------------------------------------------------------------------------

Quality.BUDGET = {
	SEE = "Config/Perf",
}

--- The tier a player is actually on, as published by their QualityController, or the default
--- before it has run. Anything that drives its own visuals per frame must consult this rather
--- than let the one-shot tier pass fight it.
function Quality.tierOf(player: Player): TierName
	local name = player:GetAttribute("QualityTier")
	if type(name) == "string" and Quality.TIERS[name] then
		return name :: TierName
	end
	return Quality.default()
end

function Quality.default(): TierName
	return "Medium"
end

function Quality.get(name: TierName): Tier
	return Quality.TIERS[name] or Quality.TIERS[Quality.default()]
end

--- Classify a measured average frame time into a tier.
---
--- Hysteresis must be SIGNED BY THE TIER YOU ARE IN: it widens the threshold you would
--- have to cross to LEAVE where you are. Applying it in one direction regardless (the
--- first draft treated `current` as a boolean) makes it harder to enter Low *and* harder
--- to enter High from anywhere, biasing every client toward Medium and demoting a stable
--- High client that drifts a millisecond.
function Quality.classify(avgFrameMs: number, current: TierName?): TierName
	local d = Quality.DETECT
	local toLow, toHigh = d.LOW_IF_MS_ABOVE, d.HIGH_IF_MS_BELOW
	if current == "Low" then
		toLow += d.HYSTERESIS_MS -- must improve past the threshold to leave Low
	elseif current == "High" then
		toHigh -= d.HYSTERESIS_MS -- must degrade past the threshold to leave High
	elseif current == "Medium" then
		toLow += d.HYSTERESIS_MS -- Medium resists being pulled either way
		toHigh -= d.HYSTERESIS_MS
	end
	if avgFrameMs > toLow then
		return "Low"
	elseif avgFrameMs < toHigh then
		return "High"
	end
	return "Medium"
end

return Quality
