--[[
	ClassicUI (Shared Module)
	=========================
	The ONLY sanctioned way to create UI in this game. All frames/buttons/labels
	follow the 2007 dialog style:

	  - Fill: Color3.fromRGB(128, 128, 128), border: 2px black UIStroke
	  - Buttons: classic bevel (light top-left edge, dark bottom-right edge)
	  - Font: Enum.Font.SourceSans only
	  - FORBIDDEN: UICorner (no rounded corners), drop shadows, blur,
	    gradients other than the classic grey button gradient.

	Usage:
	  local ClassicUI = require(ReplicatedStorage:WaitForChild("ClassicUI"))
	  local frame = ClassicUI.makeFrame(playerGui, UDim2.fromScale(0.5,0.5), UDim2.fromScale(0,0.25))
]]

local ClassicUI = {}

-- === 2007 dialog palette (Color3 — these are UI colors, not BrickColors) ===
ClassicUI.FILL        = Color3.fromRGB(128, 128, 128) -- classic dialog grey
ClassicUI.BORDER      = Color3.fromRGB(0, 0, 0)       -- 2px black border
ClassicUI.BEVEL_LIGHT = Color3.fromRGB(224, 224, 224) -- light top-left edge
ClassicUI.BEVEL_DARK  = Color3.fromRGB(64, 64, 64)    -- dark bottom-right edge
ClassicUI.TEXT_DARK   = Color3.fromRGB(0, 0, 0)
ClassicUI.FONT        = Enum.Font.SourceSans           -- no modern fonts allowed

--- Creates a studs-style classic dialog frame. Adds 2px black UIStroke.
-- @param parent Instance (ScreenGui / Frame)
-- @param size UDim2
-- @param position UDim2
-- @return Frame
function ClassicUI.makeFrame(parent, size, position)
	assert(parent, "ClassicUI.makeFrame: parent required")
	local frame = Instance.new("Frame")
	frame.Name = "ClassicFrame"
	frame.Size = size or UDim2.new(0, 200, 0, 120)
	frame.Position = position or UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = ClassicUI.FILL
	frame.BorderSizePixel = 1 -- legacy 1px inner edge; real border is the stroke below
	-- NO UICorner anywhere. Ever.
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = ClassicUI.BORDER
	stroke.ApplyMode = Enum.StrokeApplyMode.OutlineStroke
	stroke.Parent = frame
	frame.Parent = parent
	return frame
end

--- Creates a classic beveled button: light edges top/left, dark edges bottom/right.
-- @param parent Instance
-- @param text string
-- @param size UDim2
-- @param position UDim2
-- @return TextButton
function ClassicUI.makeButton(parent, text, size, position)
	assert(parent, "ClassicUI.makeButton: parent required")
	local button = Instance.new("TextButton")
	button.Name = "ClassicButton"
	button.Text = text or "Button"
	button.Size = size or UDim2.new(0, 160, 0, 32)
	button.Position = position or UDim2.new(0, 0, 0, 0)
	button.BackgroundColor3 = ClassicUI.FILL
	button.Font = ClassicUI.FONT
	button.TextColor3 = ClassicUI.TEXT_DARK
	button.TextSize = 16
	button.AutoButtonColor = false -- classic buttons don't tint on hover
	button.BorderSizePixel = 0

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = ClassicUI.BORDER
	stroke.Parent = button

	-- Bevel: two nested 2px Frames simulate the classic raised edge.
	local lightEdge = Instance.new("Frame")
	lightEdge.Name = "BevelLight"
	lightEdge.BorderSizePixel = 0
	lightEdge.BackgroundColor3 = ClassicUI.BEVEL_LIGHT
	lightEdge.Size = UDim2.new(1, -2, 0, 2)
	lightEdge.Position = UDim2.new(0, 1, 0, 1)
	lightEdge.Parent = button

	local leftEdge = lightEdge:Clone()
	leftEdge.Name = "BevelLightLeft"
	leftEdge.Size = UDim2.new(0, 2, 1, -2)
	leftEdge.Position = UDim2.new(0, 1, 0, 1)
	leftEdge.Parent = button

	local darkEdge = Instance.new("Frame")
	darkEdge.Name = "BevelDark"
	darkEdge.BorderSizePixel = 0
	darkEdge.BackgroundColor3 = ClassicUI.BEVEL_DARK
	darkEdge.Size = UDim2.new(1, -2, 0, 2)
	darkEdge.Position = UDim2.new(0, 1, -2, -1)
	darkEdge.Parent = button

	local rightEdge = darkEdge:Clone()
	rightEdge.Name = "BevelDarkRight"
	rightEdge.Size = UDim2.new(0, 2, 1, -2)
	rightEdge.Position = UDim2.new(-2, -1, 0, 1)
	rightEdge.Parent = button

	button.Parent = parent
	return button
end

--- Creates a classic label (transparent background, black SourceSans text).
-- @param parent Instance
-- @param text string
-- @param size UDim2
-- @param position UDim2
-- @returnTextLabel
function ClassicUI.makeLabel(parent, text, size, position)
	assert(parent, "ClassicUI.makeLabel: parent required")
	local label = Instance.new("TextLabel")
	label.Name = "ClassicLabel"
	label.Text = text or ""
	label.Size = size or UDim2.new(1, 0, 0, 20)
	label.Position = position or UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = ClassicUI.FONT
	label.TextColor3 = ClassicUI.TEXT_DARK
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

return ClassicUI
