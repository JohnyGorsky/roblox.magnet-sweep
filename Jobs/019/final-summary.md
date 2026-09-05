# Job 019 — final summary

**What it became.** The intake said "hub becomes a ring of 12 bases". That design was built, shown,
and **rejected outright** by the owner — *"all crowded no rooms"*, *"whole idea whole concept whole
your builtlook is totally wrong"*. What the job actually delivered instead is the thing that made a
second attempt possible: **a complete asset set, a staging room to judge it in, and a robot that
assembles and animates.**

## The five ground rules that redirected everything

Set by the owner mid-job, and now in `docs/systems/player-base` and the workspace memory:

1. Build **everything in the editor**, so it can be moved.
2. **Real assets** — kit primitives read as placeholder.
3. Upgrade buildings are **common**, not per-player.
4. A player owns **only their smelter**.
5. Other shops are **common** too.

Consequence: `HubBuilder`, `HubSpec`, `WorkshopBuilder` and the per-base station logic are switched
off (`BUILD_GENERATED_WORLD = false` in `Bootstrap`) and should be deleted in a later job.

## Delivered

| | |
|---|---|
| **44 meshes** generated and imported | walls, 12 scrap types, 16 robot parts, 3 common buildings, 9 Workshop objects, ingot |
| **Arena** | built in the editor, 692 parts, 224 across, magnet on a gantry 184 up |
| **Demo room** | staging area at x 670..1130 — floor patterns, wall patterns, scrap, parts, rarity grades, smelter rig, workshop inventory board, 7 robots |
| **Smelter rig** | hopper → belt → furnace → output bay, **12 parts** as meshes (was 194 as primitives) |
| **Robot rig** | 10 joints, 7 sockets, `AnimationController` + `Animator` |
| **16 part mounts** | hand-posed by the owner, exported to `Config/PartMounts.luau` |
| **3 animation clips** | Idle, Move, SweepLight — side-aware and mirrored, in `Robot/RobotAnim.luau` |
| **96-part catalog** | `Config/PartsCatalog.luau`, generated from the doc, validates clean |

## Decisions taken

- **Bright lighting**, warm rather than dusk. High Ambient does not brighten a scene, it *flattens*
  it — the tiles were rendering near-white while painted `#55555E`.
- **Floors and walls combine by purpose** rather than one winning: checker as default, hazard at
  thresholds, bay rings under pads, big plates in the run lane.
- **The player base is a Gantry** — a crane arm holding the robot over the player's own smelter. The
  install sequence in `robot-assembly` already required a crane, so it is that crane doing a second
  job.
- **Ingots buy Coins only.** The gantry connects the two tracks physically while the economy stays
  separate.
- **Belts run while you are in the server**, not offline. **Unclaimed bases are dormant.** **Bases
  ring the room behind the common buildings.** **Anyone can walk into your base** — belts are
  stealable, so a barrier would be arbitrary.
- **The game gives a fixed starter robot.** No tier has a Common part for every slot, so a
  Commons-only robot cannot move or fight.

## What was learned the hard way

- 🔴 **A bounding box is not a feature.** The furnace mouth sat 4 studs off its mesh centre, so
  "aligned to 0.02 studs" was true and useless. Same class of error placed every arm by its middle.
  Fixed by hand-posing and recording `Attachment`s.
- 🔴 **`PivotTo` moved only `RobotRoot`**, leaving every other pivot at the origin — all seven sockets
  at (0,0,0) and parts mounted 900 studs away. Explicit per-part translation instead.
- 🔴 **Anchor before moving.** Nudging a part joined by `Motor6D` or `WeldConstraint` drags its
  neighbours; that scattered a robot across 54 studs and pushed `TorsoPivot` 1.4 studs off centre.
- 🔴 **`Model:ScaleTo` is absolute**, relative to import size — rescaling an already-scaled part
  shrinks it to a speck.
- 🔴 **`require` is cached, and a destroyed clone keeps its connections.** An edited module kept
  returning its old table, and three "refresh" clones left three animators fighting over one joint.
- 🔴 **Coplanar faces are the glitchy floor.** Two same-facing surfaces at one height tear.
- 🔴 Heavy `execute_luau` scripts **crash Studio** — split into one folder per call.

## Outstanding

- `GRABBER_CLAW` mount was never hand-posed (marked `derived` in `PartMounts`).
- Spawn point still sits on the arena plinth.
- 20 of 23 animation clips unwritten.
- Nothing in the game can assemble a robot yet — assembly only exists in throwaway scripts.
- `HubBuilder` / `HubSpec` / `WorkshopBuilder` still present but disabled.

**Next: job 020 — build the Workshop room.**
