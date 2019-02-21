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

	local hookAddress = EEex_WriteAssemblyAuto({[[

		!mov_eax_[ebp+byte] 08
		!dec_eax
		!cmp_eax_byte 71
		!ja_dword >UpdateButtons

		!movzx_eax_byte:[eax+dword] *CInfButtonArray::SetState()_IndirectJumpTable
		!push_eax

		!push_dword ]], {hookNameAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

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

		@UpdateButtons
		!mov_ecx_edi
		!call >CInfButtonArray::UpdateButtons
		!jmp_dword >CInfButtonArray::SetState()_AfterUpdate
	]]})

	local hookData = EEex_Malloc(0xC)
	local fixSpecial = EEex_WriteAssemblyAuto({[[

		!mov_eax_[ebp+byte] 04
		!mov_[dword]_eax ]], {hookData, 4}, [[
		!mov_eax_[esi+dword] #1478
		!mov_[dword]_eax ]], {hookData + 0x4, 4}, [[
		!mov_[dword]_esi ]], {hookData + 0x8, 4}, [[
		!mov_[ebp+byte]_dword 04 *resume
		!jmp_dword >CInfButtonArray::SetState()_NormalPath

		@resume
		!push_[dword] ]], {hookData + 0x4, 4}, [[
		!mov_ecx_[dword] ]], {hookData + 0x8, 4}, [[
		!mov_[ecx+dword]_dword #1608 #0A
		!call >CInfButtonArray::SetState
		!jmp_[dword] ]], {hookData, 4},
	})

	EEex_DisableCodeProtection()

	EEex_WriteAssembly(EEex_Label("CInfButtonArray::SetState()_BeforeUpdate"), {"!jmp_dword", {hookAddress, 4, 4}})
	EEex_WriteAssembly(EEex_Label("CInfButtonArray::OnLButtonPressed()_MainSwitchTable") + 16, {{fixSpecial, 4}})

	EEex_EnableCodeProtection()
end
EEex_InstallActionbarHook()
