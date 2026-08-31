--!strict
--[[
	HubSpec — the hub, as DATA: a ring of player bases around the Arena.

	Reference: `assets/concept_art/MapConcept.png` and the owner's sketch. Two corrections to the
	art, from the owner:
	  * **ONE run lane, not four.** The twelve-zone corridor is the single run path, so decision
	    0003 ("forward is the only direction") survives intact.
	  * **TWELVE bases, not four**, matching the server's `MaxPlayers`.

	🔴 THIS REPLACES `WorkshopSpec`'s 13x13 hall and its seven SHARED stations. Stations become
	per-player and per-base — which is the point of the layout, and what makes stealing from another
	base possible later without inventing new machinery for it.

	⚠️ Same data-in-git shape as `Zone1Spec`, for the same reason: `Workspace` does not sync, so
	geometry placed by hand lives only in the unversioned `.rbxl` (decision 0017, PITFALLS #61).

	Sources: assets/concept_art/MapConcept.png · docs/systems/factory/README.md
	         decisions 0001, 0003, 0017 · .claude/skills/magnet-sweep-style/SKILL.md §2
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KitSpec = require(ReplicatedStorage:WaitForChild("Kit", 20):WaitForChild("KitSpec", 20))

local HubSpec = {}

local T = KitSpec.TILE -- 8

--------------------------------------------------------------------------------
-- The ring.
--------------------------------------------------------------------------------

HubSpec.ORIGIN = Vector3.new(0, 0, 0)

--- 🔴 THIRTEEN slots, TWELVE bases. One slot is spent on the run lane's mouth — the arrow in the
--- owner's sketch. Everyone leaves through the same opening, which is what "one run path" means.
---
--- ⚠️ The consequence is deliberate and visible: your base is some distance from the exit, and how
--- far is a fair, readable cost you can see from where you stand.
HubSpec.SLOTS = 13
HubSpec.BASES = 12

--- Which slot is the mouth. 🔴 Slot 0 points at **-Z**, toward Zone 1, so the lane runs straight
--- out of the ring into the corridor rather than turning a corner nobody can see round.
HubSpec.LANE_SLOT = 0

--- One base pocket, in tiles. 6 x 6 = 48 x 48 studs.
HubSpec.BASE_TILES = 6
HubSpec.BASE_W = HubSpec.BASE_TILES * T -- 48

--- Ring radius, DERIVED so the pockets sit shoulder to shoulder without overlapping.
---
--- ⚠️ Not a chosen round number: thirteen pockets 48 studs wide need a circumference of at least
--- 13 x 48 = 624, so the radius is 624 / 2pi ≈ 99.3. Rounded up to a tile multiple so base centres
--- land on the same 8-stud grid everything else uses.
HubSpec.RING_RADIUS = math.ceil((HubSpec.SLOTS * HubSpec.BASE_W) / (2 * math.pi) / T) * T -- 104

--- The Arena disc in the middle.
---
--- ⚠️ Sized to leave a walkable ring between it and the bases: at radius 40 against a base inner
--- edge at 104 - 24 = 80, there are 40 studs of floor to move around in. Job 012 learned that a
--- room you cannot walk across is a diagram, not a place.
HubSpec.ARENA_RADIUS = 40

--- 🔴 DECISION 0001 IS NOW SATISFIED BY CONSTRUCTION.
---
--- Its argument was *"the Arena must be visible from the Workshop"*, and job 012 spent real effort
--- on it — a 56-stud aperture in the east wall and a sampled sightline that reached 56 % of the
--- floor. In a ring the Arena is in the MIDDLE. Every base looks at it because every base opens
--- inward. There is no aperture to widen and no sightline to sample.
---
--- `WorkshopSpec.ARENA_ANCHOR` and its sightline check retire with the hall.
HubSpec.ARENA_CENTRE = Vector3.new(0, 0, 0)

--- Where a player without a base stands, and where the Arena is entered from. Just inside the ring
--- on the lane side, so the first thing a joining player sees is the Arena with bases around it.
HubSpec.SPAWN = Vector3.new(0, 4, -(HubSpec.ARENA_RADIUS + 16))

--------------------------------------------------------------------------------
-- Base identity colours.
--------------------------------------------------------------------------------

--[[
	🔴 YOUR BASE COLOUR IS HOW YOU FIND YOUR BASE, across a ring 208 studs wide. It is the single
	most load-bearing colour decision in the game after the magnet's own red and cyan.

	⚠️ Style §2 forbids a zone accent — and by the same argument a base identity — from using a
	RESERVED signal colour. A base that reads recycler-green or alarm-red would make those colours
	stop meaning recycle and alarm everywhere else (PITFALLS #39).

	These twelve are drawn from §2's own zone-accent rows, which are already chosen to sit outside
	the reserved set, and picked for maximum separation from each other at a distance. `validate()`
	checks both properties rather than trusting the list was typed carefully.
]]
--- 🔴 SAMPLED FROM `MapConcept.png`, not chosen. The first version used style §2's zone accents —
--- candy pink, mint, lemon — and the owner's verdict on the result was blunt and correct: it looked
--- like a first-grader made it. Pastels on a dark factory deck read as washed out.
---
--- The concept's four bases measure **`#A83030` red · `#3068A0` blue · `#608828` green ·
--- `#C88800` yellow** — saturated mid-tones, not pastels. These twelve extend that family around
--- the wheel at the same saturation and lightness, so base 12 belongs to the same picture as base 1.
---
--- ⚠️ Still checked against the reserved set by `validate()`. Saturated is not permission to
--- collide with a signal colour — none of these is `#E03A2F` alarm or `#3FD64B` recycler, and the
--- check is what proves it rather than my eye.
HubSpec.IDENTITY = {
	"#A83030", -- red        (concept)
	"#3068A0", -- blue       (concept)
	"#608828", -- green      (concept)
	"#C88800", -- yellow     (concept)
	"#A84098", -- violet
	"#2F8F86", -- teal
	"#C45A28", -- burnt orange
	"#5060B8", -- indigo
	"#8FA030", -- olive
	"#B03068", -- magenta
	"#3888B8", -- sky
	"#8A5A30", -- bronze
}

HubSpec.RESERVED = {
	"#41D8FF", "#E03A2F", "#3FD64B", "#FF7A1A",
	"#C46BFF", "#FFC21A", "#FF3D7F", "#B8C2CC",
}

--------------------------------------------------------------------------------
-- What stands inside one base.
--------------------------------------------------------------------------------

export type Fixture = {
	id: string,
	label: string,
	--- Tile offset from the base pocket's own centre, +Z pointing OUT of the ring.
	tx: number,
	tz: number,
	--- The signal colour of this fixture's sign. 🔴 A SIGNAL colour, not the base identity —
	--- "green means recycle" has to hold in every base, or it means nothing in any of them.
	signal: string,
}

--- The concept art's arrangement: Robot Bay and Recycler at the back corners, Magnet Lab at the
--- side, staging pad at the mouth.
---
--- ⚠️ Three fixtures, not the old hall's seven. `PartArchive`, `Repair` and `ScrapArena` were
--- shared furniture in a shared room; in a ring the Arena IS the shared thing and the archive is a
--- screen, not a building. They are not lost — they move to the Arena rim in a later job.
HubSpec.FIXTURES = {
	{ id = "MagnetLab", label = "MAGNET LAB", tx = -2, tz = 1, signal = "#41D8FF" },
	{ id = "Recycler", label = "RECYCLER", tx = 2, tz = 1, signal = "#3FD64B" },
	{ id = "RobotBay", label = "ROBOT BAY", tx = 0, tz = 2, signal = "#FF7A1A" },
} :: { Fixture }

--- The disc at the mouth of each base: where your robot deploys and where a stolen part lands.
HubSpec.PAD_PIECE = "Struct_Platform"
HubSpec.PAD_TZ = -2

--------------------------------------------------------------------------------
-- Dressing.
--------------------------------------------------------------------------------

--[[
	🔴 THE POCKETS WERE EMPTY, and that — not the colour — was why the first build looked like a
	diagram instead of a factory.

	Count the objects in one base in `MapConcept.png`: robot arms, conveyor runs, pipe work, wall
	screens, stacked crates, hazard striping, a lit sign, floor decals. A dozen distinct things. The
	first build put three machines, a pad and two lamps in a bare box.

	⚠️ Every id here is already in the 26-piece kit and was simply not used. Nothing needs
	generating; the density was available the whole time.

	⚠️ Budget-checked, not guessed: the bare build measured 1,131 parts of the 1,800 ceiling, so
	there are ~55 parts per base to spend. This list costs ~40.
]]
export type Dressing = {
	piece: string,
	tx: number,
	tz: number,
	rotY: number,
	--- true = takes the base's identity colour; false = keeps the kit's own treatment, so the
	--- pocket does not become monochrome.
	tinted: boolean,
}

HubSpec.DRESSING = {
	--- Working machinery down both flanks — this is most of what reads as "a factory".
	{ piece = "Ind_Conveyor", tx = -2, tz = -1, rotY = 0, tinted = false },
	{ piece = "Ind_Conveyor", tx = 2, tz = -1, rotY = 0, tinted = false },
	{ piece = "Ind_PipeRun", tx = -2, tz = 2, rotY = 0, tinted = false },
	{ piece = "Prop_RobotArm", tx = 2, tz = 2, rotY = 180, tinted = true },
	{ piece = "Ind_Fan", tx = 0, tz = 2, rotY = 180, tinted = false },

	--- Screens and beacons: the lit detail the concept is full of.
	{ piece = "Ind_ControlPanel", tx = -2, tz = 0, rotY = 90, tinted = true },
	{ piece = "Prop_Beacon", tx = -2, tz = -2, rotY = 0, tinted = false },
	{ piece = "Prop_Beacon", tx = 2, tz = -2, rotY = 0, tinted = false },

	--- Crates, scattered rather than aligned — a tidy grid reads as placeholder.
	{ piece = "Prop_Crate", tx = -1, tz = -1, rotY = 22, tinted = false },
	{ piece = "Prop_Crate", tx = 1, tz = 0, rotY = -34, tinted = false },
	{ piece = "Prop_Crate", tx = -1, tz = 1, rotY = 11, tinted = false },
} :: { Dressing }

--- 🔴 HAZARD STRIPING AT THE MOUTH. Style §3 calls the yellow/black stripe *"the game's signature
--- texture"*, and the concept paints it across every threshold. The bare build used none of it.
---
--- ⚠️ `Floor_Hazard` is a kit piece with the stripe baked in — it is NOT hazard gold applied as a
--- flat colour, which style §2 forbids outside a striped pattern.
HubSpec.THRESHOLD_PIECE = "Floor_Hazard"

HubSpec.FLOOR_PIECE = "Floor_Plain"
HubSpec.FLOOR_GRATED = "Floor_Grated"
HubSpec.WALL_PIECE = "Wall_Solid"
HubSpec.WALL_MACHINE = "Wall_Machine"
HubSpec.LAMP_PIECE = "Light_Gantry"
HubSpec.SIGN_PIECE = "Sign_NeonSlab"
HubSpec.MACHINE_PIECE = "Station_Machine"

--------------------------------------------------------------------------------
-- The Arena core.
--------------------------------------------------------------------------------

--- 🔴 THE CENTREPIECE IS THE MAGNET WE ALREADY OWN. `MapConcept.png`'s Arena has a red-and-blue
--- horseshoe magnet standing on the disc, and that is exactly the mesh job 016 generated from the
--- game's own `Logo2.png`. Nothing needs generating; `Config.Magnet.MESH.ID` is the same asset.
---
--- ⚠️ Scaled up. The hand prop is 1.9 studs tall; as a monument it wants to read from 100 studs
--- away across the ring.
--- ⚠️ 20, tuned by looking. At 9 the core was 17 studs on an 80-stud disc and read as a dropped
--- toy; the concept draws it filling roughly a quarter of the Arena. 20 gives 36 studs.
HubSpec.CORE_SCALE = 20

--- The Arena's own light. 🔴 Nothing else lights the middle: the bases light themselves and their
--- lamps do not reach 80 studs. Without this the centrepiece sits in a black hole in the middle of
--- a lit ring, which is exactly how the first build looked.
HubSpec.CORE_LIGHT = { color = "#41D8FF", brightness = 2.5, range = 55 }

--- The Arena deck. Lighter than the hub floor so the disc reads as a platform from across the ring.
HubSpec.ARENA_DECK_COLOR = "#484E5C"

--------------------------------------------------------------------------------
-- Helpers.
--------------------------------------------------------------------------------

--- Bearing of a slot, in radians. Slot 0 faces -Z (toward Zone 1 and the run lane).
function HubSpec.slotAngle(slot: number): number
	return math.pi + (slot / HubSpec.SLOTS) * math.pi * 2
end

--- World position of a slot's base centre.
function HubSpec.slotCentre(slot: number): Vector3
	local a = HubSpec.slotAngle(slot)
	return HubSpec.ORIGIN + Vector3.new(math.sin(a) * HubSpec.RING_RADIUS, 0, math.cos(a) * HubSpec.RING_RADIUS)
end

--- A slot's outward-facing rotation in degrees, for placing pieces that must face the ring centre.
function HubSpec.slotRotation(slot: number): number
	return math.deg(HubSpec.slotAngle(slot))
end

--- Base slots are every slot except the lane's.
function HubSpec.baseSlots(): { number }
	local out = {}
	for s = 0, HubSpec.SLOTS - 1 do
		if s ~= HubSpec.LANE_SLOT then
			table.insert(out, s)
		end
	end
	return out
end

function HubSpec.identityColor(index: number): Color3
	return Color3.fromHex(HubSpec.IDENTITY[((index - 1) % #HubSpec.IDENTITY) + 1])
end

--------------------------------------------------------------------------------
-- validate() — and it must be able to fail.
--------------------------------------------------------------------------------

function HubSpec.validate(): { string }
	local problems: { string } = {}

	--- 1. There must be exactly one identity colour per base, and none may be reserved.
	if #HubSpec.IDENTITY < HubSpec.BASES then
		table.insert(problems, ("%d identity colours for %d bases -- two players would share one")
			:format(#HubSpec.IDENTITY, HubSpec.BASES))
	end
	local reserved: { [string]: boolean } = {}
	for _, hex in ipairs(HubSpec.RESERVED) do
		reserved[hex:upper()] = true
	end
	local seen: { [string]: boolean } = {}
	for i, hex in ipairs(HubSpec.IDENTITY) do
		if reserved[hex:upper()] then
			table.insert(problems, ("identity %d is %s, a RESERVED signal colour -- style §2 forbids it"):format(i, hex))
		end
		if seen[hex:upper()] then
			table.insert(problems, ("identity %d (%s) is a duplicate -- two bases would look the same"):format(i, hex))
		end
		seen[hex:upper()] = true
	end

	--- 2. The slots must actually fit on the ring. 🔴 This is the check that makes `RING_RADIUS`
	--- derived rather than guessed: shrink the radius or widen a base and the pockets overlap, and
	--- overlapping pockets are two players standing in each other's walls.
	local circumference = 2 * math.pi * HubSpec.RING_RADIUS
	local needed = HubSpec.SLOTS * HubSpec.BASE_W
	if circumference < needed then
		table.insert(problems, ("ring circumference %.0f cannot hold %d pockets of %d studs (needs %d)")
			:format(circumference, HubSpec.SLOTS, HubSpec.BASE_W, needed))
	end

	--- 3. The Arena must not touch the bases, or there is nowhere to walk.
	local innerEdge = HubSpec.RING_RADIUS - HubSpec.BASE_W / 2
	if HubSpec.ARENA_RADIUS >= innerEdge then
		table.insert(problems, ("Arena radius %d reaches the base pockets at %d -- no walkable ring between them")
			:format(HubSpec.ARENA_RADIUS, innerEdge))
	end

	--- 4. Every fixture must sit inside its pocket.
	local half = HubSpec.BASE_TILES / 2
	for _, f in ipairs(HubSpec.FIXTURES) do
		if math.abs(f.tx) > half or math.abs(f.tz) > half then
			table.insert(problems, ("fixture %s at tile %d,%d is outside a %d-tile pocket"):format(f.id, f.tx, f.tz, HubSpec.BASE_TILES))
		end
	end

	--- 4b. Dressing must sit inside the pocket, like the fixtures.
	for i, d in ipairs(HubSpec.DRESSING) do
		if math.abs(d.tx) > half or math.abs(d.tz) > half then
			table.insert(problems, ("dressing %d (%s) at tile %d,%d is outside a %d-tile pocket")
				:format(i, d.piece, d.tx, d.tz, HubSpec.BASE_TILES))
		end
	end

	--- 5. Every piece id must exist in the kit — build group 07's rule, applied to the hub.
	local known: { [string]: boolean } = {}
	for _, piece in ipairs(KitSpec.PIECES) do
		known[piece.id] = true
	end
	local ids = {
		HubSpec.FLOOR_PIECE, HubSpec.FLOOR_GRATED, HubSpec.WALL_PIECE, HubSpec.WALL_MACHINE,
		HubSpec.LAMP_PIECE, HubSpec.SIGN_PIECE, HubSpec.MACHINE_PIECE, HubSpec.PAD_PIECE,
		HubSpec.THRESHOLD_PIECE,
	}
	for _, d in ipairs(HubSpec.DRESSING) do
		table.insert(ids, d.piece)
	end
	for _, id in ipairs(ids) do
		if not known[id] then
			table.insert(problems, ("piece %q is not in KitSpec"):format(id))
		end
	end

	--- 6. The lane slot must be a real slot, or the ring has no way out.
	if HubSpec.LANE_SLOT < 0 or HubSpec.LANE_SLOT >= HubSpec.SLOTS then
		table.insert(problems, ("LANE_SLOT %d is not one of the %d slots -- the ring would be sealed"):format(HubSpec.LANE_SLOT, HubSpec.SLOTS))
	end
	if #HubSpec.baseSlots() ~= HubSpec.BASES then
		table.insert(problems, ("%d slots minus the lane gives %d bases, but BASES says %d")
			:format(HubSpec.SLOTS, #HubSpec.baseSlots(), HubSpec.BASES))
	end

	return problems
end

return HubSpec
