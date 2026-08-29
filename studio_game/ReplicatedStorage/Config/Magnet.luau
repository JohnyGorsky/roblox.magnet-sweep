--!strict
--[[
	Config/Magnet — the four player stats, the pull model, Flow, and the physics budget.

	The magnet is the game's verb. Everything here is tunable without touching gameplay code
	(non-negotiable #4, config-first).

	Sources: docs/systems/magnet/README.md · decision 0005 (four-state scrap budget)
	         decision 0012 (mobile-first quality tiers) · spec §11, §16, §63
]]

export type WeightClass = "Small" | "Medium" | "Heavy" | "Extreme"

local Magnet = {}

--------------------------------------------------------------------------------
-- The four stats. Starting values are the spec's Starter Magnet (§9).
--------------------------------------------------------------------------------

Magnet.START = {
	Power = 10, -- max liftable weight; the gate stat
	Radius = 12, -- PULL radius in studs
	Drive = 16, -- walkspeed, studs/sec
	Capacity = 30, -- ordinary scrap carried
}

-- Endgame targets, for sanity-checking upgrade curves. Not enforced.
Magnet.ENDGAME = {
	Power = 1500, -- must clear the zone 12 gate
	Drive = 36, -- §63: 34-36+ before endgame modifiers
}

--------------------------------------------------------------------------------
-- Pull model: strain, then refuse.
--
--   ratio = objectWeight / playerPower
--
--   ratio <= EASY_RATIO      full speed, snappy. This is most of the sweep.
--   EASY..1.0                slows toward STRAIN_MIN_SPEED, arcs and strain audio rise.
--   ratio >  1.0             REFUSE: the object shakes, sparks and never breaks free.
--
-- The third band is why this is a curve with a wall rather than a step: a hard step with
-- no reaction reads as scenery or as a bug, and a pure curve dissolves the Power gate.
--------------------------------------------------------------------------------

Magnet.PULL = {
	EASY_RATIO = 0.35, -- at or below this, no speed penalty at all
	STRAIN_MIN_SPEED = 0.25, -- speed multiplier as ratio approaches 1.0
	BASE_SPEED = 55, -- studs/sec an unladen object travels toward the magnet
	ARRIVE_RADIUS = 2.5, -- distance at which an object counts as collected
	REFUSE_SHAKE_STUDS = 0.35, -- visible shake amplitude when over Power
}

--- Speed multiplier for an object of `weight` against a player's `power`.
--- Returns 0 when the object is too heavy — the caller must then play the REFUSE state.
function Magnet.pullSpeedMultiplier(weight: number, power: number): number
	if power <= 0 then
		return 0
	end
	local ratio = weight / power
	if ratio > 1 then
		return 0 -- refuse
	end
	if ratio <= Magnet.PULL.EASY_RATIO then
		return 1
	end
	-- linear falloff from full speed at EASY_RATIO down to STRAIN_MIN_SPEED at 1.0
	local t = (ratio - Magnet.PULL.EASY_RATIO) / (1 - Magnet.PULL.EASY_RATIO)
	return 1 - t * (1 - Magnet.PULL.STRAIN_MIN_SPEED)
end

--------------------------------------------------------------------------------
-- Radius: upgrading grows BOTH ranges, with REACT wider than PULL.
--
-- Objects shake and spark before they are in collection range, so the field reads bigger
-- than it is and the player can see their reach arriving. REACT is the cheap state
-- (decision 0005), so the spectacle costs almost nothing.
--------------------------------------------------------------------------------

Magnet.REACT_RADIUS_MULTIPLIER = 1.4

function Magnet.reactRadius(radius: number): number
	return radius * Magnet.REACT_RADIUS_MULTIPLIER
end

--------------------------------------------------------------------------------
-- Magnet Flow — the combo. x1..x5, then MAGNET RUSH.
--------------------------------------------------------------------------------

Magnet.FLOW = {
	MAX_TIER = 5,
	PICKUPS_PER_TIER = 8, -- collections needed to advance one tier
	DECAY_AFTER = 3.0, -- seconds without a pickup before decay starts
	DECAY_PER_SECOND = 1.5, -- pickups-worth of progress lost per second
	COIN_MULTIPLIER = { 1.0, 1.15, 1.30, 1.50, 1.75, 2.25 }, -- index = tier + 1 (tier 0 = no flow)
	PULL_SPEED_BONUS = { 1.0, 1.03, 1.06, 1.10, 1.15, 1.25 },
	PITCH_PER_TIER = 0.06, -- collection sound pitch rise per tier
}

Magnet.RUSH = {
	DURATION = 8.0, -- seconds of MAGNET RUSH once tier 5 is reached
	RADIUS_MULTIPLIER = 1.6,
	PULL_CAP_MULTIPLIER = 1.5, -- raises MaxConcurrentPull, modestly (decision 0005)
}

--------------------------------------------------------------------------------
-- The physics budget. Decision 0005: only PULL costs physics, and it is CAPPED.
--
-- These are STARTING VALUES, not measurements. The real numbers come from the Device
-- Emulator on the reference device, and the check is a COUNT of unanchored parts during a
-- Rush -- never a reading of this table.
--------------------------------------------------------------------------------

--- ⚠️ SINGLE SOURCE OF TRUTH for decision 0005's cap. Config/Quality reads THIS table --
--- it does not carry its own copy. Two copies of one hard limit is how the check
--- ("count unanchored parts during a Rush") ends up measured against the wrong number.
Magnet.MAX_CONCURRENT_PULL = {
	Low = 40, -- [UNTUNED] phone floor
	Medium = 80,
	High = 160,
}

Magnet.POOL = {
	INITIAL_SIZE = 400, -- pre-allocated scrap instances per zone
	GROW_BY = 50, -- if the pool is exhausted, allocate this many more
	MAX_SIZE = 1200, -- hard ceiling; beyond this, spawns are skipped
}

--------------------------------------------------------------------------------
-- Rare cargo weight classes and their speed penalties (§12).
-- A floor is applied so an Extreme part is tense, never punishing.
--------------------------------------------------------------------------------

Magnet.CARGO_SPEED_PENALTY = {
	Small = 0.05,
	Medium = 0.15,
	Heavy = 0.25,
	Extreme = 0.45,
} :: { [WeightClass]: number }

Magnet.CARGO_MIN_SPEED = 9 -- studs/sec. Never slower than this, whatever the cargo.

--- Walkspeed while carrying a rare part of the given class.
function Magnet.carrySpeed(drive: number, class: WeightClass): number
	local penalty = Magnet.CARGO_SPEED_PENALTY[class] or 0
	return math.max(Magnet.CARGO_MIN_SPEED, drive * (1 - penalty))
end

--------------------------------------------------------------------------------
-- Server-side anti-exploit. Decision 0002: the client renders, the server grants.
--------------------------------------------------------------------------------

--- The per-batch ceiling must survive a MAGNET RUSH on the HIGHEST tier, or the game's
--- signature moment trips its own anti-cheat and logs honest players as exploiters.
---
--- Worst case: High cap 160 * RUSH.PULL_CAP_MULTIPLIER 1.5 = 240 concurrent pulls. At
--- BASE_SPEED 55 over a rushed radius, transit is ~0.3s, so ~800 completions/sec, i.e.
--- ~200 per 0.25s TICK. `Magnet.maxGrantPerTick()` derives the ceiling instead of
--- hardcoding one, and Bootstrap asserts it.
Magnet.GRANT = {
	TICK = 0.25, -- seconds; collections are batched, never one remote per object
	SAFETY_FACTOR = 1.5, -- headroom over the theoretical maximum
	MIN_TRANSIT = 0.25, -- seconds; floor on assumed travel time, so the maths can't divide by ~0
	MAX_RANGE_SLACK = 1.35, -- claimed collections beyond radius * this are rejected
}

--- Largest honest batch size on the given tier. Anything above this is rejected.
function Magnet.maxGrantPerTick(tierName: string): number
	local cap = Magnet.MAX_CONCURRENT_PULL[tierName] or Magnet.MAX_CONCURRENT_PULL.High
	local concurrent = cap * Magnet.RUSH.PULL_CAP_MULTIPLIER
	local perSecond = concurrent / Magnet.GRANT.MIN_TRANSIT
	return math.ceil(perSecond * Magnet.GRANT.TICK * Magnet.GRANT.SAFETY_FACTOR)
end

return Magnet
