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

function EEex_ReadSignedWord(address, index)
	local readValue = bit32.extract(EEex_ReadDword(address), index * 0x10, 0x10)
	-- TODO: This is definitely not the right way to do the conversion,
	-- but I have at least 32 bits to play around with; will do for now.
	if readValue >= 32768 then
		return -65536 + readValue
	else
		return readValue
	end
end

function EEex_WriteWord(address, value)
	for i = 0, 1, 1 do
		EEex_WriteByte(address + i, bit32.extract(value, i * 0x8, 0x8))
	end
end

function EEex_WriteDword(address, value)
	for i = 0, 3, 1 do
		EEex_WriteByte(address + i, bit32.extract(value, i * 0x8, 0x8))
	end
end

-- Function for editing text fields without a terminating NULL (e.g. resrefs)
-- This is basically like the WeiDU WRITE_ASCII function.
-- EEex_WriteLString(0x20, "SPWI304", 8)
-- equals
-- WRITE_ASCII 0x20 ~SPWI304~ #8
function EEex_WriteLString(address, toWrite, maxLength)
	local stringLength = string.len(toWrite)
	local not_so_null = EEex_ReadByte(address + stringLength, 0x0)
	EEex_WriteString(address, toWrite)
	EEex_WriteByte(address + stringLength, not_so_null)
	for i = stringLength, maxLength - 1, 1 do
		EEex_WriteByte(address + i, 0x0)
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
	if #string - startIndex + 1 > 0 then
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

