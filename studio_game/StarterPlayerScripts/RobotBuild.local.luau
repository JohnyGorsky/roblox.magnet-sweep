--!strict
--[[
	RobotBuild — the Robot Bay screen. Pick a slot, pick a part you own, watch it appear.

	This is the payoff half of the core loop's fourth layer: "a secured part gets bolted onto a
	physical robot in the Robot Bay". Until job 022 the bay's prompt said THE ROBOT BAY OPENS IN
	GROUP 09 and did nothing.

	🔴 THIS SCREEN DECIDES NOTHING. It renders `RequestInstallPart`'s reply and sends intent.

	Every rule about what fits where, what the player owns and whether they are close enough lives in
	`RobotService` on the server (decision 0007). So:

	* the slot list, the owned parts, which one is equipped and whether it CAN be installed all
	  arrive from the server -- none of it is computed here;
	* every reply carries a **fresh state**, and this screen replaces its own with it rather than
	  patching. A refused install that left the UI showing the part as equipped would be the worst
	  outcome a builder can produce, and local patching is the only way to get there;
	* an install this client thinks is legal is still re-checked. The buttons are a convenience.

	⚠️ `.local.luau` -> LocalScript ON PURPOSE. A `.client.luau` in `StarterPlayerScripts` becomes a
	Script with `RunContext = Client` and RUNS TWICE (job 002) -- here that would mean two screens
	answering one prompt, and `Screens.register` asserts on the second, so the symptom would be a
	startup error rather than a visible duplicate.

	Opened by `StationController` reading `Screen = "RobotBuild"` off the prompt the SERVER stamped
	from `StationService.BEHAVIOUR.RobotBay`. Nothing here knows where the bay is.

	Sources: docs/systems/robot-assembly · decision 0004 · decision 0007 · Ui/Screens · Jobs/022
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("RobotBuild")

local UiFolder = ReplicatedStorage:WaitForChild("Ui", 20)
local Theme = require(UiFolder:WaitForChild("Theme", 20))
local Layout = require(UiFolder:WaitForChild("Layout", 20))
local Components = require(UiFolder:WaitForChild("Components", 20))
local Screens = require(UiFolder:WaitForChild("Screens", 20))

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local Parts = require(Config:WaitForChild("Parts", 20))

local remote = Remotes.getFunction("RequestInstallPart", 20)
if not remote then
	Log.error("RequestInstallPart is missing -- the Robot Bay cannot open")
	return
end

--------------------------------------------------------------------------------
-- State. One copy, and it only ever comes from the server.
--------------------------------------------------------------------------------

local open = false
local state: any = nil
--- which slot's parts are listed. Not sent to the server -- it is a view preference.
local selectedSlot: string? = nil
local busy = false

--------------------------------------------------------------------------------
-- Build the screen once.
--------------------------------------------------------------------------------

local gui = Components.screen("RobotBuild", playerGui, 14)
gui.Enabled = false

local panel = Components.panel("Build", gui)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
--- ⚠️ Opaque, like the admin panel and unlike a HUD widget: this is two columns of part names, and
--- body text over the moving factory behind it is unreadable at any size. The design system's 0.2
--- is right for a readout and wrong for a list.
panel.BackgroundTransparency = 0.02

local pad = Instance.new("UIPadding")
local P = UDim.new(0, Theme.shape.pad)
pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = P, P, P, P
pad.Parent = panel

local title = Components.label("Title", panel, {
	text = "ROBOT BAY",
	font = Theme.font.display,
	color = Theme.color.arena,
	align = Enum.TextXAlignment.Left,
	scaled = true,
})

local subtitle = Components.label("Subtitle", panel, {
	text = "",
	font = Theme.font.label,
	color = Theme.color.textDim,
	align = Enum.TextXAlignment.Left,
	scaled = false,
	size = 14,
})

--- Left column: the slots, each showing what is on the robot right now.
local slotList = Instance.new("ScrollingFrame")
slotList.Name = "Slots"
slotList.BackgroundTransparency = 1
slotList.BorderSizePixel = 0
slotList.ScrollBarThickness = 4
slotList.ScrollBarImageColor3 = Theme.color.magnet
slotList.CanvasSize = UDim2.new()
slotList.AutomaticCanvasSize = Enum.AutomaticSize.Y
slotList.Parent = panel

local slotLayout = Instance.new("UIListLayout")
slotLayout.Padding = UDim.new(0, 4)
slotLayout.SortOrder = Enum.SortOrder.LayoutOrder
slotLayout.Parent = slotList

--- Right column: the parts you own for the selected slot.
local partList = Instance.new("ScrollingFrame")
partList.Name = "Parts"
partList.BackgroundTransparency = 1
partList.BorderSizePixel = 0
partList.ScrollBarThickness = 4
partList.ScrollBarImageColor3 = Theme.color.magnet
partList.CanvasSize = UDim2.new()
partList.AutomaticCanvasSize = Enum.AutomaticSize.Y
partList.Parent = panel

local partLayout = Instance.new("UIListLayout")
partLayout.Padding = UDim.new(0, 4)
partLayout.SortOrder = Enum.SortOrder.LayoutOrder
partLayout.Parent = partList

local statusPlate = Instance.new("Frame")
statusPlate.Name = "StatusPlate"
statusPlate.BackgroundColor3 = Theme.color.hazardBlack
statusPlate.BackgroundTransparency = 0.1
statusPlate.BorderSizePixel = 0
statusPlate.Parent = panel
local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, Theme.shape.corner)
statusCorner.Parent = statusPlate
local statusPad = Instance.new("UIPadding")
statusPad.PaddingLeft = UDim.new(0, 8)
statusPad.PaddingRight = UDim.new(0, 8)
statusPad.PaddingTop = UDim.new(0, 4)
statusPad.Parent = statusPlate

local status = Components.label("Status", statusPlate, {
	text = "",
	font = Theme.font.label,
	color = Theme.color.textDim,
	align = Enum.TextXAlignment.Left,
	scaled = false,
	size = 15,
})
status.Size = UDim2.fromScale(1, 1)
status.TextWrapped = true
status.TextYAlignment = Enum.TextYAlignment.Top

local closeButton = Components.button("Close", panel, {
	text = "CLOSE",
	color = Theme.color.chrome,
})

--------------------------------------------------------------------------------
-- Layout, measured from the canvas rather than assumed.
--------------------------------------------------------------------------------

local HEADER = 30
local SUB = 18
local STATUS_H = 44
local CLOSE_H = 40

local function layout(canvas: Vector2)
	--- ⚠️ The 5th argument is NOT optional in spirit. `Layout.size` defaults `maxFraction` to 0.6,
	--- so a fraction above that is silently clamped to 0.6 of the canvas -- asking for 0.70 and
	--- getting 0.60 with nothing to say so. Both ceilings are stated: this is a two-column modal
	--- and it needs the room.
	local w = Layout.size(canvas.X, 0.62, 720, 320, 0.92)
	local h = Layout.size(canvas.Y, 0.72, 520, 280, 0.88)
	panel.Size = UDim2.fromOffset(w, h)

	title.Position = UDim2.fromOffset(0, 0)
	title.Size = UDim2.new(1, 0, 0, HEADER)
	subtitle.Position = UDim2.fromOffset(0, HEADER)
	subtitle.Size = UDim2.new(1, 0, 0, SUB)

	local top = HEADER + SUB + 6
	local bottom = STATUS_H + CLOSE_H + 12
	local listH = h - (Theme.shape.pad * 2) - top - bottom

	--- 0.34 / 0.64 — the slot column holds one word and a part name, the part column holds a name,
	--- a rarity and an effect sentence. An even split starved the half that has more to say.
	local slotW = math.floor((w - Theme.shape.pad * 2) * 0.34)
	slotList.Position = UDim2.fromOffset(0, top)
	slotList.Size = UDim2.fromOffset(slotW, listH)
	partList.Position = UDim2.fromOffset(slotW + 10, top)
	partList.Size = UDim2.new(1, -(slotW + 10), 0, listH)

	statusPlate.AnchorPoint = Vector2.new(0, 1)
	statusPlate.Position = UDim2.new(0, 0, 1, -(CLOSE_H + 6))
	statusPlate.Size = UDim2.new(1, 0, 0, STATUS_H)

	closeButton.AnchorPoint = Vector2.new(1, 1)
	closeButton.Position = UDim2.new(1, 0, 1, 0)
	closeButton.Size = UDim2.fromOffset(math.min(160, w * 0.35), CLOSE_H)
end

--------------------------------------------------------------------------------
-- Talking to the server.
--------------------------------------------------------------------------------

local function say(message: string, color: Color3)
	status.Text = message
	status.TextColor3 = color
end

local render: () -> ()

--- One shape for both calls: no arguments reads, (slot, partId) installs.
---
--- ⚠️ `pcall` around the invoke. A `RemoteFunction` that errors server-side raises HERE, and an
--- unprotected invoke inside a button handler kills the handler for good -- the button then does
--- nothing for the rest of the session with no message anywhere.
local function call(slot: string?, partId: string?): (boolean, string)
	local pcallOk, ok, payload = pcall(function()
		if slot and partId then
			return remote:InvokeServer(slot, partId)
		end
		return remote:InvokeServer()
	end)
	if not pcallOk then
		return false, ("the bay did not answer: %s"):format(tostring(ok))
	end
	--- 🔴 REPLACE the state from the reply, on success AND on refusal. Never patch locally.
	if type(payload) == "table" and type(payload.state) == "table" then
		state = payload.state
		render()
	end
	local reason = (type(payload) == "table" and type(payload.reason) == "string") and payload.reason or "no reason given"
	return ok == true, reason
end

local function install(slot: string, partId: string)
	if busy then
		return
	end
	busy = true
	say("installing…", Theme.color.textDim)
	local ok, reason = call(slot, partId)
	busy = false
	--- ⚠️ The FLAG decides the colour, not whether the message is non-empty. A refusal carries a
	--- perfectly readable sentence, and colouring by presence would paint it green.
	say(reason, ok and Theme.color.recycle or Theme.color.alarm)
end

--------------------------------------------------------------------------------
-- Rendering. Everything drawn here came off the wire.
--------------------------------------------------------------------------------

local function clear(frame: Instance)
	for _, c in ipairs(frame:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function rarityColor(rarity: string?): Color3
	return (rarity and Parts.RARITY_COLOR[rarity]) or Theme.color.chrome
end

local function renderSlots()
	clear(slotList)
	if not state then
		return
	end
	for i, slot in ipairs(state.slots) do
		local equipped = state.equipped[slot]
		local isSelected = slot == selectedSlot
		local owned = state.bySlot[slot]
		local count = owned and #owned or 0

		local row = Instance.new("Frame")
		row.Name = slot
		row.LayoutOrder = i
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -6, 0, 52)
		row.Parent = slotList

		local btn = Components.button("Pick", row, {
			text = "",
			color = isSelected and Theme.color.magnet or Theme.color.steelMid,
			tapFloor = Layout.TAP_FLOOR,
			onActivated = function()
				selectedSlot = slot
				render()
			end,
		})
		btn.Size = UDim2.fromScale(1, 1)
		btn.BackgroundTransparency = isSelected and 0.1 or 0.45

		local name = Components.label("Slot", btn, {
			text = ("%s  <font color='#6E7A88'>(%d)</font>"):format(slot:upper(), count),
			font = Theme.font.data,
			color = isSelected and Theme.color.magnet or Theme.color.text,
			align = Enum.TextXAlignment.Left,
			scaled = false,
			size = 15,
		})
		name.Position = UDim2.fromOffset(0, 4)
		name.Size = UDim2.new(1, 0, 0, 18)

		--- 🔴 The EMPTY case is named, not blank. A slot with nothing in it is a real, legal state
		--- (the starter has no Back part by design), and an empty row reads as a rendering bug.
		local wearing = Components.label("Wearing", btn, {
			text = equipped and equipped.name or "— empty —",
			font = Theme.font.label,
			color = equipped and rarityColor(equipped.rarity) or Theme.color.steelMid,
			align = Enum.TextXAlignment.Left,
			scaled = false,
			size = 13,
		})
		wearing.Position = UDim2.fromOffset(0, 24)
		wearing.Size = UDim2.new(1, 0, 0, 18)
	end
end

local function renderParts()
	clear(partList)
	if not state or not selectedSlot then
		return
	end
	local bucket = state.bySlot[selectedSlot] or {}
	local equipped = state.equipped[selectedSlot]

	if #bucket == 0 then
		local none = Components.label("None", partList, {
			text = ("You own no %s parts yet.\nFind one in the factory — or grant one with  part.grant <PARTID>")
				:format(selectedSlot:upper()),
			font = Theme.font.label,
			color = Theme.color.textDim,
			align = Enum.TextXAlignment.Left,
			scaled = false,
			size = 14,
		})
		none.Size = UDim2.new(1, -6, 0, 56)
		none.TextWrapped = true
		none.TextYAlignment = Enum.TextYAlignment.Top
		return
	end

	for i, part in ipairs(bucket) do
		local isOn = equipped ~= nil and equipped.partId == part.partId
		local canPress = part.installable and not isOn

		local row = Instance.new("Frame")
		row.Name = part.partId
		row.LayoutOrder = i
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -6, 0, 58)
		row.Parent = partList

		local btn = Components.button("Install", row, {
			--- ⚠️ Greyed by ACCENT, and genuinely inert when it cannot be pressed -- the handler
			--- returns early rather than the button merely looking disabled. A control that presses,
			--- tweens and does nothing is the shape PITFALLS #34 is about.
			text = "",
			color = if isOn then Theme.color.recycle elseif part.installable then rarityColor(part.rarity) else Theme.color.steelMid,
			tapFloor = Layout.TAP_FLOOR,
			onActivated = function()
				if isOn then
					say(("%s is already on the robot"):format(part.name), Theme.color.textDim)
					return
				end
				if not part.installable then
					say(("%s cannot be built: %s"):format(part.name, tostring(part.blocked)), Theme.color.arena)
					return
				end
				install(selectedSlot :: string, part.partId)
			end,
		})
		btn.Size = UDim2.fromScale(1, 1)
		btn.BackgroundTransparency = canPress and 0.25 or 0.5

		local nameText = part.name
		if isOn then
			nameText = ("%s  <font color='#3FD64B'>· ON THE ROBOT</font>"):format(part.name)
		elseif not part.installable then
			nameText = ("%s  <font color='#FFC21A'>· %s</font>"):format(part.name, tostring(part.blocked))
		end
		local name = Components.label("Name", btn, {
			text = nameText,
			font = Theme.font.data,
			color = part.installable and Theme.color.text or Theme.color.steelMid,
			align = Enum.TextXAlignment.Left,
			scaled = false,
			size = 15,
		})
		name.Position = UDim2.fromOffset(0, 5)
		name.Size = UDim2.new(1, 0, 0, 20)

		local meta = Components.label("Meta", btn, {
			text = ("<font color='#%s'>%s</font>%s%s"):format(
				rarityColor(part.rarity):ToHex(),
				tostring(part.rarity):upper(),
				part.effect and ("  ·  " .. tostring(part.effect)) or "",
				part.starter and "  ·  starter stub" or ""),
			font = Theme.font.label,
			color = Theme.color.textDim,
			align = Enum.TextXAlignment.Left,
			scaled = false,
			size = 13,
		})
		meta.Position = UDim2.fromOffset(0, 27)
		meta.Size = UDim2.new(1, 0, 0, 22)
		meta.TextWrapped = true
	end
