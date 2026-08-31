# Handoff — where we left off

**Snapshot: 2026-08-31, end of session.** Read this, then [PITFALLS.md](PITFALLS.md), then
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
| **Sync** | ✅ Connected and **VERIFIED BOTH WAYS** — flat layout, 6 synced service folders (job 002). ⚠️ It DROPPED silently on a PC restart, 2026-08-31. To check: write a throwaway `.luau` into a synced folder and read the DataModel back; delete it and confirm the instance goes ([#11](PITFALLS.md#11-reopening-a-place-silently-drops-the-sync-connection)) |
| **Magnet** | ✅ **A hero mesh, not three boxes** (job 016). `ReplicatedStorage.MagnetMesh`, cloned per character, poles forward. ⚠️ It lives in the `.rbxl` and NOT in git — a script cannot texture a mesh ([#63](PITFALLS.md)) — so `Assets/registry/meshes.md` is the only record of its five asset ids outside the place |
| **Code** | ✅ **38 scripts** — 21 ReplicatedStorage (incl. the 5-module `Ui/` layer and `Workshop/`), 8 ServerScriptService, 8 StarterPlayerScripts, 1 ReplicatedFirst. **`tools/luau-analyze.sh` checks all of it on disk in ~1s — run it before any playtest** |
| **Assets** | ✅ 32 PBR maps for 8 `MaterialVariant`s · ✅ **all 15 sound slots landed.** ⚠️ `UI.Press` is 1.06 s against a brief asking ≤0.25 s — **audition it with F3**; if it rings, swap a shorter switch from the same set |
| **Kit** | ✅ **27 pieces**, generated from spec, tiling verified. Job 012 added `Light_Gantry` and `Station_Machine`, and rebuilt `Sign_NeonSlab` (dark face + glowing rim, per the concept art) |
| **Gameplay** | ✅ **The magnet.** Four-state scrap, pooled + capped, batched server grant, Flow → RUSH, Capacity → SCRAP FULL, Magnetic Drive, five VFX states |
| **Sound** | ✅ **The game makes noise.** 15 slots filled and verified in Play; `AudioBench` (F3) auditions a candidate in the slot it will occupy. ⚠️ Two licences in `SoundKit.LANDED`: 14 are Pro Sound Effects (Roblox-only), `UI.Press` is the owner's own upload |
| **Boot** | ✅ **The game has an opening, and it has art.** `ReplicatedFirst` handoff, four real load conditions, the title card, one line of tutorial that retires itself — and job 015's live `ViewportFrame` diorama: the magnet, a corridor, a robot, the player, and scrap that flies in per completed stage. **The last P0 is closed** |
| **Workshop** | ✅ **A lit hub with seven working-or-honest stations.** 425 parts from a spec in git; the Magnet Lab and Recycler are wired, the rest name the group they wait on |
| **HUD** | ✅ **The game shows you what you are doing.** Coins, Flow ×1–×5 → RUSH, Scrap/Capacity, SCRAP FULL, banners, and a working upgrade panel. Measured on the phone preset (canvas **666×316**) and clear of Roblox's own thumbstick and jump button. ✅ The **desktop** arrangement is now verified too (canvas 1825×1255, `touch=false`, layout clean) |

**What is NOT built:** zones 1–2, rare cargo and extraction, guardians, the robot, the Arena,
persistence, the Factory Refresh. **Groups 07–12.** Groups 04, 05 and 06 are done.

✅ **The P0 that was knowingly skipped is done (job 015).** §7 wanted the player, a magnet, flying
scrap, a robot and a corridor — all five are there, built from primitives in a `ViewportFrame`, with
a 2D halo painted behind it. The `ART MISSING` warn is gone, replaced by a guard that counts what
actually got built and **was proven able to fire**. The four emoji are retired.

🔴 **Still not verified: the phone preset.** The Device Emulator has no scripting API. Desktop is
measured; phone is reasoned about. See *Waiting on you*.

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
| **014** | Boot & the loading screen | Real stage completion, not a timer — PLACE holds until there is **ground under the player's feet**. Three defects only a screenshot could find: an invisible progress bar, a 🪙 rendering as tofu, and a glyph vanishing at its dim transparency |
| **013** | The stations work | Prompts on all seven; the Magnet Lab **reuses** job 011's upgrade panel rather than rebuilding it; the Recycler asks the economy's real question — Coins or robot HP, side by side, neither pre-selected — and banks +1,920 coins end to end. Wrote a PITFALLS #47 field annotation *after* reading #47 |
| **012** | The Workshop room | 425 parts from a spec in git — seven coloured station machines, neon signage, hall lighting, a measured Arena sightline. **Built the lighting to a sentence in a doc instead of to the concept art beside it** and produced a black room. Independent review found 13 issues, 11 real — two dressing pieces landing through walls, and the plinth hiding the sign on all seven stations |
| **011** | Boot & HUD (the HUD half) | Coins, Flow, Scrap/Capacity, banners, upgrade panel, and a layout audit that ships. **Six defects found while building, eleven more by the review** — including a modal that re-centred the scrap readout onto the thumbstick permanently, and a `hud.hide` that missed the banner and so invalidated its own decision-0018 check. Wired `RequestUpgrade` so coins buy something |
| **016** | The magnet becomes a real object | The player's hero prop was three welded boxes. Now it is the key-art horseshoe — red + cyan, chrome pole shoes — pointing where the player looks. **Two owner corrections: it was upside down (a horseshoe pulls with its OPEN end), and I had generated from the wrong reference entirely** — `Robot.png`'s crane-mounted magnet instead of `Logo2.png`, the game's own key art, which was already in the repo and which I had never opened. Found [PITFALLS #63](PITFALLS.md): a script cannot write `SurfaceAppearance` maps, and the command bar says it can |
| **015** | The loading screen gets its art | A live `ViewportFrame` diorama instead of a flat image, because §7 asks the screen to *feel interactive* and a picture cannot. **A probe measured, before any art existed, that a ViewportFrame renders no Bloom, no `Beam` and no `ParticleEmitter`** — so the glow is painted in 2D behind a transparent viewport. Found the 🪙 coin still rendering as tofu (`finding 0003`), contradicting job 014's summary: `FontFace` cannot add a codepoint no font contains. Six composition passes; three of them read as a doorway |
| **009** | Quality tiers, repaired | Light cull **could never fire** (kit max 18 vs threshold 40); Low's PBR drop **undone by the server on every spawn** |


**Pattern worth noting, and it has not broken once in fourteen jobs:** every job has had a real
defect found by review or by running it, and several were things already reported to the owner as
working. Job 006 was reported complete and its review, three jobs later, found that three of the four
things a quality tier is supposed to change did nothing at all.

**The four jobs of 2026-08-31 held the pattern and sharpened it.** Roughly 60 review findings across
011–014. The two worst were not in new code at all:

- **Sweeping and recycling both minted Coins for the same scrap.** Invisible for six jobs, because the
  Recycler did not exist to be the second mint. Spec §48's exact 3,600 came out as 3,750 — and worse,
  Flow's multiplier sat on the pickup grant, so a **MAGNET RUSH was multiplying ~1/25th of the payout.**
- **`RequestRecycle` had no server-side proximity check.** The only thing tying recycling to the
  Recycler was a `ProximityPrompt` firing in a LocalScript. `Capacity` is a *paid* upgrade whose whole
  value is how far you can sweep before walking back — remote cash-out made it worthless.

**The recurring shape, now seven PITFALLS entries deep (#55–#61), with #62 added by job 015:** *a measurement that returned a
confident default, or a check that passed because it was measuring nothing.* A disabled `ScreenGui`
reporting 800×600 forever. `layout clean` against zero rectangles. A validator asking whether an
offset divided by 4 instead of where the piece landed. A sightline aimed down the one axis the gap was
cut on. `Theme.audit()` structurally incapable of failing. A boot stage that was `return true`.

**And twice this session a CHECK agreed with the bug it was written to catch** — because both used the
same wrong assumption. `CFrame.LookVector` is −Z, and the verification used it too. Write the check
from the other direction.

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

## ▶️ START HERE — **group 07: zones 1–2**

Jobs #011–#015 are done. **The core loop is playable end to end**: the game boots with a real loading
screen, teaches itself with one line of text, you sweep scrap, watch Coins and Flow on a HUD, walk
into a lit Workshop, upgrade your magnet at the Magnet Lab and recycle scrap for Coins at the
Recycler — which asks you the game's actual economic question.

**Next: [build group 07](build/07-zones-1-2.md)** — both zones as self-contained streamable chunks,
their scrap sets, the zone manager, and the 1→2 gate. The Factory Entrance station is already
standing and already says `ZONE 1 OPENS IN GROUP 07`; it is waiting for exactly this.

Then **group 08 (rare cargo + escape)**, which is what the roadmap's gate question is really about.

Read first: [PITFALLS](PITFALLS.md) — **62 entries**. #55–#61 came out of jobs 011–014; **#62** is job 015's, and it is an engine constraint worth knowing before any UI work: *a `ViewportFrame` has no Bloom, no `Beam` and no `ParticleEmitter`.*
Most are one shape: *a measurement that returned a confident default, or a check that passed because
it was measuring nothing.*

⚠️ **The Workshop is GENERATED, not hand-placed** — `Workspace` does not sync, so the room lives in
git as data ([0017](decisions/0017-the-kit-is-generated-from-a-spec.md)). It builds on Play. To see it
in the **editor**, reopen the place first (Studio caches modules for a whole Edit session), then run
`require(game.ServerScriptService.WorkshopBuilder).build()` — [#61](PITFALLS.md#61-a-generated-world-is-invisible-in-the-editor-and-the-editors-copy-goes-stale).
Zones should follow the same pattern.

⚠️ **`tools/luau-analyze.sh` exists.** Run it before any playtest — it caught a syntax error in three
of the last four jobs, including a PITFALLS #47 field annotation written *after* reading #47.

## ▶️ The bigger picture

🔴 **The most valuable action is still not code, and it is now fully answerable.** The gate asks:
*when the player sees a strange object in the distance, do they think "I want that on my robot"?*
Every ingredient exists — the pull, the sound, a HUD that shows what you are earning, a hub worth
returning to, and a first-run experience. Ten minutes of playing it is worth more than the next three
jobs, and it is explicitly not something Claude can sign off.

⚠️ **Do not tick build-group checkboxes as progress.** `tools/gen-build-manifest.py` rewrites those
files and emits `- [ ]` unconditionally. Progress lives in `Jobs/`.

---

## ⏳ Waiting on you

Kept short deliberately. Tide's equivalent list reached nine rows, each individually reasonable, and
together a backlog nobody was tracking ([PITFALLS #32](PITFALLS.md#32-the-waiting-on-you-list-grows-silently)).

| # | What | Why it needs you |
|---:|---|---|
| 0 | **A commit** — job 015 (`BootScreen`, PITFALLS #62, `Jobs/015/`, `findings/0003`), plus the still-pending deletion of `studio_game/ReplicatedStorage/SyncProbe.luau` | ⚠️ The SyncProbe was a throwaway used to test that sync had reconnected; it got swept into `de43055` before being deleted. Removing it is correct — it was never game code |
| 1 | **Audition `UI.Press` with F3** — `89108158102227`, your own Jungle upload | It is **1.06 s** against a brief asking ≤0.25 s. If it rings, a shorter switch from the same `Toggle Switch, Industrial` set replaces it. It fires on *every tap in the game*, so a tail becomes a melody |
| 2 | At [the gate](roadmap/mvp.md#the-gate), **judge whether the sweep feels good** | A *feel* question, played, and the roadmap gates everything after zone 2 on it. Every ingredient now exists: the pull, the sound, a HUD showing what you earn, a hub worth returning to, and a first-run experience |
| 3 | **Confirm [finding 0002](../findings/0002-magnet-flow-now-multiplies-scrap-not-coi.md)** — Magnet Flow now multiplies **scrap**, not Coins | Fixing the double mint was unambiguous; **where Flow's bonus lands is a balance call Claude made alone.** A Rush now fills the magnet faster instead of paying more per pickup, which interacts with the paid Capacity track. `Economy.TUNED` is still false |
| 4 | **The Workshop half of the concept-art gap** — the loading screen half is done | Still a blockout: no ceiling, no conveyors, no floor arrows, and the machines are simpler than `assets/concept_art/Arena.png`. 🔴 **This half is parts work for `KitSpec`, not Meshy** — style §3 is parts-first and §5 names conveyors, floor arrows and crates as kit pieces. Job 015 established that; do not re-litigate it |
| 5 | ✅ **DONE — the phone pass ran** (owner flipped the emulator, 2026-08-31). Found and fixed a 3 px magnet/tagline overlap that existed on **desktop too**; confirmed the halo stays circular; hero mesh costs **+0.31 ms**, below the noise floor. **The HUD's layout audit ran against 5 real reserved rects for the first time and passed** — on desktop it had always had 0 rects to collide with | Nothing outstanding. The one caveat: Studio is pinned at 67 ms/frame regardless, so "no measurable cost" is not "free on real hardware" |
| 6 | **Reopen the place before the next publish** | An earlier session reported `MaxPlayers = 60` after you set 12 on the web; publishing from a stale session could overwrite it |

---

## ⚠️ One process deviation, 2026-08-31

`CLAUDE.md` sets the job lifecycle as **intake → implementation-plan → summary + changelog**.
**Jobs 013 and 014 have no `implementation-plan.md`** — 011 and 012 do. They went straight from
intake to building because the intakes were unusually specific and the work was a continuation of the
job before.

It is recorded rather than back-filled: writing a plan *after* the fact is paperwork, not planning,
and it would misrepresent how the work actually went. Worth reinstating for group 07, which is bigger
and less obvious than either of those.

---

## 🖥️ Environment state, 2026-08-31

Things a fresh session cannot discover by reading code.

| | |
|---|---|
| **Studio** | Open on the right place. **Restarted mid-session (PC reboot).** The place WAS saved first — the lighting and all four jobs' code survived |
| **Studio Sync** | Dropped silently on the restart, then reconnected and **verified in both directions**. If anything looks stale, suspect this first ([#11](PITFALLS.md#11-reopening-a-place-silently-drops-the-sync-connection)) |
| **Device Emulator** | Was ON (phone preset) for most of the session, then switched OFF by the owner — which is how the desktop layout finally got verified. It has **no scripting API**; ask the owner to flip it |
| **Lighting** | Saved into the place: ClockTime **14**, Brightness 2.5, Ambient 70/76/90, `EnvironmentSpecularScale` **0.30**. Bootstrap asserts these and warns on drift, because `Lighting` does not sync |
| **Meshy MCP** | ✅ **CONNECTED and unused.** Job 015 was going to spend ~27 credits on 2D key art; the owner redirected to in-engine and **nothing was spent — balance still 1,240**. Meshy stays for hero *meshes* (style §3), not for screens. First connected 2026-08-31 (later session). It had failed with `CONNECT_TIMEOUT` earlier the same day; it came up on its own on the next start. Balance read back: **1,240 credits**. The owner has granted use of it and said not to worry about credits |
| **Studio's own AI** | `generate_mesh`, `generate_procedural_model` and `generate_material` ARE available. Different pipeline (no rigging, no remesh→retexture chain) but fine for static dressing and the loading-screen art |

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
