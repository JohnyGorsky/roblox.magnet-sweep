# 10 -- The Scrap Arena

Persistent, server-wide, adjacent to the Workshop.

## Items

- [ ] **P0** Arena geometry and the Arena Core
- [ ] **P0** Release / Withdraw robot, with a queue when full
- [ ] **P0** Arena robot instance built from the Bay robot (disposable clone)
- [ ] **P0** Movement: AlignPosition + AlignOrientation on an unanchored, server-owned root
- [ ] **P0** AI priority ladder: attack / move to core / engage / hold
- [ ] **P0** Scripted hitboxes from AI state -- NOT from limb positions
- [ ] **P0** Combat resolution, server-authoritative
- [ ] **P0** Knockback: drop aligner MaxForce, apply impulse, play Knockback
- [ ] **P0** HP persistence across the deployment; no regeneration
- [ ] **P0** Core control detection and the hold timer
- [ ] **P0** Arena Heat escalation: 0-90s, 90-180s, 180-300s, 300s+ x4
- [ ] **P0** ROBOT DISABLED: collapse, sparks, smoke, crane removal
- [ ] **P0** Animation profiles: the ~10 combat clips x10
- [ ] **P0** Shared clips: Idle, WalkWheels, WalkLegs, WalkTracks, Hover, HitFront, HitBack, Knockback, Stunned, ArenaEnter, Victory, Defeat x12
- [ ] **P0** Damage visual stages at 75/50/25/10% x4
- [ ] **P1** Arena panel GUI: champion, owner, hold time, HP, defeats
- [ ] **P1** Arena notifications while in the factory x3
- [ ] **P1** **Measure** concurrent robot count at 30fps on a mid phone
- [ ] **P2** Owner disconnect handling for a deployed robot

---

**47 items** — P0 41 · P1 5 · P2 1

> Counted by `tools/gen-build-manifest.py`. The last `xN` on a line is that line's count.
