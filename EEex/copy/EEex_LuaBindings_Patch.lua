
EEex_DisableCodeProtection()

EEex_JITAt(EEex_Patterns["module_newindex_event"], {[[
	jmp ]], EEex_AssemblyToHex(EEex_Patterns["override_module_newindex_event"]), [[ #ENDL
]]})

EEex_EnableCodeProtection()
