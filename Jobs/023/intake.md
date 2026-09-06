# Job #023: Floor 1 — the first factory room, its doors, and its reset

**Project**: `roblox.magnet-sweep`
**Created**: 2026-09-06
**Status**: ✅ Intake complete — 2 reviewers run, 5 decision records written (0021-0025), all design questions answered (2026-09-06). **Next: the implementation plan.**

## Requirements / goal

Build **FLOOR 1** (tier 1, **COLOR WORKSHOP**) as a real room behind the Workshop's factory doors —
a designed space, not a box — and make its loop work:

> **sweep in peace → want the item → a 5-second grab → the boss wakes → run, or die.**

And decide the rules for **when those doors open and when they close** — closing **resets the whole
room**.

🔴 **This is the first job where the core loop closes.** Sweeping, the Workshop and the Robot Bay all
work; nothing connects them, because there is no way to obtain a part by playing. Floor 1 is that
connection.

## What the owner has said (verbatim)

> *"it will be long corridor, with multiple zones, each has doors like the first ones"*
>
> *"each zone is not long but full of scraps, boss guarding it and item"*
>
> *"i do not want simple room, it will have also some static objects so it look cool, so each room
> will have its design, there somewhere will be boss guarding its item, and scraps around, each room
> will have its level scraps"*
>
> *"1) path not always straight 2) we have big walls same as in main building 3) we have some
> creeates or static elements where scrap is laying aroun 4) we have area where boss sits and guards
> it item 5) doors somewhere so we can get to next area. I think walls should be as in main area -
> far walls and walls closer crating the same atmosphere, we can reuse different titles arrows etc"*

Four requirements fall out of that, and none of them is optional:

1. **Short, not long.** A room you cross, not a corridor you trudge.
2. **Dense with scrap** — and **each room has its own scrap LEVEL**, i.e. tier 1's scrap is tiny
   (screws, nuts, washers, bolts, gears, springs, beads, small pipes) and later rooms escalate.
3. **A boss guarding one item.**
4. 🔴 **Not a simple room.** Static set-dressing is a *requirement*, not polish — **each room gets its
   own design**. A grey box with scrap on the floor fails this job even if every mechanic works.

## 🔴 The room, as five requirements

These are the owner's own numbering. Every one is a build requirement, not a suggestion.

| # | Requirement | What it rules out |
|---|---|---|
| 1 | **The path is not always straight** | a corridor you can see the end of from the door |
| 2 | **Big walls, like the main building** — far walls *and* nearer walls, same atmosphere | a flat boundary box; open sky above |
| 3 | **Crates / static elements with scrap lying around them** | scrap scattered on a bare floor |
| 4 | **An area where the boss sits and guards its item** | a boss wandering the whole room |
| 5 | **Doors somewhere through to the next area** | a room with one way in and no way on |

Plus, explicitly: **reuse the existing tiles, arrows and kit pieces.** This is not a from-scratch art
job.

### 🔴 Requirement 2 is the big one, and it already has a proven implementation

*"walls should be as in main area — far walls and walls closer creating the same atmosphere"* is
**exactly what job 021 built** and measured. `WorkshopLayout.BACKDROP` records the whole recipe:

| Layer | | parts |
|---|---|--:|
| L1 collar | r 254, y 0–48 | 9 |
| L2 wall | r 268, y 40–130 | 12 |
| L3 clerestory + strips | glowing window band, cyan strips, amber accents | 108 |
| L4 trusses | a grid at y 122/130 with hazard bands + 25 lamp gantries | 106 |
| L5 roof | glazed — 49 glowing panes at y 150 in a dark deck | 168 |
| Facet bands ×12 | five types, no two neighbours alike | 476 |
| Bay lighting | 3 recessed machinery bays lit from within | 117 |
| **Meshy pieces** | 3 generated, tiled into runs | **28** |
| | **Total** | **1024** (185 Neon) |

⚠️ *The Meshy row was missing from an earlier draft of this table, whose rows summed to 996 against a
stated 1024. Count the rows — PITFALLS #9.*

It took sky across the room from **45.7 % → 0.0 %**, verified in Play. Two findings from that job
transfer directly and must not be rediscovered:

- 🔴 **Atmosphere cannot substitute for a roof.** Pushed to Density 0.50 the haze **erased the
  backdrop itself** — haze acts on distance and the backdrop is at that distance. The sky closes with
  geometry or not at all.
- 🔴 **`PointLight`s are useless on a backdrop.** `QualityController` clamps every non-`Hero` light to
  10 studs on Low. **185 of the backdrop's parts are `Neon`**, which is the only lighting that
  survives every tier. A far wall that reads only by light spill is invisible on a phone.

⚠️ **The Workshop's version is circular** — a 12-gon of facets at a radius. Floor 1 is a room on a
diagonal path, so the layering idea transfers but the *geometry* does not. The plan has to say how a
non-circular room gets the same near/far/roof treatment, and `WorkshopLayout.BACKDROP` is the numbers
to start from, not a thing to clone.

⚠️ **Cost.** The Workshop is already **3,595 parts** against `MAX_PARTS_IN_VIEW` 1800, and a 1024-part
backdrop is most of a second one. Floor 1 streams as its own chunk, so the two should rarely be in view
together — but that is an assumption this job must **measure**, not assert. Performance has still never
been measured on a device.

## 🔴 THE ZONE LOOP — what actually happens in the room

The owner's mechanic, verbatim:

> *"boss only atacks you if you pick up item, and picking up item will require like 5 seconds, once
> you got part you have to run outside area, if boss catches you he kills you"*

Four beats:

| | Beat | |
|---|---|---|
| 1 | **Sweep, in peace** | The boss is inert. Scrap collection is safe, and stays 55 % of playtime |
| 2 | **The 5-second grab** | Taking the item is a **channel**, not an instant pickup. Five seconds where you are committed and exposed |
| 3 | **The boss wakes** | It attacks *only* because you took the item |
| 4 | **Run** | Out of the area, with the boss chasing. **Caught = death** |

🔴 **This is the game's whole point, at one-room scale.** The pitch is *"I'm running away from a
security robot while dragging an engine behind me"* — this is that, in miniature, and it is the first
time the loop closes: sweep → want → steal → run → build.

**It fits the accepted decisions cleanly**, which is worth stating because it means nothing has to be
overturned:

- [0014](../../docs/decisions/0014-the-owning-guardian-chases.md) — *"Guardians are inert until you
  steal. A player carrying nothing is never threatened."* Exactly beat 1 → 3.
- **§22's escape gameplay** — the 20–45 second run home while slowed by what you are carrying.
- The **5-second channel** is what makes a Salvage Breach legible: it is the window where the alarm
  starts and you cannot yet run.

### What this leaves open

