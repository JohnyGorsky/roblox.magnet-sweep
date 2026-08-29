--!strict
--[[
	RateLimiter — a server-side token bucket, used by EVERY remote.

	Decision 0007: the client requests, the server validates. Rate limiting is the part of
	that which does not depend on the handler being written carefully -- a handler with a
	subtle hole is still bounded in how fast it can be exploited.

	"The client said it collected 4,000 scrap" is the single most likely exploit in a magnet
	game. Validation catches the impossible claim; this catches the plausible one repeated
	600 times a second.

	Usage (server):
	    local RL = require(script.Parent.RateLimiter)
	    if not RL.consume(player, "ClaimScrap") then return end

	Sources: docs/build/01-foundation.md · decision 0002 · decision 0007
]]

local Players = game:GetService("Players")
local Log = require(game:GetService("ReplicatedStorage"):WaitForChild("Log")).scope("RateLimit")

export type BucketDef = {
	rate: number, -- tokens refilled per second
	burst: number, -- bucket capacity
	note: string,
}

local RateLimiter = {}

--------------------------------------------------------------------------------
-- Buckets. Names match Remotes.SPECS[].rate.
--
-- These are deliberately generous: the goal is to bound abuse, not to punish a laggy
-- client that batched two ticks together. A limit tight enough to trip honest players
-- gets raised in a panic and then never lowered.
--------------------------------------------------------------------------------

RateLimiter.BUCKETS = {
	ClaimScrap = {
		rate = 8,
		burst = 16,
		note = "Collections are batched on a 0.25s tick, so ~4/s is honest traffic.",
	},
	RequestDetach = {
		rate = 1,
		burst = 3,
		note = "Detaching is a multi-second wind-up; nobody legitimately spams this.",
	},
	Economy = {
		rate = 4,
		burst = 10,
		note = "Recycle / repair / upgrade. Bounded by UI interaction speed.",
	},
	Robot = {
		rate = 3,
		burst = 8,
		note = "Part installs. Each triggers a Bay animation, so real use is slow.",
	},
	Arena = {
		rate = 1,
		burst = 4,
		note = "Release / withdraw. Flapping these is itself a griefing vector.",
	},
	Rename = {
		rate = 0.2,
		burst = 2,
		note = "Text filtering is a yielding web call. Strictest bucket in the game.",
	},
	Dev = {
		rate = 5,
		burst = 20,
		note = "Dev tools. Authorisation is re-checked separately; this only bounds volume.",
	},
} :: { [string]: BucketDef }

RateLimiter.DEFAULT = { rate = 5, burst = 10, note = "fallback for unlisted buckets" } :: BucketDef

--------------------------------------------------------------------------------

type Bucket = { tokens: number, updated: number }

local state: { [Player]: { [string]: Bucket } } = {}
-- how many rejections each player has accrued, so a spammer can be surfaced once rather
-- than logged 600 times
local rejects: { [Player]: { [string]: number } } = {}

Players.PlayerRemoving:Connect(function(player)
	state[player] = nil
	rejects[player] = nil
end)

--- Consume one token. Returns true if the action may proceed.
--- Never yields, never errors, and is safe to call before any validation.
function RateLimiter.consume(player: Player, bucketName: string, cost: number?): boolean
	local def = RateLimiter.BUCKETS[bucketName] or RateLimiter.DEFAULT
	local perPlayer = state[player]
	if not perPlayer then
		perPlayer = {}
		state[player] = perPlayer
	end
	local bucket = perPlayer[bucketName]
	local now = os.clock()
	if not bucket then
		bucket = { tokens = def.burst, updated = now }
		perPlayer[bucketName] = bucket
	end

	bucket.tokens = math.min(def.burst, bucket.tokens + (now - bucket.updated) * def.rate)
	bucket.updated = now

	local want = cost or 1
	if bucket.tokens >= want then
		bucket.tokens -= want
		return true
	end

	local r = rejects[player]
	if not r then
		r = {}
		rejects[player] = r
	end
	r[bucketName] = (r[bucketName] or 0) + 1
	local n = r[bucketName]
	-- log the 1st, 10th, 100th... so a persistent abuser is visible without flooding
	if n == 1 or n == 10 or n == 100 or n % 1000 == 0 then
		Log.warn("%s exceeded %q (%d rejections)", player.Name, bucketName, n)
	end
	return false
end

--- Rejection count, for anti-exploit reporting.
function RateLimiter.rejectionCount(player: Player, bucketName: string?): number
	local r = rejects[player]
	if not r then
		return 0
	end
	if bucketName then
		return r[bucketName] or 0
	end
	local total = 0
	for _, v in pairs(r) do
		total += v
	end
	return total
end

--- Test/dev only: forget a player's buckets.
function RateLimiter.reset(player: Player)
	state[player] = nil
	rejects[player] = nil
end

return RateLimiter
