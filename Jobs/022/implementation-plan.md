# Job 022 — implementation plan

**Project**: `roblox.magnet-sweep` · **Scope and order set by the owner 2026-09-06.**

## The four steps, in the owner's order

1. **Player joins → assigned a free workstation.**
2. **Workstation assigned → the wall shows that player's picture + name, rounded.**
3. **Robot spawns at the mount position (if owned).** *Assume ownership for now* — no inventory yet.
4. **Robot in place → play the Idle animation**, and build from there.

## What already exists — measured, not assumed

This job is much smaller than it looks, because job 020 laid the schema and never filled it.

| Already there | Where |
|---|---|
| `Claimed = false` and `BaseIndex` attributes on **all 10 bases** | `Hub.Bases.<n>` |
| A `RobotMount` marker Part per base, with `Purpose = "where this base's robot stands - move me, the robot follows"` | `Hub.Bases.<n>.Fixtures.SMELTER.RobotMount` |
| `Dormant = true` + `StationId = Smelter` per base | same |
| A complete rig template: **9 Motor6D, 7 sockets, `PrimaryPart = RobotRoot`**, with `Rig`/`Mounted`/`Hitboxes` folders | `ReplicatedStorage.RobotRig` |
| Three working procedural clips — **Idle, Move, SweepLight** — plus `play`/`stop`/`isPlaying` | `ReplicatedStorage.Robot.RobotAnim` |
| A declared `RobotAnimation` remote | `Remotes.luau:157` |

⚠️ **Bases are numbered 3…12, not 1…10.** Two facets became shop frontage in job 020. Anything that
assumes 1-based indexing will miss two bases and mis-key the other eight.

🔴 **`ReplicatedStorage.RobotRig` is NOT on disk.** Rojo syncs scripts, not models, so the rig
template lives only in the unversioned `.rbxl`. Losing that file loses the rig. Out of scope here,
but it needs an `.rbxm` export or a decision — worth a finding.

## Step 1 — `BaseClaimService`

Server-authoritative, per non-negotiable #2 and decision 0007. A client may never assert which bay
is its own.

- `PlayerAdded` → claim the **lowest free `BaseIndex`**; `PlayerRemoving` → release.
- Also sweep `Players:GetPlayers()` at start, so a player already in the server when the script
  loads is not skipped.
- State goes on the base model as attributes — `Claimed`, `OwnerUserId`, `OwnerName`,
  `OwnerDisplayName`. Attributes replicate on their own, so the client needs **no remote** to render
  a nameplate. This follows `StationService`'s rule: **found by attribute, never by position**,
  because the whole room is expected to be nudged.
- **Idempotent** — claiming twice returns the same base.
- **No yields between find-and-claim.** The thumbnail fetch yields, so it happens *after* the claim
  is written, or two joins in the same frame could take the same bay.
- More players than bays → log a warning and leave them unassigned. Must not error.
  ⚠️ Finding 0006: `MaxPlayers` reads **60** against 10 bays and still needs a human to set it to 10.

## Step 2 — the nameplate

- `Players:GetUserThumbnailAsync(userId, HeadShot, Size150x150)`, **`pcall`'d** — it yields and can
  throttle or fail. A failure shows the plate with no picture, never no plate.
- Rounded via `UICorner` at `Scale 0.5` on a square `ImageLabel`.
- Built to the style skill §5 signage language: dark slate housing, chrome bezel, `Neon` text panel,
  hazard plinth.
- 🔴 **`Neon` + Bloom, not `PointLight`.** Job 021 measured `QualityController.local.luau:123-131`
  clamping every non-`Hero` light to **10 studs** on Low, so a plate that reads by light spill is
  invisible on a phone.
- Generated at runtime from the base list, not hand-placed — it is data-driven, and `Workspace` does
  not sync.

## Step 3 — robot spawn

