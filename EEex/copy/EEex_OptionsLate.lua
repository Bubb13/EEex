
--=============
-- Listeners ==
--=============

EEex_GameState_AddBeforeIncludesListener(function()
	EEex_Options_Private_ReadOptions()
end)

EEex_Menu_AddMainFileLoadedListener(function()
	EEex_Menu_LoadFile("X-Option")
end)

-- Hardcoded call from EEex_GameState.lua
function EEex_Options_OnAfterGameStateInitialized()
	EEex_Options_Private_BuildLayout()
end

EEex_Menu_AddWindowSizeChangedListener(function()
	if not Infinity_IsMenuOnStack("EEex_Options") then return end
	EEex_Options_Private_Layout()
end)

EEex_Key_AddPressedListener(function(key)
	if key == EEex_Key_GetFromName("\\") then
		EEex_Options_Open()
	end
end)
