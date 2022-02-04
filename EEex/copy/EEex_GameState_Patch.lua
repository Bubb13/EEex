
(function()

	EEex_DisableCodeProtection()

	-----------------------------------------
	-- EEex_GameState_Hook_OnInitialized() --
	-----------------------------------------

	EEex_HookRelativeBranch(EEex_Label("Hook-SDL_main()-CLUAConsole::LuaInit()"), EEex_FlattenTable({
		{[[
			call #L(original)
			#MAKE_SHADOW_SPACE(32)
		]]},
		EEex_GenLuaCall("EEex_GameState_Hook_OnInitialized"),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
			jmp #L(return)
		]]},
	}))

	EEex_EnableCodeProtection()

end)()
