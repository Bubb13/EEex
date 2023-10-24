
EEex_IntegrityCheck_Load = false

(function()

	if not EEex_IntegrityCheck_Load then
		return
	end

	EEex_IntegrityCheck_Enter = EEex_JITNear({[[

		#STACK_MOD(8)
		#MAKE_SHADOW_SPACE(128)
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rcx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-24)], rdx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r8
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-40)], r9
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-48)], r10
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-56)], r11

		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-128)], rbx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-120)], rbp
		lea rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(56)] ; 8<ret ptr> + 48<EEex_RoundUp(32<shadow space> + 16<local vars>, 16)>
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-112)], rax
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-104)], rsi
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-96)], rdi
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-88)], r12
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-80)], r13
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-72)], r14
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-64)], r15

		lea r8, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-128)]
		lea rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(56)] ; 8<ret ptr> + 48<EEex_RoundUp(32<shadow space> + 16<local vars>, 16)>
		mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(40)] ; 8<ret ptr> + 32<shadow space>
		call #L(EEex::IntegrityCheckEnter)

		mov r11, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-56)]
		mov r10, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-48)]
		mov r9, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-40)]
		mov r8, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
		mov rdx, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
		mov rcx, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
		mov rax, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE
		ret
	]]})

	EEex_IntegrityCheck_Exit = EEex_JITNear({[[

		#STACK_MOD(8)
		#MAKE_SHADOW_SPACE(128)
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rcx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-24)], rdx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r8
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-40)], r9
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-48)], r10
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-56)], r11

		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-128)], rbx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-120)], rbp
		lea rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(56)] ; 8<ret ptr> + 48<EEex_RoundUp(32<shadow space> + 16<local vars>, 16)>
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-112)], rax
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-104)], rsi
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-96)], rdi
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-88)], r12
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-80)], r13
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-72)], r14
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-64)], r15

		lea r8, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-128)]
		lea rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(56)] ; 8<ret ptr> + 48<EEex_RoundUp(32<shadow space> + 16<local vars>, 16)>
		mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(40)] ; 8<ret ptr> + 32<shadow space>
		call #L(EEex::IntegrityCheckExit)

		mov r11, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-56)]
		mov r10, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-48)]
		mov r9, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-40)]
		mov r8, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
		mov rdx, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
		mov rcx, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
		mov rax, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		#DESTROY_SHADOW_SPACE
		ret
	]]})

	EEex_IntegrityCheck_HookEnter = {[[
		#MAKE_SHADOW_SPACE(16)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		mov rax, #L(hook_address)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax
		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		call ]], EEex_IntegrityCheck_Enter, [[ #ENDL
		#DESTROY_SHADOW_SPACE
	]]}

	EEex_IntegrityCheck_HookExit = {[[
		#MAKE_SHADOW_SPACE(16)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		mov rax, #L(hook_address)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax
		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
		call ]], EEex_IntegrityCheck_Exit, [[ #ENDL
		#DESTROY_SHADOW_SPACE
	]]}

	EEex_IntegrityCheck_IgnoreStackSize = function(address, offset, size)
		EEex.IntegrityCheckIgnoreStackRange(address, offset, offset + size - 1)
	end

	EEex_IntegrityCheck_IgnoreStackSizes = function(address, stackSizes)
		for _, stackSize in ipairs(stackSizes) do
			EEex_IntegrityCheck_IgnoreStackSize(address, stackSize[1], stackSize[2])
		end
	end

end)()
