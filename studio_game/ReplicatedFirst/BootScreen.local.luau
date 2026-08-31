--!strict
--[[
	BootScreen — the first thing any player ever sees.

	`docs/systems/boot` §7: the player, a glowing magnet, scrap flying in, and a progress bar driven
	by **real stage completion**. Then the title card, and a CLANG.

	🔴 THIS RUNS BEFORE ALMOST EVERYTHING, AND MAY ASSUME NOTHING.

	`ReplicatedFirst` replicates and runs ahead of `ReplicatedStorage`, so at the top of this file
	there is no `Config`, no `Remotes`, no `Ui`, no character and no Workshop. **Every wait below
	has a timeout and a real failure path**, the way `Bootstrap` does — an untimed `WaitForChild`
	here would hang the loading screen forever behind Roblox's own "may yield indefinitely" line,
	which is the single worst place in the game for that to happen.

	It is also why this file builds its own UI from scratch instead of using `Ui.Components`: the
	component library is in `ReplicatedStorage` and is not guaranteed to be here yet. The handful of
	duplicated colours are **checked against `Ui.Theme` once it arrives** (see `auditPalette`), so
	the duplication cannot drift silently.

	🔴 THE PROGRESS BAR IS NOT A TIMER. Every stage below completes on a condition that can be
	observed. A bar that finishes before the world does puts the player in an empty room, and
	PITFALLS #2 is exactly this shape: a thing that reports success while measuring nothing.

	Sources: docs/systems/boot/README.md · docs/build/06-boot-and-hud.md · PITFALLS #2, #54
]]

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

--- ⚠️ FIRST STATEMENT, deliberately. Roblox's default screen stays up until this is called, and
--- anything above it is time the player spends looking at someone else's loading screen.
ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- Palette. Duplicated ON PURPOSE, and checked later.
--------------------------------------------------------------------------------

--- ⚠️ These four are copied from `Ui.Theme` because `Ui` may not have replicated yet. That is a
--- real duplication and it is the kind that rots, so `auditPalette` compares them against the real
--- Theme the moment it arrives and warns if they have drifted apart.
local PALETTE = {
	background = Color3.fromHex("0E1526"), -- Theme.color.factoryDark
	magnet = Color3.fromHex("41D8FF"), -- Theme.color.magnet
	alarm = Color3.fromHex("E03A2F"), -- Theme.color.alarm
	text = Color3.fromHex("F2F6FA"), -- Theme.color.text
	dim = Color3.fromHex("9AA7B8"), -- Theme.color.textDim
	--- ⚠️ Not from Theme -- there is no equivalent token. `auditPalette` skips any entry Theme does
	--- not define, so this is covered by being here without inventing a false comparison.
	barTrack = Color3.fromHex("2A3346"),
}

local DISPLAY_FONT = Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Regular)
local DATA_FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)

--------------------------------------------------------------------------------
-- The screen.
--------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "BootScreen"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
--- ⚠️ `None`, not `CoreUISafeInsets`. This is full-bleed art that must cover the notch and the
--- top bar; it is the one screen in the game where `None` is right (the `mobile` skill reserves it
--- for exactly this). Nothing on it is interactive.
gui.ScreenInsets = Enum.ScreenInsets.None
gui.DisplayOrder = 1000 -- above everything, including anything a later job adds
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = PALETTE.background
backdrop.BorderSizePixel = 0
--- 🔴 SINKS INPUT. The character spawns while this screen is up -- that is what the PLACE stage
--- waits for -- so without this the player has a live, invisible character for the whole load. A
--- thumb dragged across the loading screen worked the thumbstick underneath it and they could walk
--- off a ledge blind.
backdrop.Active = true
backdrop.Parent = gui

--- The four objects that fly into the magnet. §7 names them exactly: a bolt, a gear, a coin, then
--- the magnet itself. One per stage, so the row IS the progress bar rather than decorating one.
local ICONS = { "🔩", "⚙️", "🪙", "🧲" }

