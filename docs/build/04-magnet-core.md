# 04 -- The magnet -- the whole game in one system

**This group is the gate.** If sweeping is not satisfying here, nothing downstream saves it. Build it
before there is a factory to sweep in -- one grey room and a pile of bolts is enough.

## Items

- [ ] **P0** Magnet tool/model attached to the character, red/cyan poles
- [ ] **P0** Four-state object machine: IDLE / REACT / PULL / COLLECTED
- [ ] **P0** Object pool -- allocate once, re-pose forever, **re-anchor on return**
- [ ] **P0** `MaxConcurrentPull` cap with a REACT waiting queue
- [ ] **P0** Client pull motion: slide, lift, rotate, accelerate, arc into the magnet
- [ ] **P0** Pull force curve: fast under Power, slow + straining near it, **shakes and refuses** above it
- [ ] **P0** Radius drives BOTH ranges, REACT ~40% beyond PULL
- [ ] **P0** Server collection grant, BATCHED on a tick -- never one remote per object
- [ ] **P0** Server validation: the object must be one the server spawned
- [ ] **P0** Magnet Power / Radius / Drive / Capacity stats, read from config x4
- [ ] **P0** Capacity fill + SCRAP FULL state
- [ ] **P0** Magnet Flow x1-x5 with decay
- [ ] **P0** MAGNET RUSH state
- [ ] **P0** Magnet VFX states: idle, pulling, high flow, rush, overcharge x5
- [ ] **P0** Sound families with Flow-driven pitch rise x9
- [ ] **P1** Magnet model upgrades -- a visibly different magnet per power tier
- [ ] **P1** Magnetic Drive speed applied to the character
- [ ] **P2** Magnet skins framework (cosmetic hook, no skins yet)

---

**37 items** — P0 34 · P1 2 · P2 1

> Counted by `tools/gen-build-manifest.py`. The last `xN` on a line is that line's count.
