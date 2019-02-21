
function B3FixTri()

	local fixAddress = EEex_WriteAssemblyAuto({[[

		!add_esp_byte 4

		!push_byte 30
		!call >_malloc
		!add_esp_byte 4
		!mov_ebx_eax

		!push_byte 00
		!push_byte 00
		!mov_ecx_ebx
		!call >CAITrigger::CAITrigger

		!push_edi
		!mov_ecx_ebx
		!call >CAITrigger::operator_equ

		!push_[ebp+byte] 10
		!lea_ecx_[ebx+byte] 08
		!call >CAIObjectType::Decode

		!mov_ecx_[esi+byte] 08
		!mov_esi_[esi]
		!push_ebx
		!call >CAITrigger::OfType

		!test_[edi+byte]_byte 1C 01
		!jmp_dword >CAICondition::TriggerHolds()_FixResume

	]]})

	EEex_DisableCodeProtection()
	EEex_WriteAssembly(EEex_Label("CAICondition::TriggerHolds()_FixHook"), {"!jmp_dword", {fixAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
B3FixTri()
