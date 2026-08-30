# Planned: the magnet must be visible to other players

**Project**: `roblox.magnet-sweep`
**Raised by**: job #007 review
**Size**: small, but it changes ownership of the rig

## The problem

`MagnetController` builds the magnet rig on the client, in `LocalPlayer`'s character. So **no
player can see anyone else's magnet.** Everyone is walking around empty-handed while scrap flies
into their fist.

That matters more here than in most games: the red-and-cyan magnet *is* the logo, the icon and the
Arena Core. It is the game's single strongest visual identity, and right now it only ever appears
on the screen of the person holding it — including in every screenshot a player takes of a friend.

## Why it was not done in #007

Job #007's scope was the pull system: states, pool, cap, grant. Fixing this moves who owns the rig
(server-built and replicated, or an accessory/tool), which touches character setup, respawn, and
later the magnet-skin purchase path — a different piece of work with its own failure modes.

It is also not a bug in anything #007 built: the rig was always client-side.

## What the job should decide

- Server-built rig welded on `CharacterAdded`, or a `Tool`/`Accessory`?
- Where the tip lives, given the server already needs `Magnet.TIP_OFFSET` for its grant range —
  a server-built rig means the server can measure from the **tip** rather than the root, which
  would let `grantRange()` tighten from 9.1 studs to roughly 6.5.
- How magnet skins (decision 0011: Robux never buys Arena power — cosmetics are fine) attach.

## Check it is actually fixed

Two clients in one Play session; each must see the other's magnet, and it must survive a respawn.
Not verifiable from a single-player session or from the editor.
