
-- Final step in Opcode #403 mechanics. If it becomes apparent
-- that running this logic in Lua is too slow, it can be rewritten
-- in assembly.
function EEex_HookCheckAddScreen(effectData, creatureData)

	local newStats = nil
	if EEex_ReadDword(creatureData + 0x3748) == 0x0 then
		newStats = EEex_ReadDword(creatureData + 0x3B1C)
	else
		newStats = EEex_ReadDword(creatureData + 0x3B18)
	end

	local actorID = EEex_GetActorIDShare(creatureData)
	local screenList = EEex_AccessComplexStat(actorID, "EEex_ScreenEffectsList")

	local foundImmunity = false
	EEex_IterateCPtrList(screenList, function(screenElement)

		local originatingEffectData = EEex_ReadDword(screenElement + 0x0)
		local functionName = EEex_ReadString(EEex_ReadDword(screenElement + 0x4))
		local immunityFunction = _G[functionName]

		if immunityFunction and immunityFunction(originatingEffectData, effectData, creatureData) then
			foundImmunity = true
			return true
		end
	end)

	if foundImmunity then
		return true
	end
end

function EEex_InstallOpcodeChanges()

	EEex_DisableCodeProtection()

	---------------------------------------------------------------------
	-- Opcode #42 (Non-zero Special bypasses "at least 1 slot" checks) --
	---------------------------------------------------------------------

	local opcode42WriteHook = function(address)
		local opcode42JumpDest = address + EEex_ReadByte(address + 0x3, 1) + 0x5
		local opcode42CheckSpecial = EEex_WriteAssemblyAuto({[[
			!mov_eax_[edx+byte] 44
			!test_eax_eax
			!jnz_dword >skip_check
			!test_si_si
			!jz_dword ]], {opcode42JumpDest, 4, 4}, [[
			@skip_check
			!jmp_dword ]], {address + 0x5, 4, 4},
		})
		EEex_WriteAssembly(address, {"!jmp_dword", {opcode42CheckSpecial, 4, 4}})
	end

	opcode42WriteHook(EEex_Label("Opcode42DisableCheck1"))
	opcode42WriteHook(EEex_Label("Opcode42DisableCheck2"))
	opcode42WriteHook(EEex_Label("Opcode42DisableCheck3"))
	opcode42WriteHook(EEex_Label("Opcode42DisableCheck4"))
	opcode42WriteHook(EEex_Label("Opcode42DisableCheck5"))
	opcode42WriteHook(EEex_Label("Opcode42DisableCheck6"))
	opcode42WriteHook(EEex_Label("Opcode42DisableCheck7"))
	opcode42WriteHook(EEex_Label("Opcode42DisableCheck8"))

	local opcode42LastJumpAddress = EEex_Label("Opcode42DisableCheck9")
	local opcode42LastJumpDest = opcode42LastJumpAddress + EEex_ReadDword(opcode42LastJumpAddress + 0x5) + 0x9
	local opcode42LastCheckSpecial = EEex_WriteAssemblyAuto({[[
		!mov_eax_[edx+byte] 44
		!test_eax_eax
		!jnz_dword >skip_check
		!test_si_si
		!jz_dword ]], {opcode42LastJumpDest, 4, 4}, [[
		@skip_check
		!jmp_dword ]], {opcode42LastJumpAddress + 0x9, 4, 4},
	})
	EEex_WriteAssembly(opcode42LastJumpAddress, {"!jmp_dword", {opcode42LastCheckSpecial, 4, 4}, "!nop !nop !nop !nop"})

	---------------------------------------------------------------------
	-- Opcode #62 (Non-zero Special bypasses "at least 1 slot" checks) --
	---------------------------------------------------------------------

	local opcode62WriteHook = function(address)
		local opcode62JumpDest = address + EEex_ReadByte(address + 0x3, 1) + 0x5
		local opcode62CheckSpecial = EEex_WriteAssemblyAuto({[[
			!mov_eax_[edx+byte] 44
			!test_eax_eax
			!jnz_dword >skip_check
			!test_si_si
			!jz_dword ]], {opcode62JumpDest, 4, 4}, [[
			@skip_check
			!jmp_dword ]], {address + 0x5, 4, 4},
		})
		EEex_WriteAssembly(address, {"!jmp_dword", {opcode62CheckSpecial, 4, 4}})
	end

	opcode62WriteHook(EEex_Label("Opcode62DisableCheck1"))
	opcode62WriteHook(EEex_Label("Opcode62DisableCheck2"))
	opcode62WriteHook(EEex_Label("Opcode62DisableCheck3"))
	opcode62WriteHook(EEex_Label("Opcode62DisableCheck4"))
	opcode62WriteHook(EEex_Label("Opcode62DisableCheck5"))
	opcode62WriteHook(EEex_Label("Opcode62DisableCheck6"))

	local opcode62LastJumpAddress = EEex_Label("Opcode62DisableCheck7")
	local opcode62LastJumpDest = opcode62LastJumpAddress + EEex_ReadDword(opcode62LastJumpAddress + 0x5) + 0x9
	local opcode62LastCheckSpecial = EEex_WriteAssemblyAuto({[[
		!mov_eax_[edx+byte] 44
		!test_eax_eax
		!jnz_dword >skip_check
		!test_si_si
		!jz_dword ]], {opcode62LastJumpDest, 4, 4}, [[
		@skip_check
		!jmp_dword ]], {opcode62LastJumpAddress + 0x9, 4, 4},
	})
	EEex_WriteAssembly(opcode62LastJumpAddress, {"!jmp_dword", {opcode62LastCheckSpecial, 4, 4}, "!nop !nop !nop !nop"})

	--------------------------------------------------
	-- Opcode #218 (Fire subspell when layers lost) --
	--------------------------------------------------

	local fireSubspellAddress = EEex_WriteAssemblyAuto({[[

		!build_stack_frame
		!sub_esp_byte 0C
		!push_all_registers

		!mov_esi_ecx

		!lea_edi_[esi+byte] 2C
		!mov_ecx_edi
		!call >CResRef::IsValid

		!test_eax_eax
		!jne_dword >fire_spell

		!push_dword *aB_1
		!lea_eax_[ebp+byte] F8
		!push_eax
		!lea_ecx_[esi+dword] #90
		!call >CResRef::GetResRefStr
		!push_eax
		!lea_eax_[ebp+byte] F4
		!push_eax
		!call >(CString)_operator+
		!add_esp_byte 0C
		!mov_ecx_edi
		!push_eax
		!lea_eax_[ebp+byte] FC
		!push_eax
		!call >CResRef::operator_equ
		!lea_ecx_[ebp+byte] F4
		!call >CString::~CString
		!lea_ecx_[ebp+byte] F8
		!call >CString::~CString

		@fire_spell

		!push_[esi+dword] #10C
		!mov_ecx_esi
		!push_[esi+dword] #C4
		!push_byte 00
		!push_[ebp+byte] 08
		!push_edi
		!call >CGameEffect::FireSpell
		!mov_[esi+dword]_dword #110 #01

		!pop_all_registers
		!destroy_stack_frame
		!ret_word 04 00

	]]})

	local fireSubspellHook1 = EEex_WriteAssemblyAuto({[[
		!push_complete_state
		!push_esi
		!mov_ecx_edi
		!call ]], {fireSubspellAddress, 4, 4}, [[
		!pop_complete_state
		!ret
	]]})

	EEex_WriteAssembly(EEex_Label("Opcode218LostLayersHook"), {"!call", {fireSubspellHook1, 4, 4}, "!nop !nop !nop !nop !nop"})

	----------------------------------------------
	-- Opcode #280 (Param1 overrides surge num) --
	----------------------------------------------

	local opcode280Override = EEex_Label("Opcode280Override")
	local opcode280Surge = EEex_WriteAssemblyAuto({[[
		!mov_[eax+dword]_edx #D58
		!mov_edx_[ecx+byte] 18 ; Param1 (Surge Override) ;
		!test_edx_edx
		!jz_dword >skip_num_override
		!mov_edi_[eax+dword] #3B18
		!mov_[edi+dword]_edx #184
		@skip_num_override
		!mov_edx_[ecx+byte] 44 ; Special (Suppress Graphics) ;
		!test_edx_edx
		!jz_dword >ret
		!mov_edi_[eax+dword] #3B18
		!mov_[edi+dword]_edx #188
		@ret
		!jmp_dword ]], {opcode280Override + 0x6, 4, 4},
	})
	EEex_WriteAssembly(opcode280Override, {"!jmp_dword ", {opcode280Surge, 4, 4}, "!nop"})

	local overrideJump = EEex_Label("WildSurgeOverride")
	local wildSurgeOverride = EEex_WriteAssemblyAuto({[[
		!push_dword #12C
		!mov_ecx_edi
		!call >EEex_AccessStat
		!test_eax_eax
		!cmovnz_ebx_eax
		!cmp_[ebp+dword]_byte #FFFFFB08 00
		!jmp_dword ]], {overrideJump + 0x7, 4, 4},
	})
	EEex_WriteAssembly(overrideJump, {"!jmp_dword ", {wildSurgeOverride, 4, 4}, "!nop !nop"})

	-- NOP 0x7435B9
		-- REASON: (Disables Feedback String)
		-- HOW: (add esp,0x1C  and  NOP*2)
		-- REQUIRED FIXES: (None)

	local wildSurgeFeedbackAddress = EEex_Label("WildSurgeFeedback")
	local opcode280Feedback = EEex_WriteAssemblyAuto({[[
		!push_dword #12D
		!call >EEex_AccessStat
		!test_eax_eax
		!jnz_dword >skip_feedback
		!call >CGameSprite::FeedBack
		!jmp_dword >ret
		@skip_feedback
		!add_esp_byte 1C
		@ret
		!jmp_dword ]], {wildSurgeFeedbackAddress + 0x5, 4, 4},
	})
	EEex_WriteAssembly(wildSurgeFeedbackAddress, {"!jmp_dword ", {opcode280Feedback, 4, 4}})

	-- Force 0x743608 - (Disables Random Visual Effect)

	local wildSurgeVisualJump = EEex_Label("WildSurgeSkipRandomVisual")
	local opcode280Visual = EEex_WriteAssemblyAuto({[[
		!push_dword #12D
		!mov_ecx_edi
		!call >EEex_AccessStat
		!test_eax_eax
		!jz_dword >normal_execution
		; Set the ZF manually ;
		!xor_eax_eax
		!jmp_dword >ret
		@normal_execution
		!cmp_[ebp+dword]_byte #FFFFFB50 00
		@ret
		!ret
	]]})
	EEex_WriteAssembly(wildSurgeVisualJump, {"!call", {opcode280Visual, 4, 4}, "!nop !nop"})

	-- NOP 0x744132
		-- REASON: (Prevents SPFLESHS From Loading)
		-- HOW: (NOP*4),
		-- REQUIRED FIXES: (Free "name" CString)

	local wildSurgeSwirlLoadAddress = EEex_Label("WildSurgeSkipSwirlLoad")
	local opcode280SwirlLoad = EEex_WriteAssemblyAuto({[[
		!push_dword #12D
		!mov_ecx_edi
		!call >EEex_AccessStat
		!test_eax_eax
		!jnz_dword >skip_swirl
		!call >CVisualEffect::Load
		!jmp_dword >ret
		@skip_swirl
		!mov_ecx_esp
		!call >CString::~CString
		@ret
		!jmp_dword ]], {wildSurgeSwirlLoadAddress + 0x5, 4, 4},
	})
	EEex_WriteAssembly(wildSurgeSwirlLoadAddress, {"!jmp_dword ", {opcode280SwirlLoad, 4, 4}})

	-- NOP 0x744207
		-- REASON: (Prevents SPFLESHS From Being Sent To Multiplayer)
		-- HOW: (add esp,0x8  and  NOP*2),
		-- REQUIRED FIXES: (None)

	local wildSurgeSwirlSendAddress = EEex_Label("WildSurgeSkipSwirlSend")
	local opcode280SwirlSend = EEex_WriteAssemblyAuto({[[
		!push_dword #12D
		!mov_ecx_[esp+byte] 10
		!call >EEex_AccessStat
		!test_eax_eax
		!jnz_dword >skip_swirl
		!call >CMessageHandler::AddMessage
		!jmp_dword >ret
		@skip_swirl
		!add_esp_byte 08
		@ret
		!jmp_dword ]], {wildSurgeSwirlSendAddress + 0x5, 4, 4},
	})
	EEex_WriteAssembly(wildSurgeSwirlSendAddress, {"!jmp_dword ", {opcode280SwirlSend, 4, 4}})

	-------------------------------------------
	-- Opcode #319 (Implement SPLPROT Modes) --
	-------------------------------------------

	-- Documentation:
	--     Power =>
	--         2 => SPLPROT Enabled
	--         3 => SPLPROT Enabled (Inverted)
	--
	--     Param1 => SPLPROT Value
	--     Param2 => SPLPROT Row

	local opcode319DoSplprotCheck = EEex_WriteAssemblyAuto({[[

		!build_stack_frame
		!sub_esp_byte 04
		!push_registers

		!mov_esi_ecx
		!mov_[ebp+byte]_dword FC #0
		!xor_edi_edi
		!mov_eax_[esi+dword] #10C
		!cmp_eax_byte FF
		!jz_dword >do_test
		!lea_ecx_[ebp+byte] FC
		!push_ecx ; ptr ;
		!push_eax ; index ;
		!call >CGameObjectArray::GetShare
		!add_esp_byte 08
		!test_al_al
		!jnz_dword >do_test
		!mov_ecx_[ebp+byte] FC
		!mov_eax_[ecx]
		!mov_eax_[eax+byte] 04
		!call_eax
		!mov_edi_[ebp+byte] FC
		!xor_ecx_ecx
		!cmp_al_[dword] *CGameObject::TYPE_SPRITE
		!cmovnz_edi_ecx

		@do_test

		!push_[esi+byte] 18 ; value ;
		!mov_eax_[dword] *g_pBaldurChitin
		!push_edi ; mine ;
		!mov_edi_[ebp+byte] 08
		!push_edi ; stats ;
		!push_[esi+byte] 1C ; nRow ;
		!mov_ecx_[eax+dword] *CBaldurChitin::m_pObjectGame ; this ;
		!call >CRuleTables::IsProtectedFromSpell

		!pop_registers
		!destroy_stack_frame
		!ret_word 04 00
	]]})

	local opcode319DefaultJump = EEex_Label("IsProtectedFromSpell()_defaultJump")
	local opcode319DefaultJumpDest = opcode319DefaultJump + EEex_ReadDword(opcode319DefaultJump + 0x2) + 0x6

	local opcode319CleanupJump = EEex_Label("IsProtectedFromSpell()_cleanupJump")
	local opcode319CleanupJumpDest = opcode319CleanupJump + EEex_ReadByte(opcode319CleanupJump, 0) + 1

	local opcode319DefaultOverride = EEex_WriteAssemblyAuto({[[
		!cmp_[esi+byte]_byte 14 02
		!je_dword >do_splprot
		!cmp_[esi+byte]_byte 14 03
		!je_dword >do_splprot

		!cmp_eax_byte 09
		!ja_dword ]], {opcode319DefaultJumpDest, 4, 4}, [[
		!jmp_dword ]], {opcode319DefaultJump + 0x6, 4, 4}, [[

		@do_splprot
		!push_[ebp+byte] 08 ; pSprite ;
		!mov_ecx_esi
		!call ]], {opcode319DoSplprotCheck, 4, 4}, [[

		!cmp_[esi+byte]_byte 14 03
		!jne_dword >return

		!test_eax_eax
		!mov_eax #0
		!setz_al

		@return
		!mov_ebx_eax
		!jmp_dword ]], {opcode319CleanupJumpDest, 4, 4},
	})

	local opcode319TextJump = EEex_Label("GetUsabilityText()_typeJump")
	local opcode319TextJumpDest = opcode319TextJump + EEex_ReadByte(opcode319TextJump, 0) + 1
	local opcode319TextOverride = EEex_WriteAssemblyAuto({[[
		!push_eax
		!cmp_[ecx+byte]_byte 14 02
		!je_dword >direct

		!cmp_[ecx+byte]_byte 14 01
		!jne_dword ]], {opcode319TextJumpDest, 4, 4}, [[

		@direct
		!jmp_dword ]], {opcode319TextJump + 0x1, 4, 4},
	})

	EEex_WriteAssembly(EEex_Label("GetUsabilityText()_compareLoc"), {"!jmp_dword", {opcode319TextOverride, 4, 4}})
	EEex_WriteAssembly(opcode319DefaultJump, {"!jmp_dword", {opcode319DefaultOverride, 4, 4}, "!nop"})

	-----------------------------------------
	-- Opcode #324 (Set strref to Special) --
	-----------------------------------------

	local opcode324StrrefOverride = EEex_WriteAssemblyAuto({[[
		!mov_edi_[esi+byte] 44
		!test_edi_edi
		!jnz_dword >ret
		!mov_edi #0F00080
		!cmp_eax_dword #109
		@ret
		!ret
	]]})
	EEex_WriteAssembly(EEex_Label("Opcode324StrrefHook"), {"!call", {opcode324StrrefOverride, 4, 4}})

	-----------------------------------
	-- New Opcode #400 (SetAIScript) --
	-----------------------------------

	local setAIScript = EEex_WriteAssemblyAuto({[[

		!push_state
		!mov_esi_ecx

		!push_dword *NullString
		!call >CResRef::operator_notequ

		!test_eax_eax
		!je_dword >no_script

		!push_byte 24
		!call >operator_new
		!add_esp_byte 04

		!test_eax_eax
		!je_dword >no_script

		!push_byte 00
		!mov_ecx_[ebp+byte] 08
		!push_[ecx+byte] 04
		!push_[ecx]

		!mov_ecx_eax
		!call >CAIScript::CAIScript
		!jmp_dword >new_script

		@no_script
		!xor_eax_eax

		@new_script

		!push_eax
		!push_[ebp+byte] 0C
		!mov_ecx_esi

		!mov_eax_[esi]
		!call_[eax+dword] #90

		!pop_state
		!ret_word 08 00

	]]})

	local newOpcode400 = EEex_WriteOpcode({

		["ApplyEffect"] = {[[

			!push_state

			!mov_esi_ecx

			!cmp_[esi+dword]_byte #C8 00
			!je_dword >do_nothing

			!mov_[esi+dword]_dword #C8 #00

			!movzx_eax_word:[esi+byte] 1C
			!cmp_eax_byte 07
			!ja_dword >do_nothing

			!cmp_eax_byte 04
			!jb_dword >do_lookup

			!dec_eax

			@do_lookup

			!mov_ecx_[ebp+byte] 08
			!lea_ecx_[ecx+eax*4+dword] #268
			!mov_ecx_[ecx]
			!test_ecx_ecx
			!je_dword >undefined_script

			!mov_eax_[ecx]
			!mov_[esi+byte]_eax 6C
			!mov_eax_[ecx+byte] 04
			!mov_[esi+byte]_eax 70
			!jmp_dword >defined_script

			@undefined_script

			!mov_[esi+byte]_dword 6C #00
			!mov_[esi+byte]_dword 70 #00

			@defined_script

			!movzx_eax_word:[esi+byte] 1C
			!push_eax
			!lea_eax_[esi+byte] 2C
			!push_eax
			!mov_ecx_[ebp+byte] 08
			!call ]], {setAIScript, 4, 4}, [[

			@do_nothing

			!pop_state
			!ret_word 04 00

		]]},

		["OnRemove"] = {[[

			!push_state

			!mov_esi_ecx

			!movzx_eax_word:[esi+byte] 1C
			!push_eax
			!lea_eax_[esi+byte] 6C
			!push_eax
			!mov_ecx_[ebp+byte] 08
			!call ]], {setAIScript, 4, 4}, [[

			!pop_state
			!ret_word 04 00

		]]},
	})

	----------------------------------
	-- New Opcode #401 (SetNewStat) --
	----------------------------------

	local EEex_SetNewStat = EEex_WriteOpcode({

		["ApplyEffect"] = {[[

			!build_stack_frame
			!push_registers

			!mov_esi_ecx
			!mov_edi_[esi+byte] 44 ; Special (Stat Num) ;
			!mov_ecx_[ebp+byte] 08 ; CGameSprite ;

			!sub_edi_dword #CB
			!cmp_edi_dword ]], {EEex_NewStatsCount, 4}, [[
			!jae_dword >ret

			!mov_ecx_[ecx+dword] #3B18
			!mov_eax_[esi+byte] 1C ; Param2 (Type) ;

			!sub_eax_byte 00
			!jz_dword >type_cumulative
			!dec_eax
			!jz_dword >type_flat
			!dec_eax
			!jnz_dword >ret

			@type_percentage
			!mov_edx_[ecx+edi*4]
			!imul_edx_[esi+byte] 18
			!mov_eax #51EB851F ; Magic number for division by 100 ;
			!imul_edx
			!sar_edx 05
			!mov_eax_edx
			!shr_eax 1F
			!add_edx_eax
			!jmp_dword >set_stat

			@type_cumulative
			!mov_edx_[ecx+edi*4]
			!add_edx_[esi+byte] 18 ; Param1 (Statistic Modifier) ;
			!jmp_dword >set_stat

			@type_flat
			!mov_edx_[esi+byte] 18 ; Param1 (Statistic Modifier) ;

			@set_stat
			!mov_[ecx+edi*4]_edx

			@ret
			!mov_eax #1
			!restore_stack_frame
			!ret_word 04 00
		]]},
	})

	---------------------------------
	-- New Opcode #402 (InvokeLua) --
	---------------------------------

	local EEex_InvokeLua = EEex_WriteOpcode({

		["ApplyEffect"] = {[[

			!build_stack_frame
			!sub_esp_byte 0C
			!push_registers

			!mov_esi_ecx

			; Copy resref field into null-terminated stack space ;
			!mov_eax_[esi+byte] 2C
			!mov_[ebp+byte]_eax F4
			!mov_eax_[esi+byte] 30
			!mov_[ebp+byte]_eax F8
			!mov_byte:[ebp+byte]_byte FC 0

			!lea_eax_[ebp+byte] F4
			!push_eax
			!push_[dword] *_g_lua
			!call >_lua_getglobal
			!add_esp_byte 08

			!push_esi
			!fild_[esp]
			!sub_esp_byte 04
			!fstp_qword:[esp]
			!push_[dword] *_g_lua
			!call >_lua_pushnumber
			!add_esp_byte 0C

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
			!push_byte 02
			!push_[dword] *_g_lua
			!call >_lua_pcallk
			!add_esp_byte 18

			@ret
			!mov_eax #1
			!restore_stack_frame
			!ret_word 04 00
		]]},
	})

	-------------------------------------
	-- New Opcode #403 (ScreenEffects) --
	-------------------------------------

	local checkAddScreenHookAddress = EEex_Label("CGameEffect::CheckAdd()_screen_hook")
	local checkAddScreenHookDest = checkAddScreenHookAddress + EEex_ReadDword(checkAddScreenHookAddress + 5) + 9

	local checkAddScreenHookName = "EEex_HookCheckAddScreen"
	local checkAddScreenHookNameAddress = EEex_Malloc(#checkAddScreenHookName + 1)
	EEex_WriteString(checkAddScreenHookNameAddress, checkAddScreenHookName)

	local checkAddScreenHook = EEex_WriteAssemblyAuto({[[

		!push_registers

		!push_dword ]], {checkAddScreenHookNameAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_edi
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_ebx
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_byte 02
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_toboolean
		!add_esp_byte 08
		!push_eax
		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08
		!pop_eax

		!test_eax_eax
		!pop_registers

		!jz_dword >resume_normally

		!pop_esi
		!pop_ebx
		!jmp_dword >CGameEffect::CheckAdd()_screen_hook_immunity

		@resume_normally

		!cmp_eax_[ebx+byte] 34
		!jz_dword ]], {checkAddScreenHookDest, 4, 4}, [[
		!jmp_dword ]], {checkAddScreenHookAddress + 9, 4, 4},

	})
	EEex_WriteAssembly(checkAddScreenHookAddress, {"!jmp_dword", {checkAddScreenHook, 4, 4}, "!nop !nop !nop !nop"})

	local screenListOffset = EEex_RegisterComplexListStat("EEex_ScreenEffectsList", {

		["construct"] = function(address)
			EEex_WriteDword(address + 0x4, EEex_ReadDword(EEex_Label("_afxPchNil")))
		end,

		["destruct"] = function(address)
			EEex_Call(EEex_Label("CString::~CString"), {}, address + 0x4, 0x0)
		end,

		["copy"] = function(source, dest)
			EEex_WriteDword(dest + 0x0, EEex_ReadDword(source + 0x0))
			EEex_Call(EEex_Label("CString::CString(CString_const_&)"), {dest + 0x4}, source + 0x4, 0x0)
		end,

		["size"] = 0x8,

	})

	local EEex_ScreenEffects = EEex_WriteOpcode({

		["ApplyEffect"] = {[[

			!build_stack_frame
			!sub_esp_byte 04
			!push_registers

			!mov_esi_ecx
			!mov_ebx_[ebp+byte] 08 ; CGameSprite ;

			!push_byte 08
			!call >_malloc
			!add_esp_byte 04
			!mov_edi_eax

			!mov_[edi]_esi ; Element Offset 0x0 ;

			!lea_eax_[ebp+byte] FC
			!push_eax
			!lea_ecx_[esi+byte] 2C
			!call >CResRef::GetResRefStr
			!mov_eax_[eax]
			!mov_[edi+byte]_eax 04 ; Element Offset 0x4 ;

			!push_edi
			!mov_ecx_[ebx+dword] #3B18
			!lea_ecx_[ecx+dword] ]], {screenListOffset, 4}, [[
			!call >CPtrList::AddTail

			@ret
			!mov_eax #1
			!restore_stack_frame
			!ret_word 04 00

		]]},
	})

	------------------------------------------
	-- New Opcode #404 (OverrideButtonType) --
	------------------------------------------

	local buttonOverrideOffset = EEex_RegisterSimpleListStat("EEex_OverrideButtonList", 0x8)

	local EEex_OverrideButton = EEex_WriteOpcode({

		["ApplyEffect"] = {[[

			!build_stack_frame
			!push_registers

			!mov_esi_ecx
			!mov_ebx_[ebp+byte] 08 ; CGameSprite ;

			!push_byte 08
			!call >_malloc
			!add_esp_byte 04
			!mov_edi_eax

			!mov_eax_[esi+byte] 18 ; Param1 ;
			!mov_[edi+byte]_eax 00 ; Target Button ;
			!mov_eax_[esi+byte] 1C ; Param2 ;
			!mov_[edi+byte]_eax 04 ; Override With ;

			!push_edi
			!mov_ecx_[ebx+dword] #3B18
			!lea_ecx_[ecx+dword] ]], {buttonOverrideOffset, 4}, [[
			!call >CPtrList::AddTail

			@ret
			!mov_eax #1
			!restore_stack_frame
			!ret_word 04 00

		]]},
	})

	local op404UpdateButton = function(config)

		local actorID = EEex_GetActorIDSelected()
		if actorID == 0x0 then return end

		local overrideList = EEex_AccessComplexStat(actorID, "EEex_OverrideButtonList")
		EEex_IterateCPtrList(overrideList, function(overridePtr)
			local overrideID = EEex_ReadDword(overridePtr)
			for i = 0, 11, 1 do
				local normalID = EEex_GetActionbarButton(i)
				if normalID == overrideID then
					EEex_SetActionbarButton(i, EEex_ReadDword(overridePtr + 0x4))
				end
			end
		end)
	end
	EEex_AddActionbarListener(op404UpdateButton)
	EEex_AddResetListener(function() EEex_AddActionbarListener(op404UpdateButton) end)

	-------------------------------------------
	-- New Opcode #405 (OverrideButtonIndex) --
	-------------------------------------------

	local buttonOverrideIndexOffset = EEex_RegisterSimpleListStat("EEex_OverrideButtonIndex", 0xC)

	local EEex_OverrideButtonIndex = EEex_WriteOpcode({

		["ApplyEffect"] = {[[

			!build_stack_frame
			!push_registers

			!mov_esi_ecx
			!mov_ebx_[ebp+byte] 08 ; CGameSprite ;

			!push_byte 0C
			!call >_malloc
			!add_esp_byte 04
			!mov_edi_eax

			!mov_eax_[esi+byte] 18 ; Param1 ;
			!mov_[edi+byte]_eax 00 ; Target Button ;
			!mov_eax_[esi+byte] 1C ; Param2 ;
			!mov_[edi+byte]_eax 04 ; Override With ;
			!mov_eax_[esi+byte] 44 ; Special ;
			!mov_[edi+byte]_eax 08 ; Target Config ;

			!push_edi
			!mov_ecx_[ebx+dword] #3B18
			!lea_ecx_[ecx+dword] ]], {buttonOverrideIndexOffset, 4}, [[
			!call >CPtrList::AddTail

			@ret
			!mov_eax #1
			!restore_stack_frame
			!ret_word 04 00

		]]},
	})

	local op405UpdateButton = function(config)
		local actorID = EEex_GetActorIDSelected()
		if actorID == 0x0 then return end
		local overrideList = EEex_AccessComplexStat(actorID, "EEex_OverrideButtonIndex")
		EEex_IterateCPtrList(overrideList, function(overridePtr)
			local targetConfig = EEex_ReadDword(overridePtr + 0x8)
			if targetConfig == -1 then
				if config >= 0 and config <= 19 then
					local overrideIndex = EEex_ReadDword(overridePtr)
					local overrideID = EEex_ReadDword(overridePtr + 0x4)
					EEex_SetActionbarButton(overrideIndex, overrideID)
				end
			elseif config == targetConfig then
				local overrideIndex = EEex_ReadDword(overridePtr)
				local overrideID = EEex_ReadDword(overridePtr + 0x4)
				EEex_SetActionbarButton(overrideIndex, overrideID)
			end
		end)
	end
	EEex_AddActionbarListener(op405UpdateButton)
	EEex_AddResetListener(function() EEex_AddActionbarListener(op405UpdateButton) end)

	-----------------------------
	-- Opcode Definitions Hook --
	-----------------------------

	local opcodesHook = EEex_WriteAssemblyAuto(EEex_ConcatTables({[[

		!cmp_eax_dword #190
		!jne_dword >401

		]], newOpcode400, [[

		@401
		!cmp_eax_dword #191
		!jne_dword >402

		]], EEex_SetNewStat, [[

		@402
		!cmp_eax_dword #192
		!jne_dword >403

		]], EEex_InvokeLua, [[

		@403
		!cmp_eax_dword #193
		!jne_dword >404

		]], EEex_ScreenEffects, [[

		@404
		!cmp_eax_dword #194
		!jne_dword >405

		]], EEex_OverrideButton, [[

		@405
		!cmp_eax_dword #195
		!jne_dword >fail

		]], EEex_OverrideButtonIndex, [[

		@fail
		!jmp_dword >CGameEffect::DecodeEffect()_default_label

	]]}))

	EEex_WriteAssembly(EEex_Label("CGameEffect::DecodeEffect()_default_jump"), {{opcodesHook, 4, 4}})

	EEex_EnableCodeProtection()

end
EEex_InstallOpcodeChanges()
