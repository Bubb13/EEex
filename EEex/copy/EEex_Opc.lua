
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

	local setAIScript = EEex_WriteAssemblyAuto({[[

		!push_state
		!mov_esi_ecx

		!push_dword #91BD15
		!call >CResRef::operator!=

		!test_eax_eax
		!je_dword >no_script

		!push_byte 24
		!call >operator_new
		!add_esp_byte 04

		!test_eax_eax
		!je_dword >no_script

		!push_byte 00
		!mov_ecx_[ebp+byte] 08
		!push_[ecx+byte] 04
		!push_[ecx]

		!mov_ecx_eax
		!call >CAIScript::CAIScript
		!jmp_dword >new_script

		@no_script
		!xor_eax_eax

		@new_script

		!push_eax
		!push_[ebp+byte] 0C
		!mov_ecx_esi

		!mov_eax_[esi]
		!call_[eax+dword] #90

		!pop_state
		!ret_word 08 00

	]]})

	local newOpcode400 = EEex_WriteOpcode({

		["ApplyEffect"] = {[[

			!push_state

			!mov_esi_ecx

			!cmp_[esi+dword]_byte #C8 00
			!je_dword >do_nothing

			!mov_[esi+dword]_dword #C8 #00

			!movzx_eax_word:[esi+byte] 1C
			!cmp_eax_byte 07
			!ja_dword >do_nothing

			!cmp_eax_byte 04
			!jb_dword >do_lookup
			
			!dec_eax

			@do_lookup

			!mov_ecx_[ebp+byte] 08
			!lea_ecx_[ecx+eax*4+dword] #268
			!mov_ecx_[ecx]
			!test_ecx_ecx
			!je_dword >undefined_script

			!mov_eax_[ecx]
			!mov_[esi+byte]_eax 6C
			!mov_eax_[ecx+byte] 04
			!mov_[esi+byte]_eax 70
			!jmp_dword >defined_script

			@undefined_script

			!mov_[esi+byte]_dword 6C #00
			!mov_[esi+byte]_dword 70 #00

			@defined_script

			!movzx_eax_word:[esi+byte] 1C
			!push_eax
			!lea_eax_[esi+byte] 2C
			!push_eax
			!mov_ecx_[ebp+byte] 08
			!call ]], {setAIScript, 4, 4}, [[
		
			@do_nothing

			!pop_state
			!ret_word 04 00

		]]},

		["OnRemove"] = {[[

			!push_state

			!mov_esi_ecx

			!movzx_eax_word:[esi+byte] 1C
			!push_eax
			!lea_eax_[esi+byte] 6C
			!push_eax
			!mov_ecx_[ebp+byte] 08
			!call ]], {setAIScript, 4, 4}, [[

			!pop_state
			!ret_word 04 00

		]]},
	})

	local opcodesHook = EEex_WriteAssemblyAuto(EEex_ConcatTables({[[

		!cmp_eax_dword #190
		!jne_dword >fail

		]], newOpcode400, [[

		@fail
		!jmp_dword :5A5A11

	]]}))

	EEex_WriteAssembly(0x5A15CD, {{opcodesHook, 4, 4}})

	-- (Opcode #262) Not ready yet...
	--[[
	EEex_WriteAssembly(0x52CBE8, {"!nop !nop !nop"})
	EEex_WriteAssembly(0x60C7B3, {"90 90 90"})
	EEex_WriteAssembly(0x60C7B9, {"90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90"})
	--]]

	EEex_EnableCodeProtection()
	
end
EEex_InstallOpcodeChanges()
