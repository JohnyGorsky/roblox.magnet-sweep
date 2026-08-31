# Implementation Plan — Job #018

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31
**Status**: Planning

## What exists, checked before building

Job 017's lesson was that eight of group 07's items were already built. Checked again:

| Thing | State |
|---|---|
| Zone 2's scrap set ×5 | 🔴 **Does not exist.** All eight `ScrapSpec` types are tier 1. Five real items |
| `Config/Zones` tier 2 | ✅ Exists — `TOY_ASSEMBLY`, gate 20, Wind-Up Security Bot, `hubAfter = true` |
| `ZoneBuilder` / `ZoneManager` | ✅ Take any spec of `Zone1Spec`'s shape |
| The Magnet Power gate | ✅ Written by job 017's review — and **never once executed**, because tier 2 did not exist |

## The blocker nobody has hit yet

`ScrapSpec` hardcodes `ScrapSpec.TIER1` in **five** places — `pick`, `byId`, `heaviest` and two loops.
Nothing can hold tier-2 scrap until that becomes a per-tier lookup.

So the order is forced: **scrap first, then zone 2, then the gate.** Building the zone before the
scrap would mean building a room that cannot contain anything.

⚠️ `SPRING` already exists at tier 1, and tier 2's list names springs too. Reuse it rather than
writing a second Spring — a duplicate id is the "second source of truth" failure this repo keeps
finding. Four new types plus the shared spring.

## The gate

`docs/systems/factory` specifies the behaviour exactly, and it is not a button:

> Required: 150 · Current: 137 → *(at 150)* → GRRRRR … the pin moves … BOOM … the gate opens

Three parts: a requirement readout **on the gate itself**, a physical mechanism the player pulls, and
the sequence. It stands at `Zone1Spec.exitWorld()` — the contract job 017 left, never a hand-written
coordinate.

🔴 **The pull is a claim, not a fact.** It happens on the client, so the server re-checks Magnet
Power before opening — the same lesson `RequestRecycle` and `RequestEnterZone` both cost.

## Steps

1. `ScrapSpec`: `BY_TIER` lookup, `TIER2` with four new types, `pick(rng, tier)`. Keep `TIER1`
   working so nothing else breaks.
2. `Zone2Spec` — Toy Assembly. Cobalt `#2F6BE8` · lime `#8FD63F` · coral `#FF8A6B`, none of which may
   be a reserved signal colour; `validate()` already checks that.
3. Register zone 2, place it beyond zone 1's exit, verify `ZoneManager` handles two zones — including
   the overlap warning job 017's review added, which has also never fired.
4. The gate: readout, mechanism, sequence, server-side power check.
5. **Arm and test the power gate.** With Magnet Power below 20, entering zone 2 must be refused with
   both numbers. This is the check job 017 could not run.
6. Verify in Play. Independent reviewer.

## What I need from you

- Nothing to buy or import. Kit pieces, code, and the existing sound families.
- ⚠️ The gate value 20 is a §62 balancing target the docs say must be playtested. Not tuned here.

## Checks that must be able to fail

- **Two zones register without overlapping** — the warning added in 017 fires if they do.
- **The power gate refuses** below 20 and states both numbers. Never exercised before this job.
- **Tier-2 scrap spawns in zone 2 and tier-1 does not** — a shared pool that ignores tier would look
  identical until someone read the ids.
- **The gate stands at `exitWorld()`**, measured, not assumed.
- **No zone resolves another by `Workspace` path** — grep, as in 017.
- **The walls meet the floor** — the same measurement that caught 017's trench, run on zone 2.
