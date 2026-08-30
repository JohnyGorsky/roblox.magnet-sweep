# Handoff — where we left off

**Snapshot: 2026-08-30, end of session.** Read this, then [PITFALLS.md](PITFALLS.md), then
[build/README.md](build/README.md).

## 🧲 Where the game actually is

**The magnet works.** You can stand in a field of scrap, watch it shake, lift and fly in, build a
combo, trigger a MAGNET RUSH, fill up and go recycle. That is build group 04 — the group the roadmap
calls **the gate**.

| | State |
|---|---|
| **Design** | ✅ Complete. The 87-section spec redistributed into `docs/`, with a coverage table |
| **Task list** | ✅ Complete. 14 groups, 582 items, sequenced into jobs |
| **Place** | ✅ Live. `111667188608192`, universe `10764307230`. `StreamingEnabled` on, `MaxPlayers` 12, `LightingStyle` Realistic |
| **Sync** | ✅ Connected and **VERIFIED** — flat layout, 6 synced service folders (job 002) |
| **Code** | ✅ 30 modules — 19 ReplicatedStorage (incl. the 4-module `Ui/` layer), 6 ServerScriptService, 5 StarterPlayerScripts. **`tools/luau-analyze.sh` now checks all of it on disk in ~1s** |
| **Assets** | ✅ 32 PBR maps for 8 `MaterialVariant`s · ✅ 14 of 15 sound slots landed — 🔴 **`UI.Press` is open**, so every button is silent |
| **Kit** | ✅ 24 pieces / 83 parts, generated from spec, tiling verified by assembled corridor |
| **Gameplay** | ✅ **The magnet.** Four-state scrap, pooled + capped, batched server grant, Flow → RUSH, Capacity → SCRAP FULL, Magnetic Drive, five VFX states |
| **Sound** | ✅ **The game makes noise.** 14 Pro Sound Effects clips landed and verified in Play; `AudioBench` (F3) auditions candidates in the slot they will occupy. The one gap is the UI click |
| **HUD** | ✅ **The game shows you what you are doing.** Coins, Flow ×1–×5 → RUSH, Scrap/Capacity, SCRAP FULL, banners, and a working upgrade panel. Measured on the phone preset (canvas **666×316**) and clear of Roblox's own thumbstick and jump button. ⚠️ The **desktop** arrangement is built but unverified |

**What is NOT built:** the Workshop, the loading screen, zones 1–2, rare cargo and extraction,
guardians, the robot, the Arena, persistence, the Factory Refresh. Groups 05, 06's boot half, 07–12.

**Coins now buy something** — job 011 wired `RequestUpgrade` rather than ship a dead button, so
Magnet Power, Pull Radius, Capacity and Magnetic Drive are all purchasable and the server recomputes
every price.

## ✅ Jobs completed

| # | Job | Outcome |
|---|---|---|
| **001** | Repo scaffold, design pack, project skill | 87-section spec → `docs/`; 2 skills; 13 decisions; 581-item manifest; PITFALLS. Reviewer found 7 wrong engine claims — 2 inherited from a shared workspace skill (`workspace/findings/0002`) |
| **002** | Place setup + sync probe | Layout **observed**, not guessed: flat, 6 synced folders. Caught the `.client.luau` double-run and the fact that `Lighting.Technology` cannot even be read |
| **003** | Config skeleton, remotes, rate limiter, dev tools | 6 config modules, 20 remotes, structural rate limiting, dev console. Reviewer caught an economy curve that made **zone 12 unreachable** (4.3×10⁵⁸ coins) |
| **004** | Material kit | 8 `MaterialVariant`s + built-in Metal for Chrome; `MaterialKit`; lighting recipe applied. Reviewer caught that a claim I published — "Reflectance is inert" — was **wrong**; it is material-dependent |
| **005** | Industrial kit geometry | 24 pieces / 83 parts generated from `KitSpec`. My first validator enforced the wrong invariant; the corrected one found 3 real overhang bugs |
| **006** | Lighting, atmosphere, quality tiers | Reference device + budgets; tiers chosen from a MEASURED frame time. **Its review later found the tiers changed almost nothing** — see job 009 |
| **010** | Magnet VFX + sound | Five VFX states on one emitter. Its review found the Rush state **latched on forever** client-side, and that decision 0011's "code gate" was a comment pointing at an assertion that never existed |
| **007** | Magnet core | Four states, pool, cap, batched grant. Reviewer found 6 criticals: abandoned pulls **bricked a magnet for the session**; a 16.2-stud grant gate against a 2.5-stud arrival |
| **008** | Flow, RUSH, Capacity, Drive | All four stats real and upgradeable. A full magnet **spun the claim loop at 93% rejection**; Flow re-triggered RUSH forever |
| **011** | Boot & HUD (the HUD half) | Coins, Flow, Scrap/Capacity, banners, upgrade panel, and a layout audit that ships. **Six defects in my own new code**, three of them checks that passed while measuring nothing — a disabled `ScreenGui` reporting 800x600 forever, `layout clean` against zero rectangles, and a `MinSize` silently overriding a computed height. Wired `RequestUpgrade` so coins buy something |
| **009** | Quality tiers, repaired | Light cull **could never fire** (kit max 18 vs threshold 40); Low's PBR drop **undone by the server on every spawn** |


