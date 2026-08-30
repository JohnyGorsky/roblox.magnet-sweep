--!strict
--[[
	MagnetController — the client half of the magnet. This is where the game FEELS like
	something.

	Decision 0002: the client renders and reports intent; the server grants. The server has
	already handed us network ownership of every PULL object, so moving them here is both
	authoritative for physics and free for the server.

	What this does:
	  * draws the magnet (red/cyan poles -- the game's logo, its icon and its cursor)
	  * shakes REACT objects, and shakes-but-refuses ones too heavy to lift
	  * drives PULL objects toward the magnet with real velocity
	  * batches arrivals and claims them on a 0.25s tick -- NEVER one remote per object
	  * ROLLS THE HIDE BACK when the server rejects a claim

	⚠️ `GetNetworkOwner` is SERVER-ONLY. The client cannot ask who owns a part -- calling it
	here threw once per part per frame and silently disabled the entire pull path. The server
	states the owner in a `PullOwner` attribute instead, which is what this reads.

	⚠️ `.local.luau` -> LocalScript on purpose. A `.client.luau` in StarterPlayerScripts runs
	TWICE (job 002), which here would mean two magnets fighting over the same objects.

	Sources: docs/systems/magnet/README.md · decisions 0002, 0005
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local Magnet = require(Config:WaitForChild("Magnet", 20))
local Vfx = require(Config:WaitForChild("Vfx", 20))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Magnet")

local player = Players.LocalPlayer
local claimRemote = Remotes.getEvent("ClaimScrap", 20)
local grantedRemote = Remotes.getEvent("ScrapGranted", 20)
local statsRemote = Remotes.getEvent("StatsChanged", 20)

--- ⚠️ The server's numbers, never our own. The pull speed the client drives at is the same
--- function the server's travel gate judges arrivals against (Magnet.pullSpeed), so if this
--- client keeps using the STARTER power after the player has upgraded, it drives too slowly
--- for its own claims and the server starts refusing honest collections. `Magnet.START` was
--- hardcoded here until job 008; it was invisible only because no upgrade existed yet.
local myPower = Magnet.START.Power
local myFull = false

local ATTR_ID = "ScrapId"
local ATTR_STATE = "ScrapState"

--------------------------------------------------------------------------------
-- The magnet itself. Red + cyan poles, always -- it is the logo, the icon and the
-- Arena Core. Never recoloured outside a purchased skin.
--------------------------------------------------------------------------------

local magnetRoot: BasePart? = nil

local function buildMagnet(char: Model)
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("HumanoidRootPart")
	if not hand then
		return
	end
	local old = char:FindFirstChild("MagnetRig")
	if old then
		old:Destroy()
	end
	local rig = Instance.new("Model")
	rig.Name = "MagnetRig"

	local function bar(name: string, size: Vector3, offset: CFrame, colour: Color3)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = colour
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.Parent = rig
		local w = Instance.new("Weld")
		w.Part0 = hand :: BasePart
		w.Part1 = p
		w.C0 = offset
		w.Parent = p
		return p
	end

	-- ⚠️ Vfx.RED / Vfx.CYAN, not hex literals. The particles and both beams already read those
	-- constants; a second copy here means a magnet SKIN recolours the field and leaves the
	-- physical poles signal-red, and nothing errors. Config-first decays one constant at a time
	-- (PITFALLS #38, #52).
	bar("Core", Vector3.new(1.6, 0.5, 0.5), CFrame.new(0, -1.1, 0), Vfx.CORE)
	bar("PoleRed", Vector3.new(0.5, 1.3, 0.5), CFrame.new(-0.55, -1.8, 0), Vfx.RED)
	bar("PoleCyan", Vector3.new(0.5, 1.3, 0.5), CFrame.new(0.55, -1.8, 0), Vfx.CYAN)

	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.3, 0.3, 0.3)
	tip.Transparency = 1
	tip.CanCollide, tip.CanQuery, tip.CanTouch, tip.Massless = false, false, false, true
	tip.Parent = rig
	local tw = Instance.new("Weld")
	tw.Part0 = hand :: BasePart
	tw.Part1 = tip
	-- ⚠️ Magnet.TIP_OFFSET, not a literal. The server sizes its grant range off this number
	-- and cannot see the rig, so a tip moved only here starts failing honest collections.
	tw.C0 = CFrame.new(0, -Magnet.TIP_OFFSET, 0)
	tw.Parent = tip

	rig.Parent = char
	magnetRoot = tip
end

--------------------------------------------------------------------------------
-- What we animate.
--
-- ⚠️ Only the parts in a state worth animating, kept as a live set. Sweeping every child of
-- the Scrap folder each frame is O(all scrap) forever: the pool alone is 400 parts and the
-- ceiling is 1200, and all but a handful are parked and hidden. The states change rarely
-- (a server tick at 10Hz), the frame loop runs constantly -- so pay on the change.
--------------------------------------------------------------------------------

local active: { [BasePart]: string } = {}
local watching: { [BasePart]: RBXScriptConnection } = {}

local function noteState(part: BasePart)
	local state = part:GetAttribute(ATTR_STATE)
	if state == "REACT" or state == "REFUSE" or state == "PULL" then
		active[part] = state :: string
	else
		active[part] = nil
	end
end

local function watch(child: Instance)
	if not child:IsA("BasePart") or watching[child] then
		return
	end
	watching[child] = child:GetAttributeChangedSignal(ATTR_STATE):Connect(function()
		noteState(child)
	end)
	noteState(child)
end

local function unwatch(child: Instance)
	local conn = watching[child :: any]
	if conn then
		conn:Disconnect()
		watching[child :: any] = nil
	end
	active[child :: any] = nil
end

task.spawn(function()
	local folder = workspace:WaitForChild("Scrap", 60)
	if not folder then
		Log.warn("no Scrap folder after 60s -- the magnet has nothing to pull")
		return
	end
	for _, child in ipairs(folder:GetChildren()) do
		watch(child)
	end
	folder.ChildAdded:Connect(watch)
	folder.ChildRemoved:Connect(unwatch)
end)

--------------------------------------------------------------------------------
-- Motion.
--------------------------------------------------------------------------------

--- Ids claimed but not yet answered, and the part each belongs to, so a rejected claim can
--- put the object back exactly as it was.
local inFlight: { [number]: BasePart } = {}
local pending: { [number]: BasePart } = {}
local pendingAt: { [number]: number } = {}
local pendingCount = 0
local shakePhase = 0

local function updateScrap(dt: number)
	local tip = magnetRoot
	if not tip or not tip.Parent then
		return
	end
	local target = tip.Position
	shakePhase += dt * 18

	for part, state in pairs(active) do
		if part.Parent == nil then
			continue -- reaped between ticks; the ChildRemoved handler will clear it
		end
		if state == "REACT" or state == "REFUSE" then
			-- anchored: shake in place. REFUSE shakes harder and never moves -- the object
			-- itself is the tutorial for "upgrade your Magnet Power".
			local amp = state == "REFUSE" and Magnet.PULL.REFUSE_SHAKE_STUDS or 0.12
			local id = part:GetAttribute(ATTR_ID) or 0
			local jitter = Vector3.new(
				math.sin(shakePhase + id * 1.7) * amp,
				math.sin(shakePhase * 1.3 + id) * amp * 0.5,
				math.cos(shakePhase + id * 2.3) * amp
			)
			part.CFrame = CFrame.new(part.Position + jitter * dt * 12) * (part.CFrame - part.Position)
		elseif state == "PULL" and part:GetAttribute("PullOwner") == player.UserId then
			local id = part:GetAttribute(ATTR_ID)
			if id and (pending[id] or inFlight[id]) then
				-- ⚠️ HOLD IT AT THE MAGNET until the server answers. An arrived object is still
				-- unanchored, still CanCollide = false, and still owned by this client -- and
				-- nothing is driving it any more, so it FREE-FALLS while it waits for the next
				-- batch. Measured: 6.13 studs in one 0.25s flush interval, which drops it
				-- straight out of the server's 9-stud grant gate. That was 13 of every 30
				-- honest collections rejected, and the object silently restored.
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
				part.CFrame = CFrame.new(target)
				continue
			end
			local delta = target - part.Position
			local dist = delta.Magnitude
			if dist <= Magnet.PULL.ARRIVE_RADIUS then
				if id then
					pending[id] = part
					pendingAt[id] = os.clock()
					pendingCount += 1
					part.Transparency = 1 -- hide instantly; the server confirms and pools it
					part.AssemblyLinearVelocity = Vector3.zero
				end
			else
				-- ⚠️ Magnet.pullSpeed, not a local speed formula. The server's travel gate judges
				-- arrivals against this exact function, so a second copy here -- this had its
				-- own `math.max(mult, 0.15)` floor, a number found nowhere else in the game --
				-- means honest collections start getting rejected the day the curve is retuned.
				local weight = part:GetAttribute("ScrapWeight") or 1
				local speed = Magnet.pullSpeed(weight, myPower)
				if speed > 0 then
					part.AssemblyLinearVelocity = delta.Unit * speed
					part.AssemblyAngularVelocity = Vector3.new(6, 9, 4)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Claiming. Batched on a tick -- a Magnet Rush pulling 200 objects must not send 200
-- remotes, and the server rejects an oversized batch anyway.
--------------------------------------------------------------------------------

local function flush()
	if pendingCount == 0 then
		return
	end
	if myFull then
		-- ⚠️ Do not claim into a full magnet. The server refuses every one of them and the
		-- object comes straight back, so this is a remote fired four times a second that can
		-- never succeed. The server has already sent these objects home; forget them.
		table.clear(pending)
		table.clear(pendingAt)
		pendingCount = 0
		return
	end
	-- ⚠️ Claim on the flush AFTER arrival, never the one that merely happens to be next.
	-- The server judges the claim against the object POSITION IT HAS RECEIVED, and the arrival
	-- happened on this client: fire in the same frame and the server is still holding the
	-- position from before the pull -- up to a full pull radius away -- and rejects an honest
	-- collection. Measured: 57 of 184 claims turned away as TOO_FAR with zero exploit
	-- involved, every one of which then succeeded on a retry. The object is pinned at the
	-- magnet and already invisible, so this delay costs the player nothing.
	local now = os.clock()
	local ids = {}
	for id, part in pairs(pending) do
		if now - (pendingAt[id] or now) >= Magnet.GRANT.TICK then
			table.insert(ids, id)
			inFlight[id] = part
			pending[id] = nil
			pendingAt[id] = nil
			pendingCount -= 1
		end
	end
	if #ids == 0 then
		return
	end
	claimRemote:FireServer(ids)
end

--- ⚠️ The hide above is OPTIMISTIC: it happens before the server has agreed. So every claim
--- must be answered, and every id the server did NOT accept has to be put back -- otherwise
--- a rejection is invisible and permanent, the object stays hidden on this client for the
--- rest of the session while it is still very much in the world, and nothing anywhere
--- reports a problem. The server also repairs Transparency on its side when it reaps an
--- object; this handles the case where it stays in PULL and we simply guessed wrong.
grantedRemote.OnClientEvent:Connect(function(accepted: { number }, value: number, scrapTotal: number, asked: { number }?, reason: string?)
	local ok: { [number]: boolean } = {}
	for _, id in ipairs(accepted) do
		ok[id] = true
		inFlight[id] = nil
	end
	local restored = 0
	for _, id in ipairs(asked or {}) do
		local part = inFlight[id]
		inFlight[id] = nil
		pendingAt[id] = nil
		if not ok[id] and part and part.Parent then
			part.Transparency = 0 -- rejected: it is still out there, so show it again
			restored += 1
		end
	end
	if #accepted > 0 then
		Log.debug("granted %d objects, +%d scrap (total %d)", #accepted, value, scrapTotal or -1)
	end
	if restored > 0 then
		Log.warn("%d claims rejected (%s) -- objects restored", restored, reason or "no reason given")
	end
end)

--------------------------------------------------------------------------------

local function onCharacter(char: Model)
	char:WaitForChild("HumanoidRootPart", 10)
	buildMagnet(char)
	Log.info("magnet equipped")
end

if player.Character then
	onCharacter(player.Character)
end
player.CharacterAdded:Connect(onCharacter)

-- ⚠️ PreSimulation, not RenderStepped. This loop writes AssemblyLinearVelocity, so it belongs
-- immediately before the physics step rather than at the top of a render frame -- and
-- RenderStepped does not fire at all while the client is not drawing (PITFALLS: an
-- alt-tabbed client stops rendering), which would abandon every object it is mid-pull.
statsRemote.OnClientEvent:Connect(function(s)
	if type(s) ~= "table" then
		return
	end
	if type(s.power) == "number" then
		myPower = s.power
	end
	if type(s.full) == "boolean" then
		myFull = s.full
	end
end)

RunService.PreSimulation:Connect(updateScrap)

task.spawn(function()
	while true do
		task.wait(Magnet.GRANT.TICK)
		flush()
	end
end)
