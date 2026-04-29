
-- Mirrors chExtToType, (chTypeToExt would be reverse)
function EEex_Resource_ExtToType(extension)
	return ({
		["2DA"]  = 0x3F4, -- CResText
		["ARE"]  = 0x3F2, -- CResArea
		["BAM"]  = 0x3E8, -- CResCell
		["BCS"]  = 0x3EF, -- CResText
		["BIO"]  = 0x3FE, -- CResBIO
		["BMP"]  = 0x001, -- CResBitmap
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
		["INI"]  = 0x802, -- CResINI
		["ITM"]  = 0x3ED, -- CResItem
		["LUA"]  = 0x409, -- CResText
		["MENU"] = 0x408, -- CResText
		["MOS"]  = 0x3EC, -- CResMosaic
		["MVE"]  = 0x002, -- CRes
		["PLT"]  = 0x006, -- CResPLT
		["PNG"]  = 0x40B, -- CResPng
		["PRO"]  = 0x3FD, -- CResBinary
		["PVRZ"] = 0x404, -- CResPVR
		["SPL"]  = 0x3EE, -- CResSpell
		["SQL"]  = 0x403, -- CResText
		["STO"]  = 0x3F6, -- CResStore
		["TGA"]  = 0x003, -- CRes
		["TIS"]  = 0x3EB, -- CResTileSet
		["TOH"]  = 0x407, -- CRes
		["TOT"]  = 0x406, -- CRes
		["TTF"]  = 0x40A, -- CResFont
		["VEF"]  = 0x3FC, -- CResBinary
		["VVC"]  = 0x3FB, -- CResBinary
		["WAV"]  = 0x004, -- CResWave
		["WBM"]  = 0x3FF, -- CResWebm
		["WED"]  = 0x3E9, -- CResWED
		["WFX"]  = 0x005, -- CResBinary
		["WMP"]  = 0x3F7, -- CResWorldMap
	})[extension:upper()]
end

function EEex_Resource_ExtToUserType(extension)
	return ({
		["2DA"]  = "CResText",     -- 0x3F4
		["ARE"]  = "CResArea",     -- 0x3F2
		["BAM"]  = "CResCell",     -- 0x3E8
		["BCS"]  = "CResText",     -- 0x3EF
		["BIO"]  = "CResBIO",      -- 0x3FE
		["BMP"]  = "CResBitmap",   -- 0x001
		["BS"]   = "CResText",     -- 0x3F9
		["CHR"]  = "CResCHR",      -- 0x3FA
		["CHU"]  = "CResUI",       -- 0x3EA
		["CRE"]  = "CResCRE",      -- 0x3F1
		["DLG"]  = "CResDLG",      -- 0x3F3
		["EFF"]  = "CResEffect",   -- 0x3F8
		["GAM"]  = "CResGame",     -- 0x3F5
		["GLSL"] = "CResText",     -- 0x405
		["GUI"]  = "CResText",     -- 0x402
		["IDS"]  = "CResText",     -- 0x3F0
		["INI"]  = "CResINI",      -- 0x802
		["ITM"]  = "CResItem",     -- 0x3ED
		["LUA"]  = "CResText",     -- 0x409
		["MENU"] = "CResText",     -- 0x408
		["MOS"]  = "CResMosaic",   -- 0x3EC
		["MVE"]  = "CRes",         -- 0x002
		["PLT"]  = "CResPLT",      -- 0x006
		["PNG"]  = "CResPng",      -- 0x40B
		["PRO"]  = "CResBinary",   -- 0x3FD
		["PVRZ"] = "CResPVR",      -- 0x404
		["SPL"]  = "CResSpell",    -- 0x3EE
		["SQL"]  = "CResText",     -- 0x403
		["STO"]  = "CResStore",    -- 0x3F6
		["TGA"]  = "CRes",         -- 0x003
		["TIS"]  = "CResTileSet",  -- 0x3EB
		["TOH"]  = "CRes",         -- 0x407
		["TOT"]  = "CRes",         -- 0x406
		["TTF"]  = "CResFont",     -- 0x40A
		["VEF"]  = "CResBinary",   -- 0x3FC
		["VVC"]  = "CResBinary",   -- 0x3FB
		["WAV"]  = "CResWave",     -- 0x004
		["WBM"]  = "CResWebm",     -- 0x3FF
		["WED"]  = "CResWED",      -- 0x3E9
		["WFX"]  = "CResBinary",   -- 0x005
		["WMP"]  = "CResWorldMap", -- 0x3F7
	})[extension:upper()]
end

