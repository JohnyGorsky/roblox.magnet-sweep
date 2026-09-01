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

	--- Added by job 015 for the diorama. The first four ARE in `Ui.Theme`, so they are real audited
	--- duplicates like the ones above -- `auditPalette` compares them.
	steel = Color3.fromHex("4A545E"), -- Theme.color.steelMid
	chrome = Color3.fromHex("B8C2CC"), -- Theme.color.chrome
	hazardDark = Color3.fromHex("14161C"), -- Theme.color.hazardBlack
	gold = Color3.fromHex("FFC21A"), -- Theme.color.arena
	repair = Color3.fromHex("FF7A1A"), -- Theme.color.repair
	--- ⚠️ These two have NO Theme token. `rust` is in style §2 and `Ui.Theme` simply does not expose
	--- it; `figure` is a one-off, dark enough to read as a silhouette and light enough not to be a
	--- hole in the picture. Same case as `barTrack` above -- they live here so that they are IN the
	--- audited table, and `NO_TOKEN` below states that their absence is deliberate.
	rust = Color3.fromHex("8A4B2A"),
	figure = Color3.fromHex("232B3A"),
}

--- 🔴 The entries that are deliberately NOT in `Ui.Theme`. Without this, `auditPalette`'s skip
--- branch could not tell "no token by design" from "somebody renamed the token" -- rename
--- `Theme.color.steelMid` and four colours would quietly stop being audited while the drift guard
--- went on reporting clean. That is the exact shape of PITFALLS #55-#61.
local PALETTE_NO_TOKEN = { barTrack = true, rust = true, figure = true }

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

--------------------------------------------------------------------------------
-- The plate. A blurred frame of the game's own concept art, under everything else.
--------------------------------------------------------------------------------

--- `assets/generated/loading-backdrop.png` -- `assets/concept_art/Arena.png` downscaled to 640x360,
--- Gaussian-blurred at radius 16 and darkened to 42 % brightness, then uploaded. It is the WORKSHOP,
--- which is the room the status line says the player is entering, so it is the right frame to be
--- looking at while they wait for it.
---
--- ⚠️ Blurred hard on purpose. Three strengths were rendered and compared: at radius 10 it still had
--- readable detail and fought the text, and at radius 26 it was indistinguishable from flat black.
---
--- 🔴 PARENTED FIRST, so it sits under the halo, the diorama and the scrim. Draw order inside
--- `backdrop` is child order.
---
--- ⚠️ Degrades safely. A freshly uploaded image is MODERATED, and until it passes it renders as
--- nothing for other players -- so this is a `Frame` behind an `ImageLabel`, not an image standing
--- in for the background. If the asset never loads, the player sees exactly the flat factory dark
--- this screen had before, and nothing else about the screen depends on it.
local plate = Instance.new("ImageLabel")
plate.Name = "Plate"
plate.Size = UDim2.fromScale(1, 1)
plate.BackgroundTransparency = 1
plate.BorderSizePixel = 0
plate.Image = "rbxassetid://88620361473282"
--- `Crop`, so a 16:9 plate covers both the 1.39 desktop canvas and the 1.78 phone one without
--- letterboxing. Blurred content has no detail to lose at the crop.
plate.ScaleType = Enum.ScaleType.Crop
plate.ImageTransparency = 0.18
plate.Parent = backdrop

--------------------------------------------------------------------------------
-- The diorama. §7: the player, a glowing magnet, scrap flying, a robot, a corridor.
--------------------------------------------------------------------------------

--- 🔴 MEASURED, NOT ASSUMED (job 015 probe, in Play, 2026-08-31): a `ViewportFrame` renders **no
--- Bloom, no `Beam` and no `ParticleEmitter`**. A `Neon` part inside one is a flat, hard-edged
--- colour in the very same frame in which the identical part out in the world blooms; a `Beam` and
--- a `ParticleEmitter`, both `Enabled` and inside the camera frustum, drew nothing at all.
---
--- So the whole §6 effect vocabulary -- *"arcs are always a `Beam`"*, sparks, and the Bloom pass
--- that style §3 says **is** the glow -- is unavailable in here. The glow is therefore PAINTED in
--- 2D behind the viewport instead of emitted by it, which is why this screen is three layers:
---
---   backdrop   flat factory dark, sinks input
---   glow       2D cyan halo, concentric circles, BEHIND the viewport
---   diorama    the 3D scene, on a TRANSPARENT background so the halo shows through
---
--- ⚠️ Every part below is `Instance.new`. This file runs in `ReplicatedFirst`, ahead of
--- `ReplicatedStorage`, so it cannot require `KitSpec`, clone a model, or call `MaterialKit`. The
--- materials are therefore chosen locally and deliberately: `Neon` for anything that must read as
--- lit, `Metal` for steel, `SmoothPlastic` for painted toy-factory surfaces.

