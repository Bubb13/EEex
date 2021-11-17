
EEex_DisableCodeProtection()

EEex_HookRelativeBranch(EEex_Label("Hook-CInfButtonArray::SetState()-SaveArg"), {[[
	mov dword ptr ds:[rsp+70h], r15d
	call #L(original)
	jmp #L(return)
]]})

EEex_HookRelativeBranch(EEex_Label("Hook-CInfButtonArray::SetState()-CInfButtonArray::UpdateButtons()"), EEex_FlattenTable({
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
			function(rspOffset) return {"mov qword ptr ss:[rsp+#$1], rax", {rspOffset}, "#ENDL"} end,
			function(rspOffset) return {[[
				mov edx, dword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(70h)]
				mov qword ptr ss:[rsp+#$1], rdx ]], {rspOffset}, [[ #ENDL
			]]} end,
		},
	}),
	{[[
		call_error:
		#DESTROY_SHADOW_SPACE
		mov rcx, r14
		call #L(original)
		jmp short #L(return) 
	]]},
}))

EEex_EnableCodeProtection()
