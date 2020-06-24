--[[

This is EEex's main file. Vital initialization hooks and
most utility functions are defined within this file.

--]]

-------------
-- Options --
-------------

-- Limits EEex startup to this file only. I.E. other EEex files and
-- EEex modules won't be executed / enabled when this is set to true.
EEex_MinimalStartup = false

-- Automatically detects and logs potential memory leaks. Do not turn this on
-- arbitrarily, it uses a lot of resources and can't be sustained for long.
EEex_LeakDetectionMode = false

--------------------
-- Initialization --
--------------------

-- Holds a pointer to the memory reserved by the loader's EEex_Init().
-- Initial memory is used to hold vital EEex assembly functions,
-- which are required to allocate, write, and execute assembly from Lua.
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

-- List of listeners to be executed when UI.MENU is reset,
-- (either from an F5 reload, or programmatically via EEex).
EEex_ResetListeners = {}

-- Adds the given function to the EEex_ResetListeners list.
function EEex_AddResetListener(listener)
	table.insert(EEex_ResetListeners, listener)
end

-- Used by EEex_Reset() to ignore engine startup, (which isn't a "reset").
EEex_IgnoreFirstReset = true

-- Executes the listeners in EEex_ResetListeners. Called by first line in
-- UI.MENU - which should have been inserted by the EEex WeiDU installer.
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

Infinity_DoFile("M__EXSTR") -- Strref file for EEex; this needs to be run early so tables can
-- reference the strrefs.

---------------------
-- Memory Utililty --
---------------------

-- Lua wrapper for malloc().
function EEex_Malloc(size, callerID)
	return EEex_Call(EEex_Label("_malloc"), {callerID, size}, nil, 0x8)
end

-- Lua wrapper for free().
function EEex_Free(address)
	return EEex_Call(EEex_Label("_SDL_free"), {address}, nil, 0x4)
end

-- Reads a dword from the given address, extracting and returning the "index"th byte.
function EEex_ReadByte(address, index)
	return bit32.extract(EEex_ReadDword(address), index * 0x8, 0x8)
end

-- Reads a dword from the given address, extracting and returning the "index"th signed byte.
function EEex_ReadSignedByte(address, index)
	local readValue = bit32.extract(EEex_ReadDword(address), index * 0x8, 0x8)
	-- TODO: Implement better conversion code.
	if readValue >= 128 then
		return -256 + readValue
	else
		return readValue
	end
end

-- Reads a dword from the given address, extracting and returning the "index"th word.
function EEex_ReadWord(address, index)
	return bit32.extract(EEex_ReadDword(address), index * 0x10, 0x10)
end

-- Reads a dword from the given address, extracting and returning the "index"th signed word.
function EEex_ReadSignedWord(address, index)
	local readValue = bit32.extract(EEex_ReadDword(address), index * 0x10, 0x10)
	-- TODO: Implement better conversion code.
	if readValue >= 32768 then
		return -65536 + readValue
	else
		return readValue
	end
end

-- Writes a word at the given address.
function EEex_WriteWord(address, value)
	for i = 0, 1, 1 do
		EEex_WriteByte(address + i, bit32.extract(value, i * 0x8, 0x8))
	end
end

-- Writes a dword at the given address.
function EEex_WriteDword(address, value)
	for i = 0, 3, 1 do
		EEex_WriteByte(address + i, bit32.extract(value, i * 0x8, 0x8))
	end
end

function EEex_WriteStringAuto(string)
	local address = EEex_Malloc(#string + 1, 39)
	EEex_WriteString(address, string)
	return address
end

-- OS: WINDOWS
-- Calls a function from a DLL. The DLL will be loaded into the process's address space if it isn't already.
-- dll  => String containing dll's name, not including the extension. Example: "User32".
-- proc => String containing function name to call. Example: "MessageBoxA".
-- args => Table containing function args, in reverse order. Example: {0x40, "Caption", "Message", 0x0}.
-- ecx  => Number representing the "this" register value. Should be nil if proc doesn't use "this".
-- pop  => Number of bytes, (should be an increment of 0x4), to pop off the stack after returning from proc.
--         Note: The stack must be balanced by the end of the call - if this value is wrong, the game will crash.
function EEex_DllCall(dll, proc, args, ecx, pop)
	local procaddress = #dll + 1
	local dlladdress = EEex_Malloc(procaddress + #proc + 1, 40)
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

-- Logs a message to the console window, prepending the message with the calling function's name.
function EEex_FunctionLog(message)
	local name = debug.getinfo(2, "n").name
	if name == nil then name = "(Unknown)" end
	Infinity_Log("[EEex] "..name..": "..message)
end

-- Throws a Lua error, appending the current stacktrace to the end of the message.
function EEex_Error(message)
	error(message.." "..debug.traceback())
end

-- Checked in EEex_ReadDwordDebug(); if true, prevents debug output.
EEex_ReadDwordDebug_Suppress = false

-- Called by EEex_ReadDword() to help debug crashes. Disabled by default.
function EEex_ReadDwordDebug(reading, read)
	if not EEex_ReadDwordDebug_Suppress then
		--Infinity_Log("[EEex] EEex_ReadDwordDebug: "..EEex_ToHex(reading).." => "..EEex_ToHex(read))
	end
end

-- Dumps the contents of the Lua stack to the console window. For debugging.
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

-- Dumps the contents of dynamically allocated EEex code to the console window. For debugging.
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
-- Displays a message box to the user. Note: Suspends game until closed, which can be useful for debugging.
function EEex_MessageBox(message)
	local caption = "EEex"
	local messageAddress = EEex_Malloc(#message + 1 + #caption + 1, 41)
	local captionAddress = messageAddress + #message + 1
	EEex_WriteString(messageAddress, message)
	EEex_WriteString(captionAddress, caption)
	EEex_DllCall("User32", "MessageBoxA", {EEex_Flags({0x40}), captionAddress, messageAddress, 0x0}, nil, 0x0)
	EEex_Free(messageAddress)
end

-- Like Infinity_DisplayString, but can print nil values, booleans, and entire tables.
function EEex_DS(string)
	Infinity_DisplayString(EEex_ToString(string))
end

function EEex_ToString(string)
	if string == nil then
		return "nil"
	else
		local stringType = type(string)
		if stringType == "boolean" then
			if string then
				return "true"
			else
				return "false"
			end
		elseif stringType == "function" then
			return "function()"
		elseif stringType == "table" then
			local tableString = "{"
			if string[1] == nil then
				for k, v in pairs(string) do
					tableString = tableString .. "[" .. EEex_ToString(k) .. "] = " .. EEex_ToString(v) .. ", "
				end
			else
				for k, v in ipairs(string) do
					tableString = tableString .. EEex_ToString(v) .. ", "
				end
			end
			tableString = tableString .. "}"
			return tableString
		elseif stringType == "string" then
			return "\"" .. string .. "\""
		else
			return string
		end
		
	end
end

--------------------
-- Random Utility --
--------------------

function EEex_Once(variable, func)
	if not _G[variable] then
		_G[variable] = true
		func()
	end
end

-- Flattens given table so that any nested tables are merged.
-- Example: {"Hello", {"World"}} becomes {"Hello", "World"}.
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

-- Gets the distance between two points.
function EEex_GetDistance(x1, y1, x2, y2)
	return math.floor((((x1 - x2) ^ 2) + ((y1 - y2) ^ 2)) ^ .5) 
end

-- Rounds the given number upwards to the nearest multiple.
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

-- Checks the first character of a string.
function EEex_StringStartsWith(string, startsWith)
	return string.sub(string, 1, #startsWith) == startsWith
end

-- Finds the first instance of the given char after or at the starting index.
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

-- Returns a table populated by the string sequences separated by the given char.
-- Example: EEex_SplitByChar("Hello World", " ") returns {"Hello", "World"}.
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

-- Given a pointer to a CPtrList, iterates through every
-- element and calls func() with element as argument. If func()
-- returns true, the iteration breaks and instantly returns.
function EEex_IterateCPtrList(CPtrList, func)
	local m_pNext = EEex_ReadDword(CPtrList + 0x4)
	while m_pNext ~= 0x0 do
		if func(EEex_ReadDword(m_pNext + 0x8)) then
			break
		end
		m_pNext = EEex_ReadDword(m_pNext)
	end
end

-- Frees the memory allocated by the given CPtrList pointer.
function EEex_FreeCPtrList(CPtrList)
	local m_nCount = EEex_ReadDword(CPtrList + 0xC)
	while m_nCount ~= 0 do
		EEex_Free(EEex_Call(EEex_Label("CObList::RemoveHead"), {}, CPtrList, 0x0))
		m_nCount = EEex_ReadDword(CPtrList + 0xC)
	end
	EEex_Call(EEex_Label("CObList::RemoveAll"), {}, CPtrList, 0x0)
	EEex_Call(EEex_ReadDword(EEex_ReadDword(CPtrList)), {0x1}, CPtrList, 0x0)
end

-- Returns the current CInfinity instance - mostly contains fields pertaining to rendering and viewport.
function EEex_GetCurrentCInfinity()
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin")) -- (CBaldurChitin)
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame")) -- (CInfGame)
	local m_visibleArea = EEex_ReadByte(m_pObjectGame + 0x3DA0, 0) -- (byte)
	local m_gameArea = EEex_ReadDword(m_pObjectGame + m_visibleArea * 4 + 0x3DA4) -- (CGameArea)
	local m_cInfinity = m_gameArea + 0x484 -- (CInfinity)
	return m_cInfinity
end

-- Constructs and returns a CString from the given Lua string.
function EEex_ConstructCString(string)
	local stringAddress = EEex_Malloc(#string + 1, 42)
	EEex_WriteString(stringAddress, string)
	local CStringAddress = EEex_Malloc(0x4, 43)
	EEex_Call(EEex_Label("CString::CString(char_const_*)"), {stringAddress}, CStringAddress, 0x0)
	EEex_Free(stringAddress)
	return CStringAddress
end

-- Copies the given CString and returns its pointer.
function EEex_CopyCString(CString)
	local CStringAddress = EEex_Malloc(0x4, 44)
	EEex_Call(EEex_Label("CString::CString(CString_const_&)"), {CString}, CStringAddress, 0x0)
	return CStringAddress
end

-- Frees the memory allocated by the given CString pointer.
function EEex_FreeCString(CString)
	EEex_Call(EEex_Label("CString::~CString"), {}, CString, 0x0)
	EEex_Free(CString)
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

function EEex_HookBeforeCall(address, assembly)
	EEex_WriteAssembly(address, {"!jmp_dword", {EEex_WriteAssemblyAuto(
		EEex_ConcatTables({
			assembly,
			{
				"!call", {address + EEex_ReadDword(address + 0x1) + 0x5, 4, 4},
			},
			{[[
				@return
				!jmp_dword ]], {address + 0x5, 4, 4},
			},
		})
	), 4, 4}})
end

-- Convenience function that, when given an address to the start of a standard x86asm call,
-- inserts the given assembly definition in such a way that it runs after the call has taken place.
-- Automatically inserts a valid jmp instruction, (@return label), that resumes normal execution.
function EEex_HookAfterCall(address, assembly)
	EEex_WriteAssembly(address, {"!jmp_dword", {EEex_WriteAssemblyAuto(
		EEex_ConcatTables({
			{
				"!call", {address + EEex_ReadDword(address + 0x1) + 0x5, 4, 4},
			},
			assembly,
			{[[
				@return
				!jmp_dword ]], {address + 0x5, 4, 4},
			},
		})
	), 4, 4}})
end

function EEex_HookReplaceDest(address, assembly)
	EEex_WriteAssembly(address, {"!jmp_dword", {EEex_WriteAssemblyAuto(
		EEex_ConcatTables({
			assembly,
			{[[
				@return
				!jmp_dword ]], {address + 0x5, 4, 4},
			},
		})
	), 4, 4}})
end

function EEex_HookJump(address, restoreSize, assembly)

	local storeBytes = function(startAddress, size)
		local bytes = {}
		local limit = startAddress + size - 1
		for i = startAddress, limit, 1 do
			table.insert(bytes, {EEex_ReadByte(i, 0), 1})
		end
		return bytes
	end

	local byteToDwordJmp = {
		[0x70] = {{0x0F, 1}, {0x80, 1}},
		[0x71] = {{0x0F, 1}, {0x81, 1}},
		[0x72] = {{0x0F, 1}, {0x82, 1}},
		[0x73] = {{0x0F, 1}, {0x83, 1}},
		[0x74] = {{0x0F, 1}, {0x84, 1}},
		[0x75] = {{0x0F, 1}, {0x85, 1}},
		[0x76] = {{0x0F, 1}, {0x86, 1}},
		[0x77] = {{0x0F, 1}, {0x87, 1}},
		[0x78] = {{0x0F, 1}, {0x88, 1}},
		[0x79] = {{0x0F, 1}, {0x89, 1}},
		[0x7A] = {{0x0F, 1}, {0x8A, 1}},
		[0x7B] = {{0x0F, 1}, {0x8B, 1}},
		[0x7C] = {{0x0F, 1}, {0x8C, 1}},
		[0x7D] = {{0x0F, 1}, {0x8D, 1}},
		[0x7E] = {{0x0F, 1}, {0x8E, 1}},
		[0x7F] = {{0x0F, 1}, {0x8F, 1}},
		[0xEB] = {{0xE9, 1}},
	}

	local instructionByte = EEex_ReadByte(address, 0)
	local instructionBytes = {}
	local instructionSize = nil
	local offset = nil

	local switchBytes = byteToDwordJmp[instructionByte]
	if switchBytes then
		instructionBytes = switchBytes
		instructionSize = 2
		offset = EEex_ReadByte(address + 1, 0)
	elseif instructionByte == 0xE9 then
		instructionBytes = {{instructionByte, 1}}
		instructionSize = 5
		offset = EEex_ReadDword(address + 1)
	else
		instructionBytes = {{instructionByte, 1}, {EEex_ReadByte(address + 1, 0), 1}}
		instructionSize = 6
		offset = EEex_ReadDword(address + 2)
	end

	local afterInstruction = address + instructionSize
	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = storeBytes(afterInstruction, restoreSize)
	local jmpDest = afterInstruction + offset

	EEex_DefineAssemblyLabel("jmp_success", jmpDest)

	local hookCode = EEex_WriteAssemblyAuto(EEex_ConcatTables({
		assembly,
		"@jmp",
		instructionBytes,
		{
			{jmpDest, 4, 4},
		},
		"@jmp_fail",
		restoreBytes,
		{[[
			!jmp_dword ]], {jmpFailDest, 4, 4},
		},
	}))
	
	EEex_WriteAssembly(address, {"!jmp_dword", {hookCode, 4, 4}})
end

function EEex_HookRestore(address, restoreDelay, restoreSize, assembly)

	local storeBytes = function(startAddress, size)
		local bytes = {}
		local limit = startAddress + size - 1
		for i = startAddress, limit, 1 do
			table.insert(bytes, {EEex_ReadByte(i, 0), 1})
		end
		return bytes
	end

	local afterInstruction = address + restoreDelay + restoreSize
	local restoreBytes = storeBytes(address + restoreDelay, restoreSize)

	local nops = {}
	local limit = restoreDelay + restoreSize - 5
	for i = 1, limit, 1 do
		table.insert(nops, {0x90, 1})
	end

	local hookCode = EEex_WriteAssemblyAuto(EEex_ConcatTables({
		assembly,
		"@return",
		restoreBytes,
		{[[
			!jmp_dword ]], {afterInstruction, 4, 4},
		},
	}))
	
	EEex_WriteAssembly(address, EEex_ConcatTables({
		{
			"!jmp_dword", {hookCode, 4, 4}
		},
		nops,
	}))
end

function EEex_HookAfterRestore(address, restoreDelay, restoreSize, assembly)

	local storeBytes = function(startAddress, size)
		local bytes = {}
		local limit = startAddress + size - 1
		for i = startAddress, limit, 1 do
			table.insert(bytes, {EEex_ReadByte(i, 0), 1})
		end
		return bytes
	end

	local afterInstruction = address + restoreDelay + restoreSize
	local restoreBytes = storeBytes(address + restoreDelay, restoreSize)

	local nops = {}
	local limit = restoreDelay + restoreSize - 5
	for i = 1, limit, 1 do
		table.insert(nops, {0x90, 1})
	end

	local hookCode = EEex_WriteAssemblyAuto(EEex_ConcatTables({
		restoreBytes,
		assembly,
		{[[
			@return
			!jmp_dword ]], {afterInstruction, 4, 4},
		},
	}))

	EEex_WriteAssembly(address, EEex_ConcatTables({
		{
			"!jmp_dword", {hookCode, 4, 4}
		},
		nops,
	}))
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

	local vtbl = EEex_Malloc(0x2C, 45)
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
	local systemInfo = EEex_Malloc(0x24, 46)
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
	local temp = EEex_Malloc(0x4, 47)
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
	local temp = EEex_Malloc(0x4, 24)
	-- 0x20 = PAGE_EXECUTE_READ
	-- 0x401000 = Start of .text section in memory.
	-- 0x49F000 = Size of .text section in memory.
	EEex_DllCall("Kernel32", "VirtualProtect", {temp, 0x20, 0x49F000, 0x401000}, nil, 0x0)
	EEex_Free(temp)
end

----------
-- DIMM --
----------

-- Mirrors chExtToType, (chTypeToExt would be reverse)
function EEex_FileExtensionToType(extension)

	local extensions = {
		["2DA"]  = 0x3F4, -- CResText
		["ARE"]  = 0x3F2, -- CResArea
		["BAM"]  = 0x3E8, -- CResCell
		["BCS"]  = 0x3EF, -- CResText
		["BIO"]  = 0x3FE, -- CResBIO
		["BMP"]  = 0x1  , -- CResBitmap
		["BS"]   = 0x3F9, -- CResText
		["CHR"]  = 0x3FA, -- CResCHR
		["CHU"]  = 0x3EA, -- CResUI
		["CRE"]  = 0x3F1, -- CResCRE
		["DLG"]  = 0x3F3, -- CResDLG
		["EFF"]  = 0x3F8, -- CResEffect
		["GAM"]  = 0x3F5, -- CResGame
		["GLSL"] = 0x405, -- CResText
		["GUI"]  = 0x402, -- CResText
		["IDS"]  = 0x3F0, -- CResText
		["INI"]  = 0x802, -- CRes(???)
		["ITM"]  = 0x3ED, -- CResItem
		["LUA"]  = 0x409, -- CResText
		["MENU"] = 0x408, -- CResText
		["MOS"]  = 0x3EC, -- CResMosaic
		["MVE"]  = 0x2  , -- CRes(???)
		["PLT"]  = 0x6  , -- CResPLT
		["PNG"]  = 0x40B, -- CResPng
		["PRO"]  = 0x3FD, -- CResBinary
		["PVRZ"] = 0x404, -- CResPVR
		["SPL"]  = 0x3EE, -- CResSpell
		["SQL"]  = 0x403, -- CResText
		["STO"]  = 0x3F6, -- CResStore
		["TGA"]  = 0x3  , -- CRes(???)
		["TIS"]  = 0x3EB, -- CResTileSet
		["TOH"]  = 0x407, -- CRes(???)
		["TOT"]  = 0x406, -- CRes(???)
		["TTF"]  = 0x40A, -- CResFont
		["VEF"]  = 0x3FC, -- CResBinary
		["VVC"]  = 0x3FB, -- CResBinary
		["WAV"]  = 0x4  , -- CResWave
		["WBM"]  = 0x3FF, -- CResWebm
		["WED"]  = 0x3E9, -- CResWED
		["WFX"]  = 0x5  , -- CResBinary
		["WMP"]  = 0x3F7, -- CResWorldMap
	}

	return extensions[extension:upper()]

end

function EEex_DemandCRes(resref, extension)

	local resrefLocation = EEex_Malloc(0x8, 48)
	EEex_WriteLString(resrefLocation + 0x0, resref, 8)

	local type = EEex_FileExtensionToType(extension)
	local CRes = EEex_Call(EEex_Label("dimmGetResObject"), {0x0, type, resrefLocation}, nil, 0xC)
	EEex_Free(resrefLocation)

	if CRes ~= 0x0 then
		EEex_Call(EEex_Label("CRes::Demand"), {}, CRes, 0x0)
		return CRes
	else
		return 0x0
	end

end

function EEex_DemandResData(resref, extension)
	local CRes = EEex_DemandCRes(resref, extension)
	if CRes ~= 0x0 then
		return EEex_ReadDword(CRes + 0x28)
	else
		return 0x0
	end
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

-- Translates the given screenX and screenY into a worldX and worldY. Use EEex_GetTrueMousePos() to obtain valid screen coordinates.
function EEex_ScreenToWorldXY(screenX, screenY)
	local CInfinity = EEex_GetCurrentCInfinity()
	local screenXY = EEex_Malloc(0x8, 49)
	EEex_WriteDword(screenXY + 0x0, screenX)
	EEex_WriteDword(screenXY + 0x4, screenY)
	local viewportXY = EEex_Malloc(0x8, 50)
	EEex_Call(EEex_Label("CInfinity::ScreenToViewport"), {screenXY, viewportXY}, CInfinity, 0x0)
	EEex_Free(screenXY)
	local worldXY = EEex_Malloc(0x8, 51)
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
	local menuX, menuY, menuW, menuH = EEex_GetMenuArea(menuName)
	local itemX, itemY, itemWidth, itemHeight = Infinity_GetArea(menuItemName)
	return EEex_IsCursorWithin(menuX + itemX, menuY + itemY, itemWidth, itemHeight)
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
	local resrefAddress = EEex_Malloc(#resref + 1, 52)
	EEex_WriteString(resrefAddress, resref)
	local res = EEex_Malloc(0x38, 53)
	EEex_Call(EEex_Label("CRes::CRes"), {}, res, 0x0)
	EEex_WriteDword(res + 0x4, resrefAddress)
	EEex_WriteDword(res + 0x8, 0x408)
	local pointerToRes = EEex_Malloc(0x4, 54)
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

-- Loads in the given .MENU file as if it were UI.MENU. Note that in order to keep the menu loaded in the event of an F5 UI reload,
-- a post-reset listener must be used to reload the menu manually.
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
	local stringAddress = EEex_Malloc(#menuName + 0x1, 55)
	EEex_WriteString(stringAddress, menuName)
	local result = EEex_Call(EEex_Label("_findMenu"), {0x0, 0x0, stringAddress}, nil, 0xC)
	EEex_Free(stringAddress)
	return result
end

-- Returns the given menu's x, y, w, and h components - or nil if passed invalid menuName.
function EEex_GetMenuArea(menuName)

	local menuStruct = EEex_GetMenuStructure(menuName)
	if menuStruct == 0x0 then return end

	local screenW, screenH = Infinity_GetScreenSize()

	local ha = EEex_ReadDword(menuStruct + 0x3C)
	local va = EEex_ReadDword(menuStruct + 0x40)

	local w = EEex_ReadDword(menuStruct + 0x44)
	local h = EEex_ReadDword(menuStruct + 0x48)

	local returnX = 0
	local returnY = 0

	-- right
	if ha == 1 then
		returnX = screenW - w
	-- center
	elseif ha == 2 then
		-- The negative case is nonsensical, but that's how the assembly works.
		local windowW = screenW >= 0 and screenW or screenW + 1
		local menuW = w >= 0 and w or w + 1
		returnX = windowW / 2 - menuW / 2
	end

	-- bottom
	if va == 1 then
		returnY = screenH - h
	-- center
	elseif va == 2 then
		local windowH = screenH >= 0 and screenH or screenH + 1
		local menuH = h >= 0 and h or h + 1
		returnY = windowH / 2 - menuH / 2
	end

	local offsetX, offsetY = Infinity_GetOffset(menuName)
	return returnX + offsetX, returnY + offsetY, w, h

end

function EEex_GetMenuFunctionOffset(typeName)
	local typeOffsets = {
		["onopen"] = 0x2C,
		["onclose"] = 0x30,
		["enabled"] = 0x4C,
	}
	return typeOffsets[typeName:lower()]
end

-- Returns the internal compiled function derived from
-- the <typeName> function-string in the given menu.
function EEex_GetMenuVariantFunction(menuName, typeName)
	local menu = EEex_GetMenuStructure(menuName)
	if menu == 0x0 then return end
	local offset = EEex_GetMenuFunctionOffset(typeName)
	local registryIndex = EEex_ReadDword(menu + offset)
	return EEex_GetLuaRegistryIndex(registryIndex)
end

-- Overwrites the internal compiled function derived from
-- the <typeName> function-string in the given menu.
function EEex_SetMenuVariantFunction(menuName, typeName, myFunction)
	local menu = EEex_GetMenuStructure(menuName)
	if menu == 0x0 then return end
	local offset = EEex_GetMenuFunctionOffset(typeName)
	local registryIndex = EEex_ReadDword(menu + offset)
	EEex_SetMenuVariantFunctionTempGlobal = myFunction
	EEex_SetLuaRegistryFunction(registryIndex, "EEex_SetMenuVariantFunctionTempGlobal")
	EEex_SetMenuVariantFunctionTempGlobal = nil
end

function EEex_FindActionbarMenuItems(menuName)
	local actionbarItems = {}
	local menu = EEex_GetMenuStructure(menuName)
	if menu == 0x0 then return actionbarItems end
	local currentItem = EEex_ReadDword(menu + 0x1C)
	while currentItem ~= 0x0 do
		local actionbar = EEex_ReadDword(currentItem + 0x1AC)
		if actionbar ~= 0x0 then
			table.insert(actionbarItems, currentItem)
		end
		currentItem = EEex_ReadDword(currentItem + 0x22C)
	end
	return actionbarItems
end

function EEex_GetMenuItemFunctionOffset(typeName)
	local typeOffsets = {
		["enabled"] = 0x44,
		["action"] = 0x1E0,
	}
	return typeOffsets[typeName:lower()]
end

function EEex_GetMenuItemVariantFunction(menuItem, typeName)
	local offset = EEex_GetMenuItemFunctionOffset(typeName)
	local registryIndex = EEex_ReadDword(menuItem + offset)
	return EEex_GetLuaRegistryIndex(registryIndex)
end

function EEex_SetMenuItemVariantFunction(menuItem, typeName, myFunction)
	local offset = EEex_GetMenuItemFunctionOffset(typeName)
	local registryIndex = EEex_ReadDword(menuItem + offset)
	-- Please excuse the horrid word salad
	EEex_SetMenuItemVariantFunctionTempGlobal = myFunction
	EEex_SetLuaRegistryFunction(registryIndex, "EEex_SetMenuItemVariantFunctionTempGlobal")
	EEex_SetMenuItemVariantFunctionTempGlobal = nil
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

function EEex_StoreTemplateInstance(menuName, templateName, instanceID, storeIntoName)

	local stringAddress = EEex_Malloc(#templateName + 0x1, 56)
	EEex_WriteString(stringAddress, templateName)

	local eax = nil
	local ebx = nil
	local ecx = nil
	local esi = nil
	local edi = nil

	esi = EEex_GetMenuStructure(menuName)
	if esi == 0x0 then goto _fail end

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
	local resultBlock = EEex_Malloc(0x4, 57)
	EEex_Call(EEex_Label("CGameObjectArray::GetShare"), {resultBlock, actorID}, nil, 0x8)
	local result = EEex_ReadDword(resultBlock)
	EEex_Free(resultBlock)
	return result
end

-- Returns the actorID for the given share / creatureData.
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
		local objectType = EEex_ReadByte(share + 0x4, 0)
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

function EEex_FetchBCS(resref)
	local CAIScript = EEex_Malloc(0x24, 58)
	local CResRef = EEex_Malloc(0x8, 59)
	EEex_WriteLString(CResRef, resref, 8)
	local CAIScript = EEex_Call(EEex_Label("CAIScript::CAIScript"), {0, EEex_ReadDword(CResRef + 0x4), EEex_ReadDword(CResRef)}, CAIScript, 0x0)
	EEex_Free(CResRef)
	return CAIScript
end

function EEex_CompileBCS(scriptString)
	local CAIScriptFile = EEex_Malloc(0xE8, 60)
	EEex_Call(EEex_Label("CAIScriptFile::CAIScriptFile"), {}, CAIScriptFile, 0x0)
	local lines = EEex_SplitByChar(scriptString, "\n")
	for _, line in ipairs(lines) do
		local CString = EEex_Malloc(0x4, 61)
		local charArray = EEex_Malloc(#line + 1, 62)
		EEex_WriteString(charArray, line)
		EEex_Call(EEex_Label("CString::CString(char_const_*)"), {charArray}, CString, 0x0)
		EEex_Free(charArray)
		EEex_Call(EEex_Label("CAIScriptFile::ParseOneLine"), {EEex_ReadDword(CString)}, CAIScriptFile, 0x0)
		EEex_Free(CString)
	end
	local CAIScriptCopy = EEex_Malloc(0x24, 63)
	EEex_Call(EEex_Label("CAIScript::CAIScript(CAIScript_*)"), {}, CAIScriptCopy, 0x0)
	EEex_Call(EEex_Label("CAIScript::Copy"), {CAIScriptCopy + 0x8}, EEex_ReadDword(CAIScriptFile + 0x8), 0x0)
	EEex_Call(EEex_Label("CAIScriptFile::~CAIScriptFile"), {}, CAIScriptFile, 0x0)
	EEex_Free(CAIScriptFile)
	return CAIScriptCopy
end

function EEex_RunBCSAsActor(CAIScript, actorID)
	local share = EEex_GetActorShare(actorID)
	local pendingTriggers = share + 0x2A4
	local CAIResponse = EEex_Call(EEex_Label("CAIScript::Find"), {share, pendingTriggers}, CAIScript, 0x0)
	EEex_Call(EEex_Label("CGameAIBase::InsertResponse"), {1, 1, CAIResponse}, share, 0x0)
	EEex_Call(EEex_Label("CAIResponse::~CAIResponse"), {}, CAIResponse, 0x0)
	EEex_Free(CAIResponse)
end

function EEex_FreeBCS(CAIScript)
	EEex_Call(EEex_Label("CAIScript::~CAIScript"), {}, CAIScript, 0x0)
	EEex_Free(CAIScript)
end

-----------------------
--  Object Compiler  --
-----------------------

-- TODO: Memory leak?
-- Parses the given object string in standard BAF syntax and returns a pointer to the compiled CAIObjectType instance.
-- Use EEex_EvalObjectAsActor() to evaluate the compiled object instance in relation to an actor.
function EEex_ParseObjectString(string)
	local scriptFile = EEex_Malloc(0xE8, 64)
	EEex_Call(EEex_Label("CAIScriptFile::CAIScriptFile"), {}, scriptFile, 0x0)
	local objectString = EEex_ConstructCString(string)
	local objectTypeResult = EEex_Malloc(0x14, 65)
	EEex_Call(EEex_Label("CAIScriptFile::ParseObjectType"), {objectString, objectTypeResult}, scriptFile, 0x0)
	EEex_Call(EEex_Label("CAIScriptFile::~CAIScriptFile"), {}, scriptFile, 0x0)
	EEex_Call(EEex_Label("CString::~CString"), {}, objectString, 0x0)
	return objectTypeResult
end

-- Evaluates an object pointer, (returned by EEex_ParseObjectString()), as if it was evaluated by the given actor.
function EEex_EvalObjectAsActor(object, actorID)
	local objectCopy = EEex_Malloc(0x14, 66)
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

-- Evalues an object string in standard BAF syntax as if it was evaluated by the given actor.
function EEex_EvalObjectStringAsActor(string, actorID)
	local object = EEex_ParseObjectString(string)
	local matchedID = EEex_EvalObjectAsActor(object, actorID)
	EEex_Call(EEex_Label("CString::~CString"), {}, object, 0x0)
	EEex_Free(object)
	return matchedID
end

-----------------------
--  Action Compiler  --
-----------------------

-- Parses the given string as if it was fed through C:Eval() and
-- returns the compiled script object, (only filled with actions).
-- Use in conjunction with one of the EEex_EvalActions* functions.
function EEex_ParseActionsString(string)

	local CAIScriptFile = EEex_Malloc(0xE8, 67)
	EEex_Call(EEex_Label("CAIScriptFile::CAIScriptFile"), {}, CAIScriptFile, 0x0)

	local CString = EEex_Malloc(0x4, 68)
	local charArray = EEex_Malloc(#string + 1, 69)
	EEex_WriteString(charArray, string)
	EEex_Call(EEex_Label("CString::CString(char_const_*)"), {charArray}, CString, 0x0)
	EEex_Free(charArray)

	-- Destructs CString internally
	EEex_Call(EEex_Label("CAIScriptFile::ParseResponseString"), {EEex_ReadDword(CString)}, CAIScriptFile, 0x0)
	EEex_Free(CString)

	return CAIScriptFile

end

-- Executes compiled actions returned by EEex_ParseActionsString().
-- Note that due to intentional design, the following function attempts to
-- resume the currently executing action after forcing the passed actions.
-- *** ONLY WORKS CORRECTLY FOR ACTIONS DEFINED IN INSTANT.IDS ***
function EEex_EvalActionsAsActorResume(CAIScriptFile, actorID)

	local share = EEex_GetActorShare(actorID)
	local CAIResponse = EEex_ReadDword(CAIScriptFile + 0x14)
	local actionList = CAIResponse + 0x8

	-- Copy currently executing action
	local currentCopy = EEex_Malloc(0x64, 70)
	EEex_Call(EEex_Label("CAIAction::CAIAction(CAIAction_const_&)"), {share + 0x2F8}, currentCopy, 0x0)

	EEex_IterateCPtrList(actionList, function(CAIAction)

		-- Override current action with parsed CAIAction
		EEex_Call(EEex_Label("CAIAction::operator_equ"), {CAIAction}, share + 0x2F8, 0x0)

		-- Execute inserted action
		EEex_Call(EEex_Label("CGameSprite::ExecuteAction"), {}, share, 0x0)

	end)

	-- Restore overridden action
	EEex_Call(EEex_Label("CAIAction::operator_equ"), {currentCopy}, share + 0x2F8, 0x0)

	-- Clean up copied action
	EEex_Call(EEex_Label("CAIAction::~CAIAction"), {}, currentCopy, 0x0)

	-- Free copy memory
	EEex_Free(currentCopy)

end

-- Same as EEex_EvalActionsAsActorResume(), though intead of
-- passing a compiled script object, this function compiles
-- the script from the given string and frees the resulting
-- script object for you. Use this function sparingly, as
-- compiling scripts takes a good amount of time.
function EEex_EvalActionsStringAsActorResume(string, actorID)
	local CAIScriptFile = EEex_ParseActionsString(string)
	EEex_EvalActionsAsActorResume(CAIScriptFile, actorID)
	EEex_FreeActions(CAIScriptFile)
end

-- Executes compiled actions returned by EEex_ParseActionsString().
-- Results practically identical to using C:Eval(), though note that executing
-- compiled actions is significantly faster than parsing the actions string
-- every call.
function EEex_EvalActionsAsActor(CAIScriptFile, actorID)
	local share = EEex_GetActorShare(actorID)
	local CAIResponse = EEex_ReadDword(CAIScriptFile + 0x14)
	local actionList = CAIResponse + 0x8
	EEex_IterateCPtrList(actionList, function(CAIAction)
		EEex_Call(EEex_Label("CGameAIBase::InsertAction"), {CAIAction}, share, 0x0)
	end)
end

-- Same as EEex_EvalActionsAsActor(), though intead of
-- passing a compiled script object, this function compiles
-- the script from the given string and frees the resulting
-- script object for you. Use this function sparingly, as
-- compiling scripts takes a good amount of time.
function EEex_EvalActionsStringAsActor(string, actorID)
	local CAIScriptFile = EEex_ParseActionsString(string)
	EEex_EvalActionsAsActor(CAIScriptFile, actorID)
	EEex_FreeActions(CAIScriptFile)
end

-- Frees the compiled scripts returned by EEex_ParseActionsString().
-- Ensure that the freed actions are never used again, as attempting
-- to reference freed actions will result in a crash.
function EEex_FreeActions(CAIScriptFile)
	EEex_Call(EEex_Label("CAIScriptFile::~CAIScriptFile"), {}, CAIScriptFile, 0x0)
	EEex_Free(CAIScriptFile)
end

------------------------
--  Trigger Compiler  --
------------------------

function EEex_ParseTriggersString(string)

	local CAIScriptFile = EEex_Malloc(0xE8, 71)
	EEex_Call(EEex_Label("CAIScriptFile::CAIScriptFile"), {}, CAIScriptFile, 0x0)

	local CString = EEex_Malloc(0x4, 72)
	local charArray = EEex_Malloc(#string + 1, 73)
	EEex_WriteString(charArray, string)
	EEex_Call(EEex_Label("CString::CString(char_const_*)"), {charArray}, CString, 0x0)
	EEex_Free(charArray)

	-- Destructs CString internally
	EEex_Call(EEex_Label("CAIScriptFile::ParseConditionalString"), {EEex_ReadDword(CString)}, CAIScriptFile, 0x0)
	EEex_Free(CString)

	return CAIScriptFile

end

function EEex_EvalTriggersAsActor(CAIScriptFile, actorID)
	local share = EEex_GetActorShare(actorID)
	local pendingTriggers = share + 0x2A4
	local CAICondition = EEex_ReadDword(CAIScriptFile + 0x10)
	return EEex_Call(EEex_Label("CAICondition::Hold"), {share, pendingTriggers}, CAICondition, 0x0) == 1
end

function EEex_EvalTriggersStringAsActor(string, actorID)
	local CAIScriptFile = EEex_ParseTriggersString(string)
	local toReturn = EEex_EvalTriggersAsActor(CAIScriptFile, actorID)
	EEex_FreeTriggers(CAIScriptFile)
	return toReturn
end

function EEex_FreeTriggers(CAIScriptFile)
	EEex_Call(EEex_Label("CAIScriptFile::~CAIScriptFile"), {}, CAIScriptFile, 0x0)
	EEex_Free(CAIScriptFile)
end

------------------------------
--  Actionbar Manipulation  --
------------------------------

--[[
Unique Config | State(s)
    [0]       |  = 1,   -- Mage / Sorcerer
    [1]       |  = 2,   -- Fighter
    [2]       |  = 3,   -- Cleric
    [3]       |  = 4,   -- Thief
    [4]       |  = 5,   -- Bard
    [5]       |  = 6,   -- Paladin
    [6]       |  = 7,   -- Fighter Mage
    [7]       |  = 8,   -- Fighter Cleric
    [8]       |  = 9,   -- Fighter Thief
    [9]       |  = 10,  -- Fighter Mage Thief
    [10]      |  = 11,  -- Druid
    [11]      |  = 12,  -- Ranger
    [12]      |  = 13,  -- Mage Thief
    [13]      |  = 14,  -- Cleric Mage
    [14]      |  = 15,  -- Cleric Thief
    [15]      |  = 16,  -- Fighter Druid
    [16]      |  = 17,  -- Fighter Mage Cleric
    [17]      |  = 18,  -- Cleric Ranger
    [18]      |  = 20,  -- Monk
    [19]      |  = 21,  -- Shaman
    [20]      |  = 101, -- Select Weapon Ability
              |
    [21]      |  = 102, -- Spells (Select Quick Spell)
              |    103, -- Spells (Cast)
              |
    [22]      |  = 104, -- Select Quick Item Ability
              |    105, -- Use Item
              |
    [23]      |  = 106, -- Special Abilities
    [24]      |  = 107, -- Select Quick Formation
    [25]      |  = 108, -- Defunct Select Quick Formation (Not used)
    [26]      |  = 109, -- Group Selected
    [27]      |  = 110, -- Unknown (No buttons defined; not used?)
    [28]      |  = 111, -- Internal List (Opcode #214)
    [29]      |  = 112, -- Controlled (Class doesn't have a dedicated state)
              |
    [30]      |  = 113, -- Cleric / Mage Spells (Cast)
              |    114, -- Cleric / Mage Spells (Select Quick Spell)
              |
--]]

function EEex_SetActionbarState(state)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_cButtonArray = m_pObjectGame + 0x2654
	EEex_Call(EEex_Label("CInfButtonArray::SetState"), {state}, m_cButtonArray, 0x0)
end

function EEex_GetActionbarState()
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_cButtonArray = m_pObjectGame + 0x2654
	return EEex_ReadDword(m_cButtonArray + 0x1474)
end

function EEex_GetLastActionbarState()
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_cButtonArray = m_pObjectGame + 0x2654
	return EEex_ReadDword(m_cButtonArray + 0x1478)
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
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_cButtonArray = m_pObjectGame + 0x2654
	local m_cButton = m_cButtonArray + 0x1440 + buttonIndex * 0x4 -- (dword)
	EEex_WriteDword(m_cButton, buttonType)
end

function EEex_GetActionbarButton(buttonIndex)
	if buttonIndex < 0 or buttonIndex > 11 then
		EEex_Error("buttonIndex out of bounds")
	end
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_cButtonArray = m_pObjectGame + 0x2654
	return EEex_ReadDword(m_cButtonArray + 0x1440 + buttonIndex * 0x4)
end

-- Returns true if the actionbar button at buttonIndex is currently in the process of being clicked.
function EEex_IsActionbarButtonDown(buttonIndex)
	local capture = EEex_ReadDword(EEex_Label("capture") + 0xC)
	if capture == 0x0 then return false end
	local actionbar = EEex_ReadDword(capture + 0x1AC)
	if actionbar == 0x0 then return false end
	return EEex_ReadDword(actionbar + 0x4) == buttonIndex
end

-- Returns the current frame of the actionbar button at buttonIndex, taking into account the click status.
function EEex_GetActionbarButtonFrame(buttonIndex)
	local frame = buttonArray:GetButtonSequence(buttonIndex)
	if EEex_IsActionbarButtonDown(buttonIndex) then frame = frame + 1 end
	return frame
end

-- Forces the actionbar to refresh its state. Use if making changes with EEex_SetActionbarButton() outside of an actionbar listener.
function EEex_UpdateActionbar()
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_cButtonArray = m_pObjectGame + 0x2654
	EEex_Call(EEex_Label("CInfButtonArray::UpdateState"), {}, m_cButtonArray, 0x0)
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
	local CRes = EEex_DemandCRes(resref, "SPL")
	if CRes ~= 0x0 then
		return EEex_ReadDword(CRes + 0x40)
	else
		return 0x0
	end
end

function EEex_IsSpellValid(resrefLocation)
	local eax = EEex_GetSpellData(EEex_ReadLString(resrefLocation, 8))
	return eax ~= 0x0
end

function EEex_GetSpellDescription(resrefLocation)
	local eax = EEex_GetSpellData(EEex_ReadLString(resrefLocation, 8))
	return Infinity_FetchString(EEex_ReadDword(eax + 0x50))
end

function EEex_GetSpellIcon(resrefLocation)
	local eax = EEex_GetSpellData(EEex_ReadLString(resrefLocation, 8))
	return EEex_ReadString(eax + 0x3A)
end

function EEex_GetSpellName(resrefLocation)
	local step1 = EEex_GetSpellData(EEex_ReadLString(resrefLocation, 8))
	if step1 ~= 0x0 then
		return Infinity_FetchString(EEex_ReadDword(step1 + 0x8))
	else
		return ""
	end
end

function EEex_ProcessKnownClericSpells(actorID, func)
	if not EEex_IsSprite(actorID, true) then return end
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
	if not EEex_IsSprite(actorID, true) then return end
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
	if not EEex_IsSprite(actorID, true) then return end
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
	if not EEex_IsSprite(actorID, true) then return end
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
	if not EEex_IsSprite(actorID, true) then return end
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
	if not EEex_IsSprite(actorID, true) then return end
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
	if not EEex_IsSprite(actorID, true) then return toReturn end
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
	if not EEex_IsSprite(actorID, true) then return toReturn end
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
	if not EEex_IsSprite(actorID, true) then return toReturn end
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
	if not EEex_IsSprite(actorID, true) then return toReturn end
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
	if not EEex_IsSprite(actorID, true) then return toReturn end
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
	if not EEex_IsSprite(actorID, true) then return toReturn end
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

-------------------------
-- Player Spell System --
-------------------------

function EEex_ReadySpell(m_CGameSprite, m_CButtonData, instantUse, offInternal)

	local stackArgs = {}
	table.insert(stackArgs, instantUse) -- 0 = Cast, 1 = Choose (for quickslot type things)
	for i = 0x30, 0x0, -0x4 do
		table.insert(stackArgs, EEex_ReadDword(m_CButtonData + i))
	end

	if not offInternal then
		EEex_Call(EEex_Label("CGameSprite::ReadySpell"), stackArgs, m_CGameSprite, 0x0)
	else
		EEex_Call(EEex_Label("CGameSprite::ReadyOffInternalList"), stackArgs, m_CGameSprite, 0x0)
	end
end

function EEex_UseCGameButtonList(m_CGameSprite, m_CGameButtonList, resref, action)

	local found = false
	EEex_IterateCPtrList(m_CGameButtonList, function(m_CButtonData)

		-- m_CButtonData.m_abilityId.m_res
		local m_res = EEex_ReadLString(m_CButtonData + 0x22, 0x8)

		if m_res == resref then

			action(m_CButtonData)

			found = true
			return true -- breaks out of EEex_IterateCPtrList()
		end
	end)

	EEex_FreeCPtrList(m_CGameButtonList)
	return found
end

function EEex_GetQuickButtons(m_CGameSprite, buttonType, existenceCheck)
	return EEex_Call(EEex_Label("CGameSprite::GetQuickButtons"), {existenceCheck, buttonType}, m_CGameSprite, 0x0)
end

function EEex_GetSpellAbilityDataIndex(resref, index)

	local CResSpell = EEex_DemandCRes(resref, "SPL")
	if CResSpell == 0x0 then return 0x0 end
	local spellData = EEex_ReadDword(CResSpell + 0x28)

	local abilitiesCount = EEex_ReadWord(spellData + 0x68, 0)
	if abilitiesCount == 0 then return 0x0 end

	local startAbilityAddress = spellData + EEex_ReadDword(spellData + 0x64)
	return startAbilityAddress + 0x28 * index
end

function EEex_GetSpellAbilityDataLevel(resref, casterLevel)

	local CResSpell = EEex_DemandCRes(resref, "SPL")
	if CResSpell == 0x0 then return 0x0 end
	local spellData = EEex_ReadDword(CResSpell + 0x28)

	local abilitiesCount = EEex_ReadWord(spellData + 0x68, 0)
	if abilitiesCount == 0 then return 0x0 end
	local currentAbilityAddress = spellData + EEex_ReadDword(spellData + 0x64)

	local foundAbilityOffset = nil
	for i = 1, abilitiesCount, 1 do
		local minLevel = EEex_ReadWord(currentAbilityAddress + 0x10, 0)
		if casterLevel >= minLevel then
			foundAbilityOffset = currentAbilityAddress
		else
			break
		end
		currentAbilityAddress = currentAbilityAddress + 0x28
	end
	return foundAbilityOffset or 0x0
end

function EEex_GetSpellAbilityData(m_CGameSprite, resref)

	local CResSpell = EEex_DemandCRes(resref, "SPL")
	if CResSpell == 0x0 then return 0x0 end
	local spellData = EEex_ReadDword(CResSpell + 0x28)

	local CSpell = EEex_Malloc(0xC, 74)
	EEex_WriteDword(CSpell, CResSpell)
	EEex_WriteLString(CSpell + 0x4, resref, 0x8)

	local abilitiesCount = EEex_ReadWord(spellData + 0x68, 0)
	if abilitiesCount == 0 then return 0x0 end
	local currentAbilityAddress = spellData + EEex_ReadDword(spellData + 0x64)

	local casterLevel = EEex_Call(EEex_Label("CGameSprite::GetCasterLevel"), {1, CSpell}, m_CGameSprite, 0x0)
	EEex_Free(CSpell)

	local foundAbilityOffset = nil
	for i = 1, abilitiesCount, 1 do
		local minLevel = EEex_ReadWord(currentAbilityAddress + 0x10, 0)
		if casterLevel >= minLevel then
			foundAbilityOffset = currentAbilityAddress
		else
			break
		end
		currentAbilityAddress = currentAbilityAddress + 0x28
	end
	return foundAbilityOffset or 0x0
end

-- Player must be in a quick spell select and spell must be memorized + currently accessible
function EEex_PlayerSetQuickSpellResref(resref)

	if worldScreen ~= e:GetActiveEngine() then return end

	local actorID = EEex_GetActorIDSelected()
	if not EEex_IsSprite(actorID) then return end
	local m_CGameSprite = EEex_GetActorShare(actorID)

	local m_CGameButtonList = EEex_GetQuickButtons(m_CGameSprite, 2, 0)
	EEex_UseCGameButtonList(m_CGameSprite, m_CGameButtonList, resref, function(m_CButtonData)
		local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
		local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
		local m_cButtonArray = m_pObjectGame + 0x2654
		local m_quickButtonToConfigure = EEex_ReadDword(m_cButtonArray + 0x1600)
		EEex_Call(EEex_Label("CInfButtonArray::SetQuickSlot"), {2, m_quickButtonToConfigure, m_CButtonData}, nil, 0xC)
		EEex_ReadySpell(m_CGameSprite, m_CButtonData, 1, false)
		EEex_SetActionbarState(EEex_GetLastActionbarState())
	end)
end

-- Spell must be memorized and currently accessible
function EEex_PlayerCastResref(resref)

	if worldScreen ~= e:GetActiveEngine() then return end

	local actorID = EEex_GetActorIDSelected()
	if not EEex_IsSprite(actorID) then return end
	local m_CGameSprite = EEex_GetActorShare(actorID)

	local spellAbilityData = EEex_GetSpellAbilityData(m_CGameSprite, resref)
	if spellAbilityData == 0x0 then return end
	local spellLocation = EEex_ReadWord(spellAbilityData + 0x2, 0)

	local spellButtonDataList = EEex_GetQuickButtons(m_CGameSprite, spellLocation, 0)
	EEex_UseCGameButtonList(m_CGameSprite, spellButtonDataList, resref, function(m_CButtonData)
		EEex_ReadySpell(m_CGameSprite, m_CButtonData, 0, false)
		EEex_SetActionbarState(EEex_GetLastActionbarState())
	end)
end

-- Opcode #214 must be active and the resref must be part of the Opcode #214 spell list
function EEex_PlayerCastResrefInternal(resref)

	if worldScreen ~= e:GetActiveEngine() then return end

	local actorID = EEex_GetActorIDSelected()
	if not EEex_IsSprite(actorID) then return end
	local m_CGameSprite = EEex_GetActorShare(actorID)

	local spellButtonDataList = EEex_Call(EEex_Label("CGameSprite::GetInternalButtonList"), {}, m_CGameSprite, 0x0)
	EEex_UseCGameButtonList(m_CGameSprite, spellButtonDataList, resref, function(m_CButtonData)
		EEex_ReadySpell(m_CGameSprite, m_CButtonData, 0, true)
		EEex_SetActionbarState(EEex_GetLastActionbarState())
	end)
end

-- No requirements
function EEex_PlayerCastResrefNoDec(resref)

	if worldScreen ~= e:GetActiveEngine() then return end

	local actorID = EEex_GetActorIDSelected()
	if not EEex_IsSprite(actorID) then return end
	local share = EEex_GetActorShare(actorID)

	local spellAbilityData = EEex_GetSpellAbilityData(share, resref)
	if spellAbilityData == 0x0 then return end

	local CButtonData = EEex_Malloc(0x34, 75)
	EEex_Call(EEex_Label("CButtonData::CButtonData"), {}, CButtonData, 0x0)
	local targetType = EEex_ReadByte(spellAbilityData + 0xC, 0)
	-- m_itemType = 6 is an EEex addition that bypasses all casting prerequisites
	EEex_WriteWord(CButtonData + 0x1C, targetType ~= 0x7 and 0x6 or 0x5) -- m_itemType
	EEex_WriteLString(CButtonData + 0x22, resref, 0x8) -- m_res
	EEex_WriteByte(CButtonData + 0x2A, targetType) -- m_targetType
	EEex_WriteByte(CButtonData + 0x2B, EEex_ReadByte(spellAbilityData + 0xD, 0)) -- m_targetCount

	EEex_ReadySpell(share, CButtonData, 0, true)
	EEex_Free(CButtonData)
	EEex_SetActionbarState(EEex_GetLastActionbarState())
end

----------------
-- Game State --
----------------

function EEex_GetGameTick()
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_gameTime = EEex_ReadDword(m_pObjectGame + 0x2500)
	return m_gameTime
end

function EEex_AddMessage(CMessage, bForcePassThrough)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin")) -- (CBaldurChitin)
	local m_cMessageHandler = g_pBaldurChitin + EEex_Label("CBaldurChitin::m_cMessageHandler")
	-- bForcePassThrough, message
	EEex_Call(EEex_Label("CMessageHandler::AddMessage"), {bForcePassThrough and 1 or 0, CMessage}, m_cMessageHandler, 0x0)
end

-- Attaches a LOCALS storage opcode for the given variable.
function EEex_ForceLocalVariableMarshal(actorID, variableName)

	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return end
	local localVariables = EEex_ReadDword(share + 0x3758)

	local CVariable = EEex_FetchCVariable(localVariables, variableName)
	local stringLength = #EEex_ReadLString(CVariable + 0x34, 32)

	EEex_ApplyEffectToActor(actorID, {
		["opcode"] = 187,
		["source_id"] = actorID,
		["source_x"] = EEex_ReadDword(share + 0x8),
		["source_y"] = EEex_ReadDword(share + 0xC),
		["effvar"] = variableName,
		["resist_dispel"] = EEex_ReadWord(CVariable + 0x20, 0),
		["parameter3"] = EEex_ReadWord(CVariable + 0x22, 0),
		["parameter2"] = EEex_ReadDword(CVariable + 0x24),
		["parameter1"] = EEex_ReadDword(CVariable + 0x28),
		["parameter4"] = EEex_FloatToLong(CVariable + 0x2C),
		["timing"] = 9,
		["savingthrow"] = 0x10000,
		["resource"] = EEex_ReadLString(CVariable + 0x34, 8),
		["special"] = 1,
		["vvcresource"] = stringLength > 8 and EEex_ReadLString(CVariable + 0x3C, 8) or "",
		["resource2"] = stringLength > 16 and EEex_ReadLString(CVariable + 0x44, 8) or "",
		["immediateResolve"] = 0,
	})

end

-- Fetches the CVariable corresponding to variableName.
function EEex_FetchCVariable(CVariableHash, variableName)
	local localAddress = EEex_Malloc(#variableName + 5, 76)
	EEex_WriteString(localAddress + 0x4, variableName)
	EEex_Call(EEex_Label("CString::CString(char_const_*)"), {localAddress + 0x4}, localAddress, 0x0)
	local varAddress = EEex_Call(EEex_Label("CVariableHash::FindKey"), {EEex_ReadDword(localAddress)}, CVariableHash, 0x0)
	EEex_Free(localAddress)
	return varAddress
end

-- Fetches the numeric value corresponding to variableName.
function EEex_FetchVariable(CVariableHash, variableName)
	local varAddress = EEex_FetchCVariable(CVariableHash, variableName)
	if varAddress ~= 0x0 then
		return EEex_ReadDword(varAddress + 0x28)
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

-- TODO: Memory leak?
function EEex_GetAreaGlobal(areaResref, globalName)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local areaResrefAddress = EEex_Malloc(#globalName + 5, 77)
	EEex_WriteString(areaResrefAddress + 0x4, areaResref)
	EEex_Call(EEex_Label("CString::CString(char_const_*)"), {areaResrefAddress + 0x4}, areaResrefAddress, 0x0)
	local areaAddress = EEex_Call(EEex_Label("CInfGame::GetArea"), {EEex_ReadDword(areaResrefAddress)}, m_pObjectGame, 0x0)
	if areaAddress ~= 0x0 then
		local areaVariables = areaAddress + 0xA8C
		return EEex_FetchVariable(areaVariables, globalName)
	else
		return 0x0
	end
end

function EEex_SetVariable(CVariableHash, variableName, value)
	local variableNamePtr = EEex_ConstructCString(variableName)
	local variableNameLookupPtr = EEex_CopyCString(variableNamePtr)
	local variableNameLookupAddress = EEex_ReadDword(variableNameLookupPtr)
	local existingVarAddress = EEex_Call(EEex_Label("CVariableHash::FindKey"), {variableNameLookupAddress}, CVariableHash, 0x0)
	EEex_Free(variableNameLookupPtr)
	if existingVarAddress ~= 0x0 then
		EEex_WriteDword(existingVarAddress + 0x28, value)
	else
		local newVarAddress = EEex_Malloc(0x54, 78)
		EEex_Call(EEex_Label("CVariable::CVariable"), {}, newVarAddress, 0x0)
		local variableNameAddress = EEex_ReadDword(variableNamePtr)
		EEex_Call(EEex_Label("_strncpy"), {0x20, variableNameAddress, newVarAddress}, nil, 0xC)
		EEex_WriteDword(newVarAddress + 0x28, value)
		EEex_Call(EEex_Label("CVariableHash::AddKey"), {newVarAddress}, CVariableHash, 0x0)
		EEex_Free(newVarAddress)
	end
	EEex_FreeCString(variableNamePtr)
end

-- Demands a CVariable under the given variableName exists in the CVariableHash.
-- If the variable isn't already in the CVariablehash, it is created / added.
-- Returns the CVariable corresponding to variableName.
function EEex_DemandCVariable(CVariableHash, variableName)

	local existingVarAddress = EEex_FetchCVariable(CVariableHash, variableName)
	if existingVarAddress == 0x0 then

		local newVarAddress = EEex_Malloc(0x54, 79)
		EEex_Call(EEex_Label("CVariable::CVariable"), {}, newVarAddress, 0x0)
		EEex_WriteLString(newVarAddress, variableName, 32)
		EEex_Call(EEex_Label("CVariableHash::AddKey"), {newVarAddress}, CVariableHash, 0x0)
		EEex_Free(newVarAddress)

		return EEex_FetchCVariable(CVariableHash, variableName)
	else
		return existingVarAddress
	end
end

-- Sets a "GLOBAL" variable in the .GAM as if a
-- 	SetGlobal(<globalName>, "GLOBAL", <value>)
-- script action was executed.
function EEex_SetGlobal(globalName, value)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local m_variables = m_pObjectGame + 0x5BC8
	return EEex_SetVariable(m_variables, globalName, value)
end

-- TODO: Memory leak?
-- Sets an <arearesref> variable in an .ARE as if a
-- 	SetGlobal(<globalName>, <areaResref>, <value>)
-- script action was executed.
function EEex_SetAreaGlobal(areaResref, globalName, value)
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin"))
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame"))
	local areaResrefAddress = EEex_Malloc(#globalName + 5, 80)
	EEex_WriteString(areaResrefAddress + 0x4, areaResref)
	EEex_Call(EEex_Label("CString::CString(char_const_*)"), {areaResrefAddress + 0x4}, areaResrefAddress, 0x0)
	local areaAddress = EEex_Call(EEex_Label("CInfGame::GetArea"), {EEex_ReadDword(areaResrefAddress)}, m_pObjectGame, 0x0)
	if areaAddress ~= 0x0 then
		local areaVariables = areaAddress + 0xA8C
		EEex_SetVariable(areaVariables, globalName, value)
	end
end

function EEex_2DALoad(_2DAResref)
	local resrefAddress = EEex_Malloc(#_2DAResref + 1, 81)
	EEex_WriteString(resrefAddress, _2DAResref)
	local C2DArray = EEex_Malloc(0x20, 82)
	EEex_Memset(C2DArray, 0x20, 0x0)
	EEex_WriteDword(C2DArray + 0x18, EEex_Label("_afxPchNil"))
	EEex_Call(EEex_Label("C2DArray::Load"), {resrefAddress}, C2DArray, 0x0)
	EEex_Free(resrefAddress)
	return C2DArray
end

-- TODO: Memory leak?
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
	local result = EEex_Malloc(0x4, 83)
	-- TODO: Use Pattern
	EEex_Call(0x5F7A60, {kit, class, result}, m_pObjectGame, 0x0)
	local luaString = EEex_ReadString(EEex_ReadDword(result))
	EEex_Call(EEex_Label("CString::~CString"), {}, result, 0x0)
	return luaString
end

---------------------
--  Actor Details  --
---------------------

function EEex_IsTrapFlaggedNondetectable(objectID)

	local share = EEex_GetActorShare(objectID)
	local m_objectType = EEex_ReadByte(share + 0x4, 0)

	if m_objectType == 0x21 then -- CGameDoor
		return bit32.band(EEex_ReadDword(share + 0x428), 0x8) == 0
	elseif m_objectType == 0x41 then -- CGameTrigger
		return bit32.band(EEex_ReadDword(share + 0x43C), 0x8) == 0
	end
	return false
end

function EEex_IsTrapActive(objectID)

	local share = EEex_GetActorShare(objectID)
	local m_objectType = EEex_ReadByte(share + 0x4, 0)

	if m_objectType == 0x21 then -- CGameDoor
		return EEex_ReadWord(share + 0x4D4, 0) == 1
	elseif m_objectType == 0x41 then -- CGameTrigger
		return EEex_ReadWord(share + 0x478, 0) == 1
	elseif m_objectType == 0x11 then -- CGameContainer
		return EEex_ReadWord(share + 0x690, 0) == 1
	end
	return false
end

function EEex_IsTrapDetected(objectID)

	local share = EEex_GetActorShare(objectID)
	local m_objectType = EEex_ReadByte(share + 0x4, 0)

	if m_objectType == 0x21 then -- CGameDoor
		return EEex_ReadWord(share + 0x4D6, 0) == 1
	elseif m_objectType == 0x41 then -- CGameTrigger
		return EEex_ReadWord(share + 0x47A, 0) == 1
	elseif m_objectType == 0x11 then -- CGameContainer
		return EEex_ReadWord(share + 0x692, 0) == 1
	end
	return false
end

function EEex_GetTrapDetectDifficulty(objectID)

	local share = EEex_GetActorShare(objectID)
	local m_objectType = EEex_ReadByte(share + 0x4, 0)

	if m_objectType == 0x21 then -- CGameDoor
		return EEex_ReadWord(share + 0x4D0, 0)
	elseif m_objectType == 0x41 then -- CGameTrigger
		return EEex_ReadWord(share + 0x474, 0)
	elseif m_objectType == 0x11 then -- CGameContainer
		return EEex_ReadWord(share + 0x68C, 0)
	end
	return -1
end

function EEex_GetTrapDisarmDifficulty(objectID)

	local share = EEex_GetActorShare(objectID)
	local m_objectType = EEex_ReadByte(share + 0x4, 0)

	if m_objectType == 0x21 then -- CGameDoor
		return EEex_ReadWord(share + 0x4D2, 0)
	elseif m_objectType == 0x41 then -- CGameTrigger
		return EEex_ReadWord(share + 0x476, 0)
	elseif m_objectType == 0x11 then -- CGameContainer
		return EEex_ReadWord(share + 0x68E, 0)
	end
	return -1
end

function EEex_DisarmTrap(objectID)

	local share = EEex_GetActorShare(objectID)
	local m_objectType = EEex_ReadByte(share + 0x4, 0)

	local sendCMessageSetForceActionPick = function()

		local CMessageSetForceActionPick = EEex_Malloc(0x10)
		EEex_WriteDword(CMessageSetForceActionPick, EEex_Label("CMessageSetForceActionPick_VFTable")) -- vfptr
		EEex_WriteDword(CMessageSetForceActionPick + 0x4, objectID) -- m_targetId
		EEex_WriteDword(CMessageSetForceActionPick + 0x8, -1) -- m_sourceId

		-- Not sure why the following is called "m_bOpenDoor", it actually passes 
		-- its value along to the target CGameAIBase's "m_forceActionPick"
		EEex_WriteByte(CMessageSetForceActionPick + 0xC, 1) -- m_bOpenDoor

		EEex_AddMessage(CMessageSetForceActionPick)
	end

	local sendCMessageSetTrigger = function()
		local CAITrigger = EEex_Malloc(0x30)
		EEex_Call(EEex_Label("CAITrigger::CAITrigger"), {0, 0x56}, CAITrigger, 0x0) -- CAITrigger::DISARMED
		local CMessageSetTrigger = EEex_Malloc(0x3C)
		EEex_Call(EEex_Label("CMessageSetTrigger::CMessageSetTrigger"), {objectID, -1, CAITrigger}, CMessageSetTrigger, 0x0)
		EEex_AddMessage(CMessageSetTrigger)
	end

	-- CGameDoor
	if m_objectType == 0x21 then

		sendCMessageSetForceActionPick()

		local m_trapActivated = EEex_ReadWord(share + 0x4D4, 0) == 1
		if not m_trapActivated then return end

		sendCMessageSetTrigger()

		EEex_WriteWord(share + 0x4D4, 0) -- m_trapActivated
		EEex_Call(EEex_Label("CGameDoor::SetDrawPoly"), {0}, share, 0x0)

		local CMessageDoorStatus = EEex_Malloc(0x18)
		EEex_Call(EEex_Label("CMessageDoorStatus::CMessageDoorStatus"), {objectID, -1, share}, CMessageDoorStatus, 0x0)
		EEex_AddMessage(CMessageDoorStatus)

	-- CGameTrigger
	elseif m_objectType == 0x41 then

		sendCMessageSetForceActionPick()

		local m_trapActivated = EEex_ReadWord(share + 0x478, 0) == 1
		if not m_trapActivated then return end

		local m_dwFlags = EEex_ReadDword(share + 0x43C)
		if bit32.band(m_dwFlags, 0x900) ~= 0x0 then return end

		sendCMessageSetTrigger()

		EEex_WriteWord(share + 0x478, 0) -- m_trapActivated
		EEex_Call(EEex_Label("CGameTrigger::SetDrawPoly"), {0}, share, 0x0)

		local CMessageTriggerStatus = EEex_Malloc(0x14)
		EEex_WriteDword(CMessageTriggerStatus, EEex_Label("CMessageTriggerStatus_VFTable")) -- vfptr
		EEex_WriteDword(CMessageTriggerStatus + 0x4, objectID) -- m_targetId
		EEex_WriteDword(CMessageTriggerStatus + 0x8, -1) -- m_sourceId
		EEex_WriteDword(CMessageTriggerStatus + 0xC, EEex_ReadDword(share + 0x43C)) -- m_dwFlags
		EEex_WriteWord(CMessageTriggerStatus + 0x10, EEex_ReadWord(share + 0x47A, 0)) -- m_trapDetected
		EEex_WriteWord(CMessageTriggerStatus + 0x12, EEex_ReadWord(share + 0x478, 0)) -- m_trapActivated
		EEex_AddMessage(CMessageTriggerStatus)

	-- CGameContainer
	elseif m_objectType == 0x11 then

		sendCMessageSetForceActionPick()

		local m_trapActivated = EEex_ReadWord(share + 0x690, 0) == 1
		if not m_trapActivated then return end

		sendCMessageSetTrigger()

		EEex_Call(EEex_Label("CGameContainer::SetDrawPoly"), {0}, share, 0x0)
		EEex_WriteWord(share + 0x690, 0) -- m_trapActivated
		EEex_WriteWord(share + 0x692, 0) -- m_trapDetected

		local CMessageContainerStatus = EEex_Malloc(0x14)
		EEex_WriteDword(CMessageContainerStatus, EEex_Label("CMessageContainerStatus_VFTable")) -- vfptr
		EEex_WriteDword(CMessageContainerStatus + 0x4, objectID) -- m_targetId
		EEex_WriteDword(CMessageContainerStatus + 0x8, -1) -- m_sourceId
		EEex_WriteDword(CMessageContainerStatus + 0xC, EEex_ReadDword(share + 0x688)) -- m_dwFlags
		EEex_WriteWord(CMessageContainerStatus + 0x10, EEex_ReadWord(share + 0x692, 0)) -- m_trapDetected
		EEex_WriteWord(CMessageContainerStatus + 0x12, EEex_ReadWord(share + 0x690, 0)) -- m_trapActivated
		EEex_AddMessage(CMessageContainerStatus) 

	end

end

-- Sets the given script for actorID; scriptLevel corresponds to SCRLEV.IDS
function EEex_SetActorScript(actorID, resref, scriptLevel)
	EEex_SetActorScriptInternal(EEex_GetActorShare(actorID), resref, scriptLevel)
end

function EEex_SetActorScriptInternal(share, resref, scriptLevel)
	if share <= 0 then return end
	local resrefMem = EEex_WriteStringAuto(resref)

	local CAIScript = EEex_Malloc(0x24, 84)
	EEex_Call(EEex_Label("CAIScript::CAIScript"), {
		0, -- playerscript
		EEex_ReadDword(resrefMem + 0x4), -- 2/2 of resref
		EEex_ReadDword(resrefMem + 0x0), -- 1/2 of resref
	}, CAIScript, 0x0)

	EEex_Free(resrefMem)

	-- CGameSprite::SetScript
	EEex_Call(EEex_ReadDword(EEex_ReadDword(share) + 0x90), {CAIScript, scriptLevel}, share, 0x0)
end

function EEex_GetActorAlignment(actorID)
	if not EEex_IsSprite(actorID, true) then return 0 end
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x30, 0x3)
end

function EEex_GetActorAllegiance(actorID)
	if not EEex_IsSprite(actorID, true) then return 255 end
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x24, 0x0)
end

function EEex_GetActorClass(actorID)
	if not EEex_IsSprite(actorID, true) then return 255 end
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x24, 0x3)
end

function EEex_GetActorGender(actorID)
	if not EEex_IsSprite(actorID, true) then return 0 end
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x30, 0x2)
end

function EEex_GetActorGeneral(actorID)
	if not EEex_IsSprite(actorID, true) then return 0 end
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x24, 0x1)
end

function EEex_GetActorRace(actorID)
	if not EEex_IsSprite(actorID, true) then return 255 end
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x24, 0x2)
end

function EEex_GetActorSpecific(actorID)
	if not EEex_IsSprite(actorID, true) then return 0 end
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x30, 0x1)
end

function EEex_GetActorKit(actorID)
	if not EEex_IsSprite(actorID, true) then return 0 end
	return EEex_Call(EEex_Label("CGameSprite::GetKit"), {}, EEex_GetActorShare(actorID), 0x0)
end

-- Returns a number based on how different the EAs of the two actors are.
-- Return value of 0: the actors are allies (both green, both blue, both red)
-- Return value of 1: the actors are neutral (green and blue, blue and red)
-- Return value of 2: the actors are enemies (green and red)
function EEex_CompareActorAllegiances(actorID1, actorID2)
	if not EEex_IsSprite(actorID1, true) or not EEex_IsSprite(actorID2, true) then return 2 end
	local ea1 = EEex_GetActorAllegiance(actorID1)
	local ea2 = EEex_GetActorAllegiance(actorID2)
	local eaGroup1 = 2
	local eaGroup2 = 2
	if ea1 >= 2 and ea1 <= 30 then
		eaGroup1 = 1
	elseif ea1 >= 200 then
		eaGroup1 = 3
	end
	if ea2 >= 2 and ea2 <= 30 then
		eaGroup2 = 1
	elseif ea1 >= 200 then
		eaGroup2 = 3
	end
	return math.abs(eaGroup1 - eaGroup2)
end
-- Gets the actor's level for casting a spell of the specified type.
--  Possible values for spellType:
--   1: Wizard
--   2: Priest
--   4: Innate
function EEex_GetActorCasterLevel(actorID, spellType)
	local casterLevel = 1
	local class = EEex_GetActorClass(actorID)
	local level1 = EEex_GetActorStat(actorID, 34)
	local level2 = EEex_GetActorStat(actorID, 68)
	local level3 = EEex_GetActorStat(actorID, 69)
	if spellType == 1 then
		if class == 1 or class == 5 or class == 13 or class == 19 or class > 21 then
			casterLevel = level1 + EEex_GetActorStat(actorID, 79)
		elseif class == 7 or class == 10 or class == 14 or class == 17 then
			casterLevel = level2 + EEex_GetActorStat(actorID, 79)
		end
	elseif spellType == 2 then
		if class == 3 or class == 6 or class == 11 or class == 12 or class == 14 or class == 15 or class == 18 or class == 21 or class > 21 then
			casterLevel = level1 + EEex_GetActorStat(actorID, 80)
		elseif class == 8 or class == 16 then
			casterLevel = level2 + EEex_GetActorStat(actorID, 80)
		elseif class == 17 then
			casterLevel = level3 + EEex_GetActorStat(actorID, 80)
		end
	else
		if level1 > casterLevel then
			casterLevel = level1
		end
		if level2 > casterLevel then
			casterLevel = level2
		end
		if level3 > casterLevel then
			casterLevel = level3
		end
	end
	return casterLevel
end

-- Returns the actor's current area resref as a string.
-- If the game was just loaded, sometimes the actor doesn't know what
--  area they're in yet, so it'll return "" in that case.
function EEex_GetActorAreaRes(actorID)
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return "" end
	local address = EEex_ReadDword(share + 0x14)
	if address > 0 then
		return EEex_ReadLString(address, 0x8)
	else
		return ""
	end
end

-- Gets the maximum X and Y coordinates of the area the actor is in
-- (for outside areas the numbers are usually in the thousands).
-- If the game was just loaded, sometimes it will return 0 for both coordinates
--  because the actor doesn't have a pointer to the area yet.
function EEex_GetActorAreaSize(actorID)
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then
		return 0, 0
	end
	local address = EEex_ReadDword(share + 0x14)
	if address > 0 then
		local width = EEex_ReadWord(address + 0x4BC, 0x0) * 64
		local height = EEex_ReadWord(address + 0x4C0, 0x0) * 64
		return width, height
	else
		return 0, 0
	end
end

function EEex_GetActorEffectResrefs(actorID)
	if not EEex_IsSprite(actorID, true) then return {} end
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
	if share <= 0 then return 0 end
	local localVariables = EEex_ReadDword(share + 0x3758)
	return EEex_FetchVariable(localVariables, localName)
end


-- Sets a LOCALS variable in the actor's .CRE as if a
-- 	SetGlobal(<localName>, "LOCALS", <value>)
-- script action was executed by the given actor.
function EEex_SetActorLocal(actorID, localName, value)
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return end
	local localVariables = EEex_ReadDword(share + 0x3758)
	return EEex_SetVariable(localVariables, localName, value)
end

function EEex_GetActorLocation(actorID)
	local dataAddress = EEex_GetActorShare(actorID)
	if dataAddress <= 0 then
		return 0, 0
	end
	local x = EEex_ReadDword(dataAddress + 0x8)
	local y = EEex_ReadDword(dataAddress + 0xC)
	return x, y
end

function EEex_GetActorModalTimer(actorID)
	local actorData = EEex_GetActorShare(actorID)
	if actorData <= 0 then return 0 end
	local idRemainder = actorID % 0x64
	local modalTimer = EEex_ReadDword(actorData + 0x2C4)
	local timerRemainder = modalTimer % 0x64
	if timerRemainder < idRemainder then
		return idRemainder - timerRemainder
	else
		return 100 - timerRemainder + idRemainder
	end
end

-- Returns the actor's current modal state, (as defined in MODAL.IDS; stored at offset 0x28 of the global-creature structure).
function EEex_GetActorModalState(actorID)
	if not EEex_IsSprite(actorID, true) then return 0 end
	return EEex_ReadWord(EEex_GetActorShare(actorID) + 0x295D, 0x0)
end

-- Returns the actor's dialogue resref as a string, (defined at offset 0x2CC of the .CRE,
-- or optionally overriden by the actor structure at offset 0x48).
function EEex_GetActorDialogue(actorID)
	if not EEex_IsSprite(actorID, true) then return "" end
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x35A8, 8)
end

-- Returns the actor's override script resref as a string, (defined at offset 0x248 of the .CRE,
-- or optionally overriden by the actor structure at offset 0x50).
function EEex_GetActorOverrideScript(actorID)
	if not EEex_IsSprite(actorID, true) then return "" end
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x65C, 8)
end

-- Returns the actor's specifics script resref as a string, (defined at offset 0x78 of the actor structure).
function EEex_GetActorSpecificsScript(actorID)
	if not EEex_IsSprite(actorID, true) then return "" end
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x2A24, 8)
end

-- Returns the actor's class script, (defined at offset 0x250 of the .CRE,
-- or optionally overriden by the actor structure at offset 0x60).
function EEex_GetActorClassScript(actorID)
	if not EEex_IsSprite(actorID, true) then return "" end
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x664, 8)
end

-- Returns the actor's race script resref as a string, (defined at offset 0x258 of the .CRE,
-- or optionally overriden by the actor structure at offset 0x68).
function EEex_GetActorRaceScript(actorID)
	if not EEex_IsSprite(actorID, true) then return "" end
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x66C, 8)
end

-- Returns the actor's general script resref as a string, (defined at offset 0x260 of the .CRE,
-- or optionally overriden by the actor structure at offset 0x58).
function EEex_GetActorGeneralScript(actorID)
	if not EEex_IsSprite(actorID, true) then return "" end
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x674, 8)
end

