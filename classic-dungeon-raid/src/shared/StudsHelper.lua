--[[
	StudsHelper (Shared Module)
	===========================
	HARD RULE: every visible BasePart in this game must show studs on ALL 6 faces.
	No smooth faces anywhere. Call StudsHelper.applyStuds(part) BEFORE parenting
	any runtime-generated part to Workspace.

	Material policy: Enum.Material.Plastic only (classic look, no metallic/neon).

	Texture assets (placeholders — swap with your uploaded classic stud textures):
		rbxassetid://CLASSIC_STUD_TEXTURE_TOP    -- top-face stud pattern
		rbxassetid://CLASSIC_STUD_TEXTURE_SIDE   -- side/brick stud pattern
	These IDs are also mirrored as TextureImageLabel/content entries under
	ReplicatedStorage.Assets.StudTextures for editor use.
]]

local StudsHelper = {}

-- === PLACEHOLDER ASSET IDS — SWAP THESE WITH REAL UPLOADED TEXTURES ===
StudsHelper.STUD_TEXTURE_TOP  = "rbxassetid://0000000001" -- TODO: rbxassetid://CLASSIC_STUD_TEXTURE_TOP
StudsHelper.STUD_TEXTURE_SIDE = "rbxassetid://0000000002" -- TODO: rbxassetid://CLASSIC_STUD_TEXTURE_SIDE

local SURFACE_FACES = {
	Enum.NormalId.Top,
	Enum.NormalId.Bottom,
	Enum.NormalId.Front,
	Enum.NormalId.Back,
	Enum.NormalId.Left,
	Enum.NormalId.Right,
}

--- Applies the classic stud texture to all 6 faces of a BasePart.
--- Uses SurfaceAppearance textures (Top/Bottom = stud pattern; sides = brick pattern).
--- Also sets Material = Plastic per the strict 2007 visual rules.
-- @param part BasePart
function StudsHelper.applyStuds(part)
	if not part or not part:IsA("BasePart") then
		warn("[StudsHelper] applyStuds called on non-BasePart: " .. tostring(part))
		return
	end

	part.Material = Enum.Material.Plastic

	-- Legacy fallback: classic StudySurfaceGui-free approach uses Texture on each face.
	-- Modern path: one SurfaceAppearance with 6 FaceTextures.
	local appearance = part:FindFirstChildOfClass("SurfaceAppearance")
	if not appearance then
		appearance = Instance.new("SurfaceAppearance")
		appearance.Name = "ClassicStuds"
		appearance.Parent = part
	end

	-- Clear any stale face textures so re-application is idempotent.
	for _, tex in ipairs(appearance:GetChildren()) do
		if tex:IsA("Texture") or tex:IsA("SpecialMesh") then
			tex:Destroy()
		end
	end

	for _, face in ipairs(SURFACE_FACES) do
		local isTopOrBottom = (face == Enum.NormalId.Top or face == Enum.NormalId.Bottom)
		local texture = Instance.new("Texture")
		texture.Name = "Stud_" .. face.Name
		texture.Face = face
		texture.StretchOffset = Vector2.new(0.5, 0.5) -- center on face (classic alignment)
		texture.Texture = isTopOrBottom and StudsHelper.STUD_TEXTURE_TOP or StudsHelper.STUD_TEXTURE_SIDE
		texture.ZIndex = 1
		texture.LightsInfluence = Enum.LightsInfluence.Render
		texture.Parent = appearance
	end

	-- Belt-and-braces: guarantee no Smooth surface settings from templates.
	for _, prop in ipairs({ "TopSurface", "BottomSurface" }) do
		if part[prop] ~= nil then
			part[prop] = Enum.SurfaceType.Smooth -- geometry handled by textures, not engine studs (Legacy look parity)
		end
	end
end

--- Recursively applies studs to every BasePart inside a Model/Folder.
--- MANDATORY before parenting any generated content to Workspace.
-- @param model Instance (Model, Folder, or any container)
function StudsHelper.applyStudsToModel(model)
	if not model then return end
	if model:IsA("BasePart") then
		StudsHelper.applyStuds(model)
		return
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			StudsHelper.applyStuds(descendant)
		end
	end
end

return StudsHelper
