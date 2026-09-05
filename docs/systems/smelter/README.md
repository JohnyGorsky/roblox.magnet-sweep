# Smelter — the one thing a player owns

**Status: NEW.** Introduced by the owner's ground rules, 2026-09-05. It appears nowhere in the
original spec — a repo-wide search for *smelt*, *furnace* and *melt* returned **zero hits** before
this file. Everything here is a first design, not a transcription, and is `[UNTUNED]` accordingly.

## Why it exists

The owner's ground rules made the Workshop **shared** — upgrade buildings, shops and the Arena belong
to everyone. That removed private bases, and with them the only thing a player could call theirs.

> "you only have where to melt iron"

The smelter is that one personal thing.

## The shape of it — hopper, belt, furnace, tray

```
   ┌────────┐                                    ╔═════════╗
   │ HOPPER │═══════ CONVEYOR ═══════════▶       ║ FURNACE ║ ──▶ ▭▭▭ ──▶ carry to shop
   └────────┘  scrap crawls toward the heat      ╚═════════╝    ingots      → Coins
   drop here                                                    stack up
```

**Ingots are physical objects you carry.** Decided 2026-09-05. They stack visibly on the tray, you
pick them up, and you walk them to the shop to sell.

That keeps the game's own rule — *parts exist physically, there are no loot boxes* — and it means a
full tray is legible from across the room without any UI. The cost is a carry step between tray and
shop, which is deliberate: it is the moment your smelter has actually paid out.

⚠️ **It is cast steel, not gold.** You melt scrap iron; a gold bar would be lying about what the
machine does. The model is a trapezoidal cast bar with residual heat still glowing in its seams
(`assets/generated/smelter/ingot.glb`, 4,337 tris).

**The belt IS the timer.** Scrap does not vanish into a machine and reappear as a number — you watch
your own haul crawl toward the furnace. Same mechanic as a progress bar, but it happens in the world.

Three things fall out of that, and they are why this shape was chosen over a plain machine:

1. **"Full" explains itself.** When the furnace cannot keep up, items back up along the belt. A jammed
   belt reads as *go sell* from fifty studs away — no UI needed. This answers rule 3 below without a
   single GUI element.
2. **The upgrade is visible.** Belt speed and belt length *are* the throughput. A player who upgrades
   watches their belt run faster. That beats a number rising in a menu.
3. 🔴 **The hopper is at the FAR end, and it is the only legal drop point.** If a player can drop
   directly onto the belt they will drop next to the furnace mouth and skip the queue — the wait
   becomes optional and the whole design collapses.

## Stealing — the owner's call, 2026-09-05

**Scrap in transit on the belt can be taken by any player.** This was chosen deliberately over a
private smelter.

⚠️ **The risk was raised and accepted:** the smelter is the *sell* step, not a bonus, so a stolen haul
is real progress lost, and that is the kind of thing players quit over. Recorded here so the decision
is visible, not re-argued.

Three levers keep the hook while blunting the worst case. **None is decided yet:**

- **Only the belt is stealable.** The intake hopper and the finished output tray stay safe, so a
  player can bank progress by getting scrap *past* the belt.
- **A steal takes a second or two**, so the owner can contest it rather than losing a haul to someone
  running past.
- **Theft is loud** — the victim is told, and can see who.

## 🔴 What it is NOT

**It is not the Recycler.** They are easy to confuse and must never overlap:

| | Smelter | Recycler |
|---|---|---|
| Owned by | **one player** | everyone (common) |
| Eats | **ordinary scrap** (the 12 types) | **duplicate rare PARTS** |
| Produces | ingots → Coins | Coins directly (400 → 150,000 by grade) |
| Speed | takes time; the belt is the wait | instant |
| Where | the Workshop, one per player | the Workshop **and** every Service Hub |

If the smelter ever consumed parts, or the Recycler ever consumed scrap, one of them is redundant.
That line is the whole design.

## How the belt moves things — MEASURED, not assumed

Both techniques were built as identical rigs in the demo room and tested in Play on 2026-09-05.

