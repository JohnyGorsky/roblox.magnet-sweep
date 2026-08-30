# Places & sync

## One place

| Role | Place | Id | Universe | Sync root |
|---|---|---|---|---|
| Everything | **MAGNET SWEEP** | `111667188608192` | `10764307230` | `studio_game/` |

Published name: **🧲 MAGNET SWEEP ⚡ Build & Battle Robots 🤖**, and the local DataModel now carries the
same name — Explorer and store page agree.

The Workshop, the Scrap Arena, all twelve zones and the Service Hubs are one place, carried by Instance
Streaming. This is [decision 0001](../../decisions/0001-one-place-not-two.md) and it deliberately
diverges from The Last Tide and ELEVATOR 13, which are both two-place games.

`studio_lobby/` is an **empty stub**. It syncs nothing and is listed in no config. It exists only so a
future split stays cheap.

## ✅ The sync layout is VERIFIED

Probed over MCP in [job 002](../../../Jobs/002/final-summary.md) on 2026-08-29. **Every path was
observed, not assumed** — Tide job 003 was burned by assuming, and ELEVATOR 13 inherited the same
unverified guess rather than resolving it.

**Method that could fail:** a marker file was written into *every* candidate location simultaneously, so
"nothing appeared" could be distinguished from "this particular path does not sync". Eleven of eighteen
markers arrived; seven did not. A silent no-op would have shown as zero arrivals.

### Layout: FLAT

Service folders sit **directly at the sync root**. `StarterPlayer`'s children sit at the root too:

```
studio_game/
├── ReplicatedFirst/            ✅ syncs
├── ReplicatedStorage/          ✅ syncs
├── ServerScriptService/        ✅ syncs
├── ServerStorage/              ✅ syncs
├── StarterPlayerScripts/       ✅ syncs → StarterPlayer.StarterPlayerScripts
└── StarterCharacterScripts/    ✅ syncs → StarterPlayer.StarterCharacterScripts
```

**The nested Rojo form syncs nothing.** `studio_game/StarterPlayer/StarterPlayerScripts/` produced no
instance at all. This matches The Last Tide and **contradicts Jungle**, which uses the nested convention
— the two genuinely disagree, which is why it had to be measured.

### Does not sync

`StarterGui/` · `StarterPack/` · `Workspace/` · `Lighting/` · `SoundService/` · `StarterPlayer/`

Anything in those services is **hand-placed in Studio**, not authored on disk. That is a real constraint
on how the Workshop, the zones and the HUD get built: geometry and `ScreenGui` trees are editor work,
and scripts reach them by name.

### File suffixes

| Suffix | Class | RunContext |
|---|---|---|
| `.luau` | `ModuleScript` | — |
| `.server.luau` | `Script` | `Server` |
| `.client.luau` | `Script` | `Client` |
| `.local.luau` | `LocalScript` | `Legacy` |
| `.module.luau` | ⚠️ **not a suffix** — yields a `ModuleScript` named `<x>.module` | — |

> 🔴 **`.client.luau` in `StarterPlayerScripts` RUNS TWICE.** Reproduced in a Play session: once in
> place as `StarterPlayer.StarterPlayerScripts.<name>`, and again as the per-player copy
> `Players.<name>.PlayerScripts.<name>`. Roblox logs a warning:
>
> > *"The script … with a non-legacy RunContext is parented to a container 'StarterPlayerScripts', which
> > will cause it to run multiple times."*
>
> **Use `.local.luau` in `StarterPlayerScripts`.** The control script in the same test — a `.local.luau`
> → `LocalScript` — fired exactly once.

### Deletion propagates both ways — but only if you leave the folders alone

