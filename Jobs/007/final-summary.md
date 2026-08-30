# Job #007 — final summary

**Project**: `roblox.magnet-sweep`
**Status**: complete
**Reviewer**: independent agent, given the requirement only — never my theory (GROUND-RULES 8)

The magnet works: the player stands in a field, scrap shakes, lifts, flies in and is banked. All
six critical defects the reviewer found are fixed, and two more surfaced only because the fixes
were measured in Play rather than reasoned about.

## Measured in Play, before and after

| | before | after |
|---|---|---|
| Abandoned pulls destroyed by the engine | **45 of 45** | **0 of 40** |
| Pool after 98 abandonments | would bleed 1 part each | **400 / 400, five rounds running** |
| Unanchored parts left behind | grew without bound | **0** |
| Grant gate | 16.2 studs (arrival is 2.5) | **9.1 studs, derived from the rig** |
| Honest claims rejected | — | **0.0%** (164 asked, 164 granted) |
| Per-device pull cap | hardcoded `Medium` for everyone | **reported and clamped** (`tier Medium -> cap 80`) |
| Reaper vs engine destruction | 6.00s vs 2.26s — *lost* | **0.45s vs 2.26s** |

The startup line now states both halves of each invariant, so a regression is visible on boot:

```
grant gate 9.1 vs radius 12.0 | park -300 vs plane -500 | reaper 0.50s vs destruction 2.26s
```

## The six findings

1. **`PULL` had no exit** — an abandoned pull held a cap slot forever, fell through the floor and
   was destroyed by the engine, leaving `registry` pinning a corpse and `pulling[player]` at the
   cap. The player's magnet was dead for the session. Fixed by a reaper; the height bound, not the
   timeout, is what makes it work.
2. **`unanchoredCount()` read `registry`** — blind to the exact leak decision 0005 names, because
   returning to the pool removes the entry. Now reads the folder.
3. **`init()` never cleared `pulling`** — `scrap.clear` could not restore a bricked magnet.
4. **Zero-travel collection** — entering the field *was* the collection. Two independent gates now:
   a derived distance range, and the journey time the pull really takes.
5. **`REACT` never returned to `IDLE`** — objects shook forever on every client, and `REACT` is the
   state the client animates per frame, so the cost only grew. Verified: `react` 50 → **0** on
   walking away.
6. **Claims were fire-and-forget** — a rejected claim left the object invisible for the session with
   nothing logged. The reply always fires now, and the client restores what was refused.

## Two the review did not have, found by measuring

- **43% of honest claims were being rejected.** An arrived object free-falls 6.13 studs during the
  0.25s it waits for its batch — out of its own grant gate. Pinning it at the tip took this to 25%;
  claiming on the flush *after* arrival, so the position has replicated, took it to **0.0%**.
- **A 6-second reaper cannot save a falling part.** The drop to the destroy plane is 2.26s. The
  first version of the fix was correct in shape and too slow to fire.

## What I got wrong along the way

- The travel gate's first form measured *distance moved*, which is zero for exactly the exploit it
  guards. It was vacuous until it was changed to measure the journey.
- Two test runs reported "MISMATCH" and "off by 40" against the gate boundary. Both were my own
  measurement error — comparing a client-side snapshot against a server evaluation of moving,
  free-falling objects. The gate was cutting where it says; the two sides were reading different
  moments. Recorded here because the numbers appear in the transcript.

## Residual, stated plainly

An exploiting client can still collect objects already within ~9 studs of its root without waiting
for transit — worth about 0.1s per object. It is bounded by geometry: honest arrival is ~4.5 studs
from the root, so the gate cannot go much below ~7 without rejecting real play. It is not
economically meaningful, because **the server still decides which objects enter `PULL` at all**
(radius 12, capped). The whole-field harvest the reviewer demonstrated is closed.

Related and inherent: the server judges a claim against the object position **it has received**, and
a freshly client-owned part replicates with a lag. The distance gate can only ever be as good as
that position, which is why the travel-time gate exists as a second, independent check.

## Not done — carried forward

- **The magnet rig is client-built, so no player can see another player's magnet.** Real, and out of
  this job's scope (it changes who owns the rig). Filed in `Planned/`.
- `Magnet.START.Power` is still hardcoded on the client; the profile arrives in job 011.
- `MIN_TRAVEL_FRACTION = 0.7` is a starting value, not a measurement.
- The four `[DEVICE]` performance questions still need real hardware.

## Checklist

- [x] Requirements reviewed
- [x] Independent reviewer agent run — given the requirement, not my theory
- [x] Symptom reproduced in Play before any fix
- [x] Implementation plan created
- [x] Implementation completed
- [x] Proof it works better captured — before/after, measured in Play
- [x] Final summary + changelog written