local row = Instance.new("Frame")
row.Name = "Objects"
row.BackgroundTransparency = 1
row.AnchorPoint = Vector2.new(0.5, 0.5)
row.Position = UDim2.fromScale(0.5, 0.47)
row.Size = UDim2.fromScale(0.62, 0.11)
row.Parent = gui

local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
--- ⚠️ Set explicitly. `SortOrder` defaults to `Name`, and a row of glyph-named children would
--- render in an order nobody chose -- the same default that inverted a steering control on another
--- game in this workspace.
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
--- Padding in SCALE-adjacent terms: on a narrow canvas a fixed 18 px gap plus four icons
--- overflowed the row, which has no `ClipsDescendants`, and ran off the screen.
rowLayout.Padding = UDim.new(0, 10)
rowLayout.Parent = row

local iconLabels: { TextLabel } = {}
for i, glyph in ipairs(ICONS) do
	local l = Instance.new("TextLabel")
	l.Name = "Icon" .. i
	l.LayoutOrder = i
	l.BackgroundTransparency = 1
	--- ⚠️ Sized in SCALE, not the 64 px it used to be. This screen uses `ScreenInsets.None`, so its
	--- canvas is the full viewport -- 666 x 374 on this repo's measured phone preset. A fixed 64 px
	--- row was 17 % of that height and overlapped the tagline by about 6 px on a phone while
	--- looking correct on a 1080p desktop. That is exactly the "sized against a desktop viewport"
	--- failure the mobile rules exist for.
	l.Size = UDim2.fromScale(0.16, 0.9)
	l.Text = glyph
	--- 🔴 EXPLICIT FONT. Left to the default face, the coin 🪙 rendered as **tofu** -- an empty box
	--- -- while the bolt, gear and magnet all drew fine, so the row silently showed three objects
	--- instead of four. The HUD uses BuilderSans and draws the same glyph correctly, so matching it
	--- is both the fix and the reason there is one icon vocabulary rather than two.
	l.FontFace = DATA_FONT
	l.TextScaled = true
	--- Dim until its stage lands. ⚠️ 0.62, not 0.82: at the deeper value the pale coin glyph
	--- disappeared completely against the backdrop while the darker bolt and gear still read, so
	--- the row looked like it had three objects in it, not four.
	l.TextTransparency = 0.62
	l.Parent = row
	table.insert(iconLabels, l)

	local scale = Instance.new("UIScale")
	scale.Scale = 0.8
	scale.Parent = l
end

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.24)
title.Size = UDim2.fromScale(0.8, 0.11)
title.Text = "MAGNET SWEEP"
title.FontFace = DISPLAY_FONT
title.TextColor3 = PALETTE.text
title.TextScaled = true
title.Parent = gui

local tagline = Instance.new("TextLabel")
tagline.Name = "Tagline"
tagline.BackgroundTransparency = 1
tagline.AnchorPoint = Vector2.new(0.5, 0.5)
tagline.Position = UDim2.fromScale(0.5, 0.335)
tagline.Size = UDim2.fromScale(0.8, 0.045)
tagline.Text = "Find it. Pull it. Bolt it on."
tagline.FontFace = DATA_FONT
tagline.TextColor3 = PALETTE.dim
tagline.TextScaled = true
tagline.Parent = gui

