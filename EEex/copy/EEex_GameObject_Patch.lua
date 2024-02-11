
(function()

	EEex_DisableCodeProtection()

	--[[
	+---------------------------------------------------------------------+
	| Clean up any EEex data linked to a game object before it is deleted |
	+---------------------------------------------------------------------+
	|   [Lua] EEex_GameObject_Hook_OnDeleting(objectID: number)           |
	+---------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CGameObjectArray::Delete()-DeleteJmp"), 5, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(56)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			]]},
			EEex_GenLuaCall("EEex_GameObject_Hook_OnDeleting", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbp", {rspOffset}, "#ENDL"} end,
				},
			}),
			{[[
				call_error:
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	EEex_EnableCodeProtection()

end)()
