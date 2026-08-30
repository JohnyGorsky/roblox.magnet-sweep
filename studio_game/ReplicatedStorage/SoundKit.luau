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
	--- Studs within which there is NO distance attenuation at all.
	---
	--- ⚠️ The magnet's own sounds sit on the LOCAL player's hand, and a third-person camera is
	--- ~15 studs behind it. At the engine default of 10 they were already attenuating before the
	--- listener started -- measured, the 0.18 hum was inaudible from a normal camera. Raising the
	--- MINIMUM is the correct fix; raising the volume would make it loud for everyone else too.
	--- Object families keep a smaller value, so another player's sweep still sounds distant.
	minDistance: number,
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
		minDistance = 12,
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
-- Interface sounds. Everything the player TOUCHES, as opposed to everything the world does.
--
-- ⚠️ This group is deliberately tiny, and it is the one group whose sounds are allowed to be
-- interface-like. `MAGNET.Full` is explicitly forbidden from sounding like a UI buzzer because
-- SCRAP FULL is a physical event; a button press is not, and pretending otherwise would leave
-- every button in the game silent (style §7: silence reads as broken).
--------------------------------------------------------------------------------

SoundKit.UI = {
	--- Every button in the game, via `Ui.Components.button`. There is no second press sound.
	Press = (function()
		local s = slot("a short, dry, positive click — a physical switch on a machine panel",
			"no musical note, no cartoon boop, no reverb tail; it fires on every tap in the game", 0.3)
		--- 2D, parented to SoundService: an interface sound belongs in the player's ears, not in
		--- the world, so distance attenuation must never touch it.
		s.minDistance = 1e6
		return s
	end)(),
}

--------------------------------------------------------------------------------
-- LANDED IDS — approved by the owner, 2026-08-30.
--
-- One block, so what is filled is visible at a glance and a slot cannot quietly acquire an id
-- somewhere further down the file. Licence for every one of these: Pro Sound Effects via the
-- Creator Store, free and verified, licensed for use WITHIN ROBLOX ONLY.
--------------------------------------------------------------------------------

local LANDED = {
	["FAMILY.Bolt"] = "9120099101", -- Toggle Switch Industrial 72, 0.6s, sharp click
	["FAMILY.Coin"] = "9116741697", -- Metal Lid, Incense Burner 7, 0.7s, brass and ringy
	["FAMILY.Gear"] = "9113757098", -- Chain Hit Metal 1, 1.9s
	["FAMILY.Spring"] = "9125380134", -- Baseball vs chain-link fence 13, 2.3s. A stretch; see the registry
	["FAMILY.Tool"] = "9125819216", -- Robot Impact, clangs/clunks 4, 1.4s, comic
	["FAMILY.Barrel"] = "9125672726", -- Sledge hammer on I-beam 13, 1.5s
	["FAMILY.Vehicle"] = "9116893799", -- Metal tank scrape 3, 3.9s
	["FAMILY.Machine"] = "9116673678", -- Metal impact, heavy clunking + scraping, 1.9s
	["FAMILY.Rare"] = "9114238479", -- Electric arcing 8, 2.3s. This is the SPARKLE only
	["MAGNET.Hum"] = "9112889325", -- Transformer hum 3, 52.5s, steady, loop
	["MAGNET.React"] = "9125689476", -- Metal shake, aircraft aileron 2, 2.9s
	["MAGNET.Refuse"] = "9114236886", -- Electric arcing 9, 3.2s, starts and stops
	["MAGNET.Rush"] = "9114238609", -- Electric arcing 10, 3.6s, a surge
	["MAGNET.Full"] = "9114201951", -- Duffel bag vs stucco wall 2, 2.0s, dull thud
}

--- ⚠️ Looked up by name, not chosen by an `and/or` chain. The previous form was
--- `group == "FAMILY" and FAMILY or MAGNET`, which silently routes EVERY unknown group to
--- MAGNET -- so a typo, or a third group like UI, would either land an id on the wrong slot or
--- report a slot that does exist as missing.
local GROUPS: { [string]: any } = {
	FAMILY = SoundKit.FAMILY,
	MAGNET = SoundKit.MAGNET,
	UI = SoundKit.UI,
}

for path, id in pairs(LANDED) do
	local group, name = path:match("(%u+)%.(%w+)")
	local target = GROUPS[group or ""]
	if not target then
		warn(("[SoundKit] LANDED names group %q, which does not exist"):format(tostring(group)))
	elseif target[name] then
		target[name].id = "rbxassetid://" .. id
	else
		warn(("[SoundKit] LANDED names %q, which is not a slot"):format(path))
	end
end

--- ⚠️ The magnet's own sounds are heard by the player wearing them, so they must not
--- attenuate at ordinary camera distance. Object families keep the tighter default.
for _, name in ipairs({ "Hum", "React", "Refuse", "Rush", "Full" }) do
	SoundKit.MAGNET[name].minDistance = 30
end

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
	for name, s in pairs(SoundKit.UI) do
		table.insert(out, { path = "UI." .. name, slot = s })
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
	s.RollOffMinDistance = slotRef.minDistance
	s.RollOffMaxDistance = 90
	s.Parent = parent
	return s
end