local barBack = Instance.new("Frame")
barBack.Name = "Bar"
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.62)
barBack.Size = UDim2.fromScale(0.44, 0.022)
--- ⚠️ Light enough to SEE when empty. At the hazard-black this started as, an unfilled bar was
--- indistinguishable from the backdrop -- so for the first second of the game the only progress
--- indicator was invisible, which is the same as not having one.
---
--- In `PALETTE` so `auditPalette` covers it. It was inlined here at first, which made it the one
--- colour in the file that was INVENTED rather than copied -- and therefore the only one nothing
--- checked, in a file whose header says the duplicated colours are all checked.
barBack.BackgroundColor3 = PALETTE.barTrack
barBack.BorderSizePixel = 0
barBack.Parent = gui
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBack

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = PALETTE.magnet
barFill.BorderSizePixel = 0
barFill.Parent = barBack
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = barFill

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.BackgroundTransparency = 1
statusLabel.AnchorPoint = Vector2.new(0.5, 0.5)
statusLabel.Position = UDim2.fromScale(0.5, 0.68)
statusLabel.Size = UDim2.fromScale(0.7, 0.04)
statusLabel.Text = ""
statusLabel.FontFace = DATA_FONT
statusLabel.TextColor3 = PALETTE.dim
statusLabel.TextScaled = true
statusLabel.Parent = gui

--------------------------------------------------------------------------------
-- Sound. Reused, not invented.
--------------------------------------------------------------------------------

--- The per-object *tik* and the completion **CLANG** are the game's OWN bolt and barrel sounds.
--- That is not a placeholder standing in for something better: §7 shows scrap flying into a
--- magnet, and these are the sounds that scrap makes. `SoundKit` is the single source for both.
---
--- ⚠️ Loaded lazily and never waited on. If `ReplicatedStorage` has not caught up, the screen is
--- silent for a moment rather than held up — a loading screen must never block on its own audio.
local sounds: { tik: Sound?, clang: Sound? } = { tik = nil, clang = nil }
--- ⚠️ Tried ONCE, not "until it works". The retry used to be gated on `sounds.tik` being nil and
--- rebuilt BOTH slots each time -- and `SoundKit.build` returns nil for an empty slot, which every
--- slot is by policy until a human fills it. One empty `FAMILY.Bolt` would have leaked ten
--- `BootClang` instances a second into `SoundService`, none of which anything destroys.
local soundsTried = false

local function loadSounds()
	if soundsTried then
		return
	end
	local rs = ReplicatedStorage:FindFirstChild("SoundKit")
	if not rs then
		return -- not replicated yet; try again next poll
	end
	soundsTried = true
	--- ⚠️ The whole body is guarded, not just the `require`. The field reads and the `build` calls
	--- can throw too, and this runs on the MAIN thread inside the stage loop -- a throw here used to
	--- kill `runStages` and leave an opaque full-screen GUI up permanently.
	local ok, err = pcall(function()
		local SoundKit = require(rs) :: any
		sounds.tik = SoundKit.build(SoundKit.FAMILY.Bolt, SoundService, "BootTik")
		sounds.clang = SoundKit.build(SoundKit.FAMILY.Barrel, SoundService, "BootClang")
	end)
	if not ok then
		warn("[C][Boot] could not load boot sounds: " .. tostring(err))
	end
end

local function play(s: Sound?)
	if s then
		s:Play()
	end
end

--------------------------------------------------------------------------------
-- Stages. Each completes on an OBSERVABLE condition.
--------------------------------------------------------------------------------

export type Stage = {
	name: string,
	--- Returns true once this stage is genuinely finished. Polled; must not yield.
	done: () -> boolean,
	--- Shown while waiting.
	waiting: string,
	--- Seconds after which the player is told it is taking a while. **The stage keeps waiting** --
	--- see the note on `runStages`.
	slowAfter: number,
	--- What to say once it is slow. §"Failure paths": say it, do not proceed.
	slow: string,
}

--- Set true by the first `StatsChanged`, which is this game's "the profile arrived" signal until
--- real persistence lands in group 11.
local statsArrived = false

