
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

	-- (Opcode #262) Not ready yet...
	--[[
	EEex_WriteAssembly(0x52CBE8, {"!nop !nop !nop"})
	EEex_WriteAssembly(0x60C7B3, {"90 90 90"})
	EEex_WriteAssembly(0x60C7B9, {"90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90 90"})
	--]]

	EEex_EnableCodeProtection()
	
end
EEex_InstallOpcodeChanges()
