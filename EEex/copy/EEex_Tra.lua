
(function()

	EEex_DisableCodeProtection()

	local triggerSetCursorHookAddress = EEex_Label("CGameTrigger::SetCursor()_TrapHook")
	local triggerSetCursorDefault = triggerSetCursorHookAddress + EEex_ReadByte(triggerSetCursorHookAddress + 0x9, 0) + 0xA
	EEex_HookRestore(triggerSetCursorHookAddress, 0, 8, {[[

		!push_all_registers

		!cmp_eax_byte 14 ; Targeting Spell Icon ;
		!je_dword >check_spell_cursor

		@fail
		!pop_all_registers
		!jmp_dword >return

		@check_spell_cursor

		!cmp_word:[ecx+dword]_byte #3FC 00
		!jne_dword >fail
		!cmp_word:[ecx+dword]_byte #478 00
		!je_dword >fail
		!cmp_word:[ecx+dword]_byte #47A 00
		!je_dword >fail

		!push_byte FF
		!push_byte 00
		!push_byte 14
		!mov_ecx_[edx+dword] *CBaldurChitin::m_pObjectCursor
		!call >CInfCursor::SetCursor

		!pop_all_registers
		!jmp_dword ]], {triggerSetCursorDefault, 4, 4},

	})

	local triggerOnCursorActionHookAddress = EEex_Label("CGameTrigger::OnActionButton()_TrapHook")
	local triggerOnCursorActionDefault = triggerOnCursorActionHookAddress + EEex_ReadSignedByte(triggerOnCursorActionHookAddress + 0x6, 0) + 0x7
	EEex_HookRestore(triggerOnCursorActionHookAddress, 0, 5, {[[

		!push_all_registers
		!add_eax_byte 0C

		!cmp_eax_byte 14 ; Targetting Spell Icon ;
		!je_dword >do_cast_magic
		!pop_all_registers
		!jmp_dword >return

		@do_cast_magic
		!push_[esi+byte] 34
		!mov_ecx_edi
		!call >CInfGame::UseMagicOnObject

		!push_byte 00
		!push_byte 00
		!mov_ecx_edi
		!call >CInfGame::SetState

		!mov_[edi+dword]_dword #3C5C #64
		!lea_ecx_[edi+dword] #2654
		!call >CInfButtonArray::UpdateState

		!pop_all_registers
		!jmp_dword ]], {triggerOnCursorActionDefault, 4, 4},

	})

	EEex_HookAfterRestore(EEex_Label("CGameTrigger::IsOver()_TrapHook"), 0, 7, {[[
		!je_dword >return
		!cmp_byte:[eax+dword]_byte #2560 14
	]]})

	EEex_HookAfterRestore(EEex_Label("CGameTrigger::Render()_TrapHook"), 0, 7, {[[
		!je_dword >return
		!cmp_byte:[edx+dword]_byte #2560 14
	]]})

	EEex_HookAfterRestore(EEex_Label("CGameTrigger::AddEffect()_InvokeLuaHook"), 0, 5, {[[
		!je_dword >return
		!cmp_eax_dword #192
		!jne_dword >return
		!push_edi
		!push_ebx
		!call >EEex_InvokeLua
	]]})

	EEex_WriteAssembly(EEex_Label("CGameDoor::IsOver()_TrapHook"), {"!jmp_byte"})
	EEex_WriteAssembly(EEex_Label("CGameDoor::Render()_TrapHook"), {"!jmp_byte"})

	EEex_HookAfterRestore(EEex_Label("CGameDoor::AddEffect()_InvokeLuaHook"), 0, 5, {[[
		!je_dword >return
		!cmp_eax_dword #192
		!jne_dword >return
		!push_ebx
		!push_edi
		!call >EEex_InvokeLua
	]]})

	EEex_HookAfterRestore(EEex_Label("CGameContainer::AddEffect()_InvokeLuaHook"), 0, 5, {[[
		!je_dword >return
		!cmp_eax_dword #192
		!jne_dword >return
		!push_edi
		!push_ebx
		!call >EEex_InvokeLua
	]]})

	EEex_EnableCodeProtection()

end)()
