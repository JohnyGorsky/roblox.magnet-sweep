# -*- coding: utf-8 -*-
"""Fix pass 1: regenerate the zones + parts catalog with derived values MARKED,
MobilityProfile split out of AnimationProfile, and the Observations corrected."""
import re, pathlib
from collections import Counter

ROOT = pathlib.Path(r"c:/Dati/Work/roblox.magnet-sweep")
gen = ROOT / "tools" / "gen-content-catalogs.py"
old = ROOT / "tools" / "gen-spec-coverage.py"  # untouched here

src = (ROOT / "assets" / "MAGNET SWEEP.md").read_text(encoding="utf-8")

# ---- parse spec ----
tiers = {}
for t in range(1, 13):
    m = re.search(r"# \d+\.\s*Tier %d\s*[-–]\s*(.+?)\n(.*?)(?=\n# \d+\.|\Z)" % t, src, re.S)
    name, blk = m.group(1).strip(), m.group(2)
    subs = dict()
    for sm in re.finditer(r"^### (.+?)\s*\n(.*?)(?=^### |\Z)", blk, re.S | re.M):
        subs[sm.group(1).strip()] = sm.group(2).strip()
    parts = []
    for line in blk.splitlines():
        c = [x.strip() for x in line.split("|")]
        if len(c) == 6 and c[0] == "" and c[-1] == "" and c[1] not in ("Part", "") \
           and not (set(c[1]) <= set("-: ")):
            parts.append(tuple(c[1:5]))
    tiers[t] = {"name": name, "subs": subs, "parts": parts}

# spec-sourced theme / objects, else None
SPEC_THEME = {}
SPEC_OBJ = {}
for t, d in tiers.items():
    s = d["subs"]
    SPEC_THEME[t] = s.get("Environment") or s.get("Theme")
    SPEC_OBJ[t] = s.get("Normal scrap") or s.get("Objects")
    d["guardian"] = (s.get("Guardian") or "").strip()

def flat(x):
    if not x:
        return None
    lines = [l.strip("- ").strip() for l in x.splitlines() if l.strip()]
    return ", ".join(lines)

# derived fills, EXPLICITLY MARKED
DERIVED_THEME = {
 4: "Industrial storage. Racking, pallets, strapping.",
 6: "Repair bays, lifts, part racks.",
 7: "Full assembly line. Robot welders, body shells on rails.",
 8: "Outdoor construction yard. Mud, floodlights, big machines.",
 9: "Turbine halls, busbars, transformer yards. Arcing everywhere.",
 10: "Clean labs, test chambers, experimental hardware.",
 11: "Vacuum chambers, launch rails, orbital hardware.",
 12: "Impossible technology. Light that behaves wrongly.",
}
DERIVED_OBJ = {
 3: "pots, pans, cutlery, appliance parts",
 4: "pallet hardware, brackets, chain, strapping, shelf pins",
 5: "sign hardware, meter parts, cart wheels, urban metal",
 6: "spark plugs, discs, bolts, exhaust sections, mirrors",
 7: "body panels, axles, sensors, wiring looms",
 8: "track links, hydraulic rams, counterweights, bucket teeth",
 9: "insulators, copper bar, coils, breaker parts",
 10: "servos, actuators, lab hardware, prototype plating",
 11: "heat tiles, fasteners, thruster nozzles, alloy offcuts",
 12: "exotic alloy, containment rings, flux shards",
}

