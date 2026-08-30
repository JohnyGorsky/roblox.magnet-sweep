# Job #008 — final summary

**Project**: `roblox.magnet-sweep`
**Status**: complete
**Scope**: the non-asset half of build group 04 — Flow, MAGNET RUSH, Capacity, SCRAP FULL,
Magnetic Drive, and the four stats read from config instead of hardcoded.

VFX states and the nine sound families are deliberately NOT here: they need asset ids from a
human first, and inventing them would be fabricating a registry.

## What shipped

`ServerScriptService/MagnetState.luau` — one place that owns what a player's magnet currently
is and is doing: four stats derived from upgrade levels, scrap carried, Flow, Rush, cargo, and
the Drive written onto the character. Server-side, because a client that could author its own
Radius or Capacity could author its own income (decisions 0002, 0007).

⚠️ It is required **by** `ScrapService` and must never require it back. The claim path runs the
other way: Bootstrap takes what `ScrapService` granted and hands it here.

## Measured in Play

| | reading |
|---|---|
| Capacity → SCRAP FULL | `scrap=30/30 SCRAP FULL`, and `PULL=0 REACT=225` — full stops the **pull**, not the react |
| MAGNET RUSH | fires once, `activeRadius 12.0 → 19.2` for 8.6s, then back to 12.0 — one rush in 22s |
| Flow decay | holds 3.0s, then 1.5 pickups/s; tiers step 3→2→1→0 exactly at multiples of 8 |
| Magnetic Drive | level 0 → 16.0 · level 20 → 24.0 · level 50 → 36.0, all on the live Humanoid |
| Drive after a respawn | **36.0**, not the engine's 16.0 default |
| Cargo (Extreme) | 24.0 → 13.2, matching `Magnet.carrySpeed` exactly |
| Job 007 regression | 249 asked, **249 granted**, 0.0% turned away, unanchored 0, parts 400/400 |

## Three defects found by running it

**A full magnet spun the claim loop.** Objects already in flight kept arriving at a magnet with
no room, were refused, restored by the client, and arrived again — 329 of 355 claims refused,
**93% rejection**, a remote fired four times a second for as long as the player stood there. A
full magnet now *drops* what it is carrying in, and the client stops claiming. Measured after:
**asked=0** over four seconds in the same field.

**Flow kept building during a Rush**, so it came out the far side still at tier 5 and re-triggered
on the very next pickup — one dense field would have been a permanent Rush. Flow is now frozen
during a Rush.

**Flow was uncapped**, reaching 101 against a trigger of 40; at 1.5/s that is 67 seconds to lose.
A combo you cannot lose is not a combo. Clamped to the trigger threshold, with one named constant
for both.

## One I nearly reported wrong

I first measured Rush expiry and Flow decay by `require`-ing `MagnetState` from `execute_luau`.
That builds a **second copy of the module with its own state**, so I was reading a blank entry
and would have reported "rush expired correctly" from a rush that never existed in that copy.
Re-measured through the `DevCommand` remote, which reaches the real module. (The Drive numbers
from that run were still valid — `WalkSpeed` is a property of a shared Instance.)

## Also fixed

- The client hardcoded `Magnet.START.Power` while the server's travel gate judged its arrivals
  against the player's real Power. Invisible only because no upgrade existed yet; the first
  Power upgrade would have made the client drive too slowly for its own claims. It now takes
  Power from `StatsChanged`.
- `MAGNET RUSH` multiplies the **active** radius and the pull cap, and the state machine asks for
  the active radius — otherwise the Rush would be configured, logged, and doing nothing, which is
  the same shape as job 007's hardcoded pull cap.
- The REACT exit recomputed four exponentials per (entry × player) at 10Hz. Hoisted to once per
  player, with a squared-distance compare. (First version wrote `.Magnitude ^ 2`, which takes the
  square root and then undoes it — the comment was right and the code was not.)

## Open

- **`findings/0000`** — Flow tiers 1–4 are only ever seen on the way *down*. Collection is batched,
  so one flush jumps straight to tier 3 and a dense field reaches RUSH in under a second. The
  decay half is real; the build half is not legible. This is a feel judgement and needs a human
  playing it, not a number picked here. **Group 04's "Magnet Flow x1-x5" item should not be
  ticked until that is decided.**
- Capacity 30 is very tight — a dense field fills it in about five seconds. Untuned on purpose.
- Nothing persists: levels reset every session until the profile lands in job 011. `LEVEL_KEYS`
  is the list that job has to serialise.

## Checklist

- [x] Requirements reviewed
- [x] Independent reviewer agent run — *the job 006 reviewer ran in parallel; its findings are
      about job 006's scope, and are carried into their own job rather than folded in here*
- [x] Symptom reproduced in Play
- [x] Implementation plan created
- [x] Implementation completed
- [x] Proof it works better captured — measured in Play, table above
- [x] Final summary + changelog written