-- Returns the actor's default script resref as a string, (defined at offset 0x268 of the .CRE,
-- or optionally overriden by the actor structure at offset 0x70).
function EEex_GetActorDefaultScript(actorID)
	if not EEex_IsSprite(actorID, true) then return "" end
	return EEex_ReadLString(EEex_GetActorShare(actorID) + 0x67C, 8)
end

function EEex_GetActorName(actorID)
	if not EEex_IsSprite(actorID, true) then return "" end
	return EEex_ReadString(EEex_ReadDword(EEex_Call(EEex_Label("CGameSprite::GetName"), {0x0}, EEex_GetActorShare(actorID), 0x0)))
end

function EEex_GetActorScriptName(actorID)
	local dataAddress = EEex_GetActorShare(actorID)
	if dataAddress <= 0 then return "" end
	return EEex_ReadString(EEex_ReadDword(EEex_Call(EEex_ReadDword(EEex_ReadDword(dataAddress) + 0x10), {}, dataAddress, 0x0)))
end

-- If the actor is a summoned creature, this returns the actor ID of its summoner.
-- If the actor is not a summoned creature, or if it's an image created by Mislead, Project
--  Image or Simulacrum, this will return 0.
-- Also, this will return 0 if the creature had already been summoned before the save was loaded.
function EEex_GetSummonerID(actorID)
	if not EEex_IsSprite(actorID, true) then return 0 end
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
	if not EEex_IsSprite(actorID, true) then return 0 end
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

