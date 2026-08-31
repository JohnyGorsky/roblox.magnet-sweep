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
local Players = game:GetService("Players")
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
local ScrapService = require(need(script.Parent, "ScrapService"))
local MagnetState = require(need(script.Parent, "MagnetState"))

local ConfigFolder = need(ReplicatedStorage, "Config")
local Magnet = require(need(ConfigFolder, "Magnet"))
local Zones = require(need(ConfigFolder, "Zones"))
local Parts = require(need(ConfigFolder, "Parts"))
local Arena = require(need(ConfigFolder, "Arena"))
local Economy = require(need(ConfigFolder, "Economy"))
local Quality = require(need(ConfigFolder, "Quality"))
local KitSpec = require(need(need(ReplicatedStorage, "Kit"), "KitSpec"))
local Perf = require(need(ConfigFolder, "Perf"))
local Vfx = require(need(ConfigFolder, "Vfx"))
local SoundKit = require(need(ReplicatedStorage, "SoundKit"))

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
	-- a variant resolving to NOTHING (wrong BaseMaterial, or missing) means the whole kit
	-- renders as plain grey parts. That is fatal in Studio: it must not be playtested and
	-- mistaken for an art problem.
	for _, problem in ipairs(MaterialKit.audit()) do
		table.insert(fatal, problem)
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
	-- the reference device and budgets now EXIST (Config/Perf); what remains open is the set
	-- of questions only real hardware can answer, and those must not read as done
	local device = Perf.deviceQuestionsOutstanding()
	if device > 0 then
		table.insert(warnings, ("[DEVICE] %d performance question(s) can only be answered on real hardware: %s")
			:format(device, (function()
				local ids = {}
				for _, m in ipairs(Perf.open("DEVICE")) do table.insert(ids, m.id) end
				return table.concat(ids, ", ")
			end)()))
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
		("Power %d..%d | zones %d | arena %d (measured=%s) | pull L/M/H %d/%d/%d | grant/tick %d | zone12 %s in %d buys for %.3g coins"):format(
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
			coins
		)
end)

--------------------------------------------------------------------------------
-- The magnet. Job 007.
--------------------------------------------------------------------------------

-- ⚠️ Two invariants the magnet quietly depends on, asserted where they are cheap to see.
-- Both have been violated in this file's history and neither announced itself: the pool
-- parked exactly on the destroy plane, and a grant gate wider than the pull radius (which
-- makes entering range the collection). Each check states the failing numbers.
do
	local floor = workspace.FallenPartsDestroyHeight
	if Magnet.POOL.PARK_Y <= floor + 50 then
		Log.error("POOL.PARK_Y %.0f is at or under FallenPartsDestroyHeight %.0f -- the engine will delete the pool",
			Magnet.POOL.PARK_Y, floor)
	end
	local gate = Magnet.grantRange()
	if gate >= Magnet.START.Radius then
		Log.error("grant gate %.1f studs >= starter pull radius %.1f -- the distance check cannot reject anything",
			gate, Magnet.START.Radius)
	end

	-- Scrap is CanCollide = false, so an abandoned pull falls THROUGH the floor. The reaper
	-- has to catch it before FallenPartsDestroyHeight does, or the pool bleeds a part per
	-- abandonment. Both times are computed from the LIVE gravity, not assumed.
	local g = workspace.Gravity
	local tSave = math.sqrt(2 * Magnet.PULL_FALL_LIMIT / g)
	local tLose = math.sqrt(2 * math.max(1, 1 - floor) / g)
	if tSave >= tLose then
		Log.error("reaper catches a fall at %.2fs but the engine destroys the part at %.2fs -- the pool will bleed",
			tSave, tLose)
	end
	Log.info("grant gate %.1f vs radius %.1f | park %.0f vs plane %.0f | reaper %.2fs vs destruction %.2fs",
		gate, Magnet.START.Radius, Magnet.POOL.PARK_Y, floor, tSave, tLose)
end

