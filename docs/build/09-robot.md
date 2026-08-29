# 09 -- The robot: rig, assembly and the Bay

Architecture is [systems/robot-rig](../systems/robot-rig/README.md). Build the engine before the second
part exists, or there will be a special case in a script forever.

## Items

- [ ] **P0** The ~10-joint skeleton with Motor6D and invisible pivot carriers
- [ ] **P0** `AnimationController` + `Animator` setup (NOT a Humanoid)
- [ ] **P0** Socket set: Head, Core, Body, LeftArm, RightArm, Mobility, Back x7
- [ ] **P0** `RobotMount` attachment convention + an import checklist
- [ ] **P0** Mount/unmount: align RobotMount to socket, WeldConstraint, Massless, CanCollide=false
- [ ] **P0** Part definition schema: PartId, Slot, Tier, Rarity, Weight, AnimationProfile, CombatStats, VFX, Sound x9
- [ ] **P0** 12-16 MVP parts modelled with mounts and stats x16
- [ ] **P0** Robot Builder GUI: 3D preview, seven slots, owned parts, stats
- [ ] **P0** Install sequence: crane, KRRRK, VRRRR, CLUNK, bolts, practice swing
- [ ] **P0** Robot name + Roblox text filtering, in every display context
- [ ] **P1** Duplicate handling: REINFORCE Mk I/II/III, or RECYCLE x2
- [ ] **P1** Part Archive wall logic -- a silhouette fills on SECURED, never on sighting
- [ ] **P1** Mobility sub-rigs: wheels, legs, tracks, hover -- ONE shared locomotion clip, only Legs needs a walk cycle x4
- [ ] **P1** Decorative actuators: HingeConstraint spin, PrismaticConstraint punch x2
- [ ] **P2** `IKControl` head tracking
- [ ] **P2** `IKControl` aim for ranged profiles

---

**50 items** — P0 39 · P1 9 · P2 2

> Counted by `tools/gen-build-manifest.py`. The last `xN` on a line is that line's count.
