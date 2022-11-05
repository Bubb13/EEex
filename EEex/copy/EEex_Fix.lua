
-- BUG: v2.6.6.0 - op206/318/324 incorrectly indexes source object's items
-- list if the incoming effect's source spell has a name strref of -1
-- without first checking if the source was a sprite.
function EEex_Fix_Hook_SpellImmunityShouldSkipItemIndexing(object)
	return object.m_objectType ~= CGameObjectType.SPRITE
end

-- The engine doesn't update quick lists when a special ability is added,
-- such as from op171 or act279.
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

----------------------------------------------------------------------------------
-- Fix Spell() and SpellPoint() not being disruptable if the creature is facing --
-- SSW(1), SWW(3), NWW(5), NNW(7), NNE(9), NEE(11), SEE(13), or SSE(15)         --
----------------------------------------------------------------------------------

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

function EEex_Fix_Hook_OnSetCurrAction(sprite)
	EEex_GetUDAux(sprite)["EEex_Fix_HasSpellOrSpellPointStartedCasting"] = 0
end
