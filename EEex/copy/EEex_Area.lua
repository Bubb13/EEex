
-- @bubb_doc { EEex_Area_GetVisible }
--
-- @summary: Returns the currently-visible ``CGameArea``, or ``nil`` if the worldscreen is not initialized.
--
-- @return { usertype=CGameArea | nil }: See summary.

function EEex_Area_GetVisible()
	local game = EngineGlobals.g_pBaldurChitin.m_pObjectGame
	return game.m_gameAreas:get(game.m_visibleArea)
end

function EEex_Area_GetNearestOpenPosition(area, x, y, snapshotPersonalSpace, terrainTable, facing)
	local resultX, resultY = area.m_search:GetNearestOpenSquare(x / 16, y / 12, terrainTable or CGameObject.DEFAULT_TERRAIN_TABLE, snapshotPersonalSpace, facing or -1)
	return resultX * 16, resultY * 12
end
CGameArea.getNearestOpenPosition = EEex_Area_GetNearestOpenPosition

function EEex_Area_CreateVisualEffect(area, resref, pointX, pointY, optionalArgs)

	if optionalArgs == nil then optionalArgs = {} end
	local targetX = optionalArgs["targetX"] or pointX
	local targetY = optionalArgs["targetY"] or pointY
	local height  = optionalArgs["height"]  or 32
	local speed   = optionalArgs["speed"]   or -1

	local objectId = EEex_RunWithStackManager({
		{ ["name"] = "name",        ["struct"] = "CString", ["constructor"] = {                        ["args"] = {resref}          }, ["noDestruct"] = true },
		{ ["name"] = "startPoint",  ["struct"] = "CPoint",  ["constructor"] = {["variant"] = "fromXY", ["args"] = {pointX, pointY}  }                        },
		{ ["name"] = "targetPoint", ["struct"] = "CPoint",  ["constructor"] = {["variant"] = "fromXY", ["args"] = {targetX, targetY}}                        }, },
		function(manager)
			return CVisualEffect.Load(manager:getUD("name"), area, manager:getUD("startPoint"),
				-1, manager:getUD("targetPoint"), height, false, speed)
		end)

	return EEex_GameObject_Get(objectId)
end
CGameArea.createVisualEffect = EEex_Area_CreateVisualEffect

-- @bubb_doc { EEex_Area_GetVariableInt / instance_name=getVariableInt }
--
-- @summary: Returns the integer value of the ``variableName`` Global scoped to ``area``.
--           If no variable named ``variableName`` exists, returns ``0``.
--
-- @self { area / usertype=CGameArea }: The area that the variable being fetched is scoped to.
--
-- @param { variableName / type=string }: The name of the variable to fetch.
--
-- @return { type=number }: See summary.

function EEex_Area_GetVariableInt(area, variableName)
	return area.m_variables:getInt(variableName)
end
CGameArea.getVariableInt = EEex_Area_GetVariableInt

-- @bubb_doc { EEex_Area_GetVariableString / instance_name=getVariableString }
--
-- @summary: Returns the string value of the ``variableName`` Global scoped to ``area``.
--           If no variable named ``variableName`` exists, returns ``""``.
--
-- @note: Global string values can only be accessed through EEex functions.
--
-- @self { area / usertype=CGameArea }: The area that the variable being fetched is scoped to.
--
-- @param { variableName / type=string }: The name of the variable to fetch.
--
-- @return { type=string }: See summary.

function EEex_Area_GetVariableString(area, variableName)
	return area.m_variables:getString(variableName)
end
CGameArea.getVariableString = EEex_Area_GetVariableString

-- @bubb_doc { EEex_Area_SetVariableInt / instance_name=setVariableInt }
--
-- @summary: Sets the integer value of the ``variableName`` Global scoped to ``area`` to ``value``.
--
-- @self { area / usertype=CGameArea }: The area that the variable being set is scoped to.
--
-- @param { variableName / type=string }: The name of the variable to set.
--
-- @param { value / type=number }: The value to set the variable to.

function EEex_Area_SetVariableInt(area, variableName, value)
	area.m_variables:setInt(variableName, value)
end
CGameArea.setVariableInt = EEex_Area_SetVariableInt

-- @bubb_doc { EEex_Area_SetVariableString / instance_name=setVariableString }
--
-- @summary: Sets the string value of the ``variableName`` Global scoped to ``area`` to ``value``.
--
-- @note: Global string values can only be accessed through EEex functions.
--
-- @warning: Global string values can be a maximum of 32 characters. Attempting to set a value
--           that is longer than 32 characters will result in the value being truncated.
--
-- @self { area / usertype=CGameArea }: The area that the variable being set is scoped to.
--
-- @param { variableName / type=string }: The name of the variable to set.
--
-- @param { value / type=string }: The value to set the variable to.

function EEex_Area_SetVariableString(area, variableName, value)
	area.m_variables:setString(variableName, value)
