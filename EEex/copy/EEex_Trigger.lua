
-----------
-- Hooks --
-----------

function EEex_Trigger_Hook_OnEvaluatingUnknown(object, trigger)
	-- EEex_LuaTrigger
	if trigger.m_triggerID == 0x410E then
		EEex_LuaTrigger_Object = object
		EEex_LuaTrigger_Trigger= trigger
		return load(trigger.m_string1.m_pchData:get(), nil, "t")()
	end
	return false
end
