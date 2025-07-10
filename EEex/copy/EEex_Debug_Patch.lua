
--===============
-- Conditional ==
--===============

(function()

	EEex_DisableCodeProtection()

	if EEex_Debug_LogActions then

		--[[
		+--------------------------------------------------------------------------------------------------------------+
		| Debug-log details about a CGameAIBase's action before it is executed                                         |
		+--------------------------------------------------------------------------------------------------------------+
		|   [Lua] EEex_Debug_Hook_LogAction(executingObject: CGameAIBase|EEex_GameObject_CastUT, bFromAIBase: boolean) |
		+--------------------------------------------------------------------------------------------------------------+
		--]]

		EEex_HookBeforeConditionalJumpWithLabels(EEex_Label("Hook-CGameAIBase::ExecuteAction()-DefaultJmp"), 0, {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
				EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
			}}},
			EEex_FlattenTable({
				{[[
					#MAKE_SHADOW_SPACE(56)
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], r8
				]]},
				EEex_GenLuaCall("EEex_Debug_Hook_LogAction", {
					["args"] = {
						function(rspOffset) return {[[
							mov qword ptr ss:[rsp+#$(1)], rbx
						]], {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
						function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], 1", {rspOffset}, "#ENDL"} end,
					},
				}),
				{[[
					call_error:
					mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
					#DESTROY_SHADOW_SPACE
					cmp r8d, 0x1D5
				]]},
			})
		)

		EEex_HookBeforeConditionalJumpWithLabels(EEex_Label("Hook-CGameSprite::ExecuteAction()-DefaultJmp"), 0, {
			{"hook_integrity_watchdog_ignore_registers", {
				EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R11
			}}},
			EEex_FlattenTable({
				{[[
					#MAKE_SHADOW_SPACE(80)
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r9
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r10
				]]},
				EEex_GenLuaCall("EEex_Debug_Hook_LogAction", {
					["args"] = {
						function(rspOffset) return {[[
							mov qword ptr ss:[rsp+#$(1)], rdi
						]], {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
						function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], 0", {rspOffset}, "#ENDL"} end,
					},
				}),
				{[[
					call_error:
					mov r10, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
					mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
					mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
					mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
					#DESTROY_SHADOW_SPACE
					cmp ecx, 0x1D7
				]]},
			})
		)
	end

	EEex_EnableCodeProtection()

end)()
