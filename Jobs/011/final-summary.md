# Job #011 — final summary

**Project**: `roblox.magnet-sweep`
**Status**: HUD complete and **verified in Play on the phone preset**. One sound slot awaits a human.
Desktop layout is **built but not verified** — see *What is not verified*.

Build group 06's HUD half. The magnet has worked since job 007 and been audible since job 010, and
**nothing rendered any of it**: `MagnetState.push` has been firing thirteen fields down `StatsChanged`
on every change, and the only way to see your own Flow was `dev("magnet.stats")`.

---

## What was built

| | |
|---|---|
| `ReplicatedStorage/Ui/Theme.luau` | The style skill's §7 tokens once — colours named by *meaning*, `FontFace` never `Font`, motion timings |
| `ReplicatedStorage/Ui/Layout.luau` | The measured canvas, Roblox's own reserved rects, the free-band solver, and a `ready()` gate |
| `ReplicatedStorage/Ui/Components.luau` | panel · label · bar · button · counter. The design system applied by **construction** |
| `ReplicatedStorage/Ui/Banner.luau` | One line, all caps, short-lived, queued, de-duped |
| `StarterPlayerScripts/Hud.local.luau` | The HUD, and a layout audit that ships with it |
| `ServerScriptService/MagnetState.luau` | `TRACKS`, `quotes()`, `upgrade()` — the one place coins become a magnet |
| `ServerScriptService/Bootstrap.server.luau` | `RequestUpgrade` bound; `hud.hide` and `magnet.coins` dev commands |
| `ServerScriptService/RemoteBinder.luau` | `bindFunction` no longer truncates a handler's returns |
| `ReplicatedStorage/SoundKit.luau` | A `UI.Press` slot, empty, announcing itself |
| `tools/luau-analyze.sh` | Ported from The Last Tide. This repo had no static analysis at all |

## The measurement, in Play, on the Device Emulator's phone preset

Studio was **already** in the emulator when this job started — `ViewportSize` read 666 × 374 in Edit,
which is the preset exactly. Nothing needed flipping.

| | |
|---|---|
| `Camera.ViewportSize` | 666 × 374 |
| `GuiService:GetGuiInset()` | (0, **58**) — not the 36 older docs still quote |
| Usable canvas (`CoreUISafeInsets`) | **666 × 316** |
| `UserInputService.TouchEnabled` | **true** — the emulator does give real touch |
| `DynamicThumbstickFrame` | x −100..266 · y 105..416 |
| `JumpButton` | x 571..641 · y 226..296 |
| `TouchControlFrame` | x 0..666 · y 0..316 — **the whole canvas** |

Two findings here are load-bearing and neither could have been reasoned out:

**A `CoreUISafeInsets` element at `(0,0)` reports `AbsolutePosition (0,0)`; a `ScreenInsets = None`
element at `(0,0)` reports `(0,−58)`.** `TouchGui` shares the former, so its rects and ours compare
directly. That is the fact the whole collision audit rests on, and it was measured rather than assumed.

**`TouchControlFrame` is the entire canvas.** Counting it would mark every element on screen as
colliding. `Layout.reserved()` drops any rect covering ≥ 90 % of the canvas — `DynamicThumbstickFrame`
is 54 % and is kept.

## The layout conflict, and how it was resolved

`ui-direction.md` puts Scrap bottom-centre and Upgrade bottom-right. Both are unavailable on a phone:

> The free bottom band is x 266..571. **Its centre is x ≈ 418, not the canvas centre 333.** A
> bottom-centre panel of any useful width is inside the movement control, and bottom-right is the
> jump button.

- **Scrap stays at the bottom** — centred in the *free band*, solved at runtime from Roblox's live
  rectangles (`Layout.freeBottomSpan`), not from the numbers above. An earlier draft moved it to a
  top-left column; that was an unnecessary retreat and was reverted.
