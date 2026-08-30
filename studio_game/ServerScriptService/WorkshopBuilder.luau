--!strict
--[[
	WorkshopBuilder — realises `WorkshopSpec` into `Workspace`.

	Server-only, because it clones from `ServerStorage.Kit`. Idempotent: it destroys and replaces
	its own folder, exactly like `KitBuilder.buildAll`, so calling it twice is a no-op and calling
	it after a spec change is the whole update mechanism.

	🔴 IT REBUILDS THE KIT FIRST, AND THAT IS NOT INCIDENTAL.

	`ServerStorage.Kit` was standing in the live place with 24 models and 85 parts — and
	**nothing in the codebase ever built it.** Job 005 generated it once over MCP and it has lived
	in the unversioned `.rbxl` ever since. Decision 0017 says "regenerating after a material or
	palette change is one call"; no code was making that call, so the claim was true only in the
	sense that someone *could*. A room built by cloning that folder would inherit the exact
	fragility decision 0017 exists to remove: geometry depending on state that is not in git.

	So the kit is rebuilt from `KitSpec` at every server start. 85 parts is nothing, and it makes
	`ServerStorage.Kit` a genuine build artifact rather than a fossil.

	Sources: WorkshopSpec · decisions 0001, 0017 · PITFALLS #22 (PivotTo), #39 (colour), #52
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KitFolder = ReplicatedStorage:WaitForChild("Kit", 20)
local KitSpec = require(KitFolder:WaitForChild("KitSpec", 20))
local KitBuilder = require(KitFolder:WaitForChild("KitBuilder", 20))
local WorkshopSpec = require(ReplicatedStorage:WaitForChild("Workshop", 20):WaitForChild("WorkshopSpec", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Workshop")

local WorkshopBuilder = {}

WorkshopBuilder.FOLDER_NAME = "Workshop"

local T = KitSpec.TILE
local MIN, MAX = WorkshopSpec.TILE_MIN, WorkshopSpec.TILE_MAX

--------------------------------------------------------------------------------
-- Placing.
--------------------------------------------------------------------------------

local kitRoot: Folder? = nil

local function templateFor(pieceId: string): Model?
	local root = kitRoot
	if not root then
		return nil
	end
	local piece = KitSpec.byId(pieceId)
	if not piece then
		return nil
	end
	local category = root:FindFirstChild(piece.category)
	local model = category and category:FindFirstChild(pieceId)
	return (model and model:IsA("Model")) and model or nil
end

--- Place one kit piece. Returns the placed model, or nil if the piece does not exist.
---
--- ⚠️ `PivotTo`, and `KitBuilder` deliberately leaves every piece WITHOUT a `PrimaryPart` and with
--- `WorldPivot = CFrame.new()`. A `PrimaryPart` silently overrides `WorldPivot`, which is how an
--- imported model can land a hundred studs from where it was told to go (PITFALLS #22). Because
--- the pivot is the spec's own origin — the floor plane — `PivotTo(x, 0, z)` puts the piece's feet
--- on the floor, which is what every offset in `WorkshopSpec` assumes.
local function place(pieceId: string, pos: Vector3, rotY: number, parent: Instance): Model?
	local template = templateFor(pieceId)
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

--------------------------------------------------------------------------------
-- The room.
--------------------------------------------------------------------------------

local function buildFloor(parent: Instance): number
	local n = 0
	for tx = MIN, MAX do
		for tz = MIN, MAX do
			-- Hazard stripe rings the deck edge; a grated cross marks the walking routes between
			-- stations. Style §5: hazard-striped floor edging is a recurring kit element, and gold
			-- is only ever allowed as a STRIPE, never a solid fill.
			local onEdge = tx == MIN or tx == MAX or tz == MIN or tz == MAX
			local onWalkway = tx == 0 or tz == 0
			local piece = if onEdge then "Floor_Hazard" elseif onWalkway then "Floor_Grated" else "Floor_Plain"
			if place(piece, Vector3.new(tx * T, 0, tz * T), 0, parent) then
				n += 1
			end
		end
	end
	return n
end

--- The perimeter, with a real gap in the east run for the Arena.
local function buildWalls(parent: Instance): (number, number)
	local n, skipped = 0, 0
	local ap = WorkshopSpec.APERTURE
	local halfX, halfZ = WorkshopSpec.HALF_X, WorkshopSpec.HALF_Z

	for t = MIN, MAX do
		-- north (z = -half) and south (z = +half): the run is along X, so no rotation
		if place("Wall_Solid", Vector3.new(t * T, 0, -halfZ), 0, parent) then n += 1 end
		if place("Wall_Solid", Vector3.new(t * T, 0, halfZ), 0, parent) then n += 1 end

		-- west (x = -half): run along Z, so rotate 90
		if place("Wall_Solid", Vector3.new(-halfX, 0, t * T), 90, parent) then n += 1 end

		-- east (x = +half): the same run, MINUS the aperture. This gap is the only reason
		-- decision 0001 holds -- the Arena has to be visible from in here.
		if t >= ap.from and t <= ap.to then
			skipped += 1
		elseif place("Wall_Solid", Vector3.new(halfX, 0, t * T), 90, parent) then
			n += 1
		end
	end

	-- corners, and a pillar either side of the aperture so the gap reads as an opening rather
	-- than as missing geometry
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		if place("Struct_Pillar", Vector3.new(c[1] * halfX, 0, c[2] * halfZ), 0, parent) then n += 1 end
	end
	if place("Struct_Pillar", Vector3.new(halfX, 0, (ap.from - 1) * T), 0, parent) then n += 1 end
	if place("Struct_Pillar", Vector3.new(halfX, 0, (ap.to + 1) * T), 0, parent) then n += 1 end

	return n, skipped
end

--------------------------------------------------------------------------------
-- Signage.
--------------------------------------------------------------------------------

--- Recolour a sign's neon panel and write its name on it.
---
--- ⚠️ The neon part is found by its MATERIAL, not by its index in the piece. `KitBuilder` names
--- parts `<pieceId>_<n>` where n is the child count at the time, so an index is a position in a
--- list that a spec edit silently renumbers -- exactly the kind of coupling PITFALLS #52 is about.
--- Material is what the thing actually IS.
local function dressSign(sign: Model, label: string, hex: string): boolean
	local color = Color3.fromHex(hex)
	local panel: BasePart? = nil
	for _, d in ipairs(sign:GetDescendants()) do
		if d:IsA("BasePart") and d.Material == Enum.Material.Neon then
			panel = d
			break
		end
	end
	if not panel then
		return false
	end
	panel.Color = color
	for _, d in ipairs(panel:GetChildren()) do
		if d:IsA("PointLight") then
			d.Color = color
			-- Style §4: decorative lights never cast. The budget is 8 shadow-casters visible at
			-- once, and seven station signs would eat it on their own.
			d.Shadows = false
		end
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	-- The panel is offset +0.9 on Z from its housing, so the face the player sees is +Z, which
	-- Roblox calls Back. (Front is -Z. This is the one that catches everyone.)
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0 -- it is a lit sign, not a painted one
	gui.Parent = panel

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = label
	-- Bangers, the display face: all-caps station names are exactly what style §7 reserves it for.
	text.FontFace = Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Regular)
	text.TextColor3 = Color3.fromHex("#14161C") -- dark on a lit panel, so it reads as cut-out
	text.TextScaled = true
	text.Parent = text.Parent or gui
	text.Parent = gui
	return true
end

local function buildStations(parent: Instance): (number, { string })
	local n, problems = 0, {}
	for _, s in ipairs(WorkshopSpec.STATIONS) do
		local centre = WorkshopSpec.stationPosition(s)
		local group = folder(s.id, parent)
		group:SetAttribute("StationId", s.id)
		group:SetAttribute("StationLabel", s.label)
		group:SetAttribute("SignalColor", s.color)
		-- ⚠️ The owner is stamped onto the instance, not only written in the spec. A station that
		-- is still scenery is then visible in the Explorer, not only in a file nobody opens.
		group:SetAttribute("Owner", s.owner)

		local plinth = place("Struct_Platform", centre, s.facing, group)
		if not plinth then
			table.insert(problems, ("station %q: Struct_Platform is missing from the kit"):format(s.id))
		end

		-- the sign stands just behind the plinth, against the wall it faces away from
		local back = CFrame.Angles(0, math.rad(s.facing), 0):VectorToWorldSpace(Vector3.new(0, 0, -T * 1.5))
		local sign = place("Sign_NeonSlab", centre + back, s.facing, group)
		if not sign then
			table.insert(problems, ("station %q: Sign_NeonSlab is missing from the kit"):format(s.id))
		elseif not dressSign(sign, s.label, s.color) then
			table.insert(problems, ("station %q: its sign has no Neon panel to light"):format(s.id))
		else
			n += 1
		end

		for _, d in ipairs(s.dressing or {}) do
			local offset = Vector3.new(d.offset[1], d.offset[2], d.offset[3])
			local world = CFrame.Angles(0, math.rad(s.facing), 0):VectorToWorldSpace(offset)
			if not place(d.piece, centre + world, s.facing + (d.rot or 0), group) then
				table.insert(problems, ("station %q: dressing piece %q is missing from the kit"):format(s.id, d.piece))
			end
		end
	end
	return n, problems
end

--------------------------------------------------------------------------------
-- The sightline. Decision 0001 stands or falls on this.
--------------------------------------------------------------------------------

--- Cast from the spawn to `ARENA_ANCHOR` and report what, if anything, is in the way.
---
--- ⚠️ This is the check that can actually fail, and it is the reason the Arena aperture is a real
--- gap rather than a `Wall_Window`: glass would stop the ray, and a sightline test that a pane of
--- glass satisfies is not testing what decision 0001 claims.
function WorkshopBuilder.sightline(): (boolean, string)
	local from = WorkshopSpec.SPAWN + Vector3.new(0, WorkshopSpec.EYE, 0)
	local to = WorkshopSpec.ARENA_ANCHOR
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { workspace:FindFirstChild("Terrain") :: Instance }
	params.IgnoreWater = true

	local hit = workspace:Raycast(from, to - from, params)
	if not hit then
		return true, ("clear: %0.f studs from the spawn to the Arena anchor"):format((to - from).Magnitude)
	end
	return false, ("BLOCKED by %s at %.0f studs -- decision 0001 requires the Arena to be visible from the Workshop")
		:format(hit.Instance:GetFullName(), (hit.Position - from).Magnitude)
end

--------------------------------------------------------------------------------

--- Everything wrong before a single part is placed.
function WorkshopBuilder.validate(): { string }
	local problems = WorkshopSpec.validate()
	for _, p in ipairs(KitBuilder.validate()) do
		table.insert(problems, "kit: " .. p)
	end
	return problems
end

--- Build (or rebuild) the Workshop. Returns (folder, parts placed, problems).
function WorkshopBuilder.build(): (Folder?, number, { string })
	local problems = WorkshopBuilder.validate()
	if #problems > 0 then
		-- Refuse. A misaligned room is worse than no room, because it looks nearly right --
		-- the same reasoning as KitBuilder.buildAll, and the same `Folder?` return so a caller
		-- cannot index it without handling the failure.
		return nil, 0, problems
	end

	-- 🔴 See the header: the kit is rebuilt from the spec, every start, so that nothing below
	-- depends on state that only exists inside the .rbxl.
	local kit, pieces, kitProblems = KitBuilder.buildAll(ServerStorage)
	if not kit then
		return nil, 0, kitProblems
	end
	kitRoot = kit
	Log.info("kit rebuilt from spec: %d pieces", pieces)

	local existing = workspace:FindFirstChild(WorkshopBuilder.FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	local root = folder(WorkshopBuilder.FOLDER_NAME, workspace)

	local floorN = buildFloor(folder("Floor", root))
	local wallN, skipped = buildWalls(folder("Shell", root))
	local signN, stationProblems = buildStations(folder("Stations", root))
	for _, p in ipairs(stationProblems) do
		table.insert(problems, p)
	end

	-- the spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "WorkshopSpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(WorkshopSpec.SPAWN + Vector3.new(0, 0.5, 0))
	spawn.Duration = 0 -- no forcefield: this is a safe hub, and a glowing bubble says otherwise
	spawn.Parent = root

	local parts = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end

	Log.info("built: %d floor tiles, %d shell pieces (%d skipped for the Arena aperture), %d signs, %d parts",
		floorN, wallN, skipped, signN, parts)

	local clear, why = WorkshopBuilder.sightline()
	if clear then
		Log.info("Arena sightline %s", why)
	else
		Log.error("Arena sightline %s", why)
		table.insert(problems, "sightline: " .. why)
	end

	return root, parts, problems
end

return WorkshopBuilder
