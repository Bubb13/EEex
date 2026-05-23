
-- IMPORTANT: These enum values are part of the shared EEex marshal table schema.
-- Do not modify existing values without implementing migration code for every channel.
EEex_Marshal_Private_TableFieldType = {
	["TABLE_END"]     = 0,
	["TABLE_START"]   = 1,
	["STRING"]        = 2,
	["INT8"]          = 3,
	["INTU8"]         = 4,
	["INT16"]         = 5,
	["INTU16"]        = 6,
	["INT32"]         = 7,
	["INTU32"]        = 8,
	["INT64"]         = 9,
	["INTU64"]        = 10,
	["BOOLEAN_FALSE"] = 11,
	["BOOLEAN_TRUE"]  = 12,
}

function EEex_Marshal_Private_NewTableBundle()
	return {
		["entries"] = {},
		["entryCount"] = 0,
		["tableToMeta"] = {},
		["memorySize"] = 0,
	}
end

function EEex_Marshal_Private_ResetTableBundle(bundle)
	bundle["entries"] = {}
	bundle["entryCount"] = 0
	bundle["tableToMeta"] = {}
	bundle["memorySize"] = 0
end

function EEex_Marshal_Private_AssertTableString(value, context)
	if value:find("\0", 1, true) then
		EEex_Error((context or "Marshal").." strings cannot contain NUL bytes")
	end
end

function EEex_Marshal_Private_AddTableBundleEntry(bundle, handlerName, toExport, context)
	if type(handlerName) ~= "string" or handlerName == "" then
		EEex_Error((context or "Marshal").." handler name must be a non-empty string")
	end
	EEex_Marshal_Private_AssertTableString(handlerName, context)
	if type(toExport) ~= "table" then
		EEex_Error((context or "Marshal").." handler must export table or nil")
	end
	if bundle["tableToMeta"][toExport] then
		EEex_Error((context or "Marshal").." exported the same table more than once")
	end
	bundle["entryCount"] = bundle["entryCount"] + 1
	bundle["entries"][bundle["entryCount"]] = toExport
	bundle["tableToMeta"][toExport] = {
		["handlerName"] = handlerName,
	}
end

function EEex_Marshal_Private_DetermineTableNumberInfo(number, context)
	if number ~= number or number % 1 ~= 0 then
		EEex_Error((context or "Marshal").." number must be an integer")
	end
	if number >= 0 then
		if number <= 0xFF then
			return EEex_Marshal_Private_TableFieldType.INTU8, EEex_WriteU8, 1
		elseif number <= 0xFFFF then
			return EEex_Marshal_Private_TableFieldType.INTU16, EEex_WriteU16, 2
		elseif number <= 0xFFFFFFFF then
			return EEex_Marshal_Private_TableFieldType.INTU32, EEex_WriteU32, 4
		elseif number <= 0xFFFFFFFFFFFFFFFF then
			return EEex_Marshal_Private_TableFieldType.INTU64, EEex_WriteU64, 8
		else
			EEex_Error((context or "Marshal").." number is outside the supported range")
		end
	else
		if number >= -0x100 then
			return EEex_Marshal_Private_TableFieldType.INT8, EEex_Write8, 1
		elseif number >= -0x10000 then
			return EEex_Marshal_Private_TableFieldType.INT16, EEex_Write16, 2
		elseif number >= -0x100000000 then
			return EEex_Marshal_Private_TableFieldType.INT32, EEex_Write32, 4
		elseif number >= -0x10000000000000000 then
			return EEex_Marshal_Private_TableFieldType.INT64, EEex_Write64, 8
		else
			EEex_Error((context or "Marshal").." number is outside the supported range")
		end
	end
end

