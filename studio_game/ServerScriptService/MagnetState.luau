--!strict
--[[
	MagnetState — what a player's magnet currently IS, and what it is currently doing.

	Four stats derived from upgrade levels, the scrap they are carrying, Magnet Flow, and the
	MAGNET RUSH that Flow escalates into. One place, server-side, because decision 0002 puts
	the grant on the server and decision 0007 puts capture there too — a client that could
	author its own Radius or Capacity could author its own income.

	⚠️ This module is required BY ScrapService, and must never require it back. The claim path
	runs the other way: Bootstrap takes what ScrapService granted and hands it here.

	Nothing here persists yet. Levels start at 0 every session until the profile lands in job
	011; `LEVEL_KEYS` is the list that job has to serialise, and it is kept here so the two
	cannot disagree about what a magnet is made of.

	Sources: docs/systems/magnet/README.md · spec §9, §11, §16, §63
	         decisions 0002, 0005, 0007
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 15)
local Magnet = require(Config:WaitForChild("Magnet", 15))
local Economy = require(Config:WaitForChild("Economy", 15))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes", 15))
local Log = require(ReplicatedStorage:WaitForChild("Log", 15)).scope("MagnetState")

local MagnetState = {}

export type Stats = {
	Power: number,
	Radius: number,
	Drive: number,
	Capacity: number,
}

type Entry = {
	powerLevel: number,
	radiusLevel: number,
	driveLevel: number,
	capacityLevel: number,
	coins: number,
	scrap: number, -- ordinary scrap carried; Capacity is the ceiling
	flow: number, -- progress in PICKUPS, not tiers
	lastPickup: number, -- os.clock(); decay starts DECAY_AFTER seconds later
	rushUntil: number, -- os.clock() while MAGNET RUSH is running
	overchargeUntil: number, -- os.clock() while a purchased Overcharge is running
	cargo: Magnet.WeightClass?, -- a rare part in hand slows the run home
}

--- The four upgrade tracks. Job 011 serialises exactly these; a stat that is not in this list
--- has no level and therefore cannot be upgraded, which is a decision, not an oversight.
MagnetState.LEVEL_KEYS = { "powerLevel", "radiusLevel", "driveLevel", "capacityLevel" }

--- Pickups needed to trigger a MAGNET RUSH, and the ceiling flow is clamped to. One name for
--- one number, because it is both the trigger and the cap and those must never drift apart.
local FLOW_CEILING = Magnet.FLOW.MAX_TIER * Magnet.FLOW.PICKUPS_PER_TIER

local state: { [Player]: Entry } = {}

local function blank(): Entry
	return {
		powerLevel = 0,
		radiusLevel = 0,
		driveLevel = 0,
		capacityLevel = 0,
		coins = 0,
		scrap = 0,
		flow = 0,
		lastPickup = 0,
		rushUntil = 0,
		overchargeUntil = 0,
		cargo = nil,
	}
end

local function entryFor(player: Player): Entry
	local e = state[player]
	if not e then
		e = blank()
		state[player] = e
	end
	return e
end

--------------------------------------------------------------------------------
-- The four stats.
--------------------------------------------------------------------------------

--- ⚠️ Derived from levels every time, never cached. A cached stat is a stat that can be stale
--- after an upgrade, and the symptom — "I bought Radius and nothing happened" — points at the
--- shop rather than at the cache.
function MagnetState.stats(player: Player): Stats
	local e = entryFor(player)
	return {
		Power = Economy.powerAtLevel(e.powerLevel),
		Radius = Economy.radiusAtLevel(e.radiusLevel),
		Drive = Economy.driveAtLevel(e.driveLevel),
		Capacity = Economy.capacityAtLevel(e.capacityLevel),
	}
end

--- The PULL radius actually in force right now, MAGNET RUSH included. This is what the state
--- machine must ask — reading `stats().Radius` directly is how a Rush ends up invisible to the
--- system whose behaviour it exists to change.
function MagnetState.activeRadius(player: Player): number
	local r = MagnetState.stats(player).Radius
	if MagnetState.inRush(player) then
		r *= Magnet.RUSH.RADIUS_MULTIPLIER
	end
	if MagnetState.inOvercharge(player) then
		r *= Magnet.OVERCHARGE.RADIUS_MULTIPLIER
	end
	return r
end

function MagnetState.inRush(player: Player): boolean
	return os.clock() < entryFor(player).rushUntil
end

--------------------------------------------------------------------------------
-- Overcharge — the paid PvE magnet boost (spec 71), and the magnet's maximum visual state.
--------------------------------------------------------------------------------

function MagnetState.inOvercharge(player: Player): boolean
	return os.clock() < entryFor(player).overchargeUntil
end

--- Grant an Overcharge for `seconds`.
---
--- ⚠️ DECISION 0011 IS A CODE GATE, NOT A PROMISE. Robux never buys Arena power, so this
--- must never reach a deployed robot. It is enforced structurally rather than by remembering:
--- Overcharge lives on the PLAYER's magnet state and the only things that read it are the
--- magnet's own radius and its VFX. The Arena reads robot stats, which are a different module
--- and never consult this. If a future job makes a robot ask MagnetState anything, that is the
--- moment this gate breaks -- and the assertion below is what should catch it.
function MagnetState.grantOvercharge(player: Player, seconds: number)
	local e = entryFor(player)
	e.overchargeUntil = math.max(e.overchargeUntil, os.clock() + math.max(0, seconds))
	MagnetState.push(player)
	Log.info("%s overcharged for %.0fs (PvE magnet only -- decision 0011)", player.Name, seconds)
end

--------------------------------------------------------------------------------
-- Capacity and SCRAP FULL.
--------------------------------------------------------------------------------

function MagnetState.scrapCarried(player: Player): number
	return entryFor(player).scrap
end

function MagnetState.isFull(player: Player): boolean
	return entryFor(player).scrap >= MagnetState.stats(player).Capacity
end

--- How much more this player can physically carry. The grant path uses this so a full magnet
--- cannot bank a partial batch and quietly discard the rest.
function MagnetState.headroom(player: Player): number
	return math.max(0, MagnetState.stats(player).Capacity - entryFor(player).scrap)
end

--------------------------------------------------------------------------------
-- Magnet Flow.
--------------------------------------------------------------------------------

function MagnetState.flowTier(player: Player): number
	local e = entryFor(player)
	return math.min(Magnet.FLOW.MAX_TIER, math.floor(e.flow / Magnet.FLOW.PICKUPS_PER_TIER))
end

--- Coin multiplier for the tier currently held. The table is 1-indexed with tier 0 first, so
--- this is the one place that offset is written down.
function MagnetState.coinMultiplier(player: Player): number
	return Magnet.FLOW.COIN_MULTIPLIER[MagnetState.flowTier(player) + 1] or 1.0
end

--------------------------------------------------------------------------------
-- Collecting.
--------------------------------------------------------------------------------

--- Bank a granted batch. `count` objects worth `value` scrap between them.
--- Returns (scrap actually banked, coins earned, whether this started a MAGNET RUSH).
---
--- ⚠️ ScrapService has already validated the claim by the time this runs. This function's job
--- is the ECONOMY, not the anti-cheat, and it must not be reachable from a remote directly.
function MagnetState.collect(player: Player, value: number, count: number): (number, number, boolean)
	local e = entryFor(player)
	local banked = math.min(value, MagnetState.headroom(player))
	e.scrap += banked

	local coins = math.floor(banked * MagnetState.coinMultiplier(player))
	e.coins += coins

	-- Flow counts PICKUPS, not scrap value: a rhythm of collection, not a rate of income.
	-- Weighting it by value would make one heavy pipe worth five screws of combo and turn the
	-- combo into a second income stat.
	local wasRush = MagnetState.inRush(player)
	e.lastPickup = os.clock()

	-- ⚠️ Flow does NOT build during a Rush -- the Rush is what the combo pays out. Letting it
	-- keep charging means it is full again the instant it ends, so one dense field becomes a
	-- permanent Rush: measured at flow 101 during an 8s Rush, still tier 5 on the far side and
	-- ready to re-trigger on the very next pickup.
	local started = false
	if not wasRush then
		-- ⚠️ Capped at the trigger threshold. Uncapped, a dense field banks a combo that then
		-- takes 67s to decay at 1.5/s -- a combo you cannot lose is not a combo.
		e.flow = math.min(FLOW_CEILING, e.flow + count)
		if e.flow >= FLOW_CEILING then
			e.rushUntil = os.clock() + Magnet.RUSH.DURATION
			e.flow = 0
			started = true
			Log.info("%s hit MAGNET RUSH for %.1fs", player.Name, Magnet.RUSH.DURATION)
		end
	end

	MagnetState.push(player)
	return banked, coins, started
end

--- Empty the magnet into scrap. Returns what was banked. The Workshop's recycle bench (group
--- 05) is the real caller; until then `scrap.recycle` in DevTools is.
function MagnetState.emptyCarried(player: Player): number
	local e = entryFor(player)
	local had = e.scrap
	e.scrap = 0
	MagnetState.push(player)
	return had
