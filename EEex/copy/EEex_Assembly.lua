
EEex_OnceTable = {}
EEex_GlobalAssemblyLabels = {}
EEex_CodePageAllocations = {}

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
	error(debug.traceback("[!] "..message))
end

function EEex_TracebackPrint(message, levelMod)
	print(debug.traceback(message, 2 + (levelMod or 0)))
end

function EEex_TracebackMessage(message, levelMod)
	local message = debug.traceback(message, 2 + (levelMod or 0))
	print(message)
	EEex_MessageBox(message)
end

-- Displays a message box to the user. Note: Suspends game until closed, which can be useful for debugging.
function EEex_MessageBox(message, iconOverride)
	EEex_MessageBoxInternal(message, iconOverride and iconOverride or 0x40)
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
	if multiple == 0 then return numToRound end
	local remainder = numToRound % multiple
	if remainder == 0 then return numToRound end
	return numToRound + multiple - remainder
end

function EEex_DistanceToMultiple(numToRound, multiple)
	if multiple == 0 then return 0 end
	local remainder = numToRound % multiple
	if remainder == 0 then return 0 end
	return multiple - remainder
end

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

EEex_WriteFailType = {
	["ERROR"]   = 0,
	["DEFAULT"] = 1,
	["NOTHING"] = 2,
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

EEex_UserDataAuxiliary = {}

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

function EEex_DeleteUserDataAuxiliary(ud)
	if type(ud) ~= "userdata" then
		EEex_Error("ud is not a userdata object ("..type(ud)..")!")
	end
	EEex_UserDataAuxiliary[EEex_UDToLightUD(ud)] = nil
end

EEex_DeleteUDAux = EEex_DeleteUserDataAuxiliary

function EEex_UserDataEqual(ud1, ud2)
	return EEex_UDToLightUD(ud1) == EEex_UDToLightUD(ud2)
end
EEex_UDEqual = EEex_UserDataEqual

----------------------------
-- Start Memory Interface --
----------------------------

EEex_MemoryManagerStructDefinitions = {}

EEex_MemoryManager = {}
EEex_MemoryManager.__index = EEex_MemoryManager

function EEex_NewMemoryManager(structEntries)
	return EEex_MemoryManager:new(structEntries)
end

function EEex_RunWithStackManager(structEntries, func)
	EEex_MemoryManager:runWithStack(structEntries, func)
end

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
		EEex_RunWithStack(currentOffset, function(rsp)
			initMemory(rsp)
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

function EEex_MemoryManager:getUserData(name)
	return self.nameToEntry[name].userData
end

EEex_MemoryManager.getUD = EEex_MemoryManager.getUserData

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

------------------------------
-- General Assembly Writing --
------------------------------

function EEex_DefineAssemblyLabel(label, value)
	EEex_GlobalAssemblyLabels[label] = value
end

function EEex_LabelDefault(label, default)
	return EEex_GlobalAssemblyLabels[label] or default
end

function EEex_Label(label)
	local value = EEex_GlobalAssemblyLabels[label]
	if not value then
		EEex_Error("Label \""..label.."\" is not defined in the global scope!")
	end
	return EEex_GlobalAssemblyLabels[label]
end

-------------
-- Hooking --
-------------

function EEex_StoreBytesAssembly(startAddress, size)
	if size <= 0 then return {} end
	local bytes = {".DB "}
	for i = startAddress, startAddress + size - 1 do
		table.insert(bytes, EEex_ReadU8(i))
		table.insert(bytes, ", ")
	end
	if size > 0 then
		table.remove(bytes)
		table.insert(bytes, "#ENDL")
	end
	return bytes
end

function EEex_HookRelativeBranch(address, assemblyT)
	local opcode = EEex_ReadU8(address)
	if opcode ~= 0xE8 and opcode ~= 0xE9 then EEex_Error("Not disp32 relative: "..EEex_ToHex(opcode)) end
	local afterCall = address + 5
	EEex_DefineAssemblyLabel("return", afterCall)
	local target = afterCall + EEex_Read32(address + 1)
	EEex_DefineAssemblyLabel("original", target)
	local hookAddress = EEex_JITNear(assemblyT)
	EEex_JITAt(address, {"jmp short "..hookAddress})
end

function EEex_HookBeforeCall(address, assemblyT)
	local opcode = EEex_ReadU8(address)
	if opcode ~= 0xE8 then EEex_Error("Not disp32 call: "..EEex_ToHex(opcode)) end
	local afterCall = address + 5
	EEex_DefineAssemblyLabel("return", afterCall)
	local target = afterCall + EEex_Read32(address + 1)
	local hookAddress = EEex_JITNear(EEex_FlattenTable({
		assemblyT,
		{"call #$(1) #ENDL", {target}},
		{"jmp #$(1) #ENDL", {afterCall}},
	}))
	EEex_JITAt(address, {"jmp short "..hookAddress})
end

function EEex_HookAfterCall(address, assemblyT)
	local opcode = EEex_ReadU8(address)
	if opcode ~= 0xE8 then EEex_Error("Not disp32 call: "..EEex_ToHex(opcode)) end
	local afterCall = address + 5
	EEex_DefineAssemblyLabel("return", afterCall)
	local target = afterCall + EEex_Read32(address + 1)
	local hookAddress = EEex_JITNear(EEex_FlattenTable({
		{"call #$(1) #ENDL", {target}},
		assemblyT,
		{"jmp #$(1) #ENDL", {afterCall}},
	}))
	EEex_JITAt(address, {"jmp short "..hookAddress})
end

function EEex_GetJmpInfo(address)

	local opcode = EEex_ReadU8(address)
	local hadWordPrefix = false
	local curAddress = address

	if opcode == 0x66 then
		hadWordPrefix = true
		curAddress = curAddress + 1
		opcode = EEex_ReadU8(curAddress)
	end

	local entry
	if opcode ~= 0x0F then
		entry = ({
			[0x70] = { "jo",     1                        },
			[0x71] = { "jno",    1                        },
			[0x72] = { "jb",     1                        },
			[0x73] = { "jnb",    1                        },
			[0x74] = { "jz",     1                        },
			[0x75] = { "jnz",    1                        },
			[0x76] = { "jbe",    1                        },
			[0x77] = { "ja",     1                        },
			[0x78] = { "js",     1                        },
			[0x79] = { "jns",    1                        },
			[0x7A] = { "jp",     1                        },
			[0x7B] = { "jnp",    1                        },
			[0x7C] = { "jl",     1                        },
			[0x7D] = { "jnl",    1                        },
			[0x7E] = { "jle",    1                        },
			[0x7F] = { "jg",     1                        },
			[0xE0] = { "loopnz", 1                        },
			[0xE1] = { "loopz",  1                        },
			[0xE2] = { "loop",   1                        },
			[0xE3] = { "jcxz",   1                        },
			[0xE8] = { "call",   hadWordPrefix and 2 or 4 },
			[0xE9] = { "jmp",    hadWordPrefix and 2 or 4 },
			[0xEB] = { "jmp",    1                        },
		})[opcode]
	else
		curAddress = curAddress + 1
		opcode = EEex_ReadU8(curAddress)
		local length = hadWordPrefix and 2 or 4
		entry = ({
			[0x80] = { "jo",  length },
			[0x81] = { "jno", length },
			[0x82] = { "jb",  length },
			[0x83] = { "jnb", length },
			[0x84] = { "jz",  length },
			[0x85] = { "jnz", length },
			[0x86] = { "jbe", length },
			[0x87] = { "ja",  length },
			[0x88] = { "js",  length },
			[0x89] = { "jns", length },
			[0x8A] = { "jp",  length },
			[0x8B] = { "jnp", length },
			[0x8C] = { "jl",  length },
			[0x8D] = { "jnl", length },
			[0x8E] = { "jle", length },
			[0x8F] = { "jg",  length },
		})[opcode]
	end

	local readLen = entry[2]
	local readFunc = ({
		[1] = EEex_Read8,
		[2] = EEex_Read16,
		[4] = EEex_Read32,
	})[readLen]

	curAddress = curAddress + 1
	local afterInst = curAddress + readLen
	return entry[1], afterInst + readFunc(curAddress), afterInst - address, afterInst
end

function EEex_HookJump(address, restoreSize, assemblyT)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = EEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = EEex_StoreBytesAssembly(afterInstruction, restoreSize)

	EEex_DefineAssemblyLabel("jmp_success", jmpDest)

	local hookCode = EEex_JITNear(EEex_FlattenTable({
		assemblyT,
		{[[
			jmp:
		]]},
		{
			jmpMnemonic, " ", jmpDest, [[ #ENDL
			jmp_fail:
		]]},
		restoreBytes,
		{[[
			jmp ]], jmpFailDest, [[ #ENDL
		]]},
	}))

	EEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function EEex_HookJumpOnFail(address, restoreSize, assemblyT)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = EEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = EEex_StoreBytesAssembly(afterInstruction, restoreSize)

	EEex_DefineAssemblyLabel("jmp_success", jmpDest)

	local hookCode = EEex_JITNear(EEex_FlattenTable({
		{jmpMnemonic, " ", jmpDest, "#ENDL"},
		assemblyT,
		{[[
			jmp_fail:
		]]},
		restoreBytes,
		{[[
			jmp ]], jmpFailDest, [[ #ENDL
		]]},
	}))

	EEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function EEex_HookJumpOnSuccess(address, restoreSize, assemblyT)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = EEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = EEex_StoreBytesAssembly(afterInstruction, restoreSize)

	EEex_DefineAssemblyLabel("jmp_success", jmpDest)

	local hookCode = EEex_JITNear(EEex_FlattenTable({
		{jmpMnemonic, [[ jmp_succeeded
			jmp_fail:
		]]},
		restoreBytes,
		{[[
			jmp ]], jmpFailDest, [[ #ENDL
		]]},
		{[[
			jmp_succeeded:
		]]},
		assemblyT,
		{"jmp ", jmpDest, "#ENDL"},
	}))

	EEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function EEex_HookJumpAuto(address, restoreSize, assemblyT, bAutoSuccess)

	local jmpMnemonic, jmpDest, instructionLength, afterInstruction = EEex_GetJmpInfo(address)

	local jmpFailDest = afterInstruction + restoreSize
	local restoreBytes = EEex_StoreBytesAssembly(afterInstruction, restoreSize)

	EEex_DefineAssemblyLabel("jmp_success", jmpDest)

	local hookCode = EEex_JITNear(EEex_FlattenTable({
		assemblyT,
		{[[
			#IF ]], bAutoSuccess, [[ {
				jmp #L(jmp_success)
			}
			jmp_fail:
		]]},
		restoreBytes,
		{[[
			jmp ]], jmpFailDest, [[ #ENDL
		]]},
	}))

	EEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {restoreSize - 5 + instructionLength}
	})
