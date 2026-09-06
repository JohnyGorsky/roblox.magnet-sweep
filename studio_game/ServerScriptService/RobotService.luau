--!strict
--[[
	RobotService — the server's answer to "put this part on my robot".

	Everything before this job could describe a robot; nothing could CHANGE one. The profile held a
	loadout, `RobotAssembler` could build from a loadout, and the only way to write one was the
	`profile.slot` dev command. This is the gameplay path: stand at the Robot Bay, pick a slot, pick
	a part you own, and the robot in your bay is rebuilt wearing it — permanently.

	🔴 SEVEN CHECKS, ALL SERVER-SIDE, AND THE ORDER IS NOT ARBITRARY.

	`RequestInstallPart` is a client-invoked remote, so every argument is a CLAIM. Decision 0007 makes
	the server authoritative for what a player has; a robot builder that trusts `partId` is a builder
	that hands out Legendaries. The cheap, local checks run first so a malformed call never reaches
	the DataStore or a world scan:

	  1. the arguments are strings at all
	  2. `slot` is a real slot -- from `Parts.SLOT_TO_SOCKETS`, the same table the rig is built from
	  3. the part EXISTS (starter set or catalog)
	  4. the part's own def agrees it belongs in that slot -- a Head part cannot go in the Arm socket
	  5. the part has ART, or it cannot be mounted at all (finding 0014)
	  6. 🔴 the player OWNS it -- `PlayerProfile.owns`, which reads the server's profile
	  7. 🔴 the player is really AT the Robot Bay -- `StationService.playerIsAt`

	⚠️ Check 7 is the same proximity gate `RequestEnterZone` and `RequestRecycle` use, and it is here
	for the same reason: a `ProximityPrompt` fires on the CLIENT, so "I pressed BUILD at the bay" is
	a claim too. Without it a modified client rebuilds its robot from anywhere, including mid-Arena.

	⚠️ Check 6 is NOT the last one even though it is the most important. Proximity walks the world's
	station list; ownership is a table lookup. Cheap and decisive first.

	## What it does NOT do

	**It does not grant parts.** Ownership arrives at the Service Hub `SECURED` moment and nowhere
	else (decision 0008), which is a later group. Until then `part.grant` is a dev command, and it is
	the only way a part enters an inventory — which keeps the grant path in one place rather than
	letting the builder quietly become one.

	Sources: decision 0004 (parts are content) · decision 0007 (the server owns it) · decision 0008
	         (secured at the hub) · finding 0014 (part art) · Jobs/022
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local Parts = require(Config:WaitForChild("Parts", 20))
local StarterRobot = require(Config:WaitForChild("StarterRobot", 20))
local PartsCatalog = require(Config:WaitForChild("PartsCatalog", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("RobotSvc")

local PlayerProfile = require(script.Parent:WaitForChild("PlayerProfile", 20))
local RobotAssembler = require(script.Parent:WaitForChild("RobotAssembler", 20))
local RobotSpawner = require(script.Parent:WaitForChild("RobotSpawner", 20))
local BaseClaimService = require(script.Parent:WaitForChild("BaseClaimService", 20))

local RobotService = {}

--- The station a player must be standing at. A string rather than a reference, because
--- `StationService` owns the world lookup and this module must not know where the bay is.
local STATION_ID = "RobotBay"

--- Every slot the rig has a socket for, in the order the builder should list them. Head down to
--- Mobility, because that is the order a person reads a robot.
---
--- ⚠️ A LIST, so the UI has a stable order, but validated against `Parts.SLOT_TO_SOCKETS` at
--- startup rather than trusted -- a slot added to the rig and forgotten here would otherwise be
--- invisible in the builder with nothing to say so.
RobotService.SLOT_ORDER = { "Head", "Core", "Body", "Arm", "Back", "Mobility" }

--- Which slots this list gets wrong, if any. Reported at startup.
function RobotService.auditSlots(): { string }
	local problems = {}
	local listed: { [string]: boolean } = {}
	for _, slot in ipairs(RobotService.SLOT_ORDER) do
		if not Parts.SLOT_TO_SOCKETS[slot] then
			table.insert(problems, ("SLOT_ORDER names %q, which the rig has no socket for"):format(slot))
		end
		listed[slot] = true
	end
	for slot in pairs(Parts.SLOT_TO_SOCKETS) do
		if not listed[slot] then
			table.insert(problems, ("slot %q has a socket but is missing from SLOT_ORDER -- it would not appear in the builder"):format(slot))
		end
	end
	return problems
end

--------------------------------------------------------------------------------
-- Reading the state the builder renders.
--------------------------------------------------------------------------------

export type PartView = {
	partId: string,
	name: string,
	slot: string,
	rarity: string,
	effect: string?,
	--- false when the part has no mesh binding, so the UI can grey it rather than offering an
	--- install that is guaranteed to fail (finding 0014).
	installable: boolean,
	--- why not, when `installable` is false
	blocked: string?,
	starter: boolean,
}

--- One part's display data, from whichever source defines it.
local function view(partId: string): PartView?
	local def = RobotAssembler.def(partId)
	if not def then
		return nil
	end
	--- ⚠️ `def.mesh` rather than `PartArt.has`: `RobotAssembler.def` merges the starter set AND the
	--- catalog+art, so asking IT is asking the thing that will actually do the mounting. Asking
	--- `PartArt` directly would answer "no" for all five starter parts, which carry their art
	--- inline.
	local hasArt = def.mesh ~= nil
	return {
		partId = partId,
		name = def.name or partId,
		slot = def.slot,
		rarity = def.rarity or "Common",
		effect = def.effect,
		installable = hasArt,
		blocked = if hasArt then nil else "no mesh yet — finding 0014",
		starter = StarterRobot.isStarter(partId),
	}
end

--- Everything the Robot Bay screen needs, in one round trip.
---
--- ⚠️ Includes `atStation`, so the client can say WHY the buttons are dead rather than looking
--- broken. It is advisory only -- `install` re-checks it, because this reply is a snapshot and the
--- player can walk away between reading it and pressing a button.
function RobotService.state(player: Player): any
	local StationService = require(script.Parent:WaitForChild("StationService", 20))
	local atStation, whyNot = StationService.playerIsAt(player, STATION_ID)

	local loadout = PlayerProfile.loadout(player)
	local owned = PlayerProfile.owned(player)

	--- owned parts grouped by slot, so the UI does not have to filter 96 of them per tab
	local bySlot: { [string]: { PartView } } = {}
	local ownedCount = 0
	for partId in pairs(owned) do
		local v = view(partId)
		if v then
			ownedCount += 1
			local bucket = bySlot[v.slot]
			if not bucket then
				bucket = {}
				bySlot[v.slot] = bucket
			end
			table.insert(bucket, v)
		else
			--- an owned id nothing defines. Says so rather than dropping it silently: it means a
			--- catalog rename left a profile holding a dead string, and the player's part is gone.
			Log.warn("%s owns unknown part %q -- not shown in the builder", player.Name, partId)
		end
	end
	--- rarest first inside a slot, then by name, so the list does not reorder between opens
	for _, bucket in pairs(bySlot) do
		table.sort(bucket, function(a, b)
			local ra = table.find(Parts.RARITY_ORDER, a.rarity) or 0
			local rb = table.find(Parts.RARITY_ORDER, b.rarity) or 0
			if ra ~= rb then
				return ra > rb
			end
			return a.name < b.name
		end)
	end

	--- the equipped part per slot, as a view, so the UI can show what is on the robot now
	local equipped: { [string]: PartView } = {}
	for slot, partId in pairs(loadout) do
		local v = view(partId)
		if v then
			equipped[slot] = v
		end
	end

	return {
		slots = RobotService.SLOT_ORDER,
		equipped = equipped,
		bySlot = bySlot,
		ownedCount = ownedCount,
		atStation = atStation,
		--- ⚠️ `if-then-else`, not `atStation and nil or whyNot` -- that expression always yields
		--- `whyNot`, so a player standing AT the bay was reported with the reason "at the station"
		--- attached. Same trap as the one `luau-analyze` just found in `PlayerProfile`'s lock
		--- release, and worth writing out: `x and nil or y` is `y` for every value of `x`.
		whyNot = if atStation then nil else whyNot,
		--- 🔴 So the player is TOLD their swap will not survive the session, rather than finding
		--- out on the next login. A failed load is never written back (see `PlayerProfile`), so
		--- this is not a warning about a risk -- it is a statement of fact.
		willPersist = not PlayerProfile.isSessionOnly(player),
	}
end

--------------------------------------------------------------------------------
-- Changing the robot.
--------------------------------------------------------------------------------

--- Rebuild the robot standing in this player's bay from their current loadout.
---
--- ⚠️ Returns false when they hold no bay, which is not an error: a player in a zone or the Arena
--- has a profile and no bay, and their swap must still be saved. The robot is rebuilt from the
--- profile the next time a bay is claimed, so nothing is lost.
function RobotService.rebuild(player: Player): (boolean, string)
	local base = BaseClaimService.baseFor(player)
	if not base then
		return false, "no bay held -- saved, and the robot will be built when you claim one"
	end
	local rig = RobotSpawner.spawn(base, player)
	if not rig then
		return false, "the bay could not build a robot -- see the server log"
	end
	return true, ("rebuilt in bay %s"):format(tostring(base:GetAttribute("BaseIndex")))
end

--- Install an owned part into a slot. Returns (ok, reason).
---
--- 🔴 EVERY `return false` HERE IS A REFUSAL THE PLAYER CAN READ. A builder that refuses silently
--- is indistinguishable from a broken one (PITFALLS #29/#34), and the reasons are specific enough
--- to debug from: "you do not own X" and "X does not fit the Arm slot" are different bugs.
function RobotService.install(player: Player, slot: unknown, partId: unknown): (boolean, string)
	-- 1. arguments
	if type(slot) ~= "string" or type(partId) ~= "string" then
		return false, "bad request"
	end
	-- 2. a real slot
	if not Parts.SLOT_TO_SOCKETS[slot] then
		return false, ("%q is not a robot slot"):format(slot)
	end
	-- 3. a real part
	local def = RobotAssembler.def(partId)
	if not def then
		return false, ("no such part as %q"):format(partId)
	end
	-- 4. the part's own def decides which slot it belongs in, never the caller
	if def.slot ~= slot then
		return false, ("%s is a %s part, not %s"):format(partId, tostring(def.slot), slot)
	end
	-- 5. it has to be mountable at all
	if not def.mesh then
		return false, ("%s has no mesh yet, so it cannot be built (finding 0014)"):format(partId)
	end
	-- 6. ownership, from the server's profile
	if not PlayerProfile.owns(player, partId) then
		Log.warn("%s tried to install %s, which they do not own", player.Name, partId)
		return false, ("you do not own %s"):format(partId)
	end
	-- 7. and they have to be standing at the bay
	local StationService = require(script.Parent:WaitForChild("StationService", 20))
	local atStation, whyNot = StationService.playerIsAt(player, STATION_ID)
	if not atStation then
		return false, whyNot
	end

	--- nothing to do, and saying so beats a pointless rebuild
	local current = PlayerProfile.loadout(player)[slot]
	if current == partId then
		return false, ("%s is already in the %s slot"):format(def.name or partId, slot)
	end

	if not PlayerProfile.setSlot(player, slot, partId) then
		return false, "no profile to change -- try again in a moment"
	end

	--- 🔴 SAVE BEFORE REBUILDING, not after. The rebuild is cosmetic and can fail (a missing mesh
	--- source, a bay mid-stream); the save is the thing the player was promised. Doing it in this
	--- order means a robot that fails to appear is still wearing the part after a rejoin, which is
	--- recoverable -- whereas a rebuilt robot with an unsaved loadout silently reverts.
	---
	--- ⚠️ An immediate save rather than waiting for the 60-second auto-save. An install is a
	--- deliberate, rare, player-visible act, so it is worth a write; `part.grant` is not, and does
	--- not force one.
	local saved = PlayerProfile.save(player, false)

	local rebuilt, rebuildWhy = RobotService.rebuild(player)
	Log.info("%s installed %s in %s (saved=%s, rebuilt=%s)", player.Name, partId, slot,
		tostring(saved), tostring(rebuilt))

	local name = def.name or partId
	if not rebuilt then
		return true, ("%s installed — %s"):format(name, rebuildWhy)
	end
	if not saved then
		--- 🔴 Told plainly. The part IS on the robot and the write did not land, so the honest
		--- report is "it is on, it may not last" -- not a success, and not a failure either.
		return true, ("%s installed, but the save did not land — it may not survive a rejoin"):format(name)
	end
	return true, ("%s installed in %s"):format(name, slot)
end

--------------------------------------------------------------------------------

--- Grant a part. The dev path today; the SECURED moment (decision 0008) later.
---
--- ⚠️ Refuses a starter stub explicitly. They are already owned by every profile, so a grant is
--- always a no-op, and a command that reports success for doing nothing teaches the wrong thing.
function RobotService.grant(player: Player, partId: unknown): (boolean, string)
	if type(partId) ~= "string" then
		return false, "usage: part.grant <PARTID>"
	end
	local upper = partId:upper()
	local def = RobotAssembler.def(upper)
	if not def then
		--- name the near misses, because these ids are long and typed by hand
		local near = {}
		for _, p in ipairs(PartsCatalog.ALL) do
			if #near < 4 and p.partId:find(upper, 1, true) then
				table.insert(near, p.partId)
			end
		end
		if #near > 0 then
			return false, ("no such part as %q -- did you mean %s?"):format(upper, table.concat(near, ", "))
		end
		return false, ("no such part as %q"):format(upper)
	end
	if StarterRobot.isStarter(upper) then
		return false, ("%s is a starter stub -- every profile already owns it"):format(upper)
	end
	local ok, already = PlayerProfile.grant(player, upper)
	if not ok then
		return false, "no profile loaded"
	end
	local art = def.mesh and "" or " ⚠️ has no mesh yet, so it cannot be installed (finding 0014)"
	if already then
		return true, ("%s was already owned%s"):format(upper, art)
	end
	return true, ("granted %s (%s, %s)%s"):format(upper, tostring(def.slot), tostring(def.rarity), art)
end

return RobotService
