
-- Mirrors chExtToType, (chTypeToExt would be reverse)
function EEex_Resource_ExtToType(extension)
	return ({
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
	})[extension:upper()]
end

function EEex_Resource_ExtToUserType(extension)
	return ({
		["2DA"]  = "CResText",
		["ARE"]  = "CResArea",
		["BAM"]  = "CResCell",
		["BCS"]  = "CResText",
		["BIO"]  = "CResBIO",
		["BMP"]  = "CResBitmap",
		["BS"]   = "CResText",
		["CHR"]  = "CResCHR",
		["CHU"]  = "CResUI",
		["CRE"]  = "CResCRE",
		["DLG"]  = "CResDLG",
		["EFF"]  = "CResEffect",
		["GAM"]  = "CResGame",
		["GLSL"] = "CResText",
		["GUI"]  = "CResText",
		["IDS"]  = "CResText",
		["INI"]  = "CRes",
		["ITM"]  = "CResItem",
		["LUA"]  = "CResText",
		["MENU"] = "CResText",
		["MOS"]  = "CResMosaic",
		["MVE"]  = "CRes",
		["PLT"]  = "CResPLT",
		["PNG"]  = "CResPng",
		["PRO"]  = "CResBinary",
		["PVRZ"] = "CResPVR",
		["SPL"]  = "CResSpell",
		["SQL"]  = "CResText",
		["STO"]  = "CResStore",
		["TGA"]  = "CRes",
		["TIS"]  = "CResTileSet",
		["TOH"]  = "CRes",
		["TOT"]  = "CRes",
		["TTF"]  = "CResFont",
		["VEF"]  = "CResBinary",
		["VVC"]  = "CResBinary",
		["WAV"]  = "CResWave",
		["WBM"]  = "CResWebm",
		["WED"]  = "CResWED",
		["WFX"]  = "CResBinary",
		["WMP"]  = "CResWorldMap",
	})[extension:upper()]
end

function EEex_Resource_Fetch(resref, extension)
	local toReturn
	EEex_RunWithStack(CRes.sizeof + #resref + 1, function(rsp)

		local resObj = EEex_PtrToUD(rsp, "CRes")
		resObj:Construct()
		local resrefStr = EEex_CastUD(resObj.resref, "CharString")
		resrefStr:pointTo(rsp + CRes.sizeof)
		resrefStr:write(resref)
		resObj.type = EEex_Resource_ExtToType(extension)

		toReturn = EngineGlobals.bsearch(
			resObj:getInternalReference(),
			EngineGlobals.resources.m_pData,
			EngineGlobals.resources.m_nSize,
			EEex_PointerSize,
			EngineGlobals.reference_CompareCResByTypeThenName
		)

		if toReturn then toReturn = EEex_CastUD(toReturn.reference, EEex_Resource_ExtToUserType(extension)) end
		resObj:Destruct()
	end)
	return toReturn
end

function EEex_Resource_Demand(resref, extension)

	local res = EEex_Resource_Fetch(resref, extension)
	if not res then return end
	local demanded = res:Demand()
	if not demanded then return end

	local castType = ({
		["SPL"] = "Spell_Header_st",
	})[extension:upper()]

	if castType then demanded = EEex_CastUD(demanded, castType) end
	return demanded
end

function EEex_Resource_GetSpellAbility(spellHeader, abilityIndex)
	if spellHeader.abilityCount <= abilityIndex then return end
	return EEex_PtrToUD(EEex_UDToPtr(spellHeader) + spellHeader.abilityOffset + Spell_ability_st.sizeof * abilityIndex, "Spell_ability_st")
end
Spell_Header_st.getAbility = EEex_Resource_GetSpellAbility

function EEex_Resource_GetSpellAbilityForLevel(spellHeader, casterLevel)

	local abilitiesCount = spellHeader.abilityCount
	if abilitiesCount == 0 then return end
	local currentAbilityAddress = EEex_UDToPtr(spellHeader) + spellHeader.abilityOffset

	local foundAbility = nil
	for i = 1, abilitiesCount, 1 do
		local ability = EEex_PtrToUD(currentAbilityAddress, "Spell_ability_st")
		if casterLevel >= ability.minCasterLevel then
			foundAbility = ability
		else
			break
		end
		currentAbilityAddress = currentAbilityAddress + Spell_ability_st.sizeof
	end
	return foundAbility
