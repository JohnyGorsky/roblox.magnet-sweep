# Job #014 — final summary

**Project**: `roblox.magnet-sweep`
**Status**: the boot screen and the first-run hint are built and verified in Play.

Build group 06's remaining half. The manifest opens with the reason this went now rather than later:

> *Build the loading screen early (section 7), not at the end. A loading screen retrofitted over a
> running game fights every system it wraps.*

There was finally a running game to wrap, so this was the last cheap moment.

---

## What was built

| | |
|---|---|
| `ReplicatedFirst/BootScreen.local.luau` | The loading screen. Removes Roblox's default one as its first statement, then holds until four real conditions are met |
| `StarterPlayerScripts/FirstRun.local.luau` | The MOVE NEAR SCRAP hint |
| `ServerScriptService/MagnetState.luau` | The `HasSwept` flag, set where collection actually happens |

## The bar is not a timer, and the log proves it

Every stage completes on a condition that can be observed. Measured across runs:

```
stage "HOLD"    complete after 0.00s     the backdrop has actually been laid out
stage "LOAD"    complete after 0.10s     game:IsLoaded() AND the StatsChanged INSTANCE exists
stage "PROFILE" complete after 0.00s     the first StatsChanged push arrived
stage "PLACE"   complete after 1.39s     <- the one that actually waits
ready in 1.50s
```

**PLACE is the honest one.** Its predicate is not "does `workspace.Workshop` exist" — that only means
a folder replicated. It is *the character exists, the Workshop exists, and a raycast finds ground
under the player's feet.* Dropping someone through an unstreamed floor is precisely what "never spawn
into a void" means, and it is the only one of the four that a timer would have papered over.

A stage that goes slow **says so and keeps waiting** — `docs/systems/boot`'s failure paths are
explicit that a slow stage holds rather than proceeding. There is no timeout that gives up, because
proceeding on a timer produces a player standing in an empty room, which is the same failure as a bar
that finishes early: reporting success while measuring nothing.

## It may assume nothing

`ReplicatedFirst` runs ahead of `ReplicatedStorage`, so at the top of that file there is no `Config`,
no `Remotes`, no `Ui`, no character and no Workshop. Consequences, all deliberate:

- **It builds its own UI** rather than using `Ui.Components`, which may not have replicated.
- **The six duplicated colours are audited.** `auditPalette` compares them against the real
  `Ui.Theme` and warns on drift — the duplication is unavoidable, drifting from it silently is not.
  ⚠️ It is retried from the stage loop, because at one frame into `ReplicatedFirst` there is usually
  no `Ui` to compare against — see the review below, where it had never once run.
- **Sound is loaded lazily and never waited on.** A loading screen must never block on its own audio.
- **The profile signal is polled, not awaited**, so a slow remote shows a message instead of blocking
  on a `WaitForChild` nobody can see.

## Sound: reused, not invented

The per-object *tik* is `FAMILY.Bolt` and the completion **CLANG** is `FAMILY.Barrel` — the game's own
bolt and barrel sounds. That is not a placeholder standing in for something better: §7 shows scrap
flying into a magnet, and those are the sounds that scrap makes. `SoundKit` stays the single source.

## Three things only a screenshot could tell me

The boot screen is on screen for ~1.4s, which is shorter than a round trip — so I added a temporary
per-stage hold, photographed it, and removed the instrumentation. All three of these were invisible
to every log:

| | |
|---|---|
| **The progress bar was invisible when empty.** A 1.2%-tall bar in near-black on a near-black backdrop — so for the first second the only progress indicator was not there | Taller, and a track light enough to see |
| **The 🪙 coin rendered as tofu** — an empty box — while the bolt, gear and magnet drew fine. The row silently showed three objects instead of four | The icons had no explicit `FontFace` and fell back to a face without that glyph. Set to BuilderSans, which the HUD already uses for the same glyph |
| **The pale coin vanished at the dim transparency** even once it rendered | 0.62 rather than 0.82 |

