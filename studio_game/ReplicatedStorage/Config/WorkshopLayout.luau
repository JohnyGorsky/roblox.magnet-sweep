--!strict
--[[
	Config/WorkshopLayout — the Workshop room, as PARAMETERS.

	🔴 THIS IS A SNAPSHOT, NOT A SOURCE. Editing this file moves nothing.

	The room is placed by hand in the editor ([decision 0019](../../../docs/decisions/0019-hero-geometry-is-editor-placed-and-exported.md)),
	because job 019 failed on *proportion* and proportion is what a viewport judges and a spec file
	cannot. But `Workspace` does not sync, so a hand-placed room lives only inside the unversioned
	`.rbxl` — it cannot be diffed, cannot be reviewed, and is gone with the file. That was decision
	0017's objection and it is a real one.

	This file is how the objection is paid off. It records the NUMBERS the room was built from, so
	the room can be rebuilt if the place file is lost, and so a reviewer can see the layout change
	in a diff instead of taking a screenshot's word for it.

	⚠️ It records the layout, not the geometry. The geometry comes from the demo-room patterns and
	`ServerStorage.ImportedMeshes`; those are the parts, this is where they go. Do not add a part
	list here — a 2,653-entry dump is not reviewable and would go stale on the first nudge.

	⚠️ EVERY RADIUS HERE IS PROVISIONAL. The job 020 intake is explicit that they must be walked at
	eye level before they are trusted, and they were: see `Jobs/020/final-summary.md` for what the
	walk changed and what it left open.

	🔴 RESCALED x0.5 ON 2026-09-06. The room was first built at 4x decision 0017's grid — tile 32
	against a decided 8, wall 48 against a decided 12 — which put a single floor tile at NINE METRES
	across, eight times the player's width. The owner played it and said "i just entered game and
	realised how big all is", then that the demo room (9.5-stud tiles) read better. Measured, both
	were the same complaint.

	Every object and position below was scaled by 0.5 about CENTRE, which cost zero parts because it
	is a transform rather than a rebuild. The world now sits at 2x the 0017 grid. Exactly reversible:
	scale by 2.0 about the same centre.

	Sources: Jobs/020 · docs/systems/player-base · decision 0019
]]

local WorkshopLayout = {}

--------------------------------------------------------------------------------
-- The room's shape.
--------------------------------------------------------------------------------

--- 🔴 The Arena's centre, and therefore the room's. NOT the world origin — the Arena was built at
--- x=1556 in job 019 and the room was laid around it rather than moving 692 approved parts.
WorkshopLayout.CENTRE = Vector3.new(1556, 0, 0)

--- Floor top. Every fixture in the room stands on this plane.
WorkshopLayout.FLOOR_Y = 0

--- A regular 12-gon: one facet per player base.
---
--- ⚠️ APOTHEM, not radius — it is the perpendicular distance to a wall FACE, which is the number
--- that matters when placing flat panels. The circumradius (to a vertex) is 479.0.
---
--- 🔴 462.7 is not a round number and is not arbitrary. It is the value that makes the facet side
--- come out at exactly 4 x 62-stud wall panels. A circle, or any other apothem, forces every panel
--- to be chorded and leaves a wedge gap at each joint.
WorkshopLayout.FACETS = 12
WorkshopLayout.APOTHEM = 231.35
WorkshopLayout.FACET_SIDE = 124.0 -- = 2 * APOTHEM * tan(pi/12), = 4 * PANEL_PITCH
WorkshopLayout.PANEL_PITCH = 31
WorkshopLayout.PANELS_PER_FACET = 4
WorkshopLayout.WALL_HEIGHT = 24 -- measured; the demo patterns' 60.5 included a floating Label part

--- Facet k faces outward along bearing k * 30 degrees, measured from +X toward +Z.
--- Vertices therefore sit at 15, 45, 75 ... degrees.
WorkshopLayout.FACET_BEARING_STEP = 30

