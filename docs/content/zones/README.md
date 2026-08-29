# The twelve zones

One continuous corridor ([decision 0003](../../decisions/0003-forward-is-the-only-direction.md)). Each
zone owns a **pool of 8 possible Robot Parts**; a Factory Cycle spawns only some of them, re-weighted by
the active Shift ([decision 0006](../../decisions/0006-the-factory-refreshes.md)).

Full part list with slots, rarities and effects: [parts-catalog.md](../parts-catalog.md).

> **What is the spec's and what is not.** Zone names, scales, guardians, gate values and all 96 parts are
> **the spec's**. The spec gives an *Environment/Theme* only for tiers 1, 2, 3 and 5, and an *object
> list* only for tiers 1 and 2. Everything else on this page is marked **(derived)** — a job 001
> proposal, not a specified value.

## Overview

| Tier | Zone | Scale | Guardian | Magnet Power gate |
|---:|---|---|---|---:|
| 1 | **Color Workshop** | Tiny scrap | Slow Scrap Sweeper Bot. | 10 |
| 2 | **Toy Assembly** | Toys / mechanisms | Wind-Up Security Bot. | 20 |
| 3 | **Mega Kitchen** | Appliances | Chef Security Bot. | 35 |
| 4 | **Warehouse** | Industrial storage | Security Forklift. | 55 |
| 5 | **City Storage** | Urban metal | Security Patrol Cart. | 85 |
| 6 | **Vehicle Workshop** | Vehicle components | Security Motorcycle. | 130 |
| 7 | **Car Factory** | Cars | Autonomous Security Car. | 200 |
| 8 | **Heavy Yard** | Construction machines | Autonomous Bulldozer. | 300 |
| 9 | **Power Plant** | Heavy electrical | Electrical Sentinel. | 450 |
| 10 | **Robot Laboratory** | Experimental technology | Prototype Combat Robot. | 675 |
| 11 | **Space Foundry** | Space hardware | Orbital Defense Drone. | 1,000 |
| 12 | **Quantum Reactor** | Impossible technology | Quantum Warden. | 1,500 |

Power gates rise roughly ×1.5 per zone. **These are initial balancing targets (§62) and must be
playtested.**

Service Hubs sit after zones **2, 4, 6, 8, 10 and 12** — six hubs, evenly spaced. §18 says only
"approximately every two zones" and does not enumerate them; the placement was **decided**, so that a
rare part is never more than two zones from safety and the longest extraction stays inside the spec's
20-45 second target.

---

## Tier 1 — COLOR WORKSHOP

**Theme.** Cyan / pink / yellow., Small conveyors., Paint machines., Bright toy-like machinery.

**Normal scrap.** screws, nuts, washers, bolts, gears, springs, metal beads, small pipes

**Guardian.** Slow Scrap Sweeper Bot.

**Gate.** Magnet Power 10

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Work Lamp | Head | Common | improved targeting |
| Mini Motor | Core | Common | attack-speed bonus |
| Paint Drum | Body | Common | basic HP |
| Pipe Wrench | Arm | Uncommon *(spec: Common)* | balanced melee |
| Spring Puncher | Arm | Uncommon | knockback punch |
| Caster Wheels | Mobility | Uncommon *(spec: Common)* | movement speed |
| Magnet Coil | Back | Rare | stronger Arena control |
| Golden Gear | Head | Legendary | faster ability charging |

## Tier 2 — TOY ASSEMBLY

**Theme.** Colorful toy manufacturing.

**Normal scrap.** toy cars, wind-up mechanisms, metal blocks, toy robots, springs

**Guardian.** Wind-Up Security Bot.

**Gate.** Magnet Power 20

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Toy Camera | Head | Common | improved ranged targeting |
| Wind-Up Key | Core | Uncommon | periodic speed burst |
| Building Block Chest | Body | Common | balanced armor |
| Grabber Claw | Arm | Common | pull enemy closer |
| Toy Hammer | Arm | Uncommon | heavy strike |
| Roller Skates | Mobility | Uncommon *(spec: Common)* | high movement |
| Propeller Pack | Back | Rare | short dodge burst |
| Jack-in-the-Box Launcher | Arm | Legendary | surprise ranged attack |

## Tier 3 — MEGA KITCHEN

**Theme.** Oversized industrial kitchen.

**Normal scrap *(derived)*.** pots, pans, cutlery, appliance parts

**Guardian.** Chef Security Bot.

**Gate.** Magnet Power 35

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Colander | Head | Common | increased energy regeneration |
| Blender Motor | Core | Common *(spec: Uncommon)* | faster attacks |
| Refrigerator Door | Body | Uncommon *(spec: Rare)* | large armor bonus |
| Giant Spoon | Arm | Uncommon | huge sweeping attack |
| Frying Pan | Arm | Uncommon *(spec: Rare)* | shield / counter |
| Serving Cart Wheels | Mobility | Common | stable movement |
| Toaster Coil | Back | Rare | electrical retaliation |
| Golden Tenderizer | Arm | Legendary | massive critical hit |

