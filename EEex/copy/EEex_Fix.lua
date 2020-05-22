
function EEex_InstallFixes()

	EEex_DisableCodeProtection()

	---------------------------------------------------------------------------------------
	-- Triggers with IDS values below 0x4000 should work correctly with object selectors --
	---------------------------------------------------------------------------------------

	local triggersObjectSelectorFix = EEex_WriteAssemblyAuto({[[

		!add_esp_byte 04
		!push_ebx

		!push_dword #65 ; callerID ;
		!push_byte 30
		!call >_malloc
		!add_esp_byte 8
		!mov_ebx_eax

		!push_byte 00
		!push_byte 00
		!mov_ecx_ebx
		!call >CAITrigger::CAITrigger

		!push_edi
		!mov_ecx_ebx
		!call >CAITrigger::operator_equ

		!push_[ebp+byte] 10
		!lea_ecx_[ebx+byte] 08
		!call >CAIObjectType::Decode

		!mov_ecx_[esi+byte] 08
		!mov_esi_[esi]
		!push_ebx
		!call >CAITrigger::OfType
		!push_eax

		!mov_ecx_ebx
		!call >CAITrigger::~CAITrigger

		!push_ebx
		!call >_SDL_free
		!add_esp_byte 04

		!pop_eax
		!pop_ebx
		!jmp_dword >CAICondition::TriggerHolds()_FixResume

	]]})
	EEex_WriteAssembly(EEex_Label("CAICondition::TriggerHolds()_FixHook"), {"!jmp_dword", {triggersObjectSelectorFix, 4, 4}})

	------------------------------------------------------------------------
	-- Opcode #233 should not crash when incrementing halberd proficiency --
	------------------------------------------------------------------------

	EEex_WriteAssembly(EEex_Label("Opcode233FixHalberdIncrement"), {"!lea_esi_[ecx+dword] #1E98 !nop !nop !nop !nop !nop !nop"})

	----------------------------------------------------------
	-- Pausing the game should not break effect application --
	----------------------------------------------------------

	local fixPauseAddress = EEex_Label("CGameSprite::AddEffect()_FixPause")
	local fixPauseJmpDest = fixPauseAddress + EEex_ReadByte(fixPauseAddress + 0x1, 0) + 0x2
	local fixPause = EEex_WriteAssemblyAuto({[[

		; Game Paused ;
		!jne_dword ]], {fixPauseJmpDest, 4, 4}, [[

		; Immediate Resolve ;
		!test_ebx_ebx
		!jz_dword ]], {fixPauseJmpDest, 4, 4}, [[

		; Source Type Item ;
		!cmp_[edi+dword]_byte #8C 02
		!jne_dword ]], {fixPauseJmpDest, 4, 4}, [[
		!jmp_dword ]], {fixPauseAddress + 0x6, 4, 4},
	})
	EEex_WriteAssembly(fixPauseAddress, {"!jmp_dword", {fixPause, 4, 4}, "!nop"})

	-------------------------------------------------------------------------------------------------------------
	-- Infinity_OnPortraitLClick() should internally set currentID, (NOT id), before calling updateAttrTable() --
	-------------------------------------------------------------------------------------------------------------

	EEex_HookAfterCall(EEex_Label("Infinity_OnPortraitLClick()_GlobalFixHook"), {[[

		!mov_ecx_[ebp+byte] FC
		!push_[ecx+byte] 34
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_dword ]], {EEex_WriteStringAuto("currentID"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_setglobal
		!add_esp_byte 08
	]]})

	EEex_EnableCodeProtection()
end
EEex_InstallFixes()
