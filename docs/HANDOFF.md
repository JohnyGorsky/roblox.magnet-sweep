# Handoff — where we left off

**Snapshot: 2026-08-29.** Read this, then [PITFALLS.md](PITFALLS.md), then
[build/README.md](build/README.md).

## 🧲 Where the game actually is

**There is no game yet.** No place, no code, no assets. This snapshot is honest about that so nothing
here reads as progress it is not.

| | State |
|---|---|
| **Design** | ✅ Complete. The 87-section spec redistributed into `docs/`, with a coverage table |
| **Task list** | ✅ Complete. 14 groups, 581 items, sequenced into 28 jobs |
| **Place** | ✅ Live. `111667188608192`, universe `10764307230`. `StreamingEnabled` on, `MaxPlayers` 12, `LightingStyle` Realistic |
| **Sync** | ✅ Connected and **VERIFIED** — flat layout, 6 synced service folders (job 002) |
| **Code** | ✅ 16 modules. Config, remotes, rate limiting, logging, dev tools, materials, kit |
| **Assets** | ✅ 32 PBR maps for 8 `MaterialVariant`s, logged in two registries |
| **Kit** | ✅ 24 pieces / 83 parts, generated from spec, tiling verified by assembled corridor |
| **Gameplay** | ❌ **None yet.** Nothing is playable. The magnet does not exist |

## ✅ Jobs completed

| # | Job | Outcome |
|---|---|---|
| **001** | Repo scaffold, design pack, project skill | 87-section spec → `docs/`; 2 skills; 13 decisions; 581-item manifest; PITFALLS. Reviewer found 7 wrong engine claims — 2 inherited from a shared workspace skill (`workspace/findings/0002`) |
| **002** | Place setup + sync probe | Layout **observed**, not guessed: flat, 6 synced folders. Caught the `.client.luau` double-run and the fact that `Lighting.Technology` cannot even be read |
| **003** | Config skeleton, remotes, rate limiter, dev tools | 6 config modules, 20 remotes, structural rate limiting, dev console. Reviewer caught an economy curve that made **zone 12 unreachable** (4.3×10⁵⁸ coins) |
| **004** | Material kit | 8 `MaterialVariant`s + built-in Metal for Chrome; `MaterialKit`; lighting recipe applied. Reviewer caught that a claim I published — "Reflectance is inert" — was **wrong**; it is material-dependent |
| **005** | Industrial kit geometry | 24 pieces / 83 parts generated from `KitSpec`. My first validator enforced the wrong invariant; the corrected one found 3 real overhang bugs |

