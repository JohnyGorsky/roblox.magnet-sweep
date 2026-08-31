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
--- 🔴 MEASURED, then widened. At 3 tiles (24 studs) the honest sightline sampler reported the
--- Arena visible from only **32 % of the floor** -- and spec §8, which decision 0001 quotes,
--- asks for it to be visible "from **much of** the Workshop". An independent review solved the
--- same region analytically and got 29.5 %, so the sampler agrees with the maths.
---
--- 32 % is not "much of". 7 tiles (56 studs) is a factory door rather than a window, and it is
--- what makes decision 0001's justification actually true rather than technically survivable.
WorkshopSpec.APERTURE = { from = -3, to = 3 }

--------------------------------------------------------------------------------
-- Hall lighting.
--------------------------------------------------------------------------------

--[[
	🔴 THE ROOM IS LIT AT NIGHT, AND THAT IS THE WHOLE ART DIRECTION.

	The style skill opens with "a bright, glossy, slightly absurd toy factory **at night**", and
	§1 is explicit that reflective material is only as interesting as its environment — "a
	windowless factory box needs bright emissive signage and coloured lights to give the chrome
	something to catch."

	**Seen, not reasoned:** with the place at `ClockTime` 14.5 the neon signage was washed out to
	almost nothing and the grated walkway blew out to pure white, because polished metal under
	`EnvironmentSpecularScale = 1.0` was reflecting a bright blue midday sky. At night the same
	geometry reads as the concept art does — each sign becomes a light source and pools its own
	signal colour on the floor.

	But seven sign lights cannot light a 104-stud hall. These are the fill: an overhead lamp run
	on all four walls, so the floor between the stations is legible and the chrome has warm light
	to catch from above as well as coloured light from the signs.
]]

--- Tile positions along each wall run that carry an overhead lamp.
WorkshopSpec.LAMP_TILES = { -4, 0, 4 }

--- How far in from the wall the lamps hang, so they light the floor rather than the wall face.
WorkshopSpec.LAMP_INSET = 4

--- ⚠️ Interior lamps, because a perimeter run alone does not light a room this size. The centre
--- of a 104-stud hall is 52 studs from every wall -- further than any sane lamp range -- so the
--- first version lit the walls beautifully and left the middle black. These hang over the floor
--- on the diagonals plus the centre, where the player actually walks.
WorkshopSpec.INTERIOR_LAMP_TILES = {
	{ 0, 0 },
	{ -3, -3 }, { 3, -3 }, { -3, 3 }, { 3, 3 },
}

