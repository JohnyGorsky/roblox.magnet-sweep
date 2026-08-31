--!strict
--[[
	ZoneSpec — the machinery every zone spec shares.

	🔴 WHY THIS EXISTS. `Zone1Spec` carried ~175 lines of helpers and `validate()`. Copying them into
	`Zone2Spec` would have been a second source of truth for every rule this repo cares about — the
	reserved-colour check, the wall-plane footprint test, the anchor checks — and the two copies
	would drift the first time one was fixed. There are ten more zones after this one.

	A zone spec is therefore DATA plus `ZoneSpec.finish(...)`, which attaches the shared behaviour.

	⚠️ Attached as closures over `spec`, deliberately, so that call sites stay `spec.tileToWorld(...)`
	and `ZoneBuilder` needed no change at all.

	Sources: docs/systems/factory/README.md · decision 0017 · style §2
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KitSpec = require(ReplicatedStorage:WaitForChild("Kit", 20):WaitForChild("KitSpec", 20))
local KitBuilder = require(ReplicatedStorage.Kit:WaitForChild("KitBuilder", 20))
local Zones = require(ReplicatedStorage:WaitForChild("Config", 20):WaitForChild("Zones", 20))

local ZoneSpec = {}

local T = KitSpec.TILE

--- The set no zone accent may ever use — style §2's reserved list. 🔴 Lives here, once, so that
--- adding a zone cannot mean adding a stale copy of it.
ZoneSpec.RESERVED = {
	"#41D8FF", -- magnet / pull / electricity
	"#E03A2F", -- alarm / south pole
	"#3FD64B", -- recycle / money in
	"#FF7A1A", -- repair / robot health
	"#C46BFF", -- Epic
	"#FFC21A", -- Arena control / Legendary / hazard gold
	"#FF3D7F", -- Mythic
	"#B8C2CC", -- Common
}

export type Prop = {
	piece: string,
	tx: number,
	tz: number,
	rotY: number,
	accent: string?,
	--- "W" or "E" mounts the piece ON the wall plane rather than on a floor tile.
	wall: string?,
}

export type SpawnVolume = {
	tx: number,
	tz: number,
	halfX: number,
	halfZ: number,
}

--- Attach the shared helpers and `validate()` to a zone's data table, and return it.
function ZoneSpec.finish(spec: any): any
	spec.RESERVED = ZoneSpec.RESERVED


	--------------------------------------------------------------------------------
	-- Helpers.
	--------------------------------------------------------------------------------

	--- Tile indices -> world position. 🔴 The ONLY place chunk-relative becomes absolute. Everything
	--- above is relative, so moving `ORIGIN` moves the zone and nothing else has to know.
	spec.tileToWorld = function(tx: number, tz: number, y: number?): Vector3
		return spec.ORIGIN + Vector3.new(tx * T, y or 0, tz * T)
	end

	--- Chunk-local offset -> world. The second of exactly two places relativity ends.
	spec.localToWorld = function(v: Vector3): Vector3
		return spec.ORIGIN + v
	end

	spec.entryWorld = function(): Vector3
		return spec.localToWorld(spec.ENTRY_LOCAL)
	end

	spec.exitWorld = function(): Vector3
		return spec.localToWorld(spec.EXIT_LOCAL)
	end

	spec.entryLookWorld = function(): Vector3
		return spec.localToWorld(spec.ENTRY_LOOK_LOCAL)
	end

	--- 🔴 The world plane a wall on this side sits in — the FLOOR'S EDGE, not a tile beyond it.
	---
	--- ⚠️ This exists because the first version placed walls at tile `X_MIN - 1` / `X_MAX + 1`, i.e.
	--- world ±40 against a deck edge of ±36, leaving a **3.5-stud open gutter down both sides of the
	--- corridor for its whole length** — and both doorways opened over it. `WorkshopBuilder` has always
	--- placed its walls at `±HALF_X`; this diverged from the very pair it claims to be modelled on.
	spec.wallWorld = function(x: number, z: number): Vector3
		return spec.ORIGIN + Vector3.new(x, 0, z)
	end

	spec.accentColor = function(name: string): Color3?
		local hex = spec.ACCENT[name]
		return hex and Color3.fromHex(hex) or nil
	end

	--------------------------------------------------------------------------------
	-- validate() — run at build time, and it must be able to fail.
	--------------------------------------------------------------------------------

	spec.validate = function(): { string }
		local problems: { string } = {}

		--- 1. Every piece id must exist in the kit. This IS build group 07's "if a room needs a bespoke
		--- asset, the kit is wrong", expressed as a check rather than a hope.
		local known: { [string]: boolean } = {}
		for _, piece in ipairs(KitSpec.PIECES) do
			known[piece.id] = true
		end
		local used = {
			spec.FLOOR_PLAIN, spec.FLOOR_GRATED, spec.FLOOR_HAZARD,
			spec.WALL_SOLID, spec.WALL_PIPES, spec.WALL_MACHINE,
			spec.LAMP_PIECE,
		}
		for _, prop in ipairs(spec.PROPS) do
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
		for _, hex in ipairs(spec.RESERVED) do
			reserved[hex:upper()] = true
		end
		for name, hex in pairs(spec.ACCENT) do
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
			ENTRY_LOCAL = spec.ENTRY_LOCAL,
			EXIT_LOCAL = spec.EXIT_LOCAL,
			ENTRY_LOOK_LOCAL = spec.ENTRY_LOOK_LOCAL,
		}
		for label, p in pairs(anchors) do
			local tx, tz = p.X / T, p.Z / T
			if tx < spec.X_MIN - 0.5 or tx > spec.X_MAX + 0.5
				or tz < spec.Z_MIN - 0.5 or tz > spec.Z_MAX + 0.5 then
				table.insert(problems, ("%s is at tile (%.1f, %.1f), which is off the floor (tiles %d..%d x %d..%d)")
					:format(label, tx, tz, spec.X_MIN, spec.X_MAX, spec.Z_MIN, spec.Z_MAX))
			end
			if p.Y <= 0 then
				table.insert(problems, ("%s has Y = %.1f, which is at or below the floor plane"):format(label, p.Y))
			end
			for i, prop in ipairs(spec.PROPS) do
				if math.abs(tx - prop.tx) < 1 and math.abs(tz - prop.tz) < 1 then
					table.insert(problems, ("%s stands inside prop %d (%s) at tile %d,%d")
						:format(label, i, prop.piece, prop.tx, prop.tz))
				end
			end
		end
		if (spec.ENTRY_LOOK_LOCAL - spec.ENTRY_LOCAL).Magnitude < 1 then
			table.insert(problems, "ENTRY_LOOK_LOCAL is the same point as ENTRY_LOCAL -- the player would face nowhere")
		end

		--- 4. The ID must match `Config/Zones`. The header claims `validate()` does this; it did not,
		--- and `ZoneManager.register` doing it later is a different function at a different time.
		local configured = Zones.byTier(spec.TIER)
		if not configured then
			table.insert(problems, ("Config/Zones has no tier %d"):format(spec.TIER))
		elseif configured.id ~= spec.ID then
			table.insert(problems, ("tier %d is %q in Config/Zones but this spec says %q")
				:format(spec.TIER, configured.id, spec.ID))
		end

		--- 4. Every prop and every spawn volume must be inside the floor, or it hangs in the air.
		for i, prop in ipairs(spec.PROPS) do
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
				--- ⚠️ A wall prop's X is the wall plane, so only its DEPTH into the room is meaningful —
				--- checking it against `HALF_X` would fail by definition. Its Z is checked as normal.
				local wx = prop.wall and 0 or prop.tx * T
				local wz = prop.tz * T
				local crossesX = not prop.wall
					and (wx + loX < -spec.HALF_X or wx + hiX > spec.HALF_X)
				if crossesX or wz + loZ < -spec.HALF_Z or wz + hiZ > spec.HALF_Z then
					table.insert(problems, ("prop %d (%s) at tile %d,%d rot %d spans x %.1f..%.1f z %.1f..%.1f and crosses the wall plane (half extents %d x %d)")
						:format(i, prop.piece, prop.tx, prop.tz, prop.rotY,
							wx + loX, wx + hiX, wz + loZ, wz + hiZ, spec.HALF_X, spec.HALF_Z))
				end
			end
			if prop.accent and not spec.ACCENT[prop.accent] then
				table.insert(problems, ("prop %d (%s) names accent %q, which does not exist"):format(i, prop.piece, prop.accent))
			end
		end
		for i, v in ipairs(spec.SPAWN_VOLUMES) do
			if v.tx - v.halfX < spec.X_MIN or v.tx + v.halfX > spec.X_MAX
				or v.tz - v.halfZ < spec.Z_MIN or v.tz + v.halfZ > spec.Z_MAX then
				table.insert(problems, ("spawn volume %d extends past the floor"):format(i))
			end
		end

		--- 5. There must BE somewhere for scrap to go. A zone with no spawn volume builds perfectly and
		--- is empty forever, which looks like the scrap system being broken rather than this file.
		if #spec.SPAWN_VOLUMES == 0 then
			table.insert(problems, "no spawn volumes -- the zone would build and then contain no scrap at all")
		end

		return problems
	end

	return spec
end

return ZoneSpec
