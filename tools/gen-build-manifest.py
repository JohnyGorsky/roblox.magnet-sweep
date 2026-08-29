# -*- coding: utf-8 -*-
"""Generate the MAGNET SWEEP build manifest. Item counts are COMPUTED from the item
lists, never asserted -- and an item written as 'xN' counts as N (PITFALLS #9)."""
from pathlib import Path
import re

ROOT = Path(r"c:/Dati/Work/roblox.magnet-sweep")
B = ROOT / "docs" / "build"
B.mkdir(parents=True, exist_ok=True)

# group = (slug, title, intro, [ (priority, text) ... ])
GROUPS = []

GROUPS.append(("01-foundation", "Foundation & sync", """
Nothing else can be trusted until this group is done. Every file every later group writes to disk
assumes the sync layout, and every balance number later groups tune assumes the config modules exist.
""", [
 ("P0", "Create the MAGNET SWEEP place; record its id in `docs/systems/places/README.md` and the project skill"),
 ("P0", "Decide place settings deliberately: access, social slots, `MaxPlayers` x3"),
 ("P0", "Enable and configure `StreamingEnabled` -- radius, behaviour, target radius"),
 ("P0", "**Probe the sync layout over MCP** -- flat vs nested, per service folder"),
 ("P0", "Probe which file suffix produces which class; specifically whether `.client.luau` in `StarterPlayerScripts` runs twice"),
 ("P0", "Rewrite `.jobconfig.json` with what was OBSERVED; clear the `UNVERIFIED` status"),
 ("P0", "Shared config module structure: `Config/Magnet`, `Config/Zones`, `Config/Parts`, `Config/Arena`, `Config/Economy`, `Config/Quality` x6"),
 ("P0", "Remote definitions module -- one place that names every RemoteEvent/Function"),
 ("P0", "Server-side rate limiter used by every remote"),
 ("P0", "Logging/telemetry helper with a level switch"),
 ("P0", "Dev/test configuration: forced Factory Shift, jump-to-zone, grant Magnet Power, spawn a named part x4"),
 ("P1", "`tools/luau-analyze.sh` equivalent for this repo, with ABSOLUTE paths"),
 ("P1", "Sourcemap / Rojo project file if the probe shows one is needed"),
]))

GROUPS.append(("02-industrial-kit", "The industrial kit & material system", """
70-80% of the world is built from this group (section 64). Build the kit before building any room.
The material variants are what make the concept art's gloss possible -- see the
[`magnet-sweep-style` skill](../../.claude/skills/magnet-sweep-style/SKILL.md).
""", [
 ("P0", "The nine `MaterialVariant`s: Chrome, SteelBrushed, SteelDark, PaintedGloss, PaintedWorn, HazardStripe, Rubber, Grate, Rust x9"),
 ("P0", "Source or generate the PBR texture set for each variant (colour/normal/metalness/roughness) x9"),
 ("P0", "Floor kit: plain, hazard, conveyor, grated x4"),
 ("P0", "Wall kit: solid, pipes, windows, machines x4"),
 ("P0", "Structure kit: pillar, corner, gate, bridge, ramp, platform x6"),
 ("P0", "Industrial kit: conveyor, generator, tank, pipe run, control panel, fan x6"),
 ("P0", "Neon slab sign component -- housing, chamfered bezel, Neon text panel, matching PointLight"),
 ("P0", "Hazard-stripe tiling that survives scaling"),
 ("P1", "Warning beacon (caged amber, rotating)"),
 ("P1", "Scrap crate props in red/blue/yellow x3"),
 ("P1", "Yellow robot arm prop with black joints, animatable"),
 ("P1", "Conveyor motion by texture offset (NOT physics)"),
 ("P2", "Kit placement tool for the Studio plugin/command bar"),
]))

