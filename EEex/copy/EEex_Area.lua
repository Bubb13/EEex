
function EEex_Area_GetVisible()
	local game = EngineGlobals.g_pBaldurChitin.m_pObjectGame
	return game.m_gameAreas:get(game.m_visibleArea)
end

function EEex_Area_GetVariableInt(area, variableName)
	return area.m_variables:getInt(variableName)
end
CGameArea.getVariableInt = EEex_Area_GetVariableInt

function EEex_Area_GetVariableString(area, variableName)
	return area.m_variables:getString(variableName)
end
CGameArea.getVariableString = EEex_Area_GetVariableString

function EEex_Area_SetVariableInt(area, variableName, value)
	area.m_variables:setInt(variableName, value)
end
CGameArea.setVariableInt = EEex_Area_SetVariableInt

function EEex_Area_SetVariableString(area, variableName, value)
	area.m_variables:setString(variableName, value)
end
CGameArea.setVariableString = EEex_Area_SetVariableString

-- @bubb_doc { EEex_Area_ForAllOfTypeInRange / instance_name=forAllOfTypeInRange }
-- @summary:
--
--     Calls `func` for every creature that matches `aiObjectType` around (`centerX`, `centerY`)
--     in the given `range`, as per the NumCreature() trigger.
--
-- @self { area / usertype=CGameArea }: The area to search.
--
-- @param { centerX / type=number }: The x coordinate to use as the center of the search radius.
--
-- @param { centerY / type=number }: The y coordinate to use as the center of the search radius.
--
-- @param { aiObjectType / usertype=CAIObjectType }:
--
--     The AI object type used to filter the objects passed to `func`.
--     Most commonly retrieved from `EEex_Object_ParseString()`. Remember to call `:free()`.
--
-- @param { range / type=number }: The radius to search around (`centerX`, `centerY`). `448` is a sprite's default visual range.
--
-- @param { func / type=function }: The function to call for every creature in the search area.
--
-- @param { bCheckForLineOfSight / type=boolean / default=true }:
--
--     Determines whether LOS is required from (`centerX`, `centerY`) to considered objects.
--
-- @param { bCheckForNonSprites / type=boolean / default=false }:
--
--     Determines whether `func` is additionally called for non-sprite objects in the main objects list.
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

function EEex_Area_ForAllOfTypeStringInRange(area, centerX, centerY, aiObjectTypeString, range, func, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local aiObjectType = EEex_Object_ParseString(aiObjectTypeString)
	area:forAllOfTypeInRange(centerX, centerY, aiObjectType, range, func, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	aiObjectType:free()
end
CGameArea.forAllOfTypeStringInRange = EEex_Area_ForAllOfTypeStringInRange

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

function EEex_Area_GetAllOfTypeStringInRange(area, centerX, centerY, aiObjectTypeString, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local aiObjectType = EEex_Object_ParseString(aiObjectTypeString)
	local toReturn = area:getAllOfTypeInRange(centerX, centerY, aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	aiObjectType:free()
	return toReturn
end
CGameArea.getAllOfTypeStringInRange = EEex_Area_GetAllOfTypeStringInRange

function EEex_Area_CountAllOfTypeInRange(area, centerX, centerY, aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local toReturn = 0
	area:forAllOfTypeInRange(centerX, centerY, aiObjectType, range, function(object)
		toReturn = toReturn + 1
	end, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	return toReturn
end
CGameArea.countAllOfTypeInRange = EEex_Area_CountAllOfTypeInRange

function EEex_Area_CountAllOfTypeStringInRange(area, centerX, centerY, aiObjectTypeString, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	local aiObjectType = EEex_Object_ParseString(aiObjectTypeString)
	local toReturn = area:countAllOfTypeInRange(centerX, centerY, aiObjectType, range, bCheckForLineOfSight, bCheckForNonSprites, terrainTable)
	aiObjectType:free()
	return toReturn
end
CGameArea.countAllOfTypeStringInRange = EEex_Area_CountAllOfTypeStringInRange