-- ⚠️ The light cull must be able to fire. `decorativeLightRange` and the kit's authored
-- light ranges were chosen in two files that never met -- thresholds of 40/60/10000 against a
-- kit whose largest light is 18 -- so every tier clamped nothing, on every device, and said so
-- in a log line that looked identical to a working one. Both numbers are read here, not typed.
do
	local biggest = KitSpec.maxLightRange()
	local inert = {}
	for _, t in ipairs({ "Low", "Medium" }) do
		if Quality.TIERS[t].decorativeLightRange >= biggest then
			table.insert(inert, ("%s(%d)"):format(t, Quality.TIERS[t].decorativeLightRange))
		end
	end
	if #inert > 0 then
		Log.error("light clamp is INERT for %s -- the kit's largest light is %d, so these tiers clamp nothing",
			table.concat(inert, " "), biggest)
	else
		Log.info("light clamp: kit max %d studs vs Low %d / Medium %d / High %d",
			biggest, Quality.TIERS.Low.decorativeLightRange,
			Quality.TIERS.Medium.decorativeLightRange, Quality.TIERS.High.decorativeLightRange)
	end
end

for _, problem in ipairs(Vfx.audit()) do
	Log.error("VFX %s", problem)
end

--------------------------------------------------------------------------------
-- ⚠️ A PLACE SETTING NOBODY CAN PUT IN GIT.
--
-- `Lighting` does not sync (job 002), so the whole lighting recipe lives in the unversioned
-- `.rbxl` and any of it can drift without a diff to show it. The one that matters most is the
-- TIME OF DAY: the style skill's opening line is "a bright, glossy, slightly absurd toy factory
-- **at night**", and the place shipped at `ClockTime` 14.5 -- mid-afternoon -- until job 012.
--
-- Seen, not reasoned: at 14.5 the neon signage washed out to almost nothing and the grated
-- walkway blew to pure white, because metal under `EnvironmentSpecularScale = 1.0` was
-- reflecting a bright blue midday sky. The art direction was silently not being followed.
--
-- This cannot FIX it -- it is a place setting a human owns. What it can do is refuse to let it
-- drift silently, which is PITFALLS #33 (place settings nobody chose).
--------------------------------------------------------------------------------

do
	local Lighting = game:GetService("Lighting")

	-- 🔴 The values below come from the CONCEPT ART (`assets/concept_art/Arena.png`), not from a
	-- phrase in a document. The written style skill says "a toy factory **at night**", and job 012
	-- read that literally, set the place to ClockTime 1.5, and produced a black room. The painting
	-- it was describing is a **brightly lit interior**: light-grey concrete floor, nothing in
	-- shadow, saturated colour on the machines, neon reading as signage rather than as the only
	-- light source. "At night" describes the world outside; the hall is lit.
	--
	-- ⚠️ `EnvironmentSpecularScale` was 1.00 and is the single biggest offender: polished metal
	-- mirroring a bright sky blew the grated walkway out to pure white. 0.30 keeps the gloss and
	-- loses the blowout.
	local WANT = {
		ClockTime = { 8, 17 }, -- daylight; the hall reads as lit, not as a cave
		Brightness = { 1.5, 4.0 },
		EnvironmentSpecularScale = { 0.15, 0.55 },
	}
	local readings = {
		ClockTime = Lighting.ClockTime,
		Brightness = Lighting.Brightness,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
	}
	local drift = {}
	for name, range in pairs(WANT) do
		local v = readings[name]
		if v < range[1] or v > range[2] then
			table.insert(drift, ("%s=%.2f (want %.2f..%.2f)"):format(name, v, range[1], range[2]))
		end
	end
	-- Ambient must never be near-black, or shadowed geometry disappears instead of receding.
	local a = Lighting.Ambient
	if (a.R + a.G + a.B) / 3 < 0.15 then
		table.insert(drift, ("Ambient is %s -- too dark; the concept art has nothing in black"):format(tostring(a)))
	end

	if #drift > 0 then
		Log.warn("LIGHTING drifted from the concept art: %s. Lighting does not sync, so this is a place setting a human fixes in Studio.",
			table.concat(drift, ", "))
	else
		Log.info("lighting: ClockTime %.1f, Brightness %.1f, EnvSpecular %.2f, Ambient %s",
			readings.ClockTime, readings.Brightness, readings.EnvironmentSpecularScale, tostring(a))
	end
end

