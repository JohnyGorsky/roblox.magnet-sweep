--!strict
--[[
	Config/Quality — the three client quality tiers.

	Mobile sets the budget (decision 0012). The glossy look ships as a TIER on top of a
	phone floor that is never optional.

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
	usePBR: boolean, -- MaterialVariant maps vs a flat Reflectance fallback
	meshSurfaceAppearance: boolean, -- SurfaceAppearance is MeshPart-only
	decorativeLightRange: number, -- studs; decorative PointLights beyond this are disabled
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
		decorativeLightRange = 40,
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
		decorativeLightRange = 60,
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
		decorativeLightRange = 10000, -- effectively unlimited; a finite value stays serialisable
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
}

--------------------------------------------------------------------------------
-- The reference device and the budgets.
--
-- ⚠️ NOT YET CHOSEN. Every measurement in docs/systems/performance depends on these, and
-- until they are set, "is this fast enough?" has no answer. Choosing them is the FIRST
-- item of build group 03, not an implied prerequisite.
--------------------------------------------------------------------------------

Quality.BUDGET = {
	CHOSEN = false,
	REFERENCE_DEVICE = nil :: string?,
	TARGET_FRAME_MS = 33.3, -- 30fps; the floor the design assumes
	MAX_CLIENT_MEMORY_MB = nil :: number?,
	MAX_DRAW_CALLS = nil :: number?,
	MAX_SHADOW_CASTING_LIGHTS = 8, -- from the style skill; not yet verified on device
}

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