function EEex_Resource_Fetch(resref, extension)
	local toReturn
	local resrefLen = #resref + 1
	EEex_RunWithStack(CRes.sizeof + resrefLen + EEex_PtrSize, function(rsp)

		local curRspOffset = rsp

		local resObj = EEex_PtrToUD(curRspOffset, "CRes")
		resObj:Construct()
		resObj.type = EEex_Resource_ExtToType(extension)

		curRspOffset = curRspOffset + CRes.sizeof
		local resrefStr = EEex_CastUD(resObj.resref, "CharString")
		resrefStr:pointTo(curRspOffset)
		resrefStr:write(resref)

		curRspOffset = curRspOffset + resrefLen
		local ptrToResObj = EEex_PtrToUD(curRspOffset, "Pointer<CRes>")
		ptrToResObj.reference = resObj

		toReturn = EngineGlobals.bsearch(
			ptrToResObj,
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

	local castFunc = ({
		["STO"] = function() return EEex_PtrToUD(EEex_UDToPtr(demanded) + 0x8, "CStoreFileHeader") end,
		["EFF"] = function() return EEex_PtrToUD(EEex_UDToPtr(demanded) + 0x8, "CGameEffectBase") end,
		["ITM"] = function() return EEex_CastUD(demanded, "Item_Header_st") end,
		["PRO"] = function()
			local base = EEex_PtrToUD(EEex_UDToPtr(demanded) + 0x8, "CProjectileFileFormat")
			local fileType = base.m_wFileType
			if fileType == 2 then
				return EEex_CastUD(base, "CProjectileBAMFileFormat")
			elseif fileType == 3 then
				return EEex_CastUD(base, "CProjectileAreaFileFormat")
			else
				return base
			end
		end,
		["SPL"] = function() return EEex_CastUD(demanded, "Spell_Header_st") end,
	})[extension:upper()]

	if castFunc then return castFunc() end
	return demanded
end

function EEex_Resource_GetSpellAbility(spellHeader, abilityIndex)
	if spellHeader.abilityCount <= abilityIndex then return end
	return EEex_PtrToUD(EEex_UDToPtr(spellHeader) + spellHeader.abilityOffset + Spell_ability_st.sizeof * abilityIndex, "Spell_ability_st")
end
Spell_Header_st.getAbility = EEex_Resource_GetSpellAbility

function EEex_Resource_GetItemAbility(itemHeader, abilityIndex)
	if abilityIndex < 0 or itemHeader.abilityCount <= abilityIndex then return end
	return EEex_PtrToUD(EEex_UDToPtr(itemHeader) + itemHeader.abilityOffset + Item_ability_st.sizeof * abilityIndex, "Item_ability_st")
end
Item_Header_st.getAbility = EEex_Resource_GetItemAbility

function EEex_Resource_GetCItemAbility(item, abilityIndex)
	return item.pRes.pHeader:getAbility(abilityIndex)
end
CItem.getAbility = EEex_Resource_GetCItemAbility

--------------------------------------
-- Item Runtime Mutation Helpers    --
--------------------------------------

-- This is intentionally looser than EEex_Item.lua's resref normalization:
-- item mutators use nil to mean "clear this field on the rebuilt ITM".
local function EEex_Resource_Private_NormalizeOptionalResRef(value, fieldName)
	if value == nil then
		return ""
	end
	if type(value) == "string" then
		return value
	end
	if type(value) == "userdata" and value.get then
		return value:get()
	end
	EEex_Error(fieldName.." must be a string or CResRef!")
end

local function EEex_Resource_Private_NormalizeAttackProbability(value)
	-- Accept either a Lua table or the engine's fixed-size attack-probability
	-- array, then normalize both shapes into one plain Lua array for staging.
	local attackProbability = {0, 0, 0, 0, 0, 0}
	if value == nil then
		return attackProbability
	end
	if type(value) == "table" then
		for i = 1, 6 do
			local entry = value[i]
			if entry == nil then
				entry = value[i - 1]
			end
			if entry ~= nil then
				attackProbability[i] = entry
			end
		end
		return attackProbability
	end
	if type(value) == "userdata" and value.get then
		for i = 0, 5 do
			attackProbability[i + 1] = value:get(i)
		end
		return attackProbability
	end
	EEex_Error("attackProbability must be a table or Array<unsigned __int16,6>!")
end

local function EEex_Resource_Private_CopyItemEffectData(effectData)
	-- Staging happens in pure Lua tables so effect templates can be copied,
	-- inserted, and fanned out across abilities without aliasing userdata.
	return {
		effectID = effectData.effectID,
		targetType = effectData.targetType,
		spellLevel = effectData.spellLevel,
		effectAmount = effectData.effectAmount,
		dwFlags = effectData.dwFlags,
		durationType = effectData.durationType,
		duration = effectData.duration,
		probabilityUpper = effectData.probabilityUpper,
		probabilityLower = effectData.probabilityLower,
		res = effectData.res,
		numDice = effectData.numDice,
		diceSize = effectData.diceSize,
		savingThrow = effectData.savingThrow,
		saveMod = effectData.saveMod,
		special = effectData.special,
	}
end

local function EEex_Resource_Private_CopyItemEffect(effect)
	return EEex_Resource_Private_CopyItemEffectData({
		effectID = effect.effectID,
		targetType = effect.targetType,
		spellLevel = effect.spellLevel,
		effectAmount = effect.effectAmount,
		dwFlags = effect.dwFlags,
		durationType = effect.durationType,
		duration = effect.duration,
		probabilityUpper = effect.probabilityUpper,
		probabilityLower = effect.probabilityLower,
		res = effect.res:get(),
		numDice = effect.numDice,
		diceSize = effect.diceSize,
		savingThrow = effect.savingThrow,
		saveMod = effect.saveMod,
		special = effect.special,
	})
end

local function EEex_Resource_Private_CopyItemAbility(ability)
	return {
		type = ability.type,
		quickSlotType = ability.quickSlotType,
		largeDamageDice = ability.largeDamageDice,
		quickSlotIcon = ability.quickSlotIcon:get(),
		actionType = ability.actionType,
		actionCount = ability.actionCount,
		range = ability.range,
		launcherType = ability.launcherType,
		largeDamageDiceCount = ability.largeDamageDiceCount,
		speedFactor = ability.speedFactor,
		largeDamageDiceBonus = ability.largeDamageDiceBonus,
		thac0Bonus = ability.thac0Bonus,
		damageDice = ability.damageDice,
		school = ability.school,
		damageDiceCount = ability.damageDiceCount,
		secondaryType = ability.secondaryType,
		damageDiceBonus = ability.damageDiceBonus,
		damageType = ability.damageType,
		effectCount = ability.effectCount,
		startingEffect = ability.startingEffect,
		maxUsageCount = ability.maxUsageCount,
		usageFlags = ability.usageFlags,
		abilityFlags = ability.abilityFlags,
		missileType = ability.missileType,
		attackProbability = EEex_Resource_Private_NormalizeAttackProbability(ability.attackProbability),
	}
end

local function EEex_Resource_Private_GetItemEffect(itemHeader, effectIndex)
	if effectIndex < 0 then return end
	return EEex_PtrToUD(EEex_UDToPtr(itemHeader) + itemHeader.effectsOffset + Item_effect_st.sizeof * effectIndex, "Item_effect_st")
end

local function EEex_Resource_Private_FindItemResource(itemHeader)
	if not itemHeader then
		EEex_Error("itemHeader must be defined!")
	end

	-- Mutators receive only an Item_Header_st pointer. Recover the owning CResItem
	-- by pointer identity so the rebuilt bytes get written back to the right ITM.
	local targetPtr = EEex_UDToPtr(itemHeader)
	local itemType = EEex_Resource_ExtToType("ITM")
	local resources = EngineGlobals.resources
	local resourceData = resources.m_pData

	for i = 0, resources.m_nSize - 1 do
		local res = resourceData:get(i)
		if res and res.type == itemType and res.bLoaded then
			local itemRes = EEex_CastUD(res, "CResItem")
			if itemRes.pHeader and EEex_UDToPtr(itemRes.pHeader) == targetPtr then
				return itemRes
			end
		end
	end

	EEex_Error("itemHeader must reference a demanded, engine-owned ITM resource!")
end

local function EEex_Resource_Private_ValidateNonNegativeIndex(index, name)
	if type(index) ~= "number" or index % 1 ~= 0 then
		EEex_Error(name.." must be an integer!")
	end
	if index < 0 then
		EEex_Error(name.." must be >= 0!")
	end
	return index
end

local function EEex_Resource_Private_ValidateAbilityIndexForInsert(abilityIndex)
	if abilityIndex == nil then
		return -1
	end
	if type(abilityIndex) ~= "number" or abilityIndex % 1 ~= 0 then
		EEex_Error("abilityIndex must be an integer!")
	end
	return abilityIndex
end

local function EEex_Resource_Private_ValidateWildcardIndex(index, name)
	if index == nil then
		return -1
	end
	if type(index) ~= "number" or index % 1 ~= 0 then
		EEex_Error(name.." must be an integer!")
	end
	return index
end

local function EEex_Resource_Private_NormalizeItemAbilityArgs(abilityArgs)
	-- Ability inserts are expressed as plain Lua data first; the ITM is rebuilt
	-- only after all defaults and caller overrides have been resolved.
	abilityArgs = abilityArgs or {}
	if type(abilityArgs) ~= "table" then
		EEex_Error("abilityArgs must be a table!")
	end
	if abilityArgs.effectCount ~= nil then
		EEex_Error("effectCount may not be defined!")
	end
	if abilityArgs.startingEffect ~= nil then
		EEex_Error("startingEffect may not be defined!")
	end

	local abilityData = {
		type = EEex_PackWord(0x3, 0x1), -- Type: Magical, Type flags: Usable after Identification
		quickSlotType = 3,                      -- Ability location: Quick-item slot / Use Item button
		largeDamageDice = 0,
		quickSlotIcon = "",
		actionType = 1,
		actionCount = 0,
		range = 100,
		launcherType = 0,
		largeDamageDiceCount = 0,
		speedFactor = 0,
		largeDamageDiceBonus = 0,
		thac0Bonus = 0,
		damageDice = 0,
		school = 0,
		damageDiceCount = 0,
		secondaryType = 0,
		damageDiceBonus = 0,
		damageType = 0,
		effectCount = 0,
		startingEffect = 0,
		maxUsageCount = 5,
		usageFlags = 1,                         -- When drained: Item vanishes
		abilityFlags = 0,
		missileType = 1,
		attackProbability = {0, 0, 0, 0, 0, 0},
		effects = {},
	}

	local numericKeys = {
		"type",
		"quickSlotType",
		"largeDamageDice",
		"actionType",
		"actionCount",
		"range",
		"launcherType",
		"largeDamageDiceCount",
		"speedFactor",
		"largeDamageDiceBonus",
		"thac0Bonus",
		"damageDice",
		"school",
		"damageDiceCount",
		"secondaryType",
		"damageDiceBonus",
		"damageType",
		"maxUsageCount",
		"usageFlags",
		"abilityFlags",
		"missileType",
	}

	for _, key in ipairs(numericKeys) do
		if abilityArgs[key] ~= nil then
			abilityData[key] = abilityArgs[key]
		end
	end

	abilityData.quickSlotIcon = EEex_Resource_Private_NormalizeOptionalResRef(abilityArgs.quickSlotIcon, "quickSlotIcon")
	abilityData.attackProbability = EEex_Resource_Private_NormalizeAttackProbability(abilityArgs.attackProbability)
	return abilityData
end

local function EEex_Resource_Private_NormalizeItemEffectArgs(effectArgs, defaultTargetType, defaultDurationType)
	-- Effect inserts use the same staged-table pattern as abilities so callers can
	-- describe one effect template before it is copied into the rebuilt ITM.
	effectArgs = effectArgs or {}
	if type(effectArgs) ~= "table" then
		EEex_Error("effectArgs must be a table!")
	end
	if effectArgs.effectID == nil then
		EEex_Error("effectID must be defined!")
	end

	local effectData = {
		effectID = effectArgs.effectID,
		targetType = defaultTargetType,
		spellLevel = 0,
		effectAmount = 0,
		dwFlags = 0,
		durationType = defaultDurationType,
		duration = 0,
		probabilityUpper = 100,
		probabilityLower = 0,
		res = "",
		numDice = 0,
		diceSize = 0,
		savingThrow = 0,
		saveMod = 0,
		special = 0,
	}

	local numericKeys = {
		"targetType",
		"spellLevel",
		"effectAmount",
		"dwFlags",
		"durationType",
		"duration",
		"probabilityUpper",
		"probabilityLower",
		"numDice",
		"diceSize",
		"savingThrow",
		"saveMod",
		"special",
	}

	for _, key in ipairs(numericKeys) do
		if effectArgs[key] ~= nil then
			effectData[key] = effectArgs[key]
		end
	end

	effectData.res = EEex_Resource_Private_NormalizeOptionalResRef(effectArgs.res, "res")
	return effectData
end

local function EEex_Resource_Private_StageItem(itemHeader)
	-- Mutators cannot safely edit the demanded ITM in place. Adding or removing
	-- abilities / effects changes block sizes, offsets, and startingEffect indices,
	-- so the entire resource has to be re-laid out as one fresh byte stream.
	--
	-- This staging pass snapshots every mutable piece into plain Lua tables before
	-- the rebuild happens. That keeps the read phase separate from the write phase,
	-- avoids chasing pointers into memory that will be replaced by dimmServiceFromMemory,
	-- and preserves the opaque bytes around the structured blocks verbatim.
	local itemRes = EEex_Resource_Private_FindItemResource(itemHeader)
	local itemDataBase = EEex_UDToPtr(itemHeader)
	local prefixSize = itemHeader.abilityOffset
	local oldAbilityBlockSize = itemHeader.abilityCount * Item_ability_st.sizeof
	local oldGapStart = itemDataBase + prefixSize + oldAbilityBlockSize
	local gapSize = itemHeader.effectsOffset - (prefixSize + oldAbilityBlockSize)
	-- Preserve the raw gap between ability and effect blocks byte-for-byte. The
	-- engine can leave padding or opaque data there, and rebuilds should not guess.
	if gapSize < 0 then
		EEex_Error("itemHeader contains overlapping ability and effect blocks!")
	end

	local maxEffectEnd = itemHeader.equipedStartingEffect + itemHeader.equipedEffectCount
	local equippedEffects = {}
	for localEffectIndex = 0, itemHeader.equipedEffectCount - 1 do
		local globalEffectIndex = itemHeader.equipedStartingEffect + localEffectIndex
		table.insert(equippedEffects, EEex_Resource_Private_CopyItemEffect(EEex_Resource_Private_GetItemEffect(itemHeader, globalEffectIndex)))
	end

	local abilities = {}
	for abilityIndex = 0, itemHeader.abilityCount - 1 do
		local ability = itemHeader:getAbility(abilityIndex)
		if not ability then
			EEex_Error("itemHeader ability traversal failed at index "..tostring(abilityIndex).."!")
		end

		local abilityData = EEex_Resource_Private_CopyItemAbility(ability)
		abilityData.effects = {}
		local abilityEffectEnd = abilityData.startingEffect + abilityData.effectCount
		if abilityEffectEnd > maxEffectEnd then
			maxEffectEnd = abilityEffectEnd
		end

		for localEffectIndex = 0, abilityData.effectCount - 1 do
			local globalEffectIndex = abilityData.startingEffect + localEffectIndex
			table.insert(abilityData.effects, EEex_Resource_Private_CopyItemEffect(EEex_Resource_Private_GetItemEffect(itemHeader, globalEffectIndex)))
		end

		table.insert(abilities, abilityData)
	end

	local oldEffectsEnd = itemHeader.effectsOffset + maxEffectEnd * Item_effect_st.sizeof
	if oldEffectsEnd > itemRes.nSize then
		EEex_Error("itemHeader effect block exceeds its owning ITM resource size!")
	end

	-- The returned table is the mutators' working copy: pure Lua data for every
	-- editable structure, plus the untouched byte ranges needed to reassemble the
	-- final ITM without guessing about engine-owned padding or trailing payloads.
	return {
		res = itemRes,
		dataBase = itemDataBase,
		prefixSize = prefixSize,
		oldAbilityBlockSize = oldAbilityBlockSize,
		gapSize = gapSize,
		oldGapAddress = oldGapStart,
		oldSuffixAddress = itemDataBase + oldEffectsEnd,
		suffixSize = itemRes.nSize - oldEffectsEnd,
		abilities = abilities,
		equippedEffects = equippedEffects,
	}
end

local function EEex_Resource_Private_WriteItemAbility(ability, abilityData)
	EEex_Memset(EEex_UDToPtr(ability), 0, Item_ability_st.sizeof)
	ability.type = abilityData.type
	ability.quickSlotType = abilityData.quickSlotType
	ability.largeDamageDice = abilityData.largeDamageDice
	ability.quickSlotIcon:set(abilityData.quickSlotIcon)
	ability.actionType = abilityData.actionType
	ability.actionCount = abilityData.actionCount
	ability.range = abilityData.range
	ability.launcherType = abilityData.launcherType
	ability.largeDamageDiceCount = abilityData.largeDamageDiceCount
	ability.speedFactor = abilityData.speedFactor
	ability.largeDamageDiceBonus = abilityData.largeDamageDiceBonus
	ability.thac0Bonus = abilityData.thac0Bonus
	ability.damageDice = abilityData.damageDice
	ability.school = abilityData.school
	ability.damageDiceCount = abilityData.damageDiceCount
	ability.secondaryType = abilityData.secondaryType
	ability.damageDiceBonus = abilityData.damageDiceBonus
	ability.damageType = abilityData.damageType
	ability.effectCount = abilityData.effectCount
	ability.startingEffect = abilityData.startingEffect
	ability.maxUsageCount = abilityData.maxUsageCount
	ability.usageFlags = abilityData.usageFlags
	ability.abilityFlags = abilityData.abilityFlags
	ability.missileType = abilityData.missileType
	for i = 0, 5 do
		ability.attackProbability:set(i, abilityData.attackProbability[i + 1] or 0)
	end
end

local function EEex_Resource_Private_WriteItemEffect(effect, effectData)
	EEex_Memset(EEex_UDToPtr(effect), 0, Item_effect_st.sizeof)
	effect.effectID = effectData.effectID
	effect.targetType = effectData.targetType
	effect.spellLevel = effectData.spellLevel
	effect.effectAmount = effectData.effectAmount
	effect.dwFlags = effectData.dwFlags
	effect.durationType = effectData.durationType
	effect.duration = effectData.duration
	effect.probabilityUpper = effectData.probabilityUpper
	effect.probabilityLower = effectData.probabilityLower
	effect.res:set(effectData.res)
	effect.numDice = effectData.numDice
	effect.diceSize = effectData.diceSize
	effect.savingThrow = effectData.savingThrow
	effect.saveMod = effectData.saveMod
	effect.special = effectData.special
end

local function EEex_Resource_Private_RebuildItem(stagedItem)
	local rebuiltHeader
	local newAbilityBlockSize = #stagedItem.abilities * Item_ability_st.sizeof
	local newEffectsCount = #stagedItem.equippedEffects
	for _, abilityData in ipairs(stagedItem.abilities) do
		newEffectsCount = newEffectsCount + #abilityData.effects
	end

	local newEffectsBlockSize = newEffectsCount * Item_effect_st.sizeof
	local newEffectsOffset = stagedItem.prefixSize + newAbilityBlockSize + stagedItem.gapSize
	local newSuffixAddress = newEffectsOffset + newEffectsBlockSize
	local newSize = newSuffixAddress + stagedItem.suffixSize

	-- Rebuild the demanded ITM in stack memory, flattening equipped effects and all
	-- ability effect lists into one contiguous effect block with fresh indices.
	EEex_RunWithStack(newSize, function(bufferBase)
		EEex_Memset(bufferBase, 0, newSize)
		EEex_Memcpy(bufferBase, stagedItem.dataBase, stagedItem.prefixSize)

		local newHeader = EEex_PtrToUD(bufferBase, "Item_Header_st")
		newHeader.abilityOffset = stagedItem.prefixSize
		newHeader.abilityCount = #stagedItem.abilities
		newHeader.effectsOffset = newEffectsOffset
		newHeader.equipedStartingEffect = 0
		newHeader.equipedEffectCount = #stagedItem.equippedEffects

		local nextAbilityBase = bufferBase + stagedItem.prefixSize
		local nextEffectIndex = #stagedItem.equippedEffects
		for _, abilityData in ipairs(stagedItem.abilities) do
			abilityData.effectCount = #abilityData.effects
			abilityData.startingEffect = nextEffectIndex
			EEex_Resource_Private_WriteItemAbility(EEex_PtrToUD(nextAbilityBase, "Item_ability_st"), abilityData)
			nextAbilityBase = nextAbilityBase + Item_ability_st.sizeof
			nextEffectIndex = nextEffectIndex + abilityData.effectCount
		end

		if stagedItem.gapSize > 0 then
			EEex_Memcpy(bufferBase + stagedItem.prefixSize + newAbilityBlockSize, stagedItem.oldGapAddress, stagedItem.gapSize)
		end

		local nextEffectBase = bufferBase + newEffectsOffset
		for _, effectData in ipairs(stagedItem.equippedEffects) do
			EEex_Resource_Private_WriteItemEffect(EEex_PtrToUD(nextEffectBase, "Item_effect_st"), effectData)
			nextEffectBase = nextEffectBase + Item_effect_st.sizeof
		end
		for _, abilityData in ipairs(stagedItem.abilities) do
			for _, effectData in ipairs(abilityData.effects) do
				EEex_Resource_Private_WriteItemEffect(EEex_PtrToUD(nextEffectBase, "Item_effect_st"), effectData)
				nextEffectBase = nextEffectBase + Item_effect_st.sizeof
			end
		end

		if stagedItem.suffixSize > 0 then
			EEex_Memcpy(bufferBase + newSuffixAddress, stagedItem.oldSuffixAddress, stagedItem.suffixSize)
		end

		EngineGlobals.dimmServiceFromMemory(stagedItem.res, EEex_PtrToUD(bufferBase, "VariableArray<char>"), newSize, false, true)
		local demanded = stagedItem.res:Demand()
		if not demanded then
			EEex_Error("EEex_Resource_Private_RebuildItem: failed to redemand rebuilt ITM resource!")
		end
		rebuiltHeader = EEex_CastUD(demanded, "Item_Header_st")
	end)
	return rebuiltHeader
end

local function EEex_Resource_Private_GetStagedAbility(stagedItem, abilityIndex, funcName)
	abilityIndex = EEex_Resource_Private_ValidateNonNegativeIndex(abilityIndex, "abilityIndex")
	local abilityData = stagedItem.abilities[abilityIndex + 1]
	if not abilityData then
		EEex_Error(funcName..": abilityIndex is out of range!")
	end
	return abilityData
end

-- These mutators rebuild the ITM resource in-place. Previously held pointers into the
-- demanded header, ability, or effect blocks should be treated as stale after a mutation.
-- They all start from EEex_Resource_Private_StageItem() so traversal happens against the
-- original demanded resource exactly once, before any rewrite invalidates those pointers.
-- Callers should use the returned Item_Header_st for any follow-up mutation.

-- @bubb_doc { EEex_Resource_AddItemAbility / instance_name=addAbility }
--
-- @summary: Appends a new ability to ``itemHeader`` and returns the rebuilt demanded ITM header.
--
-- @self { itemHeader / usertype=Item_Header_st }: The demanded item header to mutate.
--
-- @param { abilityArgs / type=table|nil }: Optional ability fields for the inserted ability.
--
-- @return { type=Item_Header_st }: The rebuilt demanded item header.

function EEex_Resource_AddItemAbility(itemHeader, abilityArgs)
	local stagedItem = EEex_Resource_Private_StageItem(itemHeader)
	table.insert(stagedItem.abilities, EEex_Resource_Private_NormalizeItemAbilityArgs(abilityArgs))
	return EEex_Resource_Private_RebuildItem(stagedItem)
end
Item_Header_st.addAbility = EEex_Resource_AddItemAbility

-- @bubb_doc { EEex_Resource_AddItemEqEffect / instance_name=addEqEffect }
--
-- @summary: Appends an equipped effect to ``itemHeader`` and returns the rebuilt demanded ITM header.
--
-- @self { itemHeader / usertype=Item_Header_st }: The demanded item header to mutate.
--
-- @param { effectArgs / type=table|nil }: Optional effect fields for the inserted equipped effect.
--
-- @return { type=Item_Header_st }: The rebuilt demanded item header.

function EEex_Resource_AddItemEqEffect(itemHeader, effectArgs)
	local stagedItem = EEex_Resource_Private_StageItem(itemHeader)
	table.insert(stagedItem.equippedEffects, EEex_Resource_Private_NormalizeItemEffectArgs(
		effectArgs,
		1,
		EEex_PackWord(0x2, 0x0) -- Timing mode: Instant/While equipped, Dispel/Resistance: Natural/Nonmagical
	))
	return EEex_Resource_Private_RebuildItem(stagedItem)
end
Item_Header_st.addEqEffect = EEex_Resource_AddItemEqEffect

-- @bubb_doc { EEex_Resource_AddItemEffect / instance_name=addEffect }
--
-- @summary: Adds an ability effect to one ability or to every ability when ``abilityIndex`` is ``nil``.
--
-- @self { itemHeader / usertype=Item_Header_st }: The demanded item header to mutate.
--
-- @param { effectArgs / type=table|nil }: Optional effect fields for the inserted ability effect.
--
-- @param { abilityIndex / type=number|nil / default=nil }:
--     The zero-based ability index to target. If ``nil``, the effect is copied into every ability. @EOL
--
-- @return { type=Item_Header_st }: The rebuilt demanded item header.

function EEex_Resource_AddItemEffect(itemHeader, effectArgs, abilityIndex)
	abilityIndex = EEex_Resource_Private_ValidateAbilityIndexForInsert(abilityIndex)
	local stagedItem = EEex_Resource_Private_StageItem(itemHeader)
	local effectData = EEex_Resource_Private_NormalizeItemEffectArgs(effectArgs, 2, 0)

	if abilityIndex < 0 then
		-- Insert into every ability. Copy the staged effect table for each target so
		-- later edits or rebuild bookkeeping never share the same table instance.
		if #stagedItem.abilities == 0 then
			EEex_Error("EEex_Resource_AddItemEffect: itemHeader has no abilities!")
		end
		for _, abilityData in ipairs(stagedItem.abilities) do
			table.insert(abilityData.effects, EEex_Resource_Private_CopyItemEffectData(effectData))
		end
	else
		table.insert(EEex_Resource_Private_GetStagedAbility(stagedItem, abilityIndex, "EEex_Resource_AddItemEffect").effects,
			EEex_Resource_Private_CopyItemEffectData(effectData))
	end

	return EEex_Resource_Private_RebuildItem(stagedItem)
end
Item_Header_st.addEffect = EEex_Resource_AddItemEffect

-- @bubb_doc { EEex_Resource_RemoveItemAbility / instance_name=removeAbility }
--
-- @summary: Removes one ability or all abilities when ``abilityIndex`` is ``nil``, then returns the rebuilt demanded ITM header.
--
-- @self { itemHeader / usertype=Item_Header_st }: The demanded item header to mutate.
--
-- @param { abilityIndex / type=number|nil / default=nil }:
--     The zero-based ability index to remove. If ``nil``, removes every ability. @EOL
--
-- @return { type=Item_Header_st }: The rebuilt demanded item header.

function EEex_Resource_RemoveItemAbility(itemHeader, abilityIndex)
	local stagedItem = EEex_Resource_Private_StageItem(itemHeader)
	abilityIndex = EEex_Resource_Private_ValidateWildcardIndex(abilityIndex, "abilityIndex")
	if abilityIndex < 0 then
		stagedItem.abilities = {}
	elseif stagedItem.abilities[abilityIndex + 1] == nil then
		EEex_Error("EEex_Resource_RemoveItemAbility: abilityIndex is out of range!")
	else
		table.remove(stagedItem.abilities, abilityIndex + 1)
	end
	return EEex_Resource_Private_RebuildItem(stagedItem)
end
Item_Header_st.removeAbility = EEex_Resource_RemoveItemAbility

-- @bubb_doc { EEex_Resource_RemoveItemEqEffect / instance_name=removeEqEffect }
--
-- @summary: Removes one equipped effect or all equipped effects when ``effectIndex`` is ``nil``, then returns the rebuilt demanded ITM header.
--
-- @self { itemHeader / usertype=Item_Header_st }: The demanded item header to mutate.
--
-- @param { effectIndex / type=number|nil / default=nil }:
--     The zero-based equipped-effect index to remove. If ``nil``, removes every equipped effect. @EOL
--
-- @return { type=Item_Header_st }: The rebuilt demanded item header.

function EEex_Resource_RemoveItemEqEffect(itemHeader, effectIndex)
	local stagedItem = EEex_Resource_Private_StageItem(itemHeader)
	effectIndex = EEex_Resource_Private_ValidateWildcardIndex(effectIndex, "effectIndex")
	if effectIndex < 0 then
		stagedItem.equippedEffects = {}
	elseif stagedItem.equippedEffects[effectIndex + 1] == nil then
		EEex_Error("EEex_Resource_RemoveItemEqEffect: effectIndex is out of range!")
	else
		table.remove(stagedItem.equippedEffects, effectIndex + 1)
	end
	return EEex_Resource_Private_RebuildItem(stagedItem)
end
Item_Header_st.removeEqEffect = EEex_Resource_RemoveItemEqEffect

-- @bubb_doc { EEex_Resource_RemoveItemEffect / instance_name=removeEffect }
--
-- @summary: Removes one ability effect, or a wildcard-selected set of ability effects, then returns the rebuilt demanded ITM header.
--
-- @self { itemHeader / usertype=Item_Header_st }: The demanded item header to mutate.
--
-- @param { effectIndex / type=number|nil / default=nil }:
--     The zero-based ability-effect index to remove. If ``nil``, clears the matched ability effect lists. @EOL
--
-- @param { abilityIndex / type=number|nil / default=nil }:
--     The zero-based ability index to target. If ``nil``, applies the removal across every ability. @EOL
--
-- @return { type=Item_Header_st }: The rebuilt demanded item header.

function EEex_Resource_RemoveItemEffect(itemHeader, effectIndex, abilityIndex)
	local stagedItem = EEex_Resource_Private_StageItem(itemHeader)
	effectIndex = EEex_Resource_Private_ValidateWildcardIndex(effectIndex, "effectIndex")
	abilityIndex = EEex_Resource_Private_ValidateWildcardIndex(abilityIndex, "abilityIndex")

	-- Negative indices mean "all matched entries": abilityIndex < 0 fans out across
	-- every ability, and effectIndex < 0 clears the whole targeted effect list.
	if abilityIndex < 0 then
		if effectIndex < 0 then
			for _, abilityData in ipairs(stagedItem.abilities) do
				abilityData.effects = {}
			end
		else
			local matchedAny = false
			for _, abilityData in ipairs(stagedItem.abilities) do
				if abilityData.effects[effectIndex + 1] ~= nil then
					table.remove(abilityData.effects, effectIndex + 1)
					matchedAny = true
				end
			end
			if not matchedAny then
				EEex_Error("EEex_Resource_RemoveItemEffect: effectIndex is out of range for all matched abilities!")
			end
		end
	else
		local abilityData = EEex_Resource_Private_GetStagedAbility(stagedItem, abilityIndex, "EEex_Resource_RemoveItemEffect")
		if effectIndex < 0 then
			abilityData.effects = {}
		elseif abilityData.effects[effectIndex + 1] == nil then
			EEex_Error("EEex_Resource_RemoveItemEffect: effectIndex is out of range!")
		else
			table.remove(abilityData.effects, effectIndex + 1)
		end
	end
	return EEex_Resource_Private_RebuildItem(stagedItem)
end
Item_Header_st.removeEffect = EEex_Resource_RemoveItemEffect

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

-- @bubb_doc { EEex_Resource_GetStoreItemsIterator / instance_name=getItemsIterator | getItemsItr }
--
-- @summary: Returns an iterator that traverses the ``CStoreFileItem`` entries pointed to by ``storeHeader``.
--
-- @self { storeHeader / usertype=CStoreFileHeader }: The header of the .STO file whose items are to be iterated.
--
-- @return { type=function() -> CStoreFileItem }: See summary.

function EEex_Resource_GetStoreItemsIterator(storeHeader)

	local fileBase = EEex_UDToPtr(storeHeader) - 0x8

	local itemsBase = fileBase + storeHeader.m_nInventoryOffset
	local itemSize = CStoreFileItem.sizeof

	local curItemBase = itemsBase
	local endItemBase = itemsBase + itemSize * storeHeader.m_nInventoryCount

	return function()
		if curItemBase >= endItemBase then return end
		local toReturn = EEex_PtrToUD(curItemBase, "CStoreFileItem")
		curItemBase = curItemBase + itemSize
		return toReturn
	end
end
EEex_Resource_GetStoreItemsItr    = EEex_Resource_GetStoreItemsIterator
CStoreFileHeader.getItemsIterator = EEex_Resource_GetStoreItemsIterator
CStoreFileHeader.getItemsItr      = EEex_Resource_GetStoreItemsIterator

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
	return array:FindColumnLabel(toSearchFor)
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
	return array:FindRowLabel(toSearchFor)
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
-- @return { type=string }: See summary.

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
	return array:GetAtLabels(columnLabel, rowLabel).m_pchData:get()
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
	return array:GetAtPoint(columnIndex, rowIndex).m_pchData:get()
end
C2DArray.getAtPoint = EEex_Resource_GetAt2DAPoint

-- @bubb_doc { EEex_Resource_GetMax2DAIndices / instance_name=getMaxIndices }
--
-- @summary: Returns the maximum x and y indices of the .2DA. That is the maximum indexable column, and the maximum indexable row respectively.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @return { type=number }: The .2DA's maximum 'x' index.
--
-- @return { type=number }: The .2DA's maximum 'y' index.

function EEex_Resource_GetMax2DAIndices(array)
	return array.m_nSizeX - 2, array.m_nSizeY - 1
end
C2DArray.getMaxIndices = EEex_Resource_GetMax2DAIndices

-- @bubb_doc { EEex_Resource_Iterate2DAColumnIndex / instance_name=iterateColumnIndex }
--
-- @summary: Calls ``func`` for every value in the column specified by ``columnIndex``. If ``func`` returns ``true`` the iteration ends early.
--
-- @self { array / usertype=C2DArray }: The .2DA file being operated on. This is usually the object returned by ``EEex_Resource_Load2DA()``.
--
-- @param { columnIndex / type=number }: The index of the column whose values are to be iterated.
--
-- @param { func / type=function(i: number, value: string) -> boolean }: The function to be called.

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
-- @param { func / type=function(i: number, value: string) -> boolean }: The function to be called.

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
-- @param { func / type=function(i: number, value: string) -> boolean }: The function to be called.

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
-- @param { func / type=function(i: number, value: string) -> boolean }: The function to be called.

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

-- @bubb_doc { EEex_Resource_FreeIDS / instance_name=free }
--
-- @summary: Frees the memory associated with ``ids``. *** Only use this if you know what you are doing! ***
--
-- @note: ``CAIIdList`` objects returned by ``EEex_Resource_LoadIDS()`` are subject to garbage-collection
--        – meaning ``EEex_Resource_FreeIDS()`` should ***not*** be called on these instances.
--
-- @self { ids / usertype=CAIIdList }: The .IDS file being operated on. This is usually the object returned by ``EEex_Resource_LoadIDS()``.

function EEex_Resource_FreeIDS(ids)
	EEex_SetUDGCFunc(ids, nil)
	ids:Destruct()
	EEex_FreeUD(ids)
end
CAIIdList.free = EEex_Resource_FreeIDS

-- @bubb_doc { EEex_Resource_GetIDSCount / instance_name=getCount }
--
-- @summary: Returns the size of ``ids``'s backing cache array.
--
-- @warning: This function is only valid if the .IDS was loaded with ``cacheAsArray=true``.
--
-- @self { ids / usertype=CAIIdList }: The .IDS file being operated on. This is usually the object returned by ``EEex_Resource_LoadIDS()``.
--
-- @return { type=number }: See summary.

function EEex_Resource_GetIDSCount(ids)
	return ids.m_nArray
end
CAIIdList.getCount = EEex_Resource_GetIDSCount

-- @bubb_doc { EEex_Resource_GetIDSEntry / instance_name=getEntry }
--
-- @summary: Returns the ``CAIId`` entry with the given ``id``, or ``nil`` if ``id`` is not present in the .IDS.
--
-- @note: This function performs a linear search unless the .IDS was loaded with ``cacheAsArray=true``.
--
-- @self { ids / usertype=CAIIdList }: The .IDS file being operated on. This is usually the object returned by ``EEex_Resource_LoadIDS()``.
--
-- @param { id / type=number }: The id of the entry to be fetched.
--
-- @return { usertype=CAIId }: See summary.

function EEex_Resource_GetIDSEntry(ids, id)
	local array = ids.m_pIdArray
	if array then
		return id < ids.m_nArray and array:get(id) or nil
	else
		local found = nil
		ids:iterateEntries(function(entry)
			if entry.m_id == id then
				found = entry
				return true
			end
		end)
		return found
	end
end
CAIIdList.getEntry = EEex_Resource_GetIDSEntry

-- @bubb_doc { EEex_Resource_GetIDSLine / instance_name=getLine }
--
-- @summary: Returns the symbol associated with the given ``id``, or ``nil`` if ``id`` is not present in the .IDS.
--
-- @note: This function performs a linear search unless the .IDS was loaded with ``cacheAsArray=true``.
--
-- @self { ids / usertype=CAIIdList }: The .IDS file being operated on. This is usually the object returned by ``EEex_Resource_LoadIDS()``.
--
-- @param { id / type=number }: The id of the symbol to be fetched.
--
-- @return { type=string }: See summary.

function EEex_Resource_GetIDSLine(ids, id)
	local entry = ids:getEntry(id)
	return entry and entry.m_line.m_pchData:get() or nil
end
CAIIdList.getLine = EEex_Resource_GetIDSLine

-- @bubb_doc { EEex_Resource_GetIDSStart / instance_name=getStart }
--
-- @summary: Returns the symbol value associated with the given ``id`` up until (and not including)
--           the first '(' character, or ``nil`` if ``id`` is not present in the .IDS.
--
-- @note: This function performs a linear search unless the .IDS was loaded with ``cacheAsArray=true``.
--
-- @self { ids / usertype=CAIIdList }: The .IDS file being operated on. This is usually the object returned by ``EEex_Resource_LoadIDS()``.
--
-- @param { id / type=number }: The id of the symbol to be fetched.
--
-- @return { type=string }: See summary.

function EEex_Resource_GetIDSStart(ids, id)
	local entry = ids:getEntry(id)
	return entry and entry.m_start.m_pchData:get() or nil
end
CAIIdList.getStart = EEex_Resource_GetIDSStart

-- @bubb_doc { EEex_Resource_IDSHasID / instance_name=hasID }
--
-- @summary: Returns ``true`` if the given ``id`` is present in the .IDS.
--
-- @note: This function performs a linear search unless the .IDS was loaded with ``cacheAsArray=true``.
--
-- @self { ids / usertype=CAIIdList }: The .IDS file being operated on. This is usually the object returned by ``EEex_Resource_LoadIDS()``.
--
-- @param { id / type=number }: The id to search for.
--
-- @return { type=boolean }: See summary.

function EEex_Resource_IDSHasID(ids, id)
	return ids:getEntry(id) ~= nil
end
CAIIdList.hasID = EEex_Resource_IDSHasID

-- @bubb_doc { EEex_Resource_IterateIDSEntries / instance_name=iterateEntries }
--
-- @summary: Calls ``func`` for every ``CAIId`` entry of the .IDS. If ``func`` returns ``true`` the iteration ends early.
--
-- @self { ids / usertype=CAIIdList }: The .IDS file being operated on. This is usually the object returned by ``EEex_Resource_LoadIDS()``.
--
-- @param { func / type=function(entry: CAIId) -> boolean }: The function to be called.

function EEex_Resource_IterateIDSEntries(ids, func)
	EEex_Utility_IterateCPtrList(ids.m_idList, func)
end
CAIIdList.iterateEntries = EEex_Resource_IterateIDSEntries

-- @bubb_doc { EEex_Resource_IterateUnpackedIDSEntries / instance_name=iterateUnpackedEntries }
--
-- @summary: Calls ``func`` for every ``CAIId`` entry of the .IDS, unpacking the entry's members for convenience.
--           If ``func`` returns ``true`` the iteration ends early.
--
-- @self { ids / usertype=CAIIdList }: The .IDS file being operated on. This is usually the object returned by ``EEex_Resource_LoadIDS()``.
--
-- @param { func / type=function(id: number, line: string, start: string) -> boolean }:
--
--     The function to be called.                                                                  @EOL
--                                                                                                 @EOL
--     ``id`` – the entry's numerical value.                                                       @EOL
--     ``line`` – the entry's complete symbol value.                                               @EOL
--     ``start`` – the entry's symbol value up until (and not including) the first '(' character.

function EEex_Resource_IterateUnpackedIDSEntries(ids, func)
	ids:iterateEntries(function(entry)
		return func(entry.m_id, entry.m_line.m_pchData:get(), entry.m_start.m_pchData:get())
	end)
end
CAIIdList.iterateUnpackedEntries = EEex_Resource_IterateUnpackedIDSEntries

-- @bubb_doc { EEex_Resource_LoadIDS }
--
-- @summary: Returns a ``CAIIdList`` instance that represents the .IDS with ``resref``.
--
-- @param { resref / type=string }: The resref of the .IDS to be loaded – (should omit the file extension).
--
-- @param { cacheAsArray / type=boolean / default=false }:
--
--     If ``true``, internally builds an array that maps every id of the .IDS to its corresponding ``CAIId`` entry in the      @EOL
--     range [0, <max id in .IDS>].                                                                                            @EOL
--                                                                                                                             @EOL
--     Setting this parameter to ``true`` can speed up entry lookups for the returned ``CAIIdList`` instance – ***however***,  @EOL
--     care must be taken that the given .IDS does not have a large max id value.                                              @EOL
--                                                                                                                             @EOL
--     For example, it would be a bad idea to load ``KIT.IDS`` with ``cacheAsArray=true``, as the max id of ``KIT.IDS``,       @EOL
--     ``0x80000000``, would cause the ``CAIIdList`` instance to attempt to allocate an array that has a size of               @EOL
--     ``(0x80000000 + 1) * 8 bytes`` *** = ~16 gigabytes! ***
--
-- @return { type=CAIIdList }: See summary.

function EEex_Resource_LoadIDS(resref, cacheAsArray)
	local ids = EEex_NewUD("CAIIdList")
	ids:Construct1()
	EEex_RunWithStackManager({
		{ ["name"] = "resref", ["struct"] = "CResRef", ["constructor"] = {["args"] = {resref} }}, },
		function(manager)
			ids:LoadList2(manager:getUD("resref"), cacheAsArray or false)
		end)
	EEex_SetUDGCFunc(ids, EEex_Resource_FreeIDS)
	return ids
end

----------------
-- .BCS / .BS --
----------------

-- @bubb_doc { EEex_Resource_FreeScript / instance_name=free }
--
-- @summary: Frees the memory associated with ``script``. *** Only use this if you know what you are doing! ***
--
-- @note: ``CAIScript`` objects returned by ``EEex_Resource_LoadScript()`` are subject to garbage-collection
--        – meaning ``EEex_Resource_FreeScript()`` should ***not*** be called on these instances.
--
-- @self { script / usertype=CAIScript }: The .BCS / .BS file being operated on. This is usually the object returned by ``EEex_Resource_LoadScript()``.

function EEex_Resource_FreeScript(script)
	EEex_SetUDGCFunc(script, nil)
	script:Destruct()
	EEex_FreeUD(script)
end
CAIScript.free = EEex_Resource_FreeScript

-- @bubb_doc { EEex_Resource_LoadScript }
--
-- @summary: Returns a ``CAIScript`` instance that represents the .BCS / .BS with ``resref``.
--
-- @param { resref / type=string }: The resref of the .BCS / .BS to be loaded – (should omit the file extension).
--
-- @param { bPlayerScript / type=boolean / default=false }:
--
--     If ``true``, signifies that ``resref`` has the extension ``.BS`` instead of ``.BCS``.  @EOL @EOL
--
--     **Note:** Due to the enhanced edition’s use of script caching, the engine has trouble  @EOL
--     differentiating between ``.BS`` and ``.BCS`` files with the same name. If a script     @EOL
--     with the given ``resref`` has already been loaded by the engine, that script will be   @EOL
--     used, regardless of ``bPlayerScript``.
--
-- @return { type=CAIScript }: See summary.

function EEex_Resource_LoadScript(resref, bPlayerScript)
	local script = EEex_NewUD("CAIScript")
	EEex_RunWithStackManager({
		{ ["name"] = "resref", ["struct"] = "CResRef", ["constructor"] = {["args"] = {resref} }}, },
		function(manager)
			script:Construct1(manager:getUD("resref"), bPlayerScript or false)
		end)
	EEex_SetUDGCFunc(script, EEex_Resource_FreeScript)
	return script
end

---------------------------------------------------
-- Lua tables derived from .2DA / .IDS resources --
---------------------------------------------------

EEex_Resource_Private_ItemCategoryIDSToSymbol = {}
EEex_Resource_Private_ItemCategorySymbolToIDS = {}

function EEex_Resource_ItemCategoryIDSToSymbol(itemCategoryIDS)
	return EEex_Resource_Private_ItemCategoryIDSToSymbol[itemCategoryIDS]
end

function EEex_Resource_ItemCategorySymbolToIDS(itemCategorySymbol)
	return EEex_Resource_Private_ItemCategorySymbolToIDS[itemCategorySymbol]
end

EEex_Resource_Private_KitIDSToSymbol = {}
EEex_Resource_Private_KitSymbolToIDS = {}

function EEex_Resource_KitIDSToSymbol(kitIDS)
	return EEex_Resource_Private_KitIDSToSymbol[kitIDS]
end

function EEex_Resource_KitSymbolToIDS(kitSymbol)
	return EEex_Resource_Private_KitSymbolToIDS[kitSymbol]
end

EEex_Resource_Private_KitIgnoresMeleeingWithRangedPenaltyForItemCategory = {}

EEex_GameState_AddInitializedListener(function()

	-----------------
	-- KITLIST.2DA --
	-----------------

	-- Fills:
	--     [table] EEex_Resource_Private_KitIDSToSymbol
	--     [table] EEex_Resource_Private_KitSymbolToIDS

	EEex_Utility_NewScope(function()

		local kitlist = EEex_Resource_Load2DA("KITLIST")
		local _, lastRowIndex = kitlist:getMaxIndices()

		local kitSymbolColumn = kitlist:findColumnLabel("ROWNAME")
		local kitIDSColumn = kitlist:findColumnLabel("KITIDS")

		for rowIndex = 0, lastRowIndex do
			local kitIDSStr = kitlist:getAtPoint(kitIDSColumn, rowIndex)
			if kitIDSStr:sub(1, 2):lower() == "0x" then
				local kitIDS = tonumber(kitIDSStr:sub(3), 16)
				if kitIDS ~= nil then
					local kitSymbol = kitlist:getAtPoint(kitSymbolColumn, rowIndex)
					EEex_Resource_Private_KitIDSToSymbol[kitIDS] = kitSymbol
					EEex_Resource_Private_KitSymbolToIDS[kitSymbol] = kitIDS
				end
			end
		end
	end)

	-----------------
	-- ITEMCAT.IDS --
	-----------------

	-- Fills:
	--     [table] EEex_Resource_Private_ItemCategoryIDSToSymbol

	EEex_Utility_NewScope(function()
		local itemcat = EEex_Resource_LoadIDS("ITEMCAT")
		itemcat:iterateUnpackedEntries(function(id, symbol, _)
			EEex_Resource_Private_ItemCategoryIDSToSymbol[id] = symbol
			EEex_Resource_Private_ItemCategorySymbolToIDS[symbol] = id
		end)
	end)

	------------------
	-- X-CLSERG.2DA --
	------------------

	-- Fills:
	--     [table] EEex_Resource_Private_KitIgnoresMeleeingWithRangedPenaltyForItemCategory

	EEex_Utility_NewScope(function()

		local data = EEex_Resource_Load2DA("X-CLSERG")
		local lastColumnIndex, lastRowIndex = data:getMaxIndices()

		for rowIndex = 0, lastRowIndex do

			local kitSymbol = data:getRowLabel(rowIndex)
			local kitIDS = EEex_Resource_KitSymbolToIDS(kitSymbol)

			if kitIDS ~= nil then

				local itemCategories = {}
				EEex_Resource_Private_KitIgnoresMeleeingWithRangedPenaltyForItemCategory[kitIDS] = itemCategories

				for columnIndex = 0, lastColumnIndex do

					itemCategory = EEex_Resource_ItemCategorySymbolToIDS(data:getColumnLabel(columnIndex))

					if itemCategory ~= nil then
						local value = data:getAtPoint(columnIndex, rowIndex) == "1"
						itemCategories[itemCategory] = value
					end
				end
			end
		end
	end)
end)