--- 🔴 The magnet's transform lives HERE, above everything that depends on it, because two other
--- things are DERIVED from it rather than written down beside it: the halo's screen position and
--- the mouth the scrap flies into. Both were hand-written constants at one point and both drifted
--- the moment the magnet moved -- with nothing in the code contradicting itself.
---
--- ⚠️ `MAGNET_Y` is 2.9 and the scale 0.92. The magnet has to fit between the tagline above it and
--- the progress bar below, and both edges were found by MEASURING the projection, not by eye:
--- at 3.5 the top of the arm nub landed at screen y 0.349 against a tagline box that ends at 0.357,
--- so it overlapped by about 3 px -- on every device, since `FieldOfView` is vertical and the span
--- is therefore identical on the 1.39 desktop canvas and the 1.78 phone one. 2.9 puts the span at
--- roughly 0.367 .. 0.586, clear of both.
--- ⚠️ The pitch is 8°, not the 13° tried first. Steeper, and the flat red top face grows until the
--- whole thing reads as a building again.
local MAGNET_Y = 2.9
local MAGNET_SCALE = 0.92
local MAGNET_CF = CFrame.new(0, MAGNET_Y, 0) * CFrame.Angles(math.rad(-8), math.rad(27), 0)
--- The visual centre of the horseshoe, in the magnet's own space. Between the top of the body and
--- the pole shoes, which is what the eye reads as "the middle of it".
local MAGNET_VISUAL_CENTRE = MAGNET_CF * CFrame.new(Vector3.new(0, 0.2, 0) * MAGNET_SCALE)

--- ⚠️ The camera is built FIRST but the glow is PARENTED first. Those are two different orders and
--- both matter: draw order inside `backdrop` is child order, so the halo has to be parented before
--- the viewport to sit behind it -- while the halo's *position* cannot be computed until the camera
--- exists. Creating the camera early and parenting it later is what satisfies both.
local dioramaCam = Instance.new("Camera")
dioramaCam.FieldOfView = 55
dioramaCam.CFrame = CFrame.new(Vector3.new(0, 3.4, 32), Vector3.new(0, 2.0, 0))

--- 🔴 DERIVED, never written down. Projects a world point onto the screen's vertical axis using
--- only the camera's own `CFrame` and `FieldOfView`.
---
--- ⚠️ Vertical only, and that is not a shortcut -- `FieldOfView` **is** the vertical angle, so the
--- y this returns is identical on the 1.39 desktop canvas and the 1.78 phone one. A horizontal
--- equivalent would need the aspect ratio and would differ per device.
local function projectY(worldPos: Vector3): number
	local rel = dioramaCam.CFrame:PointToObjectSpace(worldPos)
	local depth = -rel.Z
	if depth <= 0.001 then
		--- Behind the camera. Centre is the only honest answer, and it cannot happen with the
		--- values above -- but a future edit could move the camera.
		return 0.5
	end
	local halfHeight = math.tan(math.rad(dioramaCam.FieldOfView) / 2) * depth
	return 0.5 - (rel.Y / halfHeight) * 0.5
end

local glow = Instance.new("Frame")
glow.Name = "Glow"
glow.BackgroundTransparency = 1
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, projectY(MAGNET_VISUAL_CENTRE.Position))
glow.Size = UDim2.fromScale(0.56, 0.56)
glow.Parent = backdrop

--- ⚠️ Constrained square. Sized in scale on both axes the halo is an ellipse whose shape changes
--- per device -- and the two canvases this screen actually runs on are 1.39 and 1.78, which is a
--- very visible difference.
local glowRatio = Instance.new("UIAspectRatioConstraint")
glowRatio.AspectRatio = 1
glowRatio.Parent = glow