GROUPS.append(("03-lighting-and-look", "Lighting, atmosphere & quality tiers", """
This is the group that makes the game look like the concept art. It is early because every subsequent
visual decision is judged against it.
""", [
 ("P0", "`LightingStyle = Realistic` (the successor to `Lighting.Technology = Future`; neither is script-writable, so this is set in Studio) + the ambient/brightness/exposure baseline"),
 ("P0", "`Atmosphere` configured -- density, haze, colour, decay, glare"),
 ("P0", "`Sky` -- the thing chrome actually reflects"),
 ("P0", "`EnvironmentSpecularScale` / `EnvironmentDiffuseScale` tuned against a chrome test object"),
 ("P0", "Post chain: BloomEffect, ColorCorrectionEffect, SunRaysEffect x3"),
 ("P0", "Quality tier detector -- measured frame time, NOT `TouchEnabled`"),
 ("P0", "Tier controller (client): post chain on/off, PBR vs Reflectance swap, light range cull, particle rate, `MaxConcurrentPull` x5"),
 ("P0", "Measure the three tiers in the Device Emulator and record the numbers"),
 ("P1", "`DepthOfFieldEffect` for the Robot Bay install cinematic only"),
 ("P1", "Shadow-casting light budget audit tool"),
 ("P2", "A lighting-preset module if zones need to differ (Power Plant vs Space Foundry)"),
]))

GROUPS.append(("04-magnet-core", "The magnet -- the whole game in one system", """
**This group is the gate.** If sweeping is not satisfying here, nothing downstream saves it. Build it
before there is a factory to sweep in -- one grey room and a pile of bolts is enough.
""", [
 ("P0", "Magnet tool/model attached to the character, red/cyan poles"),
 ("P0", "Four-state object machine: IDLE / REACT / PULL / COLLECTED"),
 ("P0", "Object pool -- allocate once, re-pose forever, **re-anchor on return**"),
 ("P0", "`MaxConcurrentPull` cap with a REACT waiting queue"),
 ("P0", "Client pull motion: slide, lift, rotate, accelerate, arc into the magnet"),
 ("P0", "Server collection grant, BATCHED on a tick -- never one remote per object"),
 ("P0", "Server validation: the object must be one the server spawned"),
 ("P0", "Magnet Power / Radius / Drive / Capacity stats, read from config x4"),
 ("P0", "Capacity fill + SCRAP FULL state"),
 ("P0", "Magnet Flow x1-x5 with decay"),
 ("P0", "MAGNET RUSH state"),
 ("P0", "Magnet VFX states: idle, pulling, high flow, rush, overcharge x5"),
 ("P0", "Sound families with Flow-driven pitch rise x9"),
 ("P1", "Magnet model upgrades -- a visibly different magnet per power tier"),
 ("P1", "Magnetic Drive speed applied to the character"),
 ("P2", "Magnet skins framework (cosmetic hook, no skins yet)"),
]))

GROUPS.append(("05-workshop", "The Workshop hub", """
The hub, and the proof of [decision 0001](../decisions/0001-one-place-not-two.md) -- the Arena has to be
visible and audible from here.
""", [
 ("P0", "Workshop layout: the seven stations, sightline to the Arena"),
 ("P0", "Neon signage for each station x7"),
 ("P0", "Magnet Lab -- upgrade terminal and its GUI"),
 ("P0", "Recycler -- scrap to Coins, with the repair alternative shown alongside"),
 ("P0", "Repair Station"),
 ("P0", "Robot Bay (the shell; assembly is group 09)"),
 ("P0", "Factory Entrance"),
 ("P0", "Spawn point and the first-time prompt (MOVE NEAR SCRAP)"),
 ("P1", "Part Archive wall"),
 ("P1", "Arena status display"),
 ("P1", "Distant Arena audio bed -- real spatial emitters, not a loop"),
 ("P2", "Shop kiosk"),
]))