- Clone `ReplicatedStorage.RobotRig` to the base's `RobotMount` marker, using **`PivotTo` plus a
  measured correction** — `PrimaryPart` is `RobotRoot`, which silently overrides `WorldPivot`.
- Read the marker, never recompute from the crane's bounding box: the marker's own `Purpose`
  attribute says it exists to be dragged.
- Ownership is assumed for now. The real gate is a saved robot, which does not exist yet.

## Step 4 — Idle

🔴 **The rest pose must be fixed first, or this step looks broken and the clip is not at fault.**
Measured on the demo rigs: the arms sit **+11.4° from horizontal** — a rigging T-pose — and the whole
Idle loop moves the shoulders by **5.5°**. Clips are applied as *offsets from rest*
(`RobotAnim` header), so no clip can bring the arms down. Re-authoring the shoulder `C0`s fixes
every clip at once and costs no asset.

- `RobotAnim` drives `C0`, not `Transform`, specifically so a server-side write replicates. **Play on
  the server.**
- Nothing currently requires `RobotAnim` — zero callers in `studio_game/`. That is why every rig is
  static.

## Verify

- **Two clients in Team Test, not one.** One player cannot show two players racing for a bay, and
  cannot show that player A sees player B's plate.
- Read claim state from the **base attributes**, not from module internals — `execute_luau` builds a
  second copy of a module with its own state, which produced two confidently wrong readings in job 008.
- Low-tier pass with `decorativeLightRange = 10`.

---

# BUILD LOG — 2026-09-06, all four steps working

Verified in Play, three sessions, each one stopped. `fatal 0` throughout.

| Step | Evidence from the running game |
|---|---|
| 1 — join assigns a bay | `[S][BaseClaim] ready -- 10 bays, indices 3,4,5,6,7,8,9,10,11,12` then `johnygorsky10 claimed base 3`. Read back off the instances: bay 3 `Claimed=true OwnerName=johnygorsky10`, bays 4-12 `Claimed=false Owner=nil` |
| 2 — lit nameplate | `built 10 nameplate(s) at r=230 y=33`. Plate 3 shows `JOHNYGORSKY10` / `@johnygorsky10`, avatar image `SET`, glow cyan; the other nine read `FREE BAY` / `BAY n` with a dim glow |
| 3 — robot at the mount | `bay 3: robot placed from DemoRoom.10_Robots.2_Starter (documented starter loadout) \| anchored root=1, free=14` |
| 4 — idle | `bay 3: Idle playing`. Sampled twice 0.5 s apart: `LeftShoulder` C0 Z-rot delta **2.805°**, a mesh moved **0.056 studs** → animating, not just started |

## Files

- `ServerScriptService/BaseClaimService.luau` — assign/release, state on the base as attributes
- `ServerScriptService/BaseNameplate.luau` — 10 generated signs, rounded avatar, Neon glow
- `ServerScriptService/RobotSpawner.luau` — stance + placement + idle
- `Bootstrap.server.luau` — wires all three, plus a `base.who` dev command

## Three bugs the verification caught, all mine

1. 🔴 **Anchoring the whole rig made the animation silently do nothing.** A `Motor6D` cannot move an
   anchored part. The stance wrote 6 joints and reported `arms L 11.4 R 11.4` — *identical to the
   un-stanced T-pose*. Now only the root is anchored (root=1, free=14) and the joint chain holds the
   rest. This is exactly the class of bug a check that can fail is for: the log said 6 joints
   written, and nothing had moved.
2. 🔴 **`SurfaceGui.Face = Back` put the sign on the side facing the wall.**
   `CFrame.lookAt(pos, pos - n)` gives `LookVector = -n`, which is the part's **`Front`** face, and
   `dot(LookVector, inward) = 1.000` confirms it. The symptom is indistinguishable from a broken
   SurfaceGui: housing lit, face blank.
