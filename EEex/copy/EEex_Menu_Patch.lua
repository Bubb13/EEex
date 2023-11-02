
(function()

	EEex_DisableCodeProtection()

	------------------------------------------------
	-- [Lua] EEex_Menu_Hook_BeforeMenuStackSave() --
	------------------------------------------------

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-uiRefreshMenu()-saveMenuStack()"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(32)
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_BeforeMenuStackSave"),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	--------------------------------------------------
	-- [Lua] EEex_Menu_Hook_AfterMenuStackRestore() --
	--------------------------------------------------

	EEex_HookRelativeJumpWithLabels(EEex_Label("Hook-uiRefreshMenu()-restoreMenuStack()"), {
		{"stack_mod", 8},
		{"manual_continue", true},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(32)
				call #L(original)
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_AfterMenuStackRestore"),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
				#MANUAL_HOOK_EXIT(0)
				ret
			]]},
		})
	)

	------------------------------------------------
	-- [Lua] EEex_Menu_Hook_AfterMainFileLoaded() --
	------------------------------------------------

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-dimmInit()-uiLoadMenu()"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(32)
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_AfterMainFileLoaded"),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	--------------------------------------------------------------------------------------------
	-- Infinity_InstanceAnimation() can be forced to create the template in an arbitrary menu --
	--  [Lua Global] EEex_Menu_HookGlobal_TemplateMenuOverride                                --
	--------------------------------------------------------------------------------------------

	EEex_HookNOPsWithLabels(EEex_Label("Hook-Infinity_InstanceAnimation()-TemplateMenuOverride"), 7, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(16)

			mov qword ptr ss:[rsp+32], rdx

			mov rdx, ]], EEex_WriteStringCache("EEex_Menu_HookGlobal_TemplateMenuOverride"), [[ ; name
			mov rcx, #L(Hardcoded_InternalLuaState)                                             ; L
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
		]]}
	)

	--------------------------------------------------------------------------------------------
	-- Infinity_DestroyAnimation() can be forced to destroy the template in an arbitrary menu --
	--  [Lua Global] EEex_Menu_HookGlobal_TemplateMenuOverride                                --
	--------------------------------------------------------------------------------------------

	EEex_HookBetweenRestoreWithLabels(EEex_Label("Hook-Infinity_DestroyAnimation()-TemplateMenuOverride"), 0, 4, 4, 3, 7, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(8)

			mov rdx, ]], EEex_WriteStringCache("EEex_Menu_HookGlobal_TemplateMenuOverride"), [[ ; name
			mov rcx, #L(Hardcoded_InternalLuaState)                                             ; L
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
		]]}
	)

	-------------------------------------------------------------------
	-- Prevent EEex_LoadMenuFile() from causing crash when using F11 --
	--  [Lua] EEex_Menu_Hook_CheckSaveMenuItem()                     --
	-------------------------------------------------------------------

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-saveMenus()-CheckItemSave"), 5, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(56)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_CheckSaveMenuItem", {
				["args"] = {
					function(rspOffset) return {[[
						lea rax, qword ptr ds:[r14-0x28]
						mov qword ptr ss:[rsp+#$(1)], rax
					]], {rspOffset}}, "uiMenu" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+", rspOffset, "], rbx #ENDL"}, "uiItem" end,
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
			]]},
		})
	)

	----------------------------------------------------
	-- [Lua] EEex_Menu_Hook_BeforeListRenderingItem() --
	----------------------------------------------------

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-RenderListCallback()-drawItem()"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(112)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_BeforeListRenderingItem", {
				["args"] = {
					-- list
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rsi #ENDL", {rspOffset}}, "uiItem" end,
					-- item
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx #ENDL", {rspOffset}}, "uiItem" end,
					-- window
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx #ENDL", {rspOffset}}, "SDL_Rect" end,
					-- rClipBase
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r8 #ENDL", {rspOffset}}, "SDL_Rect" end,
					-- alpha
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r9 #ENDL", {rspOffset}} end,
					-- menu
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(20h)]
						mov qword ptr ss:[rsp+#$(1)], rax
					]], {rspOffset}}, "uiMenu" end,
				},
			}),
			{[[
				call_error:
				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	------------------------------------------------------
	-- [Lua] EEex_Menu_Hook_CheckForceScrollbarRender() --
	------------------------------------------------------

	EEex_HookConditionalJumpOnSuccessWithLabels(EEex_Label("Hook-drawItem()-CheckScrollbarContentHeight"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_CheckForceScrollbarRender", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r15 #ENDL", {rspOffset}}, "uiItem" end,
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
				jnz #L(jmp_fail)
			]]},
		})
	)

	---------------------------------------------------------------
	-- [JIT] Fix forced scrollbar crashing with a divide by zero --
	---------------------------------------------------------------

	for _, address in ipairs({
		EEex_Label("Hook-drawItem()-FixForcedScrollbarDivideByZero1"),
		EEex_Label("Hook-drawItem()-FixForcedScrollbarDivideByZero2") })
	do
		EEex_HookAfterRestoreWithLabels(address, 0, 11, 11, {
			{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
			{[[
				test eax, eax
				jnz #L(return)
				mov eax, -1
			]]}
		)
	end

	EEex_EnableCodeProtection()

end)()
