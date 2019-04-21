
function EEex_InstallNewTriggers()

	-- m_compareIdOnly =>
	--     Opcode #101 - IF *NOT* protecting against Opcode #24 (Hardcoded)

	-- m_compareIdAndFlagsOnly =>
	--     Opcode #101 - ONLY IF protecting against Opcode #24 (Hardcoded)
	--     Opcode #169

	-- m_compareIdAndEffectAmountOnly =>
	--     Opcode #267

	-- m_compareIdAndResrefOnly =>
	--     Opcode #296

	local luaTriggerActorName = "EEex_LuaTriggerActorID"
	local luaTriggerActorAddress = EEex_Malloc(#luaTriggerActorName + 1)
	EEex_WriteString(luaTriggerActorAddress, luaTriggerActorName)

	local luaTriggerReturnName = "EEex_LuaTrigger"
	local luaTriggerReturnAddress = EEex_Malloc(#luaTriggerReturnName + 1)
	EEex_WriteString(luaTriggerReturnAddress, luaTriggerReturnName)

	local newTriggersAddress = EEex_WriteAssemblyAuto({[[

		!cmp_eax_dword #103
		!je_dword >EEex_HasDispellableEffect
		!cmp_eax_dword #104
		!je_dword >EEex_LuaTrigger
		!cmp_eax_dword #105
		!je_dword >EEex_IsImmuneToOpcode
		@trigger_failed
		!jmp_dword >CGameAIBase::EvaluateStatusTrigger()_default_label

		@EEex_HasDispellableEffect

		!lea_eax_[ebp+dword] 1C FF FF FF
		!push_eax
		!lea_eax_[ebp+byte] CC
		!push_eax
		!mov_eax_[edi]
		!mov_eax_[eax+dword] A4 00 00 00
		!mov_ecx_edi
		!call_eax

		!mov_edi_[ebp+dword] 1C FF FF FF
		!test_edi_edi
		!je_dword >trigger_failed

		!xor_eax_eax
		!lea_ebx_[eax+byte] 01

		!mov_edx_[edi+dword] #33AC

		!test_edx_edx
		!je_dword >done_timed_effects

		@loop_timed_effects

		!test_eax_eax
		!jne_dword >done_timed_effects

		!mov_ecx_[edx+byte] 08
		!mov_edx_[edx]
		!test_[ecx+byte]_byte 58 01
		!cmovne_eax_ebx

		!test_edx_edx
		!jne_dword >loop_timed_effects

		@done_timed_effects

		!mov_edx_[edi+dword] #3380

		!test_edx_edx
		!je_dword >done_equiped_effects

		@loop_equiped_effects

		!test_eax_eax
		!jne_dword >done_equiped_effects

		!mov_ecx_[edx+byte] 08
		!mov_edx_[edx]
		!test_[ecx+byte]_byte 58 01
		!cmovne_eax_ebx

		!test_edx_edx
		!jne_dword >loop_equiped_effects

		@done_equiped_effects

		!mov_ebx_eax
		!jmp_dword >CGameAIBase::EvaluateStatusTrigger()_success_label


		@EEex_LuaTrigger

		!push_[ebp+byte] F4
		!push_[dword] *_g_lua
		; TODO: Cache Lua chunks ;
		!call >_luaL_loadstring
		!add_esp_byte 08

		!push_[edi+byte] 34
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_dword ]], {luaTriggerActorAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_setglobal
		!add_esp_byte 08

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!push_dword ]], {luaTriggerReturnAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_toboolean
		!add_esp_byte 08

		!mov_ebx_eax

		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08

		!jmp_dword >CGameAIBase::EvaluateStatusTrigger()_success_label


		@EEex_IsImmuneToOpcode

		!lea_eax_[ebp+dword] 1C FF FF FF
		!push_eax
		!lea_eax_[ebp+byte] CC
		!push_eax
		!mov_eax_[edi]
		!mov_eax_[eax+dword] A4 00 00 00
		!mov_ecx_edi
		!call_eax

		!mov_edi_[ebp+dword] 1C FF FF FF
		!test_edi_edi
		!je_dword >trigger_failed

		!xor_eax_eax
		!mov_edx_[edi+dword] #E40

		!test_edx_edx
		!je_dword >done

		!movzx_esi_word:[ebp-byte] D0
		!lea_ebx_[eax+byte] 01

		@loop

		!test_eax_eax
		!jne_dword >done

		!mov_ecx_[edx+byte] 08
		!mov_edx_[edx]
		!cmp_[ecx+byte]_esi 0C
		!cmove_eax_ebx

		!test_edx_edx
		!jne_dword >loop

		@done

		!mov_ebx_eax
		!jmp_dword >CGameAIBase::EvaluateStatusTrigger()_success_label

	]]})

	EEex_DisableCodeProtection()
	EEex_WriteAssembly(EEex_Label("CGameAIBase::EvaluateStatusTrigger()_default_jump"), {{newTriggersAddress, 4, 4}})
	EEex_EnableCodeProtection()
end
EEex_InstallNewTriggers()