--------------------------------------------------------------------------------
-- The rings.
--------------------------------------------------------------------------------

WorkshopLayout.RING = {
	ARENA_COLLAR = 63.5, -- as built in job 019; the Arena is not part of this layout
	COMMON_BUILDINGS = 0, -- superseded: the shared buildings moved onto the CONCOURSE below
	--- Chain bounding-box centre. The smelter is 192.9 long x 34.9 deep, so its outer edge lands at
	--- 450.7 — twelve studs clear of the wall face.
	BASE_CHAIN = 216.6,
	BASE_WALL_GAP = 6,
	WALL_FACE = 231.35,
}

--------------------------------------------------------------------------------
-- The wall.
--------------------------------------------------------------------------------

--- Panel letters follow the DEMO ROOM FOLDERS and the job 020 intake, which are the ones the owner
--- walked and approved:
---   A = WINDOW BAYS (17 parts) · B = TOOL-BOARD PANELS (45) · C = BAR WALL (19) · D = HAZARD PLATE (17)
---
--- 🔴 `Jobs/019/wall-research.md` letters the same four walls DIFFERENTLY — its B is the bar wall
--- and is marked "CHOSEN for the perimeter". Anyone building "B for most of the run" from that doc
--- gets tool-board panels at 45 parts a panel. See findings/0007.
---
--- Panels sit at t = -93, -31, +31, +93 along their facet, where t is measured along the facet from
--- its centre. `"OPEN"` means NO PANEL — the Factory Entrance opening.
WorkshopLayout.WALL_BY_FACET = {
	[0] = { "A", "A", "D", "OPEN" }, -- the run lane leaves here; +93 is the gate slot
	[1] = { "D", "A", "A", "A" },
	[2] = { "A", "B", "B", "A" }, -- B behind a shop
	[3] = { "A", "B", "B", "A" },
	[4] = { "A", "B", "B", "A" },
	[5] = { "C", "C", "C", "C" }, -- bar wall: the factory shows through
	[6] = { "A", "B", "B", "A" },
	[7] = { "C", "C", "C", "C" },
	[8] = { "A", "B", "B", "A" },
	[9] = { "A", "B", "B", "A" },
	[10] = { "A", "B", "B", "A" },
	[11] = { "C", "C", "C", "C" },
}
WorkshopLayout.PANEL_OFFSETS = { -46.5, -15.5, 15.5, 46.5 }

--------------------------------------------------------------------------------
-- The shared buildings.
--------------------------------------------------------------------------------

