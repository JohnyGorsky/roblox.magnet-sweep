# 02 -- The industrial kit & material system

70-80% of the world is built from this group (section 64). Build the kit before building any room.
The material variants are what make the concept art's gloss possible -- see the
[`magnet-sweep-style` skill](../../.claude/skills/magnet-sweep-style/SKILL.md).

## Items

- [ ] **P0** The nine `MaterialVariant`s: Chrome, SteelBrushed, SteelDark, PaintedGloss, PaintedWorn, HazardStripe, Rubber, Grate, Rust x9
- [ ] **P0** Source or generate the PBR texture set for each variant (colour/normal/metalness/roughness) x9
- [ ] **P0** Floor kit: plain, hazard, conveyor, grated x4
- [ ] **P0** Wall kit: solid, pipes, windows, machines x4
- [ ] **P0** Structure kit: pillar, corner, gate, bridge, ramp, platform x6
- [ ] **P0** Industrial kit: conveyor, generator, tank, pipe run, control panel, fan x6
- [ ] **P0** Neon slab sign component -- housing, chamfered bezel, Neon text panel, matching PointLight
- [ ] **P0** Hazard-stripe tiling that survives scaling
- [ ] **P1** Warning beacon (caged amber, rotating)
- [ ] **P1** Scrap crate props in red/blue/yellow x3
- [ ] **P1** Yellow robot arm prop with black joints, animatable
- [ ] **P1** Conveyor motion by texture offset (NOT physics)
- [ ] **P2** Kit placement tool for the Studio plugin/command bar

---

**47 items** — P0 40 · P1 6 · P2 1

> Counted by `tools/gen-build-manifest.py`. The last `xN` on a line is that line's count.
