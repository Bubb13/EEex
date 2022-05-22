
function EEex_AIBase_GetScriptLevel(aiBase, scriptLevel)
	return ({
		[0] = aiBase.m_overrideScript,
		[1] = aiBase.m_areaScript,
		[2] = aiBase.m_specificsScript,
		[4] = aiBase.m_classScript,
		[5] = aiBase.m_raceScript,
		[6] = aiBase.m_generalScript,
		[7] = aiBase.m_defaultScript,
	})[scriptLevel]
end
CGameAIBase.getScriptLevel = EEex_AIBase_GetScriptLevel

function EEex_AIBase_GetScriptLevelResRef(aiBase, scriptLevel)
	local script = EEex_AIBase_GetScriptLevel(scriptLevel)
	return script and script.cResRef:get() or ""
end
CGameAIBase.getScriptLevelResRef = EEex_AIBase_GetScriptLevelResRef