1. 🔴 **"Run outside area" — how far is safe?** Leaving the room? Back through the entry doors into the
   Workshop? Or all the way to a Service Hub? **This is the collision with
   [decision 0008](../../docs/decisions/0008-secured-at-the-hub-not-in-hand.md)**, which says ownership
   transfers at the hub *and nowhere else*, and that unsecured cargo does not save on disconnect. For
   zone 1 the Workshop is immediately next door, so "outside the area" and "home" are nearly the same
   place — but the answer sets the pattern for zones 2–12, where they are very much not.
2. 🔴 **"He kills you" — and then what happens to the part?** Decision 0014 already distinguishes:
   caught **inside** the guardian's territory, the part **resets**; caught **outside**, you ragdoll and
   it **drops for anyone**. Confirm that is what is wanted, and what death costs the player besides the
   part (respawn where? lose carried scrap?).
3. **Can you re-try?** After a death or a successful steal, does the item come back — and is that the
   same event as the **room reset** below? These may be one mechanic, not two.
4. **What does the boss do to a player carrying nothing?** Decision 0014 says: nothing. Confirm it
   never blocks a pure sweeping run, even though both concept sheets place it on the path to the exit.
5. **Interaction with the 5-second channel:** can it be interrupted? Does moving cancel it? Can two
   players channel the same item?

⚠️ **`RequestDetach` is declared and unbound**, and there is no guardian, no breach and no chase code
anywhere. Beats 2, 3 and 4 are **all new**. That is the real size of this job, and it is why the scope
question below matters.

## ✅ DECIDED by the owner (2026-09-06)

| Question | Decision |
|---|---|
| **What makes you safe** | **Back through the entry doors.** The room is the danger zone; cross into the Workshop and the boss stops |
| **Doors & reset** | A **global timer** — see the lockdown below |
| **Two players** | **Shared room, one item, first grab wins.** Player A grabs, the boss chases A only; B keeps sweeping untouched |
| **Tier 1 palette** | **Keep pink/mint/lemon as the accents** — the art's structure and machinery, gelled and painted candy pink `#FF6FB5`, mint `#7FE6C4`, lemon `#FFE066`, so COLOR WORKSHOP reads as colourful and distinct from the steel-blue Workshop |

### ✅ DECIDED — round 2 (2026-09-06, wizard)

The intake's five open questions are now answered, plus two it had not asked.

| Question | Decision |
|---|---|
| **Teleport vs walk** | 🔴 **The player WALKS.** Floor 1 is built physically attached to the wall aperture at (1790, 12, 31) and the corridor runs outward from it. `ZoneManager.sendTo`'s `PivotTo` is retired — **this needs a decision record**, because it changes a shipped system |
| **Scope** | **Room + steal + boss chase.** Bind `RequestDetach`, the 5-second channel, boss wake / chase / kill. 🔴 **The Lockdown moves to job 024** — it barely bites in zone 1 |
| **Item respawn** | 🆕 *(not asked in the original intake)* **A 30–60 s cooldown**, matching 0006's scrap refresh. The plinth is never dead for long and the Robot Bay is fed fast |
| **Where a tier-1 part becomes OWNED** | 🆕 *(not asked)* **At the Workshop entry doors.** Crossing them both ends the chase *and* transfers ownership — **the Workshop is hub 0**. **Decision 0008 needs an amendment naming it** |
| **Boss position** | **The middle of the room, guarding the item** — not posted at either door. Owner: *"Boss is always somewhere in the middle and guards item, so he is in the middle."* It wakes at the plinth and pursues from there; the room's geometry, not a guard post, sets the difficulty |
| **The 5-second channel** | **Moving cancels it, and it restarts from zero.** The plinth **locks to the first player who starts** — a second player cannot channel it until the first stops |
| **"Catches you"** | **A server-side radius, ~6 studs, with a ~0.5 s dwell.** Not a `Touched` event — robust under lag and on mobile, and it never kills on a graze |
| **Tier 1 roll table** | **Common 60 / Uncommon 30 / Rare 8 / Legendary 2** — i.e. `WORK_LAMP`·`MINI_MOTOR`·`PAINT_DRUM` 20 % each, `PIPE_WRENCH`·`SPRING_PUNCHER`·`CASTER_WHEELS` 10 % each, `MAGNET_COIL` 8 %, `GOLDEN_GEAR` 2 %. The concept banner's `WORK_LAMP` stays honest as the typical roll |

⚠️ **Three consequences the plan must carry:**

1. **Walking, not teleporting, makes placement load-bearing.** Floor 1's entry has to line up with
   the **real clear opening — 42 wide, centred z = 41, head height 22** (see the corrected row above;
   the 62 × 24 × 8 at z 31 is the frame's bounding box and building to it lands the centreline 10
   studs off, into a collidable slab). `Zone1Spec`'s `ORIGIN (0, 0, -200)` is dead.
2. **The boss sits mid-room, so the room's shape is the difficulty.** With the escape being *back
   through the entry doors*, a central boss means the item is placed deeper than the boss and the run
   home crosses it. The plinth's position relative to the boss is now a level-design decision, not a
   dressing one.
3. 🔴 **A 30–60 s item respawn with the Lockdown deferred means floor 1 ships with no reset pressure
   at all** — a safe, repeatable part farm until job 024 lands. Acceptable for one job, but playtest
   it knowing the clock is missing rather than mistaking it for the finished loop.

### ✅ DECIDED — round 3 (2026-09-06, after two independent reviewers)

Two reviewers ran against this job: one given only the owner's words and the repo (never this intake),
one told to attack this intake claim by claim. **They converged independently on five collisions**,
which is the strongest signal in the job. All five are now settled by decision records.

| Question | Decision |
|---|---|
| **Editor-placed vs generated** | 🔴 [0019](../../docs/decisions/0019-hero-geometry-is-editor-placed-and-exported.md) **forbids** hand-built zones — *"Zones stay generated. 0006 requires it."* — and this intake cited it *approvingly* as its licence to do exactly that. Settled by **[0023](../../docs/decisions/0023-the-room-is-placed-the-contents-are-spawned.md)**: the owner's line is *"whole room must be built, but items they are scripted of course"* — **what stands still is placed; what comes back is spawned** |
| **Does the boss kill?** | **Yes** — **[0024](../../docs/decisions/0024-the-guardian-kills.md)**, superseding 0014's non-lethal catch outcomes and `docs/systems/guardians`'s *"there is no combat"*. Death costs the **carried item only** |
| **One plinth vs the shipped pool of 8** | **One plinth** — **[0025](../../docs/decisions/0025-one-plinth-one-item.md)**, superseding 0006's pool-of-8 and deleting the duplicate `Zones.RARITY_WEIGHT` |
| **The corridor vs job 021's backdrop** | **Cut a visible opening** — you see the factory from the corridor, which fits the approved "bar wall" facet. ⚠️ It re-opens sky where every player looks when leaving, so **the corridor needs its own roof immediately**, not as polish |
| **The art's reserved signal colours** | **Signal colours win.** Plinth and chevrons take the tier-1 accents; crates lose green and orange |

