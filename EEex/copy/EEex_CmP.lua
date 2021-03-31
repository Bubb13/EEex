
--------------------
-- Initialization --
--------------------

(function()

	if not pcall(function()

		-- !!!----------------------------------------------------------------!!!
		--  | EEex_Init() is the only new function that is exposed by default. |
		--  | It does several things:                                          |
		--  |                                                                  |
		--  |   1. Exposes the hardcoded function EEex_WriteByte()             |
		--  |                                                                  |
		--  |   2. Exposes the hardcoded function EEex_ExposeToLua()           |
		--  |                                                                  |
		--  |   3. Calls VirtualAlloc() with the following params =>           |
		--  |        lpAddress = 0                                             |
		--  |        dwSize = 0x1000                                           |
		--  |        flAllocationType = MEM_COMMIT | MEM_RESERVE               |
		--  |        flProtect = PAGE_EXECUTE_READWRITE                        |
		--  |                                                                  |
		--  |   4. Passes along the VirtualAlloc()'s return value              |
		-- !!! ---------------------------------------------------------------!!!

		EEex_InitialMemory = EEex_Init()

	end) then
		-- Failed to initialize EEex!
		error("ERROR\n\n[EEex] EEex is disabled: DLL not injected. Please start the game using EEex.exe.\n\n\z
				The program will crash after you press OK.")
	end

	-- Inform the dynamic memory system of the hardcoded starting memory.
	table.insert(EEex_CodePageAllocations, {
		{["address"] = EEex_InitialMemory, ["size"] = 0x1000, ["reserved"] = false}
	})

	-- Fetch the matched pattern addresses from the loader, (thanks @mrfearless!)
	-- => https://github.com/mrfearless/EEexLoader
	EEex_GlobalAssemblyLabels = EEex_AddressList()

	---------------------
	-- Assembly Macros --
	---------------------

	Infinity_DoFile("EEex_Mac")

	-------------------------------------------
	-- Functions needed for resolving labels --
	-------------------------------------------

	-- Reads a dword at the given address.
	-- SIGNATURE:
	-- number result = EEex_ReadDword(number address)
	EEex_WriteAssemblyFunction("EEex_ReadDword", {[[

		$EEex_ReadDword
		!push_state

		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse

		!push_[eax]
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[ebp+byte] 08
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!mov_eax #1
		!pop_state
		!ret
	]]})

	-----------------------------
	-- Finish label processing --
	-----------------------------

	local resolveLabelAsRelative = function(label)
		local val = EEex_GlobalAssemblyLabels[label]
		EEex_GlobalAssemblyLabels[label] = val + EEex_ReadDword(val) + 0x4
	end

	resolveLabelAsRelative("_lua_pushvalue")

	print("[EEex] Labels Dump:")
	for label, entry in pairs(EEex_GlobalAssemblyLabels) do
		if type(entry) == "table" then
			print("    "..label..": ")
			for _, val in ipairs(entry) do
				print("        "..EEex_ToHex(val))
			end
		else
			print("    "..label..": "..EEex_ToHex(entry))
		end
	end
	print("")

	------------------------
	--  Default Functions --
	------------------------

	-- Calls an internal function at the given address.

	-- stackArgs: Includes the values to be pushed before the function is called.
	--            Note that the stackArgs are pushed in the order they are defined,
	--            so in order to call a function properly these args should be defined in reverse.

	-- ecx: Sets the ecx register to the given value directly before calling the internal function.
	--      The ecx register is most commonly used to pass the "this" pointer.

	-- popSize: Some internal functions don't clean up the stackArgs pushed to them. This value
	--          defines the size, (in bytes), that should be removed from the stack after the
	--          internal function is called. Please note that if this value is wrong, the game
	--          WILL crash due to an imbalanced stack.

	-- SIGNATURE:
	-- number eax = EEex_Call(number address, table stackArgs, number ecx, number popSize)
	EEex_WriteAssemblyFunction("EEex_Call", {[[
		$EEex_Call
		!push_state
		!push_byte 02
		!push_[ebp+byte] 08
		!call >_lua_rawlen
		!add_esp_byte 08
		!test_eax_eax
		!je_dword >no_args
		!mov_edi_eax
		!mov_esi #01
		@arg_loop
		!push_esi
		!push_byte 02
		!push_[ebp+byte] 08
		!call >_lua_rawgeti
		!add_esp_byte 0C
		!push_byte 00
		!push_byte FF
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax
		!push_byte FE
		!push_[ebp+byte] 08
		!call >_lua_settop
		!add_esp_byte 08
		!inc_esi
		!cmp_esi_edi
		!jle_dword >arg_loop
		@no_args
		!push_byte 00
		!push_byte 03
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax
		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!pop_ecx
		!call_eax
		!push_eax
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[ebp+byte] 08
		!call >_lua_pushnumber
		!add_esp_byte 0C
		!push_byte 00
		!push_byte 04
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!add_esp_eax
		!mov_eax #01
		!pop_state
		!ret
	]]})

	-- Writes the given string at the specified address.
	-- NOTE: Writes a terminating NULL in addition to the raw string.
	-- SIGNATURE:
	-- <void> = EEex_WriteString(number address, string toWrite)
	EEex_WriteAssemblyFunction("EEex_WriteString", {[[

		$EEex_WriteString
		!build_stack_frame
		!push_registers

		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!mov_edi_eax

		!push_byte 00
		!push_byte 02
		!push_[ebp+byte] 08
		!call >_lua_tolstring
		!add_esp_byte 0C

		!mov_esi_eax

		@copy_loop
		!mov_al_[esi]
		!mov_[edi]_al
		!inc_esi
		!inc_edi
		!cmp_byte:[esi]_byte 00
		!jne_dword >copy_loop

		!mov_byte:[edi]_byte 00

		!xor_eax_eax
		!restore_stack_frame
		!ret

	]]})

	----------------------------------------------------------------
	-- *** Prevent D3D from lowering FPU precision ***            --
	-- Sets D3DCREATE_FPU_PRESERVE flag, see here:                --
	-- docs.microsoft.com/en-us/windows/win32/direct3d9/d3dcreate --
	----------------------------------------------------------------

	EEex_DisableCodeProtection()

	EEex_WriteByte(EEex_Label("DrawInit_DX()_FixFPU1"), 0x42)
	EEex_WriteByte(EEex_Label("DrawInit_DX()_FixFPU2"), 0x22)

	EEex_EnableCodeProtection()

	----------------------------
	-- More default functions --
	----------------------------

	EEex_WriteAssemblyAuto({[[

		$EEex_PrintPopLuaString
		!build_stack_frame

		!push_byte 00
		!push_byte FF
		!push_[ebp+byte] 08
		!call >_lua_tolstring
		!add_esp_byte 0C

		; _lua_pushstring arg ;
		!push_eax

		!push_dword ]], {EEex_WriteStringAuto("print"), 4}, [[
		!push_[ebp+byte] 08
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_[ebp+byte] 08
		!call >_lua_pushstring
		!add_esp_byte 08

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_pcallk
		!add_esp_byte 18

		; Clear error string off of stack ;
		!push_byte FE
		!push_[ebp+byte] 08
		!call >_lua_settop
		!add_esp_byte 08

		!destroy_stack_frame
		!ret_word 04 00
	]]})

	EEex_WriteAssemblyAuto({[[

		$EEex_CheckCallError
		!test_eax_eax
		!jnz_dword >error
		!ret_word 04 00

		@error
		!push_[esp+byte] 04
		!call >EEex_PrintPopLuaString

		!mov_eax #1
		!ret_word 04 00
	]]})

	EEex_WriteAssemblyFunction("EEex_RunWithStack", EEex_FlattenTable({
		{[[
			$EEex_RunWithStack
			!mark_esp
			!push(ebx)
			!push(esi)
			!marked_esp !mov(ebx,[esp+4])
			!push(0)
			!push(1)
			!push(ebx)
			!call >_lua_tonumberx
			!add(esp,C)
			!call >__ftol2_sse

			; ROUND UP TO 32-BIT STACK ALIGNMENT ;
			!mov(ecx,eax)
			!and(ecx,FFFFFFFC)
			!cmp(eax,ecx)
			!je_dword >rounding_done
			!add(ecx,4)

			@rounding_done
			!mov(esi,ecx)
			!sub(esp,esi)
		]]},
		EEex_GenLuaCall(nil, {
			["luaState"] = {},
			["pushFunction"] = {[[
				!push(2)
				!push(ebx)
				!call >_lua_pushvalue
				!add(esp,8)
			]]},
			["args"] = {
				{"!push(esp)"},
			},
		}),
		{[[
			@call_error
			!add(esp,esi)
			!xor(eax,eax)
			!pop(esi)
			!pop(ebx)
			!ret
		]]},
	}))

	-- Writes a string to the given address, padding any remaining space with null bytes to achieve desired length.
	-- If #toWrite >= to maxLength, terminating null is not written.
	-- If #toWrite > maxLength, characters after [1, maxLength] are discarded and not written.
	-- SIGNATURE:
	-- <void> = EEex_WriteLString(number address, string toWrite, number maxLength)
	EEex_WriteAssemblyFunction("EEex_WriteLString", {[[

		$EEex_WriteLString
		!build_stack_frame
		!push_registers

		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!mov_edi_eax

		!push_byte 00
		!push_byte 02
		!push_[ebp+byte] 08
		!call >_lua_tolstring
		!add_esp_byte 0C
		!mov_esi_eax

		!push_byte 00
		!push_byte 03
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!mov_ebx_eax

		!xor_edx_edx

		!cmp_edx_ebx
		!jae_dword >return

		!cmp_byte:[esi]_byte 00
		!je_dword >null_loop

		@copy_loop

		!mov_al_[esi]
		!mov_[edi]_al
		!inc_esi
		!inc_edi

		!inc_edx
		!cmp_edx_ebx
		!jae_dword >return

		!cmp_byte:[esi]_byte 00
		!jne_dword >copy_loop

		@null_loop
		!mov_byte:[edi]_byte 00
		!inc_edi

		!inc_edx
		!cmp_edx_ebx
		!jb_dword >null_loop

		@return
		!xor_eax_eax
		!restore_stack_frame
		!ret

	]]})

	-- Reads a string from the given address until a NULL is encountered.
	-- NOTE: Certain game structures, (most commonly resrefs), don't
	-- necessarily end in a NULL. Regarding resrefs, if one uses all
	-- 8 characters of alloted space, no NULL will be written. To read
	-- this properly, please use EEex_ReadLString with maxLength set to 8.
	-- In cases where the string is guaranteed to have a terminating NULL,
	-- use this function.
	-- SIGNATURE:
	-- string result = EEex_ReadString(number address)
	EEex_WriteAssemblyFunction("EEex_ReadString", {[[
		$EEex_ReadString
		!push_state
		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax
		!push_[ebp+byte] 08
		!call >_lua_pushstring
		!add_esp_byte 08
		!mov_eax #01
		!pop_state
		!ret
	]]})

	-- This is much longer than EEex_ReadString because it had to use new behavior.
	-- Reads until NULL is encountered, OR until it reaches the given length.
	-- Registers esi, ebx, and edi are all assumed to be non-volitile.
	-- SIGNATURE:
	-- string result = EEex_ReadLString(number address, number maxLength)
	EEex_WriteAssemblyFunction("EEex_ReadLString", {[[
		$EEex_ReadLString
		!build_stack_frame
		!sub_esp_byte 08
		!push_registers
		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!mov_esi_eax
		!push_byte 00
		!push_byte 02
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!mov_ebx_eax
		!and_eax_byte FC
		!add_eax_byte 04
		!mov_[ebp+byte]_esp FC
		!sub_esp_eax
		!mov_edi_esp
		!mov_[ebp+byte]_edi F8
		!add_ebx_esi
		@read_loop
		!mov_al_[esi]
		!mov_[edi]_al
		!test_al_al
		!je_dword >done
		!inc_esi
		!inc_edi
		!cmp_esi_ebx
		!jl_dword >read_loop
		!mov_[edi]_byte 00
		@done
		!push_[ebp+byte] F8
		!push_[ebp+byte] 08
		!call >_lua_pushstring
		!add_esp_byte 08
		!mov_esp_[ebp+byte] FC
		!mov_eax #01
		!restore_stack_frame
		!ret
	]]})

	-- Returns the memory address of the given userdata object.
	-- SIGNATURE:
	-- number result = EEex_ReadUserdata(userdata value)
	EEex_WriteAssemblyFunction("EEex_ReadUserdata", {
		"$EEex_ReadUserdata 55 8B EC 53 51 52 56 57 6A 01 FF 75 08 \z
		!call >_lua_touserdata \z
		83 C4 08 50 DB 04 24 83 EC 04 DD 1C 24 FF 75 08 \z
		!call >_lua_pushnumber \z
		83 C4 0C B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})

	-- Returns a lightuserdata object that points to the given address.
	-- SIGNATURE:
	-- userdata result = EEex_ToLightUserdata(number address)
	EEex_WriteAssemblyFunction("EEex_ToLightUserdata", {
		"$EEex_ToLightUserdata 55 8B EC 53 51 52 56 57 6A 00 6A 01 FF 75 08 \z
		!call >_lua_tonumberx \z
		83 C4 0C \z
		!call >__ftol2_sse \z
		50 FF 75 08 \z
		!call >_lua_pushlightuserdata \z
		83 C4 08 B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})

	-- Fetches a value held in the special Lua REGISTRY space.
	-- This is where compiled .MENU functions - the ones in actual
	-- menu definitions, not the loose kind - are held, (among other things).
	-- Signature: <unknown_type> registryValue = EEex_GetLuaRegistryIndex(registryIndex)
	EEex_WriteAssemblyFunction("EEex_GetLuaRegistryIndex", {[[

		!build_stack_frame
		!push_registers

		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse

		!push_eax
		!push_dword #0FFF0B9D8
		!push_[ebp+byte] 08
		!call >_lua_rawgeti
		!add_esp_byte 0C

		!mov_eax #1
		!restore_stack_frame
		!ret

	]]})

	-- Sets a Lua REGISTRY index to the global defined by the given string.
	-- Only used for functions internally, so let's reflect that purpose in the name.
	-- Signature: <void> = EEex_SetLuaRegistryFunction(registryIndex, globalString)
	EEex_WriteAssemblyFunction("EEex_SetLuaRegistryFunction", {[[

		!build_stack_frame
		!push_registers

		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax

		!push_byte 00
		!push_byte 02
		!push_[ebp+byte] 08
		!call >_lua_tolstring
		!add_esp_byte 0C

		!push_eax
		!push_[ebp+byte] 08
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_dword #0FFF0B9D8
		!push_[ebp+byte] 08
		!call >_lua_rawseti
		!add_esp_byte 0C

		!xor_eax_eax
		!restore_stack_frame
		!ret

	]]})

	EEex_WriteAssemblyFunction("EEex_Memset", {[[

		!push_state

		!push_byte 00
		!push_byte 02
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax

		!push_byte 00
		!push_byte 03
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax

		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax

		!call >_memset
		!add_esp_byte 0C

		!mov_eax #00
		!pop_state
		!ret

	]]})

	EEex_WriteAssemblyFunction("EEex_FloatToLong", {[[

		!push_state

		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse

		!fld_qword:[eax]
		!call >__ftol2_sse

		!push_eax
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[ebp+byte] 08
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!mov_eax #1
		!pop_state
		!ret

	]]})

	EEex_WriteAssemblyFunction("EEex_GetMilliseconds", {[[

		$EEex_GetMilliseconds
		!build_stack_frame

		!call ]], {EEex_GetProcAddress("Kernel32", "GetTickCount"), 4, 4}, [[

		!push_eax
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[ebp+byte] 08
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!mov_eax #1
		!destroy_stack_frame
		!ret
	]]})

end)()
