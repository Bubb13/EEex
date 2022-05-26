
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
