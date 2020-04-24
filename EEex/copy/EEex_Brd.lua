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
	local hookNameAddress = EEex_Malloc(#hookName + 1, 12)
	EEex_WriteString(hookNameAddress, hookName)

	local hookAddress = EEex_WriteAssemblyAuto({[[

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
		!ret
	]]})

	EEex_DisableCodeProtection()
	EEex_WriteAssembly(EEex_Label("ThievingClassHook"), {{hookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallBardThievingHook()
