
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

EEex_GameState_InitializedListeners = {}

-- @bubb_doc { EEex_GameState_AddInitializedListener }
--
-- @summary: Registers a listener function that is called immediately after the engine's Lua environment has been initialized.
--           This only occurs once during the engine's early start up process.
--
-- @param { listener / type=function }: The listener to register.

function EEex_GameState_AddInitializedListener(listener)
	table.insert(EEex_GameState_InitializedListeners, listener)
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

-----------
-- Hooks --
-----------

function EEex_GameState_LuaHook_OnInitialized()
	for _, listener in ipairs(EEex_GameState_InitializedListeners) do
		listener()
	end
end

function EEex_GameState_Hook_OnDestroyed()
	for _, listener in ipairs(EEex_GameState_DestroyedListeners) do
		listener()
	end
end

-----------------------------------
-- Generic Lua maps out of .2DAs --
-----------------------------------

kitIDSToSymbol = {}

EEex_GameState_AddInitializedListener(function()

	local kitlist = EEex_Resource_Load2DA("KITLIST")
	local _, kitListLastRowIndex = kitlist:getDimensions()
	kitListLastRowIndex = kitListLastRowIndex - 2

	local kitSymbolColumn = kitlist:findColumnLabel("ROWNAME")
	local kitIDSColumn = kitlist:findColumnLabel("KITIDS")

	for rowIndex = 0, kitListLastRowIndex do
		local kitIDSStr = kitlist:getAtPoint(kitIDSColumn, rowIndex)
		if kitIDSStr:sub(1, 2):lower() == "0x" then
			local kitIDS = tonumber(kitIDSStr:sub(3), 16)
			if kitIDS ~= nil then
				local kitSymbol = kitlist:getAtPoint(kitSymbolColumn, rowIndex)
				kitIDSToSymbol[kitIDS] = kitSymbol
			end
		end
	end
end)

itemcatIDSToSymbol = {}

EEex_GameState_AddInitializedListener(function()

	local itemcat = EEex_Resource_LoadIDS("ITEMCAT")

	for id = 15, 30 do -- for all weapon categories ...
		itemcatIDSToSymbol[id] = EEex_Utility_FindNameById(itemcat, id)
	end
end)

EEex_Sprite_Private_KitIgnoresCloseRangedPenalityForItemCategory = {}

EEex_GameState_AddInitializedListener(function()

	local data = EEex_Resource_Load2DA("X-CLSERG")
	local nX, nY = data:getDimensions()
	nX = nX - 2
	nY = nY - 1

	for rowIndex = 0, nY do
		EEex_Sprite_Private_KitIgnoresCloseRangedPenalityForItemCategory[data:getRowLabel(rowIndex)] = {}
		for columnIndex = 0, nX do
			EEex_Sprite_Private_KitIgnoresCloseRangedPenalityForItemCategory[data:getRowLabel(rowIndex)][data:getColumnLabel(columnIndex)] = data:getAtPoint(columnIndex, rowIndex)
		end
	end
end)