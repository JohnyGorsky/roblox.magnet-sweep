# -*- coding: utf-8 -*-
"""Emit the 96-row parts catalog into Luau, read from docs/content/parts-catalog.md.

The doc is the source of truth: it is transcribed from the spec field for field and already
verified against it by tools/verify-catalog-vs-spec.py. Hand-typing 96 rows into Luau would
create a SECOND source that drifts -- so this generates them, and can be re-run.

Combat stats are deliberately omitted. The doc says none of the 96 has combat stats yet, and
inventing them here would bury made-up numbers inside a file that looks authoritative.
"""
import io, re, sys

DOC = 'docs/content/parts-catalog.md'
OUT = 'studio_game/ReplicatedStorage/Config/PartsCatalog.luau'

rows = []
for line in io.open(DOC, encoding='utf-8'):
    if not line.startswith('|'):
        continue
    if not re.match(r'\|\s*\d+\s*\|', line):
        continue
    f = [x.strip() for x in line.strip().strip('|').split('|')]
    # | # | Part | PartId | Tier | Zone | Slot | Rarity | Spec rarity | Effect | Animation | Mobility |
    if len(f) < 11:
        sys.exit('row has %d fields, expected 11: %s' % (len(f), line[:80]))
    rows.append({
        'n': int(f[0]),
        'name': f[1],
        'id': f[2].strip('`'),
        'tier': int(f[3]),
        'zone': f[4],
        'slot': f[5],
        'rarity': f[6],
        'specRarity': f[7],
        'effect': f[8],
        'anim': f[9].replace('`', ''),
        'mob': f[10].replace('`', ''),
    })

if len(rows) != 96:
    sys.exit('expected 96 rows, parsed %d' % len(rows))

VALID_SLOT = {'Head', 'Core', 'Body', 'Arm', 'Mobility', 'Back'}
VALID_RAR = {'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary', 'Mythic'}
for r in rows:
    if r['slot'] not in VALID_SLOT:
        sys.exit('row %d bad slot %r' % (r['n'], r['slot']))
    if r['rarity'] not in VALID_RAR:
        sys.exit('row %d bad rarity %r' % (r['n'], r['rarity']))


def lua_str(s):
    return '"%s"' % s.replace('\\', '\\\\').replace('"', '\\"')


def dash(s):
    """The doc writes an em-dash for 'no value'; Luau wants nil."""
    return None if s in ('—', '-', '', '=') else s


L = []
L.append('--!strict')
L.append('--[[')
L.append('\tConfig/PartsCatalog — all 96 robot parts, as data.')
L.append('')
L.append('\t🔴 GENERATED from docs/content/parts-catalog.md. Do not hand-edit: edit the doc and')
L.append('\tre-run tools/gen-parts-catalog.py. The doc is transcribed from the spec field for field')
L.append('\tand verified against it by tools/verify-catalog-vs-spec.py, so it is the one source that')
L.append('\tis actually checked. A second hand-typed copy here would drift from it silently.')
L.append('')
L.append('\t⚠️ NO COMBAT STATS. The catalog doc states none of the 96 parts has combat stats yet, so')
L.append('\tthis file carries none. Inventing them here would hide made-up numbers inside a file that')
L.append('\treads as authoritative -- balance belongs in a tuning pass, done deliberately.')
L.append('')
L.append('\t`specRarity` is the SPEC\'s own grade where decision 0015 re-graded a part; nil means the')
L.append('\tgrade was left unchanged. Nothing is destroyed.')
L.append(']]')
L.append('')
L.append('local ReplicatedStorage = game:GetService("ReplicatedStorage")')
L.append('local Parts = require(ReplicatedStorage.Config.Parts)')
L.append('')
L.append('local PartsCatalog = {}')
L.append('')
L.append('PartsCatalog.ALL = {')

