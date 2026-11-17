--[[
	LootTable (Shared Module)
	=========================
	Weighted rarity rolls for LootService. Pure data + deterministic roll helpers.

	Rarity weights are per-tier integers; drop rates shown to players via
	LootTable.getDisplayDropRates() are derived from these SAME numbers —
	transparency by construction (display and roll share one source of truth).

	Drop-rate boost (dev product) multiplies non-Common weights before the roll.
]]

local LootTable = {}

LootTable.Rarities = { "Common", "Rare", "Epic", "Legendary" }

-- Per-tier weighted item pools. weight = integer odds against total.
LootTable.Rewards = {
	tier1 = {
		{ id = "sword_rusty",   name = "Rusty Sword",     rarity = "Common",    weight = 60 },
		{ id = "shield_wood",   name = "Wooden Shield",   rarity = "Common",    weight = 25 },
		{ id = "helm_iron",     name = "Iron Helm",       rarity = "Rare",      weight = 10 },
		{ id = "amber_bracer",  name = "Amber Bracer",    rarity = "Epic",      weight = 4 },
		{ id = "classic_cape",  name = "Classic Cape '07", rarity = "Legendary", weight = 1 },
	},
	tier2 = {
		{ id = "moss_blade",    name = "Moss Blade",      rarity = "Common",    weight = 50 },
		{ id = "stone_ring",    name = "Stone Ring",      rarity = "Rare",      weight = 30 },
		{ id = "warden_shard",  name = "Warden Shard",    rarity = "Epic",      weight = 15 },
		{ id = "rotwood_crown", name = "Rotwood Crown",   rarity = "Legendary", weight = 5 },
	},
	tier3 = {
		{ id = "obsidian_key",  name = "Obsidian Key",    rarity = "Rare",      weight = 45 },
		{ id = "vault_medallion", name = "Vault Medallion", rarity = "Epic",    weight = 35 },
		{ id = "prime_core",    name = "Prime Core",      rarity = "Legendary", weight = 20 },
	},
}

--- Rolls one item from a tier pool. Deterministic given rng.
-- @param tierId string
-- @param rng Random (or pass nil to use math.random)
-- @param dropRateBoost number|nil multiplier on rare+ weights (e.g. 2)
-- @return table|nil the chosen entry
function LootTable.roll(tierId, rng, dropRateBoost)
	local pool = LootTable.Rewards[tierId]
	if not pool then return nil end
	dropRateBoost = (typeof(dropRateBoost) == "number" and dropRateBoost > 1) and dropRateBoost or 1

	local total = 0
	local adjusted = {}
	for i, entry in ipairs(pool) do
		local w = entry.weight
		if entry.rarity ~= "Common" then w = w * dropRateBoost end
		adjusted[i] = w
		total = total + w
	end

	local rand = rng and rng:NextNumber() * total or math.random() * total
	local acc = 0
	for i, w in ipairs(adjusted) do
		acc = acc + w
		if rand <= acc then return pool[i] end
	end
	return pool[#pool] -- floating-point safety net
end

--- Transparent drop rates as percentages, matching the exact weights used in roll().
-- @param tierId string
-- @param dropRateBoost number|nil same boost that will be applied to the roll
-- @return table { [rarityName] = percentString } e.g. { Common = "60.0%", ... }
function LootTable.getDisplayDropRates(tierId, dropRateBoost)
	local pool = LootTable.Rewards[tierId]
	if not pool then return {} end
	dropRateBoost = (typeof(dropRateBoost) == "number" and dropRateBoost > 1) and dropRateBoost or 1

	local totals, grand = {}, 0
	for _, entry in ipairs(pool) do
		local w = entry.weight
		if entry.rarity ~= "Common" then w = w * dropRateBoost end
		totals[entry.rarity] = (totals[entry.rarity] or 0) + w
		grand = grand + w
	end

	local display = {}
	for _, rarity in ipairs(LootTable.Rarities) do
		local t = totals[rarity] or 0
		display[rarity] = string.format("%.1f%%", (t / grand) * 100)
	end
	return display
end

return LootTable