-- Manually returns the total of the dice rolls from a damage or healing effect.
-- Values for luckMode:
-- 0: Luck won't affect die rolls.
-- 1: Weapon damage: Source's luck and minimum damage stat are added to each die roll.
-- 2: Spell damage: Target's luck is subtracted from each die roll.
-- 3: Healing: Target's luck is added to each die roll.
function EEex_RollEffectDice(targetID, sourceID, dicenumber, dicesize, luckMode)
	if dicenumber == 0 or dicesize == 0 then return 0 end
	local total = 0
	local sourceLuck = EEex_GetActorStat(sourceID, 32)
	local sourceWeaponLuck = EEex_GetActorStat(sourceID, 145)
	local sourceSpellMinimum = EEex_GetActorStat(sourceID, 621)
	local targetLuck = EEex_GetActorStat(targetID, 32)
	for i = 1, dicenumber, 1 do
		local roll = math.random(dicesize)
		if luckMode == 1 then
			roll = roll + sourceLuck + sourceWeaponLuck
		elseif luckMode == 2 then
			roll = roll - targetLuck
			if roll <= sourceSpellMinimum then
				roll = sourceSpellMinimum + 1
			end
		elseif luckMode == 3 then
			roll = roll + targetLuck
			if roll <= sourceSpellMinimum then
				roll = sourceSpellMinimum + 1
			end
		end
		if roll > dicesize then
			roll = dicesize
		elseif roll < 1 then
			roll = 1
		end
		total = total + roll
	end
	return total
