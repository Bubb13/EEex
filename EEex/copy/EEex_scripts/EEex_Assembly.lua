
-- This file needs to be called by both EEex_EarlyMain.lua and
-- EEex_Main.lua. This guard prevents the file from being
-- needlessly processed twice.
if EEex_Assembly_AlreadyLoaded then
	return
end
EEex_Assembly_AlreadyLoaded = true

-- LuaJIT compatibility
if not table.pack then
	table.pack = function(...)
		local t = {...}
		t.n = #t
		return t
	end
	table.unpack = unpack
end

------------------
-- Bits Utility --
------------------

function EEex_AreBitsSet(original, bitsString)
	return EEex_IsMaskSet(original, tonumber(bitsString, 2))
end

function EEex_AreBitsUnset(original, bitsString)
	return EEex_IsMaskUnset(original, tonumber(bitsString, 2))
end

function EEex_Flags(flags)
	local result = 0x0
	for _, flag in ipairs(flags) do
		result = EEex_BOr(result, flag)
	end
	return result
end

function EEex_IsBitSet(original, isSetIndex)
	return EEex_BAnd(original, EEex_LShift(0x1, isSetIndex)) ~= 0x0
end

function EEex_IsBitUnset(original, isUnsetIndex)
	return EEex_BAnd(original, EEex_LShift(0x1, isUnsetIndex)) == 0x0
end

function EEex_IsMaskSet(original, isSetMask)
	return EEex_BAnd(original, isSetMask) == isSetMask
end

function EEex_IsMaskUnset(original, isUnsetMask)
	return EEex_BAnd(original, isUnsetMask) == 0x0
end

function EEex_SetBit(original, toSetIndex)
	return EEex_BOr(original, EEex_LShift(0x1, toSetIndex))
end

function EEex_SetBits(original, bitsString)
	return EEex_SetMask(original, tonumber(bitsString, 2))
end

function EEex_SetMask(original, toSetMask)
	return EEex_BOr(original, toSetMask)
end

-- Warning: Don't use this with negative numbers in anything critical!
-- Lua's precision breaks down when RShifting near-max 64bit values.
-- If you need to convert a 64bit integer to a string, use
-- EEex_ToDecStr(), which is written in C++.
function EEex_ToHex(number, minLength, suppressPrefix)

	if type(number) ~= "number" then
		-- This is usually a critical error somewhere else in the code, so throw a fully fledged error.
		EEex_Error("Passed a NaN value: '"..tostring(number).."'!")
	end

	-- string.format() can't handle "negative" numbers, and bit32 can't handle 64bits, (obviously).
	local hexString = ""
	while number ~= 0x0 do
		hexString = string.format("%x", EEex_Extract(number, 0, 4)):upper()..hexString
		number = EEex_RShift(number, 4)
	end

	local wantedLength = (minLength or 1) - #hexString
	for i = 1, wantedLength, 1 do
		hexString = "0"..hexString
	end

	return suppressPrefix and hexString or "0x"..hexString
end

function EEex_UnsetBit(original, toUnsetIndex)
	return EEex_BAnd(original, EEex_BNot(EEex_LShift(0x1, toUnsetIndex)))
end

function EEex_UnsetBits(original, bitsString)
	return EEex_UnsetMask(original, tonumber(bitsString, 2))
end

function EEex_UnsetMask(original, toUnsetmask)
	return EEex_BAnd(original, EEex_BNot(toUnsetmask))
end

-------------------
-- Debug Utility --
-------------------

-- Throws a Lua error, appending the current stacktrace to the end of the message.
function EEex_Error(message)
	error(debug.traceback("[!] "..message, 2), 0)
end

function EEex_ErrorMessageHandler(err)
	if type(err) == "string" and err:find("stack traceback:") then
		return err
	end
	return debug.traceback(err)
end

-- Logs a message to the console window, prepending the message with the calling function's name.
function EEex_FunctionLog(message)
	local name = debug.getinfo(2, "n").name
	if name == nil then name = "(Unknown)" end
	print("[EEex] "..name..": "..message)
end

-- Displays a message box to the user. Note: Suspends game until closed, which can be useful for debugging.
function EEex_MessageBox(message, iconOverride)
	EEex_MessageBoxInternal(message, iconOverride and iconOverride or 0x40)
end

function EEex_TracebackMessage(message, levelMod)
	local message = debug.traceback(message, 2 + (levelMod or 0))
	print(message)
	EEex_MessageBox(message)
end

function EEex_TracebackPrint(message, levelMod)
	print(debug.traceback(message, 2 + (levelMod or 0)))
end

---------------------
-- General Utility --
---------------------

function EEex_DistanceToMultiple(numToRound, multiple)
	if multiple == 0 then return 0 end
	local remainder = numToRound % multiple
	if remainder == 0 then return 0 end
	return multiple - remainder
end

EEex_OnceTable = {}

function EEex_Once(key, func)
	if not EEex_OnceTable[key] then
		EEex_OnceTable[key] = true
		func()
	end
end

-- Rounds the given number upwards to the nearest multiple.
function EEex_RoundUp(numToRound, multiple)
	if multiple == 0 then return numToRound end
	local remainder = numToRound % multiple
	if remainder == 0 then return numToRound end
	return numToRound + multiple - remainder
