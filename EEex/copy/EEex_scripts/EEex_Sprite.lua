
----------------------
-- Static Functions --
----------------------

EEex_Sprite_LoadedListeners = {}

function EEex_Sprite_AddLoadedListener(func)
	table.insert(EEex_Sprite_LoadedListeners, func)
end

----------------------
-- Creating Sprites --
----------------------

function EEex_Sprite_CreateFromResref(resref, args)

	local res = EEex_Resource_Fetch(resref, "CRE")
	if not res then return end

	local demanded = res:Demand()
	if not demanded then return end

	if args == nil then args = {} end
	local type             = args["type"]             or 0
	local expirationTime   = args["expirationTime"]   or 0xFFFFFFFF
	local huntingRange     = args["huntingRange"]     or 0
	local followRange      = args["followRange"]      or 0
	local timeOfDayVisible = args["timeOfDayVisible"] or 0x7FFFFFFF
	local startPosX        = args["startPosX"]        or -1
	local startPosY        = args["startPosY"]        or -1
	local facing           = args["facing"]           or 0
	local copyScript       = args["copyScript"]       or 1

	return EEex_RunWithStackManager({
		{ ["name"] = "startPos", ["struct"] = "CPoint", ["constructor"] = {["variant"] = "fromXY", ["args"] = {startPosX, startPosY}} }, },
		function(manager)
			local newSprite = EEex_NewUD("CGameSprite")
			newSprite:Construct_Overload_FromData(demanded, res.nSize, type, expirationTime, huntingRange,
				followRange, timeOfDayVisible, manager:getUD("startPos"), facing, copyScript)
			return newSprite
		end)
end

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

EEex_Sprite_Private_LoadedWithUUIDCallbacks = {}
EEex_Sprite_Private_LoadedWithUUIDCallbacksBySource = {}

function EEex_Sprite_LoadedWithUUIDCallback(sourceSprite, uuid, func)

	local sourceUUID = sourceSprite:getUUID()

	-- Keep track of callbacks via EEex_Sprite_Private_LoadedWithUUIDCallbacks[<target uuid>][<source uuid>] = { <callbacks...> }
	local callbacks = EEex_Utility_GetOrCreateTable(EEex_Sprite_Private_LoadedWithUUIDCallbacks, uuid)
	table.insert(EEex_Utility_GetOrCreateTable(callbacks, sourceUUID), func)

	-- Reverse mapping via EEex_Sprite_Private_LoadedWithUUIDCallbacksBySource[<source uuid>] = { EEex_Sprite_Private_LoadedWithUUIDCallbacks[<target uuid...>] = true }
	EEex_Utility_GetOrCreateTable(EEex_Sprite_Private_LoadedWithUUIDCallbacksBySource, sourceUUID)[callbacks] = true

	local loadedSprite = EEex_Sprite_GetFromUUID(uuid)
	if loadedSprite then
		func(sourceSprite, loadedSprite)
	end
end
CGameSprite.loadedWithUUIDCallback = EEex_Sprite_LoadedWithUUIDCallback

function EEex_Sprite_GetUUID(sprite)
	return sprite:getUUID()
end

----------------------
-- Creating Sprites --
----------------------

function EEex_Sprite_CreateCopy(sprite, args)

	if args == nil then args = {} end
	local markItemsAsNonDroppable = args["markItemsAsNonDroppable"] or 0
	local copyNonDroppable        = args["copyNonDroppable"]        or 1
	local copyEffects             = args["copyEffects"]             or 1
	local copyScripts             = args["copyScripts"]             or 1

	return sprite:Copy(markItemsAsNonDroppable, copyNonDroppable, copyEffects, copyScripts)
end
CGameSprite.createCopy = EEex_Sprite_CreateCopy

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

function EEex_Sprite_GetFromUUID(uuid)
	return EEex.GetSpriteFromUUID(uuid)
end

--------------------
-- Sprite Details --
--------------------

-- @bubb_doc { EEex_Sprite_IsPartyMember / instance_name=isPartyMember }
--
-- @summary: Returns whether the given ``sprite`` is a party member.
--
-- @self { sprite / type=CGameSprite }: The sprite whose party membership is being checked.
--
-- @return { type=boolean }: See summary.

function EEex_Sprite_IsPartyMember(sprite)
	for i = 0, 5 do
		local partyMember = EEex_Sprite_GetInPortrait(i) -- CGameSprite
		if partyMember then -- sanity check
			if partyMember.m_id == sprite.m_id then
				return true
			end
		end
	end
	return false
end
CGameSprite.isPartyMember = EEex_Sprite_IsPartyMember

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

function EEex_Sprite_GetCharacterIndex(sprite)
	local spriteID = sprite.m_id
	local charactersArray = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_characters
	for i = 0, 5 do
		if charactersArray:get(i) == spriteID then
			return i
		end
	end
	return -1
end
CGameSprite.getCharacterIndex = EEex_Sprite_GetCharacterIndex

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
	return sprite.m_bAllowEffectListCall ~= 0 and sprite.m_derivedStats or sprite.m_tempStats
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

function EEex_Sprite_GetNameRef(sprite)
	local nameRef = sprite.m_baseStats.m_name
	if nameRef ~= 0xFFFFFFFF then return nameRef end
	local characterIndex = EEex_Sprite_GetCharacterIndex(sprite)
	if characterIndex <= -1 then characterIndex = 0 end
	return -characterIndex - 2
end
CGameSprite.getNameRef = EEex_Sprite_GetNameRef

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

function EEex_Sprite_GetPersonalSpace(sprite)
	local animation = sprite.m_animation
	return EEex_BAnd(animation.m_overrides, 4) == 0
		and animation.m_animation:virtual_GetPersonalSpace()
		or animation.m_personalSpace
end
CGameSprite.getPersonalSpace = EEex_Sprite_GetPersonalSpace

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

function EEex_Sprite_Private_NormalizeSpellResref(spellResRef)
	if spellResRef == nil then
		EEex_Error("spellResRef required")
	end
	if spellResRef:find(".", 1, true) ~= nil then
		EEex_Error("spellResRef must not include an extension")
	end
	-- Normalize once so later comparisons can stay exact and case-sensitive.
	spellResRef = spellResRef:upper()
	if #spellResRef < 1 or #spellResRef > 8 then
		EEex_Error("spellResRef length out-of-bounds (expected [1-8])")
	end
	return spellResRef
