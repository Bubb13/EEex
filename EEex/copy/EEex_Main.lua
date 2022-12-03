
----------
-- Main --
----------

EEex_DoFile("EEex_Assembly")
EEex_LoadLuaBindings("LuaBindings-v2.6.6.0", function()
	EEex_GlobalAssemblyLabels = EEex_GetPatternMap()
	EEex_DoFile("EEex_LuaBindings_Patch")
end)
EEex_DoFile("EEex_Assembly_Patch")

EEex_DoFile("EEex_MemoryManagerDefinitions")

EEex_DoFile("EEex_Action")
EEex_DoFile("EEex_Action_Patch")

EEex_DoFile("EEex_Actionbar")
EEex_DoFile("EEex_Actionbar_Patch")

EEex_DoFile("EEex_AIBase")

EEex_DoFile("EEex_Area")

EEex_DoFile("EEex_Fix")
EEex_DoFile("EEex_Fix_Patch")

EEex_DoFile("EEex_GameObject")
EEex_DoFile("EEex_GameObject_Patch")

EEex_DoFile("EEex_GameState")
EEex_DoFile("EEex_GameState_Patch")

EEex_DoFile("EEex_Key")
EEex_DoFile("EEex_Key_Patch")

EEex_DoFile("EEex_Menu")
EEex_DoFile("EEex_Menu_Patch")

EEex_DoFile("EEex_Object")
EEex_DoFile("EEex_Object_Patch")

EEex_DoFile("EEex_Opcode")
EEex_DoFile("EEex_Opcode_Patch")

EEex_DoFile("EEex_Resource")

EEex_DoFile("EEex_Script")
EEex_DoFile("EEex_Script_Patch")

EEex_DoFile("EEex_Sprite")
EEex_DoFile("EEex_Sprite_Patch")

EEex_DoFile("EEex_Stats")
EEex_DoFile("EEex_Stats_Patch")

EEex_DoFile("EEex_Trigger")
EEex_DoFile("EEex_Trigger_Patch")

EEex_DoFile("EEex_Utility")

EEex_DoFile("EEex_Variable")

EEex_DoFile("EEex_Debug")

EEex_GameState_AddInitializedListener(function()
	EEex_DoFile("EEex_UserDataGlobals")
	EEex_DoFile("EEex_Opcode_Init")
end)

EEex_DoFile("EEex_Modules")
for moduleName, enabled in pairs(EEex_Modules) do
	if enabled then
		EEex_DoFile(moduleName)
	end
end

-- Stops a call to SDL_LogOutput() higher in this file
-- preventing the console from attaching later on
EEex_Write32(EEex_Label("Data-EngineConsoleAttachedPtr"), 0)

EEex_Active = true
