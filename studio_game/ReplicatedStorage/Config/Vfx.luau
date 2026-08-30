--!strict
--[[
	Config/Vfx — the magnet's five visual states, as data.

	Spec §14: idle · pulling · high flow · MAGNET RUSH · Overcharge. The magnet is the game's
	logo, its icon and its cursor, so these are the most-seen effects in the game and they run
	CONTINUOUSLY — which makes them the ones that must be cheapest.

	systems/vfx-lighting is explicit about the budget: "Magnet field + idle arcs — one emitter,
	one beam pair." Not one emitter per state. The state changes the SETTINGS of the same
	emitter; nothing is created or destroyed at runtime.

	⚠️ Textures here are engine built-ins (`rbxasset://`), not marketplace ids. That is a
	deliberate shipping choice and not a placeholder: they are guaranteed present, cost no
	fetch, and cannot be the wrong asset. Custom particle art is a later upgrade and is listed
	in the asset table as such. Contrast the audio rule, where a placeholder is forbidden
	outright because a wrong SOUND is much harder to notice than a missing one.

	Sources: docs/systems/vfx-lighting/README.md · spec §14, §71 · decisions 0011, 0016
]]

local Vfx = {}

export type StateName = "Idle" | "Pulling" | "HighFlow" | "Rush" | "Overcharge"

export type State = {
	--- Field emitter
	rate: number, -- particles/sec on the magnet head
	speed: number, -- stud/sec outward drift
	size: number, -- particle size in studs
	lifetime: number,
	--- The red/cyan pole arcs
	beamWidth: number,
	beamTransparency: number, -- 1 = invisible
	--- The point light on the magnet head. It is one of the few HERO lights allowed to cast
	--- shadows (vfx-lighting: <= 8 at once, the Arena Core, the magnet, a Hub gate).
	lightRange: number,
	lightBrightness: number,
	--- Multiplier on the collection sound's volume, so the mix rises with the state.
	soundVolume: number,
}

--- ⚠️ Ordered weakest to strongest, and `Vfx.ORDER` is the single place that order is written
--- down. A state machine that compares state NAMES with `>` silently does nothing.
Vfx.ORDER = { "Idle", "Pulling", "HighFlow", "Rush", "Overcharge" } :: { StateName }

Vfx.STATES = {
	--- Standing still. The magnet is alive but quiet: this is 95% of the session and it is the
	--- one that decides whether the effect is affordable at all.
	Idle = {
		rate = 6,
		speed = 1.5,
		size = 0.35,
		lifetime = 0.5,
		beamWidth = 0.10,
		beamTransparency = 0.65,
		lightRange = 7,
		lightBrightness = 0.8,
		soundVolume = 1.0,
	},
	--- At least one object in flight.
	Pulling = {
		rate = 24,
		speed = 4,
		size = 0.45,
		lifetime = 0.6,
		beamWidth = 0.16,
		beamTransparency = 0.35,
		lightRange = 10,
		lightBrightness = 1.4,
		soundVolume = 1.0,
	},
	--- Flow tier 3+. The build toward a Rush has to be visible before it lands, or the Rush
	--- arrives from nowhere.
	HighFlow = {
		rate = 55,
		speed = 6,
		size = 0.55,
		lifetime = 0.7,
		beamWidth = 0.24,
		beamTransparency = 0.15,
		lightRange = 14,
		lightBrightness = 2.2,
		soundVolume = 1.1,
	},
	--- MAGNET RUSH.
	Rush = {
		rate = 120,
		speed = 10,
		size = 0.7,
		lifetime = 0.8,
		beamWidth = 0.36,
		beamTransparency = 0.0,
		lightRange = 20,
		lightBrightness = 3.2,
		soundVolume = 1.25,
	},
	--- Overcharge — "maximum visual state, nearby objects simultaneously react" (spec §14).
	--- Paid, PvE only, and code-gated away from the Arena (decision 0011).
	Overcharge = {
		rate = 200,
		speed = 14,
		size = 0.85,
		lifetime = 0.9,
		beamWidth = 0.5,
		beamTransparency = 0.0,
		lightRange = 26,
		lightBrightness = 4.5,
		soundVolume = 1.4,
	},
} :: { [StateName]: State }

--- Flow tier at or above which the magnet reads as HighFlow.
Vfx.HIGH_FLOW_TIER = 3

--- Seconds to blend between states. Snapping between rates reads as a bug; a Rush should
--- ARRIVE rather than cut.
Vfx.BLEND_SECONDS = 0.35

--- Engine built-in textures. See the header note on why these are not placeholders.
Vfx.TEXTURE = {
	FIELD = "rbxasset://textures/particles/sparkles_main.dds",
	BEAM = "rbxasset://textures/particles/smoke_main.dds",
}

--- The magnet's two pole colours. NEVER recoloured outside a purchased skin — this pair is the
--- logo, the game icon and the Arena Core.
Vfx.RED = Color3.fromHex("#E03A2F")
Vfx.CYAN = Color3.fromHex("#41D8FF")

function Vfx.get(name: StateName): State
	return Vfx.STATES[name] or Vfx.STATES.Idle
end

--- Which state a magnet is in, from the facts. One function, so the client's renderer and any
--- future audio mix cannot disagree about what the magnet is doing.
function Vfx.classify(opts: { overcharge: boolean?, rush: boolean?, flowTier: number?, pulling: number? }): StateName
	if opts.overcharge then
		return "Overcharge"
	elseif opts.rush then
		return "Rush"
	elseif (opts.flowTier or 0) >= Vfx.HIGH_FLOW_TIER then
		return "HighFlow"
	elseif (opts.pulling or 0) > 0 then
		return "Pulling"
	end
	return "Idle"
end

--- Every field of `State`, so a startup audit can prove each one is consumed. A field in a
--- config table that nothing reads is a lie in a table -- job 009 found three of them in
--- Config/Quality (`depthOfField` was worse: read, then overwritten with the opposite value).
Vfx.FIELDS = {
	"rate", "speed", "size", "lifetime",
	"beamWidth", "beamTransparency",
	"lightRange", "lightBrightness",
	"soundVolume",
}

--- Fails when a state is missing a field, or carries one that is not in FIELDS.
function Vfx.audit(): { string }
	local problems = {}
	for _, name in ipairs(Vfx.ORDER) do
		local state = Vfx.STATES[name]
		if not state then
			table.insert(problems, ("state %s is missing entirely"):format(name))
			continue
		end
		for _, field in ipairs(Vfx.FIELDS) do
			if (state :: any)[field] == nil then
				table.insert(problems, ("%s.%s is missing"):format(name, field))
			end
		end
		for key in pairs(state :: any) do
			if not table.find(Vfx.FIELDS, key) then
				table.insert(problems, ("%s.%s is not a declared field"):format(name, tostring(key)))
			end
		end
	end
	-- the states must actually escalate, or "maximum visual state" is a label
	for i = 2, #Vfx.ORDER do
		local prev, cur = Vfx.STATES[Vfx.ORDER[i - 1]], Vfx.STATES[Vfx.ORDER[i]]
		if prev and cur and cur.rate <= prev.rate then
			table.insert(problems, ("%s does not escalate over %s (rate %d vs %d)")
				:format(Vfx.ORDER[i], Vfx.ORDER[i - 1], cur.rate, prev.rate))
		end
	end
	return problems
end

return Vfx