| | Physics conveyor | Animated slide |
|---|---|---|
| 60 items, dense | 0 rode, 60 jammed | **60 rode** |
| 12 items, spaced 5 studs, no intervention | **0 rode, 12 stuck, 0 awake** | — |
| 60 items, kept awake by force (366 frames) | **0 rode** | — |
| Travel accuracy | 0.0 of 40 studs | **48.3 of 48 studs** |

✅ **Use the animated slide.** Items are anchored, non-collidable, and moved by script.

🔴 **The physics conveyor moved nothing, in any configuration tried.** An anchored part *does* hold a
non-zero `AssemblyLinearVelocity` (verified — it reads back, and the legacy `.Velocity` alias sets the
same field), but items resting on it **settle and sleep** and are never pushed. Forcing them awake and
writing velocity every frame for 366 frames still produced zero travel.

⚠️ **Two false readings on the way, recorded so nobody repeats them:**
- The first run reported "0 moving" because the test **zeroed the belt velocity before counting**.
  The belt was fine; the measurement was not.
- Frame-time comparison was **worthless**: vsync pins Heartbeat near 16.7 ms, so 40 items showed no
  cost and the *baseline* came out slower than the loaded run. Measure behaviour and physics step
  time, never mean frame time, on a vsync-locked client.

## The rules that matter

1. **It takes time.** Instant smelting makes it a vending machine, not a possession.
2. **Claimed on join, released on leave.** Smelters are hand-placed in the editor; a script finds them
   by name and assigns one. No generated geometry.
3. **A full smelter is obvious from across the room** — solved by the belt backing up.
4. **Nothing is lost while offline.** Losing a deposit to a disconnect is a quit-the-game event.

## Still open — deliberately not answered

- Smelt **rate**, belt **speed** and **length**, and how upgrades move them. `[UNTUNED]`
- **Ingot value per scrap unit**, against [economy](../economy/README.md)'s rule that the first magnet
  upgrade be affordable within ~2 minutes of first play.
- Which of the three **anti-grief levers** above are in.
- What happens when the belt is **completely** backed up — refuse new scrap, or overflow to a buffer?

### Leaning, not decided — pickup by proximity

Owner, 2026-09-05: *"maybe you just approach and it just picked up."*

⚠️ **A leaning, recorded so it is not lost. Not a decision.**

Worth noting *why* it is attractive: the player already owns a magnet, and pulling loose metal toward
yourself is the game's core verb. Making the tray work that way means the smelter is used with the
same action as everything else — no prompt, no button, no new verb to teach. Walk near, and the
ingots come to you exactly as scrap does in a zone.

It also collapses two of the questions below into one: if pickup is a magnet pull, an ingot is simply
**cargo**, and cargo already has rules for weight class and speed penalty.

### Opened by the ingot decision

- **Does carrying an ingot slow you down?** `Magnet.CARGO_SPEED_PENALTY` already exists for rare parts
  (Small −5% … Extreme −45%, floor 9 studs/s). Reusing it for ingots is free and consistent — but it
  makes the last twenty studs of the loop a slog, and unlike a rare part there is no thrill in it.
- **Can an ingot be stolen in transit?** The tray is safe by design, but the walk from tray to shop is
  not covered by that. With stealable belts already in, this needs an explicit answer or it will be
  decided by accident.
- **How many can you carry at once?** A stack size caps how much one trip banks, which is really a
  second throughput dial sitting next to belt speed. Two dials for one thing is usually one too many.
- **Where exactly do you sell them** — the Shop Kiosk, or a dedicated window on the smelter itself?

## What the model needs

- **A hopper mouth** at the far end, open and obvious — the only drop point.
- **A belt** with visible rollers, long enough to read as a queue.
- **A furnace** with a lit mouth: warm amber, since Magnet Lab owns cyan, Recycler green and Robot Bay
  orange — and heat reads warm anyway.
- **An output tray** where ingots stack, visible from a distance.
- **A name plate** — the dark rounded plate with a thin light border used by every station in
  `MapConcept.png`.
- Chamfered corners, riveted steel, chipped yellow hazard trim at the base
  ([wall research](../../../Jobs/019/wall-research.md)).
