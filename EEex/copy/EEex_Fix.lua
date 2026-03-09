---------------------------------------------------------------
-- Fix TRAPLIMT.2DA's snare cap check in CGameEffectSetSnare --
---------------------------------------------------------------

local EEex_Fix_Private_SetSnareTrapCap = {
	CompareJumpLabel = "Hook-SetSnareTrapCapCompareJmp",
	SupportedEngineSentinelLabel = "Hook-dimmInit()-uiLoadMenu()",
	OriginalCompareJumpOpcode = 0x7E, -- jle
	FixedCompareJumpOpcode = 0x7C, -- jl
}

function EEex_Fix_InstallSetSnareTrapCapFix()

	local private = EEex_Fix_Private_SetSnareTrapCap

	-- This fix is only installed on engine variants that expose the shared snare
	-- compare block and the usual UI loader sentinel.
	local onSupportedEngine = EEex_TryLabel(private.SupportedEngineSentinelLabel)
	local compareJumpAddress = EEex_TryLabel(private.CompareJumpLabel)

	if not compareJumpAddress then
		if onSupportedEngine then
			EEex_Error("EEex_Fix_InstallSetSnareTrapCapFix(): failed to resolve Hook-SetSnareTrapCapCompareJmp")
		end
		return
	end

	-- The real engine bug is an off-by-one in CGameEffectSetSnare::ApplyEffect():
	-- after comparing the current active trap count against TRAPLIMT.2DA's cap, the
	-- engine branches on `jle`, which still allows placement when current == limit.
	-- Rewriting that short jump to `jl` restores the intended `current < limit` behavior.
	local currentOpcode = EEex_Read8(compareJumpAddress)
	if currentOpcode == private.FixedCompareJumpOpcode then
		return
	end

	if currentOpcode ~= private.OriginalCompareJumpOpcode then
		EEex_Error(string.format(
			"EEex_Fix_InstallSetSnareTrapCapFix(): unexpected opcode 0x%02X at Hook-SetSnareTrapCapCompareJmp",
			currentOpcode
		))
	end

	EEex_Write8(compareJumpAddress, private.FixedCompareJumpOpcode)
end

----------------------------------------------------------------------------------------------------------
-- Fix quick spell slots not updating when a special ability is added (for example, by op171 or act279) --
----------------------------------------------------------------------------------------------------------

function EEex_Fix_Hook_OnAddSpecialAbility(sprite, spell)
	EEex_RunWithStackManager({
		{ ["name"] = "abilityId", ["struct"] = "CAbilityId" } },
		function(manager)
			local abilityId = manager:getUD("abilityId")
			abilityId.m_itemType = 1 -- spell, not an item
			abilityId.m_res:copy(spell.cResRef)
			-- CAbilityId* ab, short changeAmount, int remove, int removeSpellIfZero
			sprite:CheckQuickLists(abilityId, 1, 0, 0);
		end)
end

--------------------------------------------------------------------------------------------------------------------------
-- Fix Spell() and SpellPoint() not being disruptable if the creature is facing SSW(1), SWW(3), NWW(5), NNW(7), NNE(9), --
-- NEE(11), SEE(13), or SSE(15)                                                                                         --
--------------------------------------------------------------------------------------------------------------------------

function EEex_Fix_Hook_ShouldForceMainSpellActionCode(sprite, point)

	local forcing = EEex_GetUDAux(sprite)["EEex_Fix_HasSpellOrSpellPointStartedCasting"] == 1

	-- If I force the main spell action code, the direction-setting code
	-- isn't run. Manually do that here so sprites still turn to face
	-- their target after they have started the casting glow.
	if forcing then
		local message = EEex_NewUD("CMessageSetDirection")
		message:Construct(point, sprite.m_id, sprite.m_id)
		EngineGlobals.g_pBaldurChitin.m_cMessageHandler:AddMessage(message, 0)
	end

	return forcing
end

function EEex_Fix_Hook_OnSpellOrSpellPointStartedCastingGlow(sprite)
	EEex_GetUDAux(sprite)["EEex_Fix_HasSpellOrSpellPointStartedCasting"] = 1
end

--------------------------------------------
-- Fix Baldur.lua values not escaping '\' --
--------------------------------------------

EEex_GameState_AddInitializedListener(function()
	local oldNeedsEscape = needsEscape
	needsEscape = function(str)
		return str:find("\\") or oldNeedsEscape(str)
	end
end)