GROUPS.append(("06-boot-and-hud", "Boot, loading & the main HUD", """
Build the loading screen early (section 7), not at the end. A loading screen retrofitted over a running
game fights every system it wraps.
""", [
 ("P0", "`ReplicatedFirst` handoff -- remove the default screen immediately"),
 ("P0", "Loading screen art: player, magnet, flying scrap, robot, corridor"),
 ("P0", "Progress driven by REAL stage completion, not a timer"),
 ("P0", "Object-per-tick loading sound, CLANG on complete"),
 ("P0", "Title card"),
 ("P0", "Main HUD: Coins, Flow, Scrap, upgrade button, robot/Arena widget x5"),
 ("P0", "Banner system (one line, all caps, short-lived)"),
 ("P0", "Mobile safe-area layout measured in the Device Emulator"),
 ("P0", "Number animation: count-up then scale punch"),
 ("P1", "Button sound + pressed state + scale tween, applied globally"),
 ("P1", "Failure paths: profile load failed, streaming slow, joined mid-Refresh x3"),
]))

GROUPS.append(("07-zones-1-2", "Zone 1, Zone 2 and the first Service Hub", """
The first real factory. Built from the group 02 kit; if a room needs a bespoke asset, the kit is wrong.
""", [
 ("P0", "Zone 1 Color Workshop -- layout, as a self-contained streamable chunk"),
 ("P0", "Zone 1 scrap set: screws, nuts, washers, bolts, gears, springs, beads, pipes x8"),
 ("P0", "Zone 2 Toy Assembly -- layout and chunk"),
 ("P0", "Zone 2 scrap set x5"),
 ("P0", "The zone 1->2 gate: physical pull mechanism, GRRRRR, pin, BOOM"),
 ("P0", "Gate requirement readout on the gate itself"),
 ("P0", "Service Hub after zone 2: Recycler, upgrade, repair, Secure station, checkpoint, Arena display, MagRail x7"),
 ("P0", "MagRail one-way return to the Workshop"),
 ("P0", "Zone manager -- zones talk to it, never to each other"),
 ("P0", "Return lane through zones 1-2, distinct from the outbound route"),
 ("P1", "Zone hazards: conveyor, closing door, crusher, electric floor, rotating arm x5"),
 ("P1", "Zone ambience per zone x2"),
]))

GROUPS.append(("08-cargo-and-escape", "Rare cargo, extraction & guardians", """
The 45 seconds the game is arranged around.
""", [
 ("P0", "Rare part as physical carried cargo -- floats, drags, swings, sparks"),
 ("P0", "One rare part carried at a time; separate from Capacity"),
 ("P0", "Weight classes and speed penalties, with a floor x4"),
 ("P0", "Detach sequence: shake, electricity, GRRRRR, CLANG"),
 ("P0", "Server-side Magnet Power detach check"),
 ("P0", "SALVAGE BREACH -- alarm, beacons, red wash, zone-wide"),
 ("P0", "Guardian 1: Slow Scrap Sweeper Bot -- patrol, detect, pursue, catch"),
 ("P0", "Guardian 2: Wind-Up Security Bot"),
 ("P0", "Layered detection: distance, radius overlap, line-of-sight raycast x3"),
 ("P0", "Knockdown, part drop, ~5s recovery window, then neutral"),
 ("P0", "Ownership protection window after detach"),
 ("P0", "SECURED at the Service Hub -- the payoff moment: banner, sound, light, VFX"),
 ("P0", "Profile write on SECURED, and ONLY on SECURED"),
 ("P0", "Cargo HUD: name, weight, speed penalty, distance to hub, security state x5"),
 ("P1", "Guardian proximity indicator"),
 ("P1", "Death: respawn at last hub, scrap auto-recycles at reduced value"),
]))

