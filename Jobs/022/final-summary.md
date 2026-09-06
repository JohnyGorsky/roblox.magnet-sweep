# Job 022 — final summary

**The Workshop went from a room to a place where you live.** A player who joins is given a bay, their
face and name light up on the wall above it, a robot they own is standing in it, and they can now walk
up to the Robot Bay and change what that robot is made of — permanently.

The intake asked for two systems (claiming, nameplates). It closes having built six, because each one
turned out to be load-bearing for the next: a nameplate needs a claim, a robot needs a loadout, a
loadout needs somewhere to persist, a persisted part needs to exist in the catalog with art, and a
part you own is worth nothing until you can put it on.

## Delivered

| | |
|---|---|
| `BaseClaimService` | server-authoritative bay assignment; state lives as attributes ON the base |
| `BaseNameplate` | 10 plates at r=266.5, y=76 — rounded avatar, display name, dark until claimed |
| `RobotSpawner` | builds the robot from the player's loadout and starts its idle |
| `PlayerProfile` | the project's **first persistence at all** — `UpdateAsync`, session locking, save trio + `BindToClose` |
| `Config/StarterRobot` | the rusty five: never found, `scrapValue = 0`, so everything you find is an upgrade |
| `Config/PartArt` | mesh + scale + mount for 24 catalog parts, tiers 1–3 |
| `RobotService` + `RobotBuild` | **the builder** — pick a slot, pick a part you own, and it stays |

## The four things this job actually taught

### 🔴 1. A single asset looking wrong is not a bug; a second one with the identical fault is a design

I reported the starter robot's "wrong hands", diagnosed an empty `RightArmSocket` as a defect and
fixed it. The owner pushed back — *"we already had pointed robots in demo room, why do you again have
this problem?"* An audit then found **two independent rigs missing the same socket**, and
`docs/systems/robot-assembly:22` deciding the starter is five parts with one arm. Both changes were
reverted and the finding was rewritten as withdrawn.

I was also wrong, confidently, about the animations existing at all — a grep filter of my own
(`grep -iv "^.*--"`) excluded most Luau lines, and `RobotAnim.luau` with three procedural clips had
been there the whole time.

### 🔴 2. A dead code path is not a working one

Two bugs shipped long ago and had never fired, both found only when this job armed them:

- **`RobotAssembler.def` never merged `mountRot`.** Every catalog part with a measured rotation would
  have mounted unrotated. It could not fire while nothing could equip a catalog part.
- **`PlayerProfile` never released its session lock** — `release and nil or {...}` is the lock table
  for every value of `release`. Invisible in Studio, where the stale window is 10 s; in production it
  is 180 s and it refuses a player their own profile on a fast cross-server rejoin.

The second was found by **`luau-analyze`'s `MisleadingAndOr`**, not by any test — nothing throws and
the save reports success. The same expression shape was in my own new code on the same day.

### 🔴 3. Measure the placement; never derive it

Four separate attempts to compute mount points failed against the owner placing parts by eye:

- the scale convention did not transfer between mesh generations (longest axis 1.00 vs 1.90) — a
  fridge door came out 12.3 studs against a 6.5 torso;
- `mountFrac` cannot orient a part, only position it: the spoon sat at **+74°** pointing at the
  ceiling;
- my analytic left/right mirror rule was simply wrong — the owner's two arms measured **103°** and
  **65°**, not mirror images;
- and a verification that omitted `Waist` reported a part off by 0.1499, which is exactly the waist
  offset. The config had been right.

### 🔴 4. Position first, weld second

A `WeldConstraint` records its offset when it is created. Repositioning a welded rig makes the weld
fight the placement and the assembly tears itself apart the moment it is unanchored.

## Verified in Play

- **Persistence round trip**, twice: `Arm=PIPE_WRENCH` and later `Arm=GIANT_SPOON` both survived a
  full Studio restart with the original `createdAt` — the same profile, not a fresh default.
- **Lock release with a before and an after**, read off the DataStore key rather than a module:
  `table` (id matching the boot log) while held → **`nil`** after `BindToClose`.
- **All seven install refusals fire** with readable reasons, including the proximity gate at
  `67 studs from the RobotBay (max 25)`.
- **The gameplay path**: walked to the bay, pressed E, the screen opened off the prompt's own
  attribute, installed the spoon, and it mounted at **z = 103°** — its measured `mountRot` to the
  degree.
- **Robot-in-crane fixed** across all 10 bays: `ROBOT_MOUNT.RADIUS = 191.2` absolute, after a
  relative offset compounded on bay 6 (already at r=185.0) and a world-axis-aligned box check falsely
  reported 8/10 blocked.

## Also fixed, because it was in the way

🔴 **Every button in the game was outlining its own letters.** `UIStroke.ApplyStrokeMode` defaults to
`Contextual`, which on a text object strokes **the glyphs**. `Components.panel` set `Border`
explicitly; `Components.button`, four lines away, did not. Invisible on a 28 px display word, and at
the 14 px a list row uses the halo is thicker than the letter strokes — the owner's report was "these
texts cant read". Proved by switching five rows in a live panel and leaving the rest: five went crisp,
their neighbours stayed fuzzy, in one screenshot.

Also **the admin panel** (F4), which had listed 10 of 24 commands because it snapshotted at boot
before the systems registered theirs. It fetches on open and now shows 28.

## Still open

- 🔴 **Two clients have never been tested.** The session lock has met an *orphaned* lock, never two
  concurrent sessions; two players racing for one bay is unexercised; and the 180-second cross-server
  case the lock fix is really about needs a Team Test. This is the biggest gap in the job.
- 🔴 **Ownership has no gameplay source.** `part.grant` is a dev command; the real transfer is the
  Service Hub `SECURED` moment (decision 0008).
- **Finding 0014: 72 of 96 catalog parts cannot be installed** — tiers 4–12, ~2,160 Meshy credits.
  The builder greys them with the reason rather than failing.
- ⚠️ **Studio is reading and writing LIVE keys** (`PlayerProfile_v1`), logged loudly every start. The
  `roblox-data` skill says to test on a separate place.
- `MaxPlayers` reads **60** against **10** bays (finding 0006) — a Creator Hub setting, human action.
- `FRYING_PAN`'s `mountFrac` is still `[UNTUNED]`; it inherits the spoon's, because the rig has only
  two arm sockets and the spoon and tenderizer took them.
- Performance still never measured on a device — Studio throttles an unfocused viewport to a hard
  15 fps, and `QualityController` was itself fooled into selecting Low by that reading.
