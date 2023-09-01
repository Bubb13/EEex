
(function()

	EEex_DisableCodeProtection()

	-------------------------------------------
	-- EEex_Sprite_Hook_CheckSuppressTooltip --
	-------------------------------------------

	EEex_HookRelativeBranch(EEex_Label("Hook-CGameSprite::SetCursor()-SetCharacterToolTip()"), EEex_FlattenTable({
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
			jnz #L(return)
			call #L(original)
			jmp #L(return)
		]]},
	}))

	----------------------------------
	-- EEex_Sprite_Hook_OnConstruct --
	----------------------------------

	for _, labelName in ipairs({
		"Hook-CGameSprite::Construct1()-FirstCall",
		"Hook-CGameSprite::Construct2()-FirstCall"
	}) do
		EEex_HookAfterCall(EEex_Label(labelName), EEex_FlattenTable({
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
		}))
	end

	---------------------------------
	-- EEex_Sprite_Hook_OnDestruct --
	---------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::Destruct()-FirstCall"), EEex_FlattenTable({
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
	}))

	----------------------------------------
	-- EEex_Sprite_Hook_OnCheckQuickLists --
	----------------------------------------

	EEex_HookBeforeRestore(EEex_Label("Hook-CGameSprite::CheckQuickLists()-CallListeners"), 0, 5, 5, EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
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
	}))

	----------------------------------------
	-- EEex_Sprite_Hook_OnCheckQuickLists --
	----------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::Rest()-OnResetQuickListCounts"), EEex_FlattenTable({
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
	}))

	-----------------------------------------------
	-- CGameEffectList_Marshal_SavedSpritePtrMem --
	-----------------------------------------------

	local CGameEffectList_Marshal_SavedSpritePtrMem = EEex_Malloc(EEex_PtrSize * 2)
	EEex_WritePtr(CGameEffectList_Marshal_SavedSpritePtrMem, 0x0)

	EEex_HookRelativeBranch(EEex_Label("Hook-CGameSprite::Marshal()-CGameEffectList::Marshal()"), {[[
		mov qword ptr ds:[#$(1)], r13 ]], {CGameEffectList_Marshal_SavedSpritePtrMem}, [[ #ENDL
		call #L(original)
		mov qword ptr ds:[#$(1)], 0 ]], {CGameEffectList_Marshal_SavedSpritePtrMem}, [[ #ENDL
		jmp #L(return)
	]]})

	-------------------------------------------------
	-- CGameEffectList_Unmarshal_SavedSpritePtrMem --
	-------------------------------------------------

	local CGameEffectList_Unmarshal_SavedSpritePtrMem = CGameEffectList_Marshal_SavedSpritePtrMem + EEex_PtrSize
	EEex_WritePtr(CGameEffectList_Unmarshal_SavedSpritePtrMem, 0x0)

	EEex_HookRelativeBranch(EEex_Label("Hook-CGameSprite::Unmarshal()-CGameEffectList::Unmarshal()"), {[[
		mov qword ptr ds:[#$(1)], rbx ]], {CGameEffectList_Unmarshal_SavedSpritePtrMem}, [[ #ENDL
		call #L(original)
		mov qword ptr ds:[#$(1)], 0 ]], {CGameEffectList_Unmarshal_SavedSpritePtrMem}, [[ #ENDL
		jmp #L(return)
	]]})

	----------------------------------------------------------
	-- EEex_Sprite_Hook_CalculateExtraEffectListMarshalSize --
	----------------------------------------------------------

	local CGameEffectList_Marshal_OriginalMarshalSize = EEex_Malloc(EEex_PtrSize)
	EEex_WritePtr(CGameEffectList_Marshal_OriginalMarshalSize, 0x0)

	EEex_HookJump(EEex_Label("Hook-CGameEffectList::Marshal()-OverrideSize"), 0, EEex_FlattenTable({
		{[[
			cmp qword ptr ds:[#$(1)], 0 ]], {CGameEffectList_Marshal_SavedSpritePtrMem}, [[ #ENDL
			jz jmp

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
			add rbx, rax

			#DESTROY_SHADOW_SPACE
		]]},
	}))

	--------------------------------------------------
	-- EEex_Sprite_Hook_WriteExtraEffectListMarshal --
	--------------------------------------------------

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

	---------------------------------------------------
	-- EEex_Sprite_Hook_ReadExtraEffectListUnmarshal --
	---------------------------------------------------

	EEex_HookRelativeBranch(EEex_Label("Hook-CGameEffectList::Unmarshal()-CGameEffect::DecodeEffectFromBase()"), EEex_FlattenTable({
		{[[
			cmp qword ptr ds:[#$(1)], 0 ]], {CGameEffectList_Unmarshal_SavedSpritePtrMem}, [[ #ENDL
			jz dont_do_anything

			cmp dword ptr ds:[rcx], 0x49422D58 ; Check if signature is "X-BI"
			je handle_EEex_binary

			dont_do_anything:
			call #L(original)
			jmp #L(return)

			handle_EEex_binary:
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
			jmp #L(Hook-CGameEffectList::Unmarshal()-Return)
		]]},
	}))

	---------------------------------------------------
	-- EEex_Sprite_Hook_OnLoadConcentrationCheckMode --
	---------------------------------------------------

	EEex_HookBeforeCall(EEex_Label("Hook-CRuleTables::Construct()-CHECK_MODE-ConvertStrToInt"), EEex_FlattenTable({
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
	}))

	----------------------------------------------------------------------------------
	-- Call CONCENTR.2DA[VALUE,CHECK_MODE] EEex-LuaFunction=<function name>(sprite) --
	-- instead of running the normal concentration code.                            --
	-- Return:                                                                      --
	--     false -> Spell NOT disrupted.                                            --
	--     true  -> Spell disrupted.                                                --
	----------------------------------------------------------------------------------

	EEex_Sprite_Private_RunCustomConcentrationCheckMem = EEex_Malloc(1)
	EEex_Write8(EEex_Sprite_Private_RunCustomConcentrationCheckMem, 0)

	EEex_HookBeforeRestore(EEex_Label("Hook-CGameSprite::ConcentrationFailed()-CHECK_MODE-Redirect"), 0, 5, 5, EEex_FlattenTable({
		{[[
			cmp byte ptr ss:[#$(1)], 0 ]], {EEex_Sprite_Private_RunCustomConcentrationCheckMem}, [[ #ENDL
			jz return

			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
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
			ret
		]]},
	}))

	---------------------------------------------------------
	-- EEex_Sprite_Hook_OnDamageEffectStartingCalculations --
	---------------------------------------------------------

	EEex_HookAfterRestore(EEex_Label("Hook-CGameEffectDamage::ApplyEffect()-StartingCalculations"), 0, 6, 6, EEex_FlattenTable({
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
	}))

	-----------------------------------------
	-- EEex_Sprite_Hook_OnDamageEffectDone --
	-----------------------------------------

	EEex_HookAfterRestore(EEex_Label("Hook-CGameEffectDamage::ApplyEffect()-OnDone"), 0, 7, 7, EEex_FlattenTable({
		{[[
			cmp byte ptr ss:[#$(1)], 0 ]], {EEex_Sprite_Private_RunCustomConcentrationCheckMem}, [[ #ENDL
			jz #L(return)

			#MAKE_SHADOW_SPACE(56)
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
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	--------------------------------------
	-- EEex_Sprite_Hook_OnSetCurrAction --
	--------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::SetCurrAction()-FirstCall"), EEex_FlattenTable({
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
	}))

	--------------------------------------------------------------------------------------------
	-- Allow ITM header flag BIT18 to ignore weapon styles (as if the item were in SLOT_FIST) --
	--------------------------------------------------------------------------------------------

	local getProfBonusesItemHack = EEex_Malloc(EEex_PtrSize)
	EEex_WritePtr(getProfBonusesItemHack, 0)

	-- CheckCombatStats()

	EEex_HookAfterCall(0x14034C00A, {[[
		mov qword ptr ds:[#$(1)], rbx ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	-- GetMaxDamage()

	EEex_HookBeforeCall(0x1403564A9, {[[
		mov qword ptr ds:[#$(1)], r13 ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	-- GetMinDamage()

	EEex_HookBeforeCall(0x140356DB4, {[[
		mov qword ptr ds:[#$(1)], r13 ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	-- GetStatBreakdown()

	EEex_HookBeforeCall(0x14035C3B8, {[[
		mov qword ptr ds:[#$(1)], r14 ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	-- GetStyleBonus()

	EEex_HookAfterCall(0x14039C549, {[[
		mov qword ptr ds:[#$(1)], rdi ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	-- EquipMostDamagingMelee()

	EEex_HookAfterCall(0x1403930A8, {[[
		mov qword ptr ds:[#$(1)], rdi ]], {getProfBonusesItemHack}, [[ #ENDL
	]]})

	-- Main hook: GetProfBonuses()

	EEex_HookBeforeRestore(0x1402451D0, 0, 5, 5, EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(136)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov dword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], edx
			mov dword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8d
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9
		]]},
		EEex_GenLuaCall("EEex_Sprite_Hook_GetProfBonuses_IgnoreWeaponStyles", {
			["args"] = {
				function(rspOffset) return {[[
					mov rax, qword ptr ds:[#$(1)] ]], {getProfBonusesItemHack}, [[ ; Global hack (item)
					mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
				]]}, "CItem" end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)] ; Register arg 4 (damR)
					mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
				]]} end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(40)] ; Stack arg 1 (damL)
					mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
				]]} end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(48)] ; Stack arg 2 (thacR)
					mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
				]]} end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(56)] ; Stack arg 3 (thacL)
					mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
				]]} end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(64)] ; Stack arg 4 (ACB)
					mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
				]]} end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(72)] ; Stack arg 5 (ACM)
					mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
				]]} end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(80)] ; Stack arg 6 (speed)
					mov qword ptr ss:[rsp+#$(1)], rax ]], {rspOffset}, [[ #ENDL
				]]} end,
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(88)] ; Stack arg 7 (crit)
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
			ret

			do_not_ignore_weapon_styles:
			mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
			mov r8d, dword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
			mov edx, dword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	EEex_EnableCodeProtection()

end)()
