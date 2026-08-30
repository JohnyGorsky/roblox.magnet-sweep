#!/usr/bin/env python3
"""Enforce decision 0011: Robux never buys Arena power.

Magnet Overcharge is a paid, temporary PvE boost. It must never reach a deployed robot.

There is nothing to assert at runtime, because the thing being forbidden is a call site that
does not exist yet -- `studio_game/` contains no robot or Arena module at all today. So the
gate is a grep, and this is it: **only the modules named below may reference `MagnetState`.**

The failure this prevents is quiet and plausible. Build group 10 lands the Arena; a robot's
damage or HP resolver reasonably asks `MagnetState.stats(owner)` or
`MagnetState.inOvercharge(owner)` for an owner bonus. Nothing errors, nothing logs, and Robux
now buys Arena outcome.

⚠️ This file replaces a comment in MagnetState.luau that said "the assertion below is what
should catch it" -- and there was no assertion, there or anywhere. That comment survived a
build and a final summary that both repeated the claim. A comment asserting a gate is not a
gate; this is the gate.

Run: python tools/check-overcharge-gate.py
"""
from __future__ import annotations
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CODE = ROOT / "studio_game"

# Modules permitted to reference MagnetState, and WHY. Adding a row here is a deliberate act:
# say what it needs and satisfy yourself it is not an Arena or robot path.
ALLOWED = {
    "ServerScriptService/MagnetState.luau": "is MagnetState",
    "ServerScriptService/ScrapService.luau": "the magnet's own state machine: stats, active radius, isFull",
    "ServerScriptService/Bootstrap.server.luau": "starts it, and the dev commands",
}

# Anything matching these is an Arena or robot path and may NEVER reference MagnetState,
# allow-list or not. Belt and braces for the day someone adds a row above without thinking.
FORBIDDEN_NAMES = re.compile(r"(arena|robot|combat|damage|deploy)", re.IGNORECASE)

REFERENCE = re.compile(r"\bMagnetState\b")


def main() -> int:
    if not CODE.exists():
        sys.exit("FATAL: %s does not exist" % CODE)

    offenders: list[tuple[str, int, str]] = []
    forbidden: list[tuple[str, int, str]] = []
    seen_allowed: set[str] = set()

    for path in sorted(CODE.rglob("*.luau")):
        rel = path.relative_to(CODE).as_posix()
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        # A mention inside a comment is not a call site. This is a line-leading heuristic --
        # it does not track `--[[ ]]` blocks -- so it errs toward REPORTING (a reference on a
        # line that also has code is still caught). Erring the other way would be a gate with
        # a hole in it.
        hits = [
            (n, line.strip())
            for n, line in enumerate(lines, 1)
            if REFERENCE.search(line) and not line.lstrip().startswith("--")
        ]
        if not hits:
            continue
        if FORBIDDEN_NAMES.search(pathlib.Path(rel).name):
            forbidden.extend((rel, n, text) for n, text in hits)
        elif rel in ALLOWED:
            seen_allowed.add(rel)
        else:
            offenders.extend((rel, n, text) for n, text in hits)

    print("Decision 0011 — Robux never buys Arena power")
    print("Allow-list (%d entries):" % len(ALLOWED))
    for rel, why in sorted(ALLOWED.items()):
        mark = "used" if rel in seen_allowed else "NO LONGER REFERENCES IT"
        print("  %-46s %-24s %s" % (rel, "[" + mark + "]", why))

    stale = sorted(set(ALLOWED) - seen_allowed)
    problems = 0

    if forbidden:
        problems += len(forbidden)
        print("\n*** ARENA/ROBOT PATH REFERENCES MagnetState — decision 0011 VIOLATED ***")
        for rel, n, text in forbidden:
            print("  %s:%d  %s" % (rel, n, text))

    if offenders:
        problems += len(offenders)
        print("\n*** MODULE NOT ON THE ALLOW-LIST REFERENCES MagnetState ***")
        for rel, n, text in offenders:
            print("  %s:%d  %s" % (rel, n, text))
        print("\n  If this is a magnet path, add it to ALLOWED with a reason.")
        print("  If it is an Arena or robot path, it must not read magnet state at all —")
        print("  an Overcharge is PvE only and a purchased boost may not decide a fight.")

    if stale:
        print("\n  note: allow-listed but no longer referencing MagnetState — %s" % ", ".join(stale))
        print("        remove the row, so the list keeps meaning something.")

    print()
    if problems:
        print("FAIL: %d reference(s) outside the gate" % problems)
        return 1
    print("OK: only the magnet's own modules read MagnetState.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
