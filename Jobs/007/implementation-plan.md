# Job #007 — implementation plan

**Project**: `roblox.magnet-sweep`
**Status**: complete

## What was built first

`ScrapService` (server: pool, state machine, grant), `MagnetController` (client: rig, motion,
batched claim), `Config/Magnet` additions, and dev commands `scrap.spawn` / `scrap.stats` /
`scrap.clear`.

That version ran, collected scrap, and looked finished. It was not: an independent reviewer,
given only the requirement and never my theory (GROUND-RULES 8), reproduced six defects in Play.
Everything below is the repair, and the repair is the substance of this job.

## The state machine had no exit

Decision 0005 names four states but only three transitions existed. `PULL` was entered by the
server and left **only** by a successful claim. A pull is client-driven, so anything that stops
the client driving — death, alt-tab, streaming, walking away — stranded the object:

1. it stayed unanchored forever, holding a slot against `MAX_CONCURRENT_PULL`
2. it fell (scrap is `CanCollide = false`, so it goes *through* the floor)
3. at `FallenPartsDestroyHeight` the **engine destroyed it**
4. `registry` went on pinning the destroyed Instance in `PULL`
5. `pulling[player]` never came back down

The end state is a player whose magnet is dead for the rest of the session, and a pool that has
permanently lost a part. The reviewer reproduced it exactly: 80 stuck objects — precisely
`MAX_CONCURRENT_PULL.Medium` — and a pool that fell 400 → 320.

**Fixed** with a reaper at the top of `tick()`, running before the per-player sweep so an object
reaped this tick can be pulled again in the same tick. It recovers on four conditions: the owner
is gone, the object has sunk past a height bound, a timeout has expired, or the Instance is
already destroyed (in which case the entry is dropped rather than pinned).

### The first version of the exit was too slow to work

`PULL_TIMEOUT` was 6.0s. Measured in Play: an abandoned object reaches the destroy plane in
**2.26s**. The timeout lost the race — 45 of 45 abandoned objects were still destroyed. The
magnet no longer bricked, but the pool still bled a part per abandonment.

So the load-bearing check is a **height bound**, not a clock: `PULL_FALL_LIMIT = 25` studs below
the object's home. A 10Hz reaper catches a fall of 0.98 studs per tick, so it fires in ~0.5s and
always beats the 2.26s drop. `PULL_TIMEOUT` came down to 3.0s and is now the backstop, not the
mechanism.

## The decision-0005 check could not fail

`unanchoredCount()` iterated `registry`. The leak decision 0005 exists to catch is "a part
returned to the pool without being re-anchored" — and returning to the pool **removes the registry
entry**. The check was structurally blind to the single failure it was written for, and it
reported `0` while parts leaked. It also counted destroyed parts as live. It now iterates
`folder:GetChildren()`. (PITFALLS #2.)

`scrap.stats` gained `destroyed` and `parts=N/400`, and prints `*** POOL BLEEDING ***` when the
folder drops below `POOL.INITIAL_SIZE`, so pool loss is visible in one command instead of being
inferred later.

## The pool was parked on the destroy plane

`POOL.PARK_Y` was `CFrame.new(0, -500, 0)` and `FallenPartsDestroyHeight` is `-500`. Identical.
One frame unanchored while parked and the engine deletes the part. Moved to `-300`, with a startup
assertion that reads both numbers from the live DataModel and states them.

## Zero-travel collection

`maxDist` was `stats.Radius * 1.35` = **16.2 studs**, against an arrival radius of **2.5**. That
made *entering the field* the collection: 13.7 studs of every pull were optional, and the reviewer
was granted 80/80 objects at 16.9–20 studs without moving any of them.

The gate is now **derived from the rig** rather than scaled off the pull radius:

```
Magnet.grantRange() = TIP_OFFSET 2.6 + ARRIVE_RADIUS 2.5 + LAG_ALLOWANCE 4.0 = 9.1 studs
```

`MAX_RANGE_SLACK` is gone entirely — anything that scales this off the pull radius reintroduces
the original bug. A second, independent gate requires the object to have been in `PULL` for as
long as the journey really takes.

### The travel gate's first form was vacuous

It measured *distance moved*. An object that never moves has travelled 0 studs, needs 0 seconds,
and is granted instantly — so the check was empty for precisely the case it guarded. It now
measures the **journey**: how far the object was from the magnet when the pull began.

## Claims were fire-and-forget

The client hides an object the instant it arrives, before the server has agreed. The server
replied only on success, so a rejected claim left that object invisible on that client for the
rest of the session, with nothing logged anywhere — a self-sealing failure that looks exactly
like a successful collection.

`ScrapGranted` now **always** fires, echoing the batch and a reason, and the client restores
anything not accepted.

## Two more found by running it

**Honest claims were being rejected at 43%.** An arrived object is still unanchored, still
`CanCollide = false`, still client-owned, and nothing drives it once it is inside `ARRIVE_RADIUS`
— so it *free-falls while it waits for the next batch*: 6.13 studs per 0.25s flush, straight out
of its own 9-stud grant gate. Fixed by pinning arrived objects at the tip until the server
answers.

That took rejections 43% → 25%. The rest was replication: the server judges the claim against the
object position **it has received**, and the arrival happened on the client. Firing in the same
frame means the server is still holding the pre-pull position. Fixed by claiming on the flush
*after* arrival — the object is pinned and already invisible, so the delay costs the player
nothing. Rejections went to **0.0%**.

**The per-device pull cap was enforced nowhere.** Decision 0012 makes it a per-device budget;
`Config/Quality` carried it, Bootstrap audited it on startup, and the server hardcoded `Medium`
for everybody. A phone got the desktop budget. The client now reports its measured tier over a new
`ReportQuality` remote and the server clamps it to the `High` ceiling — so a lying client can
lower its own cap and never raise it.

## Smaller repairs

- `spawnField` took its drop height from `centre.Y` — the position of whichever player ran the
  command (PITFALLS #42). It now raycasts per piece and skips points with no floor.
- `OverlapParams.MaxParts = 400` silently truncated with no ordering guarantee: in a dense field
  the same objects can return every tick while others are never seen, never react and never become
  collectable, and nothing errors. Removed; the pool ceiling is the budget.
- The client swept every child of the Scrap folder every frame — 400 parts, ceiling 1200, nearly
  all of them parked and hidden. Replaced with a live set maintained on attribute change.
- `RenderStepped` → `PreSimulation`. The loop writes `AssemblyLinearVelocity`, so it belongs before
  the physics step; `RenderStepped` also stops firing when the client is not drawing.
- The client had its own `math.max(mult, 0.15)` speed floor, a number found nowhere else, while the
  server's gate judged arrivals against a different formula. Both now call `Magnet.pullSpeed`.
- `release()` clamped a corrupt pull counter to zero in silence; it now warns.
- `init()` never cleared `pulling`, so `scrap.clear` looked like the nuclear option and could not
  un-brick a magnet. Only rejoining fixed it.
- The magnet tip offset was a literal in the client and a term in the server's gate. Now
  `Magnet.TIP_OFFSET`, shared.

## Verification

Every number in [final-summary.md](final-summary.md) was measured in Play, not derived from the
config. The rejection census (`scrap.why`) exists because "13 of 30 rejected" is a number to argue
about and a per-gate breakdown is a reading — it is what turned a wrong guess about the travel gate
into the real cause.