--- 🔴 SHARED, not per-player. This is the owner's job 019 ground rule — upgrade buildings are
--- common and a player owns only their smelter — and it is why these live in
--- `Workspace.Hub.Common.Fixtures` rather than inside a base.
---
--- `StationId` is what `StationService` matches on. It is stamped on the placed Model, never
--- inferred from the name, because every position here is expected to be nudged.
--- 🔴 THE CONCOURSE. The seven shared buildings no longer ring the room -- they line an AVENUE on
--- the gate bearing, so you pass every one on the way out because it is the path you already walk.
---
--- The owner found the ring unusable by playing it: the stations sat on a r=150 circle at bearings
--- 60..300, so visiting all seven was 628 studs of arc, about 39 seconds. On the concourse it is
--- 116 studs, about 7. That is the whole reason this shape exists.
---
--- ⚠️ ORDER IS THE DESIGN, not just the grouping. Listed gate-end first, because the two directions
--- of travel want opposite things: a player coming HOME carries scrap, so the Recycler is the first
--- thing they meet and the Magnet Lab is next to spend what they just earned. A player heading OUT
--- passes the robot stations deeper in, and the Arena Status Display sits at the arena end where it
--- belongs.
WorkshopLayout.CONCOURSE = {
	AXIS_BEARING = 11.4, -- the gate bearing; the avenue points at the door
	SETBACK = 14, -- half the clear avenue width; buildings sit beyond this
	--- r, then which side of the axis (+1 / -1). High r = gate end.
	STATIONS = {
		{ stationId = "Recycler", r = 152, side = 1 },
		{ stationId = "MagnetLab", r = 130, side = 1 },
		{ stationId = "Shop", r = 98, side = 1 },
		{ stationId = "Repair", r = 152, side = -1 },
		{ stationId = "RobotBay", r = 130, side = -1 },
		{ stationId = "PartArchive", r = 106, side = -1 },
		{ stationId = "ScrapArena", r = 82, side = -1 },
	},
	--- ⚠️ The concourse STOPS at r=164 because the innermost crane is at 168.3. The last 67 studs to
	--- the gate are walked between two bases. That is deliberate -- it reads as the mouth -- but it
	--- is not a continuous arcade.
	OUTER_LIMIT = 164,

	--- 🔴 THE BACKDROP. Two runs of tool-board wall behind the stations, one per side, so they read
	--- as shopfronts on a street rather than props on an open plain. Without it the stations float
	--- against the distant perimeter and lose all presence.
	---
	--- Pattern B is not an arbitrary pick: the job 020 intake always said "B tool-board panels
	--- BEHIND THE SHOPS". The shops moved, so B moved with them. A pegboard of tools is also the
	--- right thing to have behind a workshop counter.
	---
	--- ⚠️ Cloned from the demo pattern at SCALE 0.5, because the demo room was never rescaled --
	--- copying a demo panel at native size into this world gives you a double-height wall.
	BACKDROP = {
		WALL_TYPE = "B",
		OFFSET = 48, -- from the axis, each side
		PANELS_PER_SIDE = 3,
		PANEL_WIDTH = 31,
		HEIGHT = 24,
		R_AT = { 87.5, 118.5, 149.5 },
		SOURCE_SCALE = 0.5,
	},
}

--- Where each building came FROM. Kept because the source models still live in the demo room.
WorkshopLayout.COMMON = {
	{ stationId = "MagnetLab", model = "MAGNET_LAB", source = "DemoRoom.7_Workshop.MAGNET_LAB" },
	{ stationId = "Recycler", model = "RECYCLER", source = "DemoRoom.7_Workshop.RECYCLER" },
	{ stationId = "RobotBay", model = "ROBOT_BAY", source = "DemoRoom.7_Workshop.ROBOT_BAY" },
	{ stationId = "ScrapArena", model = "ARENA_STATUS_DISPLAY", source = "DemoRoom.7_Workshop.ARENA_STATUS_DISPLAY" },
	{ stationId = "PartArchive", model = "PART_ARCHIVE_WALL", source = "DemoRoom.7_Workshop.PART_ARCHIVE_WALL" },
	{ stationId = "Repair", model = "REPAIR_STATION", source = "DemoRoom.7_Workshop.REPAIR_STATION" },
	--- ⚠️ NOT 7_Workshop.SHOP_KIOSK -- that entry is a placeholder Volume box with no mesh.
	{ stationId = "Shop", model = "SHOP_KIOSK", source = "DemoRoom.3_Objects.Shop" },
}


--- The way out. Not on the common ring: it stands IN the wall, in the panel slot facet 0 leaves
--- empty, which is the 55-stud gap that exists at every vertex because a 193-stud base sits on a
--- 248-stud facet.
WorkshopLayout.FACTORY_ENTRANCE = {
	facet = 0,
	alongFacet = 41, -- centre of the widened opening
	radius = 231.35, -- inner face flush with the wall
	stationId = "FactoryEntrance",
	source = "DemoRoom.7_Workshop.FACTORY_ENTRANCE",
}

--------------------------------------------------------------------------------
-- The player bases.
--------------------------------------------------------------------------------

