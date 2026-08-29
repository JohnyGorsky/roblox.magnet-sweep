# Launch

After the MVP gate returns a yes. Not before.

## Scope

- **All twelve zones** with their guardians and full part pools (96 parts).
- **Six Service Hubs**, roughly every two zones.
- **All eight dynamic events**, plus the five Factory Shifts.
- **The Foundry Heart** ending and the Endless Line opening.
- **Overclock** and Magnet Core Level.
- **Five daily leaderboards.**
- **Full cosmetic set** — magnet skins, robot paints, robot VFX, victory animations, arena entrances,
  trails, sound packs.
- **Monetisation live and audited** — every listing checked against what the code actually grants.
- **The Part Archive** with per-zone completion rewards.

## The store description (§4, verbatim from the spec)

```
MAGNET SWEEP 🧲⚡🤖

Start with a tiny magnet.
Pull scrap. Get stronger. Go deeper.
But some scrap isn't scrap...

🥄 Find crazy Robot Parts
🧲 Rip them out with your magnet
🚨 Escape factory security
🤖 Build your own robot
⚔️ Release it into the Arena
👑 Hold the Arena Core
🔧 Repair your robot with scrap
🚗 Eventually pull cars, machines and MUCH bigger things

How deep can you reach?
How long can your robot hold the Arena?

🎧 Headphones recommended.
```

The headphone line is not decoration — it is the promise the
[audio system](../systems/audio/README.md) has to keep.

## Store presence

Icon, four thumbnails and the description are specified in sections 5, 6 and 4:

| Asset | Content |
|---|---|
| **Icon** | large glowing red/cyan magnet, colourful objects and a giant spoon flying in, a ridiculous robot behind (STOP sign, spoon, car door). No complicated text |
| **Thumbnail 1** | hundreds of objects being pulled — **MAGNET RUSH!** |
| **Thumbnail 2** | dragging a huge engine, security robot chasing — **GET IT HOME!** |
| **Thumbnail 3** | a homemade robot entering the arena — **BUILD YOUR ROBOT** |
| **Thumbnail 4** | robots fighting around the glowing Arena Core — **HOLD THE ARENA** |

`assets/concept_art/Robot3.png` is already close to thumbnail 4, and `Logo.png` is the title treatment.

## Pre-launch checklist

- [ ] Place settings decided deliberately: access, social slots, `MaxPlayers`, `StreamingEnabled`
- [ ] **Every live game pass and dev product audited** — an unwired `IsForSale` listing is buyable from
      the website and delivers nothing
- [ ] Save profile versioned, with a migration path and a never-overwrite-a-failed-load guard
- [ ] Mobile measured in the Device Emulator at the low tier, on every screen
- [ ] Arena robot count measured at 30 fps with full VFX
- [ ] All inserted third-party assets scanned for scripts
- [ ] Asset registry complete: what we created vs used, with ids and licences
- [ ] Text filtering on robot names, in every context they display

## Post-launch (section 82)

Daily Factory Modifier · Weekly Legendary Part · Weekend Arena Modifier · limited **cosmetics**.

> Never make a limited gameplay part permanently superior.
