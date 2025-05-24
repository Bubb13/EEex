
---------------------------
-- Fetching Game Objects --
---------------------------

-- @bubb_doc { EEex_GameObject_CastUserType / alias=EEex_GameObject_CastUT }
-- @summary:
--
--     Takes the given ``object`` and returns a cast userdata that represents ``object``'s true type.
--
--     Most EEex functions will call this function before passing an object to the modder API.
--
-- @param { object / type=CGameObject }: The object to cast.
--
-- @return {
--
--     usertype =
--     @|
--         CGameAIArea   | CGameAIBase | CGameAIGame | CGameContainer | CGameDoor        | CGameFireball3d | CGameSound    | @EOL
--         CGameSpawning | CGameSprite | CGameStatic | CGameTemporal  | CGameTiledObject | CGameTrigger    | CObjectMarker | nil
--     @|
--
-- }: See summary.

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

-- @bubb_doc { EEex_GameObject_Get }
--
-- @summary: Returns the object associated with ``objectID``, or ``nil`` if ``objectID`` is invalid.
--
-- @param { objectID / type=number }: The id of the object to fetch.
--
-- @return {
--
--     usertype =
--     @|
--         CGameAIArea   | CGameAIBase | CGameAIGame | CGameContainer | CGameDoor        | CGameFireball3d | CGameSound    | @EOL
--         CGameSpawning | CGameSprite | CGameStatic | CGameTemporal  | CGameTiledObject | CGameTrigger    | CObjectMarker | nil
--     @|
--
-- }: See summary.

function EEex_GameObject_Get(objectID)

	local object
	EEex_RunWithStack(EEex_PointerSize, function(mem)
		ptr = EEex_PtrToUD(mem, "Pointer<CGameObject>")
		CGameObjectArray.GetShare(objectID, ptr)
		object = ptr.reference
	end)

	return EEex_GameObject_CastUT(object)
end

-- @bubb_doc { EEex_GameObject_GetUnderCursor }
-- @summary: Returns the interactable object currently under the cursor, or ``nil`` if none exists.
-- @return { usertype=CGameContainer | CGameDoor | CGameSprite | CGameTrigger | nil }: See summary.

function EEex_GameObject_GetUnderCursor()
	local game = EEex_EngineGlobal_CBaldurChitin.m_pObjectGame
	local curArea = game.m_gameAreas:get(game.m_visibleArea)
	return EEex_GameObject_Get(curArea.m_iPicked)
end

-- @bubb_doc { EEex_GameObject_GetUnderCursorID }
-- @summary: Returns the id of the interactable object currently under the cursor, or ``-1`` if none exists.
-- @return { type=number }: See summary.

function EEex_GameObject_GetUnderCursorID()
	local game = EEex_EngineGlobal_CBaldurChitin.m_pObjectGame
	local curArea = game.m_gameAreas:get(game.m_visibleArea)
	return curArea.m_iPicked
end

-------------------------
-- Game Object Details --
-------------------------

-- @bubb_doc { EEex_GameObject_IsSprite / instance_name=isSprite }
--
-- @summary: Returns whether the given ``object`` is a sprite.
--
-- @self { object / usertype=CGameObject }: The object to check.
--
-- @param { allowDead / type=boolean / default=false }: Determines whether ``object`` is allowed to be dead.
--
-- @return { type=boolean }: See summary.

function EEex_GameObject_IsSprite(object, allowDead)
	if object and object.m_objectType == CGameObjectType.SPRITE then
		return allowDead or EEex_BAnd(EEex_CastUD(object, "CGameSprite").m_baseStats.m_generalState, 0xFC0) == 0
	end
	return false
end
CGameObject.isSprite = EEex_GameObject_IsSprite

-- @bubb_doc { EEex_GameObject_IsSpriteID }
--
-- @summary: Returns whether the given ``objectID`` is associated with a sprite.
--
-- @param { objectID / type=number }: The object id to check.
--
-- @param { allowDead / type=boolean / default=false }: Determines whether the sprite associated with ``objectID`` is allowed to be dead.
--
-- @return { type=boolean }: See summary.

function EEex_GameObject_IsSpriteID(objectID, allowDead)
	return EEex_GameObject_IsSprite(EEex_GameObject_Get(objectID), allowDead)
end

-- @bubb_doc { EEex_GameObject_GetClass / instance_name=getClass }
--
-- @summary: Returns the given ``object``'s class.
--
-- @self { object / usertype=CGameObject }: The object whose class is being fetched.
--
-- @return { type=number }: See summary.

function EEex_GameObject_GetClass(object)
	return object.m_typeAI.m_Class
end
CGameObject.getClass = EEex_GameObject_GetClass

------------------------------
-- Game Object Manipulation --
------------------------------

