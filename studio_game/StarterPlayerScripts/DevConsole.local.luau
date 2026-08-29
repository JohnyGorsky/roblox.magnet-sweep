--!strict
--[[
	DevConsole — the human-reachable entry point for dev commands.

	Without this, `help`, `config.dump` and every future dev command are implemented and
	UNREACHABLE: nothing on the client ever invokes the DevCommand remote. A tool nobody
	can call is not shipped (PITFALLS #29 -- name the caller).

	Usage, from the client console (F9) during a playtest:

	    dev("help")
	    dev("config.dump")
	    dev("zone.jump", 4)

	Or press F2 for the command list.

	⚠️ This file is `.local.luau` -> LocalScript ON PURPOSE. A `.client.luau` here becomes a
	Script with RunContext=Client, which in StarterPlayerScripts RUNS TWICE -- once in place
	and once as the per-player copy. Measured in job 002. Never rename this to .client.luau.

	Authorisation is enforced entirely SERVER-side in DevTools; this script is a convenience
	and grants nothing.

	Sources: docs/build/01-foundation.md · Jobs/002/final-summary.md
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes", 20))
local remote = Remotes.getFunction("DevCommand", 20)

local function run(command: string, ...): (boolean, string)
	if type(command) ~= "string" then
		warn("[dev] usage: dev(\"command\", ...)")
		return false, "bad usage"
	end
	local ok, result = remote:InvokeServer(command, ...)
	if ok then
		print(("[dev] %s\n%s"):format(command, tostring(result)))
	else
		warn(("[dev] %s -> %s"):format(command, tostring(result)))
	end
	return ok, tostring(result)
end

-- Exposed deliberately: the client console is where a dev types during a playtest.
-- _G is per-client and per-session, and the server trusts none of it.
(_G :: any).dev = run

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F2 then
		run("help")
	end
end)

print('[dev] console ready -- dev("help") or press F2')
