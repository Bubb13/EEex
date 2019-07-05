
function EEex_InstallFixes()

	EEex_DisableCodeProtection()

	---------------------------------------------------------------------------------------
	-- Triggers with IDS values below 0x4000 should work correctly with object selectors --
	---------------------------------------------------------------------------------------

	local triggersObjectSelectorFix = EEex_WriteAssemblyAuto({[[

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
	EEex_WriteAssembly(EEex_Label("CAICondition::TriggerHolds()_FixHook"), {"!jmp_dword", {triggersObjectSelectorFix, 4, 4}})

	------------------------------------------------------------------------
	-- Opcode #233 should not crash when incrementing halberd proficiency --
	------------------------------------------------------------------------

	EEex_WriteAssembly(EEex_Label("Opcode233FixHalberdIncrement"), {"!lea_esi_[ecx+dword] #1E98 !nop !nop !nop !nop !nop !nop"})

	EEex_EnableCodeProtection()
end
EEex_InstallFixes()