3. ⚠️ **The first arm-angle check measured the wrong instance.** `LeftArmPivot` sits ~1 stud from the
   shoulder, so a 62° joint rotation barely moves it — it read +7.0° and looked like the stance had
   failed. Measuring the **arm mesh** relative to its shoulder gives **−54.8°** (hanging down), and
   the rig's bounding box narrowed from **25.0 → 13.2 studs** wide. A pivot is not the feature.

## The stance, and why it lives in code

Measured on the demo rigs: rest pose put the arms **+11.4° above horizontal** (a rigging T-pose) and
the whole `Idle` loop moves the shoulders **5.5°**. Clips are offsets from rest, so no clip could
ever bring the arms down — which is what the owner saw and called *"hands placed incorrectly"*.

`RobotSpawner.STANCE` applies ±62° at the shoulders and ±16° at the elbows **before** `RobotAnim.play`,
so `RobotAnim` captures the stanced pose as its rest and offsets from that. Signs are mirrored L/R
because `RobotAnim.resolve` records that the same Y rotation swings one arm forward and the other
backward, and `Idle` follows the same convention. Marked **[UNTUNED]** — readable, not final feel.

It is in code rather than baked into `ReplicatedStorage.RobotRig`'s `C0`s because **Rojo syncs
scripts, not models**, so the rig template lives only in the unversioned `.rbxl`. A load-bearing pose
belongs somewhere git can see it.

## Build log 5 — the admin panel, and one bug in the whole design system

`AdminPanel.local.luau` (F4, after F2 `DevConsole` and F3 `AudioBench`). 28 dev commands as tappable
rows, arguments in one text box, the result on a coloured strip.

**Authorisation was already right and was not touched.** `DevTools.isAuthorised` gates every call
server-side by `UserId` (`{ [5025640608] = true }`) and `DevTools.run` re-checks on *every* command.
The panel asks the server whether it is allowed and stays hidden if not — a convenience, not a
security boundary, and the file's header says exactly that so nobody later mistakes it for one.

### 🔴 Every button in this game was outlining its own letters

The owner's report was "these texts cant read", and the cause was not text size.

`UIStroke.ApplyStrokeMode` defaults to `Contextual`, and on a **text object** that applies the stroke
to **the glyphs**, not to the border. `Components.button` set a 2 px accent stroke and never set the
mode; `Components.panel`, four lines away in the same file, sets `Border` explicitly. So the button
had been drawing a 2 px halo around every letter since it was written — invisible on a 28 px display
word like **UPGRADE**, and at the 14 px a list row uses, thicker than the strokes of the letters
themselves.

**Measured, not reasoned:** in the live panel, five rows were switched to `Border` and the rest left
alone. In a single screenshot the five went crisp and their neighbours stayed fuzzy. One line fixed
in `Ui/Components.luau`, which fixes it for every button in the game.

The other four `UIStroke` sites were checked and left alone: `Ui/Banner` and `WorkshopBuilder` stroke
*large* display text, where an outline is the intended legibility effect; `BaseNameplate` and
`AudioBench` parent theirs to Frames, where `Contextual` already means border.

### Follow-up: the buttons read like code, because they were code

The owner's next report: *"more strange panel without normal titles but title placeholders."* They
were not placeholders — `scrap.spawn`, `perf.sample` and the rest are the real internal command ids,
and putting an identifier on a button makes it look unfinished however correct it is.

Fixed by **deriving** the two halves from the dotted name rather than authoring a label table: the
namespace becomes a gold section header (**SCRAP**), the action becomes the button (**SPAWN**), and
the full id stays small and dim underneath. Derived rather than authored on purpose — a hand-written
label map on the client would be a copy of a list the server owns, and a command added later would
silently fall back to the raw name, i.e. back to the bug. Measured live: **31 commands under 19
headers**, and `help` still runs from its button.

⚠️ The id is kept, not dropped: it is what you type as `dev("scrap.spawn")` and what the output strip
echoes back. A prettier button that broke that link would be worse than the ugly one.

### The second half of "cant read"

