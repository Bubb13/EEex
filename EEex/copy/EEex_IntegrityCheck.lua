
EEex_IntegrityCheck_Load = false

(function()

	if not EEex_IntegrityCheck_Load then
		return
	end

	local integrityCheckEnter = EEex_JITNear({[[

		#STACK_MOD(8)
		#MAKE_SHADOW_SPACE(184)
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rcx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-24)], rdx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r8
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-40)], r9
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-48)], r10
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-56)], r11

		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-184)], rax
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-176)], rbx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-168)], rcx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-160)], rdx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-152)], rbp
		lea rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(56)]        ; 8<ret ptr> + 48<EEex_RoundUp(32<shadow space> + 16<local vars>, 16)>
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-144)], rax ; rsp
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-136)], rsi
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-128)], rdi
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-120)], r8
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-112)], r9
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-104)], r10
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-96)], r11
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-88)], r12
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-80)], r13
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-72)], r14
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-64)], r15

		lea r8, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-184)]
		mov rdx, qword ptr ds:[rsp+#LAST_FRAME_TOP(48)]        ; 8<ret ptr> + 32<shadow space> + 8<local vars[1]>
		mov rcx, qword ptr ss:[rsp+#LAST_FRAME_TOP(40)]        ; 8<ret ptr> + 32<shadow space> + 0<local vars[0]>
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

	local integrityCheckExit = EEex_JITNear({[[

		#STACK_MOD(8)
		#MAKE_SHADOW_SPACE(184)
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rcx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-24)], rdx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r8
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-40)], r9
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-48)], r10
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-56)], r11

		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-184)], rax
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-176)], rbx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-168)], rcx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-160)], rdx
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-152)], rbp
		lea rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(56)]        ; 8<ret ptr> + 48<EEex_RoundUp(32<shadow space> + 16<local vars>, 16)>
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-144)], rax ; rsp
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-136)], rsi
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-128)], rdi
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-120)], r8
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-112)], r9
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-104)], r10
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-96)], r11
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-88)], r12
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-80)], r13
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-72)], r14
		mov qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-64)], r15

		lea r8, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-184)]
		mov rdx, qword ptr ds:[rsp+#LAST_FRAME_TOP(48)]        ; 8<ret ptr> + 32<shadow space> + 8<local vars[1]>
		mov rcx, qword ptr ss:[rsp+#LAST_FRAME_TOP(40)]        ; 8<ret ptr> + 32<shadow space> + 0<local vars[0]>
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

	local cachedHookEnter = {}
	EEex_IntegrityCheck_HookEnter = function(instance)
		local cached = cachedHookEnter[instance]
		if cached then return cached end
		local t = {[[
			#MAKE_SHADOW_SPACE(16)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
			mov rax, #L(hook_address)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax
			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], ]], instance, [[ #ENDL
			call ]], integrityCheckEnter, [[ #ENDL
			#DESTROY_SHADOW_SPACE
		]]}
		cachedHookEnter[instance] = t
		return t
	end

	local cachedHookExit = {}
	EEex_IntegrityCheck_HookExit = function(instance)
		local cached = cachedHookExit[instance]
		if cached then return cached end
		local t = {[[
			#MAKE_SHADOW_SPACE(16)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax
			mov rax, #L(hook_address)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax
			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], ]], instance, [[ #ENDL
			call ]], integrityCheckExit, [[ #ENDL
			#DESTROY_SHADOW_SPACE
		]]}
		cachedHookExit[instance] = t
		return t
	end

	EEex_IntegrityCheck_IgnoreRegistersForInstance = function(address, instance, defaultRegisters)
		local ignoreFlags = EEex_Flags(defaultRegisters)
		local ignoredRegisters = EEex_TryLabel("integrity_ignore_registers_"..instance)
		if ignoredRegisters then
			ignoreFlags = EEex_BOr(ignoreFlags, EEex_Flags(ignoredRegisters))
		end
		EEex.IntegrityCheckIgnoreRegisters(address, instance, ignoreFlags)
	end

	EEex_IntegrityCheck_IgnoreRegisters = function(address, defaultRegisters)
		local ignoreFlags = EEex_Flags(defaultRegisters)
		local ignoredRegisters = EEex_TryLabel("integrity_ignore_registers")
		if ignoredRegisters then
			ignoreFlags = EEex_BOr(ignoreFlags, EEex_Flags(ignoredRegisters))
		end
		EEex.IntegrityCheckIgnoreRegisters(address, 0, ignoreFlags)
	end

	local ignoreStackSize = function(address, instance, offset, size)
		EEex.IntegrityCheckIgnoreStackRange(address, instance, offset, offset + size - 1)
	end

	EEex_IntegrityCheck_IgnoreStackSizesForInstance = function(address, instance, stackSizes)
		for _, stackSize in ipairs(stackSizes) do
			ignoreStackSize(address, instance, stackSize[1], stackSize[2])
		end
	end

	EEex_IntegrityCheck_IgnoreStackSizes = function(address, stackSizes)
		EEex_IntegrityCheck_IgnoreStackSizesForInstance(address, 0, stackSizes)
	end

end)()
