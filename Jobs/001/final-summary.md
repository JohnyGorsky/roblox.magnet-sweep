# Job #001 — final summary

**Project:** `roblox.magnet-sweep` · **Status:** complete · 2026-08-29

## What was delivered

**Plumbing**
- `magnet-sweep` registered in `roblox.workspace/tools/job.py` (the only file touched outside this repo,
  besides two capture-queue entries).
- `CLAUDE.md`, `README.md`, `.gitignore`, `.jobconfig.json` (marked **UNVERIFIED**), and the repo tree to
  workspace convention: `docs/ Jobs/ Planned/ todo/ findings/ tools/ assets/ studio_game/`.

**Two skills** — per-game context has to be a skill in this multi-root workspace, because only the
workspace `CLAUDE.md` auto-loads.
- [`magnet-sweep-project`](../../.claude/skills/magnet-sweep-project/SKILL.md) — the entry point, the
  one-place topology, eleven non-negotiables, the docs map, the gate.
- [`magnet-sweep-style`](../../.claude/skills/magnet-sweep-style/SKILL.md) — the glossy-metal look: what
  "shader" actually means on Roblox, the palette, per-zone colour identity, the nine-variant material
  kit, the lighting recipe, the VFX vocabulary, UI tokens, quality tiers.

**The design pack** — the 87-section spec redistributed into 7 game docs, 16 system docs, 5 content docs
(including the full 96-part catalog), 15 decision records, a feature template and 2 roadmap docs.

**The build manifest** — 14 groups, **572 items**; the MVP (groups 01-12) is **349** of them.

**[PITFALLS.md](../../docs/PITFALLS.md)** — 47 entries, each *incident → rule → the check that catches
it*, with anticipatory entries labelled as such rather than dressed as history.

**Five scripts in `tools/`**, so the numbers are computed and re-runnable rather than typed:
`gen-content-catalogs.py`, `gen-build-manifest.py`, `gen-spec-coverage.py`,
`verify-catalog-vs-spec.py`, `check-links.py`.

## Verification

Checks that were capable of failing, and their results:

| Check | Result |
|---|---|
| 96-part catalog diffed field-for-field against the spec's twelve tables | 96/96 exact — 0 fabricated, 0 dropped. Rarity is deliberately re-graded (0015) and the spec's own grade is kept in its own column, which is what the check reads |
| 12 guardians + 12 power-curve values present | all present |
| Relative markdown links (incl. `../../../` from both skills) | 405 checked, 0 broken |
| Heading anchors | 56 checked, 0 broken |
| Manifest arithmetic | regenerates byte-identical; 572 = 430 + 122 + 20 |
| All 87 spec sections mapped | 87/87, 0 unmapped |

**No Play verification was possible or attempted** — there is no place, no code and nothing to run. The
intake checklist's "reproduce in PLAY" step is **not applicable** to a docs-only job, and is marked so
rather than ticked.

## The independent review (GROUND-RULES §8)

One reviewer, given the spec and the repo and **deliberately not told the reasoning**. It found real
defects across every class it was asked to hunt. All were verified independently before being acted on;
all are fixed.

### Engine facts — the serious half

Seven wrong or stale claims, **six of them in the file that originated as the user's own mid-session
architecture proposal**. Folding a proposal in is not fact-checking. Verified against
`Roblox/creator-docs` raw YAML.

| | Was written | Actually |
|---|---|---|
| **Animation priority** | `Idle < Movement < Action < Action2/3/4 < Core` | **`Core` is the LOWEST**, despite its value being 1000. An attack clip on `Core` loses to `Idle` |
| **Where to play NPC animations** | "on the CLIENT" | An `Animator` not in a player character *"must be loaded and started on the server to replicate"*. A client-played track on a server-owned Arena robot is visible to **one** player |
| **`SurfaceAppearance`** | interchangeable with `MaterialVariant` | **MeshPart-only.** On a plain `Part` it renders nothing. This game is parts-first, so `MaterialVariant` is the PBR path |
| **Metalness / roughness** | scalar values per variant | **Maps only.** Those numbers are authoring targets for 18 greyscale images — a real, previously uncosted asset task |
| **`Enum.Font.Gotham`** | the UI typeface | Removed May 2024; silently maps to Montserrat, carries **no** deprecation tag. Use `FontFace` + BuilderSans |
| **`CollisionFidelity`** | "set it on import" (implying a script could) | `PluginSecurity` on write, *"cannot be manipulated by scripts during runtime"*. Works in the command bar, fails in a `Script` |
| **`Lighting.Technology`** | `= Future` | Superseded by `LightingStyle` + `PrioritizeLightingQuality`; not script-writable at all |

Plus corrections to `PrismaticConstraint` property names, `AlignPosition.MaxForce` (a no-op when
`RigidityEnabled`), `CanQuery`/`CanTouch` ordering, `Reflectance` (skybox only, and
`EnvironmentSpecularScale` defaults to 0), and the robot-name filter (two calls, and
`GetNonChatStringForUserAsync` is the documented one for a nameplate).

