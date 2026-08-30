--!strict
--[[
	Config/Perf — the reference device, the budgets, and what we can honestly measure.

	Every performance question in this repo ("is this fast enough?", "can 6 Arena robots
	hold 30fps?", "what is MaxConcurrentPull?") is meaningless until these numbers exist.
	Choosing them is the FIRST item of build group 03, not an implied prerequisite.

	⚠️ THE HONEST PART, and it changes how every later measurement must be read:

	Studio's Device Emulator does NOT simulate device performance. It gives real
	TouchEnabled, real ViewportSize, real safe-area canvas and Roblox's own TouchGui rects
	-- all of which answer LAYOUT questions completely. It renders on the developer's GPU at
	a small viewport, so its frame rate is the developer's frame rate. A "30fps in the
	emulator" reading means nothing about a phone.

	So the budgets below split into three honestly-labelled kinds:

	  TARGET    - a design decision. Not measured, not measurable here. It is what we build
	              toward and what a real device is eventually judged against.
	  MEASURED  - readable in Studio right now (memory by tag, instance and part counts,
	              draw-call proxies). Absolute values are dev-machine values; the RELATIVE
	              numbers are meaningful and are what we tune against.
	  DEVICE    - can ONLY be answered by publishing and playing on real hardware. A human
	              action. Listed so it is never quietly assumed to be done.

	Sources: docs/systems/performance/README.md · decision 0012 · decision 0016
	         the `mobile` skill (what the emulator does and does not give)
]]

local Perf = {}

--------------------------------------------------------------------------------
-- The reference device. A TARGET spec, not a machine we own.
--
-- Chosen as a mid-range Android of ~2021 vintage, which is the broad middle of the Roblox
-- mobile audience rather than its floor. If the game holds here it holds for most players;
-- if it only holds on a flagship, the design is wrong.
--------------------------------------------------------------------------------

Perf.REFERENCE_DEVICE = {
	KIND = "TARGET",
	NAME = "Mid-range Android, ~2021 (e.g. Snapdragon 6-series class, 4GB RAM)",
	RATIONALE = "the middle of the mobile audience, not its floor",
	TARGET_FPS = 30,
	TARGET_FRAME_MS = 33.3,
	ACCEPTABLE_FRAME_MS = 40.0, -- ~25fps; below this the sweep stops feeling good
}

--------------------------------------------------------------------------------
-- Budgets.
--------------------------------------------------------------------------------

Perf.BUDGET = {
	-- TARGET: design decisions. Never claim these are measured.
	FRAME_MS = 33.3,
	CLIENT_MEMORY_MB = 700, -- total client memory on the reference device
	TEXTURE_MEMORY_MB = 180, -- the kit's PBR maps are the main consumer
	SHADOW_CASTING_LIGHTS = 8, -- visible at once; from the style skill

	-- MEASURED: readable in Studio. Dev-machine absolutes, meaningful relatives.
	MAX_PARTS_IN_VIEW = 1800, -- a zone chunk plus the Workshop
	MAX_INSTANCES_STREAMED = 6000,

	-- The pull cap lives in Config/Magnet, which is its single source of truth.
	-- Do not copy it here.
}

--------------------------------------------------------------------------------
-- The measurement register.
--
-- Every performance claim this project makes should appear here with its KIND, so a
-- TARGET is never mistaken for a MEASURED and a DEVICE question is never quietly closed.
--------------------------------------------------------------------------------

export type Kind = "TARGET" | "MEASURED" | "DEVICE"

export type Measurement = {
	id: string,
	kind: Kind,
	question: string,
	status: "open" | "done",
	value: string?,
	note: string?,
}

Perf.REGISTER = {
	{
		id = "reference-device",
		kind = "TARGET",
		question = "What device is the budget written against?",
		status = "done",
		value = "mid-range Android ~2021, 30fps / 33.3ms",
		note = "a decision, not a measurement",
	},
	{
		id = "kit-texture-memory",
		kind = "MEASURED",
		question = "How much texture memory do the 8 MaterialVariants cost?",
		status = "open",
		note = "Stats:GetMemoryUsageMbForTag(GraphicsTexture), kit loaded vs not",
	},
	{
		id = "kit-part-count",
		kind = "MEASURED",
		question = "Parts per kit piece, and per assembled corridor module?",
		status = "done",
		value = "83 parts / 24 pieces; a 8-module corridor with dressing = 110 parts",
		note = "from job 005",
	},
	{
		id = "max-concurrent-pull",
		kind = "DEVICE",
		question = "How many simultaneously pulled objects hold 33ms on the reference device?",
		status = "open",
		note = "Config/Magnet ships 40/80/160 as UNTUNED guesses. Needs a real phone.",
	},
	{
		id = "arena-robot-count",
		kind = "DEVICE",
		question = "Can 6 Arena robots with parts, actuators and VFX hold 33ms?",
		status = "open",
		note = "Config/Arena.MAX_ROBOTS = 6 is the spec's number, unmeasured",
	},
	{
		id = "workshop-plus-two-zones",
		kind = "DEVICE",
		question = "Workshop + Arena + two streamed zones: memory and frame time?",
		status = "open",
		note = "the one-place bet (decision 0001) rests on this",
	},
	{
		id = "low-tier-saving",
		kind = "DEVICE",
		question = "Does dropping MaterialVariant measurably reduce frame time?",
		status = "open",
		note = "decision 0016's own stated check. If it does not, the Low tier bought nothing.",
	},
} :: { Measurement }

function Perf.open(kind: Kind?): { Measurement }
	local out = {}
	for _, m in ipairs(Perf.REGISTER) do
		if m.status == "open" and (not kind or m.kind == kind) then
			table.insert(out, m)
		end
	end
	return out
end

--- Every DEVICE question still open. These cannot be closed from Studio at all, and a
--- report that claims otherwise is wrong.
function Perf.deviceQuestionsOutstanding(): number
	return #Perf.open("DEVICE")
end

--------------------------------------------------------------------------------
-- What Studio CAN sample. Absolute values are dev-machine values; use deltas.
--------------------------------------------------------------------------------

function Perf.sample(): { [string]: number }
	local Stats = game:GetService("Stats")
	local s: { [string]: number } = {}
	local function grab(key: string, fn: () -> number)
		local ok, v = pcall(fn)
		s[key] = ok and v or -1
	end
	grab("totalMemoryMb", function()
		return Stats:GetTotalMemoryUsageMb()
	end)
	grab("textureMemoryMb", function()
		return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.GraphicsTexture)
	end)
	grab("instanceMemoryMb", function()
		return Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Instances)
	end)
	grab("physicsFps", function()
		return workspace:GetRealPhysicsFPS()
	end)
	local parts = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	s.workspaceParts = parts
	return s
end

return Perf
