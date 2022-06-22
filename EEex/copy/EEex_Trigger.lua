
-------------
-- General --
-------------

-- Parses the given string as a .BS trigger block and returns the compiled script object, (only filled with triggers).
-- Call :free() on the returned CAIScriptFile when it is no longer needed.
function EEex_Trigger_ParseConditionalString(string)
	local toReturn = EEex_NewUD("CAIScriptFile")
	toReturn:Construct()
	toReturn.free = function(scriptFile)
		scriptFile:Destruct()
		EEex_FreeUD(scriptFile)
	end
	EEex_RunWithStackManager({
		{ ["name"] = "cstring", ["struct"] = "CString", ["constructor"] = { ["args"] = { string } }, ["noDestruct"] = true } },
		function(manager)
			toReturn:ParseConditionalString(manager:getUD("cstring"))
		end)
	return toReturn
end

-- Evaluates compiled triggers returned by EEex_Trigger_ParseConditionalString() in the context of aiBase.
function EEex_Trigger_EvalScriptFileConditionalAsAIBase(scriptFile, aiBase)
	return scriptFile.m_curCondition:Hold(aiBase.m_pendingTriggers, aiBase) ~= 0
end
CAIScriptFile.evalConditionalAsAIBase = EEex_Trigger_EvalScriptFileConditionalAsAIBase

-- Same as EEex_Trigger_EvalScriptFileConditionalAsAIBase() but takes a string instead of a compiled script object.
-- Prefer using compiled triggers when efficiency is required.
function EEex_Trigger_EvalConditionalStringAsAIBase(string, aiBase)
	return EEex_RunWithStackManager({
		{ ["name"] = "scriptFile", ["struct"] = "CAIScriptFile" },
		{ ["name"] = "cstring", ["struct"] = "CString", ["constructor"] = { ["args"] = { string } }, ["noDestruct"] = true } },
		function(manager)
			local scriptFile = manager:getUD("scriptFile")
			scriptFile:ParseConditionalString(manager:getUD("cstring"))
			return scriptFile.m_curCondition:Hold(aiBase.m_pendingTriggers, aiBase) ~= 0
		end)
end

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

	elseif triggerID == 0x410F then -- EEex_IsImmuneToOpcode

		local targetSprite = quickDecode()
		if not targetSprite then
			return false
		end

		local found = false

		local lookingForID = trigger.m_specificID
		EEex_Utility_IterateCPtrList(targetSprite:getActiveStats().m_cImmunitiesEffect, function(effect)
			if effect.m_effectId == lookingForID then
				found = true
				return true
			end
		end)

		return found

	elseif triggerID == 0x4110 then -- EEex_MatchObject / EEex_MatchObjectEx

		local matchedID = EEex.MatchObject(aiBase, trigger.m_string1.m_pchData:get(),
			trigger.m_specificID, trigger.m_specific2, trigger.m_specific3)

		EEex_GetUDAux(aiBase)["EEex_MatchObject"] = matchedID
		return matchedID ~= -1
	end

	return false
end
