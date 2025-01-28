
if EEex_Architecture == "x86" then
	EEex_DoFile("EEex_Assembly_x86_Patch")
elseif EEex_Architecture == "x86-64" then
	EEex_DoFile("EEex_Assembly_x86-64_Patch")
else
	EEex_Error(string.format("Unhandled EEex_Architecture: \"%s\"", EEex_Architecture))
end
