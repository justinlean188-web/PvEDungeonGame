--[[
	GamePassService (Server Module)
	===============================
	Caches Game Pass ownership per player; exposes a simple entitlement check.

	PUBLIC API:
	  GamePassService.playerOwns(player, passName: string) -> boolean   (cached, async-safe)
	  GamePassService.prefetch(player)                                -- call on PlayerAdded
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage:WaitForChild("MonetizationConfig"))

local GamePassService = {}

local cache = {} -- [player] = { [passName] = bool }

local function ensureTable(player)
	local t = cache[player]
	if not t then
		t = {}
		cache[player] = t
	end
	return t
end

--- Async ownership check for one pass; result cached forever (passes are permanent).
local function checkPass(player, passName)
	local passId = MonetizationConfig.GamePasses[passName]
	if not passId then return false end
	local ok, owns = pcall(function()
		return MarketplaceService:PlayerOwnsPass(player, passId)
	end)
	return ok and owns == true
end

--- Prefetches all passes for a player (call from PlayerAdded handler).
function GamePassService.prefetch(player)
	task.spawn(function()
		local t = ensureTable(player)
		for name in pairs(MonetizationConfig.GamePasses) do
			t[name] = checkPass(player, name)
		end
	end)
end

--- Synchronous cached check. If not yet cached, does an inline check once.
-- @param player Player
-- @param passName string e.g. "VipDungeonAccess", "AutoRevive", "TwoXxpAndLoot"
-- @return boolean
function GamePassService.playerOwns(player, passName)
	if typeof(passName) ~= "string" or not player or not player.Parent then return false end
	local t = ensureTable(player)
	if t[passName] == nil then
		t[passName] = checkPass(player, passName)
	end
	return t[passName] == true
end

Players.PlayerRemoving:Connect(function(player)
	cache[player] = nil
end)

Players.PlayerAdded:Connect(GamePassService.prefetch)
for _, p in ipairs(Players:GetPlayers()) do
	GamePassService.prefetch(p)
end

return GamePassService
