
-------------
-- General --
-------------

-- @bubb_doc { EEex_GameState_GetGlobalInt }
--
-- @summary: Returns the integer value of the ``variableName`` Global scoped to ``GLOBAL``.
--           If no variable named ``variableName`` exists, returns ``0``.
--
-- @param { variableName / type=string }: The name of the variable to fetch.
--
-- @return { type=number }: See summary.

function EEex_GameState_GetGlobalInt(variableName)
	return EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_variables:getInt(variableName)
end

-- @bubb_doc { EEex_GameState_GetGlobalString }
--
-- @summary: Returns the string value of the ``variableName`` Global scoped to ``GLOBAL``.
--           If no variable named ``variableName`` exists, returns ``""``.
--
-- @note: Global string values can only be accessed through EEex functions.
--
-- @param { variableName / type=string }: The name of the variable to fetch.
--
-- @return { type=string }: See summary.

function EEex_GameState_GetGlobalString(variableName)
	return EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_variables:getString(variableName)
end

-- @bubb_doc { EEex_GameState_SetGlobalInt }
--
-- @summary: Sets the integer value of the ``variableName`` Global scoped to ``GLOBAL`` to ``value``.
--
-- @param { variableName / type=string }: The name of the variable to set.
--
-- @param { value / type=number }: The value to set the variable to.

function EEex_GameState_SetGlobalInt(variableName, value)
	EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_variables:setInt(variableName, value)
end

-- @bubb_doc { EEex_GameState_SetGlobalString }
--
-- @summary: Sets the string value of the ``variableName`` Global scoped to ``GLOBAL`` to ``value``.
--
-- @note: Global string values can only be accessed through EEex functions.
--
-- @warning: Global string values can be a maximum of 32 characters. Attempting to set a value
--           that is longer than 32 characters will result in the value being truncated.
--
-- @param { variableName / type=string }: The name of the variable to set.
--
-- @param { value / type=string }: The value to set the variable to.

function EEex_GameState_SetGlobalString(variableName, value)
	EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_variables:setString(variableName, value)
end

---------------
-- Listeners --
---------------

EEex_GameState_Private_BeforeIncludesListeners = {}

function EEex_GameState_AddBeforeIncludesListener(listener)
	table.insert(EEex_GameState_Private_BeforeIncludesListeners, listener)
end

EEex_GameState_Private_AlreadyInitialized = false
EEex_GameState_Private_InitializedListeners = {}

-- @bubb_doc { EEex_GameState_AddInitializedListener }
--
-- @summary: Registers a listener function that is called immediately after the engine's Lua environment has been initialized.
--           This only occurs once during the engine's early start up process. If the engine has already been initialized,
--           ``listener`` is called immediately.
--
-- @param { listener / type=function }: The listener to register.

function EEex_GameState_AddInitializedListener(listener)
	if EEex_GameState_Private_AlreadyInitialized then
		listener()
	else
		table.insert(EEex_GameState_Private_InitializedListeners, listener)
	end
end

EEex_GameState_DestroyedListeners = {}

-- @bubb_doc { EEex_GameState_AddDestroyedListener }
--
-- @summary: Registers a listener function that is called immediately after the engine has cleaned up a game session.
--           Examples of when this occurs include the user quitting to the main menu, loading a save, etc.
--
-- @param { listener / type=function }: The listener to register.

function EEex_GameState_AddDestroyedListener(listener)
	table.insert(EEex_GameState_DestroyedListeners, listener)
end

EEex_GameState_ShutdownListeners = {}

function EEex_GameState_AddShutdownListener(listener)
	table.insert(EEex_GameState_ShutdownListeners, listener)
end

-----------
-- Hooks --
-----------

function EEex_GameState_Hook_OnBeforeIncludes()
	for _, listener in ipairs(EEex_GameState_Private_BeforeIncludesListeners) do
		listener()
	end
end

function EEex_GameState_LuaHook_OnInitialized()
	for _, listener in ipairs(EEex_GameState_Private_InitializedListeners) do
		listener()
	end
	EEex_GameState_Private_AlreadyInitialized = true
	EEex_GameState_Private_InitializedListeners = {}
	-- So EEex files using EEex_GameState_AddInitializedListener() always run before options initialization.
	EEex_Options_OnAfterGameStateInitialized()
end

function EEex_GameState_Hook_OnDestroyed()
	for _, listener in ipairs(EEex_GameState_DestroyedListeners) do
		listener()
	end
end

function EEex_GameState_Hook_OnBeforeShutdown()
	for _, listener in ipairs(EEex_GameState_ShutdownListeners) do
		listener()
	end
end