end

---------
-- JIT --
---------

EEex_CodePageAllocations = {}

function EEex_AllocCodePage()
	local address, size = EEex_AllocCodePageInternal()
	local initialEntry = {}
	initialEntry.address = address
	initialEntry.size = size
	initialEntry.reserved = false
	local codePageEntry = {initialEntry}
	table.insert(EEex_CodePageAllocations, codePageEntry)
	return codePageEntry
end

function EEex_JITAt(dst, assemblyT)
	local assemblyStr = EEex_PreprocessAssembly(assemblyT)
	local checkJIT = function(writeSize) return 0 end
	EEex_JITAtInternal(dst, checkJIT, assemblyStr)
end

function EEex_Assembly_Private_AllocNearItr()

	local currentCodePageI = 1
	local curCodePage = EEex_CodePageAllocations[currentCodePageI]
	local alreadyAllocatedCodePage = false
	local currentAllocEntryI = 0

	return function()

		while true do

			if curCodePage == nil then
				if alreadyAllocatedCodePage then
					return -- Fail
				end
				alreadyAllocatedCodePage = true
				curCodePage = EEex_AllocCodePage()
			end

			while true do

				currentAllocEntryI = currentAllocEntryI + 1
				local curAllocEntry = curCodePage[currentAllocEntryI]

				if curAllocEntry == nil then
					currentCodePageI = currentCodePageI + 1
					curCodePage = EEex_CodePageAllocations[currentCodePageI]
					currentAllocEntryI = 1
					break
				end

				if not curAllocEntry.reserved then
					return curCodePage, currentAllocEntryI, curAllocEntry -- Success
				end
			end
		end
	end
end

function EEex_Assembly_Private_ReserveAllocEntry(finalCodePage, finalAllocEntryI, finalAllocEntry, alignmentOffset, requestedSize)

	-----------------------------------------------------------------------------------------------------------------
	-- Merge with previous non-reserved allocation / create new allocation to track unused alignment padding space --
	-----------------------------------------------------------------------------------------------------------------

	if alignmentOffset ~= 0 then

		-- Modify / create previous allocation
		local previousEntry = finalCodePage[finalAllocEntryI - 1]

		if previousEntry ~= nil and not previousEntry.reserved then
			previousEntry.size = previousEntry.size + alignmentOffset
		else
			table.insert(finalCodePage, finalAllocEntryI, {
				["address"] = finalAllocEntry.address,
				["size"] = alignmentOffset,
				["reserved"] = false,
			})
			finalAllocEntryI = finalAllocEntryI + 1
		end

		-- Modify current allocation
		finalAllocEntry.address = finalAllocEntry.address + alignmentOffset
		finalAllocEntry.size = finalAllocEntry.size - alignmentOffset
	end

	--------------------------------------------------------------------------------------------
	-- Merge with next non-reserved allocation / create new allocate to track left over space --
	--------------------------------------------------------------------------------------------

	local memLeftOver = finalAllocEntry.size - requestedSize

	if memLeftOver > 0 then

		-- Modify current allocation
		finalAllocEntry.size = requestedSize

		-- Modify / create next allocation
		local addressAfterAlloc = finalAllocEntry.address + requestedSize
		local nextEntry = finalCodePage[finalAllocEntryI + 1]

		if nextEntry ~= nil then
			if not nextEntry.reserved then
				nextEntry.address = addressAfterAlloc
				nextEntry.size = memLeftOver + nextEntry.size
			else
				table.insert(finalCodePage, finalAllocEntryI + 1, {
					["address"] = addressAfterAlloc,
					["size"] = memLeftOver,
					["reserved"] = false,
				})
			end
		else
			finalCodePage[finalAllocEntryI + 1] = {
				["address"] = addressAfterAlloc,
				["size"] = memLeftOver,
				["reserved"] = false,
			}
		end
	end

	----------------------------------------------------------------------------------------------------
	-- Mark as reserved and return final allocation index (it might have changed due to an insertion) --
	----------------------------------------------------------------------------------------------------

	finalAllocEntry.reserved = true
	return finalAllocEntryI
end

function EEex_AllocNear(requestedSize, alignment)
	if alignment == nil then alignment = 0 end
	for curCodePage, currentAllocEntryI, curAllocEntry in EEex_Assembly_Private_AllocNearItr() do
		local alignmentOffset = EEex_DistanceToMultiple(curAllocEntry.address, alignment)
		if curAllocEntry.size - alignmentOffset >= requestedSize then
			EEex_Assembly_Private_ReserveAllocEntry(curCodePage, currentAllocEntryI, curAllocEntry, alignmentOffset, requestedSize)
			return curAllocEntry.address -- `EEex_Assembly_Private_ReserveAllocEntry()` might have changed this to handle alignment
		end
	end
	EEex_Error("EEex_AllocNear() failed to find/create large enough allocation")
end

