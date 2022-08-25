
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
	local script = aiBase:getScriptLevel(scriptLevel)
	return script and script.cResRef:get() or ""
end
CGameAIBase.getScriptLevelResRef = EEex_AIBase_GetScriptLevelResRef

function EEex_AIBase_SetScriptLevel(aiBase, scriptLevel, script)
	aiBase:virtual_SetScript(scriptLevel, script)
end
CGameAIBase.setScriptLevel = EEex_AIBase_SetScriptLevel

function EEex_AIBase_SetScriptLevelResRef(aiBase, scriptLevel, resref)

	local newScript = EEex_NewUD("CAIScript")

	EEex_RunWithStackManager({
		{ ["name"] = "resref", ["struct"] = "CResRef", ["constructor"] = {["args"] = {resref} }}, },
		function(manager)
			newScript:Construct1(manager:getUD("resref"), 0)
		end)

	aiBase:setScriptLevel(scriptLevel, newScript)
end
CGameAIBase.setScriptLevelResRef = EEex_AIBase_SetScriptLevelResRef