-- @bubb_doc { EEex_GameObject_ApplyEffect / instance_name=applyEffect }
--
-- @summary: Applies an effect to the given ``object`` based on the ``args`` table.
--
-- @self { object / type=CGameObject }: The object to apply the effect to.
--
-- @param { args / type=table }: The table that describes the effect to apply.
--
-- @extra_comment:
--
--  Valid keys for the ``args`` table are as follows:
--
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | **Name**         | **Default Value** | **Description**                                                                                |
--  +==================+===================+================================================================================================+
--  | diceSize         | ``0``             | As per offset [+0x3C] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | duration         | ``0``             | As per offset [+0x28] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | durationType     | ``0``             | As per offset [+0x24] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | dwFlags          | ``0``             | As per offset [+0x20] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | effectAmount     | ``0``             | As per offset [+0x1C] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | effectID         | ``<ERROR>``       | As per offset [+0x10] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | effectList       | ``1``             | If 1, adds the effect to the sprite's timed list. :raw-html:`<br/>`                            |
--  |                  |                   | If 2, adds the effect to the sprite's equipped list.                                           |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | immediateResolve | ``1``             | Determines whether the engine immediately applies the effect during the :raw-html:`<br/>`      |
--  |                  |                   | function call, or the next time the sprite's effect list is processed.                         |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_casterLevel    | ``0``             | As per offset [+0xC8] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_effectAmount2  | ``0``             | As per offset [+0x60] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_effectAmount3  | ``0``             | As per offset [+0x64] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_effectAmount4  | ``0``             | As per offset [+0x68] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_effectAmount5  | ``0``             | As per offset [+0x6C] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_flags          | ``0``             | As per offset [+0x5C] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_maxLevel       | ``0``             | As per offset [+0x58] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_minLevel       | ``0``             | As per offset [+0x54] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_projectileType | ``0``             | As per offset [+0xA0] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_res2           | ``""``            | As per offset [+0x70] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_res3           | ``""``            | As per offset [+0x78] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_school         | ``0``             | As per offset [+0x4C] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_scriptName     | ``""``            | As per offset [+0xA8] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_secondaryType  | ``0``             | As per offset [+0xD0] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_slotNum        | ``0``             | As per offset [+0xA4] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_sourceFlags    | ``0``             | As per offset [+0x9C] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_sourceRes      | ``""``            | As per offset [+0x94] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | m_sourceType     | ``0``             | As per offset [+0x90] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | noSave           | ``0``             | If true, the effect bypasses any immunities the sprite might have to its application.          |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | numDice          | ``0``             | As per offset [+0x38] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | probabilityLower | ``0``             | As per offset [+0x2E] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | probabilityUpper | ``100``           | As per offset [+0x2C] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | res              | ``""``            | As per offset [+0x30] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | saveMod          | ``0``             | As per offset [+0x44] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | savingThrow      | ``0``             | As per offset [+0x40] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | sourceID         | ``-1``            | The object id of the effect's source, as per ``CGameEffect.m_sourceId``.                       |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | sourceTarget     | ``-1``            | The object id of the source's target, as per ``CGameEffect.m_sourceTarget``; :raw-html:`<br/>` |
--  |                  |                   | you might need to set this if the opcode applies additional effects.                           |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | sourceX          | ``-1``            | As per offset [+0x80] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | sourceY          | ``-1``            | As per offset [+0x84] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | special          | ``0``             | As per offset [+0x48] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | spellLevel       | ``0``             | As per offset [+0x18] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | targetType       | ``1``             | As per offset [+0x14] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | targetX          | ``-1``            | As per offset [+0x88] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+
--  | targetY          | ``-1``            | As per offset [+0x8C] of .EFF v2.0.                                                            |
--  +------------------+-------------------+------------------------------------------------------------------------------------------------+

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

function EEex_Object_AddToArea(object, area, x, y, z, listType)
	EEex_RunWithStackManager({
		{ ["name"] = "point", ["struct"] = "CPoint", ["constructor"] = {["variant"] = "fromXY", ["args"] = {x, y}} }, },
		function(manager)
			object:virtual_AddToArea(area, manager:getUD("point"), z or 0, listType or 0)
		end)
end
CGameObject.addToArea = EEex_Object_AddToArea

function EEex_GameObject_AttachVisualEffect(object, resref, optionalArgs)

	if optionalArgs == nil then optionalArgs = {} end
	local targetX      = optionalArgs["targetX"]      or object.m_pos.x
	local targetY      = optionalArgs["targetY"]      or object.m_pos.y
	local startX       = optionalArgs["startX"]       or targetX
	local startY       = optionalArgs["startY"]       or targetY
	local height       = optionalArgs["height"]       or 32
	local linkToObject = optionalArgs["linkToObject"] or true
	local speed        = optionalArgs["speed"]        or -1

	local objectId = EEex_RunWithStackManager({
		{ ["name"] = "name",        ["struct"] = "CString", ["constructor"] = {                        ["args"] = {resref}          }, ["noDestruct"] = true },
		{ ["name"] = "startPoint",  ["struct"] = "CPoint",  ["constructor"] = {["variant"] = "fromXY", ["args"] = {startX, startY}  }                        },
		{ ["name"] = "targetPoint", ["struct"] = "CPoint",  ["constructor"] = {["variant"] = "fromXY", ["args"] = {targetX, targetY}}                        }, },
		function(manager)
			return CVisualEffect.Load(manager:getUD("name"), object.m_pArea, manager:getUD("startPoint"),
				object.m_id, manager:getUD("targetPoint"), height, linkToObject, speed)
		end)

	return EEex_GameObject_Get(objectId)
end
CGameObject.attachVisualEffect = EEex_GameObject_AttachVisualEffect

-----------
-- Hooks --
-----------

function EEex_GameObject_Hook_OnDeleting(objectID)

	local object = EEex_GameObject_Get(objectID)
	if not object then
		return
	end

	if object:isSprite(true) then
		local sourceUUID = object:getUUID()
		local callbacksMap = EEex_Sprite_Private_LoadedWithUUIDCallbacksBySource[sourceUUID]
		if callbacksMap then
			for callbacks, _ in pairs(callbacksMap) do
				callbacks[sourceUUID] = nil
			end
			EEex_Sprite_Private_LoadedWithUUIDCallbacksBySource[sourceUUID] = nil
		end
	end

	EEex_DeleteUDAux(object)

	if EEex_UDEqual(object, EEex_LuaObject) then
		EEex_LuaObject = nil
	end
end