--- One per facet, laid ALONG its wall. A 192.9-stud chain on a 248-stud facet leaves 27.5 studs at
--- each end, so neighbouring bases are 55 studs apart at every vertex — which is the walkway, and
--- which is where the Factory Entrance fits without displacing anybody.
---
--- ⚠️ Base 1 (facet 0) is shifted -27.5 along its facet to clear the gate.
WorkshopLayout.BASES = {
	COUNT = 10, -- two facets either side of the gate became the shop frontage
	CHAIN_LENGTH = 78.9, -- belt cut from 5 sections to 3, to free door + facet room
	CHAIN_DEPTH = 17.45,
	SOURCE = "DemoRoom.9_Smelter (1_Hopper, 2_Belt, 3_Furnace, 4_OutputTray)",
	GANTRY_SOURCE = "DemoRoom.7_Workshop.SMELTER_per_player_.gantry",
	--- Facet index -> offset along that facet. Absent means 0.
	OFFSET = { [0] = -22 }, -- base 1 pushed along its facet to clear the widened door
	--- 🔴 Built DORMANT: no robot, no ingots. "An unclaimed base is dark and powered down" —
	--- docs/systems/player-base. Nothing claims a base yet, so all twelve are dormant.
	DORMANT = true,
}

--- The crane, OUT IN FRONT of the smelter rather than inside it.
---
--- 🔴 It was first placed over the belt at r=425-436 — inside the chain's own 418-456 footprint —
--- and at eye level it read as a small prop wedged into the machinery, not as a crane. The owner
--- called it: "crane should be outside". Moved to the room side, centred on the facet, with a
--- 16.4-stud walkway between it and the machinery.
---
--- This is also what `docs/systems/robot-assembly` wants: the robot hangs where the whole room can
--- see it, because installing a part is a public performance rather than a menu confirm.
WorkshopLayout.CRANE = {
	RADIUS = 198.7, -- spans 196.6..201.0; chain inner face is at 207.9
	ALONG_FACET = 0, -- centred, so the twelve cranes form a regular ring
	CLEARANCE_TO_CHAIN = 8.2,

	--- 🔴 WIDENED, NOT SCALED UP. The mesh imports at 26 x 23.7 x 8.8, whose clear opening measures
	--- 12 wide x 15.95 tall — a robot is 25 x 21.2 and fits through neither. Scaling uniformly to
	--- fix the WIDTH needs x2.3, which makes the crane 54.6 tall against a 48-stud wall. So the
	--- mesh is stretched non-uniformly instead: mostly wider, a little taller.
	SIZE = Vector3.new(30, 18, 5.75),
	STAND_HEIGHT = 2.5,

	--- ⚠️ MEASURED BY RAYCAST, not derived from the bounding box, and the two disagree.
	--- Proportional maths off the box predicts an opening of 27.7 wide centred on the crane. The
	--- rays say the legs sit at +2..+20 and +44..+56 of the 60-stud width, so the real opening is
	--- 24 wide and its centre is 2 studs OFF the crane's centre — the mesh is asymmetric.
	--- This is the job-019 lesson again: a bounding box is not a feature.
	OPENING_WIDTH = 12,
	OPENING_HEIGHT = 12.1,
	OPENING_OFFSET_ALONG_FACET = -1,
	BEAM_UNDERSIDE_Y = 14.6,
}

