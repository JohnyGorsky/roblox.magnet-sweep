--!strict
--[[
	PlayerProfile — the one place player data is loaded, held and saved.

	This is `docs/build/job-order.md`'s job **026**, pulled forward to job 022 at the owner's explicit
	request. ⚠️ It was sequenced *behind* Economy (025) because the economy decides what there is to
	save; the schema here is therefore versioned and migrated from day one, so 025 can add fields
	without a rewrite.

	Before this file the project had **zero** persistence -- not one `GetDataStore` call anywhere.

	## The three rules, from the `roblox-data` skill

	1. 🔴 **`UpdateAsync`, never `SetAsync`.** `SetAsync` is a blind overwrite, which loses data under
	   concurrency. Every write here is an atomic read-modify-write, and **the transform never
	   yields** -- yielding inside it is undefined behaviour. `return nil` cancels the write.
	2. 🔴 **Session locking.** A GUID is written into the profile on load and carried in every
	   subsequent write. A second server may only take over a profile whose lock has gone **stale**.
	   Without this, two servers holding the same profile is a dupe exploit and a rollback generator.
	3. 🔴 **The save trio + `BindToClose`.** Load on join, auto-save on a loop (which also heartbeats
	   the lock), save on `PlayerRemoving`, and save everyone left inside `BindToClose`. Skipping
	   `BindToClose` loses the last session of every player when a server shuts down.

	## The rule that matters most

	🔴 **NEVER OVERWRITE A FAILED LOAD.** If the load could not be read, the in-memory profile is a
	*guess*, and saving a guess destroys the real one. A player whose load failed gets a
	session-only profile flagged `loadFailed`, and every save path refuses it. Losing one session is
	recoverable; overwriting a real profile with defaults is not.

	⚠️ **Studio shares LIVE data.** With "Studio Access to API Services" enabled, a Studio playtest
	reads and writes the same keys as the published game. The `roblox-data` skill says to test on a
	separate place. This module logs loudly which mode it is in, so a Studio session can never be
	mistaken for a safe sandbox.

	Sources: the `roblox-data` skill · docs/build/11-economy-and-save.md · Jobs/022
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local StarterRobot = require(Config:WaitForChild("StarterRobot", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Profile")

local PlayerProfile = {}

--- 🔴 Bump this ONLY with a matching entry in `MIGRATIONS`. An unknown-version profile is treated as
--- unreadable rather than guessed at, because guessing is how a schema change eats everyone's data.
PlayerProfile.VERSION = 1

local STORE_NAME = "PlayerProfile_v1"
local KEY_PREFIX = "u_"

--- A lock older than this may be stolen. Long enough that a live server's auto-save always refreshes
--- it first; short enough that a crashed server does not lock a player out for long.
---
--- ⚠️ SHORTER IN STUDIO, DELIBERATELY, and the argument is specific rather than convenience:
--- a Studio playtest is a single server, so a lock found there **cannot** belong to a live peer --
--- it is necessarily a leftover from a previous local session. In production the 180 s stands,
--- because there a foreign lock may well be a real server mid-save.
--- Without this, every stop/start cycle inside 3 minutes locks the tester out of their own profile.
local LOCK_STALE_SECONDS = RunService:IsStudio() and 10 or 180
local AUTOSAVE_SECONDS = 60
--- BindToClose gets ~30s. Leave headroom so a slow write still lands.
local CLOSE_BUDGET_SECONDS = 25
local MAX_ATTEMPTS = 4

local store: DataStore? = nil
local storeOk = false
--- one GUID per server, written into every profile this server owns
local SESSION_ID = HttpService:GenerateGUID(false)

local profiles: { [number]: any } = {}
local loadFailed: { [number]: boolean } = {}
--- userId -> true while a load is in flight. Anything that reads a loadout must wait for this,
--- or it reads defaults and acts on them. See `waitReady`.
local loading: { [number]: boolean } = {}
local started = false

local function key(userId: number): string
	return KEY_PREFIX .. tostring(userId)
end

--------------------------------------------------------------------------------
-- Schema
--------------------------------------------------------------------------------

local function defaultProfile(): any
	return {
		version = PlayerProfile.VERSION,
		createdAt = os.time(),
		lastSeen = os.time(),
		--- the five short strings a saved robot really is. Meshes can change underneath them.
		robot = {
			loadout = StarterRobot.newLoadout(),
			--- has the player ever been GIVEN their starter? Separate from the loadout being
			--- non-empty, so a player who strips their robot bare is not re-granted one.
			starterGranted = true,
			--- 🔴 WHAT THE PLAYER OWNS, as `partId -> true`. The loadout says what is BOLTED ON;
			--- this says what may be. Without it "install this part" has nothing to check against
			--- and the server would be taking the client's word for which parts it has -- which is
			--- decision 0007's whole point, and the one thing a robot builder must not do.
			---
			--- ⚠️ A SET, not a list: the question asked of it is always "do you own X", never "what
			--- is your third part". A list would also let a part be granted twice.
			owned = StarterRobot.ownedSet(),
		},
		stats = {
			--- deliberately empty until Economy (025) decides what the economy is. The version
			--- field is what lets that land without a migration scramble.
		},
	}
end

--- version -> function(profile) -> profile. Each step upgrades by exactly one version.
local MIGRATIONS: { [number]: (any) -> any } = {
	-- [1] = function(p) ... end,  -- add when VERSION becomes 2
}

--- Returns the migrated profile, or nil if it cannot be understood.
local function migrate(raw: any): any?
	if type(raw) ~= "table" or type(raw.version) ~= "number" then
		return nil
	end
	local p = raw
	local guard = 0
	while p.version < PlayerProfile.VERSION do
		local step = MIGRATIONS[p.version]
		if not step then
			return nil
		end
		p = step(p)
		guard += 1
		if guard > 32 then
			return nil
		end
	end
	if p.version > PlayerProfile.VERSION then
		--- a NEWER profile than this server understands. Do not touch it: an old server writing
		--- over a new schema is the worst case, and it happens during a staged rollout.
		return nil
	end
	--- backfill anything a partially-written profile is missing, without discarding what is there
	if type(p.robot) ~= "table" then
		p.robot = defaultProfile().robot
	end
	if type(p.robot.loadout) ~= "table" then
		p.robot.loadout = StarterRobot.newLoadout()
	end
	--- ⚠️ BACKFILLED, NOT MIGRATED, and the distinction is deliberate. `VERSION` may only be bumped
	--- alongside a `MIGRATIONS` entry; this is an additive field with a safe default, which is the
	--- same shape as the `loadout` backfill directly above. A v1 profile written before the robot
	--- builder existed reads back with its starter set owned and nothing lost.
	if type(p.robot.owned) ~= "table" then
		p.robot.owned = StarterRobot.ownedSet()
	end
	--- 🔴 SELF-HEALING: anything already BOLTED ON is owned by definition.
	---
	--- Otherwise `profile.slot Arm PIPE_WRENCH` -- a dev command that writes the loadout directly,
	--- and the one the persistence round trip was tested with -- produces a robot wearing a part its
	--- owner does not own. The builder would then refuse to put it back after a swap, and the player
	--- would lose a part by looking at it. Reconciling here means the invariant "the loadout is a
	--- subset of owned" holds for every profile on load, however it was written.
	for _, partId in pairs(p.robot.loadout) do
		if type(partId) == "string" then
			p.robot.owned[partId] = true
		end
	end
	if type(p.stats) ~= "table" then
		p.stats = {}
	end
	return p
end

--------------------------------------------------------------------------------
-- Plumbing
--------------------------------------------------------------------------------

--- pcall + exponential backoff. Returns ok, result.
local function attempt<T>(label: string, fn: () -> T): (boolean, any)
	local delay = 0.5
	for i = 1, MAX_ATTEMPTS do
		local ok, res = pcall(fn)
		if ok then
			return true, res
		end
		Log.warn("%s failed (attempt %d/%d): %s", label, i, MAX_ATTEMPTS, tostring(res))
		if i < MAX_ATTEMPTS then
			task.wait(delay)
			delay *= 2
		end
	end
	return false, nil
end

local function lockIsMine(p: any): boolean
	return type(p) == "table" and type(p.lock) == "table" and p.lock.id == SESSION_ID
end

local function lockIsStale(p: any): boolean
	if type(p) ~= "table" or type(p.lock) ~= "table" then
		return true
	end
	if type(p.lock.at) ~= "number" then
		return true
	end
	return (os.time() - p.lock.at) > LOCK_STALE_SECONDS
end

--------------------------------------------------------------------------------
-- Load
--------------------------------------------------------------------------------

--- Claim and read a player's profile. Always leaves SOMETHING usable in memory; `loadFailed` says
--- whether that something may ever be written back.
function PlayerProfile.load(player: Player): any
	local userId = player.UserId
	if profiles[userId] then
		return profiles[userId]
	end
	loading[userId] = true

	if not storeOk or not store then
		--- No DataStore (API access off, or Studio without it). Give a session-only profile and
		--- FLAG IT, so nothing tries to persist a fiction.
		profiles[userId] = defaultProfile()
		loadFailed[userId] = true
		loading[userId] = nil
		Log.warn("%s: no DataStore available -- SESSION-ONLY profile, nothing will be saved", player.Name)
		return profiles[userId]
	end

	local claimed
	local ok = false
	for i = 1, MAX_ATTEMPTS do
		local callOk, res = pcall(function()
			return (store :: DataStore):UpdateAsync(key(userId), function(old)
				--- ⚠️ THIS TRANSFORM MUST NOT YIELD. No waits, no other async calls, no requires.
				if old ~= nil then
					local migrated = migrate(old)
					if migrated == nil then
						--- unreadable or from a newer schema: cancel, and let the caller treat this
						--- as a failed load rather than replacing it with defaults
						return nil
					end
					if not lockIsStale(migrated) and not lockIsMine(migrated) then
						--- another live session holds it
						return nil
					end
					migrated.lock = { id = SESSION_ID, at = os.time() }
					migrated.lastSeen = os.time()
					return migrated
				end
				local fresh = defaultProfile()
				fresh.lock = { id = SESSION_ID, at = os.time() }
				return fresh
			end)
		end)
		if callOk and res ~= nil then
			claimed = res
			ok = true
			break
		end
		if callOk and res == nil then
			--- the transform cancelled: locked elsewhere, or unreadable. Waiting can help with a
			--- lock, never with a corrupt profile, so bounded retries either way.
			Log.warn("%s: profile locked or unreadable (attempt %d/%d)", player.Name, i, MAX_ATTEMPTS)
		end
		task.wait(1.5 * i)
	end

	if ok and claimed then
		profiles[userId] = claimed
		loadFailed[userId] = false
		Log.info("%s: profile loaded (v%d, robot %s)", player.Name, claimed.version,
			claimed.robot and claimed.robot.loadout and "present" or "MISSING")
	else
		profiles[userId] = defaultProfile()
		loadFailed[userId] = true
		--- 🔴 The load failed, so the real profile is unknown. This session runs on defaults and
		--- WILL NOT BE SAVED. Losing one session beats overwriting a real profile with a guess.
		Log.error("%s: PROFILE LOAD FAILED -- running session-only, saves are DISABLED for them",
			player.Name)
	end
	loading[userId] = nil
	return profiles[userId]
end

--- 🔴 BLOCK UNTIL THE PROFILE IS ACTUALLY LOADED.
---
--- MEASURED BUG this exists to fix: `BaseClaimService` claimed a bay and `RobotSpawner` built a
--- robot **before** the DataStore load returned, so it read the default starter loadout. After a
--- restart the profile correctly said `Arm = PIPE_WRENCH` while the robot standing in the bay was
--- still holding `RUSTY_WRENCH`. The profile was never corrupted -- but the player saw the wrong
--- robot, every single join.
---
--- ⚠️ Yields. Never call it from inside a `UpdateAsync` transform, and never from a path that must
--- not block -- the nameplate deliberately does not wait, so a bay lights up immediately.
function PlayerProfile.waitReady(player: Player, timeoutSeconds: number?): boolean
	local userId = player.UserId
	local deadline = os.clock() + (timeoutSeconds or 10)
	while (loading[userId] or profiles[userId] == nil) and os.clock() < deadline do
		if not player.Parent then
			return false
		end
		task.wait(0.1)
	end
	local ready = profiles[userId] ~= nil and not loading[userId]
	if not ready then
		Log.warn("%s: profile still not ready after %.0fs -- caller will see defaults",
			player.Name, timeoutSeconds or 10)
	end
	return ready
end

--------------------------------------------------------------------------------
-- Save
--------------------------------------------------------------------------------

--- Write a profile back by USER ID. `release` drops the session lock (use on leave / shutdown).
---
--- 🔴 KEYED ON userId, NOT ON A LIVE `Player`. Measured in Studio: pressing Stop tore the session
--- down without our `PlayerRemoving` handler ever running, `Players:GetPlayers()` was already empty
--- by `BindToClose`, and the session lock was left behind -- the next session then correctly refused
--- to steal it and ran session-only. A shutdown path that can only save players still in
--- `Players:GetPlayers()` cannot release the profiles it is holding, which is the one job it has.
function PlayerProfile.saveId(userId: number, release: boolean?, label: string?): boolean
	local who = label or ("userId " .. tostring(userId))
	local p = profiles[userId]
	if not p then
		return false
	end
	if loadFailed[userId] then
		--- 🔴 the rule this module exists for
		Log.warn("%s: refusing to save -- the load failed, so this profile is a guess", who)
		return false
	end
	if not storeOk or not store then
		return false
	end

	p.lastSeen = os.time()
	local snapshot = p

	local ok = attempt(("save %s"):format(who), function()
		return (store :: DataStore):UpdateAsync(key(userId), function(old)
			--- ⚠️ NO YIELDING IN HERE.
			if old ~= nil and type(old) == "table" and type(old.lock) == "table" then
				if old.lock.id ~= SESSION_ID and not lockIsStale(old) then
					--- another server took this profile over while we held it. Ours is now the
					--- stale one; writing would roll their session back.
					return nil
				end
			end
			--- 🔴 `if-then-else`, NOT `release and nil or {...}`.
			---
			--- That expression can never yield nil: `true and nil` is nil, and `nil or {...}` is
			--- then the table -- so **releasing wrote a fresh lock instead of clearing it**, on
			--- every leave and every `BindToClose`. Caught by `luau-analyze`'s `MisleadingAndOr`,
			--- not by any test: nothing here throws and the save still succeeds.
			---
			--- ⚠️ Why it stayed invisible: `LOCK_STALE_SECONDS` is 10 in Studio, so a leftover lock
			--- went stale before anyone could notice, and a rejoin on the SAME server passes
			--- `lockIsMine`. In production the stale window is **180 s**, and the case it breaks is
			--- a player who leaves and rejoins onto a DIFFERENT server inside three minutes -- a
			--- normal thing to do, and they would have been refused their own profile and handed a
			--- session-only one. The one bug class this module is built to prevent.
			snapshot.lock = if release then nil else { id = SESSION_ID, at = os.time() }
			return snapshot
		end)
	end)
	if ok and release then
		profiles[userId] = nil
		loadFailed[userId] = nil
	end
	return ok
end

--- Convenience wrapper for the common case where a `Player` is in hand.
function PlayerProfile.save(player: Player, release: boolean?): boolean
	return PlayerProfile.saveId(player.UserId, release, player.Name)
end

--------------------------------------------------------------------------------
-- Accessors
--------------------------------------------------------------------------------

function PlayerProfile.get(player: Player): any?
	return profiles[player.UserId]
end

function PlayerProfile.isSessionOnly(player: Player): boolean
	return loadFailed[player.UserId] == true
end

--- The player's robot loadout, or the starter if they somehow have none.
function PlayerProfile.loadout(player: Player): { [string]: string }
	local p = profiles[player.UserId]
	if p and p.robot and type(p.robot.loadout) == "table" then
		return p.robot.loadout
	end
	return StarterRobot.newLoadout()
end

--- What this player owns, as `partId -> true`. Read-only to callers by convention; the returned
--- table IS the profile's, so a caller that writes to it edits the save.
function PlayerProfile.owned(player: Player): { [string]: boolean }
	local p = profiles[player.UserId]
	if p and p.robot and type(p.robot.owned) == "table" then
		return p.robot.owned
	end
	return {}
end

--- 🔴 The ONLY question the install path asks about ownership, and it asks the SERVER's profile.
function PlayerProfile.owns(player: Player, partId: string): boolean
	return PlayerProfile.owned(player)[partId] == true
end

--- Add a part to the player's inventory. Returns false when there is no profile to change, and
--- `alreadyOwned` so a caller can tell a first grant from a repeat.
---
--- ⚠️ Grants into memory only, like `setSlot` -- the auto-save loop and the leave hook persist it.
--- Deliberately NOT a save: the SECURED moment (decision 0008) will grant several parts at once
--- and each one forcing a DataStore write would blow the per-key budget.
function PlayerProfile.grant(player: Player, partId: string): (boolean, boolean)
	local p = profiles[player.UserId]
	if not (p and p.robot and type(p.robot.owned) == "table") then
		return false, false
	end
	local already = p.robot.owned[partId] == true
	p.robot.owned[partId] = true
	return true, already
end

--- Change one slot. In memory only -- the auto-save loop and the leave hook persist it.
function PlayerProfile.setSlot(player: Player, slot: string, partId: string?): boolean
	local p = profiles[player.UserId]
	if not (p and p.robot and type(p.robot.loadout) == "table") then
		return false
	end
	p.robot.loadout[slot] = partId
	return true
end

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

function PlayerProfile.start()
	if started then
		Log.warn("start() called twice -- ignoring")
		return
	end
	started = true

	--- Is there a DataStore at all? In Studio without "Access to API Services" every call throws,
	--- and the honest answer is a session-only mode that says so, not a stack trace per join.
	local ok, res = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok and res then
		store = res
		--- GetDataStore succeeding does not prove access works, so probe with a real read.
		local probeOk = pcall(function()
			return (store :: DataStore):GetAsync("__probe")
		end)
		storeOk = probeOk
		if not probeOk then
			Log.error("DataStore unreachable (Studio Access to API Services off?) -- SESSION-ONLY mode")
		end
	else
		storeOk = false
		Log.error("GetDataStore failed: %s -- SESSION-ONLY mode", tostring(res))
	end

	if storeOk and RunService:IsStudio() then
		--- ⚠️ the `roblox-data` skill's warning, made impossible to miss
		Log.warn("STUDIO IS READING AND WRITING **LIVE** PLAYER DATA (store %q). The skill says to "
			.. "test persistence on a SEPARATE place.", STORE_NAME)
	end
	Log.info("ready -- store=%s session=%s", storeOk and STORE_NAME or "NONE (session-only)", SESSION_ID:sub(1, 8))

	Players.PlayerAdded:Connect(function(player)
		PlayerProfile.load(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		PlayerProfile.save(player, true)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerProfile.load, p)
	end

	--- auto-save loop: persists progress AND heartbeats the session lock so no other server
	--- decides ours is stale
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for _, player in ipairs(Players:GetPlayers()) do
				if profiles[player.UserId] and not loadFailed[player.UserId] then
					task.spawn(PlayerProfile.saveId, player.UserId, false, player.Name)
				end
			end
		end
	end)

	--- 🔴 Without this, every player's last session is lost on shutdown. Saves run in PARALLEL
	--- because the window is ~30s total, not 30s each.
	game:BindToClose(function()
		if not storeOk then
			return
		end
		--- 🔴 Iterate the profiles THIS SERVER HOLDS, not `Players:GetPlayers()`. In Studio the
		--- player list was already empty here, so a player-list loop released nothing and orphaned
		--- the lock. The `profiles` table is the authoritative record of what we must let go of.
		local ids = {}
		for userId in pairs(profiles) do
			table.insert(ids, userId)
		end
		if #ids == 0 then
			return
		end
		Log.info("BindToClose: releasing %d profile(s)", #ids)
		local remaining = #ids
		for _, userId in ipairs(ids) do
			task.spawn(function()
				PlayerProfile.saveId(userId, true)
				remaining -= 1
			end)
		end
		local deadline = os.clock() + CLOSE_BUDGET_SECONDS
		while remaining > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
		if remaining > 0 then
			Log.error("BindToClose ran out of time with %d profile(s) unsaved", remaining)
		else
			Log.info("BindToClose: all profiles saved")
		end
	end)
end

return PlayerProfile
