
function EEex_InstallLuaHooks()

	local actorIDJmp = EEex_Label("Eval()_actorIDJmp")
	local actorIDJmpDest = actorIDJmp + EEex_ReadByte(actorIDJmp, 1) + 2

	local hookAddress = EEex_WriteAssemblyAuto({[[

		!jl_dword ]], {actorIDJmpDest, 4, 4}, [[

		!build_stack_frame
		!sub_esp_byte 04
		!push_eax
		!push_ecx
		!push_edx
		!push_esi
		!push_edi

		!push_eax

		!lea_ecx_[ebp+byte] FC
		!push_ecx ; ptr ;
		!push_eax ; index ;
		!call >CGameObjectArray::GetShare
		!add_esp_byte 08
		!test_al_al
		!pop_eax
		!jnz_dword >fail

		!mov_ebx_eax
		!jmp_dword >return

		@fail
		!or_ebx_byte FF

		@return
		!pop_edi
		!pop_esi
		!pop_edx
		!pop_ecx
		!pop_eax
		!destroy_stack_frame
		!jmp_dword ]], {actorIDJmp + 0x5, 4, 4}, [[
	]]})

	EEex_DisableCodeProtection()
	EEex_WriteAssembly(actorIDJmp, {"!jmp_dword", {hookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallLuaHooks()
