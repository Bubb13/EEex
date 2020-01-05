
EEex_ObjectData = {}

-- Arbitrary new maximum: can be adjusted if the need arises.
EEex_NewStatsCount = 0xFFFF
EEex_SimpleStatsSize = EEex_NewStatsCount * 4

EEex_ComplexStatDefinitions = {}
EEex_CurrentStatOffset = EEex_SimpleStatsSize
EEex_ComplexStatSpace = 0x0

EEex_VolatileStorageDefinitions = {}
EEex_VolatileStorageSpace = 0x0

function EEex_GameObjectAdded(object)

	local volatileStorage = EEex_Malloc(EEex_VolatileStorageSpace)

	for _, volatileDef in pairs(EEex_VolatileStorageDefinitions) do
		local constructFunction = volatileDef["construct"]
		if constructFunction then
			local offset = volatileDef["offset"]
			constructFunction(volatileStorage + offset)
		end
	end

	local objectID = EEex_ReadDword(object + 0x34)
	EEex_ObjectData[objectID] = {
		["volatileFields"] = volatileStorage,
	}

end

function EEex_GameObjectBeingDeleted(objectID)

	local objectData = EEex_ObjectData[objectID]
	local volatileStorage = objectData["volatileFields"]

	for _, volatileDef in pairs(EEex_VolatileStorageDefinitions) do
		local destructFunction = volatileDef["destruct"]
		if destructFunction then
			local offset = volatileDef["offset"]
			destructFunction(volatileStorage + offset)
		end
	end

	EEex_Free(volatileStorage)
	EEex_ObjectData[objectID] = nil

end

function EEex_GameObjectsBeingCleaned()

	for _, objectData in pairs(EEex_ObjectData) do

		local volatileStorage = objectData["volatileFields"]

		for _, volatileDef in pairs(EEex_VolatileStorageDefinitions) do
			local destructFunction = volatileDef["destruct"]
			if destructFunction then
				local offset = volatileDef["offset"]
				destructFunction(volatileStorage + offset)
			end
		end

		EEex_Free(volatileStorage)

	end

	EEex_ObjectData = {}

end

function EEex_RegisterVolatileField(name, attributeTable)

	-- attributeTable["construct"]
	-- attributeTable["destruct"]
	-- attributeTable["get"]
	-- attributeTable["set"]
	-- attributeTable["size"]

	local offset = EEex_VolatileStorageSpace
	attributeTable["offset"] = offset
	EEex_VolatileStorageSpace = EEex_VolatileStorageSpace + attributeTable["size"]
	EEex_VolatileStorageDefinitions[name] = attributeTable
	return offset
end

function EEex_AccessVolatileField(actorID, name)
	local volatileDef = EEex_VolatileStorageDefinitions[name]
	local volatileStart = EEex_ObjectData[actorID]["volatileFields"]
	return volatileStart + volatileDef["offset"]
end

function EEex_GetVolatileField(actorID, name)
	local volatileDef = EEex_VolatileStorageDefinitions[name]
	local volatileStart = EEex_ObjectData[actorID]["volatileFields"]
	local address = volatileStart + volatileDef["offset"]
	return volatileDef["get"](address)
end

function EEex_SetVolatileField(actorID, name, value)
	local volatileDef = EEex_VolatileStorageDefinitions[name]
	local volatileStart = EEex_ObjectData[actorID]["volatileFields"]
	local address = volatileStart + volatileDef["offset"]
	return volatileDef["set"](address, value)
end

function EEex_GetVolatileFieldOffset(name)
	return EEex_VolatileStorageDefinitions[name]["offset"]
