--!strict
--[[
	Config/Economy — the pinch, upgrade costs, and Overclock.

	The whole economy exists to keep ONE question live:

	    Do I spend this scrap on myself, or on keeping my robot alive?

	If repair is ever obviously correct or obviously wrong, the pinch is dead and the loop
	stops repeating.

	Sources: docs/systems/economy/README.md · decision 0013 · spec §48, §53, §62, §79
]]

local Zones = require(script.Parent.Zones)
local Magnet = require(script.Parent.Magnet)

local Economy = {}

--------------------------------------------------------------------------------
-- The pinch. The spec's worked example (§48) is the anchor:
--     150 scrap  ->  3,600 Coins   OR   +900 robot HP
--------------------------------------------------------------------------------

Economy.RECYCLE = {
	COINS_PER_SCRAP = 24, -- 150 * 24 = 3,600  (§48, exact)
	DEATH_PENALTY = 0.5, -- [UNTUNED] auto-recycle on death/disconnect pays half
}

Economy.REPAIR = {
	HP_PER_SCRAP = 6, -- 150 * 6 = 900  (§48, exact)
}

--- The two exits must always be shown together, with real numbers, and neither
--- pre-selected. This function exists so the GUI cannot drift from the config.
function Economy.previewChoice(scrap: number): (number, number)
	return scrap * Economy.RECYCLE.COINS_PER_SCRAP, scrap * Economy.REPAIR.HP_PER_SCRAP
end

--------------------------------------------------------------------------------
-- Upgrade curves.
--
-- Magnet Power gates zones, so ITS curve IS the pacing curve.
--
-- Power grows GEOMETRICALLY per level rather than by a fixed +5 step. A fixed step needs
-- (1500-10)/5 = 298 purchases to clear zone 12, and any cost curve steep enough to pace
-- the early game then explodes: the shipped-and-rejected 45 * 1.55^level reached 4.3e58
-- coins, i.e. the game could not be finished. `Economy.audit()` now proves this can't
-- silently return, and Bootstrap calls it at startup.
--
-- [UNTUNED] Every number below is a first pass. `Economy.TUNED` stays false until a
-- playtest validates the four constraints listed further down.
--------------------------------------------------------------------------------

Economy.UPGRADE = {
	POWER_GROWTH = 1.06, -- Magnet Power multiplier per level
	POWER_COST_BASE = 45,
	POWER_COST_GROWTH = 1.115,

	RADIUS_GROWTH = 1.035,
	RADIUS_COST_BASE = 60,
	RADIUS_COST_GROWTH = 1.10,

	DRIVE_STEP = 0.4, -- studs/sec per level; Drive is additive and deliberately shallow
	DRIVE_COST_BASE = 80,
	DRIVE_COST_GROWTH = 1.13,

	CAPACITY_GROWTH = 1.05,
	CAPACITY_COST_BASE = 35,
	CAPACITY_COST_GROWTH = 1.09,

	MAX_LEVEL = 400, -- hard stop, so no loop over these curves can run away
}

local U = Economy.UPGRADE

function Economy.powerAtLevel(level: number): number
	return math.floor(Magnet.START.Power * (U.POWER_GROWTH ^ math.max(0, level)) + 0.5)
end
function Economy.radiusAtLevel(level: number): number
	return Magnet.START.Radius * (U.RADIUS_GROWTH ^ math.max(0, level))
end
function Economy.driveAtLevel(level: number): number
	return Magnet.START.Drive + U.DRIVE_STEP * math.max(0, level)
end
function Economy.capacityAtLevel(level: number): number
	return math.floor(Magnet.START.Capacity * (U.CAPACITY_GROWTH ^ math.max(0, level)) + 0.5)
end

function Economy.powerCost(level: number): number
	return math.floor(U.POWER_COST_BASE * (U.POWER_COST_GROWTH ^ math.max(0, level)))
end
function Economy.radiusCost(level: number): number
	return math.floor(U.RADIUS_COST_BASE * (U.RADIUS_COST_GROWTH ^ math.max(0, level)))
end
function Economy.driveCost(level: number): number
	return math.floor(U.DRIVE_COST_BASE * (U.DRIVE_COST_GROWTH ^ math.max(0, level)))
end
function Economy.capacityCost(level: number): number
	return math.floor(U.CAPACITY_COST_BASE * (U.CAPACITY_COST_GROWTH ^ math.max(0, level)))
end

--------------------------------------------------------------------------------
-- Balance constraints, in priority order. These are ACCEPTANCE CRITERIA, and
-- `Economy.audit()` mechanises the two that can be checked without a playtest.
--
--   1. The first upgrade is affordable within ~2 minutes of first play.
--   2. Every zone is reachable by SWEEPING ALONE, with no Arena income.
--   3. Repairing is always a tempting alternative to upgrading.
--   4. Recycling a duplicate Legendary feels like a windfall.
--------------------------------------------------------------------------------

Economy.TUNED = false -- no playtest has validated any of the above

--- Coins and purchases needed to take Magnet Power from the start to `targetPower`.
--- Returns (coins, purchases, reachable).
function Economy.coinsToReachPower(targetPower: number): (number, number, boolean)
	local total, level = 0, 0
	while Economy.powerAtLevel(level) < targetPower do
		if level >= U.MAX_LEVEL then
			return total, level, false
		end
		total += Economy.powerCost(level)
		level += 1
	end
	return total, level, true
