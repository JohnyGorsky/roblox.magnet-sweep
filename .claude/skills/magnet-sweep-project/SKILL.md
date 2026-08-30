---
name: magnet-sweep-project
description: MAGNET SWEEP (roblox.magnet-sweep) project context — a physics collection + extraction + robot-building game where players pull scrap with a magnet, rip rare Robot Parts out of a 12-tier factory, escape security with them, bolt them onto a homemade robot, and release that robot into a persistent server Arena. Points at the repo's design pack (vision, pillars, magnet/cargo/factory/robot/arena systems, zone and part catalogs, decisions, build manifest) and carries the game's non-negotiables: ONE place, parts are content and the rig is the engine, the server owns capture and rewards, physics is budgeted not free, the Arena is never pay-to-win, and IMPLEMENTED is not VERIFIED. Consult this before ANY work in roblox.magnet-sweep.
---

# MAGNET SWEEP — project context

**This skill is the entry point for MAGNET SWEEP (`roblox.magnet-sweep`).** Read it before touching
anything in that repo.

> All games' skills load at once in this multi-root workspace. This one is for **MAGNET SWEEP** — a
> magnet/scrap/robot game. It is *not* Defender, *not* Jungle/Last River, *not* The Last Tide and
> *not* ELEVATOR 13.

Use the shared `roblox-dev` skill for engine APIs, the `magnet-sweep-style` skill for the look, and
`roblox.workspace/GROUND-RULES.md` above all else.

## What the game is

A **physics collection + extraction + robot-building game**. The loop, in the player's words:

> "I started by collecting screws. Now I'm running away from a security robot while dragging an engine
> behind me so I can put it inside my homemade fighting robot."

Five layers, each feeding the next:

1. **Sweep** — a magnet pulls scrap. Objects shake, lift, spiral in, and make a noise. This is the ASMR
   layer and it has to be satisfying *before* anything else is built.
2. **Go deeper** — 12 factory tiers, gated on Magnet Power. Forward always means bigger, heavier,
   rarer, more dangerous.
3. **Extract** — some objects are **Robot Parts**. Ripping one free trips a **Salvage Breach**;
   you then run 20–45 seconds to a Service Hub while slowed by the thing you are carrying.
4. **Build** — a secured part gets bolted onto a physical robot in the Robot Bay. Traffic-light head,
   fridge-door body, giant-spoon arm. Homemade and ridiculous is the goal, not sleek.
5. **Arena** — that robot fights automatically in a persistent server Arena for control of the Arena
   Core. It takes damage and needs scrap to repair. Scrap is also how you upgrade yourself.

The economy pinches at exactly one place, and everything else hangs off it:

> **Do I spend this scrap on myself, or on keeping my robot alive?**

Full vision: [docs/game/vision.md](../../../docs/game/vision.md).
Source of record: `assets/MAGNET SWEEP.md` (the 87-section intake) plus `assets/concept_art/`
— read-only history; `docs/` is the living version.

## The repo is design memory; Studio is the code

| Question | Authority |
|---|---|
| What the game **should** be, and **why** | this git repo (`docs/`) |
| What **actually exists** right now | the live Roblox Studio session, via MCP |

- **Inspect Studio through MCP before claiming implementation state.** Docs existing does not mean code
  exists; docs missing does not mean code doesn't.
- ⚠️ **`require` in `execute_luau` builds a SECOND copy of a module**, with its own state. Reading a
  server module's state that way measures a blank object, not the running game. Go through the
  `DevCommand` remote, or read shared Instances and attributes. This produced two confidently wrong
  readings in job 008 before it was caught.
- **`IMPLEMENTED` is not `VERIFIED`.** `IMPLEMENTED` = code/content exists. `VERIFIED` = a real
  playtest exercised it and the result was recorded.
- **Never silently overturn an accepted decision** in
  [docs/decisions/](../../../docs/decisions/INDEX.md). If one must change, write a new record saying so.

## One place

| Role | Place | Id | Universe | Sync root |
|---|---|---|---|---|
| Everything | MAGNET SWEEP | `111667188608192` | `10764307230` | `studio_game/` |

The Workshop hub, the Scrap Arena, all 12 factory zones and the Service Hubs live in **one place**,
carried by Instance Streaming. This is [decision 0001](../../../docs/decisions/0001-one-place-not-two.md),
and it **deliberately diverges** from Tide and ELEVATOR 13, which are both two-place games. The reason
is specific: §8 of the spec wants the Arena physically visible from the Workshop and §51 wants it
notifying you mid-factory. A place boundary turns both into cross-server messaging.

`studio_lobby/` exists as an **empty stub** and syncs nothing.

✅ **The sync layout is VERIFIED** (job 002, probed over MCP). It is **FLAT** — service folders at the
sync root, and `StarterPlayerScripts/` / `StarterCharacterScripts/` **at the root**, not nested under
`StarterPlayer/`. The nested form syncs nothing.

**Does not sync:** `StarterGui`, `StarterPack`, `Workspace`, `Lighting`, `SoundService`. Anything there
is hand-placed in Studio; scripts find it by name.

**Suffixes:** `.luau` = `ModuleScript` · `.server.luau` = `Script`/Server · `.client.luau` =
`Script`/Client · `.local.luau` = `LocalScript` · `.module.luau` is **not** a suffix (you get a
`ModuleScript` named `<x>.module`).

🔴 **`.client.luau` in `StarterPlayerScripts` RUNS TWICE** — reproduced in Play. Use `.local.luau` there.

