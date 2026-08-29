# 08 -- Rare cargo, extraction & guardians

The 45 seconds the game is arranged around.

## Items

- [ ] **P0** Rare part as physical carried cargo -- floats, drags, swings, sparks
- [ ] **P0** One rare part carried at a time; separate from Capacity
- [ ] **P0** Weight classes and speed penalties, with a floor x4
- [ ] **P0** Detach sequence: shake, electricity, GRRRRR, CLANG
- [ ] **P0** Server-side Magnet Power detach check
- [ ] **P0** SALVAGE BREACH -- alarm, beacons, red wash, zone-wide
- [ ] **P0** Guardians are INERT until a part is stolen; only the OWNING guardian activates
- [ ] **P0** Guardian 1: Slow Scrap Sweeper Bot -- patrol, detect, pursue across zones, catch
- [ ] **P0** Guardian 2: Wind-Up Security Bot
- [ ] **P0** Layered detection: distance, radius overlap, line-of-sight raycast x3
- [ ] **P0** Guardian home territory + the boundary test (decision 0014)
- [ ] **P0** Caught INSIDE its territory -> the part RESETS to its spawn
- [ ] **P0** Caught OUTSIDE -> ragdoll, part drops NEUTRAL, any player may take it
- [ ] **P0** Guardian give-up + RETURN HOME state, so it is never stranded out of its zone
- [ ] **P0** Ownership protection window after detach
- [ ] **P0** SECURED at the Service Hub -- the payoff moment: banner, sound, light, VFX
- [ ] **P0** Profile write on SECURED, and ONLY on SECURED
- [ ] **P0** Cargo HUD: name, weight, speed penalty, distance to hub, security state x5
- [ ] **P1** Guardian proximity indicator
- [ ] **P1** Death: respawn at last hub, scrap auto-recycles at reduced value

---

**29 items** — P0 27 · P1 2 · P2 0

> Counted by `tools/gen-build-manifest.py`. The last `xN` on a line is that line's count.