end
Spell_Header_st.getAbilityForLevel = EEex_Resource_GetSpellAbilityForLevel

-- spellResRefIterator is expected to return <string spellResRef>
-- Iterator returns <string spellResRef, Spell_Header_st spellHeader>
function EEex_Resource_GetValidSpellsIterator(spellResRefIterator)
	return function()
		for spellResRef in spellResRefIterator do
			local spellHeader = EEex_Resource_Demand(spellResRef, "SPL")
			if spellHeader ~= nil then
				return spellResRef, spellHeader
			end
		end
		return nil
	end
end
EEex_Resource_GetValidSpellsItr = EEex_Resource_GetValidSpellsIterator

---------
-- 2DA --
---------

-- @bubb_doc { EEex_Resource_Find2DAColumnIndex / instance_name=findColumnIndex }
--
-- @summary: Searches the values of the row specified by ``rowIndex`` and returns the first column index that matches ``toSearchFor``.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { rowIndex / type=number }: The index of the row to be searched.
--
-- @param { toSearchFor / type=string }: The value to search for.
--
-- @return { type=number }: See summary.

function EEex_Resource_Find2DAColumnIndex(array, rowIndex, toSearchFor)
	toSearchFor = toSearchFor:upper()
	local toReturn = -1
	array:iterateRowIndex(rowIndex, function(i, val)
		if val == toSearchFor then
			toReturn = i
			return true
		end
	end)
	return toReturn
end
C2DArray.findColumnIndex = EEex_Resource_Find2DAColumnIndex

-- @bubb_doc { EEex_Resource_Find2DAColumnLabel / instance_name=findColumnLabel }
--
-- @summary: Searches the .2DA's column labels and returns the first column index that matches ``toSearchFor``.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { toSearchFor / type=string }: The label to search for.
--
-- @return { type=number }: See summary.

function EEex_Resource_Find2DAColumnLabel(array, toSearchFor)
	toSearchFor = toSearchFor:upper()
	local pNamesX = array.m_pNamesX
	for i = 0, array.m_nSizeX - 1 do
		if pNamesX:getReference(i).m_pchData:get() == toSearchFor then
			return i
		end
	end
	return -1
end
C2DArray.findColumnLabel = EEex_Resource_Find2DAColumnLabel

-- @bubb_doc { EEex_Resource_Find2DARowIndex / instance_name=findRowIndex }
--
-- @summary: Searches the values of the column specified by ``columnIndex`` and returns the first row index that matches ``toSearchFor``.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { columnIndex / type=number }: The index of the column to be searched.
--
-- @param { toSearchFor / type=string }: The value to search for.
--
-- @return { type=number }: See summary.

function EEex_Resource_Find2DARowIndex(array, columnIndex, toSearchFor)
	toSearchFor = toSearchFor:upper()
	local toReturn = -1
	array:iterateColumnIndex(columnIndex, function(i, val)
		if val == toSearchFor then
			toReturn = i
			return true
		end
	end)
	return toReturn
end
C2DArray.findRowIndex = EEex_Resource_Find2DARowIndex

-- @bubb_doc { EEex_Resource_Find2DARowLabel / instance_name=findRowLabel }
--
-- @summary: Searches the .2DA's row labels and returns the first row index that matches ``toSearchFor``.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { toSearchFor / type=string }: The label to search for.
--
-- @return { type=number }: See summary.

function EEex_Resource_Find2DARowLabel(array, toSearchFor)
	toSearchFor = toSearchFor:upper()
	local pNamesY = array.m_pNamesY
	for i = 0, array.m_nSizeY - 1 do
		if pNamesY:getReference(i).m_pchData:get() == toSearchFor then
			return i
		end
	end
	return -1
