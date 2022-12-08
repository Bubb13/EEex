
----------
-- Main --
----------

EEex_DoFile("EEex_Assembly")
EEex_LoadLuaBindings("LuaBindings-PSTEE", function()
    EEex_GlobalAssemblyLabels = EEex_GetPatternMap()
	EEex_DoFile("EEex_LuaBindings_Patch")
end)
EEex_DoFile("EEex_Assembly_Patch")

EEex_DoFile("EEex_GameObject")
EEex_DoFile("EEex_Utility")

-- Stops a call to SDL_LogOutput() higher in this file
-- preventing the console from attaching later on
EEex_Write32(EEex_Label("Data-EngineConsoleAttachedPtr"), 0)
