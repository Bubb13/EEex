
EEex_JITNearAsLabel("EEex_PrintPopLuaString", {[[

	mov qword ptr ss:[rsp+8], rbx
	mov qword ptr ss:[rsp+10h], rbp

	#MAKE_SHADOW_SPACE(16)

	mov rbx, rcx

	#ALIGN
	mov r8, 0    ; len
	mov rdx, -1  ; index
	mov rcx, rbx ; L
	call #L(Hardcoded_lua_tolstring)
	#ALIGN_END

	; L(Hardcoded_lua_pushstring) arg
	mov rbp, rax

	#ALIGN
	mov rdx, ]], EEex_WriteStringAuto("print"), [[ ; name
	mov rcx, rbx                                   ; L
	call #L(Hardcoded_lua_getglobal)
	#ALIGN_END

	#ALIGN
	mov rdx, rbp ; s
	mov rcx, rbx ; L
	call #L(Hardcoded_lua_pushstring)
	#ALIGN_END

	#ALIGN
	mov qword ptr ss:[rsp+8], 0 ; k
	mov qword ptr ss:[rsp], 0   ; ctx
	mov r9, 0                   ; errfunc
	mov r8, 0                   ; nresults
	mov rdx, 1                  ; nargs
	mov rcx, rbx                ; L
	call short #L(Hardcoded_lua_pcallk)
	#ALIGN_END

	; Clear error string off of stack
	#ALIGN
	mov rdx, -2  ; index
	mov rcx, rbx ; L
	call #L(Hardcoded_lua_settop)
	#ALIGN_END

	#DESTROY_SHADOW_SPACE

	mov rbp, qword ptr ss:[rsp+10h]
	mov rbx, qword ptr ss:[rsp+8]
	ret
]]})

EEex_JITNearAsLabel("EEex_CheckCallError", {[[

	test rax, rax
	jnz error
	ret

	error:
	#MAKE_SHADOW_SPACE

	#ALIGN
	call short #L(EEex_PrintPopLuaString)
	#ALIGN_END

	mov rax, 1
	#DESTROY_SHADOW_SPACE
	ret
]]})
