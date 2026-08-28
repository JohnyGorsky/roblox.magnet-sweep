# 0009 — Arena robots are animated on a controlled root, not physically driven

**Status:** Accepted · 2026-08-29 · Job 001

## Context

Robots are built from wheels, tracks, legs and hover actuators. The literal implementation is to make
the wheels real and drive the robot with torque.

Roblox physically-driven vehicles are tuning-heavy and unstable at low mass, and this game's robots have
deliberately absurd mass distribution — a fridge door on caster wheels holding a spoon. Meanwhile
section 44 says knockback matters, so an anchored robot is also wrong.

## Decision

- The robot is **one physics assembly** with an **unanchored** `RobotRoot`.
- Movement is `AlignPosition` + `AlignOrientation` driving that root toward an AI goal.
- `MobilityProfile` chooses the **locomotion animation**; wheels, tracks and legs are visual.
- Wheels, drills and pistons get `HingeConstraint`/`PrismaticConstraint` motors as **decorative
  actuators**. They spin and slide. They never propel the robot.
- Knockback drops the aligner's `MaxForce` briefly and applies an impulse. The robot really skids.
- `RobotRoot:SetNetworkOwner(nil)` — server-owned, always, because these are contested PvP objects.
- Mounted parts are `Massless`, `CanCollide = false`. Stats come from the data row, not the mesh.

## Consequences

- A Vault Door build and a Colander build move predictably and comparably. Balance is a stat table, not
  an emergent physics accident.
- Knockback, which the arena design leans on heavily, is real and tunable.
- No client can push another player's robot.
- Adding a new mobility type is a clip plus a sub-rig, not a vehicle-tuning exercise.

## What we give up

Genuinely emergent vehicle physics — robots tipping over, wheels catching on debris. That would be fun
occasionally and infuriating in a persistent PvP arena where the robot fights unattended and the owner
cannot correct it.
