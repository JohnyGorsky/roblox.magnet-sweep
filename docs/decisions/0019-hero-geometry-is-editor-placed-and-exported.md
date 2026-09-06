# 0019 — Hero geometry is editor-placed, then exported

**Status:** Accepted · 2026-09-06 · Job 020

## Context

[Decision 0017](0017-the-kit-is-generated-from-a-spec.md) settled that **the kit is data**, and its
reasoning was general: `Workspace` and `ServerStorage` do not sync, so geometry built by hand in
Studio exists only inside the unversioned `.rbxl` — it cannot be diffed, cannot be reviewed, cannot
be regenerated after a material change, and is lost with the file.

[`WorkshopSpec`](../../studio_game/ReplicatedStorage/Workshop/WorkshopSpec.luau) extended that
reasoning from the kit to the *room the kit builds*, in as many words:

> ⚠️ This deliberately DIVERGES from how Jungle's lobby is built, where objects are hand-placed and
> scripts find them by name. That is right there and wrong here, and the reason is the sync layout
> rather than taste.

**During job 019 the owner reversed this**, on seeing the generated ring:
*"all crowded no rooms"*, *"whole idea whole concept whole your builtlook is totally wrong"*. Five
ground rules followed, the first being **build everything in the editor, so it can be moved**.
`BUILD_GENERATED_WORLD` was set to `false` and `HubBuilder` / `HubSpec` / `WorkshopBuilder` were
switched off.

That reversal was recorded in [`docs/systems/player-base`](../systems/player-base/README.md) but **no
decision record was written**, which [the index](INDEX.md) forbids. This record is that correction,
written before job 020 places a 925-stud room by hand and makes the divergence permanent.

## Decision

**Split the rule by what the geometry is for.**

| Kind | How it is built | Why |
|---|---|---|
| **The kit** — repeated modular pieces | **Generated from a spec.** 0017 stands, unchanged | Proportions are reviewable as numbers; a palette change is one call |
| **Zones** — 12 procedurally varied factory floors | **Generated** from `ZoneSpec` | They must re-roll; a hand-built zone cannot refresh ([0006](0006-the-factory-refreshes.md)) |
| **Hero rooms** — the Workshop, the Arena, the Demo Room | **Placed in the editor** | They are composed by eye, once, and never re-roll |

**And the cost 0017 named is paid off rather than accepted: a placed room is EXPORTED back to a data
file in git.** The room is authored by eye; the export is what makes it diffable, reviewable and
rebuildable. The `.rbxl` stops being the only copy.

This is not a new mechanism. Job 019 already did exactly this for the sixteen robot part mounts:
hand-posed by the owner in Studio, then exported to
[`Config/PartMounts.luau`](../../studio_game/ReplicatedStorage/Config/PartMounts.luau). The precedent
is established and the owner has already accepted its shape.

## Consequences

**Good**

- Composition by eye. The failure that killed job 019's ring was *proportion*, and proportion is the
  thing a spec file is worst at and a viewport is best at.
- Objects can be nudged. 0017's "a part nudged in Studio is overwritten on the next build" was the
  specific friction the owner hit.
- The export keeps 0017's actual benefit — a reviewable diff — without keeping its constraint.

**Costs, accepted**

- 🔴 **The export must actually be written and actually be run**, or this record is just permission to
  lose the room. An unexported placed room is strictly worse than a generated one. Until the exporter
  exists, the `.rbxl` is the only copy and that is a live risk, not a theoretical one.
- The export is a snapshot, not a source. Editing the exported file does not move anything; it
  reproduces the room if the file is lost. The direction of truth is Studio → git, the opposite of
  the kit.
- Two mental models now coexist. `WorkshopSpec` and `HubSpec` describe a room that no longer exists
  and must be deleted rather than left to mislead.

## What this does NOT change

- **0017 stands for the kit.** `KitSpec` / `KitBuilder` are untouched.
- **The 4-stud grid still applies to kit pieces.** It never governed meshes, and the job-019 meshes
  and the 60.5-stud wall patterns are not on it — see
  [finding 0004](../../findings/0004-wall-height-and-tile-size-are-off-the-00.md).
- **Zones stay generated.** [0006](0006-the-factory-refreshes.md) requires it.
