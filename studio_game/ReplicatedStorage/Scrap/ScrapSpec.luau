--!strict
--[[
	ScrapSpec — the ordinary collectable objects, as data.

	Tier 1 (Color Workshop) only: screws, nuts, washers, bolts, gears, springs, metal beads,
	small pipes -- the spec's §26 list, verbatim. Later tiers add their own sets.

	`weight` is what the magnet checks against Magnet Power. It is a DESIGN number, not a
	physical mass: the part's real mass is irrelevant and deliberately so, exactly as robot
	parts are Massless (decision 0004). A screw weighing 2 and a pipe weighing 12 is a
	gameplay statement, not a physics one.

	`sound` names a family from §15. Nine families, and every object belongs to one.

	Sources: docs/systems/scrap/README.md · spec §15, §26 · decision 0005
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MaterialKit = require(ReplicatedStorage:WaitForChild("MaterialKit"))

export type SoundFamily = "Bolt" | "Coin" | "Gear" | "Spring" | "Tool" | "Barrel" | "Vehicle" | "Machine" | "Rare"

export type ScrapDef = {
	id: string,
	name: string,
	tier: number,
	weight: number, -- checked against Magnet Power. A design number, never a mass.
	value: number, -- scrap units added to Capacity
	size: { number },
	shape: string?, -- "Ball" | "Cylinder"; default Block
	along: string?, -- Cylinder axis, same convention as the kit
	surface: MaterialKit.Surface,
	color: string?,
	sound: SoundFamily,
	weightShare: number, -- relative spawn frequency within the tier
}

local ScrapSpec = {}

ScrapSpec.TIER1 = {
	{
		id = "SCREW", name = "Screw", tier = 1, weight = 2, value = 1,
		size = { 0.9, 0.3, 0.3 }, shape = "Cylinder", along = "X",
		surface = "SteelBrushed", sound = "Bolt", weightShare = 26,
	},
	{
		id = "NUT", name = "Nut", tier = 1, weight = 3, value = 1,
		size = { 0.7, 0.7, 0.35 },
		surface = "SteelBrushed", sound = "Bolt", weightShare = 22,
	},
	{
		id = "WASHER", name = "Washer", tier = 1, weight = 2, value = 1,
		size = { 0.8, 0.15, 0.8 }, shape = "Cylinder", along = "Y",
		surface = "Chrome", sound = "Coin", weightShare = 18,
	},
	{
		id = "BOLT", name = "Bolt", tier = 1, weight = 4, value = 2,
		size = { 1.4, 0.4, 0.4 }, shape = "Cylinder", along = "X",
		surface = "SteelBrushed", sound = "Bolt", weightShare = 16,
	},
	{
		id = "GEAR", name = "Gear", tier = 1, weight = 6, value = 3,
		size = { 1.6, 0.3, 1.6 }, shape = "Cylinder", along = "Y",
		surface = "SteelDark", sound = "Gear", weightShare = 9,
	},
	{
		id = "SPRING", name = "Spring", tier = 1, weight = 5, value = 3,
		size = { 0.5, 1.4, 0.5 }, shape = "Cylinder", along = "Y",
		surface = "Chrome", sound = "Spring", weightShare = 5,
	},
	{
		id = "BEAD", name = "Metal Bead", tier = 1, weight = 1, value = 1,
		size = { 0.6, 0.6, 0.6 }, shape = "Ball",
		surface = "Chrome", sound = "Coin", weightShare = 3,
	},
	{
		id = "PIPE", name = "Small Pipe", tier = 1, weight = 12, value = 5,
		size = { 3, 0.7, 0.7 }, shape = "Cylinder", along = "X",
		surface = "Rust", sound = "Tool", weightShare = 1,
	},
} :: { ScrapDef }

--------------------------------------------------------------------------------

local byId: { [string]: ScrapDef } = {}
local totalShare = 0
for _, d in ipairs(ScrapSpec.TIER1) do
	byId[d.id] = d
	totalShare += d.weightShare
end

function ScrapSpec.byId(id: string): ScrapDef?
	return byId[id]
end

--- Weighted pick from a tier's pool. `rng` is passed in so a seeded run is reproducible --
--- a randomised game whose bugs cannot be reproduced is a game that cannot be fixed.
function ScrapSpec.pick(rng: Random): ScrapDef
	local roll = rng:NextNumber() * totalShare
	local acc = 0
	for _, d in ipairs(ScrapSpec.TIER1) do
		acc += d.weightShare
		if roll <= acc then
			return d
		end
	end
	return ScrapSpec.TIER1[1]
end

--- Heaviest object in the tier, so a spawner can tell whether a player can clear the field
--- at all. Tier 1's PIPE at 12 is above the starter magnet's Power 10 ON PURPOSE: the very
--- first thing the player cannot lift is visible from the start.
function ScrapSpec.heaviest(): ScrapDef
	local best = ScrapSpec.TIER1[1]
	for _, d in ipairs(ScrapSpec.TIER1) do
		if d.weight > best.weight then
			best = d
		end
	end
	return best
end

return ScrapSpec
