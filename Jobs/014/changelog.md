# Changelog — Job #014

*The game has an opening. You no longer drop straight into a half-built room.*

- 🧲 **A proper loading screen.** Roblox's default one is gone the instant the game starts, replaced
  with **MAGNET SWEEP** and *Find it. Pull it. Bolt it on.*
- 🔩 **Four objects fly into the magnet as it loads** — bolt, gear, coin, magnet — one for each thing
  the game is actually waiting on. Each lands with a *tik*; the last one lands with a **CLANG** and
  the screen clears.
- ⏳ **The bar tells the truth.** It moves when something real finishes, not on a timer. If the world
  is slow it says so and **waits** rather than dropping you into an empty room.
- 🪧 **A first-time player gets exactly one hint: MOVE NEAR SCRAP.** It appears only if there is scrap
  around and you have not swept yet, and it disappears the moment you do. That is the whole tutorial.

**Under the hood:** the screen waits for your profile, for the world to stream, and — the one that
actually takes time — for there to be *ground under your feet* before it lets go.
