# The build manifest

Everything that must be made, sized so one item is one sitting. Ordered **MVP-first**, around
[the gate](../roadmap/mvp.md#the-gate) — not by the spec's own phase list (section 85), which builds
outward from magnet physics without ever asking whether the game is fun yet.

> **Looking for what to do next?** This page is organised **by system**, which is how you find
> things. For the **work order**, see **[the job ladder](job-order.md)** — the same items sliced
> into 28 job-sized pieces in dependency order, with what each one needs from a human.

**Priorities:** `P0` must exist for the group to be usable · `P1` launch · `P2` post-launch.

> ⚠️ **`P0` is not the same as "in the MVP".** Groups **01-12** are the MVP. Groups **13** (zones 3-12)
> and **14** (endgame, monetisation, launch) are gated behind
> [the gate](../roadmap/mvp.md#the-gate) and their contents are in the MVP's **Out** column — their
> P0 items are P0 *within their own group*, not MVP work. The MVP figure is the one that matters for
> scheduling.

> **Counting rule.** The **last `xN` on a line is that line's item count**; a line with no `xN` is one
> item. So `passes x4, dev products x4, ProcessReceipt ... x9` is **9** items -- not 17, and not 1.
> ELEVATOR 13's manifest reported 319 items by counting `xN` rows as one each; the honest count was 577.
>
> Every total on this page is **computed** by `tools/gen-build-manifest.py`, never typed. Re-run it
> after editing an item list -- the generator, not this file, is the source of truth.

## Groups

| # | Group | Items | P0 | P1 | P2 |
|---|---|--:|--:|--:|--:|
| [01](01-foundation.md) | Foundation & sync | 23 | 21 | 2 | 0 |
| [02](02-industrial-kit.md) | The industrial kit & material system | 47 | 40 | 6 | 1 |
| [03](03-lighting-and-look.md) | Lighting, atmosphere & quality tiers | 18 | 15 | 2 | 1 |
| [04](04-magnet-core.md) | The magnet -- the whole game in one system | 37 | 34 | 2 | 1 |
| [05](05-workshop.md) | The Workshop hub | 18 | 14 | 3 | 1 |
| [06](06-boot-and-hud.md) | Boot, loading & the main HUD | 17 | 13 | 4 | 0 |
| [07](07-zones-1-2.md) | Zone 1, Zone 2 and the first Service Hub | 34 | 27 | 7 | 0 |
| [08](08-cargo-and-escape.md) | Rare cargo, extraction & guardians | 29 | 27 | 2 | 0 |
| [09](09-robot.md) | The robot: rig, assembly and the Bay | 50 | 39 | 9 | 2 |
| [10](10-arena.md) | The Scrap Arena | 47 | 41 | 6 | 0 |
| [11](11-economy-and-save.md) | Economy, repair and persistence | 19 | 14 | 4 | 1 |
| [12](12-refresh-and-events.md) | Factory Refresh, Shifts & events | 19 | 4 | 6 | 9 |
| [13](13-zones-3-12.md) | The remaining ten zones | 155 | 130 | 25 | 0 |
| [14](14-endgame-and-launch.md) | Endgame, monetisation & launch | 68 | 19 | 46 | 3 |
| | **Total** | **581** | **438** | **124** | **19** |
| | *of which **MVP** (groups 01-12)* | *358* | *289* | *53* | *16* |
| | *post-gate (groups 13-14)* | *223* | *149* | *71* | *3* |

## The order, and why

**01 Foundation** blocks everything — every file later groups write assumes the sync layout, and every
number they tune assumes the config modules.

**02-03 Kit and lighting** come before any room, because 70-80 % of the world is kit
(section 64) and because every later visual judgement is made against the lighting baseline.

**04 Magnet** is deliberately fourth and not first-after-plumbing. It needs the kit to have anything to
sweep, and it needs the lighting to look like the game. But it is **the gate** — a grey room and a pile
of bolts is enough to answer whether sweeping is satisfying, and if it is not, groups 05 onward are
wasted.

**05-08** build outward from the magnet to the loop: hub, HUD, two zones, then the extraction that gives
sweeping a point.

**09-10** are the second half of the game. The rig comes before the Arena because the Arena is just
robots fighting, and the rig is what a robot *is*.

**11-12** close the loop: the economy pinch, persistence, and the refresh that stops the world going
stale. The refresh is **P0** on purpose.

**13-14** are gated on the MVP question getting a yes.

## What is not in here

Per-part balance numbers. The [parts catalog](../content/parts-catalog.md) lists 96 parts with slots,
rarities and effects, but **no part has damage, attack speed, knockback, range, HP, armour, weight or a
Magnet Power requirement yet**. That is per-tier balance work and it belongs to the tier's own group,
not to a manifest line.

Also absent: asset ids. None should be sourced until a slot needs one
([PITFALLS #24](../PITFALLS.md#24-placeholders-are-worse-than-empty-slots)).

