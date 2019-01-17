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
	local hookNameAddress = EEex_Malloc(#hookName + 1)
	EEex_WriteString(hookNameAddress, hookName)
	local hookAddress = EEex_WriteAssemblyAuto({
		"51 \z
		68", {hookNameAddress, 4},
		"FF 35 0C 01 94 00 \z
		E8 >_lua_getglobal \z
		83 C4 08 6A 00 6A 00 6A 00 6A 01 6A 00 FF 35 0C 01 94 00 \z
		E8 >_lua_pcallk \z
		83 C4 18 6A FF FF 35 0C 01 94 00 \z
		E8 >_lua_toboolean \z
		83 C4 08 50 6A FE FF 35 0C 01 94 00 \z
		E8 >_lua_settop \z
		83 C4 08 58 85 C0 59 \z
		0F 85 :70045B \z
		E8 >CGameSprite::SetCharacterToolTip \z
		E9 :700455"
	})
	EEex_DisableCodeProtection()
	EEex_WriteAssembly(0x700450, {"E9", {hookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallTooltipHook()