--- 🔴 SIXTEEN rings, each almost invisible on its own. The first version used six at ~0.8
--- transparency and the result was a bullseye: you could count the discs. The number of steps is
--- what buys the smoothness, not the opacity of any one of them -- and since there is no Bloom in
--- here (see the note above) this stack IS the glow, so it has to survive being looked at.
local GLOW_RINGS = 16
local glowRings: { Frame } = {}
local function ringTransparency(t: number): number
	return 0.995 - (t * t) * 0.135
end

for i = 1, GLOW_RINGS do
	local t = (i - 1) / (GLOW_RINGS - 1) -- 0 = widest haze, 1 = tight core
	local ring = Instance.new("Frame")
	ring.Name = "Ring" .. i
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromScale(1 - t * 0.86, 1 - t * 0.86)
	ring.BackgroundColor3 = PALETTE.magnet
	ring.BorderSizePixel = 0
	--- ⚠️ Widest ring FIRST, so the tight core draws on top of the haze rather than under it --
	--- children of equal ZIndex render in child order.
	ring.BackgroundTransparency = ringTransparency(t)
	ring.Parent = glow
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring
	table.insert(glowRings, ring)
end

--- The halo ramps with REAL progress, so the magnet visibly powers up as the game actually loads.
--- It starts near-dark on purpose: a magnet at full strength before anything has loaded would be
--- the same lie as a progress bar that fills on a timer.
local function setGlow(level: number)
	local lit = math.clamp(level, 0, 1)
	for i, ring in ipairs(glowRings) do
		local t = (i - 1) / (GLOW_RINGS - 1)
		local full = ringTransparency(t)
		ring.BackgroundTransparency = 1 - (1 - full) * (0.12 + lit * 0.88)
	end
end
setGlow(0)

local diorama = Instance.new("ViewportFrame")
diorama.Name = "Diorama"
diorama.Size = UDim2.fromScale(1, 1)
--- 🔴 TRANSPARENT. This is the entire reason the 2D halo behind it is visible at all. Left at the
--- default opaque background, the viewport would paint over the glow and the magnet would be flat.
diorama.BackgroundTransparency = 1
--- The six properties the reference documents, all set explicitly so none of them is a default that
--- has to be reasoned about later. ⚠️ The ambient started much colder and darker and the alarm-red
--- body rendered as maroon; there is no ColorCorrection in here to lift it afterwards.
diorama.Ambient = Color3.fromRGB(74, 84, 104)
diorama.LightColor = Color3.fromRGB(255, 250, 240)
diorama.LightDirection = Vector3.new(-0.35, -1, -0.45)
diorama.ImageColor3 = Color3.new(1, 1, 1)
diorama.ImageTransparency = 0
diorama.Parent = backdrop

dioramaCam.Parent = diorama
diorama.CurrentCamera = dioramaCam