## Tier 4 — WAREHOUSE

**Theme *(derived)*.** Industrial storage. Racking, pallets, strapping.

**Normal scrap *(derived)*.** pallet hardware, brackets, chain, strapping, shelf pins

**Guardian.** Security Forklift.

**Gate.** Magnet Power 55

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Barcode Scanner | Head | Common | target selection |
| Pallet Motor | Core | Common | torque bonus |
| Metal Locker | Body | Uncommon | high HP |
| Shelf Beam | Arm | Uncommon *(spec: Common)* | long-range melee |
| Strapping Gun | Arm | Rare | rapid ranged attack |
| Pallet Wheels | Mobility | Uncommon *(spec: Common)* | strong stability |
| Forklift Battery | Back | Rare | ability-energy bonus |
| Vault Door | Body | Legendary | enormous armor |

## Tier 5 — CITY STORAGE

**Theme.** Traffic equipment, mall storage, maintenance.

**Normal scrap *(derived)*.** sign hardware, meter parts, cart wheels, urban metal

**Guardian.** Security Patrol Cart.

**Gate.** Magnet Power 85

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Traffic Light | Head | Uncommon | combat-mode switching |
| Scooter Battery | Core | Common | movement-energy bonus |
| Vending Machine | Body | Rare | large HP |
| STOP Sign | Arm | Uncommon | shield |
| Parking Meter | Arm | Uncommon | fast mace |
| Shopping Cart Wheels | Mobility | Common | excellent acceleration |
| Neon Transformer | Back | Rare | electric damage |
| Golden Hydrant Cannon | Arm | Legendary | high-pressure knockback |

## Tier 6 — VEHICLE WORKSHOP

**Theme *(derived)*.** Repair bays, lifts, part racks.

**Normal scrap *(derived)*.** spark plugs, discs, bolts, exhaust sections, mirrors

**Guardian.** Security Motorcycle.

**Gate.** Magnet Power 130

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Headlight Cluster | Head | Common | accuracy bonus |
| Engine Block | Core | Uncommon *(spec: Rare)* | major power increase |
| Car Door | Body | Common *(spec: Uncommon)* | balanced armor |
| Exhaust Cannon | Arm | Uncommon *(spec: Rare)* | ranged burst |
| Brake Disc Saw | Arm | Rare | rapid melee |
| Motorcycle Wheels | Mobility | Uncommon | very high speed |
| Turbocharger | Back | Rare | temporary overdrive |
| Chrome Bumper | Arm | Legendary | devastating charge |

## Tier 7 — CAR FACTORY

**Theme *(derived)*.** Full assembly line. Robot welders, body shells on rails.

**Normal scrap *(derived)*.** body panels, axles, sensors, wiring looms

**Guardian.** Autonomous Security Car.

**Gate.** Magnet Power 200

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Sensor Rack | Head | Common *(spec: Uncommon)* | better tactical AI |
| V8 Engine | Core | Uncommon *(spec: Rare)* | high damage |
| Vehicle Chassis | Body | Rare | HP + stability |
| Welding Arm | Arm | Uncommon | burn damage |
| Axle Hammer | Arm | Rare | heavy stun |
| Racing Wheels | Mobility | Rare | extreme acceleration |
| Nitrous Tanks | Back | Epic *(spec: Rare)* | temporary speed boost |
| Prototype Engine Crane | Arm | Legendary | grab and throw |

## Tier 8 — HEAVY YARD

**Theme *(derived)*.** Outdoor construction yard. Mud, floodlights, big machines.

**Normal scrap *(derived)*.** track links, hydraulic rams, counterweights, bucket teeth

**Guardian.** Autonomous Bulldozer.

**Gate.** Magnet Power 300

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Worklight Tower | Head | Common | long-range detection |
| Diesel Generator | Core | Uncommon *(spec: Rare)* | huge energy pool |
| Bulldozer Plate | Body | Uncommon *(spec: Rare)* | frontal armor |
| Excavator Bucket | Arm | Rare | enormous slow hit |
| Forklift Fork | Arm | Rare | lift / stun |
| Tank Tracks | Mobility | Rare | huge control resistance |
| Hydraulic Pump | Back | Epic *(spec: Rare)* | attack-force increase |
| Crane Hook | Arm | Legendary | pulls enemy across Arena |

## Tier 9 — POWER PLANT

**Theme *(derived)*.** Turbine halls, busbars, transformer yards. Arcing everywhere.

**Normal scrap *(derived)*.** insulators, copper bar, coils, breaker parts

**Guardian.** Electrical Sentinel.