- **Upgrade moves to the top right on touch**, well clear of jump.
- **The modal sets `UserInputService.ModalEnabled`**, which switches Roblox's controls off entirely
  (`TouchGui.Enabled` measured `false`). There is no position that both fits a panel and clears the
  controls; hiding them is the supported answer. Verified in a **real Play script**, not the command
  bar — the command bar is privileged and would have proved nothing ([PITFALLS #18](../../docs/PITFALLS.md#18-the-command-bar-is-privileged)).

Recorded in [`docs/game/ui-direction.md`](../../docs/game/ui-direction.md), not silently diverged.

---

## Six defects, and what found each one

**Every one was in code I had just written and believed was correct.** Three were found by the audit
I shipped, two by looking at a screenshot, one by attacking my own remote.

| # | Defect | Found by |
|---|---|---|
| 1 | The metrics `ScreenGui` was `Enabled = false` and reported **800 × 600 forever**. Every element was sized against a canvas 2.4× too tall | A probe that printed the canvas *and* the viewport, so the two could disagree |
| 2 | `layout clean -- reserved=0 rects` logged during startup: a collision check against **nothing** | Reading my own log line and noticing it could not fail |
| 3 | `Scrap.Value` had no `Size`, rendered **0 × 0**. The panel showed `SCRAP`, an empty bar, and no number | **One screenshot.** Every rectangle check passed |
| 4 | `TextScaled` forces `TextWrapped`, so `▲ UPGRADE` split across two lines | The same screenshot |
| 5 | `UISizeConstraint.MinSize` (58 px) silently overrode a computed 47 px row height; two of four upgrade tracks sat below the fold | Reading `AbsoluteSize` **back** after writing `Size` |
| 6 | `Layout.reserved()` used one `Visible` flag, so hidden-by-ancestor controls counted; all four rows were flagged against a control that was not drawn | The audit firing — a false positive, which is itself a defect |

Written up as [PITFALLS #55–#58](../../docs/PITFALLS.md#55-a-disabled-screengui-reports-800--600-forever).

Three of the six are the same shape: **a measurement that returned a confident default, and a check
that passed because it was measuring nothing.** That is the pattern this repo keeps paying for —
it is [#2](../../docs/PITFALLS.md#2-a-verification-that-could-not-fail) and [#54](../../docs/PITFALLS.md#54-measuring-the-device-during-the-loading-screen) again, in a new costume.

### The audit now ships

`auditLayout` runs in the shipped client on every canvas change and every panel open. It:

- **refuses to report clean** when the canvas is not laid out, and says `COLLISIONS NOT CHECKED
  (no reserved rects)` rather than `clean` when it has nothing to compare against;
- prints reserved rects **by name and rectangle**, because `reserved=0` and `reserved=3` look equally
  healthy in a log;
- separates the two checks, since a tap-size check needs only a canvas while a collision check needs
  Roblox's rects — conflating them silently dropped tap checks exactly where the tappable rows were;
- checks **every** `GuiButton` including transparent ones, and every on-screen text element for
  `AbsoluteSize > 0` and `TextFits`.

Reading with the panel **closed** — three persistent elements, against Roblox's five live rects:

```
layout verified: 3 element(s) vs 5 reserved rect(s) -- canvas 666x316 | viewport 666x374 |
inset 58 | touch=true | tap=56px | ready=true | reserved: JumpButton[571..641,226..296]
DynamicThumbstickFrame[-100..266,105..416] DynamicThumbstickUIModifier[-100..266,105..416]
ThumbstickStart[29..103,223..297] ThumbstickEnd[48..84,242..278]
```

And with the panel **open** — eight elements, and the audit correctly refusing to claim a collision
check it cannot make, because `ModalEnabled` has taken Roblox's controls off the screen:

```
layout: 8 element(s) clear the tap floor; COLLISIONS NOT CHECKED (no reserved rects) --
canvas 666x316 | ... ready=false (touch device but TouchGui has no rects yet ...)
```

> ⚠️ **An earlier draft of this file printed the first block under the caption "with the panel open
> and all four rows on screen". That caption was wrong** and the independent review caught it: with
> the panel open the count is 8, not 3, and the collision line reads `COLLISIONS NOT CHECKED`. The
> reading was real; the state I attributed it to was not. That is the shared `mobile` skill's §4a.9
> — *measure in the state the problem was reported in* — committed in the write-up rather than in
> the code. The row geometry was separately verified by direct measurement (all four rows at 47 px,
> `visible`, none clipped), which is what actually supports the claim.

---

## Verified in Play, with eyes as well as numbers

Nine states, each screenshotted and read, not just measured:

| State | What the screen showed |
|---|---|
| Idle | Coins 12,450 · SCRAP 0/30 · UPGRADE. Clear of both thumbs |
| Sweeping | Coins counting up, SCRAP 47/54, bar tracking |
| Flow ×3 | `MAGNET FLOW ×3` top-centre, bar 64 % |
| MAGNET RUSH | Gold title, full gold bar, the Rush vignette on the world |
| SCRAP FULL | Title, number, and bar all red; magnet visibly stopped |
| **HUD hidden** | see below |
| Upgrade panel | Four tracks, all fully visible, Roblox's controls hidden |
| Purchase | Coins 12,450 → 12,415 (exactly the quoted 35), CAPACITY 30→32 became 32→33, price 35 → 38 |
| Banner | `OVERCHARGE` in violet, centred at 26 % height, over a red SCRAP FULL panel |

**The Flow ladder climbed ×1 → ×2 → ×3 → ×4 → RUSH without skipping a tier**, held RUSH for exactly
8.0 s, and then **hid itself** — which independently re-confirms that job 010's latching Rush
(the client holding `rush = true` forever) is still fixed.

### Decision 0018 holds — checked, not assumed

`dev("hud.hide")` exists for exactly this. With the HUD switched off entirely, the magnet was filled
to 30/30 and then measured:

```
scrap.stats -> live=177 react=177 pull=0 ...
scrap.why   -> asked=33 granted=23 turned away=30.3% | ... FULL=1
```

**177 objects rattling in REACT, zero in PULL.** That is decision 0018's sentence — *the pull visibly
stops while everything in range still rattles* — as a measurement. The HUD is a second voice, not the
signal. The screenshot shows scrap lying on the ground around a player with no UI at all.

> 🔴 **The tool was weaker than I described it, and the review caught that too.** `dev("hud.hide")`
> set `Enabled = false` on the **Hud** ScreenGui only. The banner is a *separate* ScreenGui, so
> `SCRAP FULL` in 64 px capitals was still free to fire across the middle of a "hidden" HUD. That
> does not merely weaken the experiment, it inverts it: it could no longer distinguish *the magnet
> taught me* from *the banner told me*, which is the exact distinction decision 0018 is about.
>
> The conclusion survives, because the evidence above is **behavioural and server-side**
> (`react=177 pull=0`) and the screenshot shows no banner. But the conclusion survived by luck of
> timing rather than by design. `Banner.setEnabled` now goes down with the HUD, so the next person
> to run this check is running the check they think they are running.

### The upgrade remote, attacked rather than trusted

| Sent | Result |
|---|---|
| `"arena"` (unknown track) | rejected — `unknown track` |
| `12345` (a number) | rejected — `track must be a string` |
| `{ track = "power", cost = 0 }` | rejected — `track must be a string` |
| `"power", 0` (a client-supplied price) | **the extra argument was ignored**; the server recomputed 50 and charged it |
| `"power"` with 0 coins | rejected — `need 87679 coins` |

That fourth row is the one that matters: a client naming its own price changes nothing, because the
server never reads one (decision 0007).

---

## The independent review — 13 findings, 11 real

Run per [GROUND-RULES 8](../../../roblox.workspace/GROUND-RULES.md), given the requirement and the
repo and **never my theory**. It found more than my own verification did, and two of its findings
were errors in *this document* rather than in the code.

### The two that would have shipped a broken HUD

**🔴 The scrap readout was re-centred onto the thumbstick after every panel open.** A five-step
chain I did not see: opening the panel sets `ModalEnabled`, which makes `TouchGui.Enabled` false, so
`reserved()` correctly returns nothing → `freeBottomSpan` read "no obstacles" as "the whole width is
free" → the readout was re-centred on **x 333, the exact number this module exists to avoid** →
closing the panel restored the controls but *nothing re-ran the layout*, so it stayed 23 px inside
`DynamicThumbstickFrame` for the rest of the session.

My own audit **would have logged it** and nothing would have fixed it. Two fixes: `reservedForLayout`
distinguishes *what is painted now* (an audit's question) from *where the controls are* (a layout's
question, and a temporarily hidden control has not moved), and `freeBottomSpan` now returns a `known`
flag that a caller cannot ignore. Re-measured after: `x 328..507` before opening, `x 328..507` after
open-and-close, `overlaps a thumbstick rect: NO`.

**🔴 `dev("hud.hide")` did not hide the banner**, so the decision-0018 check was weaker than I
described it. See the correction in that section above.

### The rest

| # | Finding | Fix |
|---|---|---|
| 2 | **`Theme.audit()` could not fail.** `Font.new` stores the family string verbatim, so `Family == ""` is never true — the check returned empty for every input, *in the file whose header is about silent font substitution* | Verified in Studio: a bogus family constructs, applies, and reports itself back — **Roblox gives no runtime signal at all**. Now checked against a `VERIFIED_FAMILIES` list, which fails on a typo and says plainly what it cannot detect |
| 7 | `math.max(80, width)` **defeated** the `band > 40` guard: any band of 41–96 px got an 80 px panel centred in it, overhanging the reserved rects both sides | The guard and the floor are now the same number |
| 8 | The purchase banner **covered the row just tapped** (banner y 62..103, row 1 y 83..130) — and the audit could never see it, because it walked one ScreenGui | Confirmations moved into the panel header; the audit now walks **both** ScreenGuis |
| 9 | A row tap was **silently swallowed** while a background re-quote was in flight — the button played its press tween and nothing happened. And an unguarded `InvokeServer` throw would latch the panel dead for the session | Purchases are never gated on a quote; the invoke is `pcall`ed |
| 10 | The purchase confirmation ignored `decimals`: `MAGNETIC DRIVE -> 17.200000000000003` in a 64 px display banner | Formatted to the track's own precision. Re-measured: `MAGNETIC DRIVE -> 16.8`, `PULL RADIUS -> 12.4` |
| 6 | `WATCHED.Flow` **looked like coverage and delivered none** — the panel is only visible during a combo, and every layout event happened while it was hidden | Audited on the visibility edge |
| 11 | `MouseLeave` is not multi-touch capable (`mobile` §7) — a second finger sliding off a button would leave it visually pressed forever | Service-level `InputEnded`, filtered to this button's own `InputObject`s |
| 12 | A comment asserted the punch "requires" a central anchor; **neither call site has one** | Comment corrected to describe what the code does |
| 13 | Two hardcoded hexes inside RichText, duplicating `Theme` tokens — the one place a token cannot be passed as a `Color3` | Built from `Theme.color.*:ToHex()` |
| 14 | Minor: the counter list grew forever · a dead `if not ev` guard on a function that errors · `magnet.stats` printed `radius=12` for 12.4 · a fractional Arena `holdSeconds` | All fixed |

**Security: nothing found.** The reviewer attacked the upgrade path independently and reached the
same conclusion my own probing did — no cost, level or stat crosses the wire, the price is recomputed
from the server's own level, and there is no yield between the affordability check and the deduction.

It also raised a **self-inflicted** rate-limit risk I had not considered: quotes and purchases share
the `Economy` bucket, so a HUD re-quoting twice a second during a Rush could get the player's real
purchase refused. `QUOTE_THROTTLE` is now 1.5 s — a price one second stale costs nothing; a refused
purchase costs the sale.

### The one I disproved

The reviewer flagged `("tap=%dpx"):format(56.88)` as a runtime throw that would kill the audit — and
noted, correctly, that my own quoted log line reading `tap=56px` could not coexist with that. It
asked to have it verified rather than assumed. **Measured: Luau's `%d` truncates, it does not throw**
(`string.format("%d", 56.88)` → `"56"`). Finding void, and the reviewer had said which evidence would
void it. It did surface a real cosmetic bug next door, though — `magnet.stats` was truncating
`radius=12.4` to `radius=12` in the very command used to verify an upgrade.

---

## What is **not** verified

🔴 **The desktop layout.** `Layout.isTouch()` selects between two arrangements and only the touch one
has been exercised. Studio's Device Emulator is a UI toggle with **no scripting API** — probed
`StudioService`, `settings():GetService("Studio")`, `RunService` and `UserInputService`, and none of
them expose it — so I cannot turn it off from here. The desktop branch is the easier case (no reserved
rects, more room) and is built from the same measured primitives, but *built from good parts* is not
*verified*, and this repo's own [#31](../../docs/PITFALLS.md#31-implemented-is-not-verified) says so.
**One click in Studio (Test → Device → off) and a Play session would settle it.**

⚠️ **Counter punch behaviour during a Rush** is rate-limited to one punch per 0.18 s against a ~0.25 s
grant tick, so the number should not vibrate. That is reasoning, not a measurement — a still frame
cannot show it.

---

## Scope: one deliberate bleed from group 05

The intake asked for an upgrade button. `RequestUpgrade` existed as a remote with **no handler**, so a
button would have been a dead control — forbidden by ground rule 10 and [#24](../../docs/PITFALLS.md#24-placeholders-are-worse-than-empty-slots)/[#29](../../docs/PITFALLS.md#29-shipping-something-nothing-else-knows-about). Put through the wizard at intake; the
answer was **wire it for real**.

So `MagnetState.upgrade`/`quotes` and the `RequestUpgrade` binding are group 05 work done early.
**Group 05's Magnet Lab is now "put a physical bench around an existing, tested transaction"** rather
than building it from nothing. Coins buy something for the first time.

Two notes on how it was built:

- **One remote does quote *and* buy**, so the price shown is the price charged. Two calls could drift,
  and the player would read that as being overcharged.
- **`MagnetState.TRACKS` asserts against `LEVEL_KEYS` at load.** A track missing from `LEVEL_KEYS` is a
  stat the player buys and loses on rejoin — it would look like a save bug and would not be one
  ([#52](../../docs/PITFALLS.md#52-a-threshold-chosen-in-one-file-against-values-chosen-in-another)).

## Three fixes to existing code, found on the way

1. **`RemoteBinder.bindFunction` truncated every handler to two return values.** `local ok, a, b =
   pcall(...)` silently dropped the third, with no error on either side. It affected every
   `RemoteFunction` in the game, not just this one. Now `table.pack`/`table.unpack`.
2. **`MagnetState.addCoins` allowed a negative balance.** `dev("magnet.coins", -99999)` drove a live
   balance to −87,629 and the panel then correctly but absurdly quoted "need 87,679 coins". Clamped at
   zero, and it logs when it clamps.
3. **A leaked Python artifact — `--- """ + W + """ SERVER-SIDE numbers` — sat in a `Bootstrap` comment**,
   left by a generator.

Plus one leak avoided: `Components.button` registers a `Layout.observe` callback, and destroying the
button does not remove it. The upgrade rows would have churned four buttons per `StatsChanged` while
open. Rows are now built once and updated in place, *and* the observer disconnects on `Destroying`.

## Waiting on you

| # | What | Why it needs you |
|---:|---|---|
| 1 | **`UI.Press` — a button click sound.** `assets/registry/sounds.md` | Every button in the game is silent until this lands, and style §7 says silence reads as broken. Announced at every startup as `AUDIO: 1 slot(s) have no asset yet -- UI.Press`. Spec: *a short, dry, positive click — a physical switch on a machine panel*; **no** musical note, cartoon boop, or reverb tail, because it fires on every tap in the game |
| 2 | **One desktop Play session** — Test → Device → off | The only unverified half of this job |
| 3 | **Commit** | Claude never commits |

## Verification tooling added

`tools/luau-analyze.sh`, ported from The Last Tide. **This repo had no static analysis.** It runs
luau-lsp's analyzer over `studio_game/` in about a second without Studio, and it caught a genuine
syntax error in a helper I had written during this job — the kind of thing that otherwise fails at
`require` time inside a Play session, which is the slowest possible way to learn about it.