### 🔴 What the reviewers found that this intake had WRONG

Not disagreements — errors, verified against source:

| Claim | Reality |
|---|---|
| *"a door frame in the Workshop wall and nothing behind it"* | Wrong in **both halves**. The frame holds a **closed, `CanCollide` MeshPart** (32 of 36 character-box slots blocked), and outward of it there is **no floor at all** — x = 1795 / 1840 / 1900 all VOID over a 2,000-stud drop |
| The doorway is *"62 × 24 at (1790, 12, 31)"* | That is the **bounding box**. `Infill` (20 × 24, collidable) fills a third of it. The **real opening is 42 wide, centred z = 41, head height 22** — and `WorkshopLayout.luau:194` already said so. Building to the box lands the centreline **10 studs off** |
| *"`Cargo` appears only in config…"* | `MagnetState.setCargo` and the carry-speed penalty are **already implemented** |
| *"the roll table still needs writing down"* | `Zones.RARITY_WEIGHT` already ships, at roughly **half** our Rare rate |
| *"loop layers 1, 2 and 4 work"* | Layer 2 returns *"not built yet"* every time — contradicted by this document's own measurement |
| The BACKDROP table | Dropped the 28-part Meshy row; printed rows summed to **996** against a stated 1024 |
| *"§84 says sweeping is 55 %"* | It is `docs/game/core-loop.md:70`, labelled *"derived — not a spec value"*. The error is copied into decision 0020 |

### 🔴 Three things every new decision depends on, none of which exists

| Missing | Consequence |
|---|---|
| **The exporter** | 0019 demanded it — *"or this record is just permission to lose the room"* — and it was never written. Under 0023 it is the world's **only** path into git. **Step zero** |
| **Zone registration for a placed room** | `ZoneManager.register`'s only caller is inside `ZoneBuilder.build`, which never runs. So `zoneContaining` returns `nil` **inside floor 1** — and under 0022 `nil` means *Workshop, safe and secured*. The guardian would give up instantly and the part would secure on detach, **both tests passing while doing nothing** |
| **`weight` + `powerRequired` on the parts catalog** | Defined in `Config/Parts.luau:34-35`, set on **no row**, unchecked by `validate()`. Without them there is no slowed carrier for the boss to outrun, and no detach gate |

### 🔴 Two measurements that change the build

| | |
|---|---|
| **The kit is at half the world's scale** | `KitSpec.TILE` 8 / `WALL_H` 12 against the built Workshop's **15.8 / 24**. Building the corridor from `ServerStorage.Kit` yields a **half-height tunnel butted onto a 24-stud wall**. Use the **DemoRoom patterns at `SOURCE_SCALE = 0.5`** |
| **Streaming at the door** | **3,523 BaseParts within 500 studs** of the doorway against `MAX_PARTS_IN_VIEW` **1800** — **196 % of budget before floor 1 exists**, with 1,228 parts loose in a Folder streaming individually and 178 lights. 0021 asked for this measurement; here it is, and it is bad |

### 🔴 THE LOCKDOWN — the owner's own words

> *"i think we need global timer, like steal an egg, doors start closing from farthest bay, and each
> player still inside it dies. Rooms starts playing alarm, red colors and sounds, and you have limited
> time to run"*

So: a **server-wide** timer, not per-room. When it fires:

1. The rooms go into **alarm** — red light, sound, beacons.
2. **Doors begin closing, starting from the farthest bay.**
3. Players get **limited time to run** out toward the Workshop.
4. **Anyone still inside dies.**
5. Doors shut → the rooms **reset** (scrap, item, boss).

This is excellent pressure and it reuses vocabulary the project already has: `Prop_Beacon` exists,
and the style skill's VFX table already specifies *"Salvage Breach: rotating amber beacons enable
across the zone, red edge vignette"*.

### ✅ SETTLED: the Lockdown REPLACES the Factory Cycle — [decision 0020](../../docs/decisions/0020-the-lockdown-replaces-the-factory-cycle.md)

| Question | Decision |
|---|---|
| Lockdown vs the ~4 min Factory Cycle | **The Lockdown replaces it.** Lethal for everyone in the room, not only carriers |
| Closing direction | **A wave from the deepest room toward the Workshop**, herding players ahead of it. Visible and outrunnable |
| Death costs | **The carried item only.** Respawn at the Workshop; swept scrap survives |
| Boss speed | **Slower than a free player, faster than one carrying.** §22's cargo penalty is the whole tension |

0006's **scrap refresh** (30–60 s) and **Factory Shift** (~12 min) are untouched. Only the middle
cycle changed.

⚠️ **The cost was stated before this was chosen and it is real:** sweeping is ~55 % of playtime and
must stay relaxing, and the vision calls it "the ASMR layer". *(⚠️ Attribution corrected: this is
`docs/game/core-loop.md:70`, explicitly labelled **"derived — a target to test against, not a spec
value"** — NOT spec §84, which is MVP Success Criteria. The misattribution was copied into accepted
decision [0020](../../docs/decisions/0020-the-lockdown-replaces-the-factory-cycle.md) and should be
fixed there too.)* A lethal global timer puts
a clock on all of it. Decision 0020 records this as the first thing to watch in playtest and the first
thing to reverse if pottering about stops being pleasant.

⚠️ It also means **two threats with two different rules**: the *boss* only wakes if you steal
(decision 0014 holds), the *room* kills anyone. The UI has to make that distinction legible or it will
read as inconsistent.

### The original conflict, for the record

[Decision 0006](../../docs/decisions/0006-the-factory-refreshes.md) already defines a ~4-minute
**Factory Cycle** with a **20-second warning** — and it is explicitly **non-lethal**:

> *"The warning creates a real decision, but **not** about a part you are already holding … Anything
> already carried is safe from the timer."*
> *"Only unclaimed parts retract. Nothing already carried is taken by the timer."*

The lockdown kills the player and takes everything. Those are different mechanics. Three ways out, and
the project skill forbids silently overturning 0006:

- **(a) The lockdown REPLACES the Factory Cycle.** Write a new decision superseding 0006's cycle
  clause. The refresh becomes lethal; the game gets a "steal an egg" heartbeat.
- **(b) They are two separate things.** Factory Cycle (~4 min, re-rolls unclaimed parts, harmless) AND
  a rarer Lockdown (lethal, clears the floor). Two timers to learn — richer, or noise.
- **(c) The lockdown IS the Factory Cycle, made lethal only for players carrying an unsecured item.**
  Sweepers are never threatened, which keeps decision 0014's promise that *"a player carrying nothing
  is never threatened"* and §84's "sweeping is 55 % of playtime and must stay relaxing".