**Gate.** Magnet Power 450

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Warning Beacon | Head | Common | faster threat switching |
| Transformer Core | Core | Uncommon *(spec: Rare)* | electric attacks |
| Turbine Shell | Body | Uncommon *(spec: Rare)* | high durability |
| Busbar Blade | Arm | Rare | electrical melee |
| Coil Cannon | Arm | Rare *(spec: Epic)* | ranged electrical shot |
| Magnetic Rail | Mobility | Rare | fast controlled movement |
| Capacitor Bank | Back | Epic | ability storage |
| Plasma Dynamo | Core | Legendary | periodic area shock |

## Tier 10 — ROBOT LABORATORY

**Theme *(derived)*.** Clean labs, test chambers, experimental hardware.

**Normal scrap *(derived)*.** servos, actuators, lab hardware, prototype plating

**Guardian.** Prototype Combat Robot.

**Gate.** Magnet Power 675

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Prototype Sensor | Head | Uncommon *(spec: Rare)* | advanced targeting |
| AI Matrix | Core | Rare *(spec: Epic)* | better combat decisions |
| Combat Frame | Body | Rare | balanced high-tier armor |
| Plasma Cutter | Arm | Epic | armor penetration |
| Servo Fist | Arm | Rare | fast heavy punch |
| Hover Actuators | Mobility | Epic | ignores some knockback |
| Shield Generator | Back | Epic | regenerating shield |
| Experimental Magnet Arm | Arm | Legendary | physically pulls enemies |

## Tier 11 — SPACE FOUNDRY

**Theme *(derived)*.** Vacuum chambers, launch rails, orbital hardware.

**Normal scrap *(derived)*.** heat tiles, fasteners, thruster nozzles, alloy offcuts

**Guardian.** Orbital Defense Drone.

**Gate.** Magnet Power 1,000

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Satellite Dish | Head | Uncommon *(spec: Rare)* | long-range targeting |
| Fusion Cell | Core | Epic | huge energy generation |
| Heat Shield | Body | Rare | damage resistance |
| Manipulator Claw | Arm | Rare | grab ability |
| Ion Lance | Arm | Epic | ranged piercing attack |
| Rover Legs | Mobility | Rare | strong traction |
| Thruster Pack | Back | Epic | arena dash |
| Meteor Drill | Arm | Legendary | escalating continuous damage |

## Tier 12 — QUANTUM REACTOR

**Theme *(derived)*.** Impossible technology. Light that behaves wrongly.

**Normal scrap *(derived)*.** exotic alloy, containment rings, flux shards

**Guardian.** Quantum Warden.

**Gate.** Magnet Power 1,500

| Part | Slot | Rarity | Effect |
|---|---|---|---|
| Quantum Lens | Head | Uncommon *(spec: Epic)* | predicts enemy movement |
| Singularity Core | Core | Epic *(spec: Legendary)* | huge power output |
| Reactor Shell | Body | Rare *(spec: Epic)* | extreme durability |
| Gravity Hammer | Arm | Rare *(spec: Epic)* | massive knockback |
| Phase Blade | Arm | Epic *(spec: Legendary)* | partially ignores armor |
| Gravity Ring | Mobility | Rare *(spec: Epic)* | unusual movement |
| Flux Stabilizer | Back | Epic | cooldown reduction |
| Void Magnet | Arm | Mythic | pulls multiple robots toward itself |

---

## Observations on the pool as written

Counted by `tools/gen-content-catalogs.py`, not eyeballed. Slots and part counts are the spec's;
rarity is the re-graded value ([decision 0015](../../decisions/0015-rarity-is-re-graded.md)).

- **Every tier has exactly 8 parts.** 12 × 8 = **96**.
- **Every tier can fill all seven slots.** All 12 tiers contain a Head, Core, Body, Mobility and Back
  part plus at least two Arms, so a player working a single tier is never blocked from completing a
  robot. What a tier does *not* give is a *choice* — usually exactly one option per non-Arm slot.
- **Some tiers double up a slot instead of spreading:** tier 1 has 2 Head parts; tier 4 has 2 Body parts; tier 9 has 2 Core parts. Those tiers offer two options in one slot and
  one everywhere else.
- **The top-grade part of a tier is usually an Arm — 9 of 12** (11 Legendary + 1 Mythic, one per
  tier). The exceptions are Golden Gear (tier 1, Head), Vault Door (tier 4, Body), Plasma Dynamo (tier 9, Core).
- **Mobility is thin and expensive at the top.** Tiers 9-12 offer only Magnetic Rail (Rare), Hover Actuators (Epic), Rover Legs (Rare), Gravity Ring (Rare) — 1 of them Epic (Hover Actuators). A late
  player who has not found an Epic mobility part is on Racing Wheels (tier 7, Rare) or an earlier wheel.
- The **Giant Spoon** (tier 3, Uncommon) is called out in §28 as the part that should become the game's
  recognisable icon. It is deliberately *not* rare — everyone should get one.
