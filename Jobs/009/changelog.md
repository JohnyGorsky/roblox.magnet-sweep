# Changelog — Job #009

*No new features. Three of the four things the quality setting was supposed to change were not
changing anything.*

- 📱 **The low-detail setting now actually saves work.** Scrap kept getting its glossy PBR
  textures put straight back on, so phones were paying for a look they had opted out of. They
  are not any more.
- 🔦 **Light detail responds to the setting** — bright, far-reaching lights are dimmed back on
  lower tiers instead of being left exactly as they were on every device.
- 🎬 **The high tier looks different from the middle one**: depth of field was switched on in
  the settings and switched off in the code.
- 🎚️ **The game waits until it has loaded before deciding how fast your device is.** It used to
  judge during the loading screen, when almost nothing is being drawn — so a phone could decide
  it was a gaming PC and struggle for the first minute.
