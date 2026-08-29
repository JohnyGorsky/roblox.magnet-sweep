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
| DataModel name | `Place2` at probe time; **renamed by the user** during the job |

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

### 🔴 A false finding, and the mistake that produced it

This job originally reported *"deleting a file does not delete the instance"*. **That was wrong.**

The probe cleaned up with `find -type d -empty -delete`, which removed the **mapped service folders**
along with the files. A watcher whose directories disappear cannot report the deletions underneath them
— so the instances lingered, and the lingering was read as a property of the sync tool rather than as
damage the cleanup had caused.

Re-tested correctly (create file → confirm arrival → delete **only** the file → re-check): the instance
**is removed**. Deletion propagates in both directions.

The same mistake **dropped the user's sync twice**, and they had to reconnect it both times. The probe
also created folders for services that cannot sync (`StarterGui/`, `Workspace/`, `Lighting/`,
`SoundService/`, `StarterPlayer/`), which have no valid mapping.

**The rule that came out of it:** the sync root's directory structure is fixed — exactly the six mapped
folders, created once, never deleted, each pinned with a `.gitkeep`. Add files freely; never touch
folders. See [PITFALLS #11b](../../docs/PITFALLS.md#11b-creating-or-deleting-directories-in-the-sync-root-drops-the-connection).

## Engine facts confirmed live

Both were flagged by job 001's engine review; this job confirmed them against the running Studio:

- **`Lighting.Technology` cannot be read.** `pcall` returns *"lacking capability RobloxScript"* even in
  the privileged MCP context. Use `LightingStyle`, which reads fine (currently `Soft`).
- **The streaming radii are not scriptable at all.** `StreamingTargetRadius`, `StreamingMinRadius`,
  `StreamingIntegrityMode` and `ModelStreamingBehavior` are *"not a valid member of Workspace"* — they
  are Properties-pane settings. Tuning the streaming budget is a human action and cannot be asserted
  from a script.

## Place settings — resolved during the job

| Setting | State |
|---|---|
| `StreamingEnabled` | ✅ true |
| Maximum Visitor Count | ✅ **12**, set on Creator Hub by the user |
| `Lighting.LightingStyle` | ✅ **Realistic**, set by the user |
| Social Slots | ⚠️ `Roblox optimized` — **still open**, can exceed the 12 cap |
| Access level | ⚠️ still open |

Two further engine facts measured while confirming these:

- **`Lighting.LightingStyle` and `PrioritizeLightingQuality` are readable but NOT writable** — the write
  throws *"lacking capability RobloxScript"*. Combined with `Technology` being unreadable, the lighting
  style is a permanent human-only action in Studio.
- **`Players.MaxPlayers` is read-only from scripts** (*"Unable to assign property MaxPlayers"*).
- ⚠️ The open Studio session still reported `MaxPlayers = 60` after the Creator Hub was set to 12 — a
  stale session. **Publishing from it could push 60 back over the 12.** Reopen before publishing.

## Files changed

- `.jobconfig.json` — rewritten with observed paths; `_status` now **VERIFIED**, with the method and the
  place ids recorded.
- `docs/systems/places/README.md` — rewritten around the observed layout and the live place state.
- `docs/PITFALLS.md` — #12 and #13 promoted from inherited guess to observed fact; **#11b added**
  (creating or deleting directories in the sync root drops the connection).
- `docs/HANDOFF.md`, `.claude/skills/magnet-sweep-project/SKILL.md` — place ids and the verified layout.

All probe files and instances removed; both sides verified clean. The six synced folders are pinned
with `.gitkeep` so no future cleanup can sweep them.

## Next

**Job 003 — the config skeleton.** Six config modules, remote definitions, the rate limiter, the logging
helper and the dev/test tools. It is now unblocked: the layout is known, so every file it writes lands
where it is meant to.

Before that, four Studio settings need a human: `MaxPlayers` → 12, `PreferredPlayers` → 12,
`LightingStyle` → `Realistic`, and an access/social-slots decision.
