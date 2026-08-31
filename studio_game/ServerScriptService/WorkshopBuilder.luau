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
	-- ⚠️ At the gap EDGE, not at the centre of the neighbouring wall tile.
	-- `(ap.from - 1) * T` is a tile centre, which sits 4 studs inside the adjacent wall panel --
	-- measured by review at 36 studs^3 of pillar buried in wall, with the pillar's near face
	-- stopping 2 studs short of the opening it was supposed to frame. The gap's real edges are at
	-- `(ap.from * T) - T/2` and `(ap.to * T) + T/2`.
	local gapMin = ap.from * T - T / 2
	local gapMax = ap.to * T + T / 2
	if place("Struct_Pillar", Vector3.new(halfX, 0, gapMin), 0, parent) then n += 1 end
	if place("Struct_Pillar", Vector3.new(halfX, 0, gapMax), 0, parent) then n += 1 end

	return n, skipped
end

--- The overhead lamp run. Four walls, three lamps each, minus any that would hang in the Arena
--- aperture -- a lamp there would be floating in a hole in the wall.
local function buildLamps(parent: Instance): (number, number)
	local n, skipped = 0, 0
	local halfX, halfZ = WorkshopSpec.HALF_X, WorkshopSpec.HALF_Z
	local inset = WorkshopSpec.LAMP_INSET
	local ap = WorkshopSpec.APERTURE

	for _, t in ipairs(WorkshopSpec.LAMP_TILES) do
		local along = t * T
		-- north and south: the run is along X
		if place(WorkshopSpec.LAMP_PIECE, Vector3.new(along, 0, -halfZ + inset), 0, parent) then n += 1 end
		if place(WorkshopSpec.LAMP_PIECE, Vector3.new(along, 0, halfZ - inset), 180, parent) then n += 1 end
		-- west: run along Z
		if place(WorkshopSpec.LAMP_PIECE, Vector3.new(-halfX + inset, 0, along), 90, parent) then n += 1 end
		-- east: the same, minus the aperture
		if t >= ap.from and t <= ap.to then
			skipped += 1
		elseif place(WorkshopSpec.LAMP_PIECE, Vector3.new(halfX - inset, 0, along), 270, parent) then
			n += 1
		end
	end

	-- the interior run, over the floor the player walks on
	for _, tile in ipairs(WorkshopSpec.INTERIOR_LAMP_TILES) do
		if place(WorkshopSpec.LAMP_PIECE, Vector3.new(tile[1] * T, 0, tile[2] * T), 0, parent) then
			n += 1
		end
	end
	return n, skipped
end

--------------------------------------------------------------------------------
-- The ground the room stands on.
--------------------------------------------------------------------------------

--- 🔴 Z-FIGHTING. Anything whose TOP surface is level with the floor plane and whose footprint
--- overlaps the room is fighting the floor for every pixel.
---
--- **Measured:** the default `Baseplate` is 2048 x 2048 at y = -8 with a height of 16, so its top
--- is at **exactly y = 0.000** — and every Workshop floor tile's top is at **exactly y = 0.000**.
--- Gap: `0.0000` studs. Two coplanar surfaces give the GPU no way to decide which is in front, so
--- it picks differently per pixel and per frame, and the floor visibly crawls and flickers.
---
--- ⚠️ An earlier version of this job's summary called that arrangement safe — "its top and the
--- floor's top are both y = 0" — which is precisely backwards. Coplanar is the WORST case, not a
--- clearance. The player reported the ground as "glitchy" and they were right.
---
--- This LOWERS the offender rather than deleting it: the Baseplate is the user's place content and
--- the world outside the Workshop walls, so it keeps doing its job two studs down where it cannot
--- fight anything. Deleting default place content is the user's call, not a build script's.
local COPLANAR_EPSILON = 0.05
local CLEARANCE = 2

