
-- Holds a pointer to the memory reserved by the loader's EEex_Init().
-- Initial memory is used to hold vital EEex assembly functions,
-- which are required to allocate, write, and execute assembly from Lua.
EEex_InitialMemory = nil

EEex_OnceTable = {}
EEex_GlobalAssemblyLabels = {}
EEex_GlobalAssemblyMacros = {}
EEex_CodePageAllocations = {}

----------------------
-- Memory Interface --
----------------------

EEex_MemoryManagerStructMeta = {

	["string"] = {
		["constructors"] = {
			["#default"] = function(manager, startPtr, luaString)
				EEex_WriteString(startPtr, luaString)
			end,
		},
		["size"] = function(manager, luaString)
			return #luaString + 1
		end,
	},

	["uninitialized"] = {
		["constructors"] = {},
		["size"] = function(manager, luaSize)
			return luaSize
		end,
	},
}

EEex_MemoryManager = {}
EEex_MemoryManager.__index = EEex_MemoryManager

function EEex_NewMemoryManager(structEntries)
	return EEex_MemoryManager:new(structEntries)
end

function EEex_RunWithStackManager(structEntries, func)
	EEex_MemoryManager:runWithStack(structEntries, func)
end

function EEex_MemoryManager:init(structEntries, stackModeFunc)

	local getConstructor = function(structEntry)
		return structEntry.constructor or {}
	end

	local nameToEntry = {}
	local currentOffset = 0

	for _, structEntry in ipairs(structEntries) do

		nameToEntry[structEntry.name] = structEntry
		local structMeta = EEex_MemoryManagerStructMeta[structEntry.struct]
		local size = structMeta.size
		local sizeType = type(size)

		structEntry.offset = currentOffset
		structEntry.structMeta = structMeta

		if sizeType == "function" then
			currentOffset = currentOffset + size(self, table.unpack(getConstructor(structEntry).luaArgs or {}))
		elseif sizeType == "number" then
			currentOffset = currentOffset + size
		else
			EEex_TracebackMessage("[EEex_MemoryManager] Invalid size type!")
		end
	end

	self.nameToEntry = nameToEntry

	local initMemory = function(startAddress)

		self.address = startAddress

		for _, structEntry in ipairs(structEntries) do

			local entryName = structEntry.name
			local offset = structEntry.offset
			local address = startAddress + offset
			structEntry.address = address

			local entryConstructor = getConstructor(structEntry)
			local constructor = structEntry.structMeta.constructors[entryConstructor.variant or "#default"]
			local constructorType = type(constructor)

			if constructorType == "function" then
				constructor(self, address, table.unpack(entryConstructor.luaArgs or {}))
			elseif constructorType == "table" then
				local args = entryConstructor.args or {}
				local argsToUse = {}
				for i = #args, 1, -1 do
					local arg = args[i]
					local argType = type(arg)
					if argType == "number" then
						table.insert(argsToUse, arg)
					elseif argType == "string" then
						local entry = nameToEntry[arg]
						if not entry then
							EEex_TracebackMessage("[EEex_MemoryManager] Invalid arg name!")
						end
						table.insert(argsToUse, startAddress + entry.offset)
					else
						EEex_TracebackMessage("[EEex_MemoryManager] Invalid arg type!")
					end
				end
				EEex_Call(constructor.address, argsToUse, address, constructor.popSize or 0x0)
			end
		end
	end

	if stackModeFunc then
		EEex_RunWithStack(currentOffset, function(esp)
			initMemory(esp)
			stackModeFunc(self)
			self:destruct()
		end)
	else
		initMemory(EEex_Malloc(currentOffset))
	end
end

function EEex_MemoryManager:getAddress(name)
	return self.nameToEntry[name].address
end

function EEex_MemoryManager:getAddresses()
	local nameToAddress = {}
	for name, entry in pairs(self.nameToEntry) do
		nameToAddress[name] = entry.address
	end
	return nameToAddress
end

function EEex_MemoryManager:destruct()
	for entryName, entry in pairs(self.nameToEntry) do
		local destructor = entry.structMeta.destructor
		if (not entry.noDestruct) and destructor then
			EEex_Call(destructor.address, {}, entry.address, destructor.popSize or 0x0)
		end
	end
end

function EEex_MemoryManager:free()
	self:destruct()
	EEex_Free(self.address)
end

function EEex_MemoryManager:new(structEntries)
	local o = {}
	setmetatable(o, self)
	o:init(structEntries)
	return o
end

function EEex_MemoryManager:runWithStack(structEntries, stackModeFunc)
	local o = {}
	setmetatable(o, self)
	o:init(structEntries, stackModeFunc)
end

---------------------
-- Memory Utililty --
---------------------

-- Lua wrapper for malloc().
function EEex_Malloc(size)
	return EEex_Call(EEex_Label("_malloc"), {size}, nil, 0x4)
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

