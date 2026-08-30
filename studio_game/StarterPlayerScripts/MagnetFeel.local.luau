--!strict
--[[
	MagnetFeel — the magnet's five visual states and the nine object voices.

	This is the half of the magnet the MVP gate actually turns on. The gate question is
	"when the player sees a strange object in the distance, do they think *I want that on my
	robot*?", and the things to fix if the answer is no are, in order: the pull feel, **the
	sound**, and **the break-free moment**. Two of the three live here.

	⚠️ ONE emitter, ONE beam pair, ONE light — for all five states. systems/vfx-lighting budgets
	the magnet field as exactly that, and this runs continuously on every client for the whole
	session, so it is the effect that must be cheapest. A state changes the SETTINGS of the same
	instances; nothing is created or destroyed at runtime.

	⚠️ Sound slots are EMPTY until a human supplies ids, and that is deliberate (see SoundKit).
	`SoundKit.build` returns nil for an empty slot rather than a silent `Sound`, so nothing here
	can quietly look wired when it is not.

	⚠️ `.local.luau` -> LocalScript. A `.client.luau` in StarterPlayerScripts runs TWICE (job
	002), which here would be two magnets' worth of particles on one hand.

	Sources: docs/systems/vfx-lighting/README.md · docs/systems/audio/README.md · spec §14, §15
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local Vfx = require(Config:WaitForChild("Vfx", 20))
local Magnet = require(Config:WaitForChild("Magnet", 20))
local Quality = require(Config:WaitForChild("Quality", 20))
local SoundKit = require(ReplicatedStorage:WaitForChild("SoundKit", 20))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Feel")

local player = Players.LocalPlayer
local statsRemote = Remotes.getEvent("StatsChanged", 20)

local ATTR_STATE = "ScrapState"
local ATTR_SOUND = "ScrapSound"
local ATTR_ID = "ScrapId"

--------------------------------------------------------------------------------
-- Live facts about this player's magnet, pushed by the server.
--------------------------------------------------------------------------------

local flowTier = 0
local inRush = false
local inOvercharge = false

--- ⚠️ Forward declaration. The handler below is connected at the top of the file and the
--- rig helpers it needs are defined further down; without this, the closure would capture a
--- GLOBAL `playMagnet` that is nil forever and the sound would silently never play.
local playMagnet: (any) -> ()

--- ⚠️ These play on the EDGE, not on the value. `StatsChanged` fires on every collection, so
--- reacting to `s.rush == true` rather than to the transition would retrigger the Rush sound
--- several times a second for its whole duration.
local wasRush, wasFull = false, false

statsRemote.OnClientEvent:Connect(function(s)
	if type(s) ~= "table" then
		return
	end
	flowTier = tonumber(s.flowTier) or flowTier
	if type(s.rush) == "boolean" then
		inRush = s.rush
		if inRush and not wasRush then
			playMagnet(SoundKit.MAGNET.Rush)
		end
		wasRush = inRush
	end
	if type(s.overcharge) == "boolean" then
		inOvercharge = s.overcharge
	end
	if type(s.full) == "boolean" then
		if s.full and not wasFull then
			playMagnet(SoundKit.MAGNET.Full)
		end
		wasFull = s.full
	end
end)

--------------------------------------------------------------------------------
-- The rig. Built once, onto the magnet the MagnetController already made.
--------------------------------------------------------------------------------

type Rig = {
	emitter: ParticleEmitter,
	beamRed: Beam,
	beamCyan: Beam,
	light: PointLight,
	hum: Sound?,
}

local rig: Rig? = nil

local function attachmentAt(part: BasePart, name: string, offset: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.Position = offset
	a.Parent = part
	return a
end

local function buildRig(tip: BasePart): Rig
	local idle = Vfx.get("Idle")

	local head = attachmentAt(tip, "FieldHead", Vector3.zero)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "MagnetField"
	emitter.Texture = Vfx.TEXTURE.FIELD
	-- red at birth, cyan at death: the two pole colours, in one emitter rather than two
	emitter.Color = ColorSequence.new(Vfx.RED, Vfx.CYAN)
	emitter.LightEmission = 0.85
	emitter.LightInfluence = 0
	emitter.Rate = idle.rate
	-- ⚠️ We write Rate every frame, so the quality controller's one-shot particle pass must
	-- not also write it -- it loses the race and its scaling silently does nothing. This marks
	-- the emitter as self-driven; the tier scale is applied below instead.
	emitter:SetAttribute("SelfDriven", true)
	emitter.Speed = NumberRange.new(idle.speed)
	emitter.Size = NumberSequence.new(idle.size)
	emitter.Lifetime = NumberRange.new(idle.lifetime)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = head

	-- one beam PAIR: the red pole and the cyan pole arcing to the field head
	local function pole(name: string, offset: Vector3, colour: Color3): Beam
		local from = attachmentAt(tip, name .. "Root", offset)
		local b = Instance.new("Beam")
		b.Name = name
		b.Attachment0 = from
		b.Attachment1 = head
		b.Color = ColorSequence.new(colour)
		b.Texture = Vfx.TEXTURE.BEAM
		b.TextureSpeed = 3
		b.LightEmission = 1
		b.FaceCamera = true
		b.Width0 = idle.beamWidth
		b.Width1 = idle.beamWidth
		b.Transparency = NumberSequence.new(idle.beamTransparency)
		b.Parent = tip
		return b
	end

	local light = Instance.new("PointLight")
	light.Name = "MagnetGlow"
	light.Color = Vfx.CYAN
	light.Range = idle.lightRange
	light.Brightness = idle.lightBrightness
	-- one of the few HERO lights allowed to cast (vfx-lighting: <= 8 at once). It is also
	-- marked Hero so the quality controller's range clamp leaves it alone.
	light.Shadows = true
	light:SetAttribute("Hero", true)
	light.Parent = tip

	return {
		emitter = emitter,
		beamRed = pole("PoleArcRed", Vector3.new(-0.55, 0.8, 0), Vfx.RED),
		beamCyan = pole("PoleArcCyan", Vector3.new(0.55, 0.8, 0), Vfx.CYAN),
		light = light,
		hum = SoundKit.build(SoundKit.MAGNET.Hum, tip, "Hum"),
	}
end

--------------------------------------------------------------------------------
-- State.
--------------------------------------------------------------------------------

--- Below this, a blended value is snapped to its target so `render` can stop writing entirely.
local CONVERGED = 1e-3

--- The particle scale last written, so a tier change re-dirties the render loop.
local lastScale = -1

local currentName: Vfx.StateName = "Idle"
local blend = { rate = 0, speed = 0, size = 0, lifetime = 0, beamWidth = 0, beamTransparency = 0, lightRange = 0, lightBrightness = 0 }

for k in pairs(blend) do
	blend[k] = (Vfx.get("Idle") :: any)[k]
end

local function pullingCount(): number
	local folder = workspace:FindFirstChild("Scrap")
	if not folder then
		return 0
	end
	local n = 0
	for _, p in ipairs(folder:GetChildren()) do
		if p:IsA("BasePart") and p:GetAttribute("PullOwner") == player.UserId then
			n += 1
		end
	end
	return n
end

--- ⚠️ Counting pulls is O(pool) — 400 parts and a ceiling of 1200 — so it runs on a slow timer
--- and NOT in the render loop. The render loop only interpolates numbers it was handed.
local pulls = 0
task.spawn(function()
	while true do
		task.wait(0.15)
		pulls = pullingCount()
	end
end)

--- ⚠️ Reused, not rebuilt. `Vfx.classify` takes a table and this is called once per frame;
--- a fresh literal here is a hash allocation every frame, forever, for four fields that are
--- overwritten immediately.
local classifyArgs = { overcharge = false, rush = false, flowTier = 0, pulling = 0 }

local function stateNow(): Vfx.StateName
	classifyArgs.overcharge = inOvercharge
	classifyArgs.rush = inRush
	classifyArgs.flowTier = flowTier
	classifyArgs.pulling = pulls
	return Vfx.classify(classifyArgs)
end

local function render(dt: number)
	local r = rig
	if not r or not r.emitter.Parent then
		return
	end
	local want = stateNow()
	if want ~= currentName then
		currentName = want
		Log.debug("magnet state -> %s (flow %d, rush %s, pulls %d)", want, flowTier, tostring(inRush), pulls)
	end
	local target = Vfx.get(want)

	-- exponential approach, framerate-independent. Snapping between rates reads as a bug; a
	-- Rush has to ARRIVE rather than cut.
	local a = 1 - math.exp(-dt / math.max(1e-3, Vfx.BLEND_SECONDS))
	local moved = false
	for key, value in pairs(blend) do
		local goal = (target :: any)[key]
		local next = value + (goal - value) * a
		if math.abs(next - goal) < CONVERGED then
			next = goal -- land exactly, so the loop below can stop for good
		end
		if next ~= value then
			blend[key] = next
			moved = true
		end
	end

	-- ⚠️ NOTHING BELOW RUNS WHEN THE BLEND HAS CONVERGED. This is the effect the whole
	-- design calls "the one that must be cheapest": it runs every frame, on every client, for
	-- the whole session, and Idle is 95% of that. Without this guard a player standing still
	-- paid six heap allocations and eight property writes per frame -- NumberRange and
	-- NumberSequence are immutable datatypes, so every assignment allocates -- roughly 1.3
	-- million allocations an hour to re-set values that had stopped changing.
	--
	-- ⚠️ ...but the QUALITY TIER is an input too, and it changes without moving the blend.
	-- The first version of this guard checked `moved` alone, so switching to Low while the
	-- magnet sat converged left the old rate in place forever: measured 199.8 where the tier
	-- called for 100.0. A cheap loop that ignores one of its inputs is just a wrong loop.
	local scale = Quality.get(Quality.tierOf(player)).particleRateScale
	if not moved and scale == lastScale then
		return
	end
	lastScale = scale

	r.emitter.Rate = blend.rate * scale
	r.emitter.Speed = NumberRange.new(blend.speed)
	r.emitter.Size = NumberSequence.new(blend.size)
	r.emitter.Lifetime = NumberRange.new(blend.lifetime)
	r.beamRed.Width0, r.beamRed.Width1 = blend.beamWidth, blend.beamWidth
	r.beamCyan.Width0, r.beamCyan.Width1 = blend.beamWidth, blend.beamWidth
	-- both beams share one value, so build the sequence once rather than twice
	local beamAlpha = NumberSequence.new(blend.beamTransparency)
	r.beamRed.Transparency = beamAlpha
	r.beamCyan.Transparency = beamAlpha
	r.light.Range = blend.lightRange
	r.light.Brightness = blend.lightBrightness
end

--------------------------------------------------------------------------------
-- Voices. One sound per collection, pitched by Flow -- the rising pitch IS the Flow feedback.
--------------------------------------------------------------------------------

--- ⚠️ Pooled, not created per collection. A Rush collects hundreds of objects a second, and
--- `Instance.new("Sound")` per pickup would allocate hundreds of instances a second on a
--- phone. Each family gets a small ring of voices so overlapping hits do not cut each other.
local VOICES_PER_FAMILY = 4
local voices: { [string]: { Sound } } = {}
local nextVoice: { [string]: number } = {}

local function magnetTip(): BasePart?
	local r = rig
	return r and r.emitter.Parent and (r.emitter.Parent :: Attachment).Parent :: BasePart? or nil
end

--- One-shot magnet sounds (Rush, Full, React, Refuse). Built on demand against the current
--- tip, and silent while the slot is empty -- `SoundKit.build` returns nil, so there is no
--- muted `Sound` sitting in the Explorer pretending to be wired.
local oneShots: { [string]: Sound } = {}

playMagnet = function(slot: any)
	if not slot or slot.id == "" then
		return
	end
	local host = magnetTip()
	if not host then
		return
	end
	local existing = oneShots[slot.id]
	if not existing or existing.Parent ~= host then
		existing = SoundKit.build(slot, host, "OneShot")
		if not existing then
			return
		end
		oneShots[slot.id] = existing
	end
	existing:Play()
end

--- ⚠️ Voices are parented to the MAGNET TIP, not to a Folder. A `Sound` under a Folder is
--- 2D: it plays at full volume in every listener's ears and ignores `RollOffMode` and
--- `RollOffMaxDistance` entirely -- so the code reads as spatial while being global. Parented
--- to the tip they play where the collection actually happens, which is also where the object
--- arrives, so this is both cheaper and more correct than positioning them per pickup.
local function voiceFor(family: string): Sound?
	local host = magnetTip()
	if not host then
		return nil -- no magnet yet: nothing to attach a voice to
	end
	local ring = voices[family]
	if not ring or (ring[1] and ring[1].Parent ~= host) then
		-- the character respawned and took the old tip with it; rebuild on the new one
		ring = {}
		local slot = SoundKit.family(family)
		if not slot or slot.id == "" then
			return nil -- empty slot: silent ON PURPOSE, and reported at startup
		end
		for i = 1, VOICES_PER_FAMILY do
			local s = SoundKit.build(slot, host, ("Voice_%s_%d"):format(family, i))
			if s then
				table.insert(ring, s)
			end
		end
		voices[family] = ring
		nextVoice[family] = 1
	end
	if #ring == 0 then
		return nil
	end
	local i = nextVoice[family]
	nextVoice[family] = (i % #ring) + 1
	return ring[i]
end

local function playCollection(family: string?)
	local slot = SoundKit.family(family)
	if not slot then
		return
	end
	local s = voiceFor(family :: string)
	if not s then
		return
	end
	s.PlaybackSpeed = SoundKit.pitchFor(slot.pitch, flowTier, Magnet.FLOW.PITCH_PER_TIER)
	s.Volume = slot.volume * Vfx.get(currentName).soundVolume
	s:Play()
end

--- The collection moment is authored by the CLIENT, at arrival -- not on the server's grant.
--- A sound that waits for a round trip lands after the object has already vanished, which is
--- exactly the lag the batched claim was designed to hide from the player.
local function watchScrap()
	local folder = workspace:WaitForChild("Scrap", 60)
	if not folder then
		return
	end
	-- ⚠️ Weak keys, and every connection is disconnected on ChildRemoved. StreamingEnabled is
	-- ON and the pool parks 300 studs under the map, so pooled parts are removed and re-added
	-- as NEW client Instances every time they cycle in and out of play. Without this, each
	-- cycle leaked a connection and a strong reference to a destroyed part, without bound.
	-- MagnetController does this correctly 130 lines away; this script did not.
	local seen: { [BasePart]: string } = setmetatable({}, { __mode = "k" }) :: any
	local mine: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any
	local conns: { [Instance]: RBXScriptConnection } = {}

	local function track(part: Instance)
		if not part:IsA("BasePart") or conns[part] then
			return
		end
		conns[part] = part:GetAttributeChangedSignal(ATTR_STATE):Connect(function()
			local state = part:GetAttribute(ATTR_STATE)
			local was = seen[part]
			seen[part] = tostring(state)
			if state == "PULL" then
				-- ⚠️ Remember WHOSE pull this was, now -- `release` clears PullOwner in the same
				-- frame it clears ScrapState, so by the time the collection fires there is no
				-- owner left to check. Without this every client hears every other player's
				-- pickups: the state change replicates to everyone.
				mine[part] = part:GetAttribute("PullOwner") == player.UserId
			elseif state == nil and was == "PULL" then
				if mine[part] then
					playCollection(part:GetAttribute(ATTR_SOUND) :: any)
				end
				mine[part] = nil
			end
		end)
	end

	local function untrack(part: Instance)
		local c = conns[part]
		if c then
			c:Disconnect()
			conns[part] = nil
		end
	end

	for _, c in ipairs(folder:GetChildren()) do
		track(c)
	end
	folder.ChildAdded:Connect(track)
	folder.ChildRemoved:Connect(untrack)
end

--------------------------------------------------------------------------------

local function onCharacter(char: Model)
	local tip: BasePart? = nil
	for _ = 1, 100 do
		local m = char:FindFirstChild("MagnetRig")
		local t = m and m:FindFirstChild("Tip")
		if t and t:IsA("BasePart") then
			tip = t
			break
		end
		task.wait(0.1)
	end
	if not tip then
		Log.warn("no MagnetRig.Tip appeared -- the magnet has no VFX this life")
		return
	end
	rig = buildRig(tip)
	local r = rig
	if r and r.hum then
		r.hum:Play()
	end
	Log.info("magnet feel attached (%d sound slots still empty)", #SoundKit.missing())
end

if player.Character then
	task.spawn(onCharacter, player.Character)
end
player.CharacterAdded:Connect(function(c)
	task.spawn(onCharacter, c)
end)

task.spawn(watchScrap)
RunService.RenderStepped:Connect(render)