end
C2DArray.findRowLabel = EEex_Resource_Find2DARowLabel

-- @bubb_doc { EEex_Resource_Free2DA / instance_name=free }
--
-- @summary: Frees the memory associated with ``array``. *** Only use this if you know what you are doing! ***
--
-- @note: ``C2DArray`` objects returned by ``EEex_Resource_Load2DA()`` are subject to garbage-collection
--        – meaning ``EEex_Resource_Free2DA()`` should ***not*** be called on these instances.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.

function EEex_Resource_Free2DA(array)
	EEex_SetUDGCFunc(array, nil)
	array:Destruct()
	EEex_FreeUD(array)
end
C2DArray.free = EEex_Resource_Free2DA

-- @bubb_doc { EEex_Resource_Get2DAColumnLabel / instance_name=getColumnLabel }
--
-- @summary: Returns the label of the column specified by ``columnIndex``.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { columnIndex / type=number }: The column index of the label to be fetched.
--
-- @return { type=number }: See summary.

function EEex_Resource_Get2DAColumnLabel(array, columnIndex)
	local sizeX = array.m_nSizeX
	if columnIndex < 0 or columnIndex >= sizeX then return "" end
	return array.m_pNamesX:getReference(columnIndex).m_pchData:get()
end
C2DArray.getColumnLabel = EEex_Resource_Get2DAColumnLabel

-- @bubb_doc { EEex_Resource_Get2DADefault / instance_name=getDefault }
--
-- @summary: Returns the "default" value of the .2DA.
--
-- @note: A .2DA's default value is defined by the line directly below the version header – it is usually an asterisk ('*').
--
-- @note: If the engine (or any EEex function) indexes a .2DA out-of-bounds, the default value is returned instead.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @return { type=string }: See summary.

function EEex_Resource_Get2DADefault(array)
	return array.m_default.m_pchData:get()
end
C2DArray.getDefault = EEex_Resource_Get2DADefault

-- @bubb_doc { EEex_Resource_Get2DADimensions / instance_name=getDimensions }
--
-- @summary: Returns the x and y dimensions of the .2DA. That is the number of columns, and the number of rows respectively.
--
-- @note:
--     * The returned 'x' dimension **includes** the row labels, (that is to say, its value is 1 more than expected).
--     * The returned 'y' dimension **excludes** the column labels.
--
--     When indexing a .2DA, column / row labels **are always excluded**.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @return { type=number }: The .2DA's 'x' dimension.
--
-- @return { type=number }: The .2DA's 'y' dimension.

function EEex_Resource_Get2DADimensions(array)
	return array.m_nSizeX, array.m_nSizeY
end
C2DArray.getDimensions = EEex_Resource_Get2DADimensions

-- @bubb_doc { EEex_Resource_Get2DARowLabel / instance_name=getRowLabel }
--
-- @summary: Returns the label of the row specified by ``rowIndex``.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { rowIndex / type=number }: The row index of the label to be fetched.
--
-- @return { type=string }: See summary.

function EEex_Resource_Get2DARowLabel(array, rowIndex)
	if rowIndex < 0 or rowIndex >= array.m_nSizeY then return "" end
	return array.m_pNamesY:getReference(rowIndex).m_pchData:get()
end
C2DArray.getRowLabel = EEex_Resource_Get2DARowLabel

-- @bubb_doc { EEex_Resource_GetAt2DALabels / instance_name=getAtLabels }
--
-- @summary: Returns the value at the intersection of ``columnLabel`` and ``rowLabel``. If either label is missing, returns the .2DA's
--           default value, (see ``EEex_Resource_Get2DADefault()``).
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { columnLabel / type=string }: The column label of the value to be fetched.
--
-- @param { rowLabel / type=string }: The row label of the value to be fetched.
--
-- @return { type=string }: See summary.

