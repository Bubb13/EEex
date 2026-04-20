
---------------
-- Listeners --
---------------

EEex_Opcode_ListsResolvedListeners = {}

function EEex_Opcode_AddListsResolvedListener(func)
	-- [EEex.dll]
	EEex.Opcode_LuaHook_AfterListsResolved_Enabled = true
	table.insert(EEex_Opcode_ListsResolvedListeners, func)
end

-----------------------
-- Private Functions --
-----------------------

local EEex_Opcode_Private_Op346ExtendedBonusesAuxKey = "EEex_Opcode_Op346_ExtendedBonuses"
local EEex_Opcode_Private_Op346VanillaSchoolCount = 12
local EEex_Opcode_Private_Op346MaxSchool = 0xFF -- Effect source school fields are 8-bit in the engine data structures.

local function EEex_Opcode_Private_Op346NormalizeInt16(value)
	-- op346 writes 16-bit stats in the engine, so mirror its signed wraparound semantics here.
	value = EEex_BAnd(value, 0xFFFF)
	if value >= 0x8000 then
		value = value - 0x10000
	end
	return value
end

local function EEex_Opcode_Private_Op346GetBonuses(sprite, create)
	-- Extended schools have no native CDerivedStats slots, so cache their resolved bonuses in sprite aux data.
	local auxiliary = create and EEex_GetUDAux(sprite) or EEex_TryGetUDAux(sprite)
	if auxiliary == nil then
		return nil
	end

	local bonuses = auxiliary[EEex_Opcode_Private_Op346ExtendedBonusesAuxKey]
	if bonuses == nil and create then
		bonuses = {}
		auxiliary[EEex_Opcode_Private_Op346ExtendedBonusesAuxKey] = bonuses
	end
	return bonuses
end

function EEex_Opcode_Hook_ClearOp346ExtendedBonuses(sprite)
	-- This cache is derived from active effects, so throw it away whenever stats are rebuilt or the sprite dies.
	local auxiliary = EEex_TryGetUDAux(sprite)
	if auxiliary ~= nil then
		auxiliary[EEex_Opcode_Private_Op346ExtendedBonusesAuxKey] = nil
	end
end

function EEex_Opcode_Hook_OnOp346ApplyEffect(effect, sprite)

	local school = effect.m_special
	if school < EEex_Opcode_Private_Op346VanillaSchoolCount or school > EEex_Opcode_Private_Op346MaxSchool then
		return false
	end

	-- Preserve the engine's add/set behavior, but redirect rows 12..255 into EEex-managed storage.
	local bonuses = EEex_Opcode_Private_Op346GetBonuses(sprite, true)
	local amount = EEex_Opcode_Private_Op346NormalizeInt16(effect.m_effectAmount)
	local modType = effect.m_dWFlags

	if modType == 0 then
		bonuses[school] = EEex_Opcode_Private_Op346NormalizeInt16((bonuses[school] or 0) + amount)
	elseif modType == 1 then
		bonuses[school] = amount
	end

	return true
end

function EEex_Opcode_Hook_GetOp346SaveVsSchoolBonus(effect, sprite)

	local school = effect.m_school
	if school < EEex_Opcode_Private_Op346VanillaSchoolCount or school > EEex_Opcode_Private_Op346MaxSchool then
		return 0
	end

	-- Saving throws read the incoming effect's spell school, so use that as the key into the extended cache.
	local bonuses = EEex_Opcode_Private_Op346GetBonuses(sprite, false)
	if bonuses == nil then
		return 0
	end

	return bonuses[school] or 0
end

function EEex_Opcode_Private_ApplyExtraMeleeEffects(sprite, targetSprite)

	EEex_Utility_IterateCPtrList(sprite:getActiveStats().m_cExtraMeleeEffects, function(effect)

		-- [EEex.dll]
		if not EEex.ShouldEffectBypassOp120(effect) then
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

		-- [EEex.dll]
		if not EEex.ShouldEffectBypassOp120(effect) then
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

function EEex_Opcode_LuaHook_AfterListsResolved(sprite)
	for _, func in ipairs(EEex_Opcode_ListsResolvedListeners) do
		func(sprite)
	end
end

--[[
+--------------------------------------------------------------------------------+
| Opcode #214                                                                    |
+--------------------------------------------------------------------------------+
| param2 == 3 -> Call Lua function in resource field to get CButtonData iterator |
+--------------------------------------------------------------------------------+
| Hook return:                                                                   |
|     false -> Effect not handled                                                |
|     true  -> Effect handled (skip normal code)                                 |
+--------------------------------------------------------------------------------+
--]]

function EEex_Opcode_Hook_OnOp214ApplyEffect(effect, sprite)

	local param2 = effect.m_dWFlags
	if param2 ~= 3 then
		return false
	end

	effect.m_done = true

	local func = _G[effect.m_res:get()]
	if func == nil then
		return false
	end

	sprite:openOp214Interface(func(effect, sprite))
	return true
end

------------------------------------------------------------
-- Opcode #248 (Special BIT0 allows .EFF to bypass op120) --
------------------------------------------------------------

function EEex_Opcode_Hook_OnAfterSwingCheckedOp248(sprite, targetSprite, bBlocked)
	if bBlocked then
		EEex_Opcode_Private_ApplyExtraMeleeEffects(sprite, targetSprite)
	end
end

------------------------------------------------------------
-- Opcode #249 (Special BIT0 allows .EFF to bypass op120) --
------------------------------------------------------------

-- This function replaces the `else` block (hit blocked) of the op120 check for ranged attacks.
--   [Bubb]: Why did I replace the entire else block instead of hooking after its CProjectile::ClearEffects() call?
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

--------------------------------------------------------------
-- Opcode #333 (param3 BIT0 - only check saving throw once) --
--------------------------------------------------------------

function EEex_Opcode_Hook_OnOp333CopiedSelf(effect)
	if EEex_IsBitSet(effect.m_effectAmount2, 0) then
		effect.m_savingThrow = 0
	end
end
