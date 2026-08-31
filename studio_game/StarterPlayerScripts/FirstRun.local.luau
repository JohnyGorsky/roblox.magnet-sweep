--!strict
--[[
	FirstRun — the only line of tutorial this game has.

	`docs/systems/boot` §9 is explicit that there is **no tutorial**. The teaching is environmental:
	scrap starts shaking as you approach, it flies in, Flow climbs, the magnet fills, and an arrow
	points at the Recycler. Nobody reads anything.

	The single exception is one prompt for a player who has not worked out that they should walk
	towards the shaking: **MOVE NEAR SCRAP**. Its whole job is to disappear the instant they sweep.

	⚠️ `.local.luau` -> LocalScript ON PURPOSE. A `.client.luau` in StarterPlayerScripts RUNS TWICE
	(job 002, reproduced in Play).

	🔴 THE FLAG IS THE SERVER'S. `HasSwept` is set in `MagnetState.collect`, which is the one place
	a collection happens. This script only READS it. Owning it here would mean the client deciding
	whether the player is new, and it would have to be rebuilt the moment profiles land in group 11
	— the attribute already survives that change untouched.

	Sources: docs/systems/boot/README.md §9 · docs/build/06-boot-and-hud.md
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--- ⚠️ A REAL failure path, not a decorative timeout. `WaitForChild(..., 20)` returns nil on
--- timeout and the nil went straight into `require` -- so the script threw and the hint silently
--- never existed. Same shape as `Bootstrap`'s `need()`, which is the pattern to copy.
local function need(parent: Instance, name: string): Instance
	local inst = parent:WaitForChild(name, 20)
	if not inst then
		error(("FirstRun: %s.%s never appeared -- the MOVE NEAR SCRAP hint will not exist")
			:format(parent:GetFullName(), name), 0)
	end
	return inst
end

local UiFolder = need(ReplicatedStorage, "Ui")
local Theme = require(need(UiFolder, "Theme"))
local Layout = require(need(UiFolder, "Layout"))
local Components = require(need(UiFolder, "Components"))
local Log = require(need(ReplicatedStorage, "Log")).scope("FirstRun")

--- 🔴 THE HINT SAYS "MOVE NEAR SCRAP", SO IT SHOWS WHEN THE PLAYER IS **NOT** NEAR SCRAP.
---
--- The first version showed it when scrap was *within* 26 studs — the exact opposite of its own
--- words. A player standing 60 studs from anything, the one person the prompt exists for, never saw
--- it; a player three studs outside the starter pull radius was told to move nearer. It could only
--- ever appear in a narrow 12–26 stud band for the second before the sweep retired it, which made
--- it close to a no-op.
---
--- Inside `ALREADY_SWEEPING` the magnet is visibly working and the hint is noise. Beyond
--- `REACHABLE` there is nothing to walk to and telling someone to move near scrap is unhelpful.
--- Between the two is the state the sentence describes.
local ALREADY_SWEEPING = 14 -- a little past the starter pull radius of 12
local REACHABLE = 160

--- ⚠️ Waits for the boot screen to be gone. A hint drawn underneath the loading screen is a hint
--- nobody sees, and it would then be dismissed by the first sweep without ever having been read.
--- This is the same mistake shape as measuring the device during the loading screen (PITFALLS #54)
--- and as verifying a tray while it was invisible.
local function waitForBootScreen()
	local deadline = os.clock() + 60
	while playerGui:FindFirstChild("BootScreen") and os.clock() < deadline do
		task.wait(0.2)
	end
end

local gui = Components.screen("FirstRun", playerGui, 15)
gui.Enabled = false

local hint = Components.panel("Hint", gui)
hint.AnchorPoint = Vector2.new(0.5, 0)

local hintText = Components.label("Text", hint, {
	text = "MOVE NEAR SCRAP",
	font = Theme.font.display,
	color = Theme.color.magnet,
	align = Enum.TextXAlignment.Center,
	size = 30,
})

--- ⚠️ Sits BELOW the Flow readout, not on top of it. Flow is at the top centre and only appears
--- once a combo is running -- which is after the player has already started sweeping, i.e. after
--- this hint has gone. They should never be on screen together, and if they are, this one is lower.
Layout.observe(function(canvas: Vector2)
	local pad = math.clamp(canvas.X * 0.02, 8, 18)
	local w = Layout.size(canvas.X, 0.44, 320, 180, 0.7)
	local h = Layout.size(canvas.Y, 0.10, 52, 30, 0.16)
	hint.Size = UDim2.fromOffset(w, h)
	hint.Position = UDim2.new(0.5, 0, 0, pad + Layout.size(canvas.Y, 0.11, 46, 28, 0.16) + pad * 2)
	hintText.Position = UDim2.fromOffset(Theme.shape.pad, 0)
	hintText.Size = UDim2.new(1, -2 * Theme.shape.pad, 1, 0)
end)

local shown = false

local function setShown(on: boolean)
	if on == shown then
		return
	end
	shown = on
	if on then
		gui.Enabled = true
		hint.BackgroundTransparency = 1
		hintText.TextTransparency = 1
		TweenService:Create(hint, Theme.motion.fade, { BackgroundTransparency = Theme.shape.panelTransparency }):Play()
		TweenService:Create(hintText, Theme.motion.fade, { TextTransparency = 0 }):Play()
	else
		TweenService:Create(hint, Theme.motion.fade, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(hintText, Theme.motion.fade, { TextTransparency = 1 }):Play()
		task.delay(0.25, function()
			if not shown then
				gui.Enabled = false
			end
		end)
	end
end

--- Should the hint be up? True when there is scrap the player could walk to and they are not
--- already on top of it.
---
--- ⚠️ `GetPartBoundsInRadius`, not a scan of the whole folder. The pool is 400 parts and can reach
--- 1200, and the first version walked all of them 2.5 times a second for as long as the player had
--- not swept -- which for someone who never sweeps is the entire session. Two existence questions
--- against the engine's own spatial query cost a fraction of that.
---
--- ⚠️ Pooled parts park at y = −300, three hundred studs below the floor, so they fall outside both
--- radii by geometry. The transparency test stays as a second guard rather than the only one.
local function shouldHint(): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local folder = workspace:FindFirstChild("Scrap")
	if not folder then
		return false
	end

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	params.MaxParts = 24

	local function anyLiveWithin(radius: number): boolean
		for _, d in ipairs(workspace:GetPartBoundsInRadius(root.Position, radius, params)) do
			if d.Transparency < 1 then
				return true
			end
		end
		return false
	end

	-- already sweeping: the shaking is doing the teaching and the hint would be noise
	if anyLiveWithin(ALREADY_SWEEPING) then
		return false
	end
	return anyLiveWithin(REACHABLE)
end

--- 🔴 RESTARTABLE.
---
--- The first version was a `while HasSwept ~= true` loop that exited for good on the first sweep.
--- That is right in production -- the flag never goes back -- but it made the hint impossible to
--- observe: `dev("first.reset")` clears the attribute and nothing was left running to notice. A
--- state you cannot restore is a state you cannot verify, and a loop whose only exit is permanent
--- quietly encodes an assumption nobody wrote down.
---
--- Watching the attribute in both directions costs nothing and makes the feature testable.
local function runHintLoop()
	while player:GetAttribute("HasSwept") ~= true do
		setShown(shouldHint())
		task.wait(0.4)
	end
	--- The hint's entire job is to disappear the moment the lesson lands. §9's claim is that the
	--- loop is understood without anyone reading anything; a hint that outlives what it pointed at
	--- becomes furniture.
	setShown(false)
	Log.info("first sweep -- hint retired")
end

task.spawn(function()
	waitForBootScreen()

	local running = false
	local function start()
		if running or player:GetAttribute("HasSwept") == true then
			return
		end
		running = true
		task.spawn(function()
			runHintLoop()
			running = false
		end)
	end

	player:GetAttributeChangedSignal("HasSwept"):Connect(start)
	if player:GetAttribute("HasSwept") == true then
		Log.info("player has swept before -- no first-run hint")
	end
	start()
end)
