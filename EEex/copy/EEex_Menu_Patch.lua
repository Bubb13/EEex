
(function()

	EEex_DisableCodeProtection()

	----------------------------------------
	-- EEex_Menu_Hook_BeforeMenuStackSave --
	----------------------------------------
	
	EEex_HookRelativeBranch(EEex_Label("Hook-uiRefreshMenu()-saveMenuStack()"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(32)
		]]},
		EEex_GenLuaCall("EEex_Menu_Hook_BeforeMenuStackSave"),
		{[[
			call_error:
			call #L(original)
			#DESTROY_SHADOW_SPACE
			jmp #L(return)
		]]},
	}))

	------------------------------------------
	-- EEex_Menu_Hook_AfterMenuStackRestore --
	------------------------------------------

	EEex_HookRelativeBranch(EEex_Label("Hook-uiRefreshMenu()-restoreMenuStack()"), EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; The stack wasn't aligned to begin with
			#MAKE_SHADOW_SPACE(32)
			call #L(original)
		]]},
		EEex_GenLuaCall("EEex_Menu_Hook_AfterMenuStackRestore"),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
			ret
		]]},
	}))

	------------------------------------------
	-- EEex_Menu_Hook_AfterMainFileLoaded() --
	------------------------------------------

	EEex_HookRelativeBranch(EEex_Label("Hook-dimmInit()-uiLoadMenu()"), EEex_FlattenTable({
		{[[
			call #L(original)
			#MAKE_SHADOW_SPACE(32)
		]]},
		EEex_GenLuaCall("EEex_Menu_Hook_AfterMainFileLoaded"),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
			jmp #L(return)
		]]},
	}))

	--------------------------------------------------------------------------------
	-- EEex_Menu_HookGlobal_TemplateMenuOverride for Infinity_InstanceAnimation() --
	--------------------------------------------------------------------------------

	EEex_HookNOPs(EEex_Label("Hook-Infinity_InstanceAnimation()-TemplateMenuOverride"), 7, {[[

		#MAKE_SHADOW_SPACE(16)

		mov qword ptr ss:[rsp+32], rdx

		mov rdx, ]], EEex_WriteStringAuto("EEex_Menu_HookGlobal_TemplateMenuOverride"), [[ ; name
		mov rcx, #L(Hardcoded_InternalLuaState)                                            ; L
		#ALIGN
		call #L(Hardcoded_lua_getglobal)
		#ALIGN_END

		mov r8, 0                               ; def
		mov rdx, -1                             ; narg
		mov rcx, #L(Hardcoded_InternalLuaState) ; L
		#ALIGN
		call #L(Hardcoded_tolua_tousertype)
		#ALIGN_END

		mov qword ptr ss:[rsp+40], rax

		mov rdx, -2                             ; index
		mov rcx, #L(Hardcoded_InternalLuaState) ; L
		#ALIGN
		call #L(Hardcoded_lua_settop)
		#ALIGN_END

		mov rax, qword ptr ss:[rsp+40]
		test rax, rax
		jnz keep_override

		mov rax, qword ptr ds:[rbp+8]

		keep_override:
		mov rdx, qword ptr ss:[rsp+32]
		mov qword ptr ds:[rdx+8], rax

		#DESTROY_SHADOW_SPACE
		jmp #L(return)
	]]})

	-------------------------------------------------------------------------------
	-- EEex_Menu_HookGlobal_TemplateMenuOverride for Infinity_DestroyAnimation() --
	-------------------------------------------------------------------------------

	EEex_HookBetweenRestore(EEex_Label("Hook-Infinity_DestroyAnimation()-TemplateMenuOverride"), 0, 4, 4, 3, 7, {[[

		#MAKE_SHADOW_SPACE(8)

		mov rdx, ]], EEex_WriteStringAuto("EEex_Menu_HookGlobal_TemplateMenuOverride"), [[ ; name
		mov rcx, #L(Hardcoded_InternalLuaState)                                            ; L
		#ALIGN
		call #L(Hardcoded_lua_getglobal)
		#ALIGN_END

		mov r8, 0                               ; def
		mov rdx, -1                             ; narg
		mov rcx, #L(Hardcoded_InternalLuaState) ; L
		#ALIGN
		call #L(Hardcoded_tolua_tousertype)
		#ALIGN_END

		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax

		mov rdx, -2                             ; index
		mov rcx, #L(Hardcoded_InternalLuaState) ; L
		#ALIGN
		call #L(Hardcoded_lua_settop)
		#ALIGN_END

		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		test rax, rax
		jz no_override

		mov rbx, rax

		no_override:
		#DESTROY_SHADOW_SPACE
	]]})

	-------------------------------------------------------------------
	-- EEex_Menu_Hook_CheckSaveMenuItem()                            --
	-- Prevent EEex_LoadMenuFile() from causing crash when using F11 --
	-------------------------------------------------------------------

	EEex_HookJump(EEex_Label("Hook-saveMenus()-CheckItemSave"), 5, EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(48)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		]]},
		EEex_GenLuaCall("EEex_Menu_Hook_CheckSaveMenuItem", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+", rspOffset, "], rbx #ENDL"} end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}),
		{[[
			jmp no_error

			call_error:
			mov rax, 1

			no_error:
			test rax, rax

			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
			jz #L(jmp_success)
			cmp qword ptr ds:[rbx+20h], 0
		]]},
	}))

	EEex_EnableCodeProtection()

end)()