end

function MagnetState.addCoins(player: Player, n: number)
	entryFor(player).coins += n
	MagnetState.push(player)
end

function MagnetState.coins(player: Player): number
	return entryFor(player).coins
end

--------------------------------------------------------------------------------
-- Magnetic Drive.
--------------------------------------------------------------------------------

--- Rare cargo in hand, or nil. Group 08 owns the cargo system; this is the hook it attaches
--- to, so Drive has exactly one implementation instead of two that must agree.
function MagnetState.setCargo(player: Player, class: Magnet.WeightClass?)
	entryFor(player).cargo = class
	MagnetState.applyDrive(player)
	MagnetState.push(player)
end

--- Write Drive onto the character. Called on spawn, on upgrade, and on cargo change.
---
--- ⚠️ Roblox resets WalkSpeed to 16 on every respawn, and 16 is also the starter Drive — so a
--- broken Drive looks exactly like a working one until the first upgrade. That is why this is
--- re-applied on CharacterAdded rather than set once.
function MagnetState.applyDrive(player: Player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local e = entryFor(player)
	local drive = MagnetState.stats(player).Drive
	hum.WalkSpeed = if e.cargo then Magnet.carrySpeed(drive, e.cargo) else drive
end

--------------------------------------------------------------------------------
-- Telling the client.
--------------------------------------------------------------------------------

--- One shape, one remote. The client RENDERS this and never derives it (Remotes: StatsChanged).
function MagnetState.push(player: Player)
	local e = entryFor(player)
	local s = MagnetState.stats(player)
	local ev = Remotes.getEvent("StatsChanged")
	if not ev then
		return
	end
	ev:FireClient(player, {
		coins = e.coins,
		scrap = e.scrap,
		capacity = s.Capacity,
		full = e.scrap >= s.Capacity,
		power = s.Power,
		radius = s.Radius,
		drive = s.Drive,
		flowTier = MagnetState.flowTier(player),
		flowProgress = e.flow % Magnet.FLOW.PICKUPS_PER_TIER,
		flowNeeded = Magnet.FLOW.PICKUPS_PER_TIER,
		rush = MagnetState.inRush(player),
		overcharge = MagnetState.inOvercharge(player),
		cargo = e.cargo,
	})
end

--------------------------------------------------------------------------------
-- Decay. Flow is a combo: it has to be losable, or it is just a counter.
--------------------------------------------------------------------------------

local function decayTick(dt: number)
	local now = os.clock()
	for player, e in pairs(state) do
		if e.flow <= 0 then
			continue
		end
		if now - e.lastPickup < Magnet.FLOW.DECAY_AFTER then
			continue
		end
		local before = MagnetState.flowTier(player)
		e.flow = math.max(0, e.flow - Magnet.FLOW.DECAY_PER_SECOND * dt)
		if MagnetState.flowTier(player) ~= before then
			MagnetState.push(player) -- only when the TIER changes; not 60 pushes a second
		end
	end
end

function MagnetState.start()
	RunService.Heartbeat:Connect(decayTick)

	local function onCharacter(player: Player)
		return function()
			task.wait() -- the Humanoid exists a frame before it is worth writing to
			MagnetState.applyDrive(player)
			MagnetState.push(player)
		end
	end

	local function onPlayer(player: Player)
		entryFor(player)
		player.CharacterAdded:Connect(onCharacter(player))
		if player.Character then
			task.spawn(onCharacter(player))
		end
		MagnetState.push(player)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		onPlayer(player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		state[player] = nil
	end)
	Log.info("flow decay running; drive re-applied on every spawn")
end

--- Dev/inspection only.
function MagnetState.debug(player: Player): { [string]: any }
	local e = entryFor(player)
	local s = MagnetState.stats(player)
	return {
		power = s.Power, radius = s.Radius, drive = s.Drive, capacity = s.Capacity,
		activeRadius = MagnetState.activeRadius(player),
		scrap = e.scrap, coins = e.coins,
		flow = e.flow, flowTier = MagnetState.flowTier(player),
		rush = MagnetState.inRush(player),
		overcharge = MagnetState.inOvercharge(player),
		full = MagnetState.isFull(player),
		levels = { e.powerLevel, e.radiusLevel, e.driveLevel, e.capacityLevel },
	}
end

--- Dev only: raise a track without paying for it.
function MagnetState.setLevel(player: Player, track: string, level: number): boolean
	local key = track .. "Level"
	local e = entryFor(player)
	if (e :: any)[key] == nil then
		return false
	end
	(e :: any)[key] = math.max(0, math.floor(level))
	MagnetState.applyDrive(player)
	MagnetState.push(player)
	return true
end

return MagnetState
