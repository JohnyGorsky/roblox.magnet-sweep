# MAGNET SWEEP 🧲⚡🤖

**Find it. Pull it. Bring it home. Bolt it on.**

A physics-driven Roblox collection game. You start with a magnet that can barely lift a screw. You end
up dragging an excavator bucket out of a factory while security chases you, so you can bolt it onto a
robot made of a fridge door and a STOP sign and let it fight for the Arena while you go back for more.

> 🧲 Find it → ⚡ Pull it → 🚨 Escape with it → 🔩 Bolt it on → 🤖 Release it →
> ⚔️ Fight for the Arena → 🔧 Repair it with scrap → 🚪 Go deeper

## This repo

Design memory and production planning. **Roblox Studio is the authority on what actually exists** —
this repo is the authority on what it *should* be, and why.

| Path | What it holds |
|---|---|
| [`docs/`](docs/) | The design pack. Start at [`docs/INDEX.md`](docs/INDEX.md) |
| [`docs/build/`](docs/build/README.md) | The task manifest — everything that must be made, sized one at a time |
| [`docs/PITFALLS.md`](docs/PITFALLS.md) | Mistakes already paid for on the other games in this workspace |
| `Jobs/` | Worked jobs: `intake` → `implementation-plan` → `final-summary` + `changelog` |
| `Planned/` | Queued ideas, one file each. Promoting one = opening a job |
| `todo/` · `findings/` | Fast capture queues: small tasks, and deferred bugs |
| `studio_game/` | The Studio Sync root. **One place.** Empty until the sync probe job |
| `assets/MAGNET SWEEP.md` | The original 87-section specification. Read-only history |
| `assets/concept_art/` | The key art. Read-only history |
| `assets/registry/` | What this game uses and what it still needs |

## One place, not two

The Arena is **persistent per server** and must be visible and audible from the Workshop while robots
fight in it, and it must notify you while you are deep in the factory. Splitting lobby from game turns
the signature feature into a cross-server messaging problem. So: **one place**, with Instance Streaming
carrying the long factory corridor. See
[decision 0001](docs/decisions/0001-one-place-not-two.md).

`studio_lobby/` is kept as an empty stub only so the split stays cheap if streaming ever forces it.

## Working here

Every change is a **job**. Scaffold from the workspace root:

```
python tools/job.py new --project magnet-sweep "Title" "Requirements"
```

## Status

**No game exists yet.** No place, no code, no assets. See
[`docs/HANDOFF.md`](docs/HANDOFF.md) for exactly where things stand and what needs you.