end
CGameArea.setVariableString = EEex_Area_SetVariableString

-- @bubb_doc { EEex_Area_ForAllOfTypeInRange / instance_name=forAllOfTypeInRange }
-- @summary:
--
--     Calls ``func`` for every creature that matches ``aiObjectType`` around (``centerX``, ``centerY``)
--     in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { area / usertype=CGameArea }: The area to search.
--
-- @param { centerX / type=number }: The x coordinate to use as the center of the search radius.
--
-- @param { centerY / type=number }: The y coordinate to use as the center of the search radius.
--
-- @param { aiObjectType / usertype=CAIObjectType }:
--
--     The AI object type used to filter the objects passed to ``func``. @EOL
--     Most commonly retrieved from ``EEex_Object_ParseString()``. Remember to call ``:free()``.
--
-- @param { range / type=number }: The radius to search around (``centerX``, ``centerY``). ``448`` is a sprite's default visual range.
--
-- @param { func / type=function }: The function to call for every creature in the search area.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from (``centerX``, ``centerY``) to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=CGameObject.DEFAULT_VISIBLE_TERRAIN_TABLE }:
--
--     The terrain table to use for determining LOS.

function EEex_Area_ForAllOfTypeInRange(area, centerX, centerY, aiObjectType, range, func, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	EEex_RunWithStackManager({
		{ ["name"] = "center", ["struct"] = "CPoint", ["constructor"] = { ["variant"] = "fromXY", ["args"] = { centerX, centerY } } },
		{ ["name"] = "resultPtrList", ["struct"] = "CTypedPtrList<CPtrList,long>" } },
		function(manager)
			local resultPtrList = manager:getUD("resultPtrList")
			area:GetAllInRange1(manager:getUD("center"), aiObjectType, range, terrainTable or CGameObject.DEFAULT_VISIBLE_TERRAIN_TABLE,
				resultPtrList, bCheckForLineOfSight or 1, bCheckForNonSprites or 0)
			EEex_Utility_IterateCPtrList(resultPtrList, function(objectID)
				func(EEex_GameObject_Get(objectID))
			end)
		end)
end
CGameArea.forAllOfTypeInRange = EEex_Area_ForAllOfTypeInRange

-- @bubb_doc { EEex_Area_ForAllOfTypeStringInRange / instance_name=forAllOfTypeStringInRange }
-- @summary:
--
--     Calls ``func`` for every creature that matches ``aiObjectTypeString`` around (``centerX``, ``centerY``)
--     in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { area / usertype=CGameArea }: The area to search.
--
-- @param { centerX / type=number }: The x coordinate to use as the center of the search radius.
--
-- @param { centerY / type=number }: The y coordinate to use as the center of the search radius.
--
-- @param { aiObjectTypeString / type=string }:
--
--     The AI object type string used to filter the objects passed to ``func``. @EOL
--     Automatically parsed by ``EEex_Object_ParseString()``; the resulting object is freed before return.
--
-- @param { range / type=number }: The radius to search around (``centerX``, ``centerY``). ``448`` is a sprite's default visual range.
--
-- @param { func / type=function }: The function to call for every creature in the search area.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from (``centerX``, ``centerY``) to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=CGameObject.DEFAULT_VISIBLE_TERRAIN_TABLE }:
--
--     The terrain table to use for determining LOS.