⚠️ **The remote already exists and is unbound.** `FactoryCycleWarning` is declared in `Remotes.SPECS`
— *"20-second warning. Must be audible and visible zone-wide, including while running"* — and
`cycle.force` is a declared-but-unregistered dev command. Whichever option wins, that is where it
lands.

### ⚠️ "Doors close from the farthest bay" reads two opposite ways

- **A closing wave that sweeps players home.** The deepest door shuts first and the closure travels
  toward the Workshop, herding everyone ahead of it. Deep players get the most warning; the wave is
  visible and fair.
- **The far door shuts first and seals deep players in.** The deeper you were, the more likely you
  die.

These produce opposite feelings and opposite code. Needs one sentence from the owner.

⚠️ Zone 1 is the **nearest** room to the Workshop, so under either reading its players are the safest.
The lockdown will barely bite in floor 1 — it becomes real at zones 4+. Build it now anyway, because
retrofitting a lethal global timer into twelve rooms later is worse.

## 🔴 The concept art — `Zone_1_ideas.png` and `Zone_1_ideas_2.png`

Two sheets, added by the owner 2026-09-06, both titled **"ZONE 1 — COLOR WORKSHOP · Small Parts. Big
Possibilities!"**. Sheet 2 is the same room, more open and more legible; sheet 1 is denser and has
more machinery.

⚠️ **Mockups are direction, not spec** (workspace memory). These set layout, mood and the *kind* of
object. Do not build a mechanic because it appears in a painting.

### The layout they agree on

Both sheets read the same way, and it is a **diagonal**:

```
                                    [ TO NEXT AREA ]  ->  exit ramp, blue chevrons
                                   /
        [ RARE PART: WORK LAMP (HEAD) ]  on a raised, lit plinth
                    |                      + a banner naming it
                    |                        "Shines a brighter path!"
                    |                                    [ SCRAP SWEEPER BOT ]
        green floor chevrons  - - - - ->                  red danger glow on the floor
                    |                                     between you and the exit
   [ FROM BASE RUN LANE ]  ->  entry, green chevrons
```

- **Entry: bottom-left**, a marked lane painted **FROM BASE RUN LANE** with green chevron arrows.
- **Exit: top-right**, a railed ramp under a blue **TO NEXT AREA** sign with blue chevrons.
- **The item: top-centre**, raised on a gold plinth, lit, with a banner naming the part.
- **The boss: right side**, standing between the player and the exit, with a **red glowing danger
  radius painted on the floor** around it and a floating **"! SCRAP SWEEPER BOT"** tag.
- **Green chevron arrows painted across the floor** the whole way, entry to exit. Wayfinding is
  *painted*, not a UI arrow.

~~🔴 **The boss guards the ROUTE as well as the item.**~~ ✅ **SETTLED, and the art is overruled.** The
owner: *"Boss is always somewhere in the middle and guards item, so he is in the middle."* It guards
the **item**, not either door. Both sheets post it at the far exit, which under "safety is back
through the entry doors" would be guarding a door nobody escapes through.

### The objects the art specifies

| Group | What is in the sheets |
|---|---|
| **Conveyors** | dark belts in yellow/blue frames, carrying scrap, several runs |
| **Magnet set piece** | a yellow robot arm with a blue magnetic pulse, lifting scrap in a swirl (top-left, both sheets) |
| **Paint machine** | vertical red/orange/green/blue tubes — the "COLOR" of Color Workshop |
| **Crates** | open-top, green / orange / blue, piled with scrap |
| **Scrap loose on the floor** | nuts, bolts, screws, springs, gears, washers, hex nuts — some arcing with blue electricity |
| **Pipes** | blue and green runs along walls and floor edges |
| **Safety kit** | yellow/black hazard edging, yellow tubular guard rails, orange traffic cones |
| **Lighting** | warm amber wall lamps + cyan strip lights |
| **The item plinth** | raised, gold, spot-lit, with a hanging banner |
| **Floor decals** | green chevrons, a large **SMALL PARTS BIG ADVENTURES** floor logo |

### The signage voice — a real content list

The sheets are covered in wall signs, and they carry the game's tone. Verbatim:

`SORT COLLECT UPGRADE — KEEP GOING!` · `MAGNETS TURN SCRAP INTO PROGRESS` ·
`SAME SCRAP DIFFERENT FUTURE` · `COLOR MAKES THINGS STRONGER!` · `GOOD PARTS BRIGHTER BUILDS` ·
`SCRAP MAKES A BRIGHTER WORLD!` · `COLLECT PULL UPGRADE REPEAT!` · `TURN SCRAP INTO PROGRESS` ·
`MAGNETS MAKE THINGS HAPPEN` · `SMALL PARTS BIG ADVENTURES`

These are cheap to build (the signage kit exists) and they are most of what makes the room feel
authored rather than generated.

### ⚠️ One conflict with the style skill, unresolved

The art's palette is the **structural** one — hazard yellow, chrome, factory dark, plus green/orange/
blue crates. The `magnet-sweep-style` skill assigns tier 1 the accents **candy pink `#FF6FB5` · mint
`#7FE6C4` · lemon `#FFE066`**, "bright, even, toy-like", and says a zone accent is what lets a player
name the zone from the light alone.

✅ **CHOSEN — the art's structure, pink/mint/lemon as the accents.** (This paragraph previously read
*"Neither has been chosen"* while two other sections called it decided. Stale text in an authoritative
document, found by the adversarial audit.)

🔴 **And a sharper conflict the original text missed entirely: the art uses RESERVED SIGNAL COLOURS.**
`#FFC21A` gold is *Legendary / Arena control* and `#3FD64B` green is *Recycle / the Uncommon outline*
(`magnet-sweep-style` §2, mirrored in `Ui/Theme.luau:44-67`). The sheets order a **gold plinth**,
**green floor chevrons** and **green/orange/blue crates** — and `Zone1Spec.luau:117-121` already warns
about the gold case in almost these words.

✅ **DECIDED: the signal colours win.** The plinth and chevrons take the tier-1 accents; the crates lose
green and orange. The art's *composition* survives; its palette does not.

⚠️ The art also names the rare part as **`WORK_LAMP` (Head)**, which is a **Common** in the catalog,
not a rare. `MAGNET_COIL` (Rare) and `GOLDEN_GEAR` (Legendary) are tier 1's actual prizes. Either the
banner is illustrative or the roll table needs saying out loud.

---

## 🔴 Read this first — what actually exists today

All measured over MCP on 2026-09-06, not assumed.

