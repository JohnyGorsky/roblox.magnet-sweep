--!strict
--[[
	HubBuilder — builds the ring of bases and the Arena from `HubSpec`.

	Replaces `WorkshopBuilder`. Same contract: the spec is data in git, the geometry is a build
	artifact, and the build happens at server start (decision 0017, PITFALLS #61).

	🔴 IT ALSO OWNS THE KIT BUILD. `WorkshopBuilder` used to rebuild `ServerStorage.Kit` as a side
	effect, and `ZoneBuilder` quietly depended on that having happened. Retiring the Workshop would
	have silently broken every zone. The kit build moves here, and stays the first thing that runs.

	Sources: assets/concept_art/MapConcept.png · decisions 0001, 0003, 0017
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local KitSpec = require(ReplicatedStorage:WaitForChild("Kit", 20):WaitForChild("KitSpec", 20))
local KitBuilder = require(ReplicatedStorage.Kit:WaitForChild("KitBuilder", 20))
local HubSpec = require(ReplicatedStorage:WaitForChild("Hub", 20):WaitForChild("HubSpec", 20))
local MaterialKit = require(ReplicatedStorage:WaitForChild("MaterialKit", 20))
local Magnet = require(ReplicatedStorage:WaitForChild("Config", 20):WaitForChild("Magnet", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Hub")

local HubBuilder = {}

HubBuilder.FOLDER_NAME = "Hub"

local T = KitSpec.TILE
local kitRoot: Folder? = nil

--------------------------------------------------------------------------------
-- Placing.
--------------------------------------------------------------------------------

local function templateFor(pieceId: string): Model?
	local root = kitRoot
	local piece = root and KitSpec.byId(pieceId)
	if not root or not piece then
		return nil
	end
	local category = root:FindFirstChild(piece.category)
	local model = category and category:FindFirstChild(pieceId)
	return (model and model:IsA("Model")) and model or nil
end

--- ⚠️ Takes a full `CFrame`, not a position and a yaw. Every pocket is rotated to face the ring's
--- centre, so "place at x,z rotated by n degrees" would mean recomputing the same rotation at every
--- call site — and getting it wrong once puts a wall inside a floor.
local function place(pieceId: string, cf: CFrame, parent: Instance): Model?
	local template = templateFor(pieceId)
	if not template then
		return nil
	end
	local model = template:Clone()
	model:PivotTo(cf)
	model.Parent = parent
	return model
end

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

--- Paint a piece's paintable surfaces in a base's identity colour.
---
--- 🔴 Selects on the `MSSurface` attribute, never on colour or material. Job 017 got this wrong
--- twice — `SmoothPlastic` reached 3 parts of 90, and `Color == white` repainted hazard stripes
--- into something that read as gold. `MaterialKit` stamps what a part IS; ask it.
local PAINTABLE: { [string]: boolean } = { PaintedGloss = true, SteelBrushed = true }

local function tint(model: Model, colour: Color3): number
	local n = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Material ~= Enum.Material.Neon then
			local surface = d:GetAttribute(MaterialKit.ATTRIBUTE)
			if type(surface) == "string" and PAINTABLE[surface] then
				d.Color = colour
				n += 1
			end
		end
	end
	return n
end

--------------------------------------------------------------------------------
-- The Arena.
--------------------------------------------------------------------------------

--- The hub's ground: one disc under everything.
---
--- 🔴 THE RING BETWEEN THE ARENA AND THE BASES NEEDS A FLOOR, and the first build did not give it
--- one. The Arena disc covered r <= 40 and the base pockets covered the ring at r ~ 104, but the
--- 40 studs of walkable space between them was **open void** — and the spawn sits in it, so the
--- boot screen held at "WAITING FOR THE WORLD TO STREAM IN" forever. It was right to: its PLACE
--- stage waits for ground under the player's feet, and there was none.
---
--- ⚠️ ONE part, not tiles. At radius 128 a tiled floor is ~800 pieces — half the entire budget for
--- a surface the player reads as one continuous factory deck.
local function buildGround(parent: Instance): number
	local ground = Instance.new("Part")
	ground.Name = "HubFloor"
	ground.Shape = Enum.PartType.Cylinder
	local r = HubSpec.RING_RADIUS + HubSpec.BASE_W
	ground.Size = Vector3.new(2, r * 2, r * 2)
	--- A Cylinder's axis is X, so it is stood on end to become a floor, and sits with its TOP at
	--- y = 0 — the plane every kit piece's pivot assumes.
	ground.CFrame = CFrame.new(HubSpec.ORIGIN + Vector3.new(0, -1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ground.Anchored = true
	ground.CastShadow = false
	ground.Parent = parent
	MaterialKit.apply(ground, "SteelDark")
	return 1
end

local function buildArena(parent: Instance): (number, { string })
	local problems = {}
	local n = 0

	--- The disc. One part, not a ring of tiles: it is 80 studs across and a tiled version would
	--- cost ~80 parts for a shape the player reads as a single floor.
	local disc = Instance.new("Part")
	disc.Name = "ArenaFloor"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(2, HubSpec.ARENA_RADIUS * 2, HubSpec.ARENA_RADIUS * 2)
	--- A Cylinder's axis is X, so it is stood on end to become a floor.
	--- ⚠️ Raised a stud above the hub floor so the Arena reads as a PLATFORM rather than a painted
	--- circle. `MapConcept.png` draws it stepped up, and a flat disc at the same height as the deck
	--- would be a colour change nobody notices.
	disc.CFrame = CFrame.new(HubSpec.ARENA_CENTRE + Vector3.new(0, 0, 0)) * CFrame.Angles(0, 0, math.rad(90))
	disc.Anchored = true
	disc.CastShadow = false
	disc.Parent = parent
	MaterialKit.apply(disc, "SteelDark")
	--- ⚠️ Applied AFTER `MaterialKit`, which sets its own default colour. Lighter than the hub
	--- floor so the disc reads as a platform from 100 studs away.
	disc.Color = Color3.fromHex(HubSpec.ARENA_DECK_COLOR)
	n += 1

	--- 🔴 THE CENTREPIECE IS THE MAGNET WE ALREADY OWN — the mesh job 016 built from `Logo2.png`,
	--- which is exactly what `MapConcept.png` draws standing on this disc. Nothing is generated.
	local template = ReplicatedStorage:FindFirstChild("MagnetMesh")
	if template and template:IsA("MeshPart") then
		local core = template:Clone()
		core.Name = "ArenaCore"
		core.Anchored = true
		core.CanCollide = true
		core.Massless = false
		core.Size = template.Size * HubSpec.CORE_SCALE
		core.CFrame = CFrame.new(HubSpec.ARENA_CENTRE + Vector3.new(0, core.Size.Y / 2 + 1, 0))
		core.Parent = parent

		--- 🔴 The only light in the middle. The bases light themselves and nothing reaches 80 studs
		--- inward, so without this the centrepiece sits in a black hole in a lit ring.
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromHex(HubSpec.CORE_LIGHT.color)
		pl.Brightness = HubSpec.CORE_LIGHT.brightness
		pl.Range = HubSpec.CORE_LIGHT.range
		pl.Shadows = false
		pl.Parent = core
		n += 1
	else
		--- ⚠️ Named, not silent. The mesh lives in the `.rbxl` and not in git (a script cannot write
		--- `SurfaceAppearance` maps — PITFALLS #63), so a lost place file loses it. Its ids are in
		--- `Config.Magnet.MESH` and the shared registry for rebuilding.
		table.insert(problems, ("ReplicatedStorage.MagnetMesh is missing -- the Arena has no core. Re-import assets/generated/magnet-v2/magnet.glb; ids are in Config.Magnet.MESH (%s)"):format(Magnet.MESH.ID))
	end

	return n, problems
end

--------------------------------------------------------------------------------
-- One base.
--------------------------------------------------------------------------------

local function buildBase(slot: number, index: number, parent: Instance): (number, number, { string })
	local problems = {}
	local parts, painted = 0, 0

	local colour = HubSpec.identityColor(index)
	local angle = HubSpec.slotAngle(slot)
	--- The pocket's own frame: at its slot on the ring, turned so local +Z points OUT of the ring.
	--- Everything below is written in pocket-local tiles and transformed by this once.
	local frame = CFrame.new(HubSpec.slotCentre(slot)) * CFrame.Angles(0, angle, 0)

	local base = Instance.new("Model")
	base.Name = ("Base%02d"):format(index)
	--- ⚠️ `Atomic`, for the reason job 017's review gave: at the default a Model's anchored children
	--- stream individually and being a Model buys nothing.
	base.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	base:SetAttribute("Slot", slot)
	base:SetAttribute("Index", index)
	base:SetAttribute("Identity", HubSpec.IDENTITY[index])
	base.Parent = parent

	local half = (HubSpec.BASE_TILES - 1) / 2
	local lo, hi = -math.floor(half), math.floor(half)

	--- Floor. The mouth row is grated, so the way out reads as a threshold.
	local floors = folder("Floor", base)
	for tx = lo, hi do
		for tz = lo, hi do
			--- The mouth row is hazard-striped: style §3 calls the stripe the game's signature
			--- texture and the concept paints it across every threshold. The row behind it is
			--- grated, so the way out reads as two steps rather than one flat edge.
			local piece = HubSpec.FLOOR_PIECE
			if tz == lo then
				piece = HubSpec.THRESHOLD_PIECE
			elseif tz == lo + 1 then
				piece = HubSpec.FLOOR_GRATED
			end
			if place(piece, frame * CFrame.new(tx * T, 0, tz * T), floors) then
				parts += 1
			end
		end
	end

	--- Walls on three sides. 🔴 The side facing the ring centre is LEFT OPEN — that is the whole
	--- design: you look out at the Arena and across at your neighbours. A closed pocket would be
	--- twelve private rooms that happen to be near each other.
	---
	--- ⚠️ Walls sit on the floor's EDGE plane, `(half + 0.5) * T`, not a tile beyond it. Job 017
	--- shipped a 3.5-stud trench by placing them one tile out, and its own check could not see it
	--- because the check measured wall centres rather than faces.
	local edge = (half + 0.5) * T
	local shell = folder("Shell", base)
	for t = lo, hi do
		if place(HubSpec.WALL_PIECE, frame * CFrame.new(-edge, 0, t * T) * CFrame.Angles(0, math.rad(90), 0), shell) then
			parts += 1
		end
		if place(HubSpec.WALL_PIECE, frame * CFrame.new(edge, 0, t * T) * CFrame.Angles(0, math.rad(-90), 0), shell) then
			parts += 1
		end
		--- The back wall, away from the centre. Machine panels rather than plate, so a base has a
		--- face rather than a blank rear.
		local piece = (t == 0) and HubSpec.WALL_MACHINE or HubSpec.WALL_PIECE
		place(piece, frame * CFrame.new(t * T, 0, edge) * CFrame.Angles(0, math.rad(180), 0), shell)
		parts += 1
	end

	--- 🔴 THE WHOLE SHELL TAKES THE IDENTITY COLOUR, not just its `PaintedGloss` panels.
	---
	--- ⚠️ `tint()`'s whitelist is right for a ZONE, where `SteelDark` is structure that must recede
	--- so the accents read against it. It is wrong for a BASE, where the wall **is** the identity —
	--- the concept paints entire pockets solid red, blue, green, yellow. Measured: the shell is
	--- `SteelDark` x180 and `SteelBrushed` x12, so the whitelist reached 12 parts of 192 and every
	--- pocket came out white. That is what made the ring look like a first-grader built it.
	---
	--- `Neon` is still never touched here: the lamp strips keep their own glow.
	for _, d in ipairs(shell:GetDescendants()) do
		if d:IsA("BasePart") and d.Material ~= Enum.Material.Neon then
			d.Color = colour
			painted += 1
		end
	end

	--- The three fixtures, each a machine with its own signal-coloured sign.
	local fixtures = folder("Fixtures", base)
	for _, f in ipairs(HubSpec.FIXTURES) do
		local at = frame * CFrame.new(f.tx * T, 0, f.tz * T) * CFrame.Angles(0, math.rad(180), 0)
		local machine = place(HubSpec.MACHINE_PIECE, at, fixtures)
		if not machine then
			table.insert(problems, ("base %d: %s has no machine piece"):format(index, f.id))
		else
			machine.Name = f.id
			--- 🔴 The machine takes the BASE's identity colour; its SIGN keeps the fixture's SIGNAL
			--- colour. Green still means recycle in every base — style §2's whole point.
			painted += tint(machine, colour)
			parts += #machine:GetDescendants()
			machine:SetAttribute("StationId", f.id)
			machine:SetAttribute("BaseIndex", index)

			local sign = place(HubSpec.SIGN_PIECE, at * CFrame.new(0, 6, -1), fixtures)
			if sign then
				parts += #sign:GetDescendants()
				for _, d in ipairs(sign:GetDescendants()) do
					if d:IsA("BasePart") and d.Material == Enum.Material.Neon then
						d.Color = Color3.fromHex(f.signal)
					end
				end
			end
		end
	end

	--- The staging pad at the mouth — the disc in the concept art.
	local pad = place(HubSpec.PAD_PIECE, frame * CFrame.new(0, 0, HubSpec.PAD_TZ * T), folder("Pad", base))
	if pad then
		pad.Name = "StagingPad"
		parts += #pad:GetDescendants()
		--- The doorstep is the base's too, same reasoning as the shell.
		for _, d in ipairs(pad:GetDescendants()) do
			if d:IsA("BasePart") and d.Material ~= Enum.Material.Neon then
				d.Color = colour
				painted += 1
			end
		end
	end

	--- The dressing: the dozen objects that make a pocket read as a working bay rather than a box.
	local dress = folder("Dressing", base)
	for _, d in ipairs(HubSpec.DRESSING) do
		local m = place(d.piece, frame * CFrame.new(d.tx * T, 0, d.tz * T) * CFrame.Angles(0, math.rad(d.rotY), 0), dress)
		if m then
			parts += #m:GetDescendants()
			if d.tinted then
				painted += tint(m, colour)
			end
		else
			table.insert(problems, ("base %d: dressing piece %q is not in the built kit"):format(index, d.piece))
		end
	end

	--- 🔴 THE SCREENS GLOW IN THE BASE'S COLOUR. Every `Station_Machine` and `Ind_ControlPanel`
	--- ships with `ScreenCyan` faces, so twelve bases lit the whole ring the same cyan and no base
	--- was findable from across it — the one job a base colour has.
	---
	--- ⚠️ Only the generic screen cyan is repainted. A fixture's SIGN keeps its signal colour, so
	--- green still means recycle in every base (style §2, PITFALLS #39).
	local SCREEN_CYAN = Color3.fromHex("#41D8FF")
	for _, group in ipairs({ shell, dress, fixtures }) do
		for _, d in ipairs(group:GetDescendants()) do
			if d:IsA("BasePart") and d.Material == Enum.Material.Neon
				and d.Color:ToHex():upper() == SCREEN_CYAN:ToHex():upper()
				and not d:IsDescendantOf(fixtures) then
				d.Color = colour
				--- A light per screen: this is what actually pools the base's colour on its floor.
				local pl = Instance.new("PointLight")
				pl.Color = colour
				pl.Brightness = 2
				pl.Range = 22
				pl.Shadows = false
				pl.Parent = d
			end
		end
	end

	local lamps = folder("Lights", base)
	for _, tx in ipairs({ -2, 2 }) do
		if place(HubSpec.LAMP_PIECE, frame * CFrame.new(tx * T, 0, 0), lamps) then
			parts += 3
		end
	end

	if painted == 0 then
		table.insert(problems, ("base %d painted NOTHING in its identity colour -- it is indistinguishable from every other base"):format(index))
	end

	return parts, painted, problems
end

--------------------------------------------------------------------------------
-- Ground conflicts.
--------------------------------------------------------------------------------

local COPLANAR_EPSILON = 0.05
local CLEARANCE = 2

--- 🔴 PORTED FROM `WorkshopBuilder`, WHICH THIS JOB RETIRES — and forgetting to port it cost a
--- broken build already: with the Workshop gone, the stock `Workspace.SpawnLocation` at (0, 0.5, 0)
--- was live again alongside `HubSpawn`, **and Roblox picks at random between neutral spawns**. The
--- boot screen sat at "WAITING FOR THE WORLD TO STREAM IN" until its watchdog fired.
---
--- Its two hard-won lessons are kept verbatim, because both were paid for:
---   * 🔴 `Terrain` IS a `BasePart`, and so is a `SpawnLocation`. The first version of this
---     "resolved a ground conflict" by moving `Workspace.Terrain` down 128 studs, on a place that
---     is not in git.
---   * ⚠️ Extents must be ROTATION-AWARE. A rotated slab's footprint is not its `Size`.
---
--- ⚠️ Adapted from a rectangle to a RING: the hub is a disc of radius `RING_RADIUS + BASE_W`, so
--- the overlap test is radial rather than two half-extents.
local function resolveGroundConflicts(): { string }
	local fixed = {}
	local mine = workspace:FindFirstChild(HubBuilder.FOLDER_NAME)
	local reach = HubSpec.RING_RADIUS + HubSpec.BASE_W

	for _, d in ipairs(workspace:GetDescendants()) do
		local isGround = d:IsA("BasePart")
			and not d:IsA("Terrain")
			and not d:IsA("SpawnLocation")
			and not d:IsA("MeshPart")
		if isGround and not (mine and d:IsDescendantOf(mine)) then
			local cf, size = d.CFrame, d.Size
			local ex = math.abs(cf.RightVector.X) * size.X + math.abs(cf.UpVector.X) * size.Y + math.abs(cf.LookVector.X) * size.Z
			local ez = math.abs(cf.RightVector.Z) * size.X + math.abs(cf.UpVector.Z) * size.Y + math.abs(cf.LookVector.Z) * size.Z
			local top = cf.Position.Y + (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
			--- Nearest approach of the slab's footprint to the hub centre.
			local dx = math.max(0, math.abs(cf.Position.X) - ex / 2)
			local dz = math.max(0, math.abs(cf.Position.Z) - ez / 2)
			local overlaps = math.sqrt(dx * dx + dz * dz) < reach

			if overlaps and top > -COPLANAR_EPSILON then
				if d.Anchored then
					local drop = CLEARANCE + top
					d.Position -= Vector3.new(0, drop, 0)
					table.insert(fixed, ("%s (top was y=%.3f -- lowered %.1f studs)"):format(d:GetFullName(), top, drop))
				else
					table.insert(fixed, ("%s is UNANCHORED and its top is y=%.3f -- left alone"):format(d:GetFullName(), top))
				end
			end
		end
	end

	--- 🔴 THERE MUST BE EXACTLY ONE SPAWN. Disabled rather than deleted: it is the owner's place
	--- content, and `Workspace` is not in git.
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("SpawnLocation") and d.Name ~= "HubSpawn" and d.Enabled then
			d.Enabled = false
			table.insert(fixed, ("%s disabled -- the hub owns the spawn, and Roblox picks at random between them"):format(d:GetFullName()))
		end
	end

	return fixed
end

--------------------------------------------------------------------------------
-- Build.
--------------------------------------------------------------------------------

function HubBuilder.build(): (Folder?, number, { string })
	local problems = HubSpec.validate()
	if #problems > 0 then
		return nil, 0, problems
	end

	--- 🔴 The kit first, and this is now the only place it happens.
	local kit, pieces, kitProblems = KitBuilder.buildAll(ServerStorage)
	if not kit then
		return nil, 0, kitProblems
	end
	kitRoot = kit
	Log.info("kit rebuilt from spec: %d pieces", pieces)

	local existing = workspace:FindFirstChild(HubBuilder.FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	local root = folder(HubBuilder.FOLDER_NAME, workspace)

	local groundN = buildGround(folder("Ground", root))
	local arenaN, arenaProblems = buildArena(folder("Arena", root))
	for _, p in ipairs(arenaProblems) do
		table.insert(problems, p)
	end

	local bases = folder("Bases", root)
	local baseParts, basePainted = 0, 0
	local index = 0
	for _, slot in ipairs(HubSpec.baseSlots()) do
		index += 1
		local p, painted, baseProblems = buildBase(slot, index, bases)
		baseParts += p
		basePainted += painted
		for _, bp in ipairs(baseProblems) do
			table.insert(problems, bp)
		end
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(HubSpec.SPAWN)
	spawn.Parent = root

	for _, line in ipairs(resolveGroundConflicts()) do
		Log.info("ground conflict resolved: %s", line)
	end

	local parts = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end

	Log.info("hub built: %d bases on a ring of %d, ground %d, arena %d, %d surfaces in identity colours, %d parts total",
		index, HubSpec.RING_RADIUS, groundN, arenaN, basePainted, parts)

	return root, parts, problems
end

return HubBuilder