function EEex_Resource_GetAt2DALabels(array, columnLabel, rowLabel)
	local toReturn
	EEex_RunWithStackManager({
		{ ["name"] = "CColumnLabel", ["struct"] = "CString", ["constructor"] = {["args"] = {columnLabel} }},
		{ ["name"] = "CRowLabel",    ["struct"] = "CString", ["constructor"] = {["args"] = {rowLabel}    }}, },
		function(manager)
			toReturn = array:GetAtLabels(manager:getUD("CColumnLabel"), manager:getUD("CRowLabel")).m_pchData:get()
		end)
	return toReturn
end
C2DArray.getAtLabels = EEex_Resource_GetAt2DALabels

-- @bubb_doc { EEex_Resource_GetAt2DAPoint / instance_name=getAtPoint }
--
-- @summary: Returns the value at the intersection of ``columnIndex`` and ``rowIndex``. If either index exceeds the .2DA's dimensions, returns the
--           .2DA's default value, (see ``EEex_Resource_Get2DADefault()``).
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { columnIndex / type=number }: The column index of the value to be fetched.
--
-- @param { rowIndex / type=number }: The row index of the value to be fetched.
--
-- @return { type=string }: See summary.

function EEex_Resource_GetAt2DAPoint(array, columnIndex, rowIndex)
	local sizeX, sizeY = array:getDimensions()
	if columnIndex < 0 or columnIndex >= sizeX or rowIndex < 0 or rowIndex >= sizeY then return array:getDefault() end
	return array.m_pArray:getReference(columnIndex + rowIndex * sizeX).m_pchData:get()
end
C2DArray.getAtPoint = EEex_Resource_GetAt2DAPoint

-- @bubb_doc { EEex_Resource_Iterate2DAColumnIndex / instance_name=iterateColumnIndex }
--
-- @summary: Calls ``func`` for every value in the column specified by ``columnIndex``. If ``func`` returns ``true`` the iteration ends early.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { columnIndex / type=number }: The index of the column whose values are to be iterated.
--
-- @param { func / type=function(value: string) -> boolean }: The function to be called.

function EEex_Resource_Iterate2DAColumnIndex(array, columnIndex, func)
	local sizeX, sizeY = array:getDimensions()
	if columnIndex < 0 or columnIndex >= sizeX then return end
	local pArray = array.m_pArray
	local curIndex = columnIndex
	for i = 0, sizeY - 1 do
		if func(i, pArray:getReference(curIndex).m_pchData:get()) then break end
		curIndex = curIndex + sizeX
	end
end
C2DArray.iterateColumnIndex = EEex_Resource_Iterate2DAColumnIndex

-- @bubb_doc { EEex_Resource_Iterate2DAColumnLabel / instance_name=iterateColumnLabel }
--
-- @summary: Calls ``func`` for every value in the column specified by ``columnLabel``. If ``func`` returns ``true`` the iteration ends early.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { columnLabel / type=string }: The label of the column whose values are to be iterated.
--
-- @param { func / type=function(value: string) -> boolean }: The function to be called.

function EEex_Resource_Iterate2DAColumnLabel(array, columnLabel, func)
	array:iterateColumnIndex(array:findColumnLabel(columnLabel), func)
end
C2DArray.iterateColumnLabel = EEex_Resource_Iterate2DAColumnLabel

-- @bubb_doc { EEex_Resource_Iterate2DARowIndex / instance_name=iterateRowIndex }
--
-- @summary: Calls ``func`` for every value in the row specified by ``rowIndex``. If ``func`` returns ``true`` the iteration ends early.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { rowIndex / type=number }: The index of the row whose values are to be iterated.
--
-- @param { func / type=function(value: string) -> boolean }: The function to be called.

function EEex_Resource_Iterate2DARowIndex(array, rowIndex, func)
	local sizeX, sizeY = array:getDimensions()
	if rowIndex < 0 or rowIndex >= sizeY then return end
	local pArray = array.m_pArray
	local curIndex = sizeX * rowIndex
	for i = 0, sizeX - 2 do
		if func(i, pArray:getReference(curIndex).m_pchData:get()) then break end
		curIndex = curIndex + 1
	end
end
C2DArray.iterateRowIndex = EEex_Resource_Iterate2DARowIndex

