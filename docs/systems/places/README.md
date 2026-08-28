# Places & sync

## One place

| Role | Place | Id | Sync root |
|---|---|---|---|
| Everything | MAGNET SWEEP | **not created yet** | `studio_game/` |

The Workshop, the Scrap Arena, all twelve zones and the Service Hubs are one place, carried by Instance
Streaming. This is [decision 0001](../../decisions/0001-one-place-not-two.md) and it deliberately
diverges from The Last Tide and ELEVATOR 13, which are both two-place games.

`studio_lobby/` is an **empty stub**. It syncs nothing and is listed in no config. It exists only so a
future split stays cheap.

## ⚠️ The sync layout is UNVERIFIED

`.jobconfig.json` currently **guesses** the layout from The Last Tide. Do not cite those paths as fact.

| Game | Layout |
|---|---|
| The Last Tide | **flat** — service folders at the sync root; `StarterPlayerScripts/` and `StarterCharacterScripts/` at the root, *not* nested under `StarterPlayer/` |
| Jungle | **nested** — the Rojo convention, `sync/StarterPlayer/StarterPlayerScripts/` |

The two disagree. Tide job 003 was burned by assuming, and ELEVATOR 13 inherited the same unverified
guess rather than resolving it. **Job 002 probes it over MCP and rewrites the file with what was
observed.**

What the probe must settle:

1. Flat vs nested.
2. Which service folders actually sync. On Tide, `StarterGui`, `StarterPack` and `Workspace` do **not**.
3. Which file suffix produces which class. On Tide: `.luau` = `ModuleScript`, `.server.luau` =
   `Script`/Server, `.local.luau` = `LocalScript`, `.module.luau` is **not** recognised — and
   `.client.luau` in `StarterPlayerScripts` **runs twice**, which is a trap.

## Studio Sync is two-way and destructive

> 🔴 **Deleting an instance in Studio deletes the source FILE.** Treat a Studio-side delete as `rm`.
> Scope any cleanup to `Workspace` only, and never tidy the synced service folders from the Explorer.

> ⚠️ **Reopening a place can silently drop the sync connection.** Confirm sync is live before trusting
> that an edit landed.

> ⚠️ **Studio Sync does not reach a running Play session.** Stop Play before expecting a file change to
> take effect — and always stop a Play session you started; leaving one running blocks both sync and the
> Edit datamodel.

## Place settings to decide before anyone can join

Tide shipped `Fully Open` access with social slots enabled and both became findings. Decide these
deliberately:

- Access: who can join, and from where.
- Social slots: on or off.
- `MaxPlayers` — this drives the Arena's 4-6 robot target and the streaming budget together.
- `StreamingEnabled` and its radius/behaviour. **This one is not optional here.**

## Open

| Question | When |
|---|---|
| The place does not exist yet — it needs creating and its id recording | before job 002 |
| `MaxPlayers`: what number makes a 4-6 robot Arena feel contested but not queued? | before the Arena ships |
