
-- Arbitrary new maximum: can be adjusted if the need arises.
EEex_NewStatsCount = 0xFFFF
EEex_SimpleStatsSize = EEex_NewStatsCount * 4

EEex_ComplexStatDefinitions = {}
EEex_CurrentStatOffset = EEex_SimpleStatsSize
EEex_ComplexStatSpace = 0x0

function EEex_RegisterComplexStat(name, attributeTable)

	-- attributeTable["construct"]
	-- attributeTable["destruct"]
	-- attributeTable["clear"]
	-- attributeTable["copy"]
	-- attributeTable["size"]

	local offset = EEex_CurrentStatOffset
	attributeTable["offset"] = offset
	local size = attributeTable["size"]

	EEex_CurrentStatOffset = EEex_CurrentStatOffset + size
	EEex_ComplexStatSpace = EEex_ComplexStatSpace + size

	EEex_ComplexStatDefinitions[name] = attributeTable

	return offset

end

function EEex_RegisterSimpleListStat(name, elementSize)
	return EEex_RegisterComplexStat(name, {
		["construct"] = function(address)
			EEex_Call(EEex_Label("CObList::CObList"), {10}, address, 0x0)
		end,
		["destruct"] = function(address)
			EEex_IterateCPtrList(address, function(overridePtr)
				EEex_Free(overridePtr)
			end)
			EEex_Call(EEex_Label("CObList::~CObList"), {}, address, 0x0)
		end,
		["clear"] = function(address)
			EEex_IterateCPtrList(address, function(overridePtr)
				EEex_Free(overridePtr)
			end)
			EEex_Call(EEex_Label("CObList::RemoveAll"), {}, address, 0x0)
		end,
		["copy"] = function(source, dest)
			EEex_IterateCPtrList(dest, function(overridePtr)
				EEex_Free(overridePtr)
			end)
			EEex_Call(EEex_Label("CObList::RemoveAll"), {}, dest, 0x0)
			EEex_IterateCPtrList(source, function(overridePtr)
				local copyOverridePtr = EEex_Malloc(elementSize)
				EEex_Call(EEex_Label("_memcpy"), {elementSize, overridePtr, copyOverridePtr}, nil, 0xC)
				EEex_Call(EEex_Label("CPtrList::AddTail"), {copyOverridePtr}, dest, 0x0)
			end)
		end,
		["size"] = 0x1C,
	})
end

function EEex_RegisterComplexListStat(name, attributeTable)
	return EEex_RegisterComplexStat(name, {
		["construct"] = function(address)
			EEex_Call(EEex_Label("CObList::CObList"), {10}, address, 0x0)
		end,
		["destruct"] = function(address)
			EEex_IterateCPtrList(address, function(overridePtr)
				attributeTable["destruct"](overridePtr)
				EEex_Free(overridePtr)
			end)
			EEex_Call(EEex_Label("CObList::~CObList"), {}, address, 0x0)
		end,
		["clear"] = function(address)
			EEex_IterateCPtrList(address, function(overridePtr)
				attributeTable["destruct"](overridePtr)
				EEex_Free(overridePtr)
			end)
			EEex_Call(EEex_Label("CObList::RemoveAll"), {}, address, 0x0)
		end,
		["copy"] = function(source, dest)
			EEex_IterateCPtrList(dest, function(overridePtr)
				attributeTable["destruct"](overridePtr)
				EEex_Free(overridePtr)
			end)
			EEex_Call(EEex_Label("CObList::RemoveAll"), {}, dest, 0x0)
			EEex_IterateCPtrList(source, function(overridePtr)
				local copyOverridePtr = EEex_Malloc(attributeTable["size"])
				attributeTable["construct"](copyOverridePtr)
				attributeTable["copy"](overridePtr, copyOverridePtr)
				EEex_Call(EEex_Label("CPtrList::AddTail"), {copyOverridePtr}, dest, 0x0)
			end)
		end,
		["size"] = 0x1C,
	})
end

