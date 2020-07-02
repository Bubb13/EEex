
function EEex_Crashing()
	print(debug.traceback("EEex detected crash; Lua traceback ->", 2))
end

(function()

	EEex_DisableCodeProtection()

	EEex_HookAfterCall(EEex_Label("_ReportCrash()_LuaTracebackHook"), {[[

		!push_all_registers

		!push_dword ]], {EEex_WriteStringAuto("EEex_Crashing"), 4}, [[
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

end)()