local function block(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	--- ⚠️ Off deliberately. A ViewportFrame has no shadow pass, so leaving `CastShadow` true would
	--- be a property that silently means nothing -- and this repo has enough of those.
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = diorama
	return p
end

--- 🔴 EVERYTHING BELOW RUNS UNDER `pcall`, and that is not defensive habit -- it is this file's
--- own stated disaster. `RemoveDefaultLoadingScreen` has already been called and `backdrop` is
--- already parented, opaque, with `Active = true` sinking input. A throw between here and the
--- watchdog spawned ~400 lines further down would leave the player behind an opaque frame they
--- cannot see past or click through, **permanently**, with no watchdog to rescue them.
---
--- Before this job the code between those two points was ~50 lines of flat 2D `Frame` work. It is
--- now the largest and newest block in the file, and it does CFrame algebra and enum lookups. So
--- it degrades instead of dying: lose the art, keep the title, the bar and the status line.
---
--- ⚠️ The instances the stage loop needs are declared OUTSIDE the pcall and assigned inside, so a
--- half-built scene leaves them nil rather than leaving them dangling.
--- 🔴 These three are OUTSIDE the guarded build below, deliberately.
---
--- The stage loop reads all of them, so if they lived inside the `pcall` they would be locals of
--- that closure and invisible to it -- and none of them is a thing that can throw: two are pure
--- arithmetic on constants, and the scrim is a `Frame` and a gradient. Only the geometry is risky,
--- so only the geometry is guarded.

--- 🔴 Derived from `MAGNET_CF` and `MAGNET_SCALE`, never written as a world position. It was a
--- bare `CFrame.new(0, -3.0, 0)` for one pass, and the moment the magnet was lifted and rescaled
--- the scrap kept flying to where the mouth used to be -- landing in mid-air below it, with
--- nothing in the code contradicting itself.
local MAGNET_MOUTH = MAGNET_CF * CFrame.new(0, -3.0 * MAGNET_SCALE, 0)

--- The scrim. Text readability is bought here, not hoped for from the art.
---
--- ⚠️ It darkens the BOTTOM of the frame only. The title and tagline already sit on empty dark sky
--- and dimming them would cost contrast for nothing; it is the bar and the status line, which sit
--- on the magnet and the floor, that need the help. A first version darkened the middle too and
--- flattened the whole picture.
---
--- 🔴 The gradient carries ALL of the transparency and the frame itself is opaque. Split between
--- the two, `BackgroundTransparency` and `UIGradient.Transparency` combine, and the result stops
--- being readable from either number alone.
local scrim = Instance.new("Frame")
scrim.Name = "Scrim"
scrim.Size = UDim2.fromScale(1, 1)
scrim.BackgroundColor3 = PALETTE.background
scrim.BackgroundTransparency = 0
scrim.BorderSizePixel = 0
scrim.Parent = backdrop

local scrimGradient = Instance.new("UIGradient")
scrimGradient.Rotation = 90 -- vertical
scrimGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0.00, 1.00), -- top: no scrim at all
	NumberSequenceKeypoint.new(0.52, 0.95),
	NumberSequenceKeypoint.new(0.62, 0.62), -- the progress bar
	NumberSequenceKeypoint.new(0.78, 0.50), -- the status line
	NumberSequenceKeypoint.new(1.00, 0.44),
})
scrimGradient.Parent = scrim

--- The scrap. §7's diagram is `🔩 → ⚙️ → 🪙 → 🧲` -- three objects arriving, and then the magnet
--- itself. So there are three pieces here, not four, and the fourth stage is the magnet coming up
--- to full power. `runStages` asserts that this count plus one still equals the stage count.
---
--- ⚠️ The start positions are WELL outside the frustum on both canvases. At the ±17 they started
--- at, all three sat visible in shot from the first frame, waiting their turn.
local SCRAP_PIECES = {
	{ name = "Bolt", size = Vector3.new(2.2, 0.62, 0.62), color = PALETTE.chrome, material = Enum.Material.Metal, from = Vector3.new(-46, 20, -6) },
	{ name = "Gear", size = Vector3.new(0.42, 1.9, 1.9), color = PALETTE.steel, material = Enum.Material.Metal, from = Vector3.new(48, 14, -4) },
	{ name = "Coin", size = Vector3.new(0.22, 1.5, 1.5), color = PALETTE.gold, material = Enum.Material.Neon, from = Vector3.new(-44, -2, 8) },
}

local poleNorth: Part? = nil
local poleSouth: Part? = nil
local scrapParts: { Part } = {}