**Two of these are inherited, not invented.** The priority ladder and the client-side advice are copied
faithfully from the shared `roblox-animation` skill — which GROUND-RULES §6 makes mandatory reading. The
skill is wrong, so the rule currently propagates the errors into every game.
→ **`roblox.workspace/findings/0002`**, with exact replacement wording. That fix is a workspace job and
was deliberately **not** made from inside this one.

### Documentation defects

| Class | Found | Fixed by |
|---|---|---|
| **Invented content presented as the spec's** | Themes for 8 tiers and scrap lists for 10, unmarked. The spec gives a theme only for tiers 1/2/3/5 and objects only for 1/2 | every derived value now marked **(derived)**; the generator emits the marks |
| | `Capacity` added to the Overclock reset list; the spec resets four things | corrected, with a note that changing it needs a new decision |
| | A §77 "divergence" manufactured by truncating *"…made from curated room modules"* | divergence removed — 7 → 6 |
| **Coverage by link** | §4 (store description) and §75 (midgame) claimed covered; neither had landed anywhere | both written; the coverage rows now name what actually arrived |
| **Counting errors** | "no zone is self-sufficient" (all 12 are); "three of four late mobility parts are Epic" (two); "9 of 12 legendaries" (9 of 13) | Observations now **computed** by the generator, not written by hand |
| | `P0` labelled "MVP" for 149 items that are explicitly post-gate | manifest reports MVP (349 / 281 P0) and post-gate separately |
| **Self-contradiction** | A style rule broken by its own table: 9 of 12 zone accents reused a reserved signal colour | zone palette rewritten; the reserved set is now stated and the one accepted collision is explained |
| | "Each of these has a stated failure condition" — 3 of 5 rows had none | thresholds added; the missing budgets are called out as not-yet-chosen |
| | Missing `MobilitySocket`; profile count stated three ways; `§N` meaning two different things | all resolved |
| **Stale fact** | "this repo has **zero commits**" — false when written; `cf6a90a` landed mid-session | corrected in HANDOFF and the plan |
| **Misattributed incident** | PITFALLS #42 blamed streaming; Jungle's records say it was a `CLEAR_Y` constant vs voxel grid snapping | rewritten as the constant-vs-measurement bug it was, with streaming kept as a *separate* hazard |

Three new PITFALLS entries (**45-47**) came out of the review itself: the rendered docs site misreporting
deprecation, enums that do not order by value, and capabilities that work in the command bar and fail in
a `Script`.

## What the reviewer said that was *not* acted on

> "The pack is over-built for where the project is — 98 files against zero code, and the single question
> everything is gated on is answered by build group 04."

That is a fair criticism and it is recorded here rather than argued with. The full pack was an explicit
choice made at intake via the wizard, with a skeleton offered as the alternative. It stands, but the
manifest's ordering already concedes the point: groups 05-14 are gated behind
[the gate](../../docs/roadmap/mvp.md#the-gate), and roughly half the system docs describe systems that
may never be built if the sweep does not feel good.

## Files changed

All of `roblox.magnet-sweep/` except `assets/MAGNET SWEEP.md` and `assets/concept_art/`, which are
untouched. Outside this repo: `roblox.workspace/tools/job.py` (project registration),
`roblox.workspace/todo/0001`, `roblox.workspace/findings/0002`.

No Luau was written. No asset was sourced. No place exists.

## Follow-up in the same session: sixteen open questions answered

After the review, the open-question list was put through the wizard and settled. Two answers were
load-bearing enough to become records:

- **[0014 — the owning guardian chases you.](../../docs/decisions/0014-the-owning-guardian-chases.md)**
  A steal-an-egg rule replacing §23's flat 5-second recovery window. Guardians are inert until you
  steal; only the owning guardian chases, and it chases across zones. Caught inside its territory the
  part **resets**; caught outside, you ragdoll and it **drops** neutral. This came from the user, not
  from the spec, and it is better than what the spec describes — it gives the escape a sprint-then-walk
  shape, makes the zone boundary a real finish line, removes the ragdoll lottery, and guarantees exactly
  one pursuer at a time in a streamed corridor.
- **[0015 — rarity is re-graded.](../../docs/decisions/0015-rarity-is-re-graded.md)** 18 / 27 / 27 / 12 /
  11 / 1, banded per tier, spec grade preserved in its own column and still verified.

The other fourteen went into their system docs; the full table is in
[decisions/INDEX](../../docs/decisions/INDEX.md#answered-by-the-user-2026-08-29). What remains open is
now cleanly separated in [HANDOFF](../../docs/HANDOFF.md#-still-open) into **measurements** (which need
Studio, not a decision), **content that does not exist yet** (per-part stats, Relic Parts), and small
deferrable calls.

`todo/0000` (rarity) and `todo/0001` (hub placement) are resolved.

## Next

**Job 002 — create the place and probe the sync layout.** See
[HANDOFF](../../docs/HANDOFF.md#-the-bigger-picture). Before any robot code is written, the
`roblox-animation` skill fix (workspace finding 0002) should land, or the next game repeats this.
