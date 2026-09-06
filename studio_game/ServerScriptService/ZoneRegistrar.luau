--!strict
--[[
	ZoneRegistrar — gives a HAND-PLACED zone its identity.

	🔴 WHY THIS EXISTS. `ZoneManager.register` has exactly one other call site: `ZoneBuilder.build`,
	which never runs (`Bootstrap.BUILD_GENERATED_WORLD = false`). Decision 0023 makes every place
	hand-placed, so without this module **a placed room registers with nothing**.

	That failure is silent and it is the worst one in the job, because of what `nil` now means:

	    decision 0022 -- `zoneContaining` returning nil means THE WORKSHOP, i.e. safe and secured.

	So an unregistered floor 1 reads as the Workshop from inside it: the guardian gives up
	instantly, and a stolen part secures the moment it is detached. **Both tests pass while doing
	nothing.** It looks like "the chase is broken", never like "the registry is empty".

	🔴 MARKERS, NOT BOUNDING BOXES. Job 023 was bitten by this once already: the factory doorway's
	"62 x 24 aperture" was the model's BOUNDING BOX, and the real opening is 42 wide at a different
	centre -- `Infill` fills a third of the box. A bounding box says where the OBJECT is, not where
	its mouth is. So entry/exit come from Attachments placed by hand, and the zone's extent comes
	from an explicit `Bounds` part, never from `model:GetBoundingBox()`.

	WHAT THE EDITOR MUST PROVIDE, per zone model under `Workspace.Zones`:

	    <ZoneModel>
	      Bounds        BasePart, invisible, CanCollide=false, CanQuery=false
	                    Attributes: ZoneId (string), ZoneTier (number)
	        Entry       Attachment -- where the corridor begins; look direction is its LookVector
	        Exit        Attachment -- the door onward to the next zone
	      ScrapVolumes  Folder of BaseParts (optional) -- each one a scrap spawn box

	Sources: decisions 0003, 0021, 0022, 0023 - docs/systems/factory/README.md
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("ZoneReg")
local ZoneManager = require(script.Parent:WaitForChild("ZoneManager", 20))

local ZoneRegistrar = {}

ZoneRegistrar.FOLDER_NAME = "Zones"
ZoneRegistrar.BOUNDS_NAME = "Bounds"

--- How far above and below the Bounds part the zone still counts as "inside".
---
--- ⚠️ `zoneContaining` only tests X and Z (it is an AABB on the horizontal plane), so these are
--- recorded for completeness and for anything that later wants a real 3D test. They are not a
--- second source of truth for the horizontal extent.
local HEADROOM = 64
local UNDERROOM = 32

--------------------------------------------------------------------------------
-- Reading one zone model.
--------------------------------------------------------------------------------

--- 🔴 Returns a REASON on every failure. A zone that silently declines to register is exactly the
--- bug this module exists to prevent, so there is no path here that fails quietly.
local function describeZone(model: Model): ({ [string]: any }?, string?)
	local bounds = model:FindFirstChild(ZoneRegistrar.BOUNDS_NAME)
	if not bounds or not bounds:IsA("BasePart") then
		return nil, ("has no %q BasePart"):format(ZoneRegistrar.BOUNDS_NAME)
	end

	local id = bounds:GetAttribute("ZoneId")
	local tier = bounds:GetAttribute("ZoneTier")
	if type(id) ~= "string" or id == "" then
		return nil, "Bounds has no ZoneId string attribute"
	end
	if type(tier) ~= "number" then
		return nil, ("Bounds has no ZoneTier number attribute (id %q)"):format(id)
	end

	local entry = bounds:FindFirstChild("Entry")
	local exit = bounds:FindFirstChild("Exit")
	if not entry or not entry:IsA("Attachment") then
		return nil, ("%s: Bounds has no Entry Attachment"):format(id)
	end
	if not exit or not exit:IsA("Attachment") then
		return nil, ("%s: Bounds has no Exit Attachment"):format(id)
	end

	--- ⚠️ A rotated Bounds part would make a naive min/max wrong. `GetBoundingBox` on a single
	--- part in world space is not available, so this uses the part's own extents projected onto
	--- the axes -- correct for an axis-aligned part, and loudly wrong for a rotated one, which is
	--- why it is checked rather than assumed.
	local cf = bounds.CFrame
	local rightY = math.abs(cf.RightVector.Y)
	local upY = math.abs(cf.UpVector.Y)
	if rightY > 0.01 or upY < 0.99 then
		return nil, ("%s: Bounds is rotated off-axis -- min/max would be wrong. Keep it axis-aligned"):format(id)
	end

	local pos, size = bounds.Position, bounds.Size
	local halfX, halfZ = size.X / 2, size.Z / 2

	local volumes: { { centre: Vector3, halfX: number, halfZ: number } } = {}
	local folder = model:FindFirstChild("ScrapVolumes")
	if folder then
		for _, v in ipairs(folder:GetChildren()) do
			if v:IsA("BasePart") then
				table.insert(volumes, {
					centre = v.Position,
					halfX = v.Size.X / 2,
					halfZ = v.Size.Z / 2,
				})
			end
		end
	end

	--- The look target is one stud down the Entry attachment's facing, resolved to world space.
	local entryWorld = entry.WorldCFrame
	return {
		id = id,
		tier = tier,
		model = model,
		entry = entryWorld.Position,
		entryLook = entryWorld.Position + entryWorld.LookVector * 16,
		exit = exit.WorldCFrame.Position,
		min = Vector3.new(pos.X - halfX, pos.Y - UNDERROOM, pos.Z - halfZ),
		max = Vector3.new(pos.X + halfX, pos.Y + HEADROOM, pos.Z + halfZ),
		spawnVolumes = volumes,
	}, nil
end

--------------------------------------------------------------------------------
-- Registration.
--------------------------------------------------------------------------------

--- Register every hand-placed zone under `Workspace.Zones`. Returns how many registered, and the
--- problems found. Safe to call again: `ZoneManager.register` refuses duplicate ids, and this
--- unregisters first so a re-placed room can be re-registered.
function ZoneRegistrar.registerAll(): (number, { string })
	local problems: { string } = {}
	local folder = workspace:FindFirstChild(ZoneRegistrar.FOLDER_NAME)
	if not folder then
		--- 🔴 NOT an error yet. Before floor 1 is placed there is legitimately no `Zones` folder,
		--- and a fatal here would block every other system from booting. It IS worth saying out
		--- loud, because the alternative -- silence -- is what makes the nil-means-Workshop trap
		--- invisible.
		Log.warn("no Workspace.%s folder -- no zone is registered, so ZoneManager.zoneContaining "
			.. "returns nil EVERYWHERE. Decision 0022 reads nil as 'the Workshop, safe and secured', "
			.. "so a guardian would give up instantly and a part would secure on detach",
			ZoneRegistrar.FOLDER_NAME)
		return 0, problems
	end

	local count = 0
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") then
			local desc, why = describeZone(model)
			if not desc then
				table.insert(problems, ("%s: %s"):format(model.Name, why or "unknown"))
			else
				ZoneManager.unregister(desc.id)
				if ZoneManager.register(desc :: any) then
					count += 1
				else
					table.insert(problems, ("%s: ZoneManager refused the registration"):format(desc.id))
				end
			end
		end
	end

	return count, problems
end

--------------------------------------------------------------------------------
-- A check that can fail.
--------------------------------------------------------------------------------

--- 🔴 Proves registration BOTH WAYS, which is the whole point.
---
--- Testing only "inside the room returns the zone" cannot distinguish a correct registry from one
--- that returns the same answer everywhere. Testing only "the Workshop returns nil" cannot
--- distinguish a correct registry from an EMPTY one -- and the empty registry is the actual
--- failure mode here. So both, or neither is evidence.
---
--- `outsidePoint` should be a spot in the Workshop, well clear of any zone.
function ZoneRegistrar.verify(zoneId: string, outsidePoint: Vector3): (boolean, string)
	local z = ZoneManager.byId(zoneId)
	if not z then
		return false, ("%q is not registered at all"):format(zoneId)
	end

	local centre = Vector3.new((z.min.X + z.max.X) / 2, 0, (z.min.Z + z.max.Z) / 2)
	local inside = ZoneManager.zoneContaining(centre)
	local outside = ZoneManager.zoneContaining(outsidePoint)

	if not inside or inside.id ~= zoneId then
		return false, ("INSIDE %s at %s returned %s -- the bounds are wrong")
			:format(zoneId, tostring(centre), inside and inside.id or "nil")
	end
	if outside then
		return false, ("OUTSIDE at %s returned %q -- the bounds are too big, and the Workshop now "
			.. "reads as a zone")
			:format(tostring(outsidePoint), outside.id)
	end

	return true, ("%s: inside -> %s, outside -> nil"):format(zoneId, zoneId)
end

return ZoneRegistrar
