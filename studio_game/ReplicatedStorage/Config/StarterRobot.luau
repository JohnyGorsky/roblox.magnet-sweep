--!strict
--[[
	Config/StarterRobot — the five parts a new player is given, and nothing else.

	`docs/systems/robot-assembly` decided on 2026-09-05 that the game GIVES a new player a fixed,
	assembled robot -- **Head, Core, Body, one Arm, one Mobility** -- because no tier has a Common
	part for every slot, so the catalog cannot supply a first robot on its own. It left one thing
	open, in its own words:

	> *"Still to decide: which specific parts the starter loadout uses, and whether they are real
	> catalog entries (findable, recyclable) or a distinct 'rusty starter' set that exists only at
	> spawn."*

	🔴 THE OWNER CHOSE THE RUSTY SET (2026-09-06). So these five are deliberately **NOT** catalog
	parts:

	- **Never found in the world.** They carry no `zone`, so no spawn pool can ever roll them.
	- **Worth nothing at the Recycler** (`scrapValue = 0`). A new player cannot strip their own
	  starter for scrap in the first minute, which the real-catalog option would have allowed.
	- **Every part you find is therefore a strict upgrade**, which is the whole point: replacing a
	  rusty stub reads as progress, whereas replacing a real Common reads as a sideways trade.

	🔴 THEY LIVE HERE, NOT IN `PartsCatalog`, AND THAT IS NOT A SHORTCUT.
	`Config/PartsCatalog.luau` is **generated** from `docs/content/parts-catalog.md` by
	`tools/gen-parts-catalog.py` and says "do not hand-edit". More importantly, the catalog is the
	96 findable parts -- putting a never-findable part in it would contradict the definition of both.

	⚠️ These reuse the SAME FIVE MESHES as their catalog cousins, tinted rust. That is deliberate and
	costs no Meshy credits: a rusty paint drum and a good paint drum should read as the same object in
	different condition, which is exactly what "everything found afterwards replaces a piece" means.

	Every def here is validated against `Config/Parts.validate`, which is STRICTER than
	`PartsCatalog.validate` -- it also requires `tier`, `powerRequired`, `weight`, and an
	`animationProfile` on Arms / `mobilityProfile` on Mobility.

	Sources: docs/systems/robot-assembly · decision 0004 (parts are content) · Jobs/022
]]

local StarterRobot = {}

--- 🔴 `scrapValue = 0` is the mechanism, not a decoration. Anything that pays out for a part must
--- read this field rather than deriving a value from rarity, or the rusty set becomes farmable.
StarterRobot.SCRAP_VALUE = 0

--- Rust, from the style palette (`#8A4B2A`, "oxide brown -- wear, salvage, the *homemade* robot").
StarterRobot.TINT = Color3.fromHex("8A4B2A")

--- `MS_Rust` is CorrodedMetal at metalness 0.7 / roughness 0.75 -- the style kit's "salvage, old
--- parts" surface. Applied through `MaterialKit`, never by hand, because two of the nine surfaces
--- are not what their name suggests.
StarterRobot.SURFACE = "Rust"

--- The rig template these mount onto. A Model, so it lives only in the .rbxl -- see the
--- RobotAssembler header. Named here so there is one place to change it.
StarterRobot.RIG_TEMPLATE = "RobotRig"

--- The five defs. `mesh` names an entry in `ServerStorage.ImportedMeshes`.
---
--- ⚠️ `starterOnly = true` is what every economy path must check. It is set on all five rather than
--- inferred from the id prefix, because a string prefix is not a contract.
StarterRobot.PARTS = {
	RUSTY_LAMP = {
		partId = "RUSTY_LAMP",
		name = "Rusty Work Lamp",
		slot = "Head",
		tier = 1,
		rarity = "Common",
		powerRequired = 0,
		weight = "Small",
		mesh = "work_lamp",
		--- MEASURED off DemoRoom.10_Robots.2_Starter, the assembly the owner approved.
		--- Uniform on all three axes, which is why one number covers it.
		scale = 3.20,
		--- Where this part's RobotMount sits ON THE PART, as a fraction of its half-extent:
		--- 0 = dead centre, +-1 = on the face. A bounding box says where the object is, not
		--- where its socket is -- job 019 paid for that twice.
		mountFrac = Vector3.new(0.00, -1.00, 0.00),
		starterOnly = true,
		scrapValue = 0,
		effect = "barely works",
	},
	RUSTY_MOTOR = {
		partId = "RUSTY_MOTOR",
		name = "Seized Mini Motor",
		slot = "Core",
		tier = 1,
		rarity = "Common",
		powerRequired = 0,
		weight = "Small",
		mesh = "mini_motor",
		--- MEASURED off DemoRoom.10_Robots.2_Starter, the assembly the owner approved.
		--- Uniform on all three axes, which is why one number covers it.
		scale = 2.60,
		--- Where this part's RobotMount sits ON THE PART, as a fraction of its half-extent:
		--- 0 = dead centre, +-1 = on the face. A bounding box says where the object is, not
		--- where its socket is -- job 019 paid for that twice.
		mountFrac = Vector3.new(0.00, 0.00, -1.00),
		starterOnly = true,
		scrapValue = 0,
		effect = "no bonus",
	},
	RUSTY_DRUM = {
		partId = "RUSTY_DRUM",
		name = "Dented Paint Drum",
		slot = "Body",
		tier = 1,
		rarity = "Common",
		powerRequired = 0,
		weight = "Medium",
		mesh = "paint_drum",
		--- MEASURED off DemoRoom.10_Robots.2_Starter, the assembly the owner approved.
		--- Uniform on all three axes, which is why one number covers it.
		scale = 6.50,
		--- Where this part's RobotMount sits ON THE PART, as a fraction of its half-extent:
		--- 0 = dead centre, +-1 = on the face. A bounding box says where the object is, not
		--- where its socket is -- job 019 paid for that twice.
		mountFrac = Vector3.new(0.00, 0.00, 0.00),
		starterOnly = true,
		scrapValue = 0,
		effect = "minimum HP",
	},
	RUSTY_WRENCH = {
		partId = "RUSTY_WRENCH",
		name = "Bent Pipe Wrench",
		slot = "Arm",
		tier = 1,
		rarity = "Common",
		powerRequired = 0,
		weight = "Medium",
		--- must be one of `Parts.ANIMATION_PROFILES`; `SweepLight` is what the real PIPE_WRENCH uses,
		--- so the starter animates with a clip that already exists rather than needing a new one.
		animationProfile = "SweepLight",
		mesh = "pipe_wrench",
		--- MEASURED off DemoRoom.10_Robots.2_Starter, the assembly the owner approved.
		--- Uniform on all three axes, which is why one number covers it.
		scale = 5.50,
		--- Where this part's RobotMount sits ON THE PART, as a fraction of its half-extent:
		--- 0 = dead centre, +-1 = on the face. A bounding box says where the object is, not
		--- where its socket is -- job 019 paid for that twice.
		mountFrac = Vector3.new(-0.58, -0.14, 0.00),
		starterOnly = true,
		scrapValue = 0,
		effect = "weak melee",
	},
	RUSTY_CASTERS = {
		partId = "RUSTY_CASTERS",
		name = "Squeaky Caster Wheels",
		slot = "Mobility",
		tier = 1,
		rarity = "Common",
		powerRequired = 0,
		weight = "Small",
		--- must be one of `Parts.MOBILITY_PROFILES`
		mobilityProfile = "Wheels",
		mesh = "caster_wheels",
		--- MEASURED off DemoRoom.10_Robots.2_Starter, the assembly the owner approved.
		--- Uniform on all three axes, which is why one number covers it.
		scale = 4.50,
		--- Where this part's RobotMount sits ON THE PART, as a fraction of its half-extent:
		--- 0 = dead centre, +-1 = on the face. A bounding box says where the object is, not
		--- where its socket is -- job 019 paid for that twice.
		mountFrac = Vector3.new(0.00, 1.00, 0.00),
		starterOnly = true,
		scrapValue = 0,
		effect = "slow",
	},
}