function EEex_Marshal_Private_CalculateTableBundleSize(bundle, context)

	local accumulator = 0
	local lengthTypeSwitch = {
		["boolean"] = function(v)
			return 0
		end,
		["number"] = function(v)
			local _, _, writeAdvance = EEex_Marshal_Private_DetermineTableNumberInfo(v, context)
			return writeAdvance
		end,
		["string"] = function(v)
			EEex_Marshal_Private_AssertTableString(v, context)
			return #v + 1
		end,
	}

	local processStack = {{bundle["entries"], nil}} -- toProcessT, iterK
	local activeTables = {
		[bundle["entries"]] = true,
	}
	local stackTop = 1

	while true do

		::continue::
		local toProcess = processStack[stackTop]
		local toProcessT = toProcess[1]

		while true do

			local k, v = next(toProcessT, toProcess[2])
			if k == nil then
				break
			end
			local kType = type(k)
			if kType ~= "boolean" and kType ~= "number" and kType ~= "string" then
				EEex_Error((context or "Marshal").." only supports boolean, number, and string keys")
			end

			toProcess[2] = k

			if stackTop == 1 then
				local meta = bundle["tableToMeta"][v]
				if not meta then
					EEex_Error((context or "Marshal").." top-level table is missing handler metadata")
				end
				local handlerName = meta["handlerName"]
				accumulator = accumulator + #handlerName + 1
				if activeTables[v] then
					EEex_Error((context or "Marshal").." table cycle detected")
				end
				activeTables[v] = true
				stackTop = stackTop + 1
				processStack[stackTop] = {v, nil}
				goto continue
			else
				local vType = type(v)
				if vType ~= "boolean" and vType ~= "number" and vType ~= "string" and vType ~= "table" then
					EEex_Error((context or "Marshal").." only supports boolean, number, string, and table values")
				end
				if vType == "table" then
					-- KEY_FIELD_TYPE + KEY_LENGTH + TABLE_START
					accumulator = accumulator + 1 + lengthTypeSwitch[kType](k) + 1
					if activeTables[v] then
						EEex_Error((context or "Marshal").." table cycle detected")
					end
					activeTables[v] = true
					stackTop = stackTop + 1
					processStack[stackTop] = {v, nil}
					goto continue
				end
				-- KEY_FIELD_TYPE + KEY_LENGTH + VALUE_FIELD_TYPE + VALUE_LENGTH
				accumulator = accumulator + 1 + lengthTypeSwitch[kType](k) + 1 + lengthTypeSwitch[vType](v)
			end
		end

		accumulator = accumulator + 1 -- TABLE_END

		activeTables[toProcessT] = nil
		processStack[stackTop] = nil
		stackTop = stackTop - 1

		if stackTop == 0 then
			break
		end
	end

	return accumulator
end

function EEex_Marshal_Private_WriteTableBundle(memoryPtr, bundle, context)

	local writeNumber = function(number)
		local typeByte, writeFunc, writeAdvance = EEex_Marshal_Private_DetermineTableNumberInfo(number, context)
		EEex_Write8(memoryPtr, typeByte)
		memoryPtr = memoryPtr + 1
		writeFunc(memoryPtr, number)
		memoryPtr = memoryPtr + writeAdvance
	end

	local writeTypeSwitch = {
		["boolean"] = function(v)
			EEex_Write8(memoryPtr, v
				and EEex_Marshal_Private_TableFieldType.BOOLEAN_TRUE
				or  EEex_Marshal_Private_TableFieldType.BOOLEAN_FALSE
			)
			memoryPtr = memoryPtr + 1
		end,
		["number"] = writeNumber,
		["string"] = function(v)
			EEex_Marshal_Private_AssertTableString(v, context)
			EEex_Write8(memoryPtr, EEex_Marshal_Private_TableFieldType.STRING)
			memoryPtr = memoryPtr + 1
			EEex_WriteString(memoryPtr, v)
			memoryPtr = memoryPtr + #v + 1
		end,
		["table"] = function(v)
			EEex_Write8(memoryPtr, EEex_Marshal_Private_TableFieldType.TABLE_START)
			memoryPtr = memoryPtr + 1
		end,
	}

	local processStack = {{bundle["entries"], nil}} -- toProcessT, iterK
	local activeTables = {
		[bundle["entries"]] = true,
	}
	local stackTop = 1

	while true do

		::continue::
		local toProcess = processStack[stackTop]
		local toProcessT = toProcess[1]

		while true do

			local k, v = next(toProcessT, toProcess[2])
			if k == nil then
				break
			end
			local kType = type(k)
			if kType ~= "boolean" and kType ~= "number" and kType ~= "string" then
				EEex_Error((context or "Marshal").." only supports boolean, number, and string keys")
			end

			toProcess[2] = k

			if stackTop == 1 then
				local meta = bundle["tableToMeta"][v]
				if not meta then
					EEex_Error((context or "Marshal").." top-level table is missing handler metadata")
				end
				local handlerName = meta["handlerName"]
				EEex_Marshal_Private_AssertTableString(handlerName, context)
				EEex_WriteString(memoryPtr, handlerName)
				memoryPtr = memoryPtr + #handlerName + 1
			else
				local vType = type(v)
				if vType ~= "boolean" and vType ~= "number" and vType ~= "string" and vType ~= "table" then
					EEex_Error((context or "Marshal").." only supports boolean, number, string, and table values")
				end
				writeTypeSwitch[kType](k)
				writeTypeSwitch[vType](v)
			end

			if type(v) == "table" then
				if activeTables[v] then
					EEex_Error((context or "Marshal").." table cycle detected")
				end
				activeTables[v] = true
				stackTop = stackTop + 1
				processStack[stackTop] = {v, nil}
				goto continue
			end
		end

		EEex_Write8(memoryPtr, EEex_Marshal_Private_TableFieldType.TABLE_END)
		memoryPtr = memoryPtr + 1

		activeTables[toProcessT] = nil
		processStack[stackTop] = nil
		stackTop = stackTop - 1

		if stackTop == 0 then
			break
		end
	end