end

function EEex_Sprite_Private_NormalizeSpellType(spellType)
	if spellType == 0 or spellType == 1 or spellType == 2 then
		return spellType
	end

	if type(spellType) == "string" then
		return ({
			["PRIEST"] = 0,
			["WIZARD"] = 1,
			["INNATE"] = 2,
		})[spellType:upper()] or EEex_Error(string.format("Unknown spell type: %s", tostring(spellType)))
	end

	EEex_Error(string.format("Unknown spell type: %s", tostring(spellType)))
end

function EEex_Sprite_Private_GetSpellbookInfo(sprite, spellType)
	-- Each spellbook is tracked as parallel known / memorized-level / memorized-entry tables.
	-- Innate spells do not mirror a derived memorization table, unlike priest and mage books.
	local info = ({
		[0] = {
			spellType = 0,
			maxLevels = 7,
			knownLists = sprite.m_knownSpellsPriest,
			memorizedLevels = sprite.m_memorizedSpellsLevelPriest,
			memorizedLists = sprite.m_memorizedSpellsPriest,
			derivedLevels = sprite.m_derivedStats.m_memorizedSpellsLevelPriest,
		},
		[1] = {
			spellType = 1,
			maxLevels = 9,
			knownLists = sprite.m_knownSpellsMage,
			memorizedLevels = sprite.m_memorizedSpellsLevelMage,
			memorizedLists = sprite.m_memorizedSpellsMage,
			derivedLevels = sprite.m_derivedStats.m_memorizedSpellsLevelMage,
		},
		[2] = {
			spellType = 2,
			maxLevels = 1,
			knownLists = sprite.m_knownSpellsInnate,
			memorizedLevels = sprite.m_memorizedSpellsLevelInnate,
			memorizedLists = sprite.m_memorizedSpellsInnate,
			derivedLevels = nil,
		},
	})[spellType]

	if info == nil then
		EEex_Error(string.format("Unsupported spell type: %s", tostring(spellType)))
	end
	return info
end

function EEex_Sprite_Private_NormalizeSpellLevel(spellLevel, maxLevels)
	if type(spellLevel) ~= "number" then
		EEex_Error("spellLevel must be a number")
	end
	spellLevel = math.floor(spellLevel)
	if spellLevel < 0 or spellLevel >= maxLevels then
		EEex_Error(string.format("Spell level out-of-bounds (expected [0-%d])", maxLevels - 1))
	end
	return spellLevel
end

function EEex_Sprite_Private_NormalizeSpellCount(spellCount)
	if spellCount == nil then
		return 1
	end
	if type(spellCount) ~= "number" then
		EEex_Error("spellCount must be a number")
	end
	return math.floor(spellCount)
end

function EEex_Sprite_Private_NormalizeMemorizedState(memorized)
	if memorized == nil then
		return true
	end
	if type(memorized) ~= "boolean" then
		EEex_Error("memorized must be a boolean")
	end
	return memorized
end

function EEex_Sprite_Private_ResetMemorizedSpellLevel(memorizedSpellLevel, spellLevel, spellType)
	memorizedSpellLevel.m_spellLevel = spellLevel
	memorizedSpellLevel.m_baseCount = 0
	memorizedSpellLevel.m_count = 0
	memorizedSpellLevel.m_magicType = spellType
	memorizedSpellLevel.m_memorizedStartingSpell = 0
	memorizedSpellLevel.m_memorizedCount = 0
end

function EEex_Sprite_Private_IsSpontaneousCaster(sprite, spellType)
	local class = EEex_GameObject_GetClass(sprite)
	return (spellType == 1 and class == 19) or (spellType == 0 and class == 21)
end

function EEex_Sprite_Private_CountMatchingMemorizedSpells(memorizedSpellList, spellResRef)
	local matchingCount = 0
	local node = memorizedSpellList.m_pNodeHead
	while node do
		local memorizedSpell = node.data
		if memorizedSpell.m_spellId:get():upper() == spellResRef then
			matchingCount = matchingCount + 1
		end
		node = node.pNext
	end
	return matchingCount
end

function EEex_Sprite_Private_GetSpontaneousSpellCopyLimit(sprite, spellbookInfo, spellLevel)
	if not EEex_Sprite_Private_IsSpontaneousCaster(sprite, spellbookInfo.spellType) then
		return nil
	end

	-- Sorcerer-style books cap duplicate memorized entries to the slot count tracked for that level.
	local maxCopies = 0
	local memorizedSpellLevel = spellbookInfo.memorizedLevels:get(spellLevel)
	if memorizedSpellLevel ~= nil then
		maxCopies = math.max(maxCopies, memorizedSpellLevel.m_baseCount, memorizedSpellLevel.m_count)
	end

	local derivedLevels = spellbookInfo.derivedLevels
	if derivedLevels ~= nil then
		local derivedMemorizedSpellLevel = derivedLevels:getReference(spellLevel)
		maxCopies = math.max(maxCopies, derivedMemorizedSpellLevel.m_baseCount, derivedMemorizedSpellLevel.m_count)
	end

	return maxCopies
end

function EEex_Sprite_Private_EnsureMemorizedSpellLevel(spellbookInfo, spellLevel)
	local memorizedSpellLevel = spellbookInfo.memorizedLevels:get(spellLevel)
	if memorizedSpellLevel == nil then
		-- These level records are allocated lazily; sparse spellbooks are valid.
		memorizedSpellLevel = EEex_PtrToUD(EEex_Malloc(CCreatureFileMemorizedSpellLevel.sizeof), "CCreatureFileMemorizedSpellLevel")
		EEex_Memset(EEex_UDToPtr(memorizedSpellLevel), 0, CCreatureFileMemorizedSpellLevel.sizeof)
		EEex_Sprite_Private_ResetMemorizedSpellLevel(memorizedSpellLevel, spellLevel, spellbookInfo.spellType)
		spellbookInfo.memorizedLevels:set(spellLevel, memorizedSpellLevel)
	end
	return memorizedSpellLevel
end

