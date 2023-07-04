
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

---------
-- 2DA --
---------

function EEex_Resource_Find2DAColumnIndex(array, y, toSearchFor)
	toSearchFor = toSearchFor:upper()
	local toReturn = -1
	array:iterateRowIndex(y, function(i, val)
		if val == toSearchFor then
			toReturn = i
			return true
		end
	end)
	return toReturn
end
C2DArray.findColumnIndex = EEex_Resource_Find2DAColumnIndex

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

function EEex_Resource_Find2DARowIndex(array, x, toSearchFor)
	toSearchFor = toSearchFor:upper()
	local toReturn = -1
	array:iterateColumnIndex(x, function(i, val)
		if val == toSearchFor then
			toReturn = i
			return true
		end
	end)
	return toReturn
end
C2DArray.findRowIndex = EEex_Resource_Find2DARowIndex

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

function EEex_Resource_Free2DA(array)
	array:Destruct()
	EEex_FreeUD(array)
end
C2DArray.free = EEex_Resource_Free2DA

function EEex_Resource_Get2DAColumnLabel(array, n)
	local sizeX = array.m_nSizeX
	if n < 0 or n >= sizeX then return "" end
	return array.m_pNamesX:getReference(n).m_pchData:get()
end
C2DArray.getColumnLabel = EEex_Resource_Get2DAColumnLabel

function EEex_Resource_Get2DADefault(array)
	return array.m_default.m_pchData:get()
end
C2DArray.getDefault = EEex_Resource_Get2DADefault

function EEex_Resource_Get2DADimensions(array)
	return array.m_nSizeX, array.m_nSizeY
end
C2DArray.getDimensions = EEex_Resource_Get2DADimensions

function EEex_Resource_Get2DARowLabel(array, n)
	if n < 0 or n >= array.m_nSizeY then return "" end
	return array.m_pNamesY:getReference(n).m_pchData:get()
end
C2DArray.getRowLabel = EEex_Resource_Get2DARowLabel

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

function EEex_Resource_GetAt2DAPoint(array, x, y)
	local sizeX, sizeY = array:getDimensions()
	if x < 0 or x >= sizeX or y < 0 or y >= sizeY then return array:getDefault() end
	return array.m_pArray:getReference(x + y * sizeX).m_pchData:get()
end
C2DArray.getAtPoint = EEex_Resource_GetAt2DAPoint

function EEex_Resource_Iterate2DAColumnIndex(array, x, func)
	local sizeX, sizeY = array:getDimensions()
	if x < 0 or x >= sizeX then return end
	local pArray = array.m_pArray
	local curIndex = x
	for i = 0, sizeY - 1 do
		if func(i, pArray:getReference(curIndex).m_pchData:get()) then break end
		curIndex = curIndex + sizeX
	end
end
C2DArray.iterateColumnIndex = EEex_Resource_Iterate2DAColumnIndex

function EEex_Resource_Iterate2DAColumnLabel(array, columnLabel, func)
	array:iterateColumnIndex(array:findColumnLabel(columnLabel), func)
end
C2DArray.iterateColumnLabel = EEex_Resource_Iterate2DAColumnLabel

function EEex_Resource_Iterate2DARowIndex(array, y, func)
	local sizeX, sizeY = array:getDimensions()
	if y < 0 or y >= sizeY then return end
	local pArray = array.m_pArray
	local curIndex = sizeX * y
	for i = 0, sizeX - 2 do
		if func(i, pArray:getReference(curIndex).m_pchData:get()) then break end
		curIndex = curIndex + 1
	end
end
C2DArray.iterateRowIndex = EEex_Resource_Iterate2DARowIndex

function EEex_Resource_Iterate2DARowLabel(array, rowLabel, func)
	array:iterateRowIndex(array:findRowLabel(rowLabel), func)
end
C2DArray.iterateRowLabel = EEex_Resource_Iterate2DARowLabel

function EEex_Resource_Load2DA(resref)
	local array = EEex_NewUD("C2DArray")
	array:Construct()
	EEex_RunWithStackManager({
		{ ["name"] = "resref", ["struct"] = "CResRef", ["constructor"] = {["args"] = {resref} }}, },
		function(manager)
			array:Load(manager:getUD("resref"))
		end)
	return array
end

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
