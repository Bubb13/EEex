
(function()

	EEex_DisableCodeProtection()

	---------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_CheckSuppressTooltip() --
	---------------------------------------------------

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CGameSprite::SetCursor()-SetCharacterToolTip()"), {
		{"uses_early_return", true}},
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
				jnz #L(return)
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

	-----------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnDestruct() --
	-----------------------------------------

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

	------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnCheckQuickLists() --
	------------------------------------------------

	EEex_HookBeforeRestore(EEex_Label("Hook-CGameSprite::CheckQuickLists()-CallListeners"), 0, 5, 5, EEex_FlattenTable({
		{[[
			#STACK_MOD(8) ; TODO This was called, the ret ptr broke alignment
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

	-----------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnResetQuickListCounts() --
	-----------------------------------------------------

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

	EEex_HookBeforeAndAfterCall(EEex_Label("Hook-CGameEffectList::Unmarshal()-CGameEffect::DecodeEffectFromBase()"),
		{[[
			cmp qword ptr ds:[#$(1)], 0 ]], {CGameEffectList_Unmarshal_SavedSpritePtrMem}, [[ #ENDL
			jz dont_do_anything

			cmp dword ptr ds:[rcx], 0x49422D58 ; Check if signature is "X-BI"
			je handle_EEex_binary

			dont_do_anything:
		]]},
		EEex_FlattenTable({
			{[[
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
			]]},
			EEex_IntegrityCheck_HookExit,
			{[[
				jmp #L(Hook-CGameEffectList::Unmarshal()-Return)
			]]},
		})
	)

	-----------------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnLoadConcentrationCheckMode() --
	-----------------------------------------------------------

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
	--                                                                              --
	--  [Lua] EEex_Sprite_Hook_OnCheckConcentration()                               --
	----------------------------------------------------------------------------------

	EEex_Sprite_Private_RunCustomConcentrationCheckMem = EEex_Malloc(1)
	EEex_Write8(EEex_Sprite_Private_RunCustomConcentrationCheckMem, 0)

	EEex_HookBeforeRestore(EEex_Label("Hook-CGameSprite::ConcentrationFailed()-CHECK_MODE-Redirect"), 0, 5, 5, EEex_FlattenTable({
		{[[
			cmp byte ptr ss:[#$(1)], 0 ]], {EEex_Sprite_Private_RunCustomConcentrationCheckMem}, [[ #ENDL
			jz return

			#STACK_MOD(8) ; TODO This was called, the ret ptr broke alignment
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
			ret ; TODO
		]]},
	}))

	-----------------------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnDamageEffectStartingCalculations() --
	-----------------------------------------------------------------

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

	-------------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnDamageEffectDone() --
	-------------------------------------------------

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

	----------------------------------------------
	-- [Lua] EEex_Sprite_Hook_OnSetCurrAction() --
	----------------------------------------------

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

	EEex_EnableCodeProtection()

end)()
