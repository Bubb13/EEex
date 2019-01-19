
function B3Books_InstallBookChanges()

	EEex_DisableCodeProtection()

	EEex_WriteAssembly(0x6870F6, {"!jmp_byte"}) -- force bookMode to true
	EEex_WriteAssembly(0x709287, {"!jmp_byte"}) -- force hasMageBook to true

	EEex_EnableCodeProtection()
end
B3Books_InstallBookChanges()