Deleting a **file** removes its instance. Deleting an **instance** in Studio deletes the source file
([PITFALLS #10](../../PITFALLS.md#10-studio-sync-is-two-way-and-deleting-an-instance-deletes-the-file)).
Both directions verified.

> 🔴 **The directory structure under `studio_game/` is fixed.** Exactly six folders, created once, never
> deleted, each pinned with a `.gitkeep`. **Adding or removing directories in the sync root drops the
> connection** — it did so twice during job 002, and it also produced a false "deletion is one-way"
> finding, because a watcher whose folders vanish cannot report the file deletions underneath them.
> [PITFALLS #11b](../../PITFALLS.md#11b-creating-or-deleting-directories-in-the-sync-root-drops-the-connection).
>
> Never create a folder for a service that does not sync. It maps to nothing and destabilises the
> connection.

## Place settings — current state

| Setting | State | Notes |
|---|---|---|
| `StreamingEnabled` | ✅ **true** | Load-bearing for a one-place twelve-zone corridor |
| Maximum Visitor Count | ✅ **12** on Creator Hub | See the stale-session warning below |
| `Lighting.LightingStyle` | ✅ **Realistic** | Carries the role `Future` used to; what the glossy look needs |
| `Lighting.PrioritizeLightingQuality` | ✅ true | Keep |
| Social Slots | 🔴 **Roblox optimized** — DECIDED AGAINST, not yet applied | Must become a fixed 12 — see below |
| Access level | 🔴 **Private during development** — decided 2026-08-30 | Not yet applied |

### ⚠️ The Studio session can be stale, and publishing from it can overwrite the web

The Creator Hub says **12**. The open Studio Edit session still reports `Players.MaxPlayers = 60`, and
`Players.PreferredPlayers = 60` alongside it — re-probed 2026-08-30 and unchanged.

That is a **cached session**, not a failed save — the Creator Hub value is what live servers use. But it
is a genuine hazard: **publishing from a Studio session holding the old value can push `60` back over
the `12`.** Reopen the place in Studio before publishing, and confirm it reads 12.

`Players.MaxPlayers` is **read-only from scripts** (`"Unable to assign property MaxPlayers"`), so this
cannot be corrected or asserted from code — only observed.

### Social Slots — decided, and still to be applied by a human

**Decision (2026-08-30): a fixed 12 slots, and the place stays private while it is being built.**

`Roblox optimized` lets Roblox add slots above the cap so friends can join a full server, which means
**the effective server size can exceed 12** — the number every budget in
[performance](../performance/README.md) is calculated against. Measuring the Arena robot count or the
pull cap against a server that can quietly hold more than 12 would produce numbers that mean nothing.

Tide shipped `Fully Open` with social slots on without deciding either, and both became findings — the
failure there was not the setting, it was that nobody chose it. This one is now chosen.

> **The human owns every setting on this page.** Server size, social slots and access level are
> theirs to set and change; none of it is tracked as an outstanding item here and it should not be
> raised again. Recorded below only so the *reason* behind the numbers survives — every performance
> budget assumes a server of a known size, so if that changes, the budgets need re-baselining.

#### The values, for reference

| Where | Setting | Value |
|---|---|---|
| Creator Hub → the place's settings | **Server Size / Max Players** | `12` |
| Creator Hub → the place's settings | **Social Slots** | a **fixed** number, `0` extra — not "Roblox optimized" |
| Creator Hub → the experience's settings | **Playability / Access** | **Private** while building |

⚠️ **Claude cannot apply any of these.** Probed 2026-08-30 in the live Edit session:
`Players.MaxPlayers` and `Players.PreferredPlayers` are **read-only from scripts** — a write is
refused — and Social Slots and access level are web settings with no script surface at all. They can
only be observed from here, never set or asserted.

`Lighting` contains a `Sky`, `Atmosphere`, `SunRaysEffect`, `BloomEffect`, `DepthOfFieldEffect`
**and a `ColorCorrectionEffect`** — verified in a Play session, 2026-08-30. Most of
[build group 03](../../build/03-lighting-and-look.md)'s objects exist and need configuring
rather than creating.

> ⚠️ This list was wrong once, and the error cost real work. It omitted `ColorCorrectionEffect`,
> and a reviewer reading it concluded that colour grading was missing from the game — which
> matters because `postColorCorrection` is the **only** post-processing field that differs
> between the Low and Medium tiers. The effect was there all along. An inventory of what lives
> inside the `.rbxl` is unfalsifiable from the repository, so date it and say how it was checked,
> or do not write it down.

> ⚠️ **The streaming radii are not scriptable.** `StreamingTargetRadius`, `StreamingMinRadius`,
> `StreamingIntegrityMode` and `ModelStreamingBehavior` are *not valid members of Workspace* from Luau —
> reading one throws. They are Properties-pane settings, so tuning the streaming budget is a **human**
> action, and its values cannot be asserted from a script.

> ⚠️ **The lighting properties are not settable from code — any code.** Measured live:
>
> | Property | Read | Write |
> |---|---|---|
> | `Lighting.Technology` | ❌ throws *"lacking capability RobloxScript"* | ❌ same |
> | `Lighting.LightingStyle` | ✅ | ❌ *"cannot write 'LightingStyle' (lacking capability RobloxScript)"* |
> | `Lighting.PrioritizeLightingQuality` | ✅ | ❌ same |
>
> So the lighting **style** is a human action in Studio, permanently. Only the *contents* of `Lighting`
> — the `Atmosphere`, `Sky`, `BloomEffect` and friends — are scriptable, and those are where build group
> 03's work actually lives.

## Open

| Question | When |
|---|---|
| **Social Slots** — `Roblox optimized` can push the server past 12, which is the number every performance budget assumes | before the place is joinable, and after the Arena count is measured |
| Access level — decide deliberately | before the place is joinable |
| Reopen Studio so its session picks up `MaxPlayers = 12`, and never publish from a session showing 60 | before the next publish |
| Streaming radii — what target radius suits a twelve-zone corridor? Human-set, and needs measuring | before zone 3 |
| Does 12 players still hold once the Arena robot count is **measured**? | when the Arena is measured |
