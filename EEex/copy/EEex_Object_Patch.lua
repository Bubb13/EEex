
(function()

	EEex_DisableCodeProtection()

	--[[
	+----------------------------------------------------------------------------------------------+
	| Prevent certain OBJECT.IDS entries from interpreting their string parameter as a script name |
	+----------------------------------------------------------------------------------------------+
	|   117 EEex_Target()                                                                          |
	|   118 EEex_LuaDecode()                                                                       |
	+----------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Object_Hook_ForceIgnoreActorScriptName(aiType: CAIObjectType) -> boolean        |
	|       return:                                                                                |
	|           -> false - Don't alter engine behavior                                             |
	|           -> true  - Even though the script object was defined with a string parameter,      |
	|                      this string should not be treated as a script name                      |
	+----------------------------------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-CAIObjectType::Decode()-TargetNameOverride"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Object_Hook_ForceIgnoreActorScriptName", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r13 #ENDL", {rspOffset}}, "CAIObjectType" end,
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
		})
	)

	--[[
	+------------------------------------------------------------------------------------------------------------------------------+
	| Implement new OBJECT.IDS entries                                                                                             |
	+------------------------------------------------------------------------------------------------------------------------------+
	|   117 EEex_Target()                                                                                                          |
	|   118 EEex_LuaDecode()                                                                                                       |
	+------------------------------------------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Object_Hook_OnEvaluatingUnknown(decodingAIType: CAIObjectType, caller CGameAIBase|EEex_GameObject_CastUT,       |
	|                                              nSpecialCaseI: number, curAIType: CAIObjectType) -> number                      |
	|       return:                                                                                                                |
	|           -> EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.HANDLED_CONTINUE - Continue evaluating outer objects            |
	|                                                                                                                              |
	|           -> EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.HANDLED_DONE     - Halt OBJECT.IDS processing and use curAIType |
	|                                                                                                                              |
	|           -> EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.UNHANDLED        - Engine falls back to "Myself" and continues  |
	|                                                                                 evaluating outer objects                     |
	+------------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CAIObjectType::Decode()-DefaultJmp"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(72)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rdx
			]]},
			EEex_GenLuaCall("EEex_Object_Hook_OnEvaluatingUnknown", {
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
			}),
			{[[
				jmp no_error

				call_error:
				mov rax, #$(1) ]], {EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.UNHANDLED}, [[ #ENDL

				no_error:
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE

				cmp rax, #$(1) ]], {EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.HANDLED_CONTINUE}, [[ #ENDL
				je normal_return

				cmp rax, #$(1) ]], {EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.HANDLED_DONE}, [[ #ENDL
				jne #L(jmp_success)

				#MANUAL_HOOK_EXIT(0)
				jmp #L(Hook-CAIObjectType::Decode()-ReturnBranch)

				normal_return:
				#MANUAL_HOOK_EXIT(0)
				jmp #L(Hook-CAIObjectType::Decode()-NormalBranch)
			]]},
		})
	)
	EEex_HookIntegrityWatchdog_IgnoreStackSizes(EEex_Label("Hook-CAIObjectType::Decode()-DefaultJmp"), {{0x68, CAIObjectType.sizeof}})

	EEex_EnableCodeProtection()

end)()
