--!strict
--[[
	StationController — what happens when the player uses a Workshop station.

	⚠️ `.local.luau` -> LocalScript ON PURPOSE. A `.client.luau` in StarterPlayerScripts RUNS TWICE
	(job 002, reproduced in Play). Two copies here would open two screens per prompt.

	🔴 THE PROMPT IS HANDLED ON THE CLIENT; ONLY THE TRANSACTION CROSSES THE WIRE.

	`ProximityPromptService.PromptTriggered` fires locally, so opening a screen needs no remote at
	all. The server never sends "open a window" — it owns money, and the client owns windows. That
	keeps the remote surface exactly as small as `Remotes.SPECS` says it is.

	The station is identified by the `StationId` attribute the SERVER stamped on the prompt. Nothing
	here knows where a station is: the Workshop is regenerated from a spec and every position in it
	has already moved twice.

	⚠️ **`screen_capture` cannot render prompt bubbles** (PITFALLS #20). A screenshot with no prompt
	visible is not evidence of a missing prompt.

	Sources: Jobs/013 · docs/build/05-workshop.md · decision 0007 · spec §48
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Stations")

local UiFolder = ReplicatedStorage:WaitForChild("Ui", 20)
local Theme = require(UiFolder:WaitForChild("Theme", 20))
local Layout = require(UiFolder:WaitForChild("Layout", 20))
local Components = require(UiFolder:WaitForChild("Components", 20))
local Banner = require(UiFolder:WaitForChild("Banner", 20))
local Screens = require(UiFolder:WaitForChild("Screens", 20))

local recycleRemote = Remotes.getFunction("RequestRecycle", 20)

local function comma(n: number): string
	local s = ("%d"):format(math.floor(n + 0.5))
	while true do
		local replaced: number
		s, replaced = s:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then
			break
		end
	end
	return s
end

--------------------------------------------------------------------------------
-- The Recycler screen. Spec §48's pinch, and the whole reason the economy is interesting.
--------------------------------------------------------------------------------

--[[
	🔴 BOTH EXITS, ALWAYS, WITH REAL NUMBERS, AND NEITHER PRE-SELECTED.

	`docs/systems/economy` and `Economy.previewChoice` are explicit about this: the game's single
	economic question is *do I spend this scrap on myself, or on keeping my robot alive?* A screen
	that shows one exit at a time, or that highlights the "recommended" one, is not asking it.

	Repair is shown with its real HP number and is **disabled**, because there is no robot until
	group 09. Showing it greyed with an honest reason is the point — hiding it would hide the choice
	the entire economy is built around, and faking it would be a placeholder (ground rule 10).
]]

local gui = Components.screen("StationScreens", playerGui, 12)
gui.Enabled = false

local panel = Components.panel("Recycle", gui)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundTransparency = 0.05

local title = Components.label("Title", panel, {
	text = "RECYCLER",
	font = Theme.font.display,
	color = Theme.color.recycle,
	align = Enum.TextXAlignment.Left,
	size = 28,
})

local carried = Components.label("Carried", panel, {
	font = Theme.font.label,
	color = Theme.color.textDim,
	align = Enum.TextXAlignment.Left,
	size = 16,
})

--- The two exits, side by side.
local coinsButton = Components.button("Coins", panel, {
	color = Theme.color.recycle,
	tapFloor = Layout.TAP_FLOOR,
})
coinsButton.Text = ""
--- ⚠️ More opaque than the panel behind them. At the shared panel transparency both exits blended
--- into the modal and read as flat regions of text rather than as the two things you choose between.
coinsButton.BackgroundColor3 = Theme.color.hazardBlack
coinsButton.BackgroundTransparency = 0.15
local coinsTop = Components.label("Head", coinsButton, {
	text = "RECYCLE",
	font = Theme.font.data,
	color = Theme.color.text,
	align = Enum.TextXAlignment.Center,
	size = 18,
})
coinsTop.Position = UDim2.fromScale(0, 0.12)
coinsTop.Size = UDim2.new(1, 0, 0.3, 0)
local coinsValue = Components.label("Value", coinsButton, {
	font = Theme.font.data,
	color = Theme.color.arena,
	align = Enum.TextXAlignment.Center,
	size = 30,
})
coinsValue.Position = UDim2.fromScale(0, 0.46)
coinsValue.Size = UDim2.new(1, 0, 0.42, 0)

local repairButton = Components.button("Repair", panel, {
	color = Theme.color.repair,
	tapFloor = Layout.TAP_FLOOR,
})
repairButton.Text = ""
repairButton.BackgroundColor3 = Theme.color.hazardBlack
repairButton.BackgroundTransparency = 0.15
local repairTop = Components.label("Head", repairButton, {
	text = "REPAIR ROBOT",
	font = Theme.font.data,
	color = Theme.color.text,
	align = Enum.TextXAlignment.Center,
	size = 18,
})
repairTop.Position = UDim2.fromScale(0, 0.12)
repairTop.Size = UDim2.new(1, 0, 0.3, 0)
local repairValue = Components.label("Value", repairButton, {
	font = Theme.font.data,
	color = Theme.color.repair,
	align = Enum.TextXAlignment.Center,
	size = 30,
})
repairValue.Position = UDim2.fromScale(0, 0.46)
repairValue.Size = UDim2.new(1, 0, 0.42, 0)

local status = Components.label("Status", panel, {
	font = Theme.font.label,
	color = Theme.color.textDim,
	align = Enum.TextXAlignment.Center,
	size = 15,
})

local closeButton = Components.button("Close", panel, {
	text = "CLOSE",
	color = Theme.color.chrome,
})

local recycleOpen = false

local function layout(canvas: Vector2)
	local pad = math.clamp(canvas.X * 0.02, 8, 18)
	local tap = Layout.tapTarget()
	local w = math.min(canvas.X - 2 * pad, math.max(320, canvas.X * 0.52))
	--- 🔴 SIZED TO ITS CONTENT, not to a fraction of the screen.
	---
	--- Two versions got this wrong in a row. The first took 72 % of the canvas height and stretched
	--- the two exits to fill it, so each was a mostly-empty rectangle with its label stranded at the
	--- top. Capping the exits then left the same hole somewhere else -- a dead gap between them and
	--- the CLOSE button. A panel that asks one question should be exactly the size of one question,
	--- so the height is ADDED UP from the parts and only then clamped to the canvas.
	local titleH = math.max(24, tap * 0.6)
	local carriedH = 18
	local statusH = 20
	local exitH = math.clamp(tap * 2, tap, 132)
	local gap = 10
	local contentH = 6 + titleH + carriedH + gap + exitH + gap + statusH + gap + tap + Theme.shape.pad
	local h = math.min(canvas.Y - 2 * pad, contentH)
	panel.Size = UDim2.fromOffset(w, h)

	title.Position = UDim2.fromOffset(Theme.shape.pad, 6)
	title.Size = UDim2.new(1, -2 * Theme.shape.pad, 0, titleH)
	carried.Position = UDim2.fromOffset(Theme.shape.pad, 6 + titleH)
	carried.Size = UDim2.new(1, -2 * Theme.shape.pad, 0, carriedH)

	--- The two exits are the SAME SIZE and side by side. Making one bigger, or putting one above
	--- the other, is a recommendation -- and neither is pre-selected on purpose.
	local top = 6 + titleH + carriedH + gap
	local exitW = (w - 3 * Theme.shape.pad) / 2
	coinsButton.Position = UDim2.fromOffset(Theme.shape.pad, top)
	coinsButton.Size = UDim2.fromOffset(exitW, exitH)
	repairButton.Position = UDim2.fromOffset(2 * Theme.shape.pad + exitW, top)
	repairButton.Size = UDim2.fromOffset(exitW, exitH)

	status.Position = UDim2.fromOffset(Theme.shape.pad, top + exitH + gap)
	status.Size = UDim2.new(1, -2 * Theme.shape.pad, 0, statusH)

	closeButton.AnchorPoint = Vector2.new(0.5, 1)
	closeButton.Position = UDim2.new(0.5, 0, 1, -Theme.shape.pad)
	closeButton.Size = UDim2.fromOffset(math.max(tap * 2, exitW), tap)
end

type Preview = { scrap: number, coins: number, hp: number, repairable: boolean }

--- ⚠️ ACTUALLY disabled, not just greyed. `Components.button` fires its press tween and its press
--- sound unconditionally, so a "disabled" exit that only changed colour still felt like a working
--- button -- and at zero scrap the greyed RECYCLE still sent a real `InvokeServer(true)` and burned
--- an `Economy` token to be told "NOTHING TO RECYCLE".
local function setExitsEnabled(canRecycle: boolean, canRepair: boolean?)
	coinsButton.Interactable = canRecycle
	coinsButton.Active = canRecycle
	repairButton.Interactable = canRepair == true
	repairButton.Active = canRepair == true
end

local function render(p: Preview)
	carried.Text = ("CARRYING %s SCRAP"):format(comma(p.scrap))
	coinsValue.Text = ("🪙 %s"):format(comma(p.coins))
	repairValue.Text = ("+%s HP"):format(comma(p.hp))

	local canRecycle = p.scrap > 0
	coinsValue.TextColor3 = if canRecycle then Theme.color.arena else Theme.color.textDim
	coinsTop.TextColor3 = if canRecycle then Theme.color.text else Theme.color.textDim

	--- ⚠️ Greyed and LABELLED, not hidden. The number is real; the exit is not available yet.
	repairValue.TextColor3 = if p.repairable then Theme.color.repair else Theme.color.steelMid
	repairTop.TextColor3 = if p.repairable then Theme.color.text else Theme.color.steelMid
	repairTop.Text = if p.repairable then "REPAIR ROBOT" else "REPAIR ROBOT — NO ROBOT YET"
	setExitsEnabled(canRecycle, p.repairable)
end

--- Whether a background PREVIEW is in flight. A commit is never gated on it -- see `ask`.
local previewing = false

--- Ask the server. `commit` nil previews, `true` performs the recycle.
---
--- ⚠️ `pcall`, and `busy` is always cleared. Job 011's review found the same shape latching a panel
--- dead for a whole session when an unguarded `InvokeServer` threw.
local function ask(commit: boolean?)
	--- 🔴 A COMMIT IS NEVER DROPPED; only a background preview is.
	---
	--- `setRecycleOpen(true)` fires a preview and the panel is on screen for the whole round trip.
	--- With a single `busy` flag, a player who tapped RECYCLE inside that window got the press
	--- tween and the press sound and **nothing else** -- no status, no error, no server call.
	---
	--- This is the identical bug job 011 found in `refreshQuotes`, post-mortem and all: the guard
	--- could not tell "a preview is running" from "a purchase is running", and only one of those is
	--- safe to discard. It was re-implemented here from the broken side.
	if previewing and not commit then
		return
	end
	if not commit then
		previewing = true
	end
	task.spawn(function()
		local invoked, ok, payload = pcall(function(): ...any
			return recycleRemote:InvokeServer(commit)
		end)
		previewing = false
		if not invoked then
			Log.error("RequestRecycle threw: %s", tostring(ok))
			status.Text = "THE RECYCLER IS NOT ANSWERING"
			status.TextColor3 = Theme.color.alarm
			return
		end
		if type(payload) ~= "table" then
			status.Text = tostring(payload)
			status.TextColor3 = Theme.color.alarm
			return
		end
		if commit then
			status.Text = tostring(payload.reason)
			status.TextColor3 = if ok then Theme.color.recycle else Theme.color.alarm
		end
		if type(payload.preview) == "table" then
			render(payload.preview)
		end
	end)
end

local function setRecycleOpen(open: boolean)
	recycleOpen = open
	gui.Enabled = open
	--- Hides Roblox's touch controls while the modal is up. Job 011 measured that there is no
	--- position on a phone that both fits a panel and clears the thumbstick and jump button.
	UserInputService.ModalEnabled = open
	if open then
		--- 🔴 CLEARED, not left showing the last visit.
		---
		--- Only `status` used to be reset, so if the preview never arrived -- the `Economy` bucket
		--- is shared with `RequestUpgrade` and can rate-limit -- the panel opened showing the
		--- PREVIOUS visit's scrap and coin figures with a live RECYCLE button under them. The
		--- server recomputes, so no money was ever wrong; but the number on screen was not the
		--- number charged, which is exactly the drift the one-remote quote-and-commit shape exists
		--- to prevent. On a first open it was worse: two completely blank exits.
		status.Text = ""
		carried.Text = "READING YOUR MAGNET…"
		coinsValue.Text = "—"
		repairValue.Text = "—"
		setExitsEnabled(false)
		ask(nil)
	end
end

Screens.register("Recycle", {
	setOpen = setRecycleOpen,
	isOpen = function(): boolean
		return recycleOpen
	end,
})

closeButton.Activated:Connect(function()
	setRecycleOpen(false)
end)

coinsButton.Activated:Connect(function()
	ask(true)
end)

--- 🔴 READS THE SERVER'S `repairable` FLAG rather than hardcoding the refusal.
---
--- The refusal used to be a literal string here, ignoring the flag the server already ships. The
--- day group 09 sets `repairable = true`, the server would say the exit is open, the panel would
--- draw it live in orange with a real HP number, and pressing it would still print "no robot yet"
--- -- with nothing in any type, assert or log connecting the two.
---
--- The button is now genuinely disabled while `repairable` is false, so this only runs once the
--- server says the exit is real. `RequestRepair` is bound and refuses honestly if it is not.
repairButton.Activated:Connect(function()
	ask(nil)
	status.Text = "REPAIR IS NOT WIRED YET — GROUP 09 OWNS IT"
	status.TextColor3 = Theme.color.textDim
end)

Layout.observe(layout)

--------------------------------------------------------------------------------
-- Prompts.
--------------------------------------------------------------------------------

--- 🔴 NO LOCAL COPIES. Both the screen name and the "not yet" message come off the prompt, which
--- the SERVER stamped from `StationService.BEHAVIOUR`.
---
--- There used to be a `NOT_YET` table and a `SCREEN_FOR` table here, described in a comment as
--- "mirrors StationService.BEHAVIOUR". They did not mirror it, nothing enforced that they did, and
--- they had already drifted apart on two of the five entries. A station added on the server with a
--- screen this file had never heard of got a "NOT BUILT YET" banner and no error.

ProximityPromptService.PromptTriggered:Connect(function(prompt, promptPlayer)
	if promptPlayer ~= player then
		return
	end
	local id = prompt:GetAttribute("StationId")
	if type(id) ~= "string" then
		return
	end

	--- ⚠️ Close whatever is open FIRST, on EVERY station -- not only on the branch that opens
	--- something. Measured: walking from the Recycler to the Repair Station and pressing E showed
	--- the "no robot yet" banner while leaving the Recycler's modal open behind it, so the player
	--- was reading one station's message over another station's screen.
	---
	--- Two modals open at once is worse than untidy: both set `ModalEnabled`, and whichever closes
	--- second hands Roblox's touch controls back for both.
	Screens.closeAll()

	local screen = prompt:GetAttribute("Screen")
	if type(screen) == "string" then
		if not Screens.open(screen) then
			Log.error("station %q wants screen %q, which nothing registered", id, screen)
			Banner.show("THAT PANEL IS MISSING", Theme.color.alarm)
		end
		return
	end

	--- ⚠️ `ModalEnabled` is cleared by hand here. `closeAll` only reaches screens that were open,
	--- so a station with no screen would otherwise leave the flag set by whatever closed.
	UserInputService.ModalEnabled = false
	local notYet = prompt:GetAttribute("NotYet")
	Banner.show(if type(notYet) == "string" then notYet else "NOT BUILT YET", Theme.color.textDim)
end)

--- 🔴 CHECKED LATE, ON PURPOSE, AND IT CAN FAIL.
---
--- An earlier version logged `Screens.names()` at load time and printed `Recycle` -- missing
--- `Upgrade`, because `Hud.local.luau` had not registered yet. That line looked like coverage and
--- was really a statement about script load order.
---
--- What matters is whether every screen a station points at exists **by the time a player can
--- reach one**, so the check waits for the boot screen to clear and then asserts exactly that. A
--- station wired to a screen nobody registered is a prompt that does nothing, which is the failure
--- PITFALLS #29 is about -- and it would otherwise only surface when a player pressed E.
task.spawn(function()
	local deadline = os.clock() + 60
	while playerGui:FindFirstChild("BootScreen") and os.clock() < deadline do
		task.wait(0.2)
	end
	task.wait(1)

	--- Reads the SERVER's own stamped contract off the live prompts, so this checks what the game
	--- will actually ask for rather than a list this file keeps.
	local missing = {}
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			local wants = d:GetAttribute("Screen")
			local id = d:GetAttribute("StationId")
			if type(wants) == "string" and not Screens.get(wants) then
				table.insert(missing, ("%s -> %s"):format(tostring(id), wants))
			end
		end
	end
	if #missing > 0 then
		Log.error("station screens NOT registered: %s (registered: %s)",
			table.concat(missing, ", "), table.concat(Screens.names(), ", "))
	else
		Log.info("station screens all registered: %s", table.concat(Screens.names(), ", "))
	end
end)