function EEex_Sprite_Private_SyncDerivedMemorizedSpellLevel(spellbookInfo, spellLevel, memorizedSpellLevel)
	local derivedLevels = spellbookInfo.derivedLevels
	if derivedLevels == nil then
		return
	end

	local derivedMemorizedSpellLevel = derivedLevels:getReference(spellLevel)
	if memorizedSpellLevel == nil then
		-- Clearing the base level must also clear the derived mirror the engine reads from.
		EEex_Sprite_Private_ResetMemorizedSpellLevel(derivedMemorizedSpellLevel, spellLevel, spellbookInfo.spellType)
		return
	end

	-- Keep the derived bookkeeping in sync with the base spellbook arrays.
	derivedMemorizedSpellLevel.m_spellLevel = memorizedSpellLevel.m_spellLevel
	derivedMemorizedSpellLevel.m_baseCount = memorizedSpellLevel.m_baseCount
	derivedMemorizedSpellLevel.m_count = memorizedSpellLevel.m_count
	derivedMemorizedSpellLevel.m_magicType = memorizedSpellLevel.m_magicType
	derivedMemorizedSpellLevel.m_memorizedStartingSpell = memorizedSpellLevel.m_memorizedStartingSpell
	derivedMemorizedSpellLevel.m_memorizedCount = memorizedSpellLevel.m_memorizedCount
end

function EEex_Sprite_Private_SyncMemorizedSpellInfo(spellbookInfo)
	local memorizedStartingSpell = 0
	for spellLevel = 0, spellbookInfo.maxLevels - 1 do
		local memorizedSpellLevel = spellbookInfo.memorizedLevels:get(spellLevel)
		if memorizedSpellLevel ~= nil then
			local memorizedSpellList = spellbookInfo.memorizedLists:getReference(spellLevel)
			-- The engine expects a flattened starting index into the concatenated per-level lists.
			memorizedSpellLevel.m_spellLevel = spellLevel
			memorizedSpellLevel.m_magicType = spellbookInfo.spellType
			memorizedSpellLevel.m_memorizedStartingSpell = memorizedStartingSpell
			memorizedSpellLevel.m_memorizedCount = memorizedSpellList.m_nCount
			memorizedStartingSpell = memorizedStartingSpell + memorizedSpellList.m_nCount
		end
		EEex_Sprite_Private_SyncDerivedMemorizedSpellLevel(spellbookInfo, spellLevel, memorizedSpellLevel)
	end
end

function EEex_Sprite_Private_HasKnownSpell(spellbookInfo, spellLevel, spellType, spellResRef)
	local knownSpellList = spellbookInfo.knownLists:getReference(spellLevel)
	local node = knownSpellList.m_pNodeHead
	while node do
		local knownSpell = node.data
		if knownSpell.m_spellLevel == spellLevel
			and knownSpell.m_magicType == spellType
			and knownSpell.m_knownSpellId:get():upper() == spellResRef
		then
			return true
		end
		node = node.pNext
	end
	return false
end

-- @bubb_doc { EEex_Sprite_AddKnownSpell / instance_name=addKnownSpell }
--
-- @summary:
--
--     Adds ``spellResRef`` to the given ``sprite``'s known spell list for ``spellType`` at ``spellLevel``.
--
--     ``spellResRef`` must be a spell resref without an extension. ``spellLevel`` is zero-based.
--
--     If the spell is already known at the given level and type, no duplicate entry is added.
--
-- @self { sprite / usertype=CGameSprite }: The sprite whose known spell list is being modified.
--
-- @param { spellResRef / type=string }:
--
--     The spell resref to add. @EOL
--     Must not include an extension.
--
-- @param { spellLevel / type=number }:
--
--     The zero-based spell level to add the spell at. @EOL
--     Valid values depend on ``spellType``.
--
-- @param { spellType / type=number | string }:
--
--     The spellbook to modify. @EOL
--     Accepts ``0`` / ``PRIEST``, ``1`` / ``WIZARD``, or ``2`` / ``INNATE``.
--
-- @return { type=boolean }:
--
--     ``true`` if a new known-spell entry was added, or ``false`` if the spell was already present.

function EEex_Sprite_AddKnownSpell(sprite, spellResRef, spellLevel, spellType)
	local normalizedSpellType = EEex_Sprite_Private_NormalizeSpellType(spellType)
	local spellbookInfo = EEex_Sprite_Private_GetSpellbookInfo(sprite, normalizedSpellType)
	local normalizedSpellLevel = EEex_Sprite_Private_NormalizeSpellLevel(spellLevel, spellbookInfo.maxLevels)
	local normalizedSpellResRef = EEex_Sprite_Private_NormalizeSpellResref(spellResRef)

	-- Known spells are keyed by level + magic type + resref, so avoid duplicate nodes.
	if EEex_Sprite_Private_HasKnownSpell(spellbookInfo, normalizedSpellLevel, normalizedSpellType, normalizedSpellResRef) then
		return false
	end

	local knownSpellList = spellbookInfo.knownLists:getReference(normalizedSpellLevel)
	local knownSpell = EEex_PtrToUD(EEex_Malloc(CCreatureFileKnownSpell.sizeof), "CCreatureFileKnownSpell")
	EEex_Memset(EEex_UDToPtr(knownSpell), 0, CCreatureFileKnownSpell.sizeof)
	knownSpell.m_knownSpellId:set(normalizedSpellResRef)
	knownSpell.m_spellLevel = normalizedSpellLevel
	knownSpell.m_magicType = normalizedSpellType
	knownSpellList:AddTail(knownSpell)
	return true
end
CGameSprite.addKnownSpell = EEex_Sprite_AddKnownSpell

-- @bubb_doc { EEex_Sprite_AddMemorizedSpell / instance_name=addMemorizedSpell }
--
-- @summary:
--
--     Adds one or more memorized copies of ``spellResRef`` to the given ``sprite``'s spellbook.
--
--     The spell is first ensured to exist in the known-spell list for the same ``spellType`` and ``spellLevel``.
--
--     For spontaneous casters, the number of copies actually added is capped by the available slot count at that level.
--
-- @self { sprite / usertype=CGameSprite }: The sprite whose memorized spell list is being modified.
--
-- @param { spellResRef / type=string }:
--
--     The spell resref to add. @EOL
--     Must not include an extension.
--
-- @param { spellLevel / type=number }:
--
--     The zero-based spell level to add the spell at. @EOL
--     Valid values depend on ``spellType``.
--
-- @param { spellType / type=number | string }:
--
--     The spellbook to modify. @EOL
--     Accepts ``0`` / ``PRIEST``, ``1`` / ``WIZARD``, or ``2`` / ``INNATE``.
--
-- @param { spellCount / type=number / default=1 }:
--
--     The number of memorized entries to append.
--
-- @param { memorized / type=boolean / default=true }:
--
--     Determines whether newly added entries start flagged as memorized.
--
-- @return { type=number }:
--
--     The number of memorized-spell entries actually added.

