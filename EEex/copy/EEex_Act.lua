--[[

Installs the EEex_Lua action into the exe.
No new Lua functionality is defined in this file.

--]]

function EEex_InstallNewActions()
	local hookAddress = EEex_WriteAssemblyAuto({
		"3D D8 01 00 00 74 02 EB 51 FF B6 44 03 00 00 FF 35 0C 01 94 00 \z
		E8 >_lua_getglobal \z
		83 C4 08 FF 76 28 DB 04 24 83 EC 04 DD 1C 24 FF 35 0C 01 94 00 \z
		E8 >_lua_pushnumber \z
		83 C4 0C 6A 00 6A 00 6A 00 6A 00 6A 01 FF 35 0C 01 94 00 \z
		E8 >_lua_pcallk \z
		83 C4 18 EB 00 66 BB FF FF \z
		E9 :53A024 \z
		E9 :53A00C"
	})
	EEex_DisableCodeProtection()
	EEex_WriteAssembly(0x536B75, {{hookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallNewActions()