function EEex_ConstructCString(string)
	local stringAddress = EEex_Malloc(#string + 1)
	EEex_WriteString(stringAddress, string)
	local CStringAddress = EEex_Malloc(0x4)
	EEex_Call(EEex_Label("CString::CString(char_const_*)"), {stringAddress}, CStringAddress, 0x0)
	EEex_Free(stringAddress)
	return CStringAddress
end

function EEex_FreeCString(CString)
	EEex_Call(EEex_Label("CString::~CString"), {}, CString, 0x0)
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
EEex_MacroQuickPrefixes = {}
function EEex_DefineAssemblyMacro(macroName, macroValue, quickPrefix)
	EEex_GlobalAssemblyMacros[macroName] = macroValue
	if quickPrefix then
		EEex_MacroQuickPrefixes[quickPrefix] = macroValue
	end
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
			local inComment = false
			local processSection = function(section)
				local prefix = string.sub(section, 1, 1)
				if prefix == ";" then
					inComment = not inComment
				elseif not inComment then
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
			local inComment = false
			local processSection = function(section)
				local prefix = string.sub(section, 1, 1)
				if prefix == ";" then
					inComment = not inComment
				elseif not inComment then
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
		textArg = textArg:gsub("%s+", " ")
		local limit = #textArg
		local lastSpace = 0
		for i = 1, limit, 1 do
			local char = string.sub(textArg, i, i)
			if char == " " then
				if i - lastSpace > 1 then
					local section = string.sub(textArg, lastSpace + 1, i - 1)
					if func(section) then
						return true
					end
				end
				lastSpace = i
			end
		end
		if limit - lastSpace > 0 then
			local lastSection = string.sub(textArg, lastSpace + 1, limit)
			if func(lastSection) then
				return true
			end
		end
	end

	local Classification = {
		["NUMBER_STRING"] = 1,
		["RELATIVE_TO_KNOWN"] = 0,
		["ABSOLUTE_OF_OFFSET"] = 2,
		["RELATIVE_TO_LABEL"] = 3,
		["ABSOLUTE_OF_LABEL"] = 4,
		["MACRO_FUNCTION"] = 5,
		["LABEL"] = 6,
		["RELATIVE_TO_ADDRESS"] = 7,
	}

	local decodeTextArg = nil

	local handleMacro = function(macroValue, macroSplit, func)
		local macroType = type(macroValue)
		if macroType == "string" then
			decodeTextArg(macroValue, func)
		elseif macroType == "table" then
			local decodedMacroArgs = {}
			local limit = #macroSplit
			for i = 1, limit, 1 do
				decodeTextArg(macroSplit[i], function(decoded) table.insert(decodedMacroArgs, decoded) end)
			end
			local decode = {}
			decode.classification = Classification.MACRO_FUNCTION
			decode.value = macroValue
			decode.decodedMacroArgs = decodedMacroArgs
			func(decode)
		end
	end

	local defaultMacroArgSplit = function(arg)
		local macroSplit = {}
		local startArgIndex = EEex_CharFind(arg, ",")
		local argLength = #arg
		if startArgIndex ~= -1 and argLength > startArgIndex then
			local argsString = string.sub(arg, startArgIndex + 1, argLength)
			macroSplit = EEex_SplitByChar(argsString, ",")
		end
		return macroSplit
	end

	decodeTextArg = function(arg, func)
		local argType = type(arg)
		if argType == "string" then
			local prefix = string.sub(arg, 1, 1)
			local quickMacro = EEex_MacroQuickPrefixes[prefix]
			if quickMacro then

				local macroSplit = nil
				local quickSplit = quickMacro.quickSplit
				if quickSplit then
					macroSplit = quickSplit(arg)
				else
					macroSplit = defaultMacroArgSplit(arg)
				end
				handleMacro(quickMacro, macroSplit, func)

			elseif prefix == ":" then
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

				local macroSplit = defaultMacroArgSplit(arg)

				local macroSplitName = EEex_SplitByChar(arg, ",")[1]
				local macroName = string.sub(macroSplitName, 2, #macroSplitName)

				local macroValue = EEex_GlobalAssemblyMacros[macroName]
				handleMacro(macroValue, macroSplit, func)

			elseif prefix == "@" then
				local decode = {}
				decode.classification = Classification.LABEL
				decode.value = string.sub(arg, 2, #arg)
				func(decode)
			else
				local decode = {}
				decode.classification = Classification.NUMBER_STRING
				decode.value = arg
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
		elseif classification == Classification.NUMBER_STRING then
			toReturn = 1
		end
		return toReturn
	end

	local decodedArgs = decodeArgs(args)

	local currentAddress = address 
	for i, decodedArg in ipairs(decodedArgs) do

		local classification = decodedArg.classification
		local value = decodedArg.value

		if classification == Classification.MACRO_FUNCTION then
			currentAddress = currentAddress + value.write(currentAddress, decodedArg.decodedMacroArgs, EEex_WriteByte)
		else
			-- Use "hex" Macro if no other Classification / Macro is being used
			local macroSplit = EEex_SplitByChar(value, ",")
			local decodedMacroArgs = {}
			local limit = #macroSplit
			for i = 1, limit, 1 do
				decodeTextArg(macroSplit[i], function(decoded) table.insert(decodedMacroArgs, decoded) end)
			end
			currentAddress = currentAddress + EEex_GlobalAssemblyMacros["hex"].write(currentAddress, decodedMacroArgs, EEex_WriteByte)
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
			local inComment = false
			local processSection = function(section)
				local prefix = string.sub(section, 1, 1)
				if prefix == ";" then
					inComment = not inComment
				elseif not inComment then
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

	writeOrDefault(vtbl + 0x0,  opcodeFunctions["__vecDelDtor"],  EEex_Label("DefaultOpcodeFree"))
	writeOrDefault(vtbl + 0x4,  opcodeFunctions["Copy"],          opcodeCopy)
	writeOrDefault(vtbl + 0x8,  opcodeFunctions["ApplyEffect"],   EEex_Label("DefaultOpcodeApplyEffect"))
	writeOrDefault(vtbl + 0xC,  opcodeFunctions["ResolveEffect"], EEex_Label("DefaultOpcodeResolveEffect"))
	writeOrDefault(vtbl + 0x10, opcodeFunctions["OnAdd"],         EEex_Label("DefaultOpcodeOnAdd"))
	writeOrDefault(vtbl + 0x14, opcodeFunctions["OnAddSpecific"], EEex_Label("DefaultOpcodeNullsub4"))
	writeOrDefault(vtbl + 0x18, opcodeFunctions["OnLoad"],        EEex_Label("DefaultOpcodeNullsub4"))
	writeOrDefault(vtbl + 0x1C, opcodeFunctions["CheckSave"],     EEex_Label("DefaultOpcodeCheckSave"))
	writeOrDefault(vtbl + 0x20, opcodeFunctions["UsesDice"],      EEex_Label("DefaultOpcodeUsesDice"))
	writeOrDefault(vtbl + 0x24, opcodeFunctions["DisplayString"], EEex_Label("DefaultOpcodeDisplayString"))
	writeOrDefault(vtbl + 0x28, opcodeFunctions["OnRemove"],      EEex_Label("DefaultOpcodeNullsub4"))

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
	return bit32.band(original, bit32.lshift(0x1, isSetIndex)) ~= 0x0
end

function EEex_AreBitsSet(original, bitsString)
	return EEex_IsMaskSet(original, tonumber(bitsString, 2))
end

function EEex_IsMaskSet(original, isSetMask)
	return bit32.band(original, isSetMask) == isSetMask
end

function EEex_IsBitUnset(original, isUnsetIndex)
	return bit32.band(original, bit32.lshift(0x1, isUnsetIndex)) == 0x0
end

function EEex_AreBitsUnset(original, bitsString)
	return EEex_IsMaskUnset(original, tonumber(bitsString, 2))
end

function EEex_IsMaskUnset(original, isUnsetMask)
	return bit32.band(original, isUnsetMask) == 0x0
end

function EEex_SetBit(original, toSetIndex)
	return bit32.bor(original, bit32.lshift(0x1, toSetIndex))
end

function EEex_SetBits(original, bitsString)
	return EEex_SetMask(original, tonumber(bitsString, 2))
end

function EEex_SetMask(original, toSetMask)
	return bit32.bor(original, toSetMask)
end

function EEex_UnsetBit(original, toUnsetIndex)
	return bit32.band(original, bit32.bnot(bit32.lshift(0x1, toUnsetIndex)))
end

function EEex_UnsetBits(original, bitsString)
	return EEex_UnsetMask(original, tonumber(bitsString, 2))
end

function EEex_UnsetMask(original, toUnsetmask)
	return bit32.band(original, bit32.bnot(toUnsetmask))
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

function EEex_ScreenToWorldXY(screenX, screenY)
	local CInfinity = EEex_GetCurrentCInfinity()
	local screenXY = EEex_Malloc(0x8)
	EEex_WriteDword(screenXY + 0x0, screenX)
	EEex_WriteDword(screenXY + 0x4, screenY)
	local viewportXY = EEex_Malloc(0x8)
	EEex_Call(EEex_Label("CInfinity::ScreenToViewport"), {screenXY, viewportXY}, CInfinity, 0x0)
	EEex_Free(screenXY)
	local worldXY = EEex_Malloc(0x8)
	EEex_Call(EEex_Label("CInfinity::GetWorldCoordinates"), {viewportXY, worldXY}, CInfinity, 0x0)
	EEex_Free(viewportXY)
	local worldX = EEex_ReadDword(worldXY + 0x0)
	local worldY = EEex_ReadDword(worldXY + 0x4)
	EEex_Free(worldXY)
	return worldX, worldY
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

function EEex_FetchMenuRes(resref)
	local resrefAddress = EEex_Malloc(#resref + 1)
	EEex_WriteString(resrefAddress, resref)
	local res = EEex_Malloc(0x38)
	EEex_Call(EEex_Label("CRes::CRes"), {}, res, 0x0)
	EEex_WriteDword(res + 0x4, resrefAddress)
	EEex_WriteDword(res + 0x8, 0x408)
	local pointerToRes = EEex_Malloc(0x4)
	EEex_WriteDword(pointerToRes, res)
	local result = EEex_Call(EEex_Label("_bsearch"), {
		EEex_Label("CompareCResByTypeThenName"),
		0x4,
		EEex_ReadDword(EEex_Label("resources.m_nSize")),
		EEex_ReadDword(EEex_Label("resources.m_pData")),
		pointerToRes
	}, nil, 0x14)
	EEex_Free(resrefAddress)
	EEex_Free(res)
	EEex_Free(pointerToRes)
	return EEex_ReadDword(result)
end

function EEex_LoadMenuFile(resref)
	EEex_Call(EEex_Label("_saveMenuStack"), {}, nil, 0x0)
	EEex_Memset(EEex_Label("_menuStack"), 0x400, 0x0)
	EEex_WriteDword(EEex_Label("_nextStackMenuIdx"), 0x0)
	local menuSrc = EEex_ReadDword(EEex_Label("_menuSrc"))
	local menuLength = EEex_ReadDword(EEex_Label("_menuLength"))
	EEex_Call(EEex_Label("_uiLoadMenu"), {EEex_FetchMenuRes(resref)}, nil, 0x4)
	EEex_WriteDword(EEex_Label("_menuSrc"), menuSrc)
	EEex_WriteDword(EEex_Label("_menuLength"), menuLength)
	EEex_Call(EEex_Label("_restoreMenuStack"), {}, nil, 0x0)
end

function EEex_GetMenuStructure(menuName)
	local stringAddress = EEex_Malloc(#menuName + 0x1)
	EEex_WriteString(stringAddress, menuName)
	local result = EEex_Call(EEex_Label("_findMenu"), {0x0, 0x0, stringAddress}, nil, 0xC)
	EEex_Free(stringAddress)
	return result
end

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

function EEex_GetActorIDShare(share)
	return EEex_ReadDword(share + 0x34)
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

-----------------------
--  Script Compiler  --
-----------------------

function EEex_ParseObjectString(string)
	local scriptFile = EEex_Malloc(0xE8)
	EEex_Call(EEex_Label("CAIScriptFile::CAIScriptFile"), {}, scriptFile, 0x0)
	local objectString = EEex_ConstructCString(string)
	local objectTypeResult = EEex_Malloc(0x14)
	EEex_Call(EEex_Label("CAIScriptFile::ParseObjectType"), {objectString, objectTypeResult}, scriptFile, 0x0)
	EEex_Call(EEex_Label("CAIScriptFile::~CAIScriptFile"), {}, scriptFile, 0x0)
	EEex_Call(EEex_Label("CString::~CString"), {}, objectString, 0x0)
	return objectTypeResult
end

function EEex_EvalObjectAsActor(object, actorID)
	local objectCopy = EEex_Malloc(0x14)
	EEex_Call(EEex_Label("CAIObjectType::CAIObjectType"), {-0x1, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0}, objectCopy, 0x0)
	EEex_Call(EEex_Label("CAIObjectType::operator_equ"), {object}, objectCopy, 0x0)
	local actorShare = EEex_GetActorShare(actorID)
	EEex_Call(EEex_Label("CAIObjectType::Decode"), {actorShare}, objectCopy, 0x0)
	local matchedShare = EEex_Call(EEex_Label("CAIObjectType::GetShare"), {0x0, actorShare}, objectCopy, 0x0)
	EEex_Call(EEex_Label("CString::~CString"), {}, objectCopy, 0x0)
	EEex_Free(objectCopy)
	if matchedShare ~= 0x0 then
		return EEex_GetActorIDShare(matchedShare)
	else
		return 0x0
	end
end

function EEex_EvalObjectStringAsActor(string, actorID)
	local object = EEex_ParseObjectString(string)
	local matchedID = EEex_EvalObjectAsActor(object, actorID)
	EEex_Call(EEex_Label("CString::~CString"), {}, object, 0x0)
	EEex_Free(object)
	return matchedID
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

function EEex_IsActionbarButtonDown(buttonIndex)
	local capture = EEex_ReadDword(EEex_Label("capture") + 0xC)
	if capture == 0x0 then return false end
	local actionbar = EEex_ReadDword(capture + 0x1AC)
	if actionbar == 0x0 then return false end
	return EEex_ReadDword(actionbar + 0x4) == buttonIndex
end

function EEex_GetActionbarButtonFrame(buttonIndex)
	local frame = buttonArray:GetButtonSequence(buttonIndex)
	if EEex_IsActionbarButtonDown(buttonIndex) then frame = frame + 1 end
	return frame
end

---------------------------
--  Actor Spell Details  --
---------------------------

-- Gets offset 0x0 of the data for the SPL file.
-- The offsets after that are exactly the same as in a SPL file.
-- For example:
-- Infinity_DisplayString(EEex_ReadDword(EEex_GetSpellData("SPWI304") + 0x34))
-- will print:
--  3
-- because offset 0x34 in the SPL file is the spell's level.
-- Warning: this will crash if the spell is not in the game.
function EEex_GetSpellData(resref)
	local resrefLocation = EEex_Malloc(0x8)
	EEex_WriteLString(resrefLocation + 0x0, resref, 8)
	local eax = EEex_Call(EEex_Label("dimmGetResObject"), {0x0, 0x3EE, resrefLocation}, nil, 0xC)
	EEex_Free(resrefLocation)
	if eax ~= 0x0 then
		return EEex_ReadDword(eax + 0x40)
	else
		return 0
	end
end

function EEex_IsSpellValid(resrefLocation)
	local eax = EEex_Call(EEex_Label("dimmGetResObject"), {0x0, 0x3EE, resrefLocation}, nil, 0xC)
	return eax ~= 0x0
end

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
	EEex_ProcessClericMemorization(actorID, function(level, resrefLocation)
		if EEex_IsSpellValid(resrefLocation) then
			local memorizedSpell = {}
			memorizedSpell.resref = EEex_ReadString(resrefLocation)
			memorizedSpell.icon = EEex_GetSpellIcon(resrefLocation)
			local flags = EEex_ReadWord(resrefLocation + 0x8, 0x0)
			memorizedSpell.castable = EEex_IsBitSet(flags, 0x0)
			memorizedSpell.index = #toReturn[level]
			memorizedSpell.name = EEex_GetSpellName(resrefLocation)
			memorizedSpell.description = EEex_GetSpellDescription(resrefLocation)
			table.insert(toReturn[level], memorizedSpell)
		end
	end)
	return toReturn
end

function EEex_GetMemorizedWizardSpells(actorID)
	local toReturn = {}
	for i = 1, 9, 1 do
		table.insert(toReturn, {})
	end
	EEex_ProcessWizardMemorization(actorID, function(level, resrefLocation)
		if EEex_IsSpellValid(resrefLocation) then
			local memorizedSpell = {}
			memorizedSpell.resref = EEex_ReadString(resrefLocation)
			memorizedSpell.icon = EEex_GetSpellIcon(resrefLocation)
			local flags = EEex_ReadWord(resrefLocation + 0x8, 0x0)
			memorizedSpell.castable = EEex_IsBitSet(flags, 0x0)
			memorizedSpell.index = #toReturn[level]
			memorizedSpell.name = EEex_GetSpellName(resrefLocation)
			memorizedSpell.description = EEex_GetSpellDescription(resrefLocation)
			table.insert(toReturn[level], memorizedSpell)
		end
	end)
	return toReturn
end

function EEex_GetMemorizedInnateSpells(actorID)
	local toReturn = {}
	table.insert(toReturn, {})
	EEex_ProcessInnateMemorization(actorID, function(level, resrefLocation)
		if EEex_IsSpellValid(resrefLocation) then
			local memorizedSpell = {}
			memorizedSpell.resref = EEex_ReadString(resrefLocation)
			memorizedSpell.icon = EEex_GetSpellIcon(resrefLocation)
			local flags = EEex_ReadWord(resrefLocation + 0x8, 0x0)
			memorizedSpell.castable = EEex_IsBitSet(flags, 0x0)
			memorizedSpell.index = #toReturn[level]
			memorizedSpell.name = EEex_GetSpellName(resrefLocation)
			memorizedSpell.description = EEex_GetSpellDescription(resrefLocation)
			table.insert(toReturn[level], memorizedSpell)
		end
	end)
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

----------------
-- Game State --
----------------

function EEex_FetchVariable(CVariableHash, variableName)
	local localAddress = EEex_Malloc(#variableName + 5)
	EEex_WriteString(localAddress + 0x4, variableName)
	EEex_Call(EEex_Label("CString::CString(char_const_*)"), {localAddress + 0x4}, localAddress, 0x0)
	local varAddress = EEex_Call(EEex_Label("CVariableHash::FindKey"), 
		{EEex_ReadDword(localAddress)}, CVariableHash, 0x0)
	EEex_Free(localAddress)
	if varAddress ~= 0x0 then
		return EEex_ReadDword(varAddress + 0x28)
	else
		return 0x0
	end
end

-- TODO: Not done yet.
function EEex_SetVariable(CVariableHash, variableName, value)

	local variableNameAddress = EEex_ConstructCString(variableName)
	local varAddress = EEex_Call(EEex_Label("CVariableHash::FindKey"), {variableNameAddress}, CVariableHash, 0x0)
	EEex_FreeCString(variableNameAddress)

	if varAddress ~= 0x0 then
		EEex_WriteDword(varAddress + 0x28, value)
	else
		return 0x0
	end
end

function EEex_GetGlobal(globalName)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_variables = m_pObjectGame + 0x5BC8
	return EEex_FetchVariable(m_variables, globalName)
end

function EEex_GetAreaGlobal(areaResref, globalName)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local areaResrefAddress = EEex_Malloc(#globalName + 5)
	EEex_WriteString(areaResrefAddress + 0x4, areaResref)
	EEex_Call(EEex_Label("CString::CString(char_const_*)"), {areaResrefAddress + 0x4}, areaResrefAddress, 0x0)
	local areaAddress = EEex_Call(EEex_Label("CInfGame::GetArea"), 
		{EEex_ReadDword(areaResrefAddress)}, m_pObjectGame, 0x0)
	if areaAddress ~= 0x0 then
		local areaVariables = areaAddress + 0xA8C
		return EEex_FetchVariable(areaVariables, globalName)
	else
		return 0x0
	end
end

function EEex_2DALoad(_2DAResref)
	local resrefAddress = EEex_Malloc(#_2DAResref + 1)
	EEex_WriteString(resrefAddress, _2DAResref)
	local C2DArray = EEex_Malloc(0x20)
	EEex_Memset(C2DArray, 0x20, 0x0)
	EEex_WriteDword(C2DArray + 0x18, EEex_Label("_afxPchNil"))
	EEex_Call(EEex_Label("C2DArray::Load"), {resrefAddress}, C2DArray, 0x0)
	EEex_Free(resrefAddress)
	return C2DArray
end

function EEex_2DAGetAtStrings(C2DArray, columnString, rowString)
	local columnCString = EEex_ConstructCString(columnString)
	local rowCString = EEex_ConstructCString(rowString)
	local foundCString = EEex_Call(EEex_Label("C2DArray::GetAt(CString*_CString*)"), 
		{rowCString, columnCString}, C2DArray, 0x0)
	EEex_Call(EEex_Label("CString::~CString"), {}, rowCString, 0x0)
	return EEex_ReadString(EEex_ReadDword(foundCString))
end

function EEex_GetActorClassString(actorID)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local kit = EEex_GetActorKit(actorID)
	local class = EEex_GetActorClass(actorID)
	local result = EEex_Malloc(0x4)
	-- TODO: Use Pattern
	EEex_Call(0x5F7A60, {kit, class, result}, m_pObjectGame, 0x0)
	local luaString = EEex_ReadString(EEex_ReadDword(result))
	EEex_Call(EEex_Label("CString::~CString"), {}, result, 0x0)
	return luaString
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

-- Returns the resref of the actor's DLG file.
function EEex_GetActorDialogue(actorID)
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x35A8, 8)
end

function EEex_GetActorKit(actorID)
	return EEex_Call(EEex_Label("CGameSprite::GetKit"), {}, EEex_GetActorShare(actorID), 0x0)
end

function EEex_GetActorAreaRes(actorID)
	if EEex_ReadDword(EEex_GetActorShare(actorID) + 0x14) > 0 then
		return EEex_ReadLString(EEex_ReadDword(EEex_GetActorShare(actorID) + 0x14), 0x8)
	else
		return ""
	end
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

-- Returns a number based on which modal state the actor is using:
-- 0: Not using a modal state
-- 1: Bard Song
-- 2: Detect Traps
-- 3: Stealth
-- 4: Turn Undead
-- 5: Shamanic Dance
function EEex_GetActorModalState(actorID)
	return EEex_ReadWord(EEex_GetActorShare(actorID) + 0x295D, 0x0)
end

-- Returns the resref of the actor's DLG file.
function EEex_GetActorDialogue(actorID)
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x35A8, 8)
end

-- Returns the resref of the actor's override script.
function EEex_GetActorOverrideScript(actorID)
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x65C, 8)
end

function EEex_GetActorSpecificsScript(actorID)
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x2A24, 8)
end

function EEex_GetActorClassScript(actorID)
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x664, 8)
end

function EEex_GetActorRaceScript(actorID)
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x66C, 8)
end

function EEex_GetActorGeneralScript(actorID)
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x674, 8)
end

function EEex_GetActorDefaultScript(actorID)
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x67C, 8)
end

