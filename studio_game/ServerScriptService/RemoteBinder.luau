--!strict
--[[
	RemoteBinder — the ONLY sanctioned way to attach a server handler to a remote.

	Why this exists: the first draft of job 003 shipped a correct rate limiter that was
	wired to exactly ONE of nineteen remotes. `Remotes.SPECS[].rate` named a bucket for
	eight of them and no code ever read that field, so every future handler would have had
	to REMEMBER to call RateLimiter.consume. PITFALLS #38 is precisely about that decay
	mode: the first forgotten call is not a problem, the fortieth is an unlimited endpoint.

	Binding through here makes the limit structural rather than advisory:

	    RemoteBinder.bindFunction("RequestRecycle", function(player, amount)
	        -- rate limiting has ALREADY happened; this only runs if it passed
	    end)

	It also enforces that the remote is the class SPECS says it is, and that a
	ClientToServer remote actually names a bucket.

	Sources: docs/build/01-foundation.md · decision 0002 · decision 0007 · PITFALLS #38
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes", 10))
local RateLimiter = require(script.Parent:WaitForChild("RateLimiter", 10))
local Log = require(ReplicatedStorage:WaitForChild("Log", 10)).scope("RemoteBinder")

local RemoteBinder = {}

local bound: { [string]: boolean } = {}

local function checkedSpec(name: string, wantKind: string)
	local spec = Remotes.spec(name)
	if not spec then
		error(("cannot bind unknown remote %q -- add it to Remotes.SPECS first"):format(name))
	end
	if spec.kind ~= wantKind then
		error(("remote %q is kind %q, not %q"):format(name, spec.kind, wantKind))
	end
	if spec.dir ~= "ClientToServer" and spec.dir ~= "Both" then
		error(("remote %q is %s -- the server does not receive on it"):format(name, spec.dir))
	end
	if not spec.rate then
		error(("remote %q accepts client traffic but names no rate bucket"):format(name))
	end
	if bound[name] then
		error(("remote %q is already bound -- two handlers would both run"):format(name))
	end
	bound[name] = true
	return spec
end

export type FunctionHandler = (player: Player, ...any) -> ...any

--- Bind a RemoteFunction. Rate limiting is applied before the handler runs; a limited
--- call returns `false, "rate limited"` without ever reaching it.
function RemoteBinder.bindFunction(name: string, handler: FunctionHandler)
	local spec = checkedSpec(name, "Function")
	local remote = Remotes.getFunction(name)
	remote.OnServerInvoke = function(player: Player, ...): ...any
		if not RateLimiter.consume(player, spec.rate :: string) then
			return false, "rate limited"
		end
		local ok, a, b = pcall(handler, player, ...)
		if not ok then
			-- a handler that throws must not surface an internal error to the client
			Log.error("%s handler threw: %s", name, tostring(a))
			return false, "internal error"
		end
		return a, b
	end
	Log.debug("bound function %q (bucket %s)", name, spec.rate)
end

export type EventHandler = (player: Player, ...any) -> ()

--- Bind a RemoteEvent's OnServerEvent, with the same guarantees.
function RemoteBinder.bindEvent(name: string, handler: EventHandler)
	local spec = checkedSpec(name, "Event")
	local remote = Remotes.getEvent(name)
	remote.OnServerEvent:Connect(function(player: Player, ...)
		if not RateLimiter.consume(player, spec.rate :: string) then
			return
		end
		local ok, err = pcall(handler, player, ...)
		if not ok then
			Log.error("%s handler threw: %s", name, tostring(err))
		end
	end)
	Log.debug("bound event %q (bucket %s)", name, spec.rate)
end

--- Which ClientToServer remotes still have no handler. Reported at startup: a remote that
--- exists but does nothing is an unlisted endpoint waiting to be found.
function RemoteBinder.unbound(): { string }
	local out = {}
	for _, spec in ipairs(Remotes.SPECS) do
		if (spec.dir == "ClientToServer" or spec.dir == "Both") and not bound[spec.name] then
			table.insert(out, spec.name)
		end
	end
	table.sort(out)
	return out
end

return RemoteBinder
