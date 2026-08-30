# Sound registry — the fourteen slots

**Status: every slot is EMPTY.** That is deliberate, not unfinished work.

> 🔴 **No placeholder sounds.** Leave the slot empty and make it announce itself. A wrong sound is
> much harder to notice than a missing one, and a placeholder is how the wrong asset ships.
> — [systems/audio](../../docs/systems/audio/README.md)

The code side is done and wired: [`SoundKit`](../../studio_game/ReplicatedStorage/SoundKit.luau) holds
the slots, [`MagnetFeel`](../../studio_game/StarterPlayerScripts/MagnetFeel.local.luau) plays them with
a Flow-driven pitch rise, and Bootstrap prints the empty ones **by name** on every startup:

```
[S][Bootstrap] AUDIO: 14 slot(s) have no asset yet -- FAMILY.Barrel, FAMILY.Bolt, FAMILY.Coin,
FAMILY.Gear, FAMILY.Machine, FAMILY.Rare, FAMILY.Spring, FAMILY.Tool, FAMILY.Vehicle,
MAGNET.Full, MAGNET.Hum, MAGNET.React, MAGNET.Refuse, MAGNET.Rush
```

`SoundKit.build` returns **nil** for an empty slot rather than a silent `Sound`, so nothing can look
wired in the Explorer while being mute.

**To land one:** paste the id into that slot's `id` field in `SoundKit.luau`, then move its row from
*Needed* to *Landed* below.

---

## What I searched, and what I learned

Searched: our own [shared catalog](../../../roblox.workspace/Assets/registry/audio.md) (90 recorded
ids, all Defender / Jungle / Tide — **nothing reusable**, no metal-impact or magnet material), then
the Creator Store, free + verified creators only.

**Pro Sound Effects is the source to use.** Free, verified, and its assets carry a real description
and a category, which is what makes them judgeable without listening to every one. The categories
that actually returned useful results:

`Metal - Hits` · `Metal - Misc` · `Rattles` · `Robots - Misc` · `Vehicles - Brakes` · `Impacts`

⚠️ **Search by that vocabulary, not plain language.** This is the shared registry's own standing
warning and it held again here: `Metal Squeal Scrape Tear` returned a creature roar, a tyre swerve
and two unrelated uploads.

