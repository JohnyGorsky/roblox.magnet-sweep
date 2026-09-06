--!strict
--[[
	BaseClaimService — gives each player a workstation, and takes it back when they leave.

	Job 020 built ten bases and stamped `Claimed = false` + `BaseIndex` on every one of them, then
	nothing ever set them. `Config/WorkshopLayout.luau:217` says it outright: *"Nothing claims a base
	yet, so all twelve are dormant."* This is the code that fills that schema in.

	🔴 THE SERVER OWNS THE MAPPING. A client may never assert which bay is its own
	([decision 0007](../../../docs/decisions/0007-server-owns-capture-and-reward.md), non-negotiable
	#2). There is deliberately no "request a base" remote: joining IS the request.

	🔴 STATE LIVES ON THE BASE AS ATTRIBUTES, NOT IN THIS MODULE'S TABLE.

	Attributes replicate on their own, so a client can render a nameplate with **no remote at all**,
	and anything else that needs to know who owns a bay reads one source of truth. It also means the
	state is inspectable in the Explorer during a playtest, which a Lua table is not. `StationService`
	made the same call for `StationId` and gives the reason: the room is hand-placed and expected to
	be nudged, so **found by attribute, never by position**.

	⚠️ BASES ARE NUMBERED 3..12, NOT 1..10. Two facets became shop frontage in job 020, so the ten
	bays carry `BaseIndex` 3 through 12. Anything that assumes 1-based indexing silently misses two
	bays and mis-keys the other eight. Never derive an index from a loop counter -- read the attribute.

	⚠️ NO YIELD BETWEEN FINDING A FREE BASE AND CLAIMING IT. Luau is single-threaded per script, so a
	non-yielding find-then-write cannot interleave. The moment something yields in that window -- a
	thumbnail fetch, a DataStore read, a `WaitForChild` -- two players joining in the same frame can be
	handed the same bay. Everything slow happens AFTER the claim is committed.

	Sources: docs/systems/player-base · decision 0007 · Jobs/022
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("BaseClaim")

local BaseClaimService = {}

--- Attribute names, in one place so the nameplate builder and this module cannot drift apart.
BaseClaimService.ATTR = {
	CLAIMED = "Claimed",
	INDEX = "BaseIndex",
	OWNER_ID = "OwnerUserId",
	OWNER_NAME = "OwnerName",
	OWNER_DISPLAY = "OwnerDisplayName",
	CLAIMED_AT = "ClaimedAt",
}

local A = BaseClaimService.ATTR

local basesFolder: Instance? = nil

local function bases(): { Instance }
	if not basesFolder then
		local hub = workspace:FindFirstChild("Hub")
		basesFolder = hub and hub:FindFirstChild("Bases") or nil
	end
	if not basesFolder then
		return {}
	end
	local list = {}
	for _, b in ipairs(basesFolder:GetChildren()) do
		if b:GetAttribute(A.INDEX) ~= nil then
			table.insert(list, b)
		end
	end
	--- sorted by the ATTRIBUTE, never by name: "10" sorts before "3" as a string.
	table.sort(list, function(x, y)
		return (x:GetAttribute(A.INDEX) :: number) < (y:GetAttribute(A.INDEX) :: number)
	end)
	return list
end

--- How many bays exist at all. Used by the "more players than bays" warning.
function BaseClaimService.count(): number
	return #bases()
end

--- The base this player owns, or nil. Reads the world, so it is correct even if this module was
--- reloaded (which `execute_luau` does routinely -- job 008).
function BaseClaimService.baseFor(player: Player): Instance?
	for _, b in ipairs(bases()) do
		if b:GetAttribute(A.OWNER_ID) == player.UserId then
			return b
		end
	end
	return nil
end

--- Everything currently claimed, as `{ baseIndex -> userId }`. For diagnostics and DevTools.
function BaseClaimService.snapshot(): { [number]: number }
	local out = {}
	for _, b in ipairs(bases()) do
		local owner = b:GetAttribute(A.OWNER_ID)
		if owner then
			out[b:GetAttribute(A.INDEX) :: number] = owner :: number
		end
	end
	return out
end

--- Claim the lowest-numbered free bay for `player`.
---
--- Idempotent: a player who already holds a bay gets that same bay back rather than a second one.
--- Returns the base, or nil when every bay is taken.
function BaseClaimService.claim(player: Player): Instance?
	local already = BaseClaimService.baseFor(player)
	if already then
		return already
	end

	local all = bases()
	if #all == 0 then
		Log.warn("no bases found in workspace.Hub.Bases -- is the hub built?")
		return nil
	end

	for _, b in ipairs(all) do
		if b:GetAttribute(A.CLAIMED) ~= true then
			--- 🔴 committed with no yield in between, so two joins in one frame cannot collide
			b:SetAttribute(A.CLAIMED, true)
			b:SetAttribute(A.OWNER_ID, player.UserId)
			b:SetAttribute(A.OWNER_NAME, player.Name)
			b:SetAttribute(A.OWNER_DISPLAY, player.DisplayName)
			b:SetAttribute(A.CLAIMED_AT, os.time())
			Log.info("%s claimed base %d", player.Name, b:GetAttribute(A.INDEX) :: number)
			return b
		end
	end

	--- Not an error: the game must survive more players than bays. Finding 0006 records MaxPlayers
	--- reading 60 against ten bays, and that is a Creator Hub setting only a human can change.
	Log.warn("%s has NO base -- all %d bays are taken (MaxPlayers vs bay count, see finding 0006)",
		player.Name, #all)
	return nil
end

--- Give the bay back. Safe to call for a player who never had one.
function BaseClaimService.release(player: Player): boolean
	local b = BaseClaimService.baseFor(player)
	if not b then
		return false
	end
	local idx = b:GetAttribute(A.INDEX) :: number
	b:SetAttribute(A.CLAIMED, false)
	b:SetAttribute(A.OWNER_ID, nil)
	b:SetAttribute(A.OWNER_NAME, nil)
	b:SetAttribute(A.OWNER_DISPLAY, nil)
	b:SetAttribute(A.CLAIMED_AT, nil)
	Log.info("%s released base %d", player.Name, idx)
	return true
end

--- Clear every claim. Used at start, because `Claimed` is a saved place attribute and a crashed or
--- republished session can leave a bay marked as owned by nobody -- which would shrink the pool by
--- one every time until no bay was ever free again.
function BaseClaimService.releaseAll(): number
	local n = 0
	for _, b in ipairs(bases()) do
		if b:GetAttribute(A.CLAIMED) == true or b:GetAttribute(A.OWNER_ID) ~= nil then
			b:SetAttribute(A.CLAIMED, false)
			b:SetAttribute(A.OWNER_ID, nil)
			b:SetAttribute(A.OWNER_NAME, nil)
			b:SetAttribute(A.OWNER_DISPLAY, nil)
			b:SetAttribute(A.CLAIMED_AT, nil)
			n += 1
		end
	end
	return n
end

local started = false
local connections: { RBXScriptConnection } = {}

--- Called by Bootstrap. Fires `onClaim(player, base)` / `onRelease(player, base)` so the nameplate
--- and the robot spawner can hang off this without this module needing to know they exist.
function BaseClaimService.start(hooks: { onClaim: ((Player, Instance) -> ())?, onRelease: ((Player, Instance) -> ())? }?)
	if started then
		Log.warn("start() called twice -- ignoring the second")
		return
	end
	started = true
	hooks = hooks or {}

	local stale = BaseClaimService.releaseAll()
	if stale > 0 then
		Log.info("cleared %d stale claim(s) left in the place file", stale)
	end

	local function onJoin(player: Player)
		local base = BaseClaimService.claim(player)
		if base and hooks and hooks.onClaim then
			--- pcall, because a hook that errors must not cost the player their bay
			local ok, err = pcall(hooks.onClaim, player, base)
			if not ok then
				Log.warn("onClaim hook failed for %s: %s", player.Name, tostring(err))
			end
		end
	end

	local function onLeave(player: Player)
		local base = BaseClaimService.baseFor(player)
		if base and hooks and hooks.onRelease then
			local ok, err = pcall(hooks.onRelease, player, base)
			if not ok then
				Log.warn("onRelease hook failed for %s: %s", player.Name, tostring(err))
			end
		end
		BaseClaimService.release(player)
	end

	table.insert(connections, Players.PlayerAdded:Connect(onJoin))
	table.insert(connections, Players.PlayerRemoving:Connect(onLeave))

	--- ⚠️ Anyone already in the server when this runs would otherwise never be claimed. In Studio
	--- Play the local player joins BEFORE server scripts finish, so without this the only player in
	--- the test never gets a bay -- and it would look like the whole system does nothing.
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(onJoin, p)
	end

	Log.info("ready -- %d bays, indices %s", BaseClaimService.count(), (function()
		local ids = {}
		for _, b in ipairs(bases()) do
			table.insert(ids, tostring(b:GetAttribute(A.INDEX)))
		end
		return table.concat(ids, ",")
	end)())
end

return BaseClaimService