COMBAT = {
 "Pipe Wrench":"SweepLight","Spring Puncher":"PunchFast","Grabber Claw":"GrabPull",
 "Toy Hammer":"SmashHeavy","Jack-in-the-Box Launcher":"RangedCannon","Giant Spoon":"SweepHeavy",
 "Frying Pan":"Shield","Golden Tenderizer":"SmashHeavy","Shelf Beam":"SweepLight",
 "Strapping Gun":"RangedRapid","STOP Sign":"Shield","Parking Meter":"SweepHeavy",
 "Golden Hydrant Cannon":"RangedCannon","Exhaust Cannon":"RangedCannon",
 "Brake Disc Saw":"ThrustContinuous","Chrome Bumper":"ChargeBody","Welding Arm":"ThrustContinuous",
 "Axle Hammer":"SmashHeavy","Prototype Engine Crane":"GrabPull","Excavator Bucket":"SmashHeavy",
 "Forklift Fork":"GrabPull","Crane Hook":"GrabPull","Busbar Blade":"SweepLight",
 "Coil Cannon":"RangedCannon","Plasma Cutter":"ThrustContinuous","Servo Fist":"PunchFast",
 "Experimental Magnet Arm":"GrabPull","Manipulator Claw":"GrabPull","Ion Lance":"RangedCannon",
 "Meteor Drill":"ThrustContinuous","Gravity Hammer":"SmashHeavy","Phase Blade":"SweepLight",
 "Void Magnet":"GrabPull",
}
MOBIL = {
 "Caster Wheels":"Wheels","Roller Skates":"Wheels","Serving Cart Wheels":"Wheels",
 "Pallet Wheels":"Wheels","Shopping Cart Wheels":"Wheels","Motorcycle Wheels":"Wheels",
 "Racing Wheels":"Wheels","Tank Tracks":"Tracks","Magnetic Rail":"Hover",
 "Hover Actuators":"Hover","Rover Legs":"Legs","Gravity Ring":"Hover",
}
POWER = {1:10,2:20,3:35,4:55,5:85,6:130,7:200,8:300,9:450,10:675,11:1000,12:1500}
SCALE = {1:"Tiny scrap",2:"Toys / mechanisms",3:"Appliances",4:"Industrial storage",5:"Urban metal",
         6:"Vehicle components",7:"Cars",8:"Construction machines",9:"Heavy electrical",
         10:"Experimental technology",11:"Space hardware",12:"Impossible technology"}


# ---------------------------------------------------------------- rarity re-grade
# Decision 0015. The spec grades 35 of 96 parts "Rare" and only 13 "Uncommon", so Rare
# is the most common rarity in the game. We re-band per tier, PRESERVING the spec's own
# ordering within each tier: rank a tier's 8 parts by the spec rarity (stable, so row
# order breaks ties), then relabel against that tier's target band. The spec's
# Legendary/Mythic always stays the top of its tier.
RANK = {"Common": 0, "Uncommon": 1, "Rare": 2, "Epic": 3, "Legendary": 4, "Mythic": 5}

# per tier, the 8 grades in ascending order. Depth shifts the whole band upward.
BANDS = {}
for _t in (1, 2, 3):
    BANDS[_t] = ["Common"] * 3 + ["Uncommon"] * 3 + ["Rare"] + ["Legendary"]
for _t in (4, 5, 6):
    BANDS[_t] = ["Common"] * 2 + ["Uncommon"] * 3 + ["Rare"] * 2 + ["Legendary"]
for _t in (7, 8, 9):
    BANDS[_t] = ["Common"] + ["Uncommon"] * 2 + ["Rare"] * 3 + ["Epic"] + ["Legendary"]
for _t in (10, 11):
    BANDS[_t] = ["Uncommon"] + ["Rare"] * 3 + ["Epic"] * 3 + ["Legendary"]
BANDS[12] = ["Uncommon"] + ["Rare"] * 3 + ["Epic"] * 3 + ["Mythic"]

REGRADED = {}          # (tier, part name) -> new rarity
for _t in range(1, 13):
    _idx = sorted(range(len(tiers[_t]["parts"])),
                  key=lambda i: (RANK[tiers[_t]["parts"][i][2]], i))
    for _pos, _i in enumerate(_idx):
        REGRADED[(_t, tiers[_t]["parts"][_i][0])] = BANDS[_t][_pos]

