--[[
	LootService (Server Module)
	===========================
	Server-authoritative weighted loot rolls via shared LootTable.
	Drop-rate boost (Dev Product) and 2x-XP/Loot pass are applied SERVER-side only.

	PUBLIC API:
	  LootService.grantRunLoot(player, rewardTableId) -> { name = itemName, rarity = rarity }
	  LootService.rollForPlayer(player, tierId)       -> entry (no grant; for preview UIs)
	  LootService.getTransparentRates(tierId, player) -> display table incl. player's boosts
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LootTable          = require(ReplicatedStorage:WaitForChild("LootTable"))
local MonetizationConfig = require(ReplicatedStorage:WaitForChild("MonetizationConfig"))

local LootService = {}

local inventories = {} -- [player] = { {id,name,rarity} ... } (swap for DataStore later)

--- Computes the effective drop-rate boost multiplier for a player (server truth).
local function getBoostMultiplier(player)
	local MonetizationService = require(script.Parent:WaitForChild("MonetizationService"))
	if MonetizationService.hasActiveBoost(player, "DropRateBoost") then
		return 2 -- DropRateBoost doubles rare+ weights
	end
	return 1
end

--- Rolls + grants one item from a tier's reward table. Fully server-side.
-- @return table summary { name, rarity }
function LootService.grantRunLoot(player, rewardTableId)
	if not player or typeof(rewardTableId) ~= "string" then
		return { name = "Nothing", rarity = "Common" }
	end
	local boost = getBoostMultiplier(player)
	local entry = LootTable.roll(rewardTableId, nil, boost)
	if not entry then return { name = "Nothing", rarity = "Common" } end

	-- 2x XP & Loot pass: roll a second time (bonus item), never a fake double.
	local GamePassService = require(script.Parent:WaitForChild("GamePassService"))
	local bonus = GamePassService.playerOwns(player, "TwoXxpAndLoot")
		and LootTable.roll(rewardTableId, nil, boost) or nil

	inventories[player] = inventories[player] or {}
	table.insert(inventories[player], entry)
	if bonus then table.insert(inventories[player], bonus) end

	return { name = entry.name, rarity = entry.rarity, bonusName = bonus and bonus.name }
end

--- Preview roll without granting (used by loot-rate info panels).
function LootService.rollForPlayer(player, tierId)
	return LootTable.roll(tierId, nil, getBoostMultiplier(player))
end

--- Transparent drop rates WITH the player's active boosts reflected honestly.
function LootService.getTransparentRates(tierId, player)
	return LootTable.getDisplayDropRates(tierId, player and getBoostMultiplier(player) or 1)
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	inventories[player] = nil
end)

return LootService