function EEex_AccessComplexStat(actorID, name)

	local creatureData = EEex_GetActorShare(actorID)

	local newStats = nil
	if EEex_ReadDword(creatureData + 0x3748) == 0x0 then
		newStats = EEex_ReadDword(creatureData + 0x3B1C)
	else
		newStats = EEex_ReadDword(creatureData + 0x3B18)
	end

	return newStats + EEex_ComplexStatDefinitions[name]["offset"]

end

function EEex_HookConstructCreature(fromFile, toStruct)

	local newStats = EEex_Malloc(EEex_SimpleStatsSize + EEex_ComplexStatSpace)
	local newTempStats = EEex_Malloc(EEex_SimpleStatsSize + EEex_ComplexStatSpace)

	EEex_WriteDword(toStruct + 0x3B18, newStats)
	EEex_WriteDword(toStruct + 0x3B1C, newTempStats)

	for _, complexStatDef in pairs(EEex_ComplexStatDefinitions) do
		local constructFunction = complexStatDef["construct"]
		if constructFunction then
			local statOffset = complexStatDef["offset"]
			constructFunction(newStats + statOffset)
			constructFunction(newTempStats + statOffset)
		end
	end

end

function EEex_HookDeconstructCreature(cre)

	local newStats = EEex_ReadDword(cre + 0x3B18)
	local newTempStats = EEex_ReadDword(cre + 0x3B1C)

	for _, complexStatDef in pairs(EEex_ComplexStatDefinitions) do
		local destructFunction = complexStatDef["destruct"]
		if destructFunction then
			local statOffset = complexStatDef["offset"]
			destructFunction(newStats + statOffset)
			destructFunction(newTempStats + statOffset)
		end
	end

	EEex_Free(newStats)
	EEex_Free(newTempStats)

end

function EEex_HookReloadStats(cre)

	local newStats = EEex_ReadDword(cre + 0x3B18)
	local newTempStats = EEex_ReadDword(cre + 0x3B1C)

	-- Only the DERIVED base is reloaded - temp needs to be preserved
	-- so that stats can be detected within effect calls
	EEex_Memset(newStats, EEex_SimpleStatsSize, 0x0)

	for _, complexStatDef in pairs(EEex_ComplexStatDefinitions) do
		local clearFunction = complexStatDef["clear"]
		if clearFunction then
			local statOffset = complexStatDef["offset"]
			clearFunction(newStats + statOffset)
			clearFunction(newTempStats + statOffset)
		end
	end

end

function EEex_HookCopyStats(cre)

	local newStats = EEex_ReadDword(cre + 0x3B18)
	local newTempStats = EEex_ReadDword(cre + 0x3B1C)
	EEex_Call(EEex_Label("_memcpy"), {EEex_SimpleStatsSize, newStats, newTempStats}, nil, 0xC)

	for _, complexStatDef in pairs(EEex_ComplexStatDefinitions) do
		local copyFunction = complexStatDef["copy"]
		if copyFunction then
			local statOffset = complexStatDef["offset"]
			copyFunction(newStats + statOffset, newTempStats + statOffset)
		end
	end

end

