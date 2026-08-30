# PITFALLS — mistakes already paid for

**Read this before building.** It is not a "be careful" page.

Every entry names a real incident from another game in this workspace, the rule that came out of it, and
— most importantly — **the check that catches it**. A rule without its incident gets rationalised away; a
rule without a check is decoration.

Sources: The Last Tide's 31 findings and its sea failure, Roblox Jungle's job records, Roblox Defender's
mobile rework, ELEVATOR 13's own pitfalls page, and `roblox.workspace/GROUND-RULES.md` §7 and §8 — which
exist *because* of the Tide sea failure.

**Entries 1-35, 42 and 45-47 each cite a real, traceable incident.** Entries 36-41, 43 and 44 are
**anticipatory** — they name a failure mode this game's design makes likely, not one already paid for.
They are labelled where they appear.

Part 6 was written *by* this repo's first independent review, which found seven wrong engine claims in
the design pack it was reviewing. Those are the freshest entries here and the ones most likely to bite
again.

MAGNET SWEEP starts with zero code. That is exactly when these are cheap to install, and exactly when
they get skipped.

---

## Part 1 — Verification

### 1. Verified in Edit, where the bug could not appear

> **The incident.** A cloud-bank VFX drew ~129 sprites 340 studs from the camera, permanently, reading as
> rectangular blocks on the horizon. It is a **client** effect, so every Edit screenshot showed a clean
> sea. **Six consecutive rounds of "it's fixed now"** were reported from screenshots structurally
> incapable of showing the bug. The user's sentence — *"editor is fine, in game it sucks"* — was the
> entire diagnosis.

**Rule:** the editor is for authoring. **It is never evidence.** Reproduce in Play, at the reporter's
camera angle, before forming any hypothesis.

**Check:** before reporting anything fixed — *was this observed in Play, at the player's camera?* If Edit
was the more convenient place to measure, treat that as a reason to **distrust** the result.

**Aimed at MAGNET SWEEP:** the magnet field, every pull trail, every arc, the whole post-processing
chain and the entire HUD are client-side. Arena robots are spawned at runtime. Scrap is pooled at
runtime. **Almost nothing in this game exists in an Edit session.**

### 2. A verification that could not fail

> **The incident.** `tools/luau-analyze.sh` does `cd "$(dirname "$0")/.."`. A baseline built by writing
> `git show HEAD:<file>` into a temp directory and passing a **relative** path therefore analysed the
> repo's own working copy — the file was compared *against itself*. "No new diagnostics" was reported
> twice, from a check structurally incapable of failing.

**Rule:** state what a failure would have looked like. If you cannot, the check is decoration.

**Check:** every verification row in this repo's docs and plans names its failure condition.

### 3. A world fact asserted from a constant

> **The incident.** `OCEAN_EXTENT_Z.min` said `-1000`. The water was actually filled to `-3070`. A
> visible world edge was reported to the user **that does not exist.**

**Rule:** never assert a world fact from a constant. Measure it.

**Here:** "we are under `MaxConcurrentPull`" is a **count of unanchored parts taken during a Magnet
Rush**, never a reading of the config value.

### 4. No "before" kept for a visual change

> **The incident.** Water was brightened from 3.2 % to 8.5 % luminance for a "sunny day". That collapsed
> the sea/sky value contrast — which is what the eye reads as texture and distance — so the sea appeared
> to stop a few hundred studs out. **The user found it, not Claude**, because no before/after comparison
> was ever made.

**Rule:** every visual change gets a before and after from the **same camera**. Keep the before.

**Here:** this game's whole look is a materials-and-lighting stack. One roughness value or one
`EnvironmentSpecularScale` tweak changes every metal surface in the game at once.

### 5. Two failed fixes, and the frame was never re-opened

> **The incident.** Six consecutive rounds inside a wrong frame — water colour, atmosphere, fog,
> streaming, a mesh ocean — while the cause was a client script nobody had looked at.

