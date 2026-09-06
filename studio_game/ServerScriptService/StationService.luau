--!strict
--[[
	StationService — makes the Workshop's seven stations do something.

	Job 012 built the room; every station in it was scenery. This attaches a `ProximityPrompt` to
	each one and owns the transactions behind the two that have real economies.

	🔴 FOUND BY ATTRIBUTE, NEVER BY POSITION.

	The Workshop is PLACED BY HAND in the editor (job 020, decision 0019) and every position in it
	is provisional — the whole room is expected to be nudged, and the radii in particular were
	built to be walked and then changed. So a station is found by its `StationId` attribute, which
	survives being moved, and never by coordinate or by name. Anything here that hunted for a
	station by position would break the first time someone dragged it three studs, silently, and
	look like a prompt bug.

	The room has TWO kinds of station — shared buildings in `Hub.Common.Fixtures` and one smelter
	per player in `Hub.Bases.<n>.Fixtures`. See `collectStations`.

	⚠️ **`screen_capture` cannot render `ProximityPrompt` bubbles** (PITFALLS #20). A screenshot
	showing no prompt is not evidence there is no prompt. Verify by reading
	`PlayerGui.ProximityPrompts`, or by triggering it.

	Sources: docs/build/05-workshop.md · decision 0007 (the server owns currency) · spec §48
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local Economy = require(Config:WaitForChild("Economy", 20))
local Log = require(ReplicatedStorage:WaitForChild("Log", 20)).scope("Stations")

local MagnetState = require(script.Parent:WaitForChild("MagnetState", 20))

local StationService = {}

--- What each station's prompt says and does.
---
--- `screen` names a client screen (see `Ui.Screens`). `nil` means the station has no screen yet --
--- and the client says so out loud rather than opening nothing, because a prompt that appears to
--- do nothing is indistinguishable from a broken one.
export type Behaviour = {
	actionText: string,
	objectText: string,
	screen: string?,
	--- Said by the client when there is no screen. Names what is missing and when it lands.
	notYet: string?,
	--- The zone TIER this station sends the player to, if it is a way into the factory.
	--- ⚠️ A tier number, not a zone id and certainly not an instance: the station must not know
	--- what zone 1 is called or where it is, only that it is the first one.
	enter: number?,
}

--- ⚠️ `= { ... } :: { ... }`, NOT `StationService.BEHAVIOUR: { ... } = { ... }`. A type annotation
--- on a table FIELD is a syntax error in Luau and it reads exactly like the local-declaration form
--- that is legal. Documented as PITFALLS #47 after it cost a job, and I wrote it anyway -- the
--- error surfaces at require time in whichever file required this one, not here.
StationService.BEHAVIOUR = {
	MagnetLab = {
		actionText = "UPGRADE",
		objectText = "MAGNET LAB",
		-- ⚠️ Opens the panel job 011 already built and attacked. It is NOT reimplemented here.
		screen = "Upgrade",
	},
	Recycler = {
		actionText = "RECYCLE",
		objectText = "RECYCLER",
		screen = "Recycle",
	},
	Repair = {
		actionText = "REPAIR",
		objectText = "REPAIR STATION",
		screen = nil,
		notYet = "NO ROBOT TO REPAIR YET — GROUP 09",
	},
	RobotBay = {
		actionText = "BUILD",
		objectText = "ROBOT BAY",
		--- 🔴 Opened in job 022. `RobotBuild.local.luau` registers this name; `RobotService` owns
		--- every decision behind it. The `notYet` is GONE rather than kept alongside a screen --
		--- the client prefers the screen, so a stale message would sit there unread and untrue.
		screen = "RobotBuild",
	},
	PartArchive = {
		actionText = "VIEW",
		objectText = "PART ARCHIVE",
		screen = nil,
		notYet = "NO PARTS DISCOVERED YET",
	},
	--- ⚠️ Kept, but it no longer stands in a base. Job 019 moved the way out to the ring's LANE
	--- SLOT -- the gap in the ring -- so this behaviour is attached to the lane mouth rather than
	--- to a station inside somebody's base. Entering the factory is not a thing you do at your own
	--- Recycler.
	FactoryEntrance = {
		actionText = "ENTER",
		objectText = "FACTORY ENTRANCE",
		screen = nil,
		--- 🔴 No `notYet` any more -- job 017 built the destination. `enter` below moves the player
		--- to zone 1's entry anchor via `ZoneManager`, which is the ONLY sanctioned way to reach a
		--- zone: a hardcoded `workspace.Zones.COLOR_WORKSHOP` path here would work today and become
		--- a nil index the moment a player is far enough away for the chunk to stream out.
		---
		--- ⚠️ If the zone failed to build, the prompt still answers -- with the reason. A station
		--- that says ENTER and does nothing is the placeholder-shaped hole this job removes.
		enter = 1,
	},
	ScrapArena = {
		actionText = "WATCH",
		objectText = "SCRAP ARENA",
		screen = nil,
		notYet = "THE ARENA IS BUILT IN GROUP 10",
	},
	--- ⚠️ Added in job 020 because the kiosk is now STANDING in the common ring while its economy
	--- is still P2 in `docs/build/05-workshop.md`. Without an entry here `attachPrompts` logs
	--- `station "Shop" has no behaviour defined` and the building is silent scenery — which is the
	--- placeholder-shaped hole non-negotiable #10 exists to prevent. It announces the gap instead.
	Shop = {
		actionText = "BROWSE",
		objectText = "SHOP KIOSK",
		screen = nil,
		notYet = "THE SHOP OPENS LATER — NOTHING TO SELL YET",
	},
	--- 🔴 The player's OWN smelter, one per base. Unlike every other id this one is per-player, so
	--- the prompt carries a `BaseIndex` and ownership is checked server-side before anything is
	--- granted. Dormant until the base is claimed, which nothing does yet.
	Smelter = {
		actionText = "INSPECT",
		objectText = "SMELTER",
		screen = nil,
		notYet = "BASE CLAIMING IS NOT BUILT YET",
	},
} :: { [string]: Behaviour }

--------------------------------------------------------------------------------
-- Attaching the prompts.
--------------------------------------------------------------------------------

local PROMPT_DISTANCE = 14

--- The part a prompt should hang on: the machine's glowing face, which is the thing the player is
--- looking at. Falls back to any part, so a station whose piece changed still gets a prompt.
local function promptHost(station: Instance): BasePart?
	--- ⚠️ The fixture IS the machine now. In the hall each station was a folder containing a
	--- `Station_Machine`; in a base the machine model is the fixture itself, so the glowing face is
	--- a direct descendant rather than a grandchild.
	for _, d in ipairs(station:GetDescendants()) do
		if d:IsA("BasePart") and d.Material == Enum.Material.Neon then
			return d
		end
	end
	for _, d in ipairs(station:GetDescendants()) do
		if d:IsA("BasePart") then
			return d
		end
	end
	return nil
end

--- Every fixture in the Workshop that carries a `StationId`, from BOTH halves of the room.
---
--- 🔴 THE ROOM HAS TWO KINDS OF STATION, and this is the whole reason this helper exists.
--- Job 019's per-base design was rejected: the owner's ground rule is that upgrade buildings are
--- COMMON and a player owns only their smelter. So job 020 built:
---
---   `Hub.Common.Fixtures.*`          — the seven shared buildings, no `BaseIndex`
---   `Hub.Bases.<1..12>.Fixtures.*`   — each player's own smelter, stamped with `BaseIndex`
---
--- Walking only `Bases` (as this did) finds the twelve smelters and NONE of the seven buildings,
--- so `RequestRecycle`, the Magnet Lab upgrade and `enterZone` all answer "station is not in the
--- world" while standing in front of the building.
---
--- ⚠️ Found by ATTRIBUTE, never by name or coordinate. Every position in the room is provisional
--- and expected to be nudged in the editor; a coordinate would be stale the first time it moved.
local function collectStations(): ({ Instance }, string?)
	local root = workspace:FindFirstChild("Hub")
	if not root then
		return {}, "the hub is not built"
	end
	local machines: { Instance } = {}
	local common = root:FindFirstChild("Common")
	local commonFixtures = common and common:FindFirstChild("Fixtures")
	if commonFixtures then
		for _, m in ipairs(commonFixtures:GetChildren()) do
			if m:GetAttribute("StationId") then
				table.insert(machines, m)
			end
		end
	end
	local bases = root:FindFirstChild("Bases")
	if bases then
		for _, base in ipairs(bases:GetChildren()) do
			local fixtures = base:FindFirstChild("Fixtures")
			if fixtures then
				for _, m in ipairs(fixtures:GetChildren()) do
					if m:GetAttribute("StationId") then
						table.insert(machines, m)
					end
				end
			end
		end
	end
	if #machines == 0 then
		return {}, "the hub is built but holds no station -- nothing carries a StationId"
	end
	return machines, nil
end

--- The shared buildings that must stand in the common ring, and how many bases the room has.
---
--- ⚠️ Deliberately a list HERE rather than a count derived from the world: a check that counts
--- what it finds can never fail. If a building is deleted in the editor, this is what notices.
--- `Smelter` is absent on purpose -- it is per-base and validated separately below.
local REQUIRED_COMMON = {
	"MagnetLab",
	"Recycler",
	"Repair",
	"RobotBay",
	"PartArchive",
	"ScrapArena",
	"FactoryEntrance",
	"Shop",
}
--- 🔴 TEN, not twelve — and this is a DESIGN CHANGE, not a tuning number.
---
--- The Workshop is a 12-gon and job 020 built one base per facet. The owner then gave **two facets
--- either side of the Factory Entrance over to the shared shops**, so the upgrade stations cluster
--- at the exit instead of ringing the room. That leaves ten player bases.
---
--- ⚠️ `docs/systems/places` and the decision index both say `MaxPlayers = 12`. Ten bases cannot
--- house twelve players. Either the cap drops to 10, or two bases go somewhere other than a facet.
--- Tracked in findings/0010 — do not "fix" this by quietly putting it back to 12.
local EXPECTED_BASES = 10

--- How many stations actually stand in the world right now.
---
--- ⚠️ Exists so the prompt count can be reported against a REAL denominator. Bootstrap used to
--- derive it from `HubSpec.FIXTURES * HubSpec.BASES` — a spec for a room that job 019 deleted, and
--- which now describes nothing that exists. "7/0 prompts attached" is not a health check.
function StationService.stationCount(): number
	local machines = collectStations()
	return #machines
end

--- Attach a prompt to every station the Workshop built. Returns (attached, problems).
---
--- Idempotent, like everything else that touches the regenerated room: an existing prompt is
--- replaced, so calling this after a `workshop.rebuild` is correct rather than additive.
function StationService.attachPrompts(): (number, { string })
	local problems = {}
	local machines, err = collectStations()
	if err then
		return 0, { err }
	end

	local n = 0
	local seen: { [string]: boolean } = {}
	local perBase: { [number]: number } = {}
	for _, station in ipairs(machines) do
		local id = station:GetAttribute("StationId")
		local baseIndex = station:GetAttribute("BaseIndex")
		if type(id) ~= "string" then
			table.insert(problems, ("%s has no StationId attribute -- the builder must stamp it"):format(station.Name))
			continue
		end
		seen[id] = true
		if type(baseIndex) == "number" then
			perBase[baseIndex] = (perBase[baseIndex] or 0) + 1
		end

		local behaviour = StationService.BEHAVIOUR[id]
		if not behaviour then
			table.insert(problems, ("station %q has no behaviour defined"):format(id))
			continue
		end

		local host = promptHost(station)
		if not host then
			table.insert(problems, ("station %q has no part to hang a prompt on"):format(id))
			continue
		end

		local existing = host:FindFirstChildOfClass("ProximityPrompt")
		if existing then
			existing:Destroy()
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StationPrompt"
		prompt.ActionText = behaviour.actionText
		prompt.ObjectText = behaviour.objectText
		prompt.MaxActivationDistance = PROMPT_DISTANCE
		prompt.RequiresLineOfSight = false -- the face is recessed behind a chrome frame
		prompt.HoldDuration = 0
		--- ⚠️ The id travels ON the prompt. The client reads it to decide which screen to open,
		--- so it never has to know where a station is or what it is called in the Explorer.
		prompt:SetAttribute("StationId", id)
		--- 🔴 Which base this prompt belongs to. Ownership is enforced server-side; this is here so
		--- the client can say WHOSE station it is refusing, rather than just refusing.
		if type(baseIndex) == "number" then
			prompt:SetAttribute("BaseIndex", baseIndex)
		end
		--- 🔴 THE WHOLE CONTRACT TRAVELS ON THE PROMPT.
		---
		--- `screen` and `notYet` used to live only in this table, and the client kept its own
		--- copies of both. Nothing enforced that they matched and **they had already drifted** --
		--- the server said "NO ROBOT TO REPAIR YET" while the client said "... — GROUP 09", and a
		--- station added here with a screen the client did not know about would silently show
		--- "NOT BUILT YET" with no error anywhere. Two of the fields were dead decoration
		--- describing a contract the wire did not carry.
		---
		--- Now the wire carries it, so there is exactly one source and a new station needs no
		--- client change at all.
		if behaviour.screen then
			prompt:SetAttribute("Screen", behaviour.screen)
		end
		if behaviour.notYet then
			prompt:SetAttribute("NotYet", behaviour.notYet)
		end
		--- The whole contract travels on the prompt, same as `Screen` and `NotYet` -- so the client
		--- needs no table of its own and cannot drift from this one.
		if behaviour.enter then
			prompt:SetAttribute("EnterTier", behaviour.enter)
		end
		prompt.Parent = host
		n += 1
	end

	--- ⚠️ VALIDATED AGAINST THE ROOM THAT EXISTS, not against `HubSpec`.
	---
	--- 🔴 This used to compare every base against `#HubSpec.FIXTURES` (3) and `HubSpec.BASES`, i.e.
	--- against job 019's rejected design where each base held its own Magnet Lab, Recycler and
	--- Robot Bay. Job 020's owner ground rule is the opposite: the upgrade buildings are COMMON and
	--- a player owns only their smelter. So the old check reported twelve errors -- "base 1 got 1
	--- prompts, not 3" -- against a room that was completely correct, which is worse than no check:
	--- it trains everyone to scroll past station errors.
	---
	--- What can still genuinely fail, and does the job the old check was trying to do:
	for _, id in ipairs(REQUIRED_COMMON) do
		if not seen[id] then
			table.insert(problems, ("common station %q is missing from Hub.Common.Fixtures"):format(id))
		end
	end
	for index, got in pairs(perBase) do
		if got ~= 1 then
			table.insert(problems, ("base %d has %d fixtures, expected exactly 1 (its own smelter)"):format(index, got))
		end
	end
	local basesSeen = 0
	for _ in pairs(perBase) do
		basesSeen += 1
	end
	if basesSeen ~= EXPECTED_BASES then
		table.insert(problems, ("%d bases carry a smelter, expected %d"):format(basesSeen, EXPECTED_BASES))
	end

	return n, problems
end

--------------------------------------------------------------------------------
-- Being AT the station. The server's job, not the prompt's.
--------------------------------------------------------------------------------

--- How far from a station's machine a player may be and still use it. The prompt itself allows
--- `PROMPT_DISTANCE`; this is deliberately looser, because the client's position and the server's
--- differ by a round trip and an honest player at the edge must not be refused.
local USE_DISTANCE = PROMPT_DISTANCE * 1.8

--- 🔴 THE PROMPT IS NOT A GATE. IT IS A LOCALSCRIPT.
---
--- `ProximityPromptService.PromptTriggered` fires on the CLIENT, so "the player pressed E at the
--- Recycler" is a claim, not a fact. Without this, a modified client sends
--- `RequestRecycle:InvokeServer(true)` from anywhere in the world and cashes out.
---
--- What that buys is not cosmetic. **`Capacity` is a paid upgrade whose entire value is how far
--- you can sweep before walking back.** Remote recycling empties the magnet on demand, so Capacity
--- buys nothing and the return trip -- the loop's only risk window -- disappears. Decision 0007's
--- own closing test is "could a modified client send this to gain something?", and the answer here
--- was yes.
---
--- `ScrapService` already does exactly this for collection claims, forty lines from here. The
--- precedent existed and was not applied.
---
--- ⚠️ The station is found by its `StationId` attribute, never by a coordinate -- the Workshop is
--- regenerated from a spec and every position in it has moved.
--- Move a player into a zone, if they are really standing at the Factory Entrance.
---
--- 🔴 The proximity check is the point. `ScrapService` and `RequestRecycle` both learned this the
--- expensive way: the prompt is a LocalScript, so the only thing that makes "I pressed E at the
--- entrance" true is the server measuring it. Without this a modified client walks into any zone
--- from anywhere -- and zones are exactly what the Magnet Power gates are supposed to ration.
function StationService.enterZone(player: Player, stationId: unknown): (boolean, string)
	if type(stationId) ~= "string" then
		return false, "bad request"
	end
	local behaviour = StationService.BEHAVIOUR[stationId]
	if not behaviour or not behaviour.enter then
		return false, "that is not a way into the factory"
	end
	local at, why = StationService.playerIsAt(player, stationId)
	if not at then
		return false, why
	end
	--- 🔴 THE TIER COMES FROM THE SERVER'S OWN TABLE, never from the client.
	---
	--- ⚠️ The first version took a `tier` number off the wire and passed it straight to `sendTo`.
	--- The proximity half was right; this half did not exist. It passed its test only because
	--- tier 2 does not exist yet, so every wrong number was refused by a `byTier` lookup — the test
	--- succeeded for the wrong reason, and **job 018 is what arms it**: the moment zone 2 registers,
	--- a client standing legitimately at the entrance could send `2` and land past the physical
	--- gate. `Remotes.luau`'s own note claimed this was defended; it was not.
	local ZoneManager = require(script.Parent:WaitForChild("ZoneManager", 20))
	return ZoneManager.sendTo(player, behaviour.enter)
end

function StationService.playerIsAt(player: Player, stationId: string): (boolean, string)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false, "no character"
	end
	--- 🔴 Walks BOTH the common ring and the twelve bases -- see `collectStations`. This proximity
	--- check is the one thing standing between a modified client and every economy remote in the
	--- game, so it has to see every station that exists. Job 019 moved stations per-base; job 020
	--- moved the seven shared ones back out to `Hub.Common`, and for a while this looked only at
	--- `Bases` -- which finds the smelters and none of the buildings, refusing honest players
	--- standing directly in front of the Recycler.
	local candidates, err = collectStations()
	if err then
		return false, err
	end
	for _, station in ipairs(candidates) do
		if station:GetAttribute("StationId") == stationId then
			local host = promptHost(station)
			if not host then
				return false, ("station %q has no part to measure from"):format(stationId)
			end
			local d = (root.Position - host.Position).Magnitude
			if d <= USE_DISTANCE then
				return true, "at the station"
			end
			return false, ("%.0f studs from the %s (max %.0f)"):format(d, stationId, USE_DISTANCE)
		end
	end
	return false, ("station %q is not in the world"):format(stationId)
end

--------------------------------------------------------------------------------
-- The Recycler. Spec §48's pinch, and the first place Coins come from a choice.
--------------------------------------------------------------------------------

--- What the two exits are worth right now. The client renders this; it does not compute it.
---
--- ⚠️ Both are always returned together. Decision 0007's economy pinch is *do I spend this on
--- myself or on keeping my robot alive*, and a UI that shows one exit at a time is not asking that
--- question. `Economy.previewChoice` exists so the numbers cannot drift from the config.
function StationService.recyclePreview(player: Player): { scrap: number, coins: number, hp: number, repairable: boolean }
	local scrap = MagnetState.scrapCarried(player)
	local coins, hp = Economy.previewChoice(scrap)
	return {
		scrap = scrap,
		coins = coins,
		hp = hp,
		--- 🔴 FALSE, and honestly so. There is no robot until group 09, so the repair exit cannot
		--- be taken. It is still SHOWN, with its real number, because hiding it would hide the
		--- choice the whole economy is built around -- but it must not pretend to work.
		repairable = false,
	}
end

--- Convert carried scrap into Coins. Returns (ok, message, preview-after).
---
--- ⚠️ The server reads the scrap, computes the coins and empties the magnet. Nothing about the
--- amount comes from the client (decision 0007) -- the client sends intent and nothing else.
function StationService.recycle(player: Player): (boolean, string)
	--- ⚠️ FIRST. Everything below mints currency, so the "are you actually here" question has to
	--- be answered before any of it runs.
	local near, why = StationService.playerIsAt(player, "Recycler")
	if not near then
		Log.warn("%s tried to recycle but is %s", player.Name, why)
		return false, "TOO FAR FROM THE RECYCLER"
	end

	local scrap = MagnetState.scrapCarried(player)
	if scrap <= 0 then
		return false, "NOTHING TO RECYCLE"
	end
	local coins = Economy.previewChoice(scrap)
	local banked = MagnetState.emptyCarried(player)
	if banked ~= scrap then
		-- the two reads disagreeing means something else emptied the magnet in between
		Log.warn("%s: recycle read %d scrap but banked %d", player.Name, scrap, banked)
		coins = Economy.previewChoice(banked)
	end
	MagnetState.addCoins(player, coins)
	Log.info("%s recycled %d scrap for %d coins", player.Name, banked, coins)
	return true, ("+%d COINS"):format(coins)
end

--- Repair is bound so the remote is not an unlit endpoint, and refuses honestly.
---
--- ⚠️ It would be easy to leave `RequestRepair` unbound until group 09. But an unbound remote that
--- a station's prompt points at is a control that does nothing with no explanation, which is the
--- shape PITFALLS #29 and #34 are both about. Bound and refusing is a different thing from absent.
function StationService.repair(_player: Player): (boolean, string)
	return false, StationService.BEHAVIOUR.Repair.notYet or "NO ROBOT TO REPAIR YET"
end

return StationService
