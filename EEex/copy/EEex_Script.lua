
function EEex_Script_IsPlayerScript(script)
	-- [EEex.dll]
	return EEex.IsPlayerScript(script)
end
CAIScript.isPlayerScript = EEex_Script_IsPlayerScript

function EEex_Script_GetResRef(script)
	return script.cResRef:get()
end
CAIScript.getResRef = EEex_Script_GetResRef