end

function EEex_Marshal_Private_ReadTableBundle(memory, handlerReader)

	local baseMemory = memory

	while true do

		local toFill = {}
		local handlerStr = EEex_ReadString(memory)
		memory = memory + #handlerStr + 1

		-- The top-level list writes TABLE_END('\0') to signal that all
		-- marshalled data has ended, which reads as an empty string.
		if handlerStr == "" then
			break
		end

		local fieldReadSwitch = {
			[EEex_Marshal_Private_TableFieldType.STRING] = function()
				local read = EEex_ReadString(memory)
				memory = memory + #read + 1
				return read
			end,
			[EEex_Marshal_Private_TableFieldType.INT8] = function()
				local read = EEex_Read8(memory)
				memory = memory + 1
				return read
			end,
			[EEex_Marshal_Private_TableFieldType.INTU8] = function()
				local read = EEex_ReadU8(memory)
				memory = memory + 1
				return read
			end,
			[EEex_Marshal_Private_TableFieldType.INT16] = function()
				local read = EEex_Read16(memory)
				memory = memory + 2
				return read
			end,
			[EEex_Marshal_Private_TableFieldType.INTU16] = function()
				local read = EEex_ReadU16(memory)
				memory = memory + 2
				return read
			end,
			[EEex_Marshal_Private_TableFieldType.INT32] = function()
				local read = EEex_Read32(memory)
				memory = memory + 4
				return read
			end,
			[EEex_Marshal_Private_TableFieldType.INTU32] = function()
				local read = EEex_ReadU32(memory)
				memory = memory + 4
				return read
			end,
			[EEex_Marshal_Private_TableFieldType.INT64] = function()
				local read = EEex_Read64(memory)
				memory = memory + 8
				return read
			end,
			[EEex_Marshal_Private_TableFieldType.INTU64] = function()
				local read = EEex_ReadU64(memory)
				memory = memory + 8
				return read
			end,
			[EEex_Marshal_Private_TableFieldType.BOOLEAN_FALSE] = function()
				return false
			end,
			[EEex_Marshal_Private_TableFieldType.BOOLEAN_TRUE] = function()
				return true
			end,
		}

		local tableStack = {}
		local tableStackTop = 0

		while true do

			local keyFieldType = EEex_Read8(memory)
			memory = memory + 1

			if keyFieldType == EEex_Marshal_Private_TableFieldType.TABLE_END then
				if tableStackTop == 0 then
					break
				end
				toFill = tableStack[tableStackTop]
				tableStackTop = tableStackTop - 1
			else
				local keyReader = fieldReadSwitch[keyFieldType]
				if not keyReader then
					EEex_Error("Unknown marshal key field type "..keyFieldType)
				end
				local key = keyReader()
				local valueFieldType = EEex_Read8(memory)
				memory = memory + 1
				if valueFieldType == EEex_Marshal_Private_TableFieldType.TABLE_START then
					local subTable = {}
					toFill[key] = subTable
					tableStackTop = tableStackTop + 1
					tableStack[tableStackTop] = toFill
					toFill = subTable
				else
					local valueReader = fieldReadSwitch[valueFieldType]
					if not valueReader then
						EEex_Error("Unknown marshal value field type "..valueFieldType)
					end
					toFill[key] = valueReader()
				end
			end
		end

		handlerReader(handlerStr, toFill)
	end

	return memory - baseMemory
end
