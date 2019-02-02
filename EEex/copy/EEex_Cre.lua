
EEex_NewStatsCount = 0xFFFF

function EEex_HookConstructCreature(fromFile, toStruct)

	-- arbitrary new maximum... but let's make it pretty and have 
	-- it be the max of an unsigned short... maybe people will think
	-- there is an actual meaning behind it that way; for full
	-- explanation, see video: https://youtu.be/dQw4w9WgXcQ

	local newStatsAddress = EEex_Malloc(EEex_NewStatsCount * 4)
	local tempNewStatsAddress = EEex_Malloc(EEex_NewStatsCount * 4)

	EEex_WriteDword(toStruct + 0x3B18, newStatsAddress)
	EEex_WriteDword(toStruct + 0x3B1C, tempNewStatsAddress)

end

function EEex_HookDeconstructCreature(cre)
	EEex_Free(EEex_ReadDword(cre + 0x3B18))
	EEex_Free(EEex_ReadDword(cre + 0x3B1C))
end

function EEex_HookReloadStats(cre)
	EEex_Memset(EEex_ReadDword(cre + 0x3B18), EEex_NewStatsCount * 4, 0x0)
	EEex_Memset(EEex_ReadDword(cre + 0x3B1C), EEex_NewStatsCount * 4, 0x0)
end

