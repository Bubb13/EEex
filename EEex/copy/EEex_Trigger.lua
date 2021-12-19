
-----------
-- Hooks --
-----------

function EEex_Trigger_Hook_OnEvaluatingUnknown(object, trigger)
	-- EEex_LuaTrigger
	if trigger.m_triggerID == 0x410E then
		local func, err = load(trigger.m_string1.m_pchData:get(), nil, "t")
		if func then
			EEex_LuaTrigger_Object = object
			EEex_LuaTrigger_Trigger = trigger
			local success, val = xpcall(func, function(msg)
				return debug.traceback(msg)
			end)
			if success then
				return val
			end
			print("[EEex_LuaTrigger] Runtime error: "..val)
		else
			print("[EEex_LuaTrigger] Compile error: "..err)
		end
	end
	return false
end
