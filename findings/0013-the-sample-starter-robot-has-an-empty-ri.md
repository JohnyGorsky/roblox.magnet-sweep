# FINDING 0013: MISDIAGNOSIS — the starter robot's empty right arm is the DESIGN, not a defect

**Project:** `roblox.magnet-sweep`
**Status:** ❌ **withdrawn — there was no defect.** Kept as a record of the mistake.
**Created:** 2026-09-06 (job 021) · **Withdrawn:** 2026-09-06, same day

## What was reported

The owner, looking at `workspace.Hub.Bases.4.Fixtures.SMELTER.ROBOT`:
*"what is this robot with wrong hands in wrong positions?"*

## What I concluded, and why it was wrong

I measured the rig — correctly — and found it sound: 9 Motor6Ds in a proper chain, 7 declared
sockets, all 5 installed parts' `RobotMount` attachments aligned to their socket to **0.000 studs**,
0 mirrored parts. Then I found `RightArmSocket` empty and called **that** the defect, installed a
grabber claw into it, and fixed the DemoRoom source too.

🔴 **`docs/systems/robot-assembly/README.md:22`, decided 2026-09-05:**

> *"The game GIVES a new player a fixed, assembled robot. **Head, Core, Body, one Arm and one
> Mobility**, already bolted together. Everything found afterwards replaces a piece."*

**Five parts. One arm. The empty `RightArmSocket` IS the starter loadout.** `2_Starter` had exactly
those five meshes and was correct as built.

## The evidence that was available and that I did not weigh

An audit of the demo room, which the owner's question prompted and which I should have run *first*:

| Robot | meshes | empty sockets | |
|---|--:|---|---|
| `10_Robots.1_BareRig` | 0 | all 7 | deliberate — the bare rig demo |
| `10_Robots.2_Starter` | **5** | **RightArm** | **deliberate — the starter loadout** |
| `10_Robots.3_FullTier1` | 7 | none | complete |
| `10_Robots.4_MismatchedArms` | 6 | none | complete, and *named* for asymmetric arms |
| `11_RobotsT2.1_T2Starter` | **5** | **RightArm** | **deliberate — same pattern, independently** |

**Two separate "Starter" rigs, in two separate tiers, each missing exactly the right arm.** That is a
pattern, not an oversight, and it was visible in one query. The demo room is a designed progression —
bare rig → starter → full → mismatched — and I read the second rung as a broken version of the third.

## Answering the owner's actual question

*"But we already had pointed robots in demo room, why you again had this problem?"*

**There was no problem, and the demo room is fine.** `3_FullTier1` and `4_MismatchedArms` are both
complete. What job 020 did was put **`2_Starter`** — deliberately sparse — on base 4 as the room's
only visible robot. That is a **display choice**, not a rig defect.

And the same doc predicts exactly the reaction it got, three lines further down:

> *"Standing one on a pad, it reads as **broken rather than as unfinished**, which is exactly how it
> was received."*

## What was done

- The grabber claw was **removed** from both the placed robot and the DemoRoom source. Both are back
  to **5 meshes with `RightArmSocket` empty**, matching the decided loadout.
- `11_RobotsT2.1_T2Starter` was never touched.

## The lesson, stated so it is not re-learned

🔴 **I changed a decided design without checking whether it was decided.** The project skill's rule is
*"Never silently overturn an accepted decision"*, and `docs/` is the first place to look when
something looks wrong-but-deliberate. **A single asset looking odd is not evidence of a bug; a second
asset with the identical "bug" is evidence of a design.** The audit that revealed the pattern took one
query and came *after* the fix instead of before it.

## The real, still-open question — a display choice, not a defect

If the Workshop's showcase robot should look complete, stand **`4_MismatchedArms`** (6 parts, and its
asymmetric wrench-vs-other-arm pairing is exactly the §39 look) or **`3_FullTier1`** (7 parts) on base
4 instead of `2_Starter`. That is a one-line swap and needs the owner's say-so, since the current
choice may be deliberate — a starter is what a new player actually gets.

---

## ROOT CAUSE, found on the owner's third push — there are no animation CLIPS

The owner: *"we already rigged and animated these robots at demo stage, and now I see a robot with
hands placed incorrectly."* They were right about the rigging. Measured on
`DemoRoom.10_Robots.4_MismatchedArms`:

| Check | Result |
|---|---|
| Motor6D skeleton | ✅ 9 joints |
| Shoulder offsets | ✅ **symmetric** — `LeftShoulder C0 (−5.05, 1.60, 0)` vs `RightShoulder C0 (+5.05, 1.60, 0)` |
| Elbow offsets | ✅ symmetric — `−0.90/−0.40` vs `+0.90/−0.40` |
| `Animator` | ✅ present on every one of the 8 demo rigs |
| Arm mesh vs its pivot | ✅ **touching** — gaps −1.38 and −0.21 studs, nothing floats |
| Every arm part's `RobotMount` | ✅ at a real **edge** feature (frac −0.58, −0.72, +0.82, +0.16), not the bounding-box centre |

**The rigging is correct and the mounts are correct.** The only mounts at dead centre are the
torsos, which is where a torso's mount belongs.

🔴 **What is missing is the clips.**

- **`Animation` instances anywhere in the DemoRoom: 0.**
- No animation asset id anywhere in `studio_game/` — the only `rbxassetid` entries are the boot plate
  and the magnet's five PBR maps.
- `Config/Parts.ANIMATION_PROFILES` and the `animationProfile` column in `PartsCatalog` are a
  **schema of names** (`SweepLight`, `PunchFast`, `GrabPull`, `SmashHeavy`, `RangedCannon`…), not
  clips. `docs/build/spec-coverage.md:124` marks that column **(derived)**.
- `docs/build/10-arena.md:19` still reads **`[ ] P0 Animation profiles: the ~10 combat clips`** —
  unchecked.

So every rig holds its **rest pose**: arms straight out sideways at shoulder height, because that is
exactly what the `C0` offsets describe with nothing playing over them. A pipe wrench held straight
out horizontally is what the owner saw, and *"hands placed incorrectly"* is a fair description of a
rest pose being used as a display pose.

⚠️ Whether clips were ever **uploaded** to the owner's Roblox inventory cannot be seen from here.
What is certain is that **nothing in this place references one**.

## What this changes

1. The rigging work was not wasted and does not need redoing.
2. Standing any rig on a pad as scenery will keep looking wrong until either a clip plays or an
   **authored display pose** is baked into the Motor6D `C0`s (a cheap idle lean costs no asset).
3. The sample robot was removed from base 4 at the owner's request — job 022's claim logic will spawn
   a player's robot instead — so nothing is currently displaying a rest pose in the Workshop.
