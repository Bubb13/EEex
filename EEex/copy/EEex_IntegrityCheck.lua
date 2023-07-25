
EEex_IntegrityCheck_Load = true

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
		#MAKE_SHADOW_SPACE(80)
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax

		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-80)], rbx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-72)], rbp
		lea rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(56)] ; 8<ret ptr> + 48<EEex_RoundUp(32<shadow space> + 16<local vars>, 16)>
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-64)], rax
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-56)], rsi
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-48)], rdi
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-40)], r12
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r13
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r14
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-16)], r15

		lea r8, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-80)]
		lea rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(56)] ; 8<ret ptr> + 48<EEex_RoundUp(32<shadow space> + 16<local vars>, 16)>
		mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(40)] ; 8<ret ptr> + 32<shadow space>
		call #L(EEex::IntegrityCheckExit)

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

	local integrityCheck = function(address, originalCall)
		return EEex_FlattenTable({
			{[[
				#MAKE_SHADOW_SPACE(16)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
				mov rax, ]], address, [[ #ENDL
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax
				mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				call ]], EEex_IntegrityCheck_Enter, [[ #ENDL
				#DESTROY_SHADOW_SPACE
			]]},
			originalCall,
			{[[
				#MAKE_SHADOW_SPACE(16)
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
				mov rax, ]], address, [[ #ENDL
				mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax
				mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
				call ]], EEex_IntegrityCheck_Exit, [[ #ENDL
				#DESTROY_SHADOW_SPACE
			]]},
		})
	end

	if false then

		EEex_DisableCodeProtection()

		local installIntegrityCheck = function(address)
			EEex_HookRelativeBranch(address, EEex_FlattenTable({
				integrityCheck(address, {"call #L(original) #ENDL"}),
				{[[
					jmp #L(return)
				]]},
			}))
		end

		installIntegrityCheck(0x14014DDC1)
		EEex.IntegrityCheckIgnoreStackRange(0x14014DDC1, 0x68, 0x68 + CAIObjectType.sizeof - 1)

		EEex_HookNOPs(0x14014DE70, 1, EEex_FlattenTable({
			integrityCheck(0x14014DE70, {"call qword ptr ds:[rax+0xC8] #ENDL"}),
			{[[
				jmp #L(return)
			]]},
		}))

		installIntegrityCheck(0x14014DE87)
		EEex.IntegrityCheckIgnoreStackRange(0x14014DE87, 0x68, 0x68 + CAIObjectType.sizeof - 1)

		installIntegrityCheck(0x14014DE94)
		EEex.IntegrityCheckIgnoreStackRange(0x14014DE94, 0x68, 0x68 + CAIObjectType.sizeof - 1)

		installIntegrityCheck(0x14014DEAA)
		installIntegrityCheck(0x14014DED3)
		installIntegrityCheck(0x14014DF20)
		installIntegrityCheck(0x14014DF30)
		installIntegrityCheck(0x14014DF63)
		installIntegrityCheck(0x14014DF73)
		installIntegrityCheck(0x14014DFA6)
		installIntegrityCheck(0x14014DFD7)
		installIntegrityCheck(0x14014DFEB)
		installIntegrityCheck(0x14014E044)
		installIntegrityCheck(0x14014E05D)
		installIntegrityCheck(0x14014E076)
		installIntegrityCheck(0x14014E081)
		installIntegrityCheck(0x14014E08E)
		installIntegrityCheck(0x14014E0E0)
		installIntegrityCheck(0x14014E0F0)

		EEex_EnableCodeProtection()
	end

end)()
