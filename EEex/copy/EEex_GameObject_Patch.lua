
(function()

	EEex_DisableCodeProtection()

	---------------------------------------------
	-- [Lua] EEex_GameObject_Hook_OnDeleting() --
	---------------------------------------------

	EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CGameObjectArray::Delete()-DeleteJmp"), 5, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_GameObject_Hook_OnDeleting", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbp", {rspOffset}, "#ENDL"} end,
				},
			}),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	EEex_EnableCodeProtection()

end)()
