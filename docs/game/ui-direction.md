# UI direction

Engineering rules are in the shared `roblox-ui` skill; measurement is in `mobile`; visual tokens are in
the [`magnet-sweep-style` skill](../../.claude/skills/magnet-sweep-style/SKILL.md). This page is the
*policy*.

## The rule that overrides all others

Section 55: **keep the screen clean. Do not fill it with simulator buttons.**

This game's competition is a genre defined by walls of coloured buttons. Not doing that is a positioning
decision, not just taste. If a thing can be a world object instead of a HUD element, it should be.

## The main HUD

| Position | Element | Visible |
|---|---|---|
| Top left | 🪙 Coins | always |
| Top centre | MAGNET FLOW x4 | **only while active** |
| Bottom centre | Scrap 72 / 100 | always |
| Bottom right | Upgrade button | always, small |
| Side | 🤖 1,840 / 3,200 HP · 👑 Arena 01:42 | compact widget |

That is the whole persistent HUD. Everything else is contextual.

### Built, and where touch differs — measured, job 011

The table above is what desktop ships. Two of its five positions are unavailable on a phone, and the
reason is measured rather than aesthetic. On the Device Emulator's phone preset, in Play:

| | |
|---|---|
| `Camera.ViewportSize` | 666 × 374 |
| `GuiService:GetGuiInset()` | (0, **58**) |
| Usable canvas, `CoreUISafeInsets` | **666 × 316** ← size everything from this |
| `DynamicThumbstickFrame` | x −100..266 · y 105..416 |
| `JumpButton` | x 571..641 · y 226..296 |

`TouchGui` rects and a `CoreUISafeInsets` element's `AbsolutePosition` share one coordinate space, so
they compare directly. (`ScreenInsets = None` does not: its origin sits 58 px higher.)

**The consequence, and it is not obvious.** The free bottom band is x 266..571, and its centre is
**x ≈ 418 — not the canvas centre, 333**. Anything "centred at the bottom" on a phone is sitting inside
the movement control.

So:

- **Scrap stays at the bottom on both layouts**, as above. On touch it is centred in the *free band*
  rather than on the canvas — derived at runtime from Roblox's own live rectangles
  (`Ui.Layout.freeBottomSpan`), not from the numbers in this table, so the day Roblox moves a control
  the HUD moves with it. If a device has no usable band it falls back to a top-left vitals column.
- **The upgrade button moves to the top right on touch.** Bottom-right is the jump button. Top-right
  is free, clear of both thumbs, and the button is a menu opener rather than a twitch control.
- **A modal owns the screen.** The upgrade panel sets `UserInputService.ModalEnabled`, which switches
  Roblox's touch controls off for as long as it is open. There is no position that both fits a panel
  and clears the controls, so the supported answer is to hide them.

**Not built, and deliberately not faked:** the robot/Arena widget is wired to `ArenaStateChanged` and
stays hidden, because nothing fires that remote until groups 09/10. It draws no invented HP and no
placeholder timer (ground rule 10).

## Rare cargo HUD

Replaces nothing; appears while carrying:

```
GIANT SPOON
⚖ Heavy      ⚡ Speed -18%
🏠 Service Hub: 142m
🚨 Security Alert
```

Plus a guardian proximity indicator when one is relevant. This panel is doing real work — it is the
player's only readout during the most tense 45 seconds in the game — so it may be larger than it
otherwise would be.

## Three seconds to understand

Every banner states the situation in one line, in caps, with no lore: **SALVAGE BREACH** ·
**FACTORY REFRESH IN 00:20** · **SECURED** · **MAGNET RUSH!** · **⚡ LEGENDARY PART DETECTED**.

## Robot Builder

A large 3D robot preview with the seven slots arranged around it. Selecting a slot lists owned parts for
it; each shows tier, stats, signature effect, reinforcement level and a preview. The robot in the
preview is the *actual* robot, not an icon.

## Arena panel

Shown near the Arena: current champion, owner, control time, HP, defeats. Buttons: **RELEASE ROBOT**,
**WITHDRAW ROBOT**, **REPAIR**. A queue position if the Arena is full.

## Feedback contract

- Every button has a pressed state, a sound and a short scale tween. Silence reads as broken.
- Numbers animate on change: count up, then a scale punch.
- Nothing important is communicated by colour alone — pair it with an icon or a word.

## Mobile

Laid out against the **measured** safe area and Roblox's own reserved thumbstick and jump-button
regions, from the first HUD element — not adjusted later. See
[decision 0012](../decisions/0012-mobile-first-quality-tiers.md) and the `mobile` skill. A pixel
`MinSize` floor is not a substitute for measurement; it breaks on high-DPI devices.