-- ⚠️ Name the empty sound slots, every startup, one line each. The audio rule is that an
-- empty slot must ANNOUNCE ITSELF -- a wrong sound is much harder to notice than a missing one,
-- and a placeholder is how the wrong asset ships. A count ("9 sounds missing") is a number you
-- learn to scroll past; the list is what makes a silent slot impossible to forget.
do
	local missing = SoundKit.missing()
	if #missing > 0 then
		Log.warn("AUDIO: %d slot(s) have no asset yet -- %s", #missing, table.concat(missing, ", "))
	else
		Log.info("AUDIO: every slot filled")
	end
end

-- ⚠️ The client cannot decide it is authorised -- `DevTools.isAuthorised` lives on the server
-- and must stay there. The server states the answer in an attribute, and the audio bench builds
-- nothing at all unless it is true. Same shape as the quality-tier publish.
Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("DevAuthorised", DevTools.isAuthorised(player))
end)
for _, player in ipairs(Players:GetPlayers()) do
	player:SetAttribute("DevAuthorised", DevTools.isAuthorised(player))
end

--------------------------------------------------------------------------------
-- The Workshop. Job 012.
--
-- ⚠️ Built BEFORE the scrap pool, because `WorkshopBuilder` rebuilds `ServerStorage.Kit` from
-- `KitSpec` and anything already holding a reference into the old folder would be left pointing
-- at a destroyed instance.
--------------------------------------------------------------------------------

