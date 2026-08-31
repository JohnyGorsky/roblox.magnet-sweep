# Final Summary — Job #016

**Project**: `roblox.magnet-sweep`
**Completed**: 2026-08-31
**Status**: ✅ Completed, including the phone-preset pass

## What was implemented

**The player's magnet is a real object.** It was three welded boxes — a 1.6 × 0.5 × 0.5 bar and two
0.5 × 1.3 poles — on the right hand of a game called MAGNET SWEEP. It is now the hero mesh from the
game's own key art: a chunky red-and-cyan horseshoe with chrome pole shoes, gripped at the bend,
**pole faces pointing forward where the player is looking**.

### Two things the owner caught that I had wrong

**1. It was upside down.** The first version hung the magnet straight down with its rounded back at
the ground. The owner: *"why magnet is upside down? the pulling part is not the rounded bet other."*
Correct — the pulling face of a horseshoe is the **open end**, and I had pointed the one part of it
that does nothing at the scrap.

**2. I had built the wrong magnet entirely.** I generated from `Robot.png`, where the magnet hangs
off a robot arm — so its pole faces are **capped by a crane mount**, and it is all-red. The owner
sent `Logo2.png`, the game's own key art, which was **already in the repo** and which I had never
opened. It shows the actual object: a hand-held horseshoe, red arm and cyan arm, chrome pole shoes
at a free open end.

That second one matters beyond this job: the key art satisfies style §2's *"the magnet is red +
cyan, always, everywhere — the poles are the game's logo"* and my generated one did **not**. I had
been treating `Robot.png` and `Arena.png` as the concept art and never checked what else was in the
folder.

### The pipeline

`Logo2.png` → crop → `image_to_image` (isolate on plain grey, drop the character, hand, arcs and
background) → `image_to_3d` (meshy-7, PBR, **2K**, triangle, remesh to 8k).

**8,021 triangles · 1.9031 × 1.7924 × 0.5396 studs · 5.9 MB.**

⚠️ 2K, not the 4K used on the discarded v1 — Roblox resamples uploads down anyway and this is a hand
prop. Same credits, **a third of the file size** (5.9 MB vs 16 MB).

**Geometry was verified before anyone was asked to import it.** The API returns no thumbnail, so the
GLB was parsed and software-rendered from four angles (`assets/generated/magnet-v2/_preview.png`).
Studio then independently reported the same triangle count and bounding box, which cross-checks the
preview against the file actually imported.

### Files changed

- `studio_game/ReplicatedStorage/Config/Magnet.luau` — `Magnet.MESH`: ids, size, `YAW`, `HOLD`, `TIP_DIR`
- `studio_game/StarterPlayerScripts/MagnetController.local.luau` — `buildMagnet` clones the mesh; the
  three boxes are **kept as a fallback**
- `docs/PITFALLS.md` — **#63**
- The shared `Assets/registry/meshes.md` — all five ids, plus the superseded v1 set
- `assets/generated/magnet-v2/`, `magnet-ref-v2.png`, `magnet-crop-from-logo2.png`

## The engine constraint this job found

🔴 **A script cannot texture a mesh.** The design was to build the magnet entirely at runtime —
`CreateMeshPartAsync` for geometry, a `SurfaceAppearance` assembled from four ids in config — so that
nothing lived in the `.rbxl`. It fails:

```
The current thread cannot write 'ColorMap' (lacking capability Plugin)
```

The *mesh* half works fine (measured: 0.18 s from a `LocalScript`, correct size). Only the texturing
is gated.

🔴 **And the convenient way to check reports the opposite.** The identical write **succeeds** from
`execute_luau`, including against the **Client** datamodel in a live Play session, because that
thread holds plugin capability. Measured side by side in one session: command bar `true`,
`LocalScript` `lacking capability Plugin`. Had this been probed rather than run for real, it would
have shipped a **grey magnet with a green tick against it**.

