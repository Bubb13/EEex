local EEex_Item_Private_ItemExtension = "ITM"
local EEex_Item_Private_MarshalVersion = "V1"
local EEex_Item_Private_PersistentResrefs = {}
local EEex_Item_Private_ItemType = EEex_Resource_ExtToType(EEex_Item_Private_ItemExtension)

local function EEex_Item_Private_ValidateString(value, errorPrefix, minLength, maxLength)
	if type(value) ~= "string" then
		EEex_Error(errorPrefix .. tostring(value))
	end

	local length = #value
	if length < minLength or length > maxLength then
		EEex_Error(errorPrefix .. tostring(value))
	end
end

local function EEex_Item_Private_ValidateBoolean(value, errorPrefix)
	if type(value) ~= "boolean" then
		EEex_Error(errorPrefix .. tostring(value))
	end
end

local function EEex_Item_Private_NormalizeResref(value, fieldName, allowEmpty)
	if type(value) == "userdata" and value.get then
		value = value:get()
	end
	if allowEmpty and value == nil then
		return ""
	end
	if type(value) ~= "string" then
		EEex_Error(fieldName .. " must be a string or CResRef!")
	end
	value = value:upper()
	if #value > 8 or (not allowEmpty and #value == 0) then
		EEex_Error(fieldName .. " must be between " .. (allowEmpty and "0" or "1") .. " and 8 characters!")
	end
	return value
end

local function EEex_Item_Private_MakeFourCC(value)
	EEex_Item_Private_ValidateString(value, "Invalid FourCC: ", 4, 4)
	local byte1, byte2, byte3, byte4 = value:byte(1, 4)
	return byte1 + byte2 * 0x100 + byte3 * 0x10000 + byte4 * 0x1000000
end

local function EEex_Item_Private_ValidateItem(item)
	if type(item) ~= "userdata" or item.pRes == nil then
		EEex_Error("item must be a CItem!")
	end
	return item
end

-- Runtime ITMs can exist in dimm without a demanded header. Centralize the
-- demand-or-error path so create, copy, marshal, and unmarshal stay consistent.
local function EEex_Item_Private_DemandResourceHeader(resource, errorMessage)
	if resource.pHeader == nil then
		if resource:Demand() == nil or resource.pHeader == nil then
			EEex_Error(errorMessage)
		end
	end
	return EEex_CastUD(resource.pHeader, "Item_Header_st")
end

local function EEex_Item_Private_GetResource(item)
	item = EEex_Item_Private_ValidateItem(item)

	local itemResource = item.pRes
	EEex_Item_Private_DemandResourceHeader(itemResource, "Unable to demand item resource!")

	return itemResource
end

local function EEex_Item_Private_GetOrCreateRuntimeResource(itemResref)
	local itemResource
	EEex_RunWithStack(CResRef.sizeof, function(stackMem)
		local resrefUD = EEex_PtrToUD(stackMem, "CResRef")
		resrefUD:set(itemResref)
		-- const CResRef* cResRef, int nType, bool createIfNotExists
		itemResource = EEex_CastUD(EngineGlobals.dimmGetResObject(resrefUD, EEex_Item_Private_ItemType, true), "CResItem")
	end)
	if not itemResource then
		EEex_Error("Failed to create runtime item resource: " .. itemResref)
	end
	return itemResource
end

