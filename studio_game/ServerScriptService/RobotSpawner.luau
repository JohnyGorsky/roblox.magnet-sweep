--!strict
--[[
	RobotSpawner — stands a player's robot on their bay's mount, and gives it an idle.

	Steps 3 and 4 of job 022. Ownership is ASSUMED for now: there is no robot inventory yet, so
	every claimed bay gets the documented starter loadout.

	🔴 THE STANCE IS APPLIED IN CODE, NOT BAKED INTO THE RIG FILE.

	Measured on the demo rigs: the authored rest pose puts the arms **+11.4 degrees from horizontal**
	-- a rigging T-pose -- and the whole `Idle` loop moves the shoulders by only **5.5 degrees**. So no
	clip can bring the arms down, because `RobotAnim` applies every clip as an OFFSET FROM REST
	(see its header). That is why the owner's reaction to the sample robot was *"hands placed
	incorrectly"*: a T-pose being used as a display pose.

	The fix could be re-authored into the rig's `Motor6D.C0` values in Studio, but
	`ReplicatedStorage.RobotRig` is a Model and **Rojo syncs scripts, not models** -- so it lives only
	in the unversioned `.rbxl`. Editing it there would put a load-bearing pose somewhere git cannot
	see. Applying it here means it is reviewable, diffable, and survives losing the place file.

	⚠️ ORDER MATTERS: stance FIRST, then `RobotAnim.play`. `RobotAnim` captures each joint's rest pose
	on first play, so the stance must already be in `C0` when it does -- otherwise the clip offsets
	from a T-pose and the arms snap back out.

	🔴 `RobotAnim` drives `C0`, not `Transform`, precisely so a server-side write replicates
	(`Transform` is the `Animator` channel and does not replicate on its own). An Arena robot is
	nobody's character, so these are played **on the server**.

	Sources: docs/systems/robot-assembly (the starter loadout) · docs/systems/robot-rig · Jobs/022
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local StarterRobot = require(Config:WaitForChild("StarterRobot", 20))
local RobotAssembler = require(script.Parent:WaitForChild("RobotAssembler", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("RobotSpawn")

local RobotSpawner = {}

local MOUNT_NAME = "RobotMount"
local SPAWNED_NAME = "OwnedRobot"

--- Rotation applied to each joint's authored `C0` to turn a T-pose into a standing stance.
---
--- ⚠️ SIGNS ARE MIRRORED LEFT vs RIGHT, and this is not cosmetic. `RobotAnim.resolve` records the
--- reason: *"the same Y rotation swings one arm forward and the other BACKWARD"*. The `Idle` clip
--- follows the same convention (left `+`, right `-` about Z), so the stance must too, or the clip
--- will fight it on one side.
---
--- [UNTUNED] — readable, not final. Z is the arm's up/down swing.
RobotSpawner.STANCE = {
	LeftShoulder = CFrame.Angles(0, 0, math.rad(62)),
	RightShoulder = CFrame.Angles(0, 0, math.rad(-62)),
	LeftElbow = CFrame.Angles(0, 0, math.rad(16)),
	RightElbow = CFrame.Angles(0, 0, math.rad(-16)),
	--- a touch of settle, so it does not read as standing to attention
	Waist = CFrame.new(0, -0.15, 0),
	Neck = CFrame.Angles(math.rad(-3), 0, 0),
}

local function mountFor(base: Instance): BasePart?
	for _, d in ipairs(base:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == MOUNT_NAME then
			return d
		end
	end
	return nil
end

--- Apply the stance to a rig's joints. Returns how many joints moved.
function RobotSpawner.applyStance(rig: Instance): number
	local n = 0
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("Motor6D") then
			local offset = RobotSpawner.STANCE[d.Name]
			if offset then
				d.C0 = d.C0 * offset
				n += 1
			end
		end
	end
	return n
end

--- Measure the arm angle above horizontal, so "the stance worked" is a number and not a screenshot.
function RobotSpawner.armAngles(rig: Instance): { [string]: number }
	local torso
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "TorsoPivot" then
			torso = d
		end
	end
	local out = {}
	if not torso then
		return out
	end
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == "LeftArmPivot" or d.Name == "RightArmPivot") then
			local rel = torso.CFrame:PointToObjectSpace(d.Position)
			local horiz = math.sqrt(rel.X * rel.X + rel.Z * rel.Z)
			out[d.Name] = math.deg(math.atan2(rel.Y, horiz))
		end
	end
	return out
end

function RobotSpawner.despawn(base: Instance): boolean
	local existing = base:FindFirstChild(SPAWNED_NAME, true)
	if existing then
		existing:Destroy()
		return true
	end
	return false
end

--- Stand a robot on this bay's mount and start its idle.
---
--- 🔴 BUILT FROM THE PLAYER'S LOADOUT, not cloned from a fixed model. The first pass cloned
--- `DemoRoom.10_Robots.2_Starter` whole, which meant every player got the same object and a saved
--- loadout would have had nothing to build from. Now the profile owns five partIds and
--- `RobotAssembler` turns them into a robot, which is decision 0004's whole point.
function RobotSpawner.spawn(base: Instance, player: Player?): Instance?
	RobotSpawner.despawn(base)

	local idx = base:GetAttribute("BaseIndex")
	local mount = mountFor(base)
	if not mount then
		Log.warn("bay %s has no %s marker -- no robot placed", tostring(idx), MOUNT_NAME)
		return nil
	end

	--- the loadout is the player's if they have a profile, otherwise the starter
	local loadout
	local source = "starter (no player)"
	if player then
		local okProfile, PlayerProfile = pcall(function()
			return require(script.Parent:WaitForChild("PlayerProfile", 5))
		end)
		if okProfile and PlayerProfile then
			--- 🔴 WAIT FOR THE PROFILE FIRST. The claim fires the moment a player joins, but the
			--- DataStore load takes a round trip -- so reading the loadout immediately returns
			--- DEFAULTS. Measured: after a restart the profile said `Arm = PIPE_WRENCH` while the
			--- robot standing in the bay still held `RUSTY_WRENCH`, on every single join.
			PlayerProfile.waitReady(player, 10)
			loadout = PlayerProfile.loadout(player)
			source = PlayerProfile.isSessionOnly(player) and "profile (SESSION-ONLY, will not save)" or "saved profile"
		end
	end
	if not loadout then
		loadout = StarterRobot.newLoadout()
	end

	local rig, problems = RobotAssembler.build(loadout)
	if not rig then
		--- announce the empty bay rather than substituting something wrong (non-negotiable #10)
		Log.error("bay %s: could not build a robot -- %s", tostring(idx), table.concat(problems, "; "))
		return nil
	end
	if #problems > 0 then
		--- a partially built robot is still shown, but every missing socket is named
		Log.warn("bay %s: %d part(s) did not mount -- %s", tostring(idx), #problems, table.concat(problems, "; "))
	end
	rig.Name = SPAWNED_NAME
	rig:SetAttribute("BaseIndex", idx)
	if player then
		rig:SetAttribute("OwnerUserId", player.UserId)
	end
	rig.Parent = base

	local slots = 0
	for _ in pairs(loadout) do
		slots += 1
	end
	local srcLabel = ("%s (%d slot(s))"):format(source, slots)

	--- stance BEFORE positioning and before play, so RobotAnim captures it as rest
	local moved = RobotSpawner.applyStance(rig)

	--- 🔴 Place by the marker, and then MEASURE and correct.
	--- `PivotTo` respects a `PrimaryPart` if the model has one -- `RobotRig`'s is `RobotRoot` -- which
	--- silently overrides `WorldPivot` and can land a model far from where the CFrame said. Job 019
	--- paid for this twice. So: pivot, read the bounding box back, then translate the difference.
	if rig:IsA("Model") then
		local target = mount.Position
		--- face the room, i.e. look at the room's centre at the same height. The centre is the
		--- Arena's, not the world origin -- job 019 built the Arena at x=1556 and the room was laid
		--- around it (`Config/WorkshopLayout.CENTRE`).
		local roomCentre = Vector3.new(1556, target.Y, 0)
		rig:PivotTo(CFrame.lookAt(target, roomCentre))
		local cf, size = rig:GetBoundingBox()
		--- feet on the marker: shift so the model's base sits at the marker's Y
		local wanted = Vector3.new(target.X, target.Y + size.Y / 2, target.Z)
		rig:TranslateBy(wanted - cf.Position)
	end

	--- Anchoring is `RobotAssembler.build`'s job (root anchored, rest free, or nothing animates).
	--- Verified here rather than repeated, so the two cannot disagree silently.
	local anchored, freed = 0, 0
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Anchored then anchored += 1 else freed += 1 end
		end
	end
	if anchored ~= 1 then
		Log.warn("bay %s: %d anchored parts, expected exactly 1 (the root) -- animation may not move",
			tostring(idx), anchored)
	end

	Log.info(
		"bay %s: robot placed from %s | stance on %d joint(s) | anchored root=%d, free=%d",
		tostring(idx),
		srcLabel,
		moved,
		anchored,
		freed
	)

	--- ⚠️ Measured AFTER a couple of frames. Joint articulation is resolved by the engine, not
	--- instantly on assignment, so reading arm angles in the same tick reports the old pose and
	--- would make a working stance look broken.
	task.spawn(function()
		task.wait(0.25)
		if rig.Parent == nil then
			return
		end
		local angles = RobotSpawner.armAngles(rig)
		Log.info(
			"bay %s: arms settled at L %.1f deg / R %.1f deg above horizontal (T-pose was +11.4)",
			tostring(idx),
			angles.LeftArmPivot or 0,
			angles.RightArmPivot or 0
		)
	end)

	--- step 4: the idle. Server-side, because C0 is what replicates.
	local anim = ReplicatedStorage:FindFirstChild("Robot")
	anim = anim and anim:FindFirstChild("RobotAnim")
	if anim then
		local ok, RobotAnim = pcall(require, anim)
		if ok and RobotAnim then
			local played = RobotAnim.play(rig, "Idle")
			if played then
				Log.info("bay %s: Idle playing", tostring(idx))
			else
				Log.warn("bay %s: RobotAnim.play returned false -- no joints matched the clip", tostring(idx))
			end
		else
			Log.warn("bay %s: could not require RobotAnim: %s", tostring(idx), tostring(RobotAnim))
		end
	else
		Log.warn("ReplicatedStorage.Robot.RobotAnim not found -- robot will stand still")
	end

	return rig
end

--- Wire into BaseClaimService.start's hooks, alongside the nameplate's.
function RobotSpawner.hooks(): { onClaim: (Player, Instance) -> (), onRelease: (Player, Instance) -> () }
	return {
		onClaim = function(player: Player, base: Instance)
			--- ⚠️ OFF-THREAD, because `spawn` now waits for the DataStore load. Blocking here would
			--- hold up the claim and the nameplate too, and a bay should light up the instant it is
			--- claimed rather than after a network round trip.
			task.spawn(RobotSpawner.spawn, base, player)
		end,
		onRelease = function(_player: Player, base: Instance)
			RobotSpawner.despawn(base)
		end,
	}
end

return RobotSpawner