function EEex_Area_ForAllOfTypeStringInRange(area, centerX, centerY, aiObjectTypeString, range, func, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local aiObjectType = EEex_Object_ParseString(aiObjectTypeString)
	area:forAllOfTypeInRange(centerX, centerY, aiObjectType, range, func, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	aiObjectType:free()
end
CGameArea.forAllOfTypeStringInRange = EEex_Area_ForAllOfTypeStringInRange

-- @bubb_doc { EEex_Area_GetAllOfTypeInRange / instance_name=getAllOfTypeInRange }
-- @summary:
--
--     Returns a table populated by every creature that matches ``aiObjectType`` around (``centerX``, ``centerY``)
--     in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { area / usertype=CGameArea }: The area to search.
--
-- @param { centerX / type=number }: The x coordinate to use as the center of the search radius.
--
-- @param { centerY / type=number }: The y coordinate to use as the center of the search radius.
--
-- @param { aiObjectType / usertype=CAIObjectType }:
--
--     The AI object type used to filter the objects passed to ``func``. @EOL
--     Most commonly retrieved from ``EEex_Object_ParseString()``. Remember to call ``:free()``.
--
-- @param { range / type=number }: The radius to search around (``centerX``, ``centerY``). ``448`` is a sprite's default visual range.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from (``centerX``, ``centerY``) to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=CGameObject.DEFAULT_VISIBLE_TERRAIN_TABLE }:
--
--     The terrain table to use for determining LOS.
--
-- @return { type=table }: See summary.

function EEex_Area_GetAllOfTypeInRange(area, centerX, centerY, aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local toReturn = {}
	local toReturnI = 1
	area:forAllOfTypeInRange(centerX, centerY, aiObjectType, range, function(object)
		toReturn[toReturnI] = object
		toReturnI = toReturnI + 1
	end, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	return toReturn
end
CGameArea.getAllOfTypeInRange = EEex_Area_GetAllOfTypeInRange

-- @bubb_doc { EEex_Area_GetAllOfTypeStringInRange / instance_name=getAllOfTypeStringInRange }
-- @summary:
--
--     Returns a table populated by every creature that matches ``aiObjectTypeString`` around (``centerX``, ``centerY``)
--     in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { area / usertype=CGameArea }: The area to search.
--
-- @param { centerX / type=number }: The x coordinate to use as the center of the search radius.
--
-- @param { centerY / type=number }: The y coordinate to use as the center of the search radius.
--
-- @param { aiObjectTypeString / type=string }:
--
--     The AI object type string used to filter the objects added to the return table. @EOL
--     Automatically parsed by ``EEex_Object_ParseString()``; the resulting object is freed before return.
--
-- @param { range / type=number }: The radius to search around (``centerX``, ``centerY``). ``448`` is a sprite's default visual range.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from (``centerX``, ``centerY``) to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=CGameObject.DEFAULT_VISIBLE_TERRAIN_TABLE }:
--
--     The terrain table to use for determining LOS.
--
-- @return { type=table }: See summary.

function EEex_Area_GetAllOfTypeStringInRange(area, centerX, centerY, aiObjectTypeString, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local aiObjectType = EEex_Object_ParseString(aiObjectTypeString)
	local toReturn = area:getAllOfTypeInRange(centerX, centerY, aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	aiObjectType:free()
	return toReturn
end
CGameArea.getAllOfTypeStringInRange = EEex_Area_GetAllOfTypeStringInRange

-- @bubb_doc { EEex_Area_CountAllOfTypeInRange / instance_name=countAllOfTypeInRange }
-- @summary:
--
--     Returns the number of creatures that match ``aiObjectType`` around (``centerX``, ``centerY``)
--     in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { area / usertype=CGameArea }: The area to search.
--
-- @param { centerX / type=number }: The x coordinate to use as the center of the search radius.
--
-- @param { centerY / type=number }: The y coordinate to use as the center of the search radius.
--
-- @param { aiObjectType / usertype=CAIObjectType }:
--
--     The AI object type used to filter the objects passed to ``func``. @EOL
--     Most commonly retrieved from ``EEex_Object_ParseString()``. Remember to call ``:free()``.
--
-- @param { range / type=number }: The radius to search around (``centerX``, ``centerY``). ``448`` is a sprite's default visual range.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from (``centerX``, ``centerY``) to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=CGameObject.DEFAULT_VISIBLE_TERRAIN_TABLE }:
--
--     The terrain table to use for determining LOS.
--
-- @return { type=number }: See summary.

function EEex_Area_CountAllOfTypeInRange(area, centerX, centerY, aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local toReturn = 0
	area:forAllOfTypeInRange(centerX, centerY, aiObjectType, range, function(object)
		toReturn = toReturn + 1
	end, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	return toReturn
end
CGameArea.countAllOfTypeInRange = EEex_Area_CountAllOfTypeInRange

-- @bubb_doc { EEex_Area_CountAllOfTypeStringInRange / instance_name=countAllOfTypeStringInRange }
-- @summary:
--
--     Returns the number of creatures that match ``aiObjectTypeString`` around (``centerX``, ``centerY``)
--     in the given ``range``, as per the ``NumCreature()`` trigger.
--
-- @self { area / usertype=CGameArea }: The area to search.
--
-- @param { centerX / type=number }: The x coordinate to use as the center of the search radius.
--
-- @param { centerY / type=number }: The y coordinate to use as the center of the search radius.
--
-- @param { aiObjectTypeString / type=string }:
--
--     The AI object type string used to filter the objects added to the return table. @EOL
--     Automatically parsed by ``EEex_Object_ParseString()``; the resulting object is freed before return.
--
-- @param { range / type=number }: The radius to search around (``centerX``, ``centerY``). ``448`` is a sprite's default visual range.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from (``centerX``, ``centerY``) to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether non-sprite objects in the main objects list are considered.
--
-- @param { terrainTable / usertype=Array<byte,16> / default=CGameObject.DEFAULT_VISIBLE_TERRAIN_TABLE }:
--
--     The terrain table to use for determining LOS.
--
-- @return { type=number }: See summary.

function EEex_Area_CountAllOfTypeStringInRange(area, centerX, centerY, aiObjectTypeString, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local aiObjectType = EEex_Object_ParseString(aiObjectTypeString)
	local toReturn = area:countAllOfTypeInRange(centerX, centerY, aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	aiObjectType:free()
	return toReturn
end
CGameArea.countAllOfTypeStringInRange = EEex_Area_CountAllOfTypeStringInRange
