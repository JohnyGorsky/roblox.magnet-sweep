# Places & sync

## One place

| Role | Place | Id | Universe | Sync root |
|---|---|---|---|---|
| Everything | **MAGNET SWEEP** | `111667188608192` | `10764307230` | `studio_game/` |

Published name: **🧲 MAGNET SWEEP ⚡ Build & Battle Robots 🤖**. Note the local DataModel is still named
`Place2` — cosmetic, but worth renaming so Studio's title bar and the Explorer agree with the store page.

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

### Deletion is one-way

Deleting a **file** does **not** remove the instance from Studio; the instances survived and had to be
destroyed explicitly. The reverse *is* destructive: deleting an instance in Studio deletes the source
file ([PITFALLS #10](../../PITFALLS.md#10-studio-sync-is-two-way-and-deleting-an-instance-deletes-the-file)).

Practical consequence: **renaming a file leaves the old instance behind.** Renames need a Studio-side
cleanup or you accumulate ghosts that still run.

## Place settings — current state

| Setting | Now | Target | Notes |
|---|---|---|---|
| `StreamingEnabled` | ✅ **true** | true | Already on. Load-bearing for a one-place twelve-zone corridor |
| `Players.MaxPlayers` | ⚠️ **60** | **12** | Decided; needs changing in Studio |
| `Players.PreferredPlayers` | 60 | 12 | Same |
| `Lighting.LightingStyle` | ⚠️ **Soft** | **Realistic** | Realistic carries the old `Future` role and is what the glossy look needs |
| `Lighting.PrioritizeLightingQuality` | true | true | Keep |
| Access / social slots | not checked | decide | Tide shipped `Fully Open` with social slots on; both became findings |

`Lighting` already contains a `Sky`, `Atmosphere`, `SunRaysEffect`, `BloomEffect` and
`DepthOfFieldEffect` — most of [build group 03](../../build/03-lighting-and-look.md)'s objects exist and
need configuring rather than creating.

> ⚠️ **The streaming radii are not scriptable.** `StreamingTargetRadius`, `StreamingMinRadius`,
> `StreamingIntegrityMode` and `ModelStreamingBehavior` are *not valid members of Workspace* from Luau —
> reading one throws. They are Properties-pane settings, so tuning the streaming budget is a **human**
> action, and its values cannot be asserted from a script.

> ⚠️ **`Lighting.Technology` cannot even be read.** It is `RobloxScriptSecurity` on read *and* write —
> the attempt throws *"lacking capability RobloxScript"* even from the privileged MCP context. Confirmed
> live. Use `LightingStyle`, which is readable.

## Open

| Question | When |
|---|---|
| Rename the DataModel from `Place2` to `MAGNET SWEEP` | cosmetic, any time |
| Access level and social slots — decide deliberately before anyone can join | before the place is joinable |
| Streaming radii — what target radius suits a twelve-zone corridor? Human-set, and needs measuring | before zone 3 |
| Does 12 players still hold once the Arena robot count is **measured**? | when the Arena is measured |
