
function EEex_Opcode_GenDecode(args)

	local writeConstructor = function(vftable)
		return EEex_JITNear({[[
			push rbx
			sub rsp, 40h
			mov rax, qword ptr ss:[rsp+70h]
			mov rbx, rcx
			mov dword ptr ss:[rsp+30h], 0xFFFFFFFF
			mov dword ptr ss:[rsp+28h], 0x0
			mov qword ptr ss:[rsp+20h], rax
			call #L(CGameEffect::Construct)
			lea rax, qword ptr ds:[#$1] ]], {vftable}, [[ #ENDL
			mov qword ptr ds:[rbx], rax
			mov rax, rbx
			add rsp, 40h
			pop rbx
			ret
		]]})
	end
	
	local writeCopy = function(vftable)
		return EEex_JITNear({[[
			mov qword ptr ss:[rsp+8h], rbx
			mov qword ptr ss:[rsp+10h], rbp
			mov qword ptr ss:[rsp+18h], rsi
			push rdi
			sub rsp, 40h
			mov rsi, rcx
			call #L(CGameEffect::GetItemEffect)
			mov ecx, 158h
			mov rbp, rax
			call #L(operator_new)
			xor edi, edi
			mov rbx, rax
			test rax, rax
			je _1
			mov rdx, qword ptr ds:[rsi+88h]
			lea r8, qword ptr ds:[rsi+80h]
			mov r9d, dword ptr ds:[rsi+110h]
			mov rcx, rax
			mov dword ptr ss:[rsp+30h], 0xFFFFFFFF
			mov dword ptr ss:[rsp+28h], edi
			mov qword ptr ss:[rsp+20h], rdx
			mov rdx, rbp
			call #L(CGameEffect::Construct)
			lea rax, qword ptr ds:[#$1] ]], {vftable}, [[ #ENDL
			mov qword ptr ds:[rbx], rax
			jmp _2
			_1:
			mov rbx, rdi
			_2:
			mov edx, 30h
			mov rcx, rbp
			call #L(Hardcoded_free)                             ; SDL_FreeRW
			test rsi, rsi
			lea rdx, qword ptr ds:[rsi+8h]
			mov rcx, rbx
			cmove rdx, rdi
			call #L(CGameEffect::CopyFromBase)
			mov rbp, qword ptr ss:[rsp+58h]
			mov rax, rbx
			mov rbx, qword ptr ss:[rsp+50h]
			mov rsi, qword ptr ss:[rsp+60h]
			add rsp, 40h
			pop rdi
			ret
		]]})
	end

	local genDecode = function(constructor)
		return {[[
			mov ecx, #$1 ]], {CGameEffect.sizeof}, [[ #ENDL
			call #L(operator_new)
			mov rcx, rax                                     ; this
			test rax, rax
			jz #L(Hook-CGameEffect::DecodeEffect()-Fail)
			mov rax, qword ptr ds:[rsi]                      ; target
			mov qword ptr [rsp+20h], rax
			mov r9d, ebp                                     ; sourceID
			mov r8, r14                                      ; source
			mov rdx, rdi                                     ; effect
			call #$1 ]], {constructor}, [[ #ENDL
			jmp #L(Hook-CGameEffect::DecodeEffect()-Success)
		]]}
	end

	local vtblsize = _G["CGameEffect::vtbl"].sizeof
	local newvtbl = EEex_Malloc(vtblsize)
	EEex_Memcpy(newvtbl, EEex_Label("Data-CGameEffect::vftable"), vtblsize)

	EEex_WriteArgs(newvtbl, args, {
		{ "__vecDelDtor",  0  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
		{ "Copy",          1  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.DEFAULT, writeCopy(newvtbl) },
		{ "ApplyEffect",   2  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
		{ "ResolveEffect", 3  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
		{ "OnAdd",         4  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
		{ "OnAddSpecific", 5  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
		{ "OnLoad",        6  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
		{ "CheckSave",     7  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
		{ "UsesDice",      8  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
		{ "DisplayString", 9  * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
		{ "OnRemove",      10 * EEex_PtrSize, EEex_WriteType.JIT, EEex_WriteFailType.NOTHING                     },
	})

	return genDecode(writeConstructor(newvtbl))
end
