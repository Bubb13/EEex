--[[

This file's hook hardcodes a check into the exe for whenever the engine attempts to
look up a character's class when they attempt to use their thieving abilities. The
class IDS that EEex_HookBardThieving() returns will be what the engine treats the
character as when they use their thieving abilities.

--]]

function EEex_HookBardThieving()
	local actorID = EEex_GetActorIDSelected()
	local class = EEex_GetActorClass(actorID)
	return class
end

function EEex_InstallBardThievingHook()
	local hookName = "EEex_HookBardThieving"
	local hookNameAddress = EEex_Malloc(#hookName + 1)
	EEex_WriteString(hookNameAddress, hookName)
	local hookAddress = EEex_WriteAssemblyAuto({
		"68", {hookNameAddress, 4},
		"FF 35 0C 01 94 00 \z
		E8 >_lua_getglobal \z
		83 C4 08 6A 00 6A 00 6A 00 6A 01 6A 00 FF 35 0C 01 94 00 \z
		E8 >_lua_pcallk \z
		83 C4 18 6A 00 6A FF FF 35 0C 01 94 00 \z
		E8 >_lua_tonumberx \z
		83 C4 0C \z
		E8 >__ftol2_sse \z
		50 6A FE FF 35 0C 01 94 00 \z
		E8 >_lua_settop \z
		83 C4 08 58 C3"
	})
	EEex_DisableCodeProtection()
	EEex_WriteAssembly(0x616D5C, {{hookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallBardThievingHook()
