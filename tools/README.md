# tools — the checkers and the generators

Six scripts. Three **generate** files that must never be hand-edited, three **check** things that
would otherwise drift silently. All are plain `python tools/<name>.py` from the repo root, no
arguments, no dependencies.

> ⚠️ A tool nobody can call is not shipped
> ([PITFALLS #29](../docs/PITFALLS.md#29-shipping-something-nothing-else-knows-about)). This page is
> that tool's caller. If you add a script here, add its row.

## Checkers — run these before calling a job done

| Tool | Answers | How it can fail |
|---|---|---|
| [`check-links.py`](check-links.py) | do all `.md` links and `#anchors` in `docs/` resolve? | a renamed file or a retitled heading; anchors catch a heading rewritten under an unchanged link |
| [`check-pitfall-refs.py`](check-pitfall-refs.py) | does every bare `PITFALLS #N` citation resolve, and to **what**? | an out-of-range number, or a gap in the numbering meaning entries were removed without renumbering |
| [`verify-catalog-vs-spec.py`](verify-catalog-vs-spec.py) | does the generated part catalog match the 87-section spec, in both directions? | a part in the spec and not the catalog (missed), or in the catalog and not the spec (**fabricated**) |
| [`check-overcharge-gate.py`](check-overcharge-gate.py) | does anything outside the magnet read `MagnetState`? | an Arena or robot module reading magnet state — i.e. **decision 0011 violated**, Robux buying Arena power |

## Generators — their output is not editable by hand

| Tool | Writes | Note |
|---|---|---|
| [`gen-build-manifest.py`](gen-build-manifest.py) | `docs/build/*.md` | rewrites the whole file and emits `- [ ]` unconditionally — **a ticked checkbox is erased on the next run.** Progress lives in `Jobs/`, not here |
| [`gen-content-catalogs.py`](gen-content-catalogs.py) | the zone and part catalogs | |
| [`gen-spec-coverage.py`](gen-spec-coverage.py) | `docs/build/spec-coverage.md` | coverage means the named items **arrived**, not that a link resolved ([PITFALLS #9](../docs/PITFALLS.md#9-coverage-by-link-is-not-coverage)) |

## Why `check-pitfall-refs.py` exists

`PITFALLS.md` is renumbered whenever an entry is inserted, and on 2026-08-30 it had to be renumbered
to fix **two entries numbered #48** and a #47 sitting out of order. Anchor-style links
(`PITFALLS.md#39-the-colour-language-decays…`) survive that, because they carry the title and
`check-links.py` validates them. Bare `PITFALLS #N` citations — which is what the `.luau` files use,
where a markdown link would be noise — carry nothing and drift in silence. That renumbering did break
one: a job summary citing `#48` for the type-annotation trap, which had become `#47`.

The tool prints what each number resolves to **today**, so a wrong one is visible on one screen. It
fails hard on an out-of-range number or a gap in the numbering; it cannot tell you that `#2` still
*means* what a comment claims it means, and it says so rather than implying otherwise.

## Why `check-overcharge-gate.py` exists

`MagnetState.grantOvercharge` carried a comment reading *"DECISION 0011 IS A CODE GATE, NOT A
PROMISE… the assertion below is what should catch it."* **There was no assertion**, there or
anywhere, and the claim was repeated in the job's final summary. The gate the comment described
did not exist; what existed was a comment describing it.

It has to be a grep rather than a runtime check, because the thing being forbidden is a call site
that has not been written yet — `studio_game/` contains no robot or Arena module at all today, so
nothing at runtime could observe the violation. Group 10 lands the Arena; a robot's damage
resolver reasonably asks `MagnetState.stats(owner)` for an owner bonus; nothing errors, and Robux
now buys Arena outcome.

**Prefer an anchor link when the file is markdown.** Then `check-links.py` verifies it and nobody has
to eyeball anything.

## The order to run them in

```
python tools/gen-content-catalogs.py     # regenerate first...
python tools/gen-spec-coverage.py
python tools/gen-build-manifest.py
python tools/verify-catalog-vs-spec.py   # ...then check what was generated
python tools/check-links.py
python tools/check-pitfall-refs.py
python tools/check-overcharge-gate.py
```

Generators before checkers, because a checker run against a stale generated file is a check that
passed for the wrong reason.