**Pattern worth noting:** every job so far has had a real defect found by review or by running it. Three
were things I had already reported to you as working.

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
| 1 | **Commit the work** | Claude never commits. You committed twice mid-session; everything after `1a2c6a6` is uncommitted |
| 2 | **Social Slots + access level** — the last two place settings | `Roblox optimized` social slots can push a server past 12, which every performance budget assumes. Decide before the place is joinable — see [systems/places](systems/places/README.md#social-slots--the-one-still-open) |
| 3 | **Reopen the place in Studio** before the next publish | Its session reported `MaxPlayers = 60` after you set 12 on the web; publishing from a stale session could overwrite it |
| 4 | Later, at [the gate](roadmap/mvp.md#the-gate): **judge whether the sweep feels good** | A *feel* question, played. Not something Claude can sign off |

---

## ✅ Sixteen questions answered, 2026-08-29

Put through the wizard and settled. Two became decision records; the rest are written into their system
docs. Full table in [decisions/INDEX](decisions/INDEX.md#answered-by-the-user-2026-08-29).

The two that changed the design most:

**[0014 — the owning guardian chases you.](decisions/0014-the-owning-guardian-chases.md)** The
steal-an-egg rule replaces §23's flat 5-second recovery window. Guardians are **inert until you steal**;
only the guardian whose part you took chases you, and it chases across zone boundaries. Caught **inside
its territory** the part resets to its spawn; caught **outside**, you ragdoll and the part drops neutral
for anyone to take, and the guardian goes home.

This gives the escape a shape it did not have — a sprint to the boundary, then a walk — and it means
Magnetic Drive buys you *the sprint* rather than "walk home slightly faster". It also removes the
where-did-the-ragdoll-land lottery, and guarantees exactly one pursuer at a time, which matters in a
streamed corridor.

**[0015 — rarity is re-graded.](decisions/0015-rarity-is-re-graded.md)** The spec made `Rare` the most
common grade in the game (35 of 96, against 13 Uncommon). Re-banded per tier, preserving each tier's own
ordering, to **18 / 27 / 27 / 12 / 11 / 1**. The spec's grade is kept in its own column and is what the
verifier checks, so nothing was destroyed.

---

## 🚩 Still open

Nothing here blocks job 002.

### Needs measurement, not a decision

These cannot be answered by choosing. They need Studio and the Device Emulator.

| Question | Where | When |
|---|---|---|
| **`MaxConcurrentPull`** on a mid-range phone during a Magnet Rush | [magnet](systems/magnet/README.md#open--needs-measurement-not-a-decision) | before the Rush ships |
| **Can 6 Arena robots hold 30 fps** with parts, actuators and VFX? The spec wants 4–6 | [arena](systems/arena/README.md#open) | **before committing to 6** |
| Workshop + Arena + two loaded zones: memory and frame time | [performance](systems/performance/README.md#the-measurements-that-must-happen-and-when) | before the second zone |
| Draw calls in the Workshop with full signage and PBR | [performance](systems/performance/README.md#the-measurements-that-must-happen-and-when) | before the Workshop is signed off |
| The reference device and the memory / draw-call budgets **have not been chosen yet** | [performance](systems/performance/README.md#the-measurements-that-must-happen-and-when) | first — everything above depends on it |

### Content that does not exist yet

| Question | Where | When |
|---|---|---|
| **No part has combat stats.** All 96 have a slot, rarity and an effect *phrase*; none has damage, attack speed, knockback, range, HP, armour, weight or a Magnet Power requirement | [parts-catalog](content/parts-catalog.md#what-is-still-missing-per-part) | per tier, in that tier's build group |
| **Relic Parts** — seven names and nothing else. Slots, rarities, effects, recovery method | [endgame](content/endgame.md#open) | its own job, before the Endless Line |
| Guardian speeds, detection ranges and catch radii | [guardians](systems/guardians/README.md#open) | per tier |
| Coin costs for upgrades — the *requirement* curve is given (§62), the *price* curve is not | [economy](systems/economy/README.md) | when the economy is tuned |
| Arena reward rates — "rewards accumulate over time", no numbers | [arena](systems/arena/README.md) | when the Arena is tuned |

### Smaller calls, deferrable

| Question | Where | When |
|---|---|---|
| Is the `Damaged` layer additive or a replacement clip set? **Proposal: additive** | [robot-rig](systems/robot-rig/README.md#open-questions) | before damage visuals |
| Guardian give-up delay after a drop | [guardians](systems/guardians/README.md#open) | before the first guardian |
| Two thieves, one zone, one guardian — what happens? | [guardians](systems/guardians/README.md#open) | before zone 2 |
| Is the ~2 min Arena grace period the right length? | [arena](systems/arena/README.md#open) | when the Arena is tuned |
| Does a paint carry with its part when swapped out and back? | [cosmetics](content/cosmetics.md#open) | before the first paint |
| Does the Endless Line share the Arena, or is the robot left behind? | [endgame](content/endgame.md#open) | before it ships |
| Event frequency on a quiet server; MAGNETIC STORM's cost; purchased-event cooldown | [events](content/events.md#open) | before events ship |
| Spectator camera, or watch from the Workshop floor? | [arena](systems/arena/README.md#open) | before launch |

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