def graded(t, name, spec_rarity):
    return REGRADED.get((t, name), spec_rarity)

def pid(n):
    return n.upper().replace("-", " ").replace(" ", "_")

# ================= zones =================
L = ["""# The twelve zones

One continuous corridor ([decision 0003](../../decisions/0003-forward-is-the-only-direction.md)). Each
zone owns a **pool of 8 possible Robot Parts**; a Factory Cycle spawns only some of them, re-weighted by
the active Shift ([decision 0006](../../decisions/0006-the-factory-refreshes.md)).

Full part list with slots, rarities and effects: [parts-catalog.md](../parts-catalog.md).

> **What is the spec's and what is not.** Zone names, scales, guardians, gate values and all 96 parts are
> **the spec's**. The spec gives an *Environment/Theme* only for tiers 1, 2, 3 and 5, and an *object
> list* only for tiers 1 and 2. Everything else on this page is marked **(derived)** — a job 001
> proposal, not a specified value.

## Overview

| Tier | Zone | Scale | Guardian | Magnet Power gate |
|---:|---|---|---|---:|"""]
for t in range(1, 13):
    L.append("| {} | **{}** | {} | {} | {:,} |".format(
        t, tiers[t]["name"].title(), SCALE[t], tiers[t]["guardian"], POWER[t]))

L.append("""
Power gates rise roughly ×1.5 per zone. **These are initial balancing targets (§62) and must be
playtested.**

Service Hubs sit after zones **2, 4, 6, 8, 10 and 12** — six hubs, evenly spaced. §18 says only
"approximately every two zones" and does not enumerate them; the placement was **decided**, so that a
rare part is never more than two zones from safety and the longest extraction stays inside the spec's
20-45 second target.

---
""")
for t in range(1, 13):
    d = tiers[t]
    th, thd = (flat(SPEC_THEME[t]), False) if SPEC_THEME[t] else (DERIVED_THEME[t], True)
    ob, obd = (flat(SPEC_OBJ[t]), False) if SPEC_OBJ[t] else (DERIVED_OBJ[t], True)
    L.append("## Tier {} — {}\n".format(t, d["name"]))
    L.append("**Theme{}.** {}\n".format(" *(derived)*" if thd else "", th))
    L.append("**Normal scrap{}.** {}\n".format(" *(derived)*" if obd else "", ob))
    L.append("**Guardian.** {}\n".format(d["guardian"]))
    L.append("**Gate.** Magnet Power {:,}\n".format(POWER[t]))
    L.append("| Part | Slot | Rarity | Effect |")
    L.append("|---|---|---|---|")
    for n, sl, r, e in d["parts"]:
        g = graded(t, n, r)
        rr = g if g == r else "{} *(spec: {})*".format(g, r)
        L.append("| {} | {} | {} | {} |".format(n, sl, rr, e))
    L.append("")

# ---- observations, COMPUTED ----
allp = [(t, n, s, graded(t, n, r)) for t in range(1, 13) for (n, s, r, e) in tiers[t]["parts"]]
selfsuff = []
for t in range(1, 13):
    sl = [s for (tt, n, s, r) in allp if tt == t]
    if all(k in sl for k in ("Head", "Core", "Body", "Mobility", "Back")) and sl.count("Arm") >= 2:
        selfsuff.append(t)
leg = [(t, n, s) for (t, n, s, r) in allp if r in ("Legendary", "Mythic")]
leg_arm = [x for x in leg if x[2] == "Arm"]
leg_non = [x for x in leg if x[2] != "Arm"]
mob_hi = [(t, n, r) for (t, n, s, r) in allp if s == "Mobility" and t >= 9]
mob_epic = [x for x in mob_hi if x[2] == "Epic"]
dup = []
for t in range(1, 13):
    c = Counter(s for (tt, n, s, r) in allp if tt == t)
    for k, v in sorted(c.items()):
        if k != "Arm" and v > 1:
            dup.append((t, k, v))

