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
		Infinity_DisplayString("DEBUG: Actionbar Config => \zB3CurrentActionbarConfig
			.." (\ztoHex(B3CurrentActionbarConfig)..")")
		setActionbarConfig(B3CurrentActionbarConfig)
	elseif key == 0x400000E0 then
		B3CurrentActionbarConfig = B3CurrentActionbarConfig - 1
		Infinity_DisplayString("DEBUG: Actionbar Config => \zB3CurrentActionbarConfig
			.." (\ztoHex(B3CurrentActionbarConfig)..")")
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
	local keyPressedHookNameAddress = EEex_Malloc(#keyPressedHookName + 1)
	EEex_WriteString(keyPressedHookNameAddress, keyPressedHookName)
	local keyReleasedHookName = "EEex_KeyReleased"
	local keyReleasedHookNameAddress = EEex_Malloc(#keyReleasedHookName + 1)
	EEex_WriteString(keyReleasedHookNameAddress, keyReleasedHookName)
	local hookAddress = EEex_WriteAssemblyAuto({
		"0F 84 :792816 \z
		81 7D 8C 00 03 00 00 75 0D 80 7D 99 00 75 55 \z
		68", {keyPressedHookNameAddress, 4},
		"EB 0E 81 7D 8C 01 03 00 00 75 45 \z
		68", {keyReleasedHookNameAddress, 4},
		"FF 35 0C 01 94 00 \z
		E8 >_lua_getglobal \z
		83 C4 08 FF 75 A0 DB 04 24 83 EC 04 DD 1C 24 FF 35 0C 01 94 00 \z
		E8 >_lua_pushnumber \z
		83 C4 0C 6A 00 6A 00 6A 00 6A 00 6A 01 FF 35 0C 01 94 00 \z
		E8 >_lua_pcallk \z
		83 C4 18 \z
		E9 :791BF2"
	})
	EEex_DisableCodeProtection()
	EEex_WriteAssembly(0x791BEC, {"E9", {hookAddress, 4, 4}})
	EEex_WriteAssembly(0x792812, {{hookAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallKeyHook()
