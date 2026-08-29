--!strict
--[[
	Config/Arena — the persistent Scrap Arena: slots, Heat, repair limits, grace period.

	Arena Heat and the field-repair cap are not flavour. They are the MECHANICAL enforcement
	of decision 0011 (Robux never buys Arena power): together they make indefinite Core
	control impossible for any amount of scrap or money.

	Sources: docs/systems/arena/README.md · decision 0010 · decision 0011
	         spec §43-§52
]]

local Arena = {}

--------------------------------------------------------------------------------
-- Capacity. One robot per player (decision 0010).
--
-- MAX_ROBOTS is the spec's 4-6 target and is PROVISIONAL: nothing has been measured.
-- It is the single largest concurrent render cost in the game. Measure on the reference
-- device before committing to the upper end.
--------------------------------------------------------------------------------

Arena.MAX_ROBOTS = 6
Arena.MEASURED = false -- flip to true only once the frame-time check has actually run
Arena.QUEUE_LIMIT = 8

--------------------------------------------------------------------------------
-- Arena Heat (§50) — the turnover guarantee.
--
-- The longer a robot holds the Core, the more damage it takes and the less repair helps.
-- Bands are cumulative from the moment control is taken.
--------------------------------------------------------------------------------

export type HeatBand = { untilSeconds: number, damageTaken: number, repairEfficiency: number }

Arena.HEAT_BANDS = {
	{ untilSeconds = 90, damageTaken = 1.00, repairEfficiency = 1.00 },
	{ untilSeconds = 180, damageTaken = 1.10, repairEfficiency = 0.85 },
	{ untilSeconds = 300, damageTaken = 1.20, repairEfficiency = 0.65 },
	{ untilSeconds = math.huge, damageTaken = 1.35, repairEfficiency = 0.45 },
} :: { HeatBand }

function Arena.heatFor(holdSeconds: number): HeatBand
	for _, band in ipairs(Arena.HEAT_BANDS) do
		if holdSeconds < band.untilSeconds then
			return band
		end
	end
	return Arena.HEAT_BANDS[#Arena.HEAT_BANDS]
end

--------------------------------------------------------------------------------
-- Field repair through the Repair Chute (§49). Rate-limited ON PURPOSE.
--------------------------------------------------------------------------------

Arena.FIELD_REPAIR = {
	HP_PER_FEED = 250,
	COOLDOWN = 12, -- seconds between feeds
	MAX_HP_PER_WINDOW = 1000, -- cap per window, regardless of scrap spent
	WINDOW = 60, -- seconds
	EFFICIENCY = 0.7, -- field repair is worse than the Bay, before Heat is applied
}

--------------------------------------------------------------------------------
-- When the owner leaves the server.
--
-- The robot fights on briefly so a fight never ends mid-swing and the Core changes hands
-- honestly -- then it is withdrawn with its HP saved AS IT STANDS. Nobody bleeds robot HP
-- (which costs real scrap to repair) while offline and unable to react.
--------------------------------------------------------------------------------

Arena.OWNER_LEFT = {
	GRACE_PERIOD = 120, -- seconds
	SAVE_HP_ON_WITHDRAW = true,
	REJOIN_RESUMES = true, -- rejoining inside the grace period just carries on
}

--------------------------------------------------------------------------------
-- Combat. Hit detection reads AI state + RobotRoot CFrame against a SCRIPTED hitbox --
-- never a limb position. A server-spawned rig holds its rest pose, so "raycast from the
-- spoon's tip" is always the bug.
--------------------------------------------------------------------------------

Arena.COMBAT = {
	TICK = 0.1, -- seconds between AI/combat evaluations
	CORE_CONTROL_RADIUS = 18, -- studs from the Arena Core to count as holding it
	CONTEST_GRACE = 2.0, -- seconds an enemy must be inside before control flips
	KNOCKBACK_RELEASE = 0.4, -- seconds the aligner's force is dropped for
	BASE_HP = 3200, -- §47's worked example; per-part armour modifies it
}

--- AlignPosition/AlignOrientation drive an UNANCHORED root, which is what makes knockback
--- real. MaxForce is only used when RigidityEnabled is false -- on a rigid aligner,
--- dropping it for knockback is a silent no-op.
Arena.MOVER = {
	RIGIDITY_ENABLED = false, -- REQUIRED: knockback works by dropping MaxForce
	MAX_FORCE = 120000,
	MAX_TORQUE = 90000,
	RESPONSIVENESS = 25,
	APPLY_AT_CENTER_OF_MASS = true, -- default false adds torque you did not ask for
}

--------------------------------------------------------------------------------
-- Damage visual stages (§60). Parts NEVER permanently disappear -- decorative panels may
-- pop off, but the owned part is untouched. The Arena robot is a disposable clone.
--------------------------------------------------------------------------------

Arena.DAMAGE_STAGES = {
	{ atFraction = 0.75, effect = "MinorSparks" },
	{ atFraction = 0.50, effect = "SparksAndScratches" },
	{ atFraction = 0.25, effect = "Smoke" },
	{ atFraction = 0.10, effect = "HeavyElectricity" },
	{ atFraction = 0.00, effect = "Collapse" },
}

--------------------------------------------------------------------------------
-- Rewards for holding the Core (§45). Rates are placeholders pending economy tuning --
-- the spec says only "rewards accumulate over time" and gives no numbers.
--------------------------------------------------------------------------------

Arena.CONTROL_REWARD = {
	COINS_PER_MINUTE = 120,
	FAME_PER_MINUTE = 10,
	TUNED = false, -- these are guesses; flip when the economy pass sets them
}

return Arena
