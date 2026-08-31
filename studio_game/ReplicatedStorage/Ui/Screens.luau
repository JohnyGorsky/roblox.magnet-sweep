--!strict
--[[
	Screens — the client's register of openable screens, and the only way one system opens another's.

	The Workshop's Magnet Lab terminal has to open the upgrade panel. That panel lives inside
	`Hud.local.luau` as a local function, and job 011 already built, measured and attacked it — a
	second implementation would be a second thing to keep correct, and the first time the two
	disagreed the player would see two different prices.

	So the HUD **registers** its panel here and the station **asks for it by name**. Nothing reaches
	into another script, and nothing is duplicated.

	⚠️ Client-only, and it relies on a real Roblox fact: every `LocalScript` on a client shares one
	Luau VM, so `require` returns the same table to all of them. The same is NOT true across the
	client/server boundary, and it is not true of `execute_luau`, which builds its own copy
	(PITFALLS #16).

	Sources: docs/game/ui-direction.md · Jobs/011 (the panel this exists to reuse)
]]

local RunService = game:GetService("RunService")

assert(RunService:IsClient(), "Ui.Screens is client-only")

local Screens = {}

export type Screen = {
	--- Show or hide. Called with `true` to open.
	setOpen: (boolean) -> (),
	--- Whether it is open right now.
	isOpen: () -> boolean,
}

local registry: { [string]: Screen } = {}

--- Register a screen under a name. Registering twice under one name is a mistake, not a
--- convenience: two owners means neither can be relied on to close it.
function Screens.register(name: string, screen: Screen)
	assert(not registry[name], ("screen %q is already registered -- two owners for one screen"):format(name))
	registry[name] = screen
end

function Screens.get(name: string): Screen?
	return registry[name]
end

--- Open a screen. Returns false when nothing has registered that name.
---
--- ⚠️ Returns a boolean rather than erroring, because the caller is usually a world object whose
--- screen may legitimately not exist yet — a station for a system that ships in a later group. The
--- caller is expected to say something honest when this is false, not to fail silently.
function Screens.open(name: string): boolean
	local s = registry[name]
	if not s then
		return false
	end
	s.setOpen(true)
	return true
end

function Screens.close(name: string): boolean
	local s = registry[name]
	if not s then
		return false
	end
	s.setOpen(false)
	return true
end

--- Close everything. For a context change — entering a zone, a cutscene, the HUD being hidden.
function Screens.closeAll()
	for _, s in pairs(registry) do
		if s.isOpen() then
			s.setOpen(false)
		end
	end
end

function Screens.isAnyOpen(): boolean
	for _, s in pairs(registry) do
		if s.isOpen() then
			return true
		end
	end
	return false
end

--- What is registered, for a log line or a dev command.
function Screens.names(): { string }
	local out = {}
	for name in pairs(registry) do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

return Screens