The panel is 28 rows of body text and it was inheriting `Theme.shape.panelTransparency = 0.2`, so the
player's own head and the Recycler machine were rendering *through* the help column. That value is
right for a HUD widget and was not changed; this one panel overrides it to 0.02. Also: names
left-aligned into a scannable column at 16 px (they were centred in a 42 %-wide button, so `base.who`
floated in the middle of nothing), help text at 14 px in full-brightness `text` rather than 13 px
`textDim`, alternating row bands, and the output moved onto its own dark plate.

### Verified through the whole path

Clicked `help` **by instance path**, then read the widget back rather than trusting the picture:
`Output.Text` began `help -> * audio.bench …` (the genuine server response) and `Output.TextColor3`
was `(0.247, 0.839, 0.294)` = `Theme.color.recycle`, which is set from the returned **flag**, not
from the message being non-empty. Button measured 286 × 44 at 16 px, `align Left`, `stroke Border`.

⚠️ **Two earlier "verifications" of this button were false.** Both clicked a pixel read off a
`screen_capture`, and the capture is scaled ~1.12× relative to the click coordinate space — so the
click landed one row low, ran `config.dump`, returned a plausible green result, and reported
`Success`. Nothing errored. Target GUI controls by `instance_path`; a dot in an instance name breaks
the path, so pick a sibling without one.

## Build log 6 — you can change your robot in play, and it sticks

The deliverable, in the owner's framing: *a dev command grants you a part, you walk to the Robot Bay,
pick a slot and a part, it appears on the robot immediately, and it is still there after a rejoin.*

### What was added

| | |
|---|---|
| `RobotService.luau` | new. Owns every install decision — 7 server-side checks, the state the UI renders, and the grant path |
| `RobotBuild.local.luau` | new. The Robot Bay screen: slots down the left, owned parts for that slot on the right |
| `PlayerProfile` | `robot.owned` (a `partId -> true` set) + `owned` / `owns` / `grant` |
| `StarterRobot.ownedSet()` | the five rusty stubs as an ownership set, derived from `PARTS` not `LOADOUT` |
| `StationService.BEHAVIOUR.RobotBay` | `screen = "RobotBuild"`; the `notYet` is gone |
| `Bootstrap` | binds `RequestInstallPart`; registers `part.grant`, `part.owned`, `robot.rebuild`; audits the slot list |

**`RequestInstallPart` already existed in `Remotes.SPECS`** and was one of the endpoints Bootstrap
reported as unbound every boot. No new remote was added; an unlisted endpoint became a handled one.

### 🔴 The profile had a loadout and no inventory

The loadout says what is BOLTED ON. Nothing said what a player *may* bolt on — so "the server
verifies ownership", which is what `Remotes.SPECS` already promised for this remote, had nothing to
verify against. `robot.owned` is that record, and it is **backfilled, not migrated**: `VERSION` may
only move with a `MIGRATIONS` entry, and this is an additive field with a safe default, exactly like
the `loadout` backfill beside it.

It also **self-heals**: anything in the loadout is marked owned on load. Otherwise `profile.slot Arm
PIPE_WRENCH` — the dev command the persistence round trip was tested with — leaves a robot wearing a
part its owner does not own, and the builder then refuses to put it back after a swap. The player
would lose a part by looking at it. Measured on the owner's own live profile: it loaded with **11
owned** = 5 starter + the 6 tier-2 parts a previous session had written straight into the loadout.

### 🔴 Two real bugs found on the way, neither by a test

**1. `RobotAssembler.def` never merged `mountRot`.** `mount` reads `def.mountRot`; the catalog merge
copied `mesh`, `scale` and `mountFrac` and stopped. Every catalog part with a measured rotation would
have arrived unrotated — `BLENDER_MOTOR` (92° about X) lying on its side, `GIANT_SPOON` and
`FRYING_PAN` (103°) and `GOLDEN_TENDERIZER` (65°) pointing the wrong way. That is the exact +74°
ceiling-pointing failure the note in `mount` documents.

