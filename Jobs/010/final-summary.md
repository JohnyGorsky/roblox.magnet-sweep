# Job #010 — final summary

**Project**: `roblox.magnet-sweep`
**Status**: system complete; **14 sound slots awaiting ids from a human**

Build group 04's remaining P0 items: the magnet's five VFX states and the nine object sound
families with a Flow-driven pitch rise. This is the half of the magnet the MVP gate turns on —
the gate lists **sound** and **the break-free moment** as items 2 and 3 of what to fix if
sweeping is not satisfying, and the store page recommends headphones.

## The five VFX states, measured on the live rig

One emitter, one beam pair, one light — for all five states, exactly as
`systems/vfx-lighting` budgets the magnet field. A state changes the **settings** of the same
instances; nothing is created or destroyed at runtime. This runs continuously on every client
for the whole session, so it is the effect that must be cheapest.

| state | config rate | measured on the emitter |
|---|--:|--:|
| Idle | 6 | **6.0** |
| Pulling | 24 | (blends through) |
| HighFlow | 55 | (blends through) |
| Rush | 120 | **119.9** |
| Overcharge | 200 | **200.0** |

Light range tracked 7.0 → 20.0 → 26.0 and beam width 0.100 → 0.360 → 0.500 alongside. The
blend is real and visible: a mid-transition sample read 102.6 on its way to 120.

`Vfx.audit()` runs at startup and fails if a state is missing a declared field, carries an
undeclared one, or **does not escalate over the state below it** — so "maximum visual state"
is checked rather than asserted. Job 009 had just found three config fields that nothing read
and one that was read and then overwritten with the opposite value; this is the guard against
repeating that.

## Overcharge is a real hook, not a dead field

Overcharge is a paid PvE boost (spec §71) and the magnet's maximum visual state. Rather than
declare a state nothing can reach, it is wired end to end now: `MagnetState.grantOvercharge`,
a `magnet.overcharge` dev command, and the radius multiplier. The developer product in group 14
just calls it.

⚠️ **Decision 0011 is a code gate here, not a promise.** Robux never buys Arena power, so
Overcharge lives on the *player's magnet state* and the only things that read it are the
magnet's own radius and its VFX. The Arena reads robot stats, a different module that never
consults this. That separation is the enforcement.

## Audio: the system is done and every slot is empty

That is the requirement, not a shortfall:

> **No placeholder sounds.** Leave the slot empty and make it announce itself. A wrong sound is
> much harder to notice than a missing one, and a placeholder is how the wrong asset ships.

- `SoundKit` holds 14 slots, each with a **brief** (what it is, in words a search can use) and
  a **forbid** (what disqualifies a candidate — the field that actually rejects things).
- `SoundKit.build` returns **nil** for an empty slot rather than a silent `Sound`, so nothing
  can look wired in the Explorer while being mute.
- Bootstrap prints the empty slots **by name** every startup. A count is a number you learn to
  scroll past; the list is what makes a silent slot impossible to forget.
- `dev("audio.missing")` asks the same question on demand.

Voices are **pooled**, four per family. A Rush collects hundreds of objects a second and
`Instance.new("Sound")` per pickup would allocate hundreds of instances a second on a phone.

The collection sound is authored by the **client at arrival**, not on the server's grant — a
sound that waits for a round trip lands after the object has already vanished, which is exactly
the lag the batched claim exists to hide.

## The asset request

[`assets/registry/sounds.md`](../../assets/registry/sounds.md) — one row per slot, with length,
what it must not contain, and how to judge it. Searched our shared catalog first (90 recorded
ids across Defender/Jungle/Tide: **nothing reusable**), then the Creator Store.

What the search pass established, which is the part worth keeping:

- **Pro Sound Effects** is the source — free, verified, and its assets carry a real description
  and category, which is what makes them judgeable without listening to all of them.
- The category vocabulary that works: `Metal - Hits`, `Metal - Misc`, `Rattles`, `Robots - Misc`,
  `Vehicles - Brakes`, `Impacts`. Plain-language search missed badly again, exactly as the shared
  registry warns — `Metal Squeal Scrape Tear` returned a creature roar and a tyre swerve.
- **Game rips are everywhere in these results**: `hl2 metal impact`, one whose entire description
  is "TF2", two admitting "half life 2 physics sound effect… all credits go to the original
  creators". Same category as the Pink Floyd sample the shared registry already records.
- Concrete shortlist landed for `Tool`, `Barrel`, `Vehicle` and `React`, each with the caveat
  that disqualifies it if heard wrong — e.g. the sledgehammer I-beam clip has a **ring-off**,
  which is right for `Barrel` and disqualifying for `Bolt`.

## Notes for whoever fills the slots

- **Audition in the slot it will occupy.** The shared registry records two Tide clips accepted on
  their category and rejected the moment they were heard at the right volume in the right place.
- `MAGNET.Hum` is the most-heard sound in the game — it plays for the entire session. Prefer
  **length** over character; short loops are audibly short.
- `FAMILY.Rare` probably needs **two** assets, a sub-bass hit and a sparkle, because they are
  levelled independently. One clip containing both fixes their relative level forever.
- Every family sound is pitched up by Flow, so anything with a strong musical note will sound
  wrong at tier 4.

## Open

- 14 sound ids.
- Overcharge ×2.0 stacks on Rush ×1.6, giving a 38.4-stud radius — measured, and **untuned**.
- Custom particle art. The VFX uses engine built-in textures (`rbxasset://`), which is a
  deliberate shipping choice and not a placeholder — guaranteed present, no fetch, cannot be
  the wrong asset. Custom art is an upgrade, not a gap.
- `MAGNET.React` and `MAGNET.Refuse` have slots and a `watchScrap` hook but no trigger wired to
  the REACT transition yet — the families were the priority. Small follow-up.

