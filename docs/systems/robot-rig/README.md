# Robot rig — how a robot made of a fridge door is built and animated

**The architecture decision that everything else follows from:**

> **Robot parts are content. The skeleton, the sockets and the animation profiles are the engine.**

Adding a Toilet Brush Arm must mean: make the model, add one attachment, fill in a stats row, pick an
animation profile. It must never mean writing robot code. See
[decision 0004](../../decisions/0004-parts-are-content-rig-is-the-engine.md).

---

## 1. One hidden skeleton, always the same

The player sees a traffic light bolted to a fridge door holding a spoon. Roblox sees the same nine-joint
rig every single time.

```
                    RobotRoot          (the only part the movement controller moves)
                        │
                    TorsoPivot ──────── BackSocket
                    │   │   │
        ┌───────────┘   │   └───────────┐
  LeftShoulderPivot  HeadPivot   RightShoulderPivot
        │               │               │
   LeftArmPivot     HeadSocket      RightArmPivot
        │                               │
   LeftArmSocket                  RightArmSocket

                    TorsoPivot
                        │
                   CoreSocket  ·  BodySocket
                        │
                   MobilityPivot
                    /        \
             LeftDrive     RightDrive
```

**~10 animated joints. That is the whole rig.** No fingers, no facial bones, no R15 mapping. Chunky
mechanical motion is not a compromise here — it is the correct look for objects made of appliances.

Every pivot is an invisible, `Massless`, `CanCollide = false` carrier part. Sockets are `Attachment`s
on those carriers.

### Joints: Motor6D now, AnimationConstraint later

| Use | Joint | Why |
|---|---|---|
| **V1, every animated joint** | `Motor6D` | This is what Studio's Animation Editor authors against and what `Animator` drives via `Transform`. Well-trodden, cheap, exact. |
| **Later, the physical-reaction layer** | `AnimationConstraint` | Newer, spring-driven, can hand a limb to the physics solver and take it back. This is how a WHAM from an excavator bucket throws a robot around and then recovers into animation. |

`Motor6D` is **not deprecated** and does not need replacing. Treat `AnimationConstraint` as an upgrade
for §14's "physical reaction" idea, scheduled after combat feels right — not as V1 plumbing.

### Playback

`AnimationController` + `Animator` on the robot model — **not** a `Humanoid`. These robots need none of
the Humanoid feature set (no health state machine, no default animate script, no walk controller) and a
Humanoid would fight the custom movement controller for the root.

```
RobotModel
├── RobotRoot            (PrimaryPart, unanchored, server-owned)
├── AnimationController
│   └── Animator         ← Animator:LoadAnimation(anim) → AnimationTrack
├── Rig/                 (the pivots above, joined by Motor6D)
├── Mounted/             (whatever the player bolted on)
└── Hitboxes/            (scripted, invisible, NOT derived from the mesh)
```

Use `Animator:LoadAnimation`, never the deprecated `Humanoid:LoadAnimation`. **Cache the tracks** — a
robot reloads the same six animations for its whole Arena deployment.

> 🔴 **Play robot animations on the CLIENT.** An `Animator` replicates, so a server-played track shows
> up for everyone — but the **server's own rig stays in its rest pose**, and a server-side read of a
> track's weight returns `0`. This is recorded on Jungle: *NPC rig pose is client-only.*
>
> **Therefore: never resolve combat from where a limb visually is.** Hit detection reads the AI state
> and `RobotRoot`'s CFrame and uses a scripted hitbox volume. If a designer ever writes "raycast from
> the spoon's tip", that is the bug.

---

## 2. Every part carries one attachment

The single asset rule that makes the whole system work:

```
GiantSpoon                      StopSign                   TrafficLight
├── MeshPart                    ├── MeshPart               ├── Model
└── RobotMount   ← Attachment   └── RobotMount             └── RobotMount
```

`RobotMount` is a plain `Attachment` whose **position and orientation define how the object hangs**.
Mount it once, at import time, and the part works forever after.

Assembly is then one sentence: *put `GiantSpoon.RobotMount` onto `Robot.RightArmSocket`, and weld it.*

