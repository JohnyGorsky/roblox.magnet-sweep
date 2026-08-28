# UI & HUD

Policy is [game/ui-direction](../../game/ui-direction.md). Visual tokens are the
[`magnet-sweep-style` skill](../../../.claude/skills/magnet-sweep-style/SKILL.md). Engineering is the
shared `roblox-ui` skill; measurement is `mobile`. This page is the screen inventory.

## Screens

| Screen | Where | Contains |
|---|---|---|
| **Main HUD** | always | Coins · Flow (when active) · Scrap · upgrade button · robot/Arena widget |
| **Cargo HUD** | while carrying | part name, weight, speed penalty, distance to hub, security state |
| **Magnet Lab** | Workshop / Service Hub | four stat tracks, costs, next-tier preview |
| **Recycler** | Workshop / Service Hub | scrap → Coins, with the repair alternative shown alongside |
| **Repair** | Workshop / Service Hub / chute | scrap → HP, efficiency, cooldown |
| **Robot Builder** | Robot Bay | 3D preview, seven slots, owned parts, stats, reinforcement |
| **Part Archive** | Workshop wall | per-zone silhouettes, completion, cosmetic rewards |
| **Arena panel** | near the Arena | champion, owner, hold time, HP, defeats; Release / Withdraw / Repair |
| **Zone gate** | at each gate | required vs current Magnet Power |
| **Shop** | Workshop | passes, products, cosmetics |
| **Loading** | boot | see [boot](../boot/README.md) |

## Banners

Full-width, all-caps, short-lived, one line, no lore:

**MAGNET RUSH!** · **SCRAP FULL** · **SALVAGE BREACH** · **FACTORY REFRESH IN 00:20** ·
**FACTORY REFRESH** · **SECURED** · **⚡ LEGENDARY PART DETECTED** · **GIANT SPOON INSTALLED** ·
**ROBOT DISABLED** · **👑 ARENA CONTROL**

## Diegetic first

Where a thing can be a world object instead of a HUD element, it should be. The Arena status is a
physical display in the Workshop. The zone gate requirement is written on the gate. The Part Archive is a
wall. Scrap crates fill up visibly.

This is the main defence against the genre's wall-of-buttons default.

## The recycle/repair moment

The one screen that must be *hard to skim*. When the player opens the Recycler, both exits are shown
together with real numbers:

```
   150 SCRAP
   ♻ RECYCLE  → 3,600 Coins        🔧 REPAIR → +900 Robot HP
```

Never pre-select one. Never show only the one the player used last.

## Mobile

Laid out against the measured safe area and Roblox's reserved thumbstick and jump-button regions from
the first element. `UIScale` + `UIAspectRatioConstraint`, not pixel `MinSize` floors — those break on
high-DPI devices. Verified in the Device Emulator, at the low quality tier
([decision 0012](../../decisions/0012-mobile-first-quality-tiers.md)).

Tap targets: the upgrade button, the Release Robot button and the Recycler/Repair choice are the three
that must survive a thumb.
