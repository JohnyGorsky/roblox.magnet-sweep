# Changelog — Job #002

*No player-facing changes. This job measured how the project connects to Roblox Studio.*

- 🔌 The MAGNET SWEEP place is live and connected — `111667188608192`, with streaming already enabled.
- 📐 The sync layout is now **observed rather than guessed**: flat, six synced service folders, five that
  do not sync at all.
- 🪤 Two traps caught before they could cost anything: a `.client.luau` in `StarterPlayerScripts` runs
  **twice**, and deleting a file leaves its script alive in Studio.
