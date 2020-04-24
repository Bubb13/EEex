
EEexL_PermanentCallerIDs = {
	[39] = true,
}

EEexL_MallocAddresses = {}

function EEexL_MallocWrapper(address, callerID)
	EEexL_MallocAddresses[address] = {
		["callerID"] = callerID,
		["tickAllocated"] = Infinity_GetClockTicks(),
		["alreadySeen"] = false,
	}
end

function EEexL_FreeWrapper(address)
	EEexL_MallocAddresses[address] = nil
end

function EEexL_DetectLeaks()

	local oldMallocAddress = EEex_Label("_malloc")
	EEex_DefineAssemblyLabel("_oldmalloc", oldMallocAddress)

	local mallocWrapper = EEex_WriteAssemblyAuto({[[

		!push_state

		!push_dword ]], {EEex_WriteStringAuto("EEexL_MallocWrapper"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_[ebp+byte] 08
		!call >_oldmalloc
		!add_esp_byte 04
		!push_eax

		!push_eax
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_[ebp+byte] 0C
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 02
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!pop_eax
		!pop_state
		!ret

	]]})

	EEex_DisableCodeProtection()
	EEex_HookAfterCall(EEex_Label("_SDL_free"), {[[

		!push_state

		!push_dword ]], {EEex_WriteStringAuto("EEexL_FreeWrapper"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_[ebp+byte] 08
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!pop_state
		!ret

	]]})
	EEex_EnableCodeProtection()

	EEex_DefineAssemblyLabel("_malloc", mallocWrapper)

end
EEexL_DetectLeaks()

EEexL_LastCheckTick = 0
function EEexL_Tick()
	local clockTick = Infinity_GetClockTicks()
	if clockTick >= EEexL_LastCheckTick + 5000 then
		EEexL_LastCheckTick = clockTick
		for address, entry in pairs(EEexL_MallocAddresses) do
			if (not EEexL_PermanentCallerIDs[entry.callerID]) and (not entry.alreadySeen) then
				if clockTick >= entry.tickAllocated + 10000 then
					entry.alreadySeen = true
					print("Possible memory leak by "..entry.callerID.." at "..EEex_ToHex(address))
				end
			end
		end
	end
	return false
end

function EEexL_MenuPushListener()
	Infinity_PushMenu("EEexL_Menu")
end
EEex_AddInitGameListener(EEexL_MenuPushListener)

function EEexL_ResetListener()
	EEex_LoadMenuFile("EEexL")
end
EEexL_ResetListener()
EEex_AddPostResetListener(EEexL_ResetListener)
EEex_AddPostResetListener(EEexL_MenuPushListener)
