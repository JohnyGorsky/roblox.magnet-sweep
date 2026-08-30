# Job #011: The main HUD: Coins, Flow, Scrap, and the mobile safe-area layout

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-30 20:47:07
**Status**: ✅ **Complete** — see [final-summary.md](final-summary.md) and [changelog.md](changelog.md).
One item outstanding: the desktop layout is built but unverified (the Device Emulator has no
scripting API, so it cannot be switched off from here).

## Requirements / goal

Build group 06's HUD half. The magnet is finished and audible, and NOTHING renders any of it: MagnetState already pushes coins, scrap, capacity, full, power, radius, drive, flowTier, flowProgress, flowNeeded, rush, overcharge and cargo over the StatsChanged remote every time one changes, and the only way to see your own Flow today is a dev command. Scope: the main HUD (Coins, Flow, Scrap+Capacity, an upgrade button, a robot/Arena widget), the banner system (one line, all caps, short-lived), number animation (count-up then scale punch), and the mobile safe-area layout MEASURED in the Device Emulator. Out of scope for now: the loading screen and ReplicatedFirst handoff - they are the other half of group 06 and are their own job. HARD CONSTRAINTS. Decision 0012 is mobile-first, so the layout is measured not reasoned about, and the shared mobile skill must be loaded before any layout work: bottom-left belongs to Roblox's DynamicThumbstickFrame which reaches x=266 on a 666-wide canvas, bottom-right belongs to jump, the top bar takes 58px, ViewportSize is about 666x374 and NOT the screenshot pixel size so a hard pixel floor sized against a desktop viewport is a bug. Ask the human before switching Studio into the Device Emulator. Decision 0018 says SCRAP FULL is a signal carried by the magnet's own behaviour - the HUD must REINFORCE that, never replace it, because if the HUD is the only way to know you are full then the magnet has stopped teaching. The client RENDERS StatsChanged and never derives it. Every HUD element must be verified with a screenshot as well as numbers - a rectangle checker cannot see clipped text or a control under a thumb.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** - given the requirement and the repo, never my theory (GROUND-RULES 8)
- [x] **Verified in PLAY**, at the player's camera - nine states, on the phone preset, with screenshots read as images and not only as numbers (GROUND-RULES 7)
- [x] Implementation plan created & agreed - two decisions put through the wizard first
- [x] Implementation completed
- [x] **Proof it works** captured - nine Play screenshots, plus the decision-0018 check with the HUD switched off (`react=177 pull=0`)
- [x] Final summary + changelog written

---

## Read these first (a fresh session has none of this context)

| | |
|---|---|
| The game's state | [docs/HANDOFF.md](../../docs/HANDOFF.md) |
| Mistakes already paid for | [docs/PITFALLS.md](../../docs/PITFALLS.md) — 54 entries |
| Mobile rules | the shared `mobile` skill. **Load it before any layout work** |
| What the HUD renders | `MagnetState.push` in `studio_game/ServerScriptService/MagnetState.luau` |

## The payload that already exists

`StatsChanged` fires on every change with exactly this shape. Do not add to it without a reason;
do not derive any of it on the client.

```lua
{ coins, scrap, capacity, full, power, radius, drive,
  flowTier, flowProgress, flowNeeded, rush, overcharge, cargo }
```

`flowProgress` / `flowNeeded` are already the numerator and denominator of a Flow meter, so the bar
needs no arithmetic of its own. `full` is already computed server-side.

## Dev commands that make this testable

```
dev("scrap.spawn", 250, 14)   -- a dense field to sweep
dev("magnet.stats")           -- what the server thinks your magnet is
dev("magnet.level", "capacity", 60)
dev("magnet.recycle")         -- empty the magnet (stands in for the Workshop bench)
dev("magnet.overcharge", 30)  -- the maximum visual state
dev("quality.set", "Low")     -- pin a tier
dev("audio.bench") or F3      -- the sound bench
```

⚠️ **Studio Sync does not apply edits while Play is running.** Stop Play, let it sync, start
again. This cost real time twice.

⚠️ **`require` inside `execute_luau` builds a SECOND copy of a module with its own state.**
Reading a server module that way measures a blank object, not the running game. Go through the
`DevCommand` remote or read shared Instances.

## What "done" looks like

- A player can see their Coins, Scrap/Capacity and Flow tier without a dev command.
- The layout is **measured** in the Device Emulator, and no element overlaps `DynamicThumbstickFrame`
  or the jump button. Ask before switching Studio into the emulator.
- A **screenshot** of every state, read with actual eyes — not just a rectangle check. Clipped text,
  a control under a thumb, and "reads as an empty box" are all invisible to a numeric audit.
- SCRAP FULL still reads from the magnet's behaviour with the HUD hidden.
- An independent reviewer has been run, given the requirement and not my theory.

