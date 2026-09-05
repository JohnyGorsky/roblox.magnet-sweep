--!strict
--[[
	Robot/RobotAnim — procedural joint animation for the robot rig.

	Clips are FUNCTIONS OF TIME over the ten Motor6D joints, not authored AnimationTracks. Chunky
	mechanical motion is the correct look for a robot made of appliances
	([robot-rig §1](../../../docs/systems/robot-rig/README.md)), and this needs no Animation Editor
	pass and no uploaded assets to iterate on.

	🔴 DRIVEN THROUGH `C0`, NOT `Transform`. `Motor6D.Transform` is the channel `Animator` writes and
	it does **not** replicate on its own — a server writing Transform animates for nobody. `C0` is a
	normal replicated property, so a server-side write reaches every client. That distinction is the
	same trap the rig doc warns about for Animator tracks:

	> "If the Animator is not a descendant of a player character, its animations must be loaded and
	> started on the server to replicate."

	An Arena robot is nobody's character, so **play these on the server**.

	⚠️ Each joint's rest pose is captured on first play and every clip is applied as an OFFSET from
	it. Writing absolute CFrames would bake in whatever the rig happened to look like and break the
	moment a socket moves.
]]

local RunService = game:GetService("RunService")

local RobotAnim = {}

export type Clip = {
	length: number,
	loop: boolean,
	--- joint name -> (phase 0..1) -> rotation offset applied to that joint's rest C0
	tracks: { [string]: (number) -> CFrame },
}

local function deg(x: number): number
	return math.rad(x)
end

--- eased 0..1..0 triangle, so a loop has no visible corner at the wrap
local function pingPong(p: number): number
	local t = (p < 0.5) and (p * 2) or (2 - p * 2)
	return t * t * (3 - 2 * t) -- smoothstep
end

local function sine(p: number): number
	return math.sin(p * math.pi * 2)
end

--------------------------------------------------------------------------------
-- The three clips. [UNTUNED] -- these are readable motion, not final feel.
--------------------------------------------------------------------------------

RobotAnim.CLIPS = {
	--- A robot at rest still breathes: the torso settles, the arms drift, the head lags behind.
	--- Without the lag every joint peaks together and it reads as a bouncing toy.
	Idle = {
		length = 2.6,
		loop = true,
		tracks = {
			Waist = function(p)
				return CFrame.new(0, sine(p) * 0.12, 0)
			end,
			Neck = function(p)
				return CFrame.Angles(deg(sine(p - 0.08) * 2.5), deg(sine(p * 0.5) * 4), 0)
			end,
			LeftShoulder = function(p)
				return CFrame.Angles(0, 0, deg(3 + sine(p - 0.12) * 2.5))
			end,
			RightShoulder = function(p)
				return CFrame.Angles(0, 0, deg(-3 - sine(p - 0.12) * 2.5))
			end,
		},
	},

	--- Rolling, not walking: tier 1 and 2 mobility is wheels and skates. The body leans into travel
	--- and rocks side to side; the drives spin.
	Move = {
		length = 0.9,
		loop = true,
		tracks = {
			Root = function(p)
				return CFrame.Angles(deg(-6), 0, deg(sine(p) * 3))
			end,
			Waist = function(p)
				return CFrame.new(0, pingPong(p) * 0.25, 0) * CFrame.Angles(0, deg(sine(p) * 4), 0)
			end,
			Neck = function(p)
				return CFrame.Angles(deg(4 + sine(p) * 3), 0, 0)
			end,
			LeftShoulder = function(p)
				return CFrame.Angles(deg(sine(p) * 18), 0, deg(6))
			end,
			RightShoulder = function(p)
				return CFrame.Angles(deg(-sine(p) * 18), 0, deg(-6))
			end,
			LeftDrive = function(p)
				return CFrame.Angles(deg(p * 360), 0, 0)
			end,
			RightDrive = function(p)
				return CFrame.Angles(deg(p * 360), 0, 0)
			end,
		},
	},

	--- 🔴 The wind-up is most of the read. A swing that starts at the moment of impact has no weight;
	--- the first 35% pulls back, the next 25% is the strike, the rest recovers.
	---
	--- 🔴 ATTACK TRACKS NAME `ArmShoulder` / `ArmElbow`, NOT a side. Every Arm part carries its own
	--- animation profile — a Pipe Wrench sweeps, a Spring Puncher punches — so an attack belongs to
	--- WHICHEVER arm holds that part. Hardcoding RightShoulder meant a robot always swung the same
	--- hand no matter where its weapon was bolted. `play(rig, clip, side)` resolves these to Left or
	--- Right, and a two-weapon robot can run a different profile per arm.
	SweepLight = {
		length = 0.75,
		loop = false,
		tracks = {
			ArmShoulder = function(p)
				local a
				if p < 0.35 then
					a = -35 * (p / 0.35) -- wind back
				elseif p < 0.6 then
					local k = (p - 0.35) / 0.25
					a = -35 + 110 * k * k -- strike, accelerating
				else
					local k = (p - 0.6) / 0.4
					a = 75 - 75 * k * k -- recover
				end
				return CFrame.Angles(0, deg(a), 0)
			end,
			ArmElbow = function(p)
				local k = math.clamp((p - 0.3) / 0.3, 0, 1)
				return CFrame.Angles(0, 0, deg(-20 + 30 * k))
			end,
			Waist = function(p)
				local k = math.clamp((p - 0.3) / 0.3, 0, 1)
				return CFrame.Angles(0, deg(-8 + 22 * k), 0)
			end,
			Root = function(p)
				local k = math.clamp((p - 0.35) / 0.2, 0, 1)
				return CFrame.Angles(0, 0, deg(k * 4))
			end,
		},
	},
} :: { [string]: Clip }

