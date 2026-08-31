--!strict
--[[
	KitSpec — every modular kit piece, as DATA.

	Decision 0017: the kit is GENERATED from this spec, not hand-built in Studio. `Workspace`
	and `ServerStorage` geometry cannot live in git, so a hand-built kit would exist only
	inside the unversioned .rbxl -- undiffable, unreviewable, and impossible to regenerate
	after a material change. This module is the kit; `KitBuilder` just realises it.

	GRID = 4 studs -- but that constrains FOOTPRINTS, not internal detail. Each piece declares
	which axes it tiles on (`tiles = { "X", "Z" }`), and `KitBuilder.validate()` refuses to
	build if a declared axis is not a multiple of the grid. Internal parts -- a 0.4-stud neon
	inset, a 1.2-stud pipe -- are free, because they never meet a neighbouring piece.

	Surfaces are names from `MaterialKit` -- never a raw Material. That is what lets the whole
	factory re-skin when a variant changes.

	Sources: docs/build/02-industrial-kit.md · spec §64 · decision 0017
]]

local MaterialKit = require(game:GetService("ReplicatedStorage"):WaitForChild("MaterialKit"))

export type Piece = {
	id: string,
	category: "Floor" | "Wall" | "Structure" | "Industrial" | "Signage" | "Prop",
	desc: string,
	--- Which axes this piece must TILE on, i.e. where its footprint meets a neighbour.
	--- A floor tiles on X and Z. A wall tiles along its run (X) only -- its Z footprint is
	--- its THICKNESS and is nobody else's business. A free-standing prop tiles on nothing.
	--- Omit for pieces that are placed by hand.
	tiles: { string }?,
	parts: { PartSpec },
}

export type PartSpec = {
	size: { number }, -- {x, y, z}. For a Cylinder see `along`.
	offset: { number }, -- {x, y, z} from the piece's origin
	surface: MaterialKit.Surface?, -- omitted by `neon` parts
	color: string?, -- palette hex; overrides the surface default
	shape: string?, -- "Ball" | "Cylinder" | "Wedge"; default Block
	--- ⚠️ A Roblox Cylinder's LENGTH is its Size.X, always; Size.Y and Size.Z are the
	--- cross-section and the smaller wins. Writing {1.5, 1.5, 16} does NOT make a 16-stud
	--- pipe -- it makes a 1.5-stud nub, because the 16 is simply ignored. So a cylinder
	--- declares `size = { length, dia, dia }` and names the WORLD axis its length runs
	--- along; the builder does the rotation. Never hand-roll `rot` for a cylinder.
	along: string?, -- "X" | "Y" | "Z"; Cylinder only, default "X"
	neon: boolean?, -- Neon material + a matching PointLight, ignores `surface`
	rot: { number }?, -- {x, y, z} degrees. Non-cylinders only.
	light: { range: number, brightness: number }?, -- overrides the default neon light
}

local KitSpec = {}

--- Largest authored light range in the kit, computed from the spec rather than typed.
--- ⚠️ Config/Quality's `decorativeLightRange` must sit BELOW this or the tier clamps nothing.
--- The two numbers were chosen in two files that never met: ranges of 4..18 against thresholds
--- of 40/60/10000, so the light cull was inert at every tier, on every device, forever, and it
--- logged `lights toggled=0` on a healthy run and a broken one alike. Bootstrap asserts it now.
function KitSpec.maxLightRange(): number
	local m = 0
	for _, piece in pairs(KitSpec.PIECES) do
		local r = piece.light and piece.light.range
		if type(r) == "number" and r > m then
			m = r
		end
	end
	return math.max(m, KitSpec.DEFAULT_LIGHT_RANGE)
end

--- KitBuilder's fallback when a piece declares a light with no explicit range.
KitSpec.DEFAULT_LIGHT_RANGE = 18

KitSpec.GRID = 4
KitSpec.TILE = 8 -- 2 grid units: the standard floor/wall footprint
KitSpec.WALL_H = 12 -- 3 grid units: factory ceiling height

local T, H = KitSpec.TILE, KitSpec.WALL_H

