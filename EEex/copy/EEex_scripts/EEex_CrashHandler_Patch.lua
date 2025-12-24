
(function()

	EEex_DisableCodeProtection()

	EEex_JITAt(EEex_Label("Hook-WinMain$filt$0-FirstInstruction"), {[[
		jmp #L(EEex::Override_crashHandler)
	]]})

	EEex_EnableCodeProtection()

end)()
