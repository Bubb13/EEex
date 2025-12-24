
function EEex_Utility_AlphanumericCompare(a, b)
	local conv = function(s)
		local result, lastPeriod = "", ""
		for digits, nonZeroDigits, anythingChar in tostring(s):gmatch("(0*(%d*))(.?)") do
			if digits == "" then
				lastPeriod, anythingChar = "", lastPeriod..anythingChar
			else
				result = result..(lastPeriod == "" and ("%03d%s"):format(#nonZeroDigits, nonZeroDigits) or "."..digits)
				lastPeriod, anythingChar = anythingChar:match("(%.?)(.*)")
			end
			result = result..anythingChar:gsub(".", "\0%0")
		end
		return result
	end
	local ca, cb = conv(a), conv(b)
	return ca < cb or (ca == cb and a < b)
end

function EEex_Utility_AlphanumericSortTable(o, stringAccessor)
	table.sort(o, function(a, b) return EEex_Utility_AlphanumericCompare(stringAccessor(a), stringAccessor(b)) end)
	return o
end

function EEex_Utility_CallIfExists(func, ...)
	if func then return func(...) end
end

function EEex_Utility_CallSuper(t, funcName, ...)
	local mt = getmetatable(t)
	if mt == nil then return end
	local superFunc = mt[funcName]
	if superFunc == nil then return end
	return superFunc(...)
end

-- @bubb_doc { EEex_Utility_DeepCopy }
-- @deprecated: Use ``EEex.DeepCopy`` instead.
function EEex_Utility_DeepCopy(t)
	-- [EEex.dll]
	return EEex.DeepCopy(t)
end

function EEex_Utility_Default(value, default)
	if value == nil then return default else return value end
end

function EEex_Utility_Eval(src, chunk)
	local func, err = load(chunk, nil, "t")
	if func then
		local success, val = xpcall(func, EEex_ErrorMessageHandler)
		if success then
			return true, val
		end
		print(string.format("[%s] Runtime error: %s", src, val))
	else
		print(string.format("[%s] Compile error: %s", src, err))
	end
	return false
end

function EEex_Utility_Find(iterable, element)
	for i, itrElement in ipairs(iterable) do
		if itrElement == element then
			return i
		end
	end
	return nil
end

function EEex_Utility_FreeCPtrList(list)
	while list.m_nCount > 0 do
		EEex_FreeUD(list:RemoveHead())
	end
	list:Destruct()
	EEex_FreeUD(list)
end

-- @bubb_doc { EEex_Utility_GetMicroseconds }
--
-- @summary: Returns the number of microseconds that have elapsed since EEex's initialization.
--
-- @return { type=number }: See summary.

function EEex_Utility_GetMicroseconds()
	return EEex.GetMicroseconds()
end

function EEex_Utility_GetOrCreate(t, key, default)
	local v = t[key]
	if v ~= nil then return v end
	t[key] = default
	return default
end

function EEex_Utility_GetOrCreateTable(t, key, fillFunc)
	local v = t[key]
	if v ~= nil then return v end
	local default = {}
	if fillFunc then fillFunc(default) end
	t[key] = default
	return default
end

function EEex_Utility_IterateCPtrList(list, func)
	local node = list.m_pNodeHead
	while node do
		if func(node.data) then break end
		node = node.pNext
	end
end

function EEex_Utility_IterateMapAsSorted(map, sortFunc, func)
	local t = EEex_Utility_MapToSortedTable(map, sortFunc)
	for i, v in ipairs(t) do
		func(i, v[1], v[2])
	end
end

function EEex_Utility_MapToSortedTable(map, sortFunc)
	local t = {}
	local insertI = 1
	for k, v in pairs(map) do
		t[insertI] = { k, v }
		insertI = insertI + 1
	end
	table.sort(t, sortFunc)
	return t
end

function EEex_Utility_Merge(t)
	local result = {}
	for k1, v1 in pairs(t) do
		if type(v1) == "table" then
			for k2, v2 in pairs(v1) do
				result[k2] = v2
			end
		else
			result[k1] = v1
		end
	end
	return result
end

function EEex_Utility_NewScope(func)
	return func()
end

function EEex_Utility_Split(text, splitBy, usePattern, allowEmptyCapture)
	return EEex_Split(text, splitBy, usePattern, allowEmptyCapture)
end

function EEex_Utility_Switch(toSwitchOn, cases, defaultCase)
	local func = cases[toSwitchOn]
	if func then
		func()
	elseif defaultCase then
		defaultCase()
	end
end

function EEex_Utility_Ternary(condition, ifTrue, ifFalse)
	if condition then return ifTrue() else return ifFalse() end
end

function EEex_Utility_TryCatch(func, ...)
	return { xpcall(func, EEex_ErrorMessageHandler, ...) }
end

function EEex_Utility_TryFinally(func, finally, ...)
	local result = EEex_Utility_TryCatch(func, ...)
	finally()
	if not result[1] then error(result[2], 0) end
	return select(2, table.unpack(result))
end

function EEex_Utility_TryIgnore(func, ...)
	local result = EEex_Utility_TryCatch(func, ...)
	if not result[1] then
		print(result[2])
		return
	end
	return select(2, table.unpack(result))
end

---------------
-- Iterators --
---------------

-- Expects - {itr[1], itr[2], ..., itr[n]}
-- Returns - Itr such that:
--             -> itr[1]()..., itr[2]()..., ..., itr[n]()...
function EEex_Utility_ChainIteratorsTable(iterators)

	local curItr = iterators[1]
	if curItr == nil then
		return function()
			return nil
		end
	end
	local i = 1

	return function()
		while true do
			local values = {curItr()}
			if values[1] ~= nil then
				return table.unpack(values)
			else
				i = i + 1
				curItr = iterators[i]
				if curItr == nil then
					return nil
				end
			end
		end
	end
end
EEex_Utility_ChainItrsTable = EEex_Utility_ChainIteratorsTable
EEex_Utility_ChainItrsT = EEex_Utility_ChainIteratorsTable
EEex_Utility_ChainIteratorsT = EEex_Utility_ChainIteratorsTable

-- Expects - <itr[1], itr[2], ..., itr[n]>
-- Returns - Itr such that:
--             -> itr[1]()..., itr[2]()..., ..., itr[n]()...
function EEex_Utility_ChainIterators(...)
	return EEex_Utility_ChainIteratorsTable({...})
end
EEex_Utility_ChainItrs = EEex_Utility_ChainIterators

-- Expects - {itrGen[1], itrGen[2], ..., itrGen[n]}
-- Returns - Itr such that:
--             -> [itrGen[1]()...]..., [itrGen[2]()...]..., ..., [itrGen[n]()...]...
function EEex_Utility_ChainIteratorGeneratorsTable(generators)

	local curGenerator = generators[1]
	if curGenerator == nil then
		return function()
			return nil
		end
	end
	local i = 1

	local curItr
	local nextItr = function()
		while true do
			curItr = curGenerator()
			if curItr ~= nil then
				return true
			end
			i = i + 1
			curGenerator = generators[i]
			if curGenerator == nil then
				return false
			end
		end
	end
	if not nextItr() then
		return function()
			return nil
		end
	end

	return function()
		while true do
			local values = {curItr()}
			if values[1] ~= nil then
				return table.unpack(values)
			elseif not nextItr() then
				return nil
			end
		end
	end
end
EEex_Utility_ChainItrGeneratorsTable = EEex_Utility_ChainIteratorGeneratorsTable
EEex_Utility_ChainItrGeneratorsT = EEex_Utility_ChainIteratorGeneratorsTable
EEex_Utility_ChainItrGensTable = EEex_Utility_ChainIteratorGeneratorsTable
EEex_Utility_ChainItrGensT = EEex_Utility_ChainIteratorGeneratorsTable
EEex_Utility_ChainIteratorGensTable = EEex_Utility_ChainIteratorGeneratorsTable
EEex_Utility_ChainIteratorGensT = EEex_Utility_ChainIteratorGeneratorsTable

-- Expects - <itrGen[1], itrGen[2], ..., itrGen[n]>
-- Returns - Itr such that:
--             -> [itrGen[1]()...]..., [itrGen[2]()...]..., ..., [itrGen[n]()...]...
function EEex_Utility_ChainIteratorGenerators(...)
	return EEex_Utility_ChainIteratorGeneratorsTable({...})
end
EEex_Utility_ChainItrGenerators = EEex_Utility_ChainIteratorGenerators
EEex_Utility_ChainItrGens = EEex_Utility_ChainIteratorGenerators
EEex_Utility_ChainIteratorGens = EEex_Utility_ChainIteratorGenerators

-- Expects - <i, itr>
-- Returns - Itr such that:
--              * n = <number of itr elements>
--             -> select(i, itr[1]), select(i, itr[2]), ..., select(i, itr[n])
function EEex_Utility_SelectIterator(i, iterator)
	return function()
		return select(i, iterator())
	end
end
EEex_Utility_SelectItr = EEex_Utility_SelectIterator

-- Expects - <table>
-- Returns - Itr such that:
--              * n = <number of table elements>
--             -> t[1], t[2], ..., t[n]
function EEex_Utility_TableIterator(t)
	local i = 0
	return function()
		i = i + 1
		local v = t[i]
		if v == nil then
			return nil
		end
		return v
	end
end
EEex_Utility_TableItr = EEex_Utility_TableIterator

-- Expects - <v[1], v[2], ..., v[n]>
-- Returns - Itr such that:
--             -> v[1], v[2], ..., v[n]
function EEex_Utility_ValuesIterator(...)
	return EEex_Utility_TableIterator({...})
end
EEex_Utility_ValuesItr = EEex_Utility_ValuesIterator

-- Expects - <itr, func>
-- Returns - Itr such that:
--              * n = <number of itr elements>
--             -> func(itr[1]), func(itr[2]), ..., func(itr[n])
function EEex_Utility_ApplyIterator(iterator, func)
	return function()
		local values = {iterator()}
		if values[1] == nil then
			return nil
		end
		return func(table.unpack(values))
	end
end
EEex_Utility_ApplyItr = EEex_Utility_ApplyIterator

-- Expects - <itr, func>
-- Returns - Itr such that:
--              * n = <number of itr elements>
--              * Executes func(itr[1]), func(itr[2]), ..., func(itr[n])
--             -> itr[1], itr[2], ..., itr[n]
function EEex_Utility_MutateIterator(iterator, func)
	return function()
		local values = {iterator()}
		if values[1] == nil then
			return nil
		end
		func(table.unpack(values))
		return table.unpack(values)
	end
end
EEex_Utility_MutateItr = EEex_Utility_MutateIterator

-- Expects - <lowerBound, upperBound, [stepFunc], [startI]>
-- Returns - Itr such that:
--              * if stepFunc == nil then stepFunc = function(i) return i + 1 end
--              * i = startI if startI ~= nil else lowerBound
--             -> i, i = stepFunc(i), i = stepFunc(i), ... until i < lowerBound or i > upperBound
function EEex_Utility_RangeIterator(lowerBound, upperBound, stepFunc, startI)
	local i = startI or lowerBound
	if stepFunc == nil then
		stepFunc = function(i)
			return i + 1
		end
	end
	return function()
		if i < lowerBound or i > upperBound then
			return nil
		end
		local toReturn = i
		i = stepFunc(i)
		return toReturn
	end
end
EEex_Utility_RangeItr = EEex_Utility_RangeIterator

-- Expects - <itr, filterFunc>
-- Returns - Itr such that:
--              * n = <number of itr elements>
--             -> itr[1] if filterFunc(itr[1]) == true, itr[2] if filterFunc(itr[2]) == true, ...,
--                itr[n] if filterFunc(itr[n]) == true
function EEex_Utility_FilterIterator(iterator, filterFunc)
	return function()
		while true do
			local values = {iterator()}
			if values[1] == nil then
				return nil
			end
			if filterFunc(table.unpack(values)) then
				return table.unpack(values)
			end
		end
	end
end
EEex_Utility_FilterItr = EEex_Utility_FilterIterator

-- Expects - <itr, func>
-- Calls func with {itr[1]}, {itr[2]}, ..., {itr[n]}
function EEex_Utility_ProcessIteratorValues(iterator, func)
	while true do
		local values = {iterator()}
		if values[1] == nil then
			return
		end
		func(values)
	end
end
EEex_Utility_ProcessItrValues = EEex_Utility_ProcessIteratorValues

-- Expects - <itr>
-- Returns - table that collects all values returned by itr such that:
--             * n = <number of itr elements>
--             -> t[1] = {itr[1]}, t[2] = {itr[2]}, ..., t[n] = {itr[n]}
function EEex_Utility_CollectIteratorValues(iterator)
	local t = {}
	local insertI = 1
	EEex_Utility_ProcessIteratorValues(iterator, function(t2)
		t[insertI] = t2
		insertI = insertI + 1
	end)
	return t
end
EEex_Utility_CollectItrValues = EEex_Utility_CollectIteratorValues

-- Expects - <i, itr>
-- Returns - table that collects a specific value returned by itr such that:
--             * n = <number of itr elements>
--             -> t[1] = select(i, itr[1]), t[2] = select(i, itr[2]), ..., t[n] = select(i, itr[n])
function EEex_Utility_CollectIteratorValue(i, iterator)
	local t = {}
	local insertI = 1
	for value in EEex_Utility_SelectItr(i, iterator) do
		t[insertI] = value
		insertI = insertI + 1
	end
	return t
end
EEex_Utility_CollectItrValue = EEex_Utility_CollectIteratorValue

-- Expects - <i, itr>
-- Returns - table that maps all values returned by itr such that:
--             * n = <number of itr elements>
--             -> t[select(i, itr[1])] = {itr[1]}, t[select(i, itr[2])] = {itr[2]}, ..., t[select(i, itr[n])] = {itr[n]}
function EEex_Utility_MapIteratorValues(i, iterator)
	local t = {}
	EEex_Utility_ProcessIteratorValues(iterator, function(t2)
		t[t2[i]] = t2
	end)
	return t
end
EEex_Utility_MapItrValues = EEex_Utility_MapIteratorValues

--[[
function EEex_Utility_AugmentIterator(inputItr, augStart, augLength, mainItrGen, augmentFunc)

	local inputValues
	inputItr = EEex_Utility_MutateIterator(inputItr, function(...)
		inputValues = {...}
	end)

	local mainItr = mainItrGen(inputItr)
	if mainItr == nil then
		return function()
			return nil
		end
	end

	return function()
		local mainValues = {mainItr()}
		if mainValues[1] == nil then
			return nil
		end
		augmentFunc(EEex_SelectFromTables(augStart, augLength, inputValues, 1, -1, mainValues))
		return table.unpack(mainValues)
	end
end
EEex_Utility_AugmentItr = EEex_Utility_AugmentIterator
--]]
