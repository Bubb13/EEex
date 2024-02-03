
(function()

	EEex_DisableCodeProtection()

	---------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_CheckSuppressTooltip() --
	---------------------------------------------------

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CGameSprite::SetCursor()-SetCharacterToolTip()"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_CheckSuppressTooltip", {
				["returnType"] = EEex_LuaCallReturnType.Boolean,
			}),
			{[[
				jmp no_error

				call_error:
				xor rax, rax

				no_error:
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
				test rax, rax
				jnz #L(return_skip)
			]]},
		})
	)

	------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnConstruct() --
	------------------------------------------

	for _, labelName in ipairs({
		"Hook-CGameSprite::Construct1()-FirstCall",
		"Hook-CGameSprite::Construct2()-FirstCall"
	}) do
		EEex_HookAfterCallWithLabels(EEex_Label(labelName), {
			{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
			EEex_FlattenTable({
				{[[
					#MAKE_SHADOW_SPACE(40)
				]]},
				EEex_GenLuaCall("EEex_Sprite_Hook_OnConstruct", {
					["args"] = {
						function(rspOffset) return {[[
							mov qword ptr ss:[rsp+#$(1)], rsi
						]], {rspOffset}}, "CGameSprite" end,
					},
				}),
				{[[
					call_error:
					#DESTROY_SHADOW_SPACE
				]]},
			})
		)
	end

	-----------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnDestruct() --
	-----------------------------------------

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::Destruct()-FirstCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_OnDestruct", {
				["args"] = {
					function(rspOffset) return {[[
						mov qword ptr ss:[rsp+#$(1)], rbx
					]], {rspOffset}}, "CGameSprite" end,
				},
			}),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnCheckQuickLists() --
	------------------------------------------------

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameSprite::CheckQuickLists()-CallListeners"), 0, 5, 5, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(88)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_OnCheckQuickLists", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx #ENDL", {rspOffset}}, "CGameSprite" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx #ENDL", {rspOffset}}, "CAbilityId" end,
					function(rspOffset) return {[[
						movsx rax, r8w
						mov qword ptr ss:[rsp+#$(1)], rax
					]], {rspOffset}} end,
				},
			}),
			{[[
				call_error:
				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
				mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	-----------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnResetQuickListCounts() --
	-----------------------------------------------------

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::Rest()-OnResetQuickListCounts"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_OnResetQuickListCounts", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r15 #ENDL", {rspOffset}}, "CGameSprite" end,
				},
			}),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	-----------------------------------------------------
	-- [JIT] CGameEffectList_Marshal_SavedSpritePtrMem --
	-----------------------------------------------------

	local CGameEffectList_Marshal_SavedSpritePtrMem = EEex_Malloc(EEex_PtrSize * 2)
	EEex_WritePtr(CGameEffectList_Marshal_SavedSpritePtrMem, 0x0)

	EEex_HookBeforeAndAfterCall(EEex_Label("Hook-CGameSprite::Marshal()-CGameEffectList::Marshal()"),
		{"mov qword ptr ds:[#$(1)], r13 #ENDL", {CGameEffectList_Marshal_SavedSpritePtrMem}},
		{"mov qword ptr ds:[#$(1)], 0 #ENDL", {CGameEffectList_Marshal_SavedSpritePtrMem}}
	)

	-------------------------------------------------------
	-- [JIT] CGameEffectList_Unmarshal_SavedSpritePtrMem --
	-------------------------------------------------------

	local CGameEffectList_Unmarshal_SavedSpritePtrMem = CGameEffectList_Marshal_SavedSpritePtrMem + EEex_PtrSize
	EEex_WritePtr(CGameEffectList_Unmarshal_SavedSpritePtrMem, 0x0)

	EEex_HookBeforeAndAfterCall(EEex_Label("Hook-CGameSprite::Unmarshal()-CGameEffectList::Unmarshal()"),
		{"mov qword ptr ds:[#$(1)], rbx #ENDL", {CGameEffectList_Unmarshal_SavedSpritePtrMem}},
		{"mov qword ptr ds:[#$(1)], 0 #ENDL", {CGameEffectList_Unmarshal_SavedSpritePtrMem}}
	)

	------------------------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_CalculateExtraEffectListMarshalSize() --
	------------------------------------------------------------------

	local CGameEffectList_Marshal_OriginalMarshalSize = EEex_Malloc(EEex_PtrSize)
	EEex_WritePtr(CGameEffectList_Marshal_OriginalMarshalSize, 0x0)

	EEex_HookBeforeConditionalJumpWithLabels(EEex_Label("Hook-CGameEffectList::Marshal()-OverrideSize"), 0, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RBX, EEex_HookIntegrityWatchdogRegister.RCX,
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				cmp qword ptr ds:[#$(1)], 0 ]], {CGameEffectList_Marshal_SavedSpritePtrMem}, [[ #ENDL
				jnz continue

				test ebx, ebx ; Recalculates flags for the jle instruction being returned to
				jmp #L(return)

				continue:
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_CalculateExtraEffectListMarshalSize", {
				["args"] = {
					-- sprite
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[#$(1)] ]], {CGameEffectList_Marshal_SavedSpritePtrMem}, [[ #ENDL
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]}, "CGameSprite" end,
				},
				["returnType"] = EEex_LuaCallReturnType.Number,
			}),
			{[[
				jmp no_error

				call_error:
				xor rax, rax

				no_error:
				mov qword ptr ds:[#$(1)], rbx ]], {CGameEffectList_Marshal_OriginalMarshalSize}, [[ #ENDL
				add rbx, rax ; Sets flags for the jle instruction being returned to

				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	----------------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_WriteExtraEffectListMarshal() --
	----------------------------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CGameEffectList::Marshal()-WriteExtra"), EEex_FlattenTable({
		{[[
			cmp qword ptr ds:[#$(1)], 0 ]], {CGameEffectList_Marshal_SavedSpritePtrMem}, [[ #ENDL
			jz #L(return)

			#MAKE_SHADOW_SPACE(48)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		]]},
		EEex_GenLuaCall("EEex_Sprite_Hook_WriteExtraEffectListMarshal", {
			["args"] = {
				-- memory
				function(rspOffset) return {[[
					add rax, qword ptr ss:[#$(1)] ]], {CGameEffectList_Marshal_OriginalMarshalSize}, [[ #ENDL
					mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
				]]} end,
			},
		}),
		{[[
			call_error:
			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	-----------------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_ReadExtraEffectListUnmarshal() --
	-----------------------------------------------------------

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CGameEffectList::Unmarshal()-CGameEffect::DecodeEffectFromBase()"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				cmp dword ptr ds:[rcx], 0x49422D58 ; Check if signature is "X-BI"
				jne #L(return)

				cmp qword ptr ds:[#$(1)], 0 ]], {CGameEffectList_Unmarshal_SavedSpritePtrMem}, [[ #ENDL
				jz dont_process_effect

				#MAKE_SHADOW_SPACE(48)
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_ReadExtraEffectListUnmarshal", {
				["args"] = {
					-- sprite
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[#$(1)] ]], {CGameEffectList_Unmarshal_SavedSpritePtrMem}, [[ #ENDL
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]}, "CGameSprite" end,
					-- memory
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx", {rspOffset}, "#ENDL"} end,
				},
			}),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE

				dont_process_effect:
				#MANUAL_HOOK_EXIT(1)
				jmp #L(Hook-CGameEffectList::Unmarshal()-Return)
			]]},
		})
	)
	-- Manually define the ignored registers for the unusual `dont_process_effect` branch above
	EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(EEex_Label("Hook-CGameEffectList::Unmarshal()-CGameEffect::DecodeEffectFromBase()"), 1, {
		EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
		EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
		EEex_HookIntegrityWatchdogRegister.R11
	})

	-----------------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnLoadConcentrationCheckMode() --
	-----------------------------------------------------------

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CRuleTables::Construct()-CHECK_MODE-ConvertStrToInt"), {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9,
			EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(48)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_OnLoadConcentrationCheckMode", {
				["args"] = {
					function(rspOffset) return {[[
						mov qword ptr ss:[rsp+#$(1)], rcx
					]], {rspOffset}}, "string" end,
				},
			}),
			{[[
				call_error:
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	----------------------------------------------------------------------------------
	-- Call CONCENTR.2DA[VALUE,CHECK_MODE] EEex-LuaFunction=<function name>(sprite) --
	-- instead of running the normal concentration code.                            --
	-- Return:                                                                      --
	--     false -> Spell NOT disrupted.                                            --
	--     true  -> Spell disrupted.                                                --
	--                                                                              --
	--  [Lua] EEex_Sprite_Hook_OnCheckConcentration()                               --
	----------------------------------------------------------------------------------

	EEex_Sprite_Private_RunCustomConcentrationCheckMem = EEex_Malloc(1)
	EEex_Write8(EEex_Sprite_Private_RunCustomConcentrationCheckMem, 0)

	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CGameSprite::ConcentrationFailed()-CHECK_MODE-Redirect"), 0, 5, 5, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				cmp byte ptr ss:[#$(1)], 0 ]], {EEex_Sprite_Private_RunCustomConcentrationCheckMem}, [[ #ENDL
				jz #L(return)

				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_OnCheckConcentration", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx #ENDL", {rspOffset}}, "CGameSprite" end,
				},
				["returnType"] = EEex_LuaCallReturnType.Boolean,
			}),
			{[[
				jmp no_error

				call_error:
				mov rax, 1

				no_error:
				#DESTROY_SHADOW_SPACE
				#MANUAL_HOOK_EXIT(1)
				ret
			]]},
		})
	)
	-- Manually define the ignored registers for the unusual `ret` above
	EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(EEex_Label("Hook-CGameSprite::ConcentrationFailed()-CHECK_MODE-Redirect"), 1, {
		EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
		EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
		EEex_HookIntegrityWatchdogRegister.R11
	})

	-----------------------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnDamageEffectStartingCalculations() --
	-----------------------------------------------------------------

	EEex_HookAfterRestoreWithLabels(EEex_Label("Hook-CGameEffectDamage::ApplyEffect()-StartingCalculations"), 0, 6, 6, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				cmp byte ptr ss:[#$(1)], 0 ]], {EEex_Sprite_Private_RunCustomConcentrationCheckMem}, [[ #ENDL
				jz #L(return)

				#MAKE_SHADOW_SPACE(64)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_OnDamageEffectStartingCalculations", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r14 #ENDL", {rspOffset}}, "CGameEffect" end,
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rbp-0x41]
						mov qword ptr ss:[rsp+#$(1)], rax
					]], {rspOffset}}, "CGameSprite" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx #ENDL", {rspOffset}}, "CGameSprite" end,
				},
			}),
			{[[
				call_error:
				mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	-------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnDamageEffectDone() --
	-------------------------------------------------

	EEex_HookAfterRestoreWithLabels(EEex_Label("Hook-CGameEffectDamage::ApplyEffect()-OnDone"), 0, 7, 7, {
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX, EEex_HookIntegrityWatchdogRegister.R8,
			EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				cmp byte ptr ss:[#$(1)], 0 ]], {EEex_Sprite_Private_RunCustomConcentrationCheckMem}, [[ #ENDL
				jz #L(return)

				#MAKE_SHADOW_SPACE(64)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_OnDamageEffectDone", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r14 #ENDL", {rspOffset}}, "CGameEffect" end,
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rbp-0x41]
						mov qword ptr ss:[rsp+#$(1)], rax
					]], {rspOffset}}, "CGameSprite" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx #ENDL", {rspOffset}}, "CGameSprite" end,
				},
			}),
			{[[
				call_error:
				mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	----------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnSetCurrAction() --
	----------------------------------------------

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CGameSprite::SetCurrAction()-FirstCall"), {
		{"hook_integrity_watchdog_ignore_registers", {EEex_HookIntegrityWatchdogRegister.RAX}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(40)
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_OnSetCurrAction", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdi #ENDL", {rspOffset}}, "CGameSprite" end,
				},
			}),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)

	--------------------------------------------------------------------------------------------
	-- Allow ITM header flag BIT18 to ignore weapon styles (as if the item were in SLOT_FIST) --
	--------------------------------------------------------------------------------------------

	local getProfBonusesItemHack = EEex_Malloc(EEex_PtrSize)
	EEex_WritePtr(getProfBonusesItemHack, 0)

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::CheckCombatStats()-GetProfBonuses-SaveItem"), {[[
		mov qword ptr ds:[#$(1)], rbx ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	EEex_HookBeforeCall(EEex_Label("Hook-CGameSprite::GetMaxDamage()-GetProfBonuses-SaveItem"), {[[
		mov qword ptr ds:[#$(1)], r13 ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	EEex_HookBeforeCall(EEex_Label("Hook-CGameSprite::GetMinDamage()-GetProfBonuses-SaveItem"), {[[
		mov qword ptr ds:[#$(1)], r13 ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	EEex_HookBeforeCall(EEex_Label("Hook-CGameSprite::GetStatBreakdown()-GetProfBonuses-SaveItem"), {[[
		mov qword ptr ds:[#$(1)], r14 ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	-- Result saved for use in CGameSprite::GetStyleBonus()
	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::GetActiveWeaponStyleAndLevel()-GetProfBonuses-SaveItem"), {[[
		mov qword ptr ds:[#$(1)], rdi ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::EquipMostDamagingMelee()-GetProfBonuses-SaveItem"), {[[
		mov qword ptr ds:[#$(1)], rdi ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	-- Main hook
	EEex_HookBeforeRestoreWithLabels(EEex_Label("Hook-CRuleTables::GetProfBonuses()-IgnoreWeaponStyles"), 0, 5, 5, {
		{"stack_mod", 8},
		{"hook_integrity_watchdog_ignore_registers", {
			EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.R10, EEex_HookIntegrityWatchdogRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(136)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
				mov dword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], edx
				mov dword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8d
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9
			]]},
			EEex_GenLuaCall("EEex_Sprite_Hook_GetProfBonuses_IgnoreWeaponStyles", {
				["args"] = {
					function(rspOffset) return {[[
						mov rax, qword ptr ds:[#$(1)] ]], {getProfBonusesItemHack}, [[ ; Global hack [item]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]}, "CItem" end,
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)] ; Register arg 4 [damR]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]} end,
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(40)] ; Stack arg 1 [damL]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]} end,
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(48)] ; Stack arg 2 [thacR]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]} end,
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(56)] ; Stack arg 3 [thacL]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]} end,
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(64)] ; Stack arg 4 [ACB]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]} end,
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(72)] ; Stack arg 5 [ACM]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]} end,
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(80)] ; Stack arg 6 [speed]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]} end,
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(88)] ; Stack arg 7 [crit]
						mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
					]]} end,
				},
				["returnType"] = EEex_LuaCallReturnType.Boolean,
			}),
			{[[
				jmp no_error

				call_error:
				xor rax, rax

				no_error:
				test rax, rax
				jz do_not_ignore_weapon_styles

				#DESTROY_SHADOW_SPACE(KEEP_ENTRY)
				#MANUAL_HOOK_EXIT(1)
				ret

				do_not_ignore_weapon_styles:
				#RESUME_SHADOW_ENTRY
				mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
				mov r8d, dword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
				mov edx, dword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
				mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				#DESTROY_SHADOW_SPACE
			]]},
		})
	)
	-- Manually define the ignored registers for the unusual `ret` above
	EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance(EEex_Label("Hook-CRuleTables::GetProfBonuses()-IgnoreWeaponStyles"), 1, {
		EEex_HookIntegrityWatchdogRegister.RAX, EEex_HookIntegrityWatchdogRegister.RCX, EEex_HookIntegrityWatchdogRegister.RDX,
		EEex_HookIntegrityWatchdogRegister.R8, EEex_HookIntegrityWatchdogRegister.R9, EEex_HookIntegrityWatchdogRegister.R10,
		EEex_HookIntegrityWatchdogRegister.R11
	})

	EEex_EnableCodeProtection()

end)()
