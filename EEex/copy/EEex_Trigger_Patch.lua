
(function()

	EEex_DisableCodeProtection()

	EEex_HookJumpAutoSucceed(EEex_Label("Hook-CGameAIBase::EvaluateStatusTrigger()-DefaultJmp"), 0, EEex_FlattenTable({[[
		jbe jmp_fail
		#MAKE_SHADOW_SPACE(48)
		]], EEex_GenLuaCall("EEex_Trigger_Hook_OnEvaluatingUnknown", {
			["args"] = {
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$(1)], r14
				]], {rspOffset}}, "CGameAIBase" end,
				function(rspOffset) return {[[
					lea rax, qword ptr ss:[rbp+350h]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}}, "CAITrigger" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}), [[
		jmp no_error
		call_error:
		xor eax, eax
		no_error:
		mov esi, eax
		#DESTROY_SHADOW_SPACE
	]]}))

	EEex_EnableCodeProtection()

end)()
