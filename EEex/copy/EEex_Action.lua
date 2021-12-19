
EEex_Action_ReturnType = {
	["ACTION_STOPPED"] = -3,
	["ACTION_ERROR"] = -2,
	["ACTION_DONE"] = -1,
	["ACTION_NORMAL"] = 0,
	["ACTION_INTERRUPTABLE"] = 1,
	["ACTION_NO_ACTION"] = 2,
}

-----------
-- Hooks --
-----------

function EEex_Action_Hook_OnEvaluatingUnknown(object)
	local curAction = object.m_curAction
	local actionID = curAction.m_actionID
	-- EEex_LuaAction
	if actionID == 472 then
		EEex_LuaAction_Object = object
		local success, retVal = EEex_Utility_Eval("EEex_LuaAction", curAction.m_string1.m_pchData:get())
		if success then
			return retVal ~= nil and retVal or EEex_Action_ReturnType.ACTION_DONE
		end
	end
	return EEex_Action_ReturnType.ACTION_ERROR
end
