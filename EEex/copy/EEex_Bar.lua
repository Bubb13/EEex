--[[

The following function is an example of how a modder could use this file's
hook to dynamically change an Inquisitor's useless Turn Undead button for
Bard Song.
(Put the following function either in UI.MENU or a M_*.lua)

function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if
       config == 0x5
       and getActorClass(actorID) == 0x6
       and getActorKit(actorID) == 0x4005
    then
        setActionbarButton(0x5, ACTIONBAR_TYPE.BARD_SONG)
    end
end
EEex_AddActionbarListener(B3ActionbarListener)

--]]

EEex_ActionbarListeners = {}

EEex_AddResetListener(function()
	EEex_ActionbarListeners = {}
end)

function EEex_AddActionbarListener(func)
	table.insert(EEex_ActionbarListeners, func)
end

function EEex_HookActionbar(config)
	for i, func in ipairs(EEex_ActionbarListeners) do
		func(config)
	end
end

function EEex_InstallActionbarHook()

	local hookName = "EEex_HookActionbar"
	local hookNameAddress = EEex_Malloc(#hookName + 1)
	EEex_WriteString(hookNameAddress, hookName)
	local hookAddress = EEex_WriteAssemblyAuto({
		"8B 45 08 48 83 F8 71 77 4A 0F B6 80 0C 98 61 00 50 \z
		68", {hookNameAddress, 4},
		"FF 35 0C 01 94 00 \z
		E8 >_lua_getglobal \z
		83 C4 08 DB 04 24 83 EC 04 DD 1C 24 FF 35 0C 01 94 00 \z
		E8 >_lua_pushnumber \z
		83 C4 0C 6A 00 6A 00 6A 00 6A 00 6A 01 FF 35 0C 01 94 00 \z
		E8 >_lua_pcallk \z
		83 C4 18 8B CF \z
		E8 >CInfButtonArray::UpdateButtons \z
		E9 :619778"
	})

	local hookData = EEex_Malloc(0xC)
	local fixSpecial = EEex_WriteAssemblyAuto({
		"8B 45 04 \z
		A3", {hookData, 4},
		"8B 86 78 14 00 00 \z
		A3", {hookData + 0x4, 4},
		"89 35", {hookData + 0x8, 4},
		"C7 45 04 *resume \z
		E9 :61663D \z
		@resume \z
		FF 35", {hookData + 0x4, 4},
		"8B 0D", {hookData + 0x8, 4},
		"C7 81 08 16 00 00 0A 00 00 00 \z
		E8 >CInfButtonArray::SetState \z
		FF 25", {hookData, 4}
	})

	EEex_DisableCodeProtection()

	EEex_WriteAssembly(0x619771, {"E9", {hookAddress, 4, 4}})
	EEex_WriteAssembly(0x61716C, {{fixSpecial, 4}})

	EEex_EnableCodeProtection()
end
EEex_InstallActionbarHook()