--- The loadout, as `slot -> partId`. This exact table shape is what a profile saves, so a saved
--- robot is five short strings and survives any change to the meshes behind them.
---
--- ⚠️ NO `Back` ENTRY, and that is the decision, not an omission: the starter is five parts, and
--- tier 1's only Back part (`MAGNET_COIL`) is Rare.
StarterRobot.LOADOUT = {
	Head = "RUSTY_LAMP",
	Core = "RUSTY_MOTOR",
	Body = "RUSTY_DRUM",
	Arm = "RUSTY_WRENCH",
	Mobility = "RUSTY_CASTERS",
}

--- A fresh copy, so a caller mutating its loadout cannot edit this config in place.
function StarterRobot.newLoadout(): { [string]: string }
	local out = {}
	for slot, id in pairs(StarterRobot.LOADOUT) do
		out[slot] = id
	end
	return out
end

--- The starter set as an OWNERSHIP set (`partId -> true`), for a new profile's inventory.
---
--- 🔴 All five, not just the ones in `LOADOUT` -- and today those are the same five, which is
--- exactly why this is derived from `PARTS` rather than from `LOADOUT`. The moment the rusty set
--- grows a sixth stub that does not start bolted on, a `LOADOUT`-derived version would silently
--- fail to grant it and the part would be unequippable with no error anywhere.
---
--- ⚠️ A player must OWN their starter parts, or taking the rusty wrench off to try a found one
--- would throw it away: the builder refuses to install what is not owned, so an un-owned starter
--- is a one-way door.
function StarterRobot.ownedSet(): { [string]: boolean }
	local out = {}
	for id in pairs(StarterRobot.PARTS) do
		out[id] = true
	end
	return out
end

function StarterRobot.def(partId: string)
	return StarterRobot.PARTS[partId]
end

--- Is this part a starter stub? Anything that pays out, sells or grades a part must ask.
function StarterRobot.isStarter(partId: string): boolean
	local d = StarterRobot.PARTS[partId]
	return d ~= nil and d.starterOnly == true
end

--- Validate every def against the real schema, so a typo fails at startup and not in the Arena.
--- Returns a list of problems; empty means good.
function StarterRobot.validate(Parts: any): { string }
	local problems = {}
	for id, def in pairs(StarterRobot.PARTS) do
		if id ~= def.partId then
			table.insert(problems, ("key %s does not match partId %s"):format(id, tostring(def.partId)))
		end
		local ok, why = Parts.validate(def)
		if not ok then
			table.insert(problems, ("%s: %s"):format(id, tostring(why)))
		end
		if def.scrapValue ~= 0 then
			table.insert(problems, ("%s must have scrapValue 0 -- the rusty set is not farmable"):format(id))
		end
		if def.zone ~= nil then
			table.insert(problems, ("%s must have NO zone -- starter parts are never found"):format(id))
		end
	end
	--- and the loadout must name real parts, one per slot
	for slot, id in pairs(StarterRobot.LOADOUT) do
		local d = StarterRobot.PARTS[id]
		if not d then
			table.insert(problems, ("loadout slot %s names unknown part %s"):format(slot, tostring(id)))
		elseif d.slot ~= slot then
			table.insert(problems, ("loadout puts %s (a %s part) in slot %s"):format(id, tostring(d.slot), slot))
		end
	end
	return problems
end

return StarterRobot
