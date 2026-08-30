--!strict
--[[
	Layout — the screen as it ACTUALLY IS on this device, re-read whenever it changes.

	🔴 THE RULE THIS FILE EXISTS TO ENFORCE: a phone layout is measured, not reasoned about
	(decision 0012). Four rounds of rework on another game in this workspace came from sizing
	UI against a desktop viewport and finding out on hardware.

	Three facts this module supplies, none of which can be guessed:

	1. **`Camera.ViewportSize` is not the screenshot's pixel size.** Measured on a phone preset:
	   viewport 666 x 374, usable canvas 666 x 316 after insets, while the device screenshot was
	   ~1536 x 710. A pixel value is therefore ~2.3x larger relative to the canvas than any
	   desktop test suggests, which is why `Layout.size` takes a FRACTION and clamps, and why a
	   bare `UISizeConstraint.MinSize` tuned on a desktop is a bug waiting for a device.

	2. **Roblox already owns part of the screen.** `DynamicThumbstickFrame` reaches x = 266 of a
	   666-wide canvas -- the whole bottom-left quadrant is movement -- and the jump button owns
	   the bottom-right. `Layout.reserved()` reads Roblox's OWN rectangles rather than repeating
	   those numbers, so the day Roblox moves a control we move with it.

	   ⚠️ Diff against EVERY `TouchGui` child, never against the one that looks like the control.
	   `ThumbstickStart` is only the stick's resting dot (74x74); the dynamic stick spawns
	   wherever the thumb lands, and its frame is more than twice as wide.

	3. **The canvas changes.** Orientation, the Device Emulator, a resized window. Everything
	   here re-fires on `AbsoluteSize`, so those are free rather than three separate bugs.

	Sources: the shared `mobile` skill §1-3, §6 · decision 0012 · PITFALLS #30
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Layout = {}

export type Rect = {
	name: string,
	minX: number,
	minY: number,
	maxX: number,
	maxY: number,
}

--- Our own stricter target for a gameplay control. iOS says 44 pt, Android 48 dp; a magnet game
--- is played with a thumb over a moving world, so 58 is the goal and 44 is the documented floor
--- we degrade to only when the canvas genuinely cannot hold it.
Layout.TAP_PREFERRED = 58
Layout.TAP_FLOOR = 44

assert(RunService:IsClient(), "Ui.Layout is client-only -- the server cannot see a canvas")

local player = Players.LocalPlayer

--------------------------------------------------------------------------------
-- The metrics probe. One hidden ScreenGui whose only job is to report the usable canvas.
--------------------------------------------------------------------------------

--- ⚠️ `Camera.ViewportSize` is NOT the usable canvas -- insets take a real bite out of it, and
--- on a notched phone the bite is not symmetric. The only honest source is a ScreenGui with the
--- inset mode our real UI uses, asked for its own `AbsoluteSize`. MEASURED on the phone preset:
--- viewport 666 x 374, `GetGuiInset` (0, 58), CoreUISafeInsets canvas **666 x 316**.
---
--- 🔴 `Enabled` MUST STAY TRUE. A disabled `ScreenGui` does not lay out, and reports the
--- default **800 x 600** forever -- measured, not assumed: the first version of this file set
--- `Enabled = false` with a comment claiming AbsoluteSize was reported regardless, and every
--- element in the game was sized against 800 x 600 on a 666 x 316 screen. It draws nothing
--- because it has no children, which is the correct way to make it invisible.
local metrics: ScreenGui do
	local gui = Instance.new("ScreenGui")
	gui.Name = "UiMetrics"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.Enabled = true -- see above: a disabled ScreenGui reports 800x600 and never updates
	gui.Parent = player:WaitForChild("PlayerGui")
	metrics = gui
end

function Layout.isTouch(): boolean
	return UserInputService.TouchEnabled
end

--- ⚠️ Touch and desktop are not exclusive. A Surface or a touchscreen laptop reports both, and
--- the thumbstick only exists when there is no keyboard driving the character. The reservation
--- that matters is whether Roblox actually PAINTED its controls, which `reserved()` answers by
--- looking, so this is only ever used to choose a layout, never to decide a rectangle is free.
function Layout.isTouchOnly(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

--- The usable canvas, in the coordinate space every `AbsoluteSize` below shares.
function Layout.canvas(): Vector2
	return metrics.AbsoluteSize
end

--- The raw viewport, for the record. Do not size anything from it -- see the header.
function Layout.viewport(): Vector2
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.zero
end

function Layout.guiInset(): Vector2
	local top = GuiService:GetGuiInset()
	return top
end

--------------------------------------------------------------------------------
-- Sizing. A fraction of the measured canvas, clamped -- never a bare pixel floor.
--------------------------------------------------------------------------------

--- Resolve a size the way this game is allowed to: as a fraction of the canvas, with a
--- preferred pixel value that is only ever a CEILING on a large screen and a floor that is
--- itself capped as a fraction.
---
--- `prefer` is what it should be on a comfortable screen; `fraction` is what it is allowed to
--- grow or shrink to; `floor` is the smallest it may legally be. The floor is clamped to
--- `maxFraction` of the canvas dimension, which is the guard that stops a desktop-tuned
--- constant from eating a phone screen.
function Layout.size(available: number, fraction: number, prefer: number, floor: number?, maxFraction: number?): number
	local wanted = available * fraction
	local hardFloor = floor or 0
	local ceiling = available * (maxFraction or 0.6)
	-- the floor may never exceed the ceiling: on a 316px canvas a 420px "minimum" is not a
	-- minimum, it is the whole screen
	hardFloor = math.min(hardFloor, ceiling)
	return math.clamp(math.min(wanted, prefer), hardFloor, ceiling)
end

--- The tap size this canvas can actually afford, in pixels. Prefers 58, accepts 44, and never
--- exceeds 18% of the canvas height.
function Layout.tapTarget(): number
	local h = Layout.canvas().Y
	if h <= 0 then
		return Layout.TAP_PREFERRED
	end
	local ceiling = h * 0.18
	if Layout.TAP_PREFERRED <= ceiling then
		return Layout.TAP_PREFERRED
	end
	return math.max(Layout.TAP_FLOOR, math.min(Layout.TAP_PREFERRED, ceiling))
end

--------------------------------------------------------------------------------
-- What Roblox has already taken.
--------------------------------------------------------------------------------

local function rectOf(name: string, obj: GuiObject): Rect
	local p, s = obj.AbsolutePosition, obj.AbsoluteSize
	return { name = name, minX = p.X, minY = p.Y, maxX = p.X + s.X, maxY = p.Y + s.Y }
end

--- A rect this big is a CONTAINER, not a control, and must not be treated as a reservation.
---
--- 🔴 MEASURED: `TouchGui.TouchControlFrame` is `x 0..666, y 0..316` -- exactly the whole
--- canvas. It holds the thumbstick and the jump button and reserves nothing itself. Counting it
--- would mark every element on the screen as colliding, which is the failure mode the `mobile`
--- skill warns about: a naive "any overlap is a bug" check is worse than useless because it
--- cries wolf, and the first thing anyone does with a checker that always fails is stop reading
--- it. Below this threshold sit the rects that are real: `DynamicThumbstickFrame` covers 54 %
--- of the canvas and IS a genuine reservation.
local CONTAINER_AREA_FRACTION = 0.9

--- Every rectangle Roblox's own touch controls occupy, by name.
---
--- ⚠️ Returns every painted `TouchGui` descendant except whole-canvas containers -- NOT a
--- curated list of the ones that look like controls. Job #099 measured against
--- `ThumbstickStart` -- the resting dot, 74x74 -- declared the hotbar clean, and it was still
--- sitting inside the live `DynamicThumbstickFrame`, which runs to x = 266. The mistake is not
--- reading the wrong number, it is choosing which number to read.
function Layout.reserved(): { Rect }
	local out: { Rect } = {}
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
	if not touchGui then
		return out -- desktop, or the controls have not been created yet
	end
	--- 🔴 `GuiObject.Visible` is NOT "the player can see this". It is one object's own flag, and
	--- a child of a hidden parent still reports `Visible = true`.
	---
	--- MEASURED: opening a modal sets `UserInputService.ModalEnabled = true`, which takes
	--- Roblox's controls off the screen -- confirmed in a screenshot, the thumbstick and jump
	--- button were gone. But `DynamicThumbstickUIModifier`, `ThumbstickStart` and `ThumbstickEnd`
	--- all still reported `Visible = true`, so a per-object check counted three reservations that
	--- were not on the screen and flagged all four upgrade rows as colliding with a control the
	--- player could not see. A false alarm from a collision checker is not harmless: it is how
	--- people learn to ignore the one real one.
	local function painted(obj: GuiObject): boolean
		local node: Instance? = obj
		while node and node ~= touchGui do
			if node:IsA("GuiObject") and not node.Visible then
				return false
			end
			node = node.Parent
		end
		return true
	end

	if touchGui:IsA("ScreenGui") and not touchGui.Enabled then
		return out -- the whole control set is switched off, e.g. while a modal is up
	end

	local canvas = Layout.canvas()
	local canvasArea = math.max(1, canvas.X * canvas.Y)
	for _, d in ipairs(touchGui:GetDescendants()) do
		if d:IsA("GuiObject") and d.AbsoluteSize.X > 1 and d.AbsoluteSize.Y > 1 and painted(d) then
			local area = d.AbsoluteSize.X * d.AbsoluteSize.Y
			if area / canvasArea < CONTAINER_AREA_FRACTION then
				table.insert(out, rectOf(d.Name, d))
			end
		end
	end
	return out
end

--- Are these measurements worth believing yet?
---
--- 🔴 MEASURED FAILURE: at the moment `StarterPlayerScripts` runs, the camera reports a
--- viewport of **1 x 1**, the canvas has not been laid out, and `TouchGui` does not exist. The
--- first version of this HUD logged "layout clean -- canvas 800x600 ... reserved=0 rects" and
--- that line was true and meaningless: a collision check against zero rectangles passes on
--- every screen, broken or not (PITFALLS #2, #54).
---
--- So nothing may CLAIM a layout is verified until this returns true.
function Layout.ready(): (boolean, string)
	local c = Layout.canvas()
	if c.X <= 1 or c.Y <= 1 then
		return false, ("canvas is %dx%d -- not laid out yet"):format(c.X, c.Y)
	end
	local v = Layout.viewport()
	if v.X <= 1 or v.Y <= 1 then
		return false, ("viewport is %dx%d -- the camera has not been sized yet"):format(v.X, v.Y)
	end
	if Layout.isTouch() and #Layout.reserved() == 0 then
		return false, "touch device but TouchGui has no rects yet -- a collision check would be vacuous"
	end
	return true, "ready"
end

--------------------------------------------------------------------------------
-- Finding the space Roblox has NOT taken.
--------------------------------------------------------------------------------

--- The widest horizontal span in the bottom `stripHeight` pixels that no reserved rect touches.
---
--- ⚠️ This is why the bottom-centre readout is not at the canvas centre. MEASURED: the
--- thumbstick frame runs to x = 266 and the jump button starts at x = 571, so the free bottom
--- band is x 266..571 and its centre is **x = 418, not the canvas centre 333**. Anything
--- "centred" at the bottom of a phone is sitting in the movement control.
---
--- Derived from the live rects rather than from those numbers, so the day Roblox moves a
--- control the layout moves with it.
---
--- Returns `(from, to, known)`. ⚠️ **`known` is not decoration.** On a touch device before the
--- controls exist there are no rectangles, and "no obstacles" is indistinguishable from "the whole
--- width is free" — which is how the scrap readout ended up centred on the thumbstick. A caller
--- that ignores `known` will place an element in a band it has not actually measured.
function Layout.freeBottomSpan(stripHeight: number): (number, number, boolean)
	local canvas = Layout.canvas()
	local top = canvas.Y - stripHeight

	local rects, known = Layout.reservedForLayout()
	if not known then
		return 0, canvas.X, false
	end

	local blocked: { { number } } = {}
	for _, r in ipairs(rects) do
		if r.maxY > top and r.minY < canvas.Y then
			table.insert(blocked, { math.max(0, r.minX), math.min(canvas.X, r.maxX) })
		end
	end
	if #blocked == 0 then
		return 0, canvas.X, true
	end
	table.sort(blocked, function(a, b)
		return a[1] < b[1]
	end)

	local bestFrom, bestTo = 0, 0
	local cursor = 0
	local function consider(from: number, to: number)
		if to - from > bestTo - bestFrom then
			bestFrom, bestTo = from, to
		end
	end
	for _, b in ipairs(blocked) do
		if b[1] > cursor then
			consider(cursor, b[1])
		end
		cursor = math.max(cursor, b[2])
	end
	consider(cursor, canvas.X)
	return bestFrom, bestTo, true
end

--- 🔴 THE LAST KNOWN CONTROLS, WHICH IS NOT THE SAME QUESTION AS "what is painted right now".
---
--- `reserved()` answers *now*, which is what an audit needs. A LAYOUT needs something else: a
--- reservation that survives the controls being switched off for a moment.
---
--- **The bug this exists to stop.** Opening the upgrade panel sets `ModalEnabled = true`, which
--- makes `TouchGui.Enabled` false, so `reserved()` correctly returns nothing. The layout then
--- re-ran, `freeBottomSpan` saw no obstacles, concluded the entire width was free, and re-centred
--- the scrap readout on the canvas centre — x 333, the exact number this module exists to avoid.
--- Closing the panel restored the controls but nothing re-ran the layout, so the readout sat
--- 23 px inside `DynamicThumbstickFrame` **for the rest of the session**.
---
--- A control that is temporarily hidden has not moved. Layout decisions use this; audits do not.
local lastReserved: { Rect } = {}

function Layout.reservedForLayout(): ({ Rect }, boolean)
	local now = Layout.reserved()
	if #now > 0 then
		lastReserved = now
		return now, true
	end
	if #lastReserved > 0 then
		return lastReserved, true -- temporarily hidden; they have not moved
	end
	-- Never seen any. On desktop that is the truth; on touch it means the controls have not been
	-- built yet, and the caller must NOT read that as "the whole screen is free".
	return {}, not Layout.isTouch()
end

--- Does this rectangle collide with anything Roblox owns? Returns the offender's name, or nil.
function Layout.collides(minX: number, minY: number, maxX: number, maxY: number): string?
	for _, r in ipairs(Layout.reserved()) do
		if minX < r.maxX and maxX > r.minX and minY < r.maxY and maxY > r.minY then
			return r.name
		end
	end
	return nil
end

--- Convenience: the same question asked about a live element.
function Layout.collidesWith(obj: GuiObject): string?
	local p, s = obj.AbsolutePosition, obj.AbsoluteSize
	return Layout.collides(p.X, p.Y, p.X + s.X, p.Y + s.Y)
end

--------------------------------------------------------------------------------
-- Reacting to change.
--------------------------------------------------------------------------------

local listeners: { (Vector2) -> () } = {}

--- Call `fn` now with the current canvas, and again every time it changes. Returns a
--- disconnect function.
---
--- ⚠️ Calling it IMMEDIATELY is the point. A layout that only runs on the change event is
--- correct after the first rotation and wrong until then, which on a phone that never rotates
--- is wrong forever.
function Layout.observe(fn: (Vector2) -> ()): () -> ()
	table.insert(listeners, fn)
	fn(Layout.canvas())
	return function()
		local i = table.find(listeners, fn)
		if i then
			table.remove(listeners, i)
		end
	end
end

local function fire()
	local c = metrics.AbsoluteSize
	for _, fn in ipairs(listeners) do
		task.spawn(fn, c)
	end
end

metrics:GetPropertyChangedSignal("AbsoluteSize"):Connect(fire)

--- ⚠️ The canvas is not the only thing that arrives late. `TouchGui` is built by Roblox's own
--- PlayerModule AFTER our scripts run -- measured: `reserved = 0 rects` at the moment the HUD
--- was constructed, and the controls were all there a second later. A layout computed before
--- the controls exist has nothing to avoid, so it happily places an element on top of them and
--- never reconsiders.
---
--- So the arrival of the controls is itself a layout event. Fired once, on a debounce, because
--- the PlayerModule adds a dozen descendants in quick succession.
do
	local playerGui = player:WaitForChild("PlayerGui")
	local pending = false
	local function touchControlsChanged()
		if pending then
			return
		end
		pending = true
		task.delay(0.1, function()
			pending = false
			fire()
		end)
	end
	playerGui.DescendantAdded:Connect(function(d)
		if d:IsA("GuiObject") and d:FindFirstAncestor("TouchGui") then
			touchControlsChanged()
		end
	end)
	local existing = playerGui:FindFirstChild("TouchGui")
	if existing then
		existing.DescendantAdded:Connect(touchControlsChanged)
	end
end

--- Re-run every layout listener now. For a caller that has changed something the layout
--- depends on and cannot wait for a signal.
function Layout.refresh()
	fire()
end

--- A one-line description of the screen, for a log or a dev command.
---
--- ⚠️ Names the reserved rects rather than counting them. "reserved=3" and "reserved=0" look
--- equally healthy in a log; "reserved=none" next to a touch canvas does not.
function Layout.describe(): string
	local c, v = Layout.canvas(), Layout.viewport()
	local reserved = Layout.reserved()
	local names = {}
	for _, r in ipairs(reserved) do
		table.insert(names, ("%s[%d..%d,%d..%d]"):format(r.name, r.minX, r.maxX, r.minY, r.maxY))
	end
	local ok, why = Layout.ready()
	return ("canvas %dx%d | viewport %dx%d | inset %d | touch=%s | tap=%dpx | ready=%s%s | reserved: %s"):format(
		c.X, c.Y, v.X, v.Y, Layout.guiInset().Y, tostring(Layout.isTouch()), Layout.tapTarget(),
		tostring(ok), ok and "" or (" (" .. why .. ")"),
		#names > 0 and table.concat(names, " ") or "NONE")
end

return Layout