function EEex_JITNear(assemblyT)

	local stackMod = EEex_TryLabel("stack_mod")
	if stackMod then
		assemblyT = EEex_FlattenTable({
			{"#STACK_MOD(#$(1)) #ENDL", {stackMod}},
			assemblyT,
		})
	end

	assemblyT = EEex_FlattenTable({[[
		hook_start: #ENDL ]],
		assemblyT, [[ #ENDL
		hook_end: #ENDL
	]]})

	-------------------------------------------------
	-- Preprocess assembly before attempting write --
	-------------------------------------------------

	local assemblyStr, state = EEex_PreprocessAssembly(assemblyT)

	------------------------------------
	-- Setup near allocation iterator --
	------------------------------------

	local itr = EEex_Assembly_Private_AllocNearItr()
	local curCodePage, currentAllocEntryI, curAllocEntry

	local advanceItr = function()
		curCodePage, currentAllocEntryI, curAllocEntry = itr()
		if curCodePage == nil then
			EEex_Error("EEex_JITNear() failed to find/create large enough allocation")
		end
	end

	-- Fetch initial alloc entry
	advanceItr()

	-----------------
	-- Attempt JIT --
	-----------------

	local finalWriteSize

	-- This is called by `EEex_JITAtInternal()` every time it relocates to a new address.
	-- Return:
	--     -1 -> Error, return from `EEex_JITAtInternal()` without writing. Returned internally when a Lua exception is thrown.
	--      0 -> Fits, write at the current location.
	--     !0 -> Doesn't fit, try relocating to the returned address next.
	local checkJITRelocationFits = function(writeSize)
		if writeSize > curAllocEntry.size then
			-- Too small, check next alloc entry
			advanceItr()
			return curAllocEntry.address
		end
		-- Good, write at current alloc entry
		EEex_Assembly_Private_ReserveAllocEntry(curCodePage, currentAllocEntryI, curAllocEntry, 0, writeSize)
		finalWriteSize = writeSize
		return 0
	end

	local jitMetadata = EEex_JITAtInternal(curAllocEntry.address, checkJITRelocationFits, assemblyStr)

	local errorType = jitMetadata.errorType
	if errorType ~= nil then
		if errorType == 0 then
			-- Throw error with message returned by AsmJit
			EEex_Error("EEex_JITNear() failed: "..jitMetadata.errorMessage)
		elseif errorType == 1 then
			-- Rethrow Lua error raised by `checkJITRelocationFits()`
			error(jitMetadata.errorMessage, 0)
		end
	end

	-------------------------
	-- Post-JIT processing --
	-------------------------

	EEex_Assembly_Private_PostJIT(state, curAllocEntry.address, finalWriteSize, jitMetadata)
	return curAllocEntry.address
end

function EEex_JITNearAsLuaFunction(luaFunctionName, assemblyT)
	local address = EEex_JITNear(assemblyT)
	EEex_ExposeToLua(address, luaFunctionName)
	return address
end

function EEex_JITNearAsLabel(label, assemblyT)
	EEex_DefineAssemblyLabel(label, EEex_JITNear(assemblyT))
end

EEex_DebugPreprocessAssembly = false

EEex_Assembly_Private_DefaultMacroSwitch = {
	["DEBUG_OFF"] = function(state, argumentsT)
		--print("#DEBUG_OFF")
		state.debug = false
	end,
	["DEBUG_ON"] = function(state, argumentsT)
		--print("#DEBUG_ON")
		state.debug = true
	end,
}

function EEex_PreprocessAssembly(assemblyT, state)

	local builtStr = {}
	local insertI = 1

	local len = #assemblyT
	local i = 1
	while i <= len do
		local v = assemblyT[i]
		local vtype = type(v)
		local advanceCount = 1
		if vtype == "string" then
			builtStr[insertI], advanceCount = EEex_PreprocessAssemblyStr(assemblyT, i, v)
			insertI = insertI + 1
		elseif vtype == "number" then
			builtStr[insertI] = EEex_ToDecStr(v)
			insertI = insertI + 1
		else
			EEex_Dump("assemblyT", assemblyT)
			EEex_Error(string.format("Unexpected type encountered during JIT at index %d: %s", i, vtype))
		end
		i = i + advanceCount
	end

	builtStr[insertI] = "\n" -- Always end with a newline
	local toReturn = table.concat(builtStr)

	if not state then
		state = {
			["debug"] = false,
		}
		EEex_Assembly_Private_InitState(state)
	end

	while true do

		local madeChange = false

		-- Turn ENDL markers into newlines. This is a hacky pre-macro evaluation since ENDL uses macro syntax, but allows immediate text.
		-- e.g. "#ENDLxor eax, eax" needs to be transformed into "\nxor eax, eax", not parsed as the invalid macro "#ENDLxor"
		toReturn = EEex_ReplacePattern(toReturn, "#ENDL", "\n")

		-- Handle macros
		toReturn = EEex_ReplaceRegex(toReturn, "#([^\\s()]+)(?:\\(([^)]*)\\))?", function(pos, endPos, matchedStr, groups)

			local macroName = groups[1]
			local innerStr = groups[2]
			local argumentsT = innerStr ~= nil and EEex_Split(EEex_Strip(innerStr), "%s*,%s*", true) or {}

			local macroHandler = EEex_Assembly_Private_GetMacroHandler(macroName) or EEex_Assembly_Private_DefaultMacroSwitch[macroName]
			if macroHandler == nil then
				EEex_Error(string.format("Invalid macro \"#%s\"", macroName))
			end

			local replacement = macroHandler(state, argumentsT)
			madeChange = madeChange or matchedStr ~= replacement
			return replacement
		end)

		if not madeChange then
			break
		end
	end

	-- Standardize string
	toReturn = EEex_ReplacePattern(toReturn, "[ \t]+\n", "\n") -- Remove whitespace before newlines (trailing whitespace)
	toReturn = EEex_ReplacePattern(toReturn, "\n+", "\n")      -- Merge newlines
	toReturn = EEex_ReplacePattern(toReturn, "\n[ \t]+", "\n") -- Remove whitespace after newlines, (indentation)
	toReturn = EEex_ReplacePattern(toReturn, "^[ \t]+", "")    -- Remove initial indent
	toReturn = EEex_ReplacePattern(toReturn, "[ \t]+;", " ;")  -- Remove indentation before comments

	if EEex_DebugPreprocessAssembly then
		print("EEex_PreprocessAssembly returning:\n\n"..toReturn.."\n")
	end

	-- Validate labels to prevent subtle bug where zero-offset branch instructions are written for non-existing labels
	local seenLabels = {}
	EEex_IterateRegex(toReturn, "^\\s*(\\S+):", function(pos, endPos, matchedStr, groups)
		seenLabels[groups[1]] = true
	end)

	local branchUsingLabel = "^\\s*(?:call|ja|jae|jb|jbe|jc|je|jg|jge|jl|jle|jmp|jna|jnae|jnb|jnbe|jnc|jne|jng|jnge|jnl|jnle|jno|jnp|jns|jnz|jo|jp|jpe|jpo|js|jz|loope|loopne|loopnz|loopz)\\s+([^0-9]\\S*)\\s*$"
	EEex_IterateRegex(toReturn, branchUsingLabel, function(pos, endPos, matchedStr, groups)
		local expectedLabel = groups[1]
		if not seenLabels[expectedLabel] then
			EEex_Error(string.format("Label \"%s\" not defined. Did you mean to use \"#L(%s)\"?", expectedLabel, expectedLabel))
		end
	end)

	return toReturn, state
end

function EEex_OffsetOf(pathStr)
	local innerSplit = EEex_Split(pathStr, "%s*%.%s*", true)
	if innerSplit[2] == nil then EEex_Error("#OFFSET_OF has invalid number of arguments") end
	local curStructName = innerSplit[1]
	local curMemberIndex = 2
	local curMemberName = innerSplit[curMemberIndex]
	local totalOffset = 0
	while true do
		local structBinding = _G[curStructName]
		if structBinding == nil then EEex_Error(string.format("Invalid usertype encountered in #OFFSET_OF: \"%s\"", curStructName)) end
		local offsetof = structBinding["offsetof_"..curMemberName]
		if offsetof == nil then EEex_Error(string.format("Member missing offsetof binding in #OFFSET_OF: %s::%s", curStructName, curMemberName)) end
		local usertype = structBinding["usertype_"..curMemberName]
		if usertype == nil then EEex_Error(string.format("Member missing usertype binding in #OFFSET_OF: %s::%s", curStructName, curMemberName)) end
		totalOffset = totalOffset + offsetof
		curMemberIndex = curMemberIndex + 1
		curMemberName = innerSplit[curMemberIndex]
		if curMemberName == nil then break end
		curStructName = usertype
	end
	return totalOffset
end

function EEex_PreprocessAssemblyStr(assemblyT, curI, assemblyStr)

	local advanceCount = 1

	-- #IF
	assemblyStr = EEex_ReplacePattern(assemblyStr, "#IF(.*)", function(match)

		if EEex_FindPattern(match.groups[1], "[^%s]") then
			EEex_Error("Text between #IF and immediate condition")
		end

		advanceCount = 2
		local conditionV = assemblyT[curI + 1]

		if type(conditionV) == "boolean" then

			local hadBody = false
			local bodyI = curI + 2
			local bodyV = assemblyT[bodyI]

			if type(bodyV) == "string" then

				-- Find and remove the opening "{"
				local hadOpen = false
				bodyV = EEex_ReplacePattern(bodyV, "^%s-{(.*)", function(bodyMatch)
					hadOpen = true
					return bodyMatch.groups[1], true
				end)

				if hadOpen then

					assemblyT[bodyI] = bodyV

					local curLevel = 1
					repeat
						-- Look for closing "}"
						if type(bodyV) == "string" then

							local findV -- curLevel if not hadBody, else found closingI
							hadBody, findV = EEex_FindClosing(bodyV, "{", "}", curLevel)

							if hadBody then
								-- Save contents before and after the "}" if condition was true,
								-- else only save contents after the "}"
								assemblyT[bodyI] = conditionV and findV > 1
									and bodyV:sub(1, findV - 1)..bodyV:sub(findV + 1)
									or  bodyV:sub(findV + 1)
								break
							end
							curLevel = findV
						end

						-- Skip every assemblyT value until "}" is found
						if not conditionV then
							advanceCount = advanceCount + 1
						end

						bodyI = bodyI + 1
						bodyV = assemblyT[bodyI]

					until bodyV == nil
				end
			end

			if not hadBody then
				EEex_Error("#IF has no immediate body")
			end
		else
			EEex_Error("#IF has no immediate condition")
		end
	end)

	-- #$
	assemblyStr = EEex_ReplacePattern(assemblyStr, "#%$%((%d+)%)", function(match)
		local argIndexStr = match.groups[1]
		local argIndex = tonumber(argIndexStr)
		if not argIndex then EEex_Error(string.format("#$ has invalid arg index: \"%s\"", argIndexStr)) end
		local argsTable = assemblyT[curI + 1]
		if not argsTable or type(argsTable) ~= "table" then EEex_Error("#$ has no immediate arg table") end
		local argsTableSize = #argsTable
		if argIndex > argsTableSize then EEex_Error(string.format("#$%d out of bounds for arg table of size %d", argIndex, argsTableSize)) end
		advanceCount = 2
		local argVal = argsTable[argIndex]
		return type(argVal) == "number"
			and EEex_ToDecStr(argVal)
			or tostring(argVal)
	end)

	-- #L
	assemblyStr = EEex_ReplacePattern(assemblyStr, "#L(%b())", function(match)
		local labelName = match.groups[1]:sub(2, -2)
		local labelAddress = EEex_TryLabel(labelName)
		return labelAddress and EEex_ToDecStr(labelAddress) or labelName
	end)

	-- #OFFSET_OF
	assemblyStr = EEex_ReplacePattern(assemblyStr, "#OFFSET_OF(%b())", function(match)
		local innerStr = match.groups[1]
		local offset = EEex_OffsetOf(innerStr:sub(2):sub(1, -2))
		return EEex_ToDecStr(offset)
	end)

	-- #REPEAT
	assemblyStr = EEex_ReplacePattern(assemblyStr, "#REPEAT(%b())", function(match)

		local toBuild = {}

		local innerStr = match.groups[1]
		local innerMatch = EEex_FindPattern(innerStr, "^%(%s*(%d+)%s*,%s*([^,]+)%)$")
		if not innerMatch then EEex_Error(string.format("Invalid #REPEAT parameters: \"%s\"", innerStr)) end

		local repeatStr = innerMatch.groups[2]
		for i = 1, innerMatch.groups[1] do
			toBuild[i] = repeatStr
		end
		return table.concat(toBuild)
	end)

	return assemblyStr, advanceCount
end

------------
-- Labels --
------------

-- This table is stored in the Lua registry. InfinityLoader automatically
-- updates it when new patterns are added by Lua bindings DLLs.
EEex_GlobalAssemblyLabels = EEex_GetPatternMap()

function EEex_ClearAssemblyLabel(label)
	EEex_GlobalAssemblyLabels[label] = nil
end

function EEex_DefineAssemblyLabel(label, value)
	EEex_GlobalAssemblyLabels[label] = value
end

function EEex_Label(label)
	local value = EEex_GlobalAssemblyLabels[label]
	if not value then
		EEex_Error(string.format("Label \"#L(%s)\" not defined", label))
	end
	return EEex_GlobalAssemblyLabels[label]
end

function EEex_LabelDefault(label, default)
	return EEex_GlobalAssemblyLabels[label] or default
end

function EEex_RunWithAssemblyLabels(labels, func)
	for _, labelPair in ipairs(labels) do
		EEex_DefineAssemblyLabel(labelPair[1], labelPair[2])
	end
	local retVal = func()
	for _, labelPair in ipairs(labels) do
		EEex_ClearAssemblyLabel(labelPair[1])
	end
	return retVal
end

function EEex_TryLabel(label)
	return EEex_GlobalAssemblyLabels[label]
end

--------------------
-- Memory Manager --
--------------------

EEex_MemoryManagerStructDefinitions = {}

EEex_MemoryManager = {}
EEex_MemoryManager.__index = EEex_MemoryManager

function EEex_MemoryManager:destruct()
	for _, entry in pairs(self.nameToEntry) do
		local destructor = (entry.structDefinition or {}).destructor
		if destructor then
			if type(destructor) ~= "function" then
				EEex_TracebackMessage("[EEex_MemoryManager] Invalid destructor type!")
			end
			if not entry.noDestruct then
				destructor(entry.userData and entry.userData or entry.address)
			end
		end
	end
end

function EEex_MemoryManager:free()
	self:destruct()
	EEex_Free(self.address)
end

function EEex_MemoryManager:getAddress(name)
	return self.nameToEntry[name].address
end

function EEex_MemoryManager:getUserData(name)
	return self.nameToEntry[name].userData
end
EEex_MemoryManager.getUD = EEex_MemoryManager.getUserData

function EEex_MemoryManager:init(structEntries, stackModeFunc)

	local getArgs = function(structEntry)
		local args = (structEntry.constructor or {}).args
		local argsType = type(args)
		if argsType == "function" then
			return args(self)
		elseif argsType == "table" then
			return table.unpack(args)
		end
	end

	self.nameToEntry = {}
	local currentOffset = 0

	for _, structEntry in ipairs(structEntries) do

		self.nameToEntry[structEntry.name] = structEntry
		local structDefinition = EEex_MemoryManagerStructDefinitions[structEntry.struct]
		local userType = _G[structEntry.struct]

		local size
		if userType and type(userType) == "table" then
			size = userType.sizeof
			structEntry.userType = userType
		else
			if not structDefinition then
				EEex_TracebackMessage("[EEex_MemoryManager] Struct meta must be defined for non-usertype: \""..structEntry.struct.."\"!")
			end
			size = structDefinition.size
		end

		structEntry.offset = currentOffset
		structEntry.structDefinition = structDefinition

		local sizeType = type(size)
		if sizeType == "function" then
			currentOffset = currentOffset + size(getArgs(structEntry))
		elseif sizeType == "number" then
			currentOffset = currentOffset + size
		else
			EEex_TracebackMessage("[EEex_MemoryManager] Invalid size type!")
		end
	end

	local initMemory = function(startAddress)

		self.address = startAddress

		for _, structEntry in ipairs(structEntries) do

			structEntry.address = startAddress + structEntry.offset

			if structEntry.userType then
				structEntry.userData = EEex_PtrToUD(structEntry.address, structEntry.struct)
			end

			local constructor = ((structEntry.structDefinition or {}).constructors or {})[(structEntry.constructor or {}).variant or "#default"]
			if type(constructor) == "function" then
				constructor(structEntry.userData and structEntry.userData or structEntry.address, getArgs(structEntry))
			elseif type(constructor) == "table" then
				local constructorFunc = constructor.func
				if type(constructorFunc) ~= "function" then
					EEex_TracebackMessage("[EEex_MemoryManager] Invalid constructor.func type!")
				end
				if constructor.usesManager then
					constructor(self, structEntry.userData and structEntry.userData or structEntry.address, getArgs(structEntry))
				else
					constructor(structEntry.userData and structEntry.userData or structEntry.address, getArgs(structEntry))
				end
			elseif constructor ~= nil then
				EEex_TracebackMessage("[EEex_MemoryManager] Invalid constructor type!")
			end
		end
	end

	if stackModeFunc then
		local retVals
		EEex_RunWithStack(currentOffset, function(rsp)
			initMemory(rsp)
			retVals = { EEex_Utility_TryFinally(stackModeFunc, function() self:destruct() end, self) }
		end)
		return table.unpack(retVals)
	else
		initMemory(EEex_Malloc(currentOffset))
	end
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
	return o:init(structEntries, stackModeFunc)
end

function EEex_NewMemoryManager(structEntries)
	return EEex_MemoryManager:new(structEntries)
end

function EEex_RunWithStackManager(structEntries, func)
	return EEex_MemoryManager:runWithStack(structEntries, func)
end

--------------------
-- Memory Utility --
--------------------

EEex_WriteFailType = {
	["ERROR"]   = 0,
	["DEFAULT"] = 1,
	["NOTHING"] = 2,
}

EEex_WriteType = {
	["BYTE"]    = 0,
	["8"]       = 0,
	["WORD"]    = 1,
	["16"]      = 1,
	["DWORD"]   = 2,
	["32"]      = 2,
	["QWORD"]   = 3,
	["64"]      = 3,
	["POINTER"] = 4,
	["PTR"]     = 4,
	["RESREF"]  = 5,
	["JIT"]     = 6,
}

function EEex_WriteArgs(address, args, writeDefs)
	writeTypeFunc = {
		[EEex_WriteType.BYTE]    = EEex_Write8,
		[EEex_WriteType.WORD]    = EEex_Write16,
		[EEex_WriteType.DWORD]   = EEex_Write32,
		[EEex_WriteType.QWORD]   = EEex_Write64,
		[EEex_WriteType.POINTER] = EEex_WritePtr,
		[EEex_WriteType.RESREF]  = function(address, arg) EEex_WriteLString(address, arg, 8) end,
		[EEex_WriteType.JIT]     = function(address, arg)
			local ptr = arg
			if type(ptr) == "table" then
				ptr = EEex_JITNear(arg)
			end
			EEex_WritePtr(address, ptr)
		end,
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

EEex_StringCache = {}

function EEex_WriteStringCache(str)
	local cached = EEex_StringCache[str]
	if cached then
		return cached
	else
		local address = EEex_WriteStringAuto(str)
		EEex_StringCache[str] = address
		return address
	end
end

--------------------
-- String Utility --
--------------------

function EEex_FindClosing(str, openStr, endStr, curLevel)
	local strLen = #str
	local openLen = #openStr - 1
	local endLen = #endStr - 1
	curLevel = curLevel or 0
	for i = 1, strLen do
		if str:sub(i, i + openLen) == openStr then
			curLevel = curLevel + 1
		end
		if str:sub(i, i + endLen) == endStr then
			curLevel = curLevel - 1
			if curLevel == 0 then return true, i end
		end
	end
	return false, curLevel
end

function EEex_FindPattern(str, findStr, startI)
	local results = table.pack(str:find(findStr, startI or 1))
	if not results[1] then return end
	return {
		["startI"] = results[1],
		["endI"] = results[2],
		["groups"] = EEex_Subtable(results, 3, results.n)
	}
end

function EEex_FindPatternAll(str, findStr)
	local matches = {}
	local insertI = 1
	local nextStartI = 1
	while true do
		local match = EEex_FindPattern(str, findStr, nextStartI)
		if not match then break end
		matches[insertI] = match
		insertI = insertI + 1
		nextStartI = match.endI + 1
	end
	return matches
end

function EEex_IteratePattern(str, findStr, func)
	local nextStartI = 1
	while true do
		local match = EEex_FindPattern(str, findStr, nextStartI)
		if not match or func(match) then break end
		nextStartI = match.endI + 1
	end
end

function EEex_ReplacePattern(str, findStr, replaceFunc)
	local builtStr = {""}
	local insertI = 1
	local lastAfterEndI = 1
	if type(replaceFunc) == "string" then
		local replaceStr = replaceFunc
		replaceFunc = function(match) return replaceStr end
	end
	EEex_IteratePattern(str, findStr, function(match)
		if match.startI > lastAfterEndI then
			builtStr[insertI] = str:sub(lastAfterEndI, match.startI - 1)
			insertI = insertI + 1
		end
		local v, shouldEnd = replaceFunc(match)
		if v then
			builtStr[insertI] = v
			insertI = insertI + 1
		end
		lastAfterEndI = match.endI + 1
		return shouldEnd
	end)
	local len = #str
	if lastAfterEndI <= len then
		builtStr[insertI] = str:sub(lastAfterEndI, len)
	end
	return table.concat(builtStr)
end

function EEex_ReplaceRegex(str, findStr, replaceFunc)
	local builtStr = {""}
	local insertI = 1
	local lastAfterEndI = 1
	if type(replaceFunc) == "string" then
		local replaceStr = replaceFunc
		replaceFunc = function(pos, endPos, str, groups) return replaceStr end
	end
	EEex_IterateRegex(str, findStr, function(pos, endPos, matchedStr, groups)
		if pos > lastAfterEndI then
			builtStr[insertI] = str:sub(lastAfterEndI, pos - 1)
			insertI = insertI + 1
		end
		local v, shouldEnd = replaceFunc(pos, endPos, matchedStr, groups)
		if v then
			builtStr[insertI] = v
			insertI = insertI + 1
		end
		lastAfterEndI = endPos + 1
		return shouldEnd
	end)
	local len = #str
	if lastAfterEndI <= len then
		builtStr[insertI] = str:sub(lastAfterEndI, len)
	end
	return table.concat(builtStr)
end

function EEex_Split(text, splitBy, usePattern, allowEmptyCapture)

	local toReturn = {}
	local toReturnI = 1

	local plain = usePattern == nil or not usePattern
	local captureStartI = 1

	while true do

		local splitStartI, splitEndI = text:find(splitBy, captureStartI, plain)

		if splitStartI == nil then
			break
		end

		if splitStartI > captureStartI or allowEmptyCapture then
			toReturn[toReturnI] = text:sub(captureStartI, splitStartI - 1)
			toReturnI = toReturnI + 1
		end

		captureStartI = splitEndI + 1
	end

	local limit = #text
	if captureStartI <= limit or (allowEmptyCapture and limit > 0) then
		toReturn[toReturnI] = text:sub(captureStartI, limit)
	end

	return toReturn
end

function EEex_Strip(str)
	return str:gsub("^%s", ""):gsub("%s$", "")
end

-------------------
-- Table Utility --
-------------------

function EEex_Dump(key, valueToDump, dumpFunction)

	dumpFunction = dumpFunction or print

	local alphanumericSortEntries = function(o)
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

	local fillDumpLevel
	fillDumpLevel = function(tableName, levelTable, levelToFill, levelTableKey)
		local tableKey, tableValue = next(levelTable, levelTableKey)
		while tableValue ~= nil do
			local tableValueType = type(tableValue)
			if tableValueType == 'string' or tableValueType == 'number' or tableValueType == 'boolean' then
				local entry = {}
				entry.string = tableValueType..' '..tostring(tableKey)..' = '
				entry.value = tableValue
				table.insert(levelToFill, entry)
			elseif tableValueType == 'table' then
				if tableKey ~= '_G' then
					local entry = {}
					local tableStr = tostring(tableValue)
					local tableAddress = tableStr:sub(tableStr:find(" ") + 1, -1)
					entry.string = tableValueType..' '..tostring(tableKey)..' ('..tableAddress..'):'
					entry.value = {} --entry.value is a levelToFill
					entry.value.previous = {}
					entry.value.previous.tableName = tableName
					entry.value.previous.levelTable = levelTable
					entry.value.previous.levelToFill = levelToFill
					entry.value.previous.levelTableKey = tableKey
					table.insert(levelToFill, entry)
					return fillDumpLevel(tableKey, tableValue, entry.value)
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
					return fillDumpLevel(tableKey, metatable, entry.value)
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
		end
		alphanumericSortEntries(levelToFill)
		local previous = levelToFill.previous
		if previous ~= nil then
			local previousTableName = previous.tableName
			local previousLevelTable = previous.levelTable
			local previousLevelToFill = previous.levelToFill
			local previousLevelTableKey = previous.levelTableKey
			levelToFill.previous = nil
			return fillDumpLevel(previousTableName, previousLevelTable,
									  previousLevelToFill, previousLevelTableKey)
		else
			return levelToFill
		end
	end

	local printEntries
	printEntries = function(entriesTable, indentLevel, indentStrings, previousState, levelTableKey)
		local tableEntryKey, tableEntry = next(entriesTable, levelTableKey)
		while(tableEntry ~= nil) do
			local tableEntryString = tableEntry.string
			local tableEntryValue = tableEntry.value
			local indentString = indentStrings[indentLevel]
			if tableEntryValue ~= nil then
				if type(tableEntryValue) ~= 'table' then
					local valueToPrint = string.gsub(tostring(tableEntryValue), '\n', '\\n')
					dumpFunction(indentString..tableEntryString..valueToPrint)
				else
					dumpFunction(indentString..tableEntryString)
					dumpFunction(indentString..'{')
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
					return printEntries(tableEntryValue, indentLevel, indentStrings, previous)
				end
			else
				dumpFunction(indentString..tableEntryString)
			end
			--Increment
			tableEntryKey, tableEntry = next(entriesTable, tableEntryKey)
		end
		dumpFunction(indentStrings[indentLevel - 1]..'}')
		--Finish previous levels
		if previousState ~= nil then
			return printEntries(previousState.entriesTable, previousState.indentLevel, indentStrings,
									 previousState.previousState, previousState.levelTableKey)
		end
	end

	local valueToDumpType = type(valueToDump)
	if valueToDumpType == 'string' or valueToDumpType == 'number' or valueToDumpType == 'boolean' then
		dumpFunction(valueToDumpType..' '..key..' = '..tostring(valueToDump))
	elseif valueToDumpType == 'table' then
		dumpFunction(valueToDumpType..' '..key..':')
		dumpFunction('{')
		local entries = fillDumpLevel(key, valueToDump, {})
		printEntries(entries, 1, {[0] = '', [1] = '	'})
	elseif valueToDumpType == 'userdata' then
		local metatable = getmetatable(valueToDump)
		if metatable ~= nil then
			dumpFunction(valueToDumpType..' '..key..':')
			dumpFunction('{')
			local entries = fillDumpLevel(key, metatable, {})
			printEntries(entries, 1, {[0] = '', [1] = '	'})
		else
			dumpFunction(valueToDumpType..' '..key..' = nil')
		end
	else
		dumpFunction(valueToDumpType..' '..key)
	end
end

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

function EEex_ReverseTable(t, tMaxI)
	local newT = {}
	local insertI = 1
	for reverseI = tMaxI or #t, 1, -1 do
		newT[insertI] = t[reverseI]
		insertI = insertI + 1
	end
	return newT
end

function EEex_Subtable(t, startI, endI)
	local subtable = {}
	local insertI = 1
	for i = startI, endI or #t do
		subtable[insertI] = t[i]
		insertI = insertI + 1
	end
	return subtable
end

-----------------------
-- User Data Utility --
-----------------------

EEex_UserDataAuxiliary = {}

function EEex_DeleteUserDataAuxiliary(ud)
	if type(ud) ~= "userdata" then
		EEex_Error("ud is not a userdata object ("..type(ud)..")!")
	end
	EEex_UserDataAuxiliary[EEex_UDToLightUD(ud)] = nil
end
EEex_DeleteUDAux = EEex_DeleteUserDataAuxiliary

function EEex_GetUserDataAuxiliary(ud)
	if type(ud) ~= "userdata" then
		EEex_Error("ud is not a userdata object ("..type(ud)..")!")
	end
	local lud = EEex_UDToLightUD(ud)
	local auxiliary = EEex_UserDataAuxiliary[lud]
	if not auxiliary then
		auxiliary = {}
		EEex_UserDataAuxiliary[lud] = auxiliary
	end
	return auxiliary
end
EEex_GetUDAux = EEex_GetUserDataAuxiliary

function EEex_TryGetUserDataAuxiliary(ud)
	if type(ud) ~= "userdata" then
		EEex_Error("ud is not a userdata object ("..type(ud)..")!")
	end
	return EEex_UserDataAuxiliary[EEex_UDToLightUD(ud)]
end
EEex_TryGetUDAux = EEex_TryGetUserDataAuxiliary

function EEex_UserDataEqual(ud1, ud2)
	return EEex_UDToLightUD(ud1) == EEex_UDToLightUD(ud2)
end
EEex_UDEqual = EEex_UserDataEqual

function EEex_UserDataToHex(ud)
	return ud and EEex_ToHex(EEex_UDToPtr(ud)) or "nil"
end
EEex_UDToHex = EEex_UserDataToHex

function EEex_WriteUserDataArgs(userdata, args, writeDefs)
	for _, writeDef in ipairs(writeDefs) do
		local argKey = writeDef[1]
		local toWrite = args[argKey]
		local doWrite = true
		if not toWrite then
			local failType = writeDef[2]
			if failType == EEex_WriteFailType.DEFAULT then
				toWrite = writeDef[3]
			elseif failType == EEex_WriteFailType.ERROR then
				EEex_Error(argKey.." must be defined!")
			else
				doWrite = false
			end
		end
		if doWrite then
			existingVal = userdata[argKey]
			if type(existingVal) == "userdata" and existingVal.set then
				existingVal:set(toWrite)
			else
				userdata[argKey] = toWrite
			end
		end
	end
end
EEex_WriteUDArgs = EEex_WriteUserDataArgs

--------------
-- Subfiles --
--------------

if EEex_Architecture == "x86" then
	EEex_DoFile("EEex_Assembly_x86")
elseif EEex_Architecture == "x86-64" then
	EEex_DoFile("EEex_Assembly_x86-64")
else
	EEex_Error(string.format("Unhandled EEex_Architecture: \"%s\"", EEex_Architecture))
end
