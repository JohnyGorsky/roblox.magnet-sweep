# Implementation Plan — Job #019

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31
**Status**: Planning — awaiting go-ahead on the look

Reference: [`assets/concept_art/MapConcept.png`](../../assets/concept_art/MapConcept.png) plus the
owner's sketch. Two corrections to the art, from the owner: **one run lane, not four**, and **twelve
bases, not four**.

---

## How it will look

A **ring of twelve base pockets** around a **central Arena**, with **one run lane** leaving the ring
and becoming the factory corridor.

```
                    base 12   base 1    base 2
                        ╲        │        ╱
              base 11 ──┐   ┌────────┐   ┌── base 3
                        │   │ ARENA  │   │
              base 10 ──┤   │  core  │   ├── base 4          ══════════▶
                        │   └────────┘   │                    RUN LANE
               base 9 ──┘   ┌────────┐   └── base 5          (to zone 1)
                        ╱        │        ╲
                    base 8    base 7    base 6
```

**Sized, not sketched.** Twelve pockets 48 studs wide sit on a ring of radius **92 studs** — a hub
**183 studs across**, against the current Workshop's 104. Big enough that a base feels like yours,
small enough that you can read the whole ring from the middle.

### One base

A walled pocket open toward the Arena, so you look *out* at the centre and *across* at your
neighbours. Inside, in the concept's own arrangement:

| Fixture | What it is |
|---|---|
| **Magnet Lab** | your upgrade terminal — already built, job 011's panel |
| **Recycler** | your scrap → Coins — already built, job 013 |
| **Robot Bay** | your robot, group 09's contract. Stands and says so until then |
| **Staging Pad** | the disc in the concept: where your robot deploys from, and where a stolen part lands |

🔴 **Stations become PER-PLAYER.** Today seven stations are shared furniture in one hall. In the ring
each base owns its own three — which is what makes the whole layout mean anything, and what makes
"steal from another base" possible later without inventing new machinery.

### Colour: the ring is the player list

The concept gives each base a solid identity colour — red, blue, green, yellow. Twelve bases need
twelve, and **style §2 forbids using a reserved signal colour** for identity, so the palette comes
from the twelve **zone accent** rows, which are already checked against the reserved set.

⚠️ That is a real decision, not a detail: your base colour is how you find your own base at a glance
across a 183-stud ring, and it must never collide with recycler green or alarm red.

### The Arena

A raised disc in the middle with the **red-and-cyan horseshoe magnet** standing on it — exactly the
concept's centrepiece.

## Assets: what I will use, and what I will not generate

**No new Meshy spend. Nothing needs generating.**

| Thing | Source |
|---|---|
| The Arena centrepiece | 🔴 **The magnet mesh we already own** (`117205352084553`), scaled up. The concept's centrepiece *is* a red/blue horseshoe magnet, and job 016 built exactly that from the game's own key art |
| Base walls, floors, machines, conveyors, crates, gantries, signage | The 26-piece kit — the concept's shapes are all kit shapes |
| Base identity colour | `MaterialKit` tinting of white body panels, the mechanism job 017's review corrected |
| The surrounding factory clutter | Shared scenery, **built once outside the ring**, not twelve copies. That is where the concept's richness actually lives |

⚠️ I costed a Meshy pass for base fixtures and it is not worth it: twelve copies of a mesh is twelve
copies of a texture fetch, the Low quality tier drops `SurfaceAppearance` entirely, and a `MeshPart`
cannot be tinted per-base the way a kit panel can. Meshes stay for hero objects — the Arena core, and
later the guardians and robot parts.

## The budget — and a correction

I told the owner twelve bases would blow the part budget. **That was wrong.** Costed against the
kit's actual part counts rather than a guess:

| | Parts |
|---|--:|
| One base (25 floor + 14 wall + 2 lamps + pad + 3 crates + 3 stations) | **104** |
| Twelve bases | 1,248 |
| Arena ring and core | ~60 |
| **Total in view** | **≈1,308** of the 1,800 budget (73 %) |

It fits, with 490 parts of headroom. My error was estimating 200 parts a base; a base is 104 because
the kit's floor and wall pieces are one part each.

🔴 **That headroom is the whole margin, though.** The surrounding clutter has to be shared scenery and
the Arena has to stay simple. Twelve bases *plus* a rich Arena *plus* per-base clutter would exceed
it, and this number gets re-measured in Play rather than trusted.

## What survives, and what goes

**Survives:** the twelve-zone corridor, the gates, Zone 1, `ZoneManager`, `ZoneBuilder`, `ZoneSpec`,
the kit, `MaterialKit`, the magnet, the boot screen, the HUD.

**Goes:** `WorkshopSpec`'s 13×13 hall and its seven shared stations.

⚠️ **`WorkshopSpec.ARENA_ANCHOR` and the sightline check go with it** — and that is not a loss.
Decision 0001's whole argument was *"the Arena must be visible from the Workshop"*, which needed a
56-stud aperture and a sampled sightline to be true of 56 % of the floor. In the ring the Arena is in
the **middle**, visible from everywhere by construction. The new layout satisfies decision 0001 more
completely than the thing built to satisfy it.

## Steps

1. `HubSpec` — the ring as data: radius, twelve base slots, the run-lane bearing, the Arena. Same
   data-in-git shape as `Zone1Spec`, finished by `ZoneSpec` where the helpers fit.
2. `BaseSpec` — one base pocket, instanced twelve times with a slot index and an identity colour.
3. `HubBuilder` — replaces `WorkshopBuilder`. Builds the ring, the Arena, and the run-lane mouth.
4. Per-player station ownership: a base is **claimed** on join and released on leave; prompts answer
   only to their owner. `StationService` currently keys on station id alone.
5. The run-lane mouth connects to `Zone1Spec`'s entry, replacing the Factory Entrance station.
6. Verify in Play: parts measured, ring visible from the centre, every base reachable, the walls meet
   the floors (the check that caught job 017's trench).
7. Independent reviewer.

## What I need from you

- [ ] **Go-ahead on the look above** before I build it — this replaces the hub, and rebuilding it
      twice is the expensive way to find out.
- [ ] **How many bases at once?** Twelve fits the budget and matches `MaxPlayers`. Fewer, larger bases
      would look closer to the concept art, which has four.
- [ ] Nothing to buy. **No Meshy credits.**

## Checks that must be able to fail

- **Part count measured in Play**, not estimated — the 1,308 above is arithmetic, not evidence.
- **Every base is visible from the Arena centre** — sampled, the way job 012 sampled its sightline,
  because "you can see each other" is the entire premise.
- **Walls meet floors** on a base pocket — job 017 shipped a 3.5-stud trench and the check that
  should have caught it measured wall centres instead of faces.
- **A base's prompts refuse a player who does not own it**, tested from a second player's position.
- **Twelve identity colours, none reserved** — asserted, not eyeballed.
