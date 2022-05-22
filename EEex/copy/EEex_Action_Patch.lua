
(function()

	EEex_DisableCodeProtection()

	EEex_HookJumpAutoSucceed(EEex_Label("Hook-CGameAIBase::ExecuteAction()-DefaultJmp"), 0, EEex_FlattenTable({[[
		jbe jmp_fail
		#MAKE_SHADOW_SPACE(48)
		]], EEex_GenLuaCall("EEex_Action_Hook_OnEvaluatingUnknown", {
			["args"] = {
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$(1)], rbx
				]], {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Number,
		}), [[

		mov esi, eax
		#DESTROY_SHADOW_SPACE(KEEP_ENTRY)
		jmp #L(Hook-CGameAIBase::ExecuteAction()-NormalBranch)

		call_error:
		#RESUME_SHADOW_ENTRY
		#DESTROY_SHADOW_SPACE
		mov esi, -2 ; ACTION_ERROR
	]]}))

	EEex_EnableCodeProtection()

end)()