**Pattern worth noting:** every job so far has had a real defect found by review or by running it, and
several were things I had already reported to you as working. Job 006 was reported complete and its
review, run three jobs later, found that three of the four things a quality tier is supposed to change
did nothing at all.

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

## ▶️ START HERE — **group 05, the Workshop**

Job #011 is **done** ([summary](../Jobs/011/final-summary.md)). The HUD renders Coins, Magnet Flow,
Scrap/Capacity, banners and an upgrade panel, measured and verified on the phone preset.

**Next: [build group 05](build/05-workshop.md).** Coins now buy magnet levels — job 011 wired
`RequestUpgrade` for real rather than ship a dead button — so group 05 is *putting a physical
building around a transaction that already works and has been attacked*, not inventing one.
`magnet.recycle` is still a dev command standing in for the recycle bench.

Read before starting: [PITFALLS](PITFALLS.md) (**58 entries** — #55–#58 are from job 011 and are all
about measurements that returned a confident default), and `Ui/Layout.luau`, which is now the only
place a screen is measured.

## ▶️ The bigger picture

After the Workshop: **group 08, rare cargo and escape** — which is what the gate question is actually
about. It is the strange object worth stealing and the guardian chasing you home.

🔴 **The most valuable next action is still not code.** The roadmap's gate asks: *when the player sees
a strange object in the distance, do they think "I want that on my robot"?* — and its fix-list, in
order, is **pull feel, sound, the break-free moment**. All three now exist, and as of job 011 your
scrap, coins and Flow are finally visible while you judge them. Ten minutes of a human playing it is
worth more than the next three jobs, and it is explicitly not something Claude can sign off.

⚠️ **Do not tick build-group checkboxes as a way of tracking progress.** `tools/gen-build-manifest.py`
rewrites those files and emits `- [ ]` unconditionally, so a tick is erased on the next run. Progress
lives in `Jobs/`.

⚠️ **`tools/luau-analyze.sh` now exists** (ported from Tide in job 011). Run it before any playtest —
it catches syntax and type errors on disk in about a second, without Studio.

---

## ⏳ Waiting on you

Kept short deliberately. Tide's equivalent list reached nine rows, each individually reasonable, and
together a backlog nobody was tracking ([PITFALLS #32](PITFALLS.md#32-the-waiting-on-you-list-grows-silently)).

| # | What | Why it needs you |
|---:|---|---|
| 1 | **Commit the work** | Claude never commits. You committed twice mid-session; everything after `1a2c6a6` is uncommitted |
| 2 | **Reopen the place in Studio** before the next publish | Its session reported `MaxPlayers = 60` after you set 12 on the web; publishing from a stale session could overwrite it |
| 3 | **One sound id: `UI.Press`** — [assets/registry/sounds.md](../assets/registry/sounds.md) | The other 14 landed. **Every button in the game is silent** until this one does, and style §7 says silence reads as broken. Spec written, audition it with F3. The audio rule forbids me filling it with a guess |
| 4 | At [the gate](roadmap/mvp.md#the-gate), **judge whether the sweep feels good** | A *feel* question, played. Not something Claude can sign off. Everything needed to judge it now exists: the pull, the sound, and — since job 011 — a HUD that shows you what you are earning while you do it |
| 5 | **One desktop Play session**: Test → Device → *off*, then Play | Job 011's layout has two arrangements and only the touch one is verified. The Device Emulator has **no scripting API** — I probed `StudioService`, `settings():GetService("Studio")`, `RunService` and `UserInputService` — so I cannot switch it off from here. One click settles it |

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
