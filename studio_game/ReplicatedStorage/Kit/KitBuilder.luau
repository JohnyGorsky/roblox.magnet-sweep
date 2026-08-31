--!strict
--[[
	KitBuilder — turns KitSpec data into real Instances.

	Decision 0017: the kit is generated, not hand-built. This module is the "generated" half.
	It is idempotent -- building twice replaces rather than duplicates -- so regenerating the
	whole kit after a material or palette change is one call.

	Everything is surfaced through `MaterialKit`, never a raw Material, which is what lets the
	factory re-skin when a variant changes.

	Sources: docs/build/02-industrial-kit.md · decision 0017
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MaterialKit = require(ReplicatedStorage:WaitForChild("MaterialKit"))
local KitSpec = require(script.Parent:WaitForChild("KitSpec"))

local KitBuilder = {}

KitBuilder.FOLDER_NAME = "Kit"

--------------------------------------------------------------------------------
-- Validation.
--
-- The grid exists so piece FOOTPRINTS tile against each other. It does NOT mean every
-- internal detail must sit on it: a 0.4-stud neon inset, a 1.2-stud pipe or a crate's wall
-- thickness are internal and never meet a neighbouring piece. An earlier version of this
-- check required every size and offset to be grid-aligned and rejected 67 legitimate
-- values -- it was enforcing the wrong invariant, and would have forced a crude kit.
--
-- So each piece DECLARES which axes it tiles on (`tiles = { "X", "Z" }`), and only those
-- are checked. A floor tiles on X and Z; a wall tiles along its run (X) only, because its Z
-- footprint is its thickness; a free-standing prop declares nothing. Internal parts are
-- unconstrained either way.
--------------------------------------------------------------------------------

local VALID_SHAPES: { [string]: boolean } = { Ball = true, Cylinder = true, Wedge = true }
local VALID_AXES: { [string]: boolean } = { X = true, Y = true, Z = true }

--- ⚠️ A Roblox Cylinder's length is ALWAYS its Size.X (raw `enums/PartType.yaml`: "a
--- cylinder shape oriented along the X axis"). Size.Y/Z are the cross-section. So a
--- cylinder declares `size = { length, dia, dia }` and names the world axis it runs along,
--- and this is the ONE place that turns that into a rotation. Job 005 originally wrote
--- `{1.5, 1.5, 16}` for a 16-stud pipe and got a 1.5-stud nub: the 16 was ignored outright.
local function orientationOf(part: KitSpec.PartSpec): CFrame
	if part.shape == "Cylinder" then
		local along = part.along or "X"
		if along == "Y" then
			return CFrame.Angles(0, 0, math.rad(90))
		elseif along == "Z" then
			return CFrame.Angles(0, math.rad(90), 0)
		end
		return CFrame.new()
	end
	if part.rot then
		return CFrame.Angles(math.rad(part.rot[1]), math.rad(part.rot[2]), math.rad(part.rot[3]))
	end
	return CFrame.new()
end

local function nearMultiple(v: number, step: number): boolean
	return math.abs(v / step - math.floor(v / step + 0.5)) < 1e-4
end

--- World-space size of one part, AFTER its rotation. An earlier version summed raw
--- `size` on the matching world axis and ignored rotation entirely, so a rotated part at a
--- tiling edge could produce a false pass -- the exact "looks nearly right" failure the
--- validator exists to prevent.
local function worldSize(part: KitSpec.PartSpec): Vector3
	local size = Vector3.new(part.size[1], part.size[2], part.size[3])
	local cf = orientationOf(part)
	-- project the box's half-extents through the rotation
	local rx, ry, rz = cf.RightVector, cf.UpVector, cf.LookVector
	return Vector3.new(
		math.abs(rx.X) * size.X + math.abs(ry.X) * size.Y + math.abs(rz.X) * size.Z,
		math.abs(rx.Y) * size.X + math.abs(ry.Y) * size.Y + math.abs(rz.Y) * size.Z,
		math.abs(rx.Z) * size.X + math.abs(ry.Z) * size.Y + math.abs(rz.Z) * size.Z
	)
end

--- Footprint of a piece on each world axis, from its parts' rotated extents.
local function footprint(piece: KitSpec.Piece): { [string]: number }
	local lo = { X = math.huge, Y = math.huge, Z = math.huge }
	local hi = { X = -math.huge, Y = -math.huge, Z = -math.huge }
	for _, part in ipairs(piece.parts) do
		local ws = worldSize(part)
		local half = { X = ws.X / 2, Y = ws.Y / 2, Z = ws.Z / 2 }
		local off = { X = part.offset[1], Y = part.offset[2], Z = part.offset[3] }
		for _, axis in ipairs({ "X", "Y", "Z" }) do
			lo[axis] = math.min(lo[axis], off[axis] - half[axis])
			hi[axis] = math.max(hi[axis], off[axis] + half[axis])
		end
	end
	return { X = hi.X - lo.X, Y = hi.Y - lo.Y, Z = hi.Z - lo.Z }
end

--- The piece's world-axis BOUNDS about its own origin, as lo/hi per axis.
---
--- ⚠️ Exported because a consumer placing a piece needs to know how far it REACHES, not just how
--- big it is — `footprint` returns extents, which cannot answer "does this cross the wall plane".
--- Job 017 nearly wrote a third copy of the rotation maths in `Zone1Spec`; two is already one too
--- many, and the copy would have read `part.size.X` on what is actually a `{x, y, z}` array.
function KitBuilder.bounds(piece: KitSpec.Piece): { [string]: number }
	local lo = { X = math.huge, Z = math.huge }
	local hi = { X = -math.huge, Z = -math.huge }
	for _, part in ipairs(piece.parts) do
		local ws = worldSize(part)
		local half = { X = ws.X / 2, Z = ws.Z / 2 }
		local off = { X = part.offset[1], Z = part.offset[3] }
		for _, axis in ipairs({ "X", "Z" }) do
			lo[axis] = math.min(lo[axis], off[axis] - half[axis])
			hi[axis] = math.max(hi[axis], off[axis] + half[axis])
		end
	end
	return { loX = lo.X, hiX = hi.X, loZ = lo.Z, hiZ = hi.Z }
end

function KitBuilder.validate(): { string }
	local problems = {}
	local seen: { [string]: boolean } = {}
	for _, piece in ipairs(KitSpec.PIECES) do
		if seen[piece.id] then
			table.insert(problems, ("duplicate piece id %q"):format(piece.id))
		end
		seen[piece.id] = true
		if #piece.parts == 0 then
			table.insert(problems, ("%s has no parts"):format(piece.id))
		end

		for i, part in ipairs(piece.parts) do
			for axis, v in ipairs(part.size) do
				if v <= 0 then
					table.insert(problems, ("%s part %d size axis %d is %s"):format(piece.id, i, axis, tostring(v)))
				end
			end
			if not part.neon and (not part.surface or not MaterialKit.def(part.surface)) then
				table.insert(problems, ("%s part %d uses unknown surface %q"):format(piece.id, i, tostring(part.surface)))
			end
			if part.neon and not part.color then
				table.insert(problems, ("%s part %d is neon with no colour"):format(piece.id, i))
			end
			-- an unknown shape silently built a BLOCK, which is how the cylinder bug shipped
			if part.shape and not VALID_SHAPES[part.shape] then
				table.insert(problems, ("%s part %d has unknown shape %q"):format(piece.id, i, tostring(part.shape)))
			end
			if part.along and part.shape ~= "Cylinder" then
				table.insert(problems, ("%s part %d sets `along` but is not a Cylinder"):format(piece.id, i))
			end
			if part.along and not VALID_AXES[part.along] then
				table.insert(problems, ("%s part %d has unknown axis %q"):format(piece.id, i, tostring(part.along)))
			end
			if part.shape == "Cylinder" and part.rot then
				table.insert(problems, ("%s part %d is a Cylinder with a hand-rolled `rot`; use `along`"):format(piece.id, i))
			end
			-- a bad hex THROWS in Color3.fromHex, after buildAll has already destroyed the
			-- old folder -- leaving no kit at all. Catch it before anything is destroyed.
			if part.color then
				local ok = pcall(Color3.fromHex, part.color)
				if not ok then
					table.insert(problems, ("%s part %d has malformed colour %q"):format(piece.id, i, tostring(part.color)))
				end
			end
		end

		if piece.tiles and #piece.parts > 0 then
			local fp = footprint(piece)
			for _, axis in ipairs(piece.tiles) do
				local extent = fp[axis]
				if extent == nil then
					table.insert(problems, ("%s declares an unknown tiling axis %q"):format(piece.id, tostring(axis)))
				elseif not nearMultiple(extent, KitSpec.GRID) then
					table.insert(problems, ("%s tiles on %s but its %s footprint is %.2f, not a multiple of %d")
						:format(piece.id, axis, axis, extent, KitSpec.GRID))
				end
			end
		end
	end
	return problems
end

--------------------------------------------------------------------------------

local SHAPES: { [string]: Enum.PartType } = {
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}

local function buildPart(spec: KitSpec.PartSpec, parent: Instance): BasePart
	local p: BasePart
	if spec.shape == "Wedge" then
		p = Instance.new("WedgePart")
	else
		local block = Instance.new("Part")
		if spec.shape and SHAPES[spec.shape] then
			block.Shape = SHAPES[spec.shape]
		end
		p = block
	end
	p.Anchored = true
	p.Size = Vector3.new(spec.size[1], spec.size[2], spec.size[3])
	p.CFrame = CFrame.new(spec.offset[1], spec.offset[2], spec.offset[3]) * orientationOf(spec)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth

	-- Instance.new defaults nobody chose. The magnet will run GetPartBoundsInRadius
	-- continuously, so every decorative sliver being query-visible is a real cost.
	p.CanQuery = false
	p.CanTouch = false
	local thin = math.min(p.Size.X, p.Size.Y, p.Size.Z)
	p.CanCollide = thin >= 1 -- trim, insets and lamps should not be standable
	p.CastShadow = thin >= 1 -- a 0.4-stud inset casting a shadow buys nothing on a phone

	if spec.neon then
		-- Neon never takes a MaterialVariant; the glow the player sees is the Bloom pass.
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromHex(spec.color or "#41D8FF")
		local light = Instance.new("PointLight")
		light.Color = p.Color
		light.Brightness = spec.light and spec.light.brightness or 2.5
		light.Range = spec.light and spec.light.range or KitSpec.DEFAULT_LIGHT_RANGE
		light.Shadows = false -- decorative lights never cast; the budget is 8 shadow-casters
		-- tagged so the quality-tier controller can cull it by range without re-walking the
		-- world. MaterialKit stamps MSSurface for the same reason; this is the light half.
		light:SetAttribute("Decorative", true)
		light.Parent = p
	else
		MaterialKit.apply(p, spec.surface, spec.color and Color3.fromHex(spec.color) or nil)
		-- Stamp the surface here as well as in MaterialKit.apply. The builder KNOWS the
		-- surface, and the attribute is load-bearing: the quality-tier controller uses it to
		-- find parts whose variant must be stripped and restored. Depending solely on apply()
		-- means a stale `require` of MaterialKit silently produces an unusable kit -- which is
		-- exactly what happened once in an Edit session. Idempotent; same value either way.
		p:SetAttribute("MSSurface", spec.surface)
	end
	p.Parent = parent
	return p
end

--- Build one piece as a Model with a PrimaryPart, ready to Clone().
function KitBuilder.buildPiece(piece: KitSpec.Piece, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = piece.id
	model:SetAttribute("KitCategory", piece.category)
	model:SetAttribute("KitDesc", piece.desc)

	for _, partSpec in ipairs(piece.parts) do
		local p = buildPart(partSpec, model)
		p.Name = piece.id .. "_" .. tostring(#model:GetChildren())
	end
	model.Parent = parent
	-- ⚠️ NO PrimaryPart. Setting it to parts[1] made every piece pivot at a different height
	-- (Wall_Window at 1.00 where every other wall was 6.00), because a Model with a
	-- PrimaryPart pivots there and IGNORES WorldPivot -- PITFALL #22. These are static
	-- anchored models; Roblox's own docs say such models "tend not to benefit from having
	-- one set". Pivot at the spec's own origin, which is the floor plane, so PivotTo(x,0,z)
	-- means what the spec says it means.
	model.WorldPivot = CFrame.new()
	return model
end

--- Build every piece into `parent`/Kit. Idempotent: replaces an existing folder.
--- Returns (folder, count, problems).
function KitBuilder.buildAll(parent: Instance): (Folder?, number, { string })
	local problems = KitBuilder.validate()
	if #problems > 0 then
		-- refuse: a misaligned kit is worse than no kit, because it looks nearly right.
		-- Returns Folder? so a caller CANNOT index it without handling the failure -- the
		-- previous `nil :: any` laundered it past the type checker.
		return nil, 0, problems
	end

	local existing = parent:FindFirstChild(KitBuilder.FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = KitBuilder.FOLDER_NAME
	folder.Parent = parent

	local byCategory: { [string]: Folder } = {}
	local n = 0
	for _, piece in ipairs(KitSpec.PIECES) do
		local cat: Folder? = byCategory[piece.category]
		if not cat then
			local made = Instance.new("Folder")
			made.Name = piece.category
			made.Parent = folder
			byCategory[piece.category] = made
			cat = made
		end
		KitBuilder.buildPiece(piece, cat :: Folder)
		n += 1
	end
	return folder, n, problems
end

return KitBuilder
