--!strict
--[[
	Bootstrap — the server's entry point.

	Creates the remote instances, binds the dev-command remote, and audits the config.
	Deliberately tiny: it exists so there is exactly ONE place that decides what comes up at
	server start, and so a missing or malformed config fails LOUDLY here rather than quietly
	in a gameplay system twenty minutes later.

	"Loudly" is literal. The first draft of this file used eleven UNTIMED WaitForChild calls,
	which meant a single missing module would have yielded forever: no remotes would be
	created, no error would be raised, and the only symptom would be Roblox's generic
	"may yield indefinitely" line. Every wait below has a timeout and a real failure path.

	Sources: docs/build/01-foundation.md · PITFALLS #2, #29, #31
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WAIT = 15 -- seconds; generous, but finite

--------------------------------------------------------------------------------
-- Loading. A failure here is fatal and must SAY SO.
--------------------------------------------------------------------------------

local function need(parent: Instance, name: string): Instance
	local inst = parent:WaitForChild(name, WAIT)
	if not inst then
		error(
			("BOOTSTRAP FAILED: %s.%s did not appear within %ds. "):format(parent:GetFullName(), name, WAIT)
				.. "Studio Sync may be disconnected, or the file may be missing from studio_game/.",
			0
		)
	end
	return inst
end

local Log = require(need(ReplicatedStorage, "Log")).scope("Bootstrap")
local Remotes = require(need(ReplicatedStorage, "Remotes"))
local MaterialKit = require(need(ReplicatedStorage, "MaterialKit"))
local RateLimiter = require(need(script.Parent, "RateLimiter"))
local RemoteBinder = require(need(script.Parent, "RemoteBinder"))
local DevTools = require(need(script.Parent, "DevTools"))

local ConfigFolder = need(ReplicatedStorage, "Config")
local Magnet = require(need(ConfigFolder, "Magnet"))
local Zones = require(need(ConfigFolder, "Zones"))
local Parts = require(need(ConfigFolder, "Parts"))
local Arena = require(need(ConfigFolder, "Arena"))
local Economy = require(need(ConfigFolder, "Economy"))
local Quality = require(need(ConfigFolder, "Quality"))

--------------------------------------------------------------------------------
-- Config audit. Each check names a real way the config could be wrong in a way that
-- would be painful to diagnose later.
--------------------------------------------------------------------------------

local function checkConfig(): ({ string }, { string })
	local fatal, warnings = {}, {}

	-- structural: these make the game unstartable, so they are checked FIRST and the
	-- caller must not proceed to index into a malformed list
	if #Zones.LIST ~= 12 then
		table.insert(fatal, ("expected 12 zones, found %d"):format(#Zones.LIST))
	end
	if #Parts.SOCKETS ~= 7 then
		table.insert(fatal, ("expected 7 sockets, found %d"):format(#Parts.SOCKETS))
	end
	if #fatal > 0 then
		return fatal, warnings
	end

	local prevGate = -1
	for _, z in ipairs(Zones.LIST) do
		if z.gate <= prevGate then
			table.insert(fatal, ("zone %d gate %d is not above the previous gate"):format(z.tier, z.gate))
		end
		prevGate = z.gate
	end
	if Magnet.START.Power < Zones.LIST[1].gate then
		table.insert(fatal, "the starter magnet cannot open zone 1")
	end

	-- every tier must actually contain the rarities a refresh may roll there
	for tier = 1, 12 do
		if #Zones.raritiesFor(tier) == 0 then
			table.insert(fatal, ("tier %d has no rarity band"):format(tier))
		end
	end

	-- the pinch must be a real choice
	local coins, hp = Economy.previewChoice(150)
	if coins <= 0 or hp <= 0 then
		table.insert(fatal, "recycle/repair preview returned a non-positive value")
	end

	-- knockback works by dropping the aligner's MaxForce, which is a SILENT no-op when
	-- RigidityEnabled is true
	if Arena.MOVER.RIGIDITY_ENABLED then
		table.insert(fatal, "Arena.MOVER.RIGIDITY_ENABLED must be false or knockback silently does nothing")
	end

	-- the pull cap has ONE source of truth; Quality must be reading it
	for _, tierName in ipairs({ "Low", "Medium", "High" }) do
		local t = Quality.TIERS[tierName]
		if not t then
			table.insert(fatal, ("missing quality tier %q"):format(tierName))
		elseif t.maxConcurrentPull ~= Magnet.MAX_CONCURRENT_PULL[tierName] then
			table.insert(
				fatal,
				("quality tier %q pull cap %d disagrees with Magnet.MAX_CONCURRENT_PULL %d")
					:format(tierName, t.maxConcurrentPull, Magnet.MAX_CONCURRENT_PULL[tierName])
			)
		end
	end

	-- a grant ceiling below an honest Magnet Rush would log real players as exploiters
	local rushBatch = Magnet.maxGrantPerTick("High")
	if rushBatch <= Quality.TIERS.High.maxConcurrentPull then
		table.insert(fatal, ("grant ceiling %d is below a single High-tier pull cap"):format(rushBatch))
	end

	-- a MaterialVariant that failed to save reads as a plain grey part: easy to miss now,
	-- hard to attribute once there is a whole factory built out of them
	for _, problem in ipairs(MaterialKit.audit()) do
		table.insert(warnings, problem)
	end

	-- every client-facing remote must name a bucket RateLimiter actually defines
	for _, problem in ipairs(Remotes.auditBuckets(RateLimiter.BUCKETS)) do
		table.insert(fatal, problem)
	end

	-- economy curves: reachability is machine-checkable, tuning is not
	for _, problem in ipairs(Economy.audit()) do
		if problem:find("^%[UNTUNED%]") then
			table.insert(warnings, problem)
		else
			table.insert(fatal, problem)
		end
	end
	for _, problem in ipairs(Economy.auditOverclock()) do
		table.insert(fatal, problem)
	end

	-- values that are guesses must SAY they are guesses, and the flags must be read by
	-- something rather than sitting inert
	if not Arena.MEASURED then
		table.insert(warnings, "[UNTUNED] Arena robot count has never been measured on a device")
	end
	if not Quality.BUDGET.CHOSEN then
		table.insert(warnings, "[UNTUNED] no reference device or performance budget has been chosen")
	end
	if not Arena.CONTROL_REWARD.TUNED then
		table.insert(warnings, "[UNTUNED] Arena control reward rates are placeholders")
	end

	return fatal, warnings
end

--------------------------------------------------------------------------------

local fatal, warnings = checkConfig()
for _, w in ipairs(warnings) do
	Log.warn("CONFIG %s", w)
end
for _, f in ipairs(fatal) do
	Log.error("CONFIG %s", f)
end
if #fatal > 0 then
	-- In Studio, stop hard: a broken config must not be playtested and mistaken for a
	-- gameplay bug. On a live server, keep going -- a running game with a bad number beats
	-- a server that refuses to start.
	if RunService:IsStudio() then
		error(("BOOTSTRAP FAILED: %d fatal config problem(s) -- see the errors above"):format(#fatal), 0)
	end
end

Remotes.createAll()
Log.info("created %d remotes", #Remotes.SPECS)

--------------------------------------------------------------------------------
-- Dev commands. Bound through RemoteBinder, so rate limiting is structural.
-- Authorisation is re-checked inside DevTools.run on every call.
--------------------------------------------------------------------------------

RemoteBinder.bindFunction("DevCommand", function(player: Player, name: any, ...): (boolean, string)
	if type(name) ~= "string" then
		return false, "command name must be a string"
	end
	if select("#", ...) > 8 then
		return false, "too many arguments"
	end
	return DevTools.run(player, name, ...)
end)

DevTools.register("help", "List dev commands", function(_player)
	local lines = {}
	for _, c in ipairs(DevTools.list()) do
		table.insert(lines, ("%s %-14s %s"):format(c.ready and "*" or "-", c.name, c.help))
	end
	return true, table.concat(lines, "\n")
end)

DevTools.register("config.dump", "Print key config values", function(_player)
	local coins, purchases, reachable = Economy.coinsToReachTier(12)
	return true,
		("Power %d..%d | zones %d | arena %d (measured=%s) | pull L/M/H %d/%d/%d | grant/tick %d | zone12 %s in %d buys for %.3g coins | budgets=%s"):format(
			Magnet.START.Power,
			Economy.powerAtLevel(purchases), -- power actually needed to clear zone 12
			#Zones.LIST,
			Arena.MAX_ROBOTS,
			tostring(Arena.MEASURED),
			Quality.TIERS.Low.maxConcurrentPull,
			Quality.TIERS.Medium.maxConcurrentPull,
			Quality.TIERS.High.maxConcurrentPull,
			Magnet.maxGrantPerTick("High"),
			reachable and "reachable" or "UNREACHABLE",
			purchases,
			coins,
			tostring(Quality.BUDGET.CHOSEN)
		)
end)

local unbound = RemoteBinder.unbound()
if #unbound > 0 then
	Log.info("%d client-facing remotes have no handler yet: %s", #unbound, table.concat(unbound, ", "))
end

Log.info(
	"ready. %d zones, arena cap %d, pull caps %d/%d/%d | fatal %d, warnings %d",
	#Zones.LIST,
	Arena.MAX_ROBOTS,
	Quality.TIERS.Low.maxConcurrentPull,
	Quality.TIERS.Medium.maxConcurrentPull,
	Quality.TIERS.High.maxConcurrentPull,
	#fatal,
	#warnings
)
