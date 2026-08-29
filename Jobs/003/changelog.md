# Changelog — Job #003

*No player-facing changes yet. This job laid the foundation every later system builds on.*

- ⚙️ Every gameplay number now lives in one place and can be tuned without touching code.
- 🛡️ Rate limiting is **structural**: handlers are bound through a wrapper that applies it, so a
  future endpoint cannot quietly ship without one.
- 🧪 Dev tools that make a randomised game debuggable — reachable in a playtest via `dev("help")`.
- 🔍 The server audits its own config at startup and refuses to run in Studio if something is broken.