--- Where a base's robot stands. An INVISIBLE, selectable Part named `RobotMount`, one per base,
--- parented to that base's SMELTER model.
---
--- 🔴 It exists to be DRAGGED. The owner asked for "an invisible point and i will move it if
--- needed", which is exactly right: the crane mesh is asymmetric, its claw hangs off the front
--- face, and no amount of arithmetic beats putting the marker where it looks correct. Anything
--- that places a robot should read this point, never recompute a position from the crane's box.
WorkshopLayout.ROBOT_MOUNT = {
	PART_NAME = "RobotMount",
	--- 🔴 MOVED 2026-09-06 (job 022): r 198.7 -> 191.2, Y 2.5 -> 0.
	---
	--- The owner reported it plainly -- *"robot is inside crane"* -- and the measurement was worse
	--- than it looked: **all 16 robot parts intersected `GantryArm`**, not just the arms. The gantry
	--- is 5.8 studs deep and was **coaxial with the mount**, and the robot is 6.6 deep, so the two
	--- occupied the same volume. Sweeping the mount along the facet cleared nothing at any offset
	--- from -6 to +6; only radial separation works. Zero overlap from r <= 192.5, so 191.2 with a
	--- stud of margin.
	---
	--- ⚠️ AND THAT FORCED Y TO 0. The 2.5 was the crane stand's top, but the stand spans r
	--- 193.7..203.7 -- the robot cannot be both on the stand and out of the gantry. So it now stands
	--- on the floor tile in front of its crane, which still satisfies
	--- `docs/systems/robot-assembly`'s "the robot hangs where the whole room can see it".
	--- Verified in Play: feet at y = -0.06, 0 crane overlaps, all ten bays.
	---
	--- ⚠️ Bay 6's marker was additionally at along-facet t = -11 where the other nine were at -1,
	--- which put it into `CraneStandEnd`. Brought in line; no documented reason for the -11.
	RADIUS = 191.2,
	Y = 0, -- the floor tile, in front of the crane -- see above
	HEADROOM_TO_BEAM = 1.5, -- robot tops out at 13.1, beam underside at 14.6
	--- ⚠️ This note is now HISTORICAL. It said the robot's box "overhangs the opening by 0.5 a side"
	--- and that "the body itself is well clear" -- which read as an arms-only problem and is what
	--- misled the first diagnosis in job 022. Measured with an overlap test rather than a box
	--- comparison, the TORSO, HEAD, WHEELS and every pivot were inside the gantry too. The robot no
	--- longer stands in the opening at all, so the opening's width is no longer load-bearing.
	SAMPLE_ON_BASE = 4,
	SAMPLE_SOURCE = "DemoRoom.10_Robots.2_Starter",
}

--------------------------------------------------------------------------------
-- Dividers between neighbouring bases.
--------------------------------------------------------------------------------

--- One per VERTEX, running radially from just inside the crane line out to the wall corner.
--- Head high, so each base reads as its own bay.
---
--- 🔴 The vertex at 15 degrees is SKIPPED. That is where the Factory Entrance stands and where
--- players walk out to the factory; a divider there would wall off the only way out of the hub.
--- Eleven dividers, not twelve.
WorkshopLayout.DIVIDERS = {
	COUNT = 11,
	SKIP_VERTEX_BEARING = 15,
	HEIGHT = 12,
	THICKNESS = 1.25,
	RADIUS_IN = 195,
	RADIUS_OUT = 238.5, -- the wall's corner sits at the circumradius, 239.5
}

--------------------------------------------------------------------------------
-- Spawn.
--------------------------------------------------------------------------------

--- 🔴 OUTSIDE the building ring, not inside it. At r=250 (the first attempt) the player lands
--- facing the Arena with all seven shops BEHIND them and 170 studs of empty plaza ahead — verified
--- in Play and it read badly. At 350 the shops flank the view, the plaza is mid-ground and the
--- Arena closes it.
--- 🔴 On the concourse axis at its arena end, facing OUT along the avenue to the gate -- so a new
--- player's first walk is down the shops and out to the factory.
--- 🔴 In front of the shop arc, facing the gate. Arrival reads: shops either side, exit ahead.
--- It sat at r=70 on the old concourse axis for a while, which left the player 145 studs from
--- everything in an empty plaza -- the stations had moved and the spawn had not.
WorkshopLayout.SPAWN = { bearing = 14, radius = 180, facing = "gate" }

--------------------------------------------------------------------------------
-- The backdrop (job 021).
--------------------------------------------------------------------------------

