--!strict
--[[
	Remotes — the single place that NAMES every RemoteEvent and RemoteFunction.

	Why one module: decision 0007 makes the server authoritative for capture, currency and
	Arena outcome. That is only auditable if the whole attack surface is enumerable in one
	file. If a remote is not listed here, it should not exist.

	The server CREATES the instances (createAll); the client only LOOKS THEM UP (get).
	Nothing here trusts a client -- see RateLimiter and each handler's own validation.

	Sources: docs/build/01-foundation.md · decision 0002 · decision 0007
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local FOLDER_NAME = "Remotes"

export type Kind = "Event" | "Function" | "Unreliable"

export type Spec = {
	name: string,
	kind: Kind,
	dir: "ClientToServer" | "ServerToClient" | "Both",
	rate: string?, -- RateLimiter bucket; nil = server-to-client only, no limit needed
	note: string,
}

--------------------------------------------------------------------------------
-- The catalogue. Every entry states WHO may fire it and WHAT the server must re-check.
--------------------------------------------------------------------------------

Remotes.SPECS = {
	-- ── magnet / collection ───────────────────────────────────────────────────
	{
		name = "ClaimScrap",
		kind = "Event",
		dir = "ClientToServer",
		rate = "ClaimScrap",
		note = "Batched collection claim. Server MUST verify each id was one IT spawned, is owned by that player, is inside Magnet.grantRange() of their root, and has been in PULL for the time the journey really takes. Never trust the count. The reply always fires, even when nothing is accepted, so the client can undo its optimistic hide.",
	},
	{
		name = "ScrapGranted",
		kind = "Event",
		dir = "ServerToClient",
		note = "Authoritative result of a claim: accepted ids, new scrap total, Flow tier.",
	},
	{
		name = "RequestDetach",
		kind = "Function",
		dir = "ClientToServer",
		rate = "RequestDetach",
		note = "Player attempts to rip a rare part free. Server checks Magnet Power against the part's requirement. Returns granted/denied + reason.",
	},

	-- ── cargo / extraction ────────────────────────────────────────────────────
	{
		name = "CargoStateChanged",
		kind = "Event",
		dir = "ServerToClient",
		note = "Carried part, weight class, speed penalty, distance to hub, security state.",
	},
	{
		name = "PartSecured",
		kind = "Event",
		dir = "ServerToClient",
		note = "The SECURED moment. The ONLY point at which inventory changes (decision 0008).",
	},
	{
		name = "SalvageBreach",
		kind = "Event",
		dir = "ServerToClient",
		note = "Zone-wide alarm. Carries which guardian woke and which zone owns the part.",
	},

	-- ── economy ───────────────────────────────────────────────────────────────
	{
		name = "RequestRecycle",
		kind = "Function",
		dir = "ClientToServer",
		rate = "Economy",
		note = "Scrap -> Coins. Server owns the totals; the client sends intent only.",
	},
	{
		name = "RequestEnterZone",
		kind = "Function",
		dir = "ClientToServer",
		rate = "Economy",
		note = "Move the player into a built zone. Invoke with a STATION ID string -- never a tier. 🔴 Two checks, both server-side, because a ProximityPrompt fires on the CLIENT so 'the player pressed E at the entrance' is a claim: (1) the player really is within range of that station, (2) the destination is read from the server's own BEHAVIOUR table and gated on Magnet Power vs Config/Zones. An earlier version took the tier off the wire and only did (1); it passed its test because tier 2 did not exist yet. Replies (ok: boolean, { reason: string }).",
	},
	{
		name = "RequestRepair",
		kind = "Function",
		dir = "ClientToServer",
		rate = "Economy",
		note = "Scrap -> robot HP. Subject to the field-repair cap when the robot is deployed.",
	},
	{
		name = "RequestUpgrade",
		kind = "Function",
		dir = "ClientToServer",
		rate = "Economy",
		note = "Quote AND buy, on one remote so the price shown is the price charged. Invoke with no track to quote; with a track id ('power'|'radius'|'capacity'|'drive') to buy one step. Replies (ok: boolean, { reason: string, quotes: {Quote} }) and ALWAYS carries a fresh quote table. Server recomputes the cost from the player's own level; never accepts a client-supplied price.",
	},
	{
		name = "StatsChanged",
		kind = "Event",
		dir = "ServerToClient",
		note = "Coins, scrap, the four stats, zone access. The client renders this; it never derives it.",
	},

	-- ── robot / arena ─────────────────────────────────────────────────────────
	{
		name = "RequestInstallPart",
		kind = "Function",
		dir = "ClientToServer",
		rate = "Robot",
		note = "Mount an OWNED part into a slot. Server verifies ownership and slot legality.",
	},
	{
		name = "RequestRenameRobot",
		kind = "Function",
		dir = "ClientToServer",
		rate = "Rename",
		note = "Server-side text filtering is MANDATORY and is two calls: FilterStringAsync then GetNonChatStringForUserAsync. Never display on filter failure.",
	},
	{
		name = "RequestReleaseRobot",
		kind = "Function",
		dir = "ClientToServer",
		rate = "Arena",
		note = "Deploy into the Arena, or join the queue if full.",
	},
	{
		name = "RequestWithdrawRobot",
		kind = "Function",
		dir = "ClientToServer",
		rate = "Arena",
		note = "Recall the robot. HP is saved as it stands.",
	},
	{
		name = "ArenaStateChanged",
		kind = "Event",
		dir = "ServerToClient",
		note = "Champion, owner, hold time, HP, defeats, queue position.",
	},
	{
		name = "ArenaNotification",
		kind = "Event",
		dir = "ServerToClient",
		note = "Your robot defeated X / HP low / control lost. Ordinary server events because the game is one place (decision 0001).",
	},
	{
		name = "RobotAnimation",
		kind = "Unreliable",
		dir = "ServerToClient",
		note = "Server broadcasts (robotId, clipName) so every client plays it locally. NOTE: an Animator not under a player character must be started SERVER-side to replicate; this remote exists only if a client-played layer is ever added on top.",
	},

	-- ── world ─────────────────────────────────────────────────────────────────
	{
		name = "FactoryCycleWarning",
		kind = "Event",
		dir = "ServerToClient",
		note = "20-second warning. Must be audible and visible zone-wide, including while running.",
	},
	{
		name = "FactoryShiftChanged",
		kind = "Event",
		dir = "ServerToClient",
		note = "The ~12 minute server-wide modifier.",
	},

	{
		name = "ReportQuality",
		kind = "Event",
		dir = "ClientToServer",
		rate = "Economy",
		note = "Client tells the server its measured quality tier so the server can hold that client's pull cap to its own budget. Only ever LOWERS the cap -- the server clamps to the High ceiling, so a lying client cannot raise it.",
	},

	-- ── dev only ──────────────────────────────────────────────────────────────
	{
		name = "DevCommand",
		kind = "Function",
		dir = "ClientToServer",
		rate = "Dev",
		note = "STUDIO / authorised users ONLY. DevTools re-checks authorisation server-side; being listed here grants nothing.",
	},
} :: { Spec }

--------------------------------------------------------------------------------

local specByName: { [string]: Spec } = {}
for _, s in ipairs(Remotes.SPECS) do
	assert(not specByName[s.name], ("duplicate remote name %q"):format(s.name))
	specByName[s.name] = s
end

function Remotes.spec(name: string): Spec?
	return specByName[name]
end

local function classFor(kind: Kind): string
	if kind == "Function" then
		return "RemoteFunction"
	elseif kind == "Unreliable" then
		return "UnreliableRemoteEvent"
	end
	return "RemoteEvent"
end

--- Server only. Creates the folder and every remote instance. Idempotent.
function Remotes.createAll(): Folder
	assert(RunService:IsServer(), "Remotes.createAll must run on the server")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for _, spec in ipairs(Remotes.SPECS) do
		if not folder:FindFirstChild(spec.name) then
			local inst = Instance.new(classFor(spec.kind))
			inst.Name = spec.name
			inst.Parent = folder
		end
	end
	return folder :: Folder
end

--- Either side. Yields until the remote exists, with a real timeout and a real failure --
--- never an infinite WaitForChild, because under streaming that hangs forever.
---
--- Prefer the TYPED accessors below. `get` returns Instance, which forces an unchecked
--- `:: RemoteFunction` cast at every call site -- and if the Kind in SPECS ever changes,
--- that cast stays silently wrong until `.OnServerInvoke` throws at runtime.
function Remotes.get(name: string, timeout: number?): Instance
	local spec = specByName[name]
	assert(spec, ("unknown remote %q -- add it to Remotes.SPECS first"):format(name))
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, timeout or 10)
	if not folder then
		error(("Remotes folder never appeared while waiting for %q"):format(name))
	end
	local inst = folder:WaitForChild(name, timeout or 10)
	if not inst then
		error(("remote %q never appeared"):format(name))
	end
	return inst
end

local function typed(name: string, want: string, timeout: number?): Instance
	local inst = Remotes.get(name, timeout)
	if not inst:IsA(want) then
		error(("remote %q is a %s, expected %s -- Remotes.SPECS and the call site disagree")
			:format(name, inst.ClassName, want))
	end
	return inst
end

function Remotes.getEvent(name: string, timeout: number?): RemoteEvent
	return typed(name, "RemoteEvent", timeout) :: RemoteEvent
end

function Remotes.getFunction(name: string, timeout: number?): RemoteFunction
	return typed(name, "RemoteFunction", timeout) :: RemoteFunction
end

function Remotes.getUnreliable(name: string, timeout: number?): UnreliableRemoteEvent
	return typed(name, "UnreliableRemoteEvent", timeout) :: UnreliableRemoteEvent
end

--- Every ClientToServer remote MUST name a rate-limit bucket. Returns the offenders so
--- Bootstrap can refuse to start rather than shipping an unlimited endpoint.
function Remotes.auditBuckets(knownBuckets: { [string]: any }): { string }
	local problems = {}
	for _, spec in ipairs(Remotes.SPECS) do
		if spec.dir == "ClientToServer" then
			if not spec.rate then
				table.insert(problems, ("remote %q accepts client traffic but names no rate bucket"):format(spec.name))
			elseif not knownBuckets[spec.rate] then
				table.insert(problems, ("remote %q names bucket %q, which RateLimiter does not define"):format(spec.name, spec.rate))
			end
		elseif spec.rate then
			table.insert(problems, ("remote %q is %s but names a rate bucket"):format(spec.name, spec.dir))
		end
	end
	return problems
end

return Remotes