end

function Economy.coinsToReachTier(tier: number): (number, number, boolean)
	local zone = Zones.byTier(tier)
	if not zone then
		return 0, 0, false
	end
	return Economy.coinsToReachPower(zone.gate)
end

--- The affordability ceiling for constraint 2. Coins beyond this cannot plausibly be
--- swept in a human lifetime, so exceeding it means the curve is broken, not merely slow.
Economy.MAX_REASONABLE_COINS = 5e8

--- Machine-checkable half of the balance constraints. Bootstrap calls this at startup so
--- a broken curve fails on day one rather than at zone 12.
function Economy.audit(): { string }
	local problems = {}

	local firstCost = Economy.powerCost(0)
	if firstCost > 600 then
		table.insert(problems, ("first Power upgrade costs %d coins -- too steep for constraint 1"):format(firstCost))
	end

	local coins, purchases, reachable = Economy.coinsToReachTier(12)
	if not reachable then
		table.insert(problems, ("zone 12 is UNREACHABLE: Power caps out below its gate within %d levels"):format(U.MAX_LEVEL))
	elseif coins > Economy.MAX_REASONABLE_COINS then
		table.insert(problems, ("zone 12 costs %.3g coins (%d purchases) -- constraint 2 fails"):format(coins, purchases))
	end

	if not Economy.TUNED then
		table.insert(problems, "[UNTUNED] economy values have not been validated by a playtest")
	end
	return problems
end

--------------------------------------------------------------------------------
-- Duplicate rare parts (§40): a third fork, alongside install and reinforce.
-- [UNTUNED] The spec gives no numbers; these are a first pass.
--------------------------------------------------------------------------------

Economy.PART_RECYCLE_COINS = {
	Common = 400,
	Uncommon = 1200,
	Rare = 4000,
	Epic = 14000,
	Legendary = 45000,
	Mythic = 150000,
}

--------------------------------------------------------------------------------
-- Overclock (decision 0013). NOT a rebirth: the robot survives.
--
-- §79 resets exactly four things: zone access, Coins, MAGNET UPGRADE LEVELS, Drive
-- upgrades. "Magnet upgrade levels" covers BOTH Power and Radius -- they are the two
-- magnet stats. Capacity is not named by §79 and is therefore kept; that reading is
-- decision 0013's, and changing it needs a new record rather than an edit here.
--------------------------------------------------------------------------------

Economy.OVERCLOCK = {
	RESETS = { "zoneAccess", "coins", "magnetPowerLevel", "magnetRadiusLevel", "driveLevel" },
	KEEPS = { "capacityLevel", "robotParts", "archive", "cosmetics", "arenaStats", "robotName" },

	MIN_TIER_TO_OVERCLOCK = 12, -- [DERIVED] §79 does not say; zone 12 is the natural gate
	STARTING_POWER_PER_LEVEL = 25, -- [UNTUNED]
	GATE_DISCOUNT_PER_LEVEL = 0.08, -- [UNTUNED] 8% off every gate, per Core Level
	GATE_DISCOUNT_CAP = 0.60, -- never trivialise zone 12
}

--- Every stat must appear in exactly one of RESETS/KEEPS. A stat in neither is undefined
--- at Overclock, which is how `radiusLevel` was silently dropped in the first draft.
Economy.ALL_PROGRESSION_KEYS = {
	"zoneAccess",
	"coins",
	"magnetPowerLevel",
	"magnetRadiusLevel",
	"driveLevel",
	"capacityLevel",
	"robotParts",
	"archive",
	"cosmetics",
	"arenaStats",
	"robotName",
}

function Economy.auditOverclock(): { string }
	local problems = {}
	local seen: { [string]: number } = {}
	for _, k in ipairs(Economy.OVERCLOCK.RESETS) do
		seen[k] = (seen[k] or 0) + 1
	end
	for _, k in ipairs(Economy.OVERCLOCK.KEEPS) do
		seen[k] = (seen[k] or 0) + 1
	end
	for _, k in ipairs(Economy.ALL_PROGRESSION_KEYS) do
		local n = seen[k] or 0
		if n == 0 then
			table.insert(problems, ("Overclock: %q is in neither RESETS nor KEEPS -- undefined"):format(k))
		elseif n > 1 then
			table.insert(problems, ("Overclock: %q appears in both RESETS and KEEPS"):format(k))
		end
		seen[k] = nil
	end
	for k in pairs(seen) do
		table.insert(problems, ("Overclock: %q is not a known progression key"):format(k))
	end
	return problems
end

--- Effective gate requirement for a player at a given Magnet Core Level.
function Economy.gateFor(tier: number, coreLevel: number): number
	local zone = Zones.byTier(tier)
	if not zone then
		return math.huge
	end
	local discount = math.min(
		Economy.OVERCLOCK.GATE_DISCOUNT_CAP,
		Economy.OVERCLOCK.GATE_DISCOUNT_PER_LEVEL * math.max(0, coreLevel)
	)
	return math.floor(zone.gate * (1 - discount))
end

return Economy