GROUPS.append(("09-robot", "The robot: rig, assembly and the Bay", """
Architecture is [systems/robot-rig](../systems/robot-rig/README.md). Build the engine before the second
part exists, or there will be a special case in a script forever.
""", [
 ("P0", "The ~10-joint skeleton with Motor6D and invisible pivot carriers"),
 ("P0", "`AnimationController` + `Animator` setup (NOT a Humanoid)"),
 ("P0", "Socket set: Head, Core, Body, LeftArm, RightArm, Mobility, Back x7"),
 ("P0", "`RobotMount` attachment convention + an import checklist"),
 ("P0", "Mount/unmount: align RobotMount to socket, WeldConstraint, Massless, CanCollide=false"),
 ("P0", "Part definition schema: PartId, Slot, Tier, Rarity, Weight, AnimationProfile, CombatStats, VFX, Sound x9"),
 ("P0", "12-16 MVP parts modelled with mounts and stats x16"),
 ("P0", "Robot Builder GUI: 3D preview, seven slots, owned parts, stats"),
 ("P0", "Install sequence: crane, KRRRK, VRRRR, CLUNK, bolts, practice swing"),
 ("P0", "Robot name + Roblox text filtering, in every display context"),
 ("P1", "Duplicate handling: REINFORCE Mk I/II/III, or RECYCLE x2"),
 ("P1", "Mobility sub-rigs: wheels, legs, tracks, hover x4"),
 ("P1", "Decorative actuators: HingeConstraint spin, PrismaticConstraint punch x2"),
 ("P2", "`IKControl` head tracking"),
 ("P2", "`IKControl` aim for ranged profiles"),
]))

GROUPS.append(("10-arena", "The Scrap Arena", """
Persistent, server-wide, adjacent to the Workshop.
""", [
 ("P0", "Arena geometry and the Arena Core"),
 ("P0", "Release / Withdraw robot, with a queue when full"),
 ("P0", "Arena robot instance built from the Bay robot (disposable clone)"),
 ("P0", "Movement: AlignPosition + AlignOrientation on an unanchored, server-owned root"),
 ("P0", "AI priority ladder: attack / move to core / engage / hold"),
 ("P0", "Scripted hitboxes from AI state -- NOT from limb positions"),
 ("P0", "Combat resolution, server-authoritative"),
 ("P0", "Knockback: drop aligner MaxForce, apply impulse, play Knockback"),
 ("P0", "HP persistence across the deployment; no regeneration"),
 ("P0", "Core control detection and the hold timer"),
 ("P0", "Arena Heat escalation: 0-90s, 90-180s, 180-300s, 300s+ x4"),
 ("P0", "ROBOT DISABLED: collapse, sparks, smoke, crane removal"),
 ("P0", "Animation profiles: the ~10 combat clips x10"),
 ("P0", "Shared clips: Idle, WalkWheels, WalkLegs, WalkTracks, Hover, HitFront, HitBack, Knockback, Stunned, ArenaEnter, Victory, Defeat x12"),
 ("P0", "Damage visual stages at 75/50/25/10% x4"),
 ("P1", "Arena panel GUI: champion, owner, hold time, HP, defeats"),
 ("P1", "Arena notifications while in the factory x3"),
 ("P1", "**Measure** concurrent robot count at 30fps on a mid phone"),
 ("P2", "Owner disconnect handling for a deployed robot"),
]))

GROUPS.append(("11-economy-and-save", "Economy, repair and persistence", """
The pinch, and the thing that must never lose a player's progress.
""", [
 ("P0", "Recycler: scrap to Coins, with the repair alternative shown side by side"),
 ("P0", "Repair: scrap to robot HP"),
 ("P0", "Upgrade costs for all four stats, from config x4"),
 ("P0", "Profile schema + version field"),
 ("P0", "Session locking"),
 ("P0", "`UpdateAsync` for everything incremented"),
 ("P0", "**Never overwrite a profile after a failed load**"),
 ("P0", "`BindToClose` flush"),
 ("P0", "Autosave path that structurally cannot see the carried slot"),
 ("P0", "Idempotent grants with ids"),
 ("P1", "Repair Chute -- field repair with cooldown, reduced efficiency, per-window cap x3"),
 ("P1", "Migration function skeleton"),
 ("P2", "Analytics: which zone players stop at, what they spend scrap on"),
]))