Meshy does not need to know anything about robots. Generate the object, import it, add one attachment.

> 🔴 **Two import traps this workspace has already paid for:**
>
> - **`PivotTo` vs `PrimaryPart`.** `Model:PivotTo()` places by the model's pivot — but if the model has
>   a `PrimaryPart`, that silently overrides `WorldPivot`, and imported meshes land 100+ studs off. For
>   robot parts, do not place by pivot at all: align `RobotMount` to the socket explicitly.
> - **`CollisionFidelity`.** Imported meshes default to `Box`. A spoon, a crane hook or a fork with a
>   box hull is a brick. Set `PreciseConvexDecomposition` on anything with a gap that matters —
>   and set `CanCollide = false` + `Massless = true` on mounted parts regardless (see §4).

---

## 3. Rigid mounting: `WeldConstraint`

A fridge door does not deform. It does not need a bone. It needs to be nailed to something that moves.

```
RightShoulderPivot   (animated Motor6D)
        │
   RightArmPivot     (animated Motor6D)
        │
   RightArmSocket    (Attachment)
        │  WeldConstraint
        ▼
   🥄 GIANT SPOON
```

Rotate the shoulder, the entire spoon follows. Cheap, exact, and it works identically for a spoon, a
STOP sign, a satellite dish and a vault door.

Use `WeldConstraint` (Part0/Part1, keeps current relative CFrame) rather than a legacy `Weld` — snap the
part into place first by matching `RobotMount`'s CFrame to the socket's, *then* weld.

---

## 4. Mounted parts are visual; they are not physics

Every part welded onto a robot gets:

```
part.Massless   = true      -- a vault door must not change how the robot moves
part.CanCollide = false     -- and must not catch on the arena floor
part.CanQuery   = false     -- raycasts ignore it
part.CanTouch   = false
```

**Why this is non-negotiable:** the whole appeal is bolting on absurdly mismatched objects. If mass and
collision came from the actual geometry, a Vault Door build would be unplayable and an Excavator Bucket
would tip the robot over. Stats come from the **part's stat row**, not from its `Mass`. Hit volumes come
from `Hitboxes/`, not from the mesh.

This also keeps the assembly a **single physics assembly** — one root, one network owner, predictable
knockback.

---

## 5. Animation profiles: ~20 clips for 96 parts

96 catalog parts × 20 animations would be 1,920 animations. It is instead **~20 profiles**, because a
Giant Spoon and an Excavator Bucket are the same shoulder motion with a different object welded on.

A part declares a profile; the combat system only ever knows profiles.

| Profile | Motion | Example parts |
|---|---|---|
| `SweepLight` | fast wide arc | Pipe Wrench, Shelf Beam |
| `SweepHeavy` | wind-up → big arc → follow-through | **Giant Spoon**, Parking Meter |
| `SmashHeavy` | overhead → slam | Excavator Bucket, Axle Hammer, Gravity Hammer |
| `PunchFast` | short straight jab | Servo Fist, Spring Puncher |
| `ThrustContinuous` | held forward, part spins | Meteor Drill, Brake Disc Saw |
| `Shield` | raise and brace | **STOP Sign**, Frying Pan |
| `RangedCannon` | brace → recoil | Coil Cannon, Exhaust Cannon, Ion Lance |
| `RangedRapid` | small repeated recoil | Strapping Gun |
| `GrabPull` | reach → clamp → yank | Crane Hook, Grabber Claw, Experimental Magnet Arm |
| `ChargeBody` | whole-body lunge | Chrome Bumper |

Plus the non-combat set every robot shares: `Idle`, `WalkWheels`, `WalkLegs`, `WalkTracks`, `Hover`,
`HitFront`, `HitBack`, `Knockback`, `Stunned`, `ArenaEnter`, `Victory`, `Defeat`.

**Priority matters.** `Idle < Movement < Action < Action2/3/4 < Core`. An attack profile must outrank
the locomotion clip or it will not be visible. Layering an upper-body attack over a running lower body
is the intended shape — see §8.

---