for r in rows:
    bits = [
        'partId = %s' % lua_str(r['id']),
        'name = %s' % lua_str(r['name']),
        'tier = %d' % r['tier'],
        'slot = %s' % lua_str(r['slot']),
        'rarity = %s' % lua_str(r['rarity']),
    ]
    sr = dash(r['specRarity'])
    if sr:
        bits.append('specRarity = %s' % lua_str(sr))
    an = dash(r['anim'])
    if an:
        bits.append('animationProfile = %s' % lua_str(an))
    mo = dash(r['mob'])
    if mo:
        bits.append('mobilityProfile = %s' % lua_str(mo))
    bits.append('zone = %s' % lua_str(r['zone']))
    bits.append('effect = %s' % lua_str(r['effect']))

    L.append('\t--- %d. %s' % (r['n'], r['name']))
    L.append('\t{ %s },' % ', '.join(bits))

L.append('}')
L.append('')
L.append('--- Lookups, built once. 🔴 A duplicate partId is an error, not a last-one-wins:')
L.append('--- two rows sharing an id means every consumer silently disagrees about that part.')
L.append('local byId = {}')
L.append('local byTier = {}')
L.append('for _, p in ipairs(PartsCatalog.ALL) do')
L.append('\tif byId[p.partId] then')
L.append('\t\terror(("PartsCatalog: duplicate partId %q"):format(p.partId), 0)')
L.append('\tend')
L.append('\tbyId[p.partId] = p')
L.append('\tbyTier[p.tier] = byTier[p.tier] or {}')
L.append('\ttable.insert(byTier[p.tier], p)')
L.append('end')
L.append('')
L.append('function PartsCatalog.byId(id: string)')
L.append('\treturn byId[id]')
L.append('end')
L.append('')
L.append('function PartsCatalog.forTier(tier: number)')
L.append('\treturn byTier[tier] or {}')
L.append('end')
L.append('')
L.append('--- Every part of a given grade, in catalog order.')
L.append('function PartsCatalog.byRarity(rarity: string)')
L.append('\tlocal out = {}')
L.append('\tfor _, p in ipairs(PartsCatalog.ALL) do')
L.append('\t\tif p.rarity == rarity then')
L.append('\t\t\ttable.insert(out, p)')
L.append('\t\tend')
L.append('\tend')
L.append('\treturn out')
L.append('end')
L.append('')
L.append('--- ⚠️ Validates against Config/Parts rather than trusting the generator. If the doc grows a')
L.append('--- slot or grade the schema does not know, this says so at startup instead of at runtime.')
L.append('function PartsCatalog.validate(): { string }')
L.append('\tlocal problems = {}')
L.append('\tlocal slots = {}')
L.append('\tfor slot in pairs(Parts.SLOT_TO_SOCKETS) do')
L.append('\t\tslots[slot] = true')
L.append('\tend')
L.append('\tlocal grades = {}')
L.append('\tfor _, r in ipairs(Parts.RARITY_ORDER) do')
L.append('\t\tgrades[r] = true')
L.append('\tend')
L.append('\tfor _, p in ipairs(PartsCatalog.ALL) do')
L.append('\t\tif not slots[p.slot] then')
L.append('\t\t\ttable.insert(problems, ("%s has unknown slot %q"):format(p.partId, p.slot))')
L.append('\t\tend')
L.append('\t\tif not grades[p.rarity] then')
L.append('\t\t\ttable.insert(problems, ("%s has unknown rarity %q"):format(p.partId, p.rarity))')
L.append('\t\tend')
L.append('\tend')
L.append('\treturn problems')
L.append('end')
L.append('')
L.append('return PartsCatalog')
L.append('')

io.open(OUT, 'w', encoding='utf-8', newline='\n').write('\n'.join(L))

import collections
print('wrote %s' % OUT)
print('  %d parts' % len(rows))
print('  by rarity: %s' % dict(collections.Counter(r['rarity'] for r in rows)))
print('  by slot:   %s' % dict(collections.Counter(r['slot'] for r in rows)))
print('  tiers 1-%d, %d parts each' % (max(r['tier'] for r in rows),
                                       len(rows) // max(r['tier'] for r in rows)))
regraded = [r for r in rows if dash(r['specRarity'])]
print('  re-graded by decision 0015: %d' % len(regraded))
