
EEex_Action_ReturnType = {
	["ACTION_STOPPED"] = -3,
	["ACTION_ERROR"] = -2,
	["ACTION_DONE"] = -1,
	["ACTION_NORMAL"] = 0,
	["ACTION_INTERRUPTABLE"] = 1,
	["ACTION_NO_ACTION"] = 2,
}

-------------
-- General --
-------------

-- Parses the given string as if it was fed through C:Eval() and
-- returns the compiled script object, (only filled with actions).
function EEex_Action_ParseResponseString(responseStr)

	local pScriptFile = EEex_NewUD("CAIScriptFile")
	pScriptFile:Construct()

	EEex_RunWithStackManager({
		{ ["name"] = "responseStr", ["struct"] = "CString", ["constructor"] = {["args"] = {responseStr} }, ["noDestruct"] = true }, },
		function(manager)
			pScriptFile:ParseResponseString(manager:getUD("responseStr"))
		end)

	return pScriptFile
end

-- Adds compiled actions returned by EEex_Action_ParseResponseString() to the end of the object's action queue.
-- Behavior identical to C:Eval().
function EEex_Action_QueueScriptFileResponseOnAIBase(pScriptFile, pGameAIBase)
	EEex_Utility_IterateCPtrList(pScriptFile.m_curResponse.m_actionList, function(pAction)
		pGameAIBase:virtual_InsertAction(pAction)
	end)
end
CAIScriptFile.queueResponseOnAIBase = EEex_Action_QueueScriptFileResponseOnAIBase

-- Same as EEex_Action_QueueScriptFileResponseOnAIBase() but takes a string instead of a compiled script object.
-- Prefer using compiled actions when efficiency is required.
function EEex_Action_QueueResponseStringOnAIBase(responseStr, pGameAIBase)
	EEex_RunWithStackManager({
		{ ["name"] = "scriptFile", ["struct"] = "CAIScriptFile" },
		{ ["name"] = "responseStr", ["struct"] = "CString", ["constructor"] = {["args"] = {responseStr} }, ["noDestruct"] = true }, },
		function(manager)
			local scriptFile = manager:getUD("scriptFile")
			scriptFile:ParseResponseString(manager:getUD("responseStr"))
			scriptFile:queueResponseOnAIBase(pGameAIBase)
		end)
end

-- Instantly executes compiled actions returned by EEex_Action_ParseResponseString()
-- without interrupting the current action / readying the object.
-- *** ONLY WORKS CORRECTLY FOR ACTIONS DEFINED IN INSTANT.IDS ***
function EEex_Action_ExecuteScriptFileResponseAsAIBaseInstantly(pScriptFile, pGameAIBase)

	local pCurAction = pGameAIBase.m_curAction

	EEex_RunWithStackManager({
		-- Copy currently executing action
		{ ["name"] = "curActionCopy", ["struct"] = "CAIAction", ["constructor"] = { ["variant"] = "copy", ["args"] = {pCurAction} }}, },
		function(manager)

			local isSprite = pGameAIBase:virtual_GetObjectType() == CGameObjectType.SPRITE

			-- Save some clobbered fields
			local lastActionReturnCopy = pGameAIBase.m_nLastActionReturn
			local targetIdCopy = isSprite and pGameAIBase.m_targetId or nil

			EEex_Utility_IterateCPtrList(pScriptFile.m_curResponse.m_actionList, function(pAction)

				-- Override current action
				pCurAction:operator_equ(pAction)

				-- Decode new action's CAIObjectType(s)
				if not EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_ruleTables.m_lNoDecodeList:Find1(pCurAction.m_actionID) then
					pCurAction:Decode(pGameAIBase)
				end

				-- Execute new action
				pGameAIBase:virtual_ExecuteAction()
			end)

			-- Restore clobbered fields
			pGameAIBase.m_nLastActionReturn = lastActionReturnCopy
			if isSprite then
				pGameAIBase:UpdateTarget(EEex_GameObject_Get(targetIdCopy))
			end

			-- Restore overridden action
			pCurAction:operator_equ(manager:getUD("curActionCopy"))
		end)
end
CAIScriptFile.executeResponseAsAIBaseInstantly = EEex_Action_ExecuteScriptFileResponseAsAIBaseInstantly

-- Same as EEex_Action_ExecuteScriptFileResponseAsAIBaseInstantly() but takes a string instead of a compiled script object.
-- Prefer using compiled actions when efficiency is required.
function EEex_Action_ExecuteResponseStringOnAIBaseInstantly(responseStr, pGameAIBase)
	EEex_RunWithStackManager({
		{ ["name"] = "scriptFile", ["struct"] = "CAIScriptFile" },
		{ ["name"] = "responseStr", ["struct"] = "CString", ["constructor"] = {["args"] = {responseStr} }, ["noDestruct"] = true }, },
		function(manager)
			local scriptFile = manager:getUD("scriptFile")
			scriptFile:ParseResponseString(manager:getUD("responseStr"))
			scriptFile:executeResponseAsAIBaseInstantly(pGameAIBase)
		end)
end

-- Frees the object returned by EEex_Action_ParseResponseString().
-- Attempting to use an object after free()'ing it will result in a crash.
function EEex_Action_FreeScriptFile(pScriptFile)
	pScriptFile:Destruct()
	EEex_FreeUD(pScriptFile)
end
CAIScriptFile.free = EEex_Action_FreeScriptFile

-----------
-- Hooks --
-----------

function EEex_Action_Hook_OnEvaluatingUnknown(aiBase)

	local curAction = aiBase.m_curAction
	local actionID = curAction.m_actionID

	if actionID == 472 then -- EEex_LuaAction

		EEex_LuaAction_Object = aiBase

		local success, retVal = EEex_Utility_Eval("EEex_LuaAction", curAction.m_string1.m_pchData:get())
		if success then
			return retVal ~= nil and retVal or EEex_Action_ReturnType.ACTION_DONE
		end

	elseif actionID == 473 then -- EEex_MatchObject / EEex_MatchObjectEx

		EEex_GetUDAux(aiBase)["EEex_MatchObject"] = EEex.MatchObject(aiBase, curAction.m_string1.m_pchData:get(),
			curAction.m_specificID, curAction.m_specificID2, curAction.m_specificID3)

		return EEex_Action_ReturnType.ACTION_DONE

	elseif actionID == 474 then -- EEex_SetTarget

		local target = aiBase:GetTargetShare()
		local targetTable = EEex_Utility_GetOrCreate(EEex_GetUDAux(aiBase), "EEex_Target", {})
		targetTable[curAction.m_string1.m_pchData:get()] = target and target.m_id or nil

		return EEex_Action_ReturnType.ACTION_DONE
	end

	return EEex_Action_ReturnType.ACTION_ERROR
end
