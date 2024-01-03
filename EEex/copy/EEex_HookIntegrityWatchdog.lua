
EEex_HookIntegrityWatchdog_Load = true

(function()

	if not EEex_HookIntegrityWatchdog_Load then
		return
	end

	local hookIntegrityWatchdogEnter = EEex_JITNear({[[

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
		mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(48)]        ; 8<ret ptr> + 32<shadow space> + 8<local vars[1]>
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

		lea rdx, qword ptr ds:[rsp+#SHADOW_SPACE_BOTTOM(-184)]
		mov rcx, qword ptr ss:[rsp+#LAST_FRAME_TOP(40)]        ; 8<ret ptr> + 32<shadow space> + 0<local vars[0]>
		call #L(EEex::HookIntegrityWatchdogEnter)

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

	local hookIntegrityWatchdogExit = EEex_JITNear({[[

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
		mov rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(56)]        ; 8<ret ptr> + 32<shadow space> + 16<local vars[2]>
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
		call #L(EEex::HookIntegrityWatchdogExit)

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

	EEex_HookIntegrityWatchdog_HookEnter = {[[

		#MAKE_SHADOW_SPACE(32)
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax  ; Save RAX
		pushfq #STACK_MOD(8)                                  ; Save status flags
		pop rax #STACK_MOD(-8)
		and rax, 0x8D5
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax

		lea rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(0)]        ; Save previous frame's rsp as second stack arg
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], rax

		mov rax, #L(hook_address)                             ; Save hook address as first stack arg
		mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], rax

		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]  ; Restore RAX
		call ]], hookIntegrityWatchdogEnter, [[ #ENDL

		pushfq #STACK_MOD(8)                                  ; Restore status flags
		and qword ptr ss:[rsp], 0xFFFFFFFFFFFFF72A
		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
		or qword ptr ss:[rsp], rax
		popfq #STACK_MOD(-8)
		mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]  ; Restore RAX (again)
		#DESTROY_SHADOW_SPACE
	]]}

	local cachedHookExit = {}
	EEex_HookIntegrityWatchdog_HookExit = function(instance)
		local cached = cachedHookExit[instance]
		if cached then return cached end
		local t = {[[

			#MAKE_SHADOW_SPACE(40)
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rax               ; Save RAX
			pushfq #STACK_MOD(8)                                               ; Save status flags
			pop rax #STACK_MOD(-8)
			and rax, 0x8D5
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rax

			lea rax, qword ptr ss:[rsp+#LAST_FRAME_TOP(0)]                     ; Save previous frame's rsp as third stack arg
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], rax

			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], ]], instance, [[ ; Save instance as second stack arg

			mov rax, #L(hook_address)                                          ; Save hook address as first stack arg
			mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-40)], rax

			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]               ; Restore RAX
			call ]], hookIntegrityWatchdogExit, [[ #ENDL

			pushfq #STACK_MOD(8)                                               ; Restore status flags
			and qword ptr ss:[rsp], 0xFFFFFFFFFFFFF72A
			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
			or qword ptr ss:[rsp], rax
			popfq #STACK_MOD(-8)
			mov rax, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]               ; Restore RAX (again)
			#DESTROY_SHADOW_SPACE
		]]}
		cachedHookExit[instance] = t
		return t
	end

	EEex_HookIntegrityWatchdog_IgnoreRegistersForInstance = function(address, instance, defaultRegisters)
		local ignoreFlags = EEex_Flags(defaultRegisters)
		local ignoredRegisters = EEex_TryLabel("hook_integrity_watchdog_ignore_registers_"..instance)
		if ignoredRegisters then
			ignoreFlags = EEex_BOr(ignoreFlags, EEex_Flags(ignoredRegisters))
		end
		EEex.HookIntegrityWatchdogIgnoreRegisters(address, instance, ignoreFlags)
	end

	EEex_HookIntegrityWatchdog_IgnoreRegisters = function(address, defaultRegisters)
		local ignoreFlags = EEex_Flags(defaultRegisters)
		local ignoredRegisters = EEex_TryLabel("hook_integrity_watchdog_ignore_registers")
		if ignoredRegisters then
			ignoreFlags = EEex_BOr(ignoreFlags, EEex_Flags(ignoredRegisters))
		end
		EEex.HookIntegrityWatchdogIgnoreRegisters(address, 0, ignoreFlags)
	end

	local ignoreStackSize = function(address, instance, offset, size)
		EEex.HookIntegrityWatchdogIgnoreStackRange(address, instance, offset, offset + size - 1)
	end

	EEex_HookIntegrityWatchdog_DefaultIgnoreStackForInstance = function(address, instance)
		-- Stack mod indicates that the hook isn't operating in the usual stack frame. None of
		-- the stack should be ignored if stack_mod is defined, as the shadow space at the top
		-- of the stack actually belongs to the called function that's being hooked.
		if not EEex_TryLabel("stack_mod") then
			ignoreStackSize(address, instance, 0, 32)
		end
	end

	EEex_HookIntegrityWatchdog_DefaultIgnoreStack = function(address)
		EEex_HookIntegrityWatchdog_DefaultIgnoreStackForInstance(address, 0)
	end

	EEex_HookIntegrityWatchdog_IgnoreStackSizesForInstance = function(address, instance, stackSizes)
		for _, stackSize in ipairs(stackSizes) do
			ignoreStackSize(address, instance, stackSize[1], stackSize[2])
		end
	end

	EEex_HookIntegrityWatchdog_IgnoreStackSizes = function(address, stackSizes)
		EEex_HookIntegrityWatchdog_IgnoreStackSizesForInstance(address, 0, stackSizes)
	end

end)()
