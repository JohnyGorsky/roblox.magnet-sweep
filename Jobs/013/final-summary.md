# Job #013 — final summary

**Project**: `roblox.magnet-sweep`
**Status**: the Workshop's stations work. The two with real economies are wired and verified in Play;
the five waiting on later groups say so.

Build group 05's behaviour half. Job 012 built the room and every station in it was scenery —
walking up to the Recycler did nothing.

---

## What was built

| | |
|---|---|
| `ServerScriptService/StationService.luau` | The prompts and the two transactions. Finds stations by the `StationId` attribute the builder stamps |
| `StarterPlayerScripts/StationController.local.luau` | Handles prompt triggers and owns the Recycler screen |
| `ReplicatedStorage/Ui/Screens.luau` | A client register of openable screens — the only way one system opens another's |
| `Bootstrap.server.luau` | Binds `RequestRecycle` and `RequestRepair`; re-attaches prompts after `workshop.rebuild` |
| `Hud.local.luau` | Registers the job-011 upgrade panel under the name `Upgrade` |

## The upgrade panel is REUSED, not rebuilt

The Magnet Lab terminal has to open the upgrade panel. That panel lives inside `Hud.local.luau`, and
job 011 measured it, screenshotted every state and attacked its remote. **A second implementation
would be a second thing to keep correct, and the first time the two disagreed the player would be
looking at one price and paying another.**

So the HUD *registers* its panel and the station *asks for it by name*. `Ui.Screens` is the whole
mechanism — no script reaches into another, and nothing is duplicated. Verified by pressing E at the
Magnet Lab and reading the panel that opened: it is `Hud.UpgradePanel`, populated with live
server-quoted prices.

That relies on a real Roblox fact worth writing down: **every LocalScript on a client shares one Luau
VM**, so `require` returns the same table to all of them. It is *not* true across the client/server
boundary, and not true of `execute_luau` — see the verification note below.

## Prompts are client-handled; only money crosses the wire

`ProximityPromptService.PromptTriggered` fires locally, so opening a screen needs **no remote at
all**. The server never sends "open a window"; it owns money, the client owns windows. The remote
surface stays exactly as small as `Remotes.SPECS` says it is.

The station is identified by the `StationId` attribute the server stamped **on the prompt**. Nothing
on the client knows where a station is — which matters because the Workshop is regenerated from a
spec and every position in it moved twice during job 012 alone.

## The Recycler asks the question the economy is built on

`docs/systems/economy` and `Economy.previewChoice` are explicit: the game's single economic question
is *do I spend this scrap on myself, or on keeping my robot alive?* A screen that shows one exit at a
time, or highlights a "recommended" one, is not asking it.

So both exits are **the same size, side by side, and neither is pre-selected**. Measured in Play with
80 scrap carried:

| | |
|---|---|
| RECYCLE | 🪙 **1,920** (80 × 24, spec §48 exact) |
| REPAIR ROBOT — NO ROBOT YET | **+480 HP** (80 × 6, spec §48 exact) |

Pressing RECYCLE returned `+1920 COINS`, the magnet emptied, and the server's balance went to 2,012 —
the HUD followed on the same push.

**The repair exit is greyed and labelled, not hidden.** There is no robot until group 09. Hiding it
would hide the choice the entire economy is built around; faking it would be a placeholder (ground
rule 10). Tapping it spends no remote call at all — invoking `RequestRepair` to be told "no" would
burn a rate-limit token to learn what the screen already knows.