function B3Cre_InstallCreatureHook()

	EEex_DisableCodeProtection()

	-- Increase creature struct size by 0x8 bytes (in memory)	
	for _, address in ipairs({
		0x51C21E,
		0x51E0A4,
		0x521231,
		0x53EE01,
		0x53F6AD,
		0x53FF0D,
		0x54F945,
		0x54FD53,
		0x55C648,
		0x55C6E7,
		0x55C74C,
		0x55C7B9,
		0x560796,
		0x568077,
		0x57C8E4,
		0x57D081,
		0x584C61,
		0x586FDF,
		0x588CB2,
		0x590E7C,
		0x5938AF,
		0x5B31B0,
		0x5B34FF,
		0x5B650A,
		0x5B9DDC,
		0x5BA13C,
		0x5C0906,
		0x5C0CB7,
		0x620D8D,
		0x62D05D,
		0x63E5D4,
		0x63E629,
		0x63E927,
		0x63E96C,
		0x641DB0,
		0x656029,
		0x667462,
		0x66BDC9,
		0x69DE3A,
		0x6E19F7,
		0x6ECB87,
		0x714887
	})
	do
		EEex_WriteAssembly(address + 1, {{0x3B20, 4}})
	end

	local hookNameLoad = "EEex_HookConstructCreature"
	local hookNameLoadAddress = EEex_Malloc(#hookNameLoad + 1)
	EEex_WriteString(hookNameLoadAddress, hookNameLoad)
	local hookAddressLoad = EEex_WriteAssemblyAuto({
		"E8 :52EEE0 "..
		"68", {hookNameLoadAddress,  4},
		"FF 35 0C 01 94 00 "..
		"E8 :4B5C10 "..
		"83 C4 08 FF 75 08 DB 04 24 83 EC 04 DD 1C 24 FF 35 0C 01 94 00 "..
		"E8 :4B5960 "..
		"83 C4 0C 53 DB 04 24 83 EC 04 DD 1C 24 FF 35 0C 01 94 00 "..
		"E8 :4B5960 "..
		"83 C4 0C 6A 00 6A 00 6A 00 6A 00 6A 02 FF 35 0C 01 94 00 "..
		"E8 :4B63F0 "..
		"83 C4 18 "..
		"E9 :6D40CB"
	})

	-- Install EEex_HookLoadCreature
	EEex_WriteAssembly(0x6D40C6, {"E9", {hookAddressLoad, 4, 4}})

	local hookNameReload = "EEex_HookReloadStats"
	local hookNameReloadAddress = EEex_Malloc(#hookNameReload + 1)
	EEex_WriteString(hookNameReloadAddress, hookNameReload)

	-- Instead of repushing all of the stack args, I'm using a
	-- hack here and storing the ret ptr somewhere in memory,
	-- then restoring it right before it is time to return.
	local hookReloadRetPtr = EEex_Malloc(0x4)

	local hookReload1 = EEex_WriteAssemblyAuto({[[

		!mov_eax_[esp]
		!mov_[dword]_eax ]], {hookReloadRetPtr, 4}, [[
		!add_esp_byte 04

		!call >CDerivedStats::Reload

		!push_ebx

		!push_dword ]], {hookNameReloadAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!push_[dword] ]], {hookReloadRetPtr, 4}, [[
		!ret

	]]})

	local hookReload2 = EEex_WriteAssemblyAuto({[[

		!mov_eax_[esp]
		!mov_[dword]_eax ]], {hookReloadRetPtr, 4}, [[
		!add_esp_byte 04

		!call >CDerivedStats::Reload

		!push_esi

		!push_dword ]], {hookNameReloadAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!push_[dword] ]], {hookReloadRetPtr, 4}, [[
		!ret

	]]})

	-- Install EEex_HookReloadStats
	EEex_WriteAssembly(0x6F5A21, {{hookReload1, 4, 4}})
	EEex_WriteAssembly(0x7064CC, {{hookReload1, 4, 4}})
	EEex_WriteAssembly(0x7068F3, {{hookReload1, 4, 4}})
	EEex_WriteAssembly(0x723894, {{hookReload2, 4, 4}})

	local hookNameDeconstruct = "EEex_HookDeconstructCreature"
	local hookNameDeconstructAddress = EEex_Malloc(#hookNameDeconstruct + 1)
	EEex_WriteString(hookNameDeconstructAddress, hookNameDeconstruct)

	local hookDeconstruct = EEex_WriteAssemblyAuto({[[

		!call >CGameSprite::~CGameSprite

		!push_esi

		!push_dword ]], {hookNameDeconstructAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!ret

	]]})

	-- Install EEex_HookDeconstructCreature
	EEex_WriteAssembly(0x56FBE7, {{hookDeconstruct, 4, 4}})

	-- Allow engine functions to access extended states...
	local hookAccessState = EEex_WriteAssemblyAuto({[[

		!build_stack_frame
		!push_registers

		!mov_eax_[ebp+byte] 08

		!cmp_eax_dword #CB
		!jb_dword >not_my_problem

		!sub_eax_dword #CB
		!cmp_eax_dword ]], {EEex_NewStatsCount, 4}, [[
		!jae_dword >it_was_your_only_job

		!cmp_[ecx+dword]_byte #3748 00
		!je_dword >new_temp_stats

		!mov_ecx_[ecx+dword] #3B18
		!jmp_dword >access_new_stats

		@new_temp_stats
		!mov_ecx_[ecx+dword] #3B1C

		@access_new_stats
		!mov_eax_[ecx+eax*4]
		!jmp_dword >ret

		@not_my_problem

		!call >CGameSprite::GetActiveStats
		!mov_ecx_eax

		!push_[ebp+byte] 08
		!call >CDerivedStats::GetAtOffset

		!jmp_dword >ret

		@it_was_your_only_job
		!xor_eax_eax

		@ret
		!restore_stack_frame
		!ret_word 04 00

	]]})

	local newStatsTempSet1 = EEex_WriteAssemblyAuto({[[
		!push_state
		!push_[ebp+byte] 08
		!call >CDerivedStats::operator=
		!push_dword ]], {EEex_NewStatsCount * 4, 4}, [[
		!mov_eax_[esi+dword] #3B18
		!push_eax
		!mov_eax_[esi+dword] #3B1C
		!push_eax
		!call >_memcpy
		!add_esp_byte 0C
		!pop_state
		!ret_word 04 00
	]]})

	local newStatsTempSet2 = EEex_WriteAssemblyAuto({[[
		!push_state
		!push_[ebp+byte] 08
		!call >CDerivedStats::operator=
		!push_dword ]], {EEex_NewStatsCount * 4, 4}, [[
		!mov_eax_[edi+dword] #3B18
		!push_eax
		!mov_eax_[edi+dword] #3B1C
		!push_eax
		!call >_memcpy
		!add_esp_byte 0C
		!pop_state
		!ret_word 04 00
	]]})

	EEex_WriteAssembly(0x7111A0, {{newStatsTempSet1, 4, 4}})
	EEex_WriteAssembly(0x730D24, {{newStatsTempSet2, 4, 4}})

	-- lua wrapper for above function; overrides the default
	-- value in M__EEex.lua that uses inbuilt functions.
	EEex_WriteAssemblyFunction("EEex_GetActorStat", {[[

		!build_stack_frame
		!sub_esp_byte 04
		!push_registers

		!push_byte 00
		!push_byte 02
		!push_[dword] *_g_lua
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax

		!push_byte 00
		!push_byte 01
		!push_[dword] *_g_lua
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse

		!lea_ecx_[ebp+byte] FC
		!push_ecx
		!push_eax
		!call >CGameObjectArray::GetShare
		!add_esp_byte 08
		!mov_ecx_[ebp+byte] FC

		!call ]], {hookAccessState, 4, 4}, [[

		!push_eax
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[ebp+byte] 08
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!mov_eax #01
		!restore_stack_frame
		!ret

	]]})

	-- CheckStat
	EEex_WriteAssembly(0x532DC6, {{hookAccessState, 4, 4}, "!nop !nop !nop !nop !nop !nop !nop"})

	-- CheckStatGT
	EEex_WriteAssembly(0x532E09, {{hookAccessState, 4, 4}, "!nop !nop !nop !nop !nop !nop !nop"})

	-- CheckStatLT
	EEex_WriteAssembly(0x532E4C, {{hookAccessState, 4, 4}, "!nop !nop !nop !nop !nop !nop !nop"})

	-- Opcodes #318, #324, #326
	EEex_WriteAssembly(0x603519, {[[
		!push_eax
		!mov_ecx_edi
		!call ]], {hookAccessState, 4, 4}, [[
		!jmp_dword :60353A
		!nop
		!nop
	]]})

	EEex_EnableCodeProtection()
end
B3Cre_InstallCreatureHook()
