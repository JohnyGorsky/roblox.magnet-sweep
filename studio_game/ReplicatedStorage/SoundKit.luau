--!strict
--[[
	SoundKit — every sound the game has a slot for, and which of them actually exist.

	🔴 THE HARD RULE (docs/systems/audio): **no placeholder sounds.** Leave the slot empty and
	make it announce itself. A wrong sound is much harder to notice than a missing one, and a
	placeholder is how the wrong asset ships. So every `id` below is `""` until a human supplies
	a real one, and `SoundKit.missing()` reports the empty slots at startup — loudly, by name.

	This is the opposite of the usual instinct. A silent slot is a bug you can hear on the first
	playthrough; a plausible-but-wrong slot survives to launch.

	⚠️ NOTHING BAKED IN. Anything levelled independently is a separate asset:
	  * the magnet hum must not contain sparks — the hum is continuous, the sparks are per-pull
	  * a family's collection sound must not contain a coin cascade — recycle is its own moment
	  * an alarm must not be inside an ambience — the mix puts the sweep UNDER the alarm
	The shared registry records two rejected candidates that failed exactly this test (a prop
	plane inside an ocean loop, a helicopter inside a harbour loop), so it is not hypothetical.

	Sources: docs/systems/audio/README.md · spec §15 · GROUND-RULES §4
	         roblox.workspace/Assets/registry/audio.md (the shared catalog and its warnings)
]]

local SoundKit = {}

export type Slot = {
	id: string, -- "" until a human supplies one. NEVER a guess.
	volume: number,
	--- Base playback speed. Flow raises this; see `SoundKit.pitchFor`.
	pitch: number,
	looped: boolean,
	--- What the sound IS, in words a search can use.
	brief: string,
	--- What it must NOT contain. This is the field that rejects candidates.
	forbid: string,
}

--------------------------------------------------------------------------------
-- The nine object families (§15). Each has its own voice; the pitch rise with Flow IS the
-- Flow feedback, so these are the sounds that carry the combo.
--------------------------------------------------------------------------------

local function slot(brief: string, forbid: string, volume: number?, pitch: number?): Slot
	return {
		id = "",
		volume = volume or 0.5,
		pitch = pitch or 1.0,
		looped = false,
		brief = brief,
		forbid = forbid,
	}
end

SoundKit.FAMILY = {
	Bolt = slot("a short dry *tik* — a small steel bolt landing on metal",
		"no ring, no reverb tail; it repeats dozens of times a second during a Rush", 0.35),
	Coin = slot("a bright *ding* — a washer or metal bead, coin-like",
		"no cash-register, no musical chime, no UI notification sound", 0.4),
	Gear = slot("a *clink* with a little mass behind it — a toothed gear",
		"no ratchet clicking, no clockwork loop", 0.45),
	Spring = slot("a *boing* — a coil spring released",
		"no cartoon slide-whistle; comic but still metal", 0.45),
	Tool = slot("a *clunk* — a pipe or hand tool hitting a floor",
		"no voice, no workshop ambience underneath", 0.5),
	Barrel = slot("a **CLANG** — a big hollow steel drum struck once",
		"no rolling afterwards, no debris scatter", 0.6),
	Vehicle = slot("a **SCREEECH** — sheet metal dragged, a car panel torn free",
		"no engine, no tyres, no traffic", 0.65),
	Machine = slot("**GRRRRR → BOOM** — heavy machinery wrenched loose and dropping",
		"no alarm, no siren; those are levelled separately", 0.7),
	Rare = slot("a low-frequency hit with a sparkle on top — the rare-part payoff",
		"no fanfare, no orchestral sting, no voice", 0.75),
}

--------------------------------------------------------------------------------
-- Magnet-state sounds.
--------------------------------------------------------------------------------

SoundKit.MAGNET = {
	--- Spatialised to the magnet head, not the camera.
	Hum = (function()
		local s = slot("a quiet continuous electrical hum — a powered electromagnet at rest",
			"NO sparks, NO crackle, NO arcing. Those are per-pull and levelled separately; baked in they fire constantly", 0.18)
		s.looped = true
		return s
	end)(),
	--- Plays once when an object enters REACT, so the field reads as reaching out.
	React = slot("a small metallic rattle, rising — an object shivering before it lifts",
		"no impact at the end; it must not sound like it landed", 0.2),
	--- Too heavy to lift. This sound is the tutorial for "upgrade your Magnet Power".
	Refuse = slot("a strained buzz that fails — effort that does not succeed",
		"no breaking, no snapping; nothing may suggest it came free", 0.3),
	--- The Rush landing.
	Rush = slot("an electrical surge swelling upward — power arriving",
		"no explosion, no impact; the Rush starts, it does not detonate", 0.6),
	--- Capacity reached.
	Full = slot("a short dull thud — the magnet refusing, out of room",
		"no error beep, no UI buzzer; it is physical, not an interface", 0.4),
}

--------------------------------------------------------------------------------

--- Every slot, flattened, as (path, slot) pairs.
function SoundKit.all(): { { path: string, slot: Slot } }
	local out = {}
	for name, s in pairs(SoundKit.FAMILY) do
		table.insert(out, { path = "FAMILY." .. name, slot = s })
	end
	for name, s in pairs(SoundKit.MAGNET) do
		table.insert(out, { path = "MAGNET." .. name, slot = s })
	end
	table.sort(out, function(a, b)
		return a.path < b.path
	end)
	return out
end

--- The slots with no asset yet. Bootstrap prints this every startup.
---
--- ⚠️ This is the whole point of the file. It must report by NAME, not as a count: "9 sounds
--- missing" is a number you learn to scroll past, and the list is what makes an empty slot
--- impossible to forget.
function SoundKit.missing(): { string }
	local out = {}
	for _, entry in ipairs(SoundKit.all()) do
		if entry.slot.id == "" then
			table.insert(out, entry.path)
		end
	end
	return out
end

--- Resolve a family name to its slot, or nil. `ScrapSpec.SoundFamily` values feed this.
function SoundKit.family(name: string?): Slot?
	return name and SoundKit.FAMILY[name] or nil
end

--- Playback speed for a collection at Flow `tier`. The rising pitch IS the Flow feedback
--- (§15), so this is a gameplay function, not a mixing detail.
function SoundKit.pitchFor(base: number, tier: number, perTier: number): number
	return base + perTier * math.max(0, tier)
end

--- Build a `Sound` for a slot, or return nil when the slot is empty.
---
--- ⚠️ Returns nil rather than a silent `Sound`. An instance with no `SoundId` looks like a
--- working audio path in the Explorer and in any audit that counts emitters, which is exactly
--- the confusion the no-placeholder rule exists to prevent.
function SoundKit.build(slotRef: Slot, parent: Instance, name: string): Sound?
	if slotRef.id == "" then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = slotRef.id
	s.Volume = slotRef.volume
	s.PlaybackSpeed = slotRef.pitch
	s.Looped = slotRef.looped
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMaxDistance = 90
	s.Parent = parent
	return s
end

return SoundKit
