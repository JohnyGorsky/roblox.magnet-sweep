--!strict
--[[
	Config/PartMounts — where every robot part meets its socket.

	🔴 HAND-AUTHORED BY THE OWNER, 2026-09-05, by posing each part on a real robot in the editor and
	reading the result back. These numbers are not derivable: three separate attempts to compute them
	(bounding-box extremes, longest-axis hang, mount-to-centre direction) all produced arms mounted by
	their middle, jaws pointing skyward, and tools buried in the chest.

	⚠️ A bounding box says where a mesh IS, never where its handle is. Do not "improve" these values
	with a rule -- if a part hangs wrong, pose it in the editor and re-export.

	`mount` is a CFrame as { x, y, z, r00..r22 }, in the part's LOCAL space, at the size in `size`.
	Assembly is: part.CFrame = socket.WorldCFrame * mount:Inverse()

	🔴 `side` matters for ARMS. A pose authored on the left socket points inward if used on the right,
	so the builder turns the socket frame 180 degrees about the vertical when the sides differ.

	Sources: docs/systems/robot-rig §2 (one attachment per part) · decision 0004
]]

export type Mount = {
	slot: string,
	side: string?, -- "Left" | "Right" for arms; nil where the part is symmetric
	derived: boolean, -- true = inferred from a sibling's convention, NOT posed. Re-pose if it looks wrong.
	size: { number }, -- the size the offsets were authored at; rescale proportionally
	mount: { number }, -- x, y, z, then the 3x3 rotation, row-major
}

local PartMounts = {}

PartMounts.BY_ID = {
	BUILDING_BLOCK_CHEST = { slot = "Body", side = nil, derived = false, size = { 0.9609, 1.0000, 0.9180 },
		mount = { 0.00000, 0.00000, 0.00000, -0.999905, 0.000000, -0.013754, 0.000000, 1.000000, 0.000000, 0.013754, 0.000000, -0.999905 } },
	CASTER_WHEELS = { slot = "Mobility", side = nil, derived = false, size = { 6.6584, 6.1115, 7.0002 },
		mount = { 0.00000, 3.05577, 0.00000, -0.000000, 0.000000, 1.000000, 0.000000, 1.000000, 0.000000, -1.000000, 0.000000, -0.000000 } },
	GOLDEN_GEAR = { slot = "Head", side = nil, derived = false, size = { 7.0000, 7.0000, 1.1416 },
		mount = { 0.00000, -3.60957, 0.00000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000 } },
	--- ⚠️ never posed: dropped from the demo line-ups until it is
	GRABBER_CLAW = { slot = "Arm", side = nil, derived = true, size = { 0.5352, 0.5508, 1.0000 },
		mount = { 0.00000, -0.00000, 0.50000, 1.000000, 0.000000, 0.000000, 0.000000, 0.026421, -0.999651, 0.000000, 0.999651, 0.026421 } },
	JACK_IN_THE_BOX_LAUNCHER = { slot = "Arm", side = "Right", derived = false, size = { 1.0000, 1.0000, 0.5645 },
		mount = { 0.07810, 0.05853, 0.09503, -0.471776, 0.872851, 0.124734, 0.843855, 0.487987, -0.223108, -0.255608, -0.000000, -0.966780 } },
	MAGNET_COIL = { slot = "Back", side = nil, derived = false, size = { 6.9454, 6.6720, 7.0001 },
		mount = { 0.00000, 0.28589, -3.48840, 1.000000, 0.000000, 0.000000, 0.000000, -0.996658, 0.081682, 0.000000, -0.081682, -0.996658 } },
	MINI_MOTOR = { slot = "Core", side = nil, derived = false, size = { 6.1250, 5.8242, 7.0000 },
		mount = { 0.00000, 0.00000, -3.50030, -1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, -0.000000, 0.000000, -1.000000 } },
	PAINT_DRUM = { slot = "Body", side = nil, derived = false, size = { 7.0000, 7.0000, 4.7031 },
		mount = { 0.00000, 0.00000, 0.00000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000 } },
	PIPE_WRENCH = { slot = "Arm", side = "Left", derived = false, size = { 5.8105, 7.0000, 1.4014 },
		mount = { -1.67139, -0.48372, 0.00008, -0.551190, -0.834380, 0.000000, 0.834380, -0.551190, 0.000000, 0.000000, 0.000000, 1.000000 } },
	PROPELLER_PACK = { slot = "Back", side = nil, derived = false, size = { 0.8496, 1.0000, 0.7422 },
		mount = { 0.00000, -0.55752, -0.02967, 1.000000, 0.000000, 0.000000, 0.000000, -0.053150, -0.998587, 0.000000, 0.998587, -0.053150 } },
	ROLLER_SKATES = { slot = "Mobility", side = nil, derived = false, size = { 1.0000, 0.8848, 1.0000 },
		mount = { 0.00000, 0.55446, 0.15304, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000 } },
	SPRING_PUNCHER = { slot = "Arm", side = "Right", derived = false, size = { 3.0557, 7.0001, 5.4005 },
		mount = { -1.10258, 0.16142, 3.02874, 0.136652, -0.955135, 0.262763, 0.983912, 0.100051, -0.148013, 0.115082, 0.278762, 0.953440 } },
	TOY_CAMERA = { slot = "Head", side = nil, derived = false, size = { 0.9922, 1.0000, 0.6387 },
		mount = { 0.00000, -0.70827, 0.08051, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000 } },
	TOY_HAMMER = { slot = "Arm", side = "Left", derived = false, size = { 0.5176, 1.0000, 0.4209 },
		mount = { 0.21155, 0.04510, 0.00000, 0.034133, 0.999417, -0.000000, -0.999417, 0.034133, 0.000000, 0.000000, 0.000000, 1.000000 } },
	WIND_UP_KEY = { slot = "Core", side = nil, derived = false, size = { 0.5723, 0.7949, 1.0000 },
		mount = { 0.00000, 0.00000, -0.59095, -1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, -0.000000, 0.000000, -1.000000 } },
	--- ⚠️ derived from GOLDEN_GEAR's convention (heads sit on their base), not posed by hand
	WORK_LAMP = { slot = "Head", side = nil, derived = true, size = { 4.1152, 7.0000, 5.0449 },
		mount = { 0.00000, -3.50000, 0.00000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000 } },
} :: { [string]: Mount }

--- Rebuild a stored mount as a CFrame in the part's local space.
function PartMounts.cframe(id: string): CFrame?
	local row = PartMounts.BY_ID[id]
	if not row then
		return nil
	end
	local m = row.mount
	return CFrame.new(m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9], m[10], m[11], m[12])
end

--- The socket frame to mount against. 🔴 For an arm used on the side it was NOT posed on, the frame
--- turns 180 degrees about the vertical -- otherwise the tool points into the robot's own chest.
function PartMounts.socketFrame(id: string, socketName: string, socketCF: CFrame): CFrame
	local row = PartMounts.BY_ID[id]
	if not row or not row.side then
		return socketCF
	end
	local want = (socketName == "LeftArmSocket") and "Left" or "Right"
	if want ~= row.side then
		return socketCF * CFrame.Angles(0, math.pi, 0)
	end
	return socketCF
end

--- Which entries still need a real pose. Anything listed here will look wrong sooner or later.
function PartMounts.unposed(): { string }
	local out = {}
	for id, row in pairs(PartMounts.BY_ID) do
		if row.derived then
			table.insert(out, id)
		end
	end
	table.sort(out)
	return out
end

return PartMounts
