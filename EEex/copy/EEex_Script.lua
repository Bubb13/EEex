
function EEex_Script_Hook_OnRead(script, bPlayerScript)
	EEex_GetUDAux(script)["EEex_IsPlayerScript"] = bPlayerScript ~= 0
end

function EEex_Script_Hook_OnCopy(srcScript, destScript)

	local srcAux = EEex_TryGetUDAux(srcScript)
	if not srcAux then
		EEex_Error("Unknown srcScript (this should never happen)!")
	end

	EEex_GetUDAux(destScript)["EEex_IsPlayerScript"] = srcAux["EEex_IsPlayerScript"]
end

function EEex_Script_Hook_OnDestruct(script)
	EEex_DeleteUDAux(script)
end
