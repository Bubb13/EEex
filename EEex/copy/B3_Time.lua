
B3Time_Key = EEex_GetKeyFromName("d")

B3Time_PauseScheduled = false
B3Time_PauseTick = 0

B3Time_Flowing = false
B3Time_FlowTick = -1

function B3Time_Temp()
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	EEex_MessageBox(EEex_ToHex(m_pObjectGame + 0x2500))
end

function B3Time_TogglePause()
	local worldScreenAddress = EEex_ReadDword(EEex_ReadUserdata(worldScreen))
	EEex_Call(EEex_Label("CScreenWorld::TogglePauseGame"), {0, 0, 0, 1, 1}, worldScreenAddress, 0x0)
end

function B3Time_TimeStone(bargain)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	EEex_WriteDword(m_pObjectGame + 0x2500, bargain)
end

function B3Time_Tick()

	if B3Time_FlowTick ~= -1 and (not B3Time_Flowing) and Infinity_GetClockTicks() >= B3Time_FlowTick then
		B3Time_TogglePause()
		B3Time_Flowing = true
	end

	if B3Time_PauseScheduled and EEex_GetGameTick() >= B3Time_PauseTick then
		B3Time_PauseScheduled = false
		local dormammu = EEex_GetGameTick()
		B3Time_TogglePause()
		B3Time_TimeStone(dormammu)
	end
	
	return true
end

function B3Time_KeyPressedListener(key)
	if key == B3Time_Key and worldScreen:CheckIfPaused() then
		B3Time_FlowTick = Infinity_GetClockTicks() + 500
		B3Time_TogglePause()
		B3Time_PauseScheduled = true
		B3Time_PauseTick = EEex_GetGameTick() + 1
	end
end

function B3Time_KeyReleasedListener(key)
	if key == B3Time_Key then
		if B3Time_Flowing and not worldScreen:CheckIfPaused() then
			B3Time_TogglePause()
		end
		B3Time_Flowing = false
		B3Time_FlowTick = -1
	end
end

function B3Time_MenuPushListener()
	Infinity_PushMenu("B3Time_Menu")
end
EEex_AddInitGameListener(B3Time_MenuPushListener)

function B3Time_ResetListener()
	EEex_LoadMenuFile("B3_Time")
	EEex_AddKeyPressedListener(B3Time_KeyPressedListener)
	EEex_AddKeyReleasedListener(B3Time_KeyReleasedListener)
end
B3Time_ResetListener()
EEex_AddPostResetListener(B3Time_ResetListener)
EEex_AddPostResetListener(B3Time_MenuPushListener)