function EEex_GetActorName(actorID)
	return EEex_ReadString(EEex_ReadDword(EEex_Call(EEex_Label("CGameSprite::GetName"), {0x0}, EEex_GetActorShare(actorID), 0x0)))
end

function EEex_GetActorScriptName(actorID)
	local dataAddress = EEex_GetActorShare(actorID)
	return EEex_ReadString(EEex_ReadDword(EEex_Call(EEex_ReadDword(EEex_ReadDword(dataAddress) + 0x10), {}, dataAddress, 0x0)))
end

-- If the actor is a summoned creature, this returns the actor ID of its summoner.
-- If the actor is not a summoned creature, or if it's an image created by Mislead, Project
--  Image or Simulacrum, this will return 0.
-- Also, this will return 0 if the creature had already been summoned before the save was loaded.
function EEex_GetSummonerID(actorID)
	local summonerID = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x130)
	if summonerID == -1 then
		return 0
	else
		return summonerID
	end
end

-- If the actor is an image created by Mislead, Project Image or Simulacrum, this returns the actor ID
--  of the image's master. Otherwise, it returns 0.
function EEex_GetImageMasterID(actorID)
-- This first read will get the master ID even if the image doesn't have a Puppet ID effect.
-- However, that field gets reset to -1 on a reload, so the function also checks a second field.
	local masterID = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x39F4)
	if masterID ~= -1 then
		return masterID
	else
		masterID = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x1604)
		if masterID ~= -1 then
			return masterID
		else
			return 0
		end
	end
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

