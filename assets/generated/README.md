# assets/generated

Things produced by a tool rather than authored by hand — Meshy output, and images derived from
`../concept_art/` with PIL.

## The rule: keep the id, not the blob

The `.gitignore` ignores `**/*.glb`, `**/*.fbx`, `**/*.obj`, `**/*.zip` and
`assets/generated/**/*_textures/*.png` **wherever they land**. A mesh that has been imported already
lives on Roblox's servers under the owner's account, and its asset id is recorded in two places:

- the shared **`Assets/registry/meshes.md`** (and `images.md` for uploaded images)
- **`Config`** — e.g. `Magnet.MESH`

Those ids are what make the asset recoverable. The source blob is a build artifact.

> ⚠️ **This rule already existed and job 016 walked around it.** The ignore list originally matched
> only `assets/meshy/**`, so writing the files here instead put **76 MB** of a *superseded* magnet
> into git — an FBX at 31 MB and a 4K `base_color.png` at 16.7 MB, for an object that was discarded.
> It was committed and pushed before anyone noticed. The rules now match on extension rather than on
> one directory name, and the blobs were untracked with `git rm --cached`.
>
> 🔴 **The history was NOT rewritten** — those 76 MB remain in past commits. Untracking stops the
> repo growing; it does not shrink it.

## What IS tracked here, and why

| File | Why it earns its place |
|---|---|
| `loading-backdrop.png` | 88 KB. The **reproducible source** for a live uploaded asset (`88620361473282`) — `Arena.png` blurred at radius 16, 42 % brightness. Without it the exact plate cannot be rebuilt |
| `magnet-ref-v2.png` | The image the shipped magnet mesh was generated from. Regenerating the mesh needs this, not the GLB |
| `magnet-crop-from-logo2.png` | The crop of `Logo2.png` that produced it |
| `magnet-ref.png`, `magnet-crop-from-robot-png.png` | The **v1** equivalents. Kept because both job summaries cite them as the record of building from the wrong reference |
| `magnet-v2/_preview.png` | 8 KB. Four-angle software render of the GLB's geometry, made by parsing the file directly — the API returns no thumbnail, so this is how a mesh gets judged before anyone is asked to import 6 MB |

## What is here on disk but untracked

- `magnet/` — 76 MB. The **superseded** crane-mounted v1, generated from `Robot.png`. Its poles are
  capped by a crane mount and it is all-red rather than red + cyan. Kept locally because it is the
  right object for a *crane* magnet, which the Arena may yet want. Also lives in the place as
  `ReplicatedStorage.MagnetMesh_v1_craneMount`.
- `magnet-v2/magnet.glb` — 5.9 MB. The shipped magnet. Already imported; `Magnet.MESH.ID` is
  `rbxassetid://117205352084553`.

**If you need either back on another machine:** re-download from Meshy, or re-export from the place.
Neither is on the critical path, because the imported assets are what the game actually references.
