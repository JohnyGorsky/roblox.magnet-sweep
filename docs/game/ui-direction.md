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