local sceneOk, sceneErr = pcall(function()

--- The corridor. 🔴 These are LOW and WIDE, flanking the frame, and that is the whole point.
--- Built first as arches surrounding the magnet, they put steel on every side of its outline and
--- the magnet read as architecture -- a torii gate, not a magnet. Pushed out and down they still
--- say "this factory keeps going" without ever touching the silhouette.
local FLOOR_Y = -6.5
for i = 1, 4 do
	local z = -20 - (i - 1) * 16
	local halfW = 13 + i * 1.5
	local topY = -0.6 - i * 0.35
	local uprightH = topY - FLOOR_Y
	--- Hand-dimmed by depth. This is the ONLY depth cue available in here -- `Atmosphere` is a
	--- `Lighting` object and reaches inside a viewport no more than Bloom does.
	local shade = 0.62 - i * 0.11
	local steel = Color3.new(PALETTE.steel.R * shade, PALETTE.steel.G * shade, PALETTE.steel.B * shade)
	block(("ArchTop%d"):format(i), Vector3.new(halfW * 2, 0.9, 0.9), CFrame.new(0, topY, z), steel, Enum.Material.Metal)
	block(("ArchLeft%d"):format(i), Vector3.new(0.9, uprightH, 0.9), CFrame.new(-halfW, FLOOR_Y + uprightH / 2, z), steel, Enum.Material.Metal)
	block(("ArchRight%d"):format(i), Vector3.new(0.9, uprightH, 0.9), CFrame.new(halfW, FLOOR_Y + uprightH / 2, z), steel, Enum.Material.Metal)
	--- ⚠️ Small. `Neon` reads as lit with no Bloom, but at the size these started they blobbed
	--- yellow straight through the magnet's opening and looked like a fault.
	--- ⚠️ Alternating left/right of centre. Sitting on the centreline they shone straight through
	--- the magnet's opening and read as a yellow fault light inside the hero object.
	local lampX = if i % 2 == 0 then 9 else -9
	--- 🔴 CHROME, not gold. Style §2 disambiguates hazard yellow by it *"always being a striped
	--- pattern with `#14161C`, never a solid fill"*, and says outright that a solid gold panel which
	--- is not Arena- or Legendary-related **is the rule breaking**. These are decorative corridor
	--- lamps, so they get a cool white instead and the gold keeps meaning "most valuable thing here".
	block(("ArchLamp%d"):format(i), Vector3.new(2.2, 0.18, 0.18), CFrame.new(lampX, topY - 0.5, z), PALETTE.chrome, Enum.Material.Neon)
end

--- ⚠️ Wide enough that its side edges stay out of frame. At 46 studs across it was a black
--- diagonal wedge cutting the lower half of the screen -- the floor's own edges, receding.
--- 340, not the 240 first used: at 240 the far corners were still inside the frustum (half-width at
--- the far edge is ~124 studs at aspect 1.39 and ~159 at 1.78, against a 120-stud half-width). It
--- did not show, because near-black on near-black never does -- but it would the moment anyone
--- lightened the floor, and the comment claiming otherwise would have been believed.
block("Floor", Vector3.new(340, 1, 170), CFrame.new(0, FLOOR_Y - 0.5, -55), PALETTE.hazardDark, Enum.Material.Metal)

--- The magnet. §2: *"The magnet is red + cyan, always, everywhere -- the poles are the game's
--- logo."*
---
--- 🔴 WIDER THAN IT IS TALL, with a WIDE, SHORT opening -- 7.6 across, 6.0 tall, a 3.6 gap that is
--- 47 % of the width. Three earlier passes made it taller than wide with a narrow slot, and every
--- one of them read as a doorway. A horseshoe's proportions are the entire silhouette; get them
--- wrong and no amount of colour rescues it.
---
--- ⚠️ Pitched so the camera looks slightly DOWN onto its top face. Seen dead level it reads as a
--- flat facade however good the proportions are. `MAGNET_CF` is defined at the top of this section,
--- because the halo and the scrap's target are both derived from it.

local function magnetPart(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material): Part
	return block(name, size * MAGNET_SCALE, MAGNET_CF * CFrame.new(offset * MAGNET_SCALE), color, material)
end

magnetPart("MagnetTop", Vector3.new(7.6, 2.9, 3.0), Vector3.new(0, 1.55, 0), PALETTE.alarm, Enum.Material.SmoothPlastic)
magnetPart("MagnetLegL", Vector3.new(2.0, 3.2, 3.0), Vector3.new(-2.8, -1.45, 0), PALETTE.alarm, Enum.Material.SmoothPlastic)
magnetPart("MagnetLegR", Vector3.new(2.0, 3.2, 3.0), Vector3.new(2.8, -1.45, 0), PALETTE.alarm, Enum.Material.SmoothPlastic)
--- ⚠️ NO CHAMFER BLOCKS. Two 45° shoulders were tried to fake a horseshoe's round top. Large
--- enough to see, they protruded past the body and read as ears; small enough not to protrude,
--- they were invisible. The proportions carry the read on their own.
--- 🔴 The pole shoes are CHROME, and the red/cyan pair is a thin lit strip on the very bottom face.
--- Painted alarm-red directly, the south pole was red-on-red and simply disappeared -- so the half
--- of the game's logo that means "south" was invisible.
magnetPart("PoleNorth", Vector3.new(2.1, 0.85, 3.05), Vector3.new(-2.8, -3.4, 0), PALETTE.chrome, Enum.Material.Metal)
magnetPart("PoleSouth", Vector3.new(2.1, 0.85, 3.05), Vector3.new(2.8, -3.4, 0), PALETTE.chrome, Enum.Material.Metal)
poleNorth = magnetPart("PoleLitN", Vector3.new(2.15, 0.3, 3.1), Vector3.new(-2.8, -3.9, 0), PALETTE.magnet, Enum.Material.Neon)
poleSouth = magnetPart("PoleLitS", Vector3.new(2.15, 0.3, 3.1), Vector3.new(2.8, -3.9, 0), PALETTE.alarm, Enum.Material.Neon)
--- ⚠️ A NUB, not a lintel. `Robot.png` hangs the magnet off a crane arm, and a full arm was tried:
--- it ran straight up through the title. A chrome stub implies the arm without owning the frame.
magnetPart("ArmYoke", Vector3.new(1.7, 1.0, 1.7), Vector3.new(0, 3.4, 0), PALETTE.steel, Enum.Material.Metal)

--- Where scrap arrives: the mouth between the poles.

--- The robot. §9: *"Don't ship a sleek humanoid robot. Homemade, asymmetric and ridiculous is the
--- point."* Hence mismatched arms, an off-centre head and a body that is obviously salvage.
local ROBOT = CFrame.new(10.2, -2.6, -12) * CFrame.Angles(0, math.rad(-24), 0)
block("RobotBody", Vector3.new(3.4, 4.0, 2.4), ROBOT, PALETTE.rust, Enum.Material.Metal)
block("RobotHead", Vector3.new(2.2, 1.8, 1.9), ROBOT * CFrame.new(0.25, 2.9, 0), PALETTE.steel, Enum.Material.Metal)
--- 🔴 Weld orange, NOT magnet cyan. §2 closes its zone-colour rule with *"lets the cyan in the
--- scene belong to the player alone"* -- and this robot is scenery on a screen whose subject is the
--- player's magnet. Orange is `#FF7A1A`, which §2 already assigns to the robot ("repair / robot
--- health"), so the robot is lit in its own colour rather than borrowing the magnet's.
block("RobotEyeL", Vector3.new(0.5, 0.5, 0.2), ROBOT * CFrame.new(-0.2, 3.0, 1.0), PALETTE.repair, Enum.Material.Neon)
block("RobotEyeR", Vector3.new(0.34, 0.34, 0.2), ROBOT * CFrame.new(0.78, 3.16, 1.0), PALETTE.repair, Enum.Material.Neon)
block("RobotArmL", Vector3.new(0.9, 3.0, 0.9), ROBOT * CFrame.new(-2.1, -0.3, 0), PALETTE.steel, Enum.Material.Metal)
block("RobotArmR", Vector3.new(1.3, 2.1, 1.1), ROBOT * CFrame.new(2.2, 0.4, 0) * CFrame.Angles(0, 0, math.rad(18)), PALETTE.chrome, Enum.Material.Metal)
block("RobotLegL", Vector3.new(1.1, 2.4, 1.1), ROBOT * CFrame.new(-0.9, -3.2, 0), PALETTE.hazardDark, Enum.Material.Metal)
block("RobotLegR", Vector3.new(1.1, 2.4, 1.1), ROBOT * CFrame.new(1.0, -3.2, 0), PALETTE.hazardDark, Enum.Material.Metal)

--- The player, seen from behind and low in frame -- §7 lists them first.
--- ⚠️ `#232B3A`, NOT the near-black `hazardDark` this started as. Against the dark floor a
--- pure-silhouette figure was a hole in the picture rather than a person.
local FIGURE = CFrame.new(-6.2, -3.6, 2)
block("FigureBody", Vector3.new(1.7, 2.1, 0.95), FIGURE, PALETTE.figure, Enum.Material.SmoothPlastic)
block("FigureHead", Vector3.new(1.15, 1.15, 1.15), FIGURE * CFrame.new(0, 1.65, 0), PALETTE.figure, Enum.Material.SmoothPlastic)
block("FigureArmL", Vector3.new(0.5, 1.85, 0.5), FIGURE * CFrame.new(-1.1, -0.15, 0), PALETTE.figure, Enum.Material.SmoothPlastic)
block("FigureArmR", Vector3.new(0.5, 1.85, 0.5), FIGURE * CFrame.new(1.1, -0.15, 0), PALETTE.figure, Enum.Material.SmoothPlastic)
block("FigureLegL", Vector3.new(0.62, 1.7, 0.62), FIGURE * CFrame.new(-0.42, -1.9, 0), PALETTE.figure, Enum.Material.SmoothPlastic)
block("FigureLegR", Vector3.new(0.62, 1.7, 0.62), FIGURE * CFrame.new(0.42, -1.9, 0), PALETTE.figure, Enum.Material.SmoothPlastic)



for i, spec in ipairs(SCRAP_PIECES) do
	local p = Instance.new("Part")
	p.Name = "Scrap" .. spec.name
	--- ⚠️ A `Cylinder` part's axis runs along **X**, so the disc-shaped pieces are turned a quarter
	--- turn about Y to face the camera. Sized without that in mind they would be edge-on and read
	--- as a thin line.
	p.Shape = Enum.PartType.Cylinder
	p.Size = spec.size
	p.Color = spec.color
	p.Material = spec.material
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.CFrame = CFrame.new(spec.from) * CFrame.Angles(math.rad(28 * i), math.rad(90 + 17 * i), math.rad(12 * i))
	p.Parent = diorama
	scrapParts[i] = p
end

end) -- end of the guarded scene build

