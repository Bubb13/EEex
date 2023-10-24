
-- This is the main startup file for EEex. InfinityLoader redirects control flow after the CALL instruction
-- located at [Hardcoded_InternalPatchLocation] in order to (potentially) initialize Lua, initialize
-- hardcoded EEex state, and call this file.

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

	-- Contains most of the code editing functions. This file is the core of EEex.
	EEex_DoFile("EEex_Assembly")

	-- Contains Lua bindings that map engine structures to Lua
	EEex_OpenLuaBindings("LuaBindings-v2.6.6.0", function()
		-- Patches in-engine tolua functions with EEex versions.
		-- These are required for proper bindings operation.
		EEex_DoFile("EEex_LuaBindings_Patch")
	end)

	-- Contains EEex's C++ functionality
	EEex_OpenLuaBindings("EEex")
	EEex_DoFile("EEex_IntegrityCheck")

	-- Defines information about usertypes for the EEex_MemoryManager helper
	EEex_DoFile("EEex_MemoryManagerDefinitions")

	-- Run EEex's other files (which each pertain to a specific category)
	for _, fileName in ipairs(not EEex_Main_MinimalStutterStartup
		and EEex_Main_Private_NormalStartupFiles
		or  EEex_Main_Private_MinimalStutterStartupFiles)
	do
		EEex_DoFile(fileName)
	end

	if not EEex_Main_MinimalStutterStartup then

		-- This file may run before the game is initialized.
		-- The following listener runs files that need to
		-- wait for the game to be somewhat initialized.
		EEex_GameState_AddInitializedListener(function()
			EEex_DoFile("EEex_UserDataGlobals")
			EEex_DoFile("EEex_StutterDetector")
		end)

		-- Run EEex_Modules.lua, which determines the enabled EEex modules
		EEex_DoFile("EEex_Modules")
		for moduleName, enabled in pairs(EEex_Modules) do
			if enabled then
				-- Load the enabled modules
				EEex_DoFile(moduleName)
			end
		end
	end

	-- Stops a call to SDL_LogOutput() higher in this file
	-- preventing the console from attaching later on
	EEex_Write32(EEex_Label("Data-EngineConsoleAttachedPtr"), 0)

	EEex_Active = true

end)()