## 6. Parts that move on their own

Some parts earn a constraint of their own. This is where the game stops looking like a costume.

| Part | Mechanism | Result |
|---|---|---|
| Meteor Drill, Brake Disc Saw | `HingeConstraint`, `ActuatorType = Motor`, `AngularVelocity` + `MotorMaxTorque` | the bit actually spins — **VRRRRRR** |
| Spring Puncher, Axle Hammer | `PrismaticConstraint`, `ActuatorType = Motor`/`Servo` | the head physically shoots forward and retracts |
| Propeller Pack, Turbocharger | `HingeConstraint` motor | fan blades spin while the ability is charging |
| Caster / Racing / Shopping-Cart Wheels | `HingeConstraint` motor, or a spun visual | wheels roll at the robot's actual ground speed |
| Toy antenna, cables, Wind-Up Key | `SpringConstraint` | secondary bounce that follows the body a frame late |

These are **decorative actuators**. They spin, slide and bounce; they never propel the robot. Anything
that would let a part's physics move the assembly is a bug — see §7.

Every actuator is driven from the animation's own timeline via `GetMarkerReachedSignal("SpinUp")` /
`("SpinDown")`, so the motor and the clip cannot drift apart.

---

## 7. Movement: a controlled root, not driven wheels

The Arena robot does **not** drive itself with wheel torque. Physically-driven vehicles in Roblox are
tuning-heavy, unstable at low mass, and a fridge door on caster wheels is exactly the case that goes
wrong.

Instead:

```
AI decides a goal position
        ↓
AlignPosition + AlignOrientation drive RobotRoot toward it
        ↓
MobilityProfile picks the locomotion clip (wheels / legs / tracks / hover)
        ↓
decorative actuators spin at the measured ground speed
```

- `RobotRoot` is **unanchored** — that is what makes knockback real. Knockback = drop the aligner's
  `MaxForce` for ~0.4 s and apply an impulse; the robot skids, the animation plays `Knockback`, then the
  aligner takes over again. An anchored root would make §44's "knockback matters" a lie.
- **`RobotRoot:SetNetworkOwner(nil)`** — server-owned, always. These are contested PvP objects; a
  client must never own one.
- `MobilityProfile` (`Wheels` / `Legs` / `Tracks` / `Hover`) also swaps the **mobility sub-rig** under
  `MobilityPivot`. Same upper skeleton, different bottom half. This is the one place we accept rig
  variation, because rolling and walking cannot share a clip.

### Navigation

The Arena is a mostly open disc, so V1 needs no pathfinding. The AI is a priority ladder:

```
if enemy in attack range        → attack (weapon profile)
elseif not holding the Core     → move to Core
elseif threatened               → face and engage
else                            → hold the Core, scan
```

Add `PathfindingService` only when the Arena grows walls, ramps or hazards — and then with
`AgentRadius`/`AgentHeight` set from the *largest* build, not the average one.

---

## 8. Layering and IK are where the personality comes from

Three cheap techniques buy more life than another twenty animations:

**Layered tracks.** A robot running toward the Core, aiming a Coil Cannon, taking a hit and recoiling
should not stop and restart. Base `Movement` clip + upper-body `Action` clip + a short `Action2`
hit-reaction, blended by priority and weight.

**`IKControl` for aiming and reaching.** Works with an `AnimationController`+`Animator`, not just a
Humanoid. One `RangedCannon` clip plus a `LookAt` IK chain on the arm replaces twenty aiming
animations — the cannon simply tracks the enemy wherever it is. Same for `GrabPull`: the Crane Hook
reaches the *actual* enemy position instead of a canned one.

**Head tracking.** A `LookAt` `IKControl` on `HeadPivot`, active even when idle. A traffic-light head
that turns to watch an opponent before it attacks is the single highest personality-per-byte feature in
the game.

---

## 9. Damage changes the animation, not the inventory

