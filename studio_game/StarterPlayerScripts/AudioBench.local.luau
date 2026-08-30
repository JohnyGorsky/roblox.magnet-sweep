--!strict
--[[
	AudioBench — audition a candidate sound IN THE SLOT IT WILL OCCUPY. Press F3.

	Fourteen slots are specced and empty (assets/registry/sounds.md). Filling them means listening
	to candidates, and the shared workspace registry records exactly how that goes wrong: two clips
	were accepted by reading their category, and rejected the moment they were finally heard
	properly. **The audition method was the other half of that mistake** — they had been judged
	through a slot that plays at the volume of thunder 600 studs away, far too quiet and distant to
	tell a ping from a texture.

	So this plays a candidate through the REAL slot: the real volume, the real looping, the real
	rolloff, parented to the magnet tip where the sound will actually live, and pitched by a Flow
	tier you can set — because the pitch rise IS the Flow feedback (§15), and a family sound has to
	survive being played five semitones up.

	⚠️ Builds NOTHING unless the server says this player is authorised. The check is an early
	return before any Instance is created, not a `.Enabled = false` — a ScreenGui that exists can be
	re-enabled by something else, and a HUD gate that was only a flag took three attempts to make
	stick on another project in this workspace.

	⚠️ `.local.luau` -> LocalScript. A `.client.luau` here runs TWICE (job 002).

	Sources: docs/systems/audio/README.md · assets/registry/sounds.md · GROUND-RULES §4
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- ⚠️ The gate, before anything exists.
if player:GetAttribute("DevAuthorised") ~= true then
	local granted = false
	local conn
	conn = player:GetAttributeChangedSignal("DevAuthorised"):Connect(function()
		if player:GetAttribute("DevAuthorised") == true then
			granted = true
		end
	end)
	local deadline = os.clock() + 12
	while not granted and os.clock() < deadline do
		task.wait(0.25)
	end
	conn:Disconnect()
	if not granted then
		return
	end
end

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local Magnet = require(Config:WaitForChild("Magnet", 20))
local SoundKit = require(ReplicatedStorage:WaitForChild("SoundKit", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("AudioBench")

local INK = Color3.fromHex("#0E1116")
local PANEL = Color3.fromHex("#161C24")
local ROW = Color3.fromHex("#1E2732")
local TEXT = Color3.fromHex("#E6ECF2")
local DIM = Color3.fromHex("#8FA0B2")
local RED = Color3.fromHex("#E03A2F")
local CYAN = Color3.fromHex("#41D8FF")
local GOOD = Color3.fromHex("#4ADE80")

--------------------------------------------------------------------------------
-- Where a preview plays: the magnet tip, so distance and rolloff are real.
--------------------------------------------------------------------------------

local function host(): Instance
	local char = player.Character
	local rig = char and char:FindFirstChild("MagnetRig")
	local tip = rig and rig:FindFirstChild("Tip")
	if tip and tip:IsA("BasePart") then
		return tip
	end
	-- no magnet yet (dead, still spawning): fall back to the head so it is still positional
	local head = char and char:FindFirstChild("Head")
	return (head :: any) or workspace
end

local playing: Sound? = nil
local flowTier = 0

--- ⚠️ TWO MODES, because one is not enough and the first version only had one.
---
--- IN SLOT plays at the slot's real volume, on the magnet, with real rolloff -- which is how
--- you judge whether a sound SITS right in the mix. But `MAGNET.Hum` is mixed at 0.18, the
--- quietest slot in the game, and from a normal third-person camera 15 studs back that is
--- inaudible: three different hums all "did not work" because none of them could be heard.
---
--- SOLO plays the file flat and 2D at full volume, which is how you judge WHAT THE FILE IS.
--- Judging a candidate you cannot hear is not judging it.
local solo = false

--- Multiplier on top of the slot's volume, so a level can be FOUND here rather than guessed in
--- the config. Whatever reads right, tell it to Claude and it goes in the slot.
local volMult = 1.0

--- ⚠️ Each slot remembers ITS OWN candidate. The first version fell back to one shared text
--- box for every empty slot, so after clicking a single candidate every other row's play button
--- replayed that same clip -- three different families in a row producing an identical sound,
--- which reads as a broken bench rather than as "you are hearing the same file three times".
--- The shared box is now only the fallback for a slot you have not given a candidate to, and
--- every row states the id it will actually play.
local trial: { [string]: string } = {}

local function stop()
	if playing then
		playing:Stop()
		playing:Destroy()
		playing = nil
	end
end

--- Which id a row will actually play: the slot's real id if it has one, else the candidate
--- pinned to that row, else whatever is in the shared box.
local function idFor(path: string, slot: any, boxText: string?): (string?, string)
	if slot.id ~= "" then
		return slot.id, "the slot's own sound"
	end
	local pinned = trial[path]
	if pinned then
		return pinned, "suggested"
	end
	local typed = SoundKit.normaliseId(boxText)
	if typed then
		return typed, "the id in the box"
	end
	return nil, "nothing"
end

--- Play `slot` with an optional candidate id, exactly as the game would play it.
local function audition(path: string, slot: any, overrideId: string?): string
	stop()
	local s = SoundKit.preview(slot, host(), overrideId)
	if not s then
		return ("%s is empty — paste an id, or tap one of its candidates"):format(path)
	end
	-- the pitch rise IS the Flow feedback, so audition it at the tier you care about
	s.PlaybackSpeed = SoundKit.pitchFor(slot.pitch, flowTier, Magnet.FLOW.PITCH_PER_TIER)
	if solo then
		-- flat, 2D, full: reparenting off a BasePart removes positional attenuation entirely
		s.Parent = script
		s.Volume = math.min(1, slot.volume * 4 * volMult)
	else
		s.Volume = math.clamp(slot.volume * volMult, 0, 1)
	end
	playing = s
	-- clean up when it finishes on its own, not just when the next audition replaces it --
	-- otherwise every one-shot leaves its Sound parented to the magnet until you click again
	s.Ended:Once(function()
		if playing == s then
			playing = nil
		end
		s:Destroy()
	end)
	s:Play()
	Log.info("%s <- %s at flow tier %d (speed %.2f)", path, s.SoundId, flowTier, s.PlaybackSpeed)
	return ("%s  ·  %s  ·  vol %.2f  pitch x%.2f"):format(path, s.SoundId, s.Volume, s.PlaybackSpeed)
end

--------------------------------------------------------------------------------
-- The panel.
--------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "AudioBench"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 500
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Size = UDim2.new(0, 560, 0, 520)
root.Position = UDim2.new(0.5, -280, 0.5, -260)
root.BackgroundColor3 = PANEL
root.BorderSizePixel = 0
root.Parent = gui
Instance.new("UICorner").Parent = root

local stroke = Instance.new("UIStroke")
stroke.Color = CYAN
stroke.Transparency = 0.7
stroke.Parent = root

local function label(parent: Instance, text: string, size: UDim2, pos: UDim2, colour: Color3?, bold: boolean?)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = colour or TEXT
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextSize = 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = parent
	return l
end

label(root, "AUDIO BENCH", UDim2.new(1, -20, 0, 22), UDim2.new(0, 12, 0, 8), CYAN, true)
local status = label(root, "every row is preloaded with a suggestion — hit ▶ to hear it",
	UDim2.new(1, -20, 0, 18), UDim2.new(0, 12, 0, 28), DIM)

-- the id box
local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -150, 0, 30)
box.Position = UDim2.new(0, 12, 0, 52)
box.BackgroundColor3 = ROW
box.BorderSizePixel = 0
box.Text = ""
box.PlaceholderText = "paste a Creator Store id or URL here"
box.PlaceholderColor3 = DIM
box.TextColor3 = TEXT
box.Font = Enum.Font.Code
box.TextSize = 13
box.ClearTextOnFocus = false
box.Parent = root
Instance.new("UICorner").Parent = box

local function button(parent: Instance, text: string, size: UDim2, pos: UDim2, colour: Color3)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = colour
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = INK
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.AutoButtonColor = true
	b.Parent = parent
	Instance.new("UICorner").Parent = b
	return b
end

local soloBtn = button(root, "IN SLOT", UDim2.new(0, 62, 0, 22), UDim2.new(0, 12, 0, 84), ROW)
soloBtn.TextColor3 = TEXT
local volBtn = button(root, "VOL x1", UDim2.new(0, 62, 0, 22), UDim2.new(0, 78, 0, 84), ROW)
volBtn.TextColor3 = TEXT

local stopBtn = button(root, "STOP", UDim2.new(0, 60, 0, 30), UDim2.new(1, -72, 0, 52), RED)
stopBtn.TextColor3 = TEXT
stopBtn.MouseButton1Click:Connect(function()
	stop()
	status.Text = "stopped"
end)

-- flow tier stepper: the pitch rise is the Flow feedback, so it must be auditionable
local tierBtn = button(root, "FLOW 0", UDim2.new(0, 66, 0, 30), UDim2.new(1, -142, 0, 52), ROW)
tierBtn.TextColor3 = TEXT
tierBtn.MouseButton1Click:Connect(function()
	flowTier = (flowTier + 1) % (Magnet.FLOW.MAX_TIER + 1)
	tierBtn.Text = ("FLOW %d"):format(flowTier)
	status.Text = ("pitch x%.2f at tier %d"):format(
		SoundKit.pitchFor(1, flowTier, Magnet.FLOW.PITCH_PER_TIER), flowTier)
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -122)
scroll.Position = UDim2.new(0, 12, 0, 114)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = root

soloBtn.MouseButton1Click:Connect(function()
	solo = not solo
	soloBtn.Text = solo and "SOLO" or "IN SLOT"
	soloBtn.BackgroundColor3 = solo and CYAN or ROW
	soloBtn.TextColor3 = solo and INK or TEXT
	status.Text = solo
		and "SOLO — flat, 2D, loud. Judge WHAT the file is."
		or "IN SLOT — real volume and rolloff on the magnet. Judge how it SITS."
end)

local VOL_STEPS = { 1.0, 2.0, 4.0, 0.5 }
local volIndex = 1
volBtn.MouseButton1Click:Connect(function()
	volIndex = (volIndex % #VOL_STEPS) + 1
	volMult = VOL_STEPS[volIndex]
	volBtn.Text = ("VOL x%g"):format(volMult)
	status.Text = ("volume x%g — find a level that reads, then tell Claude the slot and the number"):format(volMult)
end)

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 4)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

--------------------------------------------------------------------------------

local order = 0
local function addSlotRow(path: string, slot: any)
	order += 1
	local shortlist = SoundKit.SHORTLIST[path]
	local extra = shortlist and #shortlist or 0

	-- ⚠️ Default the row to the first candidate -- Claude's pick. The first version left every
	-- empty slot with no candidate and fell back to one shared text box, so after clicking a
	-- single suggestion every other row replayed that same clip and three families in a row
	-- sounded identical. A row that cannot play anything is not a useful row.
	if shortlist and shortlist[1] and not trial[path] then
		trial[path] = SoundKit.normaliseId(shortlist[1].id)
	end

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, extra > 0 and (46 + extra * 20) or 46)
	row.BackgroundColor3 = ROW
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = scroll
	Instance.new("UICorner").Parent = row

	local filled = slot.id ~= ""
	label(row, path, UDim2.new(0, 150, 0, 18), UDim2.new(0, 10, 0, 5), filled and GOOD or TEXT, true)

	-- ⚠️ This label says WHICH ID THIS ROW WILL PLAY, never just "EMPTY". Without it, three
	-- empty rows all falling back to the same box looked like three broken sounds.
	local idLabel = label(row, "", UDim2.new(0, 250, 0, 16), UDim2.new(0, 164, 0, 6), RED)
	local function refresh()
		local id, why = idFor(path, slot, box.Text)
		if not id then
			idLabel.Text = "nothing to play — paste an id"
			idLabel.TextColor3 = RED
		else
			idLabel.Text = ("%s  (%s)"):format(id:match("%d+") or id, why)
			idLabel.TextColor3 = (slot.id ~= "" and GOOD) or (trial[path] and CYAN) or DIM
		end
	end
	refresh()
	box:GetPropertyChangedSignal("Text"):Connect(refresh)

	label(row, slot.brief, UDim2.new(1, -80, 0, 16), UDim2.new(0, 10, 0, 24), DIM)

	local play = button(row, "▶", UDim2.new(0, 34, 0, 28), UDim2.new(1, -44, 0, 6), CYAN)
	play.MouseButton1Click:Connect(function()
		local id = idFor(path, slot, box.Text)
		status.Text = audition(path, slot, id)
	end)

	-- one-tap candidates, each with the caveat that would disqualify it. Tapping one PINS it to
	-- this row, so the next row's play button is not silently the same clip.
	for i, cand in ipairs(shortlist or {}) do
		local b = button(row, ("%s  —  %s"):format(cand.id, cand.note),
			UDim2.new(1, -20, 0, 17), UDim2.new(0, 10, 0, 44 + (i - 1) * 20), PANEL)
		b.TextColor3 = DIM
		b.Font = Enum.Font.Code
		b.TextSize = 11
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.MouseButton1Click:Connect(function()
			trial[path] = SoundKit.normaliseId(cand.id)
			refresh()
			status.Text = audition(path, slot, trial[path])
		end)
	end
end

label(scroll, "THE NINE OBJECT FAMILIES — pitched up by Flow", UDim2.new(1, -8, 0, 18), UDim2.new(), CYAN, true).LayoutOrder = 0
for _, name in ipairs({ "Bolt", "Coin", "Gear", "Spring", "Tool", "Barrel", "Vehicle", "Machine", "Rare" }) do
	addSlotRow("FAMILY." .. name, SoundKit.FAMILY[name])
end

order += 1
local hdr = label(scroll, "THE FIVE MAGNET STATES", UDim2.new(1, -8, 0, 18), UDim2.new(), CYAN, true)
hdr.LayoutOrder = order
for _, name in ipairs({ "Hum", "React", "Refuse", "Rush", "Full" }) do
	addSlotRow("MAGNET." .. name, SoundKit.MAGNET[name])
end

--------------------------------------------------------------------------------

local function setOpen(open: boolean)
	gui.Enabled = open
	if not open then
		stop()
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F3 then
		setOpen(not gui.Enabled)
		player:SetAttribute("DevBenchOpen", gui.Enabled)
	end
end)

-- ⚠️ A SECOND way in, on purpose. F3 needs an Fn chord on many laptops, and a panel whose
-- only door is a key the hardware might swallow is a tool nobody can open -- the same failure
-- as a tool nobody can call (PITFALLS #29). `dev("audio.bench")` toggles the same panel.
player:GetAttributeChangedSignal("DevBenchOpen"):Connect(function()
	setOpen(player:GetAttribute("DevBenchOpen") == true)
end)

Log.info("audio bench ready — press F3 (%d slots, %d still empty)",
	#SoundKit.all(), #SoundKit.missing())