local STAGES: { Stage } = {
	{
		name = "HOLD",
		waiting = "STARTING UP",
		slowAfter = 5,
		slow = "STILL STARTING UP",
		--- 🔴 It used to be `return true`. A quarter of the bar therefore measured NOTHING and
		--- snapped full at t = 0 -- PITFALLS #2, in the file whose own header cites #2.
		---
		--- The real condition this stage names is "the screen the player is looking at has actually
		--- been drawn", which is observable: the backdrop has a non-zero rendered size only once a
		--- frame has been laid out.
		done = function()
			return backdrop.AbsoluteSize.X > 1 and backdrop.AbsoluteSize.Y > 1
		end,
	},
	{
		name = "LOAD",
		waiting = "LOADING THE FACTORY",
		slowAfter = 12,
		slow = "THE FACTORY IS TAKING A WHILE",
		--- ⚠️ `game:IsLoaded()` AND the shared folders. Either alone is a partial answer:
		--- `IsLoaded` can be true before our own content has replicated, and the folders can exist
		--- while the engine is still streaming.
		--- 🔴 `StatsChanged`, not `Remotes`.
		---
		--- `ReplicatedStorage:FindFirstChild("Remotes")` resolves to the **ModuleScript**
		--- `Remotes.luau`, which is an initial-replication instance and exists whether or not the
		--- server ever ran. So this conjunct was always true, and when `Bootstrap` deliberately
		--- errors on a fatal config problem -- which it is designed to do in Studio -- LOAD still
		--- passed and the boot held at PROFILE reporting "COULD NOT READ YOUR PROFILE". The message
		--- named the wrong subsystem at the worst possible moment.
		---
		--- A remote INSTANCE existing is proof the server got as far as `Remotes.createAll`.
		done = function()
			if not game:IsLoaded() then
				return false
			end
			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			return remotes ~= nil
				and remotes:FindFirstChild("StatsChanged") ~= nil
				and ReplicatedStorage:FindFirstChild("Config") ~= nil
				and ReplicatedStorage:FindFirstChild("Ui") ~= nil
		end,
	},
	{
		name = "PROFILE",
		waiting = "READING YOUR MAGNET",
		slowAfter = 15,
		--- §"Failure paths": a profile that will not load is SHOWN and not proceeded past. There is
		--- no persistence until group 11, so today this can only fail if the server never pushed --
		--- but the branch is real now so the later job does not have to add one under pressure.
		slow = "THE SERVER HAS NOT SENT YOUR MAGNET YET — HOLDING",
		done = function()
			return statsArrived
		end,
	},
	{
		name = "PLACE",
		waiting = "ENTERING THE WORKSHOP",
		slowAfter = 20,
		--- §"Failure paths": hold at this stage rather than dropping the player into a void.
		slow = "WAITING FOR THE WORLD TO STREAM IN",
		--- 🔴 The real test of "is the world here": the character exists, the Workshop exists, and
		--- **there is ground under the player's feet**. The last one is the one that matters --
		--- `workspace.Workshop` appearing means the folder replicated, not that the floor beneath
		--- this particular player has streamed. Dropping someone through an unstreamed floor is
		--- precisely what "never spawn into a void" means.
		done = function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then
				return false
			end
			if not workspace:FindFirstChild("Workshop") then
				return false
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			-- the character is known non-nil here: `root` was found inside it
			params.FilterDescendantsInstances = { char :: any }
			--- 🔴 `RespectCanCollide`, or this check is a lie.
			---
			--- It defaults to FALSE, so the ray hits non-collidable parts -- and scrap is
			--- explicitly `CanCollide = false` and sits in a pool under the player, as is much of
			--- the Workshop's dressing. A hit off a floating bolt satisfied "there is ground under
			--- the player's feet", which is the one claim this whole stage exists to make.
			params.RespectCanCollide = true
			return workspace:Raycast(root.Position, Vector3.new(0, -40, 0), params) ~= nil
		end,
	},
}

--------------------------------------------------------------------------------

local function landIcon(i: number)
	local l = iconLabels[i]
	if not l then
		return
	end
	local scale = l:FindFirstChildOfClass("UIScale")
	l.TextTransparency = 0
	if scale then
		scale.Scale = 1.35
		TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	play(sounds.tik)
