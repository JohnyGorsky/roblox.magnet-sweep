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
	--- Whether the client has been told each state is ON. The tick pushes once when the
	--- deadline lapses; without these it would either push every frame or never.
	rushSent: boolean,
	overchargeSent: boolean,
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
		rushSent = false,
		overchargeSent = false,
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
--- ⚠️ DECISION 0011: Robux never buys Arena power, so an Overcharge must never reach a
--- deployed robot.
---
--- That is enforced by `tools/check-overcharge-gate.py`, which fails if any module outside a
--- named allow-list references `MagnetState`. It is a GREP, not a runtime assertion, because
--- the thing being forbidden is a call site that does not exist yet -- there is no robot or
--- Arena module in `studio_game/` at all today, so nothing at runtime could observe the
--- violation.
---
--- An earlier version of this comment claimed "the assertion below is what should catch it"
--- and there was no assertion, here or anywhere. A comment asserting a gate is not a gate.
function MagnetState.grantOvercharge(player: Player, seconds: number)
	local e = entryFor(player)
	e.overchargeUntil = math.max(e.overchargeUntil, os.clock() + math.max(0, seconds))
	e.overchargeSent = true
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

--- How much more a pickup is worth at the tier currently held. The table is 1-indexed with tier 0
--- first, so this is the one place that offset is written down.
---
--- 🔴 It multiplies SCRAP, not Coins. See `collect`.
function MagnetState.flowMultiplier(player: Player): number
	return Magnet.FLOW.FLOW_MULTIPLIER[MagnetState.flowTier(player) + 1] or 1.0
end

--------------------------------------------------------------------------------
-- Collecting.
--------------------------------------------------------------------------------

--- Bank a granted batch. `count` objects worth `value` scrap between them.
--- Returns (scrap actually banked, whether this started a MAGNET RUSH).
---
--- ⚠️ ScrapService has already validated the claim by the time this runs. This function's job
--- is the ECONOMY, not the anti-cheat, and it must not be reachable from a remote directly.
function MagnetState.collect(player: Player, value: number, count: number): (number, boolean)
	local e = entryFor(player)

	--- 🔴 SWEEPING PAYS SCRAP. IT DOES NOT PAY COINS.
	---
	--- `docs/systems/economy` is unambiguous: Scrap comes from sweeping, **Coins come from
	--- recycling**. This function used to do `e.coins += banked * multiplier` as well, which was
	--- invisible while the Recycler did not exist -- job 013 lit the real Coin path and the game
	--- was suddenly paying for the same scrap twice. Spec §48's exact worked example, 150 scrap ->
	--- 3,600 Coins, came out as 3,750.
	---
	--- The second-order damage was worse than the 4 %: Flow's multiplier was applied to that
	--- pickup grant, so a MAGNET RUSH -- the game's headline reward -- was multiplying about a
	--- twenty-fifth of the payout. Moving the multiplier onto the SCRAP puts the whole Flow curve
	--- back on the quantity that actually converts to Coins.
	---
	--- ⚠️ Multiplied BEFORE the headroom clamp, so a Rush fills the magnet faster and sends the
	--- player to the Recycler sooner. That is the loop tightening, not a rounding detail.
	local worth = math.floor(value * MagnetState.flowMultiplier(player) + 0.5)
	local banked = math.min(worth, MagnetState.headroom(player))
	e.scrap += banked

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
			e.rushSent = true
			e.flow = 0
			started = true
			Log.info("%s hit MAGNET RUSH for %.1fs", player.Name, Magnet.RUSH.DURATION)
		end
	end

	--- 🔴 THE FIRST-RUN FLAG, and it lives on the SERVER.
	---
	--- `docs/systems/boot` §9 teaches the loop environmentally: the player sees scrap shake, a
	--- prompt says MOVE NEAR SCRAP, and the prompt's whole job is to disappear the moment they
	--- actually sweep. So "have they swept?" is a fact about collection, and this is the one place
	--- collection happens.
	---
	--- ⚠️ Per-session today. When profiles land in group 11 this attribute is written FROM the
	--- profile at join and back to it here — the client already reads the attribute and nothing on
	--- that side has to change. Putting it on the client instead would mean building the same
	--- state twice and having them disagree across a rejoin.
	if banked > 0 and player:GetAttribute("HasSwept") ~= true then
		player:SetAttribute("HasSwept", true)
	end

	MagnetState.push(player)
	return banked, started
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

