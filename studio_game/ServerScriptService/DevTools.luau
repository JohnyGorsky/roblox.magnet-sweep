--!strict
--[[
	DevTools — the forced-state tools that make a randomised game debuggable.

	This is NOT polish deferred to later. MAGNET SWEEP has three overlapping randomised
	cycles (scrap refresh ~30-60s, factory cycle ~4min, factory shift ~12min) plus a
	persistent Arena. Without the ability to force each of them, every bug from the magnet
	job onward is unreproducible, and "it happened once" becomes the normal bug report.

	DESIGN: a REGISTRY, not a pile of hard dependencies. Systems that do not exist yet
	simply have not registered; their commands report "not implemented" instead of failing
	to compile. Each system registers its own handler as it is built:

	    DevTools.register("zone.jump", "Teleport to a zone", function(player, tier) ... end)

	AUTHORISATION IS SERVER-SIDE AND RE-CHECKED ON EVERY CALL. Being able to fire the
	DevCommand remote grants nothing.

	Sources: docs/build/01-foundation.md · docs/build/job-order.md (job 003)
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Log = require(ReplicatedStorage:WaitForChild("Log")).scope("DevTools")

local DevTools = {}

--------------------------------------------------------------------------------
-- Authorisation.
--
-- In Studio, anyone. On a live server, only listed UserIds. The list is empty by design --
-- add ids deliberately, and never ship with a wildcard.
--------------------------------------------------------------------------------

DevTools.AUTHORISED_USER_IDS = {
	[5025640608] = true, -- johnygorsky10 (owner)
} :: { [number]: boolean }

function DevTools.isAuthorised(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	return DevTools.AUTHORISED_USER_IDS[player.UserId] == true
end

--------------------------------------------------------------------------------
-- The registry.
--------------------------------------------------------------------------------

export type Handler = (player: Player, ...any) -> (boolean, string?)

type Entry = { help: string, handler: Handler }

local registry: { [string]: Entry } = {}

--- Register a dev command. Overwriting an existing name is a mistake, so it warns.
function DevTools.register(name: string, help: string, handler: Handler)
	if registry[name] then
		Log.warn("dev command %q registered twice -- overwriting", name)
	end
	registry[name] = { help = help, handler = handler }
	Log.debug("registered %q", name)
end

--- The four commands the build manifest requires, declared up-front so `help` lists them
--- even before their systems exist. Each is replaced by a real handler on registration.
local PLANNED = {
	["shift.force"] = "Force a Factory Shift: HEAVY | ELECTRIC | GOLD | SECURITY | CHAOS",
	["zone.jump"] = "Teleport to a zone by tier (1-12)",
	["power.grant"] = "Set or add Magnet Power",
	["part.spawn"] = "Spawn a named rare part by PartId, e.g. GIANT_SPOON",
	["cycle.force"] = "Fire the Factory Cycle immediately (skips the 20s warning)",
	["quality.set"] = "Force a client quality tier: Low | Medium | High",
}

function DevTools.list(): { { name: string, help: string, ready: boolean } }
	local seen: { [string]: boolean } = {}
	local out = {}
	for name, entry in pairs(registry) do
		seen[name] = true
		table.insert(out, { name = name, help = entry.help, ready = true })
	end
	for name, help in pairs(PLANNED) do
		if not seen[name] then
			table.insert(out, { name = name, help = help, ready = false })
		end
	end
	table.sort(out, function(a, b)
		return a.name < b.name
	end)
	return out
end

--- Run a command. Returns (ok, message). Never throws -- a dev tool that crashes the
--- server is worse than one that does nothing.
function DevTools.run(player: Player, name: string, ...): (boolean, string)
	if not DevTools.isAuthorised(player) then
		Log.warn("UNAUTHORISED dev command %q from %s (%d)", name, player.Name, player.UserId)
		return false, "not authorised"
	end
	local entry = registry[name]
	if not entry then
		if PLANNED[name] then
			return false, ("%q is not implemented yet -- its system has not registered"):format(name)
		end
		return false, ("unknown command %q"):format(name)
	end
	local args = table.pack(...)
	local ok, a, b = pcall(function()
		return entry.handler(player, table.unpack(args, 1, args.n))
	end)
	if not ok then
		Log.error("command %q threw: %s", name, tostring(a))
		return false, ("%q errored: %s"):format(name, tostring(a))
	end
	-- a handler that returns nothing must NOT read as success
	if a ~= true then
		return false, tostring(b or "handler did not report success")
	end
	Log.info("%s ran %q", player.Name, name)
	return true, tostring(b or "ok")
end

return DevTools
