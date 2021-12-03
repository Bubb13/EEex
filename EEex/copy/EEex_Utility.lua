
function EEex_Utility_FreeCPtrList(list)
	while list.m_nCount > 0 do
		EEex_FreeUD(list:RemoveHead())
	end
	list:Destruct()
	EEex_FreeUD(list)
end

function EEex_Utility_IterateCPtrList(list, func)
	local node = list.m_pNodeHead
	while node do
		if func(node.data) then break end
		node = node.pNext
	end
end

function EEex_Utility_DumpMetatables(obj)
	local meta = obj
	local i = 0
	while true do
		meta = getmetatable(meta)
		if not meta then break end
		B3Dump("meta["..i.."]", meta)
		i = i + 1
	end
end

---------------
-- EEex_Dump --
---------------

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
					entry.string = tableValueType..' '..tostring(tableKey)..':'
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
