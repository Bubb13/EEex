
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

EEex_PostResetListeners = {}

-- Given listener function is called after an F5 UI reload is executed.
function EEex_AddPostResetListener(listener)
	table.insert(EEex_PostResetListeners, listener)
end

function EEex_ResetHook()
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

	EEex_EnableCodeProtection()
end
EEex_InstallMenuHooks()
