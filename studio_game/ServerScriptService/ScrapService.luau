--!strict
--[[
	ScrapService — the server half of the magnet. Owns the pool, the state machine, and the
	grant. Never trusts a client.

	THE FOUR STATES (decision 0005). Only one of them costs physics, and it is CAPPED:

	  IDLE       anchored, parked in the field. A transform. Thousands are fine.
	  REACT      anchored, shaking. A client-side tween. Hundreds are fine.
	  PULL       UNANCHORED, network ownership handed to the pulling player.
	             Real physics -- paid for by that client, not the server. CAPPED.
	  COLLECTED  returned to the pool, RE-ANCHORED, parked.

	Handing ownership is what makes decisions 0002 and 0005 agree rather than conflict: the
	client owns the MOTION (so it is instant on any connection and free for the server), the
	server owns the GRANT (so a claim is checked against what it actually spawned).

	⚠️ The single most likely exploit in a magnet game is "the client says it collected 4,000
	scrap". Every claim is checked against the server's own registry: an id it never spawned,
	or one already claimed, or one too far from the claimant, is rejected and rate-limited.

	Sources: docs/systems/magnet/README.md · decisions 0002, 0005, 0007
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 15)
local Magnet = require(Config:WaitForChild("Magnet", 15))
local ScrapSpec = require(ReplicatedStorage:WaitForChild("Scrap", 15):WaitForChild("ScrapSpec", 15))
local MaterialKit = require(ReplicatedStorage:WaitForChild("MaterialKit", 15))
local Log = require(ReplicatedStorage:WaitForChild("Log", 15)).scope("Scrap")
-- one-way: MagnetState must never require this module back
local MagnetState = require(script.Parent:WaitForChild("MagnetState", 15))

local ScrapService = {}

--- Running tally of why claims are turned away, for `scrap.why`. An honest client sweeping a
--- field should sit near zero on every gate; anything else is either an exploit or a gate
--- that is rejecting real play, and the two are indistinguishable from a bare total.
ScrapService.rejectCensus = {
	asked = 0, granted = 0,
	unknown = 0, notOwner = 0, tooFar = 0, tooSoon = 0, tooHeavy = 0, noRoom = 0,
}

export type State = "IDLE" | "REACT" | "PULL"

type Entry = {
	id: number,
	part: BasePart,
	def: ScrapSpec.ScrapDef,
	home: Vector3, -- where it was spawned; a released or reaped PULL returns here
	state: State,
	owner: Player?, -- who is pulling it
	pulledAt: number?, -- os.clock() when PULL began; drives the reaper AND the travel gate
	pullFrom: Vector3?, -- where it was when PULL began; the travel gate measures from here
}

local FOLDER_NAME = "Scrap"
local ATTR_ID = "ScrapId"

local registry: { [number]: Entry } = {}
local pool: { BasePart } = {}
local folder: Folder
local nextId = 1
local rng = Random.new(20260829)

--- Per-player pull counts, so the cap is enforced per magnet rather than globally.
local pulling: { [Player]: number } = {}

--- Per-player pull CAP. Decision 0012 makes this a per-DEVICE budget, so the client reports
--- its own measured tier and the server holds it to that. Previously the server hardcoded
--- `Medium` for everybody: the tier existed in the config, was audited on startup, and was
--- enforced nowhere -- a phone got the desktop budget.
---
--- Trusting the client is safe in one direction only, and that is the direction used: the
--- value is clamped to the High ceiling, so a lying client can lower its own cap and never
--- raise it past what any player is allowed anyway.
local playerCap: { [Player]: number } = {}

local function capFor(player: Player): number
	return playerCap[player] or Magnet.MAX_CONCURRENT_PULL.Low -- not yet reported = phone floor
end

function ScrapService.setQualityTier(player: Player, tierName: any)
	local want = Magnet.MAX_CONCURRENT_PULL[tostring(tierName)]
	if type(want) ~= "number" then
		return -- unknown tier name: keep whatever this player already had
	end
	playerCap[player] = math.min(want, Magnet.MAX_CONCURRENT_PULL.High)
	Log.debug("%s reports tier %s -> pull cap %d", player.Name, tostring(tierName), playerCap[player])
end

--------------------------------------------------------------------------------
-- Pool. Decision 0005: mandatory from the first prototype, not retrofitted.
--
-- 🔴 The leak that breaks the whole budget is a part returned to the pool WITHOUT being
-- re-anchored: it stays in the physics solver forever and the cap silently stops meaning
-- anything. `release` is the only path back, and it re-anchors first.
--------------------------------------------------------------------------------

local function newPart(): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false -- scrap never blocks the player; it is swept, not walked into
	p.CanTouch = false
	p.CanQuery = true -- the magnet's radius query MUST find these
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = folder
	return p
end

local function acquire(): BasePart?
	local p = table.remove(pool)
	if p then
		return p
	end
	local live = #folder:GetChildren()
	if live >= Magnet.POOL.MAX_SIZE then
		return nil -- hard ceiling; skip the spawn rather than allocate forever
	end
	return newPart()
end

local function release(entry: Entry)
	local p = entry.part
	if entry.owner then
		local n = pulling[entry.owner]
		if n == nil or n <= 0 then
			-- ⚠️ Do not silently clamp and carry on. A pull counter at zero on release means an
			-- object left PULL twice, or entered it without counting, and the visible symptom
			-- is a magnet that stops working -- so the corruption has to be audible where it
			-- happens, rather than diagnosed later from a dead magnet.
			Log.warn("pull counter for %s was %s on release -- counter out of sync",
				entry.owner.Name, tostring(n))
		end
		pulling[entry.owner] = math.max(0, (n or 1) - 1)
	end
	-- ⚠️ ORDER MATTERS. Re-anchor BEFORE parking, and always, on every path. Anchoring does
	-- NOT zero velocity, so it is zeroed explicitly or the stale value survives into this
	-- part's NEXT pull.
	p.Anchored = true
	p.AssemblyLinearVelocity = Vector3.zero
	p.AssemblyAngularVelocity = Vector3.zero
	p.CFrame = CFrame.new(0, Magnet.POOL.PARK_Y, 0)
	p.Transparency = 1
	p.CanQuery = false -- a pooled part must not answer the magnet's radius query
	p:SetAttribute(ATTR_ID, nil)
	p:SetAttribute("ScrapState", nil)
	p:SetAttribute("PullOwner", nil)
	registry[entry.id] = nil
	table.insert(pool, p)
end

--------------------------------------------------------------------------------

function ScrapService.init()
	folder = workspace:FindFirstChild(FOLDER_NAME) :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = workspace
	else
		folder:ClearAllChildren()
	end
	table.clear(registry)
	table.clear(pool)
	-- ⚠️ Without this a leaked pull count survives the reset: `scrap.clear` looked like the
	-- nuclear option and could not un-brick a magnet, because the count that bricked it lives
	-- here and not in the registry it clears. Only rejoining fixed it.
	table.clear(pulling)
	for _ = 1, Magnet.POOL.INITIAL_SIZE do
		local p = newPart()
		p.Transparency = 1
		p.CanQuery = false
		p.CFrame = CFrame.new(0, Magnet.POOL.PARK_Y, 0)
		table.insert(pool, p)
	end
	Log.info("pool primed with %d parts", #pool)
end

--- Spawn one piece of scrap at `position`.
function ScrapService.spawn(position: Vector3, def: ScrapSpec.ScrapDef?): number?
	local p = acquire()
	if not p then
		return nil
	end
	local d = def or ScrapSpec.pick(rng)
	local id = nextId
	nextId += 1

	p.Size = Vector3.new(d.size[1], d.size[2], d.size[3])
	if d.shape == "Ball" then
		(p :: any).Shape = Enum.PartType.Ball
	elseif d.shape == "Cylinder" then
		(p :: any).Shape = Enum.PartType.Cylinder
	else
		(p :: any).Shape = Enum.PartType.Block
	end
	local rot = CFrame.new()
	if d.shape == "Cylinder" then
		-- same convention as the kit: a Cylinder's length is its Size.X, always
		if d.along == "Y" then
			rot = CFrame.Angles(0, 0, math.rad(90))
		elseif d.along == "Z" then
			rot = CFrame.Angles(0, math.rad(90), 0)
		end
	end
	p.CFrame = CFrame.new(position) * rot * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	p.Transparency = 0
	p.Anchored = true
	p.CanQuery = true -- back in play: the magnet's radius query must find it again
	MaterialKit.apply(p, d.surface, d.color and Color3.fromHex(d.color) or nil)
	p.Name = d.id
	p:SetAttribute(ATTR_ID, id)
	p:SetAttribute("ScrapState", "IDLE")
	p:SetAttribute("ScrapWeight", d.weight)
	p:SetAttribute("ScrapSound", d.sound)

	registry[id] = {
		id = id, part = p, def = d, home = position, state = "IDLE",
		owner = nil, pulledAt = nil, pullFrom = nil,
	}
	return id
end

--- Where the ground actually is under `x, z`, or nil if there is none. A raycast, because
--- the floor of a factory tier is not at a height this module is allowed to assume.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = true

local function groundY(x: number, z: number, from: number): number?
	groundParams.FilterDescendantsInstances = { folder } -- never land on other scrap
	local hit = workspace:Raycast(Vector3.new(x, from + 60, z), Vector3.new(0, -400, 0), groundParams)
	return hit and hit.Position.Y or nil
end

--- Scatter a field of scrap. Returns how many actually spawned (the pool may cap it).
---
--- ⚠️ The drop height is MEASURED per piece, never taken from a constant. Scrap sitting 3.5
--- studs in the air, or half-buried in the floor, is the same bug either way: `centre.Y`
--- describes wherever the caller happened to be standing, and the caller is a player.
function ScrapService.spawnField(centre: Vector3, radius: number, count: number): number
	local n, ungrounded = 0, 0
	for _ = 1, count do
		local a = rng:NextNumber() * math.pi * 2
		local r = math.sqrt(rng:NextNumber()) * radius
		local x, z = centre.X + math.cos(a) * r, centre.Z + math.sin(a) * r
		local y = groundY(x, z, centre.Y)
		if not y then
			ungrounded += 1
			continue -- no floor here: spawning would drop it out of the world
		end
		if ScrapService.spawn(Vector3.new(x, y + 0.35, z)) then
			n += 1
		end
	end
	if ungrounded > 0 then
		Log.warn("%d of %d spawn points had no ground beneath them -- skipped", ungrounded, count)
	end
	Log.info("spawned %d scrap around %s (r=%d)", n, tostring(centre), radius)
	return n
end

--------------------------------------------------------------------------------
-- The state tick. The SERVER decides transitions -- it already knows every player
-- position and every scrap position, so this needs no client remote at all.
--------------------------------------------------------------------------------

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include
-- MaxParts is deliberately left at its default 0 = NO LIMIT. A cap makes the query drop parts
-- with no documented ordering guarantee, so in a dense field the same objects can come back
-- every tick while others are never seen: they never react, never become collectable, and
-- nothing errors. The part budget is enforced by the pool ceiling, not by blinding the query.

--- ⚠️ The RADIUS here is the ACTIVE one, so MAGNET RUSH is visible to the system whose
--- behaviour it exists to change. Reading `stats().Radius` instead would leave the Rush
--- multiplier configured, logged, and doing nothing -- the same shape of bug as the pull cap
--- that was hardcoded to Medium while the tier was audited on startup (job 007).
local function playerStats(player: Player)
	local s = MagnetState.stats(player)
	return {
		Power = s.Power,
		Radius = MagnetState.activeRadius(player),
		Drive = s.Drive,
		Capacity = s.Capacity,
	}
end

local function tick()
	overlap.FilterDescendantsInstances = { folder }

	-- ⚠️ THE EXIT DOOR -- and it runs BEFORE the per-player sweep, so an object reaped this
	-- tick is available to be pulled again in the same tick.
	--
	-- A pull is client-driven. If the client stops driving it -- death, alt-tab (RenderStepped
	-- stops when the client is not drawing), streaming out, or simply walking away -- the
	-- object stays unanchored forever, holds a cap slot forever, and eventually falls past
	-- FallenPartsDestroyHeight where the ENGINE destroys it. The registry then pins a
	-- destroyed Instance in PULL, the count never comes back, and that player's magnet is dead
	-- for the rest of the session. Nothing else here leaves PULL except a successful claim.
	local now = os.clock()
	-- ⚠️ A magnet that has just filled must DROP what it is carrying in, not keep flying it
	-- in to be refused at the door. Leaving those objects in PULL spins the claim loop: the
	-- object arrives, the grant refuses it for lack of room, the client restores it, it
	-- arrives again. Measured before this existed: 329 of 355 claims refused as FULL, a 93%
	-- rejection rate and a remote fired every 0.25s for as long as the player stood there.
	local isFull: { [Player]: boolean } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		isFull[player] = MagnetState.isFull(player)
	end

	for _, entry in pairs(registry) do
		if entry.state ~= "PULL" then
			continue
		end
		local owner = entry.owner
		local ownerChar = owner and owner.Character
		local expired = (now - (entry.pulledAt or now)) > Magnet.PULL_TIMEOUT
		-- ⚠️ The height bound is the one that actually works. See Magnet.PULL_FALL_LIMIT: an
		-- abandoned piece falls through the floor (CanCollide = false) and the engine deletes
		-- it in ~2.3s, so waiting for a timeout loses the part -- the magnet survives, but the
		-- pool bleeds a part per abandoned pull, permanently.
		local sank = entry.part.Position.Y < entry.home.Y - Magnet.PULL_FALL_LIMIT
		local orphaned = owner == nil
			or owner.Parent == nil
			or ownerChar == nil
			or ownerChar:FindFirstChild("HumanoidRootPart") == nil
		if entry.part.Parent == nil then
			-- already destroyed by the engine: drop the entry rather than pin a corpse
			if owner then
				pulling[owner] = math.max(0, (pulling[owner] or 1) - 1)
			end
			registry[entry.id] = nil
			Log.warn("scrap %d was destroyed while in PULL -- entry dropped", entry.id)
		elseif expired or orphaned or sank or (owner and isFull[owner]) then
			ScrapService.recover(entry)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			continue
		end
		local stats = playerStats(player)
		local pullR = stats.Radius
		local reactR = Magnet.reactRadius(pullR)
		local cap = capFor(player) -- this client's OWN measured budget (decision 0012)
		if MagnetState.inRush(player) then
			cap = math.floor(cap * Magnet.RUSH.PULL_CAP_MULTIPLIER)
		end
		pulling[player] = pulling[player] or 0

		-- ⚠️ SCRAP FULL stops the PULL, not the grant. A full magnet that still drags objects
		-- in and then refuses them at the last moment reads as a broken magnet; one that
		-- visibly stops lifting, while everything still shakes in range, reads as "I am full"
		-- and sends the player home. The signal has to be the thing that stops.
		local full = MagnetState.isFull(player)

		local near = workspace:GetPartBoundsInRadius(root.Position, reactR, overlap)
		for _, part in ipairs(near) do
			local id = part:GetAttribute(ATTR_ID)
			local entry = id and registry[id :: number]
			if not entry or entry.state == "PULL" then
				continue
			end
			local dist = (part.Position - root.Position).Magnitude
			local canLift = entry.def.weight <= stats.Power

			if dist <= pullR and canLift and not full and pulling[player] < cap then
				-- REACT -> PULL. Unanchor and hand ownership to the puller: the client pays
				-- for the physics and feels it instantly; the server pays nothing.
				entry.state = "PULL"
				entry.owner = player
				entry.pulledAt = os.clock()
				entry.pullFrom = part.Position
				pulling[player] += 1
				part.Anchored = false
				part:SetAttribute("ScrapState", "PULL")
				-- ⚠️ GetNetworkOwner is SERVER-ONLY. The client cannot ask who owns a part, so
				-- the server states it in an attribute the client can read. Without this the
				-- client's pull branch never runs and the console fills with
				-- "Network Ownership API can only be called from the Server".
				part:SetAttribute("PullOwner", player.UserId)
				local ok = pcall(function()
					part:SetNetworkOwner(player)
				end)
				if not ok then
					-- ownership refused: fall back to IDLE rather than leaving it unanchored
					part.Anchored = true
					entry.state = "IDLE"
					entry.owner = nil
					pulling[player] -= 1
					part:SetAttribute("ScrapState", "IDLE")
					part:SetAttribute("PullOwner", nil)
				end
			else
				-- inside REACT range: shake, spark, and say WHY if it cannot be lifted
				local want = canLift and "REACT" or "REFUSE"
				-- ⚠️ Compare the ATTRIBUTE, not `entry.state`. There is no REFUSE entry state --
				-- both cases store "REACT" -- so guarding on `entry.state ~= "REACT"` made this
				-- a one-shot edge: the attribute was written once and never revisited while the
				-- object stayed in range. Buy the Power upgrade that fixes a too-heavy object
				-- and it kept shaking REFUSE, so the game said "still too heavy" immediately
				-- after the purchase that fixed it. REFUSE is the tutorial for upgrading Power;
				-- it has to stop the moment the upgrade lands.
				entry.state = "REACT"
				if part:GetAttribute("ScrapState") ~= want then
					part:SetAttribute("ScrapState", want)
				end
			end
		end
	end

	-- ⚠️ THE REACT EXIT. Without it, once REACT always REACT: walk away and every object you
	-- ever passed keeps shaking on every client, and REACT is the state the client animates
	-- per frame -- so its cost only ever grows. The design sells the react ring as "your reach
	-- ARRIVING", and a ring that never goes out says nothing.
	-- ⚠️ Reach is computed ONCE PER PLAYER, not once per (entry, player). Stats derive from
	-- upgrade levels through four exponentials, and this loop runs over every live entry --
	-- so calling it inside the inner loop is O(entries x players) exponentials at 10Hz, which
	-- is 300 entries x 12 players x 8 pow() calls every tick for a number that cannot change
	-- inside the loop.
	local reach: { { root: BasePart, r2: number } } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local r = Magnet.reactRadius(playerStats(player).Radius)
			table.insert(reach, { root = root, r2 = r * r })
		end
	end
	for _, entry in pairs(registry) do
		if entry.state ~= "REACT" then
			continue
		end
		local pos = entry.part.Position
		local stillNear = false
		for _, w in ipairs(reach) do
			-- squared compare via Dot: `.Magnitude ^ 2` would take the square root and then
			-- undo it, which is the opposite of the point
			local d = pos - w.root.Position
			if d:Dot(d) <= w.r2 then
				stillNear = true
				break
			end
		end
		if not stillNear then
			entry.state = "IDLE"
			entry.part:SetAttribute("ScrapState", "IDLE")
		end
	end
end

--- Take an in-flight object back: free the cap slot, re-anchor it, return it home. Together
--- with a successful claim this is the ONLY way out of PULL, and every caller uses it rather
--- than open-coding the steps, so no path can drift out of sync with the others.
function ScrapService.recover(entry: Entry)
	local part = entry.part
	if entry.owner then
		pulling[entry.owner] = math.max(0, (pulling[entry.owner] or 1) - 1)
	end
	part.Anchored = true
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
	part.CFrame = CFrame.new(entry.home)
	part.Transparency = 0 -- the client hides it locally on arrival; this server write repairs that
	part:SetAttribute("PullOwner", nil)
	part:SetAttribute("ScrapState", "IDLE")
	entry.state = "IDLE"
	entry.owner = nil
	entry.pulledAt = nil
	entry.pullFrom = nil
end

--------------------------------------------------------------------------------
-- The grant. Batched, validated, rate-limited.
--------------------------------------------------------------------------------

--- Validate and grant a batch of claimed ids. Returns (accepted ids, total value, reason?).
function ScrapService.claim(player: Player, ids: { any }): ({ number }, number, string?)
	if type(ids) ~= "table" then
		return {}, 0, "malformed"
	end
	local maxBatch = Magnet.maxGrantPerTick("High")
	if #ids > maxBatch then
		Log.warn("%s claimed %d ids, ceiling is %d -- rejected", player.Name, #ids, maxBatch)
		return {}, 0, "batch too large"
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return {}, 0, "no character"
	end
	local stats = playerStats(player)
	-- Derived from the rig, never from the pull radius -- see Magnet.grantRange.
	local maxDist = Magnet.grantRange()

	local accepted, value, rejected = {}, 0, 0
	local why = { unknown = 0, notOwner = 0, tooFar = 0, tooSoon = 0, tooHeavy = 0, noRoom = 0 }
	for _, raw in ipairs(ids) do
		local id = tonumber(raw)
		local entry = id and registry[id]
		if not entry then
			why.unknown += 1
			continue -- never spawned, or already collected. Silently ignored.
		end
		if entry.owner ~= player then
			why.notOwner += 1
			continue -- claiming something another magnet is pulling, or already reaped
		end
		if (entry.part.Position - root.Position).Magnitude > maxDist then
			rejected += 1
			why.tooFar += 1
			continue -- too far from the magnet to have arrived at it
		end
		-- ⚠️ THE TRAVEL GATE. Distance alone asks only WHERE the object is, never whether it
		-- got there: an exploiter who moves an object to the magnet passes a distance check
		-- instantly, and collection then happens at the server tick rate rather than the
		-- physics transit rate. So the object must ALSO have been in PULL for as long as the
		-- journey would really have taken.
		--
		-- ⚠️ The journey is measured from where the pull BEGAN to the magnet -- NOT by how far
		-- the object has actually moved. Measuring distance moved makes the gate vacuous for
		-- precisely the case it exists to catch: an object that never moves has travelled 0
		-- studs, needs 0 seconds, and is granted immediately. An object that was already at
		-- the magnet when the pull began still passes, and should: there was no journey.
		local journey = entry.pullFrom and (entry.pullFrom - root.Position).Magnitude or 0
		local elapsed = os.clock() - (entry.pulledAt or 0)
		if elapsed < Magnet.minTravelTime(journey, entry.def.weight, stats.Power) then
			rejected += 1
			why.tooSoon += 1
			continue
		end
		if entry.def.weight > stats.Power then
			rejected += 1
			why.tooHeavy += 1
			continue -- could never have been lifted in the first place
		end
		-- a full magnet cannot bank a partial batch and silently drop the rest
		if value + entry.def.value > MagnetState.headroom(player) then
			rejected += 1
			why.noRoom += 1
			continue
		end
		table.insert(accepted, entry.id)
		value += entry.def.value
		release(entry)
	end
	local dropped = rejected + why.unknown + why.notOwner
	if dropped > 0 then
		-- ⚠️ Name the gate. "13 of 30 rejected" is a number to argue about; a census is a
		-- reading, and it is what turned a guess about the travel gate into the real cause.
		ScrapService.rejectCensus.unknown += why.unknown
		ScrapService.rejectCensus.notOwner += why.notOwner
		ScrapService.rejectCensus.tooFar += why.tooFar
		ScrapService.rejectCensus.tooSoon += why.tooSoon
		ScrapService.rejectCensus.tooHeavy += why.tooHeavy
		ScrapService.rejectCensus.noRoom += why.noRoom
		Log.debug("%s: %d of %d dropped (gone %d, notMine %d, far %d, soon %d, heavy %d, full %d)",
			player.Name, dropped, #ids, why.unknown, why.notOwner, why.tooFar, why.tooSoon,
			why.tooHeavy, why.noRoom)
	end
	ScrapService.rejectCensus.asked += #ids
	ScrapService.rejectCensus.granted += #accepted
	return accepted, value, dropped > 0 and ("%d of %d rejected"):format(dropped, #ids) or nil
end

--- Release everything a leaving player was pulling, so nothing is left unanchored and
--- ownerless (which is the pool leak decision 0005 warns about).
Players.PlayerRemoving:Connect(function(player)
	for _, entry in pairs(registry) do
		if entry.owner == player then
			ScrapService.recover(entry)
		end
	end
	pulling[player] = nil
	playerCap[player] = nil
end)

--- Live count of unanchored scrap in the WORLD. Decision 0005's check is a COUNT, never a
--- reading of the config value -- so this is the function that check calls.
---
--- ⚠️ It must iterate the FOLDER, not the registry. The leak decision 0005 names is "a part
--- returned to the pool without being re-anchored", and returning to the pool REMOVES the
--- registry entry -- so a registry-based count was structurally blind to the one failure it
--- existed to catch, and reported 0 while parts leaked. It also could not see a part the
--- engine had already destroyed. PITFALLS #2: a verification that cannot fail.
function ScrapService.unanchoredCount(): number
	if not folder then
		return 0
	end
	local n = 0
	for _, part in ipairs(folder:GetChildren()) do
		if part:IsA("BasePart") and not part.Anchored then
			n += 1
		end
	end
	return n
end

function ScrapService.stats(): { [string]: number }
	local live, react, pull = 0, 0, 0
	for _, e in pairs(registry) do
		live += 1
		if e.state == "REACT" then
			react += 1
		elseif e.state == "PULL" then
			pull += 1
		end
	end
	local destroyed = 0
	for _, e in pairs(registry) do
		if e.part.Parent == nil then
			destroyed += 1 -- a registry entry pinning an Instance the engine has deleted
		end
	end
	return {
		live = live,
		react = react,
		pull = pull,
		pooled = #pool,
		unanchored = ScrapService.unanchoredCount(),
		destroyed = destroyed,
		folderParts = folder and #folder:GetChildren() or 0,
	}
end

function ScrapService.start()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.1 then
			acc = 0
			tick()
		end
	end)
	Log.info("state tick running at 10Hz")
end

return ScrapService
