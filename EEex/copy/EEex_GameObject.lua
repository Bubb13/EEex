
---------------------------
-- Fetching Game Objects --
---------------------------

function EEex_GameObject_CastUserType(object)

	if not object then
		return nil
	end

	local usertype = ({
		[CGameObjectType.NONE]          = nil,
		[CGameObjectType.AIBASE]        = "CGameAIBase",
		[CGameObjectType.SOUND]         = "CGameSound",
		[CGameObjectType.CONTAINER]     = "CGameContainer",
		[CGameObjectType.SPAWNING]      = "CGameSpawning",
		[CGameObjectType.DOOR]          = "CGameDoor",
		[CGameObjectType.STATIC]        = "CGameStatic",
		[CGameObjectType.SPRITE]        = "CGameSprite",
		[CGameObjectType.OBJECT_MARKER] = "CObjectMarker",
		[CGameObjectType.TRIGGER]       = "CGameTrigger",
		[CGameObjectType.TILED_OBJECT]  = "CGameTiledObject",
		[CGameObjectType.TEMPORAL]      = "CGameTemporal",
		[CGameObjectType.AREA_AI]       = "CGameAIArea",
		[CGameObjectType.FIREBALL]      = "CGameFireball3d",
		[CGameObjectType.GAME_AI]       = "CGameAIGame",
	})[object.m_objectType]

	return usertype and EEex_CastUD(object, usertype) or object
end
EEex_GameObject_CastUT = EEex_GameObject_CastUserType

function EEex_GameObject_Get(objectID)

	local object
	EEex_RunWithStack(EEex_PointerSize, function(mem)
		ptr = EEex_PtrToUD(mem, "Pointer<CGameObject>")
		CGameObjectArray.GetShare(objectID, ptr)
		object = ptr.reference
	end)

	return EEex_GameObject_CastUT(object)
end

function EEex_GameObject_GetSelectedID()
	local node = EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_group.m_memberList.m_pNodeHead
	if not node then return -1 end
	return node.data
end

function EEex_GameObject_GetSelected()
	return EEex_GameObject_Get(EEex_GameObject_GetSelectedID())
end

function EEex_GameObject_IterateSelectedIDs(func)
	local node = EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_group.m_memberList.m_pNodeHead
	while node do
		if func(node.data) then
			break
		end
		node = node.pNext
	end
end

function EEex_GameObject_IterateSelected(func)
	EEex_GameObject_IterateSelectedIDs(function(spriteID)
		if func(EEex_GameObject_Get(spriteID)) then
			return true
		end
	end)
end

function EEex_GameObject_GetAllSelectedIDs()
	local toReturn = {}
	EEex_GameObject_IterateSelectedIDs(function(spriteID)
		table.insert(toReturn, spriteID)
	end)
	return toReturn
end

function EEex_GameObject_GetUnderCursor()
	local game = EEex_EngineGlobal_CBaldurChitin.m_pObjectGame
	local curArea = game.m_gameAreas:get(game.m_visibleArea)
	return EEex_GameObject_Get(curArea.m_iPicked)
end

function EEex_GameObject_GetUnderCursorID()
	local game = EEex_EngineGlobal_CBaldurChitin.m_pObjectGame
	local curArea = game.m_gameAreas:get(game.m_visibleArea)
	return curArea.m_iPicked
end

-------------------------
-- Game Object Details --
-------------------------

function EEex_GameObject_IsSprite(object, allowDead)
	if object and object.m_objectType == CGameObjectType.SPRITE then
		return allowDead or EEex_BAnd(EEex_CastUD(object, "CGameSprite").m_baseStats.m_generalState, 0xFC0) == 0
	end
	return false
end
CGameObject.isSprite = EEex_GameObject_IsSprite

function EEex_GameObject_IsSpriteID(objectID, allowDead)
	return EEex_GameObject_IsSprite(EEex_GameObject_Get(objectID), allowDead)
end

function EEex_GameObject_GetClass(object)
	return object.m_typeAI.m_Class
end
CGameObject.getClass = EEex_GameObject_GetClass

------------------------------
-- Game Object Manipulation --
------------------------------

