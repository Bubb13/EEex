
---------------
-- Listeners --
---------------

EEex_Opcode_ListsResolvedListeners = {}

function EEex_Opcode_AddListsResolvedListener(func)
	table.insert(EEex_Opcode_ListsResolvedListeners, func)
end

-----------------------
-- Private Functions --
-----------------------

function EEex_Opcode_Private_ApplyExtraMeleeEffects(sprite, targetSprite)

	EEex_Utility_IterateCPtrList(sprite:getActiveStats().m_cExtraMeleeEffects, function(effect)

		if not EEex_GetUDAux(effect)["EEex_BypassOp120"] then
			return -- continue
		end

		if EEex_BAnd(effect.m_special, 4) ~= 0 and sprite.m_equipment.m_selectedWeapon ~= 10 then
			return -- continue
		end

		pExtraEffect = effect:virtual_Copy()

		pExtraEffect.m_sourceId = sprite.m_id
		pExtraEffect.m_source.x = sprite.m_pos.x
		pExtraEffect.m_source.y = sprite.m_pos.y

		pExtraEffect.m_sourceTarget = targetSprite.m_id
		pExtraEffect.m_target.x = targetSprite.m_pos.x
		pExtraEffect.m_target.y = targetSprite.m_pos.y

		local addEffectMessage = EEex_NewUD("CMessageAddEffect")
		-- CGameEffect* effect, bool noSave, short commType, int caller, int target
		addEffectMessage:Construct(pExtraEffect, false, 1, sprite.m_id, targetSprite.m_id)
		EngineGlobals.g_pBaldurChitin.m_cMessageHandler:AddMessage(addEffectMessage, false)
	end)
end

function EEex_Opcode_Private_ApplyExtraRangedEffects(sprite, targetSprite)

	EEex_Utility_IterateCPtrList(sprite:getActiveStats().m_cExtraRangedEffects, function(effect)

		if not EEex_GetUDAux(effect)["EEex_BypassOp120"] then
			return -- continue
		end

		pExtraEffect = effect:virtual_Copy()

		pExtraEffect.m_sourceId = sprite.m_id
		pExtraEffect.m_source.x = sprite.m_pos.x
		pExtraEffect.m_source.y = sprite.m_pos.y

		pExtraEffect.m_sourceTarget = targetSprite.m_id
		pExtraEffect.m_target.x = targetSprite.m_pos.x
		pExtraEffect.m_target.y = targetSprite.m_pos.y

		EEex_Utility_Switch(pExtraEffect.m_targetType, {
			[1] = function()
				local addEffectMessage = EEex_NewUD("CMessageAddEffect")
				-- CGameEffect* effect, bool noSave, short commType, int caller, int target
				addEffectMessage:Construct(pExtraEffect, false, 1, sprite.m_id, sprite.m_id)
				EngineGlobals.g_pBaldurChitin.m_cMessageHandler:AddMessage(addEffectMessage, false)
			end,
			[3] = function()
				pExtraEffect.m_flags = EEex_BOr(pExtraEffect, 4)
				sprite:ApplyEffectToParty(pExtraEffect)
				pExtraEffect:virtual_Destruct(true)
			end,
			[4] = function()
				pExtraEffect.m_flags = EEex_BOr(pExtraEffect, 4)
				-- CGameEffect* effect, int ignoreParty, int useSpecifics, byte specifics, CGameObject* pIgnore
				sprite.m_pArea:ApplyEffect(pExtraEffect, false, false, 0, nil)
				pExtraEffect:virtual_Destruct(true)
			end,
			[5] = function()
				pExtraEffect.m_flags = EEex_BOr(pExtraEffect, 4)
				-- CGameEffect* effect, int ignoreParty, int useSpecifics, byte specifics, CGameObject* pIgnore
				sprite.m_pArea:ApplyEffect(pExtraEffect, true, false, 0, nil)
				pExtraEffect:virtual_Destruct(true)
			end,
			[6] = function()
				pExtraEffect.m_flags = EEex_BOr(pExtraEffect, 4)
				if sprite:getPortraitIndex() == -1 then
					-- CGameEffect* effect, int ignoreParty, int useSpecifics, byte specifics, CGameObject* pIgnore
					sprite.m_pArea:ApplyEffect(pExtraEffect, false, true, sprite.m_typeAI.m_Specifics, nil)
				else
					sprite:ApplyEffectToParty(pExtraEffect)
				end
				pExtraEffect:virtual_Destruct(true)
			end,
			[7] = function()
				pExtraEffect.m_flags = EEex_BOr(pExtraEffect, 4)
				pExtraEffect:virtual_Destruct(true)
			end,
			[8] = function()
				pExtraEffect.m_flags = EEex_BOr(pExtraEffect, 4)
				-- CGameEffect* effect, int ignoreParty, int useSpecifics, byte specifics, CGameObject* pIgnore
				sprite.m_pArea:ApplyEffect(pExtraEffect, false, false, 0, sprite)
				pExtraEffect:virtual_Destruct(true)
			end,
			[9] = function()
				pExtraEffect.m_flags = EEex_BOr(pExtraEffect, 8)
				sprite.m_curProjectile:AddEffect(pExtraEffect)
			end },
			function()
				sprite.m_curProjectile:AddEffect(pExtraEffect)
			end
		)
	end)
