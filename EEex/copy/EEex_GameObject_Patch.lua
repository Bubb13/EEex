
(function()

	EEex_DisableCodeProtection()

	---------------------------------------------
	-- [Lua] EEex_GameObject_Hook_OnDeleting() --
	---------------------------------------------

	EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-CGameObjectArray::Delete()-DeleteJmp"), 5, {
		{"integrity_ignore_registers", {
			EEex_IntegrityRegister.RAX, EEex_IntegrityRegister.RCX, EEex_IntegrityRegister.RDX, EEex_IntegrityRegister.R8,
			EEex_IntegrityRegister.R9, EEex_IntegrityRegister.R10, EEex_IntegrityRegister.R11
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
