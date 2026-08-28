# Scrap

Ordinary collectable material. The volume layer, the sound layer, and the input to the economy's central
decision.

## What scrap is

Small metal objects, themed per zone: screws, nuts, washers, bolts, gears, springs, metal beads, small
pipes in tier 1; toy mechanisms in tier 2; kitchenware in tier 3, and so on up to space hardware.

Scrap goes into **Capacity**. When Capacity is full: **SCRAP FULL**, and an arrow points to the nearest
Recycler.

## The two exits

This is the whole economy, and it is deliberately a dilemma
([economy](../economy/README.md)):

```
        150 SCRAP
        /        \
   ♻ RECYCLE     🔧 REPAIR
   3,600 Coins   +900 Robot HP
```

Coins buy magnet upgrades. HP keeps your robot in the Arena. There is no correct answer and the game
never suggests one.

## Sound families

Section 15 is not decoration; it is a system. Each object family has its own voice, and the pitch rises
with Magnet Flow.

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
| Rare part | low-frequency hit + sparkle |

See [audio](../audio/README.md). The game is headphone-recommended and the store page says so.

## Refresh

Scrap repopulates every **30-60 seconds** from the pool
([decision 0006](../../decisions/0006-the-factory-refreshes.md)). A refresh re-poses pooled objects; it
never allocates.

## Pooling

Mandatory from the first prototype. Collected scrap is returned to a pool, re-anchored, hidden, and
reused by the next refresh.

> 🔴 **The leak that breaks the budget:** an object returned to the pool without `Anchored = true` stays
> in the physics solver forever. The check is a count of unanchored parts during a Magnet Rush — see
> [decision 0005](../../decisions/0005-four-state-scrap-budget.md).

## On death

Section 69: normal scrap auto-recycles at **reduced value** rather than vanishing. Death should be mild.
The thing you actually lose on death is unsecured rare cargo — see [cargo](../cargo/README.md).
