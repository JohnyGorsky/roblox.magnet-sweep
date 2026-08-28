# Audio

**Sound is a feature, not polish.** Section 15 makes it fundamental, the store page recommends
headphones, and the ASMR quality of the sweep is a stated pillar. Audio is not the last group in the
build manifest.

Follow the shared `roblox-audio` skill for the API (modern `AudioPlayer`/`AudioEmitter`/`AudioListener`
+ `Wire`, or the legacy `Sound` API), 3D positioning and mobile cost.

## Object families

Each family has its own voice. Pitch rises with Magnet Flow — that rising pitch *is* the Flow feedback.

| Family | Sound |
|---|---|
| Bolt | *tik* |
| Coin | *ding* |
| Gear | *clink* |
| Spring | *boing* |
| Tool | *clunk* |
| Barrel | **CLANG** |
| Vehicle | **SCREEECH** |
| Huge machine | **GRRRRR — BOOM** |
| Rare part | a special low-frequency hit + sparkle |

## Key moments

| Moment | Sound |
|---|---|
| Magnet idle | quiet electrical hum, spatialised to the magnet |
| Object REACT | small rattle, rising |
| Detaching a rare part | **GRRRRRRR** strain, building → **CLANG** release |
| Salvage Breach | alarm klaxon, zone-wide |
| Guardian near | proximity cue that rises before the guardian is visible |
| SECURED | the payoff chord. The most satisfying sound in the game |
| Recycle | coin cascade |
| Install | VRRRR → CLUNK → electric snap |
| Arena, from the Workshop | distant **CLANG**, **BOOM**, **ZAP** — continuous, spatialised |
| Loading | *tik* per object, **CLANG** on complete |

## The Workshop soundscape

Section 8: the Arena must be constantly audible from the Workshop. This is a spatial audio job — real
emitters in the Arena, attenuated across the hub — not an ambience loop. It is also the audio proof of
[decision 0001](../../decisions/0001-one-place-not-two.md).

## Rules

- **No placeholder sounds.** Leave the slot empty and make it announce itself. A wrong sound is much
  harder to notice than a missing one, and placeholders are how the wrong asset ships.
- **Nothing baked in.** A magnet hum must not have sparks in it; a factory ambience must not have an
  alarm in it. Anything levelled independently must be a separate asset, or it fires at the wrong moment.
- **Every UI button has a sound.** Silence reads as broken.
- Mix so that the sweep layer sits *under* the alarm layer. During a Salvage Breach the player must hear
  the danger over their own collecting.

## Sourcing

Per GROUND-RULES §4: Claude searches our registry and the Creator Store first, writes a searchable spec
(length, loop, what it must **not** contain, how it is judged in context), and the human finds and
supplies the id. Requests are presented as a table, one asset per row.
