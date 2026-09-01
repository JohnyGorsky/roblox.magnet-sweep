# Concept art analysis — what actually makes it look like that

All eight images in `assets/concept_art/`, read for build detail rather than mood.

---

## 1. The ground

Sampled, not eyeballed:

| Surface | Colour |
|---|---|
| Outer factory deck | `#282832` — dark blue-grey, almost navy |
| Arena floor | `#3C3C46` — one step lighter, so the disc reads as a platform |
| Run lane deck | tinted by the lane's colour over the same dark base |
| Base interior floor | the base's identity colour, heavily darkened |

🔴 **The deck is DARK.** Every previous attempt lit it like concrete. In `MapConcept.png` the floor is
nearly navy and everything on it is brighter than it is — that contrast is most of why the art reads
as "glossy factory" rather than "grey room".

The deck is not flat colour: it carries a **grid of panel seams** and painted markings — hazard
chevrons at thresholds, direction arrows in the lanes, bay numbers. Those markings do a lot of work
and cost nothing but a texture.

## 2. The layout, in ratios

| Thing | Reading |
|---|---|
| Base compounds | **4**, not 12 |
| Compound width | roughly **the arena disc's own diameter** — they are big |
| Compound interior | **mostly EMPTY floor.** Fixtures line the inner walls; the middle is open |
| Arena core | **small** — around a quarter of the disc. The rest is fighting floor |
| Between compounds | gaps, with a staging pad on the ring |
| Outside everything | dense pipe-and-machine clutter, as **scenery** — not walkable |

🔴 **This is the ratio I got wrong.** My pockets were 48 studs against an 80-stud arena and then
filled with fourteen objects. The concept's compounds are *larger* than the arena and *emptier*.

🔴 **And the core blocks the fight.** `Robot2.png` and `Robot3.png` both show the Arena as a combat
floor with a **small** magnet trophy on a low plinth at the centre and robots fighting around it.
A 36-stud monument in an 80-stud disc leaves nowhere to fight.

## 3. What the buildings actually are

`Robot2.png` is the clearest reference for an interior, and nothing in it is a slab:

- **Wall units are waist-to-shoulder height** — tool boards, parts racks, screens on stands. The
  player can see over them. Mine were 20-stud panels taller than the character.
- **Machines have silhouette**: yellow robot arms with black joints, cabling, hoses, mounting feet,
  a lit screen recessed in a frame.
- **Signage is small and specific** — `MAGNET BAY 07`, `ARMS / GRAB IT.`, `POWER CORE LVL 3`, a
  green UPGRADE arrow. Not one giant glowing name-slab per building.
- **The deploy pad is a low disc** with a cyan ring inlay and hazard stripes around the rim.

## 4. The light

Two colours, always:

- **Warm amber** from overhead fixtures and machine lamps, pooling on the deck
- **Cool cyan** from screens, the magnet, and arc effects

Never one flat wash. `Robot2.png` has warm light on the floor and cyan on every screen; `Arena.png`
puts warm ceiling light over cool neon signage. My build had one cyan tone everywhere, which is why
it read as flat.

## 5. Why my build looked cheap — the honest list

1. **Primitives, not models.** Boxes and slabs, however coloured. The concept is made of objects with
   bevels, bolts, hoses and inset screens.
2. **Wrong scale.** Wall panels above head height; the concept's are furniture-height.
3. **Wrong density distribution.** Crammed interiors, empty surroundings. The concept is the reverse:
   open interiors, dense surroundings.
4. **One light colour.**
5. **No floor markings.** No chevrons, arrows or bay numbers anywhere.
6. **Coplanar floors** — hub disc, arena disc and base tiles all at y = 0, which is the z-fighting
   the owner saw.

---

## What this means for the build

Under the new ground rules — shared buildings, personal smelter only, editor-placed, real assets —
the concept's *four private compounds* no longer describe the layout. What carries over is
everything else: the dark deck, the ratios, the scale, the two-colour light, the markings.

Proposed shape, for agreement before anything is placed:

```
        ┌─────────────── dense factory scenery (not walkable) ───────────────┐
        │                                                                    │
        │     ╔══════════╗        ╔═══════════╗        ╔══════════╗          │
        │     ║ MAGNET   ║        ║  ROBOT    ║        ║ RECYCLER ║          │
        │     ║   LAB    ║        ║   BAY     ║        ║          ║          │
        │     ╚══════════╝        ╚═══════════╝        ╚══════════╝          │
        │            ╲                  │                  ╱                 │
        │             ╲        ┌────────────────┐         ╱                  │
        │              ╲       │     ARENA      │        ╱                   │
        │   ╔════════╗   ──────│  small core,   │──────   ╔════════╗         │
        │   ║  SHOP  ║         │  open floor    │         ║  SHOP  ║         │
        │   ╚════════╝         └────────────────┘         ╚════════╝         │
        │                             │                                      │
        │        smelter · smelter · smelter · smelter · smelter             │
        │              (one per player, along the back)                      │
        │                             │                                      │
        └──────────────────────── RUN LANE ═════════════════════════▶ zone 1 │
```

- **Common buildings** ring the Arena — walk-in, shared, one of each.
- **Smelters** are a row of personal stations, claimed on join.
- **One run lane** leaves toward the factory.
- **The Arena stays clear** — small trophy core, room to fight.