GROUPS.append(("12-refresh-and-events", "Factory Refresh, Shifts & events", """
In the MVP, not deferred -- [decision 0006](../decisions/0006-the-factory-refreshes.md).
""", [
 ("P0", "Scrap Refresh every 30-60s from the pool"),
 ("P0", "Factory Cycle every ~4min: warning, machinery, retract unclaimed, respawn"),
 ("P0", "The 20-second warning -- audible and visible zone-wide, while running"),
 ("P0", "Per-zone part pool with rarity weighting"),
 ("P1", "Factory Shift every ~12min x5 (Heavy, Electric, Gold, Security, Chaos)"),
 ("P1", "LEGENDARY PART DETECTED server notification"),
 ("P2", "The eight dynamic events x8"),
 ("P2", "Event concurrency cap"),
]))

GROUPS.append(("13-zones-3-12", "The remaining ten zones", """
**Only after the MVP gate returns a yes.** Each zone is the same shape: layout, scrap set, guardian,
eight parts, gate, return lane -- and a Service Hub every second zone.
""", [
 ("P0", "Zone layout and streamable chunk x10"),
 ("P0", "Zone scrap set x10"),
 ("P0", "Guardian x10"),
 ("P0", "Robot parts, modelled with mounts and stats x80"),
 ("P0", "Zone gate x10"),
 ("P0", "Return lane x10"),
 ("P1", "Service Hub x5"),
 ("P1", "Zone-specific hazard x10"),
 ("P1", "Zone ambience x10"),
]))

GROUPS.append(("14-endgame-and-launch", "Endgame, monetisation & launch", """
Everything after zone 12, plus the commercial surface. **All of this is post-gate** — none of it is
MVP work, and its `P0` markers mean "required for launch once we get here", not "build now".
The store assets are largely already drawn: `assets/concept_art/` holds a logo and two key-art pieces
that map onto thumbnails 1 and 4.
""", [
 ("P0", "The Foundry Heart ending + cinematic"),
 ("P0", "Endless Line: curated room modules and the distance metric"),
 ("P0", "Overclock + Magnet Core Level"),
 ("P0", "Monetisation: passes x4, dev products x4, `ProcessReceipt` grant-exactly-once x9"),
 ("P0", "**Audit every live listing against what the code grants**"),
 ("P0", "Store assets: icon, four thumbnails, description x6"),
 ("P1", "Part Archive completion rewards x12"),
 ("P1", "Cosmetics: magnet skins x7, robot paints x6, robot VFX x5, victory anims, entrances, trails, sound packs x22"),
 ("P1", "Five daily leaderboards x5"),
 ("P1", "Relic Parts -- slots, rarities, effects must be DEFINED first x7"),
 ("P2", "Daily Factory Modifier"),
 ("P2", "Weekly Legendary Part"),
 ("P2", "Weekend Arena Modifier"),
]))

MUL = re.compile(r"\bx(\d+)\b")

def count(text):
    m = MUL.findall(text)
    return int(m[-1]) if m else 1

totals = {"P0": 0, "P1": 0, "P2": 0}
rows = []
for slug, title, intro, items in GROUPS:
    g = {"P0": 0, "P1": 0, "P2": 0}
    body = ["# {} -- {}\n".format(slug.split("-")[0], title), intro.strip(), "\n## Items\n"]
    for pri, text in items:
        n = count(text)
        g[pri] += n
        totals[pri] += n
        body.append("- [ ] **{}** {}".format(pri, text))
    gt = sum(g.values())
    body.append("\n---\n")
    body.append("**{} items** — P0 {} · P1 {} · P2 {}".format(gt, g["P0"], g["P1"], g["P2"]))
    body.append("\n> Counted by `tools/gen-build-manifest.py`. The last `xN` on a line is that line's count.")
    (B / (slug + ".md")).write_text("\n".join(body) + "\n", encoding="utf-8")
    rows.append((slug, title, gt, g["P0"], g["P1"], g["P2"]))

grand = sum(totals.values())