| | |
|---|--:|
| `Workspace.Zones` | **does not exist** — no zone is built, at all |
| The doorway | 🔴 **CORRECTED 2026-09-06** — the frame's *bounding box* is 62 × 24 at z 31, but `Infill` (20 × 24, `CanCollide`) fills a third of it. The **real clear opening is 42 wide, centred z = 41, head height 22**, and `Config/WorkshopLayout.luau:194` already said so (`alongFacet = 41`). See [0021](../../docs/decisions/0021-you-walk-in-nobody-teleports.md) |
| The fixture in it | `Hub.Common.Fixtures.FACTORY_ENTRANCE` at (1790, 10, 41), 38 × 21 × 7 — 🔴 **it is a CLOSED, `CanCollide` MeshPart with a `SurfaceAppearance`.** 32 of 36 character-box slots across the door plane are blocked. Making it open is a build task, and a script cannot re-skin a replacement |
| Pressing ENTER today | server replies **`zone tier 1 is not built yet`** |
| Zone 1 Magnet Power gate | **10** · zone 2 is **20** |
| Scrap pool | already primed with **400** parts |

🔴 **CORRECTED 2026-09-06 — "a door frame with nothing behind it" is wrong in both halves.** The
frame holds a **closed, collidable door**, and outward of it there is **no floor at all**: rays at
x = 1795 / 1840 / 1900 all return VOID, over a 2,000-stud drop. Job 021's `Backdrop.L1_F00` collar
sits across the path 20 studs out, at y up to 48.

So this job's first three tasks are **make the door open**, **make a floor exist**, and **cut the
backdrop** — before any room is designed.

⚠️ **`Zone1Spec.luau` already exists** and describes a generated 9 × 21-tile corridor at
`ORIGIN (0, 0, -200)`. It is **not being built** — `Bootstrap.BUILD_GENERATED_WORLD = false`, because
the world moved to hand-placed. Do not resurrect the generator without deciding to; do not delete it
without deciding either. **Its numbers are still a useful starting point and its ORIGIN is now wrong**
(the Workshop moved to x≈1556 in job 020; the door is at x 1790).

## 🔴 The conflict this job has to resolve first

`ZoneManager.sendTo` **teleports** the player: `char:PivotTo(...)` onto a registered zone's entry
point. That is a hub-and-spoke move wearing a corridor's clothes.

The owner's description — one corridor, doors between zones — is
[decision 0003](../../docs/decisions/0003-forward-is-the-only-direction.md) as written:

> *"The factory is **one physically continuous corridor**, zone 1 through zone 12 … There is no
> zone-select menu. You reach zone 5 by walking through zones 1 to 4."*

If floor 1 is physically continuous with the Workshop, **the teleport goes away** and the corridor
starts at the wall aperture at (1790, 12, 31) and runs outward from there. That is a change to a
shipped system, and it should be made deliberately rather than discovered halfway through building a
room.

## ✅ ANSWERED — the decision this job was really about

**When do the doors open, when do they close, and what does "reset" mean?**

🔴 **This section is kept for its reasoning, but the question is SETTLED** — see **✅ DECIDED** above
and **[decision 0020](../../docs/decisions/0020-the-lockdown-replaces-the-factory-cycle.md)**. A
lethal global Lockdown: alarm, doors closing as a wave from the deepest room toward the Workshop,
anyone still inside dies, rooms reset. Questions 1-3 and 5 below are answered by 0020; **question 4
(shared vs per-player) is answered by "shared room, one item, first grab wins."**

The analysis that produced it:

This was new. Nothing in `docs/` described a room that resets on a door closing, and it **interacted
with an accepted decision**:

[Decision 0006 — the factory refreshes](../../docs/decisions/0006-the-factory-refreshes.md) says
scrap repopulates every **30–60 s**, Robot Parts re-roll every **~4 min**, and a server-wide Shift
re-weights the pools every **~12 min** — a *continuous ambient* model, deliberately chosen so that
*"the spoon is always here"* never becomes true.

A room that **resets when its doors close** is a *run/instance* model instead. The two are not
automatically compatible. Questions the plan must answer, not assume:

1. **What opens the doors?** Magnet Power alone (§61's "pull the locking mechanism")? Entering? A
   button? Something the boss drops?
2. **What closes them?** A timer? Taking the item? The boss waking? The player leaving? Death?
3. **What does "reset" actually reset?** Scrap only? Scrap + item + boss? Does the boss heal? Does an
   item you already grabbed but did not secure vanish — and how does that square with
   [decision 0008](../../docs/decisions/0008-secured-at-the-hub-not-in-hand.md), *"a rare part in hand
   is not owned"*?
4. **Is the room per-player or shared?** MAGNET SWEEP is **one place, one server, shared** (decision
   0001). If floor 1 resets, it resets *for everyone in it* — which means one player's reset can
   delete another player's run. This is the single biggest unknown and it is a design question, not
   an implementation detail.
5. **Does resetting replace decision 0006, or sit alongside it?** If it replaces it, that needs a new
   decision record superseding 0006 — the project skill forbids silently overturning one.

## What is already decided and must not be re-litigated

| Source | What it fixes |
|---|---|
| [0003](../../docs/decisions/0003-forward-is-the-only-direction.md) | One continuous corridor · physical gates, no Unlock button · no zone menu |
| [0014](../../docs/decisions/0014-the-owning-guardian-chases.md) | Guardians are **inert until you steal**. A player carrying nothing is never threatened |
| [0008](../../docs/decisions/0008-secured-at-the-hub-not-in-hand.md) | Ownership transfers at the Service Hub SECURED moment, nowhere else |
| [0001](../../docs/decisions/0001-one-place-not-two.md) | One place, shared server — see question 4 above |
| `docs/systems/factory` | Zone 1 gate **10**, zone 2 **20** · Service Hubs after zones 2, 4, 6, 8, 10, 12 |
| `docs/content/zones/README.md` | Tier 1 = *"Cyan / pink / yellow. Small conveyors. Paint machines. Bright toy-like machinery."* Guardian = **Slow Scrap Sweeper Bot** |
| `magnet-sweep-style` §2 | Tier 1 accents: candy pink `#FF6FB5` · mint `#7FE6C4` · lemon `#FFE066`; light "bright, even, toy-like" |

**Tier 1 scrap** (spec): screws, nuts, washers, bolts, gears, springs, metal beads, small pipes.

**Tier 1 parts** — the "item" rolls from these 8, all of which already have mesh + mount bindings in
`Config/PartArt`, so any of them can be built onto a robot **today**:

| Part | Slot | Rarity |
|---|---|---|
| `WORK_LAMP` · `MINI_MOTOR` · `PAINT_DRUM` | Head / Core / Body | Common |
| `PIPE_WRENCH` · `SPRING_PUNCHER` · `CASTER_WHEELS` | Arm / Arm / Mobility | Uncommon |
| **`MAGNET_COIL`** | Back | **Rare** |
| **`GOLDEN_GEAR`** | Head | **Legendary** |

## 🔴 Scope question: can the item actually be taken?

**No — not yet.** Measured: `RequestDetach` is **declared and unbound**, and `Guardian` and `Breach`
appear only in config, remote definitions and UI vocabulary.

🔴 **~~and `Cargo`~~ — FALSE, and it is good news.** `MagnetState.setCargo` is **implemented
server-side** (`MagnetState.luau:446-451`), and `MagnetState.luau:467` already does
`hum.WalkSpeed = Magnet.carrySpeed(drive, e.cargo)`. **The carry-speed penalty is built and waiting
for a caller** — which is most of what decision 0020's *"boss slower than a free player, faster than a
carrying one"* needs. ⚠️ What it still lacks is the *data*: no row in `PartsCatalog.ALL` sets `weight`
(or `powerRequired`), and `validate()` does not check, so the gap is silent at boot. `ServiceHub` appears in **zero**
files. That whole layer is build group 08.

So this job must choose:

- **(a) Room only** — build floor 1, its doors and its reset; the item and boss are present and
  correct but not yet takeable. Group 08 makes them live.
- **(b) Room + a minimal steal** — also bind `RequestDetach` so the item can be ripped free and the
  boss wakes, without the full breach/hub/extraction chain.

⚠️ Until one of these lands, **`part.grant` is the only way a part enters an inventory**. The Robot
Bay (job 022) works and has no supply.

## 🔴 What we can reuse — this is an assembly job, not an art job

Probed in Studio 2026-09-06. Almost everything the concept sheets show already exists.

### The tier-1 scrap is already modelled — all eight of it

The spec's tier 1 scrap list is *"screws, nuts, washers, bolts, gears, springs, metal beads, small
pipes"*. `ServerStorage.ImportedMeshes` (55 meshes) contains **`screw`, `nut`, `washer`, `bolt`,
`gear`, `spring`, `bead`, `pipe`** — a complete match, nothing to generate.

### The set dressing exists as kit

| The art shows | We already have |
|---|---|
| conveyor runs | `Ind_Conveyor`, `Floor_Conveyor`, mesh `belt_section` |
| the yellow magnet arm set piece | **`Prop_RobotArm`** |
| open crates piled with scrap | **`Prop_Crate`** |
| pipe runs along the walls | `Ind_PipeRun`, meshes `pipe`, `pipes` |
| orange beacons / cones | `Prop_Beacon` |
| the doors to the next area | **`Struct_Gate`** |
| the exit ramp | `Struct_Ramp` |
| neon wall signs | `Sign_NeonSlab` |
| warm lamp gantries | `Light_Gantry` |
| hazard floor edging | `Floor_Hazard`, `Floor_Grated`, `Floor_Plain` |
| machine faces / control panels | `Wall_Machine`, `Ind_ControlPanel`, `Station_Machine` |
| tanks, fans, generators | `Ind_Tank`, `Ind_Fan`, `Ind_Generator` |

Plus **approved patterns already staged in `DemoRoom`**: `1_FloorPatterns` (162 parts),
`2_WallPatterns` (116 — the four approved wall types A window bays / B tool-board / C bar wall /
D hazard plate), `3_Objects` (78), `4_Scrap` (129).

### What does NOT exist and has to be made

| Missing | Note |
|---|---|
| 🔴 **The Scrap Sweeper Bot** | no mesh, no rig, no AI. The boss is the single biggest new thing in this job |
| The item plinth | the raised, lit, bannered pedestal from the art — buildable from kit |
| The paint machine | the coloured vertical tubes ("COLOR MAKES THINGS STRONGER!") — buildable from kit |
| Floor chevron decals + the `SMALL PARTS BIG ADVENTURES` floor logo | textures/decals, not geometry |

⚠️ **Search the market before generating anything** (standing ground rule). A sweeper/roomba-style bot
is a common asset; check the Creator Store before spending Meshy credits. Meshy balance is **1,593**.

## 🔴 WHAT GOES INTO ROOM 1 — the list

> *"each level will have tiers, and this is room one with low tier scraps. So I think we need to
> settle what goes into room, we need list"*

Room 1 is **tier 1**. Everything below is either already built or explicitly marked as new.

### A. The scrap — all 8 tier-1 types, already specced and modelled

`ScrapSpec.TIER1`. Weights and values are the shipped gameplay ladder; `share` is spawn frequency
within the tier and sums to 100.

| id | name | weight | value | share | surface | sound | mesh |
|---|---|--:|--:|--:|---|---|---|
| `SCREW` | Screw | 2 | 1 | 26 % | SteelBrushed | Bolt | `screw` |
| `NUT` | Nut | 3 | 1 | 22 % | SteelBrushed | Bolt | `nut` |
| `WASHER` | Washer | 2 | 1 | 18 % | Chrome | Coin | `washer` |
| `BOLT` | Bolt | 4 | 2 | 16 % | SteelBrushed | Bolt | `bolt` |
| `GEAR` | Gear | 6 | 3 | 9 % | SteelDark | Gear | `gear` |
| `SPRING` | Spring | 5 | 3 | 5 % | Chrome | Spring | `spring` |
| `BEAD` | Metal Bead | 1 | 1 | 3 % | Chrome | Coin | `bead` |
| `PIPE` | Small Pipe | **12** | 5 | 1 % | Rust | Tool | `pipe` |

🔴 **`PIPE` weighs 12 against a starter Magnet Power of 10.** It is deliberately **the first thing in
the game you can see and visibly cannot lift**. That is a teaching object, so the room must place a few
of them **early and in plain sight** — not tucked in a corner. It is also why the tier-2 room escalates
to `TOY_ROBOT` at weight 26.

⚠️ `PIPE` is **chunky, not long** (≈1:1:1). Place several short sections rather than one long pipe —
owner's call, 2026-09-05.

### B. The item — one of tier 1's 8 parts, re-rolled

All eight already have mesh + mount bindings in `Config/PartArt`, so **any of them can be installed on
a robot today** (job 022).

| Part | Slot | Rarity |
|---|---|---|
| `WORK_LAMP` | Head | Common |
| `MINI_MOTOR` | Core | Common |
| `PAINT_DRUM` | Body | Common |
| `PIPE_WRENCH` | Arm | Uncommon |
| `SPRING_PUNCHER` | Arm | Uncommon |
| `CASTER_WHEELS` | Mobility | Uncommon |
| **`MAGNET_COIL`** | Back | **Rare** |
| **`GOLDEN_GEAR`** | Head | **Legendary** |

⚠️ The concept banner reads **`WORK_LAMP`**, a Common. Fine as the *typical* roll.

🔴 **~~the roll table and its rarity weights still need writing down~~ — FALSE, one already shipped.**
`Zones.RARITY_WEIGHT` (`Config/Zones.luau:122-129`) has been there all along: Common 100 / Uncommon 55
/ Rare 22 / Epic 7 / Legendary 2, which normalises across tier 1 to ≈ **61 / 34 / 4.5 / 0.4** — about
**half** the intended Rare rate and **a fifth** of the Legendary. [Decision 0025](../../docs/decisions/0025-one-plinth-one-item.md)
settles it at **60/30/8/2** and requires the shipped table to be **deleted or repointed**, because two
rarity tables in two files is PITFALLS #38/#52 by construction.

### C. The boss — 🆕 ALL NEW

**Scrap Sweeper Bot.** No mesh, no rig, no AI, nothing. This is the largest new item in the job.
Needs: a model, a sit/idle state, a wake trigger, a chase, a "catches you" test, and a kill.
**Search the Creator Store first** — a round sweeper/roomba shape is common. Meshy balance **1,593**.

### D. Structure — from the kit

| Need | Piece |
|---|---|
| Floors | `Floor_Plain`, `Floor_Hazard`, `Floor_Grated`, `Floor_Conveyor` |
| Near walls | `Wall_Machine`, `Wall_Pipes`, `Wall_Solid`, `Wall_Window` + the 4 approved `DemoRoom.2_WallPatterns` |
| Far walls + roof | the job 021 layering recipe (see requirement 2 above) |
| The doors | **`Struct_Gate`** |
| The exit ramp | `Struct_Ramp` |
| Bends, levels | `Struct_Corner`, `Struct_Pillar`, `Struct_Platform`, `Struct_Bridge` |

### E. Machinery and set dressing — from the kit

`Ind_Conveyor` + mesh `belt_section` · **`Prop_RobotArm`** (the yellow magnet arm from both sheets) ·
**`Prop_Crate`** ×N piled with scrap · `Ind_Tank` · `Ind_Fan` · `Ind_Generator` · `Ind_ControlPanel` ·
`Ind_PipeRun` + meshes `pipe`/`pipes` · **`Prop_Beacon`** · `Light_Gantry` · `Sign_NeonSlab`

🔴 **`Prop_Beacon` is now load-bearing, not decoration** — the lockdown needs rotating amber beacons,
which is already the style skill's specified Salvage Breach vocabulary.

### F. Signage — the 10 slogans from the sheets

`SORT COLLECT UPGRADE — KEEP GOING!` · `MAGNETS TURN SCRAP INTO PROGRESS` ·
`SAME SCRAP DIFFERENT FUTURE` · `COLOR MAKES THINGS STRONGER!` · `GOOD PARTS BRIGHTER BUILDS` ·
`SCRAP MAKES A BRIGHTER WORLD!` · `COLLECT PULL UPGRADE REPEAT!` · `TURN SCRAP INTO PROGRESS` ·
`MAGNETS MAKE THINGS HAPPEN` · `SMALL PARTS BIG ADVENTURES`

### G. 🆕 New builds

| | Note |
|---|---|
| **Scrap Sweeper Bot** | see C — the big one |
| **The item plinth** | raised, gold, spot-lit, hanging banner naming the part. Kit-buildable |
| **The paint machine** | vertical coloured tubes — this is where pink/mint/lemon lands hardest |
| **Floor decals** | green chevrons · `FROM BASE RUN LANE` · `TO NEXT AREA` · the `SMALL PARTS BIG ADVENTURES` floor logo |
| **The alarm state** | red light, siren, beacons spinning, closing doors, a countdown the player can read |

### H. Colour, per the decision above

Structure stays industrial (hazard yellow, chrome, factory dark). **Accents — candy pink `#FF6FB5`,
mint `#7FE6C4`, lemon `#FFE066` — go on the paint machines, the machine panels, the item plinth and the
light gels.** Light is "bright, even, toy-like".

⚠️ Zone accents may **never** colour a Recycler, a repair effect, a magnet, an alarm or a rarity
outline — those are signal colours and they *mean* something. The lockdown alarm is **`#E03A2F`
signal red**, not a zone accent.

## Traps this job will walk into

Every one of these has already cost this project time.

1. **`Workspace` does not sync.** A hand-placed room lives only in the unversioned `.rbxl` unless it
   is exported — [decision 0019](../../docs/decisions/0019-hero-geometry-is-editor-placed-and-exported.md).
   Job 021 paid this off with `WorkshopLayout.BACKDROP`; floor 1 needs the same.
2. **Build in the editor with real assets**, not kit primitives from a spec — the owner's standing
   rule, and why `BUILD_GENERATED_WORLD` is off. Stage new objects in `DemoRoom` for approval before
   they enter the world.
3. **Streaming.** `StreamingEnabled` is ON. Zones must be self-contained chunks and **no script may
   hold a hardcoded instance path into another zone** (decision 0003's own rule) — under streaming
   that is a nil-index crash, not a smell.
4. **Heavy `execute_luau` crashes Studio.** One folder per call; check what survived before re-running.
5. **No visible map edges** (workspace memory) — a corridor needs its far end closed, not a fall-off.
6. **Coplanar faces are the glitchy floor** — two same-facing surfaces at one height; separate by 0.06.
7. **Verify in Play at eye level.** The editor is never evidence.
8. **The room is already at 3,595 parts** against `MAX_PARTS_IN_VIEW` 1800. Floor 1 adds to what
   streams. Performance has still never been measured on a device.

## ▶️ RESUME HERE (written 2026-09-06, end of session)

**State: intake only. Nothing has been built. No code written for this job. No world geometry
placed.**

### What is done

- This intake, complete: the owner's five requirements, both concept sheets read, the zone loop, the
  contents list, the reuse inventory, the traps.
- **[Decision 0020](../../docs/decisions/0020-the-lockdown-replaces-the-factory-cycle.md)** written —
  the Lockdown replaces 0006's Factory Cycle and is lethal. `docs/decisions/INDEX.md` updated and
  0006 flagged as partially superseded.
- Nine design questions answered by the owner via the wizard (all recorded above under
  **✅ DECIDED** and **✅ SETTLED**).

### ✅ The five open questions — ANSWERED 2026-09-06

All five, plus two the intake had not thought to ask (item respawn cadence; where a tier-1 part
becomes owned). The answers are the **✅ DECIDED — round 2** table above. In short:

| | |
|---|---|
| 1. Teleport vs walk | **Walk.** Floor 1 attaches to the aperture at (1790, 12, 31); `sendTo`'s `PivotTo` retires |
| 2. Scope | **Room + steal + boss chase.** Lockdown → job 024 |
| 3. The 5-second grab | **Moving cancels, restarts from zero; the plinth locks to the first channeller** |
| 4. "Catches you" | **Radius ~6 studs + ~0.5 s dwell**, server-side |
| 5. Roll table | **60 / 30 / 8 / 2** across Common / Uncommon / Rare / Legendary |
| 🆕 6. Item respawn | **30–60 s cooldown** |
| 🆕 7. Where a part becomes owned | **The Workshop entry doors — hub 0** |

### 🔴 What is now blocking, in order

1. ~~Two decision records to write~~ ✅ **WRITTEN 2026-09-06**, both indexed:
   - **[0021 — you walk in, nothing teleports you](../../docs/decisions/0021-you-walk-in-nobody-teleports.md)**.
     🔴 It carries a trap the plan must act on: **the teleport is currently the only thing enforcing
     the Magnet Power gate** (`sendTo` checks `MagnetState.stats().Power` against `Config/Zones.gate`).
     Removing the `PivotTo` without moving that check to the door leaves the gate as decoration.
   - **[0022 — the Workshop is hub 0](../../docs/decisions/0022-the-workshop-is-hub-zero.md)**, amending
     0008. 🔴 Its trap: **the chase ending and the `SECURED` transfer are one event or neither** —
     ship the boss without the secure and the job has shipped a way to lose parts.
2. **The independent reviewer agent**, given the requirement and never my reading of it
   (GROUND-RULES §8). Job 021's reviewer overturned that intake in six places.
3. **Source the Scrap Sweeper Bot** — Creator Store before Meshy credits (balance 1,593).
4. `implementation-plan.md`.

### Then, in order

- Run an **independent reviewer agent** against this intake — given the requirement, never my reading
  of it (GROUND-RULES §8). Job 021's reviewer overturned that intake in six places and saved the job.
- Write `implementation-plan.md`.
- **Search the Creator Store for the Scrap Sweeper Bot before spending Meshy credits** (balance
  **1,593**). It is the single biggest new asset in the job.
- Stage every new object in `DemoRoom` for the owner's approval before it enters the world.

### Context a fresh session will not otherwise have

- **Where the game logic actually stands:** loop layers 1 (sweep) and 4 (build the robot) work.
  ⚠️ **Layer 2 (zone 1 gate) does NOT** — an earlier draft of this line claimed it did, while
  `:354` of this same document records that pressing ENTER returns *"zone tier 1 is not built yet"*
  every single time. The **gate check** works; the layer does not. Layer **3 (extract)** and layer
  **5 (Arena)** do not exist either. The boot log's
  `4 client-facing remotes have no handler yet: RequestDetach, RequestReleaseRobot, RequestRenameRobot,
  RequestWithdrawRobot` is the precise measure. **Floor 1 is what closes the loop.**
- **Job 022 shipped the Robot Bay and it has no supply** — `part.grant` is a dev command standing in
  for the Service Hub SECURED moment. That is the gap this job fills.
- `Workspace.Zones` **does not exist**. `Bootstrap.BUILD_GENERATED_WORLD = false`. Zone1Spec is data
  for a room nobody builds, and its `ORIGIN (0,0,-200)` predates the Workshop moving to x≈1556.
- The doorway is real: `Hub.Room.Wall.F00_GATE_FRAME` at **(1790, 12, 31)**, 62 × 24 × 8.

## Checklist

- [x] Requirements reviewed (this intake) — and **corrected in 7 places** by an adversarial audit
- [x] Owner's design direction captured — five requirements + two concept sheets
- [x] **The door/reset rules decided** — a lethal global lockdown timer (see above)
- [x] 🔴 **Lockdown vs decision 0006 settled** — it replaces it; [decision 0020](../../docs/decisions/0020-the-lockdown-replaces-the-factory-cycle.md) written
- [x] 🔴 **Door closing direction clarified** — a wave that herds players home
- [x] **Teleport-vs-walk resolved** — the player **walks**; [0021](../../docs/decisions/0021-you-walk-in-nobody-teleports.md) written
- [x] **Palette resolved** — art's structure, pink/mint/lemon as accents
- [x] **Roll table + rarity weights** — Common 60 / Uncommon 30 / Rare 8 / Legendary 2
- [x] **Contents list settled** — see "WHAT GOES INTO ROOM 1"
- [x] **Boss speed + death cost decided** — slower than a free player, faster than a carrying one;
      death costs the carried item only
- [ ] **Boss position** — decided: **mid-room, guarding the item**; the plinth's placement relative to it is a level-design call for the plan
- [ ] **Item respawn** — decided: **30–60 s cooldown**; ⚠️ with the Lockdown deferred, floor 1 ships with **no reset pressure**
- [x] **"Catches you" defined** — server-side radius ~6 studs with a ~0.5 s dwell, not `Touched`
- [x] **"Outside the area" defined** — back through the entry doors into the Workshop
- [x] Squared with decision 0008 **in writing** — [0022](../../docs/decisions/0022-the-workshop-is-hub-zero.md), the Workshop is **hub 0**
- [x] **The 5-second channel specified** — moving cancels and resets it; the plinth locks to the first channeller
- [x] Scope chosen — **room + steal + boss chase**; the Lockdown moves to **job 024**
- [x] **Independent reviewer agents run** — TWO, with opposed lenses (GROUND-RULES §8): one never shown
      this intake, one told to attack it. They converged on five collisions independently
- [x] **Decision records written** — [0021](../../docs/decisions/0021-you-walk-in-nobody-teleports.md)
      walk-not-teleport · [0022](../../docs/decisions/0022-the-workshop-is-hub-zero.md) hub 0 ·
      [0023](../../docs/decisions/0023-the-room-is-placed-the-contents-are-spawned.md) placed vs spawned ·
      [0024](../../docs/decisions/0024-the-guardian-kills.md) the guardian kills ·
      [0025](../../docs/decisions/0025-one-plinth-one-item.md) one plinth
- [x] **Boss sourced — the market is EMPTY.** Five Creator Store searches (sweeper robot / roomba /
      security robot / cleaning drone / own inventory) returned nothing usable; relevance collapses
      after ~2 hits in every query. **Meshy it is** — approved at meshy-6 + refine, 30 credits
- [ ] 🔴 **The exporter written and round-tripped** — 0023's step zero
- [ ] 🔴 **Zone registration path for a placed room** — else the guardian and SECURED both no-op
- [ ] 🔴 **`weight` + `powerRequired` authored** for the 8 tier-1 parts
- [ ] 🔴 **The door made to open**, a floor made to exist, the backdrop cut
- [ ] **Docs updated to match the new records** — `docs/systems/guardians`, `docs/build/08-cargo-and-escape.md`,
      `docs/systems/factory`, `Config/Zones` (`SPAWN_PER_CYCLE`, `RARITY_WEIGHT`, `CYCLE_*`)
- [x] Implementation plan created — [implementation-plan.md](implementation-plan.md) · ⚠️ **not yet agreed**
- [ ] New objects staged in `DemoRoom` for approval before they enter the world
- [ ] Implementation completed
- [ ] **Proof it works** captured in Play, at the player's camera — including a sky/enclosure
      measurement for requirement 2, the way job 021 measured 45.7 % -> 0.0 %
- [ ] Part count measured with floor 1 and the Workshop both loaded
- [ ] Exported per decision 0019 — `Workspace` does not sync
- [ ] Final summary + changelog written
