
-------------
-- Options --
-------------

-- Key that, while paused, advances time 2 AsynchronousUpdate ticks, or 1 "game time" tick.
-- Holding this key for half a second causes time to flow normally until it is released.
B3TimeStep_Key = EEex_Key_GetFromName("d")

-------------
-- Globals --
-------------

B3TimeStep_PauseScheduled = false
B3TimeStep_PauseTick = -1

B3TimeStep_Flowing = false
B3TimeStep_FlowTick = -1

-------------
-- Utility --
-------------

function B3TimeStep_TogglePause()
	-- byte visualPause, byte bSendMessage, int idPlayerPause, byte bLogPause, byte bRequireHostUnpause
	EngineGlobals.g_pBaldurChitin.m_pEngineWorld:TogglePauseGame(true, true, 0, false, false)
end

function B3TimeStep_GetGameTime()
	return EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_worldTime.m_gameTime
end

function B3TimeStep_SetGameTime(value)
	EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_worldTime.m_gameTime = value
end

---------------
-- Main Tick --
---------------

function B3TimeStep_Tick()

	local gameTime = B3TimeStep_GetGameTime()
	if B3TimeStep_PauseTick ~= -1 and gameTime >= B3TimeStep_PauseTick then
		B3TimeStep_PauseTick = -1
		B3TimeStep_TogglePause()
		-- For some reason the engine reverses m_gameTime by 1 tick on pause.
		-- Since this code only steps 1 tick, force the time to advance.
		B3TimeStep_SetGameTime(gameTime)
	end

	if not B3TimeStep_Flowing and B3TimeStep_FlowTick ~= -1 and Infinity_GetClockTicks() >= B3TimeStep_FlowTick then
		B3TimeStep_TogglePause()
		B3TimeStep_Flowing = true
	end

	return false
end

-------------------
-- Key Listeners --
-------------------

EEex_Key_AddPressedListener(function(key)
	if key == B3TimeStep_Key and worldScreen == e:GetActiveEngine() and Infinity_TextEditHasFocus() == 0 and worldScreen:CheckIfPaused() then
		B3TimeStep_TogglePause()
		B3TimeStep_PauseTick = B3TimeStep_GetGameTime() + 1
		B3TimeStep_FlowTick = Infinity_GetClockTicks() + 500
	end
end)

EEex_Key_AddReleasedListener(function(key)
	if key == B3TimeStep_Key then
		if B3TimeStep_Flowing and not worldScreen:CheckIfPaused() then
			B3TimeStep_TogglePause()
		end
		B3TimeStep_Flowing = false
		B3TimeStep_FlowTick = -1
	end
end)

------------------------------
-- Maintain B3TimeStep_Menu --
------------------------------

EEex_Menu_AddMainFileLoadedListener(function()
	EEex_Menu_LoadFile("B3TiStep")
end)

function B3TimeStep_PushMenu()
	Infinity_PushMenu("B3TimeStep_Menu")
end
EEex_GameState_AddInitializedListener(B3TimeStep_PushMenu)
EEex_Menu_AddAfterMainFileReloadedListener(B3TimeStep_PushMenu)