function EEex_Sprite_AddMemorizedSpell(sprite, spellResRef, spellLevel, spellType, spellCount, memorized)
	local normalizedSpellType = EEex_Sprite_Private_NormalizeSpellType(spellType)
	local spellbookInfo = EEex_Sprite_Private_GetSpellbookInfo(sprite, normalizedSpellType)
	local normalizedSpellLevel = EEex_Sprite_Private_NormalizeSpellLevel(spellLevel, spellbookInfo.maxLevels)
	local normalizedSpellResRef = EEex_Sprite_Private_NormalizeSpellResref(spellResRef)
	local normalizedSpellCount = EEex_Sprite_Private_NormalizeSpellCount(spellCount)
	local normalizedMemorized = EEex_Sprite_Private_NormalizeMemorizedState(memorized)

	-- Memorized entries assume the spell is already present in the known-spell list.
	EEex_Sprite_AddKnownSpell(sprite, normalizedSpellResRef, normalizedSpellLevel, normalizedSpellType)
	if normalizedSpellCount <= 0 then
		return 0
	end

	local memorizedSpellList = spellbookInfo.memorizedLists:getReference(normalizedSpellLevel)
	local spontaneousSpellCopyLimit = EEex_Sprite_Private_GetSpontaneousSpellCopyLimit(sprite, spellbookInfo, normalizedSpellLevel)
	if spontaneousSpellCopyLimit ~= nil then
		-- Spontaneous casters are limited by slot count, not by how many identical nodes we would like to append.
		local existingSpellCopies = EEex_Sprite_Private_CountMatchingMemorizedSpells(memorizedSpellList, normalizedSpellResRef)
		normalizedSpellCount = math.min(normalizedSpellCount, math.max(0, spontaneousSpellCopyLimit - existingSpellCopies))
		if normalizedSpellCount <= 0 then
			return 0
		end
	end

	local memorizedSpellLevel = EEex_Sprite_Private_EnsureMemorizedSpellLevel(spellbookInfo, normalizedSpellLevel)
	local addedCount = 0

	for _ = 1, normalizedSpellCount do
		local memorizedSpell = EEex_PtrToUD(EEex_Malloc(CCreatureFileMemorizedSpell.sizeof), "CCreatureFileMemorizedSpell")
		EEex_Memset(EEex_UDToPtr(memorizedSpell), 0, CCreatureFileMemorizedSpell.sizeof)
		memorizedSpell.m_spellId:set(normalizedSpellResRef)
		memorizedSpell.m_flags = normalizedMemorized and 1 or 0
		memorizedSpellList:AddTail(memorizedSpell)
		addedCount = addedCount + 1
	end

	if addedCount > 0 then
		local memorizedSpellCount = memorizedSpellList.m_nCount
		if not EEex_Sprite_Private_IsSpontaneousCaster(sprite, normalizedSpellType) then
			-- Prepared casters store capacity directly on the level record; keep it at least as large as the list.
			if memorizedSpellLevel.m_baseCount < memorizedSpellCount then
				memorizedSpellLevel.m_baseCount = memorizedSpellCount
			end
			if memorizedSpellLevel.m_count < memorizedSpellCount then
				memorizedSpellLevel.m_count = memorizedSpellCount
			end
		end
		EEex_Sprite_Private_SyncMemorizedSpellInfo(spellbookInfo)
	end

	return addedCount
end
CGameSprite.addMemorizedSpell = EEex_Sprite_AddMemorizedSpell

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

function EEex_Sprite_GetLauncher(sprite, curAbility)
	return EEex_RunWithStackManager({
		{ ["name"] = "launcherSlot", ["struct"] = "Primitive<short>" } },
		function(manager)
			local launcherSlot = manager:getUD("launcherSlot")
			local launcher = sprite:GetLauncher(curAbility, launcherSlot)
			return launcher, launcher and launcherSlot.value or -1
		end
	)
end
CGameSprite.getLauncher = EEex_Sprite_GetLauncher

function EEex_Sprite_DisplayTextRef(sprite, text, optionalArgs)

	local id = sprite.m_id
	local message = EEex_NewUD("CMessageDisplayTextRef")
	message:Construct_Overload_Default()

	if optionalArgs == nil then optionalArgs = {} end
	message.m_targetId           = id
	message.m_sourceId           = id
	message.m_name               = sprite:getNameRef()
	message.m_text               = text
	message.m_nameColor          = optionalArgs["nameColor"] or CVidPalette.RANGE_COLORS:get(sprite.m_baseStats.m_colors:get(2))
	message.m_textColor          = optionalArgs["textColor"] or 0xBED7D7
	message.m_marker             = -1
	message.m_moveToTop          = false
	message.m_overHead           = optionalArgs["overHead"] or false
	message.m_overrideDialogMode = false
	message.m_bPlaySound         = optionalArgs["playSound"] or true

	EngineGlobals.g_pBaldurChitin.m_cMessageHandler:AddMessage(message, false)
end
CGameSprite.displayTextRef = EEex_Sprite_DisplayTextRef

function EEex_Sprite_DisplayMessage(sprite, messageStr, messageColor)

	local message = EEex_NewUD("CMessageDisplayText")

	EEex_RunWithStackManager({
		{ ["name"] = "messageStr", ["struct"] = "CString", ["constructor"] = {["args"] = {messageStr} } } },
		function(manager)
			local id = sprite.m_id
			message:Construct(
				sprite:GetName(true),
				manager:getUD("messageStr"),
				CVidPalette.RANGE_COLORS:get(sprite.m_baseStats.m_colors:get(2)),
				messageColor == nil and 0xBED7D7 or messageColor,
				-1, id, id
			)
		end
	)

	EngineGlobals.g_pBaldurChitin.m_cMessageHandler:AddMessage(message, false)

