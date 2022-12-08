
EEex_JITNearAsLabel("EEex_PrintPopLuaString", {[[

	push 0   ; len
	push -1  ; index
	push ebx ; L
	call #L(Hardcoded_lua_tolstring)
	add esp, 0xC

	; used in #L(Hardcoded_lua_pushstring) below
	push eax

	push ]], EEex_WriteStringCache("print"), [[ ; name
	push ebx                                    ; L
	call #L(Hardcoded_lua_getglobal)
	add esp, 8

	push ebx ; L
	call #L(Hardcoded_lua_pushstring)
	add esp, 8

	push 0   ; k
	push 0   ; ctx
	push 0   ; errfunc
	push 0   ; nresults
	push 1   ; nargs
	push ebx ; L
	call #L(Hardcoded_lua_pcallk)
	add esp, 0x18

	; Clear error string off of stack
	push -2  ; index
	push ebx ; L
	call #L(Hardcoded_lua_settop)
	add esp, 8
	ret
]]})

EEex_JITNearAsLabel("EEex_CheckCallError", {[[

	test eax, eax
	jnz error
	ret

	error:
	call #L(EEex_PrintPopLuaString)
	mov eax, 1
	ret
]]})