readme = ["""# The build manifest

Everything that must be made, sized so one item is one sitting. Ordered **MVP-first**, around
[the gate](../roadmap/mvp.md#the-gate) — not by the spec's own phase list (section 85), which builds
outward from magnet physics without ever asking whether the game is fun yet.

**Priorities:** `P0` must exist for the group to be usable · `P1` launch · `P2` post-launch.

> ⚠️ **`P0` is not the same as "in the MVP".** Groups **01-12** are the MVP. Groups **13** (zones 3-12)
> and **14** (endgame, monetisation, launch) are gated behind
> [the gate](../roadmap/mvp.md#the-gate) and their contents are in the MVP's **Out** column — their
> P0 items are P0 *within their own group*, not MVP work. The MVP figure is the one that matters for
> scheduling.

> **Counting rule.** The **last `xN` on a line is that line's item count**; a line with no `xN` is one
> item. So `passes x4, dev products x4, ProcessReceipt ... x9` is **9** items -- not 17, and not 1.
> ELEVATOR 13's manifest reported 319 items by counting `xN` rows as one each; the honest count was 577.
>
> Every total on this page is **computed** by `tools/gen-build-manifest.py`, never typed. Re-run it
> after editing an item list -- the generator, not this file, is the source of truth.

## Groups

| # | Group | Items | P0 | P1 | P2 |
|---|---|--:|--:|--:|--:|"""]
for slug, title, gt, p0, p1, p2 in rows:
    readme.append("| [{}]({}.md) | {} | {} | {} | {} | {} |".format(
        slug.split("-")[0], slug, title, gt, p0, p1, p2))
readme.append("| | **Total** | **{}** | **{}** | **{}** | **{}** |".format(
    grand, totals["P0"], totals["P1"], totals["P2"]))

MVP_GROUPS = [r for r in rows if not r[0].startswith(("13-", "14-"))]
mvp_items = sum(r[2] for r in MVP_GROUPS)
mvp_p0 = sum(r[3] for r in MVP_GROUPS)
readme.append("| | *of which **MVP** (groups 01-12)* | *{}* | *{}* | *{}* | *{}* |".format(
    mvp_items, mvp_p0, sum(r[4] for r in MVP_GROUPS), sum(r[5] for r in MVP_GROUPS)))
readme.append("| | *post-gate (groups 13-14)* | *{}* | *{}* | *{}* | *{}* |".format(
    grand - mvp_items, totals["P0"] - mvp_p0,
    totals["P1"] - sum(r[4] for r in MVP_GROUPS),
    totals["P2"] - sum(r[5] for r in MVP_GROUPS)))

readme.append("""
## The order, and why

**01 Foundation** blocks everything — every file later groups write assumes the sync layout, and every
number they tune assumes the config modules.

**02-03 Kit and lighting** come before any room, because 70-80 % of the world is kit
(section 64) and because every later visual judgement is made against the lighting baseline.

**04 Magnet** is deliberately fourth and not first-after-plumbing. It needs the kit to have anything to
sweep, and it needs the lighting to look like the game. But it is **the gate** — a grey room and a pile
of bolts is enough to answer whether sweeping is satisfying, and if it is not, groups 05 onward are
wasted.

**05-08** build outward from the magnet to the loop: hub, HUD, two zones, then the extraction that gives
sweeping a point.

**09-10** are the second half of the game. The rig comes before the Arena because the Arena is just
robots fighting, and the rig is what a robot *is*.

**11-12** close the loop: the economy pinch, persistence, and the refresh that stops the world going
stale. The refresh is **P0** on purpose.

**13-14** are gated on the MVP question getting a yes.

## What is not in here

Per-part balance numbers. The [parts catalog](../content/parts-catalog.md) lists 96 parts with slots,
rarities and effects, but **no part has damage, attack speed, knockback, range, HP, armour, weight or a
Magnet Power requirement yet**. That is per-tier balance work and it belongs to the tier's own group,
not to a manifest line.

Also absent: asset ids. None should be sourced until a slot needs one
([PITFALLS #24](../PITFALLS.md#24-placeholders-are-worse-than-empty-slots)).
""")

(B / "README.md").write_text("\n".join(readme) + "\n", encoding="utf-8")
print("groups: %d   items: %d  (P0 %d / P1 %d / P2 %d)" % (
    len(GROUPS), grand, totals["P0"], totals["P1"], totals["P2"]))
