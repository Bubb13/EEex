
----------------------
-- Static Functions --
----------------------

----------------------
-- Fetching Sprites --
----------------------

-- @bubb_doc { EEex_Sprite_GetSelectedID }
-- @summary:
--
--     Returns the object id associated with the "leader" of the sprites the player currently has selected and is controlling.
--
--     The leader is the party member with the highest portrait slot, (lowest index), or the creature
--     that was selected first.
--
--     If no creatures are currently selected, returns ``-1``.
--
-- @return { type=number }: See summary.

function EEex_Sprite_GetSelectedID()
	local node = EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_group.m_memberList.m_pNodeHead
	if not node then return -1 end
	return node.data
end

-- @bubb_doc { EEex_GameObject_GetSelectedID }
-- @deprecated: Use ``EEex_Sprite_GetSelectedID()`` instead.
-- @mirror { EEex_Sprite_GetSelectedID }

EEex_GameObject_GetSelectedID = EEex_Sprite_GetSelectedID

-- @bubb_doc { EEex_Sprite_GetSelected }
-- @summary:
--
--     Returns the sprite that is the "leader" of the sprites the player currently has selected and is controlling.
--
--     The leader is the party member with the highest portrait slot, (lowest index), or the creature
--     that was selected first.
--
--     If no creatures are currently selected, returns ``nil``.
--
-- @return { type=CGameSprite | nil }: See summary.

function EEex_Sprite_GetSelected()
	return EEex_GameObject_Get(EEex_Sprite_GetSelectedID())
end

-- @bubb_doc { EEex_GameObject_GetSelected }
-- @deprecated: Use ``EEex_Sprite_GetSelected()`` instead.
-- @mirror { EEex_Sprite_GetSelected }

EEex_GameObject_GetSelected = EEex_Sprite_GetSelected

-- @bubb_doc { EEex_Sprite_IterateSelectedIDs }
--
-- @summary:
--
--     Calls ``func`` for every sprite the player currently has selected and is controlling, (passing the sprite's object id).
--     Return ``true`` from ``func`` to stop iteration.
--
-- @param { func / type=function }: The function to call.

function EEex_Sprite_IterateSelectedIDs(func)
	local node = EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_group.m_memberList.m_pNodeHead
	while node do
		if func(node.data) then
			break
		end
		node = node.pNext
	end
end

-- @bubb_doc { EEex_GameObject_IterateSelectedIDs }
-- @deprecated: Use ``EEex_Sprite_IterateSelectedIDs()`` instead.
-- @mirror { EEex_Sprite_IterateSelectedIDs }

EEex_GameObject_IterateSelectedIDs = EEex_Sprite_IterateSelectedIDs

-- @bubb_doc { EEex_Sprite_IterateSelected }
--
-- @summary:
--
--     Calls ``func`` for every sprite the player currently has selected and is controlling, (passing the sprite).
--     Return ``true`` from ``func`` to stop iteration.
--
-- @param { func / type=function }: The function to call.

function EEex_Sprite_IterateSelected(func)
	EEex_Sprite_IterateSelectedIDs(function(spriteID)
		if func(EEex_GameObject_Get(spriteID)) then
			return true
		end
	end)
end

-- @bubb_doc { EEex_GameObject_IterateSelected }
-- @deprecated: Use ``EEex_Sprite_IterateSelected()`` instead.
-- @mirror { EEex_Sprite_IterateSelected }

EEex_GameObject_IterateSelected = EEex_Sprite_IterateSelected

-- @bubb_doc { EEex_Sprite_GetAllSelectedIDs }
--
-- @summary: Returns a table populated with the object ids of all the sprites the player currently has selected and is controlling.
--
-- @return { type=table }: See summary.

function EEex_Sprite_GetAllSelectedIDs()
	local toReturn = {}
	EEex_Sprite_IterateSelectedIDs(function(spriteID)
		table.insert(toReturn, spriteID)
	end)
	return toReturn
end

-- @bubb_doc { EEex_GameObject_GetAllSelectedIDs }
-- @deprecated: Use ``EEex_Sprite_GetAllSelectedIDs()`` instead.
-- @mirror { EEex_Sprite_GetAllSelectedIDs }

EEex_GameObject_GetAllSelectedIDs = EEex_Sprite_GetAllSelectedIDs

-- @bubb_doc { EEex_Sprite_GetNumCharacters }
--
-- @summary: Returns the number of characters currently in the party.
--
-- @return { type=number }: See summary.

function EEex_Sprite_GetNumCharacters()
	return EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_nCharacters
end

-- @bubb_doc { EEex_Sprite_GetInPortrait }
--
-- @summary: Returns the sprite of the party member in the given ``portraitIndex``, or ``nil`` if none exists.
--
-- @param { portraitIndex / type=number }: The portrait index of the sprite to fetch; valid values are [0-5].
--
-- @return { type=CGameSprite | nil }: See summary.

function EEex_Sprite_GetInPortrait(portraitIndex)
	return EEex_GameObject_Get(EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_charactersPortrait:get(portraitIndex))
end

-- @bubb_doc { EEex_Sprite_GetInPortraitID }
--
-- @summary: Returns the object id of the party member in the given ``portraitIndex``, or ``-1`` if none exists.
--
-- @param { portraitIndex / type=number }: The portrait index of the sprite to fetch; valid values are [0-5].
--
-- @return { type=number }: See summary.

function EEex_Sprite_GetInPortraitID(portraitIndex)
	return EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_charactersPortrait:get(portraitIndex)
end

----------------------------
-- / End Static Functions --
----------------------------

------------------------
-- Instance Functions --
------------------------

----------------------
-- Fetching Sprites --
----------------------

-- @bubb_doc { EEex_Sprite_ForAllOfTypeInRange / instance_name=forAllOfTypeInRange }
-- @summary:
--
--     Calls ``func`` for every creature that matches ``aiObjectType`` around
--     ``sprite`` in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { sprite / usertype=CGameSprite }: The sprite to search around.
--
-- @param { aiObjectType / usertype=CAIObjectType }:
--
--     The AI object type used to filter the objects passed to ``func``. @EOL
--     Most commonly retrieved from ``EEex_Object_ParseString()``. Remember to call ``:free()``.
--
-- @param { range / type=number }: The radius to search around ``sprite``. ``448`` is a sprite's default visual range.
--
-- @param { func / type=function }: The function to call for every creature in the search area.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from ``sprite`` to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=sprite:virtual_GetVisibleTerrainTable() }:
--
--     The terrain table to use for determining LOS.

