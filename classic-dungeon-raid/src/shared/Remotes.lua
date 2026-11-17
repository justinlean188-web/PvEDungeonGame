--[[
	Remotes (Shared Module)
	=======================
	Single source of truth for every RemoteEvent. Creates them on first access
	(server or client) under ReplicatedStorage.Remotes, and fetches thereafter.

	EXPLICIT SIGNATURES (never change without updating both sides):

	  PlayerDied        (server -> all clients)
	    FireAllClients(runId: string, victimName: string)

	  RequestRevive     (client -> server)
	    FireServer(runId: string)                    -- runId MUST be a non-empty string

	  ReviveResult      (server -> one client)
	    FireClient(player, success: boolean, remaining: number)

	  WaveUpdate        (server -> all clients)
	    FireAllClients(runId: string, waveNumber: number, totalWaves: number, enemiesAlive: number)

	  BossHealthUpdate  (server -> all clients)
	    FireAllClients(runId: string, bossName: string, health: number, maxHealth: number)

	  RunComplete       (server -> all clients)
	    FireAllClients(runId: string, outcome: "complete"|"failed", lootSummary: { {name=rarity} })

	The module also exposes Remotes.PurchasePrompt (BindableEvent, client-side)
	so UI can open native purchase dialogs: Fire(devProductId: number).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local EVENT_NAMES = {
	"PlayerDied",
	"RequestRevive",
	"ReviveResult",
	"WaveUpdate",
	"BossHealthUpdate",
	"RunComplete",
}

local container = ReplicatedStorage:FindFirstChild("Remotes")
if not container then
	container = Instance.new("Folder")
	container.Name = "Remotes"
	-- On Play-Solo, the server creates it first; clients WaitForChild below.
	if game:GetService("RunService"):IsServer() then
		container.Parent = ReplicatedStorage
	end
end

for _, name in ipairs(EVENT_NAMES) do
	local remote = container:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		if game:GetService("RunService"):IsServer() then
			remote.Parent = container
		else
			remote.Parent = container -- replicated copy; harmless locally
		end
	end
	Remotes[name] = remote
end

--- Client-safe accessor: waits for server-created remotes to replicate.
-- @param name string
-- @return RemoteEvent
function Remotes.get(name)
	return container:WaitForChild(name, 30)
end

return Remotes