end

-----------
-- Hooks --
-----------

function EEex_Opcode_Hook_AfterListsResolved(sprite)
	for _, func in ipairs(EEex_Opcode_ListsResolvedListeners) do
		func(sprite)
	end
end

------------------------------------------------------------
-- Opcode #248 (Special BIT0 allows .EFF to bypass op120) --
------------------------------------------------------------

function EEex_Opcode_Hook_OnOp248AddTail(op248, effect)
	if EEex_IsBitSet(op248.m_special, 0) then
		EEex_GetUDAux(effect)["EEex_BypassOp120"] = true
	end
end

function EEex_Opcode_Hook_OnAfterSwingCheckedOp248(sprite, targetSprite, bBlocked)
	if bBlocked then
		EEex_Opcode_Private_ApplyExtraMeleeEffects(sprite, targetSprite)
	end
end

------------------------------------------------------------
-- Opcode #249 (Special BIT0 allows .EFF to bypass op120) --
------------------------------------------------------------

function EEex_Opcode_Hook_OnOp249AddTail(op249, effect)
	if EEex_IsBitSet(op249.m_special, 0) then
		EEex_GetUDAux(effect)["EEex_BypassOp120"] = true
	end
end

function EEex_Opcode_Hook_OnAfterSwingCheckedOp249(sprite, targetSprite, bBlocked)

	if bBlocked then

		sprite.m_curProjectile:ClearEffects()
		EEex_Opcode_Private_ApplyExtraRangedEffects(sprite, targetSprite)

		if sprite.m_curAction.m_actionID ~= 98 then
			EEex_RunWithStackManager({
				{ ["name"] = "stringIn", ["struct"] = "CString", ["constructor"] = { ["args"] = { "" } } } },
				function(manager)
					sprite:FeedBack(37, 0, 0, 0, -1, 0, manager:getUD("stringIn"))
				end
			)
		end
	end
end

-----------------------------------------------------------------------
-- Opcode #280                                                       --
--   param1  != 0 => Force wild surge number                         --
--   special != 0 => Suppress wild surge feedback string and visuals --
-----------------------------------------------------------------------

function EEex_Opcode_Hook_OnOp280ApplyEffect(effect, sprite)
	local statsAux = EEex_GetUDAux(sprite.m_derivedStats)
	local t = EEex_Utility_GetOrCreateTable(statsAux, "EEex_Op280")
	t.param1 = effect.m_effectAmount
	t.special = effect.m_special
end

-- Return:
--     0  => Don't override wild surge number
--     !0 => Override wild surge number
function EEex_Opcode_Hook_OverrideWildSurgeNumber(sprite)
	local statsAux = EEex_GetUDAux(sprite:getActiveStats())
	local t = statsAux["EEex_Op280"]
	return t and t.param1 or 0
end

-- Return:
--     false => Don't suppress wild surge feedback string and visuals
--     true  => Suppress wild surge feedback string and visuals
function EEex_Opcode_Hook_SuppressWildSurgeVisuals(sprite)
	local statsAux = EEex_GetUDAux(sprite:getActiveStats())
	local t = statsAux["EEex_Op280"]
	return t and t.special ~= 0 or false