**Rule:** two failed fixes for the same symptom → stop and re-open the diagnosis from zero, including
*"am I even in the right subsystem?"*

**Check:** after the second failure, a fresh-eyes agent is **mandatory** before a third attempt, and it
is **not told the theory** (GROUND-RULES §8).

### 6. Substituting your framing for the user's words

> **The incident.** "The problem is the sea horizon", said three times, unchanged, while the
> investigation kept re-framing it.

**Rule:** a complaint repeated **unchanged** means the model is wrong, not that the user missed the fix.
The user's words are the specification.

### 7. Finding real bugs is not finding the reported bug

> **The incident.** An investigation turned up no sun disc in any sea state, `SunRaysEffect` at intensity
> 0, a bloom threshold above anything on screen, and no `ColorCorrectionEffect` at all. All real, all
> worth fixing, **and none of them was what the user reported.**

**Check:** ask explicitly — *does fixing this account for the symptom I was given?*

### 8. One reviewer, never told the theory

**Rule:** every job uses at least one independent agent, given the *symptom or requirement* and the repo
— never the hypothesis. A reviewer handed the conclusion just confirms it.

### 9. Coverage by link is not coverage

> **The incident.** ELEVATOR 13's spec-coverage table marked three sections "covered" because a link
> resolved — the linked page did not actually contain the content. Separately, a manifest reported 319
> items by counting `×N` rows as one item each; the honest count was 577.

**Rule:** a coverage table checks that the named items **arrived**, not that a link resolves. Count
`×N` rows as N.

---

## Part 2 — Studio & sync

### 10. Studio Sync is two-way, and deleting an instance deletes the FILE

> **The incident.** Recorded on Jungle. A tidy-up in the Studio Explorer removed source files from disk.

**Rule:** treat a Studio-side delete as `rm`. Scope every cleanup to `Workspace` only.

### 11. Reopening a place silently drops the sync connection

**Check:** confirm sync is live before trusting that an edit landed. A file saved into a dropped
connection looks exactly like a file that synced.

**How to check cheaply:** write a marker file to a path known to sync and read the DataModel back. Job
002's probe worked precisely because it wrote to *every* candidate location at once — so "nothing
arrived" meant *sync is down*, and could not be mistaken for *this path is not synced*.

### 11b. Creating or deleting DIRECTORIES in the sync root drops the connection

> **The incident.** Job 002's probe created folders inside `studio_game/` for services that cannot sync
> (`StarterGui/`, `StarterPack/`, `Workspace/`, `Lighting/`, `SoundService/`, `StarterPlayer/`), and
> then cleaned up with `find -type d -empty -delete`, removing the **mapped service folders** as well.
> **The user's sync dropped twice**, and they had to reconnect it both times.
>
> It also produced a **false finding**: because the watched directories vanished mid-operation, the
> per-file deletions were never reported, and job 002 concluded "deleting a file does not delete the
> instance". Re-tested properly — delete the file, leave the directory — the instance **does** disappear.
> A broken watcher looks exactly like a one-way sync.

**Rule:** the sync root's **top level** is fixed. Only the six mapped service folders may exist there,
they are created once, and they are **never** deleted. Never create a top-level folder for a service
that does not sync.

**Sub-folders inside a synced service are fine** — `ReplicatedStorage/Config/` maps to a `Folder`
instance, verified in job 003. They are ordinary content. What must never happen is deleting them, or
adding a service folder at the top level.

**Check:**

```
find studio_game -mindepth 1 -maxdepth 1 -type d    # exactly the six synced services
find studio_game -type d ! -name .git -exec test -e {}/.gitkeep \; -o -print   # every dir pinned
```

**Every directory carries a `.gitkeep`**, so none can become empty and be swept by a cleanup command.

**And:** never create a folder for a service that does not sync. It cannot map to anything, and it is
what destabilised the connection here.

### 12. Sync layout does not transfer between games

