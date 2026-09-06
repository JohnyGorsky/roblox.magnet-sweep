--!strict
--[[
	BaseNameplate — the lit sign above each bay saying who owns it.

	One plate per base, generated at runtime from the base list. Dark and blank when the bay is free;
	lit with the owner's headshot, display name and @username when it is claimed.

	🔴 GENERATED, NOT HAND-PLACED. `Workspace` does not sync
	([decision 0019](../../../docs/decisions/0019-hero-geometry-is-editor-placed-and-exported.md)), so
	hand-placed plates would live only in the unversioned `.rbxl`. Hero geometry earns that cost;
	ten identical data-driven signs do not.

	🔴 IT READS FROM `Neon` + BLOOM, NEVER FROM LIGHT SPILL.
	`QualityController.local.luau:123-131` clamps every non-`Hero` `PointLight`/`SpotLight`/
	`SurfaceLight` to **10 studs** on the Low tier -- job 021 measured all 150 lights in the room
	sitting at range 10 in a real Play session. A sign 30+ studs from the player that glows because
	of a light would be invisible on a phone. Bloom is the only post-effect Low keeps, so the glow
	has to come from an emissive surface.

	🔴 PLACED FROM THE BASE'S OWN BEARING, NOT A LOOP COUNTER. Bays are `BaseIndex` 3..12 and each
	`SMELTER` carries the `Bearing` it was placed on. Deriving a bearing from the iteration order
	would put plates on the wrong walls the moment a bay is added, removed or reordered.

	⚠️ `GetUserThumbnailAsync` YIELDS and can throttle or fail outright. It is always `pcall`'d, and a
	failure shows the plate **with no picture** rather than no plate -- an empty slot that announces
	itself, per non-negotiable #10.

	Sources: style skill section 5 (signage) and section 7 (type) · Jobs/022
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Nameplate")

local BaseNameplate = {}

local FOLDER_NAME = "BaseNameplates"

--- Mounted HIGH, on the blank stretch of the job-021 backdrop wall.
---
--- 🔴 THE HEIGHT IS MEASURED, NOT CHOSEN. An outward raycast sweep on every one of the ten facets
--- says the same thing: below ~50 the wall carries job 021's detail band (pipes, ribbed duct runs,
--- fan housings, louvres at r 239..250), and from ~105 up it is the clerestory glazing at r=267.
--- Between them, **y 55..100 is clear on all ten facets** down to the `L2` backdrop face at r=268.
--- That is the only band where a sign is not competing with machinery, and it is where the first
--- version was wrong: at y=33 the plate sat directly in front of a duct run.
---
--- r=266.5 puts the plate just off `L2`'s face (268) so nothing is coplanar -- 0.06 is the minimum
--- that avoids z-fighting and 1.5 is comfortable.
local RADIUS = 266.5
local Y = 76
--- Scaled for the new distance, not left at the old size. From a player at their bay (r=200,
--- eye 5) the plate is now `sqrt(66.5^2 + 71^2)` = **97 studs** away against 41 before, so it is
--- sized up ~2.2x to read the same. A 66-stud plate is a bit under half the 142.6-stud facet width.
local WIDTH, HEIGHT, DEPTH = 66, 28, 2.2

local SLATE = Color3.fromHex("141B2B")
local CHROME = Color3.fromHex("B8C2CC")
local CYAN = Color3.fromHex("41D8FF")
local DIM = Color3.fromHex("2A323C")
local CENTRE = Vector3.new(1556, 0, 0)

local function fontBold(): Font
	return Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
end
local function fontRegular(): Font
	return Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
end

--- Build the physical plate for one base. Returns the housing part.
local function buildPlate(parent: Instance, baseIndex: number, bearingDeg: number): BasePart
	local b = math.rad(bearingDeg)
	local n = Vector3.new(math.cos(b), 0, math.sin(b))
	local pos = CENTRE + n * RADIUS + Vector3.new(0, Y, 0)

	local housing = Instance.new("Part")
	housing.Name = ("Plate_%d"):format(baseIndex)
	housing.Size = Vector3.new(WIDTH, HEIGHT, DEPTH)
	--- lookAt is right-handed by construction, so this cannot mirror (finding 0009)
	housing.CFrame = CFrame.lookAt(pos, pos - n)
	housing.Anchored = true
	housing.CanCollide = false
	housing.CastShadow = false
	housing.Material = Enum.Material.SmoothPlastic
	housing.Color = SLATE
	housing:SetAttribute("BaseIndex", baseIndex)
	housing.Parent = parent

	--- chrome bezel, per the signage language
	local bezel = Instance.new("Part")
	bezel.Name = "Bezel"
	bezel.Size = Vector3.new(WIDTH + 1.6, HEIGHT + 1.6, DEPTH * 0.7)
	bezel.CFrame = housing.CFrame * CFrame.new(0, 0, 0.5)
	bezel.Anchored = true
	bezel.CanCollide = false
	bezel.CastShadow = false
	bezel.Material = Enum.Material.Metal
	bezel.Color = CHROME
	bezel.Parent = housing

	--- the emissive strip under the plate is what makes it read at distance on every tier
	local glow = Instance.new("Part")
	glow.Name = "Glow"
	glow.Size = Vector3.new(WIDTH, 0.9, 0.9)
	glow.CFrame = housing.CFrame * CFrame.new(0, -HEIGHT / 2 - 0.6, -0.2)
	glow.Anchored = true
	glow.CanCollide = false
	glow.CastShadow = false
	glow.Material = Enum.Material.Neon
	glow.Color = DIM
	glow.Parent = housing

	--- The face. `LightInfluence = 0` so the GUI is not darkened by the room's lighting -- the plate
	--- must stay legible on the shadowed half of the ring, which is always half of it.
	local sg = Instance.new("SurfaceGui")
	sg.Name = "Face"
	--- 🔴 `Front`, not `Back`. `CFrame.lookAt(pos, pos - n)` gives `LookVector = -n`, which points
	--- INWARD at the room, and `LookVector` is the part's -Z axis -- i.e. its `Front` face. Measured:
	--- `dot(LookVector, inward) = 1.000`. Setting `Back` renders the sign on the side facing the
	--- wall, which looks exactly like a broken SurfaceGui: housing lit, face blank.
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	--- 20, not 48. The plate is now 66 studs wide; at 48 that is a 3168px surface per sign, ten of
	--- them, for something read at ~97 studs. 20 gives a 1320px surface, which is still far more
	--- resolution than the distance can resolve.
	sg.PixelsPerStud = 20
	sg.LightInfluence = 0
	sg.AlwaysOnTop = false
	sg.Adornee = housing
	sg.Parent = housing

	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = sg

	--- avatar, ROUNDED: UICorner at scale 0.5 on a square turns it into a circle
	local avatarHolder = Instance.new("Frame")
	avatarHolder.Name = "AvatarHolder"
	avatarHolder.AnchorPoint = Vector2.new(0, 0.5)
	avatarHolder.Position = UDim2.new(0.035, 0, 0.5, 0)
	avatarHolder.Size = UDim2.fromScale(0.28, 0.82)
	avatarHolder.BackgroundColor3 = DIM
	avatarHolder.BorderSizePixel = 0
	avatarHolder.Parent = root
	local holderAspect = Instance.new("UIAspectRatioConstraint")
	holderAspect.AspectRatio = 1
	holderAspect.Parent = avatarHolder
	local holderCorner = Instance.new("UICorner")
	holderCorner.CornerRadius = UDim.new(0.5, 0)
	holderCorner.Parent = avatarHolder
	local ring = Instance.new("UIStroke")
	ring.Name = "Ring"
	ring.Thickness = 3
	ring.Color = DIM
	ring.Parent = avatarHolder

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.fromScale(1, 1)
	avatar.BackgroundTransparency = 1
	avatar.Image = ""
	avatar.Parent = avatarHolder
	local avCorner = Instance.new("UICorner")
	avCorner.CornerRadius = UDim.new(0.5, 0)
	avCorner.Parent = avatar

	local display = Instance.new("TextLabel")
	display.Name = "DisplayName"
	display.AnchorPoint = Vector2.new(0, 1)
	display.Position = UDim2.new(0.35, 0, 0.52, 0)
	display.Size = UDim2.fromScale(0.62, 0.34)
	display.BackgroundTransparency = 1
	display.FontFace = fontBold()
	display.TextColor3 = Color3.new(1, 1, 1)
	display.TextScaled = true
	display.TextXAlignment = Enum.TextXAlignment.Left
	display.Text = "FREE BAY"
	display.Parent = root

	local handle = Instance.new("TextLabel")
	handle.Name = "Handle"
	handle.Position = UDim2.new(0.35, 0, 0.54, 0)
	handle.Size = UDim2.fromScale(0.62, 0.24)
	handle.BackgroundTransparency = 1
	handle.FontFace = fontRegular()
	handle.TextColor3 = CYAN
	handle.TextScaled = true
	handle.TextTransparency = 0.15
	handle.TextXAlignment = Enum.TextXAlignment.Left
	handle.Text = ("BAY %d"):format(baseIndex)
	handle.Parent = root

	return housing
end

--- Read the bearing each base was actually placed on, rather than deriving it from a counter.
local function bearingFor(base: Instance): number?
	for _, d in ipairs(base:GetDescendants()) do
		local bear = d:GetAttribute("Bearing")
		if bear ~= nil then
			return bear :: number
		end
	end
	return nil
end

local plates: { [number]: BasePart } = {}

--- Build (or rebuild) every plate. Safe to call twice.
function BaseNameplate.build(): number
	local hub = workspace:FindFirstChild("Hub")
	local basesFolder = hub and hub:FindFirstChild("Bases")
	if not basesFolder then
		Log.warn("workspace.Hub.Bases not found -- no plates built")
		return 0
	end

	local old = workspace:FindFirstChild(FOLDER_NAME)
	if old then
		old:Destroy()
	end
	plates = {}

	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = workspace

	local n = 0
	local missing = {}
	for _, base in ipairs(basesFolder:GetChildren()) do
		local idx = base:GetAttribute("BaseIndex")
		if idx ~= nil then
			local bear = bearingFor(base)
			if bear == nil then
				table.insert(missing, tostring(idx))
			else
				plates[idx :: number] = buildPlate(folder, idx :: number, bear)
				n += 1
			end
		end
	end
	if #missing > 0 then
		--- announce the gap rather than guessing a bearing: a plate on the wrong wall is worse
		--- than a missing one, because it attributes a bay to the wrong player
		Log.warn("no Bearing attribute on base(s) %s -- those bays get NO plate", table.concat(missing, ","))
	end
	Log.info("built %d nameplate(s) at r=%d y=%d", n, RADIUS, Y)
	return n
end

--- Light a plate up for its owner. Called from BaseClaimService's onClaim hook.
function BaseNameplate.setOwner(baseIndex: number, player: Player?)
	local housing = plates[baseIndex]
	if not housing then
		Log.warn("no plate for base %d", baseIndex)
		return
	end
	local face = housing:FindFirstChild("Face")
	local glow = housing:FindFirstChild("Glow")
	if not face then
		return
	end
	local root = face:FindFirstChildWhichIsA("Frame")
	if not root then
		return
	end
	local holder = root:FindFirstChild("AvatarHolder")
	local avatar = holder and holder:FindFirstChild("Avatar")
	local ring = holder and holder:FindFirstChild("Ring")
	local display = root:FindFirstChild("DisplayName")
	local handle = root:FindFirstChild("Handle")

	if not player then
		if avatar then (avatar :: ImageLabel).Image = "" end
		if display then (display :: TextLabel).Text = "FREE BAY" end
		if handle then (handle :: TextLabel).Text = ("BAY %d"):format(baseIndex) end
		if ring then (ring :: UIStroke).Color = DIM end
		if glow then (glow :: BasePart).Color = DIM end
		return
	end

	--- text and colour FIRST, so the plate lights the moment the bay is claimed. The picture is the
	--- only part that needs the network, and it must never gate the rest.
	if display then (display :: TextLabel).Text = string.upper(player.DisplayName) end
	if handle then (handle :: TextLabel).Text = "@" .. player.Name end
	if ring then (ring :: UIStroke).Color = CYAN end
	if glow then (glow :: BasePart).Color = CYAN end

	--- ⚠️ yields, and can fail. pcall or a throttle takes the whole claim down with it.
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size150x150
			)
		end)
		--- re-check: the player may have left while we were waiting on the web
		if not ok then
			Log.warn("thumbnail failed for %s (%s) -- plate shows name only", player.Name, tostring(img))
			return
		end
		if housing.Parent == nil then
			return
		end
		if avatar then
			(avatar :: ImageLabel).Image = img :: string
		end
	end)
end

--- Wire straight into BaseClaimService.start's hooks.
function BaseNameplate.hooks(): { onClaim: (Player, Instance) -> (), onRelease: (Player, Instance) -> () }
	return {
		onClaim = function(player: Player, base: Instance)
			BaseNameplate.setOwner(base:GetAttribute("BaseIndex") :: number, player)
		end,
		onRelease = function(_player: Player, base: Instance)
			BaseNameplate.setOwner(base:GetAttribute("BaseIndex") :: number, nil)
		end,
	}
end

return BaseNameplate