⚠️ **It had never fired because nothing could equip a catalog part.** The starter five come from
`StarterRobot.def`, return before that branch, and carry no `mountRot`. A dead code path is not a
working one — and this deliverable was the thing that would have armed it.

**2. `PlayerProfile` never released its session lock.** Pre-existing at HEAD:

```lua
snapshot.lock = release and nil or { id = SESSION_ID, at = os.time() }
```

`true and nil` is nil, and `nil or {...}` is the table — so **releasing wrote a fresh lock**, on every
leave and every `BindToClose`. Found by `luau-analyze`'s `MisleadingAndOr`, which no test would have
produced: nothing throws and the save reports success.

Why it stayed invisible: `LOCK_STALE_SECONDS` is **10 in Studio**, so a leftover lock went stale
before anyone noticed, and a rejoin on the same server passes `lockIsMine`. In production the window
is **180 s**, and the case it breaks is a player leaving and rejoining onto a *different* server
inside three minutes — who would have been refused their own profile and handed a session-only one.
The single bug class the module exists to prevent.

The same `x and nil or y` shape was in my own new `RobotService.state` (`whyNot`), where it reported
a player standing at the bay with the reason "at the station" attached. Both rewritten as
`if-then-else`.

### Verified in Play, not Edit

**All seven refusals fire**, each with a reason a person can read:

| attempt | reply |
|---|---|
| Arm/GIANT_SPOON from 67 studs away | `67 studs from the RobotBay (max 25)` |
| Head/GIANT_SPOON | `GIANT_SPOON is a Arm part, not Head` |
| Head/TRAFFIC_LIGHT | `TRAFFIC_LIGHT has no mesh yet, so it cannot be built (finding 0014)` |
| Arm/GOLDEN_TENDERIZER (not owned) | `you do not own GOLDEN_TENDERIZER` |
| Elbow/GIANT_SPOON | `"Elbow" is not a robot slot` |
| Arm/FOO | `no such part as "FOO"` |
| slot = 42 | `bad request` |

**The gameplay path**, end to end: walked to the bay (8.0 studs, `atStation=true`), pressed **E**, the
screen opened off the prompt's own `Screen` attribute, clicked ARM then Giant Spoon. Status went green
`Giant Spoon installed in Arm` — coloured from the returned **flag**, not from the message being
non-empty.

**The spoon mounted at z = 103° relative to `LeftArmPivot`**, which is its measured `mountRot` to the
degree. That is bug 1 above, proven fixed rather than assumed: without the merge it reads 0°.

**It sticks.** Full Studio restart, then read back through the dev remote:
`profile: v1 | sessionOnly=false | createdAt=1788702877 | Arm=GIANT_SPOON …`, and the bay rebuilt
6 parts from that saved profile with the spoon still at z=103°. Same `createdAt`, so it is the same
profile and not a fresh default.

**The lock release, with a before AND an after** — read off the DataStore key itself rather than a
module (`GetAsync("u_…")`, so it is the stored value, not a second copy):

| | `lock` |
|---|---|
| while the server held it | `table`, id `8d0d1ba9…` — matching the boot log's `session=8d0d1ba9` |
| after shutdown (`BindToClose` released) | **`nil`**, and `lastSeen` advanced |

Before the fix the second row would have read the session id back. A check that cannot fail is not a
check.

### Not done, and why

- **Ownership still arrives only from `part.grant`.** The real transfer is the Service Hub `SECURED`
  moment (decision 0008), a later group. Keeping the grant in one dev command stops the builder from
  quietly becoming a second grant path.
- **72 of 96 catalog parts still cannot be installed** (finding 0014). The builder greys them with
  the reason on the row rather than offering an install that is guaranteed to fail — measured live
  with `TRAFFIC_LIGHT`.
- **Still one client.** Two players racing for a bay, and the 180-second cross-server lock case the
  fix above is really about, both need a Team Test.