end
CGameSprite.displayMessage = EEex_Sprite_DisplayMessage

-- @bubb_doc { EEex_Sprite_GetActiveInactiveClasses / instance_name=getActiveInactiveClasses }
-- @summary:
--
--     Returns the active class ID for the given sprite. @EOL
--     In case of dual-classed characters, it also returns their original class and whether it is re-activated.
--
-- @self { sprite / usertype=CGameSprite }: Input sprite.
--
-- @return { type=table }: See summary.

function EEex_Sprite_GetActiveInactiveClasses(sprite)

	if not EEex_GameObject_IsSprite(sprite) then
		EEex_Error("Expected CGameSprite!")
	end

	local flags = sprite.m_baseStats.m_flags
	if not EEex_IsAtMostOneBitSet(flags, 0x1F8) then -- isolate bits 3-8 (0x8|0x10|0x20|0x40|0x80|0x100)
		EEex_Error("Expected at most one of bits 3-8 to be set in m_flags!")
	end

	local class = EEex_GameObject_GetClass(sprite)
	local symbol = EEex_Resource_IDSToSymbol("CLASS", class)
	local toReturn = {
		["active"] = class,
		["inactive"] = nil,
		["reactivated"] = nil,
	}

	local func = function()

		local toReturn = false
		local reactivated = EEex_Trigger_ParseConditionalString(string.format("Class(Myself,%d)", class))
		if reactivated:evalConditionalAsAIBase(sprite) then
			toReturn = true
		end
		reactivated:free()
		return toReturn

	end

	EEex_Utility_Switch(symbol, {

		-- FIGHTER_MAGE, resolves pair (1 <-> 2)
		["FIGHTER_MAGE"] = function()
			if EEex_IsBitSet(flags, 0x3) then -- Original class: Fighter
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "MAGE")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "FIGHTER")
			elseif EEex_IsBitSet(flags, 0x4) then -- Original class: Mage
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "FIGHTER")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "MAGE")
			end
		end,

		-- FIGHTER_CLERIC, resolves pair (2 <-> 3)
		["FIGHTER_CLERIC"] = function()
			if EEex_IsBitSet(flags, 0x3) then -- Original class: Fighter
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "CLERIC")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "FIGHTER")
			elseif EEex_IsBitSet(flags, 0x5) then -- Original class: Cleric
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "FIGHTER")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "CLERIC")
			end
		end,

		-- FIGHTER_THIEF, resolves pair (2 <-> 4)
		["FIGHTER_THIEF"] = function()
			if EEex_IsBitSet(flags, 0x3) then -- Original class: Fighter
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "THIEF")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "FIGHTER")
			elseif EEex_IsBitSet(flags, 0x6) then -- Original class: Thief
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "FIGHTER")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "THIEF")
			end
		end,

		-- MAGE_THIEF, resolves pair (1 <-> 4)
		["MAGE_THIEF"] = function()
			if EEex_IsBitSet(flags, 0x4) then -- Original class: Mage
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "THIEF")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "MAGE")
			elseif EEex_IsBitSet(flags, 0x6) then -- Original class: Thief
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "MAGE")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "THIEF")
			end
		end,

		-- CLERIC_MAGE, resolves pair (1 <-> 3)
		["CLERIC_MAGE"] = function()
			if EEex_IsBitSet(flags, 0x5) then -- Original class: Cleric
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "MAGE")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "CLERIC")
			elseif EEex_IsBitSet(flags, 0x4) then -- Original class: Mage
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "CLERIC")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "MAGE")
			end
		end,

		-- CLERIC_THIEF, resolves pair (3 <-> 4)
		["CLERIC_THIEF"] = function()
			if EEex_IsBitSet(flags, 0x5) then -- Original class: Cleric
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "THIEF")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "CLERIC")
			elseif EEex_IsBitSet(flags, 0x6) then -- Original class: Thief
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "CLERIC")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "THIEF")
			end
		end,

		-- FIGHTER_DRUID, resolves pair (2 <-> 11)
		["FIGHTER_DRUID"] = function()
			if EEex_IsBitSet(flags, 0x3) then -- Original class: Fighter
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "DRUID")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "FIGHTER")
			elseif EEex_IsBitSet(flags, 0x7) then -- Original class: Druid
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "FIGHTER")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "DRUID")
			end
		end,

		-- CLERIC_RANGER, resolves pair (3 <-> 12)
		["CLERIC_RANGER"] = function()
			if EEex_IsBitSet(flags, 0x5) then -- Original class: Cleric
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "RANGER")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "CLERIC")
			elseif EEex_IsBitSet(flags, 0x8) then -- Original class: Ranger
				toReturn["active"] = EEex_Resource_SymbolToIDS("CLASS", "CLERIC")
				toReturn["inactive"] = EEex_Resource_SymbolToIDS("CLASS", "RANGER")
			end
		end,

	}) -- no defaultCase needed: unhandled classes will simply return with inactive = nil, which is the expected value for non-dual-classable classes.

	if toReturn["inactive"] then
		toReturn["reactivated"] = func()
	end

	return toReturn
end
CGameSprite.getActiveInactiveClasses = EEex_Sprite_GetActiveInactiveClasses

-- @bubb_doc { EEex_Sprite_GetLevels / instance_name=getLevels }
-- @summary:
--
--     Returns the base and current (i.e. modified) class levels for the given sprite. @EOL
--     For dual-classed / multi-classed characters, will also return the highest and average (rounded up) class levels. @EOL
--     For dual-classed characters, the "highest" and "average" levels will be identical to the active class levels.
--
-- @self { sprite / usertype=CGameSprite }: Input sprite.
--
-- @return { type=table }: See summary.

