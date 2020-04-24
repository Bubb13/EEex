--[[

This file's hook provides the EEex_IsKeyDown() function, along with two listener functions.
The following function is an example of how a modder could use the keyPressed listener
to make a debug system which changes the currently displayed actionbar configuration
when you press Shift or Ctrl.
(Put the following function either in UI.MENU or a M_*.lua)

B3CurrentActionbarConfig = -1
function B3ActionbarKeyListener(key)
	if key == 0x400000E1 then
		B3CurrentActionbarConfig = B3CurrentActionbarConfig + 1
		Infinity_DisplayString("DEBUG: Actionbar Config => "B3CurrentActionbarConfig
			.." ("toHex(B3CurrentActionbarConfig)..")")
		setActionbarConfig(B3CurrentActionbarConfig)
	elseif key == 0x400000E0 then
		B3CurrentActionbarConfig = B3CurrentActionbarConfig - 1
		Infinity_DisplayString("DEBUG: Actionbar Config => "B3CurrentActionbarConfig
			.." ("toHex(B3CurrentActionbarConfig)..")")
		setActionbarConfig(B3CurrentActionbarConfig)
	end
end
EEex_AddKeyPressedListener(B3ActionbarKeyListener)

--]]

EEex_KeyPressedListeners = {}
EEex_KeyReleasedListeners = {}

function EEex_KeyReset()
	EEex_KeyPressedListeners = {}
	EEex_KeyReleasedListeners = {}
	EEex_AddResetListener(EEex_KeyReset)
end
EEex_AddResetListener(EEex_KeyReset)

EEex_KeysDown = {}

function EEex_KeyPressed(key)
	EEex_KeysDown[key] = true
	for i, func in ipairs(EEex_KeyPressedListeners) do
		func(key)
	end
end

function EEex_KeyReleased(key)
	EEex_KeysDown[key] = false
	for i, func in ipairs(EEex_KeyReleasedListeners) do
		func(key)
	end
end

function EEex_GetKeyFromName(name)
	local nameMem = EEex_Malloc(#name + 1, 23)
	EEex_WriteString(nameMem, name)
	local code = EEex_Call(EEex_Label("SDL_GetKeyFromName"), {nameMem}, nil, 0x4)
	EEex_Free(nameMem)
	return code
end

function EEex_IsKeyDown(key)
	return EEex_KeysDown[key]
end

function EEex_AddKeyPressedListener(func)
	table.insert(EEex_KeyPressedListeners, func)
end

function EEex_AddKeyReleasedListener(func)
	table.insert(EEex_KeyReleasedListeners, func)
end

function EEex_InstallKeyHook()

	local keyPressedHookName = "EEex_KeyPressed"
	local keyPressedHookNameAddress = EEex_Malloc(#keyPressedHookName + 1, 25)
	EEex_WriteString(keyPressedHookNameAddress, keyPressedHookName)

	local keyReleasedHookName = "EEex_KeyReleased"
	local keyReleasedHookNameAddress = EEex_Malloc(#keyReleasedHookName + 1, 26)
	EEex_WriteString(keyReleasedHookNameAddress, keyReleasedHookName)

	local hookAddress = EEex_WriteAssemblyAuto({[[

		!je_dword >SDLHook_NoEvents

		!cmp_[ebp+byte]_dword 8C #300
		!jne_dword >check_1

		!cmp_byte:[ebp+byte] 99 00
		!jne_dword >exit

		!push_dword ]], {keyPressedHookNameAddress, 4}, [[
		!jmp_dword >function_call

		@check_1

		!cmp_[ebp+byte]_dword 8C #301
		!jne_dword >exit

		!push_dword ]], {keyReleasedHookNameAddress, 4}, [[

		@function_call

		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_[ebp+byte] A0
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

		@exit
		!jmp_dword >SDLHook_ResumeExecution

	]]})

	EEex_DisableCodeProtection()
	EEex_WriteAssembly(EEex_Label("SDLHook_NoEventsJump"), {"!jmp_dword", {hookAddress, 4, 4}})
	EEex_WriteAssembly(EEex_Label("SDLHook_AnyMoreEventsJump"), {{hookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallKeyHook()