function EEex_Sprite_ForAllOfTypeInRange(sprite, aiObjectType, range, func, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)

	local area = sprite.m_pArea
	if not area then
		return
	end

	local spritePos = sprite.m_pos
	local vertListPos = sprite.m_posVertList

	if sprite.m_listType == VertListType.LIST_FRONT and vertListPos then
		EEex_RunWithStackManager({
			{ ["name"] = "resultPtrList", ["struct"] = "CTypedPtrList<CPtrList,long>" } },
			function(manager)
				local resultPtrList = manager:getUD("resultPtrList")
				area:GetAllInRange2(vertListPos, spritePos, aiObjectType, range,
					terrainTable or sprite:virtual_GetVisibleTerrainTable(),
					resultPtrList, bCheckForLineOfSight or 1, bCheckForNonSprites or 0)
				EEex_Utility_IterateCPtrList(resultPtrList, function(objectID)
					func(EEex_GameObject_Get(objectID))
				end)
			end)
	else
		area:forAllOfTypeInRange(spritePos.x, spritePos.y, aiObjectType, range, func, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	end
end
CGameSprite.forAllOfTypeInRange = EEex_Sprite_ForAllOfTypeInRange

-- @bubb_doc { EEex_Sprite_ForAllOfTypeStringInRange / instance_name=forAllOfTypeStringInRange }
-- @summary:
--
--     Calls ``func`` for every creature that matches ``aiObjectTypeString`` around
--     ``sprite`` in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { sprite / usertype=CGameSprite }: The sprite to search around.
--
-- @param { aiObjectTypeString / type=string }:
--
--     The AI object type string used to filter the objects passed to ``func``. @EOL
--     Automatically parsed by ``EEex_Object_ParseString()``; the resulting object is freed before return.
--
-- @param { range / type=number }: The radius to search around ``sprite``. ``448`` is a sprite's default visual range.
--
-- @param { func / type=function }: The function to call for every creature in the search area.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from ``sprite`` to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=sprite:virtual_GetVisibleTerrainTable() }:
--
--     The terrain table to use for determining LOS.