function EEex_Sprite_GetLevels(sprite)

	if not EEex_GameObject_IsSprite(sprite) then
		EEex_Error("Expected CGameSprite!")
	end

	local baseStats = sprite.m_baseStats -- CCreatureFileHeader
	local activeStats = EEex_Sprite_GetActiveStats(sprite) -- CDerivedStats

	local class = EEex_GameObject_GetClass(sprite)
	local symbol = EEex_Resource_IDSToSymbol("CLASS", class)

	local toReturn = {
		["base"] = {
			["first"] = baseStats.m_level1,
			["second"] = 0,
			["third"] = 0,
			["highest"] = baseStats.m_level1,
			["average"] = baseStats.m_level1,
		},
		["active"] = {
			["first"] = activeStats.m_nLevel1,
			["second"] = 0,
			["third"] = 0,
			["highest"] = activeStats.m_nLevel1,
			["average"] = activeStats.m_nLevel1,
		},
	}

	local two = function()
		toReturn.base.second = baseStats.m_level2
		toReturn.active.second = activeStats.m_nLevel2
		--
		local tbl = EEex_Sprite_GetActiveInactiveClasses(sprite)
		if tbl["inactive"] then -- dualclass
			if string.find(symbol, EEex_Resource_IDSToSymbol("CLASS", tbl["inactive"]) .. "_", 1, true) then
				toReturn.base.highest = baseStats.m_level2
				toReturn.active.highest = activeStats.m_nLevel2
				--
				toReturn.base.average = baseStats.m_level2
				toReturn.active.average = activeStats.m_nLevel2
			else
				toReturn.base.highest = baseStats.m_level1
				toReturn.active.highest = activeStats.m_nLevel1
				--
				toReturn.base.average = baseStats.m_level1
				toReturn.active.average = activeStats.m_nLevel1
			end
		else -- true multiclass
			toReturn.base.highest = math.max(toReturn.base.first, toReturn.base.second)
			toReturn.active.highest = math.max(toReturn.active.first, toReturn.active.second)
			--
			toReturn.base.average = math.ceil((toReturn.base.first + toReturn.base.second) / 2)
			toReturn.active.average = math.ceil((toReturn.active.first + toReturn.active.second) / 2)
		end
	end

	local three = function()
		toReturn.base.second = baseStats.m_level2
		toReturn.active.second = activeStats.m_nLevel2
		toReturn.base.third = baseStats.m_level3
		toReturn.active.third = activeStats.m_nLevel3
		--
		toReturn.base.highest = math.max(toReturn.base.first, toReturn.base.second, toReturn.base.third)
		toReturn.active.highest = math.max(toReturn.active.first, toReturn.active.second, toReturn.active.third)
		--
		toReturn.base.average = math.ceil((toReturn.base.first + toReturn.base.second + toReturn.base.third) / 3)
		toReturn.active.average = math.ceil((toReturn.active.first + toReturn.active.second + toReturn.active.third) / 3)
	end

	EEex_Utility_Switch(symbol, {

		["FIGHTER_MAGE"] = two, -- NB: if we write ``two()``, then Lua calls the function immediately at table construction time, and assigns its return value to the key. Since two returns nothing, the return value is ``nil``, and that is what gets assigned to the key, which is not what we want. By writing just ``two``, we are assigning the function itself to the key, and EEex_Utility_Switch will call it when that case is hit.
		["FIGHTER_CLERIC"] = two,
		["FIGHTER_THIEF"] = two,
		["MAGE_THIEF"] = two,
		["CLERIC_MAGE"] = two,
		["CLERIC_THIEF"] = two,
		["FIGHTER_DRUID"] = two,
		["CLERIC_RANGER"] = two,
		--
		["FIGHTER_MAGE_THIEF"] = three,
		["FIGHTER_MAGE_CLERIC"] = three,

	}) -- no defaultCase needed: playable single classes and non-playable classes will simply keep default values.

	return toReturn

end
CGameSprite.getLevels = EEex_Sprite_GetLevels

-- @bubb_doc { EEex_Sprite_GetSelectedWeapon / instance_name=getSelectedWeapon }
-- @summary:
--
--     Returns information about the currently selected weapon for the given sprite, including: @EOL
--     - The weapon slot (as per ``SLOTS.IDS``) currently selected in the Inventory UI. @EOL
--     - The ``CItem`` userdata for the currently selected weapon. @EOL
--     - The ability index associated with the selected weapon. @EOL
--     - The launcher (``CItem`` userdata) associated with the selected weapon ability, if any. @EOL
--     - The launcher slot (as per ``SLOTS.IDS``) associated with the selected weapon ability, if any.
--
-- @self { sprite / usertype=CGameSprite }: Input sprite.
--
-- @return { type=table }: See summary.

function EEex_Sprite_GetSelectedWeapon(sprite)

	if not EEex_GameObject_IsSprite(sprite) then
		EEex_Error("Expected CGameSprite!")
	end

	local equipment = sprite.m_equipment -- CGameSpriteEquipment

	local toReturn = {
		["weaponSlot"] = equipment.m_selectedWeapon, -- number
		["weapon"] = equipment.m_items:get(equipment.m_selectedWeapon) or EEex_Error("Expected CItem!"), -- CItem
		["weaponAbility"] = equipment.m_selectedWeaponAbility, -- number
		["launcher"] = sprite:getLauncher(equipment.m_selectedWeaponAbility) or nil, -- CItem
		["launcherSlot"] = sprite:getLauncher(equipment.m_selectedWeaponAbility) and select(2, sprite:getLauncher(equipment.m_selectedWeaponAbility)) or nil, -- number
	}

	return toReturn
end
CGameSprite.getSelectedWeapon = EEex_Sprite_GetSelectedWeapon

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

EEex_Sprite_Private_QuickListNotifyRemovedListeners = {}

function EEex_Sprite_AddQuickListNotifyRemovedListener(listener)
	table.insert(EEex_Sprite_Private_QuickListNotifyRemovedListeners, listener)
end

EEex_Sprite_Private_SpellDisableStateChangedListeners = {}

function EEex_Sprite_AddSpellDisableStateChangedListener(listener)
	table.insert(EEex_Sprite_Private_SpellDisableStateChangedListeners, listener)
end

EEex_Sprite_Private_MarshalHandlers = {}

function EEex_Sprite_AddMarshalHandlers(handlerName, exporter, importer)
	EEex_Sprite_Private_MarshalHandlers[handlerName] = {
		["exporter"] = exporter,
		["importer"] = importer,
	}
end

EEex_Sprite_Private_BlockWeaponHitListeners = {}

function EEex_Sprite_AddBlockWeaponHitListener(listener)
	table.insert(EEex_Sprite_Private_BlockWeaponHitListeners, listener)
end

