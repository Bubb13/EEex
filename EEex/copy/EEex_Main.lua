
-- This is the main startup file for EEex. InfinityLoader redirects control flow after the CALL instruction
-- located at [Hardcoded_InternalPatchLocation] in order to (potentially) initialize Lua, initialize
-- hardcoded EEex state, and call this file.

----------------------------------
-- Startup Config (Do not edit) --
----------------------------------

EEex_Main_Private_StartupFiles = {
	"EEex_Utility",          -- Here so all EEex files can immediately use utility functions
	"EEex_Key",              -- Here because it is required by EEex_Options.lua
	"EEex_Key_Patch",        --
	"EEex_Options",          -- Here so most EEex files can register options
	"EEex_Action",           --
	"EEex_Action_Patch",     --
	"EEex_Actionbar",        --
	"EEex_Actionbar_Patch",  --
	"EEex_AIBase",           --
	"EEex_AIBase_Patch",     --
	"EEex_Area",             --
	"EEex_Fix",              --
	"EEex_Fix_Patch",        --
	"EEex_GameObject",       --
	"EEex_GameObject_Patch", --
	"EEex_GameState",        --
	"EEex_GameState_Patch",  --
	"EEex_Keybinds",         --
	"EEex_Menu",             --
	"EEex_Menu_Patch",       --
	"EEex_Mix_Patch",        --
	"EEex_Object",           --
	"EEex_Object_Patch",     --
	"EEex_Opcode",           --
	"EEex_Opcode_Patch",     --
	"EEex_Projectile",       --
	"EEex_Projectile_Patch", --
	"EEex_Resource",         --
	"EEex_Script",           --
	"EEex_Script_Patch",     --
	"EEex_Sprite",           --
	"EEex_Sprite_Patch",     --
	"EEex_Stats",            --
	"EEex_Stats_Patch",      --
	"EEex_Test",             --
	"EEex_Trigger",          --
	"EEex_Trigger_Patch",    --
	"EEex_Variable",         --
	-- Late files
	"EEex_Debug",            --
	"EEex_Debug_Patch",      --
	"EEex_Marshal",          --
	"EEex_Module",           --
	"EEex_OptionsLate",      -- Here so it can register listeners provided by other EEex files
}

EEex_Main_Private_Modules = {
	{ "B3EffMen",         "EEex_Module_EffectMenu"     },
	{ "B3EmptyContainer", "EEex_Module_EmptyContainer" },
	{ "B3Hotkey",         nil                          },
	{ "B3Invis",          nil                          },
	{ "B3Scale",          "EEex_Module_Scale"          },
	{ "B3TimeStep",       "EEex_Module_TimeStep"       },
	{ "B3Timer",          "EEex_Module_Timer"          },
}

----------
-- Main --
----------

(function()

	-- Contains most of the code editing functions. This file is the core of EEex.
	EEex_DoFile("EEex_Assembly")
	EEex_DoFile("EEex_Assembly_Patch")

	-- Contains Lua bindings that map engine structures to Lua
	EEex_OpenLuaBindings("LuaBindings-v2.6.6.0", function()
		-- Patches in-engine tolua functions with EEex versions.
		-- These are required for proper bindings operation.
		EEex_DoFile("EEex_LuaBindings_Patch")
	end)

	-- Contains EEex's C++ functionality
	EEex_OpenLuaBindings("EEex")
	EEex_DoFile("EEex_HookIntegrityWatchdog")

	-- Defines aliases for EEex functions to preserve API compatibility if internal names change
	EEex_DoFile("EEex_Alias")

	-- Defines information about usertypes for the EEex_MemoryManager helper
	EEex_DoFile("EEex_MemoryManagerDefinitions")

	-- Run EEex's other files (which each pertain to a specific category)
	for _, fileName in ipairs(EEex_Main_Private_StartupFiles) do
		EEex_DoFile(fileName)
	end

	-- This file may run before the game is initialized.
	-- The following listener runs files that need to
	-- wait for the game to be somewhat initialized.
	EEex_GameState_AddInitializedListener(function()
		EEex_DoFile("EEex_UserDataGlobals")
		EEex_DoFile("EEex_StutterDetector")
	end)

	-- Run EEex_Modules.lua, which determines the legacy-enabled EEex modules
	EEex_DoFile("EEex_Modules")

	for _, moduleEntry in ipairs(EEex_Main_Private_Modules) do

		local moduleFile = moduleEntry[1]
		local moduleOptionName = moduleEntry[2]

		local legacyEnabled = EEex_Modules[moduleFile]
		local option = EEex_Options_Get(moduleOptionName)

		if legacyEnabled and option ~= nil then
			option:_set(1, true)
		end

		if legacyEnabled or (option ~= nil and option:get() == 1) then
			EEex_DoFile(moduleFile)
		end
	end

	-- Stops a call to SDL_LogOutput() higher in this file
	-- preventing the console from attaching later on
	EEex_Write32(EEex_Label("Data-EngineConsoleAttachedPtr"), 0)

	EEex_Active = true

end)()
