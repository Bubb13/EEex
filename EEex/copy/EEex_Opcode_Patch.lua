
(function()

	EEex_DisableCodeProtection()

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
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], rcx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], rdx", {rspOffset}, "#ENDL"}, "CGameObject" end,
				},
			}), [[

			call_error:
			#DESTROY_SHADOW_SPACE
			mov rax, 1
			ret
		]]}),
	})

	------------------------------
	-- EEex_ScreenEffects (403) --
	------------------------------

	local EEex_ScreenEffects = EEex_Opcode_GenDecode({

		["ApplyEffect"] = EEex_FlattenTable({[[

			#STACK_MOD(8) ; This was called, the ret ptr broke alignment
			#MAKE_SHADOW_SPACE(48)

			]], EEex_GenLuaCall("EEex_Opcode_Hook_ApplyScreenEffects", {
				["args"] = {
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], rcx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], rdx", {rspOffset}, "#ENDL"}, "CGameObject" end,
				},
			}), [[

			call_error:
			#DESTROY_SHADOW_SPACE
			mov rax, 1
			ret
		]]}),
	})

	EEex_Stats_Register("EEex_ScreenEffects", {
		["onConstruct"] = function(stats, aux)
			aux["EEex_ScreenEffects"] = {}
		end,
		["onReload"] = function(stats, aux, sprite)
			aux["EEex_ScreenEffects"] = {}
		end,
		["onEqu"] = function(stats, aux, otherStats, otherAux)
			local t = {}
			aux["EEex_ScreenEffects"] = t
			for i, effect in ipairs(otherAux["EEex_ScreenEffects"]) do
				t[i] = effect
			end
		end,
		["onPlusEqu"] = function(stats, aux, otherStats, otherAux)
			local insertI = #aux + 1
			for _, effect in ipairs(otherAux["EEex_ScreenEffects"]) do
				aux[insertI] = effect
				insertI = insertI + 1
			end
		end,
	})

	local effectBlockedHack = EEex_Malloc(0x8)

	EEex_HookJumpOnFail(EEex_Label("Hook-CGameEffect::CheckAdd()-LastProbabilityJmp"), 0, EEex_FlattenTable({[[

		#MAKE_SHADOW_SPACE(56)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rdx

		]], EEex_GenLuaCall("EEex_Opcode_Hook_OnCheckAdd", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], rdi #ENDL", {rspOffset}}, "CGameEffect" end,
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], r14 #ENDL", {rspOffset}}, "CGameSprite" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}), [[
		jmp no_error

		call_error:
		xor rax, rax

		no_error:
		mov qword ptr ds:[#$1], rax ]], {{effectBlockedHack}}, [[ #ENDL
		mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE
		test rax, rax
		jnz #L(Hook-CGameEffect::CheckAdd()-ProbabilityFailed)
	]]}))

	EEex_HookJumpOnSuccess(EEex_Label("Hook-CGameSprite::AddEffect()-noSave-Override"), 3, {[[
		cmp qword ptr ds:[#$1], 0 ]], {effectBlockedHack}, [[ #ENDL
		jnz jmp_fail
	]]})

	-------------------
	-- Decode Switch --
	-------------------

	EEex_HookJumpAutoFail(EEex_Label("Hook-CGameEffect::DecodeEffect()-DefaultJmp"), 0, EEex_FlattenTable({[[

		cmp eax, 367
		jbe jmp_fail

		cmp eax, 402
		jne _403
		]], EEex_InvokeLua, [[

		_403:
		cmp eax, 403
		jne #L(jmp_success)
		]], EEex_ScreenEffects, [[
	]]}))

	EEex_EnableCodeProtection()

end)()
