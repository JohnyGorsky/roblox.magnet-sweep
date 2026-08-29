# Job #001 — implementation plan

**Project:** `roblox.magnet-sweep`
**Status:** agreed and executed (the four blocking decisions were answered at intake via the wizard)

## What was asked

> "I created new game roblox.magnet-sweep. Read MAGNET SWEEP.md + see concept art. Then order folders
> like we did in jungle game. Understand game and if needed ask questions. Game must be colourful, also
> lets use some shaders so it looks like concept art — metal glossy."

Plus, mid-session: *"what roblox mechanics we can use to build robot, animate it?"* — answered by the
user with a full proposed architecture, which this job folds into the pack.

## Current state before this job

- Repo existed with **zero commits**. Only `assets/` (the 87-section spec + 7 concept art files) and
  two empty folders, `studio_game/` and `studio_lobby/`.
- ⚠️ The user then committed `cf6a90a "Initial commit"` **mid-job**, capturing part of the work in
  flight. Anything written after that point is still uncommitted.
- `roblox.magnet-sweep` was already added to `roblox.workspace.code-workspace` by the user.
- Not registered in `roblox.workspace/tools/job.py`.
- No place exists in Roblox Studio. Nothing to inspect over MCP.

## Blocking questions, asked via the wizard before any writing

Four, because each changes the structure materially. All four came back as the recommended option.

| # | Question | Answer | Recorded as |
|---|---|---|---|
| 1 | One place or two? The repo had `studio_lobby/`, but §8 wants the Arena visible from the Workshop and §51 wants it notifying mid-factory | **One place** | [decision 0001](../../docs/decisions/0001-one-place-not-two.md) |
| 2 | Scope of this pass | **Full design pack**, ELEVATOR 13 style | this job |
| 3 | How hard to push the glossy look, given Roblox has no shaders | **Hybrid** — PBR kit + Future lighting + post-FX, hero meshes only | [style skill](../../.claude/skills/magnet-sweep-style/SKILL.md) |
| 4 | Platform budget | **Mobile-first, PC gets more** | [decision 0012](../../docs/decisions/0012-mobile-first-quality-tiers.md) |

## The one place where the brief and the spec disagreed

The user asked to "order folders like we did in jungle game". Jungle uses a **nested** `sync/` root with
`Jobs/`, `Planned/`, `findings/`, `todo/`, `tools/`, `assets/` and a game doc at the root.

The repo already had `studio_game/` + `studio_lobby/`, which is the **newer** Tide / ELEVATOR 13 shape,
and Jungle's own `jungle-project` skill is referenced by its `CLAUDE.md` but does not exist on disk.

**Resolved as:** Jungle's *convention* (the capture queues, the job lifecycle, the per-game project
skill, `Planned/`), on the *newer* `studio_*` sync-root layout the repo was already set up for. Noted
here rather than silently chosen.

## Approach

1. Register `magnet-sweep` in `roblox.workspace/tools/job.py` and scaffold this job.
2. Read the spec end to end and all seven concept art files. Extract every table verbatim.
3. Redistribute into a living `docs/` pack; leave `assets/MAGNET SWEEP.md` untouched as history.
4. Write the two skills, because in this multi-root workspace **only the workspace `CLAUDE.md` loads** —
   per-game context has to be a skill or it is invisible.
5. Write decision records for anything load-bearing, so it cannot be silently overturned.
6. Generate the manifest and the coverage table **with scripts**, so counts are computed and re-runnable
   rather than typed.
7. Run an independent reviewer that is not told the reasoning.

## Config values introduced

None. No code was written. Every number in `docs/` is either the spec's or explicitly marked
**(derived)**.

## What this needs from the human

| # | What | Why |
|---|---|---|
| 1 | Commit this job | Claude never commits. `cf6a90a` captured part of it mid-session; the rest is uncommitted |
| 2 | Create the MAGNET SWEEP place, supply its id | Cannot be done over MCP |
| 3 | Studio open on it | The sync probe (job 002) has no connectivity otherwise |
| 4 | Decide place settings, incl. `StreamingEnabled` | Load-bearing for a one-place game with a 12-zone corridor |

## Risks

- **The sync layout is guessed.** Marked `UNVERIFIED` in `.jobconfig.json` and owned by job 002. Tide
  was burned assuming; ELEVATOR 13 inherited the same guess. This is the third chance to get it right.
- **The pack could be fiction.** A 90-file design pack written in one pass is exactly the artefact that
  invents numbers and claims coverage by link. Mitigated by generating the counts, marking derived
  values, and the reviewer pass — not by care alone.
- **No verification in Play is possible**, because there is no place, no code and nothing to play. The
  intake checklist's "reproduce in Play" step is **not applicable** to a docs-only job and is marked so
  rather than ticked.
