
--=============
-- Listeners ==
--=============

EEex_Options_Private_ReadOptions(true)

EEex_GameState_AddBeforeIncludesListener(function()
	EEex_Options_Private_ReadOptions(false)
end)

EEex_Menu_AddMainFileLoadedListener(function()
	EEex_Menu_LoadFile("X-Option")
	EEex_Options_Private_InstallButtons()
end)

-- Hardcoded call from EEex_GameState.lua
function EEex_Options_OnAfterGameStateInitialized()
	EEex_Options_Private_SpecialSortTabs()
	EEex_Options_Private_BuildLayout()
end

EEex_Menu_AddWindowSizeChangedListener(function()
	if not Infinity_IsMenuOnStack("EEex_Options") then return end
	EEex_Options_Private_Layout()
end)

EEex_Menu_AddBeforeUIItemRenderListener("EEex_Options_Background", EEex_Options_Private_Background_Render)