EEex_Sprite_Private_AlterBaseWeaponDamageListeners = {}

function EEex_Sprite_AddAlterBaseWeaponDamageListener(listener)
	table.insert(EEex_Sprite_Private_AlterBaseWeaponDamageListeners, listener)
end

-----------
-- Hooks --
-----------

function EEex_Sprite_Hook_CheckSuppressTooltip()
	return false
end

function EEex_Sprite_Hook_OnCheckQuickLists(sprite, abilityId, changeAmount, remove)

	local resref = abilityId.m_res:get()
	if resref == "" then
		return
	end

	if remove then
		for _, listener in ipairs(EEex_Sprite_Private_QuickListNotifyRemovedListeners) do
			EEex_Utility_TryIgnore(listener, sprite, resref)
		end
	elseif changeAmount ~= 0 then
		for _, listener in ipairs(EEex_Sprite_Private_QuickListsCheckedListeners) do
			EEex_Utility_TryIgnore(listener, sprite, resref, changeAmount)
		end
	end
end

function EEex_Sprite_Hook_OnResetQuickListCounts(sprite)
	for _, listener in ipairs(EEex_Sprite_Private_QuickListCountsResetListeners) do
		EEex_Utility_TryIgnore(listener, sprite)
	end
end

function EEex_Sprite_LuaHook_OnSpellDisableStateChanged(sprite)
	for _, listener in ipairs(EEex_Sprite_Private_SpellDisableStateChangedListeners) do
		EEex_Utility_TryIgnore(listener, sprite)
	end
end

function EEex_Sprite_Hook_CheckBlockWeaponHit(attackingSprite, targetSprite, weapon, weaponAbility)

	local listenerContext = {
		["attackingSprite"] = attackingSprite,
		["targetSprite"] = targetSprite,
		["weapon"] = weapon,
		["weaponAbility"] = weaponAbility,
	}

	for _, listener in ipairs(EEex_Sprite_Private_BlockWeaponHitListeners) do
		if EEex_Utility_TryIgnore(listener, listenerContext) then
			return true
		end
	end
end

-- function EEex_Sprite_Hook_OnConstruct(sprite)
--
-- end

-- function EEex_Sprite_Hook_OnDestruct(sprite)
--
-- end

-- IMPORTANT: This is part of the X-BIV1.0 schema, don't modify existing enum values without implementing migration code!
EEex_Sprite_Private_MarshalHandlerFieldType = {
	["TABLE_END"]     = 0,
	["TABLE_START"]   = 1,
	["STRING"]        = 2,
	["INT8"]          = 3,
	["INTU8"]         = 4,
	["INT16"]         = 5,
	["INTU16"]        = 6,
	["INT32"]         = 7,
	["INTU32"]        = 8,
	["INT64"]         = 9,
	["INTU64"]        = 10,
	["BOOLEAN_FALSE"] = 11,
	["BOOLEAN_TRUE"]  = 12,
}

EEex_Sprite_Private_CurrentSpriteMarshalHandlerData = {}
EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableSize = 0
EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableToMeta = {}
EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_MemorySize = 0

function EEex_Sprite_Private_DetermineSpriteMarshalHandlerNumberInfo(number)
	if number >= 0 then
		if number <= 0xFF then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INTU8, EEex_WriteU8, 1
		elseif number <= 0xFFFF then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INTU16, EEex_WriteU16, 2
		elseif number <= 0xFFFFFFFF then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INTU32, EEex_WriteU32, 4
		elseif number <= 0xFFFFFFFFFFFFFFFF then
			return EEex_Sprite_Private_MarshalHandlerFieldType.INTU64, EEex_WriteU64, 8
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
		["boolean"] = function(v)
			return 0
		end,
		["number"] = function(v)
			local _, _, writeAdvance = EEex_Sprite_Private_DetermineSpriteMarshalHandlerNumberInfo(v)
			return writeAdvance
		end,
		["string"] = function(v)
			return #v + 1
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
			if kType ~= "boolean" and kType ~= "number" and kType ~= "string" then
				EEex_Error("Only booleans / numbers / strings can be used as keys in creature marshal")
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
				if vType ~= "boolean" and vType ~= "number" and vType ~= "string" and vType ~= "table" then
					EEex_Error("Only booleans / numbers / strings / tables can be used as values in creature marshal")
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
		["boolean"] = function(v)
			EEex_Write8(memoryPtr, v
				and EEex_Sprite_Private_MarshalHandlerFieldType.BOOLEAN_TRUE
				or  EEex_Sprite_Private_MarshalHandlerFieldType.BOOLEAN_FALSE
			)
			memoryPtr = memoryPtr + 1
		end,
		["number"] = writeNumber,
		["string"] = function(v)
			EEex_Write8(memoryPtr, EEex_Sprite_Private_MarshalHandlerFieldType.STRING)
			memoryPtr = memoryPtr + 1
			EEex_WriteString(memoryPtr, v)
			memoryPtr = memoryPtr + #v + 1
		end,
		["table"] = function(v)
			EEex_Write8(memoryPtr, EEex_Sprite_Private_MarshalHandlerFieldType.TABLE_START)
			memoryPtr = memoryPtr + 1
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
		if toExport == nil then
			-- `nil` means the export handler doesn't want to marshal any data, not even an empty table.
			-- This saves some bytes by not writing the bare-bones serialized table structure.
			return
		end
		if type(toExport) ~= "table" then
			EEex_Error("Creature marshal handler must export table or nil")
		end
		EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableSize = EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableSize + 1
		EEex_Sprite_Private_CurrentSpriteMarshalHandlerData[EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableSize] = toExport
		EEex_Sprite_Private_CurrentSpriteMarshalHandlerData_TableToMeta[toExport] = {
			["handlerName"] = handlerName,
		}
	end

	for handlerName, handler in pairs(EEex_Sprite_Private_MarshalHandlers) do
		EEex_Utility_TryIgnore(function()
			addTableExport(handlerName, handler.exporter(sprite))
		end)
	end

	-- Marshal data that was stored in the fallback table because it was missing its handler
	for handlerName, toExport in pairs(EEex_GetUDAux(sprite)["EEex_Sprite_FallbackMarshalStorage"] or {}) do
		addTableExport(handlerName, toExport)
	end

	-- Initial size of 8 to store the signature and version.
	-- Round up to multiple of CGameEffectBase to match an effect boundary on the CRE.
	-- If only 8 bytes are needed (no data is marshalled), skip writing entirely.

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

