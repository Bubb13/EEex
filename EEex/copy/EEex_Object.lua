
EEex_LuaObject = nil

-----------
-- Hooks --
-----------

function EEex_Object_Hook_OnEvaluatingUnknown(decodingAIType, caller, nSpecialCaseI, curAIType)
	local nObjectIDS = decodingAIType.m_SpecialCase:get(nSpecialCaseI)
	-- EEex_LuaObject
	if nObjectIDS == 115 then
		if EEex_LuaObject then
			curAIType.m_Instance = EEex_LuaObject.m_id
		else
			curAIType:Set(CAIObjectType.NOONE)
		end
		return true
	end
	return false
end