-- @bubb_doc { EEex_Resource_Iterate2DARowLabel / instance_name=iterateRowLabel }
--
-- @summary: Calls ``func`` for every value in the row specified by ``rowLabel``. If ``func`` returns ``true`` the iteration ends early.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { rowLabel / type=string }: The label of the row whose values are to be iterated.
--
-- @param { func / type=function(value: string) -> boolean }: The function to be called.

function EEex_Resource_Iterate2DARowLabel(array, rowLabel, func)
	array:iterateRowIndex(array:findRowLabel(rowLabel), func)
end
C2DArray.iterateRowLabel = EEex_Resource_Iterate2DARowLabel

-- @bubb_doc { EEex_Resource_Load2DA }
--
-- @summary: Returns a ``C2DArray`` instance that represents the .2DA with ``resref``.
--
-- @param { resref / type=string }: The resref of the .2DA to be loaded – (should omit the file extension).
--
-- @return { type=C2DArray }: See summary.

function EEex_Resource_Load2DA(resref)
	local array = EEex_NewUD("C2DArray")
	array:Construct()
	EEex_RunWithStackManager({
		{ ["name"] = "resref", ["struct"] = "CResRef", ["constructor"] = {["args"] = {resref} }}, },
		function(manager)
			array:Load(manager:getUD("resref"))
		end)
	EEex_SetUDGCFunc(array, EEex_Resource_Free2DA)
	return array
end

-- Iterator returns:
--   bIncludeLabel == true : {array:getRowLabel(y), ...}
--   else : {...}
function EEex_Resource_Get2DARowTableIterator(array, bIncludeLabel)
	local sizeX, sizeY = array:getDimensions()
	sizeX = sizeX - 1
	local y = 0
	if bIncludeLabel then
		return function()
			while true do
				if y >= sizeY then return nil end
				local rowValues = {array:getRowLabel(y)}
				for i = 1, sizeX do
					rowValues[i + 1] = array:getAtPoint(i - 1, y)
				end
				y = y + 1
				return rowValues
			end
		end
	else
		return function()
			while true do
				if y >= sizeY then return nil end
				local rowValues = {}
				for i = 1, sizeX do
					rowValues[i] = array:getAtPoint(i - 1, y)
				end
				y = y + 1
				return rowValues
			end
		end
	end
end
EEex_Resource_Get2DARowTableItr = EEex_Resource_Get2DARowTableIterator
C2DArray.getRowTableIterator = EEex_Resource_Get2DARowTableItr
C2DArray.getRowTableItr = EEex_Resource_Get2DARowTableItr

-- Iterator returns:
--   bIncludeLabel == true : <array:getRowLabel(y), ...>
--   else : <...>
function EEex_Resource_Get2DARowValuesIterator(array, bIncludeLabel)
	return EEex_Utility_ApplyItr(array:getRowTableItr(bIncludeLabel), function(t)
		return table.unpack(t)
	end)
end
EEex_Resource_Get2DARowValuesItr = EEex_Resource_Get2DARowValuesIterator
C2DArray.getRowValuesIterator = EEex_Resource_Get2DARowValuesItr
C2DArray.getRowValuesItr = EEex_Resource_Get2DARowValuesItr

-- Iterator returns:
--   labelI == nil : <...>
--   else : <..., array:getRowLabel(y), ...>
function EEex_Resource_Get2DARowColumnsIterator(array, labelI, ...)
	local columnIndexes = {...}
	local _, sizeY = array:getDimensions()
	local y = 0
	if labelI == nil then
		return function()
			while true do
				if y >= sizeY then return nil end
				local rowValues = {}
				for i, columnIndex in ipairs(columnIndexes) do
					rowValues[i] = array:getAtPoint(columnIndex, y)
				end
				y = y + 1
				return table.unpack(rowValues)
			end
		end
	else
		return function()
			while true do
				if y >= sizeY then return nil end
				local rowValues = {}
				for i = 1, labelI - 1 do
					rowValues[i] = array:getAtPoint(columnIndexes[i], y)
				end
				rowValues[labelI] = array:getRowLabel(y)
				local i = labelI
				while true do
					local columnIndex = columnIndexes[i]
					if columnIndex == nil then break end
					i = i + 1
					rowValues[i] = array:getAtPoint(columnIndex, y)
				end
				y = y + 1
				return table.unpack(rowValues)
			end
		end
	end
