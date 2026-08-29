--!strict
--[[
	Log — a logging helper with a level switch and per-system scoping.

	Why this exists rather than bare print(): this game has three overlapping randomised
	cycles (scrap refresh, factory cycle, factory shift) plus a persistent Arena. Reading
	what happened from an undifferentiated print stream is close to impossible, and the
	build manifest calls the dev tools out as the thing that makes later bugs reproducible.

	Usage:
	    local Log = require(ReplicatedStorage.Log).scope("Magnet")
	    Log.info("pulled %d objects (cap %d)", n, cap)
	    Log.warn("claim rejected: %s", reason)

	Sources: docs/build/01-foundation.md
]]

local RunService = game:GetService("RunService")

export type Level = "trace" | "debug" | "info" | "warn" | "error" | "off"

local ORDER: { [string]: number } = {
	trace = 10,
	debug = 20,
	info = 30,
	warn = 40,
	error = 50,
	off = 100,
}

local Log = {}

--- Default level. Studio is chatty; a live server is not.
Log.level = (RunService:IsStudio() and "debug" or "info") :: Level

--- Per-scope overrides, so one noisy system can be turned up without drowning in the rest.
--- e.g. Log.scopeLevel.Magnet = "trace"
Log.scopeLevel = {} :: { [string]: Level }

local function side(): string
	if RunService:IsServer() then
		return "S"
	end
	return "C"
end

local function enabled(scope: string, level: Level): boolean
	local threshold = Log.scopeLevel[scope] or Log.level
	return (ORDER[level] or 0) >= (ORDER[threshold] or 100)
end

local function emit(scope: string, level: Level, fmt: string, ...): ()
	if not enabled(scope, level) then
		return
	end
	local ok, body = pcall(string.format, fmt, ...)
	if not ok then
		body = fmt .. "  <malformed log args>"
	end
	local line = ("[%s][%s] %s"):format(side(), scope, body)
	if level == "error" then
		-- warn, not error(): a log call must never abort the caller
		warn("[ERROR]" .. line)
	elseif level == "warn" then
		warn(line)
	else
		print(line)
	end
end

export type Scoped = {
	trace: (string, ...any) -> (),
	debug: (string, ...any) -> (),
	info: (string, ...any) -> (),
	warn: (string, ...any) -> (),
	error: (string, ...any) -> (),
	--- Logs and returns the condition, so it can be used inline.
	assertf: (any, string, ...any) -> boolean,
}

local scopes: { [string]: Scoped } = {}

--- Get (or create) a logger for one system. Cached, so calling this in a hot path is fine.
function Log.scope(name: string): Scoped
	local existing = scopes[name]
	if existing then
		return existing
	end
	local s: Scoped = {
		trace = function(fmt, ...)
			emit(name, "trace", fmt, ...)
		end,
		debug = function(fmt, ...)
			emit(name, "debug", fmt, ...)
		end,
		info = function(fmt, ...)
			emit(name, "info", fmt, ...)
		end,
		warn = function(fmt, ...)
			emit(name, "warn", fmt, ...)
		end,
		error = function(fmt, ...)
			emit(name, "error", fmt, ...)
		end,
		assertf = function(cond, fmt, ...)
			if not cond then
				emit(name, "error", fmt, ...)
			end
			return cond and true or false
		end,
	}
	scopes[name] = s
	return s
end

return Log
