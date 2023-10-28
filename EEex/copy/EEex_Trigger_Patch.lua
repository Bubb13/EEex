
(function()

	EEex_DisableCodeProtection()

	---------------------------------------------------
	-- [Lua] EEex_Trigger_Hook_OnEvaluatingUnknown() --
	---------------------------------------------------

	EEex_HookConditionalJumpOnSuccess(EEex_Label("Hook-CGameAIBase::EvaluateStatusTrigger()-DefaultJmp"), 0, EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(48)
		]]},
		EEex_GenLuaCall("EEex_Trigger_Hook_OnEvaluatingUnknown", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r14 #ENDL", {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
				function(rspOffset) return {[[
					lea rax, qword ptr ss:[rbp+350h]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}}, "CAITrigger" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}),
		{[[
			jmp no_error

			call_error:
			xor eax, eax

			no_error:
			mov esi, eax
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	EEex_EnableCodeProtection()

end)()
