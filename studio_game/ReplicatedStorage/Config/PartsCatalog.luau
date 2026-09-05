--!strict
--[[
	Config/PartsCatalog — all 96 robot parts, as data.

	🔴 GENERATED from docs/content/parts-catalog.md. Do not hand-edit: edit the doc and
	re-run tools/gen-parts-catalog.py. The doc is transcribed from the spec field for field
	and verified against it by tools/verify-catalog-vs-spec.py, so it is the one source that
	is actually checked. A second hand-typed copy here would drift from it silently.

	⚠️ NO COMBAT STATS. The catalog doc states none of the 96 parts has combat stats yet, so
	this file carries none. Inventing them here would hide made-up numbers inside a file that
	reads as authoritative -- balance belongs in a tuning pass, done deliberately.

	`specRarity` is the SPEC's own grade where decision 0015 re-graded a part; nil means the
	grade was left unchanged. Nothing is destroyed.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Parts = require(ReplicatedStorage.Config.Parts)

local PartsCatalog = {}

PartsCatalog.ALL = {
	--- 1. Work Lamp
	{ partId = "WORK_LAMP", name = "Work Lamp", tier = 1, slot = "Head", rarity = "Common", zone = "Color Workshop", effect = "improved targeting" },
	--- 2. Mini Motor
	{ partId = "MINI_MOTOR", name = "Mini Motor", tier = 1, slot = "Core", rarity = "Common", zone = "Color Workshop", effect = "attack-speed bonus" },
	--- 3. Paint Drum
	{ partId = "PAINT_DRUM", name = "Paint Drum", tier = 1, slot = "Body", rarity = "Common", zone = "Color Workshop", effect = "basic HP" },
	--- 4. Pipe Wrench
	{ partId = "PIPE_WRENCH", name = "Pipe Wrench", tier = 1, slot = "Arm", rarity = "Uncommon", specRarity = "Common", animationProfile = "SweepLight", zone = "Color Workshop", effect = "balanced melee" },
	--- 5. Spring Puncher
	{ partId = "SPRING_PUNCHER", name = "Spring Puncher", tier = 1, slot = "Arm", rarity = "Uncommon", animationProfile = "PunchFast", zone = "Color Workshop", effect = "knockback punch" },
	--- 6. Caster Wheels
	{ partId = "CASTER_WHEELS", name = "Caster Wheels", tier = 1, slot = "Mobility", rarity = "Uncommon", specRarity = "Common", mobilityProfile = "Wheels", zone = "Color Workshop", effect = "movement speed" },
	--- 7. Magnet Coil
	{ partId = "MAGNET_COIL", name = "Magnet Coil", tier = 1, slot = "Back", rarity = "Rare", zone = "Color Workshop", effect = "stronger Arena control" },
	--- 8. Golden Gear
	{ partId = "GOLDEN_GEAR", name = "Golden Gear", tier = 1, slot = "Head", rarity = "Legendary", zone = "Color Workshop", effect = "faster ability charging" },
	--- 9. Toy Camera
	{ partId = "TOY_CAMERA", name = "Toy Camera", tier = 2, slot = "Head", rarity = "Common", zone = "Toy Assembly", effect = "improved ranged targeting" },
	--- 10. Wind-Up Key
	{ partId = "WIND_UP_KEY", name = "Wind-Up Key", tier = 2, slot = "Core", rarity = "Uncommon", zone = "Toy Assembly", effect = "periodic speed burst" },
	--- 11. Building Block Chest
	{ partId = "BUILDING_BLOCK_CHEST", name = "Building Block Chest", tier = 2, slot = "Body", rarity = "Common", zone = "Toy Assembly", effect = "balanced armor" },
	--- 12. Grabber Claw
	{ partId = "GRABBER_CLAW", name = "Grabber Claw", tier = 2, slot = "Arm", rarity = "Common", animationProfile = "GrabPull", zone = "Toy Assembly", effect = "pull enemy closer" },
	--- 13. Toy Hammer
	{ partId = "TOY_HAMMER", name = "Toy Hammer", tier = 2, slot = "Arm", rarity = "Uncommon", animationProfile = "SmashHeavy", zone = "Toy Assembly", effect = "heavy strike" },
	--- 14. Roller Skates
	{ partId = "ROLLER_SKATES", name = "Roller Skates", tier = 2, slot = "Mobility", rarity = "Uncommon", specRarity = "Common", mobilityProfile = "Wheels", zone = "Toy Assembly", effect = "high movement" },
	--- 15. Propeller Pack
	{ partId = "PROPELLER_PACK", name = "Propeller Pack", tier = 2, slot = "Back", rarity = "Rare", zone = "Toy Assembly", effect = "short dodge burst" },
	--- 16. Jack-in-the-Box Launcher
	{ partId = "JACK_IN_THE_BOX_LAUNCHER", name = "Jack-in-the-Box Launcher", tier = 2, slot = "Arm", rarity = "Legendary", animationProfile = "RangedCannon", zone = "Toy Assembly", effect = "surprise ranged attack" },
	--- 17. Colander
	{ partId = "COLANDER", name = "Colander", tier = 3, slot = "Head", rarity = "Common", zone = "Mega Kitchen", effect = "increased energy regeneration" },
	--- 18. Blender Motor
	{ partId = "BLENDER_MOTOR", name = "Blender Motor", tier = 3, slot = "Core", rarity = "Common", specRarity = "Uncommon", zone = "Mega Kitchen", effect = "faster attacks" },
	--- 19. Refrigerator Door
	{ partId = "REFRIGERATOR_DOOR", name = "Refrigerator Door", tier = 3, slot = "Body", rarity = "Uncommon", specRarity = "Rare", zone = "Mega Kitchen", effect = "large armor bonus" },
	--- 20. Giant Spoon
	{ partId = "GIANT_SPOON", name = "Giant Spoon", tier = 3, slot = "Arm", rarity = "Uncommon", animationProfile = "SweepHeavy", zone = "Mega Kitchen", effect = "huge sweeping attack" },
	--- 21. Frying Pan
	{ partId = "FRYING_PAN", name = "Frying Pan", tier = 3, slot = "Arm", rarity = "Uncommon", specRarity = "Rare", animationProfile = "Shield", zone = "Mega Kitchen", effect = "shield / counter" },
	--- 22. Serving Cart Wheels
	{ partId = "SERVING_CART_WHEELS", name = "Serving Cart Wheels", tier = 3, slot = "Mobility", rarity = "Common", mobilityProfile = "Wheels", zone = "Mega Kitchen", effect = "stable movement" },
	--- 23. Toaster Coil
	{ partId = "TOASTER_COIL", name = "Toaster Coil", tier = 3, slot = "Back", rarity = "Rare", zone = "Mega Kitchen", effect = "electrical retaliation" },
	--- 24. Golden Tenderizer
	{ partId = "GOLDEN_TENDERIZER", name = "Golden Tenderizer", tier = 3, slot = "Arm", rarity = "Legendary", animationProfile = "SmashHeavy", zone = "Mega Kitchen", effect = "massive critical hit" },
	--- 25. Barcode Scanner
	{ partId = "BARCODE_SCANNER", name = "Barcode Scanner", tier = 4, slot = "Head", rarity = "Common", zone = "Warehouse", effect = "target selection" },
	--- 26. Pallet Motor
	{ partId = "PALLET_MOTOR", name = "Pallet Motor", tier = 4, slot = "Core", rarity = "Common", zone = "Warehouse", effect = "torque bonus" },
	--- 27. Metal Locker
	{ partId = "METAL_LOCKER", name = "Metal Locker", tier = 4, slot = "Body", rarity = "Uncommon", zone = "Warehouse", effect = "high HP" },
	--- 28. Shelf Beam
	{ partId = "SHELF_BEAM", name = "Shelf Beam", tier = 4, slot = "Arm", rarity = "Uncommon", specRarity = "Common", animationProfile = "SweepLight", zone = "Warehouse", effect = "long-range melee" },
	--- 29. Strapping Gun
	{ partId = "STRAPPING_GUN", name = "Strapping Gun", tier = 4, slot = "Arm", rarity = "Rare", animationProfile = "RangedRapid", zone = "Warehouse", effect = "rapid ranged attack" },
	--- 30. Pallet Wheels
	{ partId = "PALLET_WHEELS", name = "Pallet Wheels", tier = 4, slot = "Mobility", rarity = "Uncommon", specRarity = "Common", mobilityProfile = "Wheels", zone = "Warehouse", effect = "strong stability" },
	--- 31. Forklift Battery
	{ partId = "FORKLIFT_BATTERY", name = "Forklift Battery", tier = 4, slot = "Back", rarity = "Rare", zone = "Warehouse", effect = "ability-energy bonus" },
	--- 32. Vault Door
	{ partId = "VAULT_DOOR", name = "Vault Door", tier = 4, slot = "Body", rarity = "Legendary", zone = "Warehouse", effect = "enormous armor" },
	--- 33. Traffic Light
	{ partId = "TRAFFIC_LIGHT", name = "Traffic Light", tier = 5, slot = "Head", rarity = "Uncommon", zone = "City Storage", effect = "combat-mode switching" },
	--- 34. Scooter Battery
	{ partId = "SCOOTER_BATTERY", name = "Scooter Battery", tier = 5, slot = "Core", rarity = "Common", zone = "City Storage", effect = "movement-energy bonus" },
	--- 35. Vending Machine
	{ partId = "VENDING_MACHINE", name = "Vending Machine", tier = 5, slot = "Body", rarity = "Rare", zone = "City Storage", effect = "large HP" },
	--- 36. STOP Sign
	{ partId = "STOP_SIGN", name = "STOP Sign", tier = 5, slot = "Arm", rarity = "Uncommon", animationProfile = "Shield", zone = "City Storage", effect = "shield" },
	--- 37. Parking Meter
	{ partId = "PARKING_METER", name = "Parking Meter", tier = 5, slot = "Arm", rarity = "Uncommon", animationProfile = "SweepHeavy", zone = "City Storage", effect = "fast mace" },
	--- 38. Shopping Cart Wheels
	{ partId = "SHOPPING_CART_WHEELS", name = "Shopping Cart Wheels", tier = 5, slot = "Mobility", rarity = "Common", mobilityProfile = "Wheels", zone = "City Storage", effect = "excellent acceleration" },
	--- 39. Neon Transformer
	{ partId = "NEON_TRANSFORMER", name = "Neon Transformer", tier = 5, slot = "Back", rarity = "Rare", zone = "City Storage", effect = "electric damage" },
	--- 40. Golden Hydrant Cannon
	{ partId = "GOLDEN_HYDRANT_CANNON", name = "Golden Hydrant Cannon", tier = 5, slot = "Arm", rarity = "Legendary", animationProfile = "RangedCannon", zone = "City Storage", effect = "high-pressure knockback" },
	--- 41. Headlight Cluster
	{ partId = "HEADLIGHT_CLUSTER", name = "Headlight Cluster", tier = 6, slot = "Head", rarity = "Common", zone = "Vehicle Workshop", effect = "accuracy bonus" },
	--- 42. Engine Block
	{ partId = "ENGINE_BLOCK", name = "Engine Block", tier = 6, slot = "Core", rarity = "Uncommon", specRarity = "Rare", zone = "Vehicle Workshop", effect = "major power increase" },
	--- 43. Car Door
	{ partId = "CAR_DOOR", name = "Car Door", tier = 6, slot = "Body", rarity = "Common", specRarity = "Uncommon", zone = "Vehicle Workshop", effect = "balanced armor" },
	--- 44. Exhaust Cannon
	{ partId = "EXHAUST_CANNON", name = "Exhaust Cannon", tier = 6, slot = "Arm", rarity = "Uncommon", specRarity = "Rare", animationProfile = "RangedCannon", zone = "Vehicle Workshop", effect = "ranged burst" },
	--- 45. Brake Disc Saw
	{ partId = "BRAKE_DISC_SAW", name = "Brake Disc Saw", tier = 6, slot = "Arm", rarity = "Rare", animationProfile = "ThrustContinuous", zone = "Vehicle Workshop", effect = "rapid melee" },
	--- 46. Motorcycle Wheels
	{ partId = "MOTORCYCLE_WHEELS", name = "Motorcycle Wheels", tier = 6, slot = "Mobility", rarity = "Uncommon", mobilityProfile = "Wheels", zone = "Vehicle Workshop", effect = "very high speed" },
	--- 47. Turbocharger
	{ partId = "TURBOCHARGER", name = "Turbocharger", tier = 6, slot = "Back", rarity = "Rare", zone = "Vehicle Workshop", effect = "temporary overdrive" },
	--- 48. Chrome Bumper
	{ partId = "CHROME_BUMPER", name = "Chrome Bumper", tier = 6, slot = "Arm", rarity = "Legendary", animationProfile = "ChargeBody", zone = "Vehicle Workshop", effect = "devastating charge" },
	--- 49. Sensor Rack
	{ partId = "SENSOR_RACK", name = "Sensor Rack", tier = 7, slot = "Head", rarity = "Common", specRarity = "Uncommon", zone = "Car Factory", effect = "better tactical AI" },
	--- 50. V8 Engine
	{ partId = "V8_ENGINE", name = "V8 Engine", tier = 7, slot = "Core", rarity = "Uncommon", specRarity = "Rare", zone = "Car Factory", effect = "high damage" },
	--- 51. Vehicle Chassis
	{ partId = "VEHICLE_CHASSIS", name = "Vehicle Chassis", tier = 7, slot = "Body", rarity = "Rare", zone = "Car Factory", effect = "HP + stability" },
	--- 52. Welding Arm
	{ partId = "WELDING_ARM", name = "Welding Arm", tier = 7, slot = "Arm", rarity = "Uncommon", animationProfile = "ThrustContinuous", zone = "Car Factory", effect = "burn damage" },
	--- 53. Axle Hammer
	{ partId = "AXLE_HAMMER", name = "Axle Hammer", tier = 7, slot = "Arm", rarity = "Rare", animationProfile = "SmashHeavy", zone = "Car Factory", effect = "heavy stun" },
	--- 54. Racing Wheels
	{ partId = "RACING_WHEELS", name = "Racing Wheels", tier = 7, slot = "Mobility", rarity = "Rare", mobilityProfile = "Wheels", zone = "Car Factory", effect = "extreme acceleration" },
	--- 55. Nitrous Tanks
	{ partId = "NITROUS_TANKS", name = "Nitrous Tanks", tier = 7, slot = "Back", rarity = "Epic", specRarity = "Rare", zone = "Car Factory", effect = "temporary speed boost" },
	--- 56. Prototype Engine Crane
	{ partId = "PROTOTYPE_ENGINE_CRANE", name = "Prototype Engine Crane", tier = 7, slot = "Arm", rarity = "Legendary", animationProfile = "GrabPull", zone = "Car Factory", effect = "grab and throw" },
	--- 57. Worklight Tower
	{ partId = "WORKLIGHT_TOWER", name = "Worklight Tower", tier = 8, slot = "Head", rarity = "Common", zone = "Heavy Yard", effect = "long-range detection" },
	--- 58. Diesel Generator
	{ partId = "DIESEL_GENERATOR", name = "Diesel Generator", tier = 8, slot = "Core", rarity = "Uncommon", specRarity = "Rare", zone = "Heavy Yard", effect = "huge energy pool" },
	--- 59. Bulldozer Plate
	{ partId = "BULLDOZER_PLATE", name = "Bulldozer Plate", tier = 8, slot = "Body", rarity = "Uncommon", specRarity = "Rare", zone = "Heavy Yard", effect = "frontal armor" },
	--- 60. Excavator Bucket
	{ partId = "EXCAVATOR_BUCKET", name = "Excavator Bucket", tier = 8, slot = "Arm", rarity = "Rare", animationProfile = "SmashHeavy", zone = "Heavy Yard", effect = "enormous slow hit" },
	--- 61. Forklift Fork
	{ partId = "FORKLIFT_FORK", name = "Forklift Fork", tier = 8, slot = "Arm", rarity = "Rare", animationProfile = "GrabPull", zone = "Heavy Yard", effect = "lift / stun" },
	--- 62. Tank Tracks
	{ partId = "TANK_TRACKS", name = "Tank Tracks", tier = 8, slot = "Mobility", rarity = "Rare", mobilityProfile = "Tracks", zone = "Heavy Yard", effect = "huge control resistance" },
	--- 63. Hydraulic Pump
	{ partId = "HYDRAULIC_PUMP", name = "Hydraulic Pump", tier = 8, slot = "Back", rarity = "Epic", specRarity = "Rare", zone = "Heavy Yard", effect = "attack-force increase" },
	--- 64. Crane Hook
	{ partId = "CRANE_HOOK", name = "Crane Hook", tier = 8, slot = "Arm", rarity = "Legendary", animationProfile = "GrabPull", zone = "Heavy Yard", effect = "pulls enemy across Arena" },
	--- 65. Warning Beacon
	{ partId = "WARNING_BEACON", name = "Warning Beacon", tier = 9, slot = "Head", rarity = "Common", zone = "Power Plant", effect = "faster threat switching" },
	--- 66. Transformer Core
	{ partId = "TRANSFORMER_CORE", name = "Transformer Core", tier = 9, slot = "Core", rarity = "Uncommon", specRarity = "Rare", zone = "Power Plant", effect = "electric attacks" },
	--- 67. Turbine Shell
	{ partId = "TURBINE_SHELL", name = "Turbine Shell", tier = 9, slot = "Body", rarity = "Uncommon", specRarity = "Rare", zone = "Power Plant", effect = "high durability" },
	--- 68. Busbar Blade
	{ partId = "BUSBAR_BLADE", name = "Busbar Blade", tier = 9, slot = "Arm", rarity = "Rare", animationProfile = "SweepLight", zone = "Power Plant", effect = "electrical melee" },
	--- 69. Coil Cannon
	{ partId = "COIL_CANNON", name = "Coil Cannon", tier = 9, slot = "Arm", rarity = "Rare", specRarity = "Epic", animationProfile = "RangedCannon", zone = "Power Plant", effect = "ranged electrical shot" },
	--- 70. Magnetic Rail
	{ partId = "MAGNETIC_RAIL", name = "Magnetic Rail", tier = 9, slot = "Mobility", rarity = "Rare", mobilityProfile = "Hover", zone = "Power Plant", effect = "fast controlled movement" },
	--- 71. Capacitor Bank
	{ partId = "CAPACITOR_BANK", name = "Capacitor Bank", tier = 9, slot = "Back", rarity = "Epic", zone = "Power Plant", effect = "ability storage" },
	--- 72. Plasma Dynamo
	{ partId = "PLASMA_DYNAMO", name = "Plasma Dynamo", tier = 9, slot = "Core", rarity = "Legendary", zone = "Power Plant", effect = "periodic area shock" },
	--- 73. Prototype Sensor
	{ partId = "PROTOTYPE_SENSOR", name = "Prototype Sensor", tier = 10, slot = "Head", rarity = "Uncommon", specRarity = "Rare", zone = "Robot Laboratory", effect = "advanced targeting" },
	--- 74. AI Matrix
	{ partId = "AI_MATRIX", name = "AI Matrix", tier = 10, slot = "Core", rarity = "Rare", specRarity = "Epic", zone = "Robot Laboratory", effect = "better combat decisions" },
	--- 75. Combat Frame
	{ partId = "COMBAT_FRAME", name = "Combat Frame", tier = 10, slot = "Body", rarity = "Rare", zone = "Robot Laboratory", effect = "balanced high-tier armor" },
	--- 76. Plasma Cutter
	{ partId = "PLASMA_CUTTER", name = "Plasma Cutter", tier = 10, slot = "Arm", rarity = "Epic", animationProfile = "ThrustContinuous", zone = "Robot Laboratory", effect = "armor penetration" },
	--- 77. Servo Fist
	{ partId = "SERVO_FIST", name = "Servo Fist", tier = 10, slot = "Arm", rarity = "Rare", animationProfile = "PunchFast", zone = "Robot Laboratory", effect = "fast heavy punch" },
	--- 78. Hover Actuators
	{ partId = "HOVER_ACTUATORS", name = "Hover Actuators", tier = 10, slot = "Mobility", rarity = "Epic", mobilityProfile = "Hover", zone = "Robot Laboratory", effect = "ignores some knockback" },
	--- 79. Shield Generator
	{ partId = "SHIELD_GENERATOR", name = "Shield Generator", tier = 10, slot = "Back", rarity = "Epic", zone = "Robot Laboratory", effect = "regenerating shield" },
	--- 80. Experimental Magnet Arm
	{ partId = "EXPERIMENTAL_MAGNET_ARM", name = "Experimental Magnet Arm", tier = 10, slot = "Arm", rarity = "Legendary", animationProfile = "GrabPull", zone = "Robot Laboratory", effect = "physically pulls enemies" },
	--- 81. Satellite Dish
	{ partId = "SATELLITE_DISH", name = "Satellite Dish", tier = 11, slot = "Head", rarity = "Uncommon", specRarity = "Rare", zone = "Space Foundry", effect = "long-range targeting" },
	--- 82. Fusion Cell
	{ partId = "FUSION_CELL", name = "Fusion Cell", tier = 11, slot = "Core", rarity = "Epic", zone = "Space Foundry", effect = "huge energy generation" },
	--- 83. Heat Shield
	{ partId = "HEAT_SHIELD", name = "Heat Shield", tier = 11, slot = "Body", rarity = "Rare", zone = "Space Foundry", effect = "damage resistance" },
	--- 84. Manipulator Claw
	{ partId = "MANIPULATOR_CLAW", name = "Manipulator Claw", tier = 11, slot = "Arm", rarity = "Rare", animationProfile = "GrabPull", zone = "Space Foundry", effect = "grab ability" },
	--- 85. Ion Lance
	{ partId = "ION_LANCE", name = "Ion Lance", tier = 11, slot = "Arm", rarity = "Epic", animationProfile = "RangedCannon", zone = "Space Foundry", effect = "ranged piercing attack" },
	--- 86. Rover Legs
	{ partId = "ROVER_LEGS", name = "Rover Legs", tier = 11, slot = "Mobility", rarity = "Rare", mobilityProfile = "Legs", zone = "Space Foundry", effect = "strong traction" },
	--- 87. Thruster Pack
	{ partId = "THRUSTER_PACK", name = "Thruster Pack", tier = 11, slot = "Back", rarity = "Epic", zone = "Space Foundry", effect = "arena dash" },
	--- 88. Meteor Drill
	{ partId = "METEOR_DRILL", name = "Meteor Drill", tier = 11, slot = "Arm", rarity = "Legendary", animationProfile = "ThrustContinuous", zone = "Space Foundry", effect = "escalating continuous damage" },
	--- 89. Quantum Lens
	{ partId = "QUANTUM_LENS", name = "Quantum Lens", tier = 12, slot = "Head", rarity = "Uncommon", specRarity = "Epic", zone = "Quantum Reactor", effect = "predicts enemy movement" },
	--- 90. Singularity Core
	{ partId = "SINGULARITY_CORE", name = "Singularity Core", tier = 12, slot = "Core", rarity = "Epic", specRarity = "Legendary", zone = "Quantum Reactor", effect = "huge power output" },
	--- 91. Reactor Shell
	{ partId = "REACTOR_SHELL", name = "Reactor Shell", tier = 12, slot = "Body", rarity = "Rare", specRarity = "Epic", zone = "Quantum Reactor", effect = "extreme durability" },
	--- 92. Gravity Hammer
	{ partId = "GRAVITY_HAMMER", name = "Gravity Hammer", tier = 12, slot = "Arm", rarity = "Rare", specRarity = "Epic", animationProfile = "SmashHeavy", zone = "Quantum Reactor", effect = "massive knockback" },
	--- 93. Phase Blade
	{ partId = "PHASE_BLADE", name = "Phase Blade", tier = 12, slot = "Arm", rarity = "Epic", specRarity = "Legendary", animationProfile = "SweepLight", zone = "Quantum Reactor", effect = "partially ignores armor" },
	--- 94. Gravity Ring
	{ partId = "GRAVITY_RING", name = "Gravity Ring", tier = 12, slot = "Mobility", rarity = "Rare", specRarity = "Epic", mobilityProfile = "Hover", zone = "Quantum Reactor", effect = "unusual movement" },
	--- 95. Flux Stabilizer
	{ partId = "FLUX_STABILIZER", name = "Flux Stabilizer", tier = 12, slot = "Back", rarity = "Epic", zone = "Quantum Reactor", effect = "cooldown reduction" },
	--- 96. Void Magnet
	{ partId = "VOID_MAGNET", name = "Void Magnet", tier = 12, slot = "Arm", rarity = "Mythic", animationProfile = "GrabPull", zone = "Quantum Reactor", effect = "pulls multiple robots toward itself" },
}

--- Lookups, built once. 🔴 A duplicate partId is an error, not a last-one-wins:
--- two rows sharing an id means every consumer silently disagrees about that part.
local byId = {}
local byTier = {}
for _, p in ipairs(PartsCatalog.ALL) do
	if byId[p.partId] then
		error(("PartsCatalog: duplicate partId %q"):format(p.partId), 0)
	end
	byId[p.partId] = p
	byTier[p.tier] = byTier[p.tier] or {}
	table.insert(byTier[p.tier], p)
end

function PartsCatalog.byId(id: string)
	return byId[id]
end

function PartsCatalog.forTier(tier: number)
	return byTier[tier] or {}
end

--- Every part of a given grade, in catalog order.
function PartsCatalog.byRarity(rarity: string)
	local out = {}
	for _, p in ipairs(PartsCatalog.ALL) do
		if p.rarity == rarity then
			table.insert(out, p)
		end
	end
	return out
end

--- ⚠️ Validates against Config/Parts rather than trusting the generator. If the doc grows a
--- slot or grade the schema does not know, this says so at startup instead of at runtime.
function PartsCatalog.validate(): { string }
	local problems = {}
	local slots = {}
	for slot in pairs(Parts.SLOT_TO_SOCKETS) do
		slots[slot] = true
	end
	local grades = {}
	for _, r in ipairs(Parts.RARITY_ORDER) do
		grades[r] = true
	end
	for _, p in ipairs(PartsCatalog.ALL) do
		if not slots[p.slot] then
			table.insert(problems, ("%s has unknown slot %q"):format(p.partId, p.slot))
		end
		if not grades[p.rarity] then
			table.insert(problems, ("%s has unknown rarity %q"):format(p.partId, p.rarity))
		end
	end
	return problems
end

return PartsCatalog
