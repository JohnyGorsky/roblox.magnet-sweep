# -*- coding: utf-8 -*-
"""Check every relative markdown link in the repo: the file resolves, and any #anchor
matches a real heading.

Anchor slugs follow GitHub's rule: lowercase, drop punctuation, spaces -> hyphens.
GitHub does NOT collapse repeated hyphens (so "a - b" becomes "a--b"), but some other
renderers do -- so both forms are accepted rather than reporting a false positive.

Proven able to fail: temporarily break a link or an anchor and re-run.
"""
import re
import pathlib
import unicodedata
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def slugs_for(heading: str):
    h = re.sub(r"`([^`]*)`", r"\1", heading)
    h = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", h)
    # NOTE: this strips `_` as markdown emphasis, which also eats the underscore inside a code
    # identifier in a heading -- "### 16. `execute_luau` ..." slugs to "16-executeluau-...".
    # GitHub keeps the underscore, so anchors to such headings differ between here and GitHub.
    # Left as-is deliberately: existing links in the repo already use this form, and changing the
    # rule would break them all at once. Match the tool, not GitHub, when writing an anchor.
    h = re.sub(r"[*_]", "", h)
    h = h.lower()
    h = "".join(c for c in h if unicodedata.category(c)[0] in "LNZ" or c in "-_ ")
    # GitHub keeps the hyphen left behind by a stripped leading emoji ("## 🧲 Foo" -> "#-foo"),
    # and does not collapse runs of hyphens. Other renderers do both. Accept every form.
    raw = h.replace(" ", "-")
    trimmed = h.strip().replace(" ", "-")
    return {raw, trimmed,
            re.sub(r"-+", "-", raw).strip("-"),
            re.sub(r"-+", "-", trimmed).strip("-")}


def headings(path: pathlib.Path):
    out = set()
    try:
        txt = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return out
    for line in txt.splitlines():
        m = re.match(r"^#{1,6}\s+(.*?)\s*$", line)
        if m:
            out |= slugs_for(m.group(1))
    return out


def main():
    cache = {}
    bad_file, bad_anchor = [], []
    n_file = n_anchor = 0

    for md in ROOT.rglob("*.md"):
        if ".git" in md.parts:
            continue
        txt = md.read_text(encoding="utf-8", errors="replace")
        rel = md.relative_to(ROOT)
        for m in re.finditer(r"\[[^\]]*\]\(([^)#]*)(?:#([^)]+))?\)", txt):
            target, anchor = (m.group(1) or "").strip(), m.group(2)
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            p = (md.parent / target).resolve() if target else md
            if target:
                n_file += 1
                if not p.exists():
                    bad_file.append((rel, target))
                    continue
            if anchor:
                n_anchor += 1
                if p not in cache:
                    cache[p] = headings(p)
                if anchor.strip() not in cache[p]:
                    bad_anchor.append((rel, target or "(self)", anchor))

    print("file links checked : %d   broken: %d" % (n_file, len(bad_file)))
    for f, t in bad_file:
        print("   BROKEN FILE  ", f, "->", t)
    print("anchors checked    : %d   broken: %d" % (n_anchor, len(bad_anchor)))
    for f, t, a in bad_anchor:
        print("   BROKEN ANCHOR", f, "->", t, "#" + a)

    return 1 if (bad_file or bad_anchor) else 0


if __name__ == "__main__":
    sys.exit(main())
