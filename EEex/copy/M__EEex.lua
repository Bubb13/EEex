
print("\n\n\z
	----------------------------\n\z
	-- EEex is starting up... --\n\z
	----------------------------\n\n\z
")

Infinity_DoFile("EEex_CmS")
Infinity_DoFile("EEex_CmP")

if EEex_InitialMemory then
	Infinity_DoFile("EEex_Cor")
	print("\n\n\z
		------------------------------------------\n\z
		-- EEex startup completed successfully! --\n\z
		------------------------------------------\n\n\z
	")
end