## The independent review, and what it found

Run after the build, given the requirement and never my theory. It returned four CRITICALs and
ten MAJORs. The headline one I reproduced in Play before touching anything:

**The Rush and Overcharge VFX states latched ON and never turned off.** `inRush` / `inOvercharge`
are predicates over a deadline, so the server is always right about them — but the client only
learns their value from a push, and every push site fires on an **action** (a collection, a
recycle, an upgrade). A Rush that simply runs out is not an action. Measured: the server left
the Rush at T+8.2s and the client held `rate = 120`, `lightRange = 20`, shadow-casting, for as
long as it was watched.

Two things broke at once. The continuous-cost budget this whole design is built around was
abandoned for the entire walk home after *every* Rush, and "MAGNET RUSH" stopped meaning a Rush
was happening. For the **paid** Overcharge it is worse: the only feedback the product gives said
you still owned a boost that had expired. Fixed by pushing once on the edge, in the tick that
was already running. After: the client drops out at 8.1s with the server.

**Decision 0011 was not code-gated — the comment pointed at an assertion that did not exist.** I
wrote "the assertion below is what should catch it", and there was no assertion, there or
anywhere. The final summary repeated the claim. Now enforced by
[`tools/check-overcharge-gate.py`](../../tools/check-overcharge-gate.py): only named modules may
reference `MagnetState`, and any file whose name matches arena/robot/combat/damage/deploy may
never. It is a grep rather than a runtime check because the thing being forbidden is a call site
that does not exist yet — proven both ways: clean on the repo, and it fails on a probe
`ArenaCombat.luau` that asks `MagnetState.inOvercharge`.

**The Low tier's `particleRateScale` was dead for the magnet field.** `applyParticles` scaled the
emitter; the render loop overwrote `Rate` one frame later. Because Medium and High both scale by
1.0, the conflict was invisible everywhere except **Low — which is the phone, which is the entire
point of decision 0012**. This is PITFALLS #53 reintroduced three jobs after job 009 found four
instances of it. Fixed with a `SelfDriven` exemption (the mechanism `applyLights` had as `Hero`
and this never had) plus the emitter applying the tier scale itself.

**The render loop allocated six datatypes per frame, forever.** `NumberRange`/`NumberSequence`
are immutable, so every assignment allocates — roughly 1.3 million allocations an hour to re-set
values that had stopped changing, on the effect whose own header says it "must be cheapest".
Fixed by snapping to target and returning early. Measured after: **0 of 75 frames** write.

### A bug I introduced fixing that one

The first converged-guard checked "did the blend move?" alone — but the **quality tier is an
input too**, and it changes without moving the blend. Switching to Low while the magnet sat
converged left the old rate in place: measured 199.8 where the tier called for 100.0. A cheap
loop that ignores one of its inputs is just a wrong loop. Caught by re-running the C3 test rather
than assuming the fix worked.

### Also fixed

- **The collection sound was 2D and global.** Voices were parented to a *Folder*, which ignores
  `RollOffMode` entirely — so the code read as spatial and was not — and `watchScrap` had no
  owner filter, so on a 12-player server every client heard every other player's pickups at full
  volume with no positional cue. Voices now live on the magnet tip, and ownership is recorded
  when the pull *starts*, because `release` clears `PullOwner` in the same frame it clears
  `ScrapState`.
- **`watchScrap` leaked a connection and a strong Instance key per streaming cycle.**
  `StreamingEnabled` is on and the pool parks 300 studs under the map, so pooled parts are
  removed and re-added as new client Instances constantly. `MagnetController` does this correctly
  130 lines away; this script did not.
- **`Vfx.audit` checked only `rate`** while the summary claimed it checked escalation. Overcharge
  could pass with a dimmer light than Idle and fully invisible beams. Now every field is checked
  in its own direction — including `beamTransparency`, which must *fall*. Verified against the
  reviewer's exact counterexample: both violations caught.
- **The pole colours were hex literals in two files** while `Vfx` declared itself their source of
  truth — a magnet skin would have recoloured the field and left the poles signal-red.
- `Vfx.FIELDS` claimed to "prove each field is consumed". It cannot: both checks read literal
  tables in the same file. The comment now says so.

## Carried forward from the review

- `MAGNET.Rush` and `MAGNET.Full` have no caller (the summary previously disclosed only React and
  Refuse). Both already have a signal waiting: Bootstrap fires a dedicated Rush message, and
  `StatsChanged` carries `full`.
- REFUSE never re-evaluates when you upgrade Power — the object keeps shaking "too heavy"
  immediately after the purchase that fixed it. Job 007/008 code, in job 010's blast radius.
- `SoundKit.missing()` cannot report a `ScrapSpec` sound family with no matching slot.
- Four of the nine families (`Barrel`, `Vehicle`, `Machine`, `Rare`) are referenced by no scrap
  def yet, so the asset request asks for four assets no code path can play.
- `FAMILY.Rare` needs two assets and `Slot` holds one id.
- **Unsettled and worth a Play session:** whether the `PULL → nil` attribute transition survives
  streaming, given `release` teleports the part 300 studs down in the same frame. If unstreaming
  wins that race the collection signal is unreliable and the whole nine-family system would be
  mute even after the ids land — and it would look exactly like "the sound ids are wrong".

## Regression

244 asked, **244 granted**, 0.0% turned away, unanchored 0, destroyed 0, parts 400/400.

## Checklist

- [x] Requirements reviewed
- [x] **Independent reviewer agent run** — findings above, acted on
- [x] Symptom / behaviour reproduced in Play
- [x] Implementation completed
- [x] Proof it works captured — the state table above, measured on the live rig
- [x] Final summary written
