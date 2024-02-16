
(function()

	EEex_DisableCodeProtection()

	--[[
	+---------------------------------------------------------------------------------------------------------------------------+
	| Implement new triggers                                                                                                    |
	+---------------------------------------------------------------------------------------------------------------------------+
	|   0x410D EEex_HasDispellableEffect(O:Object*)                                                                             |
	|   0x410E EEex_LuaTrigger(S:Chunk*)                                                                                        |
	|   0x410F EEex_IsImmuneToOpcode(O:Object*,I:Opcode*)                                                                       |
	|   0x4110 EEex_MatchObject(S:Chunk*)                                                                                       |
	|   0x4110 EEex_MatchObjectEx(S:Chunk*,I:Nth*,I:Range*,I:Flags*X-MATOBJ)                                                    |
	+---------------------------------------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Trigger_Hook_OnEvaluatingUnknown(aiBase: CGameAIBase|EEex_GameObject_CastUT, trigger: CAITrigger) -> boolean |
	|       return -> The trigger's evaluated value (false / true)                                                              |
	+---------------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CGameAIBase::EvaluateStatusTrigger()-DefaultJmp"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.RSI, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
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
		})
	)

	EEex_EnableCodeProtection()

end)()
