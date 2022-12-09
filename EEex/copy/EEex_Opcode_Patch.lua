
(function()

	EEex_DisableCodeProtection()

	-----------------------------------------
	-- EEex_Opcode_Hook_AfterListsResolved --
	-----------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CGameSprite::ProcessEffectList()-AfterListsResolved"), EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(40)
		]]},
		EEex_GenLuaCall("EEex_Opcode_Hook_AfterListsResolved", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rsi #ENDL", {rspOffset}}, "CGameSprite" end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	--------------------------------------------------------------------------
	-- Opcode #326 (Special BIT0 flips SPLPROT.2DA's "source" and "target") --
	--------------------------------------------------------------------------

	EEex_HookAfterRestore(EEex_Label("Hook-CGameEffectApplySpell::ApplyEffect()-OverrideSplprotContext"), 0, 7, 7, EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(72)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r8
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r9
		]]},
		EEex_GenLuaCall("EEex_Opcode_Hook_ApplySpell_ShouldFlipSplprotSourceAndTarget", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}),
		{[[
			jmp no_error

			call_error:
			xor rax, rax

			no_error:
			test rax, rax
			mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
			mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
			mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
			jz #L(return)

			mov rax, r8
			mov r8, r9
			mov r9, rax
		]]},
	}))

	--------------------------------------------
	-- New Opcode #400 (SetTemporaryAIScript) --
	--------------------------------------------

	local EEex_SetTemporaryAIScript = EEex_Opcode_GenDecode({

		["ApplyEffect"] = EEex_FlattenTable({[[

			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(48)

			]], EEex_GenLuaCall("EEex_Opcode_Hook_SetTemporaryAIScript_ApplyEffect", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx", {rspOffset}, "#ENDL"}, "CGameSprite" end,
				},
			}), [[

			call_error:
			#DESTROY_SHADOW_SPACE
			mov rax, 1
			ret
		]]}),

		["OnRemove"] = EEex_FlattenTable({[[

			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(48)

			]], EEex_GenLuaCall("EEex_Opcode_Hook_SetTemporaryAIScript_OnRemove", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx", {rspOffset}, "#ENDL"}, "CGameSprite" end,
				},
			}), [[

			call_error:
			#DESTROY_SHADOW_SPACE
			ret
		]]}),
	})

	---------------------------------------
	-- New Opcode #401 (SetExtendedStat) --
	---------------------------------------

	local EEex_SetExtendedStat = EEex_Opcode_GenDecode({

		["ApplyEffect"] = EEex_FlattenTable({[[

			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(48)

			]], EEex_GenLuaCall("EEex_Opcode_Hook_ApplySetExtendedStat", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx", {rspOffset}, "#ENDL"}, "CGameSprite" end,
				},
			}), [[

			call_error:
			#DESTROY_SHADOW_SPACE
			mov rax, 1
			ret
		]]}),
	})

	---------------------------------
	-- New Opcode #402 (InvokeLua) --
	---------------------------------

	local EEex_InvokeLua = EEex_Opcode_GenDecode({

		["ApplyEffect"] = EEex_FlattenTable({[[

			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(64)
			mov rax, qword ptr ds:[rcx+30h] ; res
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax
			mov byte ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], 0

			]], EEex_GenLuaCall(nil, {
				["functionSrc"] = {[[
					lea rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
					mov rcx, rbx
					#ALIGN
					call #L(Hardcoded_lua_getglobal)
					#ALIGN_END
				]]},
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx", {rspOffset}, "#ENDL"}, "CGameSprite" end,
				},
			}), [[

			call_error:
			#DESTROY_SHADOW_SPACE
			mov rax, 1
			ret
		]]}),
	})

	-------------------------------------
	-- New Opcode #403 (ScreenEffects) --
	-------------------------------------

	local EEex_ScreenEffects = EEex_Opcode_GenDecode({

		["ApplyEffect"] = EEex_FlattenTable({[[

			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(48)

			]], EEex_GenLuaCall("EEex_Opcode_Hook_ApplyScreenEffects", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx", {rspOffset}, "#ENDL"}, "CGameSprite" end,
				},
			}), [[

			call_error:
			#DESTROY_SHADOW_SPACE
			mov rax, 1
			ret
		]]}),
	})

	local effectBlockedHack = EEex_Malloc(0x8)

	EEex_HookJumpOnFail(EEex_Label("Hook-CGameEffect::CheckAdd()-LastProbabilityJmp"), 0, EEex_FlattenTable({[[

		#MAKE_SHADOW_SPACE(56)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rdx

		]], EEex_GenLuaCall("EEex_Opcode_Hook_OnCheckAdd", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdi #ENDL", {rspOffset}}, "CGameEffect" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], r14 #ENDL", {rspOffset}}, "CGameSprite" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}), [[
		jmp no_error

		call_error:
		xor rax, rax

		no_error:
		mov qword ptr ds:[#$(1)], rax ]], {{effectBlockedHack}}, [[ #ENDL
		mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE
		test rax, rax
		jnz #L(Hook-CGameEffect::CheckAdd()-ProbabilityFailed)
	]]}))

	EEex_HookJumpOnSuccess(EEex_Label("Hook-CGameSprite::AddEffect()-noSave-Override"), 3, {[[
		cmp qword ptr ds:[#$(1)], 0 ]], {effectBlockedHack}, [[ #ENDL
		jnz jmp_fail
	]]})

	-----------------------------------------
	-- New Opcode #408 (ProjectileMutator) --
	-----------------------------------------

	local EEex_ProjectileMutator = EEex_Opcode_GenDecode({

		["ApplyEffect"] = EEex_FlattenTable({[[

			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(48)

			]], EEex_GenLuaCall("EEex_Opcode_Hook_ProjectileMutator_ApplyEffect", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rcx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rdx", {rspOffset}, "#ENDL"}, "CGameSprite" end,
				},
			}), [[

			call_error:
			#DESTROY_SHADOW_SPACE
			mov rax, 1
			ret
		]]}),
	})

	-------------------
	-- Decode Switch --
	-------------------

	EEex_HookJumpOnSuccess(EEex_Label("Hook-CGameEffect::DecodeEffect()-DefaultJmp"), 0, EEex_FlattenTable({[[

		mov qword ptr ss:[rsp+60h], r15 ; save non-volatile register

		cmp eax, 367
		jbe jmp_fail

		cmp eax, 400
		jne _401
		]], EEex_SetTemporaryAIScript, [[

		_401:
		cmp eax, 401
		jne _402
		]], EEex_SetExtendedStat, [[

		_402:
		cmp eax, 402
		jne _403
		]], EEex_InvokeLua, [[

		_403:
		cmp eax, 403
		jne _408
		]], EEex_ScreenEffects, [[

		_408:
		cmp eax, 408
		jne #L(jmp_success)
		]], EEex_ProjectileMutator, [[
	]]}))

	EEex_EnableCodeProtection()

end)()
