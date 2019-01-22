
function EEex_InstallOpcodeChanges()

	EEex_DisableCodeProtection()

	-- Remove the "at least 1 slot" checks from Opcode #42
	EEex_WriteAssembly(0x59027D, {"!nop !nop"})
	EEex_WriteAssembly(0x5902A8, {"!nop !nop"})
	EEex_WriteAssembly(0x5902D3, {"!nop !nop"})
	EEex_WriteAssembly(0x5902FE, {"!nop !nop"})
	EEex_WriteAssembly(0x590329, {"!nop !nop"})
	EEex_WriteAssembly(0x590354, {"!nop !nop"})
	EEex_WriteAssembly(0x59037F, {"!nop !nop"})
	EEex_WriteAssembly(0x5903AA, {"!nop !nop"})
	EEex_WriteAssembly(0x5903DC, {"!nop !nop !nop !nop !nop !nop"})

	-- Set strref of opcode #324 to Special
	EEex_WriteAssembly(0x57F805, {"8B 7E 44 90 90"}) 

	local fireSubspellAddress = EEex_WriteAssemblyAuto({[[

		!build_stack_frame
		!sub_esp_byte 0C
		!push_all_registers

		!mov_esi_ecx

		!lea_edi_[esi+byte] 2C
		!mov_ecx_edi
		!call >CResRef::IsValid

		!test_eax_eax
		!jne_dword >fire_spell

		!push_dword *aB_1
		!lea_eax_[ebp+byte] F8
		!push_eax
		!lea_ecx_[esi+dword] #90
		!call >CResRef::GetResRefStr
		!push_eax
		!lea_eax_[ebp+byte] F4
		!push_eax
		!call >(CString)_operator+
		!add_esp_byte 0C
		!mov_ecx_edi
		!push_eax
		!lea_eax_[ebp+byte] FC
		!push_eax
		!call >CResRef::operator=
		!lea_ecx_[ebp+byte] F4
		!call >CString::~CString
		!lea_ecx_[ebp+byte] F8
		!call >CString::~CString

		@fire_spell

		!push_[esi+dword] #10C
		!mov_ecx_esi
		!push_[esi+dword] #C4
		!push_byte 00
		!push_[ebp+byte] 08
		!push_edi
		!call >CGameEffect::FireSpell
		!mov_[esi+dword]_dword #110 #01

		!pop_all_registers
		!destroy_stack_frame
		!ret_word 04 00

	]]})

	local fireSubspellHook1 = EEex_WriteAssemblyAuto({[[
		!push_complete_state
		!push_esi
		!mov_ecx_edi
		!call ]], {fireSubspellAddress, 4, 4}, [[
		!pop_complete_state
		!ret
	]]})

	-- Fire subspell when Opcode #218 expires due to losing all layers
	EEex_WriteAssembly(0x59078B, {"!call", {fireSubspellHook1, 4, 4}, "!nop !nop !nop !nop !nop"})

	-- (Opcode #262) Not ready yet...
	--[[
	EEex_WriteAssembly(0x52CBE8, {"!nop !nop !nop"})
	EEex_WriteAssembly(0x60C7B3, {"90 90 90"})
	EEex_WriteAssembly(0x60C7B9, {"90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90"})
	--]]

	EEex_EnableCodeProtection()
	
end
EEex_InstallOpcodeChanges()
