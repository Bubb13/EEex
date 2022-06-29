
(function()

    EEex_DisableCodeProtection()

	EEex_HookJumpOnFail(EEex_Label("Hook-CGameEffect::CheckAdd()-FixSpellImmunityShouldSkipItemIndexing"), 4, EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(40)
		]]},
		EEex_GenLuaCall("EEex_Fix_Hook_SpellImmunityShouldSkipItemIndexing", {
			["args"] = {
				function(rspOffset) return {[[
					mov rax, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(50h)]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}, "#ENDL"}, "CGameObject" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}),
		{[[
			jmp no_error

			call_error:
			xor rax, rax

			no_error:
			test rax, rax

			#DESTROY_SHADOW_SPACE
			jnz #L(jmp_success)
		]]},
	}))

    EEex_EnableCodeProtection()

end)()
