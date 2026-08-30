--!strict
--[[
	Hud — Coins, Magnet Flow, Scrap/Capacity, the upgrade button and the robot/Arena widget.

	⚠️ This file is `.local.luau` -> LocalScript ON PURPOSE. A `.client.luau` in
	StarterPlayerScripts becomes a Script with RunContext=Client and RUNS TWICE -- once in place
	and once as the per-player copy. Measured in job 002. Two HUDs would look like one HUD with
	doubled tween speeds. Never rename this.

	--------------------------------------------------------------------------------
	THE THREE RULES THIS FILE IS BOUND BY
	--------------------------------------------------------------------------------

	1. **The client RENDERS `StatsChanged`. It never derives it.** `flowProgress`/`flowNeeded`
	   arrive as a numerator and a denominator; `full` arrives already computed. Nothing below
	   recalculates a stat the server owns, and the upgrade prices are asked for rather than
	   worked out from the shared Economy curves -- see the note on `refreshQuotes`.

	2. **The HUD REINFORCES `SCRAP FULL`; it does not carry it** (decision 0018). The magnet
	   already teaches it without a word of UI: the pull visibly stops while everything in range
	   still rattles, and `MAGNET.Full` plays. If this HUD ever becomes the only way to know you
	   are full, the magnet has stopped teaching. `dev("hud.hide")` exists precisely so that can
	   be re-checked rather than assumed.

	3. **The layout is MEASURED, not reasoned about** (decision 0012, `mobile` skill). Two
	   layouts, one HUD -- see `applyLayout`. Nothing here uses a pixel constant that was not
	   derived from the live canvas, and `auditLayout` re-checks the result against Roblox's own
	   touch-control rectangles every time the canvas changes.

	--------------------------------------------------------------------------------
	NOT PLACEHOLDERS, AND THE DIFFERENCE MATTERS
	--------------------------------------------------------------------------------

	The robot/Arena widget is real code bound to the real remote, and it stays HIDDEN because
	nothing fires `ArenaStateChanged` yet (groups 09/10). It draws no invented HP and no fake
	timer. It says so once at startup so that "the Arena widget never appears" is a known state
	rather than a bug someone re-discovers.

	Sources: docs/game/ui-direction.md · decisions 0012, 0018 · the `mobile` and
	         `magnet-sweep-style` skills · PITFALLS #13, #24, #29, #30
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Hud")

local UiFolder = ReplicatedStorage:WaitForChild("Ui", 20)
local Theme = require(UiFolder:WaitForChild("Theme", 20))
local Layout = require(UiFolder:WaitForChild("Layout", 20))
local Components = require(UiFolder:WaitForChild("Components", 20))
local Banner = require(UiFolder:WaitForChild("Banner", 20))

for _, problem in ipairs(Theme.audit()) do
	Log.error("THEME %s", problem)
end

--------------------------------------------------------------------------------
-- Formatting.
--------------------------------------------------------------------------------

--- 12450 -> "12,450". Coins are the largest number on screen and the one the player is most
--- often comparing against a price; ungrouped digits are measurably slower to read.
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

--- Power and Capacity are whole numbers; Radius and Drive are fractional. The server says
--- which is which (`Quote.decimals`) so the two sides cannot disagree about a rounding.
local function numberFor(v: number, decimals: number): string
	if decimals <= 0 then
		return comma(v)
	end
	return ("%.1f"):format(v)
end

--------------------------------------------------------------------------------
-- Build.
--------------------------------------------------------------------------------

local gui = Components.screen("Hud", playerGui, 10)

-- ── Coins ─────────────────────────────────────────────────────────────────────
local coinsPanel = Components.panel("Coins", gui)
local coinsIcon = Components.label("Icon", coinsPanel, {
	text = "🪙",
	align = Enum.TextXAlignment.Center,
	color = Theme.color.arena,
	size = 30,
})
coinsIcon.Size = UDim2.new(0, 0, 1, -8)
coinsIcon.Position = UDim2.fromOffset(0, 4)

local coinsCounter = Components.counter("Value", coinsPanel, comma, {
	font = Theme.font.data,
	color = Theme.color.arena,
	align = Enum.TextXAlignment.Left,
	size = 30,
})
coinsCounter.label.AnchorPoint = Vector2.new(0, 0.5)
coinsCounter.label.Position = UDim2.fromScale(0, 0.5)

-- ── Scrap / Capacity ──────────────────────────────────────────────────────────
local scrapPanel = Components.panel("Scrap", gui)
local scrapTitle = Components.label("Title", scrapPanel, {
	text = "SCRAP",
	font = Theme.font.label,
	color = Theme.color.textDim,
	size = 14,
})
scrapTitle.Position = UDim2.new(0, Theme.shape.pad, 0, 4)
scrapTitle.Size = UDim2.new(0.5, 0, 0, 14)

--- Capacity is displayed inside the scrap counter's own format string, so the two can never be
--- rendered from different pushes. It is the SERVER's `capacity`, never a local ceiling.
local capacityShown = 0
local scrapCounter = Components.counter("Value", scrapPanel, function(v)
	return ("%s <font color=\"#%s\">/ %s</font>"):format(comma(v), Theme.color.textDim:ToHex(), comma(capacityShown))
end, {
	font = Theme.font.data,
	color = Theme.color.magnet,
	align = Enum.TextXAlignment.Right,
	size = 30,
})
scrapCounter.label.AnchorPoint = Vector2.new(1, 0)
scrapCounter.label.Position = UDim2.new(1, -Theme.shape.pad, 0, 2)

local scrapBar = Components.bar("Bar", scrapPanel, Theme.color.magnet)
scrapBar.frame.AnchorPoint = Vector2.new(0.5, 1)
scrapBar.frame.Position = UDim2.new(0.5, 0, 1, -6)
scrapBar.frame.Size = UDim2.new(1, -2 * Theme.shape.pad, 0, 6)

-- ── Magnet Flow ───────────────────────────────────────────────────────────────
local flowPanel = Components.panel("Flow", gui)
flowPanel.Visible = false

local flowTitle = Components.label("Title", flowPanel, {
	text = "MAGNET FLOW",
	font = Theme.font.display,
	color = Theme.color.magnet,
	align = Enum.TextXAlignment.Center,
	size = 26,
})
flowTitle.Position = UDim2.new(0, Theme.shape.pad, 0, 2)
flowTitle.Size = UDim2.new(1, -2 * Theme.shape.pad, 0.62, 0)

local flowBar = Components.bar("Bar", flowPanel, Theme.color.magnet)
flowBar.frame.AnchorPoint = Vector2.new(0.5, 1)
flowBar.frame.Position = UDim2.new(0.5, 0, 1, -6)
flowBar.frame.Size = UDim2.new(1, -2 * Theme.shape.pad, 0, 6)

-- ── Robot / Arena widget ──────────────────────────────────────────────────────
-- Real code, real remote, no invented numbers. Hidden until the Arena exists.
local arenaPanel = Components.panel("Arena", gui)
arenaPanel.Visible = false
local arenaLine = Components.label("Line", arenaPanel, {
	text = "",
	font = Theme.font.data,
	color = Theme.color.repair,
	align = Enum.TextXAlignment.Center,
	size = 20,
})
arenaLine.Size = UDim2.new(1, -2 * Theme.shape.pad, 1, -8)
arenaLine.Position = UDim2.fromOffset(Theme.shape.pad, 4)

-- ── Upgrade ───────────────────────────────────────────────────────────────────
--- ⚠️ Forward-declared. `toggleUpgrade` calls the layout audit, and `auditLayout` is
--- defined further down -- without this the name inside `toggleUpgrade` would resolve to a
--- nil GLOBAL rather than to the local declared later, and the call would throw the first
--- time a player opened the panel. Lua scoping, silent until it runs.
local auditLayout: () -> ()

local upgradePanel: Frame
local upgradeOpen = false
local toggleUpgrade: () -> ()

local upgradeButton = Components.button("Upgrade", gui, {
	text = "UPGRADE",
	color = Theme.color.recycle,
	onActivated = function()
		toggleUpgrade()
	end,
})

--------------------------------------------------------------------------------
-- The upgrade panel.
--------------------------------------------------------------------------------

upgradePanel = Components.panel("UpgradePanel", gui)
upgradePanel.Visible = false
upgradePanel.BackgroundTransparency = 0.05 -- a modal is more opaque than a readout
upgradePanel.ZIndex = 5

local upgradeTitle = Components.label("Title", upgradePanel, {
	text = "MAGNET LAB",
	font = Theme.font.display,
	color = Theme.color.magnet,
	align = Enum.TextXAlignment.Left,
	size = 28,
})
upgradeTitle.ZIndex = 6

local closeButton = Components.button("Close", upgradePanel, {
	text = "✕",
	color = Theme.color.alarm,
	onActivated = function()
		toggleUpgrade()
	end,
})
closeButton.ZIndex = 6

--- ⚠️ A `ScrollingFrame`, not a hand-tuned column of four rows. Four tap targets plus a title
--- is 90 % of a phone's usable height at the measured 316 px canvas -- it fits, but only just,
--- and it would stop fitting the first time a fifth track or a taller device appeared. The
--- scroll makes the panel correct on every canvas instead of on the one that was measured.
local upgradeList = Instance.new("ScrollingFrame")
upgradeList.Name = "Tracks"
upgradeList.BackgroundTransparency = 1
upgradeList.BorderSizePixel = 0
upgradeList.ScrollBarThickness = 4
upgradeList.ScrollBarImageColor3 = Theme.color.magnet
upgradeList.AutomaticCanvasSize = Enum.AutomaticSize.Y
upgradeList.CanvasSize = UDim2.new()
upgradeList.ZIndex = 6
upgradeList.Parent = upgradePanel

local upgradeLayout = Instance.new("UIListLayout")
--- ⚠️ `SortOrder` is set EXPLICITLY. It defaults to `Name`, and a list of rows named after
--- their track would render alphabetically -- capacity, drive, power, radius -- which is not
--- the order the server sends and not the order they matter in. This exact default inverted a
--- steering control on another game in this workspace.
upgradeLayout.SortOrder = Enum.SortOrder.LayoutOrder
upgradeLayout.Padding = UDim.new(0, 6)
upgradeLayout.Parent = upgradeList

type Quote = {
	track: string,
	label: string,
	level: number,
	value: number,
	nextValue: number,
	cost: number,
	affordable: boolean,
	maxed: boolean,
	decimals: number,
}

local upgradeRemote = Remotes.getFunction("RequestUpgrade", 20)

--- Whether a BACKGROUND re-quote is in flight. A purchase is never gated on this — see the note
--- in `refreshQuotes`.
local quoting = false

--- 🔴 The purchase result goes HERE, in the panel, not into a banner.
---
--- MEASURED collision: the banner sits at 26 % of canvas height — y 62..103 on the phone preset —
--- and the upgrade panel's first row spans y 83..130. So buying MAGNET POWER produced a banner
--- that covered the top of the very row the player had just tapped, and the banner's right end ran
--- under the CLOSE button. Worse, the audit could never have seen it: it walks the Hud ScreenGui's
--- descendants, and the banner is a different ScreenGui entirely.
---
--- Putting the confirmation next to what was bought is also simply better: the player is looking at
--- the row, not at the middle of the screen.
local upgradeStatus = Components.label("Status", upgradePanel, {
	font = Theme.font.label,
	color = Theme.color.textDim,
	align = Enum.TextXAlignment.Left,
	size = 15,
})
upgradeStatus.ZIndex = 6

local statusUntil = 0

local function setUpgradeStatus(text: string, color: Color3?)
	upgradeStatus.Text = text:upper()
	upgradeStatus.TextColor3 = color or Theme.color.textDim
	statusUntil = os.clock() + 3
	local mine = statusUntil
	task.delay(3.05, function()
		if statusUntil == mine then
			upgradeStatus.Text = ""
		end
	end)
end

local renderQuotes: ({ Quote }) -> ()

--- Ask the server for the current prices and redraw.
---
--- ⚠️ The prices come from the SERVER even though `Config/Economy` is replicated and the client
--- could do the arithmetic itself. Two implementations of one price is one implementation too
--- many: the first time they disagreed, the player would read it as being overcharged, and the
--- disagreement would be invisible to every test that only ever ran one of them.
local function refreshQuotes(track: string?)
	--- ⚠️ A PURCHASE IS NEVER DROPPED; only a background re-quote is.
	---
	--- The first version guarded both with one `busy` flag. `render()` re-quotes whenever coins
	--- move and the panel is open — which during a MAGNET RUSH is constantly — so a row tap that
	--- landed in that window hit `if busy then return end` and did nothing at all. The button had
	--- already played its press tween, so the player tapped BUY and the game silently ignored it.
	--- The guard could not tell "a quote is running" from "a purchase is running", and only one of
	--- those is safe to discard.
	local isPurchase = track ~= nil
	if quoting and not isPurchase then
		return
	end
	if not isPurchase then
		quoting = true
	end

	task.spawn(function()
		--- ⚠️ `pcall`, because `InvokeServer` CAN throw — a handler erroring outside RemoteBinder's
		--- own pcall, the remote being torn down, an invoke that races the server's bind. Without
		--- it the `quoting = false` below is skipped and the panel becomes a permanent no-op for
		--- the rest of the session, with nothing on screen to say why.
		-- `: ...any` because the closure forwards BOTH of InvokeServer's returns; without the
		-- annotation the solver infers one and the payload is dropped at type level.
		local invoked, ok, payload = pcall(function(): ...any
			return upgradeRemote:InvokeServer(track)
		end)
		quoting = false

		if not invoked then
			Log.error("RequestUpgrade threw: %s", tostring(ok))
			setUpgradeStatus("THE MAGNET LAB IS NOT ANSWERING", Theme.color.alarm)
			return
		end
		-- the rate limiter and the error path reply with a plain string, not the payload table
		if type(payload) ~= "table" then
			setUpgradeStatus(tostring(payload), Theme.color.alarm)
			return
		end
		if isPurchase then
			setUpgradeStatus(tostring(payload.reason), if ok then Theme.color.recycle else Theme.color.alarm)
		end
		renderQuotes(payload.quotes or {})
	end)
end

type Row = { button: TextButton, name: TextLabel, delta: TextLabel, price: TextLabel }

--- ⚠️ Rows are built ONCE and updated in place, never rebuilt.
---
--- The first version destroyed and recreated all four on every render, and `render` calls
--- `refreshQuotes` on every `StatsChanged` while the panel is open -- which during a MAGNET
--- RUSH is four times a second. That is 16 buttons a second churned, and worse, each
--- `Components.button` registers a `Layout.observe` callback: destroying the button does not
--- remove the callback, so the observer list would grow without limit and keep every destroyed
--- instance alive. A leak with a long fuse, invisible in a short test.
--- The height an upgrade row is actually drawn at, decided by `applyLayout` from the space the
--- panel really has. Starts at the preferred tap target and degrades no further than the
--- documented 44 px floor.
---
--- ⚠️ MEASURED FAILURE: fixed at `Layout.tapTarget()` (56 px on the phone preset), four rows
--- plus the header needed 245 px inside a 170 px viewport, so rows 3 and 4 -- CAPACITY and
--- MAGNETIC DRIVE -- were cut off. The list scrolled, so nothing was unreachable, but a row
--- sliced through the middle of its own label reads as broken rather than as scrollable, and
--- two of the four things the player came here to buy were below the fold.
local rowHeight = Layout.TAP_PREFERRED

local rows: { Row } = {}
--- What the server last said, read by the row callbacks so a reused row cannot buy a stale
--- track. Indexed the same way the rows are.
local currentQuotes: { Quote } = {}

local function ensureRow(i: number): Row
	local existing = rows[i]
	if existing then
		return existing
	end

	local button = Components.button("Row" .. i, upgradeList, {
		-- ⚠️ The rows are the one control allowed down to the documented 44 px floor, so that
		-- every track fits the panel instead of two of them sitting below the fold. Without
		-- this the constraint's default 58 px minimum silently overrides `rowHeight`.
		tapFloor = Layout.TAP_FLOOR,
		onActivated = function()
			local q = currentQuotes[i]
			if not q then
				return
			end
			if q.maxed then
				Banner.show("ALREADY AT MAXIMUM", Theme.color.textDim)
				return
			end
			refreshQuotes(q.track)
		end,
	})
	button.Text = ""
	button.LayoutOrder = i
	button.ZIndex = 6
	button.Size = UDim2.new(1, -8, 0, rowHeight)

	local name = Components.label("TrackName", button, {
		font = Theme.font.data,
		color = Theme.color.text,
		size = 16,
	})
	name.AnchorPoint = Vector2.new(0, 0)
	name.Position = UDim2.fromScale(0, 0.08)
	name.Size = UDim2.new(0.58, 0, 0.46, 0)
	name.ZIndex = 7

	local delta = Components.label("Delta", button, {
		font = Theme.font.label,
		color = Theme.color.textDim,
		size = 14,
	})
	delta.AnchorPoint = Vector2.new(0, 1)
	delta.Position = UDim2.new(0, 0, 1, -2)
	delta.Size = UDim2.new(0.58, 0, 0.42, 0)
	delta.ZIndex = 7

	local price = Components.label("Price", button, {
		font = Theme.font.data,
		align = Enum.TextXAlignment.Right,
		size = 20,
	})
	price.AnchorPoint = Vector2.new(1, 0.5)
	price.Position = UDim2.fromScale(1, 0.5)
	price.Size = UDim2.new(0.4, 0, 0.6, 0)
	price.ZIndex = 7

	local row: Row = { button = button, name = name, delta = delta, price = price }
	rows[i] = row
	return row
end

function renderQuotes(quotes: { Quote })
	currentQuotes = quotes

	for i, q in ipairs(quotes) do
		local row = ensureRow(i)
		local accent = if q.maxed
			then Theme.color.textDim
			elseif q.affordable then Theme.color.recycle
			else Theme.color.steelMid

		row.button.Visible = true
		row.button.TextColor3 = accent
		local stroke = row.button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = accent
		end

		row.name.Text = q.label
		-- ⚠️ Built from `Theme`, not from a literal. RichText is the one place a colour token
		-- cannot be passed as a Color3, which is exactly how two hardcoded hexes got in here and
		-- would have been left behind the day a signal colour changed (PITFALLS #39).
		row.delta.Text = ("%s <font color=\"#%s\">→ %s</font>"):format(
			numberFor(q.value, q.decimals), Theme.color.magnet:ToHex(), numberFor(q.nextValue, q.decimals))
		row.price.Text = if q.maxed then "MAX" else ("🪙 %s"):format(comma(q.cost))
		row.price.TextColor3 = if q.maxed
			then Theme.color.textDim
			elseif q.affordable then Theme.color.arena
			else Theme.color.alarm
	end

	-- a track the server stopped sending must not keep a stale row on screen
	for i = #quotes + 1, #rows do
		rows[i].button.Visible = false
	end

	-- ⚠️ The row height depends on HOW MANY tracks the server sent, and the layout runs long
	-- before the first quote arrives. Without this the rows keep whatever height was computed
	-- for an empty list, which is exactly how they ended up overflowing the panel.
	Layout.refresh()
end

--- ⚠️ `ModalEnabled` hides Roblox's OWN touch controls while the panel is open. Without it the
--- modal sits on top of the thumbstick and the jump button on every phone -- the panel is
--- centred and the free bottom band is only 305 px of 666, so there is no position that both
--- fits the panel and clears the controls. Hiding them is the supported answer, and it is
--- restored the moment the panel closes.
function toggleUpgrade()
	upgradeOpen = not upgradeOpen
	upgradePanel.Visible = upgradeOpen
	UserInputService.ModalEnabled = upgradeOpen
	upgradeButton.Text = if upgradeOpen then "CLOSE" else "UPGRADE"
	if upgradeOpen then
		upgradeStatus.Text = ""
		refreshQuotes(nil)
	else
		-- 🔴 RE-LAYOUT ON CLOSE, and this line is load-bearing.
		--
		-- `ModalEnabled` switched Roblox's controls off while the panel was up. Closing switches
		-- them back on, but that fires no signal this module listens to: `metrics.AbsoluteSize` did
		-- not change, and `DescendantAdded` does not fire because Roblox only flips `Enabled`.
		-- Without this the layout keeps whatever it computed while the screen looked empty.
		Layout.refresh()
	end
	-- ⚠️ Re-audited on open, because the rows only exist while the panel is up: measuring the
	-- HUD in one state and calling the SCREEN verified is how a tray got signed off while it
	-- was `Visible = false` (mobile §4a.9). State coverage is part of the check, not a bonus.
	auditLayout()
end

--------------------------------------------------------------------------------
-- Layout. Two arrangements, chosen from a MEASURED canvas.
--------------------------------------------------------------------------------

--[[
	`docs/game/ui-direction.md` puts Scrap bottom-centre and Upgrade bottom-right. Both are
	right on a desktop and both are wrong on a phone, and the reason is measured rather than
	aesthetic:

	  * `DynamicThumbstickFrame` reaches x = 266 of a 666-wide canvas, so the free bottom band
	    is x 266..571 -- whose centre is x ≈ 418, NOT the canvas centre 333. A bottom-centre
	    panel of any useful width sits inside the movement control.
	  * The jump button owns x 571..641, y 226..296. A bottom-right button sits under it.

	So on touch, Scrap joins Coins in a top-left vitals column -- which is where the `mobile`
	skill puts a glanceable readout anyway -- and Upgrade moves to the top right, comfortably
	above the jump button. Desktop keeps `ui-direction.md` exactly as written.

	This is a deliberate, recorded divergence, not a drift. See Jobs/011/final-summary.md.
]]

local function applyLayout(canvas: Vector2)
	local touch = Layout.isTouch()
	local pad = math.clamp(canvas.X * 0.02, 8, 18)
	local gap = math.max(6, pad * 0.6)
	local rowH = Layout.size(canvas.Y, 0.11, 46, 28, 0.16)
	local tap = Layout.tapTarget()

	-- widths, all a fraction of the measured canvas
	local coinsW = Layout.size(canvas.X, 0.21, 200, 108, 0.34)
	local scrapW = Layout.size(canvas.X, 0.27, 250, 140, 0.40)
	local flowW = Layout.size(canvas.X, 0.32, 300, 150, 0.44)
	local arenaW = Layout.size(canvas.X, 0.25, 235, 130, 0.34)
	local upgradeW = math.max(tap, Layout.size(canvas.X, 0.17, 160, 92, 0.28))

	coinsPanel.AnchorPoint = Vector2.new(0, 0)
	coinsPanel.Position = UDim2.fromOffset(pad, pad)
	coinsPanel.Size = UDim2.fromOffset(coinsW, rowH)
	coinsIcon.Size = UDim2.new(0, rowH * 0.7, 1, -8)
	coinsIcon.Position = UDim2.fromOffset(Theme.shape.pad, 4)
	coinsCounter.label.Position = UDim2.new(0, Theme.shape.pad + rowH * 0.7 + 4, 0.5, 0)
	coinsCounter.label.Size = UDim2.new(1, -(2 * Theme.shape.pad + rowH * 0.7 + 4), 0.8, 0)

	-- Flow: top centre on both layouts. Only ever visible while active.
	flowPanel.AnchorPoint = Vector2.new(0.5, 0)
	flowPanel.Position = UDim2.new(0.5, 0, 0, pad)
	flowPanel.Size = UDim2.fromOffset(flowW, rowH * 1.15)

	--[[
		The scrap readout stays at the BOTTOM on both layouts -- `ui-direction.md` is right that
		it belongs there, and an earlier draft of this file moved it to a top-left vitals column
		on touch, which was an unnecessary retreat.

		What changes on touch is only WHERE along the bottom. MEASURED on the phone preset:
		the thumbstick frame runs to x = 266 and the jump button starts at x = 571, so the free
		bottom band is x 266..571 and its centre is **x = 418** -- not the canvas centre, 333. A
		panel centred at 333 sits inside the movement control.

		`freeBottomSpan` derives that from Roblox's own live rectangles, so this is not the
		numbers above written down a second time.
	]]
	local scrapH = rowH * 1.25

	-- 🔴 The scrap VALUE had no Size and rendered at 0x0: the panel showed the word "SCRAP",
	-- an empty bar, and nothing else. Every rectangle check passed -- the panel itself was the
	-- right size in the right place -- and one screenshot showed an empty box. `Components.label`
	-- does not set a Size, so every label needs one from the layout that owns it.
	scrapTitle.Position = UDim2.new(0, Theme.shape.pad, 0, 4)
	scrapTitle.Size = UDim2.new(0.45, 0, 0, math.max(12, scrapH * 0.32))
	scrapCounter.label.AnchorPoint = Vector2.new(1, 0)
	scrapCounter.label.Position = UDim2.new(1, -Theme.shape.pad, 0, 2)
	scrapCounter.label.Size = UDim2.new(0.55, -Theme.shape.pad, 0, scrapH * 0.52)

	scrapPanel.AnchorPoint = Vector2.new(0.5, 1)
	scrapPanel.Position = UDim2.new(0.5, 0, 1, -pad)
	scrapPanel.Size = UDim2.fromOffset(scrapW, scrapH)
	if touch then
		local from, to, known = Layout.freeBottomSpan(scrapH + pad)
		local band = to - from

		--- The narrowest this readout may be and still say "SCRAP 309 / 913" legibly. It is a
		--- floor, so the band must be able to CONTAIN it — an earlier version applied
		--- `math.max(80, width)` *after* passing a `band > 40` guard, which meant any band between
		--- 41 and ~96 px got an 80 px panel centred in it, overhanging the reserved rects on both
		--- sides. The guard and the floor have to be the same number or the guard is decorative.
		local MIN_READOUT = 80
		local needed = MIN_READOUT + 2 * gap

		if not known then
			-- ⚠️ We have never seen Roblox's controls on a touch device, so the band is unmeasured.
			-- Leave the panel where it is rather than placing it in a gap we are guessing at.
			Log.debug("bottom band not measurable yet -- leaving the scrap readout where it is")
		elseif band >= needed then
			scrapPanel.Size = UDim2.fromOffset(math.min(scrapW, band - 2 * gap), scrapH)
			scrapPanel.AnchorPoint = Vector2.new(0.5, 1)
			scrapPanel.Position = UDim2.new(0, (from + to) * 0.5, 1, -pad)
		else
			-- No band on this device wide enough to hold the readout. Fall back to the top-left
			-- vitals column, which the `mobile` skill names as the home for a glanceable readout,
			-- rather than placing it under a thumb.
			scrapPanel.AnchorPoint = Vector2.new(0, 0)
			scrapPanel.Position = UDim2.fromOffset(pad, pad + rowH + gap)
			scrapPanel.Size = UDim2.fromOffset(math.max(scrapW, coinsW), scrapH)
			Log.warn("free bottom band is %.0f px, under the %.0f px this readout needs -- moved to the top-left column",
				band, needed)
		end
	end

	-- The upgrade button: bottom-right on desktop, top-right on touch (clear of jump).
	if touch then
		upgradeButton.AnchorPoint = Vector2.new(1, 0)
		upgradeButton.Position = UDim2.new(1, -pad, 0, pad)
	else
		upgradeButton.AnchorPoint = Vector2.new(1, 1)
		upgradeButton.Position = UDim2.new(1, -pad, 1, -pad)
	end
	upgradeButton.Size = UDim2.fromOffset(upgradeW, tap)

	-- The Arena widget sits under whichever corner the upgrade button took.
	arenaPanel.AnchorPoint = Vector2.new(1, 0)
	arenaPanel.Size = UDim2.fromOffset(arenaW, rowH)
	if touch then
		arenaPanel.Position = UDim2.new(1, -pad, 0, pad + tap + gap)
	else
		arenaPanel.Position = UDim2.new(1, -pad, 0, pad)
	end

	-- The modal. Capped as a FRACTION of the canvas, never at a pixel height.
	local panelW = math.min(canvas.X - 2 * pad, math.max(300, canvas.X * 0.62))
	local panelH = math.min(canvas.Y - 2 * pad, canvas.Y * 0.90)
	upgradePanel.AnchorPoint = Vector2.new(0.5, 0.5)
	upgradePanel.Position = UDim2.fromScale(0.5, 0.5)
	upgradePanel.Size = UDim2.fromOffset(panelW, panelH)

	local titleH = math.max(24, tap * 0.6)
	upgradeTitle.Position = UDim2.fromOffset(Theme.shape.pad, 6)
	upgradeTitle.Size = UDim2.new(1, -(2 * Theme.shape.pad + tap), 0, titleH)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -6, 0, 6)
	closeButton.Size = UDim2.fromOffset(tap, tap)

	local headerH = math.max(titleH, tap) + 10
	local listH = panelH - headerH - Theme.shape.pad
	upgradeList.Position = UDim2.fromOffset(Theme.shape.pad, headerH)
	upgradeList.Size = UDim2.new(1, -2 * Theme.shape.pad, 0, listH)

	-- The status line fills the gap the header already has: the title is `titleH` tall but the
	-- header is as tall as the close button, so there is dead space under the title and to the
	-- left of it. No extra height is taken from the list.
	upgradeStatus.Position = UDim2.fromOffset(Theme.shape.pad, titleH + 6)
	upgradeStatus.Size = UDim2.new(1, -(2 * Theme.shape.pad + tap), 0, math.max(12, headerH - titleH - 12))

	--[[
		⚠️ The row height is DERIVED from the space the list actually has, not taken from
		`tapTarget()` and hoped for.

		Prefer 58 → accept 44 → only then scroll. iOS says 44 pt and Android 48 dp; 58 is our own
		stricter target, so degrading toward 44 to keep every track on screen is the documented
		trade the `mobile` skill allows, and it beats slicing two rows in half.

		MEASURED before this: rows fixed at 56 px needed 245 px in a 170 px viewport, and
		CAPACITY and MAGNETIC DRIVE were below the fold on the phone preset.
	]]
	local ROW_GAP = 6
	local count = math.max(1, #currentQuotes)
	local fits = (listH - ROW_GAP * (count - 1)) / count
	rowHeight = math.clamp(fits, Layout.TAP_FLOOR, tap)
	if fits < Layout.TAP_FLOOR then
		-- Below the floor we stop shrinking and let it scroll: an untappable row is worse than
		-- a scrollbar. Said out loud, because a silent degrade is how a control ends up at 34 px.
		Log.warn("upgrade rows would need %.0f px for %d tracks in %.0f px -- held at the %d px floor, list scrolls",
			fits, count, listH, Layout.TAP_FLOOR)
	end
	upgradeLayout.Padding = UDim.new(0, ROW_GAP)

	for _, row in ipairs(rows) do
		row.button.Size = UDim2.new(1, -8, 0, rowHeight)
	end
end

--------------------------------------------------------------------------------
-- The layout audit. A check that can actually fail.
--------------------------------------------------------------------------------

--- ⚠️ This runs in the SHIPPED client, not only in a test. Roblox can move its own controls,
--- a device can report a canvas nobody anticipated, and a future element can be added to the
--- wrong corner. It states the offender by name, because "the HUD overlaps something" is not
--- actionable and "Upgrade overlaps DynamicThumbstickFrame" is.
---
--- ⚠️ Deferred a frame. `AbsolutePosition` is not updated until after the layout pass, so
--- measuring in the same frame as the write reports the PREVIOUS rectangle -- which is how a
--- check like this passes while the screen is wrong.
local WATCHED: { [string]: GuiObject } = {}

function auditLayout()
	task.defer(function()
		task.wait()

		-- 🔴 A CHECK THAT CANNOT FAIL IS NOT A CHECK. The first version of this function
		-- happily logged "layout clean -- canvas 800x600 ... reserved=0 rects" during startup,
		-- when the camera was 1x1, the canvas had not been laid out and Roblox had not built
		-- its touch controls yet. Every element passed because there was nothing to collide
		-- with. It said `clean` on a screen it had not measured. (PITFALLS #2, #54.)
		local canvas = Layout.canvas()
		local viewport = Layout.viewport()
		if canvas.X <= 1 or canvas.Y <= 1 or viewport.X <= 1 or viewport.Y <= 1 then
			Log.debug("layout not measurable yet -- canvas %dx%d viewport %dx%d",
				canvas.X, canvas.Y, viewport.X, viewport.Y)
			return
		end

		-- ⚠️ The two checks have DIFFERENT preconditions, and conflating them silently drops
		-- one of them. A collision check needs Roblox's rects to exist; a tap-size check needs
		-- only a real canvas. While the modal is open `ModalEnabled` hides the touch controls,
		-- so `reserved` is legitimately empty -- and an audit gated on a single "ready" flag
		-- would then stop checking tap sizes exactly where the tappable rows live.
		local reserved = Layout.reserved()
		local canCheckCollisions = (not Layout.isTouch()) or #reserved > 0

		--- Everything paintable AND everything tappable. The upgrade rows are included while
		--- the panel is open, because a transparent row button under the floor is invisible to
		--- an audit that only looks at the persistent HUD.
		local targets: { [string]: GuiObject } = table.clone(WATCHED)
		if upgradeOpen then
			targets.UpgradeClose = closeButton
			for i, row in ipairs(rows) do
				if row.button.Visible then
					targets["UpgradeRow" .. i] = row.button
				end
			end
		end

		local problems, checked = 0, 0
		for name, obj in pairs(targets) do
			if obj.Visible then
				checked += 1
				if canCheckCollisions then
					local hit = Layout.collidesWith(obj)
					if hit then
						problems += 1
						Log.error("LAYOUT %s overlaps Roblox's own %s -- %s", name, hit, Layout.describe())
					end
				end
				-- ⚠️ Every GuiButton, including a transparent one. A clear button with no text
				-- still takes taps and is invisible to any audit that filters on "does it paint".
				local s = obj.AbsoluteSize
				if obj:IsA("GuiButton") and (s.X < Layout.TAP_FLOOR or s.Y < Layout.TAP_FLOOR) then
					problems += 1
					Log.error("LAYOUT %s is %.0fx%.0f, under the %d px tap floor", name, s.X, s.Y, Layout.TAP_FLOOR)
				end
			end
		end

		--[[
			🔴 THE CHECK THAT A RECTANGLE AUDIT CANNOT DO.

			`Scrap.Value` shipped at **0 x 0** and the panel rendered as an empty box with the
			word SCRAP in it. Every check above passed, because the panel WAS the right size in
			the right place -- it was the label inside it that had none. `Components.label` does
			not set a `Size`, so a label whose owner forgets to give it one is invisible, silent,
			and indistinguishable from a working panel in any numeric audit.

			One screenshot found it. This is that screenshot turned into something that fails on
			its own, for every element, on every canvas.
		]]
		--- Walks to whichever `ScreenGui` owns the element, so it works for the HUD and the
		--- banner alike. Stopping at one hardcoded root silently reported every banner element as
		--- not-painted, which would have made including them pointless.
		local function paintedOnScreen(obj: GuiObject): boolean
			local node: Instance? = obj
			while node do
				if node:IsA("ScreenGui") then
					return node.Enabled
				end
				if node:IsA("GuiObject") and not node.Visible then
					return false
				end
				node = node.Parent
			end
			return false
		end

		-- ⚠️ BOTH ScreenGuis. The banner is a separate one, and an audit that walks only this
		-- module's own tree cannot see the single largest piece of text the game draws.
		local painted: { Instance } = { gui }
		if Banner.screen.Enabled then
			table.insert(painted, Banner.screen)
		end
		local textNodes: { Instance } = {}
		for _, root in ipairs(painted) do
			for _, d in ipairs(root:GetDescendants()) do
				table.insert(textNodes, d)
			end
		end

		for _, d in ipairs(textNodes) do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and paintedOnScreen(d) then
				local s = d.AbsoluteSize
				if s.X < 1 or s.Y < 1 then
					problems += 1
					Log.error("LAYOUT %s has text %q but renders at %.0fx%.0f -- it is invisible",
						d:GetFullName(), d.Text, s.X, s.Y)
				elseif not d.TextFits then
					-- ⚠️ Clipped text is not smaller text. Below `MinTextSize` a label WRAPS and
					-- the overflow is cut, so a box that is too narrow ships severed mid-word.
					problems += 1
					Log.error("LAYOUT %s does not fit its %.0fx%.0f box -- text is clipped: %q",
						d:GetFullName(), s.X, s.Y, d.Text)
				end
			end
		end

		if problems > 0 then
			return
		end
		if canCheckCollisions then
			Log.info("layout verified: %d element(s) vs %d reserved rect(s) -- %s", checked, #reserved, Layout.describe())
		else
			-- ⚠️ Says what it did NOT check. "clean" from a check with nothing to compare
			-- against is the exact failure this whole function exists to avoid.
			Log.info("layout: %d element(s) clear the tap floor; COLLISIONS NOT CHECKED (no reserved rects) -- %s",
				checked, Layout.describe())
		end
	end)
end

WATCHED.Coins = coinsPanel
WATCHED.Scrap = scrapPanel
WATCHED.Flow = flowPanel
WATCHED.Arena = arenaPanel
WATCHED.Upgrade = upgradeButton

Layout.observe(function(canvas: Vector2)
	applyLayout(canvas)
	auditLayout()
end)

--------------------------------------------------------------------------------
-- Rendering the server's state.
--------------------------------------------------------------------------------

local wasFull, wasRush, wasOvercharge = false, false, false
local seenFirstPush = false

--- Re-quoting while the panel is open is throttled against the `Economy` rate-limit bucket, not
--- against how fast the screen could redraw.
---
--- ⚠️ Quotes and PURCHASES share that bucket. At 0.5 s a Rush with the panel open spends two
--- tokens a second on cosmetic price refreshes, out of the same burst allowance the player's
--- actual BUY needs — so the HUD could rate-limit its own owner. A price that is a second stale
--- costs nothing; a purchase refused because the HUD was talking costs the sale.
local QUOTE_THROTTLE = 1.5
local lastQuotedCoins, lastQuoteAt = -1, 0

local function render(s: any)
	if type(s) ~= "table" then
		return
	end

	-- Coins
	if type(s.coins) == "number" then
		coinsCounter:set(s.coins)
	end

	-- Scrap / Capacity. Both come from the same push, so they can never disagree.
	if type(s.capacity) == "number" then
		capacityShown = s.capacity
	end
	if type(s.scrap) == "number" then
		scrapCounter:set(s.scrap)
		scrapCounter:refresh() -- capacity may have moved while scrap did not
		scrapBar:set(s.scrap, capacityShown)
	end

	-- SCRAP FULL. `full` is computed on the server; this does not compare the two numbers.
	if type(s.full) == "boolean" then
		if s.full ~= wasFull then
			scrapBar:setColor(if s.full then Theme.color.alarm else Theme.color.magnet)
			scrapTitle.Text = if s.full then "SCRAP FULL" else "SCRAP"
			scrapTitle.TextColor3 = if s.full then Theme.color.alarm else Theme.color.textDim
			scrapCounter.label.TextColor3 = if s.full then Theme.color.alarm else Theme.color.magnet
			-- ⚠️ A banner ON THE EDGE only, and only as a SECOND voice. Decision 0018: the
			-- magnet already stopped pulling and played its own sound. This must never become
			-- the thing that tells the player.
			if s.full and seenFirstPush then
				Banner.show("SCRAP FULL", Theme.color.alarm)
			end
		end
		wasFull = s.full
	end

	-- Magnet Flow. `flowProgress` / `flowNeeded` are already a fraction; nothing is divided
	-- here that the server did not already decide.
	local tier = if type(s.flowTier) == "number" then s.flowTier else 0
	local rush = s.rush == true
	local overcharge = s.overcharge == true
	local showFlow = rush or tier > 0
	-- ⚠️ Audit on the EDGE. `WATCHED.Flow` looked like coverage and delivered none: the panel is
	-- only visible during a combo, every other layout event happens while it is hidden, and the
	-- audit's `if obj.Visible` gate therefore skipped it every single time.
	if showFlow ~= flowPanel.Visible then
		flowPanel.Visible = showFlow
		if showFlow then
			auditLayout()
		end
	end
	if showFlow then
		if rush then
			flowTitle.Text = "MAGNET RUSH!"
			flowTitle.TextColor3 = Theme.color.arena
			flowBar:setColor(Theme.color.arena)
			flowBar:set(1, 1)
		else
			flowTitle.Text = ("MAGNET FLOW  ×%d"):format(tier)
			flowTitle.TextColor3 = Theme.color.magnet
			flowBar:setColor(Theme.color.magnet)
			if type(s.flowProgress) == "number" and type(s.flowNeeded) == "number" then
				flowBar:set(s.flowProgress, s.flowNeeded)
			end
		end
	end

	if rush and not wasRush and seenFirstPush then
		Banner.show("MAGNET RUSH!", Theme.color.arena)
	end
	wasRush = rush

	if overcharge and not wasOvercharge and seenFirstPush then
		Banner.show("OVERCHARGE", Theme.color.epic)
	end
	wasOvercharge = overcharge

	-- The panel's prices depend on the coin balance, so coins earned while it is open have to
	-- be reflected. ⚠️ Throttled, and only when COINS actually moved: `StatsChanged` fires on
	-- every collection, so an unguarded refresh here would invoke a RemoteFunction four times a
	-- second for the whole of a MAGNET RUSH -- against the `Economy` rate-limit bucket, which
	-- would then start refusing the player's real purchases.
	if upgradeOpen and not quoting and type(s.coins) == "number" then
		local now = os.clock()
		if s.coins ~= lastQuotedCoins and now - lastQuoteAt > QUOTE_THROTTLE then
			lastQuotedCoins, lastQuoteAt = s.coins, now
			refreshQuotes(nil)
		end
	end

	seenFirstPush = true
end

Remotes.getEvent("StatsChanged", 20).OnClientEvent:Connect(render)

--------------------------------------------------------------------------------
-- The Arena widget. Real remote, no invented numbers.
--------------------------------------------------------------------------------

--- ⚠️ Renders ONLY what actually arrived. A missing field hides the widget rather than showing
--- a zero: "🤖 0 / 0 HP" is indistinguishable from a destroyed robot, and inventing a plausible
--- number is exactly what the no-placeholder rule forbids (PITFALLS #24).
local function renderArena(a: any)
	if type(a) ~= "table" or type(a.hp) ~= "number" or type(a.maxHp) ~= "number" then
		arenaPanel.Visible = false
		return
	end
	local parts = { ("🤖 %s / %s"):format(comma(a.hp), comma(a.maxHp)) }
	-- ⚠️ Floored before use. `holdSeconds` will arrive from a server clock (group 10) and there is
	-- no reason it will be whole; `%02d` on a fraction is fine in Luau but `%` on it is not what a
	-- clock means. Read once into a local so the type test and the arithmetic cannot disagree.
	local held = if type(a.holdSeconds) == "number" then math.max(0, math.floor(a.holdSeconds)) else 0
	if held > 0 then
		table.insert(parts, ("👑 %02d:%02d"):format(held // 60, held % 60))
	end
	arenaLine.Text = table.concat(parts, "  ·  ")
	arenaLine.TextColor3 = if held > 0 then Theme.color.arena else Theme.color.repair
	arenaPanel.Visible = true
	auditLayout()
end

Remotes.getEvent("ArenaStateChanged", 20).OnClientEvent:Connect(renderArena)

--------------------------------------------------------------------------------
-- Hiding the HUD, so decision 0018 can be re-checked rather than assumed.
--------------------------------------------------------------------------------

--- ⚠️ The gate is on `gui.Enabled` and nothing else re-enables it. Hiding a HUD element took
--- three attempts on another game in this workspace because a state driver kept switching it
--- back on; here there is exactly one writer, and it is this function.
local function applyVisibility()
	local hidden = player:GetAttribute("HudHidden") == true
	gui.Enabled = not hidden
	-- 🔴 The banner is a SEPARATE ScreenGui, and hiding only this one left `SCRAP FULL` firing in
	-- 64 px capitals across the middle of a "hidden" HUD. That does not weaken the decision-0018
	-- check, it inverts it: the experiment could no longer tell "the magnet taught me" from "the
	-- banner told me". Anything added to this HUD that builds its own ScreenGui belongs here too.
	Banner.setEnabled(not hidden)
	if hidden and upgradeOpen then
		toggleUpgrade()
	end
end
player:GetAttributeChangedSignal("HudHidden"):Connect(applyVisibility)
applyVisibility()

--------------------------------------------------------------------------------

--- ⚠️ Said out loud, once. "The Arena widget never appears" is true today and will be true
--- until group 10; without this line the first person to notice has to go and find out why.
Log.info("HUD ready -- %s", Layout.describe())
Log.info("Arena widget is wired to ArenaStateChanged, which has NO server handler yet (groups 09/10). It stays hidden and draws nothing.")