if not sceneOk then
	warn(("[C][Boot] DIORAMA BUILD FAILED: %s -- the screen keeps its title, bar and status line")
		:format(tostring(sceneErr)))
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
		waiting = "ENTERING THE FACTORY",
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
			--- 🔴 NO FOLDER-NAME CHECK. This looked for `workspace.Workshop`, then `workspace.Hub`,
			--- and each rename silently broke it: PLACE could never complete, the screen sat on
			--- "WAITING FOR THE WORLD TO STREAM IN" for the full 90 s, and only the watchdog
			--- released the player. **Twice.**
			---
			--- The world is hand-placed now and its top-level names are the owner's to choose, so a
			--- name in here is a hostage to a rename that has nothing to do with booting. The ray
			--- below is the check that actually matters and always was — "is there ground under this
			--- player's feet" does not care what the folder is called.
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

--- Stage `i` landing: the i-th piece of scrap flies into the magnet's mouth and is absorbed.
--- The LAST stage has no piece -- it is the magnet itself coming up to full power, which is §7's
--- `🧲`, and it lands on the same beat as the CLANG.
local function landObject(i: number)
	setGlow(i / #STAGES)
	local piece = scrapParts[i]
	if piece then
		--- `EasingDirection.In` on purpose: scrap accelerates INTO a magnet. Eased out, it drifted
		--- to a polite stop at the mouth and read as being placed rather than pulled.
		local flight = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		TweenService:Create(piece, flight, {
			CFrame = MAGNET_MOUTH * CFrame.Angles(0, math.rad(90), 0),
			Size = piece.Size * 0.35,
			Transparency = 1,
		}):Play()
	else
		local surge = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		--- ⚠️ Both poles are `Part?` because the build above can fail. Checked rather than assumed:
		--- an `ipairs` over a table with a nil in it stops at the hole silently, which would have
		--- surged one pole and not the other and looked like a rendering bug.
		if poleNorth and poleSouth then
			TweenService:Create(poleNorth, surge, { Size = poleNorth.Size * 1.4 }):Play()
			TweenService:Create(poleSouth, surge, { Size = poleSouth.Size * 1.4 }):Play()
		end
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
		--- Job 015's diorama colours. Four of the five ARE Theme tokens, so adding them here makes
		--- them genuinely audited rather than merely present; `rust` has no token and is skipped by
		--- the `if theirs` below, which is the same treatment `barTrack` gets.
		steel = (Theme :: any).color.steelMid,
		chrome = (Theme :: any).color.chrome,
		hazardDark = (Theme :: any).color.hazardBlack,
		gold = (Theme :: any).color.arena,
		repair = (Theme :: any).color.repair,
	}
	for name, mine in pairs(PALETTE) do
		local theirs = expect[name]
		if not theirs and not PALETTE_NO_TOKEN[name] then
			--- Not exempt and not expected: either a new colour was added without an expectation,
			--- or the Theme token it mirrors was renamed. Both silently disable the drift check.
			warn(("[C][Boot] palette audit gap: BootScreen.%s has no `Ui.Theme` expectation and is not in PALETTE_NO_TOKEN -- it is not being checked")
				:format(name))
		end
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
	--- ⚠️ `ImageTransparency`, NOT `BackgroundTransparency`. The viewport's background is already
	--- transparent by design, so tweening it would fade nothing at all while the 3D content stayed
	--- at full strength for the entire out-tween and then vanished on the `Destroy`.
	TweenService:Create(diorama, out, { ImageTransparency = 1 }):Play()
	--- 🔴 The scrim fades too. It is a child of `backdrop`, and tweening a parent's
	--- `BackgroundTransparency` does NOTHING to a child -- so while every other element faded, a
	--- 56 %-opaque dark band held over the lower third for the whole 0.45 s out-tween and then
	--- vanished on `Destroy`. A hard cut on every single boot.
	TweenService:Create(scrim, out, { BackgroundTransparency = 1 }):Play()
	for _, ring in ipairs(glowRings) do
		TweenService:Create(ring, out, { BackgroundTransparency = 1 }):Play()
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
	if #SCRAP_PIECES + 1 ~= total then
		warn(("[C][Boot] %d scrap pieces + the magnet for %d stages -- every stage needs a visible arrival")
			:format(#SCRAP_PIECES, total))
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

		landObject(i)
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
--- 🔴 THE CHECK THAT REPLACED `ART MISSING`, and it can still fail.
---
--- `docs/build/06-boot-and-hud.md` listed as **P0**: "Loading screen art: player, magnet, flying
--- scrap, robot, corridor". Job 015 built all five. Deleting the old warn outright would have
--- traded a check for nothing, and the realistic failure now is not "no art" -- it is **a diorama
--- that built nothing**. An empty `ViewportFrame` renders as a hole the exact colour of the
--- backdrop behind it, which looks indistinguishable from the screen working.
---
--- ⚠️ So this counts what actually got parented, rather than trusting that the code above ran.
--- Ground rule 10: an empty slot must announce itself.
do
	--- 🔴 NAMES §7's five subjects, one representative part each.
	---
	--- ⚠️ A part COUNT was tried first -- `built < 20` against 42 actual parts -- and it was worth
	--- nothing: you could delete the entire magnet, the entire robot and the entire player figure,
	--- land on exactly 20, and the guard would stay silent. It replaced a warn that named all five
	--- subjects with a number that tolerated losing three of them. That is the PITFALLS #55-#61
	--- shape appearing in the very check written to prevent it.
	local REQUIRED = {
		{ "the player", "FigureBody" },
		{ "a glowing magnet", "MagnetTop" },
		{ "scrap flying", "ScrapBolt" },
		{ "a robot", "RobotBody" },
		{ "a factory corridor", "ArchTop1" },
	}
	local missing = {}
	for _, pair in ipairs(REQUIRED) do
		if not diorama:FindFirstChild(pair[2]) then
			table.insert(missing, ("%s (%s)"):format(pair[1], pair[2]))
		end
	end
	--- ⚠️ Cast before the nil test. The new type solver types `CurrentCamera` as a non-nullable
	--- `Camera`, so a bare `== nil` is a type ERROR rather than a check -- and silencing it by
	--- dropping the test would have removed half of what this guard is for.
	local noCamera = (diorama.CurrentCamera :: Camera?) == nil
	if #missing > 0 or noCamera then
		warn(("[C][Boot] ART MISSING: %d of §7's five subjects are not on screen -- %s%s")
			:format(#missing, table.concat(missing, ", "), noCamera and " | AND the viewport has no camera, so it renders nothing at all" or ""))
	end
end

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
