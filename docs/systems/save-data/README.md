# Save data

Follow the shared `roblox-data` skill for the API, session locking, budgets and the
load / auto-save / `PlayerRemoving` / `BindToClose` lifecycle. This page is what MAGNET SWEEP stores and
the rules specific to it.

## The profile

Persisted (section 68):

- Coins
- Magnet Power, Radius, Drive, Capacity upgrade levels
- Zone progression
- **Secured** Robot Parts
- Installed robot configuration
- Part reinforcement levels (Mk I / II / III)
- Robot name
- Collection archive
- Arena statistics
- Cosmetics owned and equipped
- Endgame progression: Magnet Core Level, Endless Line distance

## Never persisted

- **Unsecured carried rare cargo.** This is the anti-extraction-exploit rule and it is load-bearing —
  [decision 0008](../../decisions/0008-secured-at-the-hub-not-in-hand.md).
- Current scrap in hand? *Open question — see below.*
- Anything about the live Arena state. The Arena is per-server and dies with it.

> 🔴 **Autosave must exclude the carried slot entirely.** Not "skip if carrying" — the carried slot is
> not a field the save path can see. A well-timed disconnect must be structurally unable to write it.

## The rules that prevent data loss

1. **Never overwrite a profile after a failed load.** A DataStore read failure must never be written
   back as defaults. This is the single most expensive bug a progression game can ship.
2. **Session locking.** One server owns a profile at a time; that is what prevents duplication across a
   fast rejoin.
3. **`UpdateAsync`, not `GetAsync` + `SetAsync`**, for anything incremented.
4. **`BindToClose`** must flush. A server shutdown mid-session is normal, not exceptional.
5. **Grants are idempotent.** Every Coin grant, part secure and purchase carries an id so a retried
   remote cannot double-pay.

## Versioning

The profile carries a schema version from the first write. Migration is a function per version step, run
on load, never a "if the field is nil, guess" scatter through the codebase.

## Death (section 69)

Mild. Respawn at the latest Service Hub. Normal scrap auto-recycles at reduced value. Unsecured rare
cargo is lost. **Existing progression is always safe** — Coins, upgrades and secured parts are never
touched by death.

## Open

| Question | When |
|---|---|
| Does uncollected scrap in Capacity survive a disconnect, or auto-recycle like on death? Auto-recycle is consistent and closes a hoarding exploit | before the first save ships |
| Does the Part Archive store *discovered* or *secured*? A part seen but lost is a different fact | before the Archive ships |
