
(function()

	EEex_DisableCodeProtection()

	EEex_HookJumpAutoSucceed(EEex_Label("Hook-CAIObjectType::Decode()-DefaultJmp"), 0, EEex_FlattenTable({[[
		jbe jmp_fail
		#MAKE_SHADOW_SPACE(88)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
		]], EEex_GenLuaCall("EEex_Object_Hook_OnEvaluatingUnknown", {
			["args"] = {
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$1], r13
				]], {rspOffset}}, "CAIObjectType" end,
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$1], r12
				]], {rspOffset}}, "CGameAIBase" end,
				function(rspOffset) return {[[
					mov qword ptr ss:[rsp+#$1], r15
				]], {rspOffset}} end,
				function(rspOffset) return {[[
					lea rax, qword ptr ss:[rbp-11h]
					mov qword ptr ss:[rsp+#$1], rax
				]], {rspOffset}}, "CAIObjectType" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}), [[
		jmp no_error
		call_error:
		xor rax, rax
		no_error:
		test rax, rax
		mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
		mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE
		jnz #L(Hook-CAIObjectType::Decode()-NormalBranch)
	]]}))

	EEex_EnableCodeProtection()

end)()
