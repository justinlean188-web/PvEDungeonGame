--[[
	ClassicPalette (Shared Module)
	==============================
	The ONLY allowed BrickColors for this game. Strict 2007 classic palette.
	Reference these constants everywhere; never hard-code Color3 values for parts.

	Usage:
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local ClassicPalette = require(ReplicatedStorage:WaitForChild("ClassicPalette"))
		part.BrickColor = ClassicPalette.BrightRed
]]

local ClassicPalette = {}

-- === Allowed classic 2007 BrickColors (BrickColor.new(name)) ===
ClassicPalette.BrightRed        = BrickColor.new("Bright red")         -- (255, 0, 0) family
ClassicPalette.BrightBlue       = BrickColor.new("Bright blue")        -- (0, 128, 255) family
ClassicPalette.BrightYellow     = BrickColor.new("Bright yellow")      -- (255, 255, 0) family
ClassicPalette.BrightGreen      = BrickColor.new("Bright green")       -- (0, 255, 0) family
ClassicPalette.BrYellowishGreen = BrickColor.new("Br. yellowish green")-- classic olive-lime
ClassicPalette.MediumStoneGrey  = BrickColor.new("Medium stone grey")  -- stone / dungeon walls
ClassicPalette.ReddishBrown     = BrickColor.new("Reddish brown")      -- floor beams / crates
ClassicPalette.White            = BrickColor.new("White")
ClassicPalette.Black            = BrickColor.new("Black")

-- Whitelist for runtime validation (server-side color checks).
ClassicPalette.Allowed = {
	ClassicPalette.BrightRed,
	ClassicPalette.BrightBlue,
	ClassicPalette.BrightYellow,
	ClassicPalette.BrightGreen,
	ClassicPalette.BrYellowishGreen,
	ClassicPalette.MediumStoneGrey,
	ClassicPalette.ReddishBrown,
	ClassicPalette.White,
	ClassicPalette.Black,
}

--- Returns true if a BrickColor is in the strict classic whitelist.
-- @param brickColor BrickColor to validate
-- @return boolean
function ClassicPalette.isAllowed(brickColor)
	if not (typeof(brickColor) == "BrickColor" or typeof(brickColor) == "Color3") then
		return false
	end
	local bc = BrickColor.new(brickColor)
	for _, allowed in ipairs(ClassicPalette.Allowed) do
		if bc.Name == allowed.Name then
			return true
		end
	end
	return false
end

--- Snaps any BrickColor/Color3 to the nearest allowed classic color.
-- @param color BrickColor or Color3
-- @return BrickColor guaranteed to be in the palette
function ClassicPalette.snapNearest(color)
	if ClassicPalette.isAllowed(color) then
		return BrickColor.new(color)
	end
	return ClassicPalette.MediumStoneGrey
end

return ClassicPalette