end

function EEex_GetActorSpellState(actorID, splstateID)
	if not EEex_IsSprite(actorID) then return false end
	return EEex_Call(EEex_Label("CDerivedStats::GetSpellState"), {splstateID},
		EEex_GetActorShare(actorID) + 0xB30, 0x0) == 1
end

function EEex_GetActorSpellTimer(actorID)
	if not EEex_IsSprite(actorID) then return 0 end
	return EEex_ReadDword(EEex_GetActorShare(actorID) + 0x3870)
end

function EEex_GetActorStat(actorID, statID)
	if not EEex_IsSprite(actorID) then return 0 end
	local share = EEex_GetActorShare(actorID)
	return EEex_Call(EEex_Label("EEex_AccessStat"), {statID}, share, 0x0)
end

-- Returns true if the actor has at least one of the specified states, based on the numbers in STATE.IDS.
-- For example, if the state parameter is set to 0x8000, it will return true if the actor
--  is hasted or improved hasted, because STATE_HASTE is state 0x8000 in STATE.IDS.
function EEex_HasState(actorID, state)
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return false end
	local stateBits = bit32.bor(EEex_ReadDword(share + 0x434), EEex_ReadDword(share + 0xB30))
	return (bit32.band(stateBits, state) > 0)
end

-- Returns true if the actor is immune to the specified opcode.
function EEex_IsImmuneToOpcode(actorID, opcode)
	if not EEex_IsSprite(actorID, true) then return false end
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
	if not EEex_IsSprite(actorID, true) then return false end
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
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return 0 end
	local timerValue = EEex_ReadSignedWord(share + 0x3360, 0)
	if timerValue >= 0 then
		return 100 - timerValue
	else
		return 0
	end
end

-- Returns true if the given actor is in combat.
-- If includeDeadZone is set to true, the time period will be extended to until the battle music fully fades out.
function EEex_IsActorInCombat(actorID, includeDeadZone)
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return false end
	local area = EEex_ReadDword(share + 0x14)
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
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return 0 end
	local targetID = EEex_ReadDword(share + 0x3564)
	if targetID ~= -0x1 then
		return targetID
	else
		return 0x0
	end
end

function EEex_GetActorTargetPoint(actorID)
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return 0, 0 end
	return EEex_ReadDword(share + 0x3568), EEex_ReadDword(share + 0x356C)
end

-- Returns the ID of the action the actor is currently doing, based on ACTION.IDS.
-- For example, if the actor is currently moving to a point, it will return 23
--  because MoveToPoint() is action 23 in ACTION.IDS.
-- If the actor isn't doing anything, it will return 0.
function EEex_GetActorCurrentAction(actorID)
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return 0 end
	return EEex_ReadWord(share + 0x2F8, 0x0)
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

-- Returns the actor's current HP, (defined at offset 0x24 of the .CRE).
function EEex_GetActorCurrentHP(actorID)
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return 0 end
	return EEex_ReadSignedWord(share + 0x438, 0x0)
end

function EEex_GetActorCurrentDest(actorID)
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return 0, 0 end
	return EEex_ReadDword(share + 0x3404), EEex_ReadDword(share + 0x3408)