-- Returns true if the actor has the specified state, based on the numbers in STATE.IDS.
-- For example, if the state parameter is set to 0x8000, it will return true if the actor
--  is hasted or improved hasted, because STATE_HASTE is state 0x8000 in STATE.IDS.
function EEex_HasState(actorID, state)
	return (bit32.band(EEex_ReadDword(EEex_GetActorShare(actorID) + 0xB30), state) == state)
end

-- Returns true if the actor is immune to the specified opcode.
function EEex_IsImmuneToOpcode(actorID, opcode)
	if actorID == 0x0 then return end
	local found_it = false
	EEex_IterateActorEffects(actorID, function(eData)
		if found_it == false then
			local the_opcode = EEex_ReadDword(eData + 0x10)
			local the_parameter2 = EEex_ReadDword(eData + 0x20)
			if (the_opcode == 101 or the_opcode == 198) and the_parameter2 == opcode then
				found_it = true
			end
		end
	end)
	return found_it
end

-- Returns true if the actor is immune to the specified spell level.
-- If includeSpellDeflection is true, it will also return true if the actor has a Spell Deflection,
--  Spell Turning or Spell Trap effect for the specified spell level.
function EEex_IsImmuneToSpellLevel(actorID, level, includeSpellDeflection)
	if actorID == 0x0 then return end
	local found_it = false
	EEex_IterateActorEffects(actorID, function(eData)
		if found_it == false then
			local the_opcode = EEex_ReadDword(eData + 0x10)
			local the_parameter1 = EEex_ReadDword(eData + 0x1C)
			if (the_opcode == 102 or the_opcode == 199) and the_parameter1 == level then
				found_it = true
			elseif includeSpellDeflection then
				local the_parameter2 = EEex_ReadDword(eData + 0x20)
				if (the_opcode == 200 or the_opcode == 201 or the_opcode == 259) and the_parameter2 == level then
					found_it = true
				end
			end
		end
	end)
	return found_it