end

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

	---------------------------
	-- EEex_ObjectData Hooks --
	---------------------------

	--------------------------
	-- EEex_GameObjectAdded --
	--------------------------

	local objectAddedHookAddress = EEex_Label("CGameObjectArray::Add()_EndHook")
	objectAddedHookAddress = objectAddedHookAddress + EEex_ReadDword(objectAddedHookAddress) + 0x4

	-- Have to go searching for the hook address, as the function changed between game versions

	local destructCString = EEex_Label("CString::~CString")
	local findCall = function(address)
		return EEex_ReadByte(address, 0) == 0xE8 and (address + EEex_ReadDword(address + 0x1) + 0x5) == destructCString
	end

	while not findCall(objectAddedHookAddress) do
		objectAddedHookAddress = objectAddedHookAddress + 1
	end

	local objectAddedHook = EEex_WriteAssemblyAuto({[[

		!call >CString::~CString
		!push_all_registers

		!push_dword ]], {EEex_WriteStringAuto("EEex_GameObjectAdded"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_edi
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

		!pop_all_registers
		!jmp_dword ]], {objectAddedHookAddress + 0x5, 4, 4},

	})
	EEex_WriteAssembly(objectAddedHookAddress, {"!jmp_dword", {objectAddedHook, 4, 4}})

	---------------------------------
	-- EEex_GameObjectBeingDeleted --
	---------------------------------

	-- If you're here because something broke, good luck.

	local objectBeingDeletedHookAddress = EEex_Label("CGameDoor::RemoveFromArea()_DeleteCall")
	objectBeingDeletedHookAddress = objectBeingDeletedHookAddress + EEex_ReadDword(objectBeingDeletedHookAddress) + 0x4

	local objectBeingDeletedHook = EEex_WriteAssemblyAuto({[[

		$restore
		!nop !nop !nop !nop !nop !nop !nop 

		!push_all_registers

		!push_dword ]], {EEex_WriteStringAuto("EEex_GameObjectBeingDeleted"), 4}, [[
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

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 01
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!pop_all_registers
		!jmp_dword ]], {objectBeingDeletedHookAddress + 0x7, 4, 4},

	})

	local restoreAddress = EEex_Label("restore")
	for i = 0, 6, 1 do
		EEex_WriteByte(restoreAddress + i, EEex_ReadByte(objectBeingDeletedHookAddress + i, 0))
	end

	EEex_WriteAssembly(objectBeingDeletedHookAddress, {"!jmp_dword", {objectBeingDeletedHook, 4, 4}, "!nop !nop"})

	----------------------------------
	-- EEex_GameObjectsBeingCleaned --
	----------------------------------

	local objectsBeingCleanedHookAddress = EEex_Label("CGameObjectArray::Clean") + 0x6
	local objectsBeingCleanedHook = EEex_WriteAssemblyAuto({[[

		!push_all_registers

		!push_dword ]], {EEex_WriteStringAuto("EEex_GameObjectsBeingCleaned"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_[dword] *_g_lua
		!call >_lua_pcallk
		!add_esp_byte 18

		!pop_all_registers

		; Redefine what I altered ;
		!push_esi
		!or_esi_byte FF
		!(word) !test_eax_eax

		!jmp_dword ]], {objectsBeingCleanedHookAddress + 0x7, 4, 4},

	})
	EEex_WriteAssembly(objectsBeingCleanedHookAddress, {"!jmp_dword", {objectsBeingCleanedHook, 4, 4}, "!nop !nop"})

	--------------------------------
	-- $EEex_AccessVolatileFields --
	--------------------------------

	EEex_WriteAssemblyAuto({[[

		$EEex_AccessVolatileFields
		!push_registers

		; Referenced below ;
		!push_[ecx+byte] 34

		!push_dword ]], {EEex_WriteStringAuto("EEex_ObjectData"), 4}, [[
		!push_[dword] *_g_lua
		!call >_lua_getglobal
		!add_esp_byte 08

		; Uses push highlighted above ; 
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[dword] *_g_lua
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!push_byte FE
		!push_[dword] *_g_lua
		!call >_lua_gettable
		!add_esp_byte 08

		!push_dword ]], {EEex_WriteStringAuto("volatileFields"), 4}, [[
		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_getfield
		!add_esp_byte 0C

		!push_byte 00
		!push_byte FF
		!push_[dword] *_g_lua
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse

		!push_eax

		!push_byte FC
		!push_[dword] *_g_lua
		!call >_lua_settop
		!add_esp_byte 08

		!pop_eax

		!pop_registers
		!ret

	]]})

	-----------------------
	-- CGameSprite Hooks --
	-----------------------

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
