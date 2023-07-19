
(function()

	EEex_DisableCodeProtection()

	---------------------------------------------
	-- [Lua] EEex_GameObject_Hook_OnDeleting() --
	---------------------------------------------

	EEex_HookJumpOnSuccess(EEex_Label("Hook-CGameObjectArray::Delete()-DeleteJmp"), 5, EEex_FlattenTable({
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
	}))

	EEex_EnableCodeProtection()

end)()
