
EEex_DisableCodeProtection()

if EEex_Profiler_ForceTracePatches then

	local parseLargeLua = function(fileName)
		local file, fileErr = io.open(fileName, "r")
		if file == nil then
			print("File error: \n" .. fileErr)
			return false
		end
		for line in file:lines() do
			local code, loadErr = loadstring(line)
			if loadErr then
				print("Loadstring error: \n" .. loadErr)
				return false
			end
			code()
		end
		file:close()
	end

	print("Installing profiler patches, please wait...")
	parseLargeLua("EEex_scripts/EEex_Trace.lua")
end

EEex_EnableCodeProtection()