| HP | Look |
|---|---|
| 100 % | clean, smooth |
| 75 % | occasional spark, small arm jerk |
| 50 % | visible sparks, heavier gait, `Damaged` additive layer |
| 25 % | smoke, limp, head flicker, an arm sometimes hangs |
| 10 % | arcing electricity, slow recovery from every hit |
| 0 % | `Defeat` clip, collapse, decorative panels pop off, crane removes it |

> 🔴 **Popped-off parts are a temporary combat clone. The owned part is never lost.** §60 is explicit
> and players would hate the Arena otherwise. The Robot Bay's copy is the truth; the Arena's robot is a
> disposable instance built from it. A destroyed Arena robot costs **repair scrap**, never inventory.

---

## 10. The part specification

Every robot-compatible object ships with the same metadata block. This is the contract between an
artist making a spoon and the code that has never heard of spoons.

```
RobotPart
├── Model                (the geometry)
├── RobotMount           (Attachment — the one manual import step)
├── PartId               "GIANT_SPOON"
├── Slot                 Head | Core | Body | Arm | Mobility | Back
├── Tier                 3   (Mega Kitchen)
├── Rarity               Uncommon
├── Weight               Medium         → player carry-speed penalty
├── AnimationProfile     "SweepHeavy"
├── MobilityProfile      —              (Mobility slot only)
├── CombatStats          damage / attackSpeed / knockback / range / hp / armor
├── SignatureEffect      "huge sweeping attack"
├── VFXProfile           "ElectricBlue"
└── SoundProfile         "MetalHeavy"
```

Arms are interchangeable: a part whose `Slot` is `Arm` mounts to either `LeftArmSocket` or
`RightArmSocket`. Spoon + STOP Sign is a legal, and deliberately encouraged, build.

---

## 11. Assembly is machinery, not character animation

The Robot Bay install sequence (§42) is `TweenService` + constraints on the bay's own crane and
manipulator arms. It is not a robot animation and should not live in the robot's clip set.

```
crane descends → grabs the old part → KRRRK → detaches
new part lowers → VRRRR → RobotMount aligns to socket → CLUNK
bolts spin → ⚡ → robot plays one practice swing of its new profile → "GIANT SPOON INSTALLED"
```

That practice swing is the payoff: the game demonstrating that the ridiculous object you dragged home
is now genuinely part of your machine. It plays the part's **actual `AnimationProfile`**, so it is free.

---

## 12. Mapping, at a glance

| Problem | Roblox mechanism |
|---|---|
| Robot skeleton | custom rig, ~10 invisible pivot parts |
| Animated joints (V1) | `Motor6D` |
| Physical hit reactions (later) | `AnimationConstraint` |
| Playback | `AnimationController` + `Animator` |
| Part sockets | `Attachment` (`RobotMount` → `*Socket`) |
| Rigid part mounting | `WeldConstraint`, part `Massless`+`CanCollide=false` |
| Aiming, reaching, head tracking | `IKControl` (`LookAt` / `Position`) |
| Spinning drills, wheels, fans | `HingeConstraint` motor |
| Pistons, punchers | `PrismaticConstraint` motor/servo |
| Antennae, cables, secondary motion | `SpringConstraint` |
| Arena movement | `AlignPosition` + `AlignOrientation` on an unanchored root |
| Knockback | drop aligner `MaxForce`, apply impulse |
| Complex navigation (later) | `PathfindingService` |
| Bay install sequence | `TweenService` + constraints |
| Sparks, arcs, trails | `ParticleEmitter`, `Beam`, `Trail` |
| Death | `Defeat` clip → decorative panels unweld and fall |

---

## Open questions

| Question | When it must be answered |
|---|---|
| Do the four `MobilityProfile` sub-rigs share one locomotion clip with different weights, or four clips? | before the first mobility part ships |
| Does a two-handed part (Crane Hook, Meteor Drill) occupy both arm sockets, or one? The catalog implies one — but the animation may not read | before tier 8 |
| Is the `Damaged` layer additive over locomotion, or a full replacement clip set? Additive is cheaper and blends; a replacement reads more clearly | before the damage-visual item in the manifest |
| How many robots can render at 30 fps on a mid phone, with parts, actuators and VFX? §43 wants 4–6 | **measure before committing to 6** |
