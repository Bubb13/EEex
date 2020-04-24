--[[

This file's hook hardcodes a check into the exe for whenever the engine attempts to
display a tooltip over a creature in the world screen. If EEex_IsActorTooltipDisabled is
implemented, and it returns true, the engine will not display the tooltip as it was
attempting.

--]]

function EEex_IsActorTooltipDisabled()
	return false
end

function EEex_InstallTooltipHook()

	local hookName = "EEex_IsActorTooltipDisabled"
	local hookNameAddress = EEex_Malloc(#hookName + 1, 36)
	EEex_WriteString(hookNameAddress, hookName)

	local tooltipHookAddress = EEex_Label("TooltipHook")

	local hookAddress = EEex_WriteAssemblyAuto({[[

		!push_ecx

		!push_dword ]], {hookNameAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_byte 00
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

		!pop_ecx

		!jne_dword ]], {tooltipHookAddress, 4, 4}, [[

		!call >CGameSprite::SetCharacterToolTip
		!jmp_dword ]], {tooltipHookAddress - 6, 4, 4},

	})

	EEex_DisableCodeProtection()
	EEex_WriteAssembly(tooltipHookAddress - 0xB, {"!jmp_dword", {hookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallTooltipHook()
