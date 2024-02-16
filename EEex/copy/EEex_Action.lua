
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

-- @bubb_doc { EEex_Action_ParseResponseString }
--
-- @summary: Parses ``responseStr`` as if it was fed through ``C:Eval()`` and
--           returns the compiled script object, (only filled with actions).
--
--           *** Remember to call *** ``:free()`` *** on the returned value when it is no longer being used. ***
--
-- @param { responseStr / type=string }: The string to parse.
--
-- @return { usertype=CAIScriptFile }: See summary.

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

-- @bubb_doc { EEex_Action_QueueScriptFileResponseOnAIBase / instance_name=queueResponseOnAIBase }
--
-- @summary: Adds compiled actions returned by ``EEex_Action_ParseResponseString()`` to the end of ``pGameAIBase``'s action queue.
--           Behavior identical to ``C:Eval()``.
--
-- @self { pScriptFile / usertype=CAIScriptFile }: The AI script file returned by ``EEex_Action_ParseResponseString()``.
--
-- @param { pGameAIBase / usertype=CGameAIBase }: The AI base to queue the actions on.

function EEex_Action_QueueScriptFileResponseOnAIBase(pScriptFile, pGameAIBase)
	EEex_Utility_IterateCPtrList(pScriptFile.m_curResponse.m_actionList, function(pAction)
		pGameAIBase:virtual_InsertAction(pAction)
	end)
end
CAIScriptFile.queueResponseOnAIBase = EEex_Action_QueueScriptFileResponseOnAIBase

-- @bubb_doc { EEex_Action_QueueResponseStringOnAIBase }
--
-- @summary: Adds the actions contained in ``responseStr`` to the end of ``pGameAIBase``'s action queue.
--           Behavior identical to ``C:Eval()``.
--
--           ``EEex_Action_ParseResponseString()`` is used to compile ``responseStr``; prefer using this function
--           in conjunction with ``EEex_Action_QueueScriptFileResponseOnAIBase()`` when efficiency is required.
--
-- @param { responseStr / type=string }: The string to parse.
--
-- @param { pGameAIBase / usertype=CGameAIBase }: The AI base to queue the actions on.

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

-- @bubb_doc { EEex_Action_ExecuteScriptFileResponseAsAIBaseInstantly / instance_name=executeResponseAsAIBaseInstantly }
--
-- @summary: Has ``pGameAIBase`` instantly execute compiled actions returned by ``EEex_Action_ParseResponseString()``
--           without interrupting ``pGameAIBase``'s current action / readying ``pGameAIBase``.
--
--           *** Running this function with actions not defined in INSTANT.IDS is undefined behavior. ***
--
-- @self { pScriptFile / usertype=CAIScriptFile }: The AI script file returned by ``EEex_Action_ParseResponseString()``.
--
-- @param { pGameAIBase / usertype=CGameAIBase }: The AI base that will execute the actions.

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

-- @bubb_doc { EEex_Action_ExecuteResponseStringOnAIBaseInstantly }
--
-- @summary: Has ``pGameAIBase`` instantly execute the actions contained in ``responseStr``
--           without interrupting ``pGameAIBase``'s current action / readying ``pGameAIBase``.
--
--           ``EEex_Action_ParseResponseString()`` is used to compile ``responseStr``; prefer using this function
--           in conjunction with ``EEex_Action_ExecuteScriptFileResponseAsAIBaseInstantly()`` when efficiency is required.
--
--           *** Running this function with actions not defined in INSTANT.IDS is undefined behavior. ***
--
-- @param { responseStr / type=string }: The string to parse.
--
-- @param { pGameAIBase / usertype=CGameAIBase }: The AI base that will execute the actions.

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

-- @bubb_doc { EEex_Action_FreeScriptFile / instance_name=free }
--
-- @summary: Frees the value returned by ``EEex_Action_ParseResponseString()``.
--
--           *** Attempting to use *** ``pScriptFile`` *** after calling *** ``:free()`` *** will result in a crash. ***
--
-- @self { pScriptFile / usertype=CAIScriptFile }: The AI script file to free.

function EEex_Action_FreeScriptFile(pScriptFile)
	pScriptFile:Destruct()
	EEex_FreeUD(pScriptFile)
end
CAIScriptFile.free = EEex_Action_FreeScriptFile

---------------
-- Listeners --
---------------

EEex_Action_Private_SpriteStartedNextActionListeners = {}

function EEex_Action_AddSpriteStartedNextActionListener(func)
	table.insert(EEex_Action_Private_SpriteStartedNextActionListeners, func)
end

EEex_Action_Private_SpriteStartedActionListeners = {}

function EEex_Action_AddSpriteStartedActionListener(func)
	table.insert(EEex_Action_Private_SpriteStartedActionListeners, func)
end

EEex_Action_Private_EnabledSpriteStartedActionListeners = {}

function EEex_Action_AddEnabledSpriteStartedActionListener(funcName, func)
	EEex_Action_Private_EnabledSpriteStartedActionListeners[funcName] = func
end

------------------------------------
-- Built-In Action Hook Listeners --
------------------------------------

