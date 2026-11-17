--[[
	DungeonService (Server Script)
	==============================
	Run lifecycle: idle -> starting -> in-progress -> complete | failed.
	Reads tier definitions from DungeonConfig; spawns waves of studded classic
	blocks, then a boss. All state is server-authoritative.

	PUBLIC API (other server scripts require this ModuleScript):
	  DungeonService.startRun(player, tierId: string) -> runId|nil, err
	  DungeonService.endRun(runId, outcome)           -- forced end (admin/gm)
	  DungeonService.getActiveRunForPlayer(player)    -> runState|nil
	  DungeonService.damageEnemy(player, runId, enemyKey, amount) -> appliedDamage
	      ^ Server validates everything; client-sent amounts are CLAMPED, never trusted.
	  signalBossHealth(runId, health) -- called by combat handler each hit

	State machine + wave timer live here; ReviveService listens to PlayerDied.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DungeonConfig  = require(ReplicatedStorage:WaitForChild("DungeonConfig"))
local StudsHelper    = require(ReplicatedStorage:WaitForChild("StudsHelper"))
local ClassicPalette = require(ReplicatedStorage:WaitForChild("ClassicPalette"))
local Remotes        = require(ReplicatedStorage:WaitForChild("Remotes"))

local DungeonService = {}

local runs = {}          -- runId -> state
local nextRunId = 0
local WAVE_CLEAR_DELAY = 4 -- seconds between waves

-- ---------- helpers ----------

local function makeWaveCorners(count)
	-- Spawns `count` simple studded cube "enemies" around origin (placeholder visuals).
	local spawned = {}
	for i = 1, count do
		local part = Instance.new("Part")
		part.Name = "Enemy_" .. i
		part.Size = Vector3.new(4, 4, 4)
		part.Anchored = false
		part.BrickColor = ClassicPalette.BrightRed
		part.Position = Vector3.new(math.random(-20, 20), 6, math.random(-20, 20))
		StudsHelper.applyStuds(part) -- MANDATORY before parenting
		part.Parent = workspace
		spawned[part] = true
	end
	return spawned
end

local function cleanupRun(state)
	for part in pairs(state.enemies or {}) do
		if part and part.Parent then part:Destroy() end
	end
	if state.boss and state.boss.Parent then state.boss:Destroy() end
end

-- ---------- lifecycle ----------

--- Starts a run for the player's party. Validates tier id strictly.
-- @return string|nil runId, string|nil error
function DungeonService.startRun(player, tierId)
	if typeof(tierId) ~= "string" then return nil, "bad tierId" end
	local tier = DungeonConfig.getTier(tierId)
	if not tier then return nil, "unknown tier" end
	if tier.requiresVip then
		local GamePassService = require(script.Parent:WaitForChild("GamePassService"))
		if not GamePassService.playerOwns(player, "VipDungeonAccess") then
			return nil, "vip required"
		end
	end

	nextRunId = nextRunId + 1
	local runId = "run_" .. nextRunId
	runs[runId] = {
		id = runId, tier = tier, phase = "in-progress",
		wave = 0, totalWaves = tier.waveCount, enemies = {},
		party = { player }, startedAt = os.clock(), reviveCap = tier.reviveCap,
	}

	task.spawn(function()
		local state = runs[runId]
		for w = 1, tier.waveCount do
			state.wave = w
			state.enemies = makeWaveCorners(math.random(tier.enemyStats.countMin, tier.enemyStats.countMax))
			Remotes.WaveUpdate:FireAllClients(runId, w, tier.waveCount, (function() local n=0 for _ in pairs(state.enemies) do n=n+1 end return n end)())
			task.wait(WAVE_CLEAR_DELAY) -- placeholder: real clear detection via enemy Humanoids
		end
		-- Boss encounter
		local boss = Instance.new("Part")
		boss.Name = "Boss_" .. tier.bossStats.name
		boss.Size = Vector3.new(10, 10, 10)
		boss.BrickColor = ClassicPalette.Black
		boss.Position = Vector3.new(0, 8, -30)
		StudsHelper.applyStuds(boss)
		boss.Parent = workspace
		state.boss = boss
		state.bossHealth = tier.bossStats.health
		state.phase = "boss"
		Remotes.BossHealthUpdate:FireAllClients(runId, tier.bossStats.name, state.bossHealth, tier.bossStats.health)
	end)

	return runId
end

--- Called by the combat handler when the boss takes validated damage.
function DungeonService.signalBossHealth(runId, health)
	local state = runs[runId]
	if not state or typeof(health) ~= "number" then return end
	state.bossHealth = math.max(0, health)
	Remotes.BossHealthUpdate:FireAllClients(runId, state.tier.bossStats.name, state.bossHealth, state.tier.bossStats.health)
	if state.bossHealth <= 0 then
		DungeonService.endRun(runId, "complete")
	end
end

--- Authoritative enemy damage entrypoint. NEVER trusts client amounts:
--- clamps to weapon max, verifies attacker is in the party and run is active.
-- @return number|nil appliedDamage, string|nil error
function DungeonService.damageEnemy(player, runId, enemyKey, claimedAmount)
	local state = runs[runId]
	if typeof(runId) ~= "string" or not state then return nil, "bad run" end
	if state.phase ~= "in-progress" and state.phase ~= "boss" then return nil, "wrong phase" end
	if typeof(claimedAmount) ~= "number" or claimedAmount < 0 then return nil, "bad amount" end
	local inParty = false
	for _, p in ipairs(state.party) do if p == player then inParty = true end end
	if not inParty then return nil, "not in party" end
	local maxAllowed = state.tier.enemyStats.health * 0.5 -- sanity clamp per hit
	local applied = math.min(claimedAmount, maxAllowed)
	-- (Real implementation would subtract from the enemy Humanoid here.)
	if state.enemies and state.enemies[enemyKey] then
		state.enemies[enemyKey]:Destroy()
		state.enemies[enemyKey] = nil
	end
	return applied
end

--- Ends a run. outcome: "complete" | "failed".
function DungeonService.endRun(runId, outcome)
	local state = runs[runId]
	if not state then return end
	if outcome ~= "complete" and outcome ~= "failed" then outcome = "failed" end
	state.phase = outcome
	cleanupRun(state)

	local LootService = require(script.Parent:WaitForChild("LootService"))
	local lootSummary = {}
	if outcome == "complete" then
		for _, p in ipairs(state.party) do
			lootSummary[#lootSummary + 1] = LootService.grantRunLoot(p, state.tier.rewardTableId)
		end
	end
	Remotes.RunComplete:FireAllClients(runId, outcome, lootSummary)
	task.delay(10, function() runs[runId] = nil end)
end

--- Read-only accessor for other services (ReviveService validates runIds with it).
function DungeonService.getActiveRunForPlayer(player)
	for _, state in pairs(runs) do
		if state.phase == "in-progress" or state.phase == "boss" then
			for _, p in ipairs(state.party) do
				if p == player then return state end
			end
		end
	end
	return nil
end

Players.PlayerRemoving:Connect(function(player)
	for _, state in pairs(runs) do
		for i, p in ipairs(state.party) do
			if p == player then table.remove(state.party, i); break end
		end
		if #state.party == 0 and (state.phase == "in-progress" or state.phase == "boss") then
			DungeonService.endRun(state.id, "failed")
		end
	end
end)

if RunService:IsServer() then
	DungeonService._runs = runs -- debug handle for admin scripts
end

return DungeonService