--- ⚠️ A neutral WARM lamp, never a signal colour. A hall light that reads as recycler-green or
--- alarm-red would make the colour language mean nothing (PITFALLS #39), which is why
--- `KitSpec.PALETTE.LampWarm` exists and is documented as carrying no signal meaning.
WorkshopSpec.LAMP_PIECE = "Light_Gantry"

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
	--- The painted housing colour of the station's machine. Read off the concept art, where every
	--- station is a big coloured machine rather than a grey box with a sign on it.
	accent: string,
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
		-- The magnet is red + cyan ALWAYS -- the poles are the game's logo. A red housing under a
		-- cyan face is the magnet's own south pole, not a borrowed alarm colour.
		accent = "#E03A2F",
		tile = { -5, -3 },
		facing = 90, -- west wall, faces +X into the room
		owner = "job 013 -- opens the upgrade panel built in job 011",
		dressing = {
			{ piece = "Ind_ControlPanel", offset = { 12, 0, 8 }, rot = -30 },
			{ piece = "Prop_Crate", offset = { 8, 0, 12 }, rot = 0 },
		},
	},
	{
		id = "Recycler",
		label = "RECYCLER",
		color = "#3FD64B", -- recycler green: money IN, and nothing else is ever green
		accent = "#3FD64B",
		tile = { -5, 3 },
		facing = 90,
		owner = "job 013 -- RequestRecycle, still unbound",
		dressing = {
			-- the conveyor runs OUT of the recycler into the room, as it does in the concept art
			{ piece = "Ind_Conveyor", offset = { 14, 0, 0 }, rot = 90 },
			{ piece = "Prop_Crate", offset = { 10, 0, 12 }, rot = 0 },
		},
	},
	{
		id = "Repair",
		label = "REPAIR",
		color = "#FF7A1A", -- weld orange: repair and robot HP
		accent = "#FF7A1A",
		tile = { -2, 5 },
		facing = 180, -- south wall, faces -Z
		owner = "job 013 -- RequestRepair, still unbound; needs a robot (group 09)",
		dressing = {
			{ piece = "Prop_RobotArm", offset = { -14, 0, 6 }, rot = 0 },
			{ piece = "Ind_Tank", offset = { 14, 0, 4 }, rot = 0 },
		},
	},
	{
		id = "RobotBay",
		label = "ROBOT BAY",
		-- ⚠️ The SIGN stays chrome -- every signal colour already means something and the robot
		-- must not invent an eighth. The HOUSING takes cobalt, a zone accent that carries no
		-- signal meaning, which is what the concept art paints the Robot Bay.
		color = "#B8C2CC",
		accent = "#2F6BE8",
		tile = { 2, 5 },
		facing = 180,
		owner = "group 09 -- assembly; job 013 builds the shell",
		dressing = {
			{ piece = "Prop_RobotArm", offset = { 14, 0, 6 }, rot = 180 },
			{ piece = "Ind_Generator", offset = { -14, 0, 6 }, rot = 0 },
		},
	},
	{
		id = "PartArchive",
		label = "PART ARCHIVE",
		color = "#C46BFF", -- violet: the rarity ramp's own colour
		accent = "#C46BFF",
		tile = { -2, -5 },
		facing = 0, -- north wall, faces +Z
		owner = "P1 -- the wall's contents are not in this job",
		dressing = {
			{ piece = "Ind_ControlPanel", offset = { -14, 0, 6 }, rot = 20 },
		},
	},
	{
		id = "FactoryEntrance",
		label = "FACTORY ENTRANCE",
		color = "#E03A2F", -- signal red: danger, and the only way out of the safe hub
		accent = "#4A545E", -- steel; the red sign and the hazard stripes carry this station
		tile = { 3, -5 },
		facing = 0,
		owner = "group 07 -- zones 1-2 attach here",
		dressing = {
			-- ⚠️ Beacons stand CLEAR of the machine. An earlier version put the gate at the sign's
			-- exact position and pushed both gate posts through the sign housing.
			{ piece = "Prop_Beacon", offset = { -14, 0, 8 }, rot = 0 },
			{ piece = "Prop_Beacon", offset = { 14, 0, 8 }, rot = 0 },
		},
	},
	{
		id = "ScrapArena",
		label = "SCRAP ARENA",
		color = "#FFC21A", -- crown gold: Arena control
		accent = "#FFC21A", -- Arena-related, so a gold housing is the rule being followed
		-- ⚠️ NOT on z = 0. At tile {5, 0} this station's own sign stood in the middle of the Arena
		-- aperture and blocked the view of the Arena it was labelling -- caught by the sightline
		-- raycast on the first build. Offset two tiles north so it sits beside the opening.
		tile = { 5, -2 },
		facing = 270, -- east wall, faces -X into the room
		owner = "group 10 -- the Arena itself stands at ARENA_ANCHOR",
		dressing = {
			{ piece = "Prop_Crate", offset = { 10, 0, 12 }, rot = 0 },
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
		--- ⚠️ Calibrated so the FAILURE fails. `|tile| * 8 > 52` first trips at tile 7, which is
		--- outside the wall loop's own range of +/-6 -- so it could never fire, and review
		--- confirmed a station at tile 6 passing while 8 of its 10 parts landed beyond the wall.
		--- The real limit is the wall, minus half the machine's depth.
		local MACHINE_HALF_DEPTH = 4
		local limit = WorkshopSpec.HALF_X - MACHINE_HALF_DEPTH
		if math.abs(s.tile[1]) * T > limit or math.abs(s.tile[2]) * T > limit then
			table.insert(problems, ("station %q at tile %s puts its machine through the wall (max %d studs from centre)")
				:format(s.id, key, limit))
		end
		if #s.tile ~= 2 then
			table.insert(problems, ("station %q has %d tile components, not 2"):format(s.id, #s.tile))
		end
		if s.facing % 90 ~= 0 then
			table.insert(problems, ("station %q faces %d degrees -- signs sit on walls, so use a multiple of 90")
				:format(s.id, s.facing))
		end

		for _, d in ipairs(s.dressing or {}) do
			if not KitSpec.byId(d.piece) then
				table.insert(problems, ("station %q dresses with %q, which is not a kit piece"):format(s.id, d.piece))
			end
			if #d.offset ~= 3 then
				table.insert(problems, ("station %q dressing %q has %d offset components, not 3 -- Vector3.new would take a nil")
					:format(s.id, d.piece, #d.offset))
				continue
			end

			--- 🔴 WHERE THE PIECE ACTUALLY LANDS, not whether its numbers divide by 4.
			---
			--- The offset is rotated by `facing` before use, so a table entry that reads as "away
			--- from the wall" points AT the wall for facing 90 and 180. Independent review
			--- measured two real casualties of that: the Recycler's tank ended up 60 studs^3
			--- inside a wall panel, and the Robot Bay's platform cantilevered 12 studs OUTSIDE
			--- the room with two of its legs standing on nothing.
			---
			--- The old check only asked whether each component was a multiple of 4 -- it measured
			--- the number's divisibility and never its meaning, so both passed.
			local rot = CFrame.Angles(0, math.rad(s.facing), 0)
			local world = WorkshopSpec.stationPosition(s) + rot:VectorToWorldSpace(
				Vector3.new(d.offset[1], d.offset[2], d.offset[3]))
			--- A generous half-extent for the biggest piece placed here, so a piece whose CENTRE
			--- is just inside the wall still fails.
			local MARGIN = 8
			if math.abs(world.X) + MARGIN > WorkshopSpec.HALF_X or math.abs(world.Z) + MARGIN > WorkshopSpec.HALF_Z then
				table.insert(problems, ("station %q dressing %q lands at (%.0f, %.0f) -- inside or through the wall (room is +/-%d)")
					:format(s.id, d.piece, world.X, world.Z, WorkshopSpec.HALF_X))
			end

			for i = 1, 3 do
				local v = d.offset[i] or 0
				if v % 2 ~= 0 then
					table.insert(problems, ("station %q dressing %q component %d is %s, off the 2-stud sub-grid")
						:format(s.id, d.piece, i, tostring(v)))
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

	--- 🔴 NOTHING MAY STAND ON THE SIGHTLINE. Found the hard way: the SCRAP ARENA station sat on
	--- tile {5, 0}, so its own sign stood in the middle of the aperture and blocked the view of
	--- the Arena it was labelling. The raycast in `WorkshopBuilder` caught it — after 362 parts
	--- had been placed. This catches the same mistake from the spec alone, before anything is
	--- built, and names the station rather than the part id the raycast reports.
	---
	--- The sightline runs from the spawn to `ARENA_ANCHOR`; both sit at z = 0 today, so the test
	--- is a corridor about the z of that line. It is derived from the two endpoints rather than
	--- assuming z = 0, so moving either one keeps the check honest.
	local lineZ = (WorkshopSpec.SPAWN.Z + WorkshopSpec.ARENA_ANCHOR.Z) * 0.5
	local SIGN_HALF_WIDTH = 8 -- Sign_NeonSlab is 16 studs across
	for _, s in ipairs(WorkshopSpec.STATIONS) do
		local pos = WorkshopSpec.stationPosition(s)
		local blocksLine = math.abs(pos.Z - lineZ) < SIGN_HALF_WIDTH
		local betweenSpawnAndAnchor = pos.X > WorkshopSpec.SPAWN.X
		if blocksLine and betweenSpawnAndAnchor then
			table.insert(problems, ("station %q at z=%d stands on the Arena sightline (z=%d) -- its own sign would block the view")
				:format(s.id, pos.Z, lineZ))
		end
	end

	return problems
end

--[[
	⚠️ NO `signalColors()` HELPER, DELIBERATELY — and this note is what replaces it.

	There was one. It built the set of colours the stations claim, and its comment said it existed
	"so anything else in the game can assert it is not stealing one". **Nothing ever called it.**
	Dead code that made a constraint look policed while policing nothing, which is worse than an
	absent check because it stops anyone from writing a real one.

	And a real one cannot be written here, because the constraint is genuinely in tension with the
	design system it comes from. `PITFALLS #39` says a kit piece must never wear a signal colour.
	Style §5 explicitly lists "yellow robot arms" and "slate control panels with cyan screens" as
	recurring kit pieces. Both are true and they contradict: `Prop_RobotArm` wears solid `#FFC21A`
	(Arena gold) and `Ind_ControlPanel` wears `#41D8FF` (magnet cyan), and both are placed here.

	So this is a KNOWN, ACCEPTED tension, written down rather than hidden behind a function that
	returns a table nobody reads. If it is ever resolved, the place to resolve it is the style
	skill, not a validator in the Workshop.
]]

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