--- ⚠️ Clamped at zero, and it says so when it clamps.
---
--- Found by testing: `dev("magnet.coins", -99999)` drove a live balance to **-87,629**, and the
--- upgrade panel then correctly but absurdly quoted "need 87,679 coins". Nothing in the grant
--- path passes a negative today, so this is not a live bug -- but a currency that can go
--- negative is one careless caller away from being one, and a debt is not a state this game has
--- any rules for. Spending goes through `MagnetState.upgrade`, which checks affordability
--- first; this function is for INCOME.
function MagnetState.addCoins(player: Player, n: number)
	local e = entryFor(player)
	local wanted = e.coins + n
	if wanted < 0 then
		Log.warn("%s: coins would have gone to %d -- clamped to 0", player.Name, wanted)
		wanted = 0
	end
	e.coins = wanted
	MagnetState.push(player)
end

function MagnetState.coins(player: Player): number
	return entryFor(player).coins
end

--------------------------------------------------------------------------------
-- Buying a level. The one place coins turn into a magnet.
--------------------------------------------------------------------------------

--- The four upgrade tracks, each naming its level field and the two Economy curves that
--- describe it. Config-first: no cost, growth or ceiling appears in this file.
---
--- ⚠️ `Economy.<x>Cost(level)` is the price to go FROM `level` TO `level + 1` -- that is the
--- convention `Economy.coinsToReachPower` walks, and reading it as "the price at this level"
--- charges the player for the step they already own.
export type Track = {
	id: string,
	levelKey: string,
	label: string,
	cost: (number) -> number,
	value: (number) -> number,
	--- Whole numbers are displayed bare; Radius and Drive are fractional and get one decimal.
	decimals: number,
}

MagnetState.TRACKS = {
	{ id = "power", levelKey = "powerLevel", label = "MAGNET POWER",
		cost = Economy.powerCost, value = Economy.powerAtLevel, decimals = 0 },
	{ id = "radius", levelKey = "radiusLevel", label = "PULL RADIUS",
		cost = Economy.radiusCost, value = Economy.radiusAtLevel, decimals = 1 },
	{ id = "capacity", levelKey = "capacityLevel", label = "CAPACITY",
		cost = Economy.capacityCost, value = Economy.capacityAtLevel, decimals = 0 },
	{ id = "drive", levelKey = "driveLevel", label = "MAGNETIC DRIVE",
		cost = Economy.driveCost, value = Economy.driveAtLevel, decimals = 1 },
} :: { Track }

--- ⚠️ TRACKS and LEVEL_KEYS are two lists of the same thing, written for two different
--- consumers -- the shop and the future save file. PITFALLS #52: when one module's table has to
--- agree with another's, assert it where it is cheap to see rather than discovering the day a
--- track silently stops persisting. A track missing from LEVEL_KEYS is a stat the player buys
--- and loses on rejoin, which looks like a save bug and is not one.
do
	local byKey: { [string]: boolean } = {}
	for _, k in ipairs(MagnetState.LEVEL_KEYS) do
		byKey[k] = true
	end
	for _, t in ipairs(MagnetState.TRACKS) do
		assert(byKey[t.levelKey], ("track %q names level key %q, which LEVEL_KEYS does not list -- it would not persist"):format(t.id, t.levelKey))
		byKey[t.levelKey] = nil
	end
	local orphan = next(byKey)
	assert(not orphan, ("LEVEL_KEYS lists %q, which no upgrade track sells -- it can never rise"):format(tostring(orphan)))
end

local trackById: { [string]: Track } = {}
for _, t in ipairs(MagnetState.TRACKS) do
	trackById[t.id] = t
end

export type Quote = {
	track: string,
	label: string,
	level: number,
	value: number,
	nextValue: number,
	cost: number,
	affordable: boolean,
	maxed: boolean,
	decimals: number,
}

