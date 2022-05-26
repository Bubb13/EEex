
-------------
-- General --
-------------

function EEex_GameState_GetGlobalInt(variableName)
	return EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_variables:getInt(variableName)
end

function EEex_GameState_GetGlobalString(variableName)
	return EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_variables:getString(variableName)
end

function EEex_GameState_SetGlobalInt(variableName, value)
	EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_variables:setInt(variableName, value)
end

function EEex_GameState_SetGlobalString(variableName, value)
	EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_variables:setString(variableName, value)
end

---------------
-- Listeners --
---------------

EEex_GameState_InitializedListeners = {}

function EEex_GameState_AddInitializedListener(listener)
	table.insert(EEex_GameState_InitializedListeners, listener)
end

-----------
-- Hooks --
-----------

function EEex_GameState_Hook_OnInitialized()
	for _, listener in ipairs(EEex_GameState_InitializedListeners) do
		listener()
	end
end
