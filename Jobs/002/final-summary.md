# Job #002 — final summary

**Project:** `roblox.magnet-sweep` · **Status:** complete · 2026-08-29

## Goal

Verify the place over MCP and **observe** the Studio Sync layout, replacing the guess `.jobconfig.json`
inherited from The Last Tide.

## The place

| | |
|---|---|
| Published name | 🧲 MAGNET SWEEP ⚡ Build & Battle Robots 🤖 |
| `PlaceId` | `111667188608192` |
| Universe | `10764307230` |
| Creator | `johnygorsky10` |
| Studio | `0.736.0.7361346`, Edit mode |
| DataModel name | ⚠️ `Place2` — cosmetic, worth renaming |

Existing contents: a `Baseplate`, a `SpawnLocation`, and a `Lighting` service already holding a `Sky`,
`Atmosphere`, `SunRaysEffect`, `BloomEffect` and `DepthOfFieldEffect`. All script service folders empty.

## Method — a probe that could fail

18 marker files were written into **every candidate location simultaneously**, then the DataModel was
read back. Writing to only the expected paths would have made "sync is down" indistinguishable from
"this path does not sync"; writing everywhere makes zero arrivals mean something specific.

**11 of 18 arrived.** A dead connection would have produced 0.

## Findings

### Layout is FLAT — matches Tide, contradicts Jungle

| Path | Result |
|---|---|
| `ReplicatedFirst/` `ReplicatedStorage/` `ServerScriptService/` `ServerStorage/` | ✅ sync |
| `StarterPlayerScripts/` `StarterCharacterScripts/` **at the root** | ✅ sync → `StarterPlayer.*` |
| `StarterPlayer/StarterPlayerScripts/` (nested, Jungle's convention) | ❌ **nothing** |
| `StarterGui/` `StarterPack/` `Workspace/` `Lighting/` `SoundService/` | ❌ do not sync |

Five services being unsyncable is a real constraint on how the game gets built: geometry and `ScreenGui`
trees are **editor work**, and scripts reach them by name.

### Suffixes

| Suffix | Class | RunContext |
|---|---|---|
| `.luau` | `ModuleScript` | — |
| `.server.luau` | `Script` | `Server` |
| `.client.luau` | `Script` | `Client` |
| `.local.luau` | `LocalScript` | `Legacy` |
| `.module.luau` | ⚠️ not a suffix — `ModuleScript` named `<x>.module` | — |

### 🔴 The double-run trap is real here

Tested in a Play session, because Edit cannot answer it. A `.client.luau` in `StarterPlayerScripts`
executed **twice**:

```
#1  StarterPlayer.StarterPlayerScripts.SYNCPROBE_DoubleRun
#2  Players.johnygorsky10.PlayerScripts.SYNCPROBE_DoubleRun
```

Roblox logs a warning that is easy to scroll past. A `.local.luau` control in the same test fired
**once**. **Rule: use `.local.luau` in `StarterPlayerScripts`.**

Play was started and stopped by this job; Studio was returned to Edit and verified.

### 🔴 Deletion is one-way

Deleting the 18 files removed **nothing** from Studio — all 13 instances survived and had to be
destroyed explicitly. Only Studio → disk deletion propagates.

**Consequence:** renaming a file leaves the old instance behind, **and it still runs.** Every rename
needs a Studio-side cleanup.

## Engine facts confirmed live

Both were flagged by job 001's engine review; this job confirmed them against the running Studio:

- **`Lighting.Technology` cannot be read.** `pcall` returns *"lacking capability RobloxScript"* even in
  the privileged MCP context. Use `LightingStyle`, which reads fine (currently `Soft`).
- **The streaming radii are not scriptable at all.** `StreamingTargetRadius`, `StreamingMinRadius`,
  `StreamingIntegrityMode` and `ModelStreamingBehavior` are *"not a valid member of Workspace"* — they
  are Properties-pane settings. Tuning the streaming budget is a human action and cannot be asserted
  from a script.

## Place settings — current vs target

| Setting | Now | Target |
|---|---|---|
| `StreamingEnabled` | ✅ true | true |
| `Players.MaxPlayers` | ⚠️ 60 | **12** |
| `Players.PreferredPlayers` | ⚠️ 60 | **12** |
| `Lighting.LightingStyle` | ⚠️ `Soft` | **`Realistic`** |
| Access / social slots | unchecked | decide before joinable |

## Files changed

- `.jobconfig.json` — rewritten with observed paths; `_status` now **VERIFIED**, with the method and the
  place ids recorded.
- `docs/systems/places/README.md` — rewritten around the observed layout and the live place state.
- `docs/PITFALLS.md` — #12 and #13 promoted from inherited guess to observed fact; **#11b added**
  (deleting a file does not delete the instance).
- `docs/HANDOFF.md`, `.claude/skills/magnet-sweep-project/SKILL.md` — place ids and the verified layout.

All 18 probe files and 13 probe instances removed; both sides verified clean.

## Next

**Job 003 — the config skeleton.** Six config modules, remote definitions, the rate limiter, the logging
helper and the dev/test tools. It is now unblocked: the layout is known, so every file it writes lands
where it is meant to.

Before that, four Studio settings need a human: `MaxPlayers` → 12, `PreferredPlayers` → 12,
`LightingStyle` → `Realistic`, and an access/social-slots decision.
