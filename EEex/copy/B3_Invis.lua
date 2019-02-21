
B3Invis_RenderAsInvisible = true

function B3Invis_InstallOpcode193Changes()

	EEex_DisableCodeProtection()

	local canSeeInvisAddress = EEex_WriteAssemblyAuto({[[
		!build_stack_frame
		!sub_esp_byte 04
		!push_registers
		!mov_eax_[dword] *g_pBaldurChitin
		!mov_eax_[eax+dword] *CBaldurChitin::m_pObjectGame
		!mov_esi_[eax+dword] #3E54
		!test_esi_esi
		!je_dword >fail
		!xor_ebx_ebx
		@loop
		!lea_ecx_[ebp+byte] FC
		!push_ecx
		!push_[esi+byte] 08
		!call >CGameObjectArray::GetShare
		!mov_ecx_[ebp+byte] FC
		!cmp_[ecx+dword]_byte #C08 00
		!jne_dword >found
		!mov_esi_[esi]
		!test_esi_esi
		!jne_dword >loop
		@fail
		!mov_ebx #01
		@found
		!mov_eax_ebx
		!restore_stack_frame
		!ret
	]]})

	local invisCheckHook1 = EEex_WriteAssemblyAuto({[[
		!push_complete_state
		!cmp_[esi+dword]_byte #2D07 00
		!je_dword >ret
		!call ]], {canSeeInvisAddress, 4, 4}, [[
		!cmp_eax_byte 00
		@ret
		!pop_complete_state
		!ret
	]]})

	local invisCheckHook2 = EEex_WriteAssemblyAuto({[[
		!push_complete_state
		!cmp_[ebx+dword]_byte #2D07 00
		!je_dword >ret
		!call ]], {canSeeInvisAddress, 4, 4}, [[
		!cmp_eax_byte 00
		@ret
		!pop_complete_state
		!ret
	]]})

	local forceCircleHook = EEex_WriteAssemblyAuto({[[
		!push_complete_state
		!cmp_[eax+dword]_byte #9B 00
		!jne_dword >ret
		!cmp_[ebx+dword]_byte #2D07 00
		!je_dword >ret
		!call ]], {canSeeInvisAddress, 4, 4}, [[
		!cmp_eax_byte 01
		@ret
		!pop_complete_state
		!ret
	]]})

	EEex_WriteAssembly(EEex_Label("Opcode218IsOverHook"), {"!call", {invisCheckHook1, 4, 4}, "!nop !nop"})
	EEex_WriteAssembly(EEex_Label("Opcode218RenderMarkerHook"), {"!call", {invisCheckHook2, 4, 4}, "!nop !nop"})
	EEex_WriteAssembly(EEex_Label("Opcode218IsPausedHook"), {"!call", {forceCircleHook, 4, 4}, "!nop !nop"})

	if B3Invis_RenderAsInvisible then

		local invisCheckHook3 = EEex_WriteAssemblyAuto({[[
			!push_complete_state
			!cmp_[ebx+dword]_byte #2D07 00
			!je_dword >ret
			!call ]], {canSeeInvisAddress, 4, 4}, [[
			!cmp_eax_byte 01
			@ret
			!pop_complete_state
			!ret
		]]})
		
		EEex_WriteAssembly(EEex_Label("Opcode218RenderSpriteHook1"), {"!call", {invisCheckHook2, 4, 4}, "!nop !nop"})
		EEex_WriteAssembly(EEex_Label("Opcode218RenderSpriteHook2"), {"!call", {invisCheckHook3, 4, 4}, "!nop !nop"})
	end
	EEex_EnableCodeProtection()
end
B3Invis_InstallOpcode193Changes()