function B3Cre_InstallCreatureHook()

	EEex_DisableCodeProtection()

	-- Increase creature struct size by 0x8 bytes (in memory)
	for _, address in ipairs(EEex_Label("CreAllocationSize")) do
		EEex_WriteAssembly(address + 1, {{0x3B20, 4}})
	end

	local hookNameLoad = "EEex_HookConstructCreature"
	local hookNameLoadAddress = EEex_Malloc(#hookNameLoad + 1)
	EEex_WriteString(hookNameLoadAddress, hookNameLoad)

	local hookAddressLoad = EEex_WriteAssemblyAuto({[[

		!call >CGameAIBase::CGameAIBase

		!push_dword ]], {hookNameLoadAddress, 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_[ebp+byte] 08
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_ebx
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
		!push_byte 02
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!ret
	]]})

	-- Install EEex_HookConstructCreature
	EEex_WriteAssembly(EEex_Label("HookConstructCreature1"), {{hookAddressLoad, 4, 4}})
	EEex_WriteAssembly(EEex_Label("HookConstructCreature2"), {{hookAddressLoad, 4, 4}})

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
	EEex_WriteAssembly(EEex_Label("HookReloadStats1"), {{hookReload1, 4, 4}})
	EEex_WriteAssembly(EEex_Label("HookReloadStats2"), {{hookReload1, 4, 4}})
	EEex_WriteAssembly(EEex_Label("HookReloadStats3"), {{hookReload1, 4, 4}})
	EEex_WriteAssembly(EEex_Label("HookReloadStats4"), {{hookReload2, 4, 4}})

	local hookNameDeconstruct = "EEex_HookDeconstructCreature"
	local hookNameDeconstructAddress = EEex_Malloc(#hookNameDeconstruct + 1)
	EEex_WriteString(hookNameDeconstructAddress, hookNameDeconstruct)

	local deconstructHookAddress = EEex_Label("CGameSprite::~CGameSprite")

	local hookDeconstruct = EEex_WriteAssemblyAuto({[[

		!push_state

		!push_ecx

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

		!pop_state

		!push_ebp
		!mov_ebp_esp
		!push_ecx
		!push_ebx

		!jmp_dword ]], {deconstructHookAddress + 0x5, 4, 4},

	})

	-- Install EEex_HookDeconstructCreature
	EEex_WriteAssembly(deconstructHookAddress, {"!jmp_dword", {hookDeconstruct, 4, 4}})

	-- Allow engine functions to access extended states...
	local hookAccessState = EEex_WriteAssemblyAuto({[[

		$EEex_AccessStat

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

	local hookNameCopy = "EEex_HookCopyStats"
	local hookNameCopyAddress = EEex_Malloc(#hookNameCopy + 1)
	EEex_WriteString(hookNameCopyAddress, hookNameCopy)

	local hookCopy1 = EEex_WriteAssemblyAuto({[[
		!push_state
		!push_esi
		!push_[ebp+byte] 08
		!call >CDerivedStats::operator_equ
		!push_dword ]], {hookNameCopyAddress, 4}, [[
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
		!pop_state
		!ret_word 04 00
	]]})

	local hookCopy2 = EEex_WriteAssemblyAuto({[[
		!push_state
		!push_edi
		!push_[ebp+byte] 08
		!call >CDerivedStats::operator_equ
		!push_dword ]], {hookNameCopyAddress, 4}, [[
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
		!pop_state
		!ret_word 04 00
	]]})

	EEex_WriteAssembly(EEex_Label("HookStatsTempSet1"), {{hookCopy1, 4, 4}})
	EEex_WriteAssembly(EEex_Label("HookStatsTempSet2"), {{hookCopy2, 4, 4}})

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
	EEex_WriteAssembly(EEex_Label("HookCheckStat"), {{hookAccessState, 4, 4}, "!nop !nop !nop !nop !nop !nop !nop"})

	-- CheckStatGT
	EEex_WriteAssembly(EEex_Label("HookCheckStatGT"), {{hookAccessState, 4, 4}, "!nop !nop !nop !nop !nop !nop !nop"})

	-- CheckStatLT
	EEex_WriteAssembly(EEex_Label("HookCheckStatLT"), {{hookAccessState, 4, 4}, "!nop !nop !nop !nop !nop !nop !nop"})

	-- Opcodes #318, #324, #326
	local hookSplprotOpcodesAddress = EEex_Label("HookSplprotOpcodes")
	EEex_WriteAssembly(hookSplprotOpcodesAddress, {[[
		!push_ecx ; relation ;
		!push_esi ; b ;
		!push_eax
		!mov_ecx_edi
		!call ]], {hookAccessState, 4, 4}, [[
		!jmp_dword ]], {hookSplprotOpcodesAddress + 33, 4, 4}, [[
	]]})

	EEex_EnableCodeProtection()
end
B3Cre_InstallCreatureHook()
