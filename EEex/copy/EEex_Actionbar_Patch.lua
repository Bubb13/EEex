
(function()

	EEex_DisableCodeProtection()

	-----------------------------------------------
	-- [Lua] EEex_Actionbar_Hook_StateUpdating() --
	-----------------------------------------------

	EEex_HookBeforeCall(EEex_Label("Hook-CInfButtonArray::SetState()-SaveArg"), {[[
		mov dword ptr ds:[rsp+70h], r15d ; store it in unused spill space
	]]})
	EEex_IntegrityCheck_IgnoreStackSizes(EEex_Label("Hook-CInfButtonArray::SetState()-SaveArg"), {{0x70, 4}})

	EEex_HookBeforeCallWithLabels(EEex_Label("Hook-CInfButtonArray::SetState()-CInfButtonArray::UpdateButtons()"), {
		{"integrity_ignore_registers", {
			EEex_IntegrityRegister.RDX, EEex_IntegrityRegister.R8, EEex_IntegrityRegister.R9,
			EEex_IntegrityRegister.R10, EEex_IntegrityRegister.R11
		}}},
		EEex_FlattenTable({
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
						mov edx, dword ptr ds:[rsp+#LAST_FRAME_TOP(70h)]
						mov qword ptr ss:[rsp+#$(1)], rdx ]], {rspOffset}, [[ #ENDL
					]]} end,
				},
			}),
			{[[
				call_error:
				#DESTROY_SHADOW_SPACE
				mov rcx, r14
			]]},
		})
	)

	-------------------------------------------------
	-- [Lua] EEex_Actionbar_Hook_HasFullThieving() --
	-------------------------------------------------

	EEex_HookAfterRestoreWithLabels(EEex_Label("Hook-CInfButtonArray::OnLButtonPressed()-HasFullThieving"), 0, 7, 11, {
		{"integrity_ignore_registers", {
			EEex_IntegrityRegister.RAX, EEex_IntegrityRegister.RDX, EEex_IntegrityRegister.R8,
			EEex_IntegrityRegister.R9, EEex_IntegrityRegister.R10, EEex_IntegrityRegister.R11
		}}},
		EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(48)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
			]]},
			EEex_GenLuaCall("EEex_Actionbar_Hook_HasFullThieving", {
				["args"] = {
					function(rspOffset) return {[[
						mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(48h)]
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
		})
	)

	-----------------------------------------------
	-- [Lua] EEex_Actionbar_Hook_IsPartyLeader() --
	-----------------------------------------------

	EEex_HookAfterCallWithLabels(EEex_Label("Hook-CAIGroup::IsPartyLeader()-Override"), {
		{"integrity_ignore_registers", {EEex_IntegrityRegister.RAX}}},
		EEex_FlattenTable({
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
		})
	)

	------------------------------------------------------------------------------------
	-- [Lua Global] EEex_Actionbar_HookGlobal_IsThievingHotkeyOpeningSpecialAbilities --
	------------------------------------------------------------------------------------

	EEex_HookBeforeAndAfterCallWithLabels(EEex_Label("Hook-CScreenWorld::OnKeyDown()-ThievingHotkeyPressSpecialAbilitiesCall"), {
		{"integrity_ignore_registers_0", {
			EEex_IntegrityRegister.R8, EEex_IntegrityRegister.R9, EEex_IntegrityRegister.R10, EEex_IntegrityRegister.R11
		}},
		{"integrity_ignore_registers_1", {EEex_IntegrityRegister.RAX}}},
		{[[
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
			#DESTROY_SHADOW_SPACE
		]]},
		{[[
			#MAKE_SHADOW_SPACE(8)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax

			mov rdx, 0
			mov rcx, #L(Hardcoded_InternalLuaState)
			call #L(Hardcoded_lua_pushboolean)
			mov rdx, #$(1) ]], {EEex_WriteStringCache("EEex_Actionbar_HookGlobal_IsThievingHotkeyOpeningSpecialAbilities")}, [[ #ENDL
			mov rcx, #L(Hardcoded_InternalLuaState)
			call #L(Hardcoded_lua_setglobal)

			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			#DESTROY_SHADOW_SPACE
		]]}
	)

	EEex_EnableCodeProtection()

end)()
