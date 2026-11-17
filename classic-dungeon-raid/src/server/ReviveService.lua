--[[
	ReviveService (Server Module)
	=============================
	Enforces max paid revives per run (tier.reviveCap, e.g. 3). Consumes the
	"Revive" Developer Product via a token bucket credited by MonetizationService
	(never trusts client purchase claims). Emits PlayerDied on death and answers
	RequestRevive with ReviveResult(player, success, remaining).

	PUBLIC API:
	  ReviveService.creditPaidToken(player) -> boolean   -- called by receipt handler
	  ReviveService.getRemainingRevives(player, runId) -> number
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local ReviveService = {}

local tokens = {}      -- [player] = number of PAID revive tokens available
local used   = {}      -- ["player|runId"] = revives consumed this run

local DungeonService   -- lazy require to avoid circular load

local function getDungeon()
	if not DungeonService then
		DungeonService = require(script.Parent:WaitForChild("DungeonService"))
	end
	return DungeonService
end

--- Credits one paid revive token (called ONLY from ProcessReceipt grant path).
-- @return boolean success
function ReviveService.creditPaidToken(player)
	if not player or not player.Parent then return false end
	tokens[player] = (tokens[player] or 0) + 1
	return true
end

--- Remaining revives for this player in this run (cap minus used).
function ReviveService.getRemainingRevives(player, runId)
	local state = getDungeon()._runs[runId]
	if not state then return 0 end
	local key = player.Name .. "|" .. runId
	return math.max(0, (state.reviveCap or 0) - (used[key] or 0))
end

-- ---------- death handling ----------

local function onDied(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid.Died:Connect(function()
		local state = getDungeon():getActiveRunForPlayer(player)
		if not state then return end
		-- Broadcast death so all clients can show the revive prompt context.
		Remotes.PlayerDied:FireAllClients(state.id, player.Name)

		-- Auto-Revive Game Pass holders revive free (does NOT consume cap/tokens).
		local GamePassService = require(script.Parent:WaitForChild("GamePassService"))
		if GamePassService.playerOwns(player, "AutoRevive") then
			ReviveService._doRevive(player, state.id, true)
		end
	end)
end

-- ---------- RequestRevive remote (client -> server) ----------

Remotes.RequestRevive.OnServerEvent:Connect(function(player, runId)
	-- VALIDATE CLIENT INPUT — never trust it.
	if typeof(runId) ~= "string" or runId == "" then return end
	local state = getDungeon()._runs[runId]
	if not state or (state.phase ~= "in-progress" and state.phase ~= "boss") then
		Remotes.ReviveResult:FireClient(player, false, 0); return
	end
	local inParty = false
	for _, p in ipairs(state.party) do if p == player then inParty = true end end
	if not inParty then return end

	local remaining = ReviveService.getRemainingRevives(player, runId)
	if remaining <= 0 or (tokens[player] or 0) <= 0 then
		-- Out of cap OR no confirmed paid token: refuse. Client cannot fake purchases.
		Remotes.ReviveResult:FireClient(player, false, remaining); return
	end

	tokens[player] = tokens[player] - 1
	ReviveService._doRevive(player, runId, false)
end)

--- Internal revive executor. isFree = auto-revive pass (skips cap accounting).
function ReviveService._doRevive(player, runId, isFree)
	local state = getDungeon()._runs[runId]
	if not state then
		Remotes.ReviveResult:FireClient(player, false, 0); return
	end
	if not isFree then
		local key = player.Name .. "|" .. runId
		used[key] = (used[key] or 0) + 1
	end
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then root.CFrame = CFrame.new(0, 5, 0) end -- respawn at dungeon entry
		local hum = character:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = hum.MaxHealth / 2 end -- classic half-health revive
	end
	Remotes.ReviveResult:FireClient(player, true, ReviveService.getRemainingRevives(player, runId))
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char) onDied(player, char) end)
end)
Players.PlayerRemoving:Connect(function(player)
	tokens[player] = nil
	for key in pairs(used) do
		if key:sub(1, #player.Name + 1) == player.Name .. "|" then used[key] = nil end
	end
end)

return ReviveService