local function EEex_Item_Private_MarshalResourceHex(resource)
	local itemHeader = EEex_Item_Private_DemandResourceHeader(resource, "Unable to demand item resource before marshal!")

	local address = EEex_UDToPtr(itemHeader)
	local encoded = {}
	for i = 0, resource.nSize - 1 do
		encoded[#encoded + 1] = string.format("%02X", EEex_ReadU8(address + i))
	end
	return table.concat(encoded)
end

local function EEex_Item_Private_UnmarshalResourceHex(resource, marshaledHex)
	EEex_Item_Private_ValidateString(marshaledHex, "Invalid marshaled item blob: ", 0, math.huge)
	if #marshaledHex % 2 ~= 0 then
		EEex_Error("Marshaled item blob must have an even hex length!")
	end

	local byteCount = #marshaledHex / 2
	if byteCount == 0 then
		EEex_Error("Marshaled item blob may not be empty!")
	end

	EEex_RunWithStack(byteCount, function(bufferBase)
		local writeOffset = 0
		for i = 1, #marshaledHex, 2 do
			local byteValue = tonumber(marshaledHex:sub(i, i + 1), 16)
			if byteValue == nil then
				EEex_Error("Marshaled item blob contains invalid hex!")
			end
			EEex_WriteU8(bufferBase + writeOffset, byteValue)
			writeOffset = writeOffset + 1
		end

		-- CRes* pRes, void* pData, int nSize, bool useTempOverride, bool makeCopy
		EngineGlobals.dimmServiceFromMemory(resource, EEex_PtrToUD(bufferBase, "VariableArray<char>"), byteCount, false, true)
	end)

	EEex_Item_Private_DemandResourceHeader(resource, "Failed to demand unmarshaled item resource!")
end

-- Applies simple header overrides.
local function EEex_Item_Private_ApplyHeaderArgs(itemHeader, args)
	if args == nil then
		return
	end

	if type(args) ~= "table" then
		EEex_Error("item args must be a table!")
	end

	local numericFields = {
		"genericName",
		"identifiedName",
		"itemFlags",
		"itemType",
		"notUsableBy",
		"minLevelRequired",
		"minSTRRequired",
		"minSTRBonusRequired",
		"notUsableBy2a",
		"minINTRequired",
		"notUsableBy2b",
		"minDEXRequired",
		"notUsableBy2c",
		"minWISRequired",
		"notUsableBy2d",
		"minCONRequired",
		"proficiencyType",
		"minCHRRequired",
		"baseValue",
		"maxStackable",
		"loreValue",
		"baseWeight",
		"genericDescription",
		"identifiedDescription",
		"attributes",
	}

	for _, fieldName in ipairs(numericFields) do
		local value = args[fieldName]
		if value ~= nil then
			itemHeader[fieldName] = value
		end
	end

	local resrefFields = {
		"usedUpItemID",
		"itemIcon",
		"groundIcon",
		"descriptionPicture",
	}

	for _, fieldName in ipairs(resrefFields) do
		local value = args[fieldName]
		if value ~= nil then
			itemHeader[fieldName]:set(EEex_Item_Private_NormalizeResref(value, fieldName, true))
		end
	end

	if args.animationType ~= nil then
		local animationType = args.animationType
		EEex_Item_Private_ValidateString(animationType, "Invalid animationType: ", 0, 2)
		itemHeader.animationType:set(animationType)
	end
end

local function EEex_Item_Private_GetPersistentResRefs()
	local itemResrefs = {}
	for itemResref in pairs(EEex_Item_Private_PersistentResrefs) do
		itemResrefs[#itemResrefs + 1] = itemResref
	end
	table.sort(itemResrefs)
	return itemResrefs
end

local function EEex_Item_Private_SetPersistenceEnabled(itemResref, persist)
	persist = EEex_Utility_Default(persist, false)
	EEex_Item_Private_ValidateBoolean(persist, "Invalid persist value: ")

	if persist then
		EEex_Item_Private_PersistentResrefs[itemResref] = true
	else
		EEex_Item_Private_PersistentResrefs[itemResref] = nil
	end
end

-- Both creation paths finish the same way: demand the new ITM, apply any
-- caller-provided header overrides, and record whether it should survive saves.
local function EEex_Item_Private_FinalizeCreatedResource(itemResource, itemResref, args, persist)
	local itemHeader = EEex_Item_Private_DemandResourceHeader(itemResource, "Unable to demand item resource: " .. itemResref)
	EEex_Item_Private_ApplyHeaderArgs(itemHeader, args)
	EEex_Item_Private_SetPersistenceEnabled(itemResref, persist)
	return itemHeader
end

-- Unmarshal always starts from a clean slate: dump the old persisted ITMs from
-- dimm, then forget the registry so the next marshal payload is authoritative.
local function EEex_Item_Private_DumpPersistentResources()
	for itemResref in pairs(EEex_Item_Private_PersistentResrefs) do
		local itemResource = EEex_Resource_Fetch(itemResref, EEex_Item_Private_ItemExtension)
		if itemResource then
			-- CRes* pRes
			EngineGlobals.dimmDump(itemResource)
		end
	end
	EEex_Item_Private_PersistentResrefs = {}
end

-- @bubb_doc { EEex_Item_CreateFromResref }
--
-- @summary: Creates a new in-memory ITM resource under ``itemResref`` and returns its demanded header.
--
-- @param { itemResref / type=string }: The resref to assign to the new in-memory item.
--
-- @param { args / type=table|nil }:
--     Optional scalar header overrides. @EOL
--
-- @param { persist / type=boolean / default=false }:
--     If ``true``, registers the ITM for marshal/unmarshal persistence; otherwise it remains session-only. @EOL
--
-- @return { type=Item_Header_st }: The demanded header of the created item.

function EEex_Item_CreateFromResref(itemResref, args, persist)
	itemResref = EEex_Item_Private_NormalizeResref(itemResref, "itemResref")
	local itemResource = EEex_Item_Private_GetOrCreateRuntimeResource(itemResref)

	EEex_RunWithStack(Item_Header_st.sizeof, function(bufferBase)
		EEex_Memset(bufferBase, 0, Item_Header_st.sizeof)
		local itemHeader = EEex_PtrToUD(bufferBase, "Item_Header_st")
		itemHeader.nFileType = EEex_Item_Private_MakeFourCC("ITM ")
		itemHeader.nFileVersion = EEex_Item_Private_MakeFourCC("V1  ")
		itemHeader.abilityOffset = Item_Header_st.sizeof
		itemHeader.abilityCount = 0
		itemHeader.effectsOffset = Item_Header_st.sizeof
		itemHeader.equipedStartingEffect = 0
		itemHeader.equipedEffectCount = 0
		itemHeader.maxStackable = 1

		-- CRes* pRes, void* pData, int nSize, bool useTempOverride, bool makeCopy
		EngineGlobals.dimmServiceFromMemory(itemResource, EEex_PtrToUD(bufferBase, "VariableArray<char>"), Item_Header_st.sizeof, false, true)
	end)

	return EEex_Item_Private_FinalizeCreatedResource(itemResource, itemResref, args, persist)
end

-- @bubb_doc { EEex_Item_CreateCopy }
--
-- @summary: Copies the full demanded ITM blob backing ``sourceItem`` into a new in-memory ITM resource under ``itemResref``.
--
-- @param { itemResref / type=string }: The resref to assign to the new in-memory item.
--
-- @param { sourceItem / type=CItem }: The source item to copy.
--
-- @param { args / type=table|nil }:
--     Optional scalar header overrides. @EOL
--
-- @param { persist / type=boolean / default=false }:
--     If ``true``, registers the ITM for marshal/unmarshal persistence; otherwise it remains session-only. @EOL
--
-- @return { type=Item_Header_st }: The demanded header of the created item.

function EEex_Item_CreateCopy(itemResref, sourceItem, args, persist)
	itemResref = EEex_Item_Private_NormalizeResref(itemResref, "itemResref")
	local sourceResource = EEex_Item_Private_GetResource(sourceItem)
	local sourceHeader = EEex_Item_Private_DemandResourceHeader(sourceResource, "Unable to demand item resource!")
	local itemResource = EEex_Item_Private_GetOrCreateRuntimeResource(itemResref)

	EEex_RunWithStack(sourceResource.nSize, function(bufferBase)
		-- Clone the entire demanded ITM payload, including equipped effects, abilities,
		-- and ability-linked effect blocks.
		EEex_Memcpy(bufferBase, EEex_UDToPtr(sourceHeader), sourceResource.nSize)
		-- CRes* pRes, void* pData, int nSize, bool useTempOverride, bool makeCopy
		EngineGlobals.dimmServiceFromMemory(itemResource, EEex_PtrToUD(bufferBase, "VariableArray<char>"), sourceResource.nSize, false, true)
	end)

	return EEex_Item_Private_FinalizeCreatedResource(itemResource, itemResref, args, persist)
end

--------------------------------------------------------------
-- EEex_Marshal.lua calls these cross-file helpers directly --
--------------------------------------------------------------

function EEex_Item_Private_MarshalPersistentItems()
	local itemResrefs = EEex_Item_Private_GetPersistentResRefs()
	local marshaled = { EEex_Item_Private_MarshalVersion }

	for _, itemResref in ipairs(itemResrefs) do
		local itemResource = EEex_Resource_Fetch(itemResref, EEex_Item_Private_ItemExtension)
		if not itemResource then
			EEex_Error("Persistent item resource is missing: " .. itemResref)
		end
		marshaled[#marshaled + 1] = itemResref .. ":" .. EEex_Item_Private_MarshalResourceHex(itemResource)
	end

	return table.concat(marshaled, "\n")
end

function EEex_Item_Private_UnmarshalPersistentItems(marshaled)
	EEex_Item_Private_DumpPersistentResources()

	if marshaled == nil or marshaled == "" then
		return
	end

	EEex_Item_Private_ValidateString(marshaled, "Invalid marshaled item payload: ", 1, math.huge)

	local version
	-- The item marshal payload is line-oriented: the first line is the marshal
	-- version and each following line is RESREF:HEX for one persisted ITM.
	for line in marshaled:gmatch("[^\r\n]+") do
		if version == nil then
			version = line
			if version ~= EEex_Item_Private_MarshalVersion then
				EEex_Error("Unsupported item marshal version: " .. tostring(version))
			end
		else
			local itemResref, marshaledHex = line:match("^(.-):([0-9A-F]*)$")
			if itemResref == nil then
				EEex_Error("Item marshal payload is corrupted!")
			end
			itemResref = EEex_Item_Private_NormalizeResref(itemResref, "marshaled item resref")
			local itemResource = EEex_Item_Private_GetOrCreateRuntimeResource(itemResref)
			EEex_Item_Private_UnmarshalResourceHex(itemResource, marshaledHex)
			EEex_Item_Private_SetPersistenceEnabled(itemResref, true)
		end
	end
end