-- Directly applies an effect to a game object based on the args table.
function EEex_GameObject_ApplyEffect(object, args)

	if not object then
		return
	end

	local effect

	EEex_RunWithStackManager({
		{ ["name"] = "itemEffect", ["struct"] = "Item_effect_st" },
		{ ["name"] = "source",     ["struct"] = "CPoint"         },
		{ ["name"] = "target",     ["struct"] = "CPoint"         }, },
		function(manager)

			itemEffect = manager:getUD("itemEffect")
			EEex_WriteUDArgs(itemEffect, args, {
				{ "effectID",         EEex_WriteFailType.ERROR        },
				{ "targetType",       EEex_WriteFailType.DEFAULT, 1   },
				{ "spellLevel",       EEex_WriteFailType.DEFAULT, 0   },
				{ "effectAmount",     EEex_WriteFailType.DEFAULT, 0   },
				{ "dwFlags",          EEex_WriteFailType.DEFAULT, 0   },
				{ "durationType",     EEex_WriteFailType.DEFAULT, 0   },
				{ "duration",         EEex_WriteFailType.DEFAULT, 0   },
				{ "probabilityUpper", EEex_WriteFailType.DEFAULT, 100 },
				{ "probabilityLower", EEex_WriteFailType.DEFAULT, 0   },
				{ "res",              EEex_WriteFailType.DEFAULT, ""  },
				{ "numDice",          EEex_WriteFailType.DEFAULT, 0   },
				{ "diceSize",         EEex_WriteFailType.DEFAULT, 0   },
				{ "savingThrow",      EEex_WriteFailType.DEFAULT, 0   },
				{ "saveMod",          EEex_WriteFailType.DEFAULT, 0   },
				{ "special",          EEex_WriteFailType.DEFAULT, 0   },
			})

			local source = manager:getUD("source")
			source.x = args["sourceX"] or -1
			source.y = args["sourceY"] or -1

			local target = manager:getUD("target")
			target.x = args["targetX"] or -1
			target.y = args["targetY"] or -1

			effect = CGameEffect.DecodeEffect(itemEffect, source, args["sourceID"] or -1, target, args["sourceTarget"] or -1)
		end)

	EEex_WriteUDArgs(effect, args, {
		{ "m_school",          EEex_WriteFailType.NOTHING },
		{ "m_minLevel",        EEex_WriteFailType.NOTHING },
		{ "m_maxLevel",        EEex_WriteFailType.NOTHING },
		{ "m_flags",           EEex_WriteFailType.NOTHING },
		{ "m_effectAmount2",   EEex_WriteFailType.NOTHING },
		{ "m_effectAmount3",   EEex_WriteFailType.NOTHING },
		{ "m_effectAmount4",   EEex_WriteFailType.NOTHING },
		{ "m_effectAmount5",   EEex_WriteFailType.NOTHING },
		{ "m_res2",            EEex_WriteFailType.NOTHING },
		{ "m_res3",            EEex_WriteFailType.NOTHING },
		{ "m_sourceType",      EEex_WriteFailType.NOTHING },
		{ "m_sourceRes",       EEex_WriteFailType.NOTHING },
		{ "m_sourceFlags",     EEex_WriteFailType.NOTHING },
		{ "m_projectileType",  EEex_WriteFailType.NOTHING },
		{ "m_slotNum",         EEex_WriteFailType.NOTHING },
		{ "m_scriptName",      EEex_WriteFailType.NOTHING },
		{ "m_casterLevel",     EEex_WriteFailType.NOTHING },
		{ "m_secondaryType",   EEex_WriteFailType.NOTHING },
	})

	object:virtual_AddEffect(effect, args["effectList"] or 1, args["noSave"] or 0, args["immediateResolve"] or 1)
end
CGameObject.applyEffect = EEex_GameObject_ApplyEffect

-----------
-- Hooks --
-----------

function EEex_GameObject_Hook_OnDeleting(objectID)

	local object = EEex_GameObject_Get(objectID)
	if not object then
		return
	end

	EEex_DeleteUDAux(object)

	if EEex_UDEqual(object, EEex_LuaObject) then
		EEex_LuaObject = nil
	end
end
