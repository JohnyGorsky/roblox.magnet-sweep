--!strict
--[[
	Config/PartArt — which MESH each catalog part is, how big, and where it attaches.

	🔴 THIS FILE EXISTS BECAUSE THE CATALOG DELIBERATELY DOES NOT CARRY ART.

	[Finding 0014](../../../findings/0014-the-96-catalog-parts-have-no-mesh-bindin.md): the 96 parts in
	`Config/PartsCatalog` describe *game data* -- slot, tier, rarity, animation profile, effect -- and
	nothing about geometry. So the game could describe a Pipe Wrench and could not put one on a robot.
	Measured live: setting a saved loadout's Arm to `PIPE_WRENCH` produced
	`Arm/PIPE_WRENCH: PIPE_WRENCH has no mesh field` and a four-part robot.

	It is a SEPARATE FILE, not new columns in the catalog, for two reasons:

	1. `PartsCatalog.luau` is **generated** from `docs/content/parts-catalog.md` by
	   `tools/gen-parts-catalog.py` and says "do not hand-edit". Art data added there is erased on the
	   next run.
	2. A mesh id and a mount offset are not design decisions. `docs/content/parts-catalog.md` is a
	   design document that a human reads and argues about; it should not carry
	   `mountFrac = (-0.58, -0.14, 0)`.

	## 🔴 MEASURED, NEVER DERIVED

	Every `scale` and `mountFrac` below was read off the **eight demo robots in
	`Workspace.DemoRoom`** -- the assemblies the owner built and approved -- not computed. Look at the
	spread: mount points at `(0,0,0)`, `(0,-1.03,0)`, `(-0.58,-0.14,0)`, `(+0.82,+0.09,0)` and
	`(+0.16,+0.12,+0.34)`. **No formula produces those.** A bounding-box guess hangs every part by its
	middle, half of it inside the torso, which is the mistake job 019 paid for twice and PITFALLS
	records as *"a bounding box is not the feature"*.

	`mountFrac` is a fraction of the part's HALF-EXTENT: `0` = dead centre, `±1` = on the face. It is
	stored as a fraction rather than studs so it survives a change to `scale`.

	⚠️ SLOT COMES FROM THE CATALOG, NOT FROM HERE. Where a demo robot mounted a part in a socket the
	catalog disagrees with -- `magnet_coil` and `propeller_pack` are catalogued `Back` but sit on the
	torso in the demos -- the CATALOG WINS. This file supplies art, never design.

	## Coverage, honestly

	**Tiers 1 and 2: 16 of 16.** Those are the only tiers a player can currently reach -- zone 1 is
	the only built zone -- so this unblocks the whole early loop: find a part, install it, see it.

	**Tiers 3-12: 0 of 80.** Their meshes do not exist yet. That is a Meshy programme costed at
	~2,400 credits, not a config task, and it is art for zones that have not been built. Anything not
	listed here fails LOUDLY in `RobotAssembler` and leaves the socket empty, per non-negotiable #10.

	Sources: finding 0014 · decision 0004 · Jobs/022
]]

local PartArt = {}

--- `partId -> { mesh, scale, mountFrac }`. `mesh` names an entry in `ServerStorage.ImportedMeshes`.
PartArt.BY_PART = {
	----------------------------------------------------------------------------
	-- Tier 1 — Color Workshop. Complete.
	----------------------------------------------------------------------------
	WORK_LAMP = { mesh = "work_lamp", scale = 3.20, mountFrac = Vector3.new(0.00, -1.00, 0.00) },
	GOLDEN_GEAR = { mesh = "golden_gear", scale = 3.20, mountFrac = Vector3.new(0.00, -1.03, 0.00) },
	MINI_MOTOR = { mesh = "mini_motor", scale = 2.60, mountFrac = Vector3.new(0.00, 0.00, -1.00) },
	PAINT_DRUM = { mesh = "paint_drum", scale = 6.50, mountFrac = Vector3.new(0.00, 0.00, 0.00) },
	PIPE_WRENCH = { mesh = "pipe_wrench", scale = 5.50, mountFrac = Vector3.new(-0.58, -0.14, 0.00) },
	SPRING_PUNCHER = { mesh = "spring_puncher", scale = 5.50, mountFrac = Vector3.new(-0.72, 0.05, 1.12) },
	CASTER_WHEELS = { mesh = "caster_wheels", scale = 4.50, mountFrac = Vector3.new(0.00, 1.00, 0.00) },
	--- catalogued `Back`; the demos mount it on the torso. Catalog wins on slot, this on art.
	MAGNET_COIL = { mesh = "magnet_coil", scale = 4.00, mountFrac = Vector3.new(0.00, 0.09, -1.00) },

	----------------------------------------------------------------------------
	-- Tier 2 — Toy Assembly. Complete.
	----------------------------------------------------------------------------
	TOY_CAMERA = { mesh = "toy_camera", scale = 3.20, mountFrac = Vector3.new(0.00, -1.42, 0.25) },
	WIND_UP_KEY = { mesh = "wind_up_key", scale = 2.60, mountFrac = Vector3.new(0.00, 0.00, -1.18) },
	BUILDING_BLOCK_CHEST = { mesh = "block_chest", scale = 6.50, mountFrac = Vector3.new(0.00, 0.00, 0.00) },
	TOY_HAMMER = { mesh = "toy_hammer", scale = 5.50, mountFrac = Vector3.new(0.82, 0.09, 0.00) },
	JACK_IN_THE_BOX_LAUNCHER = { mesh = "jack_launcher", scale = 5.50, mountFrac = Vector3.new(0.16, 0.12, 0.34) },
	ROLLER_SKATES = { mesh = "roller_skates", scale = 4.50, mountFrac = Vector3.new(0.00, 1.25, 0.31) },
	PROPELLER_PACK = { mesh = "propeller_pack", scale = 4.00, mountFrac = Vector3.new(0.00, -1.12, -0.08) },
	--- ⚠️ THE ONE ESTIMATE IN THIS FILE. `grabber_claw` appears in no demo assembly, so there is no
	--- approved mount for it. `(0,0,-1)` = the inner end of its long axis, which is how job 021
	--- mounted it by hand and it read correctly on the rig. Treat as [UNTUNED] and re-measure once it
	--- has stood in a demo robot.
	GRABBER_CLAW = { mesh = "grabber_claw", scale = 2.60, mountFrac = Vector3.new(0.00, 0.00, -1.00) },
}

function PartArt.get(partId: string)
	return PartArt.BY_PART[partId]
end

function PartArt.has(partId: string): boolean
	return PartArt.BY_PART[partId] ~= nil
end

--- Which catalog parts still have no art. Reported at startup so the gap is a NUMBER on every boot
--- rather than a surprise the first time someone tries to equip a tier-3 part.
function PartArt.audit(PartsCatalog: any): { covered: number, missing: number, missingByTier: { [number]: number } }
	local covered, missing = 0, 0
	local byTier: { [number]: number } = {}
	for _, p in ipairs(PartsCatalog.ALL) do
		if PartArt.BY_PART[p.partId] then
			covered += 1
		else
			missing += 1
			byTier[p.tier] = (byTier[p.tier] or 0) + 1
		end
	end
	return { covered = covered, missing = missing, missingByTier = byTier }
end

return PartArt