end

function EEex_GetActorCastTimer(actorID)
	local timerValue = EEex_ReadSignedWord(EEex_GetActorShare(actorID) + 0x3360, 0)
	if timerValue >= 0 then
		return 100 - timerValue
	else
		return 0
	end
end

function EEex_IsActorInCombat(actorID, includeDeadZone)
	local area = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x14)
	local songCounter = EEex_ReadDword(area + 0xAA0)
	local damageCounter = EEex_ReadDword(area + 0xAA4)
	local songCompare = 0
	if includeDeadZone then
		-- Ladies and Gentlemen, the longest label in the entire Infinity Engine:
		songCompare = EEex_ReadDword(EEex_Label("CGameArea::BATTLE_SONG_COUNTER_POST_SONG_DEAD_ZONE"))
	end
	return songCounter > songCompare or damageCounter > 0
end

-- Returns the ID of the target of the actor's current action.
-- If the actor is not targeting another creature (e.g. if the actor
--  is doing nothing, targeting a point, or targeting a container, door, or trap),
--   then it will return 0.
function EEex_GetActorTargetID(actorID)
	local targetID = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x3564)
	if targetID ~= -0x1 then
		return targetID
	else
		return 0x0
	end
end

function EEex_GetActorTargetPoint(actorID)
	local share = EEex_GetActorShare(actorID)
	return EEex_ReadDword(share + 0x3568), EEex_ReadDword(share + 0x356C)
