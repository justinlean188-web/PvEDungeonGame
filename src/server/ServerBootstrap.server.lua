--[[
	ServerBootstrap (Script)
	========================
	Wires the server module graph in dependency-safe order and enforces the
	2007 visual rules at DataModel level: Legacy lighting, R6 blocky characters,
	no terrain (studded parts only).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

-- === 2007 LIGHTING LOCK (see default.project.json for replicated props) ===
pcall(function() Lighting.Technology = Enum.Technology.Legacy end) -- Voxel fallback if removed
Lighting.Ambient = Color3.fromRGB(0, 0, 0)
Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
Lighting.Brightness = 1
Lighting.GlobalShadows = false
for _, inst in ipairs(Lighting:GetChildren()) do
	if inst:IsA("Atmosphere") or inst:IsA("FogAtmosphere") or inst:IsA("ColorCorrectionEffect") then
		inst:Destroy() -- no atmosphere/fog/modern effects allowed
	end
end

-- === Classic sky (placeholder — swap with rbxasset:// classic sky if desired) ===
local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxassetid://1010000"   -- TODO: CLASSIC_SKY_BACK
sky.SkyboxDn = "rbxassetid://1010001"   -- TODO: CLASSIC_SKY_DOWN
sky.SkyboxFt = "rbxassetid://1010002"   -- TODO: CLASSIC_SKY_FRONT
sky.SkyboxLf = "rbxassetid://1030000"   -- TODO: CLASSIC_SKY_LEFT
sky.SkyboxRt = "rbxassetid://1030001"   -- TODO: CLASSIC_SKY_RIGHT
sky.SkyboxUp = "rbxassetid://1020000"   -- TODO: CLASSIC_SKY_UP
sky.Parent = Lighting

-- === Terrain: disabled entirely; dungeon built from studded Parts ===
if workspace.Terrain then workspace.Terrain:ClearCellsAsync() end

-- === R6 blocky characters (no R15, no meshes) ===
Players.CharacterAutoLoads = true
game.StarterPlayer.CharacterAutoScale = false
game.StarterPlayer.AvatarType = Enum.AvatarType.R6

-- === Load services (module init wires their remote/receipt handlers) ===
require(script:WaitForChild("GamePassService"))
require(script:WaitForChild("MonetizationService"))
require(script:WaitForChild("ReviveService"))
require(script:WaitForChild("LootService"))
local DungeonService = require(script:WaitForChild("DungeonService"))

-- Placeholder lobby floor so something studded exists at test time.
local StudsHelper = require(ReplicatedStorage:WaitForChild("StudsHelper"))
local ClassicPalette = require(ReplicatedStorage:WaitForChild("ClassicPalette"))
local floor = Instance.new("Part")
floor.Name = "LobbyFloor"
floor.Size = Vector3.new(204, 1, 204)
floor.Anchored = true
floor.Position = Vector3.new(0, -0.5, 0)
floor.BrickColor = ClassicPalette.MediumStoneGrey
StudsHelper.applyStuds(floor)
floor.Parent = workspace

-- Simple entry NPC button: touches start tier1 run (swap for real portal UI).
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
print("[ServerBootstrap] classic dungeon scaffold ready. Use admin: DungeonService.startRun(player,'tier1')")
