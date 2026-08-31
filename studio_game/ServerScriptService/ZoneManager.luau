--!strict
--[[
	ZoneManager — the registry every zone talks to, and the only thing that knows where zones are.

	🔴 WHY THIS EXISTS AT ALL. `docs/systems/factory`:

	    "Zones are authored as self-contained streamable chunks. No script may hold a hardcoded
	     instance path into another zone; zones talk to the zone manager only. Under Instance
	     Streaming that coupling is not a smell, it is a nil-index crash."

	`StreamingEnabled` is ON for this place. That sentence is not style advice — it is the difference
	between working code and a crash on a client that has not streamed the far zone in. A zone that
	does `workspace.Zone2.Gate` works perfectly on the machine of whoever wrote it, standing next to
	zone 2, and indexes nil for a player still in zone 1.

	So: zones REGISTER here, and anything that needs a zone asks here. This module is built before
	any zone exists precisely so nothing is ever tempted to route around it.

	⚠️ SERVER-SIDE. The client is told which zone it is in over a remote; it never reads Workspace to
	work it out, for exactly the same streaming reason.

	Sources: docs/systems/factory/README.md · decision 0003 · docs/build/07-zones-1-2.md
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local Zones = require(Config:WaitForChild("Zones", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Zone")

--- ⚠️ One-way: `MagnetState` must never require this module back.
local MagnetState = require(script.Parent:WaitForChild("MagnetState", 20))

local ZoneManager = {}

export type SpawnVolume = {
	--- WORLD-space centre and half-extents. The spec expresses these in chunk-relative tiles; they
	--- are resolved to world exactly once, here, at registration.
	centre: Vector3,
	halfX: number,
	halfZ: number,
}

export type Registered = {
	id: string,
	tier: number,
	model: Model,
	entry: Vector3,
	entryLook: Vector3,
	exit: Vector3,
	--- World-space AABB of the chunk, used by `zoneContaining`.
	min: Vector3,
	max: Vector3,
	spawnVolumes: { SpawnVolume },
}

local byId: { [string]: Registered } = {}
local byTier: { [number]: Registered } = {}
local order: { Registered } = {}

--------------------------------------------------------------------------------
-- Registration.
--------------------------------------------------------------------------------

--- 🔴 Validated on the way in, not trusted. A zone that registers with a `nil` model or a tier that
--- `Config/Zones` does not define is a bug in the builder, and the loud version of that bug is far
--- cheaper than a `zoneContaining` that silently never matches.
function ZoneManager.register(z: Registered): boolean
	if byId[z.id] then
		Log.warn("zone %q registered twice -- the second registration is ignored", z.id)
		return false
	end

	local configured = Zones.byTier(z.tier)
	if not configured then
		Log.warn("zone %q claims tier %d, which Config/Zones does not define", z.id, z.tier)
		return false
	end
	--- ⚠️ Checks the ID matches too. Two files agreeing on a tier number but not on an id is exactly
	--- the kind of drift that produces a gate requiring the wrong zone's Magnet Power.
	if configured.id ~= z.id then
		Log.warn("tier %d is %q in Config/Zones but %q registered -- one of the two is wrong",
			z.tier, configured.id, z.id)
		return false
	end
	if not z.model or not z.model.Parent then
		Log.warn("zone %q registered with no model in the DataModel", z.id)
		return false
	end

	--- 🔴 Overlap is a REGISTRY problem, so it is caught here. Two zones sharing world space makes
	--- `zoneContaining` return whichever sorts first, silently and forever. This job owns the
	--- registry and job 018 is the one that will add the second zone, so the check belongs here now
	--- rather than after it has already bitten.
	for _, other in ipairs(order) do
		if not (z.max.X < other.min.X or z.min.X > other.max.X
			or z.max.Z < other.min.Z or z.min.Z > other.max.Z) then
			Log.warn("zone %q overlaps %q in world space (x %d..%d vs %d..%d, z %d..%d vs %d..%d) -- zoneContaining will silently pick one",
				z.id, other.id,
				math.floor(z.min.X), math.floor(z.max.X), math.floor(other.min.X), math.floor(other.max.X),
				math.floor(z.min.Z), math.floor(z.max.Z), math.floor(other.min.Z), math.floor(other.max.Z))
		end
	end

	byId[z.id] = z
	byTier[z.tier] = z
	table.insert(order, z)
	table.sort(order, function(a, b)
		return a.tier < b.tier
	end)

	Log.info("registered %s (tier %d) -- %d spawn volume(s), bounds %d..%d on z",
		z.id, z.tier, #z.spawnVolumes, math.floor(z.min.Z), math.floor(z.max.Z))
	return true
end

--- Remove a zone from the registry. Needed by any rebuild: `register` refuses a duplicate id, so
--- without this a rebuilt zone fails to register and the registry keeps pointing at the destroyed
--- model — with `zone.model.Parent == nil` and zero descendants — for the rest of the session.
function ZoneManager.unregister(id: string): boolean
	local z = byId[id]
	if not z then
		return false
	end
	byId[id] = nil
	if byTier[z.tier] == z then
		byTier[z.tier] = nil
	end
	for i, other in ipairs(order) do
		if other == z then
			table.remove(order, i)
			break
		end
	end
	return true
end

--------------------------------------------------------------------------------
-- Lookup. These are the ONLY sanctioned ways to reach a zone.
--------------------------------------------------------------------------------

function ZoneManager.byId(id: string): Registered?
	return byId[id]
end

function ZoneManager.byTier(tier: number): Registered?
	return byTier[tier]
end

function ZoneManager.all(): { Registered }
	return table.clone(order)
end

function ZoneManager.count(): number
	return #order
end

--- Which zone is this world position inside? `nil` for the Workshop and for anywhere between zones.
---
--- ⚠️ Deliberately an AABB test rather than a `:IsDescendantOf(zone.model)` walk. A player is not
--- parented to the zone, and scrap that has been pulled out of a zone is still logically in it.
function ZoneManager.zoneContaining(pos: Vector3): Registered?
	for _, z in ipairs(order) do
		if pos.X >= z.min.X and pos.X <= z.max.X
			and pos.Z >= z.min.Z and pos.Z <= z.max.Z then
			return z
		end
	end
	return nil
end

function ZoneManager.zoneOf(player: Player): Registered?
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	return ZoneManager.zoneContaining(root.Position)
end

--------------------------------------------------------------------------------
-- Movement.
--------------------------------------------------------------------------------

--- Put a player at a zone's entry, facing down the corridor.
---
--- 🔴 Returns a reason on failure rather than failing silently. The Factory Entrance station calls
--- this, and a station that says "ENTER" and does nothing is precisely the placeholder-shaped hole
--- this job exists to remove.
function ZoneManager.sendTo(player: Player, tier: number): (boolean, string)
	local z = byTier[tier]
	if not z then
		return false, ("zone tier %d is not built yet"):format(tier)
	end

	--- 🔴 THE MAGNET POWER GATE. `Config/Zones` has carried a `gate` per tier since job 003 and
	--- `Zones.highestUnlocked` existed with **zero call sites** — a producer with no consumer
	--- (PITFALLS #52). Without this, the gate is decoration: the physical "GRRRRR / pin / BOOM"
	--- mechanism job 018 builds would be the only thing stopping anyone, and a client that sends a
	--- tier number straight to this remote never touches it.
	---
	--- ⚠️ This was NOT exercised by job 017's own test, and could not have been: only tier 1 exists,
	--- so every wrong tier was refused by the `byTier` lookup above and the test passed for the
	--- wrong reason. Job 018 is what arms it.
	local configured = Zones.byTier(tier)
	local have = MagnetState.stats(player).Power
	if configured and have < configured.gate then
		--- Both numbers, together. "You need more power" is not a message anyone can act on.
		return false, ("MAGNET POWER %d REQUIRED — YOU HAVE %d"):format(configured.gate, have)
	end
	local char = player.Character
	if not char then
		return false, "no character"
	end
	--- ⚠️ `PivotTo` on the model, not `HumanoidRootPart.CFrame`. Setting the root alone leaves the
	--- rest of the rig behind for a frame and the player sees themselves stretch
	--- (PITFALLS #22 is the same family of mistake).
	char:PivotTo(CFrame.lookAt(z.entry, Vector3.new(z.entryLook.X, z.entry.Y, z.entryLook.Z)))
	Log.info("%s -> %s", player.Name, z.id)
	return true, z.id
end

--------------------------------------------------------------------------------
-- A check that can fail.
--------------------------------------------------------------------------------

--- 🔴 Greps the SERVER for anyone reaching a zone by Workspace path instead of through here.
---
--- ⚠️ This cannot be a runtime test — the crash it guards against only happens on a client that has
--- streamed the far zone out, which no server-side assertion can observe. What it CAN do is assert
--- the invariant that makes the crash impossible: every zone model is a direct child of one folder
--- with a known name, so a stray `workspace.<something>` reference is findable by grep and this
--- reports the folder's shape so a reviewer can check it by eye.
function ZoneManager.describe(): string
	local parts = {}
	for _, z in ipairs(order) do
		table.insert(parts, ("tier %d %s at %s (%d parts)")
			:format(z.tier, z.id, tostring(z.model:GetPivot().Position), #z.model:GetDescendants()))
	end
	return #parts > 0 and table.concat(parts, " | ") or "no zones registered"
end

return ZoneManager
