
EEex_LuaObject = nil

-----------
-- Hooks --
-----------

function EEex_Object_Hook_OnEvaluatingUnknown(decodingAIType, caller, nSpecialCaseI, curAIType)

	local nObjectIDS = decodingAIType.m_SpecialCase:get(nSpecialCaseI)

	local setObject = function(object)
		if object and object.m_id ~= -1 then
			curAIType.m_Instance = object.m_id
		else
			curAIType:Set(CAIObjectType.NOONE)
		end
	end

	local setInstance = function(objectID)
		if objectID and objectID ~= -1 then
			curAIType.m_Instance = objectID
		else
			curAIType:Set(CAIObjectType.NOONE)
		end
	end

	if nObjectIDS == 115 then -- EEex_LuaObject
		setObject(EEex_LuaObject)
		return true
	elseif nObjectIDS == 116 then -- EEex_MatchObject
		setInstance(EEex_GetUDAux(caller)["EEex_MatchObject"])
		return true
	end
	return false
end