> **The incident.** Tide job 003 assumed Jungle's nested Rojo layout. Tide is **flat**. ELEVATOR 13 then
> inherited the same unverified guess rather than resolving it.

**Rule:** probe the layout over MCP, per place, and write down what was **observed**.

**Here:** ✅ settled. Job 002 probed it and MAGNET SWEEP is **flat**, like Tide and unlike Jungle.
`.jobconfig.json` now says `VERIFIED` and records the method.

### 13. File suffixes are traps — two of them, both confirmed here

Observed in job 002, not inherited:

- **`.module.luau` is not a suffix.** You get a `ModuleScript` whose *name* ends in `.module`. It looks
  like it worked.
- 🔴 **`.client.luau` in `StarterPlayerScripts` RUNS TWICE** — once in place, once as the per-player copy
  in `Players.<name>.PlayerScripts`. Roblox logs a warning about it that is easy to scroll past.
  **Use `.local.luau` there.** A `.local.luau` control in the same test fired exactly once.

**Check:** grep for `.client.luau` under `StarterPlayerScripts/`. There should never be one.

### 14. Studio Sync does not reach a running Play session

And: **always stop a Play session you started.** Leaving one running blocks both sync and the Edit
datamodel, and it is the user's Studio.

### 15. A failed or stale `require` is cached for the whole Edit session

A module that errored once keeps returning the error until the place is reopened. A "fix" that appears
not to work may simply be cached.

### 16. `execute_luau` runs in a separate Luau context

**Rule:** verify through shared Instances — attributes, `leaderstats`, DataStore — never through a
module's internals. Play-mode and Edit-mode DataStores differ.

### 17. `execute_luau` re-runs module scope and rebinds remotes

> **The incident.** `require`ing a live server module from `execute_luau` re-ran its top-level scope and
> rebound `OnServerInvoke`, breaking the running game.

**Rule:** **never `require` a live server module from `execute_luau`.**

### 18. The command bar is privileged

The command bar and `execute_luau` run with plugin capability. A gated property write that succeeds
there may fail in a real script. **Verify gated writes in an actual Play script.**

### 19. `screen_capture` with `camera_position` locks the camera

It leaves the Edit camera `Scriptable`, which locks the user's navigation. Reset `CameraType = Custom`
afterwards.

### 20. `screen_capture` cannot show prompts, and a timeout means nothing is drawing

Captures never render `ProximityPrompt` bubbles — press the key or read `PlayerGui.ProximityPrompts`
instead. And a capture that times out means the client **is not rendering**: `RenderStepped` is not
firing. Never drive an effect's completion from inside a frame loop that a capture will stall.

---

## Part 3 — Assets & models

### 21. Collision fidelity — a pipeline default, and a property scripts cannot set

Two separate traps that look like one.

> **The incident.** Recorded on this workspace: Meshy imports arrive with `CollisionFidelity = Box`, so
> players could not walk under a model's wings or through its gaps.

**Rule 1:** *Box* is not the **engine** default — the enum default is `Default` (voxel convex
decomposition). It is what **Meshy and Creator Store imports arrive set to**. Fix it at import; do not
write docs claiming the engine does it.

**Rule 2 — the sharper one:** `CollisionFidelity` write access is **`PluginSecurity`** and the property
is `NotReplicated`. The docs are explicit: it "cannot be read or manipulated by scripts during runtime."
It belongs in the **import checklist**, never in a mount or spawn function.

