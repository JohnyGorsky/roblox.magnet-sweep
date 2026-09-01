# Wall research — how the perimeter should look

Source: `Robot.png` and `Robot2.png`, cropped and examined at 2× (`_wall_*.png`). The starting area
is large and enclosed by this wall, so it is the most-seen surface in the game.

⚠️ **Colours below are read off the crops, not pixel-sampled.** Automated sampling on art this dense
kept returning shadow tones — it reported the cyan sign as orange-brown. Read values are honest about
being read.

---

## The vocabulary — ten things every wall in the art has

1. **Dark blue-grey panel base**, roughly `#38414E`. Never black, never neutral grey — always cool.
2. 🔴 **Chamfered corners on every frame.** 45° cuts, never a square corner. This is the single most
   consistent shape rule in the whole art set, and the thing that most makes it read as "designed"
   rather than "boxes". My arena has none.
3. **Chrome/steel bezels** around every panel and opening, `#8892A0`, with a bright highlight edge.
4. **Yellow painted trim and kick plates**, `#D9A21C` — *chipped and worn*, always along the bottom
   edge and up frame sides. This is where the warmth in the picture comes from.
5. **Hazard striping** at thresholds and around openings, `#F2C020` on `#16181E`.
6. **Long thin cyan light strips**, `#4FD8FF`, running horizontally along beams — not glowing panels,
   *lines*.
7. **Amber accent strips**, `#FF9A2E`, the second light colour. Always both, never one.
8. **Exposed structural frames in yellow** at intervals — portal frames standing proud of the wall.
9. **Pipe runs along the top** of every wall, disappearing into the ceiling structure.
10. **Rivets and bolts** along every frame edge.

## The three wall types the art actually shows

### A · Panelled bay wall — `Robot2.png` left
The tool-board wall. A dark perforated panel inside a heavy chrome bezel with chamfered corners, a
glowing cyan sign plate at the top (`ARMS / GRAB IT.`), a chipped yellow kick plate along the bottom,
and objects hung on it. **This is the "tiled wall" reading** — it tiles horizontally as bays.

Best for: the areas behind shops and stations, where the wall should feel like a workshop.

### B · Structural bar wall — `Robot.png` background ✅ CHOSEN for the perimeter
Steel columns at intervals with pipe runs overhead, hazard striping at the base, and tube railings at
walkway level. Reads as depth rather than as a boundary — you see the factory continuing past it.

🔴 **Correction to my first reading: the gaps are NOT open.** I wrote that the bays between columns
were open onto machinery. Cropping the background (`_wall_bg_window.png`) shows they are **tall
multi-pane windows, glowing cool blue from outside**, in dark steel mullion frames.

That matters more than it sounds. **Those windows are where the cool light in every single shot comes
from.** The art is lit warm-amber from the factory fixtures and cool-blue from the window wall, and I
had been trying to get that second colour out of neon signage. It comes from the perimeter.

They are also cheap: a dark mullion grid over a glass panel with light behind it. No mesh needed.

Best for: most of the perimeter. Cheapest to build, and it stops a large enclosure feeling like a box.

### C · Window bay — `Robot2.png` right
A large **chamfered octagonal opening** in a heavy frame, hazard-striped, with a mounted sign plate
above (`ARENA`) and a light strip over it. Robot arms bracket it.

Best for: punctuation. One or two per side, looking out at something — the factory corridor, the
Arena. Not repeated.

## What to build vs what to generate

The Creator Store was searched three times — barriers, railings, sci-fi wall panels. It returned
fences, a "Doom Door", and models from 2010. **There is nothing usable in this style**, so props come
from Meshy.

But not everything should:

⚠️ **The two pieces changed once the bar wall was chosen.** The spec said "panel + pipe", but a bar
wall repeats **columns**, not panels — so the two generated pieces are the column and the pipe run.
Same count, same cost.

| Element | Source | Why |
|---|---|---|
| 🔴 **Column** — chrome shaft, riveted collars, hazard placard | **Meshy** ✅ | The most-repeated single object on the perimeter, and all round + bevelled. Exactly what primitives cannot do |
| 🔴 **Pipe run** — bundled pipes, flanges, hose | **Meshy** ✅ | Round, detailed, repeats along every wall top. Flange ends are open so it tiles end-to-end |
| Window bays — mullion grid + glass + light behind | **Primitives** | Flat grid of thin slabs. A mesh buys nothing and this is the single largest area of the wall |
| Beams, kick plates, hazard bands, railings | **Primitives** | Flat slabs and tubes |
| Light strips and glows | **Primitives** | Neon slabs are correct here |

⚠️ **The repeat count is the constraint.** A perimeter wall is the most-repeated geometry in the
game, so a heavy mesh is multiplied ~60×. Meshy should produce **few, tileable** pieces — a panel, a
pipe section, a bezel — not a whole wall.

## Proposed build order

1. Agree the wall type mix (B for most of the perimeter, A behind buildings, C as punctuation).
2. Generate the tileable panel + pipe section in Meshy. Two meshes, ~30 credits each with texture.
3. Build one 32-stud wall section in the editor from primitives + those meshes.
4. **Look at it at eye level** before repeating it. Every mistake so far has come from judging
   geometry from above.
5. Repeat around the perimeter once the section is right.
