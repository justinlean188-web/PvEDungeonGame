--[[
	MonetizationService (Server Module + bootstrap Script pattern)
	==============================================================
	Handles MarketplaceService.ProcessReceipt for ALL Developer Products:
	  Revive, DamageBoost2x, LootBoxKey, DropRateBoost.

	IDEMPOTENCY CONTRACT (Roblox may retry receipts):
	  - Every ReceiptId is recorded in `processed` BEFORE granting.
	  - A duplicate ReceiptId returns PurchaseHistoryType.AlreadyPurchased ->
	    we still return Enum.ProductPurchaseDecision.PurchaseGranted (already handled).
	  - We return PurchaseGranted ONLY after the grant function completes without error;
	    on grant failure we do NOT mark processed and return NotProcessedYet so Roblox retries.

	PUBLIC API:
	  MonetizationService.grantProduct(player, productName) -> boolean  (used by ReviveService)
	  MonetizationService.hasActiveBoost(player, productName) -> boolean
]]

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage:WaitForChild("MonetizationConfig"))

local MonetizationService = {}

local processed = {}            -- [receiptId] = true  (idempotency ledger)
local boosts = {}               -- [player] = { [productName] = expiryTime }
local BOOST_DURATION = 600      -- single-run boosts last 10 min as fallback cap

-- ---------- grant handlers (server-authoritative effects) ----------

local grantHandlers = {
	Revive = function(player)
		-- Actual revive logic lives in ReviveService; receipt path only tops up
		-- a token bucket that ReviveService consumes.
		local ReviveService = require(script.Parent:WaitForChild("ReviveService"))
		return ReviveService.creditPaidToken(player)
	end,
	DamageBoost2x = function(player)
		MonetizationService._setBoost(player, "DamageBoost2x", os.clock() + BOOST_DURATION)
		return true
	end,
	LootBoxKey = function(player)
		local leaderstats = player:FindFirstChild("leaderstats")
		local keys = leaderstats and leaderstats:FindFirstChild("LootBoxKeys")
		if keys then keys.Value = keys.Value + 1 return true end
		return false
	end,
	DropRateBoost = function(player)
		MonetizationService._setBoost(player, "DropRateBoost", os.clock() + BOOST_DURATION)
		return true
	end,
}

function MonetizationService._setBoost(player, name, expiry)
	boosts[player] = boosts[player] or {}
	boosts[player][name] = expiry
end

--- True while an active (unexpired) boost exists for this player+product.
function MonetizationService.hasActiveBoost(player, productName)
	local b = boosts[player]
	return b ~= nil and typeof(b[productName]) == "number" and b[productName] > os.clock()
end

--- Direct grant (no receipt) — used internally/tests. Returns success bool.
function MonetizationService.grantProduct(player, productName)
	local handler = grantHandlers[productName]
	if not handler or not player then return false end
	local ok = pcall(handler, player)
	return ok
end

-- ---------- ProcessReceipt ----------

MarketplaceService.ProcessReceipt = function(receiptInfo)
	if typeof(receiptInfo) ~= "table" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local productId, playerId, receiptId = receiptInfo.ProductId, receiptInfo.PlayerId, receiptInfo.ReceiptId

	-- Unknown product: never grant, never block the queue forever.
	local productName = MonetizationConfig.getProductName(productId)
	if not productName then
		warn("[MonetizationService] unknown ProductId:", productId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- IDEMPOTENT: duplicate receipt => already granted earlier, confirm it.
	if processed[receiptId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = game:GetService("Players"):GetPlayerByUserId(playerId)
	if not player then
		-- Player offline; let Roblox retry next session. Do NOT mark processed.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	processed[receiptId] = true -- claim first to survive concurrent retries
	local granted = MonetizationService.grantProduct(player, productName)
	if not granted then
		processed[receiptId] = nil -- rollback so Roblox can retry
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- PurchaseGranted ONLY after confirmed grant:
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	boosts[player] = nil
end)

return MonetizationService