end

function EEex_GetActorPosDest(actorID)
	local share = EEex_GetActorShare(actorID)
	if share <= 0 then return 0, 0 end
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

-- Returns the actor's animation, (as defined in ANIMATE.IDS; stored at offset 0x28 of the .CRE,
-- or optionally overriden by the actor structure at offset 0x30).
function EEex_GetActorAnimation(actorID)
	return EEex_ReadDword(EEex_GetActorShare(actorID) + 0x43C)
end

-- Returns the actor's base strength, (defined at offset 0x238 of the .CRE).
function EEex_GetActorBaseStrength(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x64C, 0x0)
end

-- Returns the actor's base dexterity, (defined at offset 0x23C of the .CRE).
function EEex_GetActorBaseDexterity(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x650, 0x0)
end

-- Returns the actor's base constitution, (defined at offset 0x23D of the .CRE).
function EEex_GetActorBaseConstitution(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x651, 0x0)
end

-- Returns the actor's base intelligence, (defined at offset 0x23A of the .CRE).
function EEex_GetActorBaseIntelligence(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x64E, 0x0)
end

-- Returns the actor's base wisdom, (defined at offset 0x23B of the .CRE).
function EEex_GetActorBaseWisdom(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x64F, 0x0)
end

-- Returns the actor's base charisma, (defined at offset 0x23E of the .CRE).
function EEex_GetActorBaseCharisma(actorID)
	return EEex_ReadByte(EEex_GetActorShare(actorID) + 0x652, 0x0)
end

-- Returns the actor's direction, (as defined in DIR.IDS; stored at offset 0x34 of the actor structure).
function EEex_GetActorDirection(actorID)
	return EEex_ReadWord(EEex_GetActorShare(actorID) + 0x31FE, 0x0)
end

-- Returns the direction, (as defined in DIR.IDS), required for the actor to face the given point.
function EEex_GetActorRequiredDirection(actorID, targetX, targetY)
	if not EEex_IsSprite(actorID) then return -1 end
	local share = EEex_GetActorShare(actorID)
	local targetPoint = EEex_Malloc(0x8, 85)
	EEex_WriteDword(targetPoint + 0x0, targetX)
	EEex_WriteDword(targetPoint + 0x4, targetY)
	local result = EEex_Call(EEex_Label("CGameSprite::GetDirection"), {targetPoint}, share, 0x0)
	EEex_Free(targetPoint)
	return bit32.extract(result, 0, 0x10)
end

-- Returns true if the sourceID actor is facing the exact direction required to face the targetID actor.
function EEex_IsActorFacing(sourceID, targetID)
	local targetX, targetY = EEex_GetActorLocation(targetID)
	local currentDir = EEex_GetActorDirection(sourceID)
	local requiredDir = EEex_GetActorRequiredDirection(sourceID, targetX, targetY)
	return currentDir == requiredDir
end

-- Sanity function to help work with number ranges that are cyclic, (like actor direction).
-- Example:
-- 	EEex_CyclicBound(num, 0, 15)
-- defines a range of 0 to 15. num = 16 rolls over to 0, as does num = 32. num = -1 wraps around to 15, as does num = -17.
function EEex_CyclicBound(num, lowerBound, upperBound)
	local tolerance = upperBound - lowerBound + 1
	local cycleCount = math.floor((num - lowerBound) / tolerance)
	return num - tolerance * cycleCount
end

-- Returns true if num2 is within <range> positions of num in the cyclic bounds. See EEex_CyclicBound() for more info about cyclic ranges.
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

-- Returns true if the attackerID actor's direction is sufficent to backstab the targetID actor.
function EEex_IsValidBackstabDirection(attackerID, targetID)
	local attackerDirection = EEex_GetActorDirection(attackerID)
	local targetDirection = EEex_GetActorDirection(targetID)
	return EEex_WithinCyclicRange(attackerDirection, targetDirection, 3, 0, 15)
end

-- Returns true if the actor is a creature.
-- Returns false if the actor is BALDUR.BCS, a creature that no longer exists, an area script, a door, a container, or a region.
-- For example, if you get the sourceID of an effect of a fireball from a trap, and you
--  do EEex_IsSprite(sourceID), it will return false.
-- If the source had been a mage casting a fireball, it would've returned true.
function EEex_IsSprite(actorID, allowDead)
	-- EEex uses 0x0 as an "invalid" actorID return value, but it actually
	-- points to a valid object - (not a sprite, though, so return false).
	if actorID ~= 0x0 and actorID ~= -0x1 then
		local share = EEex_GetActorShare(actorID)
		if share <= 0 then
			return false
		elseif EEex_ReadByte(share + 0x4, 0) == 0x31 then
			return allowDead or bit32.band(EEex_ReadDword(share + 0x434), 0xFC0) == 0x0
		end
	end
	return false
end

-- Directly applies an effect to an actor based on the args table.
function EEex_ApplyEffectToActor(actorID, args)

	local Item_effect_st = EEex_Malloc(0x30, 86)

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
			local stringMem = EEex_Malloc(#resref + 1, 87)
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

	local writeStringArg = function(address, argKey, length)
		local string = args[argKey]
		EEex_WriteLString(address, string or "", length)
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

	local target = EEex_Malloc(0x8, 88)
	EEex_WriteDword(target + 0x0, argOrDefault("target_x", -0x1))
	EEex_WriteDword(target + 0x4, argOrDefault("target_y", -0x1))

	local sourceID = argOrDefault("source_id", -0x1)

	local source = EEex_Malloc(0x8, 89)
	EEex_WriteDword(source + 0x0, argOrDefault("source_x", -0x1))
	EEex_WriteDword(source + 0x4, argOrDefault("source_y", -0x1))

	-- int sourceTarget, CPoint *target, int sourceID, CPoint *source, Item_effect_st *effect
	local CGameEffect = EEex_Call(EEex_Label("CGameEffect::DecodeEffect"), {sourceTarget, target, sourceID, source, Item_effect_st}, nil, 0x14)

	EEex_Free(target)
	EEex_Free(source)
	EEex_Free(Item_effect_st)

	EEex_WriteDword(CGameEffect + 0x5C, argOrDefault("parameter3", 0))
	EEex_WriteDword(CGameEffect + 0x60, argOrDefault("parameter4", 0))
	EEex_WriteDword(CGameEffect + 0x64, argOrDefault("parameter5", 0))
	writeResrefArg(CGameEffect + 0x6C, "vvcresource")
	writeResrefArg(CGameEffect + 0x74, "resource2")
	EEex_WriteDword(CGameEffect + 0x8C, argOrDefault("restype", 0))
	writeResrefArg(CGameEffect + 0x90, "parent_resource")
	EEex_WriteDword(CGameEffect + 0x98, argOrDefault("resource_flags", 0))
	EEex_WriteDword(CGameEffect + 0x9C, argOrDefault("impact_projectile", 0))
	EEex_WriteDword(CGameEffect + 0xA0, argOrDefault("sourceslot", 0xFFFFFFFF))
	writeStringArg(CGameEffect + 0xA4, "effvar", 32)
	EEex_WriteDword(CGameEffect + 0xC4, argOrDefault("casterlvl", 1))
	EEex_WriteDword(CGameEffect + 0xC8, argOrDefault("internal_flags", 1))
	EEex_WriteDword(CGameEffect + 0xCC, argOrDefault("sectype", 0))

	local share = EEex_GetActorShare(actorID)
	local vtable = EEex_ReadDword(share)
	-- int immediateResolve, int noSave, char list, CGameEffect *pEffect
	EEex_Call(EEex_ReadDword(vtable + 0x74), {argOrDefault("immediateResolve", 1), 0, 1, CGameEffect}, share, 0x0)
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
-- This looks through spell effects, item equipped effects, and permanent effects.
function EEex_IterateActorEffects(actorID, func)
	if not EEex_IsSprite(actorID, true) then return end
	local esi = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x33AC)
	while esi ~= 0x0 do
		local eData = EEex_ReadDword(esi + 0x8) - 0x4
		if eData > 0x0 then
			func(eData)
		end
		esi = EEex_ReadDword(esi)
	end
	esi = EEex_ReadDword(EEex_GetActorShare(actorID) + 0x3380)
	while esi ~= 0x0 do
		local eData = EEex_ReadDword(esi + 0x8) - 0x4
		if eData > 0x0 then
			func(eData)
		end
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
		if edi > 0x0 then
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
		end
		esi = EEex_ReadDword(esi)
	end
end

-- Returns the resref of the item the actor has in the specified inventory slot (from SLOTS.IDS).
function EEex_GetActorItemRes(actorID, slot)
	if not EEex_IsSprite(actorID, true) then return "" end
	local share = EEex_GetActorShare(actorID)
	local invItemData = EEex_ReadDword(share + 0xA80 + slot * 4)
	if invItemData > 0 then
		return EEex_ReadLString(invItemData + 0x8, 8)
	else
		return ""
	end
end

-- Returns the remaining charges of an ability of the item the actor has in the specified inventory slot (from SLOTS.IDS).
--  The ability parameter should be 1, 2 or 3 depending on which ability header you want to check.
function EEex_GetActorItemCharges(actorID, slot, ability)
	if not EEex_IsSprite(actorID, true) then return 0 end
	local share = EEex_GetActorShare(actorID)
	if ability < 1 then
		ability = 1
	elseif ability > 3 then
		ability = 3
	end
	local invItemData = EEex_ReadDword(share + 0xA80 + slot * 4)
	if invItemData > 0 then
		return EEex_ReadWord(invItemData + 0x12 + ability * 2, 0x0)
	else
		return 0
	end
end

-- Sets the remaining charges of an ability of the item the actor has in the specified inventory slot (from SLOTS.IDS).
--  The ability parameter should be 1, 2 or 3 depending on which ability header you want to check.
--  The charges parameter should be non-zero.
function EEex_SetActorItemCharges(actorID, slot, ability, charges)
	if not EEex_IsSprite(actorID, true) then return end
	local share = EEex_GetActorShare(actorID)
	if ability < 1 then
		ability = 1
	elseif ability > 3 then
		ability = 3
	end
	local invItemData = EEex_ReadDword(share + 0xA80 + slot * 4)
	if invItemData > 0 then
		EEex_WriteWord(invItemData + 0x12 + ability * 2, charges)
	end
end

-- Looks through the items in the actor's inventory, calling a function for each one.
--  If equippedItemsOnly is set to true, it will only call the function for items the actor
--  has equipped. The first parameter of the called function is the slot number of the item (from SLOTS.IDS).
--  The second parameter returns data on the inventory item. Here's how you can use it:
--[[
	EEex_ReadLString(invItemData + 0x8, 8) -- Gets the resref of the item.
	EEex_ReadWord(invItemData + 0x14, 0x0) -- Gets the number of charges on the item's first ability.
	EEex_ReadWord(invItemData + 0x16, 0x0) -- Gets the number of charges on the item's second ability.
	EEex_ReadWord(invItemData + 0x18, 0x0) -- Gets the number of charges on the item's third ability.
	EEex_ReadDword(invItemData + 0x1C) -- Gets the item's flags (from INVITEM.IDS)
--]]
function EEex_IterateActorItems(actorID, equippedItemsOnly, func)
	if not EEex_IsSprite(actorID, true) then return end
	local share = EEex_GetActorShare(actorID)
	local equippedWeaponSlot = EEex_ReadByte(share + 0xB1C, 0x0)
	local equippedWeaponAbility = EEex_ReadWord(share + 0xB1E, 0x0)
	local hasShieldEquipped = (EEex_ReadDword(share + 0xAA4) > 0)
	if hasShieldEquipped and equippedItemsOnly then
		local invWeaponData = EEex_ReadDword(share + 0xA80 + equippedWeaponSlot * 4)
		if invWeaponData > 0 then
			local itemData = EEex_DemandResData(EEex_ReadLString(invWeaponData + 0x8, 8), "ITM")
			if itemData > 0 then
				if bit32.band(EEex_ReadDword(itemData + 0x18), 0x2) > 0 or EEex_ReadByte(itemData + 0x72 + equippedWeaponAbility * 0x38) ~= 1 then
					hasShieldEquipped = false
				end
			end
		end
	end
	for i = 0, 38, 1 do
		local invItemData = EEex_ReadDword(share + 0xA80 + i * 4)
		if invItemData > 0 and (equippedItemsOnly == false or i < 9 or (i == 9 and hasShieldEquipped) or i == equippedWeaponSlot) then
			func(i, invItemData)
		end
	end
end

----------------------
--  Spell Learning  --
----------------------

function EEex_LearnWizardSpell(actorID, level, resref)
	local resrefAddress = EEex_Malloc(0xC, 90)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::AddKnownSpellMage"), {level, resrefAddress}, EEex_GetActorShare(actorID), 0x0)
	EEex_Free(resrefAddress)
end

function EEex_LearnClericSpell(actorID, level, resref)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local spellLevelListPointer = actorDataAddress + (level * 8 - level + 0x1A1) * 4
	local resrefAddress = EEex_Malloc(0xC, 91)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::AddKnownSpell"),
		{0x0, spellLevelListPointer, level, resrefAddress}, actorDataAddress, 0x0)
	EEex_Free(resrefAddress)
end

function EEex_LearnInnateSpell(actorID, resref)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local spellLevelListPointer = actorDataAddress + 0x844
	local resrefAddress = EEex_Malloc(0xC, 92)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::AddKnownSpell"),
		{0x2, spellLevelListPointer, 0x0, resrefAddress}, actorDataAddress, 0x0)
	EEex_Free(resrefAddress)
end

function EEex_UnlearnWizardSpell(actorID, level, resref)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local resrefAddress = EEex_Malloc(0xC, 93)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::RemoveKnownSpellMage"), {level, resrefAddress}, actorDataAddress, 0x0)
	EEex_Free(resrefAddress)
end

function EEex_UnlearnClericSpell(actorID, level, resref)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local resrefAddress = EEex_Malloc(0xC, 94)
	EEex_WriteString(resrefAddress, resref)
	EEex_Call(EEex_Label("CGameSprite::RemoveKnownSpellPriest"), {level, resrefAddress}, actorDataAddress, 0x0)
	EEex_Free(resrefAddress)
end

function EEex_UnlearnInnateSpell(actorID, resref)
	local actorDataAddress = EEex_GetActorShare(actorID)
	local spellLevelListPointer = actorDataAddress + 0x844
	local resrefAddress = EEex_Malloc(0xC, 95)
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

	local spellLevelListPointer = EEex_Malloc(0x14, 96)
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

	local spellLevelListPointer = EEex_Malloc(0x14, 97)
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

	local spellLevelListPointer = EEex_Malloc(0x14, 98)
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

---------------------------------------------------------
--  Functions you can use with opcode 402 (Invoke Lua) --
---------------------------------------------------------

--[[
To use the EXCHARGE function, create an opcode 402 effect in an item or spell, set the resource to EXCHARGE (all capitals),
 set the timing to instant, limited and the duration to 0, and choose parameters.
For an example of this function in use, look at EXCHARGE.ITM.

The EXCHARGE function modifies the number of charges on an item (or the quantity of the item) in the character's inventory.
 It cannot reduce the number of charges on an item to 0 or less.

parameter1 - Determines how many charges to add.

parameter2 - 
If 0, parameter1 charges are added.
If 1, the number of charges is set to parameter1.
If 2, the number of charges is multiplied by parameter1 then divided by 100 (percentage multiplier).

savingthrow - This function uses several extra bits on this parameter:
Bit 16: If set, it will not modify the quantity of an item like a potion; it will only work with items like wands that have charges.
Bit 17: If set, it will not modify the charges of an item; it will only modify the quantity of stackable items like potions.
Bit 18: If set, it can increase the charges/quantity beyond the normal maximum for the item.

special - Determines which item slot to recharge (from SLOTS.IDS).
Note: Some of the slot names in SLOTS.IDS are misleading:
15 SLOT_MISC0 is the first quick item slot.
16 SLOT_MISC1 is the second quick item slot.
17 SLOT_MISC2 is the third quick item slot.
34 SLOT_MISC19 is the conjured weapon slot.

If bit 20 of an item's header flags (the flags that include stuff like Add Strength Bonus) is set, the function will not modify
 the charges of that ability of the item.
--]]
function EXCHARGE(effectData, creatureData)
	local targetID = EEex_ReadDword(creatureData + 0x34)
	local parameter1 = EEex_ReadDword(effectData + 0x18)
	local parameter2 = EEex_ReadDword(effectData + 0x1C)
	local savingthrow = EEex_ReadDword(effectData + 0x3C)
	local doNotModifyQuantity = (bit32.band(savingthrow, 0x10000) > 0)
	local doNotModifyCharges = (bit32.band(savingthrow, 0x20000) > 0)
	local goOverMaximum = (bit32.band(savingthrow, 0x40000) > 0)
	local special = EEex_ReadDword(effectData + 0x44)
	local invItemData = EEex_ReadDword(creatureData + 0xA80 + special * 4)
	if invItemData > 0 then
		local charges1 = EEex_ReadWord(invItemData + 0x14, 0x0)
		local charges2 = EEex_ReadWord(invItemData + 0x16, 0x0)
		local charges3 = EEex_ReadWord(invItemData + 0x18, 0x0)
		local itemData = EEex_DemandResData(EEex_ReadLString(invItemData + 0x8, 8), "ITM")
		if itemData > 0 then
			local maxQuantity = EEex_ReadWord(itemData + 0x38, 0x0)
			local numAbilities = EEex_ReadWord(itemData + 0x68, 0x0)
			if numAbilities >= 1 then
				local maxCharges1 = EEex_ReadWord(itemData + 0x94, 0x0)
				if maxCharges1 > 0 and bit32.band(EEex_ReadDword(itemData + 0x98), 0x100000) == 0 and ((maxQuantity > 1 and doNotModifyQuantity == false) or (maxQuantity <= 1 and doNotModifyCharges == false)) then
					if parameter2 == 0 then
						charges1 = charges1 + parameter1
					elseif parameter2 == 1 then
						charges1 = parameter1
					elseif parameter2 == 2 then
						charges1 = math.floor(charges1 * parameter1 / 100)
					end
					if charges1 <= 0 then
						charges1 = 1
					elseif goOverMaximum == false then
						if maxQuantity > 1 and charges1 > maxQuantity then
							charges1 = maxQuantity
						elseif maxQuantity <= 1 and charges1 > maxCharges1 then
							charges1 = maxCharges1
						end
					elseif charges1 > 32767 then
						charges1 = 32767
					end
					EEex_WriteWord(invItemData + 0x14, charges1)
				end
			end
			if numAbilities >= 2 then
				local maxCharges2 = EEex_ReadWord(itemData + 0xCC, 0x0)
				if maxCharges2 > 0 and bit32.band(EEex_ReadDword(itemData + 0xD0), 0x100000) == 0 and ((maxQuantity > 1 and doNotModifyQuantity == false) or (maxQuantity <= 1 and doNotModifyCharges == false)) then
					if parameter2 == 0 then
						charges2 = charges2 + parameter1
					elseif parameter2 == 1 then
						charges2 = parameter1
					elseif parameter2 == 2 then
						charges2 = math.floor(charges2 * parameter1 / 100)
					end
					if charges2 <= 0 then
						charges2 = 1
					elseif goOverMaximum == false then
						if maxQuantity > 1 and charges2 > maxQuantity then
							charges2 = maxQuantity
						elseif maxQuantity <= 1 and charges2 > maxCharges2 then
							charges2 = maxCharges2
						end
					elseif charges2 > 32767 then
						charges2 = 32767
					end
					EEex_WriteWord(invItemData + 0x14, charges2)
				end
			end
			if numAbilities >= 3 then
				local maxCharges3 = EEex_ReadWord(itemData + 0x104, 0x0)
				if maxCharges3 > 0 and bit32.band(EEex_ReadDword(itemData + 0x108), 0x100000) == 0 and ((maxQuantity > 1 and doNotModifyQuantity == false) or (maxQuantity <= 1 and doNotModifyCharges == false)) then
					if parameter2 == 0 then
						charges3 = charges3 + parameter1
					elseif parameter2 == 1 then
						charges3 = parameter1
					elseif parameter2 == 2 then
						charges3 = math.floor(charges3 * parameter1 / 100)
					end
					if charges3 <= 0 then
						charges3 = 1
					elseif goOverMaximum == false then
						if maxQuantity > 1 and charges3 > maxQuantity then
							charges3 = maxQuantity
						elseif maxQuantity <= 1 and charges3 > maxCharge3 then
							charges3 = maxCharges3
						end
					elseif charges3 > 32767 then
						charges3 = 32767
					end
					EEex_WriteWord(invItemData + 0x14, charges3)
				end
			end
		end
	end
end

