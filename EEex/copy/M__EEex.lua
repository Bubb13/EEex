--[[

This is EEex's main file. The vital initialization and hooks are
defined within this file. Please don't edit unless you
ABSOLUTELY know what you are doing... you could very easily cause a game crash in here.

Most new functions that *aren't* hardcoded into the exe are defined in here.
I haven't documented most of them yet, so have a look around.
(But please, again, no touchy!)

--]]

-------------
-- Options --
-------------

EEex_MinimalStartup = false

--------------------
-- Initialization --
--------------------

EEex_InitialMemory = nil
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
	-- Failed to initialize EEex, clean up junk.
	EEex_MinimalStartup = nil
	error("EEex is disabled: dll not injected. Please start game using EEex.exe.")
end

-----------
-- State --
-----------

EEex_ResetListeners = {}

function EEex_AddResetListener(listener)
	table.insert(EEex_ResetListeners, listener)
end

EEex_IgnoreFirstReset = true
function EEex_Reset()
	if not EEex_IgnoreFirstReset then
		local resetListenersCopy = EEex_ResetListeners
		EEex_ResetListeners = {}
		for _, listener in ipairs(resetListenersCopy) do
			listener()
		end
	else
		EEex_IgnoreFirstReset = false
	end
end

---------------------
-- Memory Utililty --
---------------------

function EEex_Malloc(size)
	return EEex_Call(EEex_Label("_malloc"), {size}, nil, 0x4)
end

function EEex_Free(address)
	return EEex_Call(EEex_Label("_SDL_free"), {address}, nil, 0x4)
end

function EEex_ReadByte(address, index)
	return bit32.extract(EEex_ReadDword(address), index * 0x8, 0x8)
end

function EEex_ReadWord(address, index)
	return bit32.extract(EEex_ReadDword(address), index * 0x10, 0x10)
end

function EEex_WriteWord(address, value)
	for i = 0, 1, 1 do
		EEex_WriteByte(address + i * 0x2, bit32.extract(value, i * 0x16, 0x8))
	end
end

function EEex_WriteDword(address, value)
	for i = 0, 3, 1 do
		EEex_WriteByte(address + i, bit32.extract(value, i * 0x8, 0x8))
	end
end

