
-----------
-- Hooks --
-----------

function EEex_Trigger_Hook_OnEvaluatingUnknown(object, trigger)
	local triggerID = trigger.m_triggerID
	if triggerID == 0x410E then -- EEex_LuaTrigger
		EEex_LuaTrigger_Object = object
		EEex_LuaTrigger_Trigger = trigger
		local success, retVal = EEex_Utility_Eval("EEex_LuaTrigger", trigger.m_string1.m_pchData:get())
		if success then
			return retVal
		end
	elseif triggerID == 0x4110 then -- EEex_MatchObject / EEex_MatchObjectEx
		local matchedID = EEex.MatchObject(object, trigger.m_string1.m_pchData:get(),
			trigger.m_specificID, trigger.m_specific2, trigger.m_specific3)
		EEex_GetUDAux(object)["EEex_MatchObject"] = matchedID
		return matchedID ~= -1
	end
	return false
end
