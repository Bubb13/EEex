
(function()

	EEex_DisableCodeProtection()

	-----------------------------------------------
	-- [Lua] EEex_Actionbar_Hook_StateUpdating() --
	-----------------------------------------------

	EEex_HookRelativeCall(EEex_Label("Hook-CInfButtonArray::SetState()-SaveArg"), {[[
		mov dword ptr ds:[rsp+70h], r15d
		call #L(original)
	]]})
	EEex_IntegrityCheck_IgnoreStackSizes(EEex_Label("Hook-CInfButtonArray::SetState()-SaveArg"), {
		{0x20, CResRef.sizeof},
		{0x70, 4},
	})

	EEex_HookRelativeCall(EEex_Label("Hook-CInfButtonArray::SetState()-CInfButtonArray::UpdateButtons()"), EEex_FlattenTable({
		{[[
			mov eax, dword ptr ds:[rsp+70h]
			dec eax
			cmp eax, 71h
			ja NoConfig

			mov rdx, #L(Data-CInfButtonArray::SetState()-IndirectJumpTable)
			movzx eax, byte ptr ds:[rdx+rax]
			jmp CallHook

			NoConfig:
			mov rax, -1

			CallHook:
			#MAKE_SHADOW_SPACE(48)
		]]},
		EEex_GenLuaCall("EEex_Actionbar_Hook_StateUpdating", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rax", {rspOffset}, "#ENDL"} end,
				function(rspOffset) return {[[
					mov edx, dword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(70h)]
					mov qword ptr ss:[rsp+#$(1)], rdx ]], {rspOffset}, [[ #ENDL
				]]} end,
			},
		}),
		{[[
			call_error:
			#DESTROY_SHADOW_SPACE
			mov rcx, r14
			call #L(original)
		]]},
	}))

	-------------------------------------------------
	-- [Lua] EEex_Actionbar_Hook_HasFullThieving() --
	-------------------------------------------------

	EEex_HookAfterRestore(EEex_Label("Hook-CInfButtonArray::OnLButtonPressed()-HasFullThieving"), 0, 7, 11, EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(48)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
		]]},
		EEex_GenLuaCall("EEex_Actionbar_Hook_HasFullThieving", {
			["args"] = {
				function(rspOffset) return {[[
					mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(48h)]
					mov qword ptr ss:[rsp+#$(1)], rax
				]], {rspOffset}}, "CGameSprite" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}),
		{[[
			jmp no_error

			call_error:
			mov rax, 1

			no_error:
			mov dl, 24h
			test rax, rax
			jnz full_thieving

			mov dl, 28h

			full_thieving:
			mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	-----------------------------------------------
	-- [Lua] EEex_Actionbar_Hook_IsPartyLeader() --
	-----------------------------------------------

	EEex_HookAfterCall(EEex_Label("Hook-CAIGroup::IsPartyLeader()-Override"), EEex_FlattenTable({
		{[[
			test rax, rax
			jnz #L(return)

			#MAKE_SHADOW_SPACE(40)
		]]},
		EEex_GenLuaCall("EEex_Actionbar_Hook_IsPartyLeader", {
			["args"] = {
				function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], rbx #ENDL", {rspOffset}}, "CGameSprite" end,
			},
			["returnType"] = EEex_LuaCallReturnType.Boolean,
		}),
		{[[
			jmp no_error

			call_error:
			xor rax, rax

			no_error:
			#DESTROY_SHADOW_SPACE
		]]},
	}))

	------------------------------------------------------------------------------------
	-- [Lua Global] EEex_Actionbar_HookGlobal_IsThievingHotkeyOpeningSpecialAbilities --
	------------------------------------------------------------------------------------

	EEex_HookRelativeCall(EEex_Label("Hook-CScreenWorld::OnKeyDown()-ThievingHotkeyPressSpecialAbilitiesCall"), {[[

		#MAKE_SHADOW_SPACE(16)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx

		mov rdx, 1
		mov rcx, #L(Hardcoded_InternalLuaState)
		call #L(Hardcoded_lua_pushboolean)
		mov rdx, #$(1) ]], {EEex_WriteStringCache("EEex_Actionbar_HookGlobal_IsThievingHotkeyOpeningSpecialAbilities")}, [[ #ENDL
		mov rcx, #L(Hardcoded_InternalLuaState)
		call #L(Hardcoded_lua_setglobal)

		mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
		mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		call #L(original)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax

		mov rdx, 0
		mov rcx, #L(Hardcoded_InternalLuaState)
		call #L(Hardcoded_lua_pushboolean)
		mov rdx, #$(1) ]], {EEex_WriteStringCache("EEex_Actionbar_HookGlobal_IsThievingHotkeyOpeningSpecialAbilities")}, [[ #ENDL
		mov rcx, #L(Hardcoded_InternalLuaState)
		call #L(Hardcoded_lua_setglobal)

		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE
	]]})

	EEex_EnableCodeProtection()

end)()
