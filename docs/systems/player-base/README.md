# The player base — the Gantry

**Status: NEW**, 2026-09-05. The base is the only personal space in the Workshop; everything else is
shared ([ground rules](../smelter/README.md#why-it-exists)).

## What it is

One structure. A crane arm carries **your robot** above **your smelter**, and the install machinery
and the smelter share a single frame.

```
              ╔═══════════════════╗
              ║  ▄▄  crane arm    ║
              ║  ██  YOUR ROBOT   ║   ← install happens here, in public view
              ╚════════╤══════════╝
   ┌────────┐          │
   │ HOPPER │══ BELT ══╧═▶ ╔═══════╗ ──▶ ▭▭▭
   └────────┘              ║FURNACE║     ingots
```

**Why the gantry and not a separate plinth:** the install sequence in
[robot-assembly](../robot-assembly/README.md) already *requires* a crane — "crane descends → grabs the
old part → KRRRK → detaches". The gantry is not extra machinery invented for looks; it is the machine
the design already called for, doing a second job.

## 🔴 Do not redesign what already exists

`docs/systems/robot-assembly` is thorough and stands as written. In particular:

- **The robot physically stands there.** Installing a part is a sequence, never a menu confirm, and it
  ends with the robot testing the part with one huge practice swing playing that part's real
  `AnimationProfile`.
- **Seven slots** — Head, Core, Body, Left Arm, Right Arm, Mobility, Back.
- **Duplicates** already have two exits: REINFORCE (Mk I → II → III) or RECYCLE for Coins.
- **Robots must look homemade** — asymmetrical, mismatched, funny. "If a build starts looking coherent
  and designed, something has gone wrong."

The gantry changes **where** that happens, not **what** happens.

## Ingots buy Coins. Nothing else. (decided 2026-09-05)

The two tracks stay separate:

```
   scrap ──▶ smelter ──▶ ingots ──▶ Coins ──▶ MAGNET upgrades
   parts ──▶ install  ──▶ REINFORCE/RECYCLE ─▶ ROBOT power
```

⚠️ **Deliberate, and it was the harder call.** Letting ingots upgrade parts would connect scrap to
your robot, which is appealing — but REINFORCE already upgrades parts using duplicates, and the
smelter is defined as the *sell* step. Ingots as a crafting material would blur both at once.

The gantry gives the two tracks a **physical** connection — your robot literally hangs over your
smelter — while the economy stays clean. That is the whole point of choosing this shape.

## 🔴 THE BUDGET FORCES MESHES — measured, not asserted

`Perf.BUDGET.MAX_PARTS_IN_VIEW` is **1,800**. Twelve hand-built bases do not fit, and it is not close:

| | parts |
|---|--:|
| Arena, as built | 692 |
| Smelter rig, machinery only | 194 |
| Gantry, conservative estimate | 55 |
| **One base** | **249** |
| × 12 players | 2,988 |
| + Arena | 692 |
| **Total, before walls, common buildings, signage or scrap** | **3,680** |
| Budget | 1,800 |
| **Over by** | **1,880 — 2.0× the ceiling** |

**A base must therefore be a handful of MESHES, not two hundred primitives.** For scale, the shop
kiosk is **16 parts** and looks better than any primitive assembly in the demo room.

Target: **≤ 8 parts per base** — meshed hopper, belt, furnace, tray, gantry arm, robot plinth, plus a
light or two. Twelve of those is ~96 parts, leaving room for the arena, the walls and the common
buildings inside the ceiling.

⚠️ The primitive rig standing in the demo room at `(910, −420)` is a **prototype for shape and scale**,
not the thing that ships. It did its job: it settled the layout, proved the belt technique, and
produced this number.

## Decided 2026-09-05

### The belt runs while you are in the server — not offline

It keeps smelting while you are out in a zone, and stops when you leave. That preserves the loop the
belt exists for — *go collect while it smelts* — with **no offline economy to balance and nothing to
simulate for absent players.**

⚠️ Stopping is not losing. Rule 4 still holds: scrap left on a belt is there next session. The belt
**pauses**; it does not empty.

### An unclaimed base is dormant — dark and powered down

All twelve stand there always: gantry unlit, belt still, no robot. You can see at a glance which are
free, and the room's shape never changes as people come and go.

🔴 **This only works because a base is meshed.** Twelve dormant bases at the prototype's 249 parts
would cost 2,988 parts of a 1,800 ceiling *for structures nobody is using*. At ≤ 8 parts each it is
~96 parts, and permanently-present bases become affordable. The budget finding above is what makes
this choice possible.

### The bases ring the room, behind the common buildings

```
        ┌─────────────── perimeter wall ───────────────┐
        │   base  base  base  base  base  base         │  ← outer ring: 12 player bases
        │      ┌────────────────────────────┐          │
        │ base │  MAGNET LAB   RECYCLER     │  base    │  ← common buildings
        │      │        ╭──────────╮        │          │
        │ base │        │  ARENA   │        │  base    │  ← centre
        │      │        ╰──────────╯        │          │
        │      │  ROBOT BAY    SHOP         │          │
        │      └────────────────────────────┘          │
        │   base  base  base  base                     │
        └──────────────────────────────────────────────┘
```

Shared space inside, personal space outside. Everyone still sees the Arena from their own base, which
is [decision 0001](../../decisions/0001-one-place-not-two.md)'s requirement.

**Provisional radii**, to be walked before they are trusted:

| Ring | Radius | Note |
|---|--:|---|
| Arena disc | 112 | as built |
| Arena steps + collar | ~118 | as built |
| Common buildings | ~200 | 4–7 stations, room to walk between |
| Player bases | ~300 | 12 bases, ~157 studs of arc each — a base is ~135 long, so it fits |
| Perimeter wall | ~380 | ~760 studs across overall |

### Anyone can walk into your base

Open. A thief has to reach your belt anyway, so a barrier would be arbitrary — and it keeps the
Workshop reading as one shared factory rather than twelve private rooms.