end

-- Returns the ID of the action the actor is currently doing, based on ACTION.IDS.
-- For example, if the actor is currently moving to a point, it will return 23
--  because MoveToPoint() is action 23 in ACTION.IDS.
-- If the actor isn't doing anything, it will return 0.
function EEex_GetActorCurrentAction(actorID)
	return EEex_ReadWord(EEex_GetActorShare(actorID) + 0x2F8, 0x0)
end

EEex_SpellIDSType = {[1] = "SPPR", [2] = "SPWI", [3] = "SPIN", [4] = "SPCL"}

-- Returns the resref of the spell the actor is either currently casting
--  or is about to cast (waiting for its aura to be cleansed).
-- For example, if the actor is casting Fireball, it will return "SPWI304".
-- If the actor is not casting a spell, it will return "".
function EEex_GetActorSpellRES(actorID)
	local actionID = EEex_GetActorCurrentAction(actorID)
	if actionID == 31 or actionID == 113 or actionID == 191 or actionID == 318 or actionID == 95 or actionID == 114 or actionID == 192 or actionID == 319 then
		local spellIDS = EEex_ReadWord(EEex_GetActorShare(actorID) + 0x338, 0x0)
		local spellRES = EEex_ReadLString(EEex_ReadDword(EEex_GetActorShare(actorID) + 0x344), 8)
		if spellRES ~= "" then
			return spellRES
		elseif spellIDS > 0 then
			return (EEex_SpellIDSType[math.floor(spellIDS / 1000)] .. spellIDS % 1000)
		else
			return ""
		end
	else
		return ""
	end
end

function EEex_GetActorCurrentHP(actorID)
	return EEex_ReadSignedWord(EEex_GetActorShare(actorID) + 0x438, 0x0)
end

function EEex_GetActorCurrentDest(actorID)
	local share = EEex_GetActorShare(actorID)
	return EEex_ReadDword(share + 0x3404), EEex_ReadDword(share + 0x3408)
end

function EEex_GetActorPosDest(actorID)
	local share = EEex_GetActorShare(actorID)
	return EEex_ReadDword(share + 0x31D4), EEex_ReadDword(share + 0x31D8)
end

-- Returns the actor's movement rate. For example, if the actor has
--  an effect (opcode 126 or 176) that sets their movement rate to 180,
--   it will return 180.
-- If the actor does not have a movement-modifying effect, it will
--  return the "move_scale" number in the creature's animation INI file.
-- If adjustForHaste is true, the movement rate number will be doubled if
--  the actor is hasted, and it will be halved if the actor is slowed.
function EEex_GetActorMovementRate(actorID, adjustForHaste)
	local speed = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x3884)
	if adjustForHaste then
		if EEex_HasState(actorID, 0x8000) then -- If the actor is hasted
			speed = speed * 2
		end
		if EEex_HasState(actorID, 0x10000) then -- If the actor is slowed
			speed = math.floor(speed / 2)
		end
	end
	return speed
end

function EEex_GetActorAnimation(actorID)
	return EEex_ReadDword(EEex_GetActorShare(actorID) + 0x43C)
end

function EEex_GetActorBaseStrength(actorID)
	-- Returns the actor's Strength ignoring Strength changes from items and spells
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x64C, 0x0)
end

function EEex_GetActorBaseDexterity(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x650, 0x0)
end

function EEex_GetActorBaseConstitution(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x651, 0x0)
end

function EEex_GetActorBaseIntelligence(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x64E, 0x0)
end

function EEex_GetActorBaseWisdom(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x64F, 0x0)
end

function EEex_GetActorBaseCharisma(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x652, 0x0)
end

function EEex_GetActorDirection(actorID)
	return EEex_ReadWord(EEex_GetActorShare(actorID) + 0x31FE, 0x0)
end

function EEex_GetActorRequiredDirection(actorID, targetX, targetY)
	local share = EEex_GetActorShare(actorID)
	local targetPoint = EEex_Malloc(0x8)
	EEex_WriteDword(targetPoint + 0x0, targetX)
	EEex_WriteDword(targetPoint + 0x4, targetY)
	local result = EEex_Call(EEex_Label("CGameSprite::GetDirection"), {targetPoint}, share, 0x0)
	EEex_Free(targetPoint)
	return bit32.extract(result, 0, 0x10)
end

function EEex_IsActorFacing(sourceID, targetID)
	local targetX, targetY = EEex_GetActorLocation(targetID)
	local currentDir = EEex_GetActorDirection(sourceID)
	local requiredDir = EEex_GetActorRequiredDirection(sourceID, targetX, targetY)
	return currentDir == requiredDir
end

function EEex_CyclicBound(num, lowerBound, upperBound)
	local tolerance = upperBound - lowerBound + 1
	local cycleCount = math.floor((num - lowerBound) / tolerance)
	return num - tolerance * cycleCount
end

function EEex_WithinCyclicRange(num, num2, range, lowerBound, higherBound)
	if num2 < (lowerBound + range) then
		-- Underflows
		return num > EEex_CyclicBound(num2 + higherBound - range + 1, lowerBound, higherBound) or num < (num2 + range)
	elseif num2 <= (higherBound - range + 1) then
		-- Normal
		return num > (num2 - range) and num < (num2 + range)
	else
		-- Overflows
		return num > (num2 - range) or num < EEex_CyclicBound(num2 + range, lowerBound, higherBound)
	end
end

function EEex_IsValidBackstabDirection(attackerID, targetID)
	local attackerDirection = EEex_GetActorDirection(attackerID)
	local targetDirection = EEex_GetActorDirection(targetID)
	return EEex_WithinCyclicRange(attackerDirection, targetDirection, 3, 0, 15)
end