## The first-run hint

One line, and it is the entire tutorial. `docs/systems/boot` §9 is explicit that the teaching is
environmental — scrap shakes, it flies in, Flow climbs, the magnet fills.

🔴 **The flag is the server's.** `HasSwept` is set in `MagnetState.collect`, the one place a
collection happens. The client only reads it. Owning it client-side would mean the client deciding
whether the player is new, and it would have to be rebuilt the moment profiles land in group 11 — the
attribute survives that change untouched.

The hint also **waits for the boot screen to clear** before it can show. A hint drawn underneath the
loading screen is a hint nobody sees, and it would then be dismissed by the first sweep without ever
having been read — the same mistake shape as measuring the device during the loading screen
([#54](../../docs/PITFALLS.md#54-measuring-the-device-during-the-loading-screen)).

### How it was verified, and the honest limit of that

- **Behaviour: verified in Play.** The console shows `[C][FirstRun] first sweep -- hint retired` on
  the first collection, and the hint's condition reads false afterwards.
- **Appearance: verified by forcing the visual state**, because I could not keep the condition true
  long enough to photograph it. Three attempts to spawn scrap outside the magnet's 12-stud pull
  radius all ended with `HasSwept = true` — the magnet collects faster than a script can step the
  character away, which is itself a small compliment to job 007. So the rect and legibility were read
  from a forced state (`320 × 52` at the top centre, clear of the Flow readout, `TextFits` true) while
  the logic was read from the log. **The two halves were verified separately and I am saying so
  rather than implying one screenshot covered both.**

## The independent review found 25, and the worst was in the feature's own logic

Run per [GROUND-RULES 8](../../../roblox.workspace/GROUND-RULES.md) on the requirement alone.

### 🔴 The first-run prompt said the opposite of what it did

`MOVE NEAR SCRAP` was shown when scrap was **within** 26 studs — so a player standing 60 studs from
anything, *the one person the prompt exists for*, never saw it, while a player three studs outside the
pull radius was told to move nearer. It could only appear in a narrow 12–26 stud band for the second
before the sweep retired it. Close to a no-op, and my own comment above it asserted the opposite of
the code beneath it.

Now: hidden inside `ALREADY_SWEEPING` (14), shown out to `REACHABLE` (160). All three branches
verified:

```
A. no scrap at all      -> hint=false   B. scrap 56 studs away -> hint=TRUE   C. in the pile -> hint=false
```

Branch B had never once worked.

### 🔴 Any error left the player trapped behind an opaque screen, forever

`runStages()` was called bare. Roblox's own screen is already gone by then, so **any** throw left the
player behind a full-screen frame at `DisplayOrder = 1000` with no way out but the Roblox menu — the
one place in the game where an unhandled error is unrecoverable, and the one place with no guard. The
live throw source was `loadSounds`, which ran *on the main thread* inside the stage loop with only its
`require` guarded.

Now `pcall`ed, with a 90-second watchdog that releases the screen regardless: a playable game with a
missing loading screen beats an unplayable one with a perfect one.

### Three predicates that measured nothing

| | |
|---|---|
| **`HOLD` was `return true`** — a quarter of the bar snapped full at t=0. PITFALLS #2, in the file whose header cites #2 | Now checks the backdrop has actually been laid out. Still usually instant, but it can now fail |
| **`LOAD` checked `FindFirstChild("Remotes")`**, which resolves to the **ModuleScript** — an initial-replication instance that exists whether or not the server ever ran. So when `Bootstrap` deliberately errors on a fatal config problem, LOAD passed and the boot held reporting **"COULD NOT READ YOUR PROFILE"** — naming the wrong subsystem at the worst moment | Checks for the `StatsChanged` **instance**, which only exists if the server reached `createAll`. Message reworded |
| **`PLACE`'s ground raycast left `RespectCanCollide` false** — and scrap is explicitly `CanCollide = false` and pools *under the player*. A hit off a floating bolt satisfied "there is ground under the player's feet", the one claim the stage exists to make | Set true |

### The rest

| Finding | Fix |
|---|---|
| **The character was live and drivable behind the screen.** It spawns during PLACE — that is what the stage waits for — so a thumb dragged across the loading screen worked the thumbstick underneath, and the player could walk off a ledge blind | The backdrop sinks input (`Active`) |
| **The first *tik* never played, every boot.** `HOLD` completed on its first evaluation so the loop body never ran, so `loadSounds` had never been called | Sounds load before the first stage |
| **`auditPalette` never ran.** It fired once, one frame into a `ReplicatedFirst` script, guarded by a non-yielding `FindFirstChild` — at which point `ReplicatedStorage` has typically not replicated. It returned silently and was never retried, so the drift guard the header cites as making the duplication safe *did not execute* | Retried from the stage loop, like `loadSounds` |
| **A sixth colour the audit did not cover** — the bar track was invented rather than copied, making it the only one nothing checked | Moved into `PALETTE` |
| **`loadSounds` rebuilt both sounds on every retry.** Harmless today; with one empty slot — which every slot is by policy — it leaks ~10 `Sound`s a second | Tried once |
| **The one pixel dimension was a desktop constant.** A 64 px icon row is 17 % of a 374-tall phone viewport and overlapped the tagline by ~6 px, while looking correct at 1080p | Scale-based, and the three text blocks re-spaced |
| **`#ICONS` vs `#STAGES` unasserted** — a fifth stage would land with no icon and no tik, the "row IS the bar" claim failing quietly | Warns on mismatch |
| **The bar never read 100 %** — the fade started on the same frame as the fill tween, so the CLANG landed on nothing | Fill completes first |
| **The loading-screen ART is a P0 deliverable and is not built** | It now **says so by name at every startup**, the way `SoundKit.missing()` does. Four emoji were reading as the finished screen rather than as a hole |
| **`FirstRun`'s timeouts had no failure path** — three analyzer nil errors; the script threw and the hint silently never existed | A real `need()`, copied from `Bootstrap` |
| **`shouldHint` scanned all 400 pool parts 2.5×/s forever** for a player who never sweeps | `GetPartBoundsInRadius`, two existence queries |
| **The hint loop exited permanently on the first sweep** — right in production, but it made the feature unobservable, and a loop whose only exit is permanent encodes an assumption nobody wrote down | Restartable, watching the attribute both ways |

### A dev command, because the feature was untestable

`dev("first.reset")` clears `HasSwept`. Three attempts to observe the hint's positive branch all ended
with the flag already set — **the magnet collects faster than a script can move the character out of
range**, which is a compliment to job 007 and a problem for verification. A state you cannot restore
is a state you cannot verify.

### Known and accepted

- **Rejoin resets the hint.** `HasSwept` is a `Player` attribute and dies with the session, so a
  returning player sees it again. Safe across *respawn* (it is on the Player, and `ResetOnSpawn` is
  false). Becomes correct when profiles land in group 11 — the attribute survives that change
  untouched, which is why it is server-owned.
- **`QualityController` samples frame time during the boot window** without waiting for the screen to
  clear. Negligible load, but the two systems measure the same window and nothing coordinates them.

## Not built

- **"Joined mid-Refresh"** is listed in the design's failure paths, but the Factory Refresh does not
  exist until group 12. There is nothing to join the middle of, and a branch written now would be
  guarding a condition that cannot occur — untestable, and exactly the kind of thing that rots.
  The PLACE stage's real work (hold until there is ground) is the mechanism that will serve it.
- **Profile load failure** has its branch and its message, but cannot be exercised: persistence lands
  in group 11. Today the stage can only hold if the server never pushes `StatsChanged`.
