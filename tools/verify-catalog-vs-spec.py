# -*- coding: utf-8 -*-
"""Re-derive the part list straight from the SPEC and diff it against the generated
catalog. This check can fail: any invented, dropped, renamed or re-slotted part shows up,
and so does any drift in the spec-rarity column.

Rarity is deliberately re-graded (decision 0015), so the catalog carries the spec's own
grade in a "Spec rarity" column -- `=` meaning unchanged. That column is what is checked
here, so the re-grade can never quietly erase the source data.

The table is parsed by HEADER NAME, not by column index, so adding a column does not
silently break the check (it did once).
"""
import re
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
spec = (ROOT / "assets" / "MAGNET SWEEP.md").read_text(encoding="utf-8")


def cells(line):
    if "|" not in line:
        return None
    c = [x.strip() for x in line.split("|")]
    if len(c) < 3 or c[0] != "" or c[-1] != "":
        return None
    return c[1:-1]


# ---- the spec's twelve tier tables ----
spec_parts = []
tier = None
for line in spec.splitlines():
    m = re.match(r"^# \d+\.\s*Tier (\d+)\s*[-–]", line)
    if m:
        tier = int(m.group(1))
        continue
    if re.match(r"^# \d+\.", line):
        tier = None
        continue
    if tier is None:
        continue
    c = cells(line)
    if c and len(c) == 4 and c[0] not in ("Part", "") and not (set(c[0]) <= set("-: ")):
        spec_parts.append((tier, c[0], c[1], c[2], c[3]))

# ---- the generated catalog, parsed by header name ----
cat = (ROOT / "docs" / "content" / "parts-catalog.md").read_text(encoding="utf-8")
header, rows = None, []
for line in cat.splitlines():
    c = cells(line)
    if not c:
        continue
    if header is None:
        if c and c[0] == "#" and "Part" in c:
            header = [h.replace("*", "").replace("(derived)", "").strip() for h in c]
        continue
    if set("".join(c)) <= set("-: "):
        continue
    if not c[0].isdigit():
        continue
    rows.append(dict(zip(header, c)))

if header is None:
    sys.exit("FAIL: could not find the catalog table header")
for need in ("Part", "Tier", "Slot", "Rarity", "Spec rarity", "Effect"):
    if need not in header:
        sys.exit("FAIL: catalog table is missing the %r column (header: %s)" % (need, header))

doc_parts = []
for r in rows:
    spec_rarity = r["Spec rarity"]
    if spec_rarity == "=":
        spec_rarity = r["Rarity"]
    doc_parts.append((int(r["Tier"]), r["Part"], r["Slot"], spec_rarity, r["Effect"]))

print("spec parts: %d   catalog parts: %d" % (len(spec_parts), len(doc_parts)))
ss, dd = set(spec_parts), set(doc_parts)
only_spec, only_doc = sorted(ss - dd), sorted(dd - ss)
print("in SPEC but not catalog: %d" % len(only_spec))
for r in only_spec:
    print("   -", r)
print("in CATALOG but not spec (FABRICATED or DRIFTED if any): %d" % len(only_doc))
for r in only_doc:
    print("   +", r)

# ---- guardians and the power curve ----
zones_doc = (ROOT / "docs" / "content" / "zones" / "README.md").read_text(encoding="utf-8")
guards = re.findall(r"^### Guardian\s*\n\s*\n(.+?)\s*$", spec, re.M)
missing_g = [g for g in guards if g.rstrip(".") not in zones_doc]
print("\nguardians in spec: %d   missing from zones doc: %s" % (len(guards), missing_g or "none"))

curve = re.search(r"# 62\..*?\n(.*?)\n# 63\.", spec, re.S)
crows = re.findall(r"^\|\s*(\d+)\s*\|\s*([\d,]+)\s*\|", curve.group(1), re.M) if curve else []
factory = (ROOT / "docs" / "systems" / "factory" / "README.md").read_text(encoding="utf-8")
badp = [(z, v) for z, v in crows if v not in factory]
print("power-curve rows in spec: %d   values missing from factory doc: %s" % (len(crows), badp or "none"))

fail = bool(only_spec or only_doc or missing_g or badp or len(spec_parts) != 96)
print("\nRESULT:", "FAIL" if fail else "OK")
sys.exit(1 if fail else 0)
