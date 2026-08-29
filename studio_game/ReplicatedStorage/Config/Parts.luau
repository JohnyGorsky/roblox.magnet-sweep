--!strict
--[[
	Config/Parts — the robot part SCHEMA, slots, rarity and animation profiles.

	Decision 0004: parts are content, the rig is the engine. This module defines the SHAPE
	a part must have. It deliberately does NOT contain the 96-row catalog -- those rows are
	authored per tier alongside that tier's models (build groups 09 and 13), and none of
	them has combat stats yet.

	Sources: docs/systems/robot-rig/README.md · docs/content/parts-catalog.md
	         decision 0004 · decision 0015 · spec §26-§38
]]

export type Slot = "Head" | "Core" | "Body" | "Arm" | "Mobility" | "Back"
export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"
export type WeightClass = "Small" | "Medium" | "Heavy" | "Extreme"

export type CombatStats = {
	damage: number,
	attackSpeed: number,
	knockback: number,
	range: number,
	hp: number,
	armor: number,
}

export type PartDef = {
	partId: string, -- SCREAMING_SNAKE, e.g. "GIANT_SPOON"
	name: string, -- display name
	tier: number,
	slot: Slot,
	rarity: Rarity,
	specRarity: Rarity?, -- the SPEC's own grade, preserved per decision 0015. nil = unchanged.
	weight: WeightClass, -- drives the CARRY penalty, never the robot's mass
	powerRequired: number, -- Magnet Power needed to detach it
	animationProfile: string?, -- Arm parts only
	mobilityProfile: string?, -- Mobility parts only
	combat: CombatStats?, -- passive parts (Head/Core/Body/Back) may omit
	vfxProfile: string?,
	soundProfile: string?,
	signatureEffect: string,
}

local Parts = {}

--------------------------------------------------------------------------------
-- Slots. Seven sockets, one per slot -- Arm appears twice on the rig.
-- EVERY Arm part takes exactly ONE socket. There are no two-handed parts: a TwoHanded
-- flag would add a special case to the builder, the rig, the profile system and every
-- stat row, which is precisely what decision 0004 forbids.
--------------------------------------------------------------------------------

Parts.SOCKETS = {
	"HeadSocket",
	"CoreSocket",
	"BodySocket",
	"LeftArmSocket",
	"RightArmSocket",
	"MobilitySocket",
	"BackSocket",
}

Parts.SLOT_TO_SOCKETS = {
	Head = { "HeadSocket" },
	Core = { "CoreSocket" },
	Body = { "BodySocket" },
	Arm = { "LeftArmSocket", "RightArmSocket" }, -- either; both accept any Arm part
	Mobility = { "MobilitySocket" },
	Back = { "BackSocket" },
} :: { [Slot]: { string } }

--------------------------------------------------------------------------------
-- Rarity. Re-graded per decision 0015 -- the spec made "Rare" the most common grade in
-- the game, which left the colour ramp meaningless.
--------------------------------------------------------------------------------

Parts.RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" } :: { Rarity }

Parts.RARITY_COLOR = {
	Common = Color3.fromHex("#B8C2CC"),
	Uncommon = Color3.fromHex("#3FD64B"),
	Rare = Color3.fromHex("#41D8FF"),
	Epic = Color3.fromHex("#C46BFF"),
	Legendary = Color3.fromHex("#FFC21A"),
	Mythic = Color3.fromHex("#FF3D7F"),
} :: { [Rarity]: Color3 }

local rarityRank: { [Rarity]: number } = {}
for i, r in ipairs(Parts.RARITY_ORDER) do
	rarityRank[r] = i
end

local WEIGHT_CLASSES: { [string]: boolean } = { Small = true, Medium = true, Heavy = true, Extreme = true }

function Parts.rarityRank(r: Rarity): number
	return rarityRank[r] or 0
end

--------------------------------------------------------------------------------
-- Animation profiles. ~10 combat profiles cover all 33 Arm parts; the other 63 are
-- passive or mobility. This ratio is the whole point of decision 0004.
--------------------------------------------------------------------------------

Parts.ANIMATION_PROFILES = {
	"SweepLight",
	"SweepHeavy",
	"SmashHeavy",
	"PunchFast",
	"ThrustContinuous",
	"Shield",
	"RangedCannon",
	"RangedRapid",
	"GrabPull",
	"ChargeBody",
}

Parts.MOBILITY_PROFILES = { "Wheels", "Legs", "Tracks", "Hover" }