## Still open

- [ ] **Two-client Team Test.** Everything above is ONE player. A single client cannot show two
      players racing for a bay, cannot show release-on-leave, and cannot show that player A sees
      player B's plate. This is the main gap.
- [ ] `MaxPlayers` still reads 60 against 10 bays (finding 0006) — a Creator Hub setting.
- [ ] Robot ownership is assumed. No inventory, no persistence: every claimed bay gets the starter.
- [ ] 🔴 **`ReplicatedStorage.RobotRig` and the DemoRoom robots exist only in the `.rbxl`.** The
      spawner logs which source it used every time for exactly this reason. Needs an `.rbxm` export
      or a decision — worth a finding.
- [ ] Low-tier pass on the nameplates specifically (they are Neon + Bloom by design, but unmeasured).

---

# NAMEPLATE MOVED UP — 2026-09-06

Owner: *"Name higher up where is empty wall."* The first placement (r=230, y=33) put the plate
directly in front of a ribbed duct run.

**The new height is measured, not chosen.** An outward raycast sweep every 5 studs on all ten facets:

| band | what is there |
|---|---|
| y 20…50 | job 021's detail band — pipes, duct runs, fan housings, louvres, at r 239…250 |
| **y 55…100** | **nothing until the `L2` backdrop face at r=268 — CLEAR on all ten facets** |
| y 105…128 | the clerestory glazing at r=267 |
| y 130+ | overhead trusses |

