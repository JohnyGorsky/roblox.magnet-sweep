--!strict
--[[
	QualityController — picks a quality tier from MEASURED frame time and applies it.

	Decision 0012: mobile sets the budget and the glossy look ships as a tier on top of a
	phone floor. Decision 0016: the Low tier DROPS the MaterialVariant entirely -- it does
	not "fall back to Reflectance", which is inert on Metal, the base material of five of the
	nine kit surfaces.

	The tier is chosen from a measured frame time, NEVER from `TouchEnabled` alone: a tablet
	is not a low-end phone and a cheap laptop is not a high-end PC. `TouchEnabled` is used
	only as a tie-breaker hint, never as the decision.

	⚠️ `.local.luau` -> LocalScript ON PURPOSE. A `.client.luau` in StarterPlayerScripts RUNS
	TWICE (measured, job 002), which here would mean two competing tier controllers.

	What this can and cannot change, measured in job 002/004:
	  * CAN:    post-processing effects, decorative PointLight range, particle rates,
	            MaterialVariant on/off, the pull cap.
	  * CANNOT: LightingStyle / Lighting.Technology / PrioritizeLightingQuality. All are
	            RobloxScriptSecurity on WRITE; Technology cannot even be READ. They are
	            place settings a human sets in Studio.

	Sources: Config/Quality · Config/Perf · decisions 0012, 0016
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local Quality = require(Config:WaitForChild("Quality", 20))
local MaterialKit = require(ReplicatedStorage:WaitForChild("MaterialKit", 20))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Quality")

local player = Players.LocalPlayer

local current: Quality.TierName? = nil
local overridden = false -- a dev pin; auto-evaluation must not undo it
local postState = "unchecked"
local drift = 0 -- parts the server re-stamped since the last tier change

--------------------------------------------------------------------------------
-- Applying a tier.
--------------------------------------------------------------------------------

local function applyPostChain(tier: Quality.Tier)
	for _, fx in ipairs(Lighting:GetChildren()) do
		if fx:IsA("BloomEffect") then
			fx.Enabled = tier.postBloom
		elseif fx:IsA("ColorCorrectionEffect") then
			fx.Enabled = tier.postColorCorrection
		elseif fx:IsA("SunRaysEffect") then
			fx.Enabled = tier.postSunRays
		elseif fx:IsA("DepthOfFieldEffect") then
			-- ⚠️ `tier.depthOfField`, not the literal `false` that used to be here. The field
			-- is `true` on High and the code wrote `false` regardless -- configured, and then
			-- enforced to the opposite value, which is worse than not enforced at all.
			fx.Enabled = tier.depthOfField
		end
	end
end

--- ⚠️ The post chain lives ONLY in the .rbxl. Nothing in git can recreate it, and an empty
--- `Lighting` produces byte-identical output to a healthy one: the loop above simply matches
--- nothing. MaterialKit.audit is fatal for the equivalent material failure; this is the
--- lighting half, and it reports what it actually found rather than that it ran.
local function auditPostChain(): string
	local want = { BloomEffect = false, ColorCorrectionEffect = false, SunRaysEffect = false }
	local found = {}
	for _, fx in ipairs(Lighting:GetChildren()) do
		if want[fx.ClassName] ~= nil then
			want[fx.ClassName] = true
		end
		table.insert(found, fx.ClassName)
	end
	local missing = {}
	for class, present in pairs(want) do
		if not present then
			table.insert(missing, class)
		end
	end
	table.sort(missing)
	if #missing > 0 then
		Log.error("post chain INCOMPLETE -- missing %s. Lighting holds: %s",
			table.concat(missing, ", "), #found > 0 and table.concat(found, ", ") or "nothing")
	end
	return #missing == 0 and "complete" or ("missing " .. table.concat(missing, ","))
end

--- Weak keys: a destroyed light or emitter must not be pinned in memory by the table that
--- remembers its authored value.
local function weak(): any
	return setmetatable({}, { __mode = "k" })
end

local baseRange: { [Instance]: number } = weak()

--- A decorative light's range is CLAMPED to the tier's ceiling. Lights marked `Hero` are
--- exempt -- the Arena Core, the player's magnet, a Service Hub gate.
---
--- ⚠️ Clamp, do not disable. Two reasons, and the first is why this function did nothing
--- at all before:
---
---  1. It used to switch a light off when `Range > threshold`. The largest light in the
---     shipped kit is 18 studs (KitSpec ranges are 4, 5, 12, 14, 16; KitBuilder defaults 18)
---     and the LOWEST threshold was 40 -- so `keep` was true for every light in the game at
---     every tier, forever, and the function reported `lights toggled=0` on a healthy run and
---     on a broken one alike. Two files chose numbers that never met.
---  2. Writing `Enabled` makes this the sole owner of a property other systems need. The
---     Salvage Breach enables and disables its beacons in a batch (Prop_Beacon, range 16);
---     a tier re-evaluation would have relit every beacon in the world with no breach running,
---     and it would have looked like a Breach bug.
---
--- Cost scales with range, so clamping saves most of it and still leaves the room lit --
--- which matters, because the big lights here are the ones that define a space.
local function applyLights(tier: Quality.Tier): number
	local n = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
			if d:GetAttribute("Hero") ~= true then
				if baseRange[d] == nil then
					baseRange[d] = d.Range -- the authored value, so tiers never compound
				end
				local want = math.min(baseRange[d], tier.decorativeLightRange)
				if math.abs(d.Range - want) > 1e-3 then
					d.Range = want
					n += 1
				end
			end
		end
	end
	return n
end

local baseRate: { [ParticleEmitter]: number } = weak()

local function applyParticles(tier: Quality.Tier): number
	local n = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			if baseRate[d] == nil then
				baseRate[d] = d.Rate
			end
			local want = baseRate[d] * tier.particleRateScale
			if math.abs(d.Rate - want) > 1e-3 then
				d.Rate = want
				n += 1
			end
		end
	end
	return n
end

local function apply(tierName: Quality.TierName)
	local tier = Quality.get(tierName)
	applyPostChain(tier)
	local lights = applyLights(tier)
	local particles = applyParticles(tier)

	-- decision 0016: PBR on or off. NOT a Reflectance swap.
	MaterialKit.setUsePBR(tier.usePBR)
	local refreshed = MaterialKit.refresh(workspace)

	current = tierName
	postState = auditPostChain()

	-- ⚠️ Tell the SERVER. The pull cap is a per-device budget (decision 0012), but the cap is
	-- enforced in ScrapService and this is the only place that knows which device this is --
	-- so without this report the number below is printed and never applied, and every phone
	-- runs the desktop budget. The server clamps what it receives, so this can only ever
	-- lower this player's own cap.
	task.spawn(function()
		local ev = Remotes.getEvent("ReportQuality", 20)
		if ev then
			ev:FireServer(tierName)
		end
	end)

	-- ⚠️ Every number here is a COUNT of what changed, not a restatement of the tier. A line
	-- that says only "tier=Medium" reads identically whether the tier did everything or
	-- nothing -- which is exactly how a light cull that could never fire survived a review.
	Log.info(
		"tier=%s | pbr=%s (%d parts) | lights clamped=%d | emitters=%d | pullCap=%d | post=%s",
		tierName,
		tostring(tier.usePBR),
		refreshed,
		lights,
		particles,
		tier.maxConcurrentPull,
		postState
	)
end

--------------------------------------------------------------------------------
-- Measuring. Frame time, not a guess.
--------------------------------------------------------------------------------

local function measureFrameMs(seconds: number): number
	local d = Quality.DETECT
	local samples, total = 0, 0
	local elapsed = 0
	local warmup = d.WARMUP_SECONDS
	local conn
	local done = false
	conn = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		if elapsed < warmup then
			return
		end
		total += dt * 1000
		samples += 1
		if elapsed >= warmup + seconds then
			done = true
		end
	end)
	while not done do
		RunService.RenderStepped:Wait()
	end
	conn:Disconnect()
	return samples > 0 and (total / samples) or 16.7
end

--------------------------------------------------------------------------------

local function evaluate()
	-- ⚠️ A pinned tier stays pinned. `_G.setQuality` used to be silently reverted by the
	-- next re-check 60s later -- exactly long enough to take one screenshot, change nothing,
	-- and take a second identical one.
	if overridden then
		return
	end
	local ms = measureFrameMs(Quality.DETECT.SAMPLE_SECONDS)
	local want = Quality.classify(ms, current)
	if want ~= current then
		Log.info("frame time %.1fms -> tier %s (was %s)", ms, want, tostring(current))
		apply(want)
	else
		Log.debug("frame time %.1fms, staying on %s", ms, tostring(current))
	end
end

-- ⚠️ THE SERVER KEEPS PUTTING THE VARIANTS BACK. `MaterialVariant` is replicated and
-- server-owned; ScrapService re-stamps it on every spawn with the server's own `usePBR`,
-- which is always true. So the Low tier's strip has to be MAINTAINED, not applied once.
--
-- A poll rather than a signal, deliberately: the parts are POOLED, so they are re-stamped
-- while already parented and `DescendantAdded` never fires for them. Per-part property
-- signals on a 400-part pool cost far more than one sweep a second, and this only ever has
-- work to do on the tier that needs the saving.
task.spawn(function()
	while true do
		task.wait(1)
		local scrap = workspace:FindFirstChild("Scrap")
		if scrap and current then
			local fixed = MaterialKit.enforce(scrap)
			if fixed > 0 then
				drift += fixed
			end
		end
	end
end)

-- Start on the default so the first seconds are not unstyled -- but do NOT record it as the
-- current tier. `Quality.classify` widens the exit threshold of whatever tier you are already
-- in, so setting `current` here meant the very first classification was always a hysteresis
-- case: LOW_IF_MS_ABOVE 26 and HIGH_IF_MS_BELOW 12 were dead constants no client ever used,
-- and the real gates were 29 and 9. A device holding 27.5ms -- worse than the reference
-- device's own budget -- classified Medium and stayed there.
apply(Quality.default())
current = nil
Log.info(
	"touch=%s (a hint only, never the decision) | viewport=%s",
	tostring(UserInputService.TouchEnabled),
	tostring(workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize)
)

task.spawn(function()
	-- ⚠️ Do not measure the loading screen. The first seconds of a session are the least
	-- representative in it: the kit's PBR maps are still decompressing, the world is still
	-- streaming, and the character often does not exist yet -- so the camera is drawing almost
	-- nothing and frames look cheap. Measured there, a phone can classify HIGH and hold a
	-- 160-object pull cap through the whole first minute, which is the first impression.
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	task.wait(Quality.DETECT.SETTLE_SECONDS)
	evaluate()
	while true do
		task.wait(Quality.DETECT.RECHECK_INTERVAL)
		evaluate()
	end
end)

--- `dev("quality.set", "Low")`. The server writes the tier as an attribute on this Player and
--- this applies it -- no new remote to audit, and the dev path is reachable from the console
--- that documents it. "auto" hands control back to the measurement.
---
--- ⚠️ This command was described in this file and registered NOWHERE. The only working
--- path was a `_G` global, which lives in the LocalScript's own Lua context and is therefore
--- invisible to `execute_luau` and to any other script -- a tool nobody can call is not
--- shipped (PITFALLS: name the caller).
local ATTR_TIER = "DevQualityTier"

local function applyOverride()
	local want = player:GetAttribute(ATTR_TIER)
	if want == nil or want == "auto" then
		overridden = false
		Log.info("quality override cleared -- measuring again")
		task.spawn(evaluate)
		return
	end
	if Quality.TIERS[tostring(want)] then
		overridden = true
		apply(tostring(want) :: Quality.TierName)
		Log.info("quality PINNED to %s by a dev command", tostring(want))
	else
		Log.warn("unknown tier %q -- ignored", tostring(want))
	end
end

player:GetAttributeChangedSignal(ATTR_TIER):Connect(applyOverride)
if player:GetAttribute(ATTR_TIER) ~= nil then
	applyOverride()
end

;(_G :: any).setQuality = function(name: string)
	player:SetAttribute(ATTR_TIER, name)
	return true
end
