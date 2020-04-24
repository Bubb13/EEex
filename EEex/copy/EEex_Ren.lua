
EEex_LinesToDraw = {}

function EEex_InstallRenderHook()

	local hookLinesToDraw = "EEex_LinesToDraw"
	local hookLinesToDrawAddress = EEex_Malloc(#hookLinesToDraw + 1, 34)
	EEex_WriteString(hookLinesToDrawAddress, hookLinesToDraw)

	local renderHookAddress = EEex_WriteAssemblyAuto({[[

		!build_stack_frame
		!sub_esp_byte 0C
		!push_registers

		!mov_eax_[ebp+byte] 08
		!mov_[ebp+byte]_eax FC
		!mov_[ebp+byte]_ecx F8

		!push_[ebp+byte] 08
		!call >CInfinity::RenderAOE

		!push_dword ]], {hookLinesToDrawAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_rawlen
		!add_esp_byte 08

		!test_eax_eax
		!je_dword >no_args

		!mov_edi_eax
		!mov_esi #01

		@outer_loop

		!push_esi
		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_rawgeti
		!add_esp_byte 0C

		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_rawlen
		!add_esp_byte 08

		!mov_ebx_eax
		!mov_[ebp+byte]_dword F4 #01

		@push_loop

		!push_[ebp+byte] F4
		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_rawgeti
		!add_esp_byte 0C

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

		!inc_[ebp+byte] F4
		!cmp_[ebp+byte]_ebx F4
		!jle_dword >push_loop

		!push_[ebp+byte] FC
		!mov_ecx_[ebp+byte] F8
		!call >CInfinity::DrawRectangle

		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08

		!inc_esi
		!cmp_esi_edi
		!jle_dword >outer_loop

		@no_args

		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08

		!restore_stack_frame
		!ret_word 04 00

	]]})

	EEex_DisableCodeProtection()
	EEex_WriteAssembly(EEex_Label("CGameArea::Render()_hook"), {{renderHookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallRenderHook()