end

render = function()
	if not state then
		subtitle.Text = "reading your robot…"
		return
	end
	--- default the selection to the first slot that HAS something to choose from, so the right-hand
	--- column is never pointlessly empty on open
	if not selectedSlot or not state.bySlot[selectedSlot] then
		for _, slot in ipairs(state.slots) do
			local bucket = state.bySlot[slot]
			if bucket and #bucket > 0 then
				selectedSlot = slot
				break
			end
		end
		selectedSlot = selectedSlot or state.slots[1]
	end

	local bits = { ("%d part(s) owned"):format(state.ownedCount or 0) }
	--- 🔴 Both of these are stated rather than hidden. A player whose profile failed to load is
	--- about to make a change that will not survive the session, and a player who has walked away
	--- from the bay is about to press a button the server will refuse.
	if state.willPersist == false then
		table.insert(bits, "⚠️ your profile did not load — changes will NOT be saved")
	end
	if state.atStation == false then
		table.insert(bits, ("⚠️ %s"):format(tostring(state.whyNot)))
	end
	subtitle.Text = table.concat(bits, "  ·  ")
	subtitle.TextColor3 = (state.willPersist == false or state.atStation == false)
		and Theme.color.arena or Theme.color.textDim

	renderSlots()
	renderParts()
end

--------------------------------------------------------------------------------
-- Open / close.
--------------------------------------------------------------------------------

local function setOpen(shouldOpen: boolean)
	open = shouldOpen
	gui.Enabled = shouldOpen
	--- Hides Roblox's touch controls while the modal is up -- job 011 measured that there is no
	--- position on a phone that both fits a panel and clears the thumbstick and jump button.
	UserInputService.ModalEnabled = shouldOpen
	if not shouldOpen then
		return
	end
	--- 🔴 CLEARED AND RE-FETCHED on every open, never restored from the last visit. The robot can
	--- have changed since -- another install, a rejoin, a profile that finished loading late -- and
	--- a builder showing a stale loadout invites a swap that is already done.
	state = nil
	say("", Theme.color.textDim)
	render()
	task.spawn(function()
		local ok, reason = call(nil, nil)
		if not ok then
			say(reason, Theme.color.alarm)
		end
	end)
end

Screens.register("RobotBuild", {
	setOpen = setOpen,
	isOpen = function(): boolean
		return open
	end,
})

closeButton.Activated:Connect(function()
	setOpen(false)
end)

Layout.observe(layout)
