--!strict
--[[
	RobotAssembler — builds a robot from a LOADOUT, one part per socket.

	This is [decision 0004](../../../docs/decisions/0004-parts-are-content-rig-is-the-engine.md)
	working: *"One hidden robot skeleton with fixed sockets. Every part is a model with a `RobotMount`
	attachment, a slot, an animation profile and stats. Adding a Toilet Brush Arm must never mean
	writing robot code."*

	It replaces job 022's first pass, which cloned `DemoRoom.10_Robots.2_Starter` whole. That worked,
	but it meant every player got a fixed model rather than *their* robot, and a saved loadout would
	have had nothing to build from.

	🔴 MOUNTED BY THE PART'S OWN MOUNT POINT, NEVER BY ITS BOUNDING BOX.

	Each def carries a `mountFrac` -- where its `RobotMount` sits on the part, as a fraction of its
	half-extent. A drum mounts at its centre `(0,0,0)`; a head at its underside `(0,-1,0)`; a wrench
	at `(-0.58,-0.14,0)`, which is nowhere near either. Deriving these from the bounding box would
	hang every part by its middle -- half of it inside the torso. Job 019 paid for that lesson twice
	(the crane's opening, then the smelter's mouth) and PITFALLS records it as
	*"a bounding box is not the feature"*.

	The numbers are MEASURED off `DemoRoom.10_Robots.2_Starter`, the assembly the owner approved, and
	live in `Config/StarterRobot` where git can see them.

	⚠️ WHAT IS STILL .rbxl-ONLY, stated plainly: the rig template (`ReplicatedStorage.RobotRig`) and
	the part meshes (`ServerStorage.ImportedMeshes`) are Models, and **Rojo syncs scripts, not
	models**. This module cannot fix that -- but it moves the *assembly data* (scale, mount point,
	which part goes in which slot) into config, so losing the place file loses art and not knowledge.

	🔴 ONLY THE ROOT IS ANCHORED. A `Motor6D` cannot move an anchored part, so anchoring the whole rig
	makes the stance and every clip silently do nothing -- measured in job 022: 6 joints written, arms
	unmoved at exactly the T-pose angle.

	Sources: decision 0004 · docs/systems/robot-rig · Jobs/022
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local Parts = require(Config:WaitForChild("Parts", 20))
local StarterRobot = require(Config:WaitForChild("StarterRobot", 20))
local PartArt = require(Config:WaitForChild("PartArt", 20))
local MaterialKit = require(ReplicatedStorage:WaitForChild("MaterialKit", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Assembler")

local RobotAssembler = {}

--- Look a part up. Starter stubs live in `StarterRobot`; real parts will come from `PartsCatalog`
--- once anything grants them. Both are checked so a mixed loadout already works.
function RobotAssembler.def(partId: string): any?
	local d = StarterRobot.def(partId)
	if d then
		return d
	end
	local okCatalog, PartsCatalog = pcall(function()
		return require(Config:FindFirstChild("PartsCatalog"))
	end)
	if okCatalog and PartsCatalog then
		for _, p in ipairs(PartsCatalog.ALL) do
			if p.partId == partId then
				--- 🔴 The catalog carries DESIGN (slot, tier, rarity, profiles) and no art. The mesh,
				--- scale and mount point come from `Config/PartArt`, which is measured off the
				--- approved demo assemblies -- finding 0014. Merged here so callers see one def and
				--- do not have to know there are two sources.
				local art = PartArt.get(partId)
				if not art then
					return p -- returned WITHOUT art, so `mount` reports "no mesh field" by name
				end
				local merged = {}
				for k, v in pairs(p) do
					merged[k] = v
				end
				merged.mesh = art.mesh
				merged.scale = art.scale
				merged.mountFrac = art.mountFrac
				--- 🔴 `mountRot` TOO, and its absence here was a real bug. `mount` below reads
				--- `def.mountRot` and this merge set only mesh/scale/mountFrac, so every catalog
				--- part with a measured rotation arrived unrotated: `BLENDER_MOTOR` (92 deg about
				--- X) lying on its side, `GIANT_SPOON` and `FRYING_PAN` (103 deg) and
				--- `GOLDEN_TENDERIZER` (65 deg) pointing the wrong way -- the exact +74 deg
				--- ceiling-pointing failure the note in `mount` documents.
				---
				--- ⚠️ It had never fired because nothing could equip a catalog part until now: the
				--- starter five come from `StarterRobot.def` and return before this branch, and
				--- they carry no `mountRot`. A dead code path is not a working one.
				merged.mountRot = art.mountRot
				--- Which socket the owner actually placed it in, when they placed it. `PartArt`
				--- says outright that hanging either tier-3 arm in the OPPOSITE socket is
				--- unverified, so passing this through lets the caller honour the measured side
				--- rather than taking whichever socket `socketFor` happens to find first.
				merged.measuredIn = art.measuredIn
				--- ⚠️ slot is NOT overridden: the catalog is authoritative on design.
				return merged
			end
		end
	end
	return nil
end

local function meshSource(name: string): BasePart?
	local folder = ServerStorage:FindFirstChild("ImportedMeshes")
	if not folder then
		return nil
	end
	local entry = folder:FindFirstChild(name)
	if not entry then
		return nil
	end
	if entry:IsA("BasePart") then
		return entry
	end
	return entry:FindFirstChildWhichIsA("MeshPart", true)
end

--- Find the socket Attachment for a slot, preferring a named one.
local function socketFor(rig: Instance, slot: string, preferSocket: string?): Attachment?
	local names = Parts.SLOT_TO_SOCKETS[slot]
	if not names then
		return nil
	end
	if preferSocket then
		for _, d in ipairs(rig:GetDescendants()) do
			if d:IsA("Attachment") and d.Name == preferSocket then
				return d
			end
		end
	end
	for _, want in ipairs(names) do
		for _, d in ipairs(rig:GetDescendants()) do
			if d:IsA("Attachment") and d.Name == want then
				return d
			end
		end
	end
	return nil
end

--- Mount one part into one socket. Returns the created MeshPart, or nil with a reason.
function RobotAssembler.mount(rig: Instance, partId: string, preferSocket: string?): (BasePart?, string?)
	local def = RobotAssembler.def(partId)
	if not def then
		return nil, ("unknown partId %q"):format(partId)
	end
	if not def.mesh then
		return nil, ("%s has no mesh field"):format(partId)
	end
	local src = meshSource(def.mesh)
	if not src then
		return nil, ("mesh %q not found in ServerStorage.ImportedMeshes"):format(def.mesh)
	end
	local socket = socketFor(rig, def.slot, preferSocket)
	if not socket then
		return nil, ("no socket for slot %q"):format(tostring(def.slot))
	end

	local part = src:Clone() :: BasePart
	part.Name = partId
	part:SetAttribute("PartId", partId)
	part:SetAttribute("Slot", def.slot)
	part.Parent = rig

	--- uniform scale, measured; `def.scale` is the longest-axis multiplier
	local s = def.scale or 1
	part.Size = part.Size * s

	--- the part's own mount point, from `mountFrac` -- NOT the bounding-box centre
	local frac = def.mountFrac or Vector3.zero
	local local_ = Vector3.new(
		frac.X * part.Size.X / 2,
		frac.Y * part.Size.Y / 2,
		frac.Z * part.Size.Z / 2
	)
	local mount = Instance.new("Attachment")
	mount.Name = Parts.ATTACHMENT_NAME or "RobotMount"
	mount.Position = local_
	mount.Parent = part

	--- 🔴 A MOUNT NEEDS AN ORIENTATION, NOT JUST A POSITION.
	---
	--- `mountFrac` says WHERE on the part the socket grips. It cannot say WHICH WAY the part points,
	--- and that is not academic: the tier-1/2 meshes normalise with their length along local **Y**,
	--- the tier-3 imports along local **X**. A shoulder roll swings a Y-length part DOWN and an
	--- X-length part SIDEWAYS. Measured on the tier-3 robot: with no roll the Giant Spoon sat at
	--- **+74 deg**, pointing at the ceiling.
	---
	--- 🔴 `mountRot` IS A FULL THREE-AXIS ROTATION, in degrees, measured relative to the SOCKET.
	--- It started as a single Z roll derived analytically, then the owner placed the tier-3 parts by
	--- hand and the measurements said otherwise: the blender motor needs **92 deg about X** to stand
	--- upright, and the two arms came out at **103 and 65 deg** -- not mirror images of each other.
	--- One axis and a mirrored sign could not express any of that.
	---
	--- ⚠️ Measured against the socket, so it is INDEPENDENT of the stance: the rig these came off
	--- carried a 62-degree shoulder roll and it cancels. That is what lets the stance live in
	--- `RobotSpawner.STANCE` without double-counting here.
	---
	--- `mountRoll` (a lone Z number) is still honoured for anything that predates `mountRot`.
	local rot = CFrame.identity
	if typeof(def.mountRot) == "Vector3" then
		rot = CFrame.Angles(
			math.rad(def.mountRot.X),
			math.rad(def.mountRot.Y),
			math.rad(def.mountRot.Z)
		)
	elseif def.mountRoll and def.mountRoll ~= 0 then
		local sign = (preferSocket == "RightArmSocket") and -1 or 1
		rot = CFrame.Angles(0, 0, math.rad(def.mountRoll * sign))
	end

	--- Solve for the part CFrame that puts its mount exactly on the socket:
	---   partCF * rot * mountLocal = socketWorld  ->  partCF = socketWorld * rot * mountLocal:Inv
	--- Built from the socket's own WorldCFrame, so it inherits the joint's orientation and follows
	--- the limb when the rig animates.
	---
	--- 🔴 POSITION FIRST, WELD SECOND — the weld below records its offset when it is created.
	--- Repositioning an already-welded part makes the weld fight the new placement, and the whole
	--- assembly tears itself apart the moment it is unanchored. Seen and photographed.
	part.CFrame = socket.WorldCFrame * rot * CFrame.new(local_):Inverse()

	--- weld to the socket's owner, which is the pivot the Motor6D chain drives
	local host = socket.Parent
	if host and host:IsA("BasePart") then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = host
		weld.Part1 = part
		weld.Parent = part
	end

	part.CanCollide = false
	part.CastShadow = true

	--- 🔴 DO NOT SET `CollisionFidelity` HERE. It is a **plugin-capability** property: a normal
	--- server script cannot write it, and the attempt THROWS --
	--- *"The current thread cannot write 'CollisionFidelity' (lacking capability Plugin)"*.
	--- Measured in Play: it took down the whole claim hook, so the player got a bay and a nameplate
	--- and **no robot**, with the only clue one line deep in the log.
	---
	--- ⚠️ This is exactly why the workspace rule says the Studio command bar is PRIVILEGED and gated
	--- property writes must be verified in a real Play script. `execute_luau` writes this happily.
	---
	--- It also does not matter here: the robot is `CanCollide = false` throughout, so no collision
	--- geometry is ever consulted. If a robot later needs to be walked into or shot at, the fidelity
	--- must be set on the SOURCE mesh in `ServerStorage.ImportedMeshes` by a human in Studio, or by
	--- a plugin -- not from gameplay code.

	--- Rusty finish for starter stubs.
	---
	--- 🔴 `TextureID` MUST BE CLEARED FIRST, and this is the whole trick.
	---
	--- `BasePart.Color` multiplies a **`SurfaceAppearance.ColorMap`** -- which is what the style
	--- skill's note is about -- but it does **NOTHING** to a **`MeshPart.TextureID`**. These meshes
	--- arrive from Meshy with a baked `TextureID` and no `SurfaceAppearance`, so the painted texture
	--- wins outright and the part renders bright yellow-and-blue no matter what colour is set.
	---
	--- MEASURED: with `TextureID` intact, tinting to `#8A4B2A` and then to a much darker `#5A4030`
	--- produced two screenshots that were *pixel-indistinguishable* from the untinted one. Clearing
	--- `TextureID` handed control back to `Color` + `MS_Rust` immediately, and the robot reads as
	--- corroded metal.
	---
	--- Losing the painted texture is the POINT, not a side effect: the rusty set exists so that a
	--- found part in fresh paint is a visible upgrade. Same silhouette, stripped finish.
	if def.starterOnly then
		if part:IsA("MeshPart") then
			part.TextureID = ""
		end
		MaterialKit.apply(part, StarterRobot.SURFACE, StarterRobot.TINT)
	end

	return part, nil
end

--- Build a whole robot. `loadout` is `slot -> partId`.
--- Returns the rig, plus a list of problems (empty means everything mounted).
function RobotAssembler.build(loadout: { [string]: string }): (Instance?, { string })
	local problems = {}
	local template = ReplicatedStorage:FindFirstChild(StarterRobot.RIG_TEMPLATE)
	if not template then
		table.insert(problems, ("rig template ReplicatedStorage.%s not found -- it is a Model, so it "
			.. "exists only in the .rbxl"):format(StarterRobot.RIG_TEMPLATE))
		return nil, problems
	end

	local rig = template:Clone()
	rig.Name = "OwnedRobot"

	--- deterministic order, so two identical loadouts build identically and an Arm always lands in
	--- the same socket. `pairs` order is not stable and would make this flaky.
	local order = { "Body", "Core", "Head", "Mobility", "Arm", "Back" }
	local armIndex = 0
	for _, slot in ipairs(order) do
		local partId = loadout[slot]
		if partId then
			local prefer = nil
			if slot == "Arm" then
				--- one arm goes left, a second goes right. The starter has one.
				armIndex += 1
				prefer = (armIndex == 1) and "LeftArmSocket" or "RightArmSocket"
			end
			local part, why = RobotAssembler.mount(rig, partId, prefer)
			if not part then
				--- announce the empty socket instead of substituting something (non-negotiable #10)
				table.insert(problems, ("%s/%s: %s"):format(slot, partId, tostring(why)))
			end
		end
	end

	--- 🔴 root anchored, everything else free, or nothing animates
	local root = (rig :: any).PrimaryPart or rig:FindFirstChild("RobotRoot", true)
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = (d == root)
			d.CanCollide = false
		end
	end
	if not root then
		table.insert(problems, "no root part -- rig cannot be anchored, it will fall")
	end

	return rig, problems
end

return RobotAssembler