-- Reads a signed 2-byte word at the given address, shifted over by 2*index bytes.
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
	local address = EEex_Malloc(#string + 1)
	EEex_WriteString(address, string)
	return address
end

-- OS:WINDOWS
function EEex_GetProcAddress(dll, proc)
	local procfunc
	EEex_RunWithStackManager({
		{ ["name"] = "dll",  ["struct"] = "string", ["constructor"] = {["luaArgs"] = {dll}  }}, 
		{ ["name"] = "proc", ["struct"] = "string", ["constructor"] = {["luaArgs"] = {proc} }}, },
		function(manager)
			local dllhandle = EEex_Call(EEex_Label("__imp__LoadLibraryA"), {manager:getAddress("dll")}, nil, 0x0)
			procfunc = EEex_Call(EEex_Label("__imp__GetProcAddress"), {manager:getAddress("proc"), dllhandle}, nil, 0x0)
		end)
	return procfunc
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

-- Logs a message to the console window, prepending the message with the calling function's name.
function EEex_FunctionLog(message)
	local name = debug.getinfo(2, "n").name
	if name == nil then name = "(Unknown)" end
	print("[EEex] "..name..": "..message)
end

-- Throws a Lua error, appending the current stacktrace to the end of the message.
function EEex_Error(message)
	error(debug.traceback(message))
end

function EEex_TracebackPrint(message, levelMod)
	print(debug.traceback("["..EEex_GetMilliseconds().."] "..message, 2 + (levelMod or 0)))
end

function EEex_TracebackMessage(message, levelMod)
	local message = debug.traceback("["..EEex_GetMilliseconds().."] "..message, 2 + (levelMod or 0))
	print(message)
	EEex_MessageBox(message)
end

-- Dumps the contents of the Lua stack to the console window. For debugging.
function EEex_DumpLuaStack()
	EEex_FunctionLog("Lua Stack =>")
	local lua_State = EEex_Label("_g_lua")
	local top = EEex_Call(EEex_Label("_lua_gettop"), {lua_State}, nil, 0x4)
	for i = 1, top, 1 do
		local t = EEex_Call(EEex_Label("_lua_type"), {i, lua_State}, nil, 0x8)
		if t == 0 then
			EEex_FunctionLog("    nil")
		elseif t == 1 then
			local boolean = EEex_Call(EEex_Label("_lua_toboolean"), {i, lua_State}, nil, 0x8)
			EEex_FunctionLog("    boolean: "..boolean)
		elseif t == 3 then
			local number = EEex_Call(EEex_Label("_lua_tonumber"), {i, lua_State}, nil, 0x8)
			EEex_FunctionLog("    number: "..EEex_ToHex(number))
		elseif t == 4 then
			local string = EEex_Call(EEex_Label("_lua_tolstring"), {0x0, i, lua_State}, nil, 0x8)
			EEex_FunctionLog("    string: "..EEex_ReadString(string))
		else
			local typeName = EEex_Call(EEex_Label("_lua_typename"), {i, lua_State}, nil, 0x8)
			EEex_FunctionLog("    type: "..t..", typeName: "..EEex_ReadString(typeName))
		end
	end
end

-- Dumps the contents of dynamically allocated EEex code to the console window. For debugging.
function EEex_DumpDynamicCode()
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
end

-- OS:WINDOWS
-- Displays a message box to the user. Note: Suspends game until closed, which can be useful for debugging.
function EEex_MessageBox(message, iconOverride)
	EEex_RunWithStackManager({
		{ ["name"] = "caption", ["struct"] = "string", ["constructor"] = {["luaArgs"] = {"EEex"}  }}, 
		{ ["name"] = "message", ["struct"] = "string", ["constructor"] = {["luaArgs"] = {message} }}, },
		function(manager)
			EEex_DllCall("User32", "MessageBoxA", {
				EEex_Flags({iconOverride or 0x40}),
				manager:getAddress("caption"),
				manager:getAddress("message"),
				0x0
			}, nil, 0x0)
		end)
end

--------------------
-- Random Utility --
--------------------

function EEex_Once(key, func)
	if not EEex_OnceTable[key] then
		EEex_OnceTable[key] = true
		func()
	end
end

function EEex_Default(defaultVal, val)
	return val ~= nil and val or defaultVal
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

-- Flattens given table so that any nested tables are merged.
-- Example: {"Hello", {"World"}} becomes {"Hello", "World"}.
function EEex_FlattenTable(table)
	local toReturn = {}
	local insertionIndex = 1
	for i = 1, #table do
		local element = table[i]
		if type(element) == "table" then
			for j = 1, #element do
				toReturn[insertionIndex] = element[j]
				insertionIndex = insertionIndex + 1
			end
		else
			toReturn[insertionIndex] = element
			insertionIndex = insertionIndex + 1
		end
	end
	return toReturn
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

function EEex_Split(text, splitBy, usePattern, allowEmptyCapture)

	local toReturn = {}
	local matchedPatterns = {}

	local plain = usePattern == nil or not usePattern
	local insertionIndex = 1
	local captureStart = 1
	local foundStart, foundEnd = text:find(splitBy, 1, plain)

	while foundStart do
		if allowEmptyCapture or (foundStart > captureStart) then
			toReturn[insertionIndex] = text:sub(captureStart, foundStart - 1)
			matchedPatterns[insertionIndex] = text:sub(foundStart, foundEnd)
			insertionIndex = insertionIndex + 1
		end
		captureStart = foundEnd + 1
		foundStart, foundEnd = text:find(splitBy, captureStart, plain)
	end

	local limit = #text
	if captureStart <= limit then
		toReturn[insertionIndex] = text:sub(captureStart, limit)
	end

	return toReturn, matchedPatterns
end

function EEex_SplitByWhitespaceProcess(text, func)

	text = text:gsub("%s+", " ")
	local limit = #text
	local captureStart = (limit > 0 and text:sub(1, 1) == " ") and 2 or 1

	for i = captureStart + 1, limit do
		if text:sub(i, i) == " " then
			func(text:sub(captureStart, i - 1))
			captureStart = i + 1
		end
	end

	if captureStart <= limit then
		func(text:sub(captureStart, limit))
	end
end

function EEex_ExpandToBytes(num, length)
	local toReturn = {}
	for i = 1, length do
		toReturn[i] = bit32.band(num, 0xFF)
		num = bit32.rshift(num, 8)
	end
	return table.unpack(toReturn)
end

function EEex_ProcessNumberAsBytes(num, length, func)
	for i = 1, length do
		func(bit32.band(num, 0xFF), i)
		num = bit32.rshift(num, 8)
	end
end

EEex_WriteType = {
	["BYTE"]   = 0,
	["WORD"]   = 1,
	["DWORD"]  = 2,
	["RESREF"] = 3,
}

EEex_WriteFailType = {
	["ERROR"]   = 0,
	["DEFAULT"] = 1,
	["NOTHING"] = 2,
}

function EEex_WriteArgs(address, args, writeDefs)
	writeTypeFunc = {
		[EEex_WriteType.BYTE]   = EEex_WriteByte,
		[EEex_WriteType.WORD]   = EEex_WriteWord,
		[EEex_WriteType.DWORD]  = EEex_WriteDword,
		[EEex_WriteType.RESREF] = function(address, arg) EEex_WriteLString(address, arg, 0x8) end,
	}
	for _, writeDef in ipairs(writeDefs) do
		local argKey = writeDef[1]
		local arg = args[argKey]
		local skipWrite = false
		if not arg then
			local failType = writeDef[4]
			if failType == EEex_WriteFailType.DEFAULT then
				arg = writeDef[5]
			elseif failType == EEex_WriteFailType.ERROR then
				EEex_Error(argKey.." must be defined!")
			else
				skipWrite = true
			end
		end
		if not skipWrite then
			writeTypeFunc[writeDef[3]](address + writeDef[2], arg)
		end
	end
end

---------------
-- EEex_Dump --
---------------

function EEex_AlphanumericSortEntries(o)
	local function conv(s)
		local res, dot = "", ""
		for n, m, c in tostring(s):gmatch"(0*(%d*))(.?)" do
			if n == "" then
				dot, c = "", dot..c
			else
				res = res..(dot == "" and ("%03d%s"):format(#m, m) or "."..n)
				dot, c = c:match"(%.?)(.*)"
			end
			res = res..c:gsub(".", "\0%0")
		end
		return res
	end
	table.sort(o,
		function (a, b)
			local ca, cb = conv(a.string), conv(b.string)
			return ca < cb or ca == cb and a.string < b.string
		end)
	return o
end

function EEex_FillDumpLevel(tableName, levelTable, levelToFill, levelTableKey)
	local tableKey, tableValue = next(levelTable, levelTableKey)
	while tableValue ~= nil do
		local tableValueType = type(tableValue)
		if tableValueType == 'string' or tableValueType == 'number' or tableValueType == 'boolean' then
			local entry = {}
			entry.string = tableValueType..' '..tableKey..' = '
			entry.value = tableValue
			table.insert(levelToFill, entry)
		elseif tableValueType == 'table' then
			if tableKey ~= '_G' then
				local entry = {}
				entry.string = tableValueType..' '..tableKey..':'
				entry.value = {} --entry.value is a levelToFill
				entry.value.previous = {}
				entry.value.previous.tableName = tableName
				entry.value.previous.levelTable = levelTable
				entry.value.previous.levelToFill = levelToFill
				entry.value.previous.levelTableKey = tableKey
				table.insert(levelToFill, entry)
				return EEex_FillDumpLevel(tableKey, tableValue, entry.value)
			end
		elseif tableValueType == 'userdata' then
			local metatable = getmetatable(tableValue)
			local entry = {}
			if metatable ~= nil then
				entry.string = tableValueType..' '..tableKey..':\n'
				entry.value = {} --entry.value is a levelToFill
				entry.value.previous = {}
				entry.value.previous.tableName = tableName
				entry.value.previous.levelTable = levelTable
				entry.value.previous.levelToFill = levelToFill
				entry.value.previous.levelTableKey = tableKey
				table.insert(levelToFill, entry)
				return EEex_FillDumpLevel(tableKey, metatable, entry.value)
			else
				entry.string = tableValueType..' '..tableKey..' = '
				entry.value = 'nil'
				table.insert(levelToFill, entry)
			end
		else
			local entry = {}
			entry.string = tableValueType..' '..tableKey
			entry.value = nil
			table.insert(levelToFill, entry)
		end
		--Iteration
		tableKey, tableValue = next(levelTable, tableKey)
		--Iteration
	end
	--Sort the now finished level
	EEex_AlphanumericSortEntries(levelToFill)
	--Sort the now finished level
	local previous = levelToFill.previous
	if previous ~= nil then
		--Clear out "previous" metadata, as it is no longer needed.
		local previousTableName = previous.tableName
		local previousLevelTable = previous.levelTable
		local previousLevelToFill = previous.levelToFill
		local previousLevelTableKey = previous.levelTableKey
		levelToFill.previous = nil
		--Clear out "previous" metadata, as it is no longer needed.
		return EEex_FillDumpLevel(previousTableName, previousLevelTable,
								  previousLevelToFill, previousLevelTableKey)
	else
		return levelToFill
	end
end

EEex_DumpFunction = print

function EEex_PrintEntries(entriesTable, indentLevel, indentStrings, previousState, levelTableKey)
	local tableEntryKey, tableEntry = next(entriesTable, levelTableKey)
	while(tableEntry ~= nil) do
		local tableEntryString = tableEntry.string
		local tableEntryValue = tableEntry.value
		local indentString = indentStrings[indentLevel]
		if tableEntryValue ~= nil then
			if type(tableEntryValue) ~= 'table' then
				local valueToPrint = string.gsub(tostring(tableEntryValue), '\n', '\\n')
				EEex_DumpFunction(indentString..tableEntryString..valueToPrint)
			else
				EEex_DumpFunction(indentString..tableEntryString)
				EEex_DumpFunction(indentString..'{')
				local previous = {}
				previous.entriesTable = entriesTable
				previous.indentLevel = indentLevel
				previous.levelTableKey = tableEntryKey
				previous.previousState = previousState
				indentLevel = indentLevel + 1
				local indentStringsSize = #indentStrings
				if indentLevel > indentStringsSize then
					indentStrings[indentStringsSize + 1] = indentStrings[indentStringsSize]..'	'
				end
				return EEex_PrintEntries(tableEntryValue, indentLevel, indentStrings, previous)
			end
		else
			EEex_DumpFunction(indentString..tableEntryString)
		end
		--Increment
		tableEntryKey, tableEntry = next(entriesTable, tableEntryKey)
		--Increment
	end
	EEex_DumpFunction(indentStrings[indentLevel - 1]..'}')
	--Finish previous levels
	if previousState ~= nil then
		return EEex_PrintEntries(previousState.entriesTable, previousState.indentLevel, indentStrings,
								 previousState.previousState, previousState.levelTableKey)
	end
end

function EEex_Dump(key, valueToDump)
	local valueToDumpType = type(valueToDump)
	if valueToDumpType == 'string' or valueToDumpType == 'number' or valueToDumpType == 'boolean' then
		EEex_DumpFunction(valueToDumpType..' '..key..' = '..tostring(valueToDump))
	elseif valueToDumpType == 'table' then
		EEex_DumpFunction(valueToDumpType..' '..key..':')
		EEex_DumpFunction('{')
		local entries = EEex_FillDumpLevel(key, valueToDump, {})
		EEex_PrintEntries(entries, 1, {[0] = '', [1] = '	'})
	elseif valueToDumpType == 'userdata' then
		local metatable = getmetatable(valueToDump)
		if metatable ~= nil then
			EEex_DumpFunction(valueToDumpType..' '..key..':')
			EEex_DumpFunction('{')
			local entries = EEex_FillDumpLevel(key, metatable, {})
			EEex_PrintEntries(entries, 1, {[0] = '', [1] = '	'})
		else
			EEex_DumpFunction(valueToDumpType..' '..key..' = nil')
		end
	else
		EEex_DumpFunction(valueToDumpType..' '..key)
	end
end

----------------------
-- Assembly Writing --
----------------------

function EEex_DefineAssemblyLabel(label, value)
	EEex_GlobalAssemblyLabels[label] = value
end

function EEex_LabelDefault(label, default)
	return EEex_GlobalAssemblyLabels[label] or default
end

function EEex_Label(label)
	local value = EEex_GlobalAssemblyLabels[label]
	if not value then
		EEex_Error("Label @"..label.." is not defined in the global scope!")
	end
	return EEex_GlobalAssemblyLabels[label]
end

function EEex_DefineAssemblyMacro(macroName, macroValue)
	EEex_GlobalAssemblyMacros[macroName] = macroValue
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

function EEex_WriteAssembly(address, assembly)
	EEex_WriteSanitizedAssembly(address, EEex_SanitizeAssembly(assembly))
end

function EEex_CollectSanitizedMacroName(section, hasPrefix)
	local macroArgsStart = section:find("(", 1, true)
	local macroName = section:sub(hasPrefix and 2 or 1, macroArgsStart and (macroArgsStart - 1) or #section)
	return macroName, macroArgsStart
end

function EEex_CollectSanitizedMacroArgs(section, macroArgsStart)
	macroArgsStart = macroArgsStart or section:find("(", 1, true)
	local macroArgsEnd = section:find(")", 1, true)
	return EEex_Split(section:sub(macroArgsStart + 1, macroArgsEnd - 1), ",")
end

function EEex_GetSanitizedMacroLength(state, address, section)
	local macroName, macroArgsStart = EEex_CollectSanitizedMacroName(section, false)
	local lengthVal = EEex_GlobalAssemblyMacros[macroName].length
	local lengthType = type(lengthVal)
	if lengthType == "function" then
		local args = EEex_CollectSanitizedMacroArgs(section, macroArgsStart)
		return lengthVal(state, address, args)
	elseif lengthType == "number" then
		return lengthVal
	else
		return 0
	end
end

function EEex_SanitizeAssembly(assembly)

	local state = {
		["sanitizedStructure"] = {},
		["seenLabelAddresses"] = {},
		["firstUnexploredSection"] = {
			["address"] = 0,
			["index"] = 0,
			["inComment"] = false,
		},
		["unroll"] = {
			["forceIgnore"] = false,
		},
		["write"] = {},
	}

	local sanitizedStructure = state.sanitizedStructure

	local unrollTextArg
	unrollTextArg = function(arg, nextArg)

		EEex_SplitByWhitespaceProcess(arg, function(section)

			if section:sub(1, 1) == "!" then

				local macroName = section:sub(2)
				local macroArgsStart = section:find("(", 1, true)
				if macroArgsStart then macroName = section:sub(2, macroArgsStart - 1) end

				local macro = EEex_GlobalAssemblyMacros[macroName]
				if not macro then
					EEex_Error("Macro \""..macroName.."\" not defined in the current scope!")
				end

				local macroType = type(macro)
				if macroType == "string" then
					-- Return is for tail call, not for returning a value
					return unrollTextArg(macro)
				elseif macroType == "table" then

					local addMacroTextToStructure = true
					local unrollFunc = macro.unroll

					if unrollFunc then

						local args
						if macroArgsStart then

							local macroArgsEnd = section:find(")", 1, true)
							if not macroArgsEnd then
								EEex_Error("No closing parentheses for macro function \""..macroName.."\"!")
							elseif macroArgsEnd ~= #section then
								EEex_Error("Invalid closing parentheses for macro function \""..macroName.."\"!")
							end

							args = EEex_Split(section:sub(macroArgsStart + 1, macroArgsEnd - 1), ",")
							for i = 1, #args do
								local funcArg = args[i]
								if funcArg:sub(1, 1) == "$" then
									if type(nextArg) ~= "table" then EEex_Error("Invalid variable-arg") end
									local varArgIndex = tonumber(funcArg:sub(2))
									if (not varArgIndex) or #nextArg < varArgIndex then EEex_Error("Invalid variable-arg") end
									args[i] = nextArg[varArgIndex]
									nextArg.skipVarArg = true
								end
							end
						else
							args = {}
						end

						local unrollResult = unrollFunc(state, args)
						if unrollResult then

							addMacroTextToStructure = false
							local unrollResultType = type(unrollResult)

							if unrollResultType == "string" then
								return unrollTextArg(unrollResult)
							elseif unrollResultType == "table" then
								for _, val in ipairs(unrollResult) do
									local valType = type(val)
									if valType == "string" then
										unrollTextArg(val)
									elseif valType == "table" then
										if not state.unroll.forceIgnore then
											table.insert(sanitizedStructure, val)
										end
									else
										EEex_Error("Invalid macro return type \""..valType.."\" for macro \""..macroName.."\"!")
									end
								end
							else
								EEex_Error("Invalid macro return type \""..macroType.."\" for macro \""..macroName.."\"!")
							end
						end
					end

					if addMacroTextToStructure then
						local lengthType = type(macro.length)
						if lengthType ~= "function" and lengthType ~= "number" and lengthType ~= "nil" then
							EEex_Error("Invalid macro length type \""..lengthType.."\" for macro \""..macroName.."\"!")
						end
						if not state.unroll.forceIgnore then
							table.insert(sanitizedStructure, section)
						end
					end
				else
					EEex_Error("Invalid macro type \""..macroType.."\" for macro \""..macroName.."\"!")
				end
			elseif not state.unroll.forceIgnore then
				table.insert(sanitizedStructure, section)
			end
		end)
	end

	local limit = #assembly
	for i = 1, limit do
		local arg = assembly[i]
		local argType = type(arg)
		if argType == "string" then
			unrollTextArg(arg, i < limit and assembly[i + 1] or nil)
		elseif argType == "table" then
			if not arg.skipVarArg then
				local argSize = #arg
				if argSize == 2 or argSize == 3 then
					local relativeFromOffset = arg[3]
					if type(arg[1]) == "number" and type(arg[2]) == "number"
						and (not relativeFromOffset or type(relativeFromOffset) == "number")
					then
						if not state.unroll.forceIgnore then
							table.insert(sanitizedStructure, arg)
						end
					else
						EEex_Error("Variable write argument included invalid data-type!")
					end
				else
					EEex_Error("Variable write argument did not have at 2-3 args!")
				end
			end
		else
			EEex_Dump("assembly", assembly)
			EEex_Error("Arg with illegal data-type in assembly declaration: \""..tostring(arg).."\" at index "..i)
		end
	end

	return state
end

function EEex_WriteSanitizedAssembly(address, state, funcOverride)

	if not funcOverride then

		-- Print a hex-dump of what is about to be written to the log
		local writeDump = ""
		EEex_WriteSanitizedAssembly(address, state, function(writeAddress, ...)
			local bytes = {...}
			for i = 1, #bytes do
				writeDump = writeDump..EEex_ToHex(bytes[i], 2, true).." "
			end
		end)
		EEex_FunctionLog("Writing Assembly at "..EEex_ToHex(address).." => "..writeDump.."\n\n")

		funcOverride = function(writeAddress, ...)
			local bytes = {...}
			for i = 1, #bytes do
				EEex_WriteByte(writeAddress, bytes[i])
				writeAddress = writeAddress + 1
			end
		end
	end

	local firstUnexploredSection = state.firstUnexploredSection
	local currentWriteAddress = address
	local inComment = false

	local prefixProcessing = {
		["!"] = function(section)
			local macroName, macroArgsStart = EEex_CollectSanitizedMacroName(section, false)
			local writeVal = EEex_GlobalAssemblyMacros[macroName].write
			if type(writeVal) == "function" then
				local args = EEex_CollectSanitizedMacroArgs(section, macroArgsStart)
				currentWriteAddress = currentWriteAddress + writeVal(state, currentWriteAddress, args, funcOverride)
			end
		end,
		[":"] = function(section)
			local targetOffset = tonumber(section, 16)
			local relativeOffsetNeeded = targetOffset - (currentWriteAddress + 4)
			for i = 0, 3, 1 do
				local byte = bit32.extract(relativeOffsetNeeded, i * 8, 8)
				funcOverride(currentWriteAddress, byte)
				currentWriteAddress = currentWriteAddress + 1
			end
		end,
		["+"] = function(section)
			local targetOffset = currentWriteAddress + 4 + tonumber(section, 16)
			for i = 0, 3, 1 do
				local byte = bit32.extract(targetOffset, i * 8, 8)
				funcOverride(currentWriteAddress, byte)
				currentWriteAddress = currentWriteAddress + 1
			end
		end,
		["#"] = function(section)
			local toWrite = tonumber(section, 16)
			for i = 0, 3, 1 do
				local byte = bit32.extract(toWrite, i * 8, 8)
				funcOverride(currentWriteAddress, byte)
				currentWriteAddress = currentWriteAddress + 1
			end
		end,
		["*"] = function(label)
			local targetOffset = EEex_CalcLabelAddress(state, label)
			if not targetOffset then
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
		end,
		[">"] = function(label)
			local targetOffset = EEex_CalcLabelAddress(state, label)
			if not targetOffset then
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
		end,
		["$"] = function(label)
			EEex_DefineAssemblyLabel(label, currentWriteAddress)
			state.seenLabelAddresses[label] = currentWriteAddress
		end,
		["@"] = function(label)
			state.seenLabelAddresses[label] = currentWriteAddress
		end,
	}

	-----------------------
	-- Process Structure --
	-----------------------

	local sanitizedStructure = state.sanitizedStructure

	-- Structure is sanitized so I can make assumptions
	for i = 1, #sanitizedStructure do

		local arg = sanitizedStructure[i]
		if type(arg) == "string" then
			local prefix = string.sub(arg, 1, 1)
			if prefix == ";" then
				inComment = not inComment
			elseif not inComment then
				local prefixFunc = prefixProcessing[prefix]
				if prefixFunc then
					prefixFunc(arg:sub(2))
				else
					local byte = tonumber(arg, 16)
					funcOverride(currentWriteAddress, byte)
					currentWriteAddress = currentWriteAddress + 1
				end
			end
		else
			local address = arg[1]
			local relativeFromOffset = arg[3]
			if relativeFromOffset then address = address - currentWriteAddress - relativeFromOffset end
			for i = 0, arg[2] - 1 do
				local byte = bit32.extract(address, i * 8, 8)
				funcOverride(currentWriteAddress, byte)
				currentWriteAddress = currentWriteAddress + 1
			end
		end

		if i > firstUnexploredSection.index then
			firstUnexploredSection.address = currentWriteAddress
			firstUnexploredSection.index = i + 1
			firstUnexploredSection.inComment = inComment
		end

	end
end

function EEex_InvalidateAssemblyState(state)
	state.seenLabelAddresses = {}
	state.firstUnexploredSection.address = 0
	state.firstUnexploredSection.index = 0
	state.firstUnexploredSection.inComment = false
end

function EEex_CalcWriteLength(state, address)

	local firstUnexploredSection = state.firstUnexploredSection
	local curAddress = address
	local inComment = false

	local prefixProcessing = {
		["!"] = function(section)
			curAddress = curAddress + EEex_GetSanitizedMacroLength(state, address, section)
		end,
		[":"] = function(section)
			curAddress = curAddress + 4
		end,
		["+"] = function(section)
			curAddress = curAddress + 4
		end,
		["#"] = function(section)
			curAddress = curAddress + 4
		end,
		["*"] = function(label)
			curAddress = curAddress + 4
		end,
		[">"] = function(label)
			curAddress = curAddress + 4
		end,
		["$"] = function(label)
			state.seenLabelAddresses[label] = curAddress
		end,
		["@"] = function(label)
			state.seenLabelAddresses[label] = curAddress
		end,
	}

	-----------------------
	-- Process Structure --
	-----------------------

	local sanitizedStructure = state.sanitizedStructure

	for i = 1, #sanitizedStructure do

		local arg = sanitizedStructure[i]
		if type(arg) == "string" then
			local prefix = string.sub(arg, 1, 1)
			if prefix == ";" then
				inComment = not inComment
			elseif not inComment then
				local prefixFunc = prefixProcessing[prefix]
				if prefixFunc then
					prefixFunc(arg:sub(2))
				else
					curAddress = curAddress + 1
				end
			end
		else
			curAddress = curAddress + arg[2]
		end

		if i > firstUnexploredSection.index then
			firstUnexploredSection.address = curAddress
			firstUnexploredSection.index = i + 1
			firstUnexploredSection.inComment = inComment
		end

	end

	return curAddress - address
end

function EEex_CalcLabelAddress(state, toFind)

	local knownAddress = state.seenLabelAddresses[toFind]
	if knownAddress then return knownAddress end

	local firstUnexploredSection = state.firstUnexploredSection
	local curAddress = firstUnexploredSection.address
	local inComment = state.firstUnexploredSection.inComment

	local prefixProcessing = {
		["!"] = function(section)
			curAddress = curAddress + EEex_GetSanitizedMacroLength(state, address, section)
		end,
		[":"] = function(section)
			curAddress = curAddress + 4
		end,
		["+"] = function(section)
			curAddress = curAddress + 4
		end,
		["#"] = function(section)
			curAddress = curAddress + 4
		end,
		["*"] = function(label)
			curAddress = curAddress + 4
		end,
		[">"] = function(label)
			curAddress = curAddress + 4
		end,
		["$"] = function(label)
			state.seenLabelAddresses[label] = curAddress
			return label == toFind
		end,
		["@"] = function(label)
			state.seenLabelAddresses[label] = curAddress
			return label == toFind
		end,
	}

	-----------------------
	-- Process Structure --
	-----------------------

	local sanitizedStructure = state.sanitizedStructure

	for i = firstUnexploredSection.index, #sanitizedStructure do

		local found = false

		local arg = sanitizedStructure[i]
		if type(arg) == "string" then
			local prefix = string.sub(arg, 1, 1)
			if prefix == ";" then
				inComment = not inComment
			elseif not inComment then
				local prefixFunc = prefixProcessing[prefix]
				if prefixFunc then
					found = prefixFunc(arg:sub(2))
				else
					curAddress = curAddress + 1
				end
			end
		else
			curAddress = curAddress + arg[2]
		end

		if i > firstUnexploredSection.index then
			firstUnexploredSection.address = curAddress
			firstUnexploredSection.index = i + 1
			firstUnexploredSection.inComment = inComment
		end

		if found then return curAddress end

	end
end

-- NOTE: Same as EEex_WriteAssembly(), but writes to a dynamically
-- allocated memory space instead of a provided address.
-- Useful for writing new executable code into memory.
function EEex_WriteAssemblyAuto(assembly)
	local state = EEex_SanitizeAssembly(assembly)
	local reservedAddress, reservedLength = EEex_ReserveCodeMemory(state)
	EEex_FunctionLog("Reserved "..EEex_ToHex(reservedLength).." bytes at "..EEex_ToHex(reservedAddress))
	EEex_WriteSanitizedAssembly(reservedAddress, state)
	return reservedAddress
end

function EEex_WriteAssemblyFunction(functionName, assembly)
	local functionAddress = EEex_WriteAssemblyAuto(assembly)
	EEex_ExposeToLua(functionAddress, functionName)
	return functionAddress
end

function EEex_HookBeforeCall(address, assembly)
	local returnAddress = address + 0x5
	EEex_DefineAssemblyLabel("return", returnAddress)
	EEex_WriteAssembly(address, {"!jmp_dword", {EEex_WriteAssemblyAuto(
		EEex_FlattenTable({
			assembly,
			{[[
				@call
				!call ]], {address + EEex_ReadDword(address + 0x1) + 0x5, 4, 4}, [[
				!jmp_dword ]], {returnAddress, 4, 4},
			},
		})
	), 4, 4}})
end

function EEex_HookAfterCall(address, assembly)
	EEex_WriteAssembly(address, {"!jmp_dword", {EEex_WriteAssemblyAuto(
		EEex_FlattenTable({
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

function EEex_HookReturnNOPs(address, nopCount, assembly)

	local afterInstruction = address + 0x5 + nopCount
	EEex_DefineAssemblyLabel("return", afterInstruction)

	local hookCode = EEex_WriteAssemblyAuto(EEex_FlattenTable({
		assembly,
		{
			"!jmp_dword", {afterInstruction, 4, 4},
		},
	}))

	local nops = {}
	local limit = nopCount
	for i = 1, limit, 1 do
		table.insert(nops, {0x90, 1})
	end

	EEex_WriteAssembly(address, EEex_FlattenTable({
		{
			"!jmp_dword", {hookCode, 4, 4}
		},
		nops,
	}))
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

	EEex_DefineAssemblyLabel("return_skip", afterInstruction)

	local hookCode = EEex_WriteAssemblyAuto(EEex_FlattenTable({
		assembly,
		"@return",
		restoreBytes,
		{[[
			!jmp_dword ]], {afterInstruction, 4, 4},
		},
	}))

	EEex_WriteAssembly(address, EEex_FlattenTable({
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

	local hookCode = EEex_WriteAssemblyAuto(EEex_FlattenTable({
		restoreBytes,
		assembly,
		"@return",
		{[[
			!jmp_dword ]], {afterInstruction, 4, 4},
		},
	}))

	EEex_WriteAssembly(address, EEex_FlattenTable({
		{
			"!jmp_dword", {hookCode, 4, 4}
		},
		nops,
	}))
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

	local hookCode = EEex_WriteAssemblyAuto(EEex_FlattenTable({
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

function EEex_HookJumpOnSuccess(address, assembly)
	local jmpFailDest = address + 6
	local jmpDest = jmpFailDest + EEex_ReadDword(address + 2)
	EEex_DefineAssemblyLabel("jmp_success", jmpDest)
	EEex_DefineAssemblyLabel("jmp_fail", jmpFailDest)
	EEex_WriteAssembly(address + 2, {{EEex_WriteAssemblyAuto(assembly), 4, 4}})
end

function EEex_HookJumpNoReturn(address, assembly)
	EEex_WriteAssembly(address, {"!jmp_dword", {EEex_WriteAssemblyAuto(assembly), 4, 4}})
end

function EEex_HookChangeCallDest(address, dest)
	EEex_WriteAssembly(address + 0x1, {{dest, 4, 4}})
end

EEex_LuaCallReturnType = {
	["Boolean"] = 0,
	["Number"] = 1,
}

function EEex_GenLuaCall(funcName, meta)

	local pushNumberTemplate = {[[
		!fild_[esp]
		!sub_esp_byte 04
		!fstp_qword:[esp]
		!push_ebx
		!call >_lua_pushnumber
		!add_esp_byte 0C
	]]}

	local returnBooleanTemplate = {[[
		!push_byte FF
		!push_ebx
		!call >_lua_toboolean
		!add_esp_byte 08
		!push_eax
	]]}

	local returnNumberTemplate = {[[
		!push_byte 00
		!push_byte FF
		!push_ebx
		!call >_lua_tonumberx
		!add_esp_byte 0C
		!call >__ftol2_sse
		!push_eax
	]]}

	local numArgs = #((meta or {}).args or {})
	local genArgPushes1 = function()

		local toReturn = {}
		local insertionIndex = 1

		if not meta then return toReturn end
		local args = meta.args
		if not args then return toReturn end

		for i = numArgs, 1, -1 do
			toReturn[insertionIndex] = args[i]
			insertionIndex = insertionIndex + 1
		end

		return EEex_FlattenTable(toReturn)
	end

	local errorFunc
	local errorFuncLuaStackPopAmount
	if (meta or {}).errorFunction then
		errorFunc = meta.errorFunction.func
		errorFuncLuaStackPopAmount = errorFunc and (1 + (meta.errorFunction.precursorAmount or 0)) or 0
	else
		errorFunc = {[[
			!push_dword ]], {EEex_WriteStringAuto("debug"), 4}, [[
			!push_ebx
			!call >_lua_getglobal
			!add_esp_byte 08

			!push_dword ]], {EEex_WriteStringAuto("traceback"), 4}, [[
			!push_byte FF
			!push_ebx
			!call >_lua_getfield
			!add_esp_byte 0C
		]]}
		errorFuncLuaStackPopAmount = 2
	end

	local genFunc = function()
		if funcName then
			if meta then
				if meta.functionChunk then EEex_Error("[EEex_GenLuaCall] funcName and meta.functionChunk are exclusive") end
				if meta.pushFunction then EEex_Error("[EEex_GenLuaCall] funcName and meta.pushFunction are exclusive") end
			end
			return {[[
				!push_dword ]], {EEex_WriteStringAuto(funcName), 4}, [[
				!push_ebx
				!call >_lua_getglobal
				!add_esp_byte 08
			]]}
		elseif meta then
			if meta.functionChunk then
				if numArgs > 0 then EEex_Error("[EEex_GenLuaCall] Lua chunks can't be passed arguments") end
				if meta.pushFunction then EEex_Error("[EEex_GenLuaCall] meta.functionChunk and meta.pushFunction are exclusive") end
				return EEex_FlattenTable({
					meta.functionChunk,
					{[[
						!push_ebx
						!call >_luaL_loadstring
						!add_esp_byte 08
						!test_eax_eax
						!jz_dword >EEex_GenLuaCall_loadstring_no_error

						!IF($1) ]], {errorFunc ~= nil}, [[
							; Call error function with loadstring message ;
							!push_byte 00
							!push_byte 00
							!push_byte 00
							!push_byte 01
							!push_byte 01
							!push_ebx
							!call >_lua_pcallk
							!add_esp_byte 18
							!push_ebx
							!call >EEex_CheckCallError
							!test_eax_eax
							!jnz_dword >EEex_GenLuaCall_error_in_error_handling
							!push_ebx
							!call >EEex_PrintPopLuaString

							@EEex_GenLuaCall_error_in_error_handling
							; Clear error function precursors off of Lua stack ;
							!push_byte ]], {-errorFuncLuaStackPopAmount, 1}, [[
							!push_ebx
							!call >_lua_settop
							!add_esp_byte 08
							!jmp_dword >call_error
						!ENDIF()

						!IF($1) ]], {errorFunc == nil}, [[
							!push_ebx
							!call >EEex_PrintPopLuaString
							!jmp_dword >call_error
						!ENDIF()

						@EEex_GenLuaCall_loadstring_no_error
					]]},
				})
			elseif meta.pushFunction then
				if meta.functionChunk then EEex_Error("[EEex_GenLuaCall] meta.pushFunction and meta.functionChunk are exclusive") end
				return meta.pushFunction
			end
		end

		EEex_Error("[EEex_GenLuaCall] meta.functionChunk or meta.pushFunction must be defined when funcName = nil")
	end

	local genArgPushes2 = function()

		local toReturn = {}
		local insertionIndex = 1

		if not meta then return toReturn end
		local args = meta.args
		if not args then return toReturn end

		for i = 1, numArgs do
			toReturn[insertionIndex] = pushNumberTemplate
			insertionIndex = insertionIndex + 1
		end

		return EEex_FlattenTable(toReturn)
	end

	local genReturnHandling = function()

		if not meta then return {} end
		local returnType = meta.returnType
		if not returnType then return {} end

		if returnType == EEex_LuaCallReturnType.Boolean then
			return returnBooleanTemplate
		elseif returnType == EEex_LuaCallReturnType.Number then
			return returnNumberTemplate
		else
			EEex_Error("[EEex_GenLuaCall] meta.returnType invalid")
		end
	end

	local numRet = (meta or {}).returnType and 1 or 0
	return EEex_FlattenTable({
		genArgPushes1(),
		(meta or {}).luaState or {[[
			!call >EEex_GetLuaState
			!mov_ebx_eax
		]]},
		errorFunc or {},
		genFunc(),
		genArgPushes2(),
		{[[
			!push_byte 00
			!push_byte 00
			!push_byte ]], {errorFunc and -(2 + numArgs) or 0, 1}, [[
			!push_byte ]], {numRet, 1}, [[
			!push_byte ]], {numArgs, 1}, [[
			!push_ebx
			!call >_lua_pcallk
			!add_esp_byte 18
			!push_ebx
			!call >EEex_CheckCallError
			!test_eax_eax

			!IF($1) ]], {errorFunc ~= nil}, [[
				!jz_dword >EEex_GenLuaCall_no_error
				; Clear error function and its precursors off of Lua stack ;
				!push_byte ]], {-(1 + errorFuncLuaStackPopAmount), 1}, [[
				!push_ebx
				!call >_lua_settop
				!add_esp_byte 08
				!jmp_dword >call_error
			!ENDIF()

			!IF($1) ]], {errorFunc == nil}, [[
				!jnz_dword >call_error
			!ENDIF()

			@EEex_GenLuaCall_no_error
		]]},
		genReturnHandling(),
		{[[
			; Clear return values and error function (+ its precursors) off of Lua stack ;
			!push_byte ]], {-(1 + errorFuncLuaStackPopAmount + numRet), 1}, [[
			!push_ebx
			!call >_lua_settop
			!add_esp_byte 08

			!IF($1) ]], {numRet > 0}, [[
				!pop_eax
			!ENDIF()
		]]},
	})
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

function EEex_ToHex(number, minLength, suppressPrefix)
	if type(number) ~= "number" then
		-- This is usually a critical error somewhere else
		-- in the code, so throw a fully fledged error.
		EEex_Error("Passed a NaN value: '"..tostring(number).."'!")
	end
	local hexString = nil
	if number < 0 then
		-- string.format can't handle "negative" numbers for some reason
		hexString = ""
		while number ~= 0x0 do
			hexString = string.format("%x", bit32.extract(number, 0, 4)):upper()..hexString
			number = bit32.rshift(number, 4)
		end
	else
		hexString = string.format("%x", number):upper()
		local wantedLength = (minLength or 0) - #hexString
		for i = 1, wantedLength, 1 do
			hexString = "0"..hexString
		end
	end
	return suppressPrefix and hexString or "0x"..hexString
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

-- OS:WINDOWS
-- NOTE: This is used internally by EEex_ReserveCodeMemory() to allocate
-- additional code pages when needed. Don't call this directly.
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

-- OS:WINDOWS
-- NOTE: Dynamically allocates and reserves executable memory for
-- new code. No reason to use instead of EEex_WriteAssemblyAuto,
-- unless you want to reserve memory for later use.
function EEex_ReserveCodeMemory(state)
	local reservedAddress = -1
	local writeLength = -1
	local processCodePageEntry = function(codePage)
		for i, allocEntry in ipairs(codePage) do
			if not allocEntry.reserved then
				writeLength = EEex_CalcWriteLength(state, allocEntry.address)
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
				else
					EEex_InvalidateAssemblyState(state)
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
				Tell Bubb he should at least guess at how big the write needs to be!)")
		end
	end
	return reservedAddress, writeLength
end

-------------------------
-- !CODE MANIPULATION! --
-------------------------

-- OS:WINDOWS
-- Enables writing to the .text section of the exe (code).
function EEex_DisableCodeProtection()
	local temp = EEex_Malloc(0x4)
	-- 0x40 = PAGE_EXECUTE_READWRITE
	-- 0x401000 = Start of .text section in memory.
	-- 0x49F000 = Size of .text section in memory.
	EEex_DllCall("Kernel32", "VirtualProtect", {temp, 0x40, 0x49F000, 0x401000}, nil, 0x0)
	EEex_Free(temp)
end

-- OS:WINDOWS
-- Reverts the .text section protections back to default.
function EEex_EnableCodeProtection()
	local temp = EEex_Malloc(0x4)
	-- 0x20 = PAGE_EXECUTE_READ
	-- 0x401000 = Start of .text section in memory.
	-- 0x49F000 = Size of .text section in memory.
	EEex_DllCall("Kernel32", "VirtualProtect", {temp, 0x20, 0x49F000, 0x401000}, nil, 0x0)
	EEex_Free(temp)
end
