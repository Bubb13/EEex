
(function()

	EEex_DisableCodeProtection()

	--[[
	+---------------------------------------------------------------------------+
	| Call a hook after the engine has completed most of its initialization     |
	+---------------------------------------------------------------------------+
	|   Used to implement listeners that need the game state to be initialized, |
	|   yet also require early execution during engine startup                  |
	+---------------------------------------------------------------------------+
	|   [EEex.dll] EEex::GameState_Hook_OnInitialized()                         |
	+---------------------------------------------------------------------------+
	|   [Lua] EEex_GameState_LuaHook_OnInitialized()                            |
	+---------------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-SDL_main()-CLUAConsole::LuaInit()"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		{[[
			call #L(EEex::GameState_Hook_OnInitialized)
		]]}
	)

	--[[
	+---------------------------------------------------------------------------+
	| Call a hook after the engine has "destroyed" a game instance              |
	+---------------------------------------------------------------------------+
	|   Used to implement listeners that need to react to a game session ending |
	+---------------------------------------------------------------------------+
	|   [Lua] EEex_GameState_Hook_OnDestroyed()                                 |
	+---------------------------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CInfGame::DestroyGame()-LastCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(32)
			]]},
			EEex_GenLuaCall("EEex_GameState_Hook_OnDestroyed"),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	--[[
	+------------------------------------------------------------------------+
	| Immediately read special values from GLOBALS (like EEEX_NEXTUUID)      |
	+------------------------------------------------------------------------+
	|   [EEex.dll] EEex::GameState_Hook_OnAfterGlobalVariablesUnmarshalled() |
	+------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CInfGame::Unmarshal()-AfterGlobalVariablesUnmarshalled"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx

			call #L(EEex::GameState_Hook_OnAfterGlobalVariablesUnmarshalled)

			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)


	EEex_EnableCodeProtection()

end)()
