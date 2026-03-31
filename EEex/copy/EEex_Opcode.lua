
---------------
-- Listeners --
---------------

EEex_Opcode_ListsResolvedListeners = {}

-- Mode-3 stat bonuses for op6/op10/op15/op19/op44/op49 ultimately flow through
-- CRuleTables::GetSpellAbilityValue(), which indexes CLSSPLAB by numeric row /
-- column rather than by symbolic labels. Keep the full schema contract here so
-- Lua and the patch layer both talk about the same layout.
EEex_Opcode_ClassSpellAbilityTable = {
	["columns"] = {
		-- Slot 0 must exist because the native STR / DEX helpers reference columns
		-- 1 and 6 respectively. The name is not semantically important; the index is.
		"RESERVED",
		"STR",
		-- Slot 2 is likewise structural padding. We opted for the STREX name so the
		-- shipped table still looks familiar to modders.
		"STREX",
		"CON",
		"INT",
		"WIS",
		"DEX",
		"CHR",
	},
	["columnIndices"] = {
		-- These are zero-based indexes as consumed by CRuleTables::GetSpellAbilityValue().
		-- They are intentionally sparse because columns 0 and 2 are reserved by layout.
		["STR"] = 1,
		["CON"] = 3,
		["INT"] = 4,
		["WIS"] = 5,
		["DEX"] = 6,
		["CHR"] = 7,
	},
	["rows"] = {
		-- Row order also matters. The engine derives a class byte, then uses that byte
		-- as a direct row index into CLSSPLAB.
		"UNUSED",
		"MAGE",
		"FIGHTER",
		"CLERIC",
		"THIEF",
		"BARD",
		"PALADIN",
		"FIGHTER_MAGE",
		"FIGHTER_CLERIC",
		"FIGHTER_THIEF",
		"FIGHTER_MAGE_THIEF",
		"DRUID",
		"RANGER",
		"MAGE_THIEF",
		"CLERIC_MAGE",
		"CLERIC_THIEF",
		"FIGHTER_DRUID",
		"FIGHTER_MAGE_CLERIC",
		"CLERIC_RANGER",
		"SORCERER",
		"MONK",
		"SHAMAN",
	},
}

function EEex_Opcode_Private_ValidateClassSpellAbilityTable()

	local array = EEex_Resource_Load2DA("CLSSPLAB")
	if not array then
		EEex_Error("[EEex_Opcode] Missing CLSSPLAB.2DA; install the EEex copy before using mode-3 class spell bonuses.")
	end

	-- Fail fast on schema drift. If another override reorders columns, the engine
	-- would silently read the wrong stat budgets unless we stop here.
	for index, expectedLabel in ipairs(EEex_Opcode_ClassSpellAbilityTable["columns"]) do
		local actualIndex = array:findColumnLabel(expectedLabel)
		local wantedIndex = index - 1
		if actualIndex ~= wantedIndex then
			EEex_Error(string.format(
				"[EEex_Opcode] CLSSPLAB.2DA column '%s' must be at zero-based index %d, found %d.",
				expectedLabel, wantedIndex, actualIndex
			))
		end
	end

	-- Row labels are validated for the same reason: native code passes a numeric class
	-- id, not a row label, so row order must stay synchronized with the executable.
	for index, expectedLabel in ipairs(EEex_Opcode_ClassSpellAbilityTable["rows"]) do
		local actualLabel = array:getRowLabel(index - 1)
		if actualLabel ~= expectedLabel then
			EEex_Error(string.format(
				"[EEex_Opcode] CLSSPLAB.2DA row %d must be '%s', found '%s'.",
				index - 1, expectedLabel, actualLabel
			))
		end
	end
end

EEex_GameState_AddInitializedListener(function()
	-- Run once the game is initialized enough for resource loading to be reliable.
	EEex_Opcode_Private_ValidateClassSpellAbilityTable()
end)

function EEex_Opcode_AddListsResolvedListener(func)
	-- [EEex.dll]
	EEex.Opcode_LuaHook_AfterListsResolved_Enabled = true
	table.insert(EEex_Opcode_ListsResolvedListeners, func)
end

-----------------------
-- Private Functions --
-----------------------

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
