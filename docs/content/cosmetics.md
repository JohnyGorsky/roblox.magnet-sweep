# Cosmetics

The revenue backbone ([decision 0011](../decisions/0011-robux-never-buys-arena-power.md)), which means
they are not a side dish. If cosmetics are weak, the monetisation stance is not sustainable and the
pressure to sell power comes back.

## The categories (section 72)

| Category | Examples |
|---|---|
| **Magnet skins** | Candy · Electric · Lava · Galaxy · Gold · Glitch · Rainbow |
| **Robot paints** — applied **per part** | construction yellow · candy · military · chrome · neon · galaxy |
| **Robot VFX** | electricity · fire · bubbles · pixels · stars |
| **Victory animations** | played when your robot wins in the Arena |
| **Arena entrances** | played when your robot is released |
| **Trails** | on pulled objects and on the player |
| **Sound packs** | replaces the collection sound family |

## Why these work here

The game is *already* about visible personal expression — your robot is made of objects you chose. A
paint job on a robot built from a fridge door and a spoon is a genuinely different-looking robot, not a
recoloured stock model. Cosmetics compound with the build system instead of competing with it.

**Magnet skins** are the highest-value slot: the magnet is on screen constantly, it is the game's icon,
and it is the object every other player looks at.

**Paints apply per part, not to the whole robot.** Paint the fridge door construction-yellow and leave
the spoon chrome. This matches the mismatched, homemade identity §39 demands — a whole-robot paint would
flatten exactly the look the game is selling — and it sells far better, because **every new part is a
new surface to buy paint for**. The cost is a paint slot per equipped part in the profile and in the
builder UI.

> The magnet stays **red and cyan** in its default form. A skin may recolour it; nothing else may.

## Earned cosmetics

Not everything is sold. Completing a zone's **Part Archive** awards cosmetics — never combat power
(section 41). This keeps the collector track meaningful without making completion mandatory.

The spec lists Arena Fame and cosmetic progression as two *separate* Arena rewards (§45); whether Fame
is spendable *on* cosmetics is unspecified. If it is, that is how the Arena rewards a player who never
spends — worth deciding before the shop ships.

## Rules

- Cosmetics must **never** obscure gameplay information. A robot VFX that hides damage state, or a
  magnet skin that makes the pull radius unreadable, is a bug.
- **Limited cosmetics are fine. Limited gameplay parts are not** (section 82) — a limited part that is
  permanently superior poisons every future season.
- Every cosmetic is visible to *other* players. A cosmetic only its owner can see does not sell twice.

## Open

| Question | When |
|---|---|
| Is there a cosmetic slot for the Arena Core when you hold it? Very visible, very desirable | consider before launch |
| Does a paint carry with the part when it is swapped out and back, or is it a slot property? Carrying with the part is what players will expect | before the first paint ships |
