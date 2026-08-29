# 01 -- Foundation & sync

Nothing else can be trusted until this group is done. Every file every later group writes to disk
assumes the sync layout, and every balance number later groups tune assumes the config modules exist.

## Items

- [ ] **P0** Create the MAGNET SWEEP place; record its id in `docs/systems/places/README.md` and the project skill
- [ ] **P0** Decide place settings deliberately: access, social slots, `MaxPlayers` x3
- [ ] **P0** Enable and configure `StreamingEnabled` -- radius, behaviour, target radius
- [ ] **P0** **Probe the sync layout over MCP** -- flat vs nested, per service folder
- [ ] **P0** Probe which file suffix produces which class; specifically whether `.client.luau` in `StarterPlayerScripts` runs twice
- [ ] **P0** Rewrite `.jobconfig.json` with what was OBSERVED; clear the `UNVERIFIED` status
- [ ] **P0** Shared config module structure: `Config/Magnet`, `Config/Zones`, `Config/Parts`, `Config/Arena`, `Config/Economy`, `Config/Quality` x6
- [ ] **P0** Remote definitions module -- one place that names every RemoteEvent/Function
- [ ] **P0** Server-side rate limiter used by every remote
- [ ] **P0** Logging/telemetry helper with a level switch
- [ ] **P0** Dev/test configuration: forced Factory Shift, jump-to-zone, grant Magnet Power, spawn a named part x4
- [ ] **P1** `tools/luau-analyze.sh` equivalent for this repo, with ABSOLUTE paths
- [ ] **P1** Sourcemap / Rojo project file if the probe shows one is needed

---

**23 items** — P0 21 · P1 2 · P2 0

> Counted by `tools/gen-build-manifest.py`. The last `xN` on a line is that line's count.
