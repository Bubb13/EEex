
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

function EEex_GameObject_GetUnderCursor()
	local game = EngineGlobals.g_pBaldurChitin.m_pObjectGame
	local curArea = game.m_gameAreas:get(game.m_visibleArea)
	return EEex_GameObject_Get(curArea.m_iPicked)
end

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