do
	local WorkshopBuilder = require(need(script.Parent, "WorkshopBuilder"))

	--- ⚠️ Goes through the module Bootstrap already required, NOT a fresh `require`.
	--- `execute_luau` runs in a separate Luau context and `require` there builds a SECOND copy of
	--- a module with its own state (PITFALLS #16, #17) -- which for this module means a second
	--- `kitRoot` pointing at a folder the first copy is about to destroy. A dev command is the
	--- only honest way to exercise the real builder from outside.
	DevTools.register("workshop.rebuild", "Rebuild the Workshop from the spec (also the idempotence test)", function()
		local before = 0
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("BasePart") then before += 1 end
		end
		local built, parts, problems = WorkshopBuilder.build()
		local after = 0
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("BasePart") then after += 1 end
		end
		if not built then
			return false, ("refused: %s"):format(table.concat(problems, "; "))
		end
		--- 🔴 RE-ATTACH FIRST, REPORT SECOND.
		---
		--- The rebuild DESTROYS the station folders and every prompt hanging inside them. An
		--- earlier version returned early when the build reported ANY problem -- a missing dressing
		--- piece, a sign with no rim -- and so skipped this, leaving all seven stations with zero
		--- prompts while the reply talked only about the sign. The room looked right and could not
		--- be used.
		---
		--- Note the shape: the guard that fixed a silent-success bug created the next one. Doing
		--- the work before deciding what to say removes the ordering question entirely.
		local StationService = require(need(script.Parent, "StationService"))
		local reattached, stationProblems = StationService.attachPrompts()
		for _, sp in ipairs(stationProblems) do
			table.insert(problems, sp)
		end

		--- ⚠️ Problems are reported on SUCCESS too, and NAMED. A build that succeeded with a
		--- blocked sightline used to return a cheerful "rebuilt: 362 parts (idempotent: YES)".
		--- Idempotent means the SECOND build leaves the world the same size as the first; a rebuild
		--- that appends shows up here as a climbing number.
		local summary = ("rebuilt: %d Workshop parts | workspace %d -> %d (idempotent: %s) | %d/%d prompts"):format(
			parts, before, after, before == after and "YES" or "*** NO, THE WORLD GREW ***",
			reattached, #require(need(ReplicatedStorage, "Workshop"):WaitForChild("WorkshopSpec")).STATIONS)
		if #problems > 0 then
			return true, ("%s | %d PROBLEM(S): %s"):format(summary, #problems, table.concat(problems, "; "))
		end
		return true, summary
	end)

	local root, parts, problems = WorkshopBuilder.build()
	for _, p in ipairs(problems) do
		Log.error("WORKSHOP %s", p)
	end
	--- 🔴 A BLOCKED SIGHTLINE IS FATAL IN STUDIO, not a log line.
	---
	--- `build()` returns a non-nil root when the geometry was placed but a check failed, and the
	--- old test here was `if not root` -- so decision 0001's load-bearing check had no failing
	--- path that reached a human. Any problem now stops a Studio session, for the same reason a
	--- bad config does: it must not be playtested and mistaken for an art problem.
	if not root or #problems > 0 then
		-- Same stance as a bad config: in Studio this must not be playtested and mistaken for an
		-- art problem. On a live server a room with a misplaced sign beats no room at all.
		if RunService:IsStudio() then
			error(("WORKSHOP FAILED: %d problem(s) -- see the errors above"):format(#problems), 0)
		end
	else
		-- ⚠️ Stated against the budget, not on its own. "412 parts" is a number you scroll past;
		-- "412 / 1800" is one you notice the day it is 1900.
		Log.info("Workshop: %d parts of the %d-part in-view budget (%.0f%%)",
			parts, Perf.BUDGET.MAX_PARTS_IN_VIEW, parts / Perf.BUDGET.MAX_PARTS_IN_VIEW * 100)
		if parts > Perf.BUDGET.MAX_PARTS_IN_VIEW then
			Log.error("the Workshop alone exceeds the whole in-view part budget -- a zone chunk still has to fit beside it")
		end
	end
end

MagnetState.start()
ScrapService.init()
ScrapService.start()

--------------------------------------------------------------------------------
-- The stations. Job 013 -- the Workshop stops being scenery.
--------------------------------------------------------------------------------

do
	local StationService = require(need(script.Parent, "StationService"))

	local attached, stationProblems = StationService.attachPrompts()
	for _, p in ipairs(stationProblems) do
		Log.error("STATIONS %s", p)
	end
	--- ⚠️ Against the DENOMINATOR. "stations: 5 prompt(s) attached" and "stations: 7" look equally
	--- healthy in scrollback -- this file makes exactly that complaint about part counts twenty
	--- lines earlier and then did not apply it here.
	local WorkshopSpec = require(need(need(ReplicatedStorage, "Workshop"), "WorkshopSpec"))
	local wanted = #WorkshopSpec.STATIONS
	if attached < wanted then
		Log.error("stations: only %d of %d prompts attached", attached, wanted)
	else
		Log.info("stations: %d/%d prompts attached", attached, wanted)
	end

	--- ⚠️ Bound even though it cannot succeed yet. `RequestRepair` refusing with a reason is a
	--- different thing from `RequestRepair` being an unbound endpoint a prompt points at --
	--- the second is a control that does nothing with no explanation (PITFALLS #29, #34).
	RemoteBinder.bindFunction("RequestRepair", function(player: Player): (boolean, any)
		local ok, reason = StationService.repair(player)
		return ok, { reason = reason, preview = StationService.recyclePreview(player) }
	end)

	--- Quote AND commit on one remote, the same shape `RequestUpgrade` uses, so the numbers the
	--- player is looking at are the numbers that get charged. `commit = nil` previews.
	RemoteBinder.bindFunction("RequestRecycle", function(player: Player, commit: any): (boolean, any)
		if commit ~= true then
			return true, { reason = "preview", preview = StationService.recyclePreview(player) }
		end
		local ok, reason = StationService.recycle(player)
		return ok, { reason = reason, preview = StationService.recyclePreview(player) }
	end)

	--- Rebuilding the room destroys the prompts with it, so they have to come back.
	DevTools.register("stations.attach", "Re-attach the station prompts (after a workshop.rebuild)", function()
		local n, problems = StationService.attachPrompts()
		if #problems > 0 then
			return false, ("%d attached, %d problem(s): %s"):format(n, #problems, table.concat(problems, "; "))
		end
		return true, ("%d prompt(s) attached"):format(n)
	end)
end

RemoteBinder.bindEvent("ClaimScrap", function(player: Player, ids: any)
	local accepted, value, reason = ScrapService.claim(player, ids)
	local banked, rushStarted = MagnetState.collect(player, value, #accepted)
	if rushStarted then
		Remotes.getEvent("ScrapGranted"):FireClient(player, {}, 0, -1, {}, "MAGNET RUSH")
	end
	-- ⚠️ ALWAYS reply, including when nothing was accepted. The client hides an object the
	-- instant it arrives, so a claim that is silently dropped leaves that object invisible on
	-- that client for the rest of the session, with no error anywhere: the failure is
	-- self-sealing and looks exactly like a successful collection. The reply is what lets the
	-- client roll its optimistic hide back.
	--
	-- The client is told only what the SERVER accepted and banked, never what it asked for.
	-- `banked` can be less than `value` when the magnet fills mid-batch.
	Remotes.getEvent("ScrapGranted"):FireClient(player, accepted, banked, MagnetState.scrapCarried(player), ids, reason)
end)

RemoteBinder.bindEvent("ReportQuality", function(player: Player, tierName: any)
	ScrapService.setQualityTier(player, tierName)
end)

--------------------------------------------------------------------------------
-- Buying a magnet level. Job 011 -- the HUD's upgrade button needs somewhere real to send a
-- player, and a button that opens nothing is a placeholder control (GROUND-RULES 10).
--
-- ⚠️ ONE remote does both the quote and the purchase, deliberately. If the price were served
-- by a different call from the one that charges, the two could drift and the player would see
-- it as being overcharged. `track = nil` quotes; a track name buys. Both replies carry the
-- FRESH quote table, so the panel is never rendering a price that has already changed.
--
-- ⚠️ The cost is recomputed here from the player's own level. Nothing about a price is ever
-- accepted from the client -- decision 0007.
--------------------------------------------------------------------------------

RemoteBinder.bindFunction("RequestUpgrade", function(player: Player, track: any): (boolean, any)
	if track == nil then
		return true, { reason = "quote", quotes = MagnetState.quotes(player) }
	end
	if type(track) ~= "string" then
		return false, { reason = "track must be a string", quotes = MagnetState.quotes(player) }
	end
	local bought, reason = MagnetState.upgrade(player, track)
	return bought, { reason = reason, quotes = MagnetState.quotes(player) }
end)

DevTools.register("scrap.spawn", "Spawn a scrap field: scrap.spawn [count] [radius]", function(player, count, radius)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, "no character"
	end
	local n = ScrapService.spawnField(root.Position, tonumber(radius) or 40, tonumber(count) or 120)
	return true, ("spawned %d scrap"):format(n)
end)

DevTools.register("scrap.stats", "Live scrap counts, incl. the decision-0005 unanchored check", function()
	local st = ScrapService.stats()
	-- folderParts is the pool-bleed detector: it starts at POOL.INITIAL_SIZE and must never
	-- fall below it. `destroyed` is registry entries pinning an Instance the engine deleted.
	local leak = st.folderParts < Magnet.POOL.INITIAL_SIZE
		and (" *** POOL BLEEDING: %d parts lost ***"):format(Magnet.POOL.INITIAL_SIZE - st.folderParts)
		or ""
	return true, ("live=%d react=%d pull=%d pooled=%d UNANCHORED=%d destroyed=%d parts=%d/%d%s"):format(
		st.live, st.react, st.pull, st.pooled, st.unanchored, st.destroyed,
		st.folderParts, Magnet.POOL.INITIAL_SIZE, leak)
end)

DevTools.register("magnet.stats", "This player's live magnet state", function(player)
	local d = MagnetState.debug(player)
	-- ⚠️ `%.1f` on radius and drive. Both are fractional at any level above 0 -- radius is
	-- geometric, drive is 16 + 0.4*level -- and Luau's `%d` TRUNCATES rather than erroring, so
	-- this command silently reported "radius=12" for 12.4 and "drive=16" for 16.4. Job 011 is
	-- what made non-zero levels reachable through gameplay, which is what armed it.
	return true, ("power=%d radius=%.1f (active %.1f) drive=%.1f | scrap=%d/%d%s coins=%d | flow=%.1f tier=%d%s"):format(
		d.power, d.radius, d.activeRadius, d.drive, d.scrap, d.capacity,
		d.full and " SCRAP FULL" or "", d.coins, d.flow, d.flowTier, d.rush and " *** RUSH ***" or "")
end)

DevTools.register("magnet.level", "Set an upgrade level: magnet.level power|radius|drive|capacity N", function(player, track, n)
	if not MagnetState.setLevel(player, tostring(track), tonumber(n) or 0) then
		return false, "unknown track: " .. tostring(track)
	end
	local d = MagnetState.debug(player)
	return true, ("%s -> power=%d radius=%.1f drive=%.1f capacity=%d"):format(
		tostring(track), d.power, d.radius, d.drive, d.capacity)
end)

DevTools.register("magnet.recycle", "Empty the carried scrap (stands in for the Workshop bench)", function(player)
	return true, ("recycled %d scrap"):format(MagnetState.emptyCarried(player))
end)

--- ⚠️ SERVER-SIDE numbers. A DevTools handler runs on the server, so the memory figures here
--- are the SERVER process -- and `Perf.BUDGET.CLIENT_MEMORY_MB` / `TEXTURE_MEMORY_MB` describe
--- the reference PHONE. Comparing the two would be a confident, meaningless number, so this
--- command deliberately does not: it reports what it can honestly measure from here and says
--- where it measured it. The client-side reporter is findings/0001.
DevTools.register("perf.sample", "Server-side memory, physics FPS and part count (NOT the client budget)", function()
	local s = Perf.sample()
	return true, ("[server process] totalMem=%.0fMB texMem=%.0fMB instMem=%.0fMB physFps=%.0f | parts=%d/%d%s"):format(
		s.totalMemoryMb, s.textureMemoryMb, s.instanceMemoryMb, s.physicsFps,
		s.workspaceParts, Perf.BUDGET.MAX_PARTS_IN_VIEW,
		s.workspaceParts > Perf.BUDGET.MAX_PARTS_IN_VIEW and " OVER" or "")
end)

DevTools.register("magnet.overcharge", "Grant a temporary Overcharge (the paid PvE boost): magnet.overcharge [seconds]", function(player, seconds)
	local n = tonumber(seconds) or Magnet.OVERCHARGE.DURATION
	MagnetState.grantOvercharge(player, n)
	return true, ("overcharged for %.0fs -- radius x%.1f, maximum visual state"):format(n, Magnet.OVERCHARGE.RADIUS_MULTIPLIER)
end)

--- ⚠️ This exists so decision 0018 can be RE-CHECKED rather than assumed. SCRAP FULL is
--- supposed to be carried by the magnet's own behaviour -- the pull stops while everything in
--- range still rattles -- and the HUD is only a second voice. The only honest way to know that
--- is still true is to turn the HUD off and go and fill up.
--- ⚠️ Exists because the first-run hint was otherwise UNTESTABLE. `HasSwept` flips on the first
--- collection, and the magnet collects faster than a script can move the character out of range --
--- three attempts to observe the hint's positive branch all ended with the flag already set. A
--- state you cannot restore is a state you cannot verify.
DevTools.register("first.reset", "Clear HasSwept, so the MOVE NEAR SCRAP hint can be seen again", function(player)
	player:SetAttribute("HasSwept", nil)
	return true, "HasSwept cleared -- the first-run hint is eligible again"
end)

DevTools.register("hud.hide", "Hide/show the HUD, to check the magnet still teaches SCRAP FULL on its own", function(player)
	local hidden = not (player:GetAttribute("HudHidden") == true)
	player:SetAttribute("HudHidden", hidden)
	return true, hidden and "HUD hidden -- fill up and see whether the magnet still tells you" or "HUD shown"
end)

DevTools.register("magnet.coins", "Grant coins, to exercise the upgrade panel: magnet.coins [n]", function(player, n)
	local amount = math.floor(tonumber(n) or 1000)
	MagnetState.addCoins(player, amount)
	return true, ("granted %d coins (now %d)"):format(amount, MagnetState.coins(player))
end)

DevTools.register("audio.bench", "Open/close the audio bench (same as F3)", function(player)
	local open = not (player:GetAttribute("DevBenchOpen") == true)
	player:SetAttribute("DevBenchOpen", open)
	return true, open and "audio bench OPEN" or "audio bench closed"
end)

DevTools.register("audio.missing", "List the sound slots with no asset yet", function()
	local missing = SoundKit.missing()
	if #missing == 0 then
		return true, "every slot filled"
	end
	return true, ("%d empty: %s"):format(#missing, table.concat(missing, ", "))
end)

DevTools.register("quality.set", "Pin this client's quality tier: quality.set Low|Medium|High|auto", function(player, tier)
	local name = tostring(tier)
	if name ~= "auto" and not Quality.TIERS[name] then
		return false, ("unknown tier %q -- use Low, Medium, High or auto"):format(name)
	end
	player:SetAttribute("DevQualityTier", name)
	return true, ("quality pinned to %s (the client applies it and stops re-measuring)"):format(name)
end)

DevTools.register("scrap.why", "Why claims were turned away (add \"reset\" to zero it)", function(_, arg)
	local c = ScrapService.rejectCensus
	if arg == "reset" then
		for k in pairs(c) do
			c[k] = 0
		end
		return true, "census reset"
	end
	local rate = c.asked > 0 and ((c.asked - c.granted) / c.asked * 100) or 0
	return true, ("asked=%d granted=%d turned away=%.1f%% | gone=%d notMine=%d TOO_FAR=%d TOO_SOON=%d heavy=%d FULL=%d"):format(
		c.asked, c.granted, rate, c.unknown, c.notOwner, c.tooFar, c.tooSoon, c.tooHeavy, c.noRoom)
end)

DevTools.register("scrap.clear", "Remove all live scrap", function()
	ScrapService.init()
	return true, "scrap cleared and pool re-primed"
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
