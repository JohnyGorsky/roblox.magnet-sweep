# 06 -- Boot, loading & the main HUD

Build the loading screen early (section 7), not at the end. A loading screen retrofitted over a running
game fights every system it wraps.

## Items

- [ ] **P0** `ReplicatedFirst` handoff -- remove the default screen immediately
- [ ] **P0** Loading screen art: player, magnet, flying scrap, robot, corridor
- [ ] **P0** Progress driven by REAL stage completion, not a timer
- [ ] **P0** Object-per-tick loading sound, CLANG on complete
- [ ] **P0** Title card
- [ ] **P0** Main HUD: Coins, Flow, Scrap, upgrade button, robot/Arena widget x5
- [ ] **P0** Banner system (one line, all caps, short-lived)
- [ ] **P0** Mobile safe-area layout measured in the Device Emulator
- [ ] **P0** Number animation: count-up then scale punch
- [ ] **P1** Button sound + pressed state + scale tween, applied globally
- [ ] **P1** Failure paths: profile load failed, streaming slow, joined mid-Refresh x3

---

**17 items** — P0 13 · P1 4 · P2 0

> Counted by `tools/gen-build-manifest.py`. The last `xN` on a line is that line's count.