function EEex_ApplyEffectToActor(actorID, args)

	local Item_effect_st = EEex_Malloc(0x30)

	local argOrError = function(argKey)
		local arg = args[argKey]
		if arg then
			return arg
		else
			EEex_Error(argKey.." must be defined!")
		end
	end

	local argOrDefault = function(argKey, default)
		local arg = args[argKey]
		if arg then
			return arg
		else
			return default
		end
	end

	local writeResrefArg = function(address, argKey)
		local resref = args[argKey]
		if resref then
			local stringMem = EEex_Malloc(#resref + 1)
			EEex_WriteDword(stringMem + 0x0, 0x0)
			EEex_WriteDword(stringMem + 0x4, 0x0)
			EEex_WriteString(stringMem, resref:upper())
			EEex_WriteDword(address + 0x0, EEex_ReadDword(stringMem + 0x0))
			EEex_WriteDword(address + 0x4, EEex_ReadDword(stringMem + 0x4))
			EEex_Free(stringMem)
		else
			EEex_WriteDword(address + 0x0, 0x0)
			EEex_WriteDword(address + 0x4, 0x0)
		end
	end

	EEex_WriteWord(Item_effect_st + 0x0, argOrError("opcode"))               -- Required
	EEex_WriteByte(Item_effect_st + 0x2, argOrDefault("target", 1))          -- Default: 1 (Self)
	EEex_WriteByte(Item_effect_st + 0x3, argOrDefault("power", 0))           -- Default: 0
	EEex_WriteDword(Item_effect_st + 0x4, argOrDefault("parameter1", 0))     -- Default: 0
	EEex_WriteDword(Item_effect_st + 0x8, argOrDefault("parameter2", 0))     -- Default: 0
	EEex_WriteByte(Item_effect_st + 0xC, argOrDefault("timing", 0))          -- Default: 0 (Instant/Limited)
	EEex_WriteByte(Item_effect_st + 0xD, argOrDefault("resist_dispel", 0))   -- Default: 0 (Natural/Nonmagical)
	EEex_WriteDword(Item_effect_st + 0xE, argOrDefault("duration",  0))      -- Default: 0
	EEex_WriteByte(Item_effect_st + 0x12, argOrDefault("probability1", 100)) -- Default: 100
	EEex_WriteByte(Item_effect_st + 0x13, argOrDefault("probability2", 0))   -- Default: 0
	writeResrefArg(Item_effect_st + 0x14, "resource")
	EEex_WriteDword(Item_effect_st + 0x1C, argOrDefault("dicenumber", 0))  -- Default: 0
	EEex_WriteDword(Item_effect_st + 0x20, argOrDefault("dicesize", 0))    -- Default: 0
	EEex_WriteDword(Item_effect_st + 0x24, argOrDefault("savingthrow", 0)) -- Default: 0 (None)
	EEex_WriteDword(Item_effect_st + 0x28, argOrDefault("savebonus", 0))   -- Default: 0
	EEex_WriteDword(Item_effect_st + 0x2C, argOrDefault("special", 0))     -- Default: 0

	local sourceTarget = argOrDefault("source_target", -0x1)

	local target = EEex_Malloc(0x8)
	EEex_WriteDword(target + 0x0, argOrDefault("target_x", -0x1))
	EEex_WriteDword(target + 0x4, argOrDefault("target_y", -0x1))

	local sourceID = argOrDefault("source_id", -0x1)

	local source = EEex_Malloc(0x8)
	EEex_WriteDword(source + 0x0, argOrDefault("source_x", -0x1))
	EEex_WriteDword(source + 0x4, argOrDefault("source_y", -0x1))

	-- int sourceTarget, CPoint *target, int sourceID, CPoint *source, Item_effect_st *effect 
	local CGameEffect = EEex_Call(EEex_Label("CGameEffect::DecodeEffect"), {sourceTarget, target, sourceID, source, Item_effect_st}, nil, 0x14)
	
	EEex_Free(target)
	EEex_Free(source)
	EEex_Free(Item_effect_st)

	writeResrefArg(CGameEffect + 0x6C, "vvcresource")
	writeResrefArg(CGameEffect + 0x74, "resource2")
	writeResrefArg(CGameEffect + 0x90, "parent_resource")
	EEex_WriteDword(CGameEffect + 0x98, argOrDefault("resource_flags", 0))
	EEex_WriteDword(CGameEffect + 0x9C, argOrDefault("impact_projectile", 0))
	EEex_WriteDword(CGameEffect + 0xA0, argOrDefault("source_slot", 0xFFFFFFFF))
	EEex_WriteDword(CGameEffect + 0xC4, argOrDefault("casterlvl", 1))
	EEex_WriteDword(CGameEffect + 0xC8, argOrDefault("internal_flags", 1))
	EEex_WriteDword(CGameEffect + 0xCC, argOrDefault("sectype", 0))

	local share = EEex_GetActorShare(actorID)
	local vtable = EEex_ReadDword(share)
	-- int immediateResolve, int noSave, char list, CGameEffect *pEffect
	EEex_Call(EEex_ReadDword(vtable + 0x74), {1, 0, 1, CGameEffect}, share, 0x0)
end

-- For each effect on the actor, the function is passed offset 0x0 of
--  the effect data. The offsets in the effect data are the same as the
--   offsets in an EFF file. For example, if you do:
--[[ 
EEex_IterateActorEffects(EEex_GetActorIDCursor(), function(eData)
	local opcode = EEex_ReadDword(eData + 0x10)
	Infinity_DisplayString(opcode)
end)
--]]
-- It will print the opcode number of each effect on the actor.
function EEex_IterateActorEffects(actorID, func)
	local esi = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x33AC)
	while esi ~= 0x0 do
		local edi = EEex_ReadDword(esi + 0x8) - 0x4
		func(edi)
		esi = EEex_ReadDword(esi)
	end
end

