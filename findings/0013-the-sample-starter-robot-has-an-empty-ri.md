# FINDING 0013: the sample starter robot has an empty right arm socket

**Project:** `roblox.magnet-sweep`
**Status:** fixed 2026-09-06 (job 021)
**Severity:** low — one sample prop, but it is the only robot a player currently sees
**Created:** 2026-09-06 (noticed by the owner during job 021)
**Owner of the defect:** job 020, not 021

**Symptom, as reported:** *"what is this robot with wrong hands in wrong positions?"* —
`workspace.Hub.Bases.4.Fixtures.SMELTER.ROBOT`, the sample starter robot job 020 stood on base 4.

**Measured — the rig is CORRECT, and that is the point of this finding.**

| Check | Result |
|---|---|
| Motor6D chain | ✅ 9 joints: `Root → TorsoPivot → {Head, Mobility, LeftShoulder, RightShoulder}`, shoulders → arm pivots, mobility → drives |
| Declared sockets | ✅ 7: `RightArm`, `LeftArm`, `Head`, `Mobility`, `Body`, `Core`, `Back` |
| Installed parts' `RobotMount` vs their socket | ✅ **all 5 aligned to 0.000 studs** |
| Mirrored parts | ✅ 0 of 15 |

So the parts are **not** misaligned, and this is
[decision 0004](../docs/decisions/0004-parts-are-content-rig-is-the-engine.md) working as designed.

🔴 **The real defect: `RightArmSocket` has 0 parts welded to `RightArmPivot`.** Socket occupancy:

| Socket | parts |
|---|--:|
| `LeftArmSocket` | 1 |
| **`RightArmSocket`** | **0 — EMPTY** |
| `HeadSocket` | 1 |
| `MobilitySocket` | 1 |
| Torso group (`Body`/`Core`/`Back`) | 2 |

**And the gap is in the SOURCE, not the clone.** `DemoRoom.10_Robots.2_Starter` has the same
**5 meshes / 5 welds** as the placed copy, so the sample was only ever assembled with one arm.

**What the owner is actually looking at, item by item:**

1. A **pipe wrench as the left arm** — this is *by design*, not a bug. §39 and the vision doc are
   explicit that homemade, asymmetric and ridiculous is the goal (*"giant-spoon arm"*,
   *"Toilet Brush Arm"*). A wrench arm is the game working.
2. A **Core part protruding from the chest** at `CoreSocket` — also by design.
3. **A bare right shoulder stub with nothing on it** — this is the bug, and it is what makes the
   whole assembly read as *broken* rather than as *deliberately ridiculous*. One empty socket
   reframes two correct design choices as mistakes.

**Where:** `Workspace.DemoRoom.10_Robots.2_Starter` (the source), cloned to
`Workspace.Hub.Bases.4.Fixtures.SMELTER.ROBOT`. `Workspace` does not sync, so both live only in the
`.rbxl`.

**Fix idea:** install any Tier-1 arm part into `RightArmSocket` by aligning its `RobotMount`
attachment to the socket — the same 0.000-stud alignment the other five already have. Candidates
already in `ServerStorage.ImportedMeshes`: `pipe_wrench` (matching pair), `toy_hammer`,
`grabber_claw`, `propeller_pack`. Fix the **DemoRoom source** as well, or the next clone repeats it.

⚠️ Do not "fix" the wrench arm or the chest core. They are correct.


---

## FIXED — 2026-09-06

A **grabber claw** was installed into `RightArmSocket`, deliberately **not** a matching wrench:
§39 wants the pair mismatched, so a claw against a pipe wrench is the design working rather than a
symmetry to be restored.

| | |
|---|--:|
| `RobotMount` offset from `RightArmSocket` | **0.0000 studs** |
| Determinant of the placed part | **+1.0000** |
| Parts welded to `RightArmPivot` | **1** (was 0) |
| Robot meshes | **6** (was 5) |

Placed the same way the other five are: `RobotMount` attachment at the part's **inner end**, aligned
to the socket, `WeldConstraint` to the arm pivot, plus the sibling `PointLight`. Built with
`CFrame.lookAt`, never `fromMatrix`.

🔴 **The DemoRoom source was fixed too** — `DemoRoom.10_Robots.2_Starter` now has 6 meshes, so the
next clone inherits the second arm instead of repeating this.

⚠️ **Left open, deliberately:** all five original meshes are still named `Node0`, the Meshy importer
default. That naming is most of why the owner could not tell what they were looking at
(*"what is this robot with wrong hands"*). The new part is named `Arm_R_GrabberClaw`; renaming the
other five is a tidy-up nobody has asked for yet.
