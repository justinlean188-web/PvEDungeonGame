-- Asset manifest (runtime module).
-- Lives in ReplicatedStorage (src/shared) because src/assets must stay a pure Folder
-- for Rojo; require it as: require(ReplicatedStorage.AssetManifest)
return {
	["StudTextures"] = {
		["ClassicStudsTop"]  = "rbxassetid://0000000001", -- TODO: CLASSIC_STUD_TEXTURE_TOP
		["ClassicStudsSide"] = "rbxassetid://0000000002", -- TODO: CLASSIC_STUD_TEXTURE_SIDE
	},
	["UIMusicAndSfx"] = {
		["ClassicClick"] = "rbxassetid://0000000003", -- TODO: classic button click sfx
		["DeathTrombone"] = "rbxassetid://0000000004", -- TODO: optional death sfx
	},
	["Fonts"] = {
		-- 2007 style uses built-in SourceSans/Legacy only. Upload custom fonts
		-- here ONLY if you must; otherwise leave empty.
	},
	["PartTemplates"] = {
		-- Insert real .rbxm models via Rojo as child folders here, e.g.:
		-- src/assets/PartTemplates/DungeonWallSegment.rbxm
		-- Every template part must be run through StudsHelper.applyStudsToModel
		-- on spawn, even if pre-textured in Studio.
	},
}