-- Table with the effect offsets, along with the size of each one. Names are based on WeiDU function variable names unless not included in there.
EEex_effOff = {
["opcode"] = {0x10, 4}, 
["target"] = {0x14, 4}, 
["power"] = {0x18, 4}, 
["parameter1"] = {0x1C, 4}, 
["parameter2"] = {0x20, 4}, 
["timing"] = {0x24, 4}, 
["duration"] = {0x28, 4}, 
["probability1"] = {0x2C, 2}, 
["probability2"] = {0x2E, 2}, 
["resource"] = {0x30, 8},
["dicenumber"] = {0x38, 4},
["dicesize"] = {0x3C, 4},
["savingthrow"] = {0x40, 4},
["savebonus"] = {0x44, 4},
["special"] = {0x48, 4},
["school"] = {0x4C, 4},
["lowestafflevel"] = {0x54, 4},
["highestafflevel"] = {0x58, 4},
["resist_dispel"] = {0x5C, 4},
["parameter3"] = {0x60, 4},
["parameter4"] = {0x64, 4},
["time_applied"] = {0x6C, 4},
["vvcresource"] = {0x70, 8},
["resource2"] = {0x78, 8},
["casterx"] = {0x80, 4},
["source_x"] = {0x80, 4},
["castery"] = {0x84, 4},
["source_y"] = {0x84, 4},
["targetx"] = {0x88, 4},
["target_x"] = {0x88, 4},
["targety"] = {0x8C, 4},
["target_y"] = {0x8C, 4},
["restype"] = {0x90, 4},
["effsource"] = {0x94, 8},
["parent_resource"] = {0x94, 8},
["resource_flags"] = {0x9C, 4},
["impact_projectile"] = {0xA0, 4},
["sourceslot"] = {0xA4, 4},
["effvar"] = {0xA8, 32},
["casterlvl"] = {0xC8, 4},
["internal_flags"] = {0xCC, 4},
["sectype"] = {0xD0, 4},
["source_id"] = {0x110, 4}}


-- This is basically like the WeiDU ALTER_EFFECT function, except that it alters effects in the middle of the game!
-- EEex_AlterActorEffect(actorID, {{"opcode",232},{"parameter2",0},{"resource","SPWI304"}}, {{"resource","SPWI502"}}, 2)
-- equals
-- LPF ALTER_EFFECT INT_VAR multi_match=2 match_opcode=232 match_parameter2=0 STR_VAR match_resource=~SPWI304~ resource=~SPWI502~ END
function EEex_AlterActorEffect(actorID, match_table, set_table, multi_match)
	if multi_match == -1 then
		multi_match = 65535
	end
	local esi = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x33AC)
	local match_count = 0
	while esi ~= 0x0 and match_count < multi_match do
		local edi = EEex_ReadDword(esi + 0x8) - 0x4
		local matched = true
		for key,value in ipairs(match_table) do
			local readSize = EEex_effOff[value[1]][2]
			if readSize == 4 then
				if EEex_ReadDword(edi + EEex_effOff[value[1]][1]) ~= value[2] then
					matched = false
				end
			elseif readSize == 2 then
				if EEex_ReadWord(edi + EEex_effOff[value[1]][1], 0x0) ~= value[2] then
					matched = false
				end
			else
				if EEex_ReadLString(edi + EEex_effOff[value[1]][1], readSize) ~= value[2] then
					matched = false
				end
			end
		end
		if matched then
			for key,value in ipairs(set_table) do
				local writeSize = EEex_effOff[value[1]][2]
				if writeSize == 4 then
					EEex_WriteDword(edi + EEex_effOff[value[1]][1], value[2])
				elseif writeSize == 2 then
					EEex_WriteWord(edi + EEex_effOff[value[1]][1], value[2])
				else
					EEex_WriteLString(edi + EEex_effOff[value[1]][1], value[2], writeSize)
				end
			end
			match_count = match_count + 1
		end
		esi = EEex_ReadDword(esi)
	end
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

	-- Needed to copy CStringList from new creature stats to new temp stats
	EEex_WriteAssemblyFunction("EEex_CopyCStringList", {[[

		!build_stack_frame
		!sub_esp_byte 04
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
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!mov_ebx_eax

		!mov_esi_[ebx+byte] 04
		!test_esi_esi
		!jz_dword >freeing_done

		@free_loop
		!lea_ecx_[esi+byte] 08
		!call >CString::~CString
		!mov_esi_[esi]
		!test_esi_esi
		!jnz_dword >free_loop

		@freeing_done
		!mov_ecx_ebx
		!call >CObList::RemoveAll
		!mov_edi_[edi+byte] 04
		!test_edi_edi
		!jz_dword >done

		@copy_loop
		!lea_eax_[edi+byte] 08
		!push_eax
		!lea_ecx_[ebp+byte] FC
		!call :778F80
		!mov_eax_[eax]

		!push_eax
		!mov_ecx_ebx
		!call >CPtrList::AddTail

		!mov_edi_[edi]
		!test_edi_edi
		!jnz_dword >copy_loop

		@done
		!mov_eax #00
		!restore_stack_frame
		!ret

	]]})

	-- Needed to clear CStringList from new creature stats and new temp stats
	EEex_WriteAssemblyFunction("EEex_ClearCStringList", {[[

		!build_stack_frame
		!push_registers

		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!mov_ebx_eax

		!mov_esi_[ebx+byte] 04
		!test_esi_esi
		!jz_dword >freeing_done

		@free_loop
		!lea_ecx_[esi+byte] 08
		!call >CString::~CString
		!mov_esi_[esi]
		!test_esi_esi
		!jnz_dword >free_loop

		@freeing_done
		!mov_ecx_ebx
		!call >CObList::RemoveAll
		!mov_edi_[edi+byte] 04

		!mov_eax #00
		!restore_stack_frame
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

	----------------
	--  2DA Files --
	----------------

	--EEex_Str = EEex_2DALoad("EEEX_STR")

	if not EEex_MinimalStartup then

		--------------------
		--  Engine Hooks  --
		--------------------

		Infinity_DoFile("EEex_Men") -- Menu Hooks
		Infinity_DoFile("EEex_Lua") -- Lua Hooks
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
		--Infinity_DoFile("EEex_Pau") -- Auto-Pause Related Things

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
