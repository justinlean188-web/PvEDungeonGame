--[[
	MonetizationConfig (Shared Module)
	==================================
	PLACEHOLDER IDs ONLY. To go live:

	1. In Creator Dashboard → your game → Monetization:
	   - Create each Game Pass and Developer Product listed below.
	   - Copy the real numeric IDs into this file, replacing the 0000000xxx values.
	2. Nothing else needs to change — all services read from here.

	Game Passes   = permanent per-player entitlements (checked via Players:GetPlayerOwnsPassAsync / PassService).
	Dev Products  = repeatable purchases handled in ProcessReceipt (revives, boosts, keys).
]]

local MonetizationConfig = {}

-- ============================================================================
-- GAME PASS IDS  (TODO: replace with real Game Pass IDs from Creator Dashboard)
-- ============================================================================
MonetizationConfig.GamePasses = {
	TwoXxpAndLoot     = 0000000001, -- TODO: "2x XP & Loot" pass id
	ExtraLoadoutSlot  = 0000000002, -- TODO: "Extra Loadout Slot" pass id
	VipDungeonAccess  = 0000000003, -- TODO: "VIP Dungeon Access" pass id (tier3 raids)
	AutoRevive        = 0000000004, -- TODO: "Auto-Revive" pass id (free revive on death)
}

-- ============================================================================
-- DEVELOPER PRODUCT IDS  (TODO: replace with real Dev Product ids)
-- ============================================================================
MonetizationConfig.DevProducts = {
	Revive            = 0000000011, -- TODO: "Instant Revive" product (used by ReviveService)
	DamageBoost2x     = 0000000012, -- TODO: "2x Damage Boost (1 run)" product
	LootBoxKey        = 0000000013, -- TODO: "Loot Box Key" product
	DropRateBoost     = 0000000014, -- TODO: "Drop Rate Boost (1 run)" product
}

--- Reverse lookup: productId -> logical name ("Revive", "DamageBoost2x", ...)
-- @param productId number
-- @return string|nil
function MonetizationConfig.getProductName(productId)
	if typeof(productId) ~= "number" then return nil end
	for name, id in pairs(MonetizationConfig.DevProducts) do
		if id == productId then return name end
	end
	return nil
end

--- Reverse lookup: passId -> logical name
-- @param passId number
-- @return string|nil
function MonetizationConfig.getPassName(passId)
	if typeof(passId) ~= "number" then return nil end
	for name, id in pairs(MonetizationConfig.GamePasses) do
		if id == passId then return name end
	end
	return nil
end

return MonetizationConfig
