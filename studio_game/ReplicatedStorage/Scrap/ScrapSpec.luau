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


--- 🔴 SIZES ARE 2.5x THE ORIGINAL SPEC, changed 2026-09-05 after standing them in the demo room
--- next to a player. At spec size four of the twelve were UNDER ONE STUD -- 12-18% of a 5-stud
--- character -- and read as specks on an empty pedestal from three paces away. A collectable the
--- player cannot see is a core loop the player cannot read.
---
--- ⚠️ Only `size` moved. `weight`, `value` and `weightShare` are untouched, so the gameplay ladder
--- and the economy are exactly as they were -- this is a readability change, not a balance one.
local ScrapSpec = {}

ScrapSpec.TIER1 = {
	{
		id = "SCREW", name = "Screw", tier = 1, weight = 2, value = 1,
		size = { 2.25, 0.75, 0.75 }, shape = "Cylinder", along = "X",
		surface = "SteelBrushed", sound = "Bolt", weightShare = 26,
	},
	{
		id = "NUT", name = "Nut", tier = 1, weight = 3, value = 1,
		size = { 1.75, 1.75, 0.875 },
		surface = "SteelBrushed", sound = "Bolt", weightShare = 22,
	},
	{
		id = "WASHER", name = "Washer", tier = 1, weight = 2, value = 1,
		size = { 2, 0.375, 2 }, shape = "Cylinder", along = "Y",
		surface = "Chrome", sound = "Coin", weightShare = 18,
	},
	{
		id = "BOLT", name = "Bolt", tier = 1, weight = 4, value = 2,
		size = { 3.5, 1, 1 }, shape = "Cylinder", along = "X",
		surface = "SteelBrushed", sound = "Bolt", weightShare = 16,
	},
	{
		id = "GEAR", name = "Gear", tier = 1, weight = 6, value = 3,
		size = { 4, 0.75, 4 }, shape = "Cylinder", along = "Y",
		surface = "SteelDark", sound = "Gear", weightShare = 9,
	},
	{
		id = "SPRING", name = "Spring", tier = 1, weight = 5, value = 3,
		size = { 1.25, 3.5, 1.25 }, shape = "Cylinder", along = "Y",
		surface = "Chrome", sound = "Spring", weightShare = 5,
	},
	{
		id = "BEAD", name = "Metal Bead", tier = 1, weight = 1, value = 1,
		size = { 1.5, 1.5, 1.5 }, shape = "Ball",
		surface = "Chrome", sound = "Coin", weightShare = 3,
	},
	{
		id = "PIPE", name = "Small Pipe", tier = 1, weight = 12, value = 5,
		--- ⚠️ CHUNKY, not long. The generated mesh is a short flanged section roughly 1:1:1, so the
		--- old 7.5 x 1.75 x 1.75 would have stretched it into a smear. Owner's call 2026-09-05:
		--- keep the mesh and place SEVERAL pipes rather than one long one. Size matches the mesh.
		size = { 3.5, 3.5, 3.4 },
		surface = "Rust", sound = "Tool", weightShare = 1,
	},
} :: { ScrapDef }

--------------------------------------------------------------------------------
-- Tier 2 — TOY ASSEMBLY. "Colorful toy manufacturing."
--------------------------------------------------------------------------------