--- Build a sound for AUDITIONING a candidate id in a slot, configured exactly as the real one
--- would be: same volume, same looping, same rolloff, same parent.
---
--- ⚠️ It goes through `SoundKit.build`, deliberately. The shared registry records two clips
--- accepted on their category and then rejected the moment they were heard properly -- and the
--- other half of that mistake was the audition METHOD: they were judged through a slot that
--- plays at the volume of thunder 600 studs away, far too quiet and distant to tell a ping from
--- a texture. A preview that does not use the real slot's settings is not a preview.
function SoundKit.preview(slotRef: Slot, parent: Instance, overrideId: string?): Sound?
	local id = overrideId
	if id == nil or id == "" then
		id = slotRef.id
	end
	if id == "" then
		return nil -- nothing to hear: the slot is empty and no candidate was given
	end
	local copy: Slot = {
		id = id,
		volume = slotRef.volume,
		pitch = slotRef.pitch,
		looped = slotRef.looped,
		minDistance = slotRef.minDistance,
		brief = slotRef.brief,
		forbid = slotRef.forbid,
	}
	return SoundKit.build(copy, parent, "Preview")
end

--- Normalise whatever a human pasted into a usable SoundId. Accepts a bare number, a full
--- `rbxassetid://` string, or a Creator Store URL.
function SoundKit.normaliseId(text: string?): string?
	if not text then
		return nil
	end
	local digits = tostring(text):match("(%d%d%d%d+)")
	return digits and ("rbxassetid://" .. digits) or nil
end

--- The shortlist from assets/registry/sounds.md, so the bench can offer one-tap candidates
--- instead of asking a human to retype ids. Not the source of truth -- that file is -- but it
--- must not drift from it, so each entry names what it is and what disqualifies it.
SoundKit.SHORTLIST = {
	-- The FIRST entry of each list is Claude's pick and is what the bench plays by default.
	["FAMILY.Bolt"] = {
		{ id = "9120099101", note = "PICK  Toggle Switch Industrial 72 - 0.6s. Sharp click, shortest dry metal found" },
		{ id = "9120094273", note = "Toggle Switch 137 - 0.6s" },
		{ id = "9120100756", note = "Toggle Switch 95 - 0.7s" },
	},
	["FAMILY.Coin"] = {
		{ id = "9116741697", note = "PICK  Metal Lid, Incense Burner 7 - 0.7s. Brass, ringy, shingy - a real ding" },
		{ id = "9125444889", note = "Coins Drop, Medallions to Wood 9 - 1.6s" },
		{ id = "9125444677", note = "Coins Drop, Medallions to Wood 4 - 1.8s" },
	},
	["FAMILY.Gear"] = {
		{ id = "9113757098", note = "PICK  Chain Hit Metal 1 - 1.9s. Has ringing" },
		{ id = "9113757558", note = "Chain Hit Metal 12 - 3.0s" },
	},
	["FAMILY.Spring"] = {
		{ id = "9125380134", note = "PICK (long shot)  Baseball vs Chain Link Fence 13 - 2.3s. A fence twang is the nearest thing to a boing in this library" },
	},
	["FAMILY.Tool"] = {
		{ id = "9125819216", note = "PICK  Robot Impact, Clangs/Clunks 4 - 1.4s, Comic" },
	},
	["FAMILY.Barrel"] = {
		{ id = "9125672726", note = "PICK  Sledge Hammer on I-Beam 13 - 1.5s, ring-off" },
		{ id = "9125672562", note = "Sledge Hammer on I-Beam 9 - 1.7s" },
	},
	["FAMILY.Vehicle"] = {
		{ id = "9116893799", note = "PICK  Metal Tank Scrape 3 - 3.9s. May be too long" },
	},
	["FAMILY.Machine"] = {
		{ id = "9116673678", note = "PICK  Metal Impact, Heavy Clunking + Scraping - 1.9s" },
	},
	["FAMILY.Rare"] = {
		{ id = "9114238479", note = "PICK (half)  Electric Arcing 8 - 2.3s. This is the SPARKLE; the sub-bass hit is still missing" },
		{ id = "9114238609", note = "Electric Arcing 10 - 3.6s" },
	},
	["MAGNET.Hum"] = {
		{ id = "9112889325", note = "PICK  Transformer Hum 3 - 52.5s, Steady, Loop. Longest" },
		{ id = "9112889082", note = "Transformer Hum 1 - 36.0s, Steady, Loop" },
		{ id = "9112889303", note = "Transformer Hum 2 - 36.0s, Steady, Loop" },
		{ id = "9112823813", note = "Light Bulb Buzz 2 - 49.4s, thinner and higher" },
		{ id = "9112889312", note = "Transformer Hum 1 - FLUCTUATING, wrong for a constant hum" },
	},
	["MAGNET.React"] = {
		{ id = "9125689476", note = "PICK  Metal Shake, Aircraft Aileron 2 - 2.9s, Rattles. Says Clunking - check" },
	},
	["MAGNET.Refuse"] = {
		{ id = "9114236886", note = "PICK  Electric Arcing 9 - 3.2s. Starts and stops = effort that fails" },
		{ id = "9114238401", note = "Electric Arcing 6 - 3.1s" },
	},
	["MAGNET.Rush"] = {
		{ id = "9114238609", note = "PICK  Electric Arcing 10 - 3.6s. A surge, closer than a lightning strike" },
		{ id = "9116279560", note = "Lightning Flash 56 - 0.8s. A strike, not a swell" },
		{ id = "9116277827", note = "Lightning Flash 30 - 0.9s" },
	},
	["MAGNET.Full"] = {
		{ id = "9114201951", note = "PICK  Duffel Bag vs Stucco Wall 2 - 2.0s. Dull, no ring, physical" },
		{ id = "9114202139", note = "Duffel Bag 5 - 2.3s" },
	},
} :: { [string]: { { id: string, note: string } } }

return SoundKit