--- What each track currently costs this player, and whether they can pay.
---
--- ⚠️ Computed on the SERVER and sent down, rather than letting the client derive it from the
--- shared Economy module. The client COULD do the arithmetic -- Economy is in ReplicatedStorage
--- -- but then the price on screen and the price charged would be two implementations that
--- have to agree, and the first time they disagreed the player would see it as being
--- overcharged. One number, computed once, in the place that takes the coins.
function MagnetState.quotes(player: Player): { Quote }
	local e = entryFor(player)
	local out: { Quote } = {}
	for _, t in ipairs(MagnetState.TRACKS) do
		local level = (e :: any)[t.levelKey] :: number
		local maxed = level >= Economy.UPGRADE.MAX_LEVEL
		local cost = t.cost(level)
		table.insert(out, {
			track = t.id,
			label = t.label,
			level = level,
			value = t.value(level),
			nextValue = t.value(level + 1),
			cost = cost,
			affordable = not maxed and e.coins >= cost,
			maxed = maxed,
			decimals = t.decimals,
		})
	end
	return out
end

--- Buy exactly one level. Returns (bought, reason).
---
--- ⚠️ The server recomputes the price from the player's CURRENT level; it never receives one.
--- A remote that accepted a cost would let a client name its own price, which is decision 0007
--- ("the server owns currency") failing in the most direct way available.
---
--- ⚠️ Deducts BEFORE raising the level, and re-reads the level from the entry rather than from
--- a value captured earlier, so two invocations racing on the same frame cannot both pass the
--- affordability check against the same balance. Luau is single-threaded per script and there
--- is no yield between the check and the deduction, which is what actually makes this safe --
--- the ordering is here so that a future `await` inserted in the middle fails loudly rather
--- than quietly granting a free level.
function MagnetState.upgrade(player: Player, trackId: string): (boolean, string)
	local t = trackById[trackId]
	if not t then
		return false, "unknown track"
	end
	local e = entryFor(player)
	local level = (e :: any)[t.levelKey] :: number
	if level >= Economy.UPGRADE.MAX_LEVEL then
		return false, "already at maximum"
	end
	local cost = t.cost(level)
	if e.coins < cost then
		return false, ("need %d coins"):format(cost - e.coins)
	end

	e.coins -= cost
	;(e :: any)[t.levelKey] = level + 1

	-- Drive is written onto the Humanoid, so buying it has to reach the character or the
	-- purchase is invisible until the next respawn (see `applyDrive`).
	MagnetState.applyDrive(player)
	MagnetState.push(player)

	Log.info("%s bought %s L%d->L%d for %d coins", player.Name, t.id, level, level + 1, cost)
	-- ⚠️ Formatted to the track's OWN `decimals`. `tostring()` here produced
	-- "MAGNETIC DRIVE -> 17.200000000000003" and "PULL RADIUS -> 13.3046145" -- float noise, in
	-- the string the client puts on screen as the confirmation of a purchase. The quote path
	-- already honours `decimals`; this one silently did not.
	local shown = if t.decimals > 0
		then ("%.1f"):format(t.value(level + 1))
		else ("%d"):format(t.value(level + 1))
	return true, ("%s -> %s"):format(t.label, shown)
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
	-- `getEvent` ERRORS when the remote is missing; it never returns nil. An earlier `if not ev
	-- then return end` here read as a guard and was dead code -- worse than absent, because it
	-- implied a failure mode that is handled and is not.
	local ev = Remotes.getEvent("StatsChanged")
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
		-- ⚠️ EXPIRY MUST BE PUSHED. `inRush` and `inOvercharge` are predicates over a deadline,
		-- so the SERVER is always right about them -- but the client only ever learns their
		-- value from a push, and every other push site fires on an ACTION (a collection, a
		-- recycle, an upgrade). A Rush that simply runs out is not an action, so nothing told
		-- the client and its copy latched ON.
		--
		-- Measured before this existed: the server left the Rush at T+8.2s and the client held
		-- `rate = 120`, `lightRange = 20`, shadow-casting, for as long as it was watched. Two
		-- things broke at once -- the continuous-cost budget the whole VFX design is built
		-- around was abandoned for the entire walk home, and "MAGNET RUSH" stopped meaning a
		-- Rush was happening. For the PAID Overcharge it is worse: the only feedback the
		-- product gives says you still own a boost that has expired.
		--
		-- It is cheap because it fires ONCE, on the edge.
		if e.rushSent and not MagnetState.inRush(player) then
			e.rushSent = false
			MagnetState.push(player)
		end
		if e.overchargeSent and not MagnetState.inOvercharge(player) then
			e.overchargeSent = false
			MagnetState.push(player)
		end

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