end

local function setProgress(done: number, total: number)
	TweenService:Create(barFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(math.clamp(done / total, 0, 1), 1),
	}):Play()
end

--- Forward-declared so the stage loop below can call it. Declaring it after the definition would
--- shadow the function rather than reference it.
local auditPalette: () -> ()

--- ⚠️ Compares the duplicated boot palette against the real `Ui.Theme` once it exists.
---
--- 🔴 Called from the STAGE LOOP, not once a frame into the script. It used to run exactly once,
--- one frame after `ReplicatedFirst` started, guarded by a non-yielding `FindFirstChild("Ui")` --
--- at which point `ReplicatedStorage` has typically not replicated. It returned silently and was
--- never retried, so the drift guard the header cites as the reason the duplication is safe never
--- actually executed.
local audited = false
function auditPalette()
	if audited then
		return
	end
	local ui = ReplicatedStorage:FindFirstChild("Ui")
	local themeScript = ui and ui:FindFirstChild("Theme")
	if not themeScript then
		return -- not replicated yet; the stage loop calls this again
	end
	audited = true
	local ok, Theme = pcall(require, themeScript)
	if not ok then
		return
	end
	local expect = {
		background = (Theme :: any).color.factoryDark,
		magnet = (Theme :: any).color.magnet,
		alarm = (Theme :: any).color.alarm,
		text = (Theme :: any).color.text,
		dim = (Theme :: any).color.textDim,
	}
	for name, mine in pairs(PALETTE) do
		local theirs = expect[name]
		if theirs and (mine :: Color3) ~= theirs then
			warn(("[C][Boot] palette drift: BootScreen.%s is #%s but Ui.Theme says #%s -- the boot screen cannot require Theme, so the copy has to be corrected by hand")
				:format(name, (mine :: Color3):ToHex(), theirs:ToHex()))
		end
	end
end

