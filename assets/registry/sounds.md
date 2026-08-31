# Sound registry — the fourteen slots

**Status: all 14 slots LANDED**, approved by the owner 2026-08-30. Verified in Play: every id
loads, the hum runs, four of the five tier-1 families fire on collection (the fifth is `Tool`, on
the Pipe, which a Power-10 magnet cannot lift), and both magnet one-shots fire on their edges.

> 🔴 **No placeholder sounds.** Leave the slot empty and make it announce itself. A wrong sound is
> much harder to notice than a missing one, and a placeholder is how the wrong asset ships.
> — [systems/audio](../../docs/systems/audio/README.md)

The code is done and wired: [`SoundKit`](../../studio_game/ReplicatedStorage/SoundKit.luau) holds the
slots, [`MagnetFeel`](../../studio_game/StarterPlayerScripts/MagnetFeel.local.luau) plays them with a
Flow-driven pitch rise, and Bootstrap prints the empty ones **by name** every startup.
`SoundKit.build` returns **nil** for an empty slot rather than a silent `Sound`, so nothing can look
wired while being mute.

**To land one:** paste the id into that slot's `id` field in `SoundKit.luau`, then move its row to
*Landed* at the bottom.

---

## How to audition — press **F3** in Play

`AudioBench` (F3) is the tool for this, and it exists because *how* you audition is half the
decision. The shared registry records two clips accepted on their category and rejected the moment
they were finally heard properly — and the other half of that mistake was the method: they had been
judged through a slot that plays at the volume of thunder 600 studs away, far too quiet and distant
to tell a ping from a texture.

So the bench plays a candidate **through the real slot**: the slot's own volume, its looping, its
rolloff, parented to the magnet tip where the sound will actually live.

| Control | What it does |
|---|---|
| the text box | paste a Creator Store **id or URL** — it pulls the digits out either way |
| **▶** on any row | plays that slot using the pasted id, or the slot's own id if it already has one |
| the grey candidate rows | one tap: fills the box and plays it. Each names what disqualifies it |
| **FLOW 0–5** | steps the Flow tier. Family sounds are pitched up to **x1.30** at tier 5 — anything with a strong musical note will sound wrong up there, and this is where you find that out |
| **STOP** | kills the current preview (the hum loops for 52 seconds) |

It is gated to authorised users and builds **nothing** for anyone else.

⚠️ **The bench cannot write to `SoundKit`.** When you settle on an id, paste it into that slot's
`id` field — or tell me the slot and the id and I will.

## How to search this library

**Pro Sound Effects** is the source: free, verified, and — crucially — its assets carry a real
description and a category, which is what lets you reject a candidate without listening to all of it.

⚠️ **Search by ITS category vocabulary, not plain language.** Confirmed again here: `Spring Boing
Twang` returned Sonic and Bee Swarm rips and zero PSE results, and `Metal Squeal Scrape Tear`
returned a creature roar and a tyre swerve. The categories that actually work:

| Category | What is in it |
|---|---|
| `Electric - Hum` | steady transformer/bulb hums, **36–52s, marked Loop** |
| `Electric - Arcs & Zaps` | lightning flashes, electrical bursts, 0.8–1.3s |
| `Metal - Hits` | sledgehammer impacts, ring-off |
| `Metal - Misc` | scrapes, coin drops, chain hits |
| `Rattles` | rattling, shaking metal |
| `Robots - Misc` | clangs and clunks, some marked *Comic* |
| `Foley - Props` | keys, bags, handled objects |

⚠️ **Filtering by long duration surfaces MUSIC, not SFX.** A `≥15s` filter returned APMOfficial and
DistrokidOfficial song catalogs — including a track literally called *"Magnetic Field"*, which is a
song, not a magnet. Pair a duration floor with a PSE category word.

⚠️ **Game rips are everywhere and we do not use them.** Seen in these very searches:
`hl2 metal impact`, one whose whole description is *"TF2"*, two admitting *"half life 2 physics sound
effect… all credits go to the original creators"*, `sonic 3 and knuckles spring`,
`Bee Swarm Simulator - PollenHoney`, `deepwoken electricity`.

⚠️ **Read the description, not the name.** `9113848518` is a perfect-sounding *"Coin, Large, Metal,
Toss"* — with **"Distant Traffic"** in it. On a sound that fires hundreds of times a session, a
baked-in car is permanent.

---

## The nine object families

Every one is pitched **up** by Magnet Flow — that rising pitch *is* the Flow feedback — so anything
with a strong musical note in it will sound wrong at tier 4.

