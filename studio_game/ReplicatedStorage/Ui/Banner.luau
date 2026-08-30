--!strict
--[[
	Banner — one line, all caps, short-lived.

	The whole "three seconds to understand" contract (docs/game/ui-direction.md) is this file:
	**SALVAGE BREACH** · **FACTORY REFRESH IN 00:20** · **SECURED** · **MAGNET RUSH!** ·
	**⚡ LEGENDARY PART DETECTED**. No lore, no second line, no panel around it.

	Shared by every client system that needs to say something, so there is exactly one banner on
	screen at a time and no two systems can stack their own.

	⚠️ **A banner REINFORCES, it never replaces.** Decision 0018 is explicit that SCRAP FULL is
	carried by the magnet's own behaviour -- the pull visibly stops while everything in range
	still rattles -- and that if the HUD becomes the only way to know, the magnet has stopped
	teaching. Every banner here is a second voice for something the world already said.

	Sources: docs/game/ui-direction.md · decision 0018 · style skill §7
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UiFolder = script.Parent
local Theme = require(UiFolder:WaitForChild("Theme", 20))
local Components = require(UiFolder:WaitForChild("Components", 20))
local Layout = require(UiFolder:WaitForChild("Layout", 20))

assert(RunService:IsClient(), "Ui.Banner is client-only")

local Banner = {}

--- Sits below the Flow readout and above the action. Not vertically centred: the middle of the
--- screen is where the player is looking at the scrap, and a banner there covers the thing it
--- is commenting on.
local Y_FRACTION = 0.26

--- More than this waiting means something is firing banners in a loop; drop the excess rather
--- than queue a minute of stale news.
local MAX_QUEUE = 3

local player = Players.LocalPlayer

local gui = Components.screen("Banner", player:WaitForChild("PlayerGui"), 20)

local label = Components.label("Line", gui, {
	font = Theme.font.display,
	align = Enum.TextXAlignment.Center,
	color = Theme.color.text,
	size = 64,
})
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, Y_FRACTION)
label.TextTransparency = 1

local stroke = Instance.new("UIStroke")
stroke.Color = Theme.color.hazardBlack
stroke.Thickness = 3
stroke.Transparency = 1
stroke.Parent = label

local scale = Instance.new("UIScale")
scale.Parent = label

--- ⚠️ Sized from the MEASURED canvas, not from a constant. A 64 px display line is right on a
--- desktop and is a fifth of a phone's usable height (mobile §2).
Layout.observe(function(canvas: Vector2)
	label.Size = UDim2.fromOffset(canvas.X * 0.86, Layout.size(canvas.Y, 0.13, 64, 24, 0.2))
end)

type Pending = { text: string, color: Color3 }

local queue: { Pending } = {}
local showing = false
local lastText, lastAt = "", 0

local function play(item: Pending)
	showing = true
	label.Text = item.text:upper()
	label.TextColor3 = item.color
	scale.Scale = 1.25

	local inInfo = TweenInfo.new(Theme.banner.inTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(label, inInfo, { TextTransparency = 0 }):Play()
	TweenService:Create(stroke, inInfo, { Transparency = 0.2 }):Play()
	TweenService:Create(scale, inInfo, { Scale = 1 }):Play()

	task.delay(Theme.banner.inTime + Theme.banner.hold, function()
		local outInfo = TweenInfo.new(Theme.banner.outTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(label, outInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, outInfo, { Transparency = 1 }):Play()
		TweenService:Create(scale, outInfo, { Scale = 1.1 }):Play()
		task.delay(Theme.banner.outTime, function()
			showing = false
			local nextItem = table.remove(queue, 1)
			if nextItem then
				play(nextItem)
			end
		end)
	end)
end

--- Say one thing. `color` defaults to the magnet's cyan; pass a SIGNAL colour that means what
--- the banner is about -- alarm red for a breach, gold for Arena control, green for a recycle.
---
--- ⚠️ De-duped. `StatsChanged` fires on every collection, so an edge that is computed slightly
--- wrong upstream turns into a banner per pickup; this is the backstop that keeps that from
--- being a screen-filling failure rather than a small one.
function Banner.show(text: string, color: Color3?)
	if type(text) ~= "string" or text == "" then
		return
	end
	local now = os.clock()
	if text == lastText and now - lastAt < Theme.banner.dedupe then
		return
	end
	lastText, lastAt = text, now

	local item: Pending = { text = text, color = color or Theme.color.magnet }
	if showing then
		if #queue < MAX_QUEUE then
			table.insert(queue, item)
		end
		return
	end
	play(item)
end

--- Drop anything waiting, and take down whatever is on screen now.
---
--- ⚠️ It clears the CURRENT banner too. An earlier version only emptied the queue, which meant
--- "clear" left the loudest thing on the screen exactly where it was.
function Banner.clear()
	table.clear(queue)
	showing = false
	label.TextTransparency = 1
	stroke.Transparency = 1
end

--- Show or hide the banner layer entirely.
---
--- 🔴 THIS IS WHY IT EXISTS. `dev("hud.hide")` sets `Hud`'s `ScreenGui.Enabled = false` so that
--- decision 0018 can be re-checked — *does the magnet still teach SCRAP FULL with no HUD?* The
--- banner is a SEPARATE `ScreenGui`, so it kept firing `SCRAP FULL` in 64 px capitals across the
--- middle of the screen while the HUD was "hidden".
---
--- That does not just weaken the experiment, it inverts it: the test could no longer tell "the
--- magnet taught me" from "the banner told me", which is the precise distinction decision 0018 is
--- about. The HUD owns this flag, so there is exactly one writer.
--- The Banner's own `ScreenGui`.
---
--- ⚠️ Exposed so the HUD's layout audit can INCLUDE it. The audit walks one ScreenGui's
--- descendants, and the banner lives in a different one -- so a banner overlapping a control, or
--- clipping its own text, was invisible to every check in the game.
Banner.screen = gui

function Banner.setEnabled(on: boolean)
	gui.Enabled = on
	if not on then
		Banner.clear()
	end
end

return Banner
