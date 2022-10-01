
function EEex_Script_IsPlayerScript(script)
	local aux = EEex_TryGetUDAux(script)
	return aux and aux["EEex_IsPlayerScript"] == true
end
CAIScript.isPlayerScript = EEex_Script_IsPlayerScript

function EEex_Script_GetResRef(script)
	return script.cResRef:get()
end
CAIScript.getResRef = EEex_Script_GetResRef

-----------
-- Hooks --
-----------

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
