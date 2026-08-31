--!strict
--[[
	Zone1Spec — the COLOR WORKSHOP (tier 1), as DATA.

	The first real zone of the factory. `docs/content/zones` gives its theme verbatim from the spec:
	*"Cyan / pink / yellow. Small conveyors. Paint machines. Bright toy-like machinery."*

	🔴 WHY THIS IS DATA AND NOT A ROOM BUILT BY HAND.

	`Workspace` does not sync (job 002, probed). Geometry placed by hand lives only inside the
	unversioned `.rbxl`: it cannot be diffed, cannot be reviewed, cannot be regenerated when a kit
	piece changes, and is gone with the file. Decision 0017 settled this for the kit and
	`WorkshopSpec` applied it to a room — a zone is the same shape of thing, so it is built the same
	way.

	⚠️ The consequence is real and is not a bug: **the zone is invisible in the editor** until a
	build runs, and the editor's copy goes stale the moment this file changes
	(PITFALLS #61). Play is authoritative.

	🔴 THE CHUNK RULE. `docs/systems/factory`: *"Zones are authored as self-contained streamable
	chunks. No script may hold a hardcoded instance path into another zone; zones talk to the zone
	manager only. Under Instance Streaming that coupling is not a smell, it is a nil-index crash."*
	`StreamingEnabled` is ON for this place. Everything positional in this file is therefore
	expressed **relative to `ORIGIN`**, so the chunk can be moved without a single call site
	knowing, and nothing here names another zone.

	Sources: docs/content/zones/README.md (tier 1) · docs/systems/factory/README.md
	         docs/build/07-zones-1-2.md · decisions 0003, 0017
	         .claude/skills/magnet-sweep-style/SKILL.md §2 (zone accents)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KitSpec = require(ReplicatedStorage:WaitForChild("Kit", 20):WaitForChild("KitSpec", 20))
local KitBuilder = require(ReplicatedStorage.Kit:WaitForChild("KitBuilder", 20))
local Zones = require(ReplicatedStorage:WaitForChild("Config", 20):WaitForChild("Zones", 20))

local Zone1Spec = {}

local T = KitSpec.TILE -- 8

--------------------------------------------------------------------------------
-- Identity.
--------------------------------------------------------------------------------

Zone1Spec.TIER = 1
--- ⚠️ Must match `Config/Zones.luau`'s entry for tier 1. `validate()` checks it rather than
--- trusting that two files were edited together.
Zone1Spec.ID = "COLOR_WORKSHOP"

--------------------------------------------------------------------------------
-- Where the chunk sits, and how big it is.
--------------------------------------------------------------------------------

--- 🔴 The one absolute position in this file. Everything else is an offset from it.
---
--- ⚠️ Placed NORTH of the Workshop, not east. East is spoken for: `WorkshopSpec.ARENA_ANCHOR` is
--- at x = 240 and the Workshop's aperture looks straight down that line — a zone dropped there
--- would stand in the Arena's sightline and break decision 0001's whole justification, which job
--- 012 went to some trouble to measure.
Zone1Spec.ORIGIN = Vector3.new(0, 0, -200)

--- A CORRIDOR, not a room. Decision 0003: *"forward is the only direction"* — the factory is one
--- continuous corridor, so the first zone has to read as a length you travel rather than a hall you
--- stand in. 9 wide by 21 long.
---
--- ⚠️ Both ODD, for the reason `WorkshopSpec` records: with an even count there is no centre tile,
--- so every index names a corner and everything derived from it drifts by half a tile.
Zone1Spec.TILES_X = 9
Zone1Spec.TILES_Z = 21

Zone1Spec.HALF_X = Zone1Spec.TILES_X * T / 2 -- 36
Zone1Spec.HALF_Z = Zone1Spec.TILES_Z * T / 2 -- 84

Zone1Spec.X_MIN, Zone1Spec.X_MAX = -(Zone1Spec.TILES_X - 1) / 2, (Zone1Spec.TILES_X - 1) / 2 -- -4..4
Zone1Spec.Z_MIN, Zone1Spec.Z_MAX = -(Zone1Spec.TILES_Z - 1) / 2, (Zone1Spec.TILES_Z - 1) / 2 -- -10..10

--- Sized against the BUDGET, not by eye. `Perf.BUDGET.MAX_PARTS_IN_VIEW` is 1800 and its comment
--- reads "a zone chunk plus the Workshop"; the Workshop measured 425, so a chunk that can be
--- co-visible with it has roughly 1375 to work in. 9 x 21 puts the floor at 189 tiles and the
--- perimeter at 60 wall segments — a shell near 250, leaving ample room for machinery.
Zone1Spec.PART_BUDGET = 900

--------------------------------------------------------------------------------
-- The two anchors. These are the ONLY things another system may ask for.
--------------------------------------------------------------------------------

--- Where a player arriving from the Workshop's Factory Entrance lands: just inside the near end,
--- facing down the corridor.
---
--- ⚠️ Offset 1.5 tiles in from the end wall, not 0. Landing exactly on the boundary tile put the
--- character half inside the end wall's collision box.
--- 🔴 **`_LOCAL` IS PART OF THE NAME.** These are offsets from `ORIGIN`, not world positions, and
--- the previous names did not say so. `EXIT` was documented as "a contract with job 018 -- use THIS
--- rather than choosing a spot", and following that literally gives `(0, 4, -76)`: **200 studs from
--- where the gate belongs**, next to the Workshop. Use `Zone1Spec.exitWorld()`, or better
--- `ZoneManager.byTier(1).exit`, which is the streaming-safe route everything else is told to use.
Zone1Spec.ENTRY_LOCAL = Vector3.new(0, 4, (Zone1Spec.Z_MAX - 1.5) * T)

--- 🔴 A CONTRACT WITH JOB 018, the same shape as `WorkshopSpec.ARENA_ANCHOR`'s contract with group
--- 10. The zone 1 -> 2 gate stands here. Nothing is drawn at it now, and job 018 uses THIS rather
--- than choosing its own spot, so the corridor stays continuous.
Zone1Spec.EXIT_LOCAL = Vector3.new(0, 4, (Zone1Spec.Z_MIN + 1.5) * T)

--- Which way the player should face on arrival: down the corridor, toward the exit.
Zone1Spec.ENTRY_LOOK_LOCAL = Vector3.new(0, 4, Zone1Spec.Z_MIN * T)

--------------------------------------------------------------------------------
-- Colour.
--------------------------------------------------------------------------------

--[[
	🔴 ZONE ACCENTS ARE NOT SIGNAL COLOURS, and this is the zone where that is easiest to break.

	Style §2 gives tier 1 candy pink, mint and lemon, and states the rule plainly: a zone accent
	*"may never colour a Recycler, a repair effect, a magnet, an alarm or a rarity outline — those
	belong to the signal set and they MEAN something."*

	⚠️ **Lemon `#FFE066` is not hazard gold `#FFC21A`.** They are close enough to read as a typo and
	far enough apart to mean different things: gold means *Arena control / Legendary / the most
	valuable thing here*. A zone painted in gold would say "treasure" in every room, and the loss
	would be invisible until the day a Legendary actually spawned. `validate()` compares every accent
	against the reserved set rather than trusting the hex was typed correctly.

	⚠️ These three are NOT in `Ui.Theme` — Theme carries structural and signal tokens, not zone
	accents — so this is a genuine new duplication, and the spec is the right place for it.
]]
Zone1Spec.ACCENT = {
	CandyPink = "#FF6FB5",
	Mint = "#7FE6C4",
	Lemon = "#FFE066",
}

--- The set no zone accent may ever use. Copied from style §2 so `validate()` has something to check
--- against; if the style guide changes, this list is what has to change with it.
Zone1Spec.RESERVED = {
	"#41D8FF", -- magnet / pull / electricity
	"#E03A2F", -- alarm / south pole
	"#3FD64B", -- recycle / money in
	"#FF7A1A", -- repair / robot health
	"#C46BFF", -- Epic
	"#FFC21A", -- Arena control / Legendary / hazard gold
	"#FF3D7F", -- Mythic
	"#B8C2CC", -- Common
}

--------------------------------------------------------------------------------
-- The shell.
--------------------------------------------------------------------------------

--- Floor. Mostly plain, with grated runs down the walking line and hazard edging at the ends.
--- ⚠️ `Floor_Conveyor` is deliberately NOT the floor: §"theme" asks for *small* conveyors, which
--- are props beside the walking line, not a surface the player is dragged along.
Zone1Spec.FLOOR_PLAIN = "Floor_Plain"
Zone1Spec.FLOOR_GRATED = "Floor_Grated"
Zone1Spec.FLOOR_HAZARD = "Floor_Hazard"

--- Tile columns (x) that get the grated walking strip.
Zone1Spec.GRATE_COLUMNS = { -1, 0, 1 }

--- Rows (z) at each end that get hazard edging: you are entering or leaving something.
Zone1Spec.HAZARD_ROWS = { Zone1Spec.Z_MIN, Zone1Spec.Z_MIN + 1, Zone1Spec.Z_MAX - 1, Zone1Spec.Z_MAX }

Zone1Spec.WALL_SOLID = "Wall_Solid"
Zone1Spec.WALL_PIPES = "Wall_Pipes"
Zone1Spec.WALL_MACHINE = "Wall_Machine"

--- Every fourth wall segment along the long runs becomes machinery rather than plain plate, so the
--- corridor has rhythm instead of reading as a tunnel of identical panels.
Zone1Spec.WALL_MACHINE_EVERY = 4
Zone1Spec.WALL_PIPES_EVERY = 3

--------------------------------------------------------------------------------
-- Lighting.
--------------------------------------------------------------------------------

--- The same reasoning as the Workshop's: the place runs at night, and a corridor this long is
--- unreadable on sign-light alone. Lamps every third row down the centre line.
Zone1Spec.LAMP_PIECE = "Light_Gantry"
Zone1Spec.LAMP_ROWS = { -9, -6, -3, 0, 3, 6, 9 }

--------------------------------------------------------------------------------
-- Machinery: "small conveyors, paint machines, bright toy-like machinery".
--------------------------------------------------------------------------------

export type Prop = {
	piece: string,
	--- Tile coordinates within the chunk.
	tx: number,
	tz: number,
	rotY: number,
	--- Which accent tints this prop's painted panels, or nil to leave the kit's own colours.
	accent: string?,
}

--- ⚠️ EVERY id here must exist in `KitSpec`. Build group 07 states the rule: *"Built from the group
--- 02 kit; if a room needs a bespoke asset, the kit is wrong."* `validate()` enforces it, so the
--- failure mode is a loud error rather than a bespoke part quietly appearing.
Zone1Spec.PROPS = {
	-- Paint drums, in the three zone accents. This is the "paint machines" of the theme.
	{ piece = "Ind_Tank", tx = -3, tz = 8, rotY = 0, accent = "CandyPink" },
	{ piece = "Ind_Tank", tx = 3, tz = 8, rotY = 0, accent = "Mint" },
	{ piece = "Ind_Tank", tx = -3, tz = 2, rotY = 0, accent = "Lemon" },
	{ piece = "Ind_Tank", tx = 3, tz = -4, rotY = 0, accent = "CandyPink" },

	-- Small conveyors, running ACROSS the corridor beside the walking line, not along it.
	{ piece = "Ind_Conveyor", tx = -3, tz = 5, rotY = 90 },
	{ piece = "Ind_Conveyor", tx = 3, tz = -1, rotY = 90 },
	{ piece = "Ind_Conveyor", tx = -3, tz = -7, rotY = 90 },

	-- Toy-like machinery: control panels and fans, tinted.
	{ piece = "Ind_ControlPanel", tx = -4, tz = 6, rotY = 90, accent = "Mint" },
	{ piece = "Ind_ControlPanel", tx = 4, tz = 0, rotY = -90, accent = "CandyPink" },
	{ piece = "Ind_Fan", tx = 4, tz = 6, rotY = -90 },
	{ piece = "Ind_Fan", tx = -4, tz = -2, rotY = 90 },
	{ piece = "Ind_Generator", tx = 3, tz = 4, rotY = 0, accent = "Lemon" },
	{ piece = "Ind_PipeRun", tx = -4, tz = -5, rotY = 90 },

	-- Crates and a beacon: things to sweep around, and one thing that says "industrial".
	{ piece = "Prop_Crate", tx = -2, tz = 7, rotY = 15 },
	{ piece = "Prop_Crate", tx = 2, tz = 3, rotY = -20 },
	{ piece = "Prop_Crate", tx = -2, tz = -3, rotY = 40 },
	{ piece = "Prop_Crate", tx = 2, tz = -8, rotY = 0 },
	{ piece = "Prop_Beacon", tx = -4, tz = 9, rotY = 0 },
	{ piece = "Prop_Beacon", tx = 4, tz = -9, rotY = 0 },
	{ piece = "Prop_RobotArm", tx = 4, tz = -6, rotY = -90, accent = "CandyPink" },
} :: { Prop }

--------------------------------------------------------------------------------
-- Where scrap may spawn.
--------------------------------------------------------------------------------

export type SpawnVolume = {
	--- Tile coordinates of the volume's centre.
	tx: number,
	tz: number,
	--- Half-extent in TILES.
	halfX: number,
	halfZ: number,
}

--- ⚠️ Volumes, not points. Scrap WILL re-pose on every Scrap Refresh (30-60 s, decision 0006), so
--- what this file owns is WHERE scrap may appear, never where a particular piece is.
---
--- 🔴 THAT REFRESH DOES NOT EXIST YET — it is build group 12. An earlier version of this comment
--- said "re-poses" in the present tense, which was simply false: `spawnBox` is called once at boot
--- and nothing re-places a collected piece, so zone 1 empties permanently after about two
--- magnet-loads. `docs/build/spec-coverage.md` gives the reason the refresh is P0 — *"building on
--- static spawns bakes in assumptions the refresh then breaks"* — so this is a known debt, named.
---
--- ⚠️ A previous version of this comment also claimed "the builder rejects a spawn that lands
--- inside a prop's footprint". **No such rejection was ever written.** `ScrapService.groundY` casts
--- down and stops on the first thing it hits, so a spawn over a `Light_Gantry` hood or an
--- `Ind_Tank` cap lands on top of it, twelve studs up. Documented rather than imagined.
Zone1Spec.SPAWN_VOLUMES = {
	{ tx = 0, tz = 7, halfX = 3, halfZ = 2 },
	{ tx = 0, tz = 1, halfX = 3, halfZ = 2 },
	{ tx = 0, tz = -5, halfX = 3, halfZ = 2 },
	{ tx = 0, tz = -9, halfX = 2, halfZ = 1 },
} :: { SpawnVolume }

--- How many scrap pieces each volume holds.
---
--- ⚠️ Per VOLUME, not per zone, so adding a volume adds scrap rather than diluting it. 14 x 4
--- volumes = 56 pieces, against a pool of 400 -- room for eleven more zones without the pool
--- becoming the limit.
Zone1Spec.SCRAP_PER_VOLUME = 14

--------------------------------------------------------------------------------
-- Helpers.
--------------------------------------------------------------------------------

--- Tile indices -> world position. 🔴 The ONLY place chunk-relative becomes absolute. Everything
--- above is relative, so moving `ORIGIN` moves the zone and nothing else has to know.
function Zone1Spec.tileToWorld(tx: number, tz: number, y: number?): Vector3
	return Zone1Spec.ORIGIN + Vector3.new(tx * T, y or 0, tz * T)
end

--- Chunk-local offset -> world. The second of exactly two places relativity ends.
function Zone1Spec.localToWorld(v: Vector3): Vector3
	return Zone1Spec.ORIGIN + v
end

function Zone1Spec.entryWorld(): Vector3
	return Zone1Spec.localToWorld(Zone1Spec.ENTRY_LOCAL)
end

function Zone1Spec.exitWorld(): Vector3
	return Zone1Spec.localToWorld(Zone1Spec.EXIT_LOCAL)
end

function Zone1Spec.entryLookWorld(): Vector3
	return Zone1Spec.localToWorld(Zone1Spec.ENTRY_LOOK_LOCAL)
end

--- 🔴 The world plane a wall on this side sits in — the FLOOR'S EDGE, not a tile beyond it.
---
--- ⚠️ This exists because the first version placed walls at tile `X_MIN - 1` / `X_MAX + 1`, i.e.
--- world ±40 against a deck edge of ±36, leaving a **3.5-stud open gutter down both sides of the
--- corridor for its whole length** — and both doorways opened over it. `WorkshopBuilder` has always
--- placed its walls at `±HALF_X`; this diverged from the very pair it claims to be modelled on.
function Zone1Spec.wallWorld(x: number, z: number): Vector3
	return Zone1Spec.ORIGIN + Vector3.new(x, 0, z)
end

function Zone1Spec.accentColor(name: string): Color3?
	local hex = Zone1Spec.ACCENT[name]
	return hex and Color3.fromHex(hex) or nil
end

--------------------------------------------------------------------------------
-- validate() — run at build time, and it must be able to fail.
--------------------------------------------------------------------------------

function Zone1Spec.validate(): { string }
	local problems: { string } = {}

	--- 1. Every piece id must exist in the kit. This IS build group 07's "if a room needs a bespoke
	--- asset, the kit is wrong", expressed as a check rather than a hope.
	local known: { [string]: boolean } = {}
	for _, piece in ipairs(KitSpec.PIECES) do
		known[piece.id] = true
	end
	local used = {
		Zone1Spec.FLOOR_PLAIN, Zone1Spec.FLOOR_GRATED, Zone1Spec.FLOOR_HAZARD,
		Zone1Spec.WALL_SOLID, Zone1Spec.WALL_PIPES, Zone1Spec.WALL_MACHINE,
		Zone1Spec.LAMP_PIECE,
	}
	for _, prop in ipairs(Zone1Spec.PROPS) do
		table.insert(used, prop.piece)
	end
	for _, id in ipairs(used) do
		if not known[id] then
			table.insert(problems, ("piece %q is not in KitSpec -- the kit is wrong, or the id is a typo"):format(id))
		end
	end

	--- 2. No accent may be a reserved signal colour. Compared case-insensitively, because `#ffc21a`
	--- and `#FFC21A` are the same colour and only one of them would be caught by an equality test.
	local reserved: { [string]: boolean } = {}
	for _, hex in ipairs(Zone1Spec.RESERVED) do
		reserved[hex:upper()] = true
	end
	for name, hex in pairs(Zone1Spec.ACCENT) do
		if reserved[hex:upper()] then
			table.insert(problems, ("accent %s is %s, which is a RESERVED signal colour -- style §2 forbids a zone accent using one"):format(name, hex))
		end
	end

	--- 3. The anchors must be somewhere a player can actually stand.
	---
	--- ⚠️ The first version compared each anchor against `HALF_Z` and was **arithmetically
	--- tautological**: `ENTRY_LOCAL.Z` is `(Z_MAX - 1.5) * T` and `HALF_Z` is `(Z_MAX + 0.5) * T`,
	--- so it held for every possible `TILES_Z` and no edit could make it fire. It also never looked
	--- at `ENTRY_LOOK_LOCAL`, never checked the anchor was above the floor, and never checked it was
	--- clear of a prop — which are the failures its own comment named.
	---
	--- These three CAN fail: land on a floor tile, be clear of every prop's footprint, and have the
	--- look-at point actually differ from the stand point.
	local anchors: { [string]: Vector3 } = {
		ENTRY_LOCAL = Zone1Spec.ENTRY_LOCAL,
		EXIT_LOCAL = Zone1Spec.EXIT_LOCAL,
		ENTRY_LOOK_LOCAL = Zone1Spec.ENTRY_LOOK_LOCAL,
	}
	for label, p in pairs(anchors) do
		local tx, tz = p.X / T, p.Z / T
		if tx < Zone1Spec.X_MIN - 0.5 or tx > Zone1Spec.X_MAX + 0.5
			or tz < Zone1Spec.Z_MIN - 0.5 or tz > Zone1Spec.Z_MAX + 0.5 then
			table.insert(problems, ("%s is at tile (%.1f, %.1f), which is off the floor (tiles %d..%d x %d..%d)")
				:format(label, tx, tz, Zone1Spec.X_MIN, Zone1Spec.X_MAX, Zone1Spec.Z_MIN, Zone1Spec.Z_MAX))
		end
		if p.Y <= 0 then
			table.insert(problems, ("%s has Y = %.1f, which is at or below the floor plane"):format(label, p.Y))
		end
		for i, prop in ipairs(Zone1Spec.PROPS) do
			if math.abs(tx - prop.tx) < 1 and math.abs(tz - prop.tz) < 1 then
				table.insert(problems, ("%s stands inside prop %d (%s) at tile %d,%d")
					:format(label, i, prop.piece, prop.tx, prop.tz))
			end
		end
	end
	if (Zone1Spec.ENTRY_LOOK_LOCAL - Zone1Spec.ENTRY_LOCAL).Magnitude < 1 then
		table.insert(problems, "ENTRY_LOOK_LOCAL is the same point as ENTRY_LOCAL -- the player would face nowhere")
	end

	--- 4. The ID must match `Config/Zones`. The header claims `validate()` does this; it did not,
	--- and `ZoneManager.register` doing it later is a different function at a different time.
	local configured = Zones.byTier(Zone1Spec.TIER)
	if not configured then
		table.insert(problems, ("Config/Zones has no tier %d"):format(Zone1Spec.TIER))
	elseif configured.id ~= Zone1Spec.ID then
		table.insert(problems, ("tier %d is %q in Config/Zones but this spec says %q")
			:format(Zone1Spec.TIER, configured.id, Zone1Spec.ID))
	end

	--- 4. Every prop and every spawn volume must be inside the floor, or it hangs in the air.
	for i, prop in ipairs(Zone1Spec.PROPS) do
		--- ⚠️ The WORLD FOOTPRINT, not the tile index. `WorkshopSpec.validate` has always done it
		--- this way; the tile-index version here passed a 16-stud `Ind_PipeRun` at `tx = -4` whose
		--- far end reaches x = -40 and ends *inside* the west wall, and job 012's review found
		--- exactly this class of defect ("two dressing pieces landing through walls").
		local piece = KitSpec.byId(prop.piece)
		if piece then
			local b = KitBuilder.bounds(piece)
			--- The piece is placed with `rotY`; at ±90° its X and Z reaches swap.
			local loX, hiX, loZ, hiZ = b.loX, b.hiX, b.loZ, b.hiZ
			local turned = math.abs(((prop.rotY % 180) + 180) % 180 - 90) < 45
			if turned then
				loX, hiX, loZ, hiZ = b.loZ, b.hiZ, b.loX, b.hiX
			end
			local wx, wz = prop.tx * T, prop.tz * T
			if wx + loX < -Zone1Spec.HALF_X or wx + hiX > Zone1Spec.HALF_X
				or wz + loZ < -Zone1Spec.HALF_Z or wz + hiZ > Zone1Spec.HALF_Z then
				table.insert(problems, ("prop %d (%s) at tile %d,%d rot %d spans x %.1f..%.1f z %.1f..%.1f and crosses the wall plane (half extents %d x %d)")
					:format(i, prop.piece, prop.tx, prop.tz, prop.rotY,
						wx + loX, wx + hiX, wz + loZ, wz + hiZ, Zone1Spec.HALF_X, Zone1Spec.HALF_Z))
			end
		end
		if prop.accent and not Zone1Spec.ACCENT[prop.accent] then
			table.insert(problems, ("prop %d (%s) names accent %q, which does not exist"):format(i, prop.piece, prop.accent))
		end
	end
	for i, v in ipairs(Zone1Spec.SPAWN_VOLUMES) do
		if v.tx - v.halfX < Zone1Spec.X_MIN or v.tx + v.halfX > Zone1Spec.X_MAX
			or v.tz - v.halfZ < Zone1Spec.Z_MIN or v.tz + v.halfZ > Zone1Spec.Z_MAX then
			table.insert(problems, ("spawn volume %d extends past the floor"):format(i))
		end
	end

	--- 5. There must BE somewhere for scrap to go. A zone with no spawn volume builds perfectly and
	--- is empty forever, which looks like the scrap system being broken rather than this file.
	if #Zone1Spec.SPAWN_VOLUMES == 0 then
		table.insert(problems, "no spawn volumes -- the zone would build and then contain no scrap at all")
	end

	return problems
end

return Zone1Spec
