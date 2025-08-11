
--=============
-- Listeners ==
--=============

EEex_Options_Private_ReadOptions(true)

EEex_GameState_AddBeforeIncludesListener(function()
	EEex_Options_Private_ReadOptions(false)
end)

EEex_Menu_AddMainFileLoadedListener(function()

	-- This should be a one-time thing, but some mods completely override the styles table in UI.MENU,
	-- preventing other mods from installing their styles via M_*.lua files. Please don't do that! :(
	EEex_Options_Private_InstallStyles()

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

EEex_Menu_AddBeforeMainFileReloadedListener(function()
	EEex_Options_Private_WasOpenBeforeReload = Infinity_IsMenuOnStack("EEex_Options")
	EEex_Options_Close()
end)

EEex_Menu_AddAfterMainFileReloadedListener(function()

	for _, tab in ipairs(EEex_Options_Private_Tabs) do
		EEex_Option_Private_InstallTabMenu(tab.layout.menuName)
	end

	if EEex_Options_Private_WasOpenBeforeReload then
		EEex_Options_Open()
	end
end)
