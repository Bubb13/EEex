
-------------
-- Options --
-------------

-- Key that, while paused, advances time 2 AsynchronousUpdate ticks, or 1 "game time" tick.
-- Holding this key for half a second causes time to flow normally until it is released.
EEex_Options_Register(EEex_Options_Option.new({
	["id"]       = "B3TimeStep_Keybind",
	["default"]  = EEex_Options_UnmarshalKeybind("d|Down"),
	["type"]     = EEex_Options_KeybindType.new({
		["lockedFireType"] = EEex_Options_KeybindFireType.DOWN,
		["callback"]       = function() B3TimeStep_Private_KeybindActivated() end,
	}),
	["accessor"] = EEex_Options_KeybindAccessor.new({ ["keybindID"] = "B3TimeStep_Keybind" }),
	["storage"]  = EEex_Options_KeybindLuaStorage.new({ ["section"] = "EEex", ["key"] = "Time Step Module: Keybind" }),
}))

EEex_Options_AddTab("Module: Time Step", function() return {
	{
		EEex_Options_DisplayEntry.new({
			["name"]     = "Keybind",
			["optionID"] = "B3TimeStep_Keybind",
			["widget"]   = EEex_Options_KeybindWidget.new(),
		}),
	},
} end)

-------------
-- Globals --
-------------

B3TimeStep_Private_PauseScheduled = false
B3TimeStep_Private_PauseTick = -1

B3TimeStep_Private_Flowing = false
B3TimeStep_Private_FlowTick = -1

-------------
-- Utility --
-------------

function B3TimeStep_Private_TogglePause()
	-- byte visualPause, byte bSendMessage, int idPlayerPause, byte bLogPause, byte bRequireHostUnpause
	EngineGlobals.g_pBaldurChitin.m_pEngineWorld:TogglePauseGame(true, true, 0, false, false)
end

function B3TimeStep_Private_GetGameTime()
	return EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_worldTime.m_gameTime
end

function B3TimeStep_Private_SetGameTime(value)
	EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_worldTime.m_gameTime = value
end

---------------
-- Main Tick --
---------------

function B3TimeStep_Private_Tick()

	local gameTime = B3TimeStep_Private_GetGameTime()
	if B3TimeStep_Private_PauseTick ~= -1 and gameTime >= B3TimeStep_Private_PauseTick then
		B3TimeStep_Private_PauseTick = -1
		B3TimeStep_Private_TogglePause()
		-- For some reason the engine reverses m_gameTime by 1 tick on pause.
		-- Since this code only steps 1 tick, force the time to advance.
		B3TimeStep_Private_SetGameTime(gameTime)
	end

	if not B3TimeStep_Private_Flowing and B3TimeStep_Private_FlowTick ~= -1 and Infinity_GetClockTicks() >= B3TimeStep_Private_FlowTick then
		B3TimeStep_Private_TogglePause()
		B3TimeStep_Private_Flowing = true
	end

	return false
end

-------------------
-- Key Listeners --
-------------------

function B3TimeStep_Private_KeybindActivated()
	if worldScreen == e:GetActiveEngine() and Infinity_TextEditHasFocus() == 0 and worldScreen:CheckIfPaused() then
		B3TimeStep_Private_KeybindActive = true
		B3TimeStep_Private_TogglePause()
		B3TimeStep_Private_PauseTick = B3TimeStep_Private_GetGameTime() + 1
		B3TimeStep_Private_FlowTick = Infinity_GetClockTicks() + 500
	end
end

EEex_Key_AddReleasedListener(function(key)

	if B3TimeStep_Private_KeybindActive then

		B3TimeStep_Private_KeybindActive = false

		if B3TimeStep_Private_Flowing and not worldScreen:CheckIfPaused() then
			B3TimeStep_Private_TogglePause()
		end

		B3TimeStep_Private_Flowing = false
		B3TimeStep_Private_FlowTick = -1
	end
end)

------------------------------
-- Maintain B3TimeStep_Menu --
------------------------------

EEex_Menu_AddMainFileLoadedListener(function()
	EEex_Menu_LoadFile("B3TiStep")
end)

function B3TimeStep_Private_PushMenu()
	Infinity_PushMenu("B3TimeStep_Menu")
end
EEex_GameState_AddInitializedListener(B3TimeStep_Private_PushMenu)
EEex_Menu_AddAfterMainFileReloadedListener(B3TimeStep_Private_PushMenu)
