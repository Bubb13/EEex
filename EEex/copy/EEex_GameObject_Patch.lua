
(function()

	EEex_DisableCodeProtection()

	---------------------------------------
	-- EEex_GameObject_Hook_OnDeleting() --
	---------------------------------------

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

	EEex_HookJumpOnFail(EEex_Label("Hook-CGameObjectArray::Clean()-DestructJmp"), 3, EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(48)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
		]]},
		EEex_GenLuaCall("EEex_GameObject_Hook_OnDeleting", {
			["args"] = {
				function(rspOffset) return {[[
					mov rax, qword ptr ds:[rcx]
					mov eax, dword ptr ds:[rax+0x48]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}, "#ENDL"} end,
			},
		}),
		{[[
			call_error:
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	---------------------------------------------
	-- EEex_GameObject_Hook_OnObjectsCleaned() --
	---------------------------------------------

	EEex_HookRelativeBranch(EEex_Label("Hook-CGameObjectArray::Clean()-LastJmp"), EEex_FlattenTable({
		{[[
			call #L(original)
			#MAKE_SHADOW_SPACE(32)
		]]},
		EEex_GenLuaCall("EEex_GameObject_Hook_OnObjectsCleaned"),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	}))

	EEex_EnableCodeProtection()

end)()
