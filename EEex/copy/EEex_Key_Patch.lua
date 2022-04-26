
(function()

	EEex_DisableCodeProtection()

	-------------------------------------
	-- EEex_Key_Hook_AfterEventsPoll() --
	-------------------------------------

	local afterEventsPollHook = EEex_JITNear(EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment

			test eax, eax
			jnz call_hook
			ret

			call_hook:
			#MAKE_SHADOW_SPACE(48)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		]]},
		EEex_GenLuaCall("EEex_Key_Hook_AfterEventsPoll", {
			["args"] = {
				function(rspOffset) return {[[
					lea rcx, qword ptr ds:[rbp-51h]
					mov qword ptr ss:[rsp+#$(1)], rcx ]], {rspOffset}, [[ #ENDL
				]]} end,
			},
		}),
		{[[
			call_error:
			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	}))

	EEex_HookRelativeBranch(EEex_Label("Hook-CChitin::ProcessEvents()-SDL_PollEvent()-1"), {[[
		call #L(original)
		call ]], afterEventsPollHook, [[ #ENDL
		jmp #L(return)
	]]})

	EEex_HookRelativeBranch(EEex_Label("Hook-CChitin::ProcessEvents()-SDL_PollEvent()-2"), {[[
		call #L(original)
		call ]], afterEventsPollHook, [[ #ENDL
		jmp #L(return)
	]]})

	EEex_EnableCodeProtection()

end)()