EEex_Action_BuiltInListener = {
	["SpellToPoint"] = function(sprite, action)
		local spellActions = {
			 [31] =  95, -- Spell            => SpellPoint
			[113] = 114, -- ForceSpell       => ForceSpellPoint
			[181] = 337, -- ReallyForceSpell => ReallyForceSpellPoint
			[191] = 192, -- SpellNoDec       => SpellPointNoDec
		}
		local newActionID = spellActions[action.m_actionID]
		if newActionID then
			local targetObject = EEex_GameObject_Get(action.m_acteeID.m_Instance)
			if targetObject then
				action.m_actionID = newActionID
				action.m_dest.x = targetObject.m_pos.x
				action.m_dest.y = targetObject.m_pos.y
			end
		end
	end
}

-- Causes the next action's projectile to target a point instead of tracking the entity.
-- Used from a script like:
--     EEex_LuaAction("EEex_Action_NextSpellToPoint()")
--     SpellNoDecRES("SPWI304",PartySlot1)  // Fireball

function EEex_Action_NextSpellToPoint()
	EEex_Action_AddSpriteStartedNextActionListener(EEex_Action_BuiltInListener.SpellToPoint)
end

-----------
-- Hooks --
-----------

function EEex_Action_Private_SpellObjectOffset(aiBase, curAction, bOnlySprite, realActionID, realActionFunc)

	if bOnlySprite and not aiBase:isSprite(true) then
		return
	end

	local target = aiBase:GetTargetShareType2(CGameObjectType.AIBASE)
	if target == nil then
		return
	end

	curAction.m_actionID = realActionID
	curAction.m_dest.x = target.m_pos.x + curAction.m_dest.x
	curAction.m_dest.y = target.m_pos.y + curAction.m_dest.y
	return realActionFunc(aiBase)
end

EEex_Action_Private_Switch = {

	-- EEex_LuaAction
	[472] = function(aiBase, curAction)

		EEex_LuaAction_Object = aiBase

		local success, retVal = EEex_Utility_Eval("EEex_LuaAction", curAction.m_string1.m_pchData:get())
		if success then
			return retVal ~= nil and retVal or EEex_Action_ReturnType.ACTION_DONE
		end
	end,

	-- EEex_MatchObject / EEex_MatchObjectEx
	[473] = function(aiBase, curAction)

		-- [EEex.dll]
		EEex_GetUDAux(aiBase)["EEex_MatchObject"] = EEex.MatchObject(aiBase, curAction.m_string1.m_pchData:get(),
			curAction.m_specificID, curAction.m_specificID2, curAction.m_specificID3)

		return EEex_Action_ReturnType.ACTION_DONE
	end,

	-- EEex_SetTarget
	[474] = function(aiBase, curAction)

		local target = aiBase:GetTargetShare()
		local targetTable = EEex_Utility_GetOrCreateTable(EEex_GetUDAux(aiBase), "EEex_Target")
		targetTable[curAction.m_string1.m_pchData:get()] = target and target.m_id or nil

		return EEex_Action_ReturnType.ACTION_DONE
	end,

	-- EEex_SpellObjectOffset / EEex_SpellObjectOffsetRES
	[476] = function(aiBase, curAction)
		return EEex_Action_Private_SpellObjectOffset(aiBase, curAction, true, 95, CGameSprite.SpellPoint)
	end,

	-- EEex_SpellObjectOffsetNoDec / EEex_SpellObjectOffsetNoDecRES
	[477] = function(aiBase, curAction)
		return EEex_Action_Private_SpellObjectOffset(aiBase, curAction, true, 192, CGameSprite.SpellPoint)
	end,

	-- EEex_ForceSpellObjectOffset / EEex_ForceSpellObjectOffsetRES
	[478] = function(aiBase, curAction)
		return EEex_Action_Private_SpellObjectOffset(aiBase, curAction, false, 114, CGameAIBase.ForceSpellPoint)
	end,

	-- EEex_ReallyForceSpellObjectOffset / EEex_ReallyForceSpellObjectOffsetRES
	[479] = function(aiBase, curAction)
		return EEex_Action_Private_SpellObjectOffset(aiBase, curAction, false, 337, CGameAIBase.ForceSpellPoint)
	end,
}

function EEex_Action_Hook_OnEvaluatingUnknown(aiBase)

	local curAction = aiBase.m_curAction
	local handler = EEex_Action_Private_Switch[curAction.m_actionID]

	if handler then
		local result = handler(aiBase, curAction)
		if result ~= nil then
			return result
		end
	end

	return EEex_Action_ReturnType.ACTION_ERROR
end

function EEex_Action_LuaHook_OnAfterSpriteStartedAction(sprite)

	local action = sprite.m_curAction

	local temp = EEex_Action_Private_SpriteStartedNextActionListeners
	EEex_Action_Private_SpriteStartedNextActionListeners = {}

	for _, listener in ipairs(temp) do
		listener(sprite, action)
	end

	for _, listener in ipairs(EEex_Action_Private_SpriteStartedActionListeners) do
		listener(sprite, action)
	end
end