local function release()
	--- ⚠️ Let the fill and the last icon's pop FINISH before fading. The out-tweens used to start on
	--- the same frame as a 0.25 s size tween and a 0.22 s pop, so the bar faded while still filling
	--- and never visibly read 100 % -- the CLANG landed on nothing.
	barFill.Size = UDim2.fromScale(1, 1)
	play(sounds.clang)
	task.wait(0.35)
	statusLabel.Text = ""
	local out = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for _, obj in ipairs({ title, tagline, statusLabel }) do
		TweenService:Create(obj, out, { TextTransparency = 1 }):Play()
	end
	for _, l in ipairs(iconLabels) do
		TweenService:Create(l, out, { TextTransparency = 1 }):Play()
	end
	TweenService:Create(backdrop, out, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(barBack, out, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(barFill, out, { BackgroundTransparency = 1 }):Play()
	task.delay(0.55, function()
		gui:Destroy()
	end)
end

local function runStages()
	local total = #STAGES
	--- ⚠️ The row IS the progress bar, so a stage with no icon lands silently -- no pop, no tik, and
	--- a bar that moves for no visible reason. This repo asserts exactly this shape between
	--- `MagnetState.TRACKS` and `LEVEL_KEYS`; the same reasoning applies here.
	if #ICONS ~= total then
		warn(("[C][Boot] %d icons for %d stages -- every stage needs one, the row IS the bar")
			:format(#ICONS, total))
	end
	setProgress(0, total)

	for i, stage in ipairs(STAGES) do
		statusLabel.Text = stage.waiting
		statusLabel.TextColor3 = PALETTE.dim

		local started = os.clock()
		local told = false
		--- 🔴 NO TIMEOUT THAT GIVES UP. `docs/systems/boot` is explicit: on a slow stage, **hold**
		--- and say so. Proceeding on a timer is what produces a player standing in an empty room,
		--- and it is the same failure as a progress bar that finishes early -- reporting success
		--- while measuring nothing.
		while not stage.done() do
			if not told and os.clock() - started > stage.slowAfter then
				told = true
				statusLabel.Text = stage.slow
				statusLabel.TextColor3 = PALETTE.alarm
				warn(("[C][Boot] stage %q still waiting after %.0fs"):format(stage.name, stage.slowAfter))
			end
			task.wait(0.1)
			-- opportunistic: these arrive part-way through and nothing should wait on them
			loadSounds()
			auditPalette()
		end

		landIcon(i)
		setProgress(i, total)
		print(("[C][Boot] stage %q complete after %.2fs"):format(stage.name, os.clock() - started))
	end
end

--------------------------------------------------------------------------------

--- The profile signal. Connected as early as the remote allows, and never waited on by the main
--- flow -- the PROFILE stage polls the flag instead, so a slow remote shows a message rather than
--- blocking on a `WaitForChild` nobody can see.
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
	local stats = remotes and remotes:WaitForChild("StatsChanged", 30)
	if not stats or not stats:IsA("RemoteEvent") then
		warn("[C][Boot] StatsChanged never appeared -- the PROFILE stage will hold and say so")
		return
	end
	stats.OnClientEvent:Connect(function()
		statsArrived = true
	end)
end)

task.spawn(function()
	-- give the first frame to the screen itself before doing anything else
	RunService.RenderStepped:Wait()
	auditPalette()
end)

--- 🔴 GUARDED, AND WITH A WATCHDOG.
---
--- `runStages` used to be called bare. Roblox's own loading screen is already gone by this point,
--- so ANY throw in the boot path left the player behind an opaque full-screen frame at
--- `DisplayOrder = 1000`, permanently, with no way out but the Roblox menu. It is the one place in
--- the game where an unhandled error is unrecoverable, and it was the one place with no guard.
---
--- The watchdog is the belt to that braces: if the stage loop is still running after this long,
--- something is wrong that holding will not fix, and a playable game with a missing loading screen
--- beats an unplayable one with a perfect one.
--- 🔴 SAYS WHAT IS MISSING, every startup, by name.
---
--- `docs/build/06-boot-and-hud.md` lists as **P0**: "Loading screen art: player, magnet, flying
--- scrap, robot, corridor". What exists is a flat backdrop, four emoji and two lines of text. Under
--- ground rule 10 an empty slot must ANNOUNCE ITSELF -- `SoundKit.missing()` prints its empty slots
--- by name at every startup for exactly this reason, and without an equivalent here four emoji read
--- as the finished screen rather than as a placeholder-shaped hole.
warn("[C][Boot] ART MISSING: the loading screen has no art yet (P0: player, magnet, flying scrap, robot, corridor). What is on screen is a title card and four glyphs.")

local bootStarted = os.clock()
local finished = false

task.spawn(function()
	local WATCHDOG = 90
	while not finished and os.clock() - bootStarted < WATCHDOG do
		task.wait(0.5)
	end
	if not finished then
		warn(("[C][Boot] watchdog fired after %ds -- releasing the screen so the player is not trapped"):format(WATCHDOG))
		finished = true
		release()
	end
end)

--- ⚠️ Sounds are loaded BEFORE the first stage, not inside the loop. HOLD used to complete on its
--- first evaluation, so the loop body never ran, so `loadSounds` had never been called and the very
--- first *tik* was silent on every single boot.
loadSounds()

local ok, err = pcall(function()
	runStages()
end)
if not ok then
	warn("[C][Boot] stage loop failed: " .. tostring(err))
	statusLabel.Text = "SOMETHING WENT WRONG STARTING UP"
	statusLabel.TextColor3 = PALETTE.alarm
	task.wait(2)
end
if not finished then
	finished = true
	print(("[C][Boot] ready in %.2fs"):format(os.clock() - bootStarted))
	release()
end