function EEex_Sprite_LuaHook_ReadExtraEffectListUnmarshal(sprite, baseMemory)

	local memory = baseMemory + 8

	while true do

		local toFill = {}
		local handlerStr = EEex_ReadString(memory)
		memory = memory + #handlerStr + 1

		-- The top level list writes TABLE_END('\0') to signal that all
		-- marshalled data has ended, which reads as an empty string
		if handlerStr == "" then
			break
		end

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
			[EEex_Sprite_Private_MarshalHandlerFieldType.BOOLEAN_FALSE] = function()
				return false
			end,
			[EEex_Sprite_Private_MarshalHandlerFieldType.BOOLEAN_TRUE] = function()
				return true
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
			EEex_Utility_TryIgnore(handlers.importer, sprite, toFill)
		else
			-- If the required marshal handler is missing, keep the data around so that it isn't stripped from the savegame
			local fallbackStorage = EEex_Utility_GetOrCreateTable(EEex_GetUDAux(sprite), "EEex_Sprite_FallbackMarshalStorage")
			fallbackStorage[handlerStr] = toFill
		end
	end

	-- Return to the C++ hook how many effects were EEex binary data
	return EEex_RoundUp(memory - baseMemory, CGameEffectBase.sizeof) / CGameEffectBase.sizeof
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
		bSpellDisrupted = EEex_Utility_TryIgnore(_G[EEex_Sprite_Private_CustomConcentrationCheckFuncName], sprite, damageData)
		if bSpellDisrupted then
			break
		end
	end

	spriteAux["EEex_Sprite_DamageEntriesSinceActionStarted"] = {}
	return bSpellDisrupted
end

EEex_Sprite_Private_SavedDamageEffectTargetStartingHP = nil

EEex_Sprite_Private_DisruptableActions = {
	[ 31] = true, -- Spell()
	[ 95] = true, -- SpellPoint()
	[191] = true, -- SpellNoDec()
	[192] = true, -- SpellPointNoDec()
	[476] = true, -- EEex_SpellObjectOffset()
	[477] = true, -- EEex_SpellObjectOffsetNoDec()
}

function EEex_Sprite_Hook_OnDamageEffectStartingCalculations(effect, sourceSprite, targetSprite)
	local actionID = targetSprite.m_curAction.m_actionID
	if EEex_Sprite_Private_DisruptableActions[actionID] then
		EEex_Sprite_Private_SavedDamageEffectTargetStartingHP = targetSprite.m_baseStats.m_hitPoints
	end
end

function EEex_Sprite_Hook_OnDamageEffectDone(effect, sourceSprite, targetSprite)

	local actionID = targetSprite.m_curAction.m_actionID
	if EEex_Sprite_Private_DisruptableActions[actionID] then

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

--[[
+---------------------------------------------------------------------------------------------------------------------------------+
| Implement X-CLSERG.2DA - Ignore the -8 thac0 penalty characters incur when meleeing with a ranged weapon for specific           |
| [KITLIST.2DA]->ROWNAME / ITEMCAT.IDS pairs                                                                                      |
+---------------------------------------------------------------------------------------------------------------------------------+
|   [Lua] EEex_Sprite_Hook_ShouldIgnoreMeleeingWithRangedPenalty(sprite: CGameSprite, item: CItem, abilityNum: number) -> boolean |
|       return:                                                                                                                   |
|           -> false - Don't alter engine behavior                                                                                |
|           -> true  - Ignore -8 thac0 penalty                                                                                    |
+---------------------------------------------------------------------------------------------------------------------------------+
--]]

function EEex_Sprite_Hook_ShouldIgnoreMeleeingWithRangedPenalty(sprite, item, abilityNum)

	if item == nil then return false end
	item = sprite:getLauncher(item:getAbility(abilityNum)) or item

	local pRes = item.pRes
	if pRes == nil then return false end

	local pHeader = pRes.pHeader
	if pHeader == nil then return false end

	local m_baseStats = sprite.m_baseStats
	local kitIDS = EEex_BOr(EEex_LShift(m_baseStats.m_mageSpecUpperWord, 16), m_baseStats.m_mageSpecialization)

	local itemCategories = EEex_Resource_Private_KitIgnoresMeleeingWithRangedPenaltyForItemCategory[kitIDS]
	if itemCategories == nil then return false end

	return itemCategories[pHeader.itemType] == true
end

function EEex_Sprite_LuaHook_OnAfterEffectListUnmarshalled(sprite)

	local allCallbacks = EEex_Sprite_Private_LoadedWithUUIDCallbacks[sprite:getUUID()]
	if allCallbacks then
		for sourceUUID, callbacks in pairs(allCallbacks) do
			local sourceSprite = EEex_Sprite_GetFromUUID(sourceUUID)
			for _, callback in ipairs(callbacks) do
				EEex_Utility_TryIgnore(callback, sourceSprite, sprite)
			end
		end
	end

	for _, func in ipairs(EEex_Sprite_LoadedListeners) do
		EEex_Utility_TryIgnore(func, sprite)
	end
end

--[[
+-------------------------------------------------------------------------------------------------------------+
| Implement EEex_Sprite_AddAlterBaseWeaponDamageListener() - Lua listeners that can alter base weapon damage  |
+-------------------------------------------------------------------------------------------------------------+
|   [EEex.dll] CGameSprite::Override_Damage(                                                                  |
|                  curWeaponIn: CItem*, pLauncher: CItem*, curAttackNum: int, criticalDamage: int,            |
|                  type: CAIObjectType*, facing: short, myFacing: short, target: CGameSprite*, lastSwing: int |
|              )                                                                                              |
|   [Lua] EEex_Sprite_LuaHook_AlterBaseWeaponDamage(context: table)                                           |
+-------------------------------------------------------------------------------------------------------------+
--]]

function EEex_Sprite_LuaHook_AlterBaseWeaponDamage(context)
	for _, listener in ipairs(EEex_Sprite_Private_AlterBaseWeaponDamageListeners) do
		EEex_Utility_TryIgnore(listener, context)
	end
end
