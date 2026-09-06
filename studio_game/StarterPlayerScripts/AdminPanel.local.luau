--!strict
--[[
	AdminPanel — a GUI front end for the dev commands, for the owner only.

	`DevConsole` already reaches every command, but only by typing into the F9 client console. That
	is fine for a scripted playtest and useless while actually playing: you cannot type
	`dev("base.who")` with one hand on the movement keys. Same commands, as a panel.

	🔴 AUTHORISATION IS NOT DONE HERE, AND MUST NOT BE.

	`DevTools.isAuthorised` gates every call **server-side**, by `UserId`:

	    DevTools.AUTHORISED_USER_IDS = { [5025640608] = true }  -- johnygorsky10 (owner)

	This script asks the server whether it is allowed and stays hidden if not. That is a
	CONVENIENCE, not a security boundary -- an exploiter can always show a hidden GUI, and it buys
	them nothing, because `DevTools.run` re-checks on every single command. Never add a client-side
	allowlist here: it would read like protection and provide none.

	⚠️ Keyed on `UserId`, not username. A Roblox username can change; a UserId cannot. If the owner
	renames, the panel keeps working and nothing needs editing.

	🔴 THE COMMAND LIST IS FETCHED ON OPEN, NOT AT BOOT.

	The first version built its list once at startup and reported **10 commands** when the server
	registers **24**. Systems register their commands as they come up -- `profile.*`, `base.who`,
	`scrap.*`, `magnet.*` and the rest all arrive after this script runs -- so a boot-time snapshot
	is guaranteed to be short, and silently so. Nothing warns you; the panel just lacks entries.

	⚠️ `.local.luau` -> LocalScript ON PURPOSE. A `.client.luau` in `StarterPlayerScripts` becomes a
	Script with `RunContext = Client` and **RUNS TWICE** -- measured in job 002. Never rename this.

	F4, because F2 is `DevConsole` and F3 is `AudioBench`.

	Sources: Ui/Theme + Ui/Components (style §7) · DevTools · Jobs/022
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes", 20))
local Ui = ReplicatedStorage:WaitForChild("Ui", 20)
local Theme = require(Ui:WaitForChild("Theme", 20))
local Components = require(Ui:WaitForChild("Components", 20))
local Layout = require(Ui:WaitForChild("Layout", 20))

local player = Players.LocalPlayer
local remote = Remotes.getFunction("DevCommand", 20)
if not remote then
	return
end

local TOGGLE_KEY = Enum.KeyCode.F4
local MAX_ARGS = 8 -- DevTools rejects more than this, so do not send more

--------------------------------------------------------------------------------
-- Talking to the server.
--------------------------------------------------------------------------------

type Cmd = { name: string, ready: boolean, help: string }

--- Ask the server for the command list. `help` is itself a registered command, so it goes through
--- the same `DevTools.run` authorisation as everything else -- if this account is not an admin it
--- comes back `false, "not authorised"` and there is nothing to show.
---
--- ⚠️ ONE round trip. `InvokeServer` returns the handler's `(ok, message)` pair, and a function
--- that returns it forwards both, so `pcall` hands back `(pcallOk, allowed, text)`.
local function fetchCommands(): (boolean, { Cmd })
	local pcallOk, allowed, text = pcall(function()
		return remote:InvokeServer("help")
	end)
	if not pcallOk or allowed ~= true then
		return false, {}
	end
	--- `help` returns lines of "* name  help" / "- name  help"; `*` registered, `-` declared only
	local cmds: { Cmd } = {}
	for line in tostring(text):gmatch("[^\n]+") do
		local mark, name, help = line:match("^(%S)%s+(%S+)%s*(.*)$")
		if name then
			table.insert(cmds, { name = name, ready = mark == "*", help = help or "" })
		end
	end
	return true, cmds
end

--------------------------------------------------------------------------------
-- The panel, built once and then refreshed.
--------------------------------------------------------------------------------

local gui: ScreenGui? = nil
local list: ScrollingFrame? = nil
local output: TextLabel? = nil
local argBox: TextBox? = nil
local hint: TextLabel? = nil
local busy = false

local function say(message: string, color: Color3)
	if output then
		output.TextColor3 = color
		output.Text = message
	end
end

--- Arguments arrive as one string. Numbers are converted, so a handler expecting a number gets
--- one; everything else stays a string.
local function parseArgs(text: string): { any }
	local args = {}
	for word in tostring(text):gmatch("%S+") do
		if #args >= MAX_ARGS then
			break
		end
		local n = tonumber(word)
		table.insert(args, n ~= nil and n or word)
	end
	return args
end

local function run(name: string)
	if busy then
		return
	end
	busy = true
	say(("running %s ..."):format(name), Theme.color.textDim)

	local args = parseArgs(argBox and argBox.Text or "")
	local pcallOk, succeeded, message = pcall(function()
		return remote:InvokeServer(name, table.unpack(args))
	end)
	busy = false

	if not pcallOk then
		say(("%s -> call failed: %s"):format(name, tostring(succeeded)), Theme.color.alarm)
		return
	end
	--- ⚠️ Trust the FLAG, not the message. `DevTools.run` enforces that a handler returning nothing
	--- does not read as success, so a non-empty message is not evidence anything worked.
	say(("%s -> %s"):format(name, tostring(message)), succeeded == true and Theme.color.recycle or Theme.color.alarm)
end

local function build()
	gui = Components.screen("AdminPanel", player:WaitForChild("PlayerGui"), 90)
	local g = gui :: ScreenGui
	g.Enabled = false

	local root = Components.panel("Root", g)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromScale(0.52, 0.66)
	--- 🔴 OPAQUE, unlike every other panel in the game. `Theme.shape.panelTransparency` is 0.2
	--- because a HUD widget should let the factory show through -- that is the design system
	--- working, and it is deliberately not being changed. But this panel is 28 rows of 14 px
	--- text, and at 0.2 the player's own head and the Recycler machine were rendering behind
	--- the help column. Body text over moving 3-D geometry is unreadable at any size.
	root.BackgroundTransparency = 0.02
	--- a pixel floor, so it stays usable on a phone. ⚠️ `MinSize` silently overrides `Size`, so
	--- this is deliberate rather than incidental (see the note in Components.label).
	local sizeMin = Instance.new("UISizeConstraint")
	sizeMin.MinSize = Vector2.new(320, 260)
	sizeMin.Parent = root

	local pad = Instance.new("UIPadding")
	local P = UDim.new(0, Theme.shape.pad)
	pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = P, P, P, P
	pad.Parent = root

	local title = Components.label("Title", root, {
		text = ("ADMIN  ·  %s"):format(player.Name),
		font = Theme.font.display,
		color = Theme.color.arena,
		align = Enum.TextXAlignment.Left,
		scaled = true,
	})
	title.Size = UDim2.new(1, 0, 0, 28)

	hint = Components.label("Hint", root, {
		text = "",
		font = Theme.font.label,
		color = Theme.color.textDim,
		align = Enum.TextXAlignment.Left,
		scaled = false,
		size = 14,
	})
	local h = hint :: TextLabel
	h.Position = UDim2.new(0, 0, 0, 28)
	h.Size = UDim2.new(1, 0, 0, 16)

	list = Instance.new("ScrollingFrame")
	local l = list :: ScrollingFrame
	l.Name = "Commands"
	l.Position = UDim2.new(0, 0, 0, 50)
	--- 50 for the title+hint above; 88 for the output plate (44, at bottom -36) plus the arg
	--- box (30) and the gaps between them. Measured against those, not chosen.
	l.Size = UDim2.new(1, 0, 1, -50 - 88)
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.ScrollBarThickness = 6
	l.ScrollBarImageColor3 = Theme.color.magnet
	l.CanvasSize = UDim2.new()
	l.AutomaticCanvasSize = Enum.AutomaticSize.Y
	l.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = l

	--- The output strip gets its own dark plate. Without one, a command's result was a dim line
	--- of text hanging directly under the last list row, and there was nothing to tell you the
	--- answer had arrived -- which is the one thing the panel exists to show you.
	local outPlate = Instance.new("Frame")
	outPlate.Name = "OutputPlate"
	outPlate.AnchorPoint = Vector2.new(0, 1)
	outPlate.Position = UDim2.new(0, 0, 1, -36)
	outPlate.Size = UDim2.new(1, 0, 0, 44)
	outPlate.BackgroundColor3 = Theme.color.hazardBlack
	outPlate.BackgroundTransparency = 0.1
	outPlate.BorderSizePixel = 0
	outPlate.Parent = root
	local outCorner = Instance.new("UICorner")
	outCorner.CornerRadius = UDim.new(0, Theme.shape.corner)
	outCorner.Parent = outPlate
	local outPad = Instance.new("UIPadding")
	outPad.PaddingLeft = UDim.new(0, 8)
	outPad.PaddingRight = UDim.new(0, 8)
	outPad.PaddingTop = UDim.new(0, 4)
	outPad.Parent = outPlate

	output = Components.label("Output", outPlate, {
		text = "ready",
		font = Theme.font.label,
		color = Theme.color.textDim,
		align = Enum.TextXAlignment.Left,
		scaled = false,
		size = 15,
	})
	local o = output :: TextLabel
	o.Size = UDim2.fromScale(1, 1)
	o.TextWrapped = true
	o.TextYAlignment = Enum.TextYAlignment.Top

	argBox = Instance.new("TextBox")
	local a = argBox :: TextBox
	a.Name = "Args"
	a.AnchorPoint = Vector2.new(0, 1)
	a.Position = UDim2.new(0, 0, 1, 0)
	a.Size = UDim2.new(1, 0, 0, 30)
	a.BackgroundColor3 = Theme.color.hazardBlack
	a.BackgroundTransparency = 0.15
	a.BorderSizePixel = 0
	a.ClearTextOnFocus = false
	a.PlaceholderText = "arguments, space separated  (e.g.  Arm  PIPE_WRENCH)"
	a.PlaceholderColor3 = Theme.color.textDim
	a.Text = ""
	a.FontFace = Theme.font.label
	a.TextColor3 = Theme.color.text
	a.TextSize = 15
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.Parent = root
	local argCorner = Instance.new("UICorner")
	argCorner.CornerRadius = UDim.new(0, Theme.shape.corner)
	argCorner.Parent = a
	local argPad = Instance.new("UIPadding")
	argPad.PaddingLeft = UDim.new(0, 8)
	argPad.Parent = a
end

--- Split `scrap.spawn` into the system that owns it and the thing it does.
---
--- 🔴 DERIVED, NOT AUTHORED. A hand-written label table here would be a client-side copy of a list
--- the SERVER owns, and it would go stale the first time a command was added -- silently, because a
--- missing entry just falls back to the raw name and looks like the bug it replaced. The dotted
--- namespace already encodes both halves; this reads them rather than restating them.
---
--- ⚠️ `help` and any other undotted command keep their name as the action and land under GENERAL.
local function split(name: string): (string, string)
	local system, action = name:match("^([%w_]+)%.(.+)$")
	--- ⚠️ BOTH captures checked, not just the first. They succeed or fail together at runtime, so
	--- guarding one "works" -- and leaves the other typed `string?`, which the analyzer catches and
	--- a reader does not. Falling back to GENERAL is the right answer for any shape this pattern
	--- does not match, including ones nobody has thought of yet.
	if not (system and action) then
		return "GENERAL", name
	end
	return system:upper(), action
end

--- Rebuild the rows from a freshly fetched list.
local function refresh(cmds: { Cmd })
	local l = list :: ScrollingFrame
	for _, c in ipairs(l:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end

	local ready, declared = 0, 0
	local lastSystem: string? = nil
	local order = 0
	for _, cmd in ipairs(cmds) do
		if cmd.ready then
			ready += 1
		else
			declared += 1
		end

		local system, action = split(cmd.name)

		--- 🔴 A HEADER WHEN THE SYSTEM CHANGES. The list arrives alphabetically, so commands of one
		--- system are already adjacent -- this only has to notice the boundary. Without it 28 rows
		--- of `x.y` read as one undifferentiated wall of code, which is what the owner reported.
		if system ~= lastSystem then
			lastSystem = system
			order += 1
			local head = Instance.new("Frame")
			head.Name = "H_" .. system
			head.LayoutOrder = order
			head.BackgroundTransparency = 1
			head.Size = UDim2.new(1, -8, 0, 22)
			head.Parent = l

			local ht = Components.label("Head", head, {
				text = system,
				font = Theme.font.data,
				color = Theme.color.arena,
				align = Enum.TextXAlignment.Left,
				scaled = false,
				size = 13,
			})
			ht.Size = UDim2.new(1, 0, 1, 0)
			ht.TextYAlignment = Enum.TextYAlignment.Bottom

			--- a hairline under the header, so the group reads as a block rather than as a
			--- slightly-different-coloured row
			local rule = Instance.new("Frame")
			rule.Name = "Rule"
			rule.BackgroundColor3 = Theme.color.steelMid
			rule.BackgroundTransparency = 0.55
			rule.BorderSizePixel = 0
			rule.AnchorPoint = Vector2.new(0, 1)
			rule.Position = UDim2.new(0, 0, 1, 0)
			rule.Size = UDim2.new(1, 0, 0, 1)
			rule.Parent = head
		end

		order += 1
		local i = order
		local row = Instance.new("Frame")
		row.Name = cmd.name
		row.LayoutOrder = i
		--- Banded, so 28 rows read as a list rather than as a wall. Barely-there on purpose:
		--- strong enough to follow a name across to its help text, weak enough not to compete
		--- with the row you are pointing at.
		row.BackgroundColor3 = Theme.color.hazardBlack
		row.BackgroundTransparency = if i % 2 == 0 then 0.75 else 1
		row.BorderSizePixel = 0
		row.Size = UDim2.new(1, -8, 0, Layout.TAP_FLOOR)
		row.Parent = l

		local btn = Components.button("Run", row, {
			--- 🔴 EMPTY, and filled by the two labels below instead. `Components.button` centres and
			--- scales its own text, so a two-line label cannot be built out of `text` -- and a
			--- button reading `scrap.spawn` was the owner's complaint: it looks like a placeholder
			--- because it is an internal identifier, not a label.
			text = "",
			color = cmd.ready and Theme.color.magnet or Theme.color.steelMid,
			--- ⚠️ TAP_FLOOR, not the preferred 58: these are rows in a list, and the bigger minimum
			--- would silently override the row height and push the rest below the fold.
			tapFloor = Layout.TAP_FLOOR,
			onActivated = function()
				if not cmd.ready then
					say(("%s is declared but its system has not registered a handler"):format(cmd.name),
						Theme.color.arena)
					return
				end
				run(cmd.name)
			end,
		})
		btn.Position = UDim2.fromScale(0, 0)
		--- 0.34, not 0.42. A command name is ~12 characters; the wider column left `base.who`
		--- floating in the middle of 350 px of nothing and squeezed the sentence that explains it.
		btn.Size = UDim2.new(0.34, 0, 1, 0)

		--- The action, as a word: SPAWN, REBUILD, GRANT. What the button DOES.
		local actionLabel = Components.label("Action", btn, {
			text = action:gsub("_", " "):upper(),
			font = Theme.font.data,
			color = cmd.ready and Theme.color.magnet or Theme.color.steelMid,
			align = Enum.TextXAlignment.Left,
			scaled = false,
			size = 16,
		})
		actionLabel.Position = UDim2.fromOffset(0, 3)
		actionLabel.Size = UDim2.new(1, 0, 0, 19)

		--- 🔴 The full id is KEPT, small and dim. It is not decoration: it is what you type into the
		--- F9 console as `dev("scrap.spawn")`, and it is what the output strip echoes back. Dropping
		--- it to make the button pretty would break the link between this panel and every other way
		--- of running the same command.
		local idLabel = Components.label("Id", btn, {
			text = cmd.name,
			font = Theme.font.label,
			color = Theme.color.textDim,
			align = Enum.TextXAlignment.Left,
			scaled = false,
			size = 12,
		})
		idLabel.Position = UDim2.fromOffset(0, 22)
		idLabel.Size = UDim2.new(1, 0, 0, 16)

		local help = Components.label("Help", row, {
			text = cmd.help,
			--- ⚠️ Full-brightness `text`, not `textDim`. The dim grey is for units and captions
			--- beside a hero number; here the sentence IS the content, and at 13 px dim grey it
			--- was the least readable thing on the screen. The name still reads as the primary
			--- element because it is cyan and bold, which is colour doing the work instead of
			--- brightness.
			color = cmd.ready and Theme.color.text or Theme.color.steelMid,
			align = Enum.TextXAlignment.Left,
			scaled = false,
			size = 14,
		})
		help.Position = UDim2.new(0.36, 0, 0, 0)
		help.Size = UDim2.new(0.63, 0, 1, 0)
		help.TextWrapped = true
	end

	if hint then
		(hint :: TextLabel).Text =
			("F4 closes  ·  %d ready, %d declared  ·  server re-checks every command"):format(ready, declared)
	end
end

--------------------------------------------------------------------------------
-- Toggle. The key is always bound; authorisation is decided by the server on press.
--------------------------------------------------------------------------------

local announced = false

local function open()
	local allowed, cmds = fetchCommands()
	if not allowed then
		--- silent. An unauthorised player is not told an admin panel exists.
		return
	end
	if not gui then
		build()
	end
	refresh(cmds)
	local g = gui :: ScreenGui
	g.Enabled = true
	local root = g:FindFirstChild("Root") :: Frame
	if root then
		root.Size = UDim2.fromScale(0.52, 0.60)
		TweenService:Create(root, Theme.motion.press, { Size = UDim2.fromScale(0.52, 0.66) }):Play()
	end
	if not announced then
		announced = true
		print(("[admin] panel open for %s -- %d commands"):format(player.Name, #cmds))
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	--- ⚠️ `processed` guard: without it F4 fires while the argument box has focus.
	if processed then
		return
	end
	if input.KeyCode ~= TOGGLE_KEY then
		return
	end
	if gui and (gui :: ScreenGui).Enabled then
		(gui :: ScreenGui).Enabled = false
	else
		open()
	end
end)
