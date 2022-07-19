
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
