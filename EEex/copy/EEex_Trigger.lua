
-----------
-- Hooks --
-----------

function EEex_Trigger_Hook_OnEvaluatingUnknown(aiBase, trigger)

	local triggerID = trigger.m_triggerID

	local quickDecode = function()
		return EEex_RunWithStackManager({
			{ ["name"] = "pointer", ["struct"] = "Pointer<CGameSprite>" }, },
			function(manager)
				local pointer = manager:getUD("pointer")
				aiBase:virtual_QuickDecode(trigger, pointer)
				return pointer.reference
			end)
	end

	if triggerID == 0x410D then -- EEex_HasDispellableEffect

		local targetSprite = quickDecode()
		if not targetSprite then
			return false
		end

		local found = false

		local testBit = function(effect)
			if EEex_BAnd(effect.m_flags, 0x1) ~= 0 then
				found = true
				return true
			end
		end

		EEex_Utility_IterateCPtrList(targetSprite.m_timedEffectList, testBit)
		if found then
			return true
		end

		EEex_Utility_IterateCPtrList(targetSprite.m_equipedEffectList, testBit)
		return found

	elseif triggerID == 0x410E then -- EEex_LuaTrigger

		EEex_LuaTrigger_Object = aiBase
		EEex_LuaTrigger_Trigger = trigger

		local success, retVal = EEex_Utility_Eval("EEex_LuaTrigger", trigger.m_string1.m_pchData:get())
		if success then
			return retVal
		end

	elseif triggerID == 0x4110 then -- EEex_MatchObject / EEex_MatchObjectEx

		local matchedID = EEex.MatchObject(aiBase, trigger.m_string1.m_pchData:get(),
			trigger.m_specificID, trigger.m_specific2, trigger.m_specific3)

		EEex_GetUDAux(aiBase)["EEex_MatchObject"] = matchedID
		return matchedID ~= -1
	end

	return false
end