`RequestRepair` **is** bound anyway, and refuses with a reason. A prompt pointing at an unbound remote
is a control that does nothing with no explanation, which is what [#29](../../docs/PITFALLS.md#29-shipping-something-nothing-else-knows-about)
and [#34](../../docs/PITFALLS.md#34-a-live-listing-that-grants-nothing) are both about. Bound and
refusing is a different thing from absent.

## Verified in Play

| Check | Result |
|---|---|
| Prompts | **7 of 7**, each with the right `StationId`, action and object text |
| Magnet Lab → E | Opens `Hud.UpgradePanel` with live prices; `ModalEnabled` true |
| Recycler → E | Opens the Recycler screen; the upgrade panel closed itself |
| RECYCLE pressed | `+1920 COINS`, magnet emptied, server balance 92 → 2,012, HUD followed |
| Repair → E | Banner: `NO ROBOT TO REPAIR YET — GROUP 09` |
| Server preview | scrap 78 → 1,872 coins / 468 HP — both exact against §48 |

### Two verification notes worth keeping

**`screen_capture` cannot render `ProximityPrompt` bubbles** ([#20](../../docs/PITFALLS.md#20-screencapture-cannot-show-prompts-and-a-timeout-means-nothing-is-drawing)).
A screenshot with no prompt visible is not evidence of a missing prompt. Every prompt here was
verified by reading the instances and by pressing the key.

🔴 **One of my checks was vacuous and said so.** I asked `execute_luau` to print
`Screens.names()` — it returned **empty**, because `execute_luau` runs in a separate Luau context
and built its own copy of the module with an empty registry ([#16](../../docs/PITFALLS.md#16-executeluau-runs-in-a-separate-luau-context)).
The registration was fine; the check could not see it. The honest verification was to trigger the
prompt and read `Hud.UpgradePanel.Visible`, which is a shared Instance.

## Defects found while building

| | Found by |
|---|---|
| `StationService.BEHAVIOUR: { ... } = { ... }` — **a type annotation on a table FIELD is a Luau syntax error**, and it reads exactly like the legal local-declaration form. This is [PITFALLS #47](../../docs/PITFALLS.md#47-a-type-annotation-on-a-table-field-is-a-syntax-error-and-it-looks-fine), documented after it cost an earlier job, and I wrote it anyway | The analyzer, before any playtest |
| `workshop.rebuild` had **two `return` statements**, the second unreachable, after I patched it | The analyzer |
| A rebuild **destroys the station folders**, taking the prompts with them — the dev command left a room that looked right and could not be used | Reasoning about the rebuild path; now re-attaches, and reports how many |
| Triggering a "not yet" station **left the previous station's modal open** behind the banner — `closeAll()` only ran on the branch that opens something | Pressing E at Repair while the Recycler was open, and reading both |
| The Recycler panel took 72 % of the canvas and stretched two buttons to fill it; capping them moved the same dead space next to CLOSE | Two screenshots. The panel is now sized by **adding up its content** |

## The independent review found a double mint, and it was the serious one

Run per [GROUND-RULES 8](../../../roblox.workspace/GROUND-RULES.md) on the requirement alone.

### 🔴 The same scrap was paid for twice

`MagnetState.collect` had been doing `e.coins += banked * COIN_MULTIPLIER` on every pickup since job
008. `StationService.recycle` then paid `scrap × 24` for **that same scrap**. Spec §48's exact
worked example — 150 scrap → 3,600 Coins — came out as **3,750**.

It was invisible until this job: the pickup grant was the *only* Coin path while the Recycler did not
exist, so it looked like the design. `docs/systems/economy`'s currency table is unambiguous that
Coins come from recycling, so the pickup grant was the undocumented one.

**The second-order damage was worse than the 4 %.** Flow's multiplier was applied to that pickup
grant — so a MAGNET RUSH, the game's headline reward, was multiplying about a *twenty-fifth* of the
payout. The whole Flow reward curve was attached to the wrong quantity.

Fixed: `collect` mints no Coins, and the multiplier now scales the **scrap** a pickup is worth
(clamped to headroom afterwards, so a Rush fills the magnet faster and sends you to the Recycler
sooner). `COIN_MULTIPLIER` → `FLOW_MULTIPLIER`, because a constant whose name says one quantity while
it scales another is how a table becomes a lie.

⚠️ **Where Flow's bonus lands is a balance judgement I made alone**, so it is logged as
[finding 0002](../../findings/0002-magnet-flow-now-multiplies-scrap-not-coi.md) rather than buried
in a diff. `Economy.TUNED` is still false and nothing here has been played for feel.

### 🔴 Anyone could cash out from anywhere

`RequestRecycle` had **no server-side proximity check**. The only thing tying recycling to the
Recycler was `PromptTriggered` firing in a **LocalScript** — a claim, not a fact. A modified client
could `InvokeServer(true)` from across the map.

That is not cosmetic: **`Capacity` is a paid upgrade whose entire value is how far you can sweep
before walking back.** Remote recycling empties the magnet on demand, so Capacity buys nothing and
the return trip — the loop's only risk window — disappears. `ScrapService` already does exactly this
check for collection claims, forty lines away; the precedent existed and I had not applied it.

Measured after the fix:

```
recycle from (200, 20, 200)  -> ok=false  "TOO FAR FROM THE RECYCLER"   scrap untouched (78)
recycle at the station       -> ok=true   "+1920 COINS"                 80 scrap -> 0, coins 0 -> 1920
```

### The rest

| Finding | What it caught | Fix |
|---|---|---|
| **Rebuild left the room unusable** | `workshop.rebuild` returned early on *any* non-fatal problem, skipping the prompt re-attach — so all seven stations came back with **zero prompts** while the reply talked only about the sign. The guard I added to fix a silent-success bug created the next one | Re-attach first, decide what to say second |
| **The RECYCLE tap was swallowed** | One `busy` flag gated the preview *and* the purchase. Tapping RECYCLE during the opening round trip gave the press tween, the press sound, and nothing else. **This is the identical bug job 011 found in `refreshQuotes`, post-mortem and all — I re-implemented the broken version** | A commit is never gated on a preview |
| **Two modals were still reachable** | The station handler called `closeAll`; the HUD's own UPGRADE button did not. Open the Recycler, tap UPGRADE, close it — and `ModalEnabled` went false with the Recycler still open, handing Roblox's touch controls back *underneath* an open modal. Verbatim the failure the comment claimed to have fixed, covering one of two entry points | `toggleUpgrade` closes everything first |
| **The panel could show the last visit's numbers** | Only `status` was cleared on open. If the preview was rate-limited — the `Economy` bucket is shared with `RequestUpgrade` — the panel opened with the previous visit's figures under a live RECYCLE button, or on a first open with two blank exits | All fields cleared to a reading state |
| **`NOT_YET` was a second copy and had already drifted** | The client kept its own copies of the screen names and the "not yet" strings, described as "mirrors `StationService.BEHAVIOUR`". They did not mirror it, nothing enforced it, and two of five entries already disagreed. `Behaviour.screen` and `.notYet` were **dead fields** describing a contract the wire did not carry | Both now travel **on the prompt** as attributes. One source; a new station needs no client change |
| **The repair exit ignored the server's own flag** | `repairable` was computed, shipped and read for colours — but the button hardcoded its refusal. The day group 09 flips the flag, the panel would draw a live exit that still printed "no robot yet" | Reads the flag; the button is genuinely disabled until then |
| **"Disabled" buttons were not disabled** | Greyed only — they still played the press tween and sound, and at zero scrap the greyed RECYCLE fired a real `InvokeServer` to be told "NOTHING TO RECYCLE" | `Interactable`/`Active` set |
| **HUD hidden + Magnet Lab = a trap** | Pressing E while `hud.hide` was on opened the panel inside a *disabled* ScreenGui with `ModalEnabled = true`: on a phone, no thumbstick, no jump, nothing on screen, and the CLOSE button unreachable | Refuses to open while hidden |
| **A bare count with no denominator** | `stations: 5 prompt(s) attached` and `7` look equally healthy. This file complains about exactly that for part counts twenty lines earlier | Reports `n/total` and errors when short |

**Clean, per the review:** stations found by attribute with no coordinate anywhere; the upgrade panel
genuinely reused; no client-supplied value crosses the wire; rate limiting structurally applied; no
yield inside `recycle`'s read-modify-write; no connection or instance leaks.

## Scope

Untouched: the Robot Bay's contents (group 09), the Part Archive's data, zone 1 behind the Factory
Entrance (group 07), and the Arena (group 10). Each of those stations names its dependency out loud
rather than being a prompt that appears broken.

The **MOVE NEAR SCRAP first-time prompt** named in the intake is **not built** — it belongs with the
boot/onboarding half of group 06 (the loading screen and `ReplicatedFirst` handoff), which is still
its own job, and putting a first-run tutorial cue in before the loading screen exists would mean
building the "have they played before?" state twice.
