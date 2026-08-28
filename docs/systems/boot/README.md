# Boot & loading

Build this early, not at the end. It is the first thing every player sees and it is where the game's
tone is set — and a loading screen retrofitted over a running game always fights the systems it wraps.

## The loading screen (section 7)

It should already feel interactive. Show: the player, a glowing magnet, scrap flying, a robot in the
background, and a factory corridor continuing into the distance.

**Progress is represented by objects flying into the magnet:**

```
🔩 → ⚙️ → 🪙 → 🧲
```

Each object arriving: **tik**. Loading complete: **CLANG**.

Then:

```
        MAGNET SWEEP
Find it. Pull it. Bolt it on.
```

That is the whole screen. No tips carousel, no lore.

## Stages

| Stage | What happens |
|---|---|
| **1 · Hold** | `ReplicatedFirst` removes the default loading screen and shows ours immediately |
| **2 · Load** | profile fetched, config replicated, cosmetics resolved, the robot's configuration read |
| **3 · Place** | the player is positioned in the Workshop, the world around them streamed in |
| **4 · Release** | the screen clears on **CLANG**, controls enable |

The progress bar is driven by **real** stage completion, not a timer. A fake progress bar that finishes
before the world does produces a player standing in an empty room, which is worse than a longer wait.

## First-time player (section 9)

No tutorial. The teaching is environmental:

1. The player spawns with the Starter Magnet (Power 10 · Radius 12 · Drive 16 · Capacity 30).
2. Nearby screws begin **shaking** as they approach. That is the entire first lesson.
3. A small prompt: **MOVE NEAR SCRAP**.
4. Scrap flies in — *tik tik tik*.
5. After several items: **MAGNET FLOW x2**.
6. Then **SCRAP FULL**, and an arrow points at the Recycler.
7. Coin explosion. The player buys their first Magnet Power upgrade.

The loop is now understood, and nobody read anything.

## Failure paths

- **Profile load fails:** show it, do not proceed into gameplay, and **never write defaults over it**
  ([save-data](../save-data/README.md)).
- **Streaming is slow:** hold at stage 3 rather than dropping the player into a void.
- **The player joins during a Factory Refresh:** land them in the Workshop regardless. Never spawn into
  a zone mid-retract.