end
EEex_Resource_Get2DARowColumnsItr = EEex_Resource_Get2DARowColumnsIterator
C2DArray.getRowColumnsIterator = EEex_Resource_Get2DARowColumnsItr
C2DArray.getRowColumnsItr = EEex_Resource_Get2DARowColumnsItr

-- Iterator returns:
--   labelI == nil : <...>
--   else : <..., array:getRowLabel(y), ...>
function EEex_Resource_Get2DARowColumnsByLabelIterator(array, labelI, ...)
	local columnIndexes = {}
	local insertI = 1
	while true do
		local label = select(insertI, ...)
		if label == nil then break end
		columnIndexes[insertI] = array:findColumnLabel(label)
		insertI = insertI + 1
	end
	local _, sizeY = array:getDimensions()
	local y = 0
	if labelI == nil then
		return function()
			while true do
				if y >= sizeY then return nil end
				local rowValues = {}
				for i, columnIndex in ipairs(columnIndexes) do
					rowValues[i] = array:getAtPoint(columnIndex, y)
				end
				y = y + 1
				return table.unpack(rowValues)
			end
		end
	else
		return function()
			while true do
				if y >= sizeY then return nil end
				local rowValues = {}
				for i = 1, labelI - 1 do
					rowValues[i] = array:getAtPoint(columnIndexes[i], y)
				end
				rowValues[labelI] = array:getRowLabel(y)
				local i = labelI
				while true do
					local columnIndex = columnIndexes[i]
					if columnIndex == nil then break end
					i = i + 1
					rowValues[i] = array:getAtPoint(columnIndex, y)
				end
				y = y + 1
				return table.unpack(rowValues)
			end
		end
	end
end
EEex_Resource_Get2DARowColumnsByLabelItr = EEex_Resource_Get2DARowColumnsByLabelIterator
C2DArray.getRowColumnsByLabelIterator = EEex_Resource_Get2DARowColumnsByLabelItr
C2DArray.getRowColumnsByLabelItr = EEex_Resource_Get2DARowColumnsByLabelItr

---------
-- IDS --
---------

function EEex_Resource_FreeIDS(ids)
	ids:Destruct()
	EEex_FreeUD(ids)
end
CAIIdList.free = EEex_Resource_FreeIDS

function EEex_Resource_GetIDSCount(ids)
	return ids.m_nArray
end
CAIIdList.getCount = EEex_Resource_GetIDSCount

function EEex_Resource_GetIDSEntry(ids, id)
	return id < ids:getCount() and ids.m_pIdArray:get(id) or nil
end
CAIIdList.getEntry = EEex_Resource_GetIDSEntry

function EEex_Resource_GetIDSLine(ids, id)
	if id >= ids:getCount() then return nil end
	local entry = ids.m_pIdArray:get(id)
	return entry and entry.m_line.m_pchData:get() or nil
end
CAIIdList.getLine = EEex_Resource_GetIDSLine

function EEex_Resource_GetIDSStart(ids, id)
	if id >= ids:getCount() then return nil end
	local entry = ids.m_pIdArray:get(id)
	return entry and entry.m_start.m_pchData:get() or nil
end
CAIIdList.getStart = EEex_Resource_GetIDSStart

function EEex_Resource_IDSHasID(ids, id)
	return id < ids:getCount() and ids.m_pIdArray:get(id) ~= nil
end
CAIIdList.hasID = EEex_Resource_IDSHasID

function EEex_Resource_LoadIDS(resref)
	local ids = EEex_NewUD("CAIIdList")
	ids:Construct1()
	EEex_RunWithStackManager({
		{ ["name"] = "resref", ["struct"] = "CResRef", ["constructor"] = {["args"] = {resref} }}, },
		function(manager)
			ids:LoadList2(manager:getUD("resref"), true)
		end)
	return ids
end
