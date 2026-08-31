# Implementation Plan — Job #016

**Project**: `roblox.magnet-sweep`
**Created**: 2026-08-31
**Status**: ⏸ Blocked on one manual Studio step (see *What I need from you*)

## Analysis

### What the hero object is today

`MagnetController.buildMagnet` welds **three boxes** to the right hand:

| Part | Size | Colour |
|---|---|---|
| `Core` | 1.6 × 0.5 × 0.5 | `Vfx.CORE` |
| `PoleRed` | 0.5 × 1.3 × 0.5 | `Vfx.RED` |
| `PoleCyan` | 0.5 × 1.3 × 0.5 | `Vfx.CYAN` |

Plus an invisible `Tip` at `Magnet.TIP_OFFSET`. That is the thing a player looks at for an entire
session, in a game called MAGNET SWEEP.

Style [§3](../../.claude/skills/magnet-sweep-style/SKILL.md) already says where this belongs:
`SurfaceAppearance` *"is reserved for the hero meshes — magnets, the Arena Core, guardians, robot
parts."* This is the first object in the game that qualifies.

### The mesh, and how it was made

Generated during job 015, from **our own art** rather than from a prompt:

`assets/concept_art/Robot.png` → crop the magnet → `image_to_image` ×2 (isolate it, then remove the
crane arm and frame it whole) → `image_to_3d` (meshy-7, PBR, 4K, triangle, remesh to 8 000).

**48 credits total** (9 + 9 + 30). Balance was 1,240.

| | |
|---|---|
| Triangles | **7,595** — under Roblox's documented 20,000-per-mesh limit |
| Bounding box | 1.371 × 1.901 × 0.721 (tall, narrow, shallow — a horseshoe) |
| Maps | `base_color` 4096², `normal` 4096², `metallic` 2048², `roughness` 2048² |
| Files | `assets/generated/magnet/magnet.glb` (16 MB), `magnet.fbx` (31 MB) + loose PNGs |

**Geometry verified before asking anyone to import it.** No thumbnail comes back from the API, so the
GLB was parsed and software-rendered from four angles into `assets/generated/magnet/_preview.png`.
The silhouette is unambiguously a horseshoe magnet with a housing block. That check could have
failed — a fused blob would have been obvious — and it did not.

⚠️ **The 4K textures were a mistake, stated plainly.** They were chosen for a "hero object", but
Roblox resamples uploaded images down anyway and this magnet is a hand-held prop a few dozen pixels
tall on a phone. 2K would have cost the same credits and produced a far smaller import. Not worth
regenerating — worth not repeating.

### The one step no tool can do

There is **no MCP tool that imports a mesh**. The Studio MCP offers `generate_mesh` and
`generate_procedural_model` (Studio's own AI) and `insert_asset` (needs an id that already exists);
none of them takes a local `.glb`/`.fbx`. `upload_image` is images only — verified, it rejects local
paths *and* non-image assets.

So the import is a human action. Per the official
[3D Importer docs](https://create.roblox.com/docs/art/modeling/3d-importer), it is **File → Import**,
and the documented formats are **`.fbx`, `.obj`, `.gltf`**.

⚠️ `.glb` is **not** in that documented list, though it is the same format in binary form and Studio
does generally accept it. Hence both files exist: try the GLB first (one file, textures embedded), and
fall back to the FBX plus the four loose PNGs if the dialog will not take it.

### Hard constraints this job must not break

1. 🔴 **`Magnet.TIP_OFFSET` must not move.** The comment in `buildMagnet` is explicit: *"the server
   sizes its grant range off this number and cannot see the rig, so a tip moved only here starts
   failing honest collections."* The mesh gets fitted **around** the existing tip, never the reverse.
2. 🔴 **Red + cyan, always** (§2). The generated texture is red with chrome and blue LEDs; the
   **poles** still have to read cyan-north / red-south, and `Vfx.RED` / `Vfx.CYAN` stay the source of
   those colours so a future skin recolours field and poles together.
3. ⚠️ **The Low quality tier drops `SurfaceAppearance` entirely**
   ([0016](../../docs/decisions/0016-low-tier-drops-the-variant.md)). So the magnet must still read
   correctly with the PBR stripped — meaning the base `Color` and shape carry it, not the maps.
4. ⚠️ `CollisionFidelity` — the rig is `CanCollide = false`, so this is about cost, not walkability.
   `Box` is correct here; the [Meshy import default](../../docs/PITFALLS.md) matters for scenery, not
   for a massless hand prop.

## Implementation steps

1. **You import the mesh** (see below) and tell me what it landed as.
2. I read the imported `MeshPart` back over MCP — `MeshId`, `TextureID`, size, whether the importer
   built a `SurfaceAppearance` — rather than assuming any of it.
3. Rewrite `buildMagnet` to weld the `MeshPart` in place of the three boxes, sized and oriented so
   the existing `Tip` still sits exactly at `Magnet.TIP_OFFSET`.
4. Keep the cyan/red pole reads, from `Vfx.CYAN` / `Vfx.RED`.
5. Check `QualityController`'s Low path still produces something sensible.
6. `tools/luau-analyze.sh`, then verify in **Play** at the player's camera: before/after from the same
   angle, plus a frame-time comparison since this adds a textured mesh to every character.
7. Independent reviewer agent.

## What I need from you

- [ ] 🔴 **Import the mesh.** In Studio: **File → Import**, choose
      `assets\generated\magnet\magnet.glb`. If the dialog will not accept `.glb`, use `magnet.fbx`
      and point it at `assets\generated\magnet\magnet_textures\` for the four maps.
      Settings that matter: **Scale Unit = Studs**, and leave **Rig Type = No Rig** (this is a prop,
      not a character). Then tell me the name it appeared under in the Explorer.
- [ ] Preview it first if you like: `assets/generated/magnet/_preview.png` is the geometry from four
      angles, and `assets/generated/magnet-ref.png` is the source image it was built from.

## Verification - MANDATORY GATES (GROUND-RULES 7)

- [ ] **Reproduced in PLAY**, at the player's camera angle
- [ ] Before/after from the SAME camera, and the "before" is kept
- [ ] No world fact asserted from a constant - measured instead

### Checks

- [ ] **`Magnet.TIP_OFFSET` unchanged**, and the `Tip` part's world position relative to the hand is
      identical before and after. *Failure: collection range silently changes and honest pickups
      start failing — a gameplay bug with a purely visual cause.*
- [ ] **The mesh actually renders**, not a grey untextured blob. *Failure: `SurfaceAppearance`
      missing or `MeshId` unset, which looks like a lighting problem and is not.*
- [ ] **Poles still read cyan and red.** *Failure: the generated texture's own colours win and the
      magnet stops being the game's logo.*
- [ ] **Low tier still legible** with `SurfaceAppearance` stripped. *Failure: on a phone the hero
      object becomes a flat grey shape.*
- [ ] **Frame time measured with the mesh vs the three boxes**, on the phone preset. *Failure: a
      7,595-triangle textured mesh on every character costs more than anyone checked.*
