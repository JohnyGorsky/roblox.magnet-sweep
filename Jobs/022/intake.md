# Job #022: Automatic base claiming and lit owner nameplates

**Project**: `roblox.magnet-sweep`
**Created**: 2026-09-06 15:14:03
**Status**: ✅ Completed 2026-09-06

## Requirements / goal

Automatic base claiming, plus a lit nameplate on the wall above each base showing that player's circular avatar, display name and @username -- so anyone in the room can see at a glance who owns which bay.

The owner's words: "when user claims spot (Automaticly), then on the wall we must draw in circle avatar name and user name, so you know what user have what place, so it like lights up".

BLOCKER FOUND BEFORE PLANNING: nothing claims a base today. A grep of studio_game/ finds no claim/assign/owner logic at all -- the only "Claim" in the codebase is ClaimScrap, which is scrap collection. Config/WorkshopLayout.luau:217 says it outright: "Nothing claims a base yet, so all twelve are dormant", and BASES.DORMANT = true. So this job is TWO systems, not one, and the nameplate is the smaller half.

SCOPE:
1. BaseClaimService, server-authoritative. Assign a free bay on PlayerAdded, release it on PlayerRemoving. The server owns the mapping; a client may never assert which bay is its own (non-negotiable 2, decision 0007). Stamp the owning UserId as an attribute on the base model so anything else can read it without a second source of truth.
2. The nameplate itself: a circular headshot, DisplayName and @Name, on the wall above that bay, dark when unclaimed and lit when claimed. Built from the existing signage language in the style skill section 5 -- dark slate housing, chamfered chrome bezel, Neon text panel, matching PointLight, hazard stripe plinth. Circle via UICorner at 0.5 scale on a square ImageLabel.
3. Wake the bay on claim. docs/systems/player-base says an unclaimed base is "unlit, powered down", and job 020 built all of them dormant. Claiming is what turns a bay on -- so the nameplate lighting up and the bay lighting up are the same event, not two.

WHAT THE OWNER MUST DECIDE (wizard, before any code):
- Does a returning player get the SAME bay, or any free one? Same-bay needs a DataStore and interacts with whatever the smelter is holding.
- What happens when players outnumber bays? There are 10 bays and MaxPlayers should be 10, but finding 0006 records MaxPlayers reading 60 in the live session and still needing a human to set it on the Creator Hub. At 60 players and 10 bays, 50 people have no bay and the nameplate system has no answer.
- Nameplate size and where exactly on the wall -- above the bay's crane, or on the new backdrop collar built in job 021.

KNOWN TECHNICAL RISKS, so the plan does not rediscover them:
- Players:GetUserThumbnailAsync yields and can fail or throttle. It must be pcall'd with a visible fallback, and never called on the client for another player.
- The nameplate is 10x on screen at once. Job 021 measured that decorative PointLights are clamped to 10-stud range on the Low tier (QualityController.local.luau:123-131), so a nameplate that reads only because of light spill will be invisible on a phone. It must read from Neon plus Bloom.
- The room is already at 3,614 parts against MAX_PARTS_IN_VIEW 1800. Ten nameplates must be cheap.
- Workspace does not sync. Any hand-placed nameplate geometry lives only in the .rbxl unless it is generated at runtime or exported per decision 0019. Generating these at runtime from the base list is probably right, precisely because they are data-driven rather than hero geometry.
- StarterGui/Workspace do not sync; SurfaceGui parented into Workspace must be created by a script or hand-placed.

VERIFY: two clients in Studio Team Test, not one. A claim system with one player cannot show the bug where two players race for the same bay, and cannot show that player A sees player B's plate correctly.

## What the job actually became

The intake scoped two systems. Each one turned out to be load-bearing for the next, and the owner
extended the scope twice in-flight (the starter robot + DataStore persistence, then the robot
builder). Delivered: `BaseClaimService`, `BaseNameplate`, `RobotSpawner`, `PlayerProfile`,
`Config/StarterRobot`, `Config/PartArt`, `RobotService` + `RobotBuild`.

The three intake questions were answered by the owner: **any free bay** (not the same one), a
**distinct rusty starter set** (not real catalog parts), and **DataStore persistence now**. The
nameplates went at r=266.5, y=76 on the job 021 backdrop collar, not above the crane -- moved up at
the owner's request to the empty wall.

## Checklist

- [x] Requirements reviewed (this intake)
- [x] **Independent reviewer agent run** - given the symptom/requirement, NOT my theory (GROUND-RULES 8)
- [x] **Symptom reproduced in PLAY**, at the player's camera, before any fix (GROUND-RULES 7) --
      the blocker was measured, not assumed: all 10 bays sat `Claimed = false` with nothing to set it
- [x] Implementation plan created & agreed -- [`implementation-plan.md`](implementation-plan.md),
      six build logs
- [x] Implementation completed
- [x] **Proof it works better** captured - before/after from the same camera, in Play.
      Persistence proved by round trip (same `createdAt` across a restart); the lock release proved
      by reading the DataStore key `table` -> `nil`; all seven install refusals exercised.
- [x] Final summary + changelog written

## ⚠️ The one checklist item that is NOT satisfied

The intake's own **VERIFY** line says: *"two clients in Studio Team Test, not one."* That has never
been run. One client cannot show two players racing for a bay, cannot show player A seeing player B's
plate, and cannot show the 180-second cross-server lock case that job 022's own lock-release fix is
about. It needs the owner to start a Team Test. Recorded in the final summary as the job's biggest
gap rather than quietly ticked.
