--!strict
--[[
	RoomExport — turns a hand-placed room into a Luau module, and back again.

	🔴 WHY THIS EXISTS. Decision 0023 makes every place hand-placed in the editor. `Workspace` does
	not sync, so a placed room lives ONLY in the unversioned `.rbxl`. Decision 0019 saw this coming
	and demanded the fix in its own words:

	    "The export must actually be written and actually be run, or this record is just permission
	     to lose the room."

	It was never written. `Config/WorkshopLayout.luau` is the hand-typed stand-in, and it has
	already drifted -- it documents backdrop layers L1_COLLAR..L5_ROOF while the world contains
	`Backdrop.L7_roof`. That drift is the argument for this module in one line: a hand-typed
	snapshot records what someone MEANT to build.

	🔴 THIS IS A RECOVERY TOOL, NOT A BUILD PIPELINE. Decision 0023 forbids regenerating a room --
	that is precisely what would erase the owner's hand-fixes. `restore` exists to bring a room
	back after a crash or a bad delete, into an EMPTY parent, and it refuses to overwrite. Nothing
	calls it on boot.

	USAGE (command bar, Edit):
	    local RoomExport = require(game.ServerScriptService.RoomExport)
	    print(RoomExport.toLuau(workspace.Zones.COLOR_WORKSHOP, "Zone1Room"))
	    -- paste into studio_game/ReplicatedStorage/Rooms/Zone1Room.luau

	Sources: decisions 0019, 0023 - PITFALLS #10 (Studio Sync is two-way)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Export")

local RoomExport = {}

--- Properties captured per class. Deliberately a WHITELIST: an exporter that walks every property
--- captures read-only and engine-derived ones too, and the restore then errors on the first of
--- them. Anything not listed here is not preserved, and that is a stated limit rather than a
--- surprise -- see `RoomExport.LIMITS`.
local BASEPART_PROPS = {
	"Size", "Anchored", "CanCollide", "CanQuery", "CanTouch", "Massless",
	"Material", "Color", "Transparency", "Reflectance", "CastShadow",
	"CollisionGroup", "Shape",
}

local EXTRA_PROPS: { [string]: { string } } = {
	MeshPart = { "MeshId", "TextureID", "CollisionFidelity", "DoubleSided" },
	SpecialMesh = { "MeshId", "TextureId", "Scale", "Offset", "MeshType" },
	Decal = { "Texture", "Face", "Color3", "Transparency" },
	Texture = { "Texture", "Face", "StudsPerTileU", "StudsPerTileV" },
	PointLight = { "Brightness", "Color", "Range", "Shadows", "Enabled" },
	SpotLight = { "Brightness", "Color", "Range", "Angle", "Face", "Shadows", "Enabled" },
	SurfaceLight = { "Brightness", "Color", "Range", "Angle", "Face", "Shadows", "Enabled" },
	Attachment = {},
	UIListLayout = {},
}

RoomExport.LIMITS = {
	"SurfaceAppearance children are recorded by asset id only -- a restored part gets the ids back, "
		.. "but PITFALLS #63 still applies: a script cannot author a NEW SurfaceAppearance's textures.",
	"Scripts, constraints, ParticleEmitters, Beams and Trails are NOT exported. A room that needs "
		.. "them is not purely placed geometry, and pretending otherwise would restore a broken room.",
	"UnionOperations and Terrain are NOT exportable this way -- unions have no reproducible source.",
}

--------------------------------------------------------------------------------
-- Serialising.
--------------------------------------------------------------------------------

local function fmt(n: number): string
	--- Round hard. Full float precision makes a 3,000-part diff unreadable, and 0.001 studs is
	--- far below anything a human placed on purpose.
	local r = math.floor(n * 1000 + 0.5) / 1000
	return (("%g"):format(r))
end

local function serialise(v: any): string?
	local t = typeof(v)
	if t == "number" then
		return fmt(v)
	elseif t == "boolean" then
		return tostring(v)
	elseif t == "string" then
		return ("%q"):format(v)
	elseif t == "Vector3" then
		return ("V(%s,%s,%s)"):format(fmt(v.X), fmt(v.Y), fmt(v.Z))
	elseif t == "Color3" then
		return ("C(%d,%d,%d)"):format(
			math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5))
	elseif t == "CFrame" then
		local c = { v:GetComponents() }
		local parts = {}
		for _, n in ipairs(c) do
			table.insert(parts, fmt(n))
		end
		return ("CF(%s)"):format(table.concat(parts, ","))
	elseif t == "EnumItem" then
		return ("Enum.%s.%s"):format(tostring(v.EnumType), v.Name)
	end
	return nil
end

local function propsFor(inst: Instance): { string }
	local out = {}
	local names: { string } = {}

	if inst:IsA("BasePart") then
		for _, p in ipairs(BASEPART_PROPS) do
			table.insert(names, p)
		end
		--- CFrame separately: it must come AFTER Size, or a resize moves the part.
		table.insert(names, "CFrame")
	end
	for _, p in ipairs(EXTRA_PROPS[inst.ClassName] or {}) do
		table.insert(names, p)
	end

	for _, name in ipairs(names) do
		--- ⚠️ pcall'd per property. `Shape` exists on Part but not MeshPart, `Color` throws on
		--- some classes, and a whitelist that is right today drifts as Roblox changes. A missing
		--- property must skip, never abort a 3,000-part export.
		local ok, value = pcall(function()
			return (inst :: any)[name]
		end)
		if ok then
			local s = serialise(value)
			if s then
				table.insert(out, ("%s = %s"):format(name, s))
			end
		end
	end

	local attrs = inst:GetAttributes()
	local attrNames = {}
	for k in pairs(attrs) do
		table.insert(attrNames, k)
	end
	table.sort(attrNames)
	if #attrNames > 0 then
		local bits = {}
		for _, k in ipairs(attrNames) do
			local s = serialise(attrs[k])
			if s then
				table.insert(bits, ("[%q] = %s"):format(k, s))
			end
		end
		if #bits > 0 then
			table.insert(out, ("attributes = {%s}"):format(table.concat(bits, ", ")))
		end
	end

	return out
end

local SKIP = {
	Script = true, LocalScript = true, ModuleScript = true,
	ParticleEmitter = true, Beam = true, Trail = true,
	Weld = true, WeldConstraint = true, Motor6D = true,
}

--- Walk one instance into a flat list of `{path, class, props}` records.
local function walk(inst: Instance, path: string, out: { string }, stats: { [string]: number })
	if SKIP[inst.ClassName] then
		stats.skipped += 1
		return
	end
	if inst:IsA("UnionOperation") then
		stats.unions += 1
		return
	end

	local props = propsFor(inst)
	table.insert(out, ('\t{ path = %q, class = %q, props = { %s } },')
		:format(path, inst.ClassName, table.concat(props, ", ")))
	stats.exported += 1

	if inst:IsA("BasePart") then
		local sa = inst:FindFirstChildOfClass("SurfaceAppearance")
		if sa then
			table.insert(out, ('\t{ path = %q, class = "SurfaceAppearance", props = { ColorMap = %q, NormalMap = %q, MetalnessMap = %q, RoughnessMap = %q } },')
				:format(path .. "/" .. sa.Name, sa.ColorMap, sa.NormalMap, sa.MetalnessMap, sa.RoughnessMap))
			stats.exported += 1
		end
	end

	for _, child in ipairs(inst:GetChildren()) do
		if not child:IsA("SurfaceAppearance") then
			walk(child, path .. "/" .. child.Name, out, stats)
		end
	end
end

--------------------------------------------------------------------------------
-- The public API.
--------------------------------------------------------------------------------

--- Export `model` as the source of a Luau module named `moduleName`.
function RoomExport.toLuau(model: Instance, moduleName: string): (string, { [string]: number })
	local rows: { string } = {}
	local stats = { exported = 0, skipped = 0, unions = 0 }

	for _, child in ipairs(model:GetChildren()) do
		walk(child, child.Name, rows, stats)
	end

	local head = {
		"--!strict",
		"--[[",
		("\t%s -- GENERATED by RoomExport. Do NOT hand-edit, and do NOT run it over a live room."):format(moduleName),
		"",
		"\t🔴 This is a RECOVERY snapshot, not a build script. Decision 0023: places are placed by",
		"\thand and never regenerated -- re-running a builder over a room erases the owner's fixes.",
		"\t`RoomExport.restore` refuses a non-empty parent for exactly that reason.",
		"",
		("\tExported %d instances (%d skipped, %d unions dropped)."):format(
			stats.exported, stats.skipped, stats.unions),
		"]]",
		"",
		"local V, C, CF = Vector3.new, Color3.fromRGB, CFrame.new",
		"",
		("local %s = {}"):format(moduleName),
		"",
		("%s.PARTS = {"):format(moduleName),
	}
	local tail = {
		"}",
		"",
		("return %s"):format(moduleName),
		"",
	}

	return table.concat(head, "\n") .. "\n" .. table.concat(rows, "\n") .. "\n"
		.. table.concat(tail, "\n"), stats
end

--- Rebuild a room from an exported module, into `parent`.
---
--- 🔴 Refuses a parent that already has children. Decision 0023 makes overwriting a placed room the
--- one thing this file must never do, and "it was empty, I checked" is not a guarantee a script
--- should take on trust.
function RoomExport.restore(data: { PARTS: { any } }, parent: Instance): (boolean, string)
	if #parent:GetChildren() > 0 then
		return false, ("%s already has %d children -- restore only into an EMPTY parent, or you are "
			.. "overwriting a placed room (decision 0023)"):format(parent:GetFullName(), #parent:GetChildren())
	end

	local made: { [string]: Instance } = {}
	local count = 0

	for _, row in ipairs(data.PARTS) do
		local inst = Instance.new(row.class)
		local segments = string.split(row.path, "/")
		inst.Name = segments[#segments]

		local props = row.props or {}
		local attrs = props.attributes

		--- ⚠️ Size BEFORE CFrame, always. Setting CFrame first and then resizing moves the part
		--- around its centre and silently shifts everything by half the delta.
		if props.Size ~= nil then
			(inst :: any).Size = props.Size
		end
		for k, v in pairs(props) do
			if k ~= "attributes" and k ~= "Size" then
				pcall(function()
					(inst :: any)[k] = v
				end)
			end
		end
		if attrs then
			for k, v in pairs(attrs) do
				inst:SetAttribute(k, v)
			end
		end

		--- Parent to the recorded path, falling back to the room root.
		local parentPath = table.concat(segments, "/", 1, #segments - 1)
		inst.Parent = (#segments > 1 and made[parentPath]) or parent
		made[row.path] = inst
		count += 1
	end

	return true, ("restored %d instances into %s"):format(count, parent:GetFullName())
end

--------------------------------------------------------------------------------
-- A check that can fail.
--------------------------------------------------------------------------------

--- 🔴 Decision 0023's check, as code: export a room, restore it into an empty folder, and compare.
--- Until this returns true once, the room is SAVED, not EXPORTED.
---
--- Compares counts and the bounding box, because those are the two things that go wrong: a dropped
--- class (count) and a property applied in the wrong order (box).
function RoomExport.roundTrip(model: Model): (boolean, string)
	local source, stats = RoomExport.toLuau(model, "RoundTrip")

	--- Compile the emitted source in-place. If the export does not even load, everything below is
	--- meaningless -- and a snapshot that cannot be loaded is the exact failure 0019 warned about.
	if type(loadstring) ~= "function" then
		return false, "loadstring unavailable -- run roundTrip from the command bar in Edit"
	end
	local fn, err = (loadstring :: any)(source)
	if not fn then
		return false, ("the exported source does not compile: %s"):format(tostring(err))
	end
	local data = fn()

	local scratch = Instance.new("Folder")
	scratch.Name = "__RoundTrip"
	scratch.Parent = workspace

	local ok, why = RoomExport.restore(data, scratch)
	if not ok then
		scratch:Destroy()
		return false, why
	end

	local originalCount = #model:GetDescendants()
	local restoredCount = #scratch:GetDescendants()
	local _, sizeA = model:GetBoundingBox()

	--- A Folder has no bounding box, so wrap it to measure.
	local wrapper = Instance.new("Model")
	wrapper.Parent = workspace
	for _, c in ipairs(scratch:GetChildren()) do
		c.Parent = wrapper
	end
	local _, sizeB = wrapper:GetBoundingBox()
	wrapper:Destroy()
	scratch:Destroy()

	local drift = (sizeA - sizeB).Magnitude
	local countOk = restoredCount >= stats.exported
	local boxOk = drift < 0.5

	if countOk and boxOk then
		return true, ("round-trip OK: %d -> %d instances, box drift %.3f studs")
			:format(originalCount, restoredCount, drift)
	end
	return false, ("round-trip FAILED: %d source descendants -> %d restored (expected >= %d); "
		.. "box drift %.3f studs (size %s vs %s)")
		:format(originalCount, restoredCount, stats.exported, drift, tostring(sizeA), tostring(sizeB))
end

return RoomExport