--- 🔴 THE ROOM'S BACKGROUND, in `Workspace.Hub.Room.Backdrop`.
---
--- Job 020 left the Workshop as a 489-stud room with a 24-stud wall and open sky above it. Measured
--- with a 48x27 raycast sky-fan at eye height 5: standing at a base looking across the room, **45.7 %
--- of the frame was sky**, and all twelve facets were open above y=24. Three of them -- the bar-wall
--- facets 5, 7 and 11 -- were open to the sky **at standing eye height**, which is 25 % of the
--- perimeter.
---
--- 🔴 THE DELIVERABLE WAS AN ANGLE, NOT A WALL. Doubling the existing wall's height moves the
--- across-the-room view by **3.5 percentage points**. That is the trap this job existed to avoid: a
--- handsome, on-palette second wall that changes almost nothing from where the complaint was made.
--- What worked was closing overhead.
---
--- Result, measured in Play (not Edit): across the room **45.7 % -> 0.0 %**.
WorkshopLayout.BACKDROP = {
	FOLDER = "Hub.Room.Backdrop",

	--- Radii are to each layer's INNER face. The existing wall's outer face is at 249.8 (type-C bar
	--- panels stand 11.1 deep), and the floor runs out to 260.2 -- beyond that is void.
	L1_COLLAR = { radius = 254, yFrom = 0, yTo = 48 },
	L2_WALL = { radius = 268, yFrom = 40, yTo = 130 },
	--- the glowing clerestory band: it fills the slot between wall-top and roof that would otherwise
	--- still show sky, AND it is the light source the roof takes away
	L3_CLERESTORY = { radius = 267.4, y = 116, height = 22, perFacet = 3 },
	--- a truss GRID, not a radial fan -- the first version read as a circus tent
	L4_TRUSSES = { yMain = 122, yCross = 130, pitch = 74, span = 520 },
	L5_ROOF = { y = 150, bay = 74, panesGlazed = 49 },

	--- 12 facet bands at y 24..48, five types so no two neighbours match. This is what makes the
	--- ring read as a factory rather than as wallpaper.
	FACET_TYPES = {
		[0] = "W", [1] = "P", [2] = "V", [3] = "C", [4] = "M", [5] = "bay+P",
		[6] = "V", [7] = "bay+M", [8] = "C", [9] = "P", [10] = "W", [11] = "bay+V",
	},
	--- P = pipe wall - V = vent/duct - C = cable - M = machine faces - W = window wall
	--- "bay" = a recessed machinery bay, on the three see-through bar-wall facets only

	--- 🔴 IT READS FROM `Neon` + BLOOM, NEVER FROM LIGHT SPILL.
	--- `QualityController.local.luau:123-131` clamps every non-`Hero` light to 10 studs on the Low
	--- tier -- measured in a real Play session with all 150 lights sitting at range 10. A backdrop
	--- 30-300 studs away gets nothing from a PointLight. 185 of its 1,024 parts are Neon.
	PARTS = 1024,
	NEON_PARTS = 185,

	--- ⚠️ Measured and worth keeping: **Atmosphere cannot substitute for the roof.** Pushed to
	--- Density 0.50 to try fogging the daylight skybox into a dark upper volume, the haze erased the
	--- backdrop itself -- haze acts on distance and the backdrop is at that distance. The sky is
	--- closed with geometry or not at all.
	---
	--- ⚠️ And see finding 0012: the sky-fan measures OCCLUSION, not APPEARANCE. At 0 % sky the far
	--- wall can still read as sky, because at 450 studs the Atmosphere washes it to the same value.
	SKY_PERCENT_BEFORE = { acrossRoom = 45.7, plaza = 37.5, arenaEdge = 41.0, spawnWest = 43.4 },
	SKY_PERCENT_AFTER = { acrossRoom = 0.0, plaza = 0.0, arenaEdge = 0.5, spawnWest = 0.1 },
}

--------------------------------------------------------------------------------
-- What was actually standing when this snapshot was taken.
--------------------------------------------------------------------------------

