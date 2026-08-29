--!strict
--[[
	MaterialKit — the nine named surfaces of the factory, and the ONLY way to apply one.

	Call sites name a surface, never a mechanism:

	    MaterialKit.apply(part, "Chrome")
	    MaterialKit.apply(part, "PaintedGloss", Palette.zoneAccent(1))

	That indirection is load-bearing, because the nine surfaces are NOT all built the same
	way and two of them are special:

	  * CHROME IS NOT A MaterialVariant. Measured in job 004: Roblox's AI material generator
	    produces textured/brushed surfaces, and a roughness map cannot make a mirror. Built-in
	    `Metal` under LightingStyle=Realistic reads far more like chrome than any generated
	    variant did. So Chrome = built-in Metal + a light tint, and nothing else.
	  * STEELDARK IS TINTED, NOT DARK. Its generated map came out pale; part Color MULTIPLIES
	    the ColorMap, so the darkness is applied here rather than regenerated.

	Because part Color multiplies the ColorMap, a NEUTRAL map is more valuable than a
	correctly-coloured one -- it can take any zone accent. Where a surface has an opinionated
	colour baked in (PaintedGloss came out red), `defaultColor` records it so a caller who
	passes no colour still gets something sane.

	Sources: Jobs/004/final-summary.md · .claude/skills/magnet-sweep-style/SKILL.md §3
	         docs/systems/vfx-lighting/README.md
]]

export type Surface =
	"Chrome"
	| "SteelBrushed"
	| "SteelDark"
	| "PaintedGloss"
	| "PaintedWorn"
	| "HazardStripe"
	| "Rubber"
	| "Grate"
	| "Rust"

type Def = {
	material: Enum.Material,
	variant: string?, -- nil = built-in material, no MaterialVariant
	defaultColor: Color3,
	note: string,
}

local MaterialKit = {}

local WHITE = Color3.fromRGB(255, 255, 255)

local DEFS: { [string]: Def } = {
	Chrome = {
		material = Enum.Material.Metal,
		variant = nil, -- deliberately: see the header
		defaultColor = Color3.fromRGB(214, 219, 224),
		note = "mirror chrome; built-in Metal, no variant",
	},
	SteelBrushed = {
		material = Enum.Material.Metal,
		variant = "MS_SteelBrushed",
		defaultColor = WHITE,
		note = "machine housings, gantries",
	},
	SteelDark = {
		material = Enum.Material.Metal,
		variant = "MS_SteelDark",
		defaultColor = Color3.fromRGB(88, 94, 102), -- tinted down; the map is pale
		note = "structure that must recede",
	},
	PaintedGloss = {
		material = Enum.Material.SmoothPlastic,
		variant = "MS_PaintedGloss",
		defaultColor = WHITE,
		note = "painted machine panels; pass a zone accent",
	},
	PaintedWorn = {
		material = Enum.Material.Metal,
		variant = "MS_PaintedWorn",
		defaultColor = WHITE,
		note = "the robot's salvaged body panels",
	},
	HazardStripe = {
		material = Enum.Material.Metal,
		variant = "MS_HazardStripe",
		defaultColor = WHITE,
		note = "the game's signature texture; keep it a STRIPE, never a solid fill",
	},
	Rubber = {
		material = Enum.Material.Rubber,
		variant = "MS_Rubber",
		defaultColor = Color3.fromRGB(150, 150, 150),
		note = "conveyor belts, tyres. Belt ribbing comes from geometry + texture offset, not the material",
	},
	Grate = {
		material = Enum.Material.DiamondPlate,
		variant = "MS_Grate",
		defaultColor = WHITE,
		note = "walkways, floors, vents",
	},
	Rust = {
		material = Enum.Material.CorrodedMetal,
		variant = "MS_Rust",
		defaultColor = WHITE,
		note = "salvage, the Heavy Yard",
	},
}

MaterialKit.SURFACES = {
	"Chrome",
	"SteelBrushed",
	"SteelDark",
	"PaintedGloss",
	"PaintedWorn",
	"HazardStripe",
	"Rubber",
	"Grate",
	"Rust",
}

function MaterialKit.def(surface: Surface): Def?
	return DEFS[surface]
end

--- Apply a named surface to a part. `color` overrides the surface default -- pass a zone
--- accent for painted surfaces. Returns false (never throws) if the surface is unknown, so
--- a typo in world-building code degrades to a visible default instead of halting a build.
function MaterialKit.apply(part: BasePart, surface: Surface, color: Color3?): boolean
	local def = DEFS[surface]
	if not def then
		warn(("[MaterialKit] unknown surface %q -- part %s left unchanged"):format(tostring(surface), part:GetFullName()))
		return false
	end
	part.Material = def.material
	part.MaterialVariant = def.variant or ""
	part.Color = color or def.defaultColor
	return true
end

--- Apply to a whole model at once.
function MaterialKit.applyAll(root: Instance, surface: Surface, color: Color3?): number
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			if MaterialKit.apply(d, surface, color) then
				n += 1
			end
		end
	end
	return n
end

--- Which surfaces are missing their MaterialVariant in this place. Bootstrap reports this:
--- a variant that failed to save reads as a plain grey part, which is easy to miss and hard
--- to attribute later.
function MaterialKit.audit(): { string }
	local MS = game:GetService("MaterialService")
	local problems = {}
	for _, name in ipairs(MaterialKit.SURFACES) do
		local def = DEFS[name]
		if def.variant and not MS:FindFirstChild(def.variant) then
			table.insert(problems, ("surface %q expects MaterialVariant %q, which is not in MaterialService"):format(name, def.variant))
		end
	end
	return problems
end

return MaterialKit