end

function EEex_HookJumpAutoFail(address, restoreSize, assemblyT)
	EEex_HookJumpAuto(address, restoreSize, assemblyT, false)
end

function EEex_HookJumpAutoSucceed(address, restoreSize, assemblyT)
	EEex_HookJumpAuto(address, restoreSize, assemblyT, true)
end

function EEex_HookAfterRestore(address, restoreDelay, restoreSize, returnDelay, assemblyT)

	local restoreBytes = EEex_StoreBytesAssembly(address + restoreDelay, restoreSize)
	local returnAddress = address + returnDelay

	local hookCode = EEex_JITNear(EEex_FlattenTable({
		restoreBytes,
		assemblyT,
		{[[
			return:
			jmp ]], returnAddress, [[ #ENDL
		]]},
	}))

	EEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {returnDelay - 5}
	})
end

function EEex_HookBetweenRestore(address, restoreDelay1, restoreSize1, restoreDelay2, restoreSize2, returnDelay, assemblyT)

	local restoreBytes1 = EEex_StoreBytesAssembly(address + restoreDelay1, restoreSize1)
	local restoreBytes2 = EEex_StoreBytesAssembly(address + restoreDelay2, restoreSize2)
	local returnAddress = address + returnDelay

	local hookCode = EEex_JITNear(EEex_FlattenTable({
		restoreBytes1,
		assemblyT,
		restoreBytes2,
		{[[
			return:
			jmp ]], returnAddress, [[ #ENDL
		]]},
	}))

	EEex_JITAt(address, {[[
		jmp short ]], hookCode, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {returnDelay - 5}
	})