--- One shared locomotion clip; each sub-rig handles its own motion. Only Legs needs a
--- real walk cycle -- wheels spin on a HingeConstraint, tracks scroll a texture, hover
--- bobs procedurally.
Parts.SHARED_CLIPS = {
	"Idle",
	"Move",
	"HitFront",
	"HitBack",
	"Knockback",
	"Stunned",
	"ArenaEnter",
	"Victory",
	"Defeat",
}

local ANIM_SET: { [string]: boolean } = {}
for _, p in ipairs(Parts.ANIMATION_PROFILES) do
	ANIM_SET[p] = true
end
local MOBILITY_SET: { [string]: boolean } = {}
for _, p in ipairs(Parts.MOBILITY_PROFILES) do
	MOBILITY_SET[p] = true
end

--------------------------------------------------------------------------------
-- Mounting. Mounted parts are VISUAL: stats come from the data row, never the geometry.
-- Without this a Vault Door build is unplayable and an Excavator Bucket tips the robot.
--------------------------------------------------------------------------------

Parts.MOUNT = {
	ATTACHMENT_NAME = "RobotMount",
	MASSLESS = true,
	CAN_COLLIDE = false,
	CAN_QUERY = false, -- only takes effect once CanCollide is false
	-- ⚠️ CanTouch cuts BOTH ways, and the two failures look nothing alike:
	--   * connecting Touched while CanTouch is ALREADY false -> THROWS.
	--   * setting CanTouch = false AFTER connecting -> silently disconnects and removes
	--     the TouchTransmitter. No error, no touch events, ever.
	-- Mounted parts want no touch handling at all, so set it at mount time and never
	-- connect Touched to them.
	CAN_TOUCH = false,
}

--------------------------------------------------------------------------------
-- Reinforcement (§40): a duplicate is never wasted.
--------------------------------------------------------------------------------

Parts.REINFORCE = {
	MAX_MARK = 3, -- Mk I -> Mk II -> Mk III
	STAT_BONUS_PER_MARK = 0.08, -- +8% to the part's own stats per mark
	DUPLICATES_PER_MARK = { 1, 3 }, -- duplicates needed for Mk II, then Mk III
}

--------------------------------------------------------------------------------
-- Validation. Used by the loader so a malformed part row fails loudly at startup
-- rather than silently at runtime.
--------------------------------------------------------------------------------

--- Takes `any`, NOT PartDef: its entire purpose is rejecting rows that are not PartDefs,
--- and typing the parameter as PartDef makes every guard here dead code to the checker.
function Parts.validate(def: any): (boolean, string?)
	if type(def) ~= "table" then
		return false, "part definition must be a table"
	end
	local id = def.partId
	if type(id) ~= "string" or not id:match("^[A-Z][A-Z0-9_]*$") then
		return false, ("partId must be SCREAMING_SNAKE, got %s"):format(tostring(id))
	end
	if not Parts.SLOT_TO_SOCKETS[def.slot] then
		return false, ("unknown slot %q"):format(tostring(def.slot))
	end
	if not rarityRank[def.rarity] then
		return false, ("unknown rarity %q"):format(tostring(def.rarity))
	end
	if def.specRarity ~= nil and not rarityRank[def.specRarity] then
		return false, ("unknown specRarity %q"):format(tostring(def.specRarity))
	end
	-- %d throws on a fractional number, so the range check must not format until it knows
	if type(def.tier) ~= "number" or def.tier % 1 ~= 0 or def.tier < 1 or def.tier > 12 then
		return false, ("tier must be an integer 1-12, got %s"):format(tostring(def.tier))
	end
	if type(def.powerRequired) ~= "number" or def.powerRequired < 0 then
		return false, ("powerRequired must be a non-negative number, got %s"):format(tostring(def.powerRequired))
	end
	if not WEIGHT_CLASSES[def.weight] then
		return false, ("unknown weight class %q"):format(tostring(def.weight))
	end
	if def.slot == "Arm" then
		if not def.animationProfile then
			return false, "Arm parts need an animationProfile"
		end
	elseif def.animationProfile then
		return false, "only Arm parts may set an animationProfile"
	end
	if def.animationProfile and not ANIM_SET[def.animationProfile] then
		return false, ("unknown animationProfile %q"):format(tostring(def.animationProfile))
	end
	if def.slot == "Mobility" then
		if not def.mobilityProfile then
			return false, "Mobility parts need a mobilityProfile"
		end
	elseif def.mobilityProfile then
		return false, "only Mobility parts may set a mobilityProfile"
	end
	if def.mobilityProfile and not MOBILITY_SET[def.mobilityProfile] then
		return false, ("unknown mobilityProfile %q"):format(tostring(def.mobilityProfile))
	end
	return true
end

return Parts
