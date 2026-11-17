--[[
	DungeonHUD (LocalScript)
	========================
	Classic 2007 HUD: current wave, boss health bar (green->red blocky fill),
	run timer. Built ONLY with ClassicUI helpers — no ad-hoc Frames, no UICorner.

	Listens to WaveUpdate / BossHealthUpdate / RunComplete per Remotes signatures.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local ClassicUI = require(ReplicatedStorage:WaitForChild("ClassicUI"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local gui = Instance.new("ScreenGui")
gui.Name = "DungeonHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Top-center dialog panel (classic grey + 2px black stroke via makeFrame).
local panel = ClassicUI.makeFrame(gui, UDim2.new(0, 420, 0, 120), UDim2.new(0.5, -210, 0, 8))

local waveLabel  = ClassicUI.makeLabel(panel, "Wave: -/-", UDim2.new(0, 200, 0, 22), UDim2.new(0, 10, 0, 6))
local timerLabel = ClassicUI.makeLabel(panel, "Time: 00:00", UDim2.new(0, 200, 0, 22), UDim2.new(0, 210, 0, 6))
local bossName   = ClassicUI.makeLabel(panel, "Boss: none", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 32))

-- === Classic BLOCKY boss health bar ===
-- Outer frame = classic dialog style; inner fill = chunky green->red segments.
local barOuter = ClassicUI.makeFrame(panel, UDim2.new(1, -20, 0, 26), UDim2.new(0, 10, 0, 56))
barOuter.BorderSizePixel = 2
local barFill = Instance.new("Frame") -- NOTE: intentional child of a ClassicUI frame; it is the bar's FILL element, not a new dialog
barFill.Name = "BlockyFill"
barFill.BorderSizePixel = 0
barFill.BackgroundColor3 = ClassicUI.BEVEL_LIGHT
barFill.Size = UDim2.new(1, -4, 1, -4)
barFill.Position = UDim2.new(0, 2, 0, 2)
barFill.Parent = barOuter

-- Green-to-red classic gradient via UIGradient (the ONLY allowed gradient, per spec).
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),     -- Bright green
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)), -- Bright yellow
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),     -- Bright red
})
grad.Rotation = 90
grad.Parent = barFill

-- Chunky segment overlay simulates 2007 non-smooth bars (blocky steps, no tween).
local SEGMENTS = 20
for i = 0, SEGMENTS - 1 do
	local tick = Instance.new("Frame")
	tick.BorderSizePixel = 0
	tick.BackgroundColor3 = ClassicUI.BORDER
	tick.Size = UDim2.new(0, 2, 1, -4)
	tick.Position = UDim2.new(i / SEGMENTS, 2, 0, 2)
	tick.Parent = barOuter
end

-- ---------- state + events ----------

local runActive, startedAt = false, os.clock()

Remotes.WaveUpdate.OnClientEvent:Connect(function(runId, waveNumber, totalWaves, enemiesAlive)
	if typeof(waveNumber) ~= "number" then return end
	runActive = true
	startedAt = os.clock()
	waveLabel.Text = string.format("Wave: %d/%d  (%d foes)", waveNumber, totalWaves, enemiesAlive or 0)
end)

Remotes.BossHealthUpdate.OnClientEvent:Connect(function(runId, name, health, maxHealth)
	if typeof(health) ~= "number" or typeof(maxHealth) ~= "number" or maxHealth <= 0 then return end
	bossName.Text = "Boss: " .. tostring(name)
	local pct = math.clamp(health / maxHealth, 0, 1)
	-- Snap to segment grid = classic stepped bar, never smooth-animated.
	local snapped = math.floor(pct * SEGMENTS) / SEGMENTS
	barFill.Size = UDim2.new(snapped, -4, 1, -4)
end)

Remotes.RunComplete.OnClientEvent:Connect(function(runId, outcome, lootSummary)
	runActive = false
	waveLabel.Text = (outcome == "complete") and "RUN COMPLETE!" or "RUN FAILED"
end)

-- Run timer (1 Hz updates — cheap, classic feel).
task.spawn(function()
	while true do
		task.wait(1)
		if runActive then
			local t = math.floor(os.clock() - startedAt)
			timerLabel.Text = string.format("Time: %02d:%02d", math.floor(t / 60), t % 60)
		end
	end
end)
