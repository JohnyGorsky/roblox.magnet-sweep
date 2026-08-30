--!strict
--[[
	WorkshopSpec — the Workshop hub, as DATA.

	The Workshop is the central safe hub (spec §8) and the proof of decision 0001: the Arena has to
	be physically visible from it, which is the whole reason this game is one place instead of two.

	🔴 WHY THIS FILE EXISTS AT ALL, rather than a room built by hand in Studio.

	`Workspace` **does not sync** (job 002, probed). Geometry placed by hand lives only inside the
	unversioned `.rbxl`: it cannot be diffed, cannot be reviewed, cannot be regenerated when a
	`MaterialVariant` changes, and is gone with the file. Decision 0017 already settled this for the
	industrial kit — the kit is data, the geometry is a build artifact — and the same reasoning
	applies to the room the kit builds.

	⚠️ This deliberately DIVERGES from how Jungle's lobby is built, where objects are hand-placed and
	scripts find them by name. That is right there and wrong here, and the reason is the sync layout
	rather than taste.

	**No hand-tweaking.** A part nudged in Studio is overwritten on the next build. The fix goes here.

	Sources: spec §8 · decisions 0001, 0017 · docs/build/05-workshop.md
	         .claude/skills/magnet-sweep-style/SKILL.md §2 (colour), §5 (signage)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KitSpec = require(ReplicatedStorage:WaitForChild("Kit", 20):WaitForChild("KitSpec", 20))

local WorkshopSpec = {}

local T = KitSpec.TILE -- 8
local G = KitSpec.GRID -- 4

--------------------------------------------------------------------------------
-- The room.
--------------------------------------------------------------------------------

--- 13 x 13 tiles = 104 x 104 studs, tile centres on multiples of 8 from -6 to +6.
---
--- ⚠️ ODD on purpose. With an even count there is no centre tile, so every station index would
--- name a corner rather than a centre and `stationPosition` would be off by half a tile -- the
--- kind of half-tile drift that is invisible in a spec and obvious once the room is standing.
---
--- Sized against the PARTS BUDGET, not by eye: `Perf.BUDGET.MAX_PARTS_IN_VIEW` is 1800 for "a
--- zone chunk plus the Workshop", and at one part per floor tile and one per wall segment this
--- room lands near 400. A 21 x 21 room would put the floor alone at 441 parts before a single
--- station existed.
WorkshopSpec.TILE_MIN = -6
WorkshopSpec.TILE_MAX = 6
WorkshopSpec.TILES_X = WorkshopSpec.TILE_MAX - WorkshopSpec.TILE_MIN + 1 -- 13
WorkshopSpec.TILES_Z = WorkshopSpec.TILES_X

WorkshopSpec.HALF_X = WorkshopSpec.TILES_X * T / 2 -- 52
WorkshopSpec.HALF_Z = WorkshopSpec.TILES_Z * T / 2 -- 52

--- Where the player arrives. Set back from the Arena aperture so the first thing framed by it is
--- the Arena, at distance -- §8 wants it visible from much of the Workshop, and the spawn is the
--- one camera position we can guarantee.
WorkshopSpec.SPAWN = Vector3.new(-16, 0, 0)

--- Roughly a standing character's eye. The sightline is cast from here, not from the floor, or it
--- would start inside the ground and hit it immediately -- a check that fails for the wrong reason
--- is as useless as one that passes for the wrong reason.
WorkshopSpec.EYE = 3

--- 🔴 THE CONTRACT WITH GROUP 10. The Arena is not built yet; this is where it goes, and the
--- sightline test fires at it. Group 10 places the Arena Core here rather than choosing its own
--- spot, because decision 0001's justification is precisely that these two are inter-visible.
---
--- ⚠️ This is a CONTRACT, not a placeholder: nothing is drawn here, and `validate()` fails if the
--- straight line from the spawn to this point is obstructed by the Workshop's own geometry.
WorkshopSpec.ARENA_ANCHOR = Vector3.new(240, 14, 0)

--- The gap in the east wall the Arena is seen through. A real ABSENCE of wall, not a window
--- piece: glass would defeat the raycast the sightline check depends on, and a check that passes
--- because it is measuring a pane of glass is no check at all.
---
--- Expressed in TILE INDICES along the east run (the same -6..+6 as everything else), inclusive.
--- Centred on z = 0 so the line from the spawn to `ARENA_ANCHOR` passes through the middle of it
--- rather than clipping an edge.
WorkshopSpec.APERTURE = { from = -1, to = 1 }

--------------------------------------------------------------------------------
-- The seven stations (§8).
--------------------------------------------------------------------------------

export type Station = {
	id: string,
	--- All caps, on the neon slab. No lore, no second line (ui-direction: three seconds).
	label: string,
	--- 🔴 A SIGNAL COLOUR, and each one owns exactly one meaning. `validate()` fails on a
	--- duplicate, because two stations sharing a colour destroys the thing the colour is for.
	color: string,
	--- Tile-grid position of the station's centre, in TILES from the room centre.
	tile: { number },
	--- Which way the sign faces, in degrees about Y. 0 faces +Z.
	facing: number,
	--- Extra kit pieces that dress this station, placed relative to its centre.
	dressing: { { piece: string, offset: { number }, rot: number? } }?,
	--- What it will DO. Nothing here builds behaviour -- that is job 013 -- but naming the owner
	--- means a station cannot quietly end up as scenery nobody wired.
	owner: string,
}

--- ⚠️ Every colour below is from the SIGNAL set and means exactly what it means everywhere else in
--- the game. A station may not borrow another's, and a kit piece may not wear one at all
--- (PITFALLS #39 — the colour language decays one green pipe at a time).
WorkshopSpec.STATIONS = {
	{
		id = "MagnetLab",
		label = "MAGNET LAB",
		color = "#41D8FF", -- magnet cyan: it IS the magnet
		tile = { -5, -3 },
		facing = 90, -- west wall, faces +X into the room
		owner = "job 013 — opens the upgrade panel built in job 011",
		dressing = {
			{ piece = "Ind_ControlPanel", offset = { 0, 0, -T }, rot = 90 },
			{ piece = "Ind_Generator", offset = { 0, 0, T * 1.5 }, rot = 90 },
		},
	},
	{
		id = "Recycler",
		label = "RECYCLER",
		color = "#3FD64B", -- recycler green: money IN, and nothing else is ever green
		tile = { -5, 3 },
		facing = 90,
		owner = "job 013 — RequestRecycle, still unbound",
		dressing = {
			{ piece = "Ind_Conveyor", offset = { 0, 0, T }, rot = 90 },
			{ piece = "Ind_Tank", offset = { 0, 0, -T * 1.5 }, rot = 90 },
		},
	},
	{
		id = "Repair",
		label = "REPAIR",
		color = "#FF7A1A", -- weld orange: repair and robot HP
		tile = { -2, 5 },
		facing = 180, -- south wall, faces -Z
		owner = "job 013 — RequestRepair, still unbound; needs a robot (group 09)",
		dressing = {
			{ piece = "Prop_RobotArm", offset = { -T, 0, 0 }, rot = 0 },
			{ piece = "Ind_PipeRun", offset = { T * 1.5, 0, 0 }, rot = 0 },
		},
	},
	{
		id = "RobotBay",
		label = "ROBOT BAY",
		-- ⚠️ Deliberately CHROME, not a signal colour. The robot is the point of the game, and the
		-- temptation is to give it the loudest sign in the room -- but every signal colour already
		-- means something, and inventing an eighth meaning is how the language starts to rot.
		color = "#B8C2CC",
		tile = { 2, 5 },
		facing = 180,
		owner = "group 09 — assembly; job 013 builds the shell",
		dressing = {
			{ piece = "Prop_RobotArm", offset = { T, 0, 0 }, rot = 180 },
			{ piece = "Struct_Platform", offset = { 0, 0, -T * 2 }, rot = 0 },
		},
	},
	{
		id = "PartArchive",
		label = "PART ARCHIVE",
		color = "#C46BFF", -- violet: the rarity ramp's own colour
		tile = { -2, -5 },
		facing = 0, -- north wall, faces +Z
		owner = "P1 — the wall's contents are not in this job",
		dressing = {
			{ piece = "Ind_ControlPanel", offset = { -T * 1.5, 0, 0 }, rot = 0 },
		},
	},
	{
		id = "FactoryEntrance",
		label = "FACTORY ENTRANCE",
		color = "#E03A2F", -- signal red: danger, and the only way out of the safe hub
		tile = { 3, -5 },
		facing = 0,
		owner = "group 07 — zones 1-2 attach here",
		dressing = {
			{ piece = "Struct_Gate", offset = { 0, 0, -T }, rot = 0 },
			{ piece = "Prop_Beacon", offset = { -T * 1.5, 0, 0 }, rot = 0 },
			{ piece = "Prop_Beacon", offset = { T * 1.5, 0, 0 }, rot = 0 },
		},
	},
	{
		id = "ScrapArena",
		label = "SCRAP ARENA",
		color = "#FFC21A", -- crown gold: Arena control
		tile = { 5, 0 },
		facing = 270, -- east wall, faces -X into the room
		owner = "group 10 — the Arena itself stands at ARENA_ANCHOR",
		dressing = {
			{ piece = "Prop_Crate", offset = { 0, 0, T * 2 }, rot = 270 },
		},
	},
} :: { Station }

--------------------------------------------------------------------------------
-- Validation. Every check below can actually fail.
--------------------------------------------------------------------------------

--- ⚠️ A validator whose checks cannot fail is decoration (PITFALLS #2). Each of these has a
--- concrete way to trip: a duplicated colour, a station off the grid, two stations on the same
--- tile, a sign inside the Arena aperture, or a piece id that does not exist in the kit.
function WorkshopSpec.validate(): { string }
	local problems = {}

	local seenColor: { [string]: string } = {}
	local seenTile: { [string]: string } = {}
	local seenId: { [string]: boolean } = {}

	for _, s in ipairs(WorkshopSpec.STATIONS) do
		if seenId[s.id] then
			table.insert(problems, ("duplicate station id %q"):format(s.id))
		end
		seenId[s.id] = true

		-- a signal colour means ONE thing; two stations wearing it means it means nothing
		local owner = seenColor[s.color]
		if owner then
			table.insert(problems, ("stations %q and %q both use %s -- a signal colour owns one meaning")
				:format(owner, s.id, s.color))
		end
		seenColor[s.color] = s.id

		local key = ("%d,%d"):format(s.tile[1], s.tile[2])
		local at = seenTile[key]
		if at then
			table.insert(problems, ("stations %q and %q are both on tile %s"):format(at, s.id, key))
		end
		seenTile[key] = s.id

		-- inside the room, and on the grid
		if math.abs(s.tile[1]) * T > WorkshopSpec.HALF_X or math.abs(s.tile[2]) * T > WorkshopSpec.HALF_Z then
			table.insert(problems, ("station %q at tile %s is outside the room"):format(s.id, key))
		end
		if s.facing % 90 ~= 0 then
			table.insert(problems, ("station %q faces %d degrees -- signs sit on walls, so use a multiple of 90")
				:format(s.id, s.facing))
		end

		for _, d in ipairs(s.dressing or {}) do
			if not KitSpec.byId(d.piece) then
				table.insert(problems, ("station %q dresses with %q, which is not a kit piece"):format(s.id, d.piece))
			end
			for _, v: number in ipairs(d.offset) do
				if v % G ~= 0 then
					table.insert(problems, ("station %q dressing %q sits at %s, off the %d-stud grid")
						:format(s.id, d.piece, tostring(v), G))
				end
			end
		end
	end

	if #WorkshopSpec.STATIONS ~= 7 then
		table.insert(problems, ("spec section 8 names seven stations; found %d"):format(#WorkshopSpec.STATIONS))
	end

	-- ⚠️ The aperture must be a real gap. A zero-width one would leave the east wall solid and the
	-- sightline check would then be measuring a wall it cannot see through.
	local ap = WorkshopSpec.APERTURE
	if ap.to < ap.from then
		table.insert(problems, "the Arena aperture is inverted")
	elseif ap.to - ap.from < 1 then
		table.insert(problems, "the Arena aperture is one tile wide -- decision 0001 wants the Arena VISIBLE")
	end
	if ap.from < WorkshopSpec.TILE_MIN or ap.to > WorkshopSpec.TILE_MAX then
		table.insert(problems, "the Arena aperture runs off the end of the east wall")
	end

	-- the anchor must be on the far side of the aperture, or the sightline points at nothing
	if WorkshopSpec.ARENA_ANCHOR.X <= WorkshopSpec.HALF_X then
		table.insert(problems, ("ARENA_ANCHOR x=%d is inside the room (east wall at x=%d)")
			:format(WorkshopSpec.ARENA_ANCHOR.X, WorkshopSpec.HALF_X))
	end

	return problems
end

--- The set of signal colours the stations claim, so anything else in the game can assert it is
--- not stealing one.
function WorkshopSpec.signalColors(): { [string]: string }
	local out: { [string]: string } = {}
	for _, s in ipairs(WorkshopSpec.STATIONS) do
		out[s.color] = s.id
	end
	return out
end

function WorkshopSpec.station(id: string): Station?
	for _, s in ipairs(WorkshopSpec.STATIONS) do
		if s.id == id then
			return s
		end
	end
	return nil
end

--- World position of a station's centre.
function WorkshopSpec.stationPosition(s: Station): Vector3
	return Vector3.new(s.tile[1] * T, 0, s.tile[2] * T)
end

return WorkshopSpec
