
B3Portr_SuppressActionIcons = true

function B3Portr_InstallPortraitHooks()

	EEex_DisableCodeProtection()

	local checkVariable = "B3Portr_SuppressActionIcons"
	local checkVariableAddress = EEex_Malloc(#checkVariable + 1, 1)
	EEex_WriteString(checkVariableAddress, checkVariable)

	local defaultSwitchAddress = EEex_Label("RenderPortraitIconSwitch")
	local returnDestination = defaultSwitchAddress + 6
	local defaultSwitchDestination = returnDestination + EEex_ReadDword(defaultSwitchAddress + 2)

	local suppressHook = EEex_WriteAssemblyAuto({[[
		!ja_dword ]], {defaultSwitchDestination, 4, 4}, [[
		!push_all_registers
		!push_dword ]], {checkVariableAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08
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
		!jnz_dword ]], {defaultSwitchDestination, 4, 4}, [[
		!jmp_dword ]], {returnDestination, 4, 4},
	})
	EEex_WriteAssembly(defaultSwitchAddress, {"!jmp_dword", {suppressHook, 4, 4}, "!nop"})

	EEex_EnableCodeProtection()
end
B3Portr_InstallPortraitHooks()
