
(function()

	EEex_DisableCodeProtection()

	--[[
	+--------------------------------------------------------------------------------------------+
	| Call a hook before the engine saves the menu stack (UI edit mode - F5)                     |
	+--------------------------------------------------------------------------------------------+
	|   Used to implement listeners that dynamically load additional menus / edit existing menus |
	+--------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Menu_Hook_OnBeforeMenuStackSave()                                       |
	|   [Lua] EEex_Menu_LuaHook_BeforeMenuStackSave()                                            |
	+--------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-uiRefreshMenu()-saveMenuStack()"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			call #L(EEex::Menu_Hook_OnBeforeMenuStackSave)
		]]}
	)

	--[[
	+--------------------------------------------------------------------------------------------+
	| Call a hook after the engine restores the menu stack (UI edit mode - F5)                   |
	+--------------------------------------------------------------------------------------------+
	|   Used to implement listeners that dynamically load additional menus / edit existing menus |
	+--------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Menu_Hook_AfterMenuStackRestore()                                             |
	+--------------------------------------------------------------------------------------------+
	--]]

	EEex_HookRelativeJumpWithLabels(EEex_Label("Hook-uiRefreshMenu()-restoreMenuStack()"), {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}},
		{"manual_continue", true}},
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

	--[[
	+------------------------------------------------------------------------------------------------------------+
	| Call a hook before/after the engine loads UI.MENU                                                          |
	+------------------------------------------------------------------------------------------------------------+
	|   * Allows EEex to distinguish "native" menus (those in UI.MENU) from those that were dynamically injected |
	|   * Used to implement listeners that dynamically load additional menus / edit existing menus               |
	+------------------------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Menu_Hook_BeforeMainFileLoaded()                                                              |
	|   [Lua] EEex_Menu_Hook_AfterMainFileLoaded()                                                               |
	+------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeAndAfterCallWithLabels(EEex_Label("Hook-dimmInit()-uiLoadMenu()"), {
		{"hook_integrity_watchdog_ignore_registers_0", {
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}},
		{"hook_integrity_watchdog_ignore_registers_1", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_BeforeMainFileLoaded", { ["labelSuffix"] = "_1" }),
			{[[
				call_error_1:
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		}),
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(32)
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_AfterMainFileLoaded", { ["labelSuffix"] = "_2" }),
			{[[
				call_error_2:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	--[[
	+-------------------------------------------------------------------------------------------------------------------+
	| Infinity_InstanceAnimation() can be forced to create the template in an arbitrary menu by setting a hook variable |
	+-------------------------------------------------------------------------------------------------------------------+
	|   [Lua Global] EEex_Menu_HookGlobal_TemplateMenuOverride: uiMenu                                                  |
	+-------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookNOPsWithLabels(EEex_Label("Hook-Infinity_InstanceAnimation()-TemplateMenuOverride"), 7, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(16)

			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rdx

			mov rdx, ]], EEex_WriteStringCache("EEex_Menu_HookGlobal_TemplateMenuOverride"), [[ ; name
			mov rcx, #L(Hardcoded_InternalLuaState)                                             ; L
			call #L(Hardcoded_lua_getglobal)

			mov r8, 0                               ; def
			mov rdx, -1                             ; narg
			mov rcx, #L(Hardcoded_InternalLuaState) ; L
			call #L(Hardcoded_tolua_tousertype)

			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax

			mov rdx, -2                             ; index
			mov rcx, #L(Hardcoded_InternalLuaState) ; L
			call #L(Hardcoded_lua_settop)

			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			test rax, rax
			jnz keep_override

			mov rax, qword ptr ds:[rbp+8]

			keep_override:
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			mov qword ptr ds:[rdx+8], rax                        ; (Potentially) override menu

			#DESTROY_SHADOW_SPACE
		]]}
	)

	--[[
	+-------------------------------------------------------------------------------------------------------------------+
	| Infinity_DestroyAnimation() can be forced to destroy the template in an arbitrary menu by setting a hook variable |
	+-------------------------------------------------------------------------------------------------------------------+
	|   [Lua Global] EEex_Menu_HookGlobal_TemplateMenuOverride: uiMenu                                                  |
	+-------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookBetweenRestoreWithLabels(EEex_Label("Hook-Infinity_DestroyAnimation()-TemplateMenuOverride"), 0, 4, 4, 3, 7, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RBX, EEex_HookIntegrityWatchdogRegister.RCX,
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(8)

			mov rdx, ]], EEex_WriteStringCache("EEex_Menu_HookGlobal_TemplateMenuOverride"), [[ ; name
			mov rcx, #L(Hardcoded_InternalLuaState)                                             ; L
			call #L(Hardcoded_lua_getglobal)

			mov r8, 0                               ; def
			mov rdx, -1                             ; narg
			mov rcx, #L(Hardcoded_InternalLuaState) ; L
			call #L(Hardcoded_tolua_tousertype)

			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax

			mov rdx, -2                             ; index
			mov rcx, #L(Hardcoded_InternalLuaState) ; L
			call #L(Hardcoded_lua_settop)

			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			test rax, rax
			jz no_override

			mov rbx, rax ; Override menu

			no_override:
			#DESTROY_SHADOW_SPACE
		]]}
	)

	--[[
	+---------------------------------------------------------------------------------+
	| Prevent EEex_Menu_LoadFile() from causing a crash when using UI edit mode's F11 |
	+---------------------------------------------------------------------------------+
	|   Menus injected by EEex do not exist in UI.MENU, and yet the engine attempts   |
	|   to write their items back to UI.MENU when F11 is toggled off. This hook       |
	|   forces the engine to skip this writing behavior for dynamically injected      |
	|   menus.                                                                        |
	+---------------------------------------------------------------------------------+
	|   [Lua] EEex_Menu_Hook_CheckSaveMenuItem(menu: uiMenu, item: uiItem) -> boolean |
	|       return:                                                                   |
	|           -> false - Don't write item back to UI.MENU                           |
	|           -> true  - Write item back to UI.MENU                                 |
	+---------------------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpOnFailWithLabels(EEex_Label("Hook-saveMenus()-CheckItemSave"), 5, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
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

	--[[
	+--------------------------------------------------------------------------------------------------+
	| Call a hook before UI lists render one of their items                                            |
	+--------------------------------------------------------------------------------------------------+
	|   Used to implement listeners that can alter list rendering behavior                             |
	+--------------------------------------------------------------------------------------------------+
	|   [Lua] EEex_Menu_Hook_BeforeListRenderingItem(list: uiItem, item: uiItem, window: SDL_Rect,     |
	|                                                rClipBase: SDL_Rect, alpha: number, menu: uiMenu) |
	+--------------------------------------------------------------------------------------------------+
	--]]

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

	--[[
	+----------------------------------------------------------------------+
	| [JIT] Fix forced scrollbars sometimes crashing with a divide by zero |
	+----------------------------------------------------------------------+
	--]]

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

	--[[
	+-------------------------------------------------------------+
	| Call a hook immediately after the engine has checked that a |
	| uiItem is enabled, and before the item is rendered. This    |
	| can be used to implement custom item render routines.       |
	+-------------------------------------------------------------+
	|   [Lua] EEex_Menu_Hook_OnBeforeUIItemRender(item: uiItem)   |
	+-------------------------------------------------------------+
	--]]

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-drawItem()-AfterEnabledCheck"), 0, 5, 5, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_OnBeforeUIItemRender", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r15", {rspOffset}, "#ENDL"}, "uiItem" end,
				},
			}),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	--[[
	+---------------------------------------------------------+
	| Call a hook whenever the engine changes the window size |
	+---------------------------------------------------------+
	|   [Lua] EEex_Menu_Hook_OnWindowSizeChanged()            |
	+---------------------------------------------------------+
	--]]

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CChitin::OnResizeWindow()-B3Scale"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({[[
			#MAKE_SHADOW_SPACE(32)
			]], EEex_GenLuaCall("EEex_Menu_Hook_OnWindowSizeChanged"), [[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]})
	)

	--[[
	+---------------------------------------------------------------------+
	| Save `instanceId` before calling the action functions of edit items |
	+---------------------------------------------------------------------+
	|   [Lua] EEex_Menu_Hook_SaveInstanceId(item: uiItem*)                |
	+---------------------------------------------------------------------+
	--]]

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-continueEditCapture()-ActionHandlerCall"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(48)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_SaveInstanceId", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdi", {rspOffset}, "#ENDL"}, "uiItem" end,
				},
			}),
			{[[
				call_error:
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	--[[
	+---------------------------------------------------------------------+
	| Save `instanceId` before calling the action functions of text items |
	+---------------------------------------------------------------------+
	|   [Lua] EEex_Menu_Hook_SaveInstanceId(item: uiItem*)                |
	+---------------------------------------------------------------------+
	--]]

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-continueTextCapture()-ActionHandlerCall"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(48)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			]]},
			EEex_GenLuaCall("EEex_Menu_Hook_SaveInstanceId", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rax", {rspOffset}, "#ENDL"}, "uiItem" end,
				},
			}),
			{[[
				call_error:
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	--[[
	+---------------------------------------------------------------------------+
	| Call a hook after the engine loads the UI translation file for a language |
	+---------------------------------------------------------------------------+
	|   Allows mods to easily load custom UI translation files                  |
	+---------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Override_uiDoFile(fileName: char*)                     |
	|   [Lua] EEex_Menu_LuaHook_AfterTranslationLoaded()                        |
	+---------------------------------------------------------------------------+
	--]]

	EEex_JITAt(EEex_Label("Hook-uiDoFile()-FirstInstruction"), {[[
		jmp #L(EEex::Override_uiDoFile)
	]]})

	--[[
	+---------------------------------------------------------------------------------------------------------------------+
	| Hook that listens in on whether a UI item's scrollbar is visible for the current render pass                        |
	+---------------------------------------------------------------------------------------------------------------------+
	|   Used to fix scrollbar visibility changes causing an incomplete content wrapping state to be presented for 1 frame |
	+---------------------------------------------------------------------------------------------------------------------+
	|   Can force the scrollbar to be hidden / shown via its return value                                                 |
	+---------------------------------------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Fix_Hook_OnUIItemCheckRenderScrollbar(pItem: uiItem*, bVisible: bool) -> bool                    |
	|       return:                                                                                                       |
	|           -> false - The scrollbar should be hidden                                                                 |
	|           -> true  - The scrollbar should be shown                                                                  |
	+---------------------------------------------------------------------------------------------------------------------+
	--]]

	EEex_HookConditionalJumpWithLabels(EEex_Label("Hook-drawItem()-CheckScrollbarContentHeight"), 0, {
		{"hook_integrity_watchdog_ignore_registers_0", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}},
		{"hook_integrity_watchdog_ignore_registers_1", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
			EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
			EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			mov rcx, r15                                         ; pItem
			mov rdx, 1                                           ; bVisible
			call #L(EEex::Fix_Hook_OnUIItemCheckRenderScrollbar)
			test al, al
			jz #L(jmp_success)
		]]},
		{[[
			mov rcx, r15                                         ; pItem
			xor rdx, rdx                                         ; bVisible
			call #L(EEex::Fix_Hook_OnUIItemCheckRenderScrollbar)
			test al, al
			jnz #L(jmp_fail)
		]]}
	)

	--[[
	+------------------------------------------------------------------------------------+
	| Track template instance destruction to clean up EEex data tied to uiItem instances |
	+------------------------------------------------------------------------------------+
	|   [EEex.dll] EEex::Menu_Hook_OnBeforeUITemplateFreed(pItem: uiItem*)               |
	+------------------------------------------------------------------------------------+
	--]]

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-Infinity_DestroyAnimation()-free()"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx

															 ; rcx already pItem
			call #L(EEex::Menu_Hook_OnBeforeUITemplateFreed)

			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_EnableCodeProtection()

end)()