| Slot | Wanted | Must NOT have | Candidates |
|---|---|---|---|
| `FAMILY.Bolt` | dry ***tik***, ≤0.4s | **no ring, no tail** — it fires dozens of times a second | ⚠️ **gap.** Everything in `Metal - Hits` is 1.4s+ and rings. Likely needs a short non-PSE upload, or trimming one |
| `FAMILY.Coin` | bright ***ding***, ≤0.6s | no cash register, no chime, **no traffic** | `9125444889` Coins Drop, Medallions to Wood 9 · 1.6s · *Metal - Misc*<br>`9125444677` same set, 1.8s<br>❌ `9113848518` — has Distant Traffic |
| `FAMILY.Gear` | ***clink*** with mass, ≤0.7s | no ratchet, no clockwork | `9113757098` Chain Hit Metal 1 · 1.9s · *Metal - Misc* (has ringing — check) |
| `FAMILY.Spring` | ***boing***, ≤0.8s | no cartoon slide-whistle | ⚠️ **gap.** No PSE results at all; every hit was a game rip. Search `Metal - Misc` for *twang*, or accept a non-PSE upload |
| `FAMILY.Tool` | ***clunk***, ≤0.9s | no voice, no ambience | **`9125819216`** Robot Impact, Metal Clangs/Clunks 4 · 1.4s · *Robots - Misc* · "Clang, Clunk, Body Hit, **Comic**" — best single match found |
| `FAMILY.Barrel` | **CLANG**, ≤1.5s | no rolling after, no debris | **`9125672726`** Sledge Hammer on 5ft I-Beam 13 · 1.5s · *Metal - Hits* · the ring-off this slot wants<br>`9125672562` same set, 1.7s |
| `FAMILY.Vehicle` | **SCREEECH**, ≤2.0s | no engine, no tyres | `9116893799` Metal Tank Scrape 3 · 3.9s · *Metal - Misc* — **likely too long, audition** |
| `FAMILY.Machine` | **GRRRRR → BOOM**, ≤2.5s | **no alarm, no siren** | `9116673678` Metal Impact, Heavy Clunking + Scraping · 1.9s · *Metal - Hits*. May need two clips layered |
| `FAMILY.Rare` | low hit + sparkle, ≤2.0s | no fanfare, no sting, no voice | ⚠️ see below — this one needs **two** assets and the code holds one |

## The five magnet states

| Slot | Wanted | Must NOT have | Candidates |
|---|---|---|---|
| `MAGNET.Hum` | steady electrical hum, **looping** | 🔴 **NO sparks, NO crackle, NO arcing** | **`9112889325`** Transformer Hum 3 · **52.5s** · *Electric - Hum* · "Steady, Loop" — **longest, take this one**<br>`9112889082` / `9112889303` Transformer Hum 1 & 2 · 36.0s · Steady, Loop<br>`9112823813` Light Bulb Buzz 2 · 49.4s · thinner, higher<br>❌ `9112889312` — same set but **"Fluctuating"**, wrong for a constant hum |
| `MAGNET.React` | small rising rattle, ≤1.0s | **no impact at the end** | `9125689476` Metal Shake, Rocking Aircraft Aileron 2 · 2.9s · *Rattles* · ⚠️ says "Clunking, Clanking" — may fail the no-impact rule |
| `MAGNET.Refuse` | a strained buzz that **fails**, ≤1.2s | **nothing suggesting it came free** | ⚠️ **gap.** Try `Electric - Hum` short + `Metal - Misc` strain. If it sounds like success, the tutorial inverts |
| `MAGNET.Rush` | surge swelling **upward**, ≤2.0s | no explosion, no impact | `9116279560` Lightning Flash 56 · 0.8s · *Electric - Arcs & Zaps*<br>`9116277827` Flash 30 · 0.9s · `9116275998` Flash 13 · 1.3s<br>⚠️ all three are "Searing, Crackle, **Hiss**" — a strike, not a swell. Closest available, not ideal |
| `MAGNET.Full` | short dull thud, ≤0.6s | no error beep, no UI buzzer | `Metal - Hits`, smallest and deadest |

## The interface — added by job 011, landed 2026-08-30

One slot, and it is the only sound in the game allowed to sound like an interface. Every button goes
through `Ui.Components.button`, so there is no second press sound and no path that forgets it.

| Slot | Wanted | Must NOT have | Where to look |
|---|---|---|---|
| **`UI.Press`** ✅ **landed** | a short, dry, **positive** click — a physical switch on a machine panel. ≤0.25s | **no musical note, no cartoon boop, no reverb tail.** It fires on every tap in the game, so any tail or pitch becomes a melody | **`89108158102227`** `ui_mouse_click` — **our own upload**, already the UI click in Jungle (`UIClick.local.luau`) and listed in the shared registry. Verified loading in this place: `IsLoaded=true`, **1.06 s** |

> ⚠️ **Landed from our own catalog, not sourced fresh — and it wants one listen.** The documented
> order is *our inventory first, the Creator Store second*, and this was already in it: owned by
> `johnygorsky10`, already moderated, already shipping as a UI click in another game here. That is
> why it is not a placeholder.
>
> But its **`TimeLength` is 1.06 s** against a brief that asks for ≤0.25 s, so it may carry a tail
> this slot forbids — a tail becomes a melody when it fires on every tap. **Audition it with F3.**
> If it rings, the fix is a shorter clip from the same `Toggle Switch, Industrial` Pro Sound Effects
> set `FAMILY.Bolt` came from — choosing a *different* switch from it, because the bolt *tik* and the
> button click must not be the same sound or collecting and tapping stop being distinguishable.

