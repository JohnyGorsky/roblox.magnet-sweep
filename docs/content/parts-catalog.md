# Robot parts — full catalog

**96 parts** across 12 tiers, 8 per tier. Part name, slot and effect are **the spec's** (§26-37),
transcribed field for field and verified against it by `tools/verify-catalog-vs-spec.py`.

**Rarity is re-graded** ([decision 0015](../decisions/0015-rarity-is-re-graded.md)) — the spec's own
grade is kept in the **Spec rarity** column, where `=` means unchanged. Nothing is destroyed.

The **Animation** and **Mobility** columns are **(derived)** — a job 001 proposal, not spec values.
They are two *separate* fields on a part
([systems/robot-rig §10](../systems/robot-rig/README.md#10-the-part-specification)): a combat
`AnimationProfile` drives the arms; a `MobilityProfile` selects the locomotion clip and sub-rig.

Rarity ramp: `Common` → `Uncommon` → `Rare` → `Epic` → `Legendary` → `Mythic`.
Slots: Head · Core · Body · Arm (either side) · Mobility · Back.

Every part is content, never code —
[decision 0004](../decisions/0004-parts-are-content-rig-is-the-engine.md). The engine knows the
profile, not the object.

## The full table

| # | Part | `PartId` | Tier | Zone | Slot | Rarity | Spec rarity | Effect | Animation *(derived)* | Mobility *(derived)* |
|--:|---|---|--:|---|---|---|---|---|---|---|
| 1 | Work Lamp | `WORK_LAMP` | 1 | Color Workshop | Head | Common | = | improved targeting | — | — |
| 2 | Mini Motor | `MINI_MOTOR` | 1 | Color Workshop | Core | Common | = | attack-speed bonus | — | — |
| 3 | Paint Drum | `PAINT_DRUM` | 1 | Color Workshop | Body | Common | = | basic HP | — | — |
| 4 | Pipe Wrench | `PIPE_WRENCH` | 1 | Color Workshop | Arm | Uncommon | Common | balanced melee | `SweepLight` | — |
| 5 | Spring Puncher | `SPRING_PUNCHER` | 1 | Color Workshop | Arm | Uncommon | = | knockback punch | `PunchFast` | — |
| 6 | Caster Wheels | `CASTER_WHEELS` | 1 | Color Workshop | Mobility | Uncommon | Common | movement speed | — | `Wheels` |
| 7 | Magnet Coil | `MAGNET_COIL` | 1 | Color Workshop | Back | Rare | = | stronger Arena control | — | — |
| 8 | Golden Gear | `GOLDEN_GEAR` | 1 | Color Workshop | Head | Legendary | = | faster ability charging | — | — |
| 9 | Toy Camera | `TOY_CAMERA` | 2 | Toy Assembly | Head | Common | = | improved ranged targeting | — | — |
| 10 | Wind-Up Key | `WIND_UP_KEY` | 2 | Toy Assembly | Core | Uncommon | = | periodic speed burst | — | — |
| 11 | Building Block Chest | `BUILDING_BLOCK_CHEST` | 2 | Toy Assembly | Body | Common | = | balanced armor | — | — |
| 12 | Grabber Claw | `GRABBER_CLAW` | 2 | Toy Assembly | Arm | Common | = | pull enemy closer | `GrabPull` | — |
| 13 | Toy Hammer | `TOY_HAMMER` | 2 | Toy Assembly | Arm | Uncommon | = | heavy strike | `SmashHeavy` | — |
| 14 | Roller Skates | `ROLLER_SKATES` | 2 | Toy Assembly | Mobility | Uncommon | Common | high movement | — | `Wheels` |
| 15 | Propeller Pack | `PROPELLER_PACK` | 2 | Toy Assembly | Back | Rare | = | short dodge burst | — | — |
| 16 | Jack-in-the-Box Launcher | `JACK_IN_THE_BOX_LAUNCHER` | 2 | Toy Assembly | Arm | Legendary | = | surprise ranged attack | `RangedCannon` | — |
| 17 | Colander | `COLANDER` | 3 | Mega Kitchen | Head | Common | = | increased energy regeneration | — | — |
| 18 | Blender Motor | `BLENDER_MOTOR` | 3 | Mega Kitchen | Core | Common | Uncommon | faster attacks | — | — |
| 19 | Refrigerator Door | `REFRIGERATOR_DOOR` | 3 | Mega Kitchen | Body | Uncommon | Rare | large armor bonus | — | — |
| 20 | Giant Spoon | `GIANT_SPOON` | 3 | Mega Kitchen | Arm | Uncommon | = | huge sweeping attack | `SweepHeavy` | — |
| 21 | Frying Pan | `FRYING_PAN` | 3 | Mega Kitchen | Arm | Uncommon | Rare | shield / counter | `Shield` | — |
| 22 | Serving Cart Wheels | `SERVING_CART_WHEELS` | 3 | Mega Kitchen | Mobility | Common | = | stable movement | — | `Wheels` |
| 23 | Toaster Coil | `TOASTER_COIL` | 3 | Mega Kitchen | Back | Rare | = | electrical retaliation | — | — |
| 24 | Golden Tenderizer | `GOLDEN_TENDERIZER` | 3 | Mega Kitchen | Arm | Legendary | = | massive critical hit | `SmashHeavy` | — |
| 25 | Barcode Scanner | `BARCODE_SCANNER` | 4 | Warehouse | Head | Common | = | target selection | — | — |
| 26 | Pallet Motor | `PALLET_MOTOR` | 4 | Warehouse | Core | Common | = | torque bonus | — | — |
| 27 | Metal Locker | `METAL_LOCKER` | 4 | Warehouse | Body | Uncommon | = | high HP | — | — |
| 28 | Shelf Beam | `SHELF_BEAM` | 4 | Warehouse | Arm | Uncommon | Common | long-range melee | `SweepLight` | — |
| 29 | Strapping Gun | `STRAPPING_GUN` | 4 | Warehouse | Arm | Rare | = | rapid ranged attack | `RangedRapid` | — |
| 30 | Pallet Wheels | `PALLET_WHEELS` | 4 | Warehouse | Mobility | Uncommon | Common | strong stability | — | `Wheels` |
| 31 | Forklift Battery | `FORKLIFT_BATTERY` | 4 | Warehouse | Back | Rare | = | ability-energy bonus | — | — |
| 32 | Vault Door | `VAULT_DOOR` | 4 | Warehouse | Body | Legendary | = | enormous armor | — | — |
| 33 | Traffic Light | `TRAFFIC_LIGHT` | 5 | City Storage | Head | Uncommon | = | combat-mode switching | — | — |
| 34 | Scooter Battery | `SCOOTER_BATTERY` | 5 | City Storage | Core | Common | = | movement-energy bonus | — | — |
| 35 | Vending Machine | `VENDING_MACHINE` | 5 | City Storage | Body | Rare | = | large HP | — | — |
| 36 | STOP Sign | `STOP_SIGN` | 5 | City Storage | Arm | Uncommon | = | shield | `Shield` | — |
| 37 | Parking Meter | `PARKING_METER` | 5 | City Storage | Arm | Uncommon | = | fast mace | `SweepHeavy` | — |
| 38 | Shopping Cart Wheels | `SHOPPING_CART_WHEELS` | 5 | City Storage | Mobility | Common | = | excellent acceleration | — | `Wheels` |
| 39 | Neon Transformer | `NEON_TRANSFORMER` | 5 | City Storage | Back | Rare | = | electric damage | — | — |
| 40 | Golden Hydrant Cannon | `GOLDEN_HYDRANT_CANNON` | 5 | City Storage | Arm | Legendary | = | high-pressure knockback | `RangedCannon` | — |
| 41 | Headlight Cluster | `HEADLIGHT_CLUSTER` | 6 | Vehicle Workshop | Head | Common | = | accuracy bonus | — | — |
| 42 | Engine Block | `ENGINE_BLOCK` | 6 | Vehicle Workshop | Core | Uncommon | Rare | major power increase | — | — |
| 43 | Car Door | `CAR_DOOR` | 6 | Vehicle Workshop | Body | Common | Uncommon | balanced armor | — | — |
| 44 | Exhaust Cannon | `EXHAUST_CANNON` | 6 | Vehicle Workshop | Arm | Uncommon | Rare | ranged burst | `RangedCannon` | — |
| 45 | Brake Disc Saw | `BRAKE_DISC_SAW` | 6 | Vehicle Workshop | Arm | Rare | = | rapid melee | `ThrustContinuous` | — |
| 46 | Motorcycle Wheels | `MOTORCYCLE_WHEELS` | 6 | Vehicle Workshop | Mobility | Uncommon | = | very high speed | — | `Wheels` |
| 47 | Turbocharger | `TURBOCHARGER` | 6 | Vehicle Workshop | Back | Rare | = | temporary overdrive | — | — |
| 48 | Chrome Bumper | `CHROME_BUMPER` | 6 | Vehicle Workshop | Arm | Legendary | = | devastating charge | `ChargeBody` | — |
| 49 | Sensor Rack | `SENSOR_RACK` | 7 | Car Factory | Head | Common | Uncommon | better tactical AI | — | — |
| 50 | V8 Engine | `V8_ENGINE` | 7 | Car Factory | Core | Uncommon | Rare | high damage | — | — |
| 51 | Vehicle Chassis | `VEHICLE_CHASSIS` | 7 | Car Factory | Body | Rare | = | HP + stability | — | — |
| 52 | Welding Arm | `WELDING_ARM` | 7 | Car Factory | Arm | Uncommon | = | burn damage | `ThrustContinuous` | — |
| 53 | Axle Hammer | `AXLE_HAMMER` | 7 | Car Factory | Arm | Rare | = | heavy stun | `SmashHeavy` | — |
| 54 | Racing Wheels | `RACING_WHEELS` | 7 | Car Factory | Mobility | Rare | = | extreme acceleration | — | `Wheels` |
| 55 | Nitrous Tanks | `NITROUS_TANKS` | 7 | Car Factory | Back | Epic | Rare | temporary speed boost | — | — |
| 56 | Prototype Engine Crane | `PROTOTYPE_ENGINE_CRANE` | 7 | Car Factory | Arm | Legendary | = | grab and throw | `GrabPull` | — |
| 57 | Worklight Tower | `WORKLIGHT_TOWER` | 8 | Heavy Yard | Head | Common | = | long-range detection | — | — |
| 58 | Diesel Generator | `DIESEL_GENERATOR` | 8 | Heavy Yard | Core | Uncommon | Rare | huge energy pool | — | — |
| 59 | Bulldozer Plate | `BULLDOZER_PLATE` | 8 | Heavy Yard | Body | Uncommon | Rare | frontal armor | — | — |
| 60 | Excavator Bucket | `EXCAVATOR_BUCKET` | 8 | Heavy Yard | Arm | Rare | = | enormous slow hit | `SmashHeavy` | — |
| 61 | Forklift Fork | `FORKLIFT_FORK` | 8 | Heavy Yard | Arm | Rare | = | lift / stun | `GrabPull` | — |
| 62 | Tank Tracks | `TANK_TRACKS` | 8 | Heavy Yard | Mobility | Rare | = | huge control resistance | — | `Tracks` |
| 63 | Hydraulic Pump | `HYDRAULIC_PUMP` | 8 | Heavy Yard | Back | Epic | Rare | attack-force increase | — | — |
| 64 | Crane Hook | `CRANE_HOOK` | 8 | Heavy Yard | Arm | Legendary | = | pulls enemy across Arena | `GrabPull` | — |
| 65 | Warning Beacon | `WARNING_BEACON` | 9 | Power Plant | Head | Common | = | faster threat switching | — | — |
| 66 | Transformer Core | `TRANSFORMER_CORE` | 9 | Power Plant | Core | Uncommon | Rare | electric attacks | — | — |
| 67 | Turbine Shell | `TURBINE_SHELL` | 9 | Power Plant | Body | Uncommon | Rare | high durability | — | — |
| 68 | Busbar Blade | `BUSBAR_BLADE` | 9 | Power Plant | Arm | Rare | = | electrical melee | `SweepLight` | — |
| 69 | Coil Cannon | `COIL_CANNON` | 9 | Power Plant | Arm | Rare | Epic | ranged electrical shot | `RangedCannon` | — |
| 70 | Magnetic Rail | `MAGNETIC_RAIL` | 9 | Power Plant | Mobility | Rare | = | fast controlled movement | — | `Hover` |
| 71 | Capacitor Bank | `CAPACITOR_BANK` | 9 | Power Plant | Back | Epic | = | ability storage | — | — |
| 72 | Plasma Dynamo | `PLASMA_DYNAMO` | 9 | Power Plant | Core | Legendary | = | periodic area shock | — | — |
| 73 | Prototype Sensor | `PROTOTYPE_SENSOR` | 10 | Robot Laboratory | Head | Uncommon | Rare | advanced targeting | — | — |
| 74 | AI Matrix | `AI_MATRIX` | 10 | Robot Laboratory | Core | Rare | Epic | better combat decisions | — | — |
| 75 | Combat Frame | `COMBAT_FRAME` | 10 | Robot Laboratory | Body | Rare | = | balanced high-tier armor | — | — |
| 76 | Plasma Cutter | `PLASMA_CUTTER` | 10 | Robot Laboratory | Arm | Epic | = | armor penetration | `ThrustContinuous` | — |
| 77 | Servo Fist | `SERVO_FIST` | 10 | Robot Laboratory | Arm | Rare | = | fast heavy punch | `PunchFast` | — |
| 78 | Hover Actuators | `HOVER_ACTUATORS` | 10 | Robot Laboratory | Mobility | Epic | = | ignores some knockback | — | `Hover` |
| 79 | Shield Generator | `SHIELD_GENERATOR` | 10 | Robot Laboratory | Back | Epic | = | regenerating shield | — | — |
| 80 | Experimental Magnet Arm | `EXPERIMENTAL_MAGNET_ARM` | 10 | Robot Laboratory | Arm | Legendary | = | physically pulls enemies | `GrabPull` | — |
| 81 | Satellite Dish | `SATELLITE_DISH` | 11 | Space Foundry | Head | Uncommon | Rare | long-range targeting | — | — |
| 82 | Fusion Cell | `FUSION_CELL` | 11 | Space Foundry | Core | Epic | = | huge energy generation | — | — |
| 83 | Heat Shield | `HEAT_SHIELD` | 11 | Space Foundry | Body | Rare | = | damage resistance | — | — |
| 84 | Manipulator Claw | `MANIPULATOR_CLAW` | 11 | Space Foundry | Arm | Rare | = | grab ability | `GrabPull` | — |
| 85 | Ion Lance | `ION_LANCE` | 11 | Space Foundry | Arm | Epic | = | ranged piercing attack | `RangedCannon` | — |
| 86 | Rover Legs | `ROVER_LEGS` | 11 | Space Foundry | Mobility | Rare | = | strong traction | — | `Legs` |
| 87 | Thruster Pack | `THRUSTER_PACK` | 11 | Space Foundry | Back | Epic | = | arena dash | — | — |
| 88 | Meteor Drill | `METEOR_DRILL` | 11 | Space Foundry | Arm | Legendary | = | escalating continuous damage | `ThrustContinuous` | — |
| 89 | Quantum Lens | `QUANTUM_LENS` | 12 | Quantum Reactor | Head | Uncommon | Epic | predicts enemy movement | — | — |
| 90 | Singularity Core | `SINGULARITY_CORE` | 12 | Quantum Reactor | Core | Epic | Legendary | huge power output | — | — |
| 91 | Reactor Shell | `REACTOR_SHELL` | 12 | Quantum Reactor | Body | Rare | Epic | extreme durability | — | — |
| 92 | Gravity Hammer | `GRAVITY_HAMMER` | 12 | Quantum Reactor | Arm | Rare | Epic | massive knockback | `SmashHeavy` | — |
| 93 | Phase Blade | `PHASE_BLADE` | 12 | Quantum Reactor | Arm | Epic | Legendary | partially ignores armor | `SweepLight` | — |
| 94 | Gravity Ring | `GRAVITY_RING` | 12 | Quantum Reactor | Mobility | Rare | Epic | unusual movement | — | `Hover` |
| 95 | Flux Stabilizer | `FLUX_STABILIZER` | 12 | Quantum Reactor | Back | Epic | = | cooldown reduction | — | — |
| 96 | Void Magnet | `VOID_MAGNET` | 12 | Quantum Reactor | Arm | Mythic | = | pulls multiple robots toward itself | `GrabPull` | — |

**96 parts.**

## Rarity distribution

| Rarity | Ours | Spec's |
|---|--:|--:|
| Common | 18 | 20 |
| Uncommon | 27 | 13 |
| Rare | 27 | 35 |
| Epic | 12 | 14 |
| Legendary | 11 | 13 |
| Mythic | 1 | 1 |

The spec's column is why [decision 0015](../decisions/0015-rarity-is-re-graded.md) exists: it graded
**35 of 96 parts `Rare`** against only **13 `Uncommon`**, making `Rare` the most common rarity in the
game and leaving the colour ramp meaningless.

The re-grade bands **per tier** and keeps the spec's own ordering inside each tier, so a tier's most
valuable part stays its most valuable part. Depth shifts the band up: tiers 1-3 top out at one
Legendary over mostly Commons; tiers 10-12 have no Commons at all. **Every tier still has exactly one
top-grade part** — its trophy — except tier 12, whose Void Magnet is the game's only Mythic.

## Slot distribution

| Slot | Count |
|---|--:|
| Head | 13 |
| Core | 13 |
| Body | 13 |
| Arm | 33 |
| Mobility | 12 |
| Back | 12 |

Arms are the largest group by a wide margin, which is correct: arms are where the visible comedy lives,
and both arm sockets accept any Arm part. Spoon + STOP Sign is a legal build.

## Animation profiles *(derived)*

Only parts that swing, shoot, block or grab need a combat profile. Head, Core, Body and Back parts are
passive — they change stats and add VFX; they do not drive the rig.

| Profile | Parts |
|---|--:|
| `GrabPull` | 7 |
| `RangedCannon` | 5 |
| `SmashHeavy` | 5 |
| `SweepLight` | 4 |
| `ThrustContinuous` | 4 |
| `PunchFast` | 2 |
| `Shield` | 2 |
| `SweepHeavy` | 2 |
| `ChargeBody` | 1 |
| `RangedRapid` | 1 |
| **total** | **33** |

## Mobility profiles *(derived)*

| Profile | Parts |
|---|--:|
| `Wheels` | 7 |
| `Hover` | 3 |
| `Legs` | 1 |
| `Tracks` | 1 |
| **total** | **12** |

**33 parts carry a combat profile across 10 profiles. 12 carry a mobility profile across 4. The
remaining 51 are passive.**

This is the payoff of [decision 0004](../decisions/0004-parts-are-content-rig-is-the-engine.md): a
catalog that could have needed hundreds of bespoke animations needs **10 combat clips** plus the shared
locomotion and reaction set. Definitions are in
[systems/robot-rig](../systems/robot-rig/README.md#5-animation-profiles).

## What is still missing per part

Every row above needs, before it can ship:

- a model with a `RobotMount` `Attachment`
- `Weight` class (Small / Medium / Heavy / Extreme) — drives the carry penalty
- `CombatStats`: damage · attackSpeed · knockback · range · hp · armor
- `VFXProfile` and `SoundProfile`
- a Magnet Power requirement to detach it

**None of these are specified anywhere in the spec.** They are per-tier balance work and belong to that
tier's build group, not to this catalog.