⚠️ **Game rips are all over these results and we do not use them.** In the first search alone:
`138612471517641` "hl2 metal impact", `7130144078` "Metal Impact" (description: *"TF2"*),
`125897531345782` / `111712996891473` (*"half life 2 physics sound effect… all credits go to the
original creators"*). Same category of problem as the Pink Floyd sample the shared registry records.

⚠️ **Read the description, not the name.** `9125672726` is a *Sledge Hammer Hit on 5ft I-Beam* with
**"Metal Ring Off"** — perfect for `Barrel`, disqualifying for `Bolt`, whose whole requirement is
that it does not ring.

---

## Needed — one row per slot

Length is a guide. **How it is judged** is the important column: audition each candidate *in the slot
it will occupy*, at the volume it will really play at. The shared registry records two clips accepted
on their category and rejected the moment they were heard in place.

### The nine object families (spec §15)

Pitch rises with Magnet Flow — **that rising pitch is the Flow feedback**, so every one of these
plays up to five semitones-ish above its natural pitch. Anything with a strong musical note in it
will sound wrong at tier 4.

| Slot | Sound | Length | Must NOT contain | Shortlist / where to look |
|---|---|---|---|---|
| `FAMILY.Bolt` | a short dry ***tik*** — a small steel bolt landing on metal | ≤0.4s | **no ring, no reverb tail** — it fires dozens of times a second in a Rush | `Metal - Hits`, smallest available |
| `FAMILY.Coin` | a bright ***ding*** — washer or metal bead, coin-like | ≤0.6s | no cash register, no musical chime, no UI notification | `Metal - Hits` + *coin*, *washer* |
| `FAMILY.Gear` | a ***clink*** with mass behind it — a toothed gear | ≤0.7s | no ratchet clicking, no clockwork loop | `Metal - Hits` |
| `FAMILY.Spring` | a ***boing*** — a coil spring released | ≤0.8s | no cartoon slide-whistle; comic but still metal | `Springs`, `Cartoon - Boing` |
| `FAMILY.Tool` | a ***clunk*** — pipe or hand tool hitting a floor | ≤0.9s | no voice, no workshop ambience underneath | **`9125819216`** Robot Impact Misc Metal Clangs/Clunks 4 · 1.4s · *Robots - Misc* · "Clang, Clunk, Body Hit, **Comic**" |
| `FAMILY.Barrel` | a **CLANG** — big hollow steel drum, struck once | ≤1.5s | no rolling afterwards, no debris scatter | **`9125672726`** Sledge Hammer on 5ft I-Beam 13 · 1.5s · *Metal - Hits* · has the ring-off this slot wants |
| `FAMILY.Vehicle` | a **SCREEECH** — sheet metal dragged, a panel torn free | ≤2.0s | no engine, no tyres, no traffic | **`9116893799`** Metal Tank Scrape 3 · 3.9s · *Metal - Misc* · drum on gritty concrete — **may be too long, check** |
| `FAMILY.Machine` | **GRRRRR → BOOM** — heavy machinery wrenched loose and dropped | ≤2.5s | **no alarm, no siren** — those are levelled separately | `Metal - Hits` heavy + `Impacts`; may need two clips layered |
| `FAMILY.Rare` | a low-frequency hit with a sparkle on top — the rare-part payoff | ≤2.0s | no fanfare, no orchestral sting, no voice | likely **two** assets: a sub-bass hit + a sparkle. See note below |

### Magnet state (spec §14, §16)

| Slot | Sound | Length | Must NOT contain | Notes |
|---|---|---|---|---|
| `MAGNET.Hum` | quiet continuous electrical hum — a powered electromagnet at rest | **loops**, prefer ≥20s | 🔴 **NO sparks, NO crackle, NO arcing** | The single most-heard sound in the game — it plays for the entire session. Length matters more than character: short loops are audibly short. `Electricity - Hum`, `Electronic - Drones` |
| `MAGNET.React` | a small metallic rattle, *rising* | ≤1.0s | **no impact at the end** — it must not sound like it landed | **`9125689476`** Metal Shake, Rocking Aircraft Aileron 2 · 2.9s · *Rattles* · ⚠️ description says "Clunking, Clanking" — may fail the no-impact rule, audition it |
| `MAGNET.Refuse` | a strained buzz that **fails** | ≤1.2s | **nothing that suggests it came free** — no breaking, no snapping | This sound is the tutorial for "upgrade your Magnet Power". If it sounds like success, the lesson inverts |
| `MAGNET.Rush` | an electrical surge swelling upward — power arriving | ≤2.0s | no explosion, no impact — a Rush *starts*, it does not detonate | `Electricity - Zaps`, `Whoosh - Riser` |
| `MAGNET.Full` | a short dull thud — the magnet refusing, out of room | ≤0.6s | no error beep, no UI buzzer — it is physical, not an interface | |

---

## Why `Rare` probably needs two assets

**Nothing baked in.** The rare-part payoff is a low hit *and* a sparkle, and the two are levelled
independently — the hit sits in the mix with the Machine family, the sparkle sits with the UI. One
clip containing both fires them at the same relative level forever. The shared registry has the same
rule for rain and thunder, and it exists because two Tide candidates were rejected for exactly this.

If a single clip is much better than either half, take it — but say so here, so the next person knows
the mix cannot be adjusted.

---

## Landed

| Slot | Id | Name | Source | Licence | Scanned? |
|---|---|---|---|---|---|
| — | | | | | *(none yet)* |

---

## Licence note

Everything from **Pro Sound Effects** on the Creator Store is free and verified, and licensed for
**use within Roblox only** — not ours, not reusable outside. Record that here for every id landed,
because the shared registry already carries this term for The Last Tide and it has to survive into
this game's own audit before launch.
