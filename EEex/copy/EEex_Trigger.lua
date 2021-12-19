
-----------
-- Hooks --
-----------

function EEex_Trigger_Hook_OnEvaluatingUnknown(object, trigger)
	-- EEex_LuaTrigger
	if trigger.m_triggerID == 0x410E then
		EEex_LuaTrigger_Object = object
		EEex_LuaTrigger_Trigger = trigger
		local success, retVal = EEex_Utility_Eval("EEex_LuaTrigger", trigger.m_string1.m_pchData:get())
		if success then
			return retVal
		end
	end
	return false
end