**Check:** the Studio command bar *can* write it (see [#18](#18-the-command-bar-is-privileged)) — so it
will appear to work exactly where you are most likely to test it, and fail in a real `Script`.

**Here:** the catalog is spoons, forks, crane hooks, colanders and vault doors, so
`PreciseConvexDecomposition` is right for the ones with a gap a player passes through — but it is
expensive and not a blanket default for 96 parts. Mounted robot parts are `CanCollide = false` and
`Massless = true` anyway, so for most of them fidelity never matters —
see [systems/robot-rig](systems/robot-rig/README.md#4-mounted-parts-are-visual-they-are-not-physics).

### 22. `PivotTo` vs `PrimaryPart`

> **The incident.** `Model:PivotTo()` places by the pivot — but a `PrimaryPart` silently overrides
> `WorldPivot`, so imported meshes landed 100+ studs off.

**Here:** this is *exactly* the part-mounting mechanic. Do not place parts by pivot. Align the
`RobotMount` attachment to the socket explicitly, then weld.

### 23. A server-made NPC's rig is in its rest pose

> **The incident.** On Jungle, a server-spawned NPC's `Animator` reported track weight `0.00` and the
> server-side rig held the rest pose. Animations play and replicate; **the server's copy does not move.**

**Rule:** never solve anything from a limb's position on the server.

**Here, this is a live footgun:** Arena combat is server-authoritative and the robots are animated. **Hit
detection must come from AI state + `RobotRoot` CFrame + a scripted hitbox — never from where the spoon
visually is.**

### 24. Placeholders are worse than empty slots

**Rule:** leave the slot empty and make it announce itself. A wrong sound or a stand-in texture is much
harder to notice than a missing one, and placeholders are how the wrong asset ships.

### 25. An object rendering where nothing exists

Check `LevelOfDetail = StreamingMesh` before assuming a ghost instance. Roblox renders an imposter for a
streamed-out mesh; the DataModel is telling the truth.

### 26. Mockups are direction, not spec

Concept art gives colour and mood. **Never build a feature because it appears in a painting** — and never
report one as existing because the art shows it.

### 27. Asset sourcing has a fixed order

Search our registry and the Creator Store **first**, then write a *searchable spec* (length, loop,
format, and what it must **not** contain), presented as a **table**, one asset per row. The human finds
and supplies the id. Scan every inserted model for scripts before Play.

---

## Part 4 — Architecture & process

### 28. A hardcoded instance path between two systems

> **The incident.** A hardcoded path between two Tide systems broke when one moved.

**Here, this one is upgraded from a smell to a crash.** The factory streams. A cross-zone instance
reference is a `nil` index the moment the target streams out —
[decision 0003](decisions/0003-forward-is-the-only-direction.md).

### 29. Shipping something nothing else knows about

> **The incident.** Tide job 017 shipped storm VFX that nothing ever called.

**Check:** for every new module, name the caller. If there is none, it is not shipped.

### 30. Mobile deferred is mobile reworked

> **The incident.** Defender jobs #094-#099 burned **four rounds of rework** deferring phone questions
> that the Device Emulator would have answered immediately.

**Rule:** measure in the emulator. Ask before switching Studio into it — it takes over the user's session
— and say what is being measured. A pixel `MinSize` floor is not a measurement; it breaks on high-DPI.

### 31. `IMPLEMENTED` is not `VERIFIED`

`IMPLEMENTED` = code exists. `VERIFIED` = a playtest exercised it and the result was recorded.

### 32. The "waiting on you" list grows silently

> **The incident.** Tide's list reached nine rows, each individually reasonable, together a backlog
> nobody was tracking.

**Rule:** keep [HANDOFF.md](HANDOFF.md)'s list short and re-read it every job.

### 33. Place settings nobody chose

> **The incident.** Tide shipped `Fully Open` access with social slots enabled. Both became findings.

**Here:** `StreamingEnabled` is not merely a setting to choose — it is load-bearing for a one-place game
with a twelve-zone corridor. Decide it before anyone can join.

### 34. A live listing that grants nothing

> **The incident.** A game pass left `IsForSale` but unwired is buyable **from the website store page**
> and delivers nothing. Real money, no product.

**Check:** before launch, sweep every listing against what the code actually grants.

### 35. Editing a script outside the system you were asked to work on

Confirm which system and which place owns a file before editing it. Ask if unsure.

---

## Part 5 — Traps specific to this game

> Except #42, these are **anticipatory**: predicted from this design, not yet paid for. They earn their
> place by naming a check, but do not cite them as history.

### 36. The physics budget decays one unanchored object at a time

The four-state model ([0005](decisions/0005-four-state-scrap-budget.md)) only holds if **every** object
returning to the pool is re-anchored. One missed `Anchored = true` on one code path and the cap silently
stops meaning anything — and the symptom is a slow framerate decline over minutes, which is the hardest
kind of bug to attribute.

**Check:** count unanchored parts during a Magnet Rush. It must not exceed `MaxConcurrentPull`.

### 37. Combat solved from where the limb looks like it is

See #23. This is the same trap, and this game walks straight into it: server-authoritative combat between
client-animated rigs. Write the hitbox contract before the first attack profile.

### 38. Config-first decays one constant at a time

The first `16` typed inline instead of `Config.BaseDriveSpeed` is not a problem. The fortieth is a game
that cannot be balanced. It never arrives as a decision.

**Check:** grep for numeric literals in gameplay modules during review.

### 39. The colour language decays one green pipe at a time

Green means recycle. Orange means repair. Cyan means magnet. The first decorative green pipe is harmless;
after twenty, colour no longer tells the player anything and the HUD has to do all the work.

### 40. Pay-to-win arrives as a "small convenience"

Nobody proposes "+50 % robot damage". They propose a slightly better repair rate, a slightly shorter
cooldown, a small head start. [Decision 0011](decisions/0011-robux-never-buys-arena-power.md)'s test is
the only defence: **could two identical players, one paying, produce a different Arena outcome?**

### 41. A part lost in the Arena would kill the game

Panels pop off on death. The **owned** part never does. Anything that makes players afraid to deploy
their robot removes half the game — and the Arena is already the half that runs unattended.

### 42. Placing objects at a height taken from a constant

> **The incident.** On Jungle, a placement routine trusted `CLEAR_Y = 15` as the ground height. Terrain
> voxels snap to a `RES = 4` grid, so the real surface was ~17 and the props were buried. The fix was to
> **raycast** for the surface. The same root cause recurred twice more (Jungle jobs 088, 090).

**Rule:** never take a world height from a constant. Measure the surface at the point you are placing.
This is [#3](#3-a-world-fact-asserted-from-a-constant) again, in its most expensive form.

**Check:** every runtime placement raycasts, and handles the raycast returning `nil`.

**The separate, adjacent hazard:** under Instance Streaming a raycast can also return `nil` simply
because the geometry is not loaded on that client. Distinguish "the ground is at 17, not 15" from "the
ground is not here yet" — they need different handling, and treating the second as the first is how you
get a prop at the world origin.

### 43. The refresh warning nobody hears

A Factory Refresh that silently retracts a part the player was walking toward reads as a bug, not a rule.
The 20-second warning must be **audible and visible from anywhere in the zone, while running**.

### 44. Deferring the Factory Refresh

It is tempting to build zones 1 and 2 with static spawns "for now". Every system built that way encodes
assumptions the refresh then breaks, and the rework lands late. It is in the
[MVP](roadmap/mvp.md) for that reason.

---

## Part 6 — Engine facts

### 45. The rendered docs site misreports deprecation and ordering

> **The incident.** This repo's own job 001. Three separate engine facts were taken from
> `create.roblox.com` and were wrong there: `Enum.AnimationPriority`'s ordering, a class-level
> deprecation on `AnimationController`, and a deprecation bled onto `TextService:FilterStringAsync` from
> the adjacent `FilterAndTranslateStringAsync`. Two of the three had already propagated into the shared
> `roblox-animation` skill, and from there into this game's robot architecture.

**Rule:** for **deprecation status, security levels and enum ordering**, the rendered docs site is not a
usable source. Read the raw YAML, which carries the real `tags:` / `security:` / `deprecation_message:`
blocks:

```
https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine/<classes|enums>/<Name>.yaml
```

Cross-check `setup.rbxcdn.com/version-<hash>-API-Dump.json` when it matters.

**Check:** any doc in this repo asserting "X is deprecated", "X is superseded", "only a plugin can write
X", or an enum's *order* names where it was read from. If the answer is the docs website, it is not yet
verified.

### 46. An enum that does not order by its numeric value

> **The incident.** `Enum.AnimationPriority.Core` has value **1000** while `Action4` has **5** — and
> `Core` is the **lowest** priority of the seven. This page's own game got it backwards in its first
> draft, inherited from the shared skill.

**Rule:** never infer an enum's semantics from its numeric values.

**Check:** an attack clip set to `Core` loses to `Idle`. If a robot's attack animation "does not play",
check the priority before checking anything else.

### 47. A type annotation on a table FIELD is a syntax error, and it looks fine

> **The incident.** Twice. Job 003 shipped `Remotes.SPECS: { Spec } = {` in **seven of eleven files**
> and the whole server failed at require time. Job 006 then did the identical thing in
> `Config/Perf.luau` — after the first one had been found, fixed and written up.

**Rule:** Luau allows a type annotation on a **local declaration**, a parameter and a return. Not on a
table-field assignment.

```lua
Perf.REGISTER: { Measurement } = { ... }   -- SYNTAX ERROR
Perf.REGISTER = { ... } :: { Measurement } -- correct
local x: { Measurement } = { ... }          -- also correct
```

**Why it keeps happening:** it reads exactly like the local-declaration form, and the error surfaces at
*require* time in a different file than the one you edited — job 006's error pointed at `Perf:87` from a
stack rooted in `Bootstrap:53`.

**Check:** grep before running.

```
grep -rn "^[A-Za-z_][A-Za-z0-9_.]*\.[A-Za-z0-9_]*\s*:\s*[^=]*=\s*{" studio_game --include=*.luau
```

Should return nothing.

### 48. A capability that works in the command bar and fails in a Script

> **The incident.** `TriangleMeshPart.CollisionFidelity` is `PluginSecurity` on write and documented as
> not manipulable by scripts at runtime — but the Studio command bar has plugin capability, so it works
> there. Anything tested only in the command bar looks supported.

**Rule:** a gated property write is verified in a **real Play script**, never in the command bar or via
`execute_luau`.

**Check:** for each property a design says to set at runtime, confirm its write `security:` is `None`.

### 49. A timeout that loses a race with gravity

> **The incident.** Abandoned scrap in `PULL` was rescued by a 6.0s reaper. Scrap is
> `CanCollide = false` by design, so an abandoned piece does not land — it falls *through* the
> floor and reaches `FallenPartsDestroyHeight` in **2.26s** at gravity 196. The reaper was correct
> in shape and never once fired in time: 45 of 45 objects were destroyed by the engine, and the
> pool bled a part per abandonment, permanently.

**Rule:** when a cleanup competes with a physical process, bound the **state**, not the clock. A
height/distance limit fires as soon as the thing has moved; a timeout fires when the thing is
already gone. Keep the timeout as a backstop, never as the mechanism.

**Check:** compute both times from the LIVE world, not from constants, and assert the ordering at
startup: `sqrt(2 * FALL_LIMIT / workspace.Gravity)` must be well under
`sqrt(2 * -FallenPartsDestroyHeight / workspace.Gravity)`.

### 50. An anti-cheat gate that measures the wrong quantity

> **The incident.** Two in one system. The collection range was `pullRadius * 1.35` = 16.2 studs
> against an arrival radius of 2.5 — so *entering the field* was the collection and 13.7 studs of
> every pull were optional; 80 of 80 objects were granted without moving any. Then the travel-time
> gate written to fix it measured **distance moved**, which is zero for an object that never moves
> — vacuous for precisely the case it guarded.

**Rule:** derive a gate from the geometry it is checking, never by scaling a number that belongs to
a different thing. Here: `TIP_OFFSET + ARRIVE_RADIUS + LAG_ALLOWANCE`, and the time gate measures
the **journey the object needed to make**, not the distance it happens to have covered.

**Check:** state the gate and the thing it must be tighter than in the same log line at startup, so
the day they meet is visible: `grant gate 9.1 vs radius 12.0`.

### 51. The server judges a position it has not received yet

> **The incident.** After `SetNetworkOwner(player)`, the object's position is authored by the
> client. The client hid an arrived object and claimed it in the same frame; the server was still
> holding the pre-pull position, up to a full pull radius away, and rejected **43% of honest
> collections**. Worse, the arrived object was unanchored, `CanCollide = false` and no longer
> driven, so it free-fell 6.13 studs during the 0.25s batch wait — out of its own grant gate.

**Rule:** anything the client hands to the server for validation must be **held still and given a
round trip**. Pin the object, and validate on the tick *after* arrival, not the next one that fires.

**Check:** a per-gate rejection census on an honest sweep must read zero. A bare total ("13 of 30
rejected") cannot distinguish an exploit from a gate that is refusing real play.

### 52. A threshold chosen in one file against values chosen in another

> **The incident.** `Config/Quality.decorativeLightRange` was 40 / 60 / 10000 studs. Every light
> `KitSpec` authors is 4, 5, 12, 14 or 16, with a `KitBuilder` default of 18. `Range <= threshold`
> was therefore true for every light in the game at every tier, forever: the cull could not fire,
> and it logged `lights toggled=0` on a healthy run and a broken one alike. The same function read
> a `Hero` attribute nothing writes, while the kit stamps `Decorative`, which nothing reads.

**Rule:** when a threshold gates values produced elsewhere, **derive the comparison from those
values** and assert the relationship at startup, stating both numbers. And when one module stamps
a marker for another to consume, grep that the reader and the writer use the same name — a
producer with no consumer is a lie in a table.

**Check:** `light clamp: kit max 18 studs vs Low 10 / Medium 15 / High 10000` — printed from
`KitSpec.maxLightRange()`, not typed, with an error when a tier's threshold reaches the maximum.

### 53. A client-side visual downgrade that the server keeps undoing

> **The incident.** The Low quality tier drops `MaterialVariant` to skip PBR sampling.
> `MaterialVariant` is a **replicated, server-owned property**, and `MaterialKit.setUsePBR` flips a
> module-level local — modules are per-VM, so the client's decision never reached the server,
> whose flag stayed true. Every scrap spawn re-stamped the variant on top of the client's strip.
> Measured: 37 → 0 → **37** as soon as the server spawned more. `refresh` was one-shot.

**Rule:** a client cannot opt out of a property the server writes. Either the server must know the
client's tier, or the client must **maintain** its override rather than apply it once. And for
**pooled** objects, `DescendantAdded` never fires — they are re-stamped while already parented —
so a reconciling sweep is the mechanism, not a signal.

**Check:** strip on the client, make the server spawn more, and count again. If the number climbs,
the override is decorative.

### 54. Measuring the device during the loading screen

> **The incident.** The quality tier was chosen from a frame time sampled 2–6 seconds into the
> session — while the kit's PBR maps were still decompressing, the world was still streaming, and
> often before the character existed, so the camera was drawing almost nothing and frames looked
> cheap. A phone could classify **High** and hold a 160-object physics cap for the whole first
> minute. Separately, the bootstrap `apply(default())` set `current` before the first
> classification, so the hysteresis branch always fired and the documented thresholds (26 ms /
> 12 ms) were dead constants no client ever used — the real gates were 29 and 9.

**Rule:** gate any device measurement on `game.Loaded`, on the character existing, and on a settle
delay. And a "current state" variable that feeds hysteresis must not be set by a provisional
default, or the neutral entry path is unreachable.

**Check:** log the thresholds actually applied, not the ones in the config.