--------------------------------------------------------------------------------
-- Palette shorthands. Structural only -- signal colours never decorate.
--------------------------------------------------------------------------------

--- Structural + zone-accent colours. SIGNAL colours are deliberately ABSENT: green means
--- recycle, red means alarm, orange means repair, and gold means Arena/Legendary. A kit
--- piece must never wear one (style skill §2, PITFALLS #39). Screen cyan is allowed because
--- §5 explicitly sanctions "slate control panels with cyan screens".
KitSpec.PALETTE = {
	FactoryDark = "#0E1526",
	SteelMid = "#4A545E",
	ChromeLight = "#B8C2CC",
	HazardYellow = "#FFC21A", -- STRIPES ONLY, never a solid fill
	HazardBlack = "#14161C",
	Rust = "#8A4B2A",
	ScreenCyan = "#41D8FF", -- console screens only
	CrateBlue = "#4A7BA8", -- zone-5 accent; crates are NOT signal red
	LampWarm = "#FFD9A0", -- neutral indicator lamp, carries no signal meaning
	LampCool = "#A8D8F0",
}
local P = KitSpec.PALETTE

--------------------------------------------------------------------------------

KitSpec.PIECES = {
	-- ── FLOORS ────────────────────────────────────────────────────────────────
	{
		id = "Floor_Plain",
		category = "Floor",
		tiles = { "X", "Z" },
		desc = "plain steel deck, the default ground",
		parts = { { size = { T, 1, T }, offset = { 0, -0.5, 0 }, surface = "SteelDark" } },
	},
	{
		id = "Floor_Grated",
		category = "Floor",
		tiles = { "X", "Z" },
		desc = "walkway grating; you can see machinery below",
		parts = { { size = { T, 1, T }, offset = { 0, -0.5, 0 }, surface = "Grate" } },
	},
	{
		id = "Floor_Hazard",
		category = "Floor",
		tiles = { "X", "Z" },
		desc = "hazard-striped deck edging; the stripe repeat is grid-aligned",
		parts = { { size = { T, 1, T }, offset = { 0, -0.5, 0 }, surface = "HazardStripe" } },
	},
	{
		id = "Floor_Conveyor",
		category = "Floor",
		tiles = { "X", "Z" },
		desc = "belt deck; motion comes from texture offset, never physics",
		parts = {
			{ size = { T, 1, T }, offset = { 0, -0.5, 0 }, surface = "Rubber" },
			-- rails INSET so the piece stays exactly T wide; overhanging rails made it 9
			{ size = { 1, 1.4, T }, offset = { -T / 2 + 0.5, -0.3, 0 }, surface = "SteelBrushed" },
			{ size = { 1, 1.4, T }, offset = { T / 2 - 0.5, -0.3, 0 }, surface = "SteelBrushed" },
		},
	},

	-- ── WALLS ─────────────────────────────────────────────────────────────────
	{
		id = "Wall_Solid",
		category = "Wall",
		tiles = { "X" },
		desc = "plain factory wall",
		parts = { { size = { T, H, 1 }, offset = { 0, H / 2, 0 }, surface = "SteelDark" } },
	},
	{
		id = "Wall_Pipes",
		category = "Wall",
		tiles = { "X" },
		desc = "wall with a chrome pipe run and a red valve wheel",
		parts = {
			{ size = { T, H, 1 }, offset = { 0, H / 2, 0 }, surface = "SteelDark" },
			{ size = { T, 1.2, 1.2 }, offset = { 0, 8, 1 }, surface = "Chrome" },
			{ size = { T, 1.2, 1.2 }, offset = { 0, 4, 1 }, surface = "Chrome" },
			-- valve wheel: length 0.6 along Z so it faces the room, dia 2
			{ size = { 0.6, 2, 2 }, offset = { 2, 6, 1.6 }, surface = "PaintedGloss", color = P.ChromeLight, shape = "Cylinder", along = "Z" },
		},
	},
	{
		id = "Wall_Window",
		category = "Wall",
		tiles = { "X" },
		desc = "wall with a lit inspection window",
		parts = {
			{ size = { T, 2, 1 }, offset = { 0, 1, 0 }, surface = "SteelDark" },
			{ size = { T, 3, 1 }, offset = { 0, H - 1.5, 0 }, surface = "SteelDark" },
			-- mullions span the GLAZING only; full-height ones z-fought the solid panels
			{ size = { 1, 7, 1 }, offset = { -T / 2 + 0.5, 5.5, 0 }, surface = "SteelBrushed" },
			{ size = { 1, 7, 1 }, offset = { T / 2 - 0.5, 5.5, 0 }, surface = "SteelBrushed" },
			{ size = { T - 2, H - 5, 0.4 }, offset = { 0, 5.5, 0 }, neon = true, color = P.ScreenCyan },
		},
	},
	{
		id = "Wall_Machine",
		category = "Wall",
		tiles = { "X" },
		desc = "wall-mounted machine face with a control screen",
		parts = {
			{ size = { T, H, 1 }, offset = { 0, H / 2, 0 }, surface = "SteelDark" },
			{ size = { T - 1, 6, 1.6 }, offset = { 0, 6, 1 }, surface = "SteelBrushed" },
			{ size = { 3, 2, 0.4 }, offset = { -1.5, 7, 2 }, neon = true, color = P.ScreenCyan },
			-- neutral lamps: green means RECYCLE and red means ALARM; neither belongs on scenery
			{ size = { 1, 1, 0.6 }, offset = { 2, 7, 2 }, neon = true, color = P.LampCool, light = { range = 5, brightness = 1.5 } },
			{ size = { 1, 1, 0.6 }, offset = { 2, 5, 2 }, neon = true, color = P.LampWarm, light = { range = 5, brightness = 1.5 } },
		},
	},

	-- ── STRUCTURE ─────────────────────────────────────────────────────────────
	{
		id = "Struct_Pillar",
		category = "Structure",
		tiles = { "X", "Z" },
		desc = "load-bearing column with a hazard-striped base",
		parts = {
			{ size = { 3, H, 3 }, offset = { 0, H / 2, 0 }, surface = "SteelBrushed" },
			{ size = { 4, 4, 4 }, offset = { 0, 2, 0 }, surface = "HazardStripe" },
		},
	},
	{
		id = "Struct_Corner",
		category = "Structure",
		tiles = { "X", "Z" },
		desc = "junction post occupying a full tile; wall runs butt into it from any side",
		parts = {
			-- Footprint is a FULL TILE, and that is the whole point. A 4-wide corner centred
			-- on multiples of 4 spans (4k-2, 4k+2), half-offset from an 8-wide wall spanning
			-- (8m-4, 8m+4) -- measured as a 2.00 stud gap that no placement can close.
			-- A junction is a TILE, like a floor. Bars reach the tile edge on BOTH axes so a
			-- run can arrive from any of the four sides, which is more useful than a fixed L.
			{ size = { T, H, 1 }, offset = { 0, H / 2, 0 }, surface = "SteelDark" },
			{ size = { 1, H, T }, offset = { 0, H / 2, 0 }, surface = "SteelDark" },
			{ size = { 3, H, 3 }, offset = { 0, H / 2, 0 }, surface = "SteelBrushed" },
			{ size = { 4, 3, 4 }, offset = { 0, 1.5, 0 }, surface = "HazardStripe" },
		},
	},
	{
		id = "Struct_Gate",
		category = "Structure",
		tiles = { "X" },
		desc = "zone gate frame; the pull mechanism mounts here",
		parts = {
			-- posts INSET so the gate is exactly 2*T wide and tiles with wall runs
			{ size = { 2, H + 4, 2 }, offset = { -T + 1, (H + 4) / 2, 0 }, surface = "HazardStripe" },
			{ size = { 2, H + 4, 2 }, offset = { T - 1, (H + 4) / 2, 0 }, surface = "HazardStripe" },
			{ size = { T * 2, 3, 2 }, offset = { 0, H + 2.5, 0 }, surface = "SteelBrushed" },
			-- hazard gold must always be a STRIPE, never a solid fill (style skill §2).
			-- The lintel reads as a gate via its striped posts; this is a neutral status strip.
			{ size = { T * 2 - 4, 2, 0.5 }, offset = { 0, H + 2.5, 1.2 }, neon = true, color = P.LampWarm, light = { range = 14, brightness = 2 } },
		},
	},
	{
		id = "Struct_Bridge",
		category = "Structure",
		tiles = { "X", "Z" },
		desc = "grated span with guard rails",
		parts = {
			{ size = { T * 2, 1, T }, offset = { 0, 0, 0 }, surface = "Grate" },
			-- rails INSET; sitting them on the edge pushed the Z footprint to 8.5
			{ size = { T * 2, 3, 0.5 }, offset = { 0, 2, -T / 2 + 0.25 }, surface = "PaintedGloss", color = P.HazardYellow },
			{ size = { T * 2, 3, 0.5 }, offset = { 0, 2, T / 2 - 0.25 }, surface = "PaintedGloss", color = P.HazardYellow },
		},
	},
	{
		id = "Struct_Ramp",
		category = "Structure",
		tiles = { "X", "Z" },
		desc = "one-module rise",
		parts = { { size = { T, 4, T }, offset = { 0, 2, 0 }, surface = "Grate", shape = "Wedge" } },
	},
	{
		id = "Struct_Platform",
		category = "Structure",
		tiles = { "X", "Z" },
		desc = "raised working platform on legs",
		parts = {
			-- deck TOP at exactly 8 so a 4-high ramp x2 reaches it flush
			{ size = { T * 2, 1, T * 2 }, offset = { 0, 7.5, 0 }, surface = "Grate" },
			{ size = { 1, 7, 1 }, offset = { -T + 1, 3.5, -T + 1 }, surface = "SteelDark" },
			{ size = { 1, 7, 1 }, offset = { T - 1, 3.5, -T + 1 }, surface = "SteelDark" },
			{ size = { 1, 7, 1 }, offset = { -T + 1, 3.5, T - 1 }, surface = "SteelDark" },
			{ size = { 1, 7, 1 }, offset = { T - 1, 3.5, T - 1 }, surface = "SteelDark" },
		},
	},

	-- ── INDUSTRIAL ────────────────────────────────────────────────────────────
	{
		id = "Ind_Conveyor",
		category = "Industrial",
		tiles = { "X" },
		desc = "raised conveyor run; belt scrolls by texture offset",
		parts = {
			{ size = { T * 2, 1, 6 }, offset = { 0, 4, 0 }, surface = "Rubber" },
			{ size = { T * 2, 2, 1 }, offset = { 0, 4, -3.5 }, surface = "SteelBrushed" },
			{ size = { T * 2, 2, 1 }, offset = { 0, 4, 3.5 }, surface = "SteelBrushed" },
			{ size = { 1, 4, 1 }, offset = { -T + 1, 2, -3.5 }, surface = "SteelDark" },
			{ size = { 1, 4, 1 }, offset = { T - 1, 2, -3.5 }, surface = "SteelDark" },
			{ size = { 1, 4, 1 }, offset = { -T + 1, 2, 3.5 }, surface = "SteelDark" },
			{ size = { 1, 4, 1 }, offset = { T - 1, 2, 3.5 }, surface = "SteelDark" },
		},
	},
	{
		id = "Ind_Generator",
		category = "Industrial",
		desc = "humming power unit with a cyan core",
		parts = {
			{ size = { 6, 6, 8 }, offset = { 0, 3, 0 }, surface = "SteelBrushed" },
			{ size = { 6.4, 2, 2 }, offset = { 0, 5, 0 }, surface = "HazardStripe" },
			-- NOT magnet cyan: that colour belongs to the player. Warm plant glow instead.
			{ size = { 2, 2, 0.4 }, offset = { 0, 3, 4 }, neon = true, color = P.LampWarm, light = { range = 12, brightness = 2 } },
			-- exhaust stack: 6 tall, dia 1.5
			{ size = { 6, 1.5, 1.5 }, offset = { 0, 9, 0 }, surface = "Chrome", shape = "Cylinder", along = "Y" },
		},
	},
	{
		id = "Ind_Tank",
		category = "Industrial",
		desc = "pressure vessel with a rusted band",
		parts = {
			-- vessel: 10 tall, dia 6, BASED ON THE FLOOR (it was floating 2.65 studs)
			{ size = { 10, 6, 6 }, offset = { 0, 5, 0 }, surface = "SteelBrushed", shape = "Cylinder", along = "Y" },
			{ size = { 2, 6.4, 6.4 }, offset = { 0, 3, 0 }, surface = "Rust", shape = "Cylinder", along = "Y" },
			{ size = { 2, 2, 2 }, offset = { 0, 11, 0 }, surface = "Chrome" },
		},
	},
	{
		id = "Ind_PipeRun",
		category = "Industrial",
		desc = "chrome pipe pair with a valve",
		parts = {
			-- a 16-stud run along Z. Writing {1.5,1.5,16} produced a 1.5-stud NUB.
			{ size = { T * 2, 1.5, 1.5 }, offset = { -1.5, 6, 0 }, surface = "Chrome", shape = "Cylinder", along = "Z" },
			{ size = { T * 2, 1.5, 1.5 }, offset = { 1.5, 6, 0 }, surface = "Chrome", shape = "Cylinder", along = "Z" },
			{ size = { 0.8, 2.5, 2.5 }, offset = { -1.5, 6, 2 }, surface = "PaintedGloss", color = P.ChromeLight, shape = "Cylinder", along = "Z" },
		},
	},
	{
		id = "Ind_ControlPanel",
		category = "Industrial",
		desc = "slate console with a cyan screen",
		parts = {
			{ size = { 5, 4, 2 }, offset = { 0, 2, 0 }, surface = "SteelDark" },
			{ size = { 5, 2.5, 2 }, offset = { 0, 4.6, -0.4 }, surface = "SteelBrushed", rot = { -25, 0, 0 } },
			{ size = { 3.6, 1.6, 0.3 }, offset = { 0, 4.9, 0.5 }, neon = true, color = P.ScreenCyan },
			-- 0.8-stud indicator lamps at Range 18 was 3 overlapping room-lights per panel.
			-- Bloom sells them; they do not need to light anything.
			{ size = { 0.8, 0.8, 0.5 }, offset = { -1.6, 1.6, 1.1 }, neon = true, color = P.LampCool, light = { range = 4, brightness = 1 } },
			{ size = { 0.8, 0.8, 0.5 }, offset = { 0, 1.6, 1.1 }, neon = true, color = P.LampWarm, light = { range = 4, brightness = 1 } },
			{ size = { 0.8, 0.8, 0.5 }, offset = { 1.6, 1.6, 1.1 }, neon = true, color = P.LampCool, light = { range = 4, brightness = 1 } },
		},
	},
	{
		id = "Ind_Fan",
		category = "Industrial",
		desc = "caged extractor fan",
		parts = {
			-- pushed clear of the wall plane; at z=0 it was coplanar with Wall_* and z-fought
			{ size = { 6, 6, 1 }, offset = { 0, 6, 0.6 }, surface = "SteelDark" },
			{ size = { 5, 5, 1.2 }, offset = { 0, 6, 0.9 }, surface = "Grate" },
			{ size = { 1.6, 1, 1 }, offset = { 0, 6, 1.1 }, surface = "Chrome", shape = "Cylinder", along = "Z" },
		},
	},

	-- ── SIGNAGE ───────────────────────────────────────────────────────────────
	{
		id = "Sign_NeonSlab",
		category = "Signage",
		desc = "the station sign: slate housing, chrome bezel, DARK face with a glowing rim",
		--- 🔴 The face is DARK and the rim GLOWS. Read off `assets/concept_art/Arena.png`, where
		--- every station sign is a deep navy panel carrying white text inside a bright coloured
		--- outline -- not a solid slab of colour.
		---
		--- The first version made the whole face neon, so each sign rendered as a flat rectangle
		--- of saturated colour with barely-legible dark text on it. The station colour belongs in
		--- the RIM, where it identifies the station without fighting the words.
		parts = {
			{ size = { 16, 5, 1.5 }, offset = { 0, 10, 0 }, surface = "SteelDark" },
			{ size = { 16.6, 0.8, 1.8 }, offset = { 0, 12.2, 0 }, surface = "Chrome" },
			{ size = { 16.6, 0.8, 1.8 }, offset = { 0, 7.8, 0 }, surface = "Chrome" },
			-- the glowing rim: a neon plate that shows only as a border behind the dark face
			{ size = { 14.6, 4, 0.4 }, offset = { 0, 10, 0.85 }, neon = true, color = P.ScreenCyan,
				light = { range = 20, brightness = 3 } },
			-- the dark face the label is written on, standing proud of the rim
			{ size = { 13.4, 3.1, 0.4 }, offset = { 0, 10, 1.0 }, surface = "SteelDark", color = P.FactoryDark },
			{ size = { 16, 2, 2 }, offset = { 0, 6.5, 0 }, surface = "HazardStripe" },
		},
	},

	{
		id = "Station_Machine",
		category = "Industrial",
		desc = "the body of a station: painted housing, buttresses, a glowing recessed face",
		--- The concept art's stations are BUILT MACHINES the size of a wall -- a painted housing
		--- with a glowing recessed face, flanked by coloured buttresses, on a hazard-striped
		--- plinth. An earlier version of the Workshop gave each station a bare platform and a sign
		--- on poles, which read as a market stall rather than as a factory.
		---
		--- Neutral here, tinted per station by the Workshop: `Color` MULTIPLIES the ColorMap, so a
		--- neutral map takes any accent (style skill §3).
		parts = {
			-- hazard plinth
			{ size = { 22, 1.5, 8 }, offset = { 0, 0.75, 0 }, surface = "HazardStripe" },
			-- main housing; tinted with the station's accent
			{ size = { 20, 11, 6 }, offset = { 0, 7, 0 }, surface = "PaintedGloss" },
			-- buttresses either side, same accent, glossier read
			{ size = { 3.5, 12.5, 7.5 }, offset = { -10.5, 7.75, 0 }, surface = "PaintedGloss" },
			{ size = { 3.5, 12.5, 7.5 }, offset = { 10.5, 7.75, 0 }, surface = "PaintedGloss" },
			-- chrome frame around the face
			{ size = { 14, 8, 0.5 }, offset = { 0, 7.5, 3.0 }, surface = "Chrome" },
			-- the glowing recessed face, in the station's own signal colour
			{ size = { 12.4, 6.6, 0.5 }, offset = { 0, 7.5, 3.2 }, neon = true, color = P.ScreenCyan,
				light = { range = 24, brightness = 3 } },
			-- chrome cap
			{ size = { 22, 0.9, 8 }, offset = { 0, 13.8, 0 }, surface = "Chrome" },
		},
	},

	-- ── LIGHTING ──────────────────────────────────────────────────────────────
	{
		id = "Light_Gantry",
		category = "Signage",
		desc = "overhead gantry lamp: slate hood, chrome bezel, warm downward panel",
		--- ⚠️ Placed by hand, so no `tiles`. It hangs from a gantry or a wall head, and its
		--- spacing is a LIGHTING decision made by the room, not a footprint that must abut.
		parts = {
			-- the hood, at the top of a 12-stud wall
			{ size = { 6, 1, 3 }, offset = { 0, H - 0.5, 0 }, surface = "SteelDark" },
			{ size = { 6.4, 0.4, 3.4 }, offset = { 0, H - 1.2, 0 }, surface = "Chrome" },
			--- The emitter. `LampWarm` is deliberately a NEUTRAL indicator colour that carries no
			--- signal meaning -- a hall lamp must not read as recycle-green or alarm-red, or the
			--- colour language stops meaning anything (PITFALLS #39).
			---
			--- ⚠️ Range 40, MEASURED not guessed. At 26 a wall-mounted run lit the walls and left
			--- the middle of a 104-stud hall black: the centre is 52 studs from any wall, twice
			--- the range. 40 overlaps across the room with an interior run to fill it.
			---
			--- This raises `KitSpec.maxLightRange()` to 40, which Bootstrap asserts must stay
			--- ABOVE every tier's `decorativeLightRange` (10 / 15) -- so the quality cull still
			--- has room to fire, and in fact becomes far more meaningful than it was at 18.
			{ size = { 5.2, 0.5, 2.2 }, offset = { 0, H - 1.6, 0 }, neon = true, color = P.LampWarm,
				light = { range = 40, brightness = 4 } },
		},
	},

	-- ── PROPS ─────────────────────────────────────────────────────────────────
	{
		id = "Prop_Beacon",
		category = "Prop",
		desc = "caged amber warning beacon; rotates during a Salvage Breach",
		parts = {
			{ size = { 2, 1, 2 }, offset = { 0, 0.5, 0 }, surface = "SteelDark" },
			-- signal RED on purpose: this beacon fires on a Salvage Breach, and red owns that
			-- meaning. Orange would have been the REPAIR colour, which is a different event.
			{ size = { 1.6, 1.6, 1.6 }, offset = { 0, 1.8, 0 }, neon = true, color = "#E03A2F", light = { range = 16, brightness = 3 } },
			{ size = { 2, 0.4, 2 }, offset = { 0, 2.8, 0 }, surface = "SteelBrushed" },
		},
	},
	{
		id = "Prop_Crate",
		category = "Prop",
		desc = "open scrap crate; the thing you sweep out of",
		parts = {
			-- base lifted clear of the floor plane (it was exactly coplanar -> z-fighting),
			-- and painted a ZONE ACCENT: signal red means alarm, not "a crate"
			{ size = { 6, 0.5, 6 }, offset = { 0, 0.35, 0 }, surface = "PaintedWorn", color = P.CrateBlue },
			{ size = { 6, 4, 0.5 }, offset = { 0, 2.1, -2.75 }, surface = "PaintedWorn", color = P.CrateBlue },
			{ size = { 6, 4, 0.5 }, offset = { 0, 2.1, 2.75 }, surface = "PaintedWorn", color = P.CrateBlue },
			{ size = { 0.5, 4, 6 }, offset = { -2.75, 2.1, 0 }, surface = "PaintedWorn", color = P.CrateBlue },
			{ size = { 0.5, 4, 6 }, offset = { 2.75, 2.1, 0 }, surface = "PaintedWorn", color = P.CrateBlue },
		},
	},
	{
		id = "Prop_RobotArm",
		category = "Prop",
		desc = "yellow factory arm with black joints; the Robot Bay installer",
		parts = {
			{ size = { 4, 1.5, 4 }, offset = { 0, 0.75, 0 }, surface = "HazardStripe" },
			{ size = { 2.5, 2.5, 2.5 }, offset = { 0, 2.5, 0 }, surface = "SteelDark", shape = "Ball" },
			{ size = { 2, 8, 2 }, offset = { 0, 7, 0 }, surface = "PaintedGloss", color = P.HazardYellow },
			{ size = { 2.5, 2.5, 2.5 }, offset = { 0, 11, 0 }, surface = "SteelDark", shape = "Ball" },
			{ size = { 2, 2, 7 }, offset = { 0, 11, 3.5 }, surface = "PaintedGloss", color = P.HazardYellow },
			{ size = { 1.5, 1.5, 1.5 }, offset = { 0, 11, 7 }, surface = "Chrome" },
		},
	},
} :: { Piece }

--------------------------------------------------------------------------------

function KitSpec.byId(id: string): Piece?
	for _, p in ipairs(KitSpec.PIECES) do
		if p.id == id then
			return p
		end
	end
	return nil
end

function KitSpec.byCategory(category: string): { Piece }
	local out = {}
	for _, p in ipairs(KitSpec.PIECES) do
		if p.category == category then
			table.insert(out, p)
		end
	end
	return out
end

return KitSpec
