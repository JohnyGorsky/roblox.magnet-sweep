# Job #016: The magnet becomes a real object

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31 11:16:04
**Status**: Requirements Gathering (intake)

## Requirements / goal

The player's magnet -- the hero object of a game called MAGNET SWEEP -- is currently three welded boxes on the right hand (MagnetController.buildMagnet: a 1.6x0.5x0.5 Core bar plus two 0.5x1.3x0.5 poles). Replace it with the Meshy-generated hero mesh already produced in job 015: assets/generated/magnet/magnet.fbx (and .glb), 7,595 triangles, with base_color/metallic/roughness/normal PBR maps, generated image-to-3d from a cleaned reference derived from our own assets/concept_art/Robot.png. Style SKILL section 3 reserves meshes and SurfaceAppearance for exactly this class of object. HARD CONSTRAINTS: Magnet.TIP_OFFSET must not move -- the server sizes its grant range off that number and cannot see the rig; the magnet stays red + cyan per style section 2; set CollisionFidelity appropriately on import; and the mesh must not regress the Low quality tier, which drops SurfaceAppearance entirely. The GLB import itself is a human action in Studio (File > Import) because no MCP tool can import a mesh.

## Checklist

- [ ] Requirements reviewed (this intake)
- [ ] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [ ] **Symptom reproduced in PLAY**, at the player's camera, before any fix (GROUND-RULES 7)
- [ ] Implementation plan created & agreed
- [ ] Implementation completed
- [ ] **Proof it works better** captured - before/after from the same camera, in Play
- [ ] Final summary + changelog written