🔴 **Deleting a file does not delete the instance**; only Studio → disk deletion propagates. A rename
leaves a ghost behind that still runs.

## Non-negotiables

Each links to its decision record.

1. **Parts are content; the rig is the engine.**
   ([0004](../../../docs/decisions/0004-parts-are-content-rig-is-the-engine.md)) One hidden robot
   skeleton with fixed sockets. Every part is a model with a `RobotMount` attachment, a slot, an
   **animation profile** and stats. Adding a Toilet Brush Arm must never mean writing robot code.
   ~20 animation profiles cover all 96 parts, not 96 × 20 animations.
2. **The server owns capture, currency and Arena outcome.**
   ([0007](../../../docs/decisions/0007-server-owns-capture-and-reward.md)) The client may *feel* the
   magnet — pull VFX, local motion, sound — but "I secured the Giant Spoon", "I have 12,450 Coins" and
   "my robot held the Core for 4 minutes" are server facts. Never trust a client's collection report.
3. **Physics is budgeted, not free.**
   ([0005](../../../docs/decisions/0005-four-state-scrap-budget.md)) Scrap has four states — IDLE
   (anchored, free) → REACT (anchored, shaking) → PULL (unanchored, real physics, **capped count**) →
   COLLECTED (pooled). A visible world of thousands is fine. A *simulated* world of thousands is not.
   The cap is a config number and the pool is mandatory from day one.
4. **Config-first.** Magnet Power curves, zone gates, part stats, Arena heat, repair rates and every
   economy value live in shared config modules. Balance without touching gameplay code.
5. **The Arena is never pay-to-win.**
   ([0011](../../../docs/decisions/0011-robux-never-buys-arena-power.md)) Robux sells magnet
   convenience, cosmetics and server-wide spectacle events. It never sells robot damage, robot HP,
   instant Legendary parts or Arena wins. Field repair is rate-limited *specifically* so a wealthy
   player cannot hold the Core forever.
6. **A rare part in hand is not owned.** Ownership transfers at the Service Hub `SECURED` moment and
   nowhere else. Unsecured cargo does not save on disconnect — that is the whole anti-extraction-exploit
   design ([0008](../../../docs/decisions/0008-secured-at-the-hub-not-in-hand.md)).
7. **Guardians are inert until you steal.** ([0014](../../../docs/decisions/0014-the-owning-guardian-chases.md))
   Only the guardian whose part you took chases you, and it chases across zones. Caught **inside its own
   territory** the part resets; caught **outside**, you ragdoll and it drops for anyone. A player
   carrying nothing is never threatened — sweeping is 55 % of playtime and must stay relaxing.
8. **The factory refreshes; nothing is memorisable.**
   ([0006](../../../docs/decisions/0006-the-factory-refreshes.md)) Scrap repopulates every 30–60 s,
   Robot Parts re-roll every ~4 min, and a server-wide Shift re-weights the pools every ~12 min. "The
   spoon is always here" must never become true.
9. **Mobile is measured, not reasoned about.**
   ([0012](../../../docs/decisions/0012-mobile-first-quality-tiers.md)) Use Studio's Device Emulator.
   Defender burned four rounds of rework deferring phone questions the emulator would have answered
   immediately. The glossy look ships as a **quality tier**, with a mobile floor that is never optional.
10. **No placeholder assets.** Leave the slot empty and make it announce itself. A wrong sound is much
   harder to notice than a missing one.
11. **Sound is a feature, not polish.** §15 gives every object family its own voice — bolt *tik*, coin
    *ding*, spring *boing*, barrel *CLANG*. The game is explicitly headphone-recommended. Audio is not
    the last group in the manifest.

## The docs map

| Folder | Holds |
|---|---|
| [`docs/game/`](../../../docs/game/) | Vision, pillars, core loop, palette, UI direction, monetisation stance, naming |
| [`docs/systems/`](../../../docs/systems/) | How each system is *intended* to work — 16 of them |
| [`docs/content/`](../../../docs/content/) | The 12 zones, the 96-part catalog, events, cosmetics |
| [`docs/decisions/`](../../../docs/decisions/INDEX.md) | Why the load-bearing choices were made |
| [`docs/features/`](../../../docs/features/) | Units of planned/completed work + their status |
| [`docs/build/`](../../../docs/build/README.md) | **The manifest — what to build next** |
| [`docs/roadmap/`](../../../docs/roadmap/) | MVP, launch |
| [`docs/PITFALLS.md`](../../../docs/PITFALLS.md) | Mistakes already paid for. Read before building |
| [`Jobs/`](../../../Jobs/) | **The record of what was actually done.** `docs/build/` is the intent; this is the outcome |
| [`findings/`](../../../findings/) | Real defects found and deliberately deferred, with the reasoning |
| [`Planned/`](../../../Planned/) | One file per queued idea. Promoting one = a new job intake |
| [`assets/registry/`](../../../assets/registry/) | Asset ids, per type. Grep before sourcing anything |
| [`tools/`](../../../tools/README.md) | Generators and checkers. Run them before calling a job done |

⚠️ **`docs/build/*.md` checkboxes are not progress.** `gen-build-manifest.py` rewrites those files and
emits `- [ ]` unconditionally, so a tick is erased on the next run. `Jobs/` is the record.

## The gate that matters

Before building zone 3, answer §84 honestly:

> **When the player sees a strange object in the distance, do they think "I want that on my robot"?**

If not strongly *yes*, ten more zones will not fix it. Fix the pull feel, the sound, the moment the part
breaks free, the alarm, the run home, and the install animation first.
