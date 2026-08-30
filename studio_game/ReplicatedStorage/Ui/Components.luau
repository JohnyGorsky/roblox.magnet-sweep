--!strict
--[[
	Components — the small set of things the HUD is built out of.

	One panel recipe, one label recipe, one bar, one button and one counter. Every screen in
	this game is assembled from these, so the design system is applied by CONSTRUCTION rather
	than by remembering to apply it.

	Three behaviours are baked in on purpose, because each is a rule that decays the moment it
	becomes optional:

	* **Every button gets a pressed state, a scale tween and a sound.** Silence reads as broken
	  (style §7). `button()` is the only way to make one, so there is no path that forgets.
	* **Every number counts up and then punches.** `counter()` owns both, and the punch is rate
	  limited -- see the note on `Counter:set`, which is a measured constraint and not taste.
	* **Every tap target clears the floor.** `button()` applies `Layout.tapTarget()` itself.
	  ⚠️ Including transparent ones: a `GuiButton` with a clear background and no text still
	  takes taps, and a paint-filtered audit cannot see it (mobile §4a.7).

	Sources: .claude/skills/magnet-sweep-style/SKILL.md §7 · the shared `mobile` and `roblox-ui`
	         skills · docs/game/ui-direction.md
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local UiFolder = script.Parent
local Theme = require(UiFolder:WaitForChild("Theme", 20))
local Layout = require(UiFolder:WaitForChild("Layout", 20))
local SoundKit = require(ReplicatedStorage:WaitForChild("SoundKit", 20))

local Components = {}

--- Text below this simply WRAPS rather than shrinking, and the overflow is cut. So a box that
--- is too small does not produce small text, it produces severed text -- which is why every
--- width change in this game has to be re-checked for clipping (mobile §5).
local MIN_TEXT = 12

--------------------------------------------------------------------------------
-- Screens and panels.
--------------------------------------------------------------------------------

--- A ScreenGui with the inset mode interactive UI must use.
---
--- ⚠️ `CoreUISafeInsets`, not `None`. `None` is for full-bleed art only; interactive UI under a
--- notch or the Dynamic Island is untappable, and the player has no way to know why.
function Components.screen(name: string, parent: Instance, displayOrder: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = displayOrder or 0
	gui.Parent = parent
	return gui
end

--- The panel recipe from style §7: `#141B2Bcc` fill, a 2 px magnet-cyan stroke at 40 %, an
--- 8 px corner, and a 1 px chrome highlight along the top edge.
function Components.panel(name: string, parent: Instance): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = Theme.color.panel
	f.BackgroundTransparency = Theme.shape.panelTransparency
	f.BorderSizePixel = 0
	f.Size = UDim2.fromOffset(100, 40)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.shape.corner)
	corner.Parent = f

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.color.magnet
	stroke.Thickness = Theme.shape.stroke
	stroke.Transparency = Theme.shape.strokeTransparency
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = f

	-- the chrome highlight: a 1 px bright line along the top, which is what makes the panel
	-- read as a bevelled metal plate rather than a flat rectangle
	local highlight = Instance.new("Frame")
	highlight.Name = "Highlight"
	highlight.BackgroundColor3 = Theme.color.chrome
	highlight.BackgroundTransparency = 0.55
	highlight.BorderSizePixel = 0
	highlight.Size = UDim2.new(1, -2 * Theme.shape.corner, 0, 1)
	highlight.Position = UDim2.new(0.5, 0, 0, 1)
	highlight.AnchorPoint = Vector2.new(0.5, 0)
	highlight.ZIndex = 2
	highlight.Parent = f

	f.Parent = parent
	return f
end

--------------------------------------------------------------------------------
-- Text.
--------------------------------------------------------------------------------

export type TextOpts = {
	text: string?,
	font: Font?,
	color: Color3?,
	align: Enum.TextXAlignment?,
	scaled: boolean?,
	size: number?,
}

function Components.label(name: string, parent: Instance, opts: TextOpts?): TextLabel
	local o: TextOpts = opts or {}
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Text = o.text or ""
	l.FontFace = o.font or Theme.font.label
	l.TextColor3 = o.color or Theme.color.text
	l.TextXAlignment = o.align or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.RichText = true
	if o.scaled ~= false then
		l.TextScaled = true
		local c = Instance.new("UITextSizeConstraint")
		c.MinTextSize = MIN_TEXT
		c.MaxTextSize = o.size or 48
		c.Parent = l
	else
		l.TextSize = o.size or 18
	end
	l.Parent = parent
	return l
end

--------------------------------------------------------------------------------
-- Bars. Flow progress and Scrap capacity are both "a numerator over a denominator".
--------------------------------------------------------------------------------

export type Bar = {
	frame: Frame,
	fill: Frame,
	--- `n` and `of` come from the SERVER. This function does not compute either of them.
	set: (self: Bar, n: number, of: number) -> (),
	setColor: (self: Bar, c: Color3) -> (),
}

--- ⚠️ Takes a numerator and a denominator, never a ratio. `StatsChanged` already carries
--- `flowProgress`/`flowNeeded` and `scrap`/`capacity` -- a client that divides them itself is
--- one refactor away from deriving a stat the server owns.
function Components.bar(name: string, parent: Instance, color: Color3): Bar
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = Theme.color.hazardBlack
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Size = UDim2.new(1, 0, 0, 6)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = frame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	frame.Parent = parent

	local bar: Bar
	bar = {
		frame = frame,
		fill = fill,
		set = function(_self, n, of)
			local ratio = if of > 0 then math.clamp(n / of, 0, 1) else 0
			TweenService:Create(fill, Theme.motion.fade, { Size = UDim2.fromScale(ratio, 1) }):Play()
		end,
		setColor = function(_self, c)
			TweenService:Create(fill, Theme.motion.fade, { BackgroundColor3 = c }):Play()
		end,
	}
	return bar
end

--------------------------------------------------------------------------------
-- Counters: count up, then punch.
--------------------------------------------------------------------------------

export type Counter = {
	label: TextLabel,
	set: (self: Counter, value: number) -> (),
	--- Set without animating -- for the first value, and after a respawn.
	snap: (self: Counter, value: number) -> (),
	--- Re-run the format function at the value already displayed.
	---
	--- ⚠️ Needed because a counter's text can depend on something OTHER than its own value --
	--- the scrap readout renders "72 / 100", and the capacity half moves when the player buys
	--- an upgrade while the scrap half does not. Without this, `set` short-circuits on an
	--- unchanged value and the new capacity is never drawn.
	refresh: (self: Counter) -> (),
}

type CounterState = {
	label: TextLabel,
	scale: UIScale,
	format: (number) -> string,
	shown: number,
	target: number,
	speed: number,
	lastPunch: number,
	primed: boolean,
}

local counters: { CounterState } = {}
local counterLoop: RBXScriptConnection? = nil

local function punch(st: CounterState)
	local now = os.clock()
	-- ⚠️ MEASURED CONSTRAINT, not taste. A MAGNET RUSH banks a batch roughly every 0.25 s and
	-- Coins changes with every one of them. Punching per change makes the number vibrate, which
	-- reads as a broken label rather than as fast income -- and it is the single most visible
	-- element on the screen while it happens.
	if now - st.lastPunch < Theme.motion.punchCooldown then
		return
	end
	st.lastPunch = now
	st.scale.Scale = Theme.motion.punchScale
	TweenService:Create(st.scale, Theme.motion.punch, { Scale = 1 }):Play()
end

local function stepCounters(dt: number)
	for _, st in ipairs(counters) do
		if st.shown ~= st.target then
			local delta = st.target - st.shown
			local step = st.speed * dt
			if math.abs(delta) <= step or step <= 0 then
				st.shown = st.target
			else
				st.shown += (if delta > 0 then step else -step)
			end
			st.label.Text = st.format(st.shown)
		end
	end
end

--- A number that travels to its new value and then snaps back from a scale punch.
---
--- `format` receives the CURRENTLY DISPLAYED value, which is fractional mid-travel -- round it
--- there, not here, so a counter of a non-integer stat is still possible later.
function Components.counter(name: string, parent: Instance, format: ((number) -> string)?, opts: TextOpts?): Counter
	local label = Components.label(name, parent, opts)

	-- ⚠️ The punch scales the label about its own ANCHOR POINT, whatever the caller set -- it does
	-- not force a central one, and an earlier comment here claimed it required one. Callers anchor
	-- these to an edge on purpose (the scrap readout is right-aligned so its digits do not crawl as
	-- the number widens), so the punch grows from that edge. Cosmetic, and stated rather than
	-- asserted as a rule nothing enforces.
	local scale = Instance.new("UIScale")
	scale.Parent = label

	local st: CounterState = {
		label = label,
		scale = scale,
		format = format or function(v)
			return tostring(math.floor(v + 0.5))
		end,
		shown = 0,
		target = 0,
		speed = 0,
		lastPunch = 0,
		primed = false,
	}
	table.insert(counters, st)
	-- ⚠️ Pruned on destroy. `counters` is module-level and `stepCounters` walks all of it every
	-- Heartbeat, so a screen that rebuilds its readouts would leave the loop iterating dead labels
	-- forever -- the same unbounded-growth shape the `Layout.observe` cleanup above exists to stop.
	label.Destroying:Connect(function()
		local i = table.find(counters, st)
		if i then
			table.remove(counters, i)
		end
	end)

	-- ⚠️ ONE loop for every counter in the game, started on the first one. Per-counter
	-- `TweenService` calls on a value that changes four times a second cancel and restart each
	-- other, and per-counter Heartbeat connections are a leak with a long fuse.
	if not counterLoop then
		counterLoop = RunService.Heartbeat:Connect(stepCounters)
	end

	local counter: Counter
	counter = {
		label = label,
		set = function(_self, value)
			if not st.primed then
				counter:snap(value)
				return
			end
			if value == st.target then
				return
			end
			st.target = value
			st.speed = math.abs(value - st.shown) / math.max(0.01, Theme.motion.countUp)
			punch(st)
		end,
		snap = function(_self, value)
			st.target = value
			st.shown = value
			st.primed = true
			st.label.Text = st.format(value)
		end,
		refresh = function(_self)
			st.label.Text = st.format(st.shown)
		end,
	}
	return counter
end

--------------------------------------------------------------------------------
-- Buttons.
--------------------------------------------------------------------------------

--- ⚠️ Built on demand and left parented to SoundService, so a UI sound is 2D and does not
--- attenuate with the camera. Returns silently when the slot is empty -- which is the whole
--- point of the no-placeholder rule: the button still works, and `SoundKit.missing()` names the
--- empty slot at every startup until a human fills it.
local pressSound: Sound? = nil
local function playPress()
	if pressSound == nil then
		pressSound = SoundKit.build(SoundKit.UI.Press, SoundService, "UiPress")
	end
	local s = pressSound
	if s then
		s:Play()
	end
end

export type ButtonOpts = {
	text: string?,
	color: Color3?, -- the accent: stroke, and the text
	onActivated: (() -> ())?,
	--- Set false only for a control that is deliberately below the tap floor, and say why.
	enforceTapTarget: boolean?,
	--- The minimum this button may shrink to. Defaults to `Layout.tapTarget()` -- our preferred
	--- 58 px, scaled to the canvas.
	---
	--- ⚠️ Pass `Layout.TAP_FLOOR` for a control that must fit a list, and only then. A minimum
	--- is not a suggestion: `UISizeConstraint.MinSize` SILENTLY OVERRIDES the size you set.
	--- MEASURED: the upgrade rows were computed at 47 px so four would fit a 207 px list, the
	--- `Size` was written correctly, and they still rendered at 56.9 -- the constraint put them
	--- straight back and the fourth row stayed below the fold. The property edited was right;
	--- something else won (mobile §4a.8). Always read `AbsoluteSize` back.
	tapFloor: number?,
}

--- The only way to make a button. Pressed state + scale tween + sound + tap floor, always.
function Components.button(name: string, parent: Instance, opts: ButtonOpts): TextButton
	local accent = opts.color or Theme.color.magnet

	local b = Instance.new("TextButton")
	b.Name = name
	b.AutoButtonColor = false -- we do our own, so the pressed state is ours and is consistent
	b.BackgroundColor3 = Theme.color.panel
	b.BackgroundTransparency = Theme.shape.panelTransparency
	b.BorderSizePixel = 0
	b.Text = opts.text or ""
	b.FontFace = Theme.font.data
	b.TextColor3 = accent
	b.TextScaled = true
	b.Size = UDim2.fromOffset(120, Layout.tapTarget())

	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MinTextSize = MIN_TEXT
	textConstraint.MaxTextSize = 28
	textConstraint.Parent = b

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.shape.corner)
	corner.Parent = b

	local stroke = Instance.new("UIStroke")
	stroke.Color = accent
	stroke.Thickness = Theme.shape.stroke
	stroke.Transparency = Theme.shape.strokeTransparency
	stroke.Parent = b

	local scale = Instance.new("UIScale")
	scale.Parent = b

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, Theme.shape.pad)
	padding.PaddingRight = UDim.new(0, Theme.shape.pad)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = b

	-- ⚠️ EVERY tap target clears the floor, and the floor comes from the MEASURED canvas.
	-- A constant here would be the exact bug the mobile skill's §2 is about.
	if opts.enforceTapTarget ~= false then
		local sizeConstraint = Instance.new("UISizeConstraint")
		sizeConstraint.Parent = b
		local stop = Layout.observe(function()
			local t = opts.tapFloor or Layout.tapTarget()
			sizeConstraint.MinSize = Vector2.new(t, t)
		end)
		-- ⚠️ Destroying the button does NOT remove its observer. Without this, a screen that
		-- rebuilds its buttons grows the observer list without limit and keeps every destroyed
		-- instance alive through the closure -- a leak that a short test cannot see.
		b.Destroying:Connect(stop)
	end

	--- ⚠️ Pressed state is tracked per `InputObject`, not on `MouseButton1Down`/`Up`. Roblox
	--- routes only the FIRST active touch through mouse emulation, so with two thumbs down a
	--- second button may never see its release and would stay visually held forever.
	local held = 0
	local function setHeld(on: boolean)
		local target = if on then 0.94 else 1
		TweenService:Create(scale, Theme.motion.press, { Scale = target }):Play()
		TweenService:Create(stroke, Theme.motion.press, {
			Transparency = if on then 0 else Theme.shape.strokeTransparency,
		}):Play()
	end

	local pressedFwd: { [InputObject]: true } = {}
	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressedFwd[input] = true
			held += 1
			setHeld(true)
		end
	end)
	local function release()
		if held > 0 then
			held -= 1
			if held == 0 then
				setHeld(false)
			end
		end
	end
	b.InputEnded:Connect(function(input)
		if pressedFwd[input] then
			pressedFwd[input] = nil
			release()
		end
	end)
	--- A finger that slides OFF the button still has to release it.
	---
	--- 🔴 NOT `MouseLeave`. The mobile skill §7 names it alongside `MouseButton1Down/Up` as not
	--- multi-touch capable: Roblox routes only the FIRST active touch through mouse emulation. With
	--- two fingers down, a second finger that presses this button and slides off fires neither the
	--- button's `InputEnded` nor `MouseLeave`, so `held` never returns to zero and the button sits
	--- visually pressed for the rest of the session.
	---
	--- The service-level signal fires for every `InputObject` regardless of which finger owns it,
	--- which is the prescribed fallback. It is filtered to the inputs this button actually took,
	--- so a release somewhere else on the screen cannot clear a genuine press here.
	local serviceRelease = UserInputService.InputEnded:Connect(function(input)
		if pressedFwd[input] then
			pressedFwd[input] = nil
			release()
		end
	end)
	b.Destroying:Connect(function()
		serviceRelease:Disconnect()
	end)

	b.Activated:Connect(function()
		playPress()
		if opts.onActivated then
			opts.onActivated()
		end
	end)

	b.Parent = parent
	return b
end

return Components