--[[
To use the EXDAMAGE function, create an opcode 402 effect in an item or spell, set the resource to EXDAMAGE (all capitals),
 set the timing to instant, limited and the duration to 0, and choose parameters.
For an example of this function in use, look at EXFLAMEB.ITM.

The EXDAMAGE function deals damage to the target. The main use of it is to put it on a weapon that should deal non-physical
 damage, such as the Flame Blade. The function can add bonuses to the damage dealt based on the character's Strength, proficiencies,
 general weapon damage bonuses, melee damage bonuses, missile damage bonuses, or fist damage bonuses. This can't be done simply
 by applying a damage effect normally.

parameter1 - The first byte determines the damage, the second byte determines the dice size, the third byte determines the dice number,
 and the fourth byte determines the proficiency used. For example, if the effect is from a bastard sword and should do 2d4+3 damage,
 parameter1 should be this:
 0x59020403
 0x59 is the bastard sword proficiency number, 0x2 is the dice number, 0x4 is the dice size, and 0x3 is the damage bonus.
 If a proficiency is not specified, it doesn't give a damage bonus based on proficiency.

parameter2 - It's the same as parameter2 on the damage opcode: the first two bytes determine whether to just deal damage or set HP or whatever.
 The last two bytes determine the damage type. If you simply want to deal fire damage, parameter2 would be 0x80000 (look at DMGTYPE.IDS).

savingthrow - This function uses several extra bits on this parameter:
Bit 16: If set, the source character's Strength bonus is added to the damage.
Bit 17: If set, the damage is treated as the base damage of a melee weapon, so it gets damage bonuses from opcodes 73 and 285.
Bit 18: If set, the damage is treated as the base damage of a missile weapon, so it gets damage bonuses from opcodes 73 and 286.
Bit 19: If set, the damage is treated as the base damage of a fist weapon, so it gets damage bonuses from opcodes 73 and 289.
If more than one of bits 17, 18, and 19 are set, opcode 73 damage bonuses are not applied multiple times. Also, if at least one
 of those three bits are set, the minimum damage of each die will be increased based on the source character's Luck and opcode 250 bonuses.
 If none of those three bits are set, the maximum damage of each die is decreased based on the target character's Luck bonuses.
Bit 26: If set, there is a Save vs. Spell against the damage (set this bit instead of bit 0 if you're using "Save for half")
Bit 27: If set, there is a Save vs. Breath against the damage (set this bit instead of bit 1 if you're using "Save for half")
Bit 28: If set, there is a Save vs. Death against the damage (set this bit instead of bit 2 if you're using "Save for half")
Bit 29: If set, there is a Save vs. Wand against the damage (set this bit instead of bit 3 if you're using "Save for half")
Bit 30: If set, there is a Save vs. Polymorph against the damage (set this bit instead of bit 4 if you're using "Save for half")
special - It's the same as special on the damage opcode.
--]]
ex_proficiency_damage = {[0] = 0, [1] = 0, [2] = 2, [3] = 3, [4] = 4, [5] = 5}
ex_strength_damage = {[0] = -20, [1] = -4, [2] = -2, [3] = -1, [4] = -1, [5] = -1, [6] = 0, [7] = 0, [8] = 0, [9] = 0, [10] = 0, [11] = 0, [12] = 0, [13] = 0, [14] = 0, [15] = 0, [16] = 1, [17] = 1, [18] = 2, [19] = 7, [20] = 8, [21] = 9, [22] = 10, [23] = 11, [24] = 12, [25] = 14}
function EXDAMAGE(effectData, creatureData)
	local sourceID = EEex_ReadDword(effectData + 0x10C)
	local targetID = EEex_ReadDword(creatureData + 0x34)
	local damage = EEex_ReadByte(effectData + 0x18, 0x0)
	local dicesize = EEex_ReadByte(effectData + 0x19, 0x0)
	local dicenumber = EEex_ReadByte(effectData + 0x1A, 0x0)
	local proficiency = EEex_ReadByte(effectData + 0x1B, 0x0)
	local parameter2 = EEex_ReadDword(effectData + 0x1C)
	local savingthrow = EEex_ReadDword(effectData + 0x3C)
	local special = EEex_ReadDword(effectData + 0x44)
	local restype = EEex_ReadDword(effectData + 0x8C)
	local parent_resource = EEex_ReadLString(effectData + 0x90, 8)
	local casterlvl = EEex_ReadDword(effectData + 0xC4)
	if bit32.band(savingthrow, 0x40000) > 0 then
		local itemData = EEex_DemandResData(parent_resource, "ITM")
		if itemData > 1000 then
			local itemType = EEex_ReadWord(itemData + 0x1C, 0x0)
			
			if itemType == 5 or itemType == 14 or itemType == 31 then
				local found_it = false
				EEex_IterateActorEffects(sourceID, function(eData)
					local the_timing = EEex_ReadDword(eData + 0x24)
					local the_sourceslot = EEex_ReadDword(eData + 0xA4)
					if the_timing == 2 and the_sourceslot >= 35 and the_sourceslot <= 38 and found_it == false then
						found_it = true
						local launcherData = EEex_DemandResData(EEex_ReadLString(eData + 0x94, 8), "ITM")
						if launcherData > 1000 then
							local launcherType = EEex_ReadWord(launcherData + 0x1C, 0x0)
							if (itemType == 5 and launcherType == 15) or (itemType == 14 and launcherType == 18) or (itemType == 31 and launcherType == 27) then
								proficiency = EEex_ReadByte(launcherData + 0x31, 0x0)
								damage = damage + EEex_ReadSignedWord(launcherData + 0x8C, 0x0)
							end
						end
					end
				end)
			end
		end
		if proficiency == 0 then
			if itemType == 5 then
				if EEex_GetActorStat(sourceID, 104) > EEex_GetActorStat(sourceID, 105) then
					proficiency = 104
				else
					proficiency = 105
				end
			elseif itemType == 14 then
				proficiency = 107
			elseif itemType == 31 then
				proficiency = 103
			end
		end
		damage = damage + EEex_GetActorStat(sourceID, 168)
	end
	if proficiency > 0 and ex_proficiency_damage[EEex_GetActorStat(sourceID, proficiency)] ~= nil then
		damage = damage + ex_proficiency_damage[EEex_GetActorStat(sourceID, proficiency)]
	end
	if bit32.band(savingthrow, 0x4000000) > 0 then
		savingthrow = bit32.band(savingthrow, 0x1)
	end
	if bit32.band(savingthrow, 0x8000000) > 0 then
		savingthrow = bit32.band(savingthrow, 0x2)
	end
	if bit32.band(savingthrow, 0x10000000) > 0 then
		savingthrow = bit32.band(savingthrow, 0x4)
	end
	if bit32.band(savingthrow, 0x20000000) > 0 then
		savingthrow = bit32.band(savingthrow, 0x8)
	end
	if bit32.band(savingthrow, 0x40000000) > 0 then
		savingthrow = bit32.band(savingthrow, 0x10)
	end
	if bit32.band(savingthrow, 0x10000) > 0 then
		local strength = EEex_GetActorStat(sourceID, 36)
		if strength < 0 then
			strength = 0
		elseif strength > 25 then
			strength = 25
		end
		damage = damage + ex_strength_damage[strength]
		if strength == 18 then
			local exStrength = EEex_GetActorStat(sourceID, 37)
			if exStrength >= 1 then
				damage = damage + 1
			end
			if exStrength >= 76 then
				damage = damage + 1
			end
			if exStrength >= 91 then
				damage = damage + 1
			end
			if exStrength >= 100 then
				damage = damage + 1
			end
		end
	end
	if bit32.band(savingthrow, 0x20000) > 0 then
		damage = damage + EEex_GetActorStat(sourceID, 167)
	end
	if bit32.band(savingthrow, 0x40000) > 0 then
		damage = damage + EEex_GetActorStat(sourceID, 168)
	end
	if bit32.band(savingthrow, 0x80000) > 0 then
		damage = damage + EEex_GetActorStat(sourceID, 171)
	end
	local luck = 0
	if bit32.band(savingthrow, 0x20000) > 0 or bit32.band(savingthrow, 0x40000) > 0 or bit32.band(savingthrow, 0x80000) > 0 then
		damage = damage + EEex_RollEffectDice(targetID, sourceID, dicenumber, dicesize, 1)
		damage = damage + EEex_GetActorStat(sourceID, 50)
		restype = 0
		parent_resource = ""

	else
		restype = 1
		damage = damage + EEex_RollEffectDice(targetID, sourceID, dicenumber, dicesize, 2)
	end
--[[
	if dicesize > 0 then
		for i = 1, dicenumber, 1 do
			local currentRoll = math.random(dicesize)
			if luck > 0 and currentRoll <= luck then
				currentRoll = luck + 1
			elseif luck < 0 and currentRoll > (dicesize + luck) then
				currentRoll = dicesize + luck
			end
			damage = damage + currentRoll
		end
	end
--]]
	EEex_ApplyEffectToActor(targetID, {
["opcode"] = 12,
["target"] = 2,
["timing"] = 1,
["parameter1"] = damage,
["parameter2"] = parameter2,
["savingthrow"] = savingthrow,
["special"] = special,
["restype"] = restype,
["parent_resource"] = parent_resource,
["source_target"] = targetID,
["source_id"] = sourceID
})
end

--[[
To use the EXMODMEM function, create an opcode 402 effect in an item or spell, set the resource to EXMODMEM (all capitals),
 set the timing to instant, limited and the duration to 0, and choose parameters.

The EXMODMEM function changes which spells the target can cast. It can either restore spell uses (like Wonderous Recall) or
 deplete spell uses (like Nishruu attacks). It can affect wizard and/or priest spells.

parameter1 - Determines the maximum number of spell uses that can be restored/removed. If set to 0, there is no limit.

parameter2 - Determines the highest spell level that can be restored (1 - 9).

savingthrow - This function uses several extra bits on this parameter:
Bit 16: If set, the function will not restore/remove wizard spells (by default it looks through both wizard and priest spells).
Bit 17: If set, the function will not restore/remove priest spells (by default it looks through both wizard and priest spells).
Bit 19: If set, the function removes memorized spells rather than restoring them.
Bit 20: If set, the function will not restore/remove more than one spell of each of the eight spell schools.
Bit 21: If set, the function will only restore/remove a specific spell. By default, that spell is the same one that called this
 function. If you set resource2 to a spell resref (calling this function from an EFF file), it will check for that spell instead.
Bit 22: If set, the function will not restore/remove a specific spell. By default, that spell is the same one that called this
 function. If you set resource3 to a spell resref (calling this function from an EFF file), it will check for that spell instead.

special - Determines the lowest spell level that can be restored (1 - 9).
--]]
ex_wizard_classes = {1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0}
ex_priest_classes = {0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1}
function EXMODMEM(effectData, creatureData)
	local targetID = EEex_ReadDword(creatureData + 0x34)
	local parameter1 = EEex_ReadDword(effectData + 0x18)
	local parameter2 = EEex_ReadDword(effectData + 0x1C)
	local savingthrow = EEex_ReadDword(effectData + 0x3C)
	local processWizardSpells = (bit32.band(savingthrow, 0x10000) == 0)
	local processPriestSpells = (bit32.band(savingthrow, 0x20000) == 0)
--	local lowestLevelFirst = (bit32.band(savingthrow, 0x40000) > 0)
	local subtractSpells = (bit32.band(savingthrow, 0x80000) > 0)
	local onePerSchool = (bit32.band(savingthrow, 0x100000) > 0)
	local matchSpecificSpell = (bit32.band(savingthrow, 0x200000) > 0)
	local ignoreSpecificSpell = (bit32.band(savingthrow, 0x400000) > 0)
	local printFeedback = (bit32.band(savingthrow, 0x800000) > 0)
	local targetClass = EEex_GetActorClass(targetID)
	local isSorcererClass = (targetClass == 19 or targetClass == 21)
	if ex_wizard_classes[targetClass] ~= 1 then
		processWizardSpells = false
	end
	if ex_priest_classes[targetClass] ~= 1 then
		processPriestSpells = false
	end
	local parent_resource = EEex_ReadLString(effectData + 0x90, 8)
	local matchSpell = EEex_ReadLString(effectData + 0x6C, 8)
	if matchSpell == "" then
		matchSpell = parent_resource
	end
	local ignoreSpell = EEex_ReadLString(effectData + 0x74, 8)
	if ignoreSpell == "" then
		ignoreSpell = parent_resource
	end
	local special = EEex_ReadDword(effectData + 0x44)
	local parameter3 = EEex_ReadDword(effectData + 0x5C)
	local schools_found = {false, false, false, false, false, false, false, false}
	if parameter3 > 0 then 
		for i = 1, 8, 1 do
			if bit32.band(parameter3, 2 ^ i) > 0 then
				schools_found[i] = true
			end
		end
	end
	local numFound = 0
	local numLeft = 0
	if parameter2 < 0 then
		parameter2 = 1
	elseif parameter2 > 9 then
		parameter2 = 9
	end
	if special < 0 then
		special = 1
	elseif special > parameter2 then
		special = parameter2
	end

	local increment = -1
--[[
	if lowestLevelFirst then
		local temp = parameter2
		parameter2 = special
		special = temp
		increment = 1
	end
--]]
	local sorcererSpellsFound = {}
	local sorcererSpellMax = 0
	for i = parameter2, special, increment do
		sorcererSpellsFound = {}
		numLeft = parameter1 - numFound
		sorcererSpellMax = 0
		if processWizardSpells then 
			EEex_ProcessWizardMemorization(targetID, function(level, resrefLocation)
				if level == i then
					local resref = EEex_ReadLString(resrefLocation, 8)
					if sorcererSpellsFound[resref] == nil then	
						sorcererSpellsFound[resref] = 1
					else
						sorcererSpellsFound[resref] = sorcererSpellsFound[resref] + 1
					end
					local flags = EEex_ReadWord(resrefLocation + 0x8, 0x0)
					local spellMemorized = (bit32.band(flags, 0x1) > 0)
					if parameter2 >= level and ((spellMemorized and subtractSpells) or (spellMemorized == false and subtractSpells == false)) and (matchSpecificSpell == false or matchSpell == resref or isSorcererClass) and (ignoreSpecificSpell == false or ignoreSpell ~= resref or isSorcererClass) then
						local spellData = EEex_GetSpellData(resref)
						if spellData ~= 0 then
							local spellSchool = EEex_ReadByte(spellData + 0x25, 0x0)
							if (parameter1 <= 0 or ((isSorcererClass == false or sorcererSpellsFound[resref] <= numLeft) and (isSorcererClass or numFound < parameter1))) and ((onePerSchool == false and parameter3 == 0) or (schools_found[spellSchool] ~= nil and schools_found[spellSchool] == false)) then
								if onePerSchool then 
									schools_found[spellSchool] = true
								end
								if subtractSpells then
									EEex_WriteWord(resrefLocation + 0x8, bit32.band(flags, 0xFFFE))
--[[
									if printFeedback then
										Infinity_SetToken("EX_SPNAME", Infinity_FetchString(EEex_ReadDword(spellData + 0x8)))
										EEex_ApplyEffectToActor(targetID, {
["opcode"] = 139,
["target"] = 2,
["timing"] = 1,
["parameter1"] = ex_modify_spell_memory_strref_2,
["source_target"] = targetID,
["source_id"] = targetID
})
									end
--]]
								else
									EEex_WriteWord(resrefLocation + 0x8, bit32.bor(flags, 0x1))
--[[
									if printFeedback then
										Infinity_SetToken("EX_SPNAME", Infinity_FetchString(EEex_ReadDword(spellData + 0x8)))
										EEex_ApplyEffectToActor(targetID, {
["opcode"] = 139,
["target"] = 2,
["timing"] = 1,
["parameter1"] = ex_modify_spell_memory_strref_1,
["source_target"] = targetID,
["source_id"] = targetID
})
									end
--]]
								end
								if isSorcererClass then
									if sorcererSpellsFound[resref] > sorcererSpellMax then
										sorcererSpellMax = sorcererSpellsFound[resref]
									end
								else
									numFound = numFound + 1
								end
							end
						end
					end
				end
			end)
		end
		numFound = numFound + sorcererSpellMax
		sorcererSpellsFound = {}
		numLeft = parameter1 - numFound
		sorcererSpellMax = 0
		if i <= 7 and processPriestSpells then 
			EEex_ProcessClericMemorization(targetID, function(level, resrefLocation)
				if level == i then
					local resref = EEex_ReadLString(resrefLocation, 8)
					if sorcererSpellsFound[resref] == nil then	
						sorcererSpellsFound[resref] = 1
					else
						sorcererSpellsFound[resref] = sorcererSpellsFound[resref] + 1
					end
					local flags = EEex_ReadWord(resrefLocation + 0x8, 0x0)
					local spellMemorized = (bit32.band(flags, 0x1) > 0)
					if parameter2 >= level and ((spellMemorized and subtractSpells) or (spellMemorized == false and subtractSpells == false)) and (matchSpecificSpell == false or matchSpell == resref or isSorcererClass) and (ignoreSpecificSpell == false or ignoreSpell ~= resref or isSorcererClass) then
						local spellData = EEex_GetSpellData(resref)
						if spellData ~= 0 then
							local spellSchool = EEex_ReadByte(spellData + 0x25, 0x0)
							if (parameter1 <= 0 or ((isSorcererClass == false or sorcererSpellsFound[resref] <= numLeft) and (isSorcererClass or numFound < parameter1))) and ((onePerSchool == false and parameter3 == 0) or (schools_found[spellSchool] ~= nil and schools_found[spellSchool] == false)) then
								if onePerSchool then 
									schools_found[spellSchool] = true
								end
								if subtractSpells then
									EEex_WriteWord(resrefLocation + 0x8, bit32.band(flags, 0xFFFE))
--[[
									if printFeedback then
										Infinity_SetToken("EX_SPNAME", Infinity_FetchString(EEex_ReadDword(spellData + 0x8)))
										EEex_ApplyEffectToActor(targetID, {
["opcode"] = 139,
["target"] = 2,
["timing"] = 1,
["parameter1"] = ex_modify_spell_memory_strref_2,
["source_target"] = targetID,
["source_id"] = targetID
})
									end
--]]
								else
									EEex_WriteWord(resrefLocation + 0x8, bit32.bor(flags, 0x1))
--[[
									if printFeedback then
										Infinity_SetToken("EX_SPNAME", Infinity_FetchString(EEex_ReadDword(spellData + 0x8)))
										EEex_ApplyEffectToActor(targetID, {
["opcode"] = 139,
["target"] = 2,
["timing"] = 1,
["parameter1"] = ex_modify_spell_memory_strref_1,
["source_target"] = targetID,
["source_id"] = targetID
})
									end
--]]
								end
								if isSorcererClass then
									if sorcererSpellsFound[resref] > sorcererSpellMax then
										sorcererSpellMax = sorcererSpellsFound[resref]
									end
								else
									numFound = numFound + 1
								end
							end
						end
					end
				end
			end)
		end
		numFound = numFound + sorcererSpellMax
	end
end

--[[
To use the EXMODSMP function, create an opcode 402 effect in an item or spell, set the resource to EXMODSMP (all capitals),
 set the timing to instant, limited and the duration to 0, and choose parameters.
For an example of this function in use, look at EXAMPLE4.SPL.

The EXMODSMP function modifies the search map of the current area. The search map determines which parts of an area block
 movement, which parts can or can't be seen through, and the footstep sounds characters make when they walk on part of
 the area. The EXMODSMP function lets you replace one kind of terrain with another. For example, you could replace all
 walls in the area with see-through walls.

parameter1 - The radius of the effect. Only terrain within parameter1 range of the target point will be modified. The scale
 is the same as in .PRO files (i.e. a radius of 256 is 15 feet, like the radius of a fireball). If parameter1 is set to -1,
 then the radius is unlimited, affecting all terrain in the area.

parameter2 - The type of terrain to transform into. It should be between 0 and 15. Here are the types of terrain, taken from
 the IESDP Index (https://gibberlings3.github.io/iesdp/appendices/search.htm):
0 - Obstacle - impassable, light blocking
1 - Sand ?
2 - Wood
3 - Wood
4 - Stone - echo-ey
5 - Grass - soft
6 - Water - passable
7 - Stone - hard
8 - Obstacle - impassable, non light blocking
9 - Wood
10 - Wall - impassable
11 - Water - passable
12 - Water - impassable
13 - Roof - impassable
14 - Worldmap exit
15 - Grass

savingthrow - Bits 16 to 31 determine the types of terrain affected by the transformation. For each terrain in the list above,
 add 16 to the number there and you get the bit for that type of terrain. So impassable water is bit 28, for example.

If you'd like to make it so all walls in the area can be seen through, set parameter1 to -1, parameter2 to 8, and check bit 16
 of savingthrow.
--]]
function EXMODSMP(effectData, creatureData)
	local targetID = EEex_ReadDword(creatureData + 0x34)
	local range = EEex_ReadDword(effectData + 0x18)
	local newColor = EEex_ReadDword(effectData + 0x1C)
	local matchingColors = EEex_ReadWord(effectData + 0x3E, 0x0)
	local targetX = EEex_ReadDword(effectData + 0x84)
	local targetY = EEex_ReadDword(effectData + 0x88)
	local areaRes = EEex_GetActorAreaRes(targetID)
	if areaRes == "" then return end
	local areaX, areaY = EEex_GetActorAreaSize(targetID)
	local bitmapData = EEex_DemandResData(areaRes .. "SR", "BMP")
	local fileSize = EEex_ReadDword(bitmapData + 0x2)
	local dataOffset = EEex_ReadDword(bitmapData + 0xA)
	local bitmapX = EEex_ReadDword(bitmapData + 0x12)
	local bitmapY = EEex_ReadDword(bitmapData + 0x16)
	local pixelSizeX = 16
	local pixelSizeY = 12
	local current = 0
	local currentA = 0
	local currentB = 0
	local currentX = 0
	local currentY = 0
	if range == -1 then
		for i = dataOffset, fileSize - 1, 1 do
			current = EEex_ReadByte(bitmapData + i, 0)
			currentA = math.floor(current / 16)
			currentB = current % 16
			if bit32.band(matchingColors, 2 ^ currentA) > 0 then
				currentA = newColor
			end
			if bit32.band(matchingColors, 2 ^ currentB) > 0 then
				currentB = newColor
			end
			EEex_WriteByte(bitmapData + i, currentA * 16 + currentB)
		end
	else
		local i = dataOffset
		for y = bitmapY - 1, 0, -1 do
			for x = 0, bitmapX - 1, 2 do
				current = EEex_ReadByte(bitmapData + i, 0)
				currentX = math.floor((x + .5) * pixelSizeX)
				currentY = math.floor((y + .5) * pixelSizeY)
				currentA = math.floor(current / 16)
				if EEex_GetDistance(currentX, currentY, targetX, targetY) < range and bit32.band(matchingColors, 2 ^ currentA) > 0 then
					currentA = newColor
				end
				if x < bitmapX - 1 then
					currentX = math.floor((x + 1.5) * pixelSizeX)
					currentB = current % 16
					if EEex_GetDistance(currentX, currentY, targetX, targetY) < range and bit32.band(matchingColors, 2 ^ currentB) > 0 then
						currentB = newColor
					end
				end
				EEex_WriteByte(bitmapData + i, currentA * 16 + currentB)
				i = i + 1
			end
		end
	end
end

--[[
The EXSPLATK function performs a spell attack roll against the target. If the attack hits, it casts a spell on the target.

parameter1 - Modifies the attack roll; when parameter1 is higher, the attack is more accurate.

parameter2 - Specifies a stat that also modifies the attack roll (parameter2 should be equal to 0 (no stat), 36 (Strength),
 38 (Intelligence), 39 (Wisdom), 40 (Dexterity), 41 (Constitution), or 42 (Charisma)). If parameter2 is equal to 36, it uses
 STRMOD.2DA to determine the attack bonus; for any other stat, it uses DEXMOD.2DA.

savingthrow - This function uses several extra bits on this parameter:
 Bit 16: If set, the attack roll ignores the target's base armor class (treating it as if it were 10)
 Bit 17: If set, your bonus THAC0 with melee weapons is added to the roll.
 Bit 18: If set, your bonus THAC0 with missile weapons is added to the roll, and the target's
  AC vs. missiles is subtracted from it.
 Bit 19: If set, your bonus THAC0 with fist weapons is added to the roll.
 Bit 20: If set, you are treated as having the base THAC0 of a fighter the same level as your caster level.
 Bit 21: If set, on a critical hit, the spell will be cast twice on the target.
 Bit 22: If set, feedback will be given on the attack roll.

resource3 - Resref of spell to cast if the attack hits. If this effect is not being called from an EFF file, the resref
 is instead set to the resref of the spell that called this function with a "D" added at the end.
 
--]]
ex_dexterity_thac0 = {[0] = -20, [1] = -6, [2] = -4, [3] = -3, [4] = -2, [5] = -1, [6] = 0, [7] = 0, [8] = 0, [9] = 0, [10] = 0, [11] = 0, [12] = 0, [13] = 0, [14] = 0, [15] = 0, [16] = 1, [17] = 2, [18] = 2, [19] = 3, [20] = 3, [21] = 4, [22] = 4, [23] = 4, [24] = 5, [25] = 5}
ex_strength_thac0 = {[0] = -20, [1] = -5, [2] = -3, [3] = -3, [4] = -2, [5] = -2, [6] = -1, [7] = -1, [8] = 0, [9] = 0, [10] = 0, [11] = 0, [12] = 0, [13] = 0, [14] = 0, [15] = 0, [16] = 0, [17] = 1, [18] = 1, [19] = 3, [20] = 3, [21] = 4, [22] = 4, [23] = 5, [24] = 6, [25] = 7}
function EXSPLATK(effectData, creatureData)
	local sourceID = EEex_ReadDword(effectData + 0x10C)
	local targetID = EEex_ReadDword(creatureData + 0x34)
	local savingthrow = EEex_ReadDword(effectData + 0x3C)
	local casterlvl = EEex_ReadDword(effectData + 0xC4)
	local parent_resource = EEex_ReadLString(effectData + 0x90, 8)
	local spellType = 4
	local spellData = EEex_DemandResData(parent_resource, "SPL")
	if spellData > 1000 then
		spellType = EEex_ReadWord(spellData + 0x1C, 0x0)
	end
	local roll = math.random(20)
	local baseTHAC0 = EEex_GetActorStat(sourceID, 7)
	local bonusTHAC0 = EEex_ReadDword(effectData + 0x18) + EEex_GetActorStat(sourceID, 32) + EEex_GetActorStat(sourceID, 610)
	if bit32.band(savingthrow, 0x20000) > 0 then
		bonusTHAC0 = bonusTHAC0 + EEex_GetActorStat(sourceID, 166)
	end
	if bit32.band(savingthrow, 0x40000) > 0 then
		bonusTHAC0 = bonusTHAC0 + EEex_GetActorStat(sourceID, 72)
	end
	if bit32.band(savingthrow, 0x80000) > 0 then
		bonusTHAC0 = bonusTHAC0 + EEex_GetActorStat(sourceID, 170)
	end
	if bit32.band(savingthrow, 0x100000) > 0 then
		baseTHAC0 = 21 - EEex_GetActorCasterLevel(sourceID, spellType)
	end
	local attackStat = EEex_ReadDword(effectData + 0x1C)
	if attackStat > 0 then
		local attackStatValue = EEex_GetActorStat(sourceID, attackStat)
		if attackStatValue < 0 then
			attackStatValue = 0
		elseif attackStatValue > 25 then
			attackStatValue = 25
		end
		if attackStat == 36 then
			bonusTHAC0 = bonusTHAC0 + ex_strength_thac0[attackStatValue]
			if attackStatValue == 18 then
				local exStrength = EEex_GetActorStat(sourceID, 37)
				if exStrength >= 51 then
					bonusTHAC0 = bonusTHAC0 + 1
				end
				if exStrength >= 100 then
					bonusTHAC0 = bonusTHAC0 + 1
				end
			end
		else
			bonusTHAC0 = bonusTHAC0 + ex_dexterity_thac0[attackStatValue]
		end
	end
	local criticalMissThreshold = 1
	local criticalHitThreshold = 20
	EEex_IterateActorEffects(sourceID, function(eData)
		local theopcode = EEex_ReadDword(eData + 0x10)
		local theparameter1 = EEex_ReadDword(eData + 0x1C)
		local theparameter2 = EEex_ReadDword(eData + 0x20)
		local thespecial = EEex_ReadDword(eData + 0x48)
		if theopcode == 54 and bit32.band(savingthrow, 0x100000) > 0 then
			if theparameter2 == 0 then
				baseTHAC0 = baseTHAC0 - theparameter1
			elseif theparameter2 == 1 then
				baseTHAC0 = theparameter1
			elseif theparameter2 == 2 then
				baseTHAC0 = math.floor(baseTHAC0 * theparameter1 / 100)
			end
		elseif theopcode == 278 and theparameter2 == 0 then
			bonusTHAC0 = bonusTHAC0 + theparameter1
		elseif theopcode == 301 and theparameter2 == 0 and (thespecial == 0 or thespecial == 3 or (thespecial == 1 and bit32.band(savingthrow, 0x20000) > 0) or (thespecial == 2 and bit32.band(savingthrow, 0x40000) > 0)) then
			criticalHitThreshold = criticalHitThreshold - theparameter1
		elseif theopcode == 362 and theparameter2 == 0 and (thespecial == 0 or thespecial == 3 or (thespecial == 1 and bit32.band(savingthrow, 0x20000) > 0) or (thespecial == 2 and bit32.band(savingthrow, 0x40000) > 0)) then
			criticalMissThreshold = criticalMissThreshold + theparameter1
		end
	end)
	local targetAC = EEex_GetActorStat(targetID, 2)
	if bit32.band(savingthrow, 0x10000) > 0 then
		local baseAC = EEex_ReadSignedWord(creatureData + 0x45C, 0x0)
		EEex_IterateActorEffects(targetID, function(eData)
			local theopcode = EEex_ReadDword(eData + 0x10)
			local theparameter1 = EEex_ReadDword(eData + 0x1C)
			local theparameter2 = EEex_ReadDword(eData + 0x20)
			if theopcode == 0 and theparameter1 < baseAC and theparameter2 == 0x10 then
				baseAC = theparameter1
			end
		end)
		targetAC = targetAC + 10 - baseAC
	end
	bonusTHAC0 = bonusTHAC0 - EEex_GetActorStat(targetID, 611)
	if bit32.band(savingthrow, 0x40000) > 0 then
		bonusTHAC0 = bonusTHAC0 + EEex_GetActorStat(targetID, 4)
	end
	local attackFeedback = ex_spell_attack_feedback_string_1 .. roll
	if bonusTHAC0 >= 0 then
		attackFeedback = attackFeedback .. " + " .. bonusTHAC0 .. " = " .. (roll + bonusTHAC0) .. " : "
	else
		attackFeedback = attackFeedback .. " - " .. (bonusTHAC0 * -1) .. " = " .. (roll + bonusTHAC0) .. " : "
	end
	local hitType = 1
	if roll >= criticalHitThreshold then
		local criticalHitAverted = false
		EEex_IterateActorEffects(targetID, function(eData)
			local thetiming = EEex_ReadDword(eData + 0x24)
			
			if thetiming == 2 and not criticalHitAverted then
				local itemData = EEex_DemandResData(EEex_ReadLString(eData + 0x94, 8), "ITM")
				if itemData > 1000 then
					local itemType = EEex_ReadWord(itemData + 0x1C, 0x0)
					local criticalHitBit = (bit32.band(EEex_ReadDword(itemData + 0x18), 0x2000000) > 0)
					if itemType == 7 or itemType == 72 then
						if not criticalHitBit then
							criticalHitAverted = true
						end
					else
						if criticalHitBit then
							criticalHitAverted = true
						end
					end
				end
			end
		end)
		if criticalHitAverted then
			hitType = 2
			attackFeedback = attackFeedback .. ex_spell_attack_feedback_string_2
			EEex_ApplyEffectToActor(sourceID, {
["opcode"] = 139,
["target"] = 2,
["timing"] = 1,
["parameter1"] = 20696,
["source_id"] = sourceID
})
		else
			hitType = 3
			attackFeedback = attackFeedback .. ex_spell_attack_feedback_string_4
		end
	elseif roll <= criticalMissThreshold then
		hitType = 0
		attackFeedback = attackFeedback .. ex_spell_attack_feedback_string_5
	elseif baseTHAC0 - bonusTHAC0 - roll <= targetAC then
		hitType = 2
		attackFeedback = attackFeedback .. ex_spell_attack_feedback_string_2
	else
		attackFeedback = attackFeedback .. ex_spell_attack_feedback_string_3
	end
	if bit32.band(savingthrow, 0x400000) > 0 then
		Infinity_SetToken("EX_SPLATK", attackFeedback)
		EEex_ApplyEffectToActor(sourceID, {
["opcode"] = 139,
["target"] = 2,
["timing"] = 1,
["parameter1"] = ex_spell_attack_feedback_strref,
["source_id"] = sourceID
})
	end
	local targetX = EEex_ReadDword(creatureData + 0x8)
	local targetY = EEex_ReadDword(creatureData + 0xC)
	local sourceX = targetX
	local sourceY = targetY
	if hitType >= 2 then
		local spellRES = EEex_ReadLString(effectData + 0x74, 8)
		if spellRES == "" then
			spellRES = parent_resource .. "D"
		end
		if EEex_IsSprite(sourceID, true) then
			local sourceData = EEex_GetActorShare(sourceID)
			sourceX = EEex_ReadDword(sourceData + 0x8)
			sourceY = EEex_ReadDword(sourceData + 0xC)
		end
		EEex_ApplyEffectToActor(targetID, {
["opcode"] = 146,
["target"] = 2,
["timing"] = 1,
["parameter1"] = casterlvl,
["parameter2"] = 1,
["casterlvl"] = casterlvl,
["resource"] = spellRES,
["source_x"] = sourceX,
["source_y"] = sourceY,
["target_x"] = targetX,
["target_y"] = targetY,
["source_id"] = sourceID
})
		if hitType == 3 and bit32.band(savingthrow, 0x200000) > 0 then
			EEex_ApplyEffectToActor(targetID, {
["opcode"] = 146,
["target"] = 2,
["timing"] = 1,
["parameter1"] = casterlvl,
["parameter2"] = 1,
["casterlvl"] = casterlvl,
["resource"] = spellRES,
["source_x"] = sourceX,
["source_y"] = sourceY,
["target_x"] = targetX,
["target_y"] = targetY,
["source_id"] = sourceID
})
		end
	end
end

-------------------------------------------------------------
--  Functions you can use with opcode 403 (Screen Effects) --
-------------------------------------------------------------

--[[
To use the EXSTONES function, create an opcode 403 effect in a spell, set the resource to EXSTONES (all capitals), and choose parameters.
For an example of this function in use, look at EXAMPL1.SPL.

It serves like the Stoneskin opcode, except more versatile.

parameter1 - Determines how many skins there are (how many instances of damage will be blocked). If parameter1 is
 set to 32767, then the effect will block an infinite number of damage instances.

parameter2 - Determines which damage types are blocked. The number for each damage type is the same as in DAMAGES.IDS,
 with one exception: crushing damage is 0x4000. If you want to block multiple damage types, add the numbers for each
 damage type. For example, if you want the skins to block slashing, piercing, crushing, missile, and nonlethal damage,
 set parameter2 to 0x4990 (0x100 + 0x10 + 0x4000 + 0x80 + 0x800)

special - Bit flags for the effect.
Bit 0: If set, when the last skin is removed, it will remove all effects of the source spell. This way, you can
 include other effects that will last as long as there are skins remaining.
Bit 1: If set, when the last skin is removed, it will cast a spell on the creature. The spell resref is specified
 by resource2 (in an EFF file). If you aren't using this from an EFF file, then the spell resref is set to the
 resref of the source spell, with an E added at the end.
Bit 2: If set, whenever a skin is removed, it will cast a spell on the source of the damage. The spell resref is specified
 by resource3 (in an EFF file). If you aren't using this from an EFF file, then the spell resref is set to the
 resref of the source spell, with an F added at the end.

If you want to make a specific damage effect bypass the EXSTONES effect without removing a skin, set bit 20 of the
 special field in the damage effect. This can't be done with base weapon damage, unfortunately.
--]]
function EXSTONES(originatingEffectData, effectData, creatureData)
	local targetID = EEex_ReadDword(creatureData + 0x34)
	local opcode = EEex_ReadDword(effectData + 0xC)
	if opcode ~= 12 then return false end
	local special = EEex_ReadDword(effectData + 0x44)
	if bit32.band(special, 0x100000) > 0 then return false end
	local skins_left = EEex_ReadDword(originatingEffectData + 0x18)
	if skins_left <= 0 then return false end
	local types_blocked = EEex_ReadDword(originatingEffectData + 0x1C)
	local flags = EEex_ReadDword(originatingEffectData + 0x44)
	local parent_resource = EEex_ReadLString(originatingEffectData + 0x90, 8)
	local damage_type = EEex_ReadWord(effectData + 0x1E, 0x0)
	local casterlvl = EEex_ReadDword(originatingEffectData + 0xC4)
	if (damage_type == 0 and bit32.band(types_blocked, 0x4000) > 0) or (damage_type ~= 0 and bit32.band(types_blocked, damage_type) > 0) then
		if bit32.band(flags, 0x4) > 0 then
			local hit_spell = EEex_ReadLString(originatingEffectData + 0x74, 8)
			if hit_spell == "" then
				hit_spell = parent_resource .. "F"
			end
			local damagerID = EEex_ReadDword(effectData + 0x10C)
			if EEex_IsSprite(damagerID) then
				EEex_ApplyEffectToActor(damagerID, {
["opcode"] = 146,
["target"] = 2,
["timing"] = 9,
["parameter1"] = casterlvl,
["parameter2"] = 2,
["resource"] = hit_spell,
["source_target"] = damagerID,
["source_id"] = targetID
})
			end
		end
		if skins_left ~= 32767 then
			skins_left = skins_left - 1
		end
		EEex_WriteDword(originatingEffectData + 0x18, skins_left)
		if skins_left <= 0 then
			EEex_WriteDword(originatingEffectData + 0x110, 0x1)
			if bit32.band(flags, 0x1) == 0x1 then
				EEex_ApplyEffectToActor(targetID, {
["opcode"] = 321,
["target"] = 2,
["timing"] = 9,
["resource"] = parent_resource,
["source_target"] = targetID,
["source_id"] = targetID
})
			else
				EEex_WriteLString(originatingEffectData + 0x90, "EXDELETE", 8)
				EEex_ApplyEffectToActor(targetID, {
["opcode"] = 321,
["target"] = 2,
["timing"] = 9,
["resource"] = "EXDELETE",
["source_target"] = targetID,
["source_id"] = targetID
})
			end
			if bit32.band(flags, 0x2) > 0 then
				local end_spell = EEex_ReadLString(originatingEffectData + 0x6C, 8)
				if end_spell == "" then
					end_spell = parent_resource .. "E"
				end
				EEex_ApplyEffectToActor(targetID, {
["opcode"] = 146,
["target"] = 2,
["timing"] = 9,
["parameter1"] = casterlvl,
["parameter2"] = 2,
["resource"] = end_spell,
["source_target"] = targetID,
["source_id"] = targetID
})
			end
		end
		return true
	end
	return false
end




ex_damage_types = {
[0] = {22, 87, ex_crushing_damage_strref},
[1] = {17, 27, ex_acid_damage_strref},
[2] = {15, 28, ex_cold_damage_strref},
[4] = {16, 29, ex_electricity_damage_strref},
[8] = {14, 30, ex_fire_damage_strref},
[16] = {23, 88, ex_piercing_damage_strref},
[32] = {74, 173, ex_poison_damage_strref},
[64] = {73, 31, ex_magic_damage_strref},
[128] = {24, 89, ex_missile_damage_strref},
[256] = {21, 86, ex_slashing_damage_strref},
[512] = {19, 84, ex_magicfire_damage_strref},
[1024] = {20, 85, ex_magiccold_damage_strref},
[2048] = {22, 87, ex_stunning_damage_strref}
}
--[[
To use the EXDAMRED function, create an opcode 403 effect in a spell, set the resource to EXDAMRED (all capitals), and choose parameters.
For an example of this function in use, look at EXAMPL2.SPL.

It gives the creature 3e-like damage resistance, preventing the first parameter1 damage of the damage types specified by parameter2. It
 can prevent a total of parameter3 damage before the effect ends. If parameter3 is 0, then the total damage preventable is unlimited.

By default, whenever damage is prevented, it will display a string saying how much damage was prevented and how many points are left.

parameter1 - Determines how many points are subtracted from incoming damage. If parameter1 is negative, it increases
 the damage dealt.

parameter2 - Determines which damage types are blocked. The number for each damage type is the same as in DAMAGES.IDS,
 with one exception: crushing damage is 0x4000. If you want to block multiple damage types, add the numbers for each
 damage type. For example, if you want the skins to block slashing, piercing, crushing, missile, and nonlethal damage,
 set parameter2 to 0x4990 (0x100 + 0x10 + 0x4000 + 0x80 + 0x800)

parameter3 - Determines the total number of points of damage that can be prevented before the effect ends. If this value
 is 0, then there's no limit to the total damage that can be prevented. If you aren't using an EFF file, then you can
 enter this value in the third and fourth bytes of parameter2. For example, if you want the effect to prevent the first 
 4 points of slashing damage, to a total of 8 points, you'd set parameter1 to 4 and either set parameter3 to 8 or set
 parameter2 to 0x80100.

special - Bit flags for the effect.
Bit 0: If set, when the effect ends, it will remove all effects of the source spell. This way, you can
 include other effects that will last as long as there is damage resistance remaining.
Bit 1: If set, when the effect ends, it will cast a spell on the creature. The spell resref is specified
 by resource2 (in an EFF file). If you aren't using this from an EFF file, then the spell resref is set to the
 resref of the source spell, with an E added at the end.
Bit 2: If set, whenever damage is prevented, it will cast a spell on the source of the damage. The spell resref is specified
 by resource3 (in an EFF file). If you aren't using this from an EFF file, then the spell resref is set to the
 resref of the source spell, with an F added at the end.
Bit 3: If set, it will not display the feedback string whenever damage is prevented.

If you want to make a specific damage effect bypass the EXDAMRED effect without being absorbed, set bit 20 of the
 special field in the damage effect. This can't be done with base weapon damage, unfortunately.
--]]

function EXDAMRED(originatingEffectData, effectData, creatureData)
	local targetID = EEex_ReadDword(creatureData + 0x34)
	local opcode = EEex_ReadDword(effectData + 0xC)
	if opcode ~= 12 then return false end
	local special = EEex_ReadDword(effectData + 0x44)
	if bit32.band(special, 0x100000) > 0 then return false end

	local reduction = EEex_ReadSignedWord(originatingEffectData + 0x18, 0x0)
	local reduction_remaining_location = "parameter3"
	local reduction_remaining = EEex_ReadWord(originatingEffectData + 0x5C, 0x0)
	if reduction_remaining == 0 then
		local reduction_remaining_location = "parameter2"
		reduction_remaining = EEex_ReadWord(originatingEffectData + 0x1E, 0x0)
	end
	local types_blocked = EEex_ReadDword(originatingEffectData + 0x1C)
	local flags = EEex_ReadDword(originatingEffectData + 0x44)
	local parent_resource = EEex_ReadLString(originatingEffectData + 0x90, 8)
	local damage = EEex_ReadDword(effectData + 0x18)
	local damage_type = EEex_ReadWord(effectData + 0x1E, 0x0)
	local dice_number = EEex_ReadDword(effectData + 0x34)
	local dice_size = EEex_ReadDword(effectData + 0x38)
	local isBaseWeaponDamage = false
	if EEex_ReadLString(effectData + 0x90, 8) == "" then
		isBaseWeaponDamage = true
	end
	local casterlvl = EEex_ReadDword(originatingEffectData + 0xC4)
	if (damage_type == 0 and bit32.band(types_blocked, 0x4000) > 0) or (damage_type ~= 0 and bit32.band(types_blocked, damage_type) > 0) then
		if reduction_remaining > 0 then
			if reduction > 0 and reduction > reduction_remaining then
				reduction = reduction_remaining
			elseif reduction < 0 and math.abs(reduction) > reduction_remaining then
				reduction = 0 - reduction_remaining
			end
		end
		local damagerID = EEex_ReadDword(effectData + 0x10C)
		local luck = 0
		if isBaseWeaponDamage then
			luck = EEex_GetActorStat(damagerID, 32) + EEex_GetActorStat(damagerID, 145)
		elseif EEex_GetActorStat(targetID, 32) ~= 0 then
			luck = 0 - EEex_GetActorStat(targetID, 32)
		end
		if dice_size > 0 then
			for i = 1, dice_number, 1 do
				local currentRoll = math.random(dice_size)
				if luck > 0 and currentRoll <= luck then
					currentRoll = luck + 1
				elseif luck < 0 and currentRoll > (dice_size + luck) then
					currentRoll = dice_size + luck
				end
				damage = damage + currentRoll
			end
		end
		if reduction > damage then
			reduction = damage
		end
		damage = damage - reduction
		local noMoreReduction = false
		if reduction_remaining > 0 then
			reduction_remaining = reduction_remaining - math.abs(reduction)
			if reduction_remaining <= 0 then
				noMoreReduction = true
			end
		end
		EEex_WriteDword(effectData + 0x18, damage)
		EEex_WriteDword(effectData + 0x34, 0)
		EEex_WriteDword(effectData + 0x38, 0)
		if bit32.band(flags, 0x8) == 0 and reduction > 0 then
			local stringDisplay = ex_damage_reduction_feedback_string_1 .. reduction .. " " .. Infinity_FetchString(ex_damage_types[damage_type][3]) .. ex_damage_reduction_feedback_string_2
			if reduction_remaining > 0 or noMoreReduction then
				if reduction_remaining == 1 then
					stringDisplay = stringDisplay .. "; " .. reduction_remaining .. ex_damage_reduction_feedback_string_4
				else
					stringDisplay = stringDisplay .. "; " .. reduction_remaining .. ex_damage_reduction_feedback_string_3
				end
			end
			Infinity_SetToken("EX_DAMRED", stringDisplay)
			EEex_ApplyEffectToActor(targetID, {
	["opcode"] = 139,
	["target"] = 2,
	["parameter1"] = ex_damage_reduction_feedback_strref,
	["timing"] = 1,
	["source_target"] = targetID,
	["source_id"] = targetID
	})
		end
		if bit32.band(flags, 0x4) > 0 then
			local hit_spell = EEex_ReadLString(originatingEffectData + 0x74, 8)
			if hit_spell == "" then
				hit_spell = parent_resource .. "F"
			end
			
			if EEex_IsSprite(damagerID) then
				EEex_ApplyEffectToActor(damagerID, {
["opcode"] = 146,
["target"] = 2,
["timing"] = 9,
["parameter1"] = casterlvl,
["parameter2"] = 2,
["resource"] = hit_spell,
["source_target"] = damagerID,
["source_id"] = targetID
})
			end
		end
		if reduction_remaining_location == "parameter3" then
			EEex_WriteWord(originatingEffectData + 0x5C, reduction_remaining)
		elseif reduction_remaining_location == "parameter2" then
			EEex_WriteWord(originatingEffectData + 0x1A, reduction_remaining)
		end
		if noMoreReduction then
			EEex_WriteDword(originatingEffectData + 0x110, 0x1)
			if bit32.band(flags, 0x1) == 0x1 then
				EEex_ApplyEffectToActor(targetID, {
["opcode"] = 321,
["target"] = 2,
["timing"] = 9,
["resource"] = parent_resource,
["source_target"] = targetID,
["source_id"] = targetID
})
			else
				EEex_WriteLString(originatingEffectData + 0x90, "EXDELETE", 8)
				EEex_ApplyEffectToActor(targetID, {
["opcode"] = 321,
["target"] = 2,
["timing"] = 9,
["resource"] = "EXDELETE",
["source_target"] = targetID,
["source_id"] = targetID
})
			end
			if bit32.band(flags, 0x2) > 0 then
				local end_spell = EEex_ReadLString(originatingEffectData + 0x6C, 8)
				if end_spell == "" then
					end_spell = parent_resource .. "E"
				end
				EEex_ApplyEffectToActor(targetID, {
["opcode"] = 146,
["target"] = 2,
["timing"] = 9,
["parameter1"] = casterlvl,
["parameter2"] = 2,
["resource"] = end_spell,
["source_target"] = targetID,
["source_id"] = targetID
})
			end
		end
		if damage <= 0 then
			return true
		else
			return false
		end
	end
	return false
end

--[[
To use the EXSPLDEF function, create an opcode 403 effect in a spell, set the resource to EXSPLDEF (all capitals), and choose parameters.

The EXSPLDEF function works like Spell Deflection, Spell Turning or Spell Trap, except it works against area of effect spells, 
 and has a few more options.

parameter1 - Determines the lowest spell level that can be deflected (0 - 9).

parameter2 - Determines the highest spell level that can be deflected (0 - 9).

special - Determines the number of spell levels that can be deflected. If set to -1, there is no limit.

savingthrow - This function uses several extra bits on this parameter:
Bit 17: If set, once the last spell level is deflected, another spell is cast on the creature whose spell
 was deflected. The spell resref is specified by resource2 (in an EFF file). If you aren't using this from an
 EFF file, then the spell resref is set to the resref of the source spell, with an E added at the end.
Bit 18: If set, whenever a spell is deflected, another spell is cast on the creature whose spell
 was deflected. The spell resref is specified by resource3 (in an EFF file). If you aren't using this from an
 EFF file, then the spell resref is set to the resref of the source spell, with an F added at the end.
Bit 19: If set, up to special spells (rather than spell levels) are deflected.
Bit 20: If NOT set, the function will remove all effects of the spell that called EXSPLDEF once the last spell level is deflected.
Bit 21: If set, only spells with the hostile flag, or that deal damage, will be deflected.
Bit 22: If set, the function will reflect rather than deflect the spell.
Bit 23: If set, the function will absorb the spell as with Spell Trap, restoring one of the character's previously-used spells.


--]]
previous_spells_turned = {}
function EXSPLDEF(originatingEffectData, effectData, creatureData)
	local targetID = EEex_ReadDword(creatureData + 0x34)
	local opcode = EEex_ReadDword(effectData + 0xC)
	local sourceID = EEex_ReadDword(effectData + 0x10C)
	local parent_resource = EEex_ReadLString(originatingEffectData + 0x90, 8)
	local internal_flags = EEex_ReadDword(effectData + 0xC8)
	if bit32.band(internal_flags, 0x4000000) > 0 or targetID <= 0 or sourceID <= 0 or targetID == sourceID then return false end
	local savingthrow = EEex_ReadDword(originatingEffectData + 0x3C)
	local parameter1 = EEex_ReadDword(originatingEffectData + 0x18)
	local parameter2 = EEex_ReadDword(originatingEffectData + 0x1C)
	local match_spellRES = EEex_ReadLString(originatingEffectData + 0x18, 8)
	local spellRES = EEex_ReadLString(effectData + 0x90, 8)
	local theopcode = EEex_ReadDword(effectData + 0xC)
	local spellLevel = EEex_ReadDword(effectData + 0x14)
	local endSpellRES = EEex_ReadLString(effectData + 0x6C, 8)
	local repeatSpellRES = EEex_ReadLString(effectData + 0x74, 8)
	if endSpellRES == "" then
		endSpellRES = parent_resource .. "E"
	end
	if repeatSpellRES == "" then
		repeatSpellRES = parent_resource .. "F"
	end
--[[
	local spellData = 0

	if spellRES ~= "" and EEex_ReadDword(effectData + 0x8C) == 1 then
		spellData = EEex_GetSpellData(spellRES)
	end
	if spellData > 0 then
		spellLevel = EEex_ReadDword(spellData + 0x34)
		if EEex_ReadWord(spellData + 0x1C, 0x0) > 2 then
			spellLevel = 0
		end
	end
	if spellLevel == 0 and bit32.band(savingthrow, 0x10000) == 0 then return false end
--]]
	if spellLevel < parameter1 or spellLevel > parameter2 then return false end
	if bit32.band(savingthrow, 0x200000) > 0 and theopcode ~= 12 and theopcode ~= 25 and theopcode ~= 78 and bit32.band(EEex_ReadDword(effectData + 0x98), 0x400) == 0 then return false end
	local special = EEex_ReadDword(originatingEffectData + 0x44)
	local time_applied = EEex_ReadDword(effectData + 0x68)
	if previous_spells_turned["" .. targetID] == nil then
		previous_spells_turned["" .. targetID] = {}
	end
	if previous_spells_turned["" .. targetID][spellRES] == nil or math.abs(previous_spells_turned["" .. targetID][spellRES] - time_applied) > 1 then
		if special == 0 then
			return false
		elseif special ~= -1 then
			if bit32.band(savingthrow, 0x80000) == 0 and spellLevel > 0 then
				special = special - spellLevel
				if special < 0 then
					special = 0
				end
			else
				special = special - 1
			end
			EEex_WriteDword(originatingEffectData + 0x44, special)
		end
		if bit32.band(savingthrow, 0x400000) == 0 then
			EEex_ApplyEffectToActor(targetID, {
["opcode"] = 206,
["target"] = 2,
["timing"] = 10,
["duration"] = 1,
["resource"] = spellRES,
["internal_flags"] = 0x4000000,
["source_target"] = targetID,
["source_id"] = targetID
})		
		else
			EEex_ApplyEffectToActor(targetID, {
["opcode"] = 207,
["target"] = 2,
["timing"] = 10,
["duration"] = 1,
["resource"] = spellRES,
["internal_flags"] = 0x4000000,
["source_target"] = targetID,
["source_id"] = targetID
})
		end
		if bit32.band(savingthrow, 0x800000) > 0 then
			EEex_ApplyEffectToActor(targetID, {
["opcode"] = 261,
["target"] = 2,
["timing"] = 1,
["parameter1"] = spellLevel,
["parameter2"] = 0,
["internal_flags"] = 0x4000000,
["source_target"] = targetID,
["source_id"] = targetID
})		
		end
		if bit32.band(savingthrow, 0x40000) > 0 then
			EEex_ApplyEffectToActor(sourceID, {
["opcode"] = 146,
["target"] = 2,
["timing"] = 1,
["parameter1"] = EEex_ReadDword(originatingEffectData + 0xC4),
["parameter2"] = 2,
["resource"] = repeatSpellRES,
["internal_flags"] = 0x4000000,
["source_target"] = sourceID,
["source_id"] = targetID
})
		end
		if special == 0 then
			if bit32.band(savingthrow, 0x20000) > 0 then
				EEex_ApplyEffectToActor(sourceID, {
["opcode"] = 146,
["target"] = 2,
["timing"] = 1,
["parameter1"] = EEex_ReadDword(originatingEffectData + 0xC4),
["parameter2"] = 2,
["resource"] = endSpellRES,
["internal_flags"] = 0x4000000,
["source_target"] = sourceID,
["source_id"] = targetID
})
			end
			if bit32.band(savingthrow, 0x100000) == 0 then
			EEex_ApplyEffectToActor(targetID, {
["opcode"] = 321,
["target"] = 2,
["timing"] = 6,
["duration"] = EEex_GetGameTick() + 1,
["resource"] = parent_resource,
["internal_flags"] = 0x4000000,
["source_target"] = targetID,
["source_id"] = targetID
})
			end
		end
	end
	previous_spells_turned["" .. targetID][spellRES] = time_applied
	return false
end

-----------------------------------------------------------------
--  Functions you can use with opcode 408 (Projectile Mutator) --
-----------------------------------------------------------------
--[[
To use the EXMODAOE function, create an opcode 408 effect in a spell or item, set the resource to EXMODAOE (all capitals), and choose parameters.

The EXMODAOE function increases the area of effect of your spells.

parameter1 - The area of effect is increased by parameter1 percent (e.g. if parameter1 is 100, the area of effect
 will be doubled).

special - Determines the number of spells that will be affected (e.g. if special is 1, only the next spell you cast
 will have its AoE modified; spells after that won't). If set to -1, there is no limit.
--]]
EXMODAOE = {
    ["typeMutator"] = function(source, originatingEffectData, creatureData, projectileType)

    end,
    ["projectileMutator"] = function(source, originatingEffectData, creatureData, projectileData)
    	local parameter1 = EEex_ReadDword(originatingEffectData + 0x18)
    	local special = EEex_ReadDword(originatingEffectData + 0x44)
    	if special ~= 0 and EEex_IsProjectileOfType(projectileData, EEex_ProjectileType.CProjectileArea) then
			local trapSize = EEex_ReadWord(projectileData + 0x2A6, 0x0)
			trapSize = trapSize + math.floor(trapSize * parameter1 / 100)
			if trapSize < 0 then
				trapSize = 0
			elseif trapSize > 32767 then
				trapSize = 32767
			end
			EEex_WriteWord(projectileData + 0x2A6, trapSize)
			local explosionSize = EEex_ReadWord(projectileData + 0x2A4, 0x0)
			explosionSize = explosionSize + math.floor(explosionSize * parameter1 / 100)
			if explosionSize < 0 then
				explosionSize = 0
			elseif explosionSize > 32767 then
				explosionSize = 32767
			end
			EEex_WriteWord(projectileData + 0x2A4, explosionSize)
			if special > 0 and source ~= EEex_ProjectileHookSource.UPDATE_AOE then
				special = special - 1
				EEex_WriteDword(originatingEffectData + 0x44, special)
			end
		end
	end,
    ["effectMutator"] = function(source, originatingEffectData, creatureData, projectileData, effectData)

    end,
}

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

	-- SIGNATURE:
	-- <void> = EEex_WriteString(number address, string toWrite)
	EEex_WriteAssemblyFunction("EEex_WriteString", {[[

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

	-- Writes a string to the given address, padding any remaining space with null bytes to achieve desired length.
	-- If #toWrite >= to maxLength, terminating null is not written.
	-- If #toWrite > maxLength, characters after [1, maxLength] are discarded and not written.

	-- SIGNATURE:
	-- <void> = EEex_WriteLString(number address, string toWrite, number maxLength)
	EEex_WriteAssemblyFunction("EEex_WriteLString", {[[

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

	EEex_DisableCodeProtection()

	-- *** Prevent D3D from lowering FPU precision ***
	-- Sets D3DCREATE_FPU_PRESERVE flag, see here:
	-- docs.microsoft.com/en-us/windows/win32/direct3d9/d3dcreate
	EEex_WriteByte(EEex_Label("DrawInit_DX()_FixFPU1"), 0x42)
	EEex_WriteByte(EEex_Label("DrawInit_DX()_FixFPU2"), 0x22)

	EEex_EnableCodeProtection()

	local debugHookName = "EEex_ReadDwordDebug"
	local debugHookAddress = EEex_Malloc(#debugHookName + 1, 99)
	EEex_WriteString(debugHookAddress, debugHookName)

	-- Reads a dword at the given address. What more is there to say.

	-- SIGNATURE:
	-- number result = EEex_ReadDword(number address)
	EEex_WriteAssemblyFunction("EEex_ReadDword", {[[

		!push_ebp
		!mov_ebp_esp
		!push_ebx
		!push_ecx
		!push_edx
		!push_esi
		!push_edi

		!push_byte 00
		!push_byte 01
		!push_[ebp+byte] 08
		!call >_lua_tonumberx
		!add_esp_byte 0C

		!call >__ftol2_sse ; Put address from _lua_tonumberx in eax ;
		!push_[eax] ; Store read value on stack ;
		!push_eax ; Store address on stack ;

		!push_dword ]], {debugHookAddress, 4}, [[
		!push_[ebp+byte] 08
		!call >_lua_getglobal
		!add_esp_byte 08

		; Push address ;
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[ebp+byte] 08
		!call >_lua_pushnumber
		!add_esp_byte 0C

		; Push copy of read value ;
		!push_[esp]
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[ebp+byte] 08
		!call >_lua_pushnumber
		!add_esp_byte 0C

		; Call EEex_ReadDwordDebug ;
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 00
		!push_byte 02
		!push_[ebp+byte] 08
		!call >_lua_pcallk
		!add_esp_byte 18

		; Return read value ;
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_[ebp+byte] 08
		!call >_lua_pushnumber
		!add_esp_byte 0C

		!mov_eax #1
		!pop_edi
		!pop_esi
		!pop_edx
		!pop_ecx
		!pop_ebx
		!pop_ebp
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
		!call >CString::CString(CString_const_&)
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

	--------------------
	--  Version Hook  --
	--------------------

	EEex_DisableCodeProtection()

	local newVersionString = "(EEex) v%d.%d.%d.%d"
	local newVersionStringAddress = EEex_Malloc(#newVersionString + 1, 100)
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

		if EEex_LeakDetectionMode then
			Infinity_DoFile("EEexL") -- Leak Detection
		end

		Infinity_DoFile("EEex_Gen") -- General Code
		Infinity_DoFile("EEex_Lua") -- Lua Hooks
		Infinity_DoFile("EEex_Cre") -- Creature Structure Expansion
		Infinity_DoFile("EEex_Act") -- New Actions (EEex_Lua)
		Infinity_DoFile("EEex_Tri") -- New Triggers / Trigger Changes
		Infinity_DoFile("EEex_Obj") -- New Script Objects
		Infinity_DoFile("EEex_AHo") -- Actions Hook
		Infinity_DoFile("EEex_Bar") -- Actionbar Hook
		Infinity_DoFile("EEex_Brd") -- Bard Thieving Hook
		Infinity_DoFile("EEex_Key") -- keyPressed / keyReleased Hook
		Infinity_DoFile("EEex_Tip") -- isTooltipDisabled Hook
		Infinity_DoFile("EEex_Ren") -- Render Hook
		Infinity_DoFile("EEex_Opc") -- New Opcodes / Opcode Changes
		Infinity_DoFile("EEex_Tra") -- Trap + Container + Door targeting/opcode expansion
		Infinity_DoFile("EEex_Pro") -- Projectile Hooks
		Infinity_DoFile("EEex_Fix") -- Engine Related Bug Fixes
		Infinity_DoFile("EEex_Spl")
		--Infinity_DoFile("EEex_Pau") -- Auto-Pause Related Things
		Infinity_DoFile("EEex_Msc")

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
