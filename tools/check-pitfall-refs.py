#!/usr/bin/env python3
"""Resolve every bare `PITFALLS #N` citation to the entry it currently points at.

Anchor-style links (`PITFALLS.md#39-the-colour-language-decays`) are already validated by
check-links.py -- they carry the title, so they cannot drift silently. Bare numeric citations
carry nothing, and PITFALLS.md gets renumbered whenever an entry is inserted or a duplicate
number is fixed. That happened on 2026-08-30: the file had two #48s and an out-of-order #47.

So this prints what each citation resolves to TODAY. It fails on an out-of-range number, and
otherwise gives a human one screen to eyeball -- a citation that reads "PITFALLS #2: a
verification that cannot fail" next to an entry titled something else is the whole point.

Run: python tools/check-pitfall-refs.py
"""
from __future__ import annotations
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PITFALLS = ROOT / "docs" / "PITFALLS.md"
SEARCH_SUFFIXES = {".md", ".luau", ".py", ".json"}
SKIP_DIRS = {".git", "__pycache__", "node_modules", ".claude"}

# Matches the first number after PITFALLS *and* any that follow in a list: "PITFALLS #2, #29,
# #31" is three citations, not one. The first version of this checker captured only #2 and
# silently ignored the rest -- a checker with its own blind spot is the exact thing it exists
# to prevent, and it had one on the first run.
CITATION = re.compile(r"PITFALLS[^\S\n]*#(\d+)((?:\s*,\s*#\d+)*)")
EXTRA = re.compile(r"#(\d+)")
HEADING = re.compile(r"^### (\d+)\.\s*(.+)$", re.MULTILINE)


def load_entries() -> dict[int, str]:
    if not PITFALLS.exists():
        sys.exit("FATAL: %s does not exist" % PITFALLS)
    text = PITFALLS.read_text(encoding="utf-8")
    entries = {int(n): title.strip() for n, title in HEADING.findall(text)}
    if not entries:
        sys.exit("FATAL: no '### N. Title' entries found in PITFALLS.md")
    return entries


def main() -> int:
    entries = load_entries()
    highest = max(entries)

    # a gap means an entry was deleted without renumbering -- every citation above the gap is
    # now off by one and nothing else would report it
    gaps = [n for n in range(1, highest + 1) if n not in entries]

    rows: list[tuple[str, int, int, str]] = []
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file() or path.suffix not in SEARCH_SUFFIXES:
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.name == "PITFALLS.md" or path.name == pathlib.Path(__file__).name:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for lineno, line in enumerate(text.splitlines(), 1):
            for match in CITATION.finditer(line):
                numbers = [int(match.group(1))]
                numbers += [int(n) for n in EXTRA.findall(match.group(2) or "")]
                for number in numbers:
                    rows.append((str(path.relative_to(ROOT)), lineno, number, line.strip()))

    print("PITFALLS.md holds %d entries, numbered 1..%d" % (len(entries), highest))
    if gaps:
        print("  !! GAPS in the numbering: %s -- entries were removed without renumbering" %
              ", ".join(str(g) for g in gaps))
    print("%d bare numeric citation(s) found\n" % len(rows))

    broken = 0
    by_number: dict[int, list[str]] = {}
    for path, lineno, number, _line in rows:
        by_number.setdefault(number, []).append("%s:%d" % (path, lineno))

    for number in sorted(by_number):
        title = entries.get(number)
        where = ", ".join(by_number[number])
        if title is None:
            broken += 1
            print("  #%-3d -> *** NO SUCH ENTRY *** (highest is %d)\n         cited at %s"
                  % (number, highest, where))
        else:
            print("  #%-3d -> %s\n         cited at %s" % (number, title, where))

    print()
    if broken:
        print("FAIL: %d citation(s) point at an entry that does not exist" % broken)
        return 1
    if gaps:
        print("FAIL: numbering has gaps; renumber PITFALLS.md in file order")
        return 1
    print("OK: every citation resolves. Titles above are for eyeballing -- a number that "
          "resolves is not the same as a number that still means what it meant.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
