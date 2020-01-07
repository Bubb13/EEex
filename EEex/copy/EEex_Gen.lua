
function EEex_DefineGeneralAssembly()

	-- push script_level
	-- push *resref
	-- this CGameSprite
	EEex_WriteAssemblyAuto({[[

		$EEex_SetScriptLevel

		!push_state
		!mov_esi_ecx
	
		!push_dword *NullString
		!call >CResRef::operator_notequ
	
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
	
end
EEex_DefineGeneralAssembly()