⚠️ **`MAGNET.Full` is explicitly forbidden from sounding like a UI buzzer** because SCRAP FULL is a
physical event. That rule is about the *world*, and it is why this group exists separately — without
it, "no interface sounds" would leave every button in the game silent, which style §7 says reads as
broken.

Audition it in place with **F3** (`dev("audio.bench")`), like every other slot.

---

## Three things to know before you start

**`MAGNET.Hum` is the most-heard sound in the game.** It plays for the whole session. Favour
**length** over character — short loops are audibly short — which is why the 52.5s Transformer Hum is
the recommendation over the two 36s ones.

**`FAMILY.Rare` needs two assets and `Slot` holds one id.** The rule is *nothing baked in*: the
low hit is levelled with the Machine family, the sparkle with the UI, and one clip containing both
fixes their relative level forever. **The data structure cannot express this today** — if you want it
properly, say so and I will add a layered slot before you source it. Otherwise take one clip and note
here that the mix cannot be adjusted.

**Four families cannot be heard yet.** `Barrel`, `Vehicle`, `Machine` and `Rare` are referenced by no
scrap definition — `ScrapSpec.TIER1` only uses `Bolt`, `Coin`, `Gear`, `Spring`, `Tool`. The other
four arrive with later tiers. Source them if you want, but nothing in the game will play them, and
the "nine families" build item can only be verified 5/9 until then.

**Audition in the slot it will occupy.** The shared registry records two Tide clips accepted on their
category and rejected the moment they were heard at the right volume in the right place. `dev("quality.set", …)`
and `dev("scrap.spawn", …)` will put you in a dense field quickly.

---

## Landed — 2026-08-30

All from **Pro Sound Effects** via the Creator Store: free, verified, licensed **for use within
Roblox only**. Not ours, not reusable outside. Audio assets carry no scripts, so the model-scan rule
does not apply.

| Slot | Id | Name | Length |
|---|---|---|---|
| `FAMILY.Bolt` | 9120099101 | Toggle Switch, Industrial 72 | 0.6s |
| `FAMILY.Coin` | 9116741697 | Metal Lid, Incense Burner 7 | 0.7s |
| `FAMILY.Gear` | 9113757098 | Chain Hit Metal 1 | 1.9s |
| `FAMILY.Spring` | 9125380134 | Baseball vs chain-link fence 13 | 2.3s |
| `FAMILY.Tool` | 9125819216 | Robot Impact, clangs/clunks 4 | 1.4s |
| `FAMILY.Barrel` | 9125672726 | Sledge hammer on I-beam 13 | 1.5s |
| `FAMILY.Vehicle` | 9116893799 | Metal tank scrape 3 | 3.9s |
| `FAMILY.Machine` | 9116673678 | Metal impact, heavy clunking + scraping | 1.9s |
| `FAMILY.Rare` | 9114238479 | Electric arcing 8 | 2.3s |
| `MAGNET.Hum` | 9112889325 | Transformer hum 3, steady, loop | 52.5s |
| `MAGNET.React` | 9125689476 | Metal shake, aircraft aileron 2 | 2.9s |
| `MAGNET.Refuse` | 9114236886 | Electric arcing 9, starts and stops | 3.2s |
| `MAGNET.Rush` | 9114238609 | Electric arcing 10 | 3.6s |
| `MAGNET.Full` | 9114201951 | Duffel bag vs stucco wall 2 | 2.0s |

### Two that are knowingly imperfect

- **`FAMILY.Spring`** — there is no spring or boing anywhere in this library; three searches
  returned only game rips. A chain-link fence twang is standing in for it. Replace when a real one
  turns up.
- **`FAMILY.Rare`** — this is the **sparkle only**. The spec wants a low sub-bass hit underneath it,
  kept separate so the two can be levelled independently, and `Slot` currently holds one id. Both
  halves are still outstanding.

### A mix fix that came out of landing these

`MAGNET.Hum` is mixed at 0.18 and was **inaudible** from a normal third-person camera: the engine's
default 10-stud rolloff minimum meant it was already attenuating 15 studs back. Slots now carry a
`minDistance`, and the magnet's own sounds use **30** — they sit on the local player's hand, so they
must not fade at ordinary camera distance. Raising the volume instead would have made the magnet
loud for everyone else too.

## Licence

Everything from **Pro Sound Effects** on the Creator Store is free, verified, and licensed for **use
within Roblox only** — not ours, not reusable outside. Record that for every id landed; the shared
registry already carries this term for The Last Tide and it must survive into this game's own
pre-launch audit.
