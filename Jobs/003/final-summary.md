# Job #003 — final summary

**Project:** `roblox.magnet-sweep` · **Status:** complete · 2026-08-29

## What was delivered

The foundation every later system builds on — 12 files, all verified running in Play.

**Six config modules** (`ReplicatedStorage/Config/`) — Magnet, Zones, Parts, Arena, Economy, Quality.
Every gameplay constant lives here; balance without touching gameplay code (non-negotiable #4).

**`Remotes.luau`** — one module naming all 20 remotes, each stating **what the server must re-check**.
Decision 0007 is only auditable if the whole attack surface is enumerable in one file.

**`RemoteBinder.luau`** — the only sanctioned way to attach a server handler. Rate limiting is applied
before the handler runs, so it is structural rather than something each future handler must remember.

**`RateLimiter.luau`** — token bucket, seven named buckets, per-player, with rejection-count dedupe.

**`Log.luau`** — levelled, per-system scoping. A game with three overlapping randomised cycles is
unreadable from an undifferentiated `print` stream.

**`DevTools.luau`** — a **registry**, not hard dependencies. Systems that do not exist yet simply have
not registered; their commands report "not implemented yet" instead of failing to compile. That is why
the dev tools could ship before the systems they drive.

**`DevConsole.local.luau`** — the client entry point. `.local.luau` deliberately: a `.client.luau` in
`StarterPlayerScripts` **runs twice** (measured in job 002).

**`Bootstrap.server.luau`** — the single entry point, which audits the config at startup and refuses to
start in Studio on a fatal problem.

## Verification

Three Play cycles. The first two failed, which is the point of running it.

```
[S][Bootstrap] created 20 remotes
[S][RemoteBinder] bound function "DevCommand" (bucket Dev)
[S][Bootstrap] 9 client-facing remotes have no handler yet: ClaimScrap, RequestDetach, ...
[S][Bootstrap] ready. 12 zones, arena cap 6, pull caps 40/80/160 | fatal 0, warnings 4

remotes replicated: 20 (RemoteEvent=10, RemoteFunction=9, UnreliableRemoteEvent=1)
config.dump  -> ok=true   zone12 reachable in 86 buys for 4.55e+06 coins
unknown cmd  -> ok=false  unknown command "nope"
rate limiter -> 5 of 30 rapid calls refused
DevConsole in PlayerScripts: 1 instance, LocalScript  (a .client.luau would give 2)
```

The four warnings are the `[UNTUNED]` flags — previously inert, now actually surfaced, so nobody
mistakes a guess for a measurement.

## 🔴 Run 1: a syntax error in seven of eleven files

`Remotes.SPECS: { Spec } = {` — Luau permits a type annotation on a **local declaration**, not on a
table-field assignment. The pattern was in seven files and would have taken the whole server down at
require time. Static reading did not catch it; running it did, immediately.

## 🔴 Run 2: the game was mathematically uncompletable

The independent reviewer flagged the Power cost curve. Verified independently:

```
purchases to Power 1500 : 298
total coins             : 4.282e+58
```

`Economy.coinsToReachTier` existed **precisely to detect this** and had **zero callers**. Now the curve
is geometric, `Economy.audit()` is called by Bootstrap at startup, and the readout proves it: **zone 12
reachable in 86 buys for 4.55e6 coins**.

## Other review findings, all confirmed then fixed

| Finding | Fix |
|---|---|
| **Rate limiter wired to 1 of 19 remotes.** `SPECS[].rate` named a bucket for 8 and no code read the field | `RemoteBinder` makes it structural; Bootstrap refuses to start if a client-facing remote names no bucket, or one RateLimiter does not define |
| **Anti-cheat would flag honest players.** `MAX_PER_TICK = 60` against a Magnet Rush producing ~200 collections per tick | derived (`maxGrantPerTick`) instead of guessed, and asserted at boot |
| **The spawner demanded Commons from tiers that have none.** Decision 0015 gives tiers 10-12 zero Common parts | rarity banded per tier; `Zones.raritiesFor()` |
| **Overclock silently dropped `radiusLevel`** — in neither RESETS nor KEEPS, so undefined | `auditOverclock()` fails if any progression key is missing from both |
| **Eleven untimed `WaitForChild`s** in the file whose docstring claimed it "fails LOUDLY" | every wait has a timeout and an error naming sync as the likely cause |
| Hysteresis treated `current` as a boolean, biasing every client to Medium | signed by the tier you are in |
| `validate()` typed so it could not receive what it existed to reject; `%d` threw on a fractional tier | takes `any`; formats only after checking |
| A dev handler returning `nil` read as success | checks `~= true` |
| The `CanTouch` comment was backwards, prescribing the silent-failure path | corrected: connecting after it is false **throws**; setting it false after connecting **silently** disconnects |

## What the reviewer said that was not acted on

That the pack is "entirely inert" — a long list of functions with zero callers. True at the time and
true by design: this is a foundation, and its callers are jobs 008 onward. Where it was actionable
(`coinsToReachTier`, the `[UNTUNED]` flags) the functions are now called by `Bootstrap`.

## Next

Job 004 — the material kit.
