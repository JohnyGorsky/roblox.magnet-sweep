--!strict
--[[
	MaterialKit — the nine named surfaces of the factory, and the ONLY way to apply one.

	Call sites name a surface, never a mechanism:

	    MaterialKit.apply(part, "Chrome")
	    MaterialKit.apply(part, "PaintedGloss", Color3.fromHex("#FF6FB5"))

	That indirection is load-bearing, because the nine surfaces are NOT all built the same
	way and two of them are special:

	  * CHROME IS NOT A MaterialVariant. Under the style skill's lighting recipe, built-in
	    `Metal` shows TIGHT specular points while every generated variant shows a broad soft
	    wash, and tight specular is what reads as polished. So Chrome = built-in Metal + a
	    light tint. NOT because "roughness maps cannot mirror" -- that is false; roughness ~0
	    with metalness 1 IS a mirror. The generator also emits a textured ColorMap and
	    NormalMap, and those break the reflection up. Hand-authored flat greyscale maps are
	    the untested route to a true PBR mirror.
	  * STEELDARK IS TINTED, NOT DARK. Its generated map came out pale; part Color MULTIPLIES
	    the ColorMap, so the darkness is applied here rather than regenerated.

	Because part Color multiplies the ColorMap, a NEUTRAL map is more valuable than a
	correctly-coloured one -- it can take any zone accent. Where a surface has an opinionated
	colour baked in (PaintedGloss came out red), `defaultColor` records it so a caller who
	passes no colour still gets something sane.

	⚠️ APPLYING A SURFACE CHANGES PHYSICS. `Material` drives friction, elasticity and density,
	not just appearance -- SmoothPlastic is slippery, Rubber is bouncy, Metal is dense. No
	variant sets CustomPhysicalProperties, so parts inherit the base material's physics. That
	matters for the player's walk and for the Arena robot's AlignPosition root. If a surface is
	ever applied to something whose handling matters, set CustomPhysicalProperties explicitly.

	Sources: Jobs/004/final-summary.md · .claude/skills/magnet-sweep-style/SKILL.md §3
	         docs/decisions/0016-low-tier-drops-the-variant.md
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

export type Def = {
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
		defaultColor = Color3.fromHex("#B8C2CC"), -- palette "Chrome light"
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
		defaultColor = Color3.fromHex("#4A545E"), -- palette "Steel mid"; tinted down, the map is pale
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
		defaultColor = Color3.fromHex("#14161C"), -- palette "Hazard black"; the rubber map is pale
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

--- Typed deliberately: an untyped literal widens to `{string}`, and the module's own public
--- list then cannot be passed to the module's own public function under --!strict.
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
} :: { Surface }

--- The attribute `apply` stamps on every part it touches. The quality-tier controller needs
--- it to find parts whose variant must be stripped on Low and restored later; without it,
--- that retrofit means re-walking every model in the world.
MaterialKit.ATTRIBUTE = "MSSurface"

function MaterialKit.def(surface: Surface): Def?
	return DEFS[surface]
end

--- Narrow an arbitrary string (an attribute, a config row) to a Surface. Data-driven call
--- sites need this or they must cast, which defeats the union.
function MaterialKit.fromString(name: string?): Surface?
	if name and DEFS[name] then
		return name :: Surface
	end
	return nil
end

--- Whether PBR variants are applied at all. The Low quality tier sets this false, which
--- drops the MaterialVariant and leaves the built-in material + palette colour
--- (decision 0016). Reflectance is NOT used -- it is inert on Metal.
local usePBR = true

function MaterialKit.setUsePBR(enabled: boolean)
	usePBR = enabled
end

function MaterialKit.usePBR(): boolean
	return usePBR
end

--- Apply a named surface to a part. `color` overrides the surface default -- pass a zone
--- accent for painted surfaces. Returns false (never throws) on an unknown surface; the part
--- is left UNCHANGED, which is why every part also gets the MSSurface attribute: a part with
--- no attribute was never successfully surfaced.
function MaterialKit.apply(part: BasePart, surface: Surface, color: Color3?): boolean
	local def = DEFS[surface]
	if not def then
		warn(("[MaterialKit] unknown surface %q -- part %s left unchanged"):format(tostring(surface), part:GetFullName()))
		return false
	end
	part.Material = def.material
	part.MaterialVariant = (usePBR and def.variant) or ""
	part.Color = color or def.defaultColor
	-- record what this part IS, so the tier controller can strip and restore it later
	part:SetAttribute(MaterialKit.ATTRIBUTE, surface)
	return true
end

--- Re-apply every already-surfaced part under `root` at the current tier. This is what makes
--- a runtime tier change possible at all.
---
--- ⚠️ ONE-SHOT. It fixes what exists when it runs and nothing after -- see
--- `MaterialKit.enforce` for why that is not enough on the client.
function MaterialKit.refresh(root: Instance): number
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			local surface = MaterialKit.fromString(d:GetAttribute(MaterialKit.ATTRIBUTE) :: any)
			if surface then
				local def = DEFS[surface]
				d.MaterialVariant = (usePBR and def.variant) or ""
				n += 1
			end
		end
	end
	return n
end

--- Bring `root` back in line with the CURRENT `usePBR`, and report how many parts had drifted.
---
--- ⚠️ `MaterialVariant` is a replicated property owned by the SERVER. The server calls
--- `MaterialKit.apply` on every scrap spawn with its own `usePBR`, which is always true --
--- `setUsePBR` flips a module-level local, and modules are per-VM, so a Low-tier client's
--- decision never reaches the server. Every spawn therefore re-attaches the variant on top of
--- the client's strip, and `refresh` is one-shot so nothing undoes it.
---
--- Measured in Play: a client stripped all 37 variants to 0, the server spawned 60 more pieces
--- of scrap, and the client was back to 37. Scrap is the highest-count object class in the
--- game and its parts are POOLED and re-spawned continuously, so the Low tier's saving decayed
--- toward zero over a session and was worst exactly when the field was densest -- while
--- decision 0016 claimed "no texture fetches, no PBR sampling".
---
--- Returns the number corrected, so a caller can tell "nothing to do" from "not running".
function MaterialKit.enforce(root: Instance): number
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			local surface = MaterialKit.fromString(d:GetAttribute(MaterialKit.ATTRIBUTE) :: any)
			if surface then
				local want = (usePBR and DEFS[surface].variant) or ""
				if d.MaterialVariant ~= want then
					d.MaterialVariant = want
					n += 1
				end
			end
		end
	end
	return n
end

--- Apply to a whole model at once.
---
--- Skips, by default: MeshParts (they are the SurfaceAppearance path, and a SurfaceAppearance
--- child overrides the variant anyway) and parts already carrying a surface (so a mixed-surface
--- kit model is not flattened by one careless call). Pass `overwrite` to force.
function MaterialKit.applyAll(root: Instance, surface: Surface, color: Color3?, overwrite: boolean?): number
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") and not d:IsA("MeshPart") then
			local already = d:GetAttribute(MaterialKit.ATTRIBUTE)
			if overwrite or already == nil then
				if MaterialKit.apply(d, surface, color) then
					n += 1
				end
			end
		end
	end
	return n
end

--- Which surfaces would silently fail in this place.
---
--- Checking the NAME is not enough. Roblox resolves a variant by name **and** BaseMaterial:
--- "The system searches the MaterialVariant instance with the specified MaterialVariant name
--- and BasePart.Material type." A variant present under the right name with the wrong
--- BaseMaterial resolves to nothing and the part renders as the plain built-in material --
--- exactly the silent grey-part failure this audit exists to catch.
---
--- What it CANNOT check: whether the variant's maps are blank. ColorMap and friends are
--- PluginSecurity on read, so no runtime Script can see them.
function MaterialKit.audit(): { string }
	local MS = game:GetService("MaterialService")
	local problems = {}
	for _, name in ipairs(MaterialKit.SURFACES) do
		local def = DEFS[name]
		if def.variant then
			local v = MS:FindFirstChild(def.variant)
			if not v then
				table.insert(problems, ("surface %q expects MaterialVariant %q, which is not in MaterialService"):format(name, def.variant))
			elseif not v:IsA("MaterialVariant") then
				table.insert(problems, ("%q in MaterialService is a %s, not a MaterialVariant"):format(def.variant, v.ClassName))
			elseif v.BaseMaterial ~= def.material then
				table.insert(problems, ("surface %q uses Material %s but variant %q has BaseMaterial %s -- it will resolve to NOTHING")
					:format(name, tostring(def.material), def.variant, tostring(v.BaseMaterial)))
			end
		end
	end
	return problems
end

return MaterialKit
