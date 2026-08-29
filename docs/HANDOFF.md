# Handoff — where we left off

**Snapshot: 2026-08-29.** Read this, then [PITFALLS.md](PITFALLS.md), then
[build/README.md](build/README.md).

## 🧲 Where the game actually is

**There is no game yet.** No place, no code, no assets. This snapshot is honest about that so nothing
here reads as progress it is not.

| | State |
|---|---|
| **Design** | ✅ Complete. The 87-section spec is redistributed into `docs/` with a coverage table |
| **Task list** | ✅ Complete. 14 groups, **572 items**, each sized to one sitting |
| **Place** | ❌ **Not created.** One place is needed ([decision 0001](decisions/0001-one-place-not-two.md)) |
| **Sync** | ❌ Not connected. `.jobconfig.json` paths are **guessed and marked UNVERIFIED** |
| **Code** | ❌ None |
| **Assets** | ❌ None sourced, and none should be until a slot needs one. Concept art and the spec are in `assets/` |

## ✅ What Job 001 delivered

- **Plumbing** — `magnet-sweep` registered in `roblox.workspace/tools/job.py`; `CLAUDE.md`,
  `README.md`, `.gitignore`, `.jobconfig.json`, and the repo folder tree to workspace convention.
- **Two skills** — [`magnet-sweep-project`](../.claude/skills/magnet-sweep-project/SKILL.md) (the entry
  point, the non-negotiables) and [`magnet-sweep-style`](../.claude/skills/magnet-sweep-style/SKILL.md)
  (the glossy-metal look, the palette, the material kit, the lighting recipe, quality tiers).
- **The design pack** — 7 game docs, 16 system docs, 5 content docs (including the full **96-part**
  catalog), 13 decisions, the feature template, 2 roadmap docs.