local function resolveGroundConflicts(): { string }
	local fixed = {}
	local halfX, halfZ = WorkshopSpec.HALF_X, WorkshopSpec.HALF_Z
	local mine = workspace:FindFirstChild(WorkshopBuilder.FOLDER_NAME)

	--- ⚠️ `GetDescendants`, not `GetChildren`. The Baseplate is a direct child in the stock
	--- template, but many places wrap their ground in a Model or Folder -- and there the
	--- z-fighting a player actually reported would have come straight back with no log line.
	---
	--- ⚠️ The ownership test compares against `mine` and TOLERATES nil. An earlier version wrote
	--- `not d:IsDescendantOf(workspace:FindFirstChild("Workshop") or workspace)`, which can never
	--- be false for a direct child of Workspace -- and if the folder were ever missing, the
	--- `or workspace` fallback made it always-false and silently disabled the whole function.
	for _, d in ipairs(workspace:GetDescendants()) do
		--- 🔴 `Terrain` IS a `BasePart`, and so is a `SpawnLocation`.
		---
		--- Measured, on the first run of this function: it "resolved a ground conflict" by moving
		--- **`Workspace.Terrain` down 128 studs**. Terrain's inherited `Position` is not a thing
		--- you are supposed to write, and this function had just decided to write it -- on the
		--- user's place, which is not in git. A `SpawnLocation` was lowered too, which is a spawn,
		--- not ground; spawns are handled separately below.
		---
		--- `IsA("BasePart")` is a wider net than it reads as. This is the explicit list of what
		--- this function is allowed to touch.
		local isGround = d:IsA("BasePart")
			and not d:IsA("Terrain")
			and not d:IsA("SpawnLocation")
			and not d:IsA("MeshPart") -- a decorative mesh at floor level is scenery, not ground
		if isGround and not (mine and d:IsDescendantOf(mine)) then
			--- Rotation-aware extent. Using raw `Size` is the exact mistake `KitBuilder.worldSize`
			--- was written to fix; a rotated slab's footprint is not its Size.
			local cf, size = d.CFrame, d.Size
			local ex = math.abs(cf.RightVector.X) * size.X + math.abs(cf.UpVector.X) * size.Y + math.abs(cf.LookVector.X) * size.Z
			local ez = math.abs(cf.RightVector.Z) * size.X + math.abs(cf.UpVector.Z) * size.Y + math.abs(cf.LookVector.Z) * size.Z
			local top = cf.Position.Y + (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
			local overlaps = math.abs(cf.Position.X) - ex / 2 < halfX and math.abs(cf.Position.Z) - ez / 2 < halfZ

			--- ⚠️ Catches a top ABOVE the floor too, not just level with it. A ground slab poking
			--- 0.25 studs through the floor is worse than one exactly level, and the first version
			--- -- `math.abs(top) < 0.05` -- ignored it while claiming to cover "anything whose top
			--- surface is level with the floor plane".
			if overlaps and top > -COPLANAR_EPSILON then
				if d.Anchored then
					local drop = CLEARANCE + top
					d.Position -= Vector3.new(0, drop, 0)
					table.insert(fixed, ("%s (top was y=%.3f, at or above the floor -- lowered %.1f studs)")
						:format(d:GetFullName(), top, drop))
				else
					table.insert(fixed, ("%s is UNANCHORED and its top is y=%.3f -- left alone; moving it would fight physics")
						:format(d:GetFullName(), top))
				end
			end
		end
	end

	--- 🔴 D11: THERE MUST BE EXACTLY ONE SPAWN.
	---
	--- Workspace is not in git and the stock template ships a `SpawnLocation` at (0, 0.5, 0) --
	--- inside this room. Roblox picks at RANDOM among neutral spawns, so the player might never
	--- stand at `WorkshopSpec.SPAWN`, which is the only point the sightline is actually gated on.
	--- Disabled rather than deleted: it is the user's place content.
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("SpawnLocation") and d.Name ~= "WorkshopSpawn" and d.Enabled then
			d.Enabled = false
			table.insert(fixed, ("%s disabled -- the Workshop owns the spawn, and Roblox picks at random between them")
				:format(d:GetFullName()))
		end
	end

	return fixed
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

	--- The glowing rim, found by MATERIAL rather than by index -- `KitBuilder` names parts by
	--- child count, so an index is a position in a list a spec edit silently renumbers.
	local rim: BasePart? = nil
	for _, d in ipairs(sign:GetDescendants()) do
		if d:IsA("BasePart") and d.Material == Enum.Material.Neon then
			rim = d
			break
		end
	end
	if not rim then
		return false
	end
	rim.Color = color
	for _, d in ipairs(rim:GetChildren()) do
		if d:IsA("PointLight") then
			d.Color = color
			d.Shadows = false -- decorative; the budget is 8 shadow-casters
		end
	end

	--- 🔴 THE LABEL GOES ON THE FRONTMOST FACE, NOT ON THE NEON.
	---
	--- It used to go on the neon part, which was correct while the whole panel was neon. The sign
	--- was then rebuilt to match the concept art -- a DARK face inside a GLOWING rim -- which put
	--- the neon *behind* the face. The `SurfaceGui` went on with it, so every station's name was
	--- rendered behind an opaque dark panel: seven signs reading as black rectangles.
	---
	--- So the face is chosen by GEOMETRY -- whichever part stands furthest forward along the
	--- sign's own facing is the one the player looks at. That stays correct however the piece is
	--- re-authored, which an index or a material test would not.
	--- ⚠️ `PointToObjectSpace`, and the frontmost part is the one with the greatest local **+Z**.
	---
	--- 🔴 `CFrame.LookVector` is the **-Z** axis. An earlier version used it as "forward" and so
	--- picked the part furthest BACK -- it put the label on the sign's housing instead of its
	--- face. Worse, the check written to verify it used `LookVector` too, so the test agreed with
	--- the bug and reported all seven signs clear (PITFALLS #2, again).
	---
	--- Working in the sign's own object space removes the axis question entirely: every offset in
	--- `Sign_NeonSlab` is authored in +Z, so the largest local Z simply IS the visible face.
	local pivot = sign:GetPivot()
	local face: BasePart? = nil
	local bestDepth = -math.huge
	for _, d in ipairs(sign:GetDescendants()) do
		if d:IsA("BasePart") then
			local depth = pivot:PointToObjectSpace(d.Position).Z
			if depth > bestDepth then
				bestDepth, face = depth, d
			end
		end
	end
	if not face then
		return false
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	--- ⚠️ The face the player sees is the part's +Z, which Roblox calls **Back**. `Front` is -Z.
	--- Verified against the built sign, not assumed.
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0 -- a lit sign, not a painted one
	gui.Parent = face

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = label
	-- Bangers, the display face: all-caps station names are what style §7 reserves it for.
	text.FontFace = Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Regular)
	--- White on the dark face, which is what the concept art does. The rim carries the station's
	--- colour; the words stay legible.
	text.TextColor3 = Color3.fromHex("#F2F6FA")
	text.TextScaled = true
	text.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Transparency = 0.35
	stroke.Parent = text

	return true
end

--- Tint the parts of a station machine that carry its accent, and light its face in its own
--- signal colour.
---
--- ⚠️ Found by their stamped `MSSurface`, not by index. `KitBuilder` names parts by child count,
--- so an index is a position in a list a spec edit silently renumbers -- and the builder already
--- stamps the surface for the quality controller, so the marker exists and has a reader.
local function dressMachine(machine: Model, signal: Color3, accent: Color3): boolean
	local litFace = false
	for _, d in ipairs(machine:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Material == Enum.Material.Neon then
				d.Color = signal
				for _, l in ipairs(d:GetChildren()) do
					if l:IsA("PointLight") then
						l.Color = signal
						l.Shadows = false
					end
				end
				litFace = true
			elseif d:GetAttribute("MSSurface") == "PaintedGloss" then
				-- `Color` MULTIPLIES the ColorMap, which is why the variant is authored neutral
				d.Color = accent
			end
		end
	end
	return litFace
end

local function buildStations(parent: Instance): (number, { string })
	local n, problems = 0, {}
	for _, s in ipairs(WorkshopSpec.STATIONS) do
		local centre = WorkshopSpec.stationPosition(s)
		local rot = CFrame.Angles(0, math.rad(s.facing), 0)
		--- Unit vector pointing INTO the room from this station. Every dressing offset is
		--- expressed in this frame, so +Z in the table means "towards the player".
		local fwd = rot:VectorToWorldSpace(Vector3.new(0, 0, 1))

		local group = folder(s.id, parent)
		group:SetAttribute("StationId", s.id)
		group:SetAttribute("StationLabel", s.label)
		group:SetAttribute("SignalColor", s.color)
		group:SetAttribute("Owner", s.owner)

		local signal = Color3.fromHex(s.color)
		local accent = Color3.fromHex(s.accent)

		--- 🔴 A BUILT MACHINE, not a platform with a sign behind it.
		---
		--- The previous version placed a `Struct_Platform` at the station centre and the sign 8
		--- studs BEHIND it. Independent review measured the result: the 16x16 deck cut through
		--- the sign's own base on all seven stations, and from standing eye height the bottom of
		--- the panel only cleared the deck from 151 studs away -- further than the room is wide.
		--- Every station's sign was hidden behind its own plinth. It also read as a market stall
		--- rather than as the wall-sized coloured machines in `assets/concept_art/Arena.png`.
		local machine = place("Station_Machine", centre, s.facing, group)
		if not machine then
			table.insert(problems, ("station %q: Station_Machine is missing from the kit"):format(s.id))
		elseif not dressMachine(machine, signal, accent) then
			table.insert(problems, ("station %q: its machine has no Neon face to light"):format(s.id))
		end

		--- The sign is mounted ON the machine's upper front, above the glowing face -- which is
		--- where the concept art puts it. Nothing stands between the player and the words.
		local signPos = centre + fwd * 2 + Vector3.new(0, 6, 0)
		local sign = place("Sign_NeonSlab", signPos, s.facing, group)
		if not sign then
			table.insert(problems, ("station %q: Sign_NeonSlab is missing from the kit"):format(s.id))
		elseif not dressSign(sign, s.label, s.color) then
			table.insert(problems, ("station %q: its sign has no Neon rim to light"):format(s.id))
		else
			n += 1
		end

		for _, d in ipairs(s.dressing or {}) do
			local offset = Vector3.new(d.offset[1], d.offset[2], d.offset[3])
			local world = rot:VectorToWorldSpace(offset)
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
	local to = WorkshopSpec.ARENA_ANCHOR
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	--- ⚠️ Terrain is NOT excluded any more. It was, and that was backwards: a hill between the
	--- Workshop and the Arena is the single most likely real occluder of a 256-stud outdoor
	--- sightline, and it was the one thing the filter removed.
	params.FilterDescendantsInstances = {}
	params.IgnoreWater = true

	--- 🔴 SAMPLED ACROSS THE FLOOR, not from the one best point.
	---
	--- Spec §8, which decision 0001 quotes, asks for the Arena to be visible "from **much of** the
	--- Workshop". The first version cast a single ray from the spawn -- and the spawn, the anchor
	--- and the aperture all sit at z = 0, so the ray was aimed straight down the axis the gap was
	--- cut on. It passed by construction. Independent review solved the real visibility region and
	--- found it was **29.5 %** of the floor while the check reported "clear".
	---
	--- ⚠️ A second blind spot, and it is subtle: `KitBuilder` sets `CanQuery = false`, which
	--- Roblox only honours on parts under 1 stud thick. So every sub-1-stud kit part -- a sign's
	--- 0.4 neon panel, a gate's neon strip -- is INVISIBLE to a raycast. A sign whose only
	--- intersecting part is its glowing face would read as clear. Everything >= 1 stud does block,
	--- so the aperture test still has teeth; this is recorded because the gap is not obvious.
	local clear, total = 0, 0
	local step = KitSpec.TILE * 2
	for x = -WorkshopSpec.HALF_X + step, WorkshopSpec.HALF_X - step, step do
		for z = -WorkshopSpec.HALF_Z + step, WorkshopSpec.HALF_Z - step, step do
			local from = Vector3.new(x, WorkshopSpec.EYE, z)
			total += 1
			if not workspace:Raycast(from, to - from, params) then
				clear += 1
			end
		end
	end

	local pct = if total > 0 then clear / total * 100 else 0
	--- "Much of the Workshop" is not a number anyone has written down, so this states the measured
	--- fraction rather than inventing a threshold and calling it a pass. What it DOES gate is the
	--- spawn: if the Arena is not visible from where the player arrives, decision 0001 is broken
	--- outright rather than merely weak.
	local spawnEye = WorkshopSpec.SPAWN + Vector3.new(0, WorkshopSpec.EYE, 0)
	local spawnHit = workspace:Raycast(spawnEye, to - spawnEye, params)
	if spawnHit then
		return false, ("BLOCKED FROM THE SPAWN by %s at %.0f studs -- decision 0001 requires the Arena to be visible from the Workshop (%.0f%% of the floor has a view)")
			:format(spawnHit.Instance:GetFullName(), (spawnHit.Position - spawnEye).Magnitude, pct)
	end
	return true, ("clear from the spawn; the Arena is visible from %.0f%% of the floor (%d of %d sample points)")
		:format(pct, clear, total)
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
	local lampN, lampSkipped = buildLamps(folder("Lights", root))
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

	Log.info("built: %d floor tiles, %d shell pieces (%d skipped for the aperture), %d lamps (%d skipped), %d signs, %d parts",
		floorN, wallN, skipped, lampN, lampSkipped, signN, parts)

	-- ⚠️ AFTER the room exists, so the footprint test has something to test against.
	for _, fix in ipairs(resolveGroundConflicts()) do
		Log.warn("ground conflict resolved: %s", fix)
	end

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
