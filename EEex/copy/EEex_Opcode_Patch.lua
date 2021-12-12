
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
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], rcx", {rspOffset}, "#ENDL"}, "CGameObject" end,
					function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], rdx", {rspOffset}, "#ENDL"}, "CGameEffect" end,
				},
			}), [[

			#DESTROY_SHADOW_SPACE
			ret
		]]}),
	})

	EEex_HookJumpAutoFail(EEex_Label("Hook-CGameEffect::DecodeEffect()-DefaultJmp"), 0, EEex_FlattenTable({[[

		cmp eax, 367
		jbe jmp_fail

		cmp eax, 402
		jne #L(jmp_success)

		]], EEex_InvokeLua, [[
	]]}))

	EEex_EnableCodeProtection()

end)()
