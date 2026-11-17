--[[
	RevivePrompt (LocalScript)
	==========================
	Appears on PlayerDied (for the local player). Shows remaining revives and a
	classic beveled "Revive (25 R$)" button. Styled ONLY via ClassicUI helpers.

	Flow:
	  PlayerDied(runId, victimName) -> if victim == me, show prompt
	  Button click -> MarketplaceService:PromptProductPurchase(revive dev product)
	                 AND Remotes.RequestRevive:FireServer(runId)
	  ReviveResult(success, remaining) -> update/close prompt
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local ClassicUI = require(ReplicatedStorage:WaitForChild("ClassicUI"))
local MonetizationConfig = require(ReplicatedStorage:WaitForChild("MonetizationConfig"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local gui = Instance.new("ScreenGui")
gui.Name = "RevivePrompt"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

-- Dialog built exclusively with ClassicUI helpers (no ad-hoc Frames).
local dialog = ClassicUI.makeFrame(gui, UDim2.new(0, 320, 0, 180), UDim2.new(0.5, -160, 0.5, -90))
dialog.Visible = false

ClassicUI.makeLabel(dialog, "You were defeated!", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 8))
local remainingLabel = ClassicUI.makeLabel(dialog, "Revives left: 3", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 36))

local reviveButton = ClassicUI.makeButton(dialog, "Revive (25 R$)", UDim2.new(0, 200, 0, 36), UDim2.new(0.5, -100, 0, 74))
local closeButton  = ClassicUI.makeButton(dialog, "Wait for team", UDim2.new(0, 200, 0, 36), UDim2.new(0.5, -100, 0, 118))

local currentRunId = nil

Remotes.PlayerDied.OnClientEvent:Connect(function(runId, victimName)
	if typeof(runId) ~= "string" then return end
	if victimName ~= player.Name then return end -- teammate death: HUD toast only
	currentRunId = runId
	dialog.Visible = true
end)

reviveButton.Activated:Connect(function()
	if not currentRunId then return end
	-- Open native Robux purchase; ProcessReceipt credits the token server-side.
	MarketplaceService:PromptProductPurchase(player, MonetizationConfig.DevProducts.Revive)
	-- Server validates token + cap; fires ReviveResult back to us.
	Remotes.RequestRevive:FireServer(currentRunId) -- signature: (runId: string)
end)

closeButton.Activated:Connect(function()
	dialog.Visible = false
	currentRunId = nil
end)

Remotes.ReviveResult.OnClientEvent:Connect(function(success, remaining)
	-- Signature: FireClient(player, success: boolean, remaining: number)
	if typeof(success) ~= "boolean" or typeof(remaining) ~= "number" then return end
	remainingLabel.Text = "Revives left: " .. math.floor(remaining)
	if success then
		dialog.Visible = false
		currentRunId = nil
	else
		remainingLabel.TextColor3 = ClassicUI.BORDER
	end
end)