end

function EEex_HookNOPs(address, nopCount, assemblyStr)
	EEex_DefineAssemblyLabel("return", address + 5 + nopCount)
	local hookAddress = EEex_JITNear(assemblyStr)
	EEex_JITAt(address, {[[
		jmp short ]], hookAddress, [[ #ENDL
		#REPEAT(#$(1),nop #ENDL) ]], {nopCount}
	})
end

EEex_LuaCallReturnType = {
	["Boolean"] = 0,
	["Number"] = 1,
}

function EEex_GenLuaCall(funcName, meta)

	local numArgs = #((meta or {}).args or {})

	local numShadowCallArgBytes = 16
	local numShadowLocalBytes = 16
	local numShadowExtraBytes = numShadowCallArgBytes + numShadowLocalBytes + numArgs * 8

	local localArgsTop = 32 + numShadowCallArgBytes
	local luaCallArgsTop = localArgsTop + numShadowLocalBytes

	local argsUserType = {}

	local labelSuffix = (meta or {}).labelSuffix or ""

	pushArgTemplate = function(argI)
		local userType = argsUserType[argI + 1]
		if userType == "" then
			return {[[
				mov rdx, qword ptr ss:[rsp+#$(1)] ]], {luaCallArgsTop + argI * 8}, [[ ; n
				mov rcx, rbx                                                        ; L
				#ALIGN
				call #L(Hardcoded_lua_pushinteger)
				#ALIGN_END
			]]}
		else
			return {[[
				mov r8, ]], EEex_WriteStringAuto(userType), [[                      ; type
				mov rdx, qword ptr ss:[rsp+#$(1)] ]], {luaCallArgsTop + argI * 8}, [[ ; value
				mov rcx, rbx                                                        ; L
				#ALIGN
				call #L(Hardcoded_tolua_pushusertype)
				#ALIGN_END
			]]}
		end
	end

	local returnBooleanTemplate = {[[
		mov rdx, -1  ; index
		mov rcx, rbx ; L
		#ALIGN
		call #L(Hardcoded_lua_toboolean)
		#ALIGN_END
		mov qword ptr ss:[rsp+#$(1)], rax ]], {localArgsTop + 8}, [[ #ENDL
	]]}

	local returnNumberTemplate = {[[
		mov r8, 0    ; isnum
		mov rdx, -1  ; index
		mov rcx, rbx ; L
		#ALIGN
		call #L(Hardcoded_lua_tointegerx)
		#ALIGN_END
		mov qword ptr ss:[rsp+#$(1)], rax ]], {localArgsTop + 8}, [[ #ENDL
	]]}

	local genArgPushes1 = function()

		local toReturn = {}
		local insertionIndex = 1

		if not meta then return toReturn end
		local args = meta.args
		if not args then return toReturn end

		for i = numArgs, 1, -1 do
			local argT, argUT = args[i](luaCallArgsTop + (i - 1) * 8)
			toReturn[insertionIndex] = argT
			argsUserType[i] = argUT or ""
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
			mov rdx, ]], EEex_WriteStringAuto("debug"), [[ ; name
			mov rcx, rbx                                   ; L
			#ALIGN
			call #L(Hardcoded_lua_getglobal)
			#ALIGN_END

			mov r8, ]], EEex_WriteStringAuto("traceback"), [[ ; k
			mov rdx, -1                                       ; index
			mov rcx, rbx                                      ; L
			#ALIGN
			call #L(Hardcoded_lua_getfield)
			#ALIGN_END
		]]}
		errorFuncLuaStackPopAmount = 2
	end

	local genFunc = function()
		if funcName then
			if meta then
				if meta.functionChunk then EEex_Error("[EEex_GenLuaCall] funcName and meta.functionChunk are exclusive") end
				if meta.functionSrc then EEex_Error("[EEex_GenLuaCall] funcName and meta.functionSrc are exclusive") end
			end
			return {[[
				mov rdx, ]], EEex_WriteStringAuto(funcName), [[ ; name
				mov rcx, rbx                                    ; L
				#ALIGN
				call #L(Hardcoded_lua_getglobal)
				#ALIGN_END
			]]}
		elseif meta then
			if meta.functionChunk then
				if numArgs > 0 then EEex_Error("[EEex_GenLuaCall] Lua chunks can't be passed arguments") end
				if meta.functionSrc then EEex_Error("[EEex_GenLuaCall] meta.functionChunk and meta.functionSrc are exclusive") end
				return EEex_FlattenTable({
					meta.functionChunk,
					{[[
						mov rcx, rbx ; L
						#ALIGN
						call short #L(Hardcoded_luaL_loadstring)
						#ALIGN_END

						test rax, rax
						jz EEex_GenLuaCall_loadstring_no_error#$(1) ]], {labelSuffix}, [[ #ENDL

						#IF ]], errorFunc ~= nil, [[ {

							; Call error function with loadstring message
							mov qword ptr ss:[rsp+40], 0 ; k
							mov qword ptr ss:[rsp+32], 0 ; ctx
							mov r9, 0                    ; errfunc
							mov r8, 1                    ; nresults
							mov rdx, 1                   ; nargs
							mov rcx, rbx                 ; L
							#ALIGN
							call #L(Hardcoded_lua_pcallk)
							#ALIGN_END

							mov rcx, rbx
							#ALIGN
							call #L(EEex_CheckCallError)
							#ALIGN_END

							test rax, rax
							jnz EEex_GenLuaCall_error_in_error_handling#$(1) ]], {labelSuffix}, [[ #ENDL

							mov rcx, rbx
							#ALIGN
							call #L(EEex_PrintPopLuaString)
							#ALIGN_END

							EEex_GenLuaCall_error_in_error_handling#$(1): ]], {labelSuffix}, [[ #ENDL
							; Clear error function precursors off of Lua stack
							mov rdx, ]], -errorFuncLuaStackPopAmount, [[ #ENDL
							mov rcx, rbx
							#ALIGN
							call #L(Hardcoded_lua_settop)
							#ALIGN_END

							jmp EEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
						}

						#IF ]], errorFunc == nil, [[ {
							mov rcx, rbx
							call #L(EEex_PrintPopLuaString)
							jmp EEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
						}

						EEex_GenLuaCall_loadstring_no_error#$(1): ]], {labelSuffix}, [[ #ENDL
					]]},
				})
			elseif meta.functionSrc then
				if meta.functionChunk then EEex_Error("[EEex_GenLuaCall] meta.functionSrc and meta.functionChunk are exclusive") end
				return meta.functionSrc
			end
		end

		EEex_Error("[EEex_GenLuaCall] meta.functionChunk or meta.functionSrc must be defined when funcName = nil")
	end

	local genArgPushes2 = function()

		local toReturn = {}
		local insertionIndex = 1

		if not meta then return toReturn end
		local args = meta.args
		if not args then return toReturn end

		for i = 0, numArgs - 1 do
			toReturn[insertionIndex] = pushArgTemplate(i)
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
	local toReturn = EEex_FlattenTable({
		{[[
			#MAKE_SHADOW_SPACE(#$(1)) ]], {numShadowExtraBytes}, [[
		]]},
		genArgPushes1(),
		(meta or {}).luaState or {[[
			mov qword ptr ss:[rsp+#$(1)], rbx ]], {localArgsTop}, [[ #ENDL
			mov rbx, #L(Hardcoded_InternalLuaState)
		]]},
		errorFunc or {},
		genFunc(),
		genArgPushes2(),
		{[[

			#ALIGN
			mov qword ptr ss:[rsp+8], 0                       ; k
			mov qword ptr ss:[rsp], 0                         ; ctx
			mov r9, ]], errorFunc and -(2 + numArgs) or 0, [[ ; errfunc
			mov r8, ]], numRet, [[                            ; nresults
			mov rdx, ]], numArgs, [[                          ; nargs
			mov rcx, rbx                                      ; L
			call short #L(Hardcoded_lua_pcallk)
			#ALIGN_END

			#ALIGN
			mov rcx, rbx
			call #L(EEex_CheckCallError)
			#ALIGN_END

			test rax, rax

			#IF ]], errorFunc ~= nil, [[ {
				jz short EEex_GenLuaCall_no_error#$(1) ]], {labelSuffix}, [[ #ENDL
				; Clear error function and its precursors off of Lua stack
				mov rdx, ]], -(1 + errorFuncLuaStackPopAmount), [[ ; index
				mov rcx, rbx                                       ; L
				#ALIGN
				call short #L(Hardcoded_lua_settop)
				#ALIGN_END
				jmp EEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
			}

			#IF ]], errorFunc == nil, [[ {
				jnz EEex_GenLuaCall_call_error#$(1) ]], {labelSuffix}, [[ #ENDL
			}

			EEex_GenLuaCall_no_error#$(1): ]], {labelSuffix}, [[ #ENDL
		]]},
		genReturnHandling(),
		{[[
			; Clear return values and error function (+ its precursors) off of Lua stack
			mov rdx, ]], -(1 + errorFuncLuaStackPopAmount + numRet), [[ ; index
			mov rcx, rbx                                                ; L
			#ALIGN
			call #L(Hardcoded_lua_settop)
			#ALIGN_END

			#IF ]], numRet > 0, [[ {
				mov rax, qword ptr ss:[rsp+#$(1)] ]], {localArgsTop + 8}, [[ #ENDL
			}

			jmp EEex_GenLuaCall_resume#$(1) ]], {labelSuffix}, [[ #ENDL

			EEex_GenLuaCall_call_error#$(1): ]], {labelSuffix}, [[ #ENDL
			mov rbx, qword ptr ss:[rsp+#$(1)] ]], {localArgsTop}, [[ #ENDL
			jmp call_error#$(1) ]], {labelSuffix}, [[ #ENDL

			EEex_GenLuaCall_resume#$(1): ]], {labelSuffix}, [[ #ENDL
			mov rbx, qword ptr ss:[rsp+#$(1)] ]], {localArgsTop}, [[ #ENDL
		]]},
	})

	return toReturn
end

----------------------
--  Bits Utilility  --
----------------------

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

function EEex_AreBitsSet(original, bitsString)
	return EEex_IsMaskSet(original, tonumber(bitsString, 2))
end

function EEex_IsMaskSet(original, isSetMask)
	return EEex_BAnd(original, isSetMask) == isSetMask
end

function EEex_IsBitUnset(original, isUnsetIndex)
	return EEex_BAnd(original, EEex_LShift(0x1, isUnsetIndex)) == 0x0
end

function EEex_AreBitsUnset(original, bitsString)
	return EEex_IsMaskUnset(original, tonumber(bitsString, 2))
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

function EEex_UnsetBit(original, toUnsetIndex)
	return EEex_BAnd(original, EEex_BNot(EEex_LShift(0x1, toUnsetIndex)))
end

function EEex_UnsetBits(original, bitsString)
	return EEex_UnsetMask(original, tonumber(bitsString, 2))
end

function EEex_UnsetMask(original, toUnsetmask)
	return EEex_BAnd(original, EEex_BNot(toUnsetmask))
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

function EEex_AssemblyToHex(number)

	local hexT = {}
	local insertI = 1

	repeat
		hexT[insertI] = string.format("%x", EEex_Extract(number, 0, 4)):upper()
		insertI = insertI + 1
		number = EEex_RShift(number, 4)
	until number == 0x0

	hexT = EEex_ReverseTable(hexT, insertI - 1)
	hexT[insertI] = "h"
	return table.concat(hexT)
end

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

-------------------------------
-- Dynamic Memory Allocation --
-------------------------------

function EEex_Subtable(t, startI, endI)
	local subtable = {}
	local insertI = 1
	for i = startI, endI or #t do
		subtable[insertI] = t[i]
		insertI = insertI + 1
	end
	return subtable
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

function EEex_PreprocessAssemblyStr(assemblyT, curI, assemblyStr)

	local advanceCount = 1

	-- #IF
	assemblyStr = EEex_ReplacePattern(assemblyStr, "#IF(.*)", function(match)
		if EEex_FindPattern(match.groups[1], "[^%s]") then EEex_Error("Text between #IF and immediate condition") end
		advanceCount = 2
		local conditionV = assemblyT[curI + 1]
		if type(conditionV) == "boolean" then
			local hadBody = false
			local bodyI = curI + 2
			local bodyV = assemblyT[bodyI]
			if type(bodyV) == "string" then
				local hadOpen = false
				bodyV = EEex_ReplacePattern(bodyV, "^%s*{(.*)", function(bodyMatch)
					hadOpen = true
					return bodyMatch.groups[1], true
				end)
				assemblyT[bodyI] = bodyV
				if hadOpen then
					local curLevel = 1
					while true do
						if type(bodyV) == "string" then
							hadBody, findV = EEex_FindClosing(bodyV, "{", "}", curLevel)
							if hadBody then
								if conditionV and findV > 1 then
									assemblyT[bodyI] = bodyV:sub(1, findV - 1)..bodyV:sub(findV + 1)
								else
									assemblyT[bodyI] = bodyV:sub(findV + 1)
								end
								break
							end
							curLevel = findV
						end
						if not conditionV then
							advanceCount = advanceCount + 1
						end
						bodyI = bodyI + 1
						bodyV = assemblyT[bodyI]
						if bodyV == nil then break end
						curLevel = findV
					end
				end
			end
			if not hadBody then EEex_Error("#IF has no immediate body") end
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
		return tostring(argsTable[argIndex])
	end)

	-- #L
	assemblyStr = EEex_ReplacePattern(assemblyStr, "#L(%b())", function(match)
		return EEex_AssemblyToHex(EEex_Label(match.groups[1]:sub(2, -2)))
	end)

	--#REPEAT
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

function EEex_PreprocessAssembly(assemblyT)

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
			builtStr[insertI] = tostring(v)
			insertI = insertI + 1
		else
			EEex_Error("Unexpected type encountered during JIT: "..vtype)
		end
		i = i + advanceCount
	end

	builtStr[insertI] = "\n" -- Always end with a newline
	local toReturn = table.concat(builtStr)

	--[[
		I would never abuse regex, I swear!
		(Please forgive the following code)
		#STACK_MOD((-\d+)[1])
		(#MAKE_SHADOW_SPACE((\d+)[3?]))[2]
		(#DESTROY_SHADOW_SPACE(KEEP_ENTRY)[5?])[4]
		(#ALIGN_END)[6]
		(#ALIGN((\d+)[8?]))[7]
		(#SHADOW_SPACE_BOTTOM((\d+)[10?]))[9]
		(#RESUME_SHADOW_ENTRY)[11]
	--]]

	local shadowSpaceStack = {}
	local shadowSpaceStackTop = 0
	local alignModStack = {}
	local alignModStackTop = 0
	local hintAccumulator = 0

	toReturn = EEex_ReplaceRegex(toReturn, "(?:#STACK_MOD\\s*\\((-{0,1}\\d+)\\))|(#MAKE_SHADOW_SPACE(?:\\s*\\((\\d+)\\)){0,1})|(#DESTROY_SHADOW_SPACE(?:(?!\\(.*?\\))|(?:\\((KEEP_ENTRY)\\))))|(#ALIGN_END)|(#ALIGN(?:\\s*\\((\\d+)\\)){0,1})|(#SHADOW_SPACE_BOTTOM\\s*\\((-{0,1}.+)\\))|(#RESUME_SHADOW_ENTRY)", function(pos, endPos, str, groups)
		if groups[1] then
			--print("#STACK_MOD("..tonumber(groups[1])..")")
			hintAccumulator = hintAccumulator + tonumber(groups[1])
		elseif groups[2] then
			--print("#MAKE_SHADOW_SPACE")
			local neededShadow = 32 + (groups[3] and tonumber(groups[3]) or 0)
			if shadowSpaceStackTop > 0 and shadowSpaceStack[shadowSpaceStackTop].top == hintAccumulator then
				local shadowEntry = shadowSpaceStack[shadowSpaceStackTop]
				if shadowEntry.sizeNoRounding < neededShadow then
					print(debug.traceback("[!] #MAKE_SHADOW_SPACE redefined where original failed to provide enough space! Correct this by expanding "..(shadowEntry.sizeNoRounding - 32).." to "..(neededShadow - 32).."; continuing with suboptimal configuration."))
					local sizeDiff = EEex_RoundUp(neededShadow, 16) - shadowEntry.size
					hintAccumulator = hintAccumulator + sizeDiff
					shadowEntry.top = shadowEntry.top + sizeDiff
					shadowEntry.size = shadowEntry.size + sizeDiff
					-- Ideally this would be merged with the previous shadow space instruction, but abusing
					-- regex like this doesn't help make that happen, (would require an additional pass)
					return string.format("sub rsp, %d #ENDL", sizeDiff)
				end
			else
				local neededStack = EEex_DistanceToMultiple(hintAccumulator + neededShadow, 16) + neededShadow
				hintAccumulator = hintAccumulator + neededStack
				shadowSpaceStackTop = shadowSpaceStackTop + 1
				shadowSpaceStack[shadowSpaceStackTop] = {
					["top"] = hintAccumulator,
					["size"] = neededStack,
					["sizeNoRounding"] = neededShadow,
				}
				return string.format("sub rsp, %d #ENDL", neededStack)
			end
		elseif groups[4] then
			--print("#DESTROY_SHADOW_SPACE")
			local shadowEntry = shadowSpaceStack[shadowSpaceStackTop]
			if not groups[5] then
				shadowSpaceStackTop = shadowSpaceStackTop - 1
			end
			hintAccumulator = hintAccumulator - shadowEntry.size
			-- LEA maintains flags (as opposed to SUB), which allows us to test a register
			-- and restore it before calling #DESTROY_SHADOW_SPACE and still use the result
			-- for a branch.
			return string.format("lea rsp, qword ptr ss:[rsp+%d]", shadowEntry.size)
		elseif groups[6] then
			--print("#ALIGN_END")
			local alignEntry = alignModStack[alignModStackTop]
			if alignEntry.madeShadow then shadowSpaceStackTop = shadowSpaceStackTop - 1 end
			alignModStackTop = alignModStackTop - 1
			if alignEntry.popAmount > 0 then
				return string.format("add rsp, %d #ENDL", tonumber(alignEntry.popAmount))
			end
		elseif groups[7] then
			local pushedArgBytes = groups[8] and tonumber(groups[8]) or 0
			--print("#ALIGN("..pushedArgBytes..")")
			local neededShadow = 0
			if shadowSpaceStackTop == 0 or shadowSpaceStack[shadowSpaceStackTop].top ~= hintAccumulator then
				neededShadow = 32
				shadowSpaceStackTop = shadowSpaceStackTop + 1
				shadowSpaceStack[shadowSpaceStackTop] = {
					["top"] = hintAccumulator,
					["size"] = neededShadow,
					["sizeNoRounding"] = neededShadow,
				}
			end
			local neededStack = EEex_DistanceToMultiple(hintAccumulator + neededShadow + pushedArgBytes, 16) + neededShadow - pushedArgBytes
			alignModStackTop = alignModStackTop + 1
			alignModStack[alignModStackTop] = {
				["popAmount"] = neededStack + pushedArgBytes,
				["madeShadow"] = neededShadow > 0,
			}
			if neededStack > 0 then
				return string.format("sub rsp, %d #ENDL", neededStack)
			end
		elseif groups[9] then
			--print("#SHADOW_SPACE_BOTTOM")
			local adjust = 0
			local adjustStr = groups[10]
			if adjustStr then
				adjust = adjustStr:sub(-1) == "h" and tonumber(adjustStr:sub(1,-2), 16) or tonumber(adjustStr)
			end
			return tostring(shadowSpaceStack[shadowSpaceStackTop].size + adjust)
		elseif groups[11] then
			hintAccumulator = hintAccumulator + shadowSpaceStack[shadowSpaceStackTop].size
		end
		return ""
	end)

	-- Standardize string
	toReturn = EEex_ReplacePattern(toReturn, "#ENDL", "\n")    -- Turn ENDL markers into newlines
	toReturn = EEex_ReplacePattern(toReturn, "[ \t]+\n", "\n") -- Remove whitespace before newlines (trailing whitespace)
	toReturn = EEex_ReplacePattern(toReturn, "\n+", "\n")      -- Merge newlines
	toReturn = EEex_ReplacePattern(toReturn, "\n[ \t]+", "\n") -- Remove whitespace after newlines, (indentation)
	toReturn = EEex_ReplacePattern(toReturn, "^[ \t]+", "")    -- Remove initial indent

	--print("EEex_PreprocessAssembly returning:\n\n"..toReturn.."\n")
	return toReturn
end

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

function EEex_JITNear(assemblyT)

	local assemblyStr = EEex_PreprocessAssembly(assemblyT)

	local finalWriteSize
	local currentCodePageI = 0
	local currentAllocEntryI = 1
	local alreadyAllocatedCodePage = false

	local getOrCreateAllocEntryIterate = function(func)
		local curCodePage
		repeat
			curCodePage = EEex_CodePageAllocations[currentCodePageI]
			if curCodePage and currentAllocEntryI < #curCodePage then
				currentAllocEntryI = currentAllocEntryI + 1
			else
				currentCodePageI = currentCodePageI + 1
				curCodePage = EEex_CodePageAllocations[currentCodePageI]
				if not curCodePage then
					if alreadyAllocatedCodePage then return true end
					alreadyAllocatedCodePage = true
					curCodePage = EEex_AllocCodePage()
				end
				currentAllocEntryI = 1
			end
		until func(curCodePage[currentAllocEntryI])
	end

	local checkJIT = function(writeSize)
		local checkEntry = EEex_CodePageAllocations[currentCodePageI][currentAllocEntryI]
		if writeSize > checkEntry.size then
			local newDst
			failed = getOrCreateAllocEntryIterate(function(allocEntry)
				if allocEntry.reserved then return end
				newDst = allocEntry.address
				return true
			end)
			return failed and -1 or newDst
		end
		finalWriteSize = writeSize
		return 0
	end

	local finalAllocEntry
	getOrCreateAllocEntryIterate(function(firstAllocEntry)

		if firstAllocEntry.reserved then return end
		EEex_JITAtInternal(firstAllocEntry.address, checkJIT, assemblyStr)
		if not finalWriteSize then
			EEex_Error("Failed to allocate memory for EEex_JITNear().")
		end

		local finalCodePage = EEex_CodePageAllocations[currentCodePageI]
		finalAllocEntry = finalCodePage[currentAllocEntryI]

		local memLeftOver = finalAllocEntry.size - finalWriteSize
		if memLeftOver > 0 then
			local newAddress = finalAllocEntry.address + finalWriteSize
			local nextEntry = finalCodePage[currentAllocEntryI + 1]
			if nextEntry then
				if not nextEntry.reserved then
					local addressDifference = nextEntry.address - newAddress
					nextEntry.address = newAddress
					nextEntry.size = finalAllocEntry.size + addressDifference
				else
					local newEntry = {}
					newEntry.address = newAddress
					newEntry.size = memLeftOver
					newEntry.reserved = false
					table.insert(finalCodePage, newEntry, currentAllocEntryI + 1)
				end
			else
				local newEntry = {}
				newEntry.address = newAddress
				newEntry.size = memLeftOver
				newEntry.reserved = false
				table.insert(finalCodePage, newEntry)
			end
		end
		finalAllocEntry.size = finalWriteSize
		finalAllocEntry.reserved = true
		return true
	end)

	return finalAllocEntry.address
end

function EEex_JITNearAsLabel(label, assemblyT)
	EEex_DefineAssemblyLabel(label, EEex_JITNear(assemblyT))
end

function EEex_JITNearAsLuaFunction(luaFunctionName, assemblyT)
	local address = EEex_JITNear(assemblyT)
	EEex_ExposeToLua(address, luaFunctionName)
	return address
end

function EEex_JITAt(dst, assemblyT)
	local assemblyStr = EEex_PreprocessAssembly(assemblyT)
	local checkJIT = function(writeSize) return 0 end
	EEex_JITAtInternal(dst, checkJIT, assemblyStr)
end