--- ⚠️ A drift check, not a budget. If the room is rebuilt and these move a lot, something changed
--- that nobody wrote down. `Perf.BUDGET.MAX_PARTS_IN_VIEW` is 1800 and the room is over it by
--- design — the owner was shown the numbers and chose full detail. See findings/0005.
WorkshopLayout.BUILT = {
	AS_OF = "2026-09-06 (job 021: backdrop added; job 022: robot mount moved)",
	FLOOR_ARENA_GROUND = 442, -- 32-stud tiles, pre-existing, NOT relaid — see the open question
	FLOOR_EXTENSION = 276,
	WALL = 1172,
	SIGNAGE = 16,
	COMMON = 29,
	BASES = 468,
	DIVIDERS = 33,
	CONCOURSE_BACKDROP = 264,
	CRANE_STANDS = 24, -- pad + rim on each of 12 bases
	SAMPLE_ROBOT = 18, -- base 4 only; the other eleven stay dormant
	ARENA_NON_FLOOR = 250,
	BACKDROP = 1024, -- job 021, in Hub.Room.Backdrop
	--- ⚠️ the job-020 sample robot was REMOVED at the owner's request: job 022's claim logic spawns
	--- a player's own robot from their saved loadout instead.
	SAMPLE_ROBOT_REMOVED = true,
	--- 🔴 MEASURED 2026-09-06, not arithmetic on the previous figure. An earlier draft of this line
	--- reconciled the old 2,728 with a "-138 (recount)" fudge, which is a made-up number in a file
	--- that reads as authoritative. The real breakdown, counted:
	---   Floor 276 - Wall 1155 - Signage 16 - Dividers 33 - Backdrop 1024 - Common 29 - Bases 370
	---   = Hub 2903, plus Arena 692.
	--- ⚠️ Bases is 370, not job 020's 468: the sample robot went, and the base chain was cut.
	ROOM_TOTAL = 3595,
	--- exactly 200 % of `Perf.BUDGET.MAX_PARTS_IN_VIEW` (1800). The owner accepted the backdrop's
	--- cost with this projection in front of them (see finding 0005 for the same posture on the room
	--- itself). ⚠️ STILL UNMEASURED ON A DEVICE -- job 022's frame-rate readings were a Studio
	--- throttle artefact (a hard 15 fps whether the backdrop was present or not), so no performance
	--- conclusion has ever actually been drawn.
	BUDGET_PERCENT = 200,
	--- runtime-generated, so not in the count above: 10 nameplates (job 022) and one robot per
	--- claimed bay.
	RUNTIME_GENERATED = "BaseNameplates (10 plates), Hub.Bases.<n>.OwnedRobot",
}

--- The floor tile is now 15.8 studs (4.4 m, 3.9x the player's width) — it was 32 (9.0 m, 8x), and
--- the world rescale fixed it without laying a single new tile.
---
--- ⚠️ STILL 2x DECISION 0017's GRID, which says 8. Whether to go the rest of the way is open: a
--- second halving would put the Magnet Lab at 4.5 studs, SHORTER THAN THE PLAYER, so the buildings
--- would need re-scaling independently rather than another uniform pass.
WorkshopLayout.FLOOR_TILE_STUDS = 15.8
WorkshopLayout.FLOOR_TILE_UNRESOLVED = false -- resolved by the x0.5 world rescale

--- Floor colours. These are PATTERNS from the demo room, and they specify COLOUR, not tile size —
--- "A1 as built" carries the Arena's exact pair while being drawn at a different scale.
WorkshopLayout.FLOOR_COLOURS = {
	A1_FLAT = { "62626A", "6E6E76" }, -- the Arena as originally built; luminance delta 0.047
	A2_MEDIUM = { "55555E", "767680" }, -- delta 0.130 — the room's default ground
	A3_STRONG = { "44444E", "82828C" }, -- delta 0.243 — inside the Arena collar
}

return WorkshopLayout