end

--------------------------------------------------------------------------
-- Opcode #326 (Special BIT0 flips SPLPROT.2DA's "source" and "target") --
--------------------------------------------------------------------------

function EEex_Opcode_Hook_ApplySpell_ShouldFlipSplprotSourceAndTarget(effect)
	return EEex_IsBitSet(effect.m_special, 1)
end

--------------------------------------------
-- New Opcode #400 (SetTemporaryAIScript) --
--------------------------------------------

function EEex_Opcode_Hook_SetTemporaryAIScript_ApplyEffect(effect, sprite)
	if effect.m_firstCall == 0 then
		return
	end
	local param2 = effect.m_dWFlags
	if param2 < 0 or param2 > 7 or param2 == 3 then
		-- Engine fails to call OnRemove() if an effect was applied with immediateResolve=1
		-- and it immediately returns from ApplyEffect() with m_done=1
		effect.m_done = 1
		return
	end
	effect.m_firstCall = 0
	local existingScript = sprite:getScriptLevel(param2)
	effect.m_effectAmount2 = EEex_Utility_Ternary(existingScript,
		function() return existingScript:isPlayerScript() end,
		function() return false end)
	effect.m_res2:set(existingScript and existingScript:getResRef() or "")
	sprite:setScriptLevelResRef(param2, effect.m_res:get())
end

function EEex_Opcode_Hook_SetTemporaryAIScript_OnRemove(effect, sprite)
	if effect.m_firstCall == 0 then
		sprite:setScriptLevelResRef(effect.m_dWFlags, effect.m_res2:get(), effect.m_effectAmount2)
	end
end

---------------------------------------
-- New Opcode #401 (SetExtendedStat) --
---------------------------------------

function EEex_Opcode_Hook_ApplySetExtendedStat(effect, sprite)

	local exStats = EEex_GetUDAux(sprite.m_derivedStats)["EEex_ExtendedStats"]

	local param1 = effect.m_effectAmount
	local modType = effect.m_dWFlags
	local exStatID = effect.m_special

	if not EEex_Stats_ExtendedInfo[exStatID] then
		print("[EEex_SetExtendedStat - Opcode #401] Invalid extended stat id: "..exStatID)
		return
	end

	local newVal

	if modType == 0 then -- cumulative
		newVal = exStats[exStatID] + param1
	elseif modType == 1 then -- flat
		newVal = param1
	elseif modType == 2 then -- percentage
		newVal = math.floor(exStats[exStatID] * math.floor(param1 / 100))
	else
		return
	end

	EEex_Stats_Private_SetExtended(exStats, exStatID, newVal)
end

-------------------------------------
-- New Opcode #403 (ScreenEffects) --
-------------------------------------

function EEex_Opcode_Hook_ApplyScreenEffects(effect, sprite)
	local statsAux = EEex_GetUDAux(sprite.m_derivedStats)
	table.insert(statsAux["EEex_ScreenEffects"], effect)
end

-- Return:
--     false => Allow effect (other immunities can still block it)
--     true  => Block effect
function EEex_Opcode_Hook_OnCheckAdd(effect, sprite)

	local foundImmunity = false
	local statsAux = EEex_GetUDAux(sprite:getActiveStats())

	for _, screenEffect in ipairs(statsAux["EEex_ScreenEffects"]) do
		local immunityFunc = _G[screenEffect.m_res:get()]
		if immunityFunc and immunityFunc(screenEffect, effect, sprite) then
			foundImmunity = true
			break
		end
	end

	return foundImmunity
end

-----------------------------------------
-- New Opcode #408 (ProjectileMutator) --
-----------------------------------------

function EEex_Opcode_Hook_ProjectileMutator_ApplyEffect(effect, sprite)
	local statsAux = EEex_GetUDAux(sprite.m_derivedStats)
	table.insert(statsAux["EEex_ProjectileMutatorEffects"], effect)
end

--------------------------------------------
-- New Opcode #409 (EnableActionListener) --
--------------------------------------------

function EEex_Opcode_Hook_EnableActionListener_ApplyEffect(effect, sprite)
	local statsAux = EEex_GetUDAux(sprite.m_derivedStats)
	statsAux["EEex_EnabledActionListeners"][effect.m_res:get()] = effect
end