function EEex_Sprite_ForAllOfTypeStringInRange(sprite, aiObjectTypeString, range, func, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local aiObjectType = EEex_Object_ParseString(aiObjectTypeString)
	sprite:forAllOfTypeInRange(aiObjectType, range, func, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	aiObjectType:free()
end
CGameSprite.forAllOfTypeStringInRange = EEex_Sprite_ForAllOfTypeStringInRange

-- @bubb_doc { EEex_Sprite_GetAllOfTypeInRange / instance_name=getAllOfTypeInRange }
-- @summary:
--
--     Returns a table populated by every creature that matches ``aiObjectType`` around
--     ``sprite`` in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { sprite / usertype=CGameSprite }: The sprite to search around.
--
-- @param { aiObjectType / usertype=CAIObjectType }:
--
--     The AI object type used to filter the objects passed to ``func``. @EOL
--     Most commonly retrieved from ``EEex_Object_ParseString()``. Remember to call ``:free()``.
--
-- @param { range / type=number }: The radius to search around ``sprite``. ``448`` is a sprite's default visual range.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from ``sprite`` to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=sprite:virtual_GetVisibleTerrainTable() }:
--
--     The terrain table to use for determining LOS.
--
-- @return { type=table }: See summary.

function EEex_Sprite_GetAllOfTypeInRange(sprite, aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local toReturn = {}
	local toReturnI = 1
	sprite:forAllOfTypeInRange(aiObjectType, range, function(object)
		toReturn[toReturnI] = object
		toReturnI = toReturnI + 1
	end, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	return toReturn
end
CGameSprite.getAllOfTypeInRange = EEex_Sprite_GetAllOfTypeInRange

-- @bubb_doc { EEex_Sprite_GetAllOfTypeStringInRange / instance_name=getAllOfTypeStringInRange }
-- @summary:
--
--     Returns a table populated by every creature that matches ``aiObjectTypeString`` around
--     ``sprite`` in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { sprite / usertype=CGameSprite }: The sprite to search around.
--
-- @param { aiObjectTypeString / type=string }:
--
--     The AI object type string used to filter the objects added to the return table. @EOL
--     Automatically parsed by ``EEex_Object_ParseString()``; the resulting object is freed before return.
--
-- @param { range / type=number }: The radius to search around ``sprite``. ``448`` is a sprite's default visual range.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from ``sprite`` to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=sprite:virtual_GetVisibleTerrainTable() }:
--
--     The terrain table to use for determining LOS.
--
-- @return { type=table }: See summary.

function EEex_Sprite_GetAllOfTypeStringInRange(sprite, aiObjectTypeString, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local aiObjectType = EEex_Object_ParseString(aiObjectTypeString)
	local toReturn = sprite:getAllOfTypeInRange(aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	aiObjectType:free()
	return toReturn
end
CGameSprite.getAllOfTypeStringInRange = EEex_Sprite_GetAllOfTypeStringInRange

-- @bubb_doc { EEex_Sprite_CountAllOfTypeInRange / instance_name=countAllOfTypeInRange }
-- @summary:
--
--     Returns the number of creatures that match ``aiObjectType`` around
--     ``sprite`` in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { sprite / usertype=CGameSprite }: The sprite to search around.
--
-- @param { aiObjectType / usertype=CAIObjectType }:
--
--     The AI object type used to filter the objects passed to ``func``. @EOL
--     Most commonly retrieved from ``EEex_Object_ParseString()``. Remember to call ``:free()``.
--
-- @param { range / type=number }: The radius to search around ``sprite``. ``448`` is a sprite's default visual range.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from ``sprite`` to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=sprite:virtual_GetVisibleTerrainTable() }:
--
--     The terrain table to use for determining LOS.
--
-- @return { type=number }: See summary.

function EEex_Sprite_CountAllOfTypeInRange(sprite, aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local toReturn = 0
	sprite:forAllOfTypeInRange(aiObjectType, range, function(object)
		toReturn = toReturn + 1
	end, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	return toReturn
end
CGameSprite.countAllOfTypeInRange = EEex_Sprite_CountAllOfTypeInRange

-- @bubb_doc { EEex_Sprite_CountAllOfTypeStringInRange / instance_name=countAllOfTypeStringInRange }
-- @summary:
--
--     Returns the number of creatures that match ``aiObjectTypeString`` around
--     ``sprite`` in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { sprite / usertype=CGameSprite }: The sprite to search around.
--
-- @param { aiObjectTypeString / type=string }:
--
--     The AI object type string used to filter the objects added to the return table. @EOL
--     Automatically parsed by ``EEex_Object_ParseString()``; the resulting object is freed before return.
--
-- @param { range / type=number }: The radius to search around ``sprite``. ``448`` is a sprite's default visual range.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from ``sprite`` to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=sprite:virtual_GetVisibleTerrainTable() }:
--
--     The terrain table to use for determining LOS.
--
-- @return { type=number }: See summary.

function EEex_Sprite_CountAllOfTypeStringInRange(sprite, aiObjectTypeString, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local aiObjectType = EEex_Object_ParseString(aiObjectTypeString)
	local toReturn = sprite:countAllOfTypeInRange(aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	aiObjectType:free()
	return toReturn
end
CGameSprite.countAllOfTypeStringInRange = EEex_Sprite_CountAllOfTypeStringInRange

--------------------
-- Sprite Details --
--------------------

-- @bubb_doc { EEex_Sprite_GetPortraitIndex / instance_name=getPortraitIndex }
--
-- @summary: Returns the given ``sprite``'s portrait index, or ``-1`` if it isn't a party member.
--
-- @self { sprite / type=CGameSprite }: The sprite whose portrait index is being fetched.
--
-- @return { type=number }: See summary.

function EEex_Sprite_GetPortraitIndex(sprite)
	local spriteID = sprite.m_id
	local portraitsArray = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_charactersPortrait
	for i = 0, 5 do
		if portraitsArray:get(i) == spriteID then
			return i
		end
	end
	return -1
end
CGameSprite.getPortraitIndex = EEex_Sprite_GetPortraitIndex

-- @bubb_doc { EEex_Sprite_GetActiveStats / instance_name=getActiveStats }
--
-- @summary:
--
-- Returns the given ``sprite``'s active stats structure. If the creature is in the middle of an effects list process,
-- using this function ensures that the work-in-progress stats structure isn't used.
--
-- @self { sprite / type=CGameSprite }: The sprite whose stats structure is being fetched.
--
-- @return { usertype=CDerivedStats }: See summary.

function EEex_Sprite_GetActiveStats(sprite)
	return sprite.m_bAllowEffectListCall and sprite.m_derivedStats or sprite.m_tempStats
end
CGameSprite.getActiveStats = EEex_Sprite_GetActiveStats

-- @bubb_doc { EEex_Sprite_GetExtendedStat / instance_name=getExtendedStat }
-- @deprecated: Use ``EEex_Sprite_GetStat()`` instead.
-- @summary: Returns the value of the extended stat on the given ``sprite``.
-- @self { sprite / type=CGameSprite }: The sprite whose extended stat value is being fetched.
-- @return { type=number }: See summary.

function EEex_Sprite_GetExtendedStat(sprite, id)
	-- [EEex.dll]
	return EEex.GetExtendedStatValue(sprite, id)
end
CGameSprite.getExtendedStat = EEex_Sprite_GetExtendedStat

function EEex_Sprite_GetName(sprite)
	return sprite.m_sName.m_pchData:get()
end
CGameSprite.getName = EEex_Sprite_GetName

function EEex_Sprite_GetSpellState(sprite, spellStateID)
	return sprite:getActiveStats():GetSpellState(spellStateID) ~= 0
end
CGameSprite.getSpellState = EEex_Sprite_GetSpellState

function EEex_Sprite_GetStat(sprite, statID)
	return sprite:getActiveStats():GetAtOffset(statID)
end
CGameSprite.getStat = EEex_Sprite_GetStat

function EEex_Sprite_GetState(sprite)
	return sprite:getActiveStats().m_generalState
end
CGameSprite.getState = EEex_Sprite_GetState

function EEex_Sprite_GetLocalInt(sprite, variableName)
	return sprite.m_pLocalVariables:getInt(variableName)
end
CGameSprite.getLocalInt = EEex_Sprite_GetLocalInt

function EEex_Sprite_GetLocalString(sprite, variableName)
	return sprite.m_pLocalVariables:getString(variableName)
end
CGameSprite.getLocalString = EEex_Sprite_GetLocalString

function EEex_Sprite_SetLocalInt(sprite, variableName, value)
	sprite.m_pLocalVariables:setInt(variableName, value)
end
CGameSprite.setLocalInt = EEex_Sprite_SetLocalInt

function EEex_Sprite_SetLocalString(sprite, variableName, value)
	sprite.m_pLocalVariables:setString(variableName, value)
end
CGameSprite.setLocalString = EEex_Sprite_SetLocalString

-- Returns the sprite's current modal state, (as defined in MODAL.IDS; stored at offset 0x28 of the global-creature structure).
function EEex_Sprite_GetModalState(sprite)
	if not sprite then return 0 end
	return sprite.m_nModalState
end
CGameSprite.getModalState = EEex_Sprite_GetModalState

-- [0-99], 0 = modal check pending
-- yes, this timer is faster than the others by 1 tick
function EEex_Sprite_GetModalTimer(sprite)
	if not sprite then return 0 end
	local idRemainder = sprite.m_id % 100
	local timerRemainder = sprite.m_PAICallCounterNoMod % 100
	if idRemainder >= timerRemainder then
		return idRemainder - timerRemainder
	else
		return 100 - timerRemainder + idRemainder
	end
end
CGameSprite.getModalTimer = EEex_Sprite_GetModalTimer

-- [0-100], 0 = contingency check pending
function EEex_Sprite_GetContingencyTimer(sprite)
	if not sprite then return 0 end
	return sprite.m_nLastContingencyCheck
end
CGameSprite.getContingencyTimer = EEex_Sprite_GetContingencyTimer

-- [-1-99], -1 = aura free
function EEex_Sprite_GetCastTimer(sprite)
	if not sprite then return 0 end
	return sprite.m_castCounter
end
CGameSprite.getCastTimer = EEex_Sprite_GetCastTimer

-- [0-1]
function EEex_Sprite_GetModalTimerPercentage(sprite)
	if not sprite then return 0 end
	return (99 - sprite:getModalTimer()) / 99
end
CGameSprite.getModalTimerPercentage = EEex_Sprite_GetModalTimerPercentage

-- [0-1]
function EEex_Sprite_GetContingencyTimerPercentage(sprite)
	if not sprite then return 0 end
	return (100 - sprite:getContingencyTimer()) / 100
end
CGameSprite.getContingencyTimerPercentage = EEex_Sprite_GetContingencyTimerPercentage

-- [0-1]
function EEex_Sprite_GetCastTimerPercentage(sprite)
	if not sprite then return 0 end
	return (sprite:getCastTimer() + 1) / 100
end
CGameSprite.getCastTimerPercentage = EEex_Sprite_GetCastTimerPercentage

function EEex_Sprite_GetCasterLevelForSpell(sprite, spellResRef, includeWildMage)
	return EEex_RunWithStackManager({
		{ ["name"] = "resref", ["struct"] = "CResRef", ["constructor"] = { ["args"] = { spellResRef } } },
		{ ["name"] = "spell",  ["struct"] = "CSpell",  ["constructor"] = { ["args"] = function(manager) return manager:getUD("resref") end } } },
		function(manager)
			return sprite:GetCasterLevel(manager:getUD("spell"), includeWildMage and 1 or 0)
		end)
end
CGameSprite.getCasterLevelForSpell = EEex_Sprite_GetCasterLevelForSpell

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef>
function EEex_Sprite_Private_GetKnownSpellsIterator(sprite, minLevel, maxLevel, getKnownSpellFunc)

	minLevel = minLevel - 1
	maxLevel = maxLevel - 1

	local spellLevel = minLevel
	local knownSpellIndex = 0

	return function()

		while spellLevel <= maxLevel do

			while true do

				local knownSpell = getKnownSpellFunc(sprite, spellLevel, knownSpellIndex)

				if knownSpell == nil then
					break
				end

				knownSpellIndex = knownSpellIndex + 1
				return spellLevel, knownSpellIndex, knownSpell.m_knownSpellId:get()
			end

			spellLevel = spellLevel + 1
			knownSpellIndex = 0
		end
	end
end
EEex_Sprite_Private_GetKnownSpellsItr = EEex_Sprite_Private_GetKnownSpellsIterator

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef>
function EEex_Sprite_GetKnownMageSpellsIterator(sprite, minLevel, maxLevel)
	minLevel = minLevel or 1
	maxLevel = maxLevel or 9
	if minLevel < 1 or minLevel > 9 or maxLevel < 1 or maxLevel > 9 then
		EEex_Error("Spell level out-of-bounds (expected [1-9])")
	end
	return EEex_Sprite_Private_GetKnownSpellsItr(sprite, minLevel, maxLevel, CGameSprite.GetKnownSpellMage)
end
EEex_Sprite_GetKnownMageSpellsItr = EEex_Sprite_GetKnownMageSpellsIterator
CGameSprite.getKnownMageSpellsIterator = EEex_Sprite_GetKnownMageSpellsItr
CGameSprite.getKnownMageSpellsItr = EEex_Sprite_GetKnownMageSpellsItr

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef>
function EEex_Sprite_GetKnownPriestSpellsIterator(sprite, minLevel, maxLevel)
	minLevel = minLevel or 1
	maxLevel = maxLevel or 7
	if minLevel < 1 or minLevel > 7 or maxLevel < 1 or maxLevel > 7 then
		EEex_Error("Spell level out-of-bounds (expected [1-7])")
	end
	return EEex_Sprite_Private_GetKnownSpellsItr(sprite, minLevel, maxLevel, CGameSprite.GetKnownSpellPriest)
end
EEex_Sprite_GetKnownPriestSpellsItr = EEex_Sprite_GetKnownPriestSpellsIterator
CGameSprite.getKnownPriestSpellsIterator = EEex_Sprite_GetKnownPriestSpellsItr
CGameSprite.getKnownPriestSpellsItr = EEex_Sprite_GetKnownPriestSpellsItr

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef>
function EEex_Sprite_GetKnownInnateSpellsIterator(sprite)
	return EEex_Sprite_Private_GetKnownSpellsItr(sprite, 1, 1, CGameSprite.GetKnownSpellInnate)
end
EEex_Sprite_GetKnownInnateSpellsItr = EEex_Sprite_GetKnownInnateSpellsIterator
CGameSprite.getKnownInnateSpellsIterator = EEex_Sprite_GetKnownInnateSpellsItr
CGameSprite.getKnownInnateSpellsItr = EEex_Sprite_GetKnownInnateSpellsItr

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef, Spell_Header_st spellHeader>
function EEex_Sprite_Private_GetValidKnownSpellsIterator(knownSpellsIterator)
	return function()
		for spellLevel, knownSpellIndex, spellResRef in knownSpellsIterator do
			local spellHeader = EEex_Resource_Demand(spellResRef, "SPL")
			if spellHeader ~= nil then
				return spellLevel, knownSpellIndex, spellResRef, spellHeader
			end
		end
		return nil
	end
end
EEex_Sprite_Private_GetValidKnownSpellsItr = EEex_Sprite_Private_GetValidKnownSpellsIterator

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef, Spell_Header_st spellHeader>
function EEex_Sprite_GetValidKnownMageSpellsIterator(sprite, minLevel, maxLevel)
	return EEex_Sprite_Private_GetValidKnownSpellsItr(sprite:getKnownMageSpellsIterator(minLevel, maxLevel))
end
EEex_Sprite_GetValidKnownMageSpellsItr = EEex_Sprite_GetValidKnownMageSpellsIterator
CGameSprite.getValidKnownMageSpellsIterator = EEex_Sprite_GetValidKnownMageSpellsItr
CGameSprite.getValidKnownMageSpellsItr = EEex_Sprite_GetValidKnownMageSpellsItr

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef, Spell_Header_st spellHeader>
function EEex_Sprite_GetValidKnownPriestSpellsIterator(sprite, minLevel, maxLevel)
	return EEex_Sprite_Private_GetValidKnownSpellsItr(sprite:getKnownPriestSpellsIterator(minLevel, maxLevel))
end
EEex_Sprite_GetValidKnownPriestSpellsItr = EEex_Sprite_GetValidKnownPriestSpellsIterator
CGameSprite.getValidKnownPriestSpellsIterator = EEex_Sprite_GetValidKnownPriestSpellsItr
CGameSprite.getValidKnownPriestSpellsItr = EEex_Sprite_GetValidKnownPriestSpellsItr

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef, Spell_Header_st spellHeader>
function EEex_Sprite_GetValidKnownInnateSpellsIterator(sprite)
	return EEex_Sprite_Private_GetValidKnownSpellsItr(sprite:getKnownInnateSpellsIterator())
end
EEex_Sprite_GetValidKnownInnateSpellsItr = EEex_Sprite_GetValidKnownInnateSpellsIterator
CGameSprite.getValidKnownInnateSpellsIterator = EEex_Sprite_GetValidKnownInnateSpellsItr
CGameSprite.getValidKnownInnateSpellsItr = EEex_Sprite_GetValidKnownInnateSpellsItr

-- validSpellsIterator is expected to return <string spellResRef, Spell_Header_st spellHeader>
-- Iterator returns <string spellResRef, Spell_Header_st spellHeader, Spell_ability_st spellAbility>
function EEex_Sprite_GetSpellsWithAbilityIterator(sprite, validSpellsIterator)
	return function()
		for spellResRef, spellHeader in validSpellsIterator do
			local spellAbility = spellHeader:getAbilityForLevel(sprite:getCasterLevelForSpell(spellResRef, true))
			if spellAbility ~= nil then
				return spellResRef, spellHeader, spellAbility
			end
		end
	end
end
EEex_Sprite_GetSpellsWithAbilityItr = EEex_Sprite_GetSpellsWithAbilityIterator
CGameSprite.getSpellsWithAbilityIterator = EEex_Sprite_GetSpellsWithAbilityItr
CGameSprite.getSpellsWithAbilityItr = EEex_Sprite_GetSpellsWithAbilityItr

-- spellResRefIterator is expected to return <string spellResRef>
-- Iterator returns <string spellResRef, Spell_Header_st spellHeader, Spell_ability_st spellAbility>
function EEex_Sprite_GetValidSpellsWithAbilityIterator(sprite, spellResRefIterator)
	return sprite:getSpellsWithAbilityIterator(EEex_Resource_GetValidSpellsIterator(spellResRefIterator))
end
EEex_Sprite_GetValidSpellsWithAbilityItr = EEex_Sprite_GetValidSpellsWithAbilityIterator
CGameSprite.getValidSpellsWithAbilityIterator = EEex_Sprite_GetValidSpellsWithAbilityItr
CGameSprite.getValidSpellsWithAbilityItr = EEex_Sprite_GetValidSpellsWithAbilityItr

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef, Spell_Header_st spellHeader, Spell_ability_st spellAbility>
function EEex_Sprite_Private_GetValidKnownSpellsWithAbilityIterator(sprite, validKnownSpellsIterator)
	return function()
		for spellLevel, knownSpellIndex, spellResRef, spellHeader in validKnownSpellsIterator do
			local spellAbility = spellHeader:getAbilityForLevel(sprite:getCasterLevelForSpell(spellResRef, true))
			if spellAbility ~= nil then
				return spellLevel, knownSpellIndex, spellResRef, spellHeader, spellAbility
			end
		end
	end
end
EEex_Sprite_Private_GetValidKnownSpellsWithAbilityItr = EEex_Sprite_Private_GetValidKnownSpellsWithAbilityIterator

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef, Spell_Header_st spellHeader, Spell_ability_st spellAbility>
function EEex_Sprite_GetKnownMageSpellsWithAbilityIterator(sprite, minLevel, maxLevel)
	return EEex_Sprite_Private_GetValidKnownSpellsWithAbilityItr(sprite, sprite:getValidKnownMageSpellsIterator(minLevel, maxLevel))
end
EEex_Sprite_GetKnownMageSpellsWithAbilityItr = EEex_Sprite_GetKnownMageSpellsWithAbilityIterator
CGameSprite.getKnownMageSpellsWithAbilityIterator = EEex_Sprite_GetKnownMageSpellsWithAbilityItr
CGameSprite.getKnownMageSpellsWithAbilityItr = EEex_Sprite_GetKnownMageSpellsWithAbilityItr

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef, Spell_Header_st spellHeader, Spell_ability_st spellAbility>
function EEex_Sprite_GetKnownPriestSpellsWithAbilityIterator(sprite, minLevel, maxLevel)
	return EEex_Sprite_Private_GetValidKnownSpellsWithAbilityItr(sprite, sprite:getValidKnownPriestSpellsIterator(minLevel, maxLevel))
end
EEex_Sprite_GetKnownPriestSpellsWithAbilityItr = EEex_Sprite_GetKnownPriestSpellsWithAbilityIterator
CGameSprite.getKnownPriestSpellsWithAbilityIterator = EEex_Sprite_GetKnownPriestSpellsWithAbilityItr
CGameSprite.getKnownPriestSpellsWithAbilityItr = EEex_Sprite_GetKnownPriestSpellsWithAbilityItr

-- Iterator returns <number spellLevel, number knownSpellIndex, string spellResRef, Spell_Header_st spellHeader, Spell_ability_st spellAbility>
function EEex_Sprite_GetKnownInnateSpellsWithAbilityIterator(sprite)
	return EEex_Sprite_Private_GetValidKnownSpellsWithAbilityItr(sprite, sprite:getValidKnownInnateSpellsIterator())
end
EEex_Sprite_GetKnownInnateSpellsWithAbilityItr = EEex_Sprite_GetKnownInnateSpellsWithAbilityIterator
CGameSprite.getKnownInnateSpellsWithAbilityIterator = EEex_Sprite_GetKnownInnateSpellsWithAbilityItr
CGameSprite.getKnownInnateSpellsWithAbilityItr = EEex_Sprite_GetKnownInnateSpellsWithAbilityItr

-- Iterator returns <CButtonData>
function EEex_Sprite_GetSpellButtonDataIteratorFrom2DA(sprite, resref)

	local array = EEex_Resource_Load2DA(resref)
	EEex_SetUDGCFunc(array, EEex_Resource_Free2DA)

	local _, sizeY = array:getDimensions()
	local y = -1

	return EEex_Utility_ApplyItr(
		function()
			while true do
				::continue::
				y = y + 1
				if y >= sizeY then return nil end
				local spellResRef = array:getAtPoint(0, y)
				local spellHeader = EEex_Resource_Demand(spellResRef, "SPL")
				if spellHeader == nil then goto continue end
				local spellAbility = spellHeader:getAbilityForLevel(sprite:getCasterLevelForSpell(spellResRef, true))
				if spellAbility == nil then goto continue end
				local castType = tonumber(array:getAtPoint(1, y)) or 3
				return spellResRef, spellHeader, spellAbility, castType
			end
		end,
		function(spellResRef, spellHeader, spellAbility, castType)
			local buttonData = EEex_Actionbar_GetSpellButtonData(spellResRef, spellHeader, spellAbility)
			buttonData.m_abilityId.m_itemType = castType
			return buttonData
		end
	)
end
EEex_Sprite_GetSpellButtonDataItrFrom2DA = EEex_Sprite_GetSpellButtonDataIteratorFrom2DA
CGameSprite.getSpellButtonDataIteratorFrom2DA = EEex_Sprite_GetSpellButtonDataItrFrom2DA
CGameSprite.getSpellButtonDataItrFrom2DA = EEex_Sprite_GetSpellButtonDataItrFrom2DA

-------------------------
-- Sprite Manipulation --
-------------------------

-- buttonDataIterator is expected to return <CButtonData>
function EEex_Sprite_OpenOp214Interface(sourceSprite, buttonDataIterator)

	local sprite = EEex_Sprite_GetSelected()
	if not sprite or not EEex_UDEqual(sprite, sourceSprite) then
		return
	end

	local spellList = EEex_NewUD("CGameButtonList")
	spellList:Construct(10) -- CTypedPtrList<CPtrList,CButtonData*>

	for buttonData in buttonDataIterator do
		spellList:AddTail(buttonData)
	end

	local internalButtonList = sprite.m_interalButtonList -- Typo in engine
	if internalButtonList ~= nil then
		internalButtonList:virtual_Destruct(true)
	end

	sprite.m_interalButtonList = spellList
	EEex_Actionbar_SetState(111)
end
CGameSprite.openOp214Interface = EEex_Sprite_OpenOp214Interface

------------------------------
-- / End Instance Functions --
------------------------------

---------------
-- Listeners --
---------------

EEex_Sprite_Private_QuickListsCheckedListeners = {}

function EEex_Sprite_AddQuickListsCheckedListener(listener)
	table.insert(EEex_Sprite_Private_QuickListsCheckedListeners, listener)
end

EEex_Sprite_Private_QuickListCountsResetListeners = {}

function EEex_Sprite_AddQuickListCountsResetListener(listener)
	table.insert(EEex_Sprite_Private_QuickListCountsResetListeners, listener)
end

EEex_Sprite_Private_MarshalHandlers = {}

function EEex_Sprite_AddMarshalHandlers(handlerName, exporter, importer)
	EEex_Sprite_Private_MarshalHandlers[handlerName] = {
		["exporter"] = exporter,
		["importer"] = importer,
	}
end

-----------
-- Hooks --
-----------

function EEex_Sprite_Hook_CheckSuppressTooltip()
	return false
end

function EEex_Sprite_Hook_OnCheckQuickLists(sprite, abilityId, changeAmount)
	local resref = abilityId.m_res:get()
	if changeAmount == 0 or resref == "" then return end
	for _, listener in ipairs(EEex_Sprite_Private_QuickListsCheckedListeners) do
		listener(sprite, resref, changeAmount)
	end
end

function EEex_Sprite_Hook_OnResetQuickListCounts(sprite)
	for _, listener in ipairs(EEex_Sprite_Private_QuickListCountsResetListeners) do
		listener(sprite)
	end
end

-- function EEex_Sprite_Hook_OnConstruct(sprite)
--
-- end

-- function EEex_Sprite_Hook_OnDestruct(sprite)
--
-- end

EEex_Sprite_Private_MarshalHandlerFieldType = {
	["TABLE_END"]   = 0,
	["TABLE_START"] = 1,
	["STRING"]      = 2,
	["INT8"]        = 3,
	["INTU8"]       = 4,
	["INT16"]       = 5,
	["INTU16"]      = 6,
	["INT32"]       = 7,
	["INTU32"]      = 8,
	["INT64"]       = 9,
	["INTU64"]      = 10,
}

EEex_Sprite_Private_CurrentSpriteMarshalHandlerData = {}
EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableSize = 0
EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableToMeta = {}
EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_MemorySize = 0

function EEex_Sprite_Private_DetermineSpriteMarshalHandlerNumberInfo(number)
	if number >= 0 then
		if number <= 0xFF then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INTU8, EEex_Write8, 1
		elseif number <= 0xFFFF then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INTU16, EEex_Write16, 2
		elseif number <= 0xFFFFFFFF then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INTU32, EEex_Write32, 4
		elseif number <= 0xFFFFFFFFFFFFFFFF then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INTU64, EEex_Write64, 8
		else
			EEex_Error("Number too large to be marshalled in creature handler")
		end
	else
		if number >= -0x100 then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INT8, EEex_Write8, 1
		elseif number >= -0x10000 then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INT16, EEex_Write16, 2
		elseif number >= -0x100000000 then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INT32, EEex_Write32, 4
		elseif number >= -0x10000000000000000 then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INT64, EEex_Write64, 8
		else
			EEex_Error("Number too large to be marshalled in creature handler")
		end
	end
end

function EEex_Sprite_Private_CalculateSpriteMarshalHandlerDataSize(t)

	local accumulator = 0
	local lengthTypeSwitch = {
		["string"] = function(v)
			return #v + 1
		end,
		["number"] = function(v)
			local _, _, writeAdvance = EEex_Sprite_Private_DetermineSpriteMarshalHandlerNumberInfo(v)
			return writeAdvance
		end,
	}

	local processStack = {{t, nil}} -- toProcessT, iterK
	local stackTop = 1

	while true do

		::continue::
		local toProcess = processStack[stackTop]
		local toProcessT = toProcess[1]

		while true do

			local k, v = next(toProcessT, toProcess[2])
			if k == nil then
				break
			end
			local kType = type(k)
			if kType ~= "number" and kType ~= "string" then
				EEex_Error("Only numbers / strings can be used as keys in creature marshal")
			end

			toProcess[2] = k

			if stackTop == 1 then
				local handlerName = EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableToMeta[v].handlerName
				-- HANDLER_STRING_LENGTH
				accumulator = accumulator + #handlerName + 1
				stackTop = stackTop + 1
				processStack[stackTop] = {v, nil}
				goto continue
			else
				local vType = type(v)
				if vType ~= "number" and vType ~= "string" and vType ~= "table" then
					EEex_Error("Only numbers / strings / tables can be used as values in creature marshal")
				end
				if vType == "table" then
					-- KEY_FIELD_TYPE + KEY_LENGTH + TABLE_START
					accumulator = accumulator + 1 + lengthTypeSwitch[kType](k) + 1
					stackTop = stackTop + 1
					processStack[stackTop] = {v, nil}
					goto continue
				end
				-- KEY_FIELD_TYPE + KEY_LENGTH + VALUE_FIELD_TYPE + VALUE_LENGTH
				accumulator = accumulator + 1 + lengthTypeSwitch[kType](k) + 1 + lengthTypeSwitch[vType](v)
			end
		end

		accumulator = accumulator + 1 -- TABLE_END

		processStack[stackTop] = nil
		stackTop = stackTop - 1

		if stackTop == 0 then
			break
		end
	end

	return accumulator
end

function EEex_Sprite_Private_WriteSpriteMarshalHandlerData(memoryPtr, t)

	local writeNumber = function(number)
		local typeByte, writeFunc, writeAdvance = EEex_Sprite_Private_DetermineSpriteMarshalHandlerNumberInfo(number)
		EEex_Write8(memoryPtr, typeByte)
		memoryPtr = memoryPtr + 1
		writeFunc(memoryPtr, number)
		memoryPtr = memoryPtr + writeAdvance
	end

	local writeTypeSwitch = {
		["string"] = function(v)
			EEex_Write8(memoryPtr, EEex_Sprite_Private_MarshalHandlerFieldType.STRING)
			memoryPtr = memoryPtr + 1
			EEex_WriteString(memoryPtr, v)
			memoryPtr = memoryPtr + #v + 1
		end,
		["number"] = writeNumber,
		["table"] = function(v)
			EEex_Write8(memoryPtr, EEex_Sprite_Private_MarshalHandlerFieldType.TABLE_START)
			memoryPtr = memoryPtr + 1
		end
	}

	local processStack = {{t, nil}} -- toProcessT, iterK
	local stackTop = 1

	while true do

		::continue::
		local toProcess = processStack[stackTop]
		local toProcessT = toProcess[1]

		while true do

			local k, v = next(toProcessT, toProcess[2])
			if k == nil then
				break
			end

			toProcess[2] = k

			if stackTop == 1 then
				local handlerName = EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableToMeta[v].handlerName
				EEex_WriteString(memoryPtr, handlerName)
				memoryPtr = memoryPtr + #handlerName + 1
			else
				writeTypeSwitch[type(k)](k)
				writeTypeSwitch[type(v)](v)
			end

			if type(v) == "table" then
				stackTop = stackTop + 1
				processStack[stackTop] = {v, nil}
				goto continue
			end
		end

		EEex_Write8(memoryPtr, EEex_Sprite_Private_MarshalHandlerFieldType.TABLE_END)
		memoryPtr = memoryPtr + 1

		processStack[stackTop] = nil
		stackTop = stackTop - 1

		if stackTop == 0 then
			break
		end
	end
end

function EEex_Sprite_Hook_CalculateExtraEffectListMarshalSize(sprite)

	if EEex_Debug_DisableExtraCreatureMarshalling then
		return 0
	end

	local addTableExport = function(handlerName, toExport)
		if type(toExport) ~= "table" then
			EEex_Error("Creature marshal handler must export table")
		end
		EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableSize = EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableSize + 1
		EEex_Sprite_Private_CurrentSpriteMarshalHandlerData[EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableSize] = toExport
		EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableToMeta[toExport] = {
			["handlerName"] = handlerName,
		}
	end

	for handlerName, handler in pairs(EEex_Sprite_Private_MarshalHandlers) do
		addTableExport(handlerName, handler.exporter(sprite))
	end

	-- Marshal data that was stored in the fallback table because it was missing its handler
	for handlerName, toExport in pairs(EEex_GetUDAux(sprite)["EEex_Sprite_FallbackMarshalStorage"] or {}) do
		addTableExport(handlerName, toExport)
	end

	local extraMarshalSize = 8 + EEex_Sprite_Private_CalculateSpriteMarshalHandlerDataSize(EEex_Sprite_Private_CurrentSpriteMarshalHandlerData)
	EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_MemorySize = (extraMarshalSize ~= 8 and
		EEex_RoundUp(extraMarshalSize, CGameEffectBase.sizeof)
		or 0) - 8
	return EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_MemorySize + 8
end

function EEex_Sprite_Hook_WriteExtraEffectListMarshal(memory)

	if EEex_Debug_DisableExtraCreatureMarshalling then
		return
	end

	if EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_MemorySize > 0 then
		EEex_WriteLString(memory, "X-BIV1.0", 8)
		local marshalPtr = memory + 8
		EEex_Memset(marshalPtr, 0, EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_MemorySize)
		EEex_Sprite_Private_WriteSpriteMarshalHandlerData(marshalPtr, EEex_Sprite_Private_CurrentSpriteMarshalHandlerData)
	end
	EEex_Sprite_Private_CurrentSpriteMarshalHandlerData = {}
	EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableSize = 0
	EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableToMeta = {}
	EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_MemorySize = 0
end

function EEex_Sprite_Hook_ReadExtraEffectListUnmarshal(sprite, memory)

	memory = memory + 8

	while true do

		local toFill = {}
		local handlerStr = EEex_ReadString(memory)

		-- The top level list writes TABLE_END('\0') to signal that all
		-- marshalled data has ended, which reads as an empty string
		if handlerStr == "" then
			break
		end

		memory = memory + #handlerStr + 1

		local fieldReadSwitch = {
			[EEex_Sprite_Private_MarshalHandlerFieldType.STRING] = function()
				local read = EEex_ReadString(memory)
				memory = memory + #read + 1
				return read
			end,
			[EEex_Sprite_Private_MarshalHandlerFieldType.INT8] = function()
				local read = EEex_Read8(memory)
				memory = memory + 1
				return read
			end,
			[EEex_Sprite_Private_MarshalHandlerFieldType.INTU8] = function()
				local read = EEex_ReadU8(memory)
				memory = memory + 1
				return read
			end,
			[EEex_Sprite_Private_MarshalHandlerFieldType.INT16] = function()
				local read = EEex_Read16(memory)
				memory = memory + 2
				return read
			end,
			[EEex_Sprite_Private_MarshalHandlerFieldType.INTU16] = function()
				local read = EEex_ReadU16(memory)
				memory = memory + 2
				return read
			end,
			[EEex_Sprite_Private_MarshalHandlerFieldType.INT32] = function()
				local read = EEex_Read32(memory)
				memory = memory + 4
				return read
			end,
			[EEex_Sprite_Private_MarshalHandlerFieldType.INTU32] = function()
				local read = EEex_ReadU32(memory)
				memory = memory + 4
				return read
			end,
			[EEex_Sprite_Private_MarshalHandlerFieldType.INT64] = function()
				local read = EEex_Read64(memory)
				memory = memory + 8
				return read
			end,
			[EEex_Sprite_Private_MarshalHandlerFieldType.INTU64] = function()
				local read = EEex_ReadU64(memory)
				memory = memory + 8
				return read
			end,
		}

		local tableStack = {}
		local tableStackTop = 0

		while true do

			local keyFieldType = EEex_Read8(memory)
			memory = memory + 1

			if keyFieldType == EEex_Sprite_Private_MarshalHandlerFieldType.TABLE_END then
				if tableStackTop == 0 then
					break
				end
				toFill = tableStack[tableStackTop]
				tableStackTop = tableStackTop - 1
			else
				local key = fieldReadSwitch[keyFieldType]()
				local valueFieldType = EEex_Read8(memory)
				memory = memory + 1
				if valueFieldType == EEex_Sprite_Private_MarshalHandlerFieldType.TABLE_START then
					local subTable = {}
					toFill[key] = subTable
					tableStackTop = tableStackTop + 1
					tableStack[tableStackTop] = toFill
					toFill = subTable
				else
					toFill[key] = fieldReadSwitch[valueFieldType]()
				end
			end
		end

		local handlers = EEex_Sprite_Private_MarshalHandlers[handlerStr]
		if handlers then
			handlers.importer(sprite, toFill)
		else
			-- If the required marshal handler is missing, keep the data around so that it isn't stripped from the savegame
			local fallbackStorage = EEex_Utility_GetOrCreateTable(EEex_GetUDAux(sprite), "EEex_Sprite_FallbackMarshalStorage")
			fallbackStorage[handlerStr] = toFill
		end
	end
end

EEex_Sprite_Private_CustomConcentrationCheckFuncName = nil

function EEex_Sprite_Hook_OnLoadConcentrationCheckMode(checkMode)
	local prefix = "EEex-LuaFunction="
	local prefixLen = #prefix
	if checkMode:sub(1, prefixLen) == prefix then
		EEex_Sprite_Private_CustomConcentrationCheckFuncName = checkMode:sub(prefixLen + 1)
		EEex_Write8(EEex_Sprite_Private_RunCustomConcentrationCheckMem, 1)
	end
end

function EEex_Sprite_Hook_OnCheckConcentration(sprite)

	local spriteAux = EEex_GetUDAux(sprite)
	local bSpellDisrupted = false

	for _, damageData in ipairs(spriteAux["EEex_Sprite_DamageEntriesSinceActionStarted"] or {}) do
		bSpellDisrupted = _G[EEex_Sprite_Private_CustomConcentrationCheckFuncName](sprite, damageData)
		if bSpellDisrupted then
			break
		end
	end

	spriteAux["EEex_Sprite_DamageEntriesSinceActionStarted"] = {}
	return bSpellDisrupted
end

EEex_Sprite_Private_SavedDamageEffectTargetStartingHP = nil

function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	local actionID = targetSprite.m_curAction.m_actionID
	if actionID == 31 or actionID == 95 then -- Spell() or SpellPoint()
		EEex_Sprite_Private_SavedDamageEffectTargetStartingHP = targetSprite.m_baseStats.m_hitPoints
	end
end

function EEex_Sprite_Hook_OnDamageEffectDone(effect, sourceSprite, targetSprite)

	local actionID = targetSprite.m_curAction.m_actionID
	if actionID == 31 or actionID == 95 then -- Spell() or SpellPoint()

		local damageTaken = EEex_Sprite_Private_SavedDamageEffectTargetStartingHP - targetSprite.m_baseStats.m_hitPoints
		if damageTaken > 0 then

			local effectCopy = effect:virtual_Copy()
			EEex_SetUDGCFunc(effectCopy, function(effect)
				effect:virtual_Destruct(true)
			end)

			table.insert(EEex_Utility_GetOrCreateTable(EEex_GetUDAux(targetSprite), "EEex_Sprite_DamageEntriesSinceActionStarted"), {
				["damageTaken"] = damageTaken,
				["effect"] = effectCopy,
				["sourceSprite"] = sourceSprite,
				["targetSprite"] = targetSprite,
			})
		end
	end
end

function EEex_Sprite_Hook_OnSetCurrAction(sprite)
	local spriteAux = EEex_GetUDAux(sprite)
	spriteAux["EEex_Fix_HasSpellOrSpellPointStartedCasting"] = 0
	spriteAux["EEex_Sprite_DamageEntriesSinceActionStarted"] = {}
end

--------------------------------------------------------------------------------------------
-- Allow ITM header flag BIT18 to ignore weapon styles (as if the item were in SLOT_FIST) --
--------------------------------------------------------------------------------------------

function EEex_Sprite_Hook_GetProfBonuses_IgnoreWeaponStyles(item, damR, damL, thacR, thacL, ACB, ACM, speed, crit)

	local ignore = EEex_IsBitSet(item.pRes.pHeader.itemFlags, 18)

	if ignore then

		-- Uncomment these lines to use the 2DA's default value
		--local weaponStyleBonuses = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_ruleTables.m_tWeaponStyleBonus
		--local default = tonumber(weaponStyleBonuses.m_default.m_pchData:get(), 10) or 0

		local default = 0

		local writeDefault = function(ptr)
			if ptr ~= 0x0 then
				EEex_Write32(ptr, default)
			end
		end

		writeDefault(damR)
		writeDefault(damL)
		writeDefault(thacR)
		writeDefault(thacL)
		writeDefault(ACB)
		writeDefault(ACM)
		writeDefault(speed)
		writeDefault(crit)

		return true
	end

	return false
end

---------------------------------------------------------------------------------------
-- Ignore the -8 thac0 penalty a character incurs when meleeing with a ranged weapon --
---------------------------------------------------------------------------------------

function EEex_Sprite_Hook_IgnoresCloseRangedPenalityWithItemCat(sprite, pItem)
	if pItem == nil then return false end
	--
	local pRes = pItem.pRes
	if pRes == nil then return false end
	--
	local pHeader = pRes.pHeader
	if pHeader == nil then return false end
	--
	local m_baseStats = sprite.m_baseStats
	local kitIDS = EEex_BOr(EEex_LShift(m_baseStats.m_mageSpecUpperWord, 16), m_baseStats.m_mageSpecialization)
	--
	if EEex_Sprite_Private_KitIgnoresCloseRangedPenalityForItemCategory[kitIDSToSymbol[kitIDS]][itemcatIDSToSymbol[pHeader.itemType]] == nil then return false end
	if EEex_Sprite_Private_KitIgnoresCloseRangedPenalityForItemCategory[kitIDSToSymbol[kitIDS]][itemcatIDSToSymbol[pHeader.itemType]] then
		return true
	else
		return false
	end
end
CGameSprite.ignoresCloseRangedPenalityWithItemCat = EEex_Sprite_Hook_IgnoresCloseRangedPenalityWithItemCat
