--!strict
--[[
	StationService — makes the Workshop's seven stations do something.

	Job 012 built the room; every station in it was scenery. This attaches a `ProximityPrompt` to
	each one and owns the transactions behind the two that have real economies.

	🔴 FOUND BY ATTRIBUTE, NEVER BY POSITION.

	The Workshop is REGENERATED from `WorkshopSpec` on every server start, so a station's world
	position is an output, not a fact — it moved twice during job 012 alone (the Scrap Arena to
	clear the sightline, then every sign when the plinths became machines). `WorkshopBuilder`
	stamps `StationId` on each station's folder for exactly this reason. Anything here that hunted
	for a station by coordinate would break the next time the spec changed, silently, and look like
	a prompt bug.

	⚠️ **`screen_capture` cannot render `ProximityPrompt` bubbles** (PITFALLS #20). A screenshot
	showing no prompt is not evidence there is no prompt. Verify by reading
	`PlayerGui.ProximityPrompts`, or by triggering it.

	Sources: docs/build/05-workshop.md · decision 0007 (the server owns currency) · spec §48
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config", 20)
local Economy = require(Config:WaitForChild("Economy", 20))
local WorkshopSpec = require(ReplicatedStorage:WaitForChild("Workshop", 20):WaitForChild("WorkshopSpec", 20))
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
		screen = nil,
		notYet = "THE ROBOT BAY OPENS IN GROUP 09",
	},
	PartArchive = {
		actionText = "VIEW",
		objectText = "PART ARCHIVE",
		screen = nil,
		notYet = "NO PARTS DISCOVERED YET",
	},
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
} :: { [string]: Behaviour }

--------------------------------------------------------------------------------
-- Attaching the prompts.
--------------------------------------------------------------------------------

local PROMPT_DISTANCE = 14

--- The part a prompt should hang on: the machine's glowing face, which is the thing the player is
--- looking at. Falls back to any part, so a station whose piece changed still gets a prompt.
local function promptHost(station: Instance): BasePart?
	local machine = station:FindFirstChild("Station_Machine")
	if machine then
		for _, d in ipairs(machine:GetDescendants()) do
			if d:IsA("BasePart") and d.Material == Enum.Material.Neon then
				return d
			end
		end
	end
	for _, d in ipairs(station:GetDescendants()) do
		if d:IsA("BasePart") then
			return d
		end
	end
	return nil
end

--- Attach a prompt to every station the Workshop built. Returns (attached, problems).
---
--- Idempotent, like everything else that touches the regenerated room: an existing prompt is
--- replaced, so calling this after a `workshop.rebuild` is correct rather than additive.
function StationService.attachPrompts(): (number, { string })
	local problems = {}
	local root = workspace:FindFirstChild("Workshop")
	local stations = root and root:FindFirstChild("Stations")
	if not stations then
		return 0, { "no Workspace.Workshop.Stations -- the room has not been built" }
	end

	local n = 0
	local seen: { [string]: boolean } = {}
	for _, station in ipairs(stations:GetChildren()) do
		local id = station:GetAttribute("StationId")
		if type(id) ~= "string" then
			table.insert(problems, ("%s has no StationId attribute -- the builder must stamp it"):format(station.Name))
			continue
		end
		seen[id] = true

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

	--- ⚠️ Every station in the SPEC must have got a prompt. Counting the prompts we made would
	--- report success for a room that built two stations; comparing against the spec is what
	--- makes this able to fail.
	for _, s in ipairs(WorkshopSpec.STATIONS) do
		if not seen[s.id] then
			table.insert(problems, ("station %q is in the spec but was not found in the built room"):format(s.id))
		end
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
	local ws = workspace:FindFirstChild("Workshop")
	local stations = ws and ws:FindFirstChild("Stations")
	if not stations then
		return false, "the Workshop is not built"
	end
	for _, station in ipairs(stations:GetChildren()) do
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