- **[The build manifest](build/README.md)** — 14 groups, 572 items (the MVP is **349** of them),
  ordered MVP-first around [the gate](roadmap/mvp.md#the-gate) rather than by the spec's phase list.
- **[PITFALLS.md](PITFALLS.md)** — 47 entries: *incident → rule → the check that catches it*, with the
  anticipatory ones labelled as such rather than dressed up as history.
- **[Spec coverage](build/spec-coverage.md)** — all 87 sections mapped, 6 deliberate divergences, and an
  explicit list of what the spec never specified.
- **Four scripts in `tools/`** — `gen-build-manifest.py`, `gen-spec-coverage.py`,
  `gen-content-catalogs.py` (the zones page and the 96-part catalog) and two checkers,
  `verify-catalog-vs-spec.py` and `check-links.py`. Every count on those pages is **computed**, never
  typed ([PITFALLS #9](PITFALLS.md#9-coverage-by-link-is-not-coverage)).

The source spec and concept art are untouched in `assets/`.

## 🎨 The four decisions you made at intake

| Question | Chosen | Recorded as |
|---|---|---|
| Place topology | **One place** | [0001](decisions/0001-one-place-not-two.md) |
| Scope of this pass | **Full design pack** | this handoff |
| The glossy look | **PBR kit + Realistic lighting + post-FX**, hero meshes only | [style skill](../.claude/skills/magnet-sweep-style/SKILL.md) |
| Platform budget | **Mobile-first, PC gets more** | [0012](decisions/0012-mobile-first-quality-tiers.md) |

The robot architecture you wrote mid-session is now
[systems/robot-rig](systems/robot-rig/README.md) and
[decision 0004](decisions/0004-parts-are-content-rig-is-the-engine.md). Your structure held up — the
hidden rig, standardised `RobotMount` sockets, `WeldConstraint` mounting and shared animation profiles
all survived review unchanged. Four things were added or corrected on top of it:

- **Mounted parts are `Massless` + `CanCollide = false`.** Otherwise a Vault Door build is unplayable.
- **Movement is `AlignPosition` on an *unanchored* root**, so knockback is real.
- **Hit detection never reads a limb position** — a server rig holds its rest pose.
- **Animations play on the SERVER, not the client** — see the correction below.

⚠️ **Two engine facts in the first draft of that page were wrong, and both came from the shared
`roblox-animation` skill rather than from your proposal.** They are fixed here and upstream:

| | Was written | Actually |
|---|---|---|
| Animation priority | `Idle < Movement < Action < Action2/3/4 < Core` | **`Core` is the LOWEST priority**, despite its value being 1000. An attack clip set to `Core` loses to `Idle` |
| Where to play NPC animations | "on the CLIENT" | An `Animator` **not** in a player character "must be loaded and started **on the server** to replicate". A client-played track on a server-owned Arena robot is visible to **one** player |

Both verified against `Roblox/creator-docs` raw YAML, not the rendered docs site — which is itself the
lesson, see [PITFALLS #45](PITFALLS.md#45-the-rendered-docs-site-misreports-deprecation-and-ordering).

---

## ▶️ The recommended next move

**Job 002 — create the place and probe the sync layout.** It is the first item of
[build group 01](build/01-foundation.md) and it blocks everything, because every file every later job
writes to disk assumes it.

Right now `.jobconfig.json` **guesses** the layout from The Last Tide (flat: service folders at the sync
root, `StarterPlayerScripts/` at the root rather than nested under `StarterPlayer/`). **Jungle uses the
nested Rojo convention instead — the two disagree**, and Tide job 003 was burned assuming the wrong one.
ELEVATOR 13 then inherited the same unverified guess rather than resolving it; do not make that three.

It needs you to have Studio open on the place. What the probe settles:

- Flat vs nested layout.
- Which service folders actually sync (on Tide, `StarterGui`, `StarterPack` and `Workspace` do **not**).
- Which file suffix produces which class — and specifically whether `.client.luau` in
  `StarterPlayerScripts` **runs twice** here, as it does on Tide.

Then `.jobconfig.json` is rewritten with what was **observed**, and its `_status` stops saying
UNVERIFIED.

After that, [group 01](build/01-foundation.md) in order. Note that its *dev/test configuration* item
(forced Shift, jump-to-zone, grant Magnet Power, spawn a named part) is not "later" — it is what makes
every subsequent bug reproducible in a game with three overlapping randomised refresh cycles.

---

## ⏳ Waiting on you

Kept short deliberately. Tide's equivalent list reached nine rows, each individually reasonable, and
together a backlog nobody was tracking ([PITFALLS #32](PITFALLS.md#32-the-waiting-on-you-list-grows-silently)).

| # | What | Why it needs you |
|---:|---|---|
| 1 | **Commit Job 001** | Claude never commits. You committed `cf6a90a` mid-session, which captured roughly the first third of this job; everything written after it is still uncommitted |
| 2 | **Create the MAGNET SWEEP place** and give me its id | Cannot be done over MCP |
| 3 | **Studio open on it** for the sync probe | MCP has no connectivity otherwise |
| 4 | **Place settings** — access, social slots, `MaxPlayers`, and `StreamingEnabled` | Tide shipped `Fully Open` with social slots on and both became findings. `StreamingEnabled` is load-bearing here, not optional — see [systems/places](systems/places/README.md#place-settings-to-decide-before-anyone-can-join) |
| 5 | Later, at [the gate](roadmap/mvp.md#the-gate): **judge whether the sweep feels good** | A *feel* question. Not something Claude can sign off |

---

## 🚩 Open design questions

Recorded so they are not answered by accident. None blocks job 002.

| Question | Where | When it must be answered |
|---|---|---|
| **No part has any combat stats.** All 96 have a slot, rarity and an effect *phrase*; none has damage, attack speed, knockback, range, HP, armour, weight or a Magnet Power requirement | [parts-catalog](content/parts-catalog.md#what-is-still-missing-per-part) | per tier, in that tier's build group |
| **`Rare` is the most common rarity** in the catalog — 35 of 96, against 13 Uncommon. Either the ramp means something different here, or the catalog needs re-grading | [parts-catalog](content/parts-catalog.md#rarity-distribution) | before drop rates are tuned |
| **Mobility is thin at the top.** Tiers 9–12 offer four mobility parts, **two** of them Epic (Hover Actuators, Gravity Ring). A late player without an Epic one is on Racing Wheels | [zones](content/zones/README.md#observations-on-the-pool-as-written) | before tier 9 |
| **Is pull force a curve or a step** at the weight threshold? A hard threshold reads as broken; a soft one makes gates fuzzy | [systems/magnet](systems/magnet/README.md#open) | before the first prototype is tuned |
| **Can 6 Arena robots hold 30 fps** on a mid phone with parts, actuators and VFX? The spec wants 4–6 | [systems/arena](systems/arena/README.md#open) | **measure before committing to 6** |
| **Do guardians threaten a player carrying nothing?** If not, they are scenery 90 % of the time | [systems/guardians](systems/guardians/README.md#open) | before tier 1 is tuned |
| **Does uncollected scrap survive a disconnect**, or auto-recycle as it does on death? | [systems/save-data](systems/save-data/README.md#open) | before the first save ships |
| **Two-handed parts** — does a Crane Hook occupy both arm sockets or one? The catalog implies one; the animation may disagree | [systems/robot-rig](systems/robot-rig/README.md#open-questions) | before tier 8 |
| **Relic Part slots, rarities and effects** are entirely unspecified — seven names and nothing else | [content/endgame](content/endgame.md#open) | before the Endless Line |
| **How does the zone power curve scale with Magnet Core Level?** Without an answer, run 2 is run 1 again | [content/endgame](content/endgame.md#open) | before Overclock |
| **Service Hub placement** is *(derived)* — the spec says only "approximately every two zones" | [zones](content/zones/README.md) | before the second hub |

---

## Reminders that will matter later

- **Verify in Play, never in Edit.** The magnet field, every trail and arc, the post chain, the whole
  HUD and every Arena robot are client-side or runtime-created. **Almost nothing in this game exists in
  an Edit session.**
- **`IMPLEMENTED` is not `VERIFIED`.**
- **The physics cap is a measured count**, never a reading of the config value.
- **Never solve combat from a limb's position** — a server-spawned rig sits in its rest pose.
- **No placeholder assets.** Leave the slot empty and make it announce itself.
- **Mobile is measured in the Device Emulator**, not reasoned about — and ask before switching Studio
  into it.