--- `docs/content/zones` tier 2: *"toy cars, wind-up mechanisms, metal blocks, toy robots, springs"*.
---
--- ⚠️ **Springs are NOT redefined here.** `SPRING` already exists at tier 1 and tier 2's list names
--- springs too; writing a second Spring would be two ids for one object and a second source of truth
--- for its weight. `POOL` below composes tier 2 out of four new types **plus** the shared spring, so
--- the game has one Spring and two zones that both spawn it.
---
--- 🔴 Weights step up past tier 1's ceiling on purpose. Tier 1's heaviest is `PIPE` at 12 against a
--- starter Power of 10 — the first thing you visibly cannot lift. Tier 2's `TOY_ROBOT` at 26 is the
--- same idea one gate later: zone 2 opens at Power 20, so its heaviest object is still out of reach
--- when you first walk in.
ScrapSpec.TIER2 = {
	{
		id = "BLOCK", name = "Metal Block", tier = 2, weight = 8, value = 4,
		size = { 2.75, 2.75, 2.75 },
		surface = "PaintedGloss", color = "#2F6BE8", sound = "Tool", weightShare = 30,
	},
	{
		id = "WINDUP", name = "Wind-Up Mechanism", tier = 2, weight = 11, value = 6,
		size = { 3, 1.25, 3 }, shape = "Cylinder", along = "Y",
		surface = "Chrome", sound = "Gear", weightShare = 24,
	},
	{
		id = "TOY_CAR", name = "Toy Car", tier = 2, weight = 16, value = 9,
		size = { 6, 2.25, 3 },
		surface = "PaintedGloss", color = "#FF8A6B", sound = "Vehicle", weightShare = 16,
	},
	{
		id = "TOY_ROBOT", name = "Toy Robot", tier = 2, weight = 26, value = 15,
		size = { 3, 5, 2.25 },
		surface = "PaintedWorn", color = "#8FD63F", sound = "Machine", weightShare = 8,
	},
} :: { ScrapDef }

--------------------------------------------------------------------------------

--- Every tier's spawn pool. 🔴 The composition lives HERE rather than being implied by the `tier`
--- field, because tier 2 deliberately re-uses tier 1's `SPRING` — a rule "everything whose tier
--- field equals N" could not express that and would silently drop it.
ScrapSpec.POOL = {
	[1] = ScrapSpec.TIER1,
	[2] = (function()
		local pool = table.clone(ScrapSpec.TIER2)
		for _, d in ipairs(ScrapSpec.TIER1) do
			if d.id == "SPRING" then
				table.insert(pool, d)
			end
		end
		return pool
	end)(),
}

local byId: { [string]: ScrapDef } = {}
local totalShare: { [number]: number } = {}
for tier, pool in pairs(ScrapSpec.POOL) do
	local sum = 0
	for _, d in ipairs(pool) do
		--- ⚠️ A duplicate id across tiers is a bug, not a feature — `byId` would silently keep
		--- whichever loaded last and every consumer would then disagree about that object's weight.
		if byId[d.id] and byId[d.id] ~= d then
			error(("ScrapSpec: duplicate id %q in more than one tier"):format(d.id), 0)
		end
		byId[d.id] = d
		sum += d.weightShare
	end
	totalShare[tier] = sum
end

function ScrapSpec.byId(id: string): ScrapDef?
	return byId[id]
end

function ScrapSpec.tiers(): number
	local n = 0
	for _ in pairs(ScrapSpec.POOL) do
		n += 1
	end
	return n
end

--- Weighted pick from a tier's pool. `rng` is passed in so a seeded run is reproducible --
--- a randomised game whose bugs cannot be reproduced is a game that cannot be fixed.
---
--- ⚠️ `tier` defaults to 1 so every existing call site keeps its behaviour. It was not a parameter
--- at all until job 018: `TIER1` was hardcoded in five places, which is why nothing could hold
--- tier-2 scrap until this changed.
function ScrapSpec.pick(rng: Random, tier: number?): ScrapDef
	local t = tier or 1
	local pool = ScrapSpec.POOL[t] or ScrapSpec.TIER1
	local roll = rng:NextNumber() * (totalShare[t] or totalShare[1])
	local acc = 0
	for _, d in ipairs(pool) do
		acc += d.weightShare
		if roll <= acc then
			return d
		end
	end
	return pool[1]
end

--- Heaviest object in a tier, so a spawner can tell whether a player can clear the field
--- at all. Tier 1's PIPE at 12 is above the starter magnet's Power 10 ON PURPOSE: the very
--- first thing the player cannot lift is visible from the start.
function ScrapSpec.heaviest(tier: number?): ScrapDef
	local pool = ScrapSpec.POOL[tier or 1] or ScrapSpec.TIER1
	local best = pool[1]
	for _, d in ipairs(pool) do
		if d.weight > best.weight then
			best = d
		end
	end
	return best
end

return ScrapSpec