--------------------------------------------------------------------------------
-- Playback
--------------------------------------------------------------------------------

type Playing = {
	rig: Instance,
	clip: Clip,
	name: string,
	t: number,
	joints: { [string]: Motor6D },
	rest: { [string]: CFrame },
	side: string?,
	onFinished: (() -> ())?,
}

local playing: { [Instance]: Playing } = {}
local connection: RBXScriptConnection? = nil

--- ⚠️ `IsA("Motor6D")` returns FALSE on an `AnimationConstraint`, which is the documented upgrade
--- path for the hit-reaction layer. Collect by NAME as well, so this keeps working if a joint is
--- ever swapped.
local function collectJoints(rig: Instance): ({ [string]: Motor6D }, { [string]: CFrame })
	local joints: { [string]: Motor6D } = {}
	local rest: { [string]: CFrame } = {}
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("Motor6D") then
			joints[d.Name] = d
			rest[d.Name] = d.C0
		end
	end
	return joints, rest
end

--- `ArmShoulder` / `ArmElbow` resolve to a real joint for the side the attack is on.
--- ⚠️ Anything else passes through unchanged, so shared clips keep naming joints directly.
local function resolve(name: string, side: string?): string
	local s = (side == "Left") and "Left" or "Right"
	if name == "ArmShoulder" then
		return s .. "Shoulder"
	elseif name == "ArmElbow" then
		return s .. "Elbow"
	end
	return name
end

local function step(dt: number)
	for rig, p in pairs(playing) do
		if not rig.Parent then
			playing[rig] = nil
			continue
		end
		p.t += dt
		local phase
		if p.clip.loop then
			phase = (p.t % p.clip.length) / p.clip.length
		else
			phase = math.min(p.t / p.clip.length, 1)
		end

		for name, fn in pairs(p.clip.tracks) do
			local real = resolve(name, p.side)
			local j = p.joints[real]
			local r = p.rest[real]
			if j and r then
				j.C0 = r * fn(phase)
			end
		end

		if not p.clip.loop and p.t >= p.clip.length then
			--- settle back to rest so the next clip blends from a known pose
			for name in pairs(p.clip.tracks) do
				local real = resolve(name, p.side)
				local j, r = p.joints[real], p.rest[real]
				if j and r then
					j.C0 = r
				end
			end
			playing[rig] = nil
			if p.onFinished then
				p.onFinished()
			end
		end
	end
	if next(playing) == nil and connection then
		connection:Disconnect()
		connection = nil
	end
end

--- Play a clip on a rig. 🔴 Call this from a SERVER script for Arena robots -- see the header.
--- `side` is "Left" or "Right" and only matters for attack clips; it says which arm swings.
function RobotAnim.play(rig: Instance, clipName: string, side: string?, onFinished: (() -> ())?): boolean
	local clip = RobotAnim.CLIPS[clipName]
	if not clip then
		return false
	end
	local joints, rest = collectJoints(rig)
	if next(joints) == nil then
		return false
	end
	--- reuse the rest pose already captured, so restarting a clip mid-motion does not bake the
	--- current animated pose in as "rest"
	local existing = playing[rig]
	if existing then
		for name, r in pairs(existing.rest) do
			rest[name] = r
		end
	end
	playing[rig] = { rig = rig, clip = clip, name = clipName, t = 0, joints = joints, rest = rest,
		side = side, onFinished = onFinished }
	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
	return true
end

function RobotAnim.stop(rig: Instance)
	local p = playing[rig]
	if p then
		for name, r in pairs(p.rest) do
			local j = p.joints[name]
			if j then
				j.C0 = r
			end
		end
	end
	playing[rig] = nil
end

function RobotAnim.isPlaying(rig: Instance): string?
	local p = playing[rig]
	return p and p.name or nil
end

return RobotAnim
