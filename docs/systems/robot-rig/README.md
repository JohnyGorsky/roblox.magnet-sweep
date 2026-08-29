# Robot rig — how a robot made of a fridge door is built and animated

**The architecture decision that everything else follows from:**

> **Robot parts are content. The skeleton, the sockets and the animation profiles are the engine.**

Adding a Toilet Brush Arm must mean: make the model, add one attachment, fill in a stats row, pick an
animation profile. It must never mean writing robot code. See
[decision 0004](../../decisions/0004-parts-are-content-rig-is-the-engine.md).

> **Notation on this page:** `§N` means **a section of this page**. References to the game
> specification are written out in full ("the spec's Robot Damage Visuals section"), because the two
> numbering schemes collide and §14 means *Magnet VFX* in one and *nothing* in the other.

---

## 1. One hidden skeleton, always the same

The player sees a traffic light bolted to a fridge door holding a spoon. Roblox sees the same ten-joint
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
                   MobilityPivot ──── MobilitySocket
                    /        \
             LeftDrive     RightDrive
```

**Seven sockets, one per slot:** `HeadSocket` · `CoreSocket` · `BodySocket` · `LeftArmSocket` ·
`RightArmSocket` · `MobilitySocket` · `BackSocket`. The Mobility part mounts to `MobilitySocket` and
*also* selects the sub-rig under `MobilityPivot` (§7) — it is the one slot that changes the skeleton,
not just what hangs off it.

**Ten animated joints. That is the whole rig.** No fingers, no facial bones, no R15 mapping. Chunky
mechanical motion is not a compromise here — it is the correct look for objects made of appliances.

Every pivot is an invisible, `Massless`, `CanCollide = false` carrier part. Sockets are `Attachment`s
on those carriers.

### Joints: Motor6D now, AnimationConstraint later

| Use | Joint | Why |
|---|---|---|
| **V1, every animated joint** | `Motor6D` | This is what Studio's Animation Editor authors against and what `Animator` drives via `Transform`. Well-trodden, cheap, exact. |
| **Later, the physical-reaction layer** | `AnimationConstraint` | Newer, spring-driven, can hand a limb to the physics solver and take it back. This is how a WHAM from an excavator bucket throws a robot around and then recovers into animation. |

`Motor6D` carries no deprecation tag, but its own reference page now says it is *superseded by
`AnimationConstraint` for avatar/character rigs* — and `AnimationConstraint` is the default joint for
R15 rigs under AvatarJointUpgrade, not merely "newer". **For a non-avatar mechanical rig `Motor6D`
remains the documented choice**, which is what this game builds, so the decision stands — but do not
justify it with "AnimationConstraint is exotic".

Carry one gotcha: `IsA("Motor6D")` returns **false** on an `AnimationConstraint`, so any joint-walking
code written now must not assume the class.

Treat `AnimationConstraint` as the upgrade path for the physical hit-reaction idea, scheduled after
combat feels right — not as V1 plumbing.

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

`AnimationController` + `Animator` is not merely preferred for a Humanoid-less rig — it is the
**required** pairing; an `Animator` needs one parent or the other. Use `Animator:LoadAnimation`, never
the deprecated `Humanoid:LoadAnimation`.

**Cache the tracks.** A robot uses its ~12 shared clips plus up to two weapon profiles for its whole
Arena deployment, and `LoadAnimation` **always creates a new `AnimationTrack`** — it is not a lookup.
To retrieve an existing track use `Animator:GetTrackByAnimationId()`.

> 🔴 **Play Arena robot animations on the SERVER.** `Animator` replicates *conditionally*, and the
> condition is exactly the case this game is not in:
>
> > "If the `Animator` is **not** a descendant of a player character, its animations must be loaded and
> > started **on the server** to replicate." — `Animator` API reference
>
> The Arena robot is `SetNetworkOwner(nil)` (§7 of this page) and is not anybody's character. A `LocalScript`
> playing a track on it animates **for that one client and nobody else** — every other player watches a
> robot slide around the Arena in its rest pose. That failure looks like a netcode or tuning problem
> for days.
>
> The legitimate client-side pattern is *server broadcasts, every client plays*: an
> `AnimationEvent` remote carrying `(robotId, clipName)`. That needs an explicit remote and it is
> **not** the same thing as "play on the client". If it is ever adopted, it goes in
> [the remote definitions module](../../build/01-foundation.md), not into a `LocalScript` by accident.

> 🔴 **Never resolve combat from where a limb visually is.** A separate fact, and it survives the
> correction above: on the **server** the rig holds its rest pose and a track's weight reads `0`
> (recorded on Jungle — *NPC rig pose is client-only*). Hit detection therefore reads AI state and
> `RobotRoot`'s CFrame against a scripted hitbox volume. If anyone ever writes "raycast from the
> spoon's tip", that is the bug.

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
> - **`CollisionFidelity` is set at import time, not at runtime.** Its write access is
>   `PluginSecurity` and it is `NotReplicated` — "cannot be read or manipulated by scripts during
>   runtime". It is part of the **import checklist**, never part of a mount function. (The Studio
>   command bar *can* write it, which is exactly the trap: it works when you test it there and fails in
>   a real `Script`.)
>
>   The engine default is `Default` (voxel convex decomposition), **not** `Box` — but Meshy and Creator
>   Store imports arrive set to `Box`, which is what this workspace keeps hitting. Use
>   `PreciseConvexDecomposition` for parts with a gap a player can pass through (the spoon's bowl, a
>   crane hook, a fork); it is expensive, so it is not a blanket default for all 96 parts. Mounted parts
>   are `CanCollide = false` regardless (§4 of this page), so for most of them fidelity never matters.

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
part.CanQuery   = false     -- raycasts ignore it (only takes effect once CanCollide is false)
part.CanTouch   = false     -- connecting Touched AFTER this THROWS
```