So: **r=266.5, y=76** (1.5 studs off `L2`'s face, so nothing is coplanar), centred in the clear band
with 21 studs of margin below and 29 above.

**Re-sized for the new distance rather than left alone.** From a player at their own bay (r=200,
eye 5) the plate is now **95 studs** away, measured, against 41 before — so **30x13 → 66x28**, about
2.2x, to read the same. `PixelsPerStud` dropped **48 → 20**: at 66 studs wide, 48 would be a 3168px
surface per sign, ten of them, for something read at 95 studs.

Verified: nothing within 20 studs behind the plate, nothing within 60 in front. From the plaza, a
claimed bay (lit, cyan glow, avatar) and a free bay (`FREE BAY` / `BAY 4`, dim, no avatar) are
distinguishable at a glance across the room — which is the actual requirement: *"so you know what
user have what place, so it like lights up"*.

---

# OWNERSHIP + PERSISTENCE — 2026-09-06

Owner chose the **larger option on both** questions: a distinct rusty starter set, and DataStore
persistence now rather than waiting for its planned slot.

⚠️ **Recorded because it was raised and overruled, not to relitigate it:** persistence is
`docs/build/job-order.md`'s **job 026**, sequenced *behind* Economy (025) because the economy decides
what there is to save. The schema here is therefore **versioned with a migration table from day one**,
so 025 can add fields without a rewrite.

## What was built

| File | Does |
|---|---|
| `Config/StarterRobot.luau` | the five rusty parts + the loadout, deliberately **outside** the 96-part catalog |
| `ServerScriptService/RobotAssembler.luau` | builds a robot from a loadout, one part per socket |
| `ServerScriptService/PlayerProfile.luau` | load / auto-save / leave / `BindToClose`, session-locked |
| `RobotSpawner.luau` | now builds from the player's saved loadout instead of cloning a model |

## The rusty starter set — closing the doc's open item

`docs/systems/robot-assembly` decided the *shape* (Head, Core, Body, one Arm, one Mobility) on
2026-09-05 and left open *"which specific parts, and whether they are real catalog entries or a
distinct rusty starter set"*. **The owner chose the rusty set.** So:

- `scrapValue = 0` — a new player cannot strip their own starter for scrap in minute one.
- no `zone` — no spawn pool can ever roll them, so they are never found.
- same five meshes as their catalog cousins, stripped of finish. **Every part you find is a strict
  upgrade**, which is the entire reason for choosing this option.

They live in `Config/StarterRobot`, **not** `PartsCatalog`: the catalog is generated from
`docs/content/parts-catalog.md` and is the 96 *findable* parts, so a never-findable entry would
contradict both. Validated at startup against `Parts.validate` (stricter than the catalog's own
check): `starter robot: 5 rusty part(s) valid, loadout 5 slot(s), scrapValue 0 (not farmable)`.

## Assembly is data now, not a cloned model

Each part carries a **measured** `scale` and `mountFrac` — where its `RobotMount` sits on the part as
a fraction of its half-extent — read off `DemoRoom.10_Robots.2_Starter`, the assembly the owner
approved. A drum mounts at `(0,0,0)`, a head at `(0,-1,0)`, the wrench at `(-0.58,-0.14,0)`.
Deriving those from a bounding box would hang every part by its middle.

Verified in Play — all five parts land **0.0000 studs** from their correct socket:

| part | slot | socket | offset |
|---|---|---|--:|
| `RUSTY_DRUM` | Body | `BodySocket` | 0.0000 |
| `RUSTY_MOTOR` | Core | `CoreSocket` | 0.0000 |
| `RUSTY_LAMP` | Head | `HeadSocket` | 0.0000 |
| `RUSTY_CASTERS` | Mobility | `MobilitySocket` | 0.0000 |
| `RUSTY_WRENCH` | Arm | `LeftArmSocket` | 0.0000 |

## Two bugs found in Play, both invisible from reading the code

1. 🔴 **`CollisionFidelity` is a plugin-capability property.** Setting it from a server script throws
   *"The current thread cannot write 'CollisionFidelity' (lacking capability Plugin)"* — and it took
   the whole `onClaim` hook down, so the player got a bay and a nameplate and **no robot**, with one
   log line as the only clue. Removed; the robot is `CanCollide = false` so no collision geometry is
   ever consulted. ⚠️ `execute_luau` writes this property happily, which is exactly why the workspace
   rule says the command bar is **privileged** and gated writes must be tested in a real Play script.

2. 🔴 **`Color` does not tint a `MeshPart.TextureID`.** It multiplies a
   `SurfaceAppearance.ColorMap` — the case the style skill documents — but these Meshy meshes carry a
   baked `TextureID` and no `SurfaceAppearance`, so the painted texture won outright.
   **Measured:** tinting to `#8A4B2A` and then to a much darker `#5A4030` produced screenshots
   *indistinguishable* from the untinted one. Clearing `TextureID` handed control back to `Color` +
   `MS_Rust` and the robot immediately read as corroded metal. Losing the paint is the point.

## Persistence — the three rules from the `roblox-data` skill

- **`UpdateAsync` everywhere, never `SetAsync`**, and no transform yields.
- **Session locking** via a per-server GUID in the profile, heartbeated by the auto-save loop, stolen
  only when stale (180 s).
- **The save trio + `BindToClose`**, saving in parallel inside a 25 s budget.
- 🔴 **Never overwrite a failed load.** A player whose load failed gets a session-only profile flagged
  `loadFailed`, and every save path refuses it. Losing one session is recoverable; overwriting a real
  profile with defaults is not.

## 🔴 Persistence is UNTESTED, and this is the blocker

Play reported:

```
DataStoreService: StudioAccessToApisNotAllowed
[ERROR][S][Profile] DataStore unreachable (Studio Access to API Services off?) -- SESSION-ONLY mode
[S][Profile] johnygorsky10: no DataStore available -- SESSION-ONLY profile, nothing will be saved
```

The fallback behaved exactly as designed — session-only, loud, no crashes, robot still built. But
**not one line of the DataStore path has executed.** To test it:

- [ ] **Human step:** Game Settings → Security → enable **Studio Access to API Services**.
- [ ] ⚠️ The `roblox-data` skill says to test persistence on a **separate place**, because Studio
      reads and writes the **live** keys. `PlayerProfile.start()` logs a loud warning when it detects
      Studio with a working store, for exactly this reason.
- [ ] Then verify: join → change a slot → rejoin and confirm it came back; two clients to prove the
      session lock; and a `BindToClose` save on shutdown.

---

# PERSISTENCE VERIFIED — 2026-09-06, DataStore access enabled

## The round trip passes

| Step | Result |
|---|---|
| First join writes a profile | `version=1`, **live lock present** (`d51ab0a5`), all 5 rusty parts in the store |
| Re-join reads it back | `sessionOnly=false`, **`createdAt=1788702877`** — the *original* timestamp, so it read rather than re-created |
| Change a slot and save | `Arm -> PIPE_WRENCH \| saved=true` |
| **Full restart** | `Arm=PIPE_WRENCH`, `createdAt` unchanged — **the change survived** |

## The two safety rules fired for real, before they were needed

An interrupted session left its lock behind, and the next session did exactly the right thing:

```
[S][Profile] profile locked or unreadable (attempt 1/4 ... 4/4)
[ERROR]      PROFILE LOAD FAILED -- running session-only, saves are DISABLED for them
[S][Profile] refusing to save -- the load failed, so this profile is a guess
```

Session locking refused to steal a live-looking lock, and **never-overwrite-a-failed-load** then
refused to write defaults over a real profile. Neither was a drill.

## Three bugs found by testing, all real

1. 🔴 **`BindToClose` could not release the profiles it held.** It iterated
   `Players:GetPlayers()`, which in Studio was **already empty** by the time it ran — so the session
   lock was orphaned on every stop, and the next session locked itself out. Now it iterates the
   in-memory `profiles` table, which is the authoritative record of what this server holds, and
   `save` is keyed on **userId** rather than a live `Player` object so it can.

2. 🔴 **The robot was built before the profile finished loading.** The claim fires on join; the
   DataStore load takes a round trip. Measured: after a restart the profile correctly said
   `Arm = PIPE_WRENCH` while the robot in the bay still held `RUSTY_WRENCH` — **every single join**.
   Added `PlayerProfile.waitReady`, and the spawn hook now runs **off-thread** so waiting for the
   network does not delay the claim or the nameplate.

3. ⚠️ **Studio stop/start inside the stale window locked the tester out.** `LOCK_STALE_SECONDS` is
   now **10 in Studio, 180 in production**. The argument is specific rather than convenience: a
   Studio playtest is a single server, so a lock found there cannot belong to a live peer — it is
   necessarily a local leftover. In production a foreign lock may well be a real server mid-save.

## 🔴 What the upgrade test uncovered — [finding 0014](../../findings/0014-the-96-catalog-parts-have-no-mesh-bindin.md)

Setting the Arm to a **real** catalog part produced:

```
bay 3: 1 part(s) did not mount -- Arm/PIPE_WRENCH: PIPE_WRENCH has no mesh field
```

**The 96 catalog parts carry no `mesh`, `scale` or `mountFrac`.** Only the rusty five have that art
binding, measured off the approved demo assembly. So the starter robot works and **no found part can
be equipped yet** — which blocks the core loop's payoff, not a cosmetic detail.

That is a job of its own (where the binding lives, plus measuring each part), so it is a finding
rather than scope creep here. The assembler fails loudly and leaves the socket empty, per
non-negotiable #10.

The test profile was restored to `RUSTY_WRENCH` so the saved state does not hold an unmountable part.

## Still open

- [ ] **Two clients.** Everything is still one player. The session lock has only been exercised by an
      *orphaned* lock, never by two genuinely concurrent sessions.
- [ ] ⚠️ **Studio is reading and writing LIVE keys** (`PlayerProfile_v1`) — logged loudly every start.
      The `roblox-data` skill says to test on a separate place. Low risk today because there is no
      real player data, but it will not stay that way.
- [ ] `MaxPlayers` still reads 60 against 10 bays (finding 0006).
- [ ] Finding 0014 blocks upgrades.
