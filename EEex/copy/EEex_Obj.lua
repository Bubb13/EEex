
EEex_LuaObject = -1

function EEex_InstallNewObjects()

	local luaObjectName = "EEex_LuaObject"
	local luaObjectAddress = EEex_Malloc(#luaObjectName + 1)
	EEex_WriteString(luaObjectAddress, luaObjectName)

	local newObjectsAddress = EEex_WriteAssemblyAuto({[[

		!cmp_eax_byte 72
		!je_dword >EEex_LuaObject
		!jmp_dword :5024B8

		@EEex_LuaObject

		!push_dword *CAIObjectType::ANYONE
		!lea_ecx_[ebp+byte] E8
		!call >CAIObjectType::operator=

		!push_dword ]], {luaObjectAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_byte 00
		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!mov_[ebp+byte]_eax F0
		!push_eax

		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08

		!pop_eax
		!cmp_eax_byte FF
		!je_dword :501A25
		!jmp_dword :50192B

	]]})

	EEex_DisableCodeProtection()
	EEex_WriteAssembly(0x50190D, {{newObjectsAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallNewObjects()