**Why this is non-negotiable:** the whole appeal is bolting on absurdly mismatched objects. If mass and
collision came from the actual geometry, a Vault Door build would be unplayable and an Excavator Bucket
would tip the robot over. Stats come from the **part's stat row**, not from its `Mass`. Hit volumes come
from `Hitboxes/`, not from the mesh.

This also keeps the assembly a **single physics assembly** — one root, one network owner, predictable
knockback.

---

## 5. Animation profiles

96 catalog parts × 20 animations would be 1,920 animations. It is instead **10 combat profiles**,
because a Giant Spoon and an Excavator Bucket are the same shoulder motion with a different object
welded on.

A part declares a profile; the combat system only ever knows profiles. Counted from the catalog by
`tools/gen-content-catalogs.py`:

| | Count |
|---|--:|
| Parts with a combat `AnimationProfile` | **33** |
| Combat profiles | **10** |
| Parts with a `MobilityProfile` | **12** |
| Mobility profiles | **4** |
| Passive parts (Head / Core / Body / Back) | **51** |

`AnimationProfile` and `MobilityProfile` are **two separate fields** (§10). A Mobility part does not
have a combat profile.

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

**Priority matters, and the enum is a trap.** The real order, highest first:

```
Action4 > Action3 > Action2 > Action > Movement > Idle > Core
```

⚠️ **`Core` is the LOWEST priority, not the highest** — despite its numeric value being `1000` while
`Action4` is `5`. `Enum.AnimationPriority` does **not** order by value, and the docs say so outright:
Core is "intended for use by Roblox default animations and catalog animation bundles". Set a robot's
attack clip to `Core` expecting it to win and it loses to everything, including `Idle`.

So: locomotion on `Movement`, attacks on `Action`, hit reactions on `Action2` so they interrupt an
attack. Layering an upper-body attack over a running lower body is the intended shape — see
[§8 of this page](#8-layering-and-ik-are-where-the-personality-comes-from).

---

## 6. Parts that move on their own

Some parts earn a constraint of their own. This is where the game stops looking like a costume.

| Part | Mechanism | Result |
|---|---|---|
| Meteor Drill, Brake Disc Saw | `HingeConstraint`, `ActuatorType = Motor`, `AngularVelocity` + `MotorMaxTorque` (set `MotorMaxAcceleration` too — it silently caps the motor) | the bit actually spins — **VRRRRRR** |
| Spring Puncher, Axle Hammer | `PrismaticConstraint`, `ActuatorType = Motor` (`Velocity` + `MotorMaxForce`) or `Servo` (`TargetPosition`/`Speed`/`ServoMaxForce`) | the head physically shoots forward and retracts |
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
  aligner takes over again. An anchored root would make the spec's "knockback matters" a lie.

  ⚠️ Three silent-failure modes on that trick: `MaxForce` is **only used when `RigidityEnabled` is
  `false`** — on a rigid aligner, dropping it does nothing at all. If `ForceLimitMode = PerAxis`, the
  limit lives in `MaxAxesForce` instead. And `ApplyAtCenterOfMass` defaults to `false`, which adds
  torque you did not ask for. `AlignOrientation`'s equivalent lever is `MaxTorque`.
- **`RobotRoot:SetNetworkOwner(nil)`** — server-owned, always. These are contested PvP objects; a
  client must never own one.
- `MobilityProfile` (`Wheels` / `Legs` / `Tracks` / `Hover`) swaps the **mobility sub-rig** under
  `MobilityPivot`. Same upper skeleton, different bottom half.

  **One locomotion clip, four sub-rigs.** The upper body plays a single `Move` clip whatever is fitted;
  each sub-rig handles its own motion in its own way — wheels spin on a `HingeConstraint`, tracks scroll
  a texture, hover bobs procedurally. **Only `Legs` needs a real walk cycle.**

  This keeps the sub-rigs *content* rather than code, and it avoids four full clip sets that would each
  need re-blending against every attack and reaction. The visible compromise is that a wheeled build and
  a tracked build look identical from the waist up — acceptable, because the waist up is where all the
  ridiculous salvage is.

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
Humanoid — but it must be a **child of the controller itself**, and all of `Target`, `ChainRoot`,
`EndEffector` and `Type` must be set or it silently does nothing at all.

 One `RangedCannon` clip plus a `LookAt` IK chain on the arm replaces twenty aiming
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

> 🔴 **Popped-off parts are a temporary combat clone. The owned part is never lost.** The spec's
> Robot Damage Visuals section is explicit
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

**Every Arm part takes exactly one socket. There are no two-handed parts.** A Crane Hook, a Meteor
Drill and an Excavator Bucket each mount to one arm, and the animation sells the weight instead of the
socket count. Spoon + STOP Sign is legal, and so is Excavator Bucket + Crane Hook.

That is a deliberate refusal of a tempting feature. A `TwoHanded` flag would add a special case to the
builder UI, the rig, the profile system and every stat row — for a visual nicety — and
[decision 0004](../../decisions/0004-parts-are-content-rig-is-the-engine.md) says a part must never
require code.

---

## 11. Assembly is machinery, not character animation

The Robot Bay install sequence (the spec's Robot Assembly section) is `TweenService` + constraints on the bay's own crane and
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
| Is the `Damaged` layer additive over locomotion, or a full replacement clip set? Additive is cheaper and blends; a replacement reads more clearly. **Proposal: additive**, unless it reads as too subtle at 25 % HP | before the damage-visual item in the manifest |
| How many robots can render at 30 fps on a mid phone, with parts, actuators and VFX? The spec wants 4–6. **Measurement, not a decision** | **measure before committing to 6** |
