
-----------------------------
-- User Data Lua Functions --
-----------------------------

C2DArray.findColumnIndex = EEex_Resource_Find2DAColumnIndex
C2DArray.findColumnLabel = EEex_Resource_Find2DAColumnLabel
C2DArray.findRowIndex = EEex_Resource_Find2DARowIndex
C2DArray.findRowLabel = EEex_Resource_Find2DARowLabel
C2DArray.free = EEex_Resource_Free2DA
C2DArray.getAtLabels = EEex_Resource_GetAt2DALabels
C2DArray.getAtPoint = EEex_Resource_GetAt2DAPoint
C2DArray.getColumnLabel = EEex_Resource_Get2DAColumnLabel
C2DArray.getDefault = EEex_Resource_Get2DADefault
C2DArray.getDimensions = EEex_Resource_Get2DADimensions
C2DArray.getRowLabel = EEex_Resource_Get2DARowLabel
C2DArray.iterateColumnIndex = EEex_Resource_Iterate2DAColumnIndex
C2DArray.iterateColumnLabel = EEex_Resource_Iterate2DAColumnLabel
C2DArray.iterateRowIndex = EEex_Resource_Iterate2DARowIndex
C2DArray.iterateRowLabel = EEex_Resource_Iterate2DARowLabel

CAIIdList.free = EEex_Resource_FreeIDS
CAIIdList.getCount = EEex_Resource_GetIDSCount
CAIIdList.getEntry = EEex_Resource_GetIDSEntry
CAIIdList.getLine = EEex_Resource_GetIDSLine
CAIIdList.getStart = EEex_Resource_GetIDSStart
CAIIdList.hasID = EEex_Resource_IDSHasID

CGameObject.applyEffect = EEex_GameObject_ApplyEffect
CGameObject.getClass = EEex_GameObject_GetClass
CGameObject.isSprite = EEex_GameObject_IsSprite

CGameSprite.getActiveStats = EEex_Sprite_GetActiveStats
CGameSprite.getCastTimer = EEex_Sprite_GetCastTimer
CGameSprite.getCastTimerPercentage = EEex_Sprite_GetCastTimerPercentage
CGameSprite.getContingencyTimer = EEex_Sprite_GetContingencyTimer
CGameSprite.getContingencyTimerPercentage = EEex_Sprite_GetContingencyTimerPercentage
CGameSprite.getModalState = EEex_Sprite_GetModalState
CGameSprite.getModalTimer = EEex_Sprite_GetModalTimer
CGameSprite.getModalTimerPercentage = EEex_Sprite_GetModalTimerPercentage

Spell_Header_st.getAbility = EEex_Resource_GetSpellAbility
Spell_Header_st.getAbilityForLevel = EEex_Resource_GetSpellAbilityForLevel

uiVariant.getValue = EEex_Menu_GetItemVariant
uiVariant.setValue = EEex_Menu_SetItemVariant

--------------------------------
-- Memory Manager Definitions --
--------------------------------

EEex_MemoryManagerStructDefinitions["C2DArray"] = {
	["constructors"] = {
		["#default"] = C2DArray.Construct,
	},
	["destructor"] = C2DArray.Destruct,
}

EEex_MemoryManagerStructDefinitions["CPoint"] = {
	["constructors"] = {
		["fromXY"] = function(point, x, y)
			point.x = x
			point.y = y
		end,
	},
}

EEex_MemoryManagerStructDefinitions["CResRef"] = {
	["constructors"] = {
		["#default"] = CResRef.set,
	},
}

EEex_MemoryManagerStructDefinitions["CString"] = {
	["constructors"] = {
		["#default"] = CString.ConstructFromChars,
	},
	["destructor"] = CString.Destruct,
}

EEex_MemoryManagerStructDefinitions["string"] = {
	["constructors"] = {
		["#default"] = function(address, luaString)
			EEex_WriteString(address, luaString)
		end,
	},
	["size"] = function(luaString)
		return #luaString + 1
	end,
}

EEex_MemoryManagerStructDefinitions["uninitialized"] = {
	["size"] = function(size)
		return size
	end,
}
