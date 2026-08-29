--!strict
--[[
	Config/Zones — the twelve tiers, their Magnet Power gates, guardians and Service Hubs.

	The factory is ONE continuous corridor (decision 0003). Zones talk to the zone manager,
	never to each other -- under streaming a cross-zone reference is a nil index, not a smell.

	Sources: docs/content/zones/README.md · docs/systems/factory/README.md
	         decision 0003 · decision 0006 · spec §17-§20, §25-§37, §61, §62
]]

export type Zone = {
	tier: number,
	id: string,
	name: string,
	gate: number, -- Magnet Power required to open the gate INTO this zone
	guardian: string,
	hubAfter: boolean, -- is there a Service Hub at this zone's exit?
}

local Zones = {}

--------------------------------------------------------------------------------
-- The power curve is the pacing curve: it is what gates progress, so Coin costs in
-- Config/Economy must be set against THIS, not independently.
--
-- Values are the spec's §62 initial balancing targets. They rise ~x1.5 per zone and
-- MUST be playtested.
--------------------------------------------------------------------------------

Zones.LIST = {
	{ tier = 1, id = "COLOR_WORKSHOP", name = "Color Workshop", gate = 10, guardian = "Slow Scrap Sweeper Bot", hubAfter = false },
	{ tier = 2, id = "TOY_ASSEMBLY", name = "Toy Assembly", gate = 20, guardian = "Wind-Up Security Bot", hubAfter = true },
	{ tier = 3, id = "MEGA_KITCHEN", name = "Mega Kitchen", gate = 35, guardian = "Chef Security Bot", hubAfter = false },
	{ tier = 4, id = "WAREHOUSE", name = "Warehouse", gate = 55, guardian = "Security Forklift", hubAfter = true },
	{ tier = 5, id = "CITY_STORAGE", name = "City Storage", gate = 85, guardian = "Security Patrol Cart", hubAfter = false },
	{ tier = 6, id = "VEHICLE_WORKSHOP", name = "Vehicle Workshop", gate = 130, guardian = "Security Motorcycle", hubAfter = true },
	{ tier = 7, id = "CAR_FACTORY", name = "Car Factory", gate = 200, guardian = "Autonomous Security Car", hubAfter = false },
	{ tier = 8, id = "HEAVY_YARD", name = "Heavy Yard", gate = 300, guardian = "Autonomous Bulldozer", hubAfter = true },
	{ tier = 9, id = "POWER_PLANT", name = "Power Plant", gate = 450, guardian = "Electrical Sentinel", hubAfter = false },
	{ tier = 10, id = "ROBOT_LABORATORY", name = "Robot Laboratory", gate = 675, guardian = "Prototype Combat Robot", hubAfter = true },
	{ tier = 11, id = "SPACE_FOUNDRY", name = "Space Foundry", gate = 1000, guardian = "Orbital Defense Drone", hubAfter = false },
	{ tier = 12, id = "QUANTUM_REACTOR", name = "Quantum Reactor", gate = 1500, guardian = "Quantum Warden", hubAfter = true },
} :: { Zone }

Zones.MVP_TIERS = 2 -- zones 1-2 plus one hub is the MVP (roadmap/mvp.md)

local byTier: { [number]: Zone } = {}
local byId: { [string]: Zone } = {}
for _, z in ipairs(Zones.LIST) do
	byTier[z.tier] = z
	byId[z.id] = z
end

function Zones.byTier(tier: number): Zone?
	return byTier[tier]
end

function Zones.byId(id: string): Zone?
	return byId[id]
end

--- Highest tier a player with this Magnet Power may enter.
function Zones.highestUnlocked(power: number): number
	local best = 0
	for _, z in ipairs(Zones.LIST) do
		if power >= z.gate then
			best = z.tier
		end
	end
	return best
end

--- The Service Hub a player retreats to from `tier` — the nearest hub at or before it.
--- Returns 0 for "the Workshop", which is always the fallback.
function Zones.hubTierFor(tier: number): number
	for t = tier, 1, -1 do
		local z = byTier[t]
		if z and z.hubAfter then
			return t
		end
	end
	return 0
end

--------------------------------------------------------------------------------
-- The three refresh cycles (decision 0006). All three ship in the MVP: building on
-- static spawns bakes in assumptions the refresh then breaks.
--------------------------------------------------------------------------------

Zones.REFRESH = {
	SCRAP_MIN = 30, -- seconds
	SCRAP_MAX = 60,
	CYCLE_PERIOD = 240, -- ~4 min: rare parts re-roll
	CYCLE_WARNING = 20, -- seconds of warning before the cycle fires
	SHIFT_PERIOD = 720, -- ~12 min: server-wide modifier changes
}

--- The warning must be audible and visible from anywhere in the zone, including while
--- running. A refresh that silently eats a part the player was walking toward reads as a
--- bug, not a rule.
Zones.SHIFTS = { "HEAVY", "ELECTRIC", "GOLD", "SECURITY", "CHAOS" }

--------------------------------------------------------------------------------
-- Rare-part spawn shape per refresh (§20). Each zone owns a pool of 8; a refresh spawns
-- only some of them, re-weighted by the active Shift.
--------------------------------------------------------------------------------

--- How many parts a refresh spawns. [UNTUNED]
--- Deliberately expressed as a COUNT plus a bonus roll, not as fixed rarities: decision
--- 0015 bands rarity PER TIER, and tiers 10-12 contain no Common parts at all. Asking for
--- "2 Commons" would be unsatisfiable in the Quantum Reactor.
Zones.SPAWN_PER_CYCLE = {
	COUNT = 3, -- parts spawned per Factory Cycle
	BONUS_ROLL_CHANCE = 0.35, -- chance of one extra, rolled one band higher
}

--- Relative weights WITHIN a tier's own band (decision 0015). A rarity absent from a
--- tier's band is simply never rolled there -- the weight table does not need to know
--- which tier it is being used for, but the CALLER must pass only that tier's available
--- rarities.
Zones.RARITY_WEIGHT = {
	Common = 100,
	Uncommon = 55,
	Rare = 22,
	Epic = 7,
	Legendary = 2,
	Mythic = 0.4,
}

--- The rarities decision 0015 makes available in each tier. A roll must draw only from
--- this set, or it will ask for a grade the tier does not contain.
local function band(...): { string }
	return { ... }
end

Zones.TIER_RARITIES = {
	band("Common", "Uncommon", "Rare", "Legendary"), -- 1
	band("Common", "Uncommon", "Rare", "Legendary"), -- 2
	band("Common", "Uncommon", "Rare", "Legendary"), -- 3
	band("Common", "Uncommon", "Rare", "Legendary"), -- 4
	band("Common", "Uncommon", "Rare", "Legendary"), -- 5
	band("Common", "Uncommon", "Rare", "Legendary"), -- 6
	band("Common", "Uncommon", "Rare", "Epic", "Legendary"), -- 7
	band("Common", "Uncommon", "Rare", "Epic", "Legendary"), -- 8
	band("Common", "Uncommon", "Rare", "Epic", "Legendary"), -- 9
	band("Uncommon", "Rare", "Epic", "Legendary"), -- 10  (no Common)
	band("Uncommon", "Rare", "Epic", "Legendary"), -- 11  (no Common)
	band("Uncommon", "Rare", "Epic", "Mythic"), -- 12  (no Common, no Legendary)
}

--- Rarities available in a tier. Empty for an unknown tier, never nil.
function Zones.raritiesFor(tier: number): { string }
	return Zones.TIER_RARITIES[tier] or {}
end

return Zones