L.append("""---

## Observations on the pool as written

Counted by `tools/gen-content-catalogs.py`, not eyeballed. Slots and part counts are the spec's;
rarity is the re-graded value ([decision 0015](../../decisions/0015-rarity-is-re-graded.md)).

- **Every tier has exactly 8 parts.** 12 × 8 = **96**.
- **Every tier can fill all seven slots.** All {} tiers contain a Head, Core, Body, Mobility and Back
  part plus at least two Arms, so a player working a single tier is never blocked from completing a
  robot. What a tier does *not* give is a *choice* — usually exactly one option per non-Arm slot.
- **Some tiers double up a slot instead of spreading:** {}. Those tiers offer two options in one slot and
  one everywhere else.
- **The top-grade part of a tier is usually an Arm — {} of {}** (11 Legendary + 1 Mythic, one per
  tier). The exceptions are {}.
- **Mobility is thin and expensive at the top.** Tiers 9-12 offer only {} — {} of them Epic ({}). A late
  player who has not found an Epic mobility part is on {}.
- The **Giant Spoon** (tier 3, Uncommon) is called out in §28 as the part that should become the game's
  recognisable icon. It is deliberately *not* rare — everyone should get one.
""".format(
    len(selfsuff),
    "; ".join("tier %d has %d %s parts" % (t, v, k) for t, k, v in dup),
    len(leg_arm), len(leg),
    ", ".join("%s (tier %d, %s)" % (n, t, s) for t, n, s in leg_non),
    ", ".join("%s (%s)" % (n, r) for t, n, r in mob_hi),
    len(mob_epic),
    " and ".join(n for t, n, r in mob_epic),
    "Racing Wheels (tier 7, Rare) or an earlier wheel",
))
(ROOT / "docs/content/zones/README.md").write_text("\n".join(L), encoding="utf-8")

# ================= parts catalog =================
O = ["""# Robot parts — full catalog

**96 parts** across 12 tiers, 8 per tier. Part name, slot and effect are **the spec's** (§26-37),
transcribed field for field and verified against it by `tools/verify-catalog-vs-spec.py`.

**Rarity is re-graded** ([decision 0015](../decisions/0015-rarity-is-re-graded.md)) — the spec's own
grade is kept in the **Spec rarity** column, where `=` means unchanged. Nothing is destroyed.

The **Animation** and **Mobility** columns are **(derived)** — a job 001 proposal, not spec values.
They are two *separate* fields on a part
([systems/robot-rig §10](../systems/robot-rig/README.md#10-the-part-specification)): a combat
`AnimationProfile` drives the arms; a `MobilityProfile` selects the locomotion clip and sub-rig.

Rarity ramp: `Common` → `Uncommon` → `Rare` → `Epic` → `Legendary` → `Mythic`.
Slots: Head · Core · Body · Arm (either side) · Mobility · Back.

Every part is content, never code —
[decision 0004](../decisions/0004-parts-are-content-rig-is-the-engine.md). The engine knows the
profile, not the object.

## The full table

| # | Part | `PartId` | Tier | Zone | Slot | Rarity | Spec rarity | Effect | Animation *(derived)* | Mobility *(derived)* |
|--:|---|---|--:|---|---|---|---|---|---|---|"""]
i = 0
rc, sc, ac, mc, spec_rc = Counter(), Counter(), Counter(), Counter(), Counter()
for t in range(1, 13):
    for n, s, r, e in tiers[t]["parts"]:
        i += 1
        a = COMBAT.get(n)
        mo = MOBIL.get(n)
        g = graded(t, n, r)
        rc[g] += 1
        spec_rc[r] += 1
        sc[s] += 1
        if a: ac[a] += 1
        if mo: mc[mo] += 1
        O.append("| {} | {} | `{}` | {} | {} | {} | {} | {} | {} | {} | {} |".format(
            i, n, pid(n), t, tiers[t]["name"].title(), s, g,
            r if r != g else "=", e,
            "`" + a + "`" if a else "—", "`" + mo + "`" if mo else "—"))

