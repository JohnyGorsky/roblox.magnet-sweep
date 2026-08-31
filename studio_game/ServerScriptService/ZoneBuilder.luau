--!strict
--[[
	ZoneBuilder — builds a zone chunk from its spec and registers it with `ZoneManager`.

	The same shape as `WorkshopBuilder`, and deliberately so: the spec is data in git, the geometry
	is a build artifact, and the build happens at server start (decision 0017, PITFALLS #61).

	🔴 ONE MODEL PER ZONE, and that is the whole point. Instance Streaming works on what is in the
	DataModel, so a zone has to BE one thing that can stream in and out as a unit. It is a `Model`
	rather than a `Folder` for that reason — a Folder has no bounds and nothing to stream against.

	⚠️ Reuses the kit `WorkshopBuilder` already built into `ServerStorage`. Rebuilding it here would
	be a second source of truth for the same 27 pieces, and the two could drift within one session.

	Sources: docs/systems/factory/README.md · docs/build/07-zones-1-2.md · decision 0017
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local KitSpec = require(ReplicatedStorage:WaitForChild("Kit", 20):WaitForChild("KitSpec", 20))
local KitBuilder = require(ReplicatedStorage.Kit:WaitForChild("KitBuilder", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Zone")

local ZoneManager = require(script.Parent:WaitForChild("ZoneManager", 20))

local ZoneBuilder = {}

ZoneBuilder.FOLDER_NAME = "Zones"

local T = KitSpec.TILE

--------------------------------------------------------------------------------
-- Placing, against the kit that already exists.
--------------------------------------------------------------------------------

local function kitRoot(): Folder?
	local existing = ServerStorage:FindFirstChild(KitBuilder.FOLDER_NAME)
	return (existing and existing:IsA("Folder")) and existing or nil
end

local function templateFor(root: Folder, pieceId: string): Model?
	local piece = KitSpec.byId(pieceId)
	if not piece then
		return nil
	end
	local category = root:FindFirstChild(piece.category)
	local model = category and category:FindFirstChild(pieceId)
	return (model and model:IsA("Model")) and model or nil
end

--- ⚠️ `PivotTo`, and the kit deliberately leaves pieces without a `PrimaryPart`: a `PrimaryPart`
--- silently overrides `WorldPivot`, which is how a model lands a hundred studs from where it was
--- told to go (PITFALLS #22).
local function place(root: Folder, pieceId: string, pos: Vector3, rotY: number, parent: Instance): Model?
	local template = templateFor(root, pieceId)
	if not template then
		return nil
	end
	local model = template:Clone()
	model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0))
	model.Parent = parent
	return model
end

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function contains(list: { number }, v: number): boolean
	for _, x in ipairs(list) do
		if x == v then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- Tinting.
--------------------------------------------------------------------------------

--- Recolour a piece's PAINTABLE surfaces in a zone accent.
---
--- 🔴 THE SELECTOR IS THE `MSSurface` ATTRIBUTE — what a part **is**, not what colour it happens
--- to be. `MaterialKit.apply` stamps that attribute on every part it touches, for exactly this: so
--- a consumer can ask rather than infer.
---
--- Only two surfaces are paintable: `PaintedGloss` (style §3's "painted machine panels, toy-factory
--- colour") and `SteelBrushed` (machine housings). Everything else keeps the kit's own treatment.
---
--- ⚠️ THIS SELECTOR HAS BEEN WRONG TWICE, and the second time is the instructive one.
---   1. `Material == SmoothPlastic` — the kit uses it for 3 parts of 90, so all four paint drums
---      came out white and the zone named *Color* Workshop had no colour in it.
---   2. `Color == white` — better, but **six** of the kit's surfaces default to white, not two.
---      That repainted `HazardStripe` and `Rust`. Part `Color` MULTIPLIES the ColorMap, so the
---      generator's hazard band × lemon came out ≈ `#FFAA0A` (hazard gold's neighbour) and the
---      robot arm's band × candy pink ≈ `#FF5512` (between repair orange and alarm red). The
---      zone's hazard markings stopped meaning "hazard" — style §2 says the gold collision is only
---      tolerable *because* hazard yellow is always a stripe pattern.
---
--- Both wrong versions were PROXIES for the real question. The fix is not a third proxy; it is to
--- stop guessing and read the marker the kit already stamps (PITFALLS #52).
---
--- ⚠️ `Neon` is additionally never touched at any surface: Neon is where signal lives.
local PAINTABLE: { [string]: boolean } = {
	PaintedGloss = true,
	SteelBrushed = true,
}

--- Returns a per-surface census, not a total. 🔴 A total of 13 looks healthy; a census reading
--- `HazardStripe=2` does not, which is the whole point.
local function tint(model: Model, colour: Color3): (number, { [string]: number })
	local n, census = 0, {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Material ~= Enum.Material.Neon then
			local surface = d:GetAttribute("MSSurface")
			if type(surface) == "string" and PAINTABLE[surface] then
				d.Color = colour
				n += 1
				census[surface] = (census[surface] or 0) + 1
			end
		end
	end
	return n, census
end

--------------------------------------------------------------------------------
-- The chunk.
--------------------------------------------------------------------------------

local function buildFloor(spec: any, root: Folder, parent: Instance): number
	local n = 0
	for tx = spec.X_MIN, spec.X_MAX do
		for tz = spec.Z_MIN, spec.Z_MAX do
			local piece = spec.FLOOR_PLAIN
			if contains(spec.HAZARD_ROWS, tz) then
				piece = spec.FLOOR_HAZARD
			elseif contains(spec.GRATE_COLUMNS, tx) then
				piece = spec.FLOOR_GRATED
			end
			if place(root, piece, spec.tileToWorld(tx, tz, 0), 0, parent) then
				n += 1
			end
		end
	end
	return n
end

--- The two long runs plus the two ends.
---
--- ⚠️ The end walls have a GAP at the centre columns: the corridor has to be enterable at one end
--- and continue at the other, or decision 0003's "forward is the only direction" is a sealed box.
--- Job 018's gate fills the far gap.
local function buildShell(spec: any, root: Folder, parent: Instance): (number, number)
	local n, skipped = 0, 0

	--- 🔴 `±HALF_X`, the FLOOR'S EDGE PLANE — not tile `X_MIN - 1`.
	---
	--- ⚠️ The first version placed at tile ±5, i.e. world ±40, against a deck that ends at ±36. A
	--- `Wall_Solid` is 1 thick, so its inner face sat at ±39.5 and left **3.5 studs of open void
	--- down both sides for the corridor's whole 168-stud length** — with both doorways opening over
	--- the gap. `WorkshopBuilder` has always placed at `±halfX`; this had diverged from the very
	--- pair it claims to be modelled on, and the job's own "X span 80" check could not see it
	--- because it measured wall-part CENTRES, which is a different quantity from the wall FACE.
	for tz = spec.Z_MIN, spec.Z_MAX do
		for _, sideX in ipairs({ -spec.HALF_X, spec.HALF_X }) do
			local piece = spec.WALL_SOLID
			if tz % spec.WALL_MACHINE_EVERY == 0 then
				piece = spec.WALL_MACHINE
			elseif tz % spec.WALL_PIPES_EVERY == 0 then
				piece = spec.WALL_PIPES
			end
			local rot = sideX < 0 and 90 or -90
			if place(root, piece, spec.wallWorld(sideX, tz * T), rot, parent) then
				n += 1
			else
				skipped += 1
			end
		end
	end

	for tx = spec.X_MIN, spec.X_MAX do
		for _, endZ in ipairs({ -spec.HALF_Z, spec.HALF_Z }) do
			--- The doorway: leave the grated walking columns open at both ends.
			if contains(spec.GRATE_COLUMNS, tx) then
				skipped += 1
			else
				local rot = endZ < 0 and 0 or 180
				if place(root, spec.WALL_SOLID, spec.wallWorld(tx * T, endZ), rot, parent) then
					n += 1
				end
			end
		end
	end

	return n, skipped
end

local function buildLights(spec: any, root: Folder, parent: Instance): number
	local n = 0
	for _, tz in ipairs(spec.LAMP_ROWS) do
		if place(root, spec.LAMP_PIECE, spec.tileToWorld(0, tz, 0), 0, parent) then
			n += 1
		end
	end
	return n
end

local function buildProps(spec: any, root: Folder, parent: Instance): (number, { [string]: number }, { string })
	local n, problems = 0, {}
	--- ⚠️ No bare total any more. A total of 13 was exactly the number that looked healthy while
	--- two of the thirteen were hazard stripes; the census is the only honest summary.
	local tintCensus: { [string]: number } = {}
	for i, prop in ipairs(spec.PROPS) do
		local model = place(root, prop.piece, spec.tileToWorld(prop.tx, prop.tz, 0), prop.rotY, parent)
		if not model then
			table.insert(problems, ("prop %d: piece %q is not in the built kit"):format(i, prop.piece))
		else
			n += 1
			if prop.accent then
				local colour = spec.accentColor(prop.accent)
				if colour then
					--- 🔴 THE COUNT IS CHECKED. A tint that touches nothing is invisible: the prop
					--- builds, the zone builds, and the colour the zone is named for is simply
					--- absent. Throwing this return value away is exactly what hid the first bug.
					local painted, census = tint(model, colour)
					for surface, c in pairs(census) do
						tintCensus[surface] = (tintCensus[surface] or 0) + c
					end
					if painted == 0 then
						table.insert(problems, ("prop %d (%s) asked for accent %s and painted NOTHING -- the piece has no white surfaces for a zone to colour")
							:format(i, prop.piece, prop.accent))
					end
				end
			end
		end
	end
	return n, tintCensus, problems
end

--------------------------------------------------------------------------------
-- Build.
--------------------------------------------------------------------------------

--- Returns the zone Model, its part count, and any problems. 🔴 `Model?` so a caller cannot index
--- the result without handling failure — the same contract `WorkshopBuilder.build` uses.
function ZoneBuilder.build(spec: any): (Model?, number, { string })
	local problems = spec.validate()
	if #problems > 0 then
		--- Refuse. A misaligned zone is worse than no zone: it looks nearly right, and every
		--- position derived from it is then subtly wrong.
		return nil, 0, problems
	end

	local root = kitRoot()
	if not root then
		return nil, 0, { "ServerStorage.Kit does not exist -- WorkshopBuilder must run first, it is what builds the kit" }
	end

	local zonesFolder = workspace:FindFirstChild(ZoneBuilder.FOLDER_NAME)
	if not zonesFolder then
		zonesFolder = folder(ZoneBuilder.FOLDER_NAME, workspace)
	end
	local existing = (zonesFolder :: Folder):FindFirstChild(spec.ID)
	if existing then
		--- 🔴 Unregister BEFORE destroying. `register` refuses a duplicate id, so a rebuild used to
		--- warn "registered twice", return false, and leave `ZoneManager` holding a **destroyed**
		--- model with zero descendants pinned for the rest of the session — while the dev command
		--- that triggered it called itself "the idempotence test".
		ZoneManager.unregister(spec.ID)
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = spec.ID
	--- 🔴 `Atomic`, and WITHOUT this the "one Model per zone" claim above is decorative. At the
	--- default `ModelStreamingMode`, a Model's anchored children stream in and out INDIVIDUALLY,
	--- exactly as a Folder's would — being a `Model` buys nothing on its own. `Atomic` is the
	--- property that makes the chunk load or not load as a unit, which is what the header claims.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = zonesFolder

	local floorN = buildFloor(spec, root, folder("Floor", model))
	local shellN, shellSkipped = buildShell(spec, root, folder("Shell", model))
	local lightN = buildLights(spec, root, folder("Lights", model))
	local propN, tintCensus, propProblems = buildProps(spec, root, folder("Props", model))
	for _, p in ipairs(propProblems) do
		table.insert(problems, p)
	end

	local parts = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end

	--- 🔴 MEASURED against the budget, not estimated. `Perf.BUDGET.MAX_PARTS_IN_VIEW` is what this
	--- is ultimately spending, and a zone that quietly triples its part count is the kind of thing
	--- that is only noticed on somebody's phone.
	if parts > spec.PART_BUDGET then
		table.insert(problems, ("zone %s built %d parts against its own budget of %d")
			:format(spec.ID, parts, spec.PART_BUDGET))
	end

	--- Resolve the chunk-relative spawn volumes to world space exactly once, here.
	--- ⚠️ Shape declared inline rather than as `ZoneManager.SpawnVolume`. The analyzer cannot see
	--- an exported type across a `WaitForChild` require, so the annotation would be a genuine
	--- error rather than the usual unresolved-require noise every file in this repo carries.
	local volumes: { { centre: Vector3, halfX: number, halfZ: number } } = {}
	for _, v in ipairs(spec.SPAWN_VOLUMES) do
		table.insert(volumes, {
			centre = spec.tileToWorld(v.tx, v.tz, 0),
			halfX = v.halfX * T,
			halfZ = v.halfZ * T,
		})
	end

	local ok = ZoneManager.register({
		id = spec.ID,
		tier = spec.TIER,
		model = model,
		entry = spec.entryWorld(),
		entryLook = spec.entryLookWorld(),
		exit = spec.exitWorld(),
		min = spec.ORIGIN + Vector3.new(-spec.HALF_X, -32, -spec.HALF_Z),
		max = spec.ORIGIN + Vector3.new(spec.HALF_X, 64, spec.HALF_Z),
		spawnVolumes = volumes,
	})
	if not ok then
		table.insert(problems, ("zone %s built but failed to register -- nothing will be able to find it"):format(spec.ID))
	end

	--- ⚠️ The tinted count is REPORTED, not just checked. "20 props" is a number you scroll past;
	--- "20 props, 26 surfaces painted" is one where a zero would stand out.
	--- ⚠️ The tint is reported as a CENSUS BY SURFACE. "13 surfaces accented" was a number that
	--- looked healthy while two of the thirteen were hazard stripes; `SteelBrushed=7 PaintedGloss=4`
	--- is a line where a wrong surface would stand out.
	local censusParts: { string } = {}
	for surface, c in pairs(tintCensus) do
		table.insert(censusParts, ("%s=%d"):format(surface, c))
	end
	table.sort(censusParts)
	Log.info("%s built: %d floor, %d shell (%d openings), %d lights, %d props (accented: %s), %d parts of a %d budget",
		spec.ID, floorN, shellN, shellSkipped, lightN, propN,
		#censusParts > 0 and table.concat(censusParts, " ") or "NOTHING",
		parts, spec.PART_BUDGET)

	return model, parts, problems
end

return ZoneBuilder
