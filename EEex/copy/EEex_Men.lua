
EEex_TemplateMenuOverride = 0

-- Exactly the same as Infinity_InstanceAnimation(), but allows said instance to be "injected" into the menu specified.
function EEex_InjectTemplate(menuName, templateName, x, y, w, h)
	EEex_TemplateMenuOverride = EEex_GetMenuStructure(menuName)
	Infinity_InstanceAnimation(templateName, nil, x, y, w, h, nil, nil)
	EEex_TemplateMenuOverride = 0
end

-- Destroys an instance injected into a menu via EEex_InjectTemplate().
function EEex_DestroyInjectedTemplate(menuName, templateName, instanceId)
	EEex_TemplateMenuOverride = EEex_GetMenuStructure(menuName)
	Infinity_DestroyAnimation(templateName, instanceId)
	EEex_TemplateMenuOverride = 0
end

-- TODO: This probably belongs in another file
EEex_InitGameListeners = {}

function EEex_AddInitGameListener(listener)
	table.insert(EEex_InitGameListeners, listener)
end

function EEex_InitGameHook()
	for i, listener in ipairs(EEex_InitGameListeners) do
		listener()
	end
end

EEex_UIMenuLoadListeners = {}

-- Given listener function is called after initial UI.MENU load an when an F5 UI reload is executed.
function EEex_AddUIMenuLoadListener(listener)
	table.insert(EEex_UIMenuLoadListeners, listener)
end

EEex_NativeMenus = {}

function EEex_IsNativeMenu(menuName)
	return EEex_NativeMenus[menuName] ~= nil
end

function EEex_HookCheckSaveMenuItem(uiMenu)
	local menuName = EEex_ReadString(EEex_ReadDword(uiMenu + 0x10))
	return EEex_IsNativeMenu(menuName)
end

function EEex_UIMenuLoadHook()

	EEex_NativeMenus = {}
	local numMenus = EEex_ReadDword(EEex_Label("n"))
	local currentAddress = EEex_Label("menus") + 0x10
	for i = 1, numMenus, 1 do
		local menuName = EEex_ReadString(EEex_ReadDword(currentAddress))
		EEex_NativeMenus[menuName] = true
		currentAddress = currentAddress + 0x54
	end

	for i, listener in ipairs(EEex_UIMenuLoadListeners) do
		listener()
	end
end

EEex_PostResetListeners = {}

-- Given listener function is called after an F5 UI reload is executed.
function EEex_AddPostResetListener(listener)
	table.insert(EEex_PostResetListeners, listener)
end

function EEex_ResetHook()
	for i, listener in ipairs(EEex_UIMenuLoadListeners) do
		listener()
	end
	for i, listener in ipairs(EEex_PostResetListeners) do
		listener()
	end
end

function EEex_InstallMenuHooks()

	EEex_DisableCodeProtection()

	local hookName = "EEex_ResetHook"
	local hookNameAddress = EEex_Malloc(#hookName + 1)
	EEex_WriteString(hookNameAddress, hookName)

	local hookReset = EEex_WriteAssemblyAuto({[[
		!call >_restoreMenuStack
		!push_all_registers
		!push_dword ]], {hookNameAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18
		!pop_all_registers
		!ret
	]]})

	-- This address is so exe-specific that I have to do
	-- the calculation myself, as the loader can't narrow
	-- it down to the final value.
	local refreshMenuCall = EEex_Label("_uiRefreshMenu")
	local refreshMenu = refreshMenuCall + EEex_ReadDword(refreshMenuCall) + 0x4
	EEex_WriteAssembly(refreshMenu + 0x24, {{hookReset, 4, 4}})

	local hookInitialLoadName = "EEex_UIMenuLoadHook"
	local hookInitialLoadNameAddress = EEex_Malloc(#hookInitialLoadName + 1)
	EEex_WriteString(hookInitialLoadNameAddress, hookInitialLoadName)

	local hookInitialLoad = EEex_WriteAssemblyAuto({[[
		!push_[esp+byte] 04
		!call >_uiLoadMenu
		!add_esp_byte 04
		!push_all_registers
		!push_dword ]], {hookInitialLoadNameAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18
		!pop_all_registers
		!ret
	]]})
	EEex_WriteAssembly(EEex_Label("InitialPostUIMenuLoadHook"), {{hookInitialLoad, 4, 4}})

	local templateHookName = "EEex_TemplateMenuOverride"
	local templateHookNameAddress = EEex_Malloc(#templateHookName + 1)
	EEex_WriteString(templateHookNameAddress, templateHookName)

	local templateMenuHook = EEex_WriteAssemblyAuto({[[
		!push_registers
		!push_dword ]], {templateHookNameAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08
		!push_byte 00
		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax
		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08
		!pop_eax
		!pop_registers
		!test_eax_eax
		!jnz_dword >normal_execution
		!mov_eax_[ebx+byte] 04
		@normal_execution
		!mov_[edx+byte]_eax 04
		!ret
	]]})
	EEex_WriteAssembly(EEex_Label("UITemplateMenu"), {"!call", {templateMenuHook, 4, 4}, "!nop !nop !nop !nop"})

	local destroyTemplateAddress = EEex_Label("DestroyTemplateMenuOverride")
	local destroyTemplateMenuHook = EEex_WriteAssemblyAuto({[[
		!push_registers
		!push_dword ]], {templateHookNameAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08
		!push_byte 00
		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax
		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08
		!pop_eax
		!pop_registers
		!test_eax_eax
		!jz_dword >no_override
		!mov_esi_eax
		!jmp_dword >normal_execution
		@no_override
		!mov_esi_[esi+byte] 04
		@normal_execution
		!push_edi
		!xor_edi_edi
		!jmp_dword ]], {destroyTemplateAddress + 0x6, 4, 4},
	})
	EEex_WriteAssembly(destroyTemplateAddress, {"!jmp_dword", {destroyTemplateMenuHook, 4, 4}, "!nop"})
	
	-------------------------------------------------------------------
	-- Prevent EEex_LoadMenuFile() from causing crash when using F11 --
	-------------------------------------------------------------------

	EEex_HookJump(EEex_Label("_saveMenus()_HookCheckItemSave"), 3, {[[

		!push_all_registers

		!push_dword ]], {EEex_WriteStringAuto("EEex_HookCheckSaveMenuItem"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!mov_eax_[ebp+byte] F4
		!sub_eax_byte 1C
		!push_eax
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_byte 01
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_toboolean
		!add_esp_byte 08
		!push_eax
		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08
		!pop_eax

		!test_eax_eax
		!pop_all_registers

		!jz_dword >jmp_success

		!cmp_[esi+byte]_byte 10 00

	]]})
	
	-----------------------
	-- EEex_InitGameHook --
	-----------------------

	EEex_HookAfterCall(EEex_Label("CBaldurChitin::Init()_After"), {[[

		!push_all_registers

		!push_dword ]], {EEex_WriteStringAuto("EEex_InitGameHook"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!pop_all_registers

	]]})

	EEex_EnableCodeProtection()
end
EEex_InstallMenuHooks()