O.append("\n**{} parts.**\n\n## Rarity distribution\n\n| Rarity | Ours | Spec's |\n|---|--:|--:|".format(i))
for r in ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]:
    O.append("| {} | {} | {} |".format(r, rc[r], spec_rc[r]))
O.append("""
The spec's column is why [decision 0015](../decisions/0015-rarity-is-re-graded.md) exists: it graded
**{} of {} parts `Rare`** against only **{} `Uncommon`**, making `Rare` the most common rarity in the
game and leaving the colour ramp meaningless.

The re-grade bands **per tier** and keeps the spec's own ordering inside each tier, so a tier's most
valuable part stays its most valuable part. Depth shifts the band up: tiers 1-3 top out at one
Legendary over mostly Commons; tiers 10-12 have no Commons at all. **Every tier still has exactly one
top-grade part** — its trophy — except tier 12, whose Void Magnet is the game's only Mythic.

## Slot distribution

| Slot | Count |
|---|--:|""".format(spec_rc["Rare"], i, spec_rc["Uncommon"]))
for s in ["Head", "Core", "Body", "Arm", "Mobility", "Back"]:
    O.append("| {} | {} |".format(s, sc[s]))

O.append("""
Arms are the largest group by a wide margin, which is correct: arms are where the visible comedy lives,
and both arm sockets accept any Arm part. Spoon + STOP Sign is a legal build.

## Animation profiles *(derived)*

Only parts that swing, shoot, block or grab need a combat profile. Head, Core, Body and Back parts are
passive — they change stats and add VFX; they do not drive the rig.

| Profile | Parts |
|---|--:|""")
for p, c in sorted(ac.items(), key=lambda kv: (-kv[1], kv[0])):
    O.append("| `{}` | {} |".format(p, c))
O.append("| **total** | **{}** |".format(sum(ac.values())))

O.append("""
## Mobility profiles *(derived)*

| Profile | Parts |
|---|--:|""")
for p, c in sorted(mc.items(), key=lambda kv: (-kv[1], kv[0])):
    O.append("| `{}` | {} |".format(p, c))
O.append("| **total** | **{}** |".format(sum(mc.values())))

passive = i - sum(ac.values()) - sum(mc.values())
O.append("""
**{} parts carry a combat profile across {} profiles. {} carry a mobility profile across {}. The
remaining {} are passive.**

This is the payoff of [decision 0004](../decisions/0004-parts-are-content-rig-is-the-engine.md): a
catalog that could have needed hundreds of bespoke animations needs **{} combat clips** plus the shared
locomotion and reaction set. Definitions are in
[systems/robot-rig](../systems/robot-rig/README.md#5-animation-profiles).

## What is still missing per part

Every row above needs, before it can ship:

- a model with a `RobotMount` `Attachment`
- `Weight` class (Small / Medium / Heavy / Extreme) — drives the carry penalty
- `CombatStats`: damage · attackSpeed · knockback · range · hp · armor
- `VFXProfile` and `SoundProfile`
- a Magnet Power requirement to detach it

**None of these are specified anywhere in the spec.** They are per-tier balance work and belong to that
tier's build group, not to this catalog.""".format(
    sum(ac.values()), len(ac), sum(mc.values()), len(mc), passive, len(ac)))

(ROOT / "docs/content/parts-catalog.md").write_text("\n".join(O) + "\n", encoding="utf-8")
print("zones + catalog regenerated: %d parts, %d combat profiles (%d parts), %d mobility profiles (%d parts), %d passive"
      % (i, len(ac), sum(ac.values()), len(mc), sum(mc.values()), passive))
print("self-sufficient tiers:", len(selfsuff))
print("legendary arm/total: %d/%d" % (len(leg_arm), len(leg)))
