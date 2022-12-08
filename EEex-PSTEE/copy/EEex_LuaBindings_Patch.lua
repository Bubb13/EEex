
(function()

	EEex_DisableCodeProtection()

	local override = function(patternName)
		EEex_JITAt(EEex_Label(patternName), {[[
			jmp #L(override_#$(1)) ]], {patternName}
		})
	end

	override("tolua_open")
	override("tolua_cclass")

	override("module_newindex_event")
	override("class_newindex_event")

	override("module_index_event")
	override("class_index_event")

	EEex_EnableCodeProtection()

end)()
