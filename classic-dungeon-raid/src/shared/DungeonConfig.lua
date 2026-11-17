--[[
	DungeonConfig (Shared Module)
	=============================
	Declarative tier definitions read by DungeonService. Data-only — no logic.

	Tier schema:
	  name          string   display name
	  waveCount     number   normal waves before the boss
	  enemyStats    table    { health, damage, moveSpeed, countMin, countMax }
	  bossStats     table    { health, damage, name }
	  rewardTableId string   key into LootTable.Rewards for this tier
	  reviveCap     number   max paid revives allowed per run (enforced by ReviveService)
	  requiresVip   boolean  needs the VIP dungeon-access Game Pass to enter
]]

local DungeonConfig = {}

DungeonConfig.Tiers = {
	{
		id         = "tier1",
		name       = "Cobblestone Crypt",     -- starter tier
		waveCount  = 3,
		enemyStats = { health = 40,  damage = 8,  moveSpeed = 12, countMin = 3, countMax = 5 },
		bossStats  = { health = 600,  damage = 20, name = "The Stone Golem" },
		rewardTableId = "tier1",
		reviveCap  = 3,
		requiresVip = false,
	},
	{
		id         = "tier2",
		name       = "Mossy Stronghold",
		waveCount  = 5,
		enemyStats = { health = 90,  damage = 14, moveSpeed = 14, countMin = 4, countMax = 7 },
		bossStats  = { health = 1400, damage = 30, name = "Rotwood Warden" },
		rewardTableId = "tier2",
		reviveCap  = 3,
		requiresVip = false,
	},
	{
		id         = "tier3",
		name       = "Obsidian Raid Vault",   -- VIP raid tier
		waveCount  = 8,
		enemyStats = { health = 180, damage = 22, moveSpeed = 16, countMin = 5, countMax = 9 },
		bossStats  = { health = 3200, damage = 45, name = "Vaultkeeper Prime" },
		rewardTableId = "tier3",
		reviveCap  = 5,
		requiresVip = true,
	},
}

--- Look up a tier by id. Returns nil for unknown ids (server must reject those).
-- @param tierId string
-- @return table|nil
function DungeonConfig.getTier(tierId)
	if typeof(tierId) ~= "string" then return nil end
	for _, tier in ipairs(DungeonConfig.Tiers) do
		if tier.id == tierId then
			return tier
		end
	end
	return nil
end

return DungeonConfig