Recorded as [PITFALLS #63](../../docs/PITFALLS.md), cross-referenced to #18 and #48, which already
state the general rule. This is what those entries look like when they cost something.

**Consequence:** the textured `MeshPart` is authored in the editor and lives in
`ReplicatedStorage.MagnetMesh`, cloned per character. It is in the `.rbxl` rather than in git — the
same trade the eight `MaterialVariant`s already make — so all five ids are in the shared registry and
in `Config.Magnet.MESH`, and the template is rebuildable from them.

## The constraint that must not break, and did not

🔴 **`Magnet.TIP_OFFSET` is 2.6 and is still 2.6.** The server adds it to `PULL.ARRIVE_RADIUS` and
`GRANT.LAG_ALLOWANCE` to size a grant range measured from the player's **root**, and it cannot see
the client-built rig — so a tip moved without the server knowing starts rejecting honest collections.

The magnet now points forward, so scrap must arrive at its pole faces rather than under the hand.
**The direction changed; the distance did not.** The tip is placed along a unit `TIP_DIR` scaled by
`TIP_OFFSET`, so the offset is still exactly 2.6 long. Rotating a fixed-length offset is invisible to
a range check measured from the root; lengthening it would not have been.

Measured in Play from config, fresh session: **TIP length 2.6000**.

## Proof it works better

| | |
|---|---|
**Before** | three welded boxes: `Core` 1.6 × 0.5 × 0.5, `PoleRed` and `PoleCyan` 0.5 × 1.3 × 0.5 |
**After** | `magnet_v2_tuned` — the key-art horseshoe, poles forward, in Play at the player's camera |
**What failure would have looked like** | the fallback boxes appearing instead, which is exactly what happened on the first attempt and is how the capability error was found |

### Checks that could have failed, and did not

| Check | Result |
|---|---|
| `TIP` offset length unchanged | **2.6000** exactly |
| Poles point where the player looks | pole direction · facing = **0.982** |
| Pole faces forward of the hand | `(0.00, −0.05, −2.37)` in hand space, −Z forward |
| `SurfaceAppearance` survives the clone | present on the clone, ColorMap intact |
| Fallback boxes NOT used | `PoleRed` absent from the rig |
| Analyzer introduced nothing | **13 issues before the job, 13 after** — all pre-existing |
| Mesh size matches config | asserted at load; warns if the asset is ever swapped |
| `TIP_DIR` is unit length | asserted at load; warns with the resulting real distance |
| Nothing left in Workspace | import artifact and orientation probe both removed |

### ✅ The phone preset — done

Measured on the emulator with `TouchEnabled = true`, canvas 666 × 374.

**Frame cost of the hero mesh: none measurable.** Five interleaved 1.2 s pairs after a discarded
2 s warm-up, toggling the mesh's `Parent` (truly absent, not merely transparent):

| State | Median | Spread |
|---|---|---|
| mesh present | 67.0 ms | 66.6 – 67.2 |
| mesh absent | 66.7 ms | 66.1 – 66.7 |
| **delta** | **+0.31 ms** | below the 0.6 ms noise floor |

⚠️ **The first attempt at this measurement was garbage and is worth recording as such.** A single
A/B without a warm-up returned **+27.59 ms** — but its two *identical* "mesh visible" samples read
53.90 ms and 35.18 ms, an 18.7 ms spread between states that were the same. The delta was inside its
own noise. Sampling had begun while the Workshop was still settling after spawn. Reported as a real
cost, it would have sent someone optimising a mesh that costs nothing.

🔴 **What this does NOT prove.** Studio sits at ~67 ms/frame (15 fps) here whatever is on screen, so
something else saturates the frame entirely. This is *no measurable cost against a saturated
baseline*, not evidence the mesh is free on real hardware. It belongs in the same bucket as
`Bootstrap`'s existing "4 performance questions can only be answered on real hardware".

### A HUD check that could never fail, finally could

Not this job's code, but this job's emulator pass surfaced it. `Hud` verifies its layout against the
rects Roblox reserves for its own touch controls. On desktop that check has always logged:

    layout verified: 3 element(s) vs 0 reserved rect(s) ... reserved: NONE

Zero rects to collide with — structurally incapable of failing, the exact PITFALLS #55–#61 shape,
sitting inside the audit written to prevent it. With the emulator on it reads:

    layout verified: 3 element(s) vs 5 reserved rect(s) ... touch=true | tap=56px
      reserved: JumpButton[571..641,226..296] DynamicThumbstickFrame[-100..266,105..416]
                DynamicThumbstickUIModifier[-100..266,105..416]
                ThumbstickStart[29..103,223..297] ThumbstickEnd[48..84,242..278]

**Five real rects, and it passes.** Job 011's layout audit is now known to work rather than assumed
to. It also confirms the two-canvas distinction: the HUD is `666 × 316` under `CoreUISafeInsets`,
the boot screen `666 × 374` under `ScreenInsets.None`.

## What was tuned by looking, not by arithmetic

`HOLD` started at `(0, -0.30, -1.00)`, derived on paper. In Play the cyan arm passed through the
character's leg. `(0, -0.05, -1.42)` clears the body and reads as held out in front. Recorded in the
config with the reason, because the number looks arbitrary otherwise.

Orientation was established the same way: the imported mesh was photographed at identity rotation
next to a marker cube on local +X, which is how we know the open end is +X and the red arm is +Y.
The exporter was not asked.

## Credits

**87 total** across both attempts — 48 on the discarded crane-mounted v1 (9 + 9 + 30), 39 on the
shipped v2 (9 + 30). Balance ~1,153 of 1,240.

The v1 spend was not wasted effort so much as wasted aim: the pipeline it proved is the pipeline v2
used. It is kept on disk and in the place as `MagnetMesh_v1_craneMount`, since it is the right object
for a **crane-mounted** magnet, which the Arena or a zone hazard may yet want.
