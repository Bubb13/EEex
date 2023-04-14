
-------------
-- Options --
-------------

EEex_Main_MinimalStutterStartup = false

----------------------------------
-- Startup Config (Do not edit) --
----------------------------------

EEex_Main_Private_NormalStartupFiles = {
	"EEex_Action",
	"EEex_Action_Patch",
	"EEex_Actionbar",
	"EEex_Actionbar_Patch",
	"EEex_AIBase",
	"EEex_Area",
	"EEex_Fix",
	"EEex_Fix_Patch",
	"EEex_GameObject",
	"EEex_GameObject_Patch",
	"EEex_GameState",
	"EEex_GameState_Patch",
	"EEex_Key",
	"EEex_Key_Patch",
	"EEex_Menu",
	"EEex_Menu_Patch",
	"EEex_Object",
	"EEex_Object_Patch",
	"EEex_Opcode",
	"EEex_Opcode_Patch",
	"EEex_Projectile",
	"EEex_Projectile_Patch",
	"EEex_Resource",
	"EEex_Script",
	"EEex_Script_Patch",
	"EEex_Sprite",
	"EEex_Sprite_Patch",
	"EEex_Stats",
	"EEex_Stats_Patch",
	"EEex_Trigger",
	"EEex_Trigger_Patch",
	"EEex_Utility",
	"EEex_Variable",
	"EEex_Debug",
}

EEex_Main_Private_MinimalStutterStartupFiles = {
	"EEex_GameState",
	"EEex_GameState_Patch",
	"EEex_Menu",
	"EEex_Menu_Patch",
	"EEex_Resource",
	"EEex_Utility",
}

----------
-- Main --
----------

(function()

	EEex_DoFile("EEex_Assembly")
	EEex_LoadLuaBindings("LuaBindings-v2.6.6.0", function()
		EEex_GlobalAssemblyLabels = EEex_GetPatternMap()
		EEex_DoFile("EEex_LuaBindings_Patch")
	end)
	EEex_DoFile("EEex_Assembly_Patch")

	EEex_DoFile("EEex_MemoryManagerDefinitions")

	for _, fileName in ipairs(not EEex_Main_MinimalStutterStartup
		and EEex_Main_Private_NormalStartupFiles
		or  EEex_Main_Private_MinimalStutterStartupFiles)
	do
		EEex_DoFile(fileName)
	end

	if not EEex_Main_MinimalStutterStartup then
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
	end

	EEex_DoFile("EEex_StutterDetector")

	-- Stops a call to SDL_LogOutput() higher in this file
	-- preventing the console from attaching later on
	EEex_Write32(EEex_Label("Data-EngineConsoleAttachedPtr"), 0)

	EEex_Active = true

end)()
