
B3Scale_Width = Infinity_GetINIValue("B3Scale", "Width", -1)

function B3Scale_SetWidth(w)
	B3Scale_Width = w
	Infinity_SetINIValue("B3Scale", "Width", B3Scale_Width)
	B3Scale_PokeEngine()
end

function B3Scale_GetVideoSize()
	local CChitin = EEex_ReadDword(EEex_Label("g_pChitin"))
	local CVidMode = EEex_ReadDword(CChitin + 0x180)
	local w = EEex_ReadDword(CVidMode + 0xD4)
	local h = EEex_ReadDword(CVidMode + 0xD8)
	return w, h
end

function B3Scale_PokeEngine()
	local CChitin = EEex_ReadDword(EEex_Label("g_pChitin"))
	local w, h = B3Scale_GetVideoSize()
	EEex_Call(EEex_Label("CChitin::OnResizeWindow"), {h, w}, CChitin, 0x0)
end

function B3Scale_HookDoSizeChange()

	local w, h = B3Scale_GetVideoSize()
	local ratio = w / h

	if B3Scale_Width == -1 then
		local w, h = B3Scale_GetVideoSize()
		B3Scale_Width = w
	end

	EEex_WriteWord(EEex_Label("CVidMode::SCREENWIDTH"), B3Scale_Width)
	EEex_WriteWord(EEex_Label("CVidMode::SCREENHEIGHT"), B3Scale_Width / ratio)
end

EEex_DisableCodeProtection()
EEex_HookAfterCall(EEex_Label("CChitin::OnResizeWindow()_ScaleHook"), {[[

	!push_all_registers

	!push_dword ]], {EEex_WriteStringAuto("B3Scale_HookDoSizeChange"), 4}, [[
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
