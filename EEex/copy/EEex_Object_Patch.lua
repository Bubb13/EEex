
(function()

	EEex_DisableCodeProtection()

	----------------------------------------------------------
	-- 117 EEex_Target                                      --
	--  [Lua] EEex_Object_Hook_ForceIgnoreActorScriptName() --
	----------------------------------------------------------

	EEex_HookJumpOnFail(EEex_Label("Hook-CAIObjectType::Decode()-TargetNameOverride"), 0, EEex_FlattenTable({[[

		#MAKE_SHADOW_SPACE(40)

		]], EEex_GenLuaCall("EEex_Object_Hook_ForceIgnoreActorScriptName", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r13 #ENDL", {rspOffset}}, "CAIObjectType" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}), [[

		jmp no_error

		call_error:
		xor rax, rax

		no_error:
		test rax, rax

		#DESTROY_SHADOW_SPACE
		jnz #L(jmp_success)
	]]}))

	--------------------------------------------------
	-- [Lua] EEex_Object_Hook_OnEvaluatingUnknown() --
	--------------------------------------------------

	EEex_HookJumpAutoSucceed(EEex_Label("Hook-CAIObjectType::Decode()-DefaultJmp"), 0, EEex_FlattenTable({[[

		jbe jmp_fail

		#MAKE_SHADOW_SPACE(88)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8

		]], EEex_GenLuaCall("EEex_Object_Hook_OnEvaluatingUnknown", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r13 #ENDL", {rspOffset}}, "CAIObjectType" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r12 #ENDL", {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r15 #ENDL", {rspOffset}} end,
				function(rspOffset) return {[[
					lea rax, qword ptr ss:[rbp-11h]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}}, "CAIObjectType" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Number,
		}), [[

		jmp no_error

		call_error:
		mov rax, #$(1) ]], {{EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.UNHANDLED}}, [[ #ENDL

		no_error:
		mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
		mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]

		cmp rax, #$(1) ]], {{EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.HANDLED_CONTINUE}}, [[ #ENDL
		je normal_return

		cmp rax, #$(1) ]], {{EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.HANDLED_DONE}}, [[ #ENDL
		je done_return

		jmp unhandled_return

		normal_return:
		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE(KEEP_ENTRY)
		jmp #L(Hook-CAIObjectType::Decode()-NormalBranch) ; TODO

		done_return:
		#RESUME_SHADOW_ENTRY
		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE(KEEP_ENTRY)
		jmp #L(Hook-CAIObjectType::Decode()-ReturnBranch) ; TODO

		unhandled_return:
		#RESUME_SHADOW_ENTRY
		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE
	]]}))

	EEex_EnableCodeProtection()

end)()
