# Assets

| Folder | What it holds |
|---|---|
| `concept_art/` | **Read-only history.** The signed key art. Never edit these |
| `registry/` | What this game needs and what it uses, with ids, source and licence |
| `meshy/` | Meshy prompts and import notes. Binary exports are gitignored — the published id is what we keep |
| `references/` | Look references gathered while building |
| `sounds/` | Audition notes and sourcing specs. Not audio files |

`MAGNET SWEEP.md` at this level is the **original 87-section specification**. It is read-only history;
[`docs/`](../docs/INDEX.md) is the living version, and [spec coverage](../docs/build/spec-coverage.md)
maps every section to where it landed.

## Concept art

| File | What it shows | Used for |
|---|---|---|
| `Arena.png` | the Workshop hub — Magnet Lab, Recycler, Robot Bay, Scrap Arena, neon signage | the hub layout and the whole signage language |
| `Robot.png` | the pull moment — magnet, arcs, Giant Spoon, Chef Security bot, Mega Kitchen | magnet VFX, the tier-3 theme, the electric-arc look |
| `Robot2.png` | the Robot Bay — a robot of car door + spoon + STOP sign on a turntable | robot visual philosophy, the install sequence |
| `Robot3.png` | arena key art — two robots, the Arena Core | close to launch **thumbnail 4** |
| `Logo.png` | the title treatment, red MAGNET / cyan SWEEP | the logo, the palette anchor |
| `Logo2.png` | "PULL GIANT PARTS!" key art | close to launch **thumbnail 1** |
| `Logo3.png` | "HOLD THE ARENA!" key art | close to launch **thumbnail 4** |

> ⚠️ **Mockups are direction, not spec.** These set colour, mood and material feel. They are not a
> feature list, and nothing in them may be reported as existing
> ([PITFALLS #26](../docs/PITFALLS.md#26-mockups-are-direction-not-spec)).

## The sourcing rule

Per `roblox.workspace/GROUND-RULES.md` §4, the order is fixed and Claude does not skip to step 4:

1. **Claude searches first** — our registry, the shared workspace registry, then the Creator Store.
2. **Claude writes the spec** — the slot it fills, how it is driven at runtime, length/loop/format, and
   **what it must NOT contain**.
3. **Claude suggests how to search** — exact terms, source, acceptance criteria.
4. **The human finds and supplies the id.**
5. **Claude wires it in, scans it for scripts, and logs it here and in the shared registry.**

Requests are presented as a **table** — one asset per row: Type · Name · How to search.

> **Leave the slot empty rather than filling it with a placeholder.** Empty slots must announce
> themselves.

## Security

Every inserted model is scanned for `LuaSourceContainer` descendants **in isolation**, and anything
Claude did not author is deleted, **before Play**.
