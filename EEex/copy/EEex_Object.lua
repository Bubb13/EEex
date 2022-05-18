
EEex_LuaObject = nil

-----------
-- Hooks --
-----------

function EEex_Object_Hook_ForceIgnoreActorScriptName(aiType)
	return aiType.m_SpecialCase:get(0) == 117
end

EEex_Object_Hook_OnEvaluatingUnknown_ReturnType = {
	["HANDLED_CONTINUE"] = 0,
	["HANDLED_DONE"] = 1,
	["UNHANDLED"] = 2,
}

function EEex_Object_Hook_OnEvaluatingUnknown(decodingAIType, caller, nSpecialCaseI, curAIType)

	local nObjectIDS = decodingAIType.m_SpecialCase:get(nSpecialCaseI)

	local setObject = function(object)
		if object then
			curAIType:Set(object:virtual_GetAIType())
			return EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.HANDLED_CONTINUE
		else
			decodingAIType:Set(CAIObjectType.NOONE)
			return EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.HANDLED_DONE
		end
	end

	local setInstance = function(objectID)
		return setObject(objectID and EEex_GameObject_Get(objectID) or nil)
	end

	if nObjectIDS == 115 then -- EEex_LuaObject

		return setObject(EEex_LuaObject)

	elseif nObjectIDS == 116 then -- EEex_MatchObject

		return setInstance(EEex_GetUDAux(caller)["EEex_MatchObject"])

	elseif nObjectIDS == 117 then -- EEex_Target

		local targetTable = EEex_Utility_GetOrCreate(EEex_GetUDAux(caller), "EEex_Target", {})
		return setInstance(targetTable[curAIType.m_name.m_pchData:get()])
	end

	return EEex_Object_Hook_OnEvaluatingUnknown_ReturnType.UNHANDLED
end