-- OS:WINDOWS
function EEex_DllCall(dll, proc, args, ecx, pop)
	local procaddress = #dll + 1
	local dlladdress = EEex_Malloc(procaddress + #proc + 1)
	procaddress = dlladdress + procaddress
	EEex_WriteString(dlladdress, dll)
	EEex_WriteString(procaddress, proc)
	local dllhandle = EEex_Call(EEex_Label("__imp__LoadLibraryA"), {dlladdress}, nil, 0x0)
	local procfunc = EEex_Call(EEex_Label("__imp__GetProcAddress"), {procaddress, dllhandle}, nil, 0x0)
	local result = EEex_Call(procfunc, args, ecx, pop)
	EEex_Free(dlladdress)
	return result
end

-------------------
-- Debug Utility --
-------------------

function EEex_FunctionLog(message)
	local name = debug.getinfo(2, "n").name
	if name == nil then name = "(Unknown)" end
	Infinity_Log("[EEex] "..name..": "..message)
end

function EEex_Error(message)
	error(message.." "..debug.traceback())
end

EEex_ReadDwordDebug_Suppress = false
function EEex_ReadDwordDebug(reading, read)
	if not EEex_ReadDwordDebug_Suppress then
		--Infinity_Log("[EEex] EEex_ReadDwordDebug: "..EEex_ToHex(reading).." => "..EEex_ToHex(read))
	end
end

function EEex_DumpLuaStack()
	EEex_FunctionLog("Lua Stack =>")
	EEex_ReadDwordDebug_Suppress = true
	local lua_State = EEex_ReadDword(EEex_Label("_g_lua"))
	local top = EEex_Call(EEex_Label("_lua_gettop"), {lua_State}, nil, 0x4)
	for i = 1, top, 1 do
		local t = EEex_Call(EEex_Label("_lua_type"), {i, lua_State}, nil, 0x8)
		if t == 0 then
			EEex_FunctionLog("    nil")
		elseif t == 1 then
			local boolean = EEex_Call(EEex_Label("_lua_toboolean"), {i, lua_State}, nil, 0x8)
			EEex_FunctionLog("    boolean: "..boolean)
		elseif t == 3 then
			local number = EEex_Call(EEex_Label("_lua_tonumberx"), {0x0, i, lua_State}, nil, 0xC)
			EEex_FunctionLog("    number: "..EEex_ToHex(number))
		elseif t == 4 then
			local string = EEex_Call(EEex_Label("_lua_tolstring"), {0x0, i, lua_State}, nil, 0x8)
			EEex_FunctionLog("    string: "..EEex_ReadString(string))
		else
			local typeName = EEex_Call(EEex_Label("_lua_typename"), {i, lua_State}, nil, 0x8)
			EEex_FunctionLog("    type: "..t..", typeName: "..EEex_ReadString(typeName))
		end
	end
	EEex_ReadDwordDebug_Suppress = false
end

function EEex_DumpDynamicCode()
	EEex_ReadDwordDebug_Suppress = true
	EEex_FunctionLog("EEex => Dynamic Code")
	for i, codePage in ipairs(EEex_CodePageAllocations) do
		EEex_FunctionLog(i)
		for j, entry in ipairs(codePage) do
			EEex_FunctionLog("    "..j)
			EEex_FunctionLog("        Entry Address: "..EEex_ToHex(entry.address))
			EEex_FunctionLog("        Entry Size: "..EEex_ToHex(entry.size))
			EEex_FunctionLog("        Entry Reserved: "..tostring(entry.reserved))
			if entry.reserved then
				local byteDump = "        "
				local address = entry.address
				local limit = address + entry.size
				for address = entry.address, limit, 4 do
					local currentDword = EEex_ReadDword(address)
					for k = 0, 3, 1 do
						local byteAddress = address + k
						if byteAddress < limit then
							local byte = bit32.extract(currentDword, k * 8, 8)
							byteDump = byteDump..EEex_ToHex(byte, 2, true).." "
						end
					end
				end
				EEex_FunctionLog(byteDump)
			end
		end
	end
	EEex_ReadDwordDebug_Suppress = false
end

-- OS:WINDOWS
function EEex_MessageBox(message)
	local caption = "EEex"
	local messageAddress = EEex_Malloc(#message + 1 + #caption + 1)
	local captionAddress = messageAddress + #message + 1
	EEex_WriteString(messageAddress, message)
	EEex_WriteString(captionAddress, caption)
	EEex_DllCall("User32", "MessageBoxA", {EEex_Flags({0x40}), captionAddress, messageAddress, 0x0}, nil, 0x0)
	EEex_Free(messageAddress)
end

--------------------
-- Random Utility --
--------------------

function EEex_ConcatTables(tables)
	local toReturn = {}
	for _, _table in ipairs(tables) do
		if type(_table) == "table" then
			for _, element in ipairs(_table) do
				table.insert(toReturn, element)
			end
		else
			table.insert(toReturn, _table)
		end
	end
	return toReturn
end

function EEex_RoundUp(numToRound, multiple)
	if multiple == 0 then
		return numToRound
	end
	local remainder = numToRound % multiple
	if remainder == 0 then
		return numToRound
	end
	return numToRound + multiple - remainder;
end

function EEex_StringStartsWith(string, startsWith)
   return string.sub(string, 1, #startsWith) == startsWith
end

function EEex_CharFind(string, char, startingIndex)
	local limit = #string
	for i = startingIndex or 1, limit, 1 do
		local subChar = string:sub(i, i)
		if subChar == char then
			return i
		end
	end
	return -1
end

function EEex_SplitByChar(string, char)
	local splits = {}
	local startIndex = 1
	local found = EEex_CharFind(string, char)
	while found ~= -1 do
		table.insert(splits, string:sub(startIndex, found - 1))
		startIndex = found + 1
		found = EEex_CharFind(string, char, startIndex)
	end
	if #string - startIndex > 0 then
		table.insert(splits, string:sub(startIndex, #string))
	end
	return splits
end

function EEex_IterateCPtrList(CPtrList, func)
	local m_pNext = EEex_ReadDword(CPtrList + 0x4)
	while m_pNext ~= 0x0 do
		if func(EEex_ReadDword(m_pNext + 0x8)) then
			break
		end
		m_pNext = EEex_ReadDword(m_pNext)
	end
end

function EEex_FreeCPtrList(CPtrList)
	local m_nCount = EEex_ReadDword(CPtrList + 0xC)
	while m_nCount ~= 0 do
		EEex_Free(EEex_Call(EEex_Label("CObList::RemoveHead"), {}, CPtrList, 0x0))
		m_nCount = EEex_ReadDword(CPtrList + 0xC)
	end
	EEex_Call(EEex_Label("CObList::RemoveAll"), {}, CPtrList, 0x0)
	EEex_Call(EEex_ReadDword(EEex_ReadDword(CPtrList)), {0x1}, CPtrList, 0x0)
end

function EEex_GetCurrentCInfinity()
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin")) -- (CBaldurChitin)
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame")) -- (CInfGame)
	local m_visibleArea = EEex_ReadByte(m_pObjectGame + 0x3DA0, 0) -- (byte)
	local m_gameArea = EEex_ReadDword(m_pObjectGame + m_visibleArea * 4 + 0x3DA4) -- (CGameArea)
	local m_cInfinity = m_gameArea + 0x484 -- (CInfinity)
	return m_cInfinity
end

----------------------
-- Assembly Writing --
----------------------

EEex_GlobalAssemblyLabels = {}
function EEex_DefineAssemblyLabel(label, value)
	EEex_GlobalAssemblyLabels[label] = value
end

function EEex_Label(label)
	local value = EEex_GlobalAssemblyLabels[label]
	if not value then
		EEex_Error("Label @"..label.." is not defined in the global scope!")
	end
	return EEex_GlobalAssemblyLabels[label]
end

EEex_GlobalAssemblyMacros = {}
function EEex_DefineAssemblyMacro(macroName, macroValue)
	EEex_GlobalAssemblyMacros[macroName] = macroValue
end

-- Some more complex assembly solutions require special macro functions
-- to generate the correct bytes on the fly
function EEex_ResolveMacro(address, args, currentWriteAddress, section, func)
	func = func or function() end
	local sectionSplit = EEex_SplitByChar(section, ",")
	local macro = sectionSplit[1]
	local macroName = string.sub(macro, 2, #macro)
	local macroValue = EEex_GlobalAssemblyMacros[macroName]
	if not macroValue then
		EEex_Error("Macro "..macro.." not defined!")
	end
	local macroType = type(macroValue)
	if macroType == "string" then
		return macroValue
	elseif macroType == "function" then
		local macroArgs = {}
		local limit = #sectionSplit
		for i = 2, limit, 1 do
			local resolvedArg = EEex_ResolveMacroArg(address, args, currentWriteAddress, sectionSplit[i])
			table.insert(macroArgs, resolvedArg)
		end
		return macroValue(currentWriteAddress, macroArgs, func)
	else
		EEex_Error("Invalid macro type in \""..macroName.."\": \""..macroType.."\"!")
	end
end

function EEex_ResolveMacroArg(address, args, currentWriteAddress, section)
	local toReturn = nil
	local prefix = string.sub(section, 1, 1)
	if prefix == ":" then
		local targetOffset = tonumber(string.sub(section, 2, #section), 16)
		toReturn = targetOffset - (currentWriteAddress + 4)
	elseif prefix == "#" then
		toReturn = tonumber(string.sub(section, 2, #section), 16)
	elseif prefix == "+" then
		toReturn = currentWriteAddress + 4 + tonumber(string.sub(section, 2, #section), 16)
	elseif prefix == ">" then
		local label = string.sub(section, 2, #section)
		local offset = EEex_CalcLabelOffset(address, args, label)
		local targetOffset = nil
		if offset then
			targetOffset = address + offset
		else
			targetOffset = EEex_GlobalAssemblyLabels[label]
			if not targetOffset then
				EEex_Error("Label @"..label.." is not defined in current scope!")
			end
		end
		toReturn = targetOffset - (currentWriteAddress + 4)
	elseif prefix == "*" then
		local label = string.sub(section, 2, #section)
		local offset = EEex_CalcLabelOffset(address, args, label)
		local targetOffset = nil
		if offset then
			targetOffset = address + offset
		else
			targetOffset = EEex_GlobalAssemblyLabels[label]
			if not targetOffset then
				EEex_Error("Label @"..label.." is not defined in current scope!")
			end
		end
		toReturn = targetOffset
	elseif prefix == "!" then
		EEex_Error("Nested macros are not implemented! (did you really expect me to implement proper bracket matching?)")
	elseif prefix == "@" then
		EEex_Error("Why have you passed a label to a macro?")
	else
		toReturn = tonumber(section, 16)
	end
	return toReturn
end

function EEex_CalcWriteLength(address, args)
	local toReturn = 0
	for _, arg in ipairs(args) do
		local argType = type(arg)
		if argType == "string" then
			-- processTextArg needs to be "defined" up here to have processSection see it.
			local processTextArg = nil
			local processSection = function(section)
				local prefix = string.sub(section, 1, 1)
				if prefix == ":" or prefix == "#" or prefix == "+" then
					toReturn = toReturn + 4
				elseif prefix == ">" or prefix == "*" then
					local label = string.sub(section, 2, #section)
					if
						not EEex_CalcLabelOffset(address, args, label)
						and not EEex_GlobalAssemblyLabels[label]
					then
						EEex_Error("Label @"..label.." is not defined in current scope!")
					end
					toReturn = toReturn + 4
				elseif prefix == "!" then -- Processes a macro
					local macroResult = EEex_ResolveMacro(address, args, toReturn, section)
					if type(macroResult) == "string" then
						if processTextArg(macroResult) then
							return true
						end
					else
						toReturn = toReturn + macroResult
					end
				elseif prefix ~= "@" and prefix ~= "$" then
					toReturn = toReturn + 1
				end
			end
			processTextArg = function(innerArg)
				innerArg = innerArg:gsub("%s+", " ")
				local limit = #innerArg
				local lastSpace = 0
				for i = 1, limit, 1 do
					local char = string.sub(innerArg, i, i)
					if char == " " then
						if i - lastSpace > 1 then
							local section = string.sub(innerArg, lastSpace + 1, i - 1)
							processSection(section)
						end
						lastSpace = i
					end
				end
				if limit - lastSpace > 0 then
					local lastSection = string.sub(innerArg, lastSpace + 1, limit)
					processSection(lastSection)
				end
			end
			processTextArg(arg)
		elseif argType == "table" then
			local argSize = #arg
			if argSize == 2 or argSize == 3 then
				local address = arg[1]
				local length = arg[2]
				local relativeFromOffset = arg[3]
				if type(address) == "number" and type(length) == "number"
					and (not relativeFromOffset or type(relativeFromOffset) == "number")
				then
					toReturn = toReturn + length
				else
					EEex_Error("Variable write argument included invalid data-type!")
				end
			else
				EEex_Error("Variable write argument did not have at 2-3 args!")
			end
		else
			EEex_Error("Illegal data-type in assembly declaration!")
		end
	end
	return toReturn
end

function EEex_CalcLabelOffset(address, args, label)
	local toReturn = 0
	for _, arg in ipairs(args) do
		local argType = type(arg)
		if argType == "string" then
			-- processTextArg needs to be "defined" up here to have processSection see it.
			local processTextArg = nil
			local processSection = function(section)
				local prefix = string.sub(section, 1, 1)
				if prefix == ":" or prefix == "#" or prefix == "+" or prefix == ">" or prefix == "*" then
					toReturn = toReturn + 4
				elseif prefix == "!" then -- Processes a macro
					local macroResult = EEex_ResolveMacro(address, args, toReturn, section)
					if type(macroResult) == "string" then
						if processTextArg(macroResult) then
							return true
						end
					else
						toReturn = toReturn + macroResult
					end
				elseif prefix == "@" or prefix == "$" then
					local argLabel = string.sub(section, 2, #section)
					if argLabel == label then
						return true
					end
				else
					toReturn = toReturn + 1
				end
			end
			processTextArg = function(innerArg)
				innerArg = innerArg:gsub("%s+", " ")
				local limit = #innerArg
				local lastSpace = 0
				for i = 1, limit, 1 do
					local char = string.sub(innerArg, i, i)
					if char == " " then
						if i - lastSpace > 1 then
							local section = string.sub(innerArg, lastSpace + 1, i - 1)
							if processSection(section) then
								return true
							end
						end
						lastSpace = i
					end
				end
				if limit - lastSpace > 0 then
					local lastSection = string.sub(innerArg, lastSpace + 1, limit)
					if processSection(lastSection) then
						return true
					end
				end
			end
			if processTextArg(arg) then
				return toReturn
			end
		elseif argType == "table" then
			local argSize = #arg
			if argSize == 2 or argSize == 3 then
				local address = arg[1]
				local length = arg[2]
				local relativeFromOffset = arg[3]
				if type(address) == "number" and type(length) == "number"
					and (not relativeFromOffset or type(relativeFromOffset) == "number")
				then
					toReturn = toReturn + length
				else
					EEex_Error("Variable write argument included invalid data-type!")
				end
			else
				EEex_Error("Variable write argument did not have at 2-3 args!")
			end
		else
			EEex_Error("Illegal data-type in assembly declaration!")
		end
	end
end

function EEex_DecodeAssembly(address, args)

	local iterateSections = function(textArg, func)
		innerArg = innerArg:gsub("%s+", " ")
		local limit = #innerArg
		local lastSpace = 0
		for i = 1, limit, 1 do
			local char = string.sub(innerArg, i, i)
			if char == " " then
				if i - lastSpace > 1 then
					local section = string.sub(innerArg, lastSpace + 1, i - 1)
					if func(section) then
						return true
					end
				end
				lastSpace = i
			end
		end
		if limit - lastSpace > 0 then
			local lastSection = string.sub(innerArg, lastSpace + 1, limit)
			if func(lastSection) then
				return true
			end
		end
	end

	local Classification = {
		["RELATIVE_TO_KNOWN"] = 0,
		["DWORD"] = 1,
		["ABSOLUTE_OF_OFFSET"] = 2,
		["RELATIVE_TO_LABEL"] = 3,
		["ABSOLUTE_OF_LABEL"] = 4,
		["MACRO_FUNCTION"] = 5,
		["LABEL"] = 6,
		["BYTE"] = 7,
		["RELATIVE_TO_ADDRESS"] = 8,
	}

	local resolveDecoded = function(decodedArg, currentWriteAddress)
		local toReturn = nil
		local classification = decodedArg.classification
		if classification == Classification.RELATIVE_TO_KNOWN then
			toReturn = 4
		elseif classification == Classification.DWORD then
			toReturn = 4
		elseif classification == Classification.ABSOLUTE_OF_OFFSET then
			toReturn = 4
		elseif classification == Classification.RELATIVE_TO_LABEL then
			toReturn = 4
		elseif classification == Classification.ABSOLUTE_OF_LABEL then
			toReturn = 4
		elseif classification == Classification.MACRO then

		elseif classification == Classification.LABEL then
			toReturn = 0
		elseif classification == Classification.BYTE then
			toReturn = 1
		end
		return toReturn
	end

	local decodeTextArg = function(arg, func)
		local argType = type(arg)
		if argType == "string" then
			local prefix = string.sub(arg, 1, 1)
			if prefix == ":" then
				local decode = {}
				decode.classification = Classification.RELATIVE_TO_KNOWN
				decode.value = tonumber(string.sub(arg, 2, #arg), 16)
				func(decode)
			elseif prefix == "#" then
				local decode = {}
				decode.classification = Classification.DWORD
				decode.value = tonumber(string.sub(arg, 2, #arg), 16)
				func(decode)
			elseif prefix == "+" then
				local decode = {}
				decode.classification = Classification.ABSOLUTE_OF_OFFSET
				decode.value = tonumber(string.sub(arg, 2, #arg), 16)
				func(decode)
			elseif prefix == ">" then
				local decode = {}
				decode.classification = Classification.RELATIVE_TO_LABEL
				decode.value = string.sub(arg, 2, #arg)
				func(decode)
			elseif prefix == "*" then
				local decode = {}
				decode.classification = Classification.ABSOLUTE_OF_LABEL
				decode.value = string.sub(arg, 2, #arg)
				func(decode)
			elseif prefix == "!" then
				local macroSplit = EEex_SplitByChar(arg, ",")
				local macroSplitName = macroSplit[1]
				local macroName = string.sub(macroSplitName, 2, #macroSplitName)
				local macroValue = EEex_GlobalAssemblyMacros[macroName]
				if not macroValue then
					EEex_Error("Macro !"..macroName.." not defined!")
				end
				local macroType = type(macroValue)
				if macroType == "string" then
					decodeTextArg(macroValue, func)
				elseif macroType == "function" then
					local decode = {}
					decode.classification = Classification.MACRO_FUNCTION
					local decodedMacroArgs = {}
					local limit = #macroSplit
					for i = 2, limit, 1 do
						table.insert(decodedMacroArgs, decodeSection(macroSplit[i]))
					end
					decode.decodedMacroArgs = decodedMacroArgs
					func(decode)
				end
			elseif prefix == "@" then
				local decode = {}
				decode.classification = Classification.LABEL
				decode.value = string.sub(arg, 2, #arg)
				func(decode)
			else
				local decode = {}
				decode.classification = Classification.BYTE
				decode.value = tonumber(string.sub(arg, 1, #arg), 16)
				func(decode)
			end
		else
			EEex_Error("Expected param #1 to be a string!")
		end
	end

	local decodeTableArg = function(arg, func)
		local argType = type(arg)
		if argType == "table" then
			local argSize = #arg
			if argSize == 2 or argSize == 3 then
				local address = arg[1]
				local length = arg[2] -- TODO: I'm going to ignore this for now...
				local relativeFromOffset = arg[3] -- TODO: I'm going to ignore the *value* for now
				if type(address) == "number" and type(length) == "number"
					and (not relativeFromOffset or type(relativeFromOffset) == "number")
				then
					if not relativeFromOffset then
						local decode = {}
						decode.classification = Classification.DWORD
						decode.value = address
						func(decode)
					else
						local decode = {}
						decode.classification = Classification.RELATIVE_TO_ADDRESS
						decode.value = address
						func(decode)
					end
				else
					EEex_Error("Variable write argument included invalid data-type!")
				end
			else
				EEex_Error("Variable write argument did not have 2-3 args!")
			end
		else
			EEex_Error("Expected param #1 to be a table!")
		end
	end

	local decodeArg = function(arg, func)
		local argType = type(arg)
		if argType == "string" then
			iterateSections(arg, function(section)
				decodeTextArg(section, func)
			end)
		elseif argType == "table" then
			decodeTableArg(arg, func)
		end
	end

	local decodeArgs = function(args)
		local structure = {}
		for _, arg in ipairs(args) do
			decodeArg(arg, function(decode) table.insert(structure, decode) end)
		end
		return structure
	end

	local macroHasFlag = function(macroValue, hasFlag)
		for _, flag in ipairs(macroValue.flags) do
			if flag == hasFlag then
				return true
			end
		end
		return false
	end

	local calcLength = function(decodedArg, currentWriteAddress, forceZero)
		local toReturn = nil
		local classification = decodedArg.classification
		if classification == Classification.RELATIVE_TO_KNOWN then
			toReturn = 4
		elseif classification == Classification.DWORD then
			toReturn = 4
		elseif classification == Classification.ABSOLUTE_OF_OFFSET then
			toReturn = 4
		elseif classification == Classification.RELATIVE_TO_LABEL then
			toReturn = 4
		elseif classification == Classification.ABSOLUTE_OF_LABEL then
			toReturn = 4
		elseif classification == Classification.MACRO_FUNCTION then
			local macroValue = decodedArg.value
			if macroHasFlag(macroValue, EEex_MacroFlag.VARIABLE_LENGTH) then
				if not forceZero then
					toReturn = macroValue.write(
						currentWriteAddress,
						decodedArg.decodedMacroArgs,
						function() end
					)
				else
					toReturn = 0
				end
			end
		elseif classification == Classification.LABEL then
			toReturn = 0
		elseif classification == Classification.BYTE then
			toReturn = 1
		end
		return toReturn
	end

	local decodedArgs = decodeArgs(args)

	local localLabelIndexes = {}
	local variableLengthIndexes = {}
	local offsetSensitiveIndexes = {}

	for i, decodedArg in ipairs(decodedArgs) do
		local classification = decodedArg.classification
		if classification == Classification.LABEL then
			labelIndexes[decodedArg.value] = i
		end
	end

	for i, decodedArg in ipairs(decodedArgs) do
		local classification = decodedArg.classification
		if classification == Classification.LABEL then
			labelIndexes[decodedArg.value] = i
		elseif classification == Classification.MACRO_FUNCTION then

			local macroValue = decodedArg.value
			if macroHasFlag(macroValue, EEex_MacroFlag.VARIABLE_LENGTH) then
				table.insert(variableLengthIndexes, i)
			end

			for _, macroArg in ipairs(macroValue.decodedMacroArgs) do

				local classification = decodedArg.classification
				if classification == Classification.RELATIVE_TO_LABEL then

				end
				if classification == Classification.ABSOLUTE_OF_LABEL then
					local labelName = macroArg.value
					--local localLabelDef = localLabelIndexes[]
				end

			end

			if macroHasFlag(macroValue, EEex_MacroFlag.OFFSET_SENSITIVE) then
				table.insert(offsetSensitiveIndexes, i)
			end
		end
	end

	for i, offsetSensitiveIndex in ipairs(offsetSensitiveIndexes) do
		for _, variableLengthIndex in ipairs(variableLengthIndexes) do
			if variableLengthIndex < offsetSensitiveIndex then
				table.insert(decodedArgs[variableLengthIndex].affects, offsetSensitiveIndex)
			end
		end
	end

end




--[[

Core function that writes assembly declarations into memory. args syntax =>

"args" MUST be a table. Acceptable sub-argument types:

	a) string:

		Every byte / operation MUST be seperated by some kind of whitespace. Syntax:

		number  = Writes hex number as byte.
		:number = Writes relative offset to hex number. Depreciated; please use label operations instead.
		#number = Writes hex number as dword.
		+number = Writes address of relative offset. Depreciated; please use label operations instead.
		>label  = Writes relative offset to label's address.
		*label  = Writes label's address.
		@label  = Defines a local label that can be used in the above two operations.
		          (only in current EEex_WriteAssembly call, use EEex_DefineAssemblyLabel()
		          if you want to create a global label)
		$label  = Defines a global label
		!macro  = Writes macro's bytes.

	b) table:

		Used to write the value of a Lua variable into memory.

		table[1] = Value to write.
		table[2] = How many bytes of table[1] to write.
		table[3] = If present, writes the relative offset to table[1] from table[3]. (Optional)

--]]

function EEex_WriteAssembly(address, args, funcOverride)
	local currentWriteAddress = address
	if not funcOverride then
		local writeDump = ""
		EEex_WriteAssembly(address, args, function(writeAddress, byte)
			writeDump = writeDump..EEex_ToHex(byte, 2, true).." "
		end)
		EEex_FunctionLog("\n\nWriting Assembly at "..EEex_ToHex(address).." => "..writeDump.."\n")
		funcOverride = function(writeAddress, byte)
			EEex_WriteByte(writeAddress, byte)
		end
	end
	for _, arg in ipairs(args) do
		local argType = type(arg)
		if argType == "string" then
			-- processTextArg needs to be "defined" up here to have processSection see it.
			local processTextArg = nil
			local processSection = function(section)
				--EEex_FunctionLog("Processing Section: \'"..section.."\"")
				local prefix = string.sub(section, 1, 1)
				if prefix == ":" then -- Writes relative offset to known address
					local targetOffset = tonumber(string.sub(section, 2, #section), 16)
					local relativeOffsetNeeded = targetOffset - (currentWriteAddress + 4)
					for i = 0, 3, 1 do
						local byte = bit32.extract(relativeOffsetNeeded, i * 8, 8)
						funcOverride(currentWriteAddress, byte)
						currentWriteAddress = currentWriteAddress + 1
					end
				elseif prefix == "#" then
					local toWrite = tonumber(string.sub(section, 2, #section), 16)
					for i = 0, 3, 1 do
						local byte = bit32.extract(toWrite, i * 8, 8)
						funcOverride(currentWriteAddress, byte)
						currentWriteAddress = currentWriteAddress + 1
					end
				elseif prefix == "+" then -- Writes absolute address of relative offset
					local targetOffset = currentWriteAddress + 4 + tonumber(string.sub(section, 2, #section), 16)
					for i = 0, 3, 1 do
						local byte = bit32.extract(targetOffset, i * 8, 8)
						funcOverride(currentWriteAddress, byte)
						currentWriteAddress = currentWriteAddress + 1
					end
				elseif prefix == ">" then -- Writes relative offset to label
					local label = string.sub(section, 2, #section)
					local offset = EEex_CalcLabelOffset(address, args, label)
					local targetOffset = nil
					if offset then
						targetOffset = address + offset
					else
						targetOffset = EEex_GlobalAssemblyLabels[label]
						if not targetOffset then
							EEex_Error("Label @"..label.." is not defined in current scope!")
						end
					end
					local relativeOffsetNeeded = targetOffset - (currentWriteAddress + 4)
					for i = 0, 3, 1 do
						local byte = bit32.extract(relativeOffsetNeeded, i * 8, 8)
						funcOverride(currentWriteAddress, byte)
						currentWriteAddress = currentWriteAddress + 1
					end
				elseif prefix == "*" then -- Writes absolute address of label
					local label = string.sub(section, 2, #section)
					local offset = EEex_CalcLabelOffset(address, args, label)
					local targetOffset = nil
					if offset then
						targetOffset = address + offset
					else
						targetOffset = EEex_GlobalAssemblyLabels[label]
						if not targetOffset then
							EEex_Error("Label @"..label.." is not defined in current scope!")
						end
					end
					for i = 0, 3, 1 do
						local byte = bit32.extract(targetOffset, i * 8, 8)
						funcOverride(currentWriteAddress, byte)
						currentWriteAddress = currentWriteAddress + 1
					end
				elseif prefix == "!" then -- Processes a macro
					local macroResult = EEex_ResolveMacro(address, args, toReturn, section, func)
					if type(macroResult) == "string" then
						processTextArg(macroResult)
					else
						currentWriteAddress = currentWriteAddress + macroResult
					end
				elseif prefix == "$" then
					local label = string.sub(section, 2, #section)
					EEex_DefineAssemblyLabel(label, currentWriteAddress)
				elseif prefix ~= "@" then
					local byte = tonumber(section, 16)
					funcOverride(currentWriteAddress, byte)
					currentWriteAddress = currentWriteAddress + 1
				end
			end
			processTextArg = function(innerArg)
				innerArg = innerArg:gsub("%s+", " ")
				local limit = #innerArg
				local lastSpace = 0
				for i = 1, limit, 1 do
					local char = string.sub(innerArg, i, i)
					if char == " " then
						if i - lastSpace > 1 then
							local section = string.sub(innerArg, lastSpace + 1, i - 1)
							processSection(section)
						end
						lastSpace = i
					end
				end
				if limit - lastSpace > 0 then
					local lastSection = string.sub(innerArg, lastSpace + 1, limit)
					processSection(lastSection)
				end
			end
			processTextArg(arg)
		elseif argType == "table" then
			local argSize = #arg
			if argSize == 2 or argSize == 3 then
				local address = arg[1]
				local length = arg[2]
				local relativeFromOffset = arg[3]
				if type(address) == "number" and type(length) == "number"
					and (not relativeFromOffset or type(relativeFromOffset) == "number")
				then
					if relativeFromOffset then address = address - currentWriteAddress - relativeFromOffset end
					local limit = length - 1
					for i = 0, limit, 1 do
						local byte = bit32.extract(address, i * 8, 8)
						funcOverride(currentWriteAddress, byte)
						currentWriteAddress = currentWriteAddress + 1
					end
				else
					EEex_Error("Variable write argument included invalid data-type!")
				end
			else
				EEex_Error("Variable write argument did not have at 2-3 args!")
			end
		else
			EEex_Error("Illegal data-type in assembly declaration!")
		end
	end
end

-- NOTE: Same as EEex_WriteAssembly(), but writes to a dynamically
-- allocated memory space instead of a provided address.
-- Very useful for writing new executable code into memory.
function EEex_WriteAssemblyAuto(assembly)
	local reservedAddress, reservedLength = EEex_ReserveCodeMemory(assembly)
	EEex_FunctionLog("Reserved "..EEex_ToHex(reservedLength).." bytes at "..EEex_ToHex(reservedAddress))
	EEex_WriteAssembly(reservedAddress, assembly)
	return reservedAddress
end

function EEex_WriteAssemblyFunction(functionName, assembly)
	local functionAddress = EEex_WriteAssemblyAuto(assembly)
	EEex_ExposeToLua(functionAddress, functionName)
	return functionAddress
end

function EEex_WriteOpcode(opcodeFunctions)

	--[[

	OFFSET       NAME                  DEFAULT FUNCTION NAME          DEFAULT ADDRESS

	[+0x0]   (__vecDelDtor)   CGameEffect::`vector deleting destructor'  0x56FBB0
	[+0x4]   (Copy)           (auto-generated)                           NA
	[+0x8]   (ApplyEffect)    (nullsub that matches signature)           0x8A81D8
	[+0xC]   (ResolveEffect)  CGameEffect::ResolveEffect                 0x5AB020
	[+0x10]  (OnAdd)          CGameEffect::OnAdd                         0x5A8150
	[+0x14]  (OnAddSpecific)  (nullsub that matches signature)           0x42C8A0
	[+0x18]  (OnLoad)         (nullsub that matches signature)           0x42C8A0
	[+0x1C]  (CheckSave)      CGameEffect::CheckSave                     0x5949D0
	[+0x20]  (UsesDice)       CWarp::GetVirtualKeys                      0x42C890
	[+0x24]  (DisplayString)  CGameEffect::DisplayString                 0x5A6B00
	[+0x28]  (OnRemove)       (nullsub that matches signature)           0x42C8A0

	--]]

	local EEex_RunOpcodeDecode = function(constructor)
		return {[[
			!push_dword #144
			!call >operator_new
			!add_esp_byte 04
			!test_eax_eax
			!je_dword >CGameEffect::DecodeEffect()_fail_label
			!mov_ecx_[ebp+byte] 14
			!push_[ecx+byte] 04
			!push_[ecx]
			!mov_ecx_eax
			!push_[ebp+byte] 10
			!push_[ebp+byte] 0C
			!push_edi
			!call ]], {constructor, 4, 4}, [[
			!mov_esi_eax
			!jmp_dword >CGameEffect::DecodeEffect()_success_label
		]]}
	end

	local EEex_WriteOpcodeConstructor = function(vtbl)
		return EEex_WriteAssemblyAuto({[[
			!push_ebp
			!mov_ebp_esp
			!push_esi
			!push_byte FF
			!push_byte 00
			!push_[ebp+byte] 18
			!mov_esi_ecx
			!push_[ebp+byte] 14
			!push_[ebp+byte] 10
			!push_[ebp+byte] 0C
			!push_[ebp+byte] 08
			!call >CGameEffect::CGameEffect
			!mov_[esi]_dword ]], {vtbl, 4}, [[
			!mov_eax_esi
			!pop_esi
			!pop_ebp
			!ret_word 14 00
		]]})
	end

	local EEex_WriteOpcodeCopy = function(vtbl)
		return EEex_WriteAssemblyAuto({[[
			!push_ebx
			!push_esi
			!push_edi
			!mov_edi_ecx
			!call >CGameEffect::GetItemEffect
			!push_dword #144
			!mov_ebx_eax
			!call >operator_new
			!mov_esi_eax
			!add_esp_byte 04
			!test_esi_esi
			!je_dword >0
			!push_byte FF
			!push_byte 00
			!push_[edi+dword] #88
			!lea_eax_[edi+byte] 7C
			!mov_ecx_esi
			!push_[edi+dword] #84
			!push_[edi+dword] #10C
			!push_eax
			!push_ebx
			!call >CGameEffect::CGameEffect
			!mov_[esi]_dword ]], {vtbl, 4}, [[
			!jmp_dword >1
			@0
			!xor_esi_esi
			@1
			!push_ebx
			!call >_SDL_free
			!add_esp_byte 04
			!test_edi_edi
			!je_dword >2
			!add_edi_byte 04
			!mov_ecx_esi
			!push_edi
			!call >CGameEffect::CopyFromBase
			!pop_edi
			!mov_eax_esi
			!pop_esi
			!pop_ebx
			!ret
			@2
			!xor_edi_edi
			!mov_ecx_esi
			!push_edi
			!call >CGameEffect::CopyFromBase
			!pop_edi
			!mov_eax_esi
			!pop_esi
			!pop_ebx
			!ret
		]]})
	end

	local vtbl = EEex_Malloc(0x2C)
	local opcodeConstructor = EEex_WriteOpcodeConstructor(vtbl)
	local opcodeCopy = EEex_WriteOpcodeCopy(vtbl)

	local writeOrDefault = function(writeAddress, writeStuff, defaultValue)
		local toWrite = nil
		if writeStuff ~= nil then
			toWrite = EEex_WriteAssemblyAuto(writeStuff)
		else
			toWrite = defaultValue
		end
		EEex_WriteDword(writeAddress, toWrite)
	end

	writeOrDefault(vtbl + 0x0,  opcodeFunctions["__vecDelDtor"],  0x56FBB0)
	writeOrDefault(vtbl + 0x4,  opcodeFunctions["Copy"],          opcodeCopy)
	writeOrDefault(vtbl + 0x8,  opcodeFunctions["ApplyEffect"],   0x8A81D8)
	writeOrDefault(vtbl + 0xC,  opcodeFunctions["ResolveEffect"], 0x5AB020)
	writeOrDefault(vtbl + 0x10, opcodeFunctions["OnAdd"],         0x5A8150)
	writeOrDefault(vtbl + 0x14, opcodeFunctions["OnAddSpecific"], 0x42C8A0)
	writeOrDefault(vtbl + 0x18, opcodeFunctions["OnLoad"],        0x42C8A0)
	writeOrDefault(vtbl + 0x1C, opcodeFunctions["CheckSave"],     0x5949D0)
	writeOrDefault(vtbl + 0x20, opcodeFunctions["UsesDice"],      0x42C890)
	writeOrDefault(vtbl + 0x24, opcodeFunctions["DisplayString"], 0x5A6B00)
	writeOrDefault(vtbl + 0x28, opcodeFunctions["OnRemove"],      0x42C8A0)

	return EEex_RunOpcodeDecode(opcodeConstructor)

end

----------------------
--  Bits Utilility  --
----------------------

function EEex_Flags(flags)
	local result = 0x0
	for _, flag in ipairs(flags) do
		result = bit32.bor(result, flag)
	end
	return result
end

function EEex_IsBitSet(original, isSetIndex)
	return bit32.band(original, bit32.lshift(0x1, isSetIndex)) == mask
end

function EEex_IsMaskSet(original, isSetMask)
	return bit32.band(original, tonumber(toSetMask, 2)) == isSetMask
end

function EEex_IsBitUnset(original, isSetIndex)
	return bit32.band(original, bit32.lshift(0x1, isSetIndex)) == 0x0
end

function EEex_IsMaskUnset(original, isUnsetMask)
	return bit32.band(original, tonumber(toSetMask, 2)) == 0x0
end

function EEex_SetBit(original, toSetIndex)
	return bit32.bor(original, bit32.lshift(0x1, toSetIndex))
end

function EEex_SetMask(original, toSetMask)
	return bit32.bor(original, tonumber(toSetMask, 2))
end

function EEex_UnsetBit(original, toUnsetIndex)
	return bit32.band(original, bit32.bnot(bit32.lshift(0x1, toUnsetIndex)))
end

function EEex_UnsetMask(original, toUnsetmask)
	return bit32.band(original, bit32.bnot(tonumber(toUnsetmask, 2)))
end

function EEex_ToHex(number, minLength, prefix)
	if type(number) ~= "number" then
		-- This is usually a critical error somewhere else
		-- in the code, so throw a fully fledged error.
		EEex_Error("Passed a NaN value!")
	end
	local hexString = string.format("%x", number)
	local wantedLength = (minLength or 0) - #hexString
	for i = 1, wantedLength, 1 do
		hexString = "0"..hexString
	end
	hexString = hexString:upper()
	if not prefix then
		return "0x"..hexString
	else
		return hexString
	end
end

-------------------------------
-- Dynamic Memory Allocation --
-------------------------------

-- OS:WINDOWS
function EEex_GetAllocGran()
	local systemInfo = EEex_Malloc(0x24)
	EEex_DllCall("Kernel32", "GetSystemInfo", {systemInfo}, nil, 0x0)
	local allocGran = EEex_ReadDword(systemInfo + 0x1C)
	EEex_Free(systemInfo)
	return allocGran
end

-- OS:WINDOWS
function EEex_VirtualAlloc(dwSize, flProtect)
	-- 0x1000 = MEM_COMMIT
	-- 0x2000 = MEM_RESERVE
	return EEex_DllCall("Kernel32", "VirtualAlloc", {flProtect, EEex_Flags({0x1000, 0x2000}), dwSize, 0x0}, nil, 0x0)
end

EEex_CodePageAllocations = {}
-- NOTE: Please don't call this directly. This is used internally
-- by EEex_ReserveCodeMemory() to allocate additional code pages
-- when needed. If you ignore this message, god help you.
function EEex_AllocCodePage(size)
	local allocGran = EEex_GetAllocGran()
	size = EEex_RoundUp(size, allocGran)
	local address = EEex_VirtualAlloc(size, 0x40)
	local initialEntry = {}
	initialEntry.address = address
	initialEntry.size = size
	initialEntry.reserved = false
	local codePageEntry = {initialEntry}
	table.insert(EEex_CodePageAllocations, codePageEntry)
	return codePageEntry
end

-- NOTE: Dynamically allocates and reserves executable memory for
-- new code. No reason to use instead of EEex_WriteAssemblyAuto,
-- unless you want to reserve memory for later use.
-- Supports filling holes caused by freeing code reservations,
-- (if you would ever want to do that?...), though freeing is not
-- currently implemented.
function EEex_ReserveCodeMemory(assembly)
	local reservedAddress = -1
	local writeLength = -1
	local processCodePageEntry = function(codePage)
		for i, allocEntry in ipairs(codePage) do
			if not allocEntry.reserved then
				writeLength = EEex_CalcWriteLength(allocEntry.address, assembly)
				if writeLength <= allocEntry.size then
					local memLeftOver = allocEntry.size - writeLength
					if memLeftOver > 0 then
						local newAddress = allocEntry.address + writeLength
						local nextEntry = codePage[i + 1]
						if nextEntry then
							if not nextEntry.reserved then
								local addressDifference = nextEntry.address - newAddress
								nextEntry.address = newAddress
								nextEntry.size = allocEntry.size + addressDifference
							else
								local newEntry = {}
								newEntry.address = newAddress
								newEntry.size = memLeftOver
								newEntry.reserved = false
								table.insert(codePage, newEntry, i + 1)
							end
						else
							local newEntry = {}
							newEntry.address = newAddress
							newEntry.size = memLeftOver
							newEntry.reserved = false
							table.insert(codePage, newEntry)
						end
					end
					allocEntry.size = writeLength
					allocEntry.reserved = true
					reservedAddress = allocEntry.address
					return true
				end
			end
		end
		return false
	end
	for _, codePage in ipairs(EEex_CodePageAllocations) do
		if processCodePageEntry(codePage) then
			break
		end
	end
	if reservedAddress == -1 then
		local newCodePage = EEex_AllocCodePage(1)
		if not processCodePageEntry(newCodePage) then
			EEex_Error("***FATAL*** I CAN ONLY ALLOCATE UP TO ALLOCGRAN ***FATAL*** \z
				Tell Bubb he should at least guess at how big the write needs to be, \z
				overestimating where required, instead of crashing like an idiot. \z
				(Though, I must ask, how in the world are you writing a function that is \z
				longer than 65536 bytes?!)")
		end
	end
	return reservedAddress, writeLength
end

-------------------------
-- !CODE MANIPULATION! --
-------------------------

-- OS:WINDOWS
-- Don't use this unless
-- you REALLY know what you are doing.
-- Enables writing to the .text section of the
-- exe (code).
function EEex_DisableCodeProtection()
	local temp = EEex_Malloc(0x4)
	-- 0x40 = PAGE_EXECUTE_READWRITE
	-- 0x401000 = Start of .text section in memory.
	-- 0x49F000 = Size of .text section in memory.
	EEex_DllCall("Kernel32", "VirtualProtect", {temp, 0x40, 0x49F000, 0x401000}, nil, 0x0)
	EEex_Free(temp)
end

-- OS:WINDOWS
-- If you were crazy enough to use
-- EEex_DisableCodeProtection(), please
-- use this to reverse your bad decisions.
-- Reverts the .text section protections back
-- to default.
function EEex_EnableCodeProtection()
	local temp = EEex_Malloc(0x4)
	-- 0x20 = PAGE_EXECUTE_READ
	-- 0x401000 = Start of .text section in memory.
	-- 0x49F000 = Size of .text section in memory.
	EEex_DllCall("Kernel32", "VirtualProtect", {temp, 0x20, 0x49F000, 0x401000}, nil, 0x0)
	EEex_Free(temp)
end

---------------------
--  Input Details  --
---------------------

function EEex_GetTrueMousePos()
	local ecx = EEex_ReadDword(EEex_Label("g_pChitin"))
	local cMousePosition = ecx + EEex_Label("CChitin::cMousePosition")
	local mouseX = EEex_ReadDword(cMousePosition)
	local mouseY = EEex_ReadDword(cMousePosition + 0x4)
	return mouseX, mouseY
end

function EEex_IsCursorWithin(x, y, width, height)
	local mouseX, mouseY = EEex_GetTrueMousePos()
	return mouseX >= x and mouseX <= (x + width)
	       and mouseY >= y and mouseY <= (y + height)
end

function EEex_IsCursorWithinMenu(menuName, menuItemName)
	local offsetX, offsetY = Infinity_GetOffset(menuName)
	local itemX, itemY, itemWidth, itemHeight = Infinity_GetArea(menuItemName)
	return EEex_IsCursorWithin(offsetX + itemX, offsetY + itemY, itemWidth, itemHeight)
end

function EEex_GetFPS()
	return EEex_ReadDword(EEex_Label("CChitin::TIMER_UPDATES_PER_SECOND"))
end

function EEex_TranslateGameXY(mouseGameX, mouseGameY)
	local eax = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local ecx = EEex_ReadDword(eax + EEex_Label("CBaldurChitin::m_pObjectGame"))
	eax = EEex_ReadByte(ecx + 0x3DA0, 0)
	local esi = EEex_ReadDword(ecx + eax * 4 + 0x3DA4)
	esi = esi + 0x484
	local viewportX = EEex_ReadDword(esi + 0x40) - EEex_ReadDword(esi + 0x58)
	local mouseX = mouseGameX - viewportX
	local viewportY = EEex_ReadDword(esi + 0x44) - EEex_ReadDword(esi + 0x5C)
	local mouseY = mouseGameY - viewportY
	local maxViewportX = EEex_ReadDword(esi + 0x60)
	local maxViewportY = EEex_ReadDword(esi + 0x64)
	local screenWidth, screenHeight = Infinity_GetScreenSize()
	local uiMouseX = math.floor(screenWidth * (mouseX / maxViewportX) + 0.5)
	local uiMouseY = math.floor(screenHeight * (mouseY / maxViewportY) + 0.5)
	return uiMouseX, uiMouseY
end

-------------------------
--  Menu Manipulation  --
-------------------------

function EEex_GetMenuAddressFromItem(menuItemName)
	return EEex_ReadDword(EEex_ReadUserdata(Infinity_FindUIItemByName(menuItemName)) + 0x4)
end

function EEex_GetMenuItemAddress(menuItemName)
	return EEex_ReadUserdata(Infinity_FindUIItemByName(menuItemName))
end

function EEex_GetListScroll(listName)
	local menuData = Infinity_FindUIItemByName(listName)
	local scrollPointer = EEex_ReadUserdata(menuData) + 0x110
	return EEex_ReadDword(scrollPointer, scroll)
end

function EEex_SetListScroll(listName, scroll)
	local menuData = Infinity_FindUIItemByName(listName)
	local scrollPointer = EEex_ReadUserdata(menuData) + 0x110
	EEex_WriteDword(scrollPointer, scroll)
end

function EEex_StoreTemplateInstance(templateName, instanceID, storeIntoName)

	local stringAddress = EEex_Malloc(#templateName + 0x1)
	EEex_WriteString(stringAddress, templateName)

	local eax = nil
	local ebx = nil
	local ecx = nil
	local esi = nil
	local edi = nil

	esi = EEex_ReadUserdata(nameToItem[templateName])
	if esi == 0x0 then goto _fail end

	esi = EEex_ReadDword(esi + 0x4)
	edi = 0x0
	esi = EEex_ReadDword(esi + 0x1C)
	if esi == 0x0 then goto _fail end

	::_0x75B4B1::
	eax = EEex_ReadDword(esi + 0x10)
	ebx = EEex_ReadDword(esi + 0x22C)
	if eax == 0x0 then goto _0x75B500 end

	eax = EEex_Call(EEex_Label("__mbscmp"), {eax, stringAddress}, nil, 0x8)
	if eax ~= 0x0 then goto _0x75B500 end

	eax = instanceID
	if EEex_ReadDword(esi + 0xC) ~= eax then goto _0x75B500 end

	eax = EEex_ReadDword(esi + 0x22C)
	if edi == 0x0 then goto _0x75B4E6 end

	::_0x75B4E6::
	ecx = EEex_ReadDword(esi + 0x4)
	if esi ~= EEex_ReadDword(ecx + 0x1C) then goto _0x75B4F5 end
	if eax == 0x0 then goto _0x75B4F5 end

	::_0x75B4F5::
	nameToItem[storeIntoName] = EEex_ToLightUserdata(esi)
	goto _0x75B502

	::_0x75B500::
	edi = esi

	::_0x75B502::
	esi = ebx
	if ebx ~= 0x0 then goto _0x75B4B1 end

	::_fail::
	EEex_Free(stringAddress)
end

-------------------------
--  ActorID Retrieval  --
-------------------------

function EEex_GetActorShare(actorID)
	local resultBlock = EEex_Malloc(0x4)
	EEex_Call(EEex_Label("CGameObjectArray::GetShare"), {resultBlock, actorID}, nil, 0x8)
	local result = EEex_ReadDword(resultBlock)
	EEex_Free(resultBlock)
	return result
end

function EEex_GetActorIDCursor()
	local esi = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local ecx = EEex_ReadDword(esi + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local eax = EEex_ReadByte(ecx + 0x3DA0, 0x0)
	eax = EEex_ReadDword(ecx + eax * 4 + 0x3DA4)
	eax = EEex_ReadDword(eax + 0x21C)
	if eax ~= -0x1 then
		return eax
	else
		return 0x0
	end
end

function EEex_IterateAreas(func)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_gameAreas = m_pObjectGame + 0x3DA4
	for i = 0, 11, 1 do
		local m_gameArea = EEex_ReadDword(m_gameAreas + i * 4)
		if m_gameArea ~= 0x0 then
			func(m_gameArea)
		end
	end
end

function EEex_IterateActorIDs(m_gameArea, func)
	local areaList = EEex_ReadDword(m_gameArea + 0x8E4)
	while areaList ~= 0x0 do
		local areaListID = EEex_ReadDword(areaList + 0x8)
		local share = EEex_GetActorShare(areaListID)
		local objectType = EEex_ReadDword(share + 0x4)
		if objectType == 0x31 then
			func(areaListID)
		end
		areaList = EEex_ReadDword(areaList)
	end
end

function EEex_GetActorIDLoaded()
	local ids = {}
	EEex_IterateAreas(function(m_gameArea)
		EEex_IterateActorIDs(m_gameArea, function(actorID)
			table.insert(ids, actorID)
		end)
	end)
	return ids
end

function EEex_GetActorIDArea(actorID)
	local ids = {}
	local actorShare = EEex_GetActorShare(actorID)
	local m_pArea = EEex_ReadDword(actorShare + 0x14)
	EEex_IterateActorIDs(m_pArea, function(areaActorID)
		table.insert(ids, areaActorID)
	end)
	return ids
end

function EEex_GetActorIDPortrait(slot)
	return EEex_Call(EEex_Label("CInfGame::GetCharacterId"), {slot},
		EEex_ReadDword(EEex_ReadDword(EEex_Label("g_pBaldurChitin")) + EEex_Label("CBaldurChitin::m_pObjectGame")), 0x0)
end

function EEex_GetActorIDSelected()
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin")) -- (CBaldurChitin)
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame")) -- (CInfGame)
	local m_pNodeHead = EEex_ReadDword(m_pObjectGame + 0x3E54)
	if m_pNodeHead ~= 0x0 then
		local actorID = EEex_ReadDword(m_pNodeHead + 0x8)
		return actorID
	else
		return 0x0
	end
end

function EEex_GetAllActorIDSelected()
	local ids = {}
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin")) -- (CBaldurChitin)
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame")) -- (CInfGame)
	local CPtrList = m_pObjectGame + 0x3E50
	EEex_IterateCPtrList(CPtrList, function(actorID)
		table.insert(ids, actorID)
	end)
	return ids
end

------------------------------
--  Actionbar Manipulation  --
------------------------------

function EEex_SetActionbarState(actionbarConfig)
	local eax = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local ecx = EEex_ReadDword(eax + EEex_Label("CBaldurChitin::m_pObjectGame"))
	eax = EEex_ReadByte(ecx + 0x3DA0, 0)
	eax = EEex_ReadDword(ecx + eax * 4 + 0x3DA4)
	eax = EEex_ReadDword(eax + 0x204)
	ecx = eax + 0x2654
	EEex_Call(EEex_Label("CInfButtonArray::SetState"), {actionbarConfig}, ecx, 0x0)
end

EEex_ACTIONBAR_TYPE = {
	["BARD_SONG"] = 2,
	["CAST_SPELL"] = 3,
	["FIND_TRAPS"] = 4,
	["TALK"] = 5,
	["GUARD"] = 7,
	["ATTACK"] = 8,
	["SPECIAL_ABILITIES"] = 10,
	["STEALTH"] = 11,
	["THIEVING"] = 12,
	["TURN_UNDEAD"] = 13,
	["USE_ITEM"] = 14,
	["STOP"] = 15,
	["QUICK_ITEM_1"] = 21,
	["QUICK_ITEM_2"] = 22,
	["QUICK_ITEM_3"] = 23,
	["QUICK_SPELL_1"] = 24,
	["QUICK_SPELL_2"] = 25,
	["QUICK_SPELL_3"] = 26,
	["QUICK_WEAPON_1"] = 27,
	["QUICK_WEAPON_2"] = 28,
	["QUICK_WEAPON_3"] = 29,
	["QUICK_WEAPON_4"] = 30,
	["NONE"] = 100,
}

function EEex_SetActionbarButton(buttonIndex, buttonType)
	if buttonIndex < 0 or buttonIndex > 11 then
		EEex_Error("buttonIndex out of bounds")
	end
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin")) -- (CBaldurChitin)
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame")) -- (CInfGame)
	local m_visibleArea = EEex_ReadByte(m_pObjectGame + 0x3DA0, 0) -- (byte)
	local m_gameArea = EEex_ReadDword(m_pObjectGame + m_visibleArea * 4 + 0x3DA4) -- (CGameArea)
	if m_gameArea ~= 0x0 then
		local m_pGame = EEex_ReadDword(m_gameArea + 0x204) -- (CInfGame)
		local m_cButtonArray = m_pGame + 0x2654 -- (CInfButtonArray)
		local m_cButton = m_cButtonArray + 0x1440 + buttonIndex * 0x4 -- (dword)
		EEex_WriteDword(m_cButton, buttonType)
	end
end

function EEex_GetActionbarButton(buttonIndex)
	if buttonIndex < 0 or buttonIndex > 11 then
		EEex_Error("buttonIndex out of bounds")
	end
	local ecx = EEex_ReadDword(EEex_ReadDword(EEex_Label("g_pBaldurChitin")) + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local actionbarAddress = EEex_ReadDword(EEex_ReadDword(ecx + EEex_ReadByte(ecx + 0x3DA0, 0) * 4 + 0x3DA4) + 0x204) + 0x2654
	return EEex_ReadDword(actionbarAddress + 0x1440 + buttonIndex * 0x4)
end

---------------------------
--  Actor Spell Details  --
---------------------------

function EEex_GetSpellDescription(resrefLocation)
	local eax = EEex_Call(EEex_Label("dimmGetResObject"), {0x0, 0x3EE, resrefLocation}, nil, 0xC)
	return Infinity_FetchString(EEex_ReadDword(EEex_ReadDword(eax + 0x40) + 0x50))
end

function EEex_GetSpellIcon(resrefLocation)
	local eax = EEex_Call(EEex_Label("dimmGetResObject"), {0x0, 0x3EE, resrefLocation}, nil, 0xC)
	return EEex_ReadString(EEex_ReadDword(eax + 0x40) + 0x3A)
end

function EEex_GetSpellName(resrefLocation)
	local eax = EEex_Call(EEex_Label("dimmGetResObject"), {0x0, 0x3EE, resrefLocation}, nil, 0xC)
	local step1 = EEex_ReadDword(eax + 0x40)
	if step1 ~= 0x0 then
		return Infinity_FetchString(EEex_ReadDword(step1 + 0x8))
	else
		return ""
	end
end

function EEex_ProcessKnownClericSpells(actorID, func)
	local eax = nil
	local ebx = EEex_GetActorShare(actorID) + 0x690
	local ecx = nil
	local esi = nil
	local edi = 0x0

	local ebp_0xFC = nil
	local ebp_0x104 = ebx
	local ebp_0x10C = edi
	local ebp_0x118 = nil
	local ebp_0x11C = nil

	local cmpTemp = nil

	::_0x7096F0::
	esi = 0x0
	ebp_0x11C = esi
	if EEex_ReadDword(ebx) <= esi then goto _0x7098FA end

	eax = ebx - 0xC

	::_0x709715::
	ecx = eax
	eax = EEex_Call(EEex_Label("CStringList::FindIndex"), {esi}, ecx, 0x0)

	if eax == 0x0 then goto _0x709724 end

	eax = EEex_ReadDword(eax + 0x8)
	func(eax)

	::_0x709724::
	eax = ebp_0x104
	edi = 0x0
	ebx = 0x0
	ebp_0x118 = edi
	esi = 0x0
	if EEex_ReadDword(eax + 0x220) <= ebx then goto _0x709832 end

	eax = eax + 0x214
	ebp_0xFC = eax

	::_0x7097D4::
	ecx = eax
	eax = EEex_Call(EEex_Label("CStringList::FindIndex"), {esi}, ecx, 0x0)
	if eax ~= 0x0 then goto _0x7097E4 end

	edi = 0x0
	goto _0x7097E7

	::_0x7097E4::
	edi = EEex_ReadDword(eax + 0x8)

	::_0x7097E7::
	ebp_0x118 = ebp_0x118 + 1
	if bit32.band(EEex_ReadByte(edi + 0x8, 0x0), 0x1) == 0x0 then goto _0x709817 end

	ebx = ebx + 1

	::_0x709817::
	eax = ebp_0x104
	esi = esi + 1
	cmpTemp = EEex_ReadDword(eax + 0x220)
	eax = ebp_0xFC
	if esi < cmpTemp then goto _0x7097D4 end

	edi = ebp_0x118

	::_0x709832::
	esi = ebp_0x11C
	esi = esi + 0x1
	ebp_0x11C = esi

	::_0x7098DC::
	ebx = ebp_0x104
	eax = ebx - 0xC
	if esi < EEex_ReadDword(ebx) then goto _0x709715 end

	edi = ebp_0x10C

	::_0x7098FA::
	edi = edi + 0x1
	ebp_0x10C = edi
	ebx = ebx + 0x1C
	ebp_0x104 = ebx
	if edi < 0x7 then goto _0x7096F0 end
end

function EEex_ProcessKnownWizardSpells(actorID, func)
	local eax = nil
	local ebx = EEex_GetActorShare(actorID) + 0x754
	local ecx = nil
	local esi = nil
	local edi = 0x0

	local ebp_0xFC = nil
	local ebp_0x104 = ebx
	local ebp_0x10C = edi
	local ebp_0x118 = nil
	local ebp_0x11C = nil

	local cmpTemp = nil

	::_0x7096F0::
	esi = 0x0
	ebp_0x11C = esi
	if EEex_ReadDword(ebx) <= esi then goto _0x7098FA end

	eax = ebx - 0xC

	::_0x709715::
	ecx = eax
	eax = EEex_Call(EEex_Label("CStringList::FindIndex"), {esi}, ecx, 0x0)

	if eax == 0x0 then goto _0x709724 end

	eax = EEex_ReadDword(eax + 0x8)
	func(eax)

	::_0x709724::
	eax = ebp_0x104
	edi = 0x0
	ebx = 0x0
	ebp_0x118 = edi
	esi = 0x0
	if EEex_ReadDword(eax + 0x220) <= ebx then goto _0x709832 end

	eax = eax + 0x214
	ebp_0xFC = eax

	::_0x7097D4::
	ecx = eax
	eax = EEex_Call(EEex_Label("CStringList::FindIndex"), {esi}, ecx, 0x0)
	if eax ~= 0x0 then goto _0x7097E4 end

	edi = 0x0
	goto _0x7097E7

	::_0x7097E4::
	edi = EEex_ReadDword(eax + 0x8)

	::_0x7097E7::
	ebp_0x118 = ebp_0x118 + 1
	if bit32.band(EEex_ReadByte(edi + 0x8, 0x0), 0x1) == 0x0 then goto _0x709817 end

	ebx = ebx + 1

	::_0x709817::
	eax = ebp_0x104
	esi = esi + 1
	cmpTemp = EEex_ReadDword(eax + 0x220)
	eax = ebp_0xFC
	if esi < cmpTemp then goto _0x7097D4 end

	edi = ebp_0x118

	::_0x709832::
	esi = ebp_0x11C
	esi = esi + 0x1
	ebp_0x11C = esi

	::_0x7098DC::
	ebx = ebp_0x104
	eax = ebx - 0xC
	if esi < EEex_ReadDword(ebx) then goto _0x709715 end

	edi = ebp_0x10C

	::_0x7098FA::
	edi = edi + 0x1
	ebp_0x10C = edi
	ebx = ebx + 0x1C
	ebp_0x104 = ebx
	if edi < 0x9 then goto _0x7096F0 end
end

function EEex_ProcessKnownInnateSpells(actorID, func)
	local eax = nil
	local ebx = EEex_GetActorShare(actorID) + 0x850
	local ecx = nil
	local esi = nil
	local edi = 0x0

	local ebp_0xFC = nil
	local ebp_0x104 = ebx
	local ebp_0x10C = edi
	local ebp_0x118 = nil
	local ebp_0x11C = nil

	local cmpTemp = nil

	::_0x7096F0::
	esi = 0x0
	ebp_0x11C = esi
	if EEex_ReadDword(ebx) <= esi then goto _0x7098FA end

	eax = ebx - 0xC

	::_0x709715::
	ecx = eax
	eax = EEex_Call(EEex_Label("CStringList::FindIndex"), {esi}, ecx, 0x0)

	if eax == 0x0 then goto _0x709724 end

	eax = EEex_ReadDword(eax + 0x8)
	func(eax)

	::_0x709724::
	eax = ebp_0x104
	edi = 0x0
	ebx = 0x0
	ebp_0x118 = edi
	esi = 0x0
	if EEex_ReadDword(eax + 0x220) <= ebx then goto _0x709832 end

	eax = eax + 0x214
	ebp_0xFC = eax

	::_0x7097D4::
	ecx = eax
	eax = EEex_Call(EEex_Label("CStringList::FindIndex"), {esi}, ecx, 0x0)
	if eax ~= 0x0 then goto _0x7097E4 end

	edi = 0x0
	goto _0x7097E7

	::_0x7097E4::
	edi = EEex_ReadDword(eax + 0x8)

	::_0x7097E7::
	ebp_0x118 = ebp_0x118 + 1
	if bit32.band(EEex_ReadByte(edi + 0x8, 0x0), 0x1) == 0x0 then goto _0x709817 end

	ebx = ebx + 1

	::_0x709817::
	eax = ebp_0x104
	esi = esi + 1
	cmpTemp = EEex_ReadDword(eax + 0x220)
	eax = ebp_0xFC
	if esi < cmpTemp then goto _0x7097D4 end

	edi = ebp_0x118

	::_0x709832::
	esi = ebp_0x11C
	esi = esi + 0x1
	ebp_0x11C = esi

	::_0x7098DC::
	ebx = ebp_0x104
	eax = ebx - 0xC
	if esi < EEex_ReadDword(ebx) then goto _0x709715 end

	edi = ebp_0x10C

	::_0x7098FA::
	edi = edi + 0x1
	ebp_0x10C = edi
	ebx = ebx + 0x1C
	ebp_0x104 = ebx
	if edi < 0x1 then goto _0x7096F0 end
end

function EEex_ProcessClericMemorization(actorID, func)
	local info = {}
	local infoIndex = nil
	local maxLevel = 0x7
	local ebx = maxLevel
	local esi = ebx
	local ecx = ebx
	local edi = EEex_GetActorShare(actorID)
	local edx = EEex_ReadDword(edi + 0x12DA)
	ecx = ecx * 0x16
	edx = edx + ecx
	ecx = ebx * 0x8
	ecx = ecx - ebx
	ecx = ecx + 0x223
	local eax = 0x0
	ecx = edi + ecx * 0x4
	::_0::
	if eax >= maxLevel then goto _3 end

	table.insert(info, 1, {})

	eax = EEex_ReadDword(ecx)
	if eax == 0x0 then goto _2 end
	::_1::
	esi = EEex_ReadDword(eax + 0x8)

	infoIndex = #info[1] + 1
	info[1][infoIndex] = {}
	info[1][infoIndex].address = esi

	eax = EEex_ReadDword(eax)
	if eax ~= 0x0 then goto _1 end
	::_2::
	ebx = ebx - 1
	ecx = ecx - 0x1C
	edx = edx - 0x10
	if ebx > 0 then goto _0 end
	::_3::
	for level = 1, #info, 1 do
		local addresses = info[level]
		for i = 1, #addresses, 1 do
			func(level, addresses[i].address)
		end
	end
end

function EEex_ProcessWizardMemorization(actorID, func)
	local info = {}
	local infoIndex = nil
	local maxLevel = 0x9
	local ebx = maxLevel
	local esi = ebx
	local ecx = ebx
	local edi = EEex_GetActorShare(actorID)
	local edx = EEex_ReadDword(edi + 0x124A)
	ecx = ecx * 0x16
	edx = edx + ecx
	ecx = ebx * 0x8
	ecx = ecx - ebx
	ecx = ecx + 0x254
	local eax = 0x0
	ecx = edi + ecx * 0x4

	::_0::
	if eax >= maxLevel then goto _3 end

	table.insert(info, 1, {})

	eax = EEex_ReadDword(ecx)
	if eax == 0x0 then goto _2 end

	::_1::
	esi = EEex_ReadDword(eax + 0x8)

	infoIndex = #info[1] + 1
	info[1][infoIndex] = {}
	info[1][infoIndex].address = esi

	eax = EEex_ReadDword(eax)
	if eax ~= 0x0 then goto _1 end

	::_2::
	ebx = ebx - 1
	ecx = ecx - 0x1C
	edx = edx - 0x10
	if ebx > 0 then goto _0 end

	::_3::
	for level = 1, #info, 1 do
		local addresses = info[level]
		for i = 1, #addresses, 1 do
			func(level, addresses[i].address)
		end
	end
end

function EEex_ProcessInnateMemorization(actorID, func)
	local resrefLocation = nil
	local currentAddress = EEex_ReadDword(EEex_GetActorShare(actorID) + 0xA68)

	::_0::
	if currentAddress == 0x0 then goto _1 end
	resrefLocation = EEex_ReadDword(currentAddress + 0x8)
	func(0x1, resrefLocation)
	currentAddress = EEex_ReadDword(currentAddress)
	goto _0

	::_1::
end

function EEex_GetMemorizedClericSpells(actorID)
	local toReturn = {}
	for i = 1, 7, 1 do
		table.insert(toReturn, {})
	end
	EEex_ProcessClericMemorization(actorID,
		function(level, resrefLocation)
			local memorizedSpell = {}
			memorizedSpell.resref = EEex_ReadString(resrefLocation)
			memorizedSpell.icon = EEex_GetSpellIcon(resrefLocation)
			local flags = EEex_ReadWord(resrefLocation + 0x8, 0x0)
			memorizedSpell.castable = EEex_IsBitUnset(flags, 0x0)
			memorizedSpell.index = #toReturn[level]
			table.insert(toReturn[level], memorizedSpell)
		end
	)
	return toReturn
end

function EEex_GetMemorizedWizardSpells(actorID)
	local toReturn = {}
	for i = 1, 9, 1 do
		table.insert(toReturn, {})
	end
	EEex_ProcessWizardMemorization(actorID,
		function(level, resrefLocation)
			local memorizedSpell = {}
			memorizedSpell.resref = EEex_ReadString(resrefLocation)
			memorizedSpell.icon = EEex_GetSpellIcon(resrefLocation)
			local flags = EEex_ReadWord(resrefLocation + 0x8, 0x0)
			memorizedSpell.castable = EEex_IsBitUnset(flags, 0x0)
			memorizedSpell.index = #toReturn[level]
			table.insert(toReturn[level], memorizedSpell)
		end
	)
	return toReturn
end

function EEex_GetMemorizedInnateSpells(actorID)
	local toReturn = {}
	table.insert(toReturn, {})
	EEex_ProcessInnateMemorization(actorID,
		function(level, resrefLocation)
			local memorizedSpell = {}
			memorizedSpell.resref = EEex_ReadString(resrefLocation)
			memorizedSpell.icon = EEex_GetSpellIcon(resrefLocation)
			local flags = EEex_ReadWord(resrefLocation + 0x8, 0x0)
			memorizedSpell.castable = EEex_IsBitUnset(flags, 0x0)
			memorizedSpell.index = #toReturn[level]
			table.insert(toReturn[level], memorizedSpell)
		end
	)
	return toReturn
end

function EEex_GetKnownClericSpells(actorID)
	local toReturn = {}
	for i = 1, 7, 1 do
		table.insert(toReturn, {})
	end
	EEex_ProcessKnownClericSpells(actorID,
		function(resrefLocation)
			local level = EEex_ReadWord(resrefLocation + 0x8, 0x0) + 1
			local knownSpell = {}
			knownSpell.resref = EEex_ReadString(resrefLocation)
			knownSpell.icon = EEex_GetSpellIcon(resrefLocation)
			knownSpell.name = EEex_GetSpellName(resrefLocation)
			knownSpell.description = EEex_GetSpellDescription(resrefLocation)
			knownSpell.index = #toReturn[level]
			table.insert(toReturn[level], knownSpell)
		end
	)
	return toReturn
end

function EEex_GetKnownWizardSpells(actorID)
	local toReturn = {}
	for i = 1, 9, 1 do
		table.insert(toReturn, {})
	end
	EEex_ProcessKnownWizardSpells(actorID,
		function(resrefLocation)
			local level = EEex_ReadWord(resrefLocation + 0x8, 0x0) + 1
			local knownSpell = {}
			knownSpell.resref = EEex_ReadString(resrefLocation)
			knownSpell.icon = EEex_GetSpellIcon(resrefLocation)
			knownSpell.name = EEex_GetSpellName(resrefLocation)
			knownSpell.description = EEex_GetSpellDescription(resrefLocation)
			knownSpell.index = #toReturn[level]
			table.insert(toReturn[level], knownSpell)
		end
	)
	return toReturn
end

function EEex_GetKnownInnateSpells(actorID)
	local toReturn = {}
	table.insert(toReturn, {})
	EEex_ProcessKnownInnateSpells(actorID,
		function(resrefLocation)
			local level = EEex_ReadWord(resrefLocation + 0x8, 0x0) + 1
			local knownSpell = {}
			knownSpell.resref = EEex_ReadString(resrefLocation)
			knownSpell.icon = EEex_GetSpellIcon(resrefLocation)
			knownSpell.name = EEex_GetSpellName(resrefLocation)
			knownSpell.description = EEex_GetSpellDescription(resrefLocation)
			knownSpell.index = #toReturn[level]
			table.insert(toReturn[level], knownSpell)
		end
	)
	return toReturn
end

-----------------
--  Game State --
-----------------

function EEex_FetchVariable(CVariableHash, variableName)
	local localAddress = EEex_Malloc(#variableName + 5)
	EEex_WriteString(localAddress + 0x4, variableName)
	EEex_Call(EEex_Label("CString::CString(char_const_*)"), {localAddress + 0x4}, localAddress, 0x0)
	local varAddress = EEex_Call(EEex_Label("CVariableHash::FindKey"), {EEex_ReadDword(localAddress)}, CVariableHash, 0x0)
	EEex_Free(localAddress)
	return EEex_ReadDword(varAddress + 0x28)
end

function EEex_GetGlobal(globalName)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_variables = m_pObjectGame + 0x5BC8
	return EEex_FetchVariable(m_variables, globalName)
end

---------------------
--  Actor Details  --
---------------------

function EEex_GetActorAlignment(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x30, 0x3)
end

function EEex_GetActorAllegiance(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x24, 0x0)
end

function EEex_GetActorClass(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x24, 0x3)
end

function EEex_GetActorGender(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x30, 0x2)
end

function EEex_GetActorGeneral(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x24, 0x1)
end

function EEex_GetActorRace(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x24, 0x2)
end

function EEex_GetActorSpecific(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x30, 0x1)
end

function EEex_GetActorKit(actorID)
	return EEex_Call(EEex_Label("CGameSprite::GetKit"), {}, EEex_GetActorShare(actorID), 0x0)
end

function EEex_GetActorAreaSize(actorID)
	local address = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x14)
	local width = EEex_ReadWord(address + 0x4BC, 0x0) * 64
	local height = EEex_ReadWord(address + 0x4C0, 0x0) * 64
	return width, height
end

function EEex_GetActorEffectResrefs(actorID)
	local uniqueList = {}
	local resref = nil

	local esi = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x33AC)
	if esi == 0x0 then goto _fail end

	::_loop::
	edi = EEex_ReadDword(esi + 0x8) + 0x90

	resref = EEex_ReadString(edi)
	if #resref > 0 then
		local spellName = EEex_GetSpellName(edi)
		if spellName ~= "" then
			local value = {}
			value.name = spellName
			value.icon = EEex_GetSpellIcon(edi)
			uniqueList[resref] = value
		end
	end

	esi = EEex_ReadDword(esi)
	if esi ~= 0x0 then goto _loop end

	::_fail::
	local toReturn = {}
	for resref, uniqueValue in pairs(uniqueList) do
		value = {}
		value.resref = resref
		value.name = uniqueValue.name
		value.icon = uniqueValue.icon
		table.insert(toReturn, value)
	end
	return toReturn
end

function EEex_GetActorLocal(actorID, localName)
	local share = EEex_GetActorShare(actorID)
	local localVariables = EEex_ReadDword(share + 0x3758)
	return EEex_FetchVariable(localVariables, localName)
end

function EEex_GetActorLocation(actorID)
	local dataAddress = EEex_GetActorShare(actorID)
	local x = EEex_ReadDword(dataAddress + 0x8)
	local y = EEex_ReadDword(dataAddress + 0xC)
	return x, y
end

function EEex_GetActorModalTimer(actorID)
	local actorData = EEex_GetActorShare(actorID)
	local idRemainder = actorID % 0x64
	local modalTimer = EEex_ReadDword(actorData + 0x2C4)
	local timerRemainder = modalTimer % 0x64
	if timerRemainder < idRemainder then
		return idRemainder - timerRemainder
	else
		return 100 - timerRemainder + idRemainder
	end
end

function EEex_GetActorName(actorID)
	return EEex_ReadString(EEex_ReadDword(EEex_Call(EEex_Label("CGameSprite::GetName"), {0x0}, EEex_GetActorShare(actorID), 0x0)))
end

function EEex_GetActorScriptName(actorID)
	local dataAddress = EEex_GetActorShare(actorID)
	return EEex_ReadString(EEex_ReadDword(EEex_Call(EEex_ReadDword(EEex_ReadDword(dataAddress) + 0x10), {}, dataAddress, 0x0)))
end

function EEex_GetActorSpellState(actorID, splstateID)
	return EEex_Call(EEex_Label("CDerivedStats::GetSpellState"), {splstateID},
		EEex_GetActorShare(actorID) + 0xB30, 0x0) == 1
end

function EEex_GetActorSpellTimer(actorID)
	return EEex_ReadDword(EEex_GetActorShare(actorID) + 0x3870)
end

function EEex_GetActorStat(actorID, statID)
	local ecx = EEex_Call(EEex_Label("CGameSprite::GetActiveStats"), {}, EEex_GetActorShare(actorID), 0x0)
	return EEex_Call(EEex_Label("CDerivedStats::GetAtOffset"), {statID}, ecx, 0x0)
end

----------------------
--  Spell Learning  --
----------------------

function EEex_LearnWizardSpell(actorID, level, resref)
	local resrefAddress = EEex_Malloc(0xC)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::AddKnownSpellMage"), {level, resrefAddress}, EEex_GetActorShare(actorID), 0x0)
	EEex_Free(resrefAddress)
end

function EEex_LearnClericSpell(actorID, level, resref)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local spellLevelListPointer = actorDataAddress + (level * 8 - level + 0x1A1) * 4
	local resrefAddress = EEex_Malloc(0xC)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::AddKnownSpell"),
		{0x0, spellLevelListPointer, level, resrefAddress}, actorDataAddress, 0x0)
	EEex_Free(resrefAddress)
end

function EEex_LearnInnateSpell(actorID, resref)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local spellLevelListPointer = actorDataAddress + 0x844
	local resrefAddress = EEex_Malloc(0xC)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::AddKnownSpell"),
		{0x2, spellLevelListPointer, 0x0, resrefAddress}, actorDataAddress, 0x0)
	EEex_Free(resrefAddress)
end

function EEex_UnlearnWizardSpell(actorID, level, resref)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local resrefAddress = EEex_Malloc(0xC)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::RemoveKnownSpellMage"), {level, resrefAddress}, actorDataAddress, 0x0)
	EEex_Free(resrefAddress)
end

function EEex_UnlearnClericSpell(actorID, level, resref)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local resrefAddress = EEex_Malloc(0xC)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::RemoveKnownSpellPriest"), {level, resrefAddress}, actorDataAddress, 0x0)
	EEex_Free(resrefAddress)
end

function EEex_UnlearnInnateSpell(actorID, resref)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local spellLevelListPointer = actorDataAddress + 0x844
	local resrefAddress = EEex_Malloc(0xC)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::RemoveKnownSpell"), {spellLevelListPointer, resrefAddress}, actorDataAddress, 0x0)
	EEex_Free(resrefAddress)
end

--------------------------
--  Spell Memorization  --
--------------------------

function EEex_GetMaximumMemorizableWizardSpells(actorID, level)
	local esi = EEex_GetActorShare(actorID)
	local ecx = esi + 0xB30
	if EEex_ReadDword(esi + 0x3748) ~= 0x0 then goto _0 end
	ecx = esi + 0x1454
	::_0::
	local edx = level
	local eax = edx
	eax = eax * 0x10
	eax = eax + 0x728
	eax = eax + ecx
	return EEex_ReadWord(eax, 0x1)
end

function EEex_GetMaximumMemorizableClericSpells(actorID, level)
	local esi = EEex_GetActorShare(actorID)
	local ecx = esi + 0xB30
	if EEex_ReadDword(esi + 0x3748) ~= 0x0 then goto _0 end
	ecx = esi + 0x1454
	::_0::
	local edx = level
	local eax = edx
	eax = eax * 0x10
	eax = eax + 0x7B8
	eax = eax + ecx
	return EEex_ReadWord(eax, 0x1)
end

function EEex_GetMaximumMemorizableInnateSpells(actorID)
	return EEex_ReadWord(EEex_ReadDword(EEex_GetActorShare(actorID) + 0x8A0), 0x1)
end

function EEex_MemorizeWizardSpell(actorID, level, resref)
	local esi = EEex_GetActorShare(actorID)
	local ecx = esi + 0xB30
	if EEex_ReadDword(esi + 0x3748) ~= 0x0 then goto _0 end
	ecx = esi + 0x1454
	::_0::
	local edx = level
	local eax = edx
	eax = eax * 0x10
	eax = eax + 0x728
	eax = eax + ecx
	local upperBoundPointer = eax
	local incrementMemorizedPointer = EEex_ReadDword(esi + edx * 0x4 + 0x87C)
	ecx = edx + 0x56
	eax = ecx * 0x8
	eax = eax - ecx
	ecx = esi
	eax = esi + eax * 0x4
	local currentlyMemorizedPointer = eax
	eax = edx * 0x8
	eax = eax - edx
	eax = eax + 0x1D2
	eax = esi + eax * 0x4

	local spellLevelListPointer = EEex_Malloc(0x14)
	EEex_WriteDword(spellLevelListPointer, spellLevelListPointer + 0x8)
	EEex_WriteDword(spellLevelListPointer + 0x4, spellLevelListPointer - 0x8)
	EEex_WriteString(spellLevelListPointer + 0x8, resref)
	local insertedIndexAddress = spellLevelListPointer + 0x11

	EEex_Call(EEex_Label("CGameSprite::MemorizeSpell"), {upperBoundPointer, incrementMemorizedPointer,
		currentlyMemorizedPointer, spellLevelListPointer,
		insertedIndexAddress, 0x0}, esi, 0x0)

	EEex_Free(spellLevelListPointer)
end

function EEex_MemorizeClericSpell(actorID, level, resref)
	local esi = EEex_GetActorShare(actorID)
	local ecx = esi + 0xB30
	if EEex_ReadDword(esi + 0x3748) ~= 0x0 then goto _0 end
	ecx = esi + 0x1454
	::_0::
	local edx = level
	local eax = edx
	eax = eax * 0x10
	eax = eax + 0x7B8
	eax = eax + ecx
	local upperBoundPointer = eax
	local incrementMemorizedPointer = EEex_ReadDword(esi + edx * 0x4 + 0x860)
	ecx = edx + 0x4F
	eax = ecx * 0x8
	eax = eax - ecx
	ecx = esi
	eax = esi + eax * 0x4
	local currentlyMemorizedPointer = eax
	eax = edx * 0x8
	eax = eax - edx
	eax = eax + 0x1A1
	eax = esi + eax * 0x4

	local spellLevelListPointer = EEex_Malloc(0x14)
	EEex_WriteDword(spellLevelListPointer, spellLevelListPointer + 0x8)
	EEex_WriteDword(spellLevelListPointer + 0x4, spellLevelListPointer - 0x8)
	EEex_WriteString(spellLevelListPointer + 0x8, resref)
	local insertedIndexAddress = spellLevelListPointer + 0x11

	EEex_Call(EEex_Label("CGameSprite::MemorizeSpell"), {upperBoundPointer, incrementMemorizedPointer,
		currentlyMemorizedPointer, spellLevelListPointer,
		insertedIndexAddress, 0x0}, esi, 0x0)

	EEex_Free(spellLevelListPointer)
end

function EEex_MemorizeInnateSpell(actorID, resref)
	local ecx = EEex_GetActorShare(actorID)
	local esi = 0x0
	local eax = EEex_ReadDword(ecx + esi * 0x4 + 0x8A0)
	local edx = esi + 0x5F
	local upperBoundPointer = eax
	local incrementMemorizedPointer =  eax
	eax = edx * 0x8
	eax = eax - edx
	eax = ecx + eax * 0x4
	local currentlyMemorizedPointer = eax

	local spellLevelListPointer = EEex_Malloc(0x14)
	EEex_WriteDword(spellLevelListPointer, spellLevelListPointer + 0x8)
	EEex_WriteDword(spellLevelListPointer + 0x4, spellLevelListPointer - 0x8)
	EEex_WriteString(spellLevelListPointer + 0x8, resref)
	local insertedIndexAddress = spellLevelListPointer + 0x11

	EEex_Call(EEex_Label("CGameSprite::MemorizeSpell"), {upperBoundPointer, incrementMemorizedPointer,
		currentlyMemorizedPointer, spellLevelListPointer,
		insertedIndexAddress, 0x0}, ecx, 0x0)

	EEex_Free(spellLevelListPointer)
end

function EEex_UnmemorizeWizardSpell(actorID, level, index)
	EEex_Call(EEex_Label("CGameSprite::UnmemorizeSpellMage"), {index, level}, EEex_GetActorShare(actorID), 0x0)
end

function EEex_UnmemorizeClericSpell(actorID, level, index)
	EEex_Call(EEex_Label("CGameSprite::UnmemorizeSpellPriest"), {index, level}, EEex_GetActorShare(actorID), 0x0)
end

function EEex_UnmemorizeInnateSpell(actorID, index)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local innatesLevel = actorDataAddress + 0xA64
	local eax = EEex_Call(EEex_Label("CStringList::FindIndex"), {index}, innatesLevel, 0x0)
	if eax == 0x0 then goto _0 end
	EEex_Call(EEex_Label("CPtrList::RemoveAt"), {eax}, innatesLevel, 0x0)
	EEex_Free(EEex_ReadDword(eax + 0x8))
	local edi = actorDataAddress + 0x8A0
	EEex_WriteDword(edi, EEex_ReadDword(edi) - 1)
	::_0::
end

-------------
-- Startup --
-------------

(function()

	-- Inform the dynamic memory system of the hardcoded starting memory.
	-- (Had to hardcode initial memory because I couldn't include a VirtualAlloc wrapper
	-- without using more than the 340 alignment bytes available.)
	table.insert(EEex_CodePageAllocations, {
		{["address"] = EEex_InitialMemory, ["size"] = 0x1000, ["reserved"] = false}
	})

	-- Fetch the matched pattern addresses from the loader.
	-- (Thanks @mrfearless!): https://github.com/mrfearless/EEexLoader
	EEex_GlobalAssemblyLabels = EEex_AddressList()

	-- Assembly Macros
	Infinity_DoFile("EEex_Mac")

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

	-- junk result = EEex_WriteString(number address, string toWrite)
	EEex_WriteAssemblyFunction("EEex_WriteString", {
		"55 8B EC 53 51 52 56 57 6A 00 6A 01 FF 75 08 \z
		!call >_lua_tonumberx \z
		83 C4 0C \z
		!call >__ftol2_sse \z
		8B F8 6A 00 6A 02 FF 75 08 \z
		!call >_lua_tolstring \z
		83 C4 0C 8B F0 8A 06 88 07 46 47 80 3E 00 75 F5 C6 07 00 B8 00 00 00 00 5F 5E 5A 59 5B 5D C3"
	})

	local debugHookName = "EEex_ReadDwordDebug"
	local debugHookAddress = EEex_Malloc(#debugHookName + 1)
	EEex_WriteString(debugHookAddress, debugHookName)

	-- Reads a dword at the given address. What more is there to say.

	-- SIGNATURE:
	-- number result = EEex_ReadDword(number address)
	EEex_WriteAssemblyFunction("EEex_ReadDword", {
		"55 8B EC 53 51 52 56 57 6A 00 6A 01 FF 75 08 \z
		!call >_lua_tonumberx \z
		83 C4 0C \z
		!call >__ftol2_sse \z
		FF 30 \z
		50 \z
		68", {debugHookAddress, 4},
		"FF 75 08 \z
		!call >_lua_getglobal \z
		83 C4 08 \z
		DB 04 24 83 EC 04 DD 1C 24 FF 75 08 \z
		!call >_lua_pushnumber \z
		83 C4 0C \z
		FF 34 24 \z
		DB 04 24 83 EC 04 DD 1C 24 FF 75 08 \z
		!call >_lua_pushnumber \z
		83 C4 0C \z
		6A 00 6A 00 6A 00 6A 00 6A 02 FF 75 08 \z
		!call >_lua_pcallk \z
		83 C4 18 \z
		DB 04 24 83 EC 04 DD 1C 24 FF 75 08 \z
		!call >_lua_pushnumber \z
		83 C4 0C B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})

	-- Disabled legacy EEex_ReadDword (no debug hook included)
	--[[
	EEex_WriteAssemblyFunction("EEex_ReadDword", {
		"55 8B EC 53 51 52 56 57 6A 00 6A 01 FF 75 08 \z
		!call >_lua_tonumberx \z
		83 C4 0C \z
		!call >__ftol2_sse \z
		FF 30 DB 04 24 83 EC 04 DD 1C 24 FF 75 08 \z
		!call >_lua_pushnumber \z
		83 C4 0C B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})
	--]]

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
		"55 8B EC 53 51 52 56 57 6A 01 FF 75 08 \z
		!call >_lua_touserdata \z
		83 C4 08 50 DB 04 24 83 EC 04 DD 1C 24 FF 75 08 \z
		!call >_lua_pushnumber \z
		83 C4 0C B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})

	-- Returns a lightuserdata object that points to the given address.

	-- SIGNATURE:
	-- userdata result = EEex_ToLightUserdata(number address)
	EEex_WriteAssemblyFunction("EEex_ToLightUserdata", {
		"55 8B EC 53 51 52 56 57 6A 00 6A 01 FF 75 08 \z
		!call >_lua_tonumberx \z
		83 C4 0C \z
		!call >__ftol2_sse \z
		50 FF 75 08 \z
		!call >_lua_pushlightuserdata \z
		83 C4 08 B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})

	EEex_WriteAssemblyFunction("EEex_GetEffectiveY", {[[

		!push_state

		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!mov_edx_eax

		!mov_eax #55555556
		!shl_edx 02
		!imul_edx
		!mov_eax_edx
		!shr_eax 1F
		!add_eax_edx

		!push_eax
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[ebp+byte] 08
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!mov_eax #01
		!pop_state
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

	--------------------
	--  Version Hook  --
	--------------------

	EEex_DisableCodeProtection()

	local newVersionString = "(EEex) v%d.%d.%d.%d"
	local newVersionStringAddress = EEex_Malloc(#newVersionString + 1)
	EEex_WriteString(newVersionStringAddress, newVersionString)
	EEex_WriteAssembly(EEex_Label("CChitin::GetVersionString()_versionStringPush"), {{newVersionStringAddress, 4}})

	EEex_EnableCodeProtection()

	if not EEex_MinimalStartup then

		--------------------
		--  Engine Hooks  --
		--------------------

		Infinity_DoFile("EEex_Act") -- New Actions (EEex_Lua)
		Infinity_DoFile("EEex_AHo") -- Actions Hook
		Infinity_DoFile("EEex_Bar") -- Actionbar Hook
		Infinity_DoFile("EEex_Brd") -- Bard Thieving Hook
		Infinity_DoFile("EEex_Key") -- keyPressed / keyReleased Hook
		Infinity_DoFile("EEex_Tip") -- isTooltipDisabled Hook
		Infinity_DoFile("EEex_Tri") -- New Triggers / Trigger Changes
		Infinity_DoFile("EEex_Obj") -- New Script Objects
		Infinity_DoFile("EEex_Ren") -- Render Hook
		Infinity_DoFile("EEex_Cre") -- Creature Structure Expansion
		Infinity_DoFile("EEex_Opc") -- New Opcodes / Opcode Changes
		Infinity_DoFile("EEex_Fix") -- Engine Related Bug Fixes

		--------------
		--  Modules --
		--------------

		Infinity_DoFile("EEex_INI") -- Define modules...
		for moduleName, moduleEnabled in pairs(EEex_Modules) do
			if moduleEnabled then
				Infinity_DoFile(moduleName)
			end
		end
	end
end)()
