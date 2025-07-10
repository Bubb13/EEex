
--===========
-- Options ==
--===========

EEex_Debug_DisableExtraCreatureMarshalling = false
EEex_Debug_LogActions = false

--===========
-- General ==
--===========

------------
-- Public --
------------

function EEex_Debug_DumpScriptEncoding(resref, bPlayerScript)
	local script = EEex_Resource_LoadScript(resref, bPlayerScript)
	local dumpAiType = function(name, aiType, indent)
		indent = indent or ""
		print(string.format("%s%s:", indent, name))
		print(string.format("%s  m_name: \"%s\"", indent, aiType.m_name.m_pchData:get()))
		print(string.format("%s  m_EnemyAlly: %d", indent, aiType.m_EnemyAlly))
		print(string.format("%s  m_General: %d", indent, aiType.m_General))
		print(string.format("%s  m_Race: %d", indent, aiType.m_Race))
		print(string.format("%s  m_Class: %d", indent, aiType.m_Class))
		print(string.format("%s  m_Instance: 0x%X", indent, aiType.m_Instance))
		for i = 0, aiType.m_SpecialCase.lastIndex do
			print(string.format("%s  m_SpecialCase[%d]: %d", indent, i, aiType.m_SpecialCase:get(i)))
		end
		print(string.format("%s  m_Specifics: %d", indent, aiType.m_Specifics))
		print(string.format("%s  m_Gender: %d", indent, aiType.m_Gender))
		print(string.format("%s  m_Alignment: %d", indent, aiType.m_Alignment))
	end
	EEex_Utility_IterateCPtrList(script.m_caList, function(conditionResponse)
		print("------------------------------------------")
		print("triggers:")
		print("------------------------------------------")
		EEex_Utility_IterateCPtrList(conditionResponse.m_condition.m_triggerList, function(trigger)
			print(string.format("  m_triggerID: 0x%X", trigger.m_triggerID))
			print(string.format("  m_specificID: %d", trigger.m_specificID))
			dumpAiType("m_triggerCause", trigger.m_triggerCause, "  ")
			print(string.format("  m_flags: 0x%X", trigger.m_flags))
			print(string.format("  m_specific2: %d", trigger.m_specific2))
			print(string.format("  m_specific3: %d", trigger.m_specific3))
			print(string.format("  m_string1: \"%s\"", trigger.m_string1.m_pchData:get()))
			print(string.format("  m_string2: \"%s\"", trigger.m_string2.m_pchData:get()))
			print("------------------------------------------")
		end)
		print("actions:")
		print("------------------------------------------")
		EEex_Utility_IterateCPtrList(conditionResponse.m_responseSet.m_responseList, function(response)
			EEex_Utility_IterateCPtrList(response.m_actionList, function(action)
				print(string.format("  m_actionID: %d", action.m_actionID))
				dumpAiType("m_actorID", action.m_actorID, "  ")
				dumpAiType("m_acteeID", action.m_acteeID, "  ")
				dumpAiType("m_acteeID2", action.m_acteeID2, "  ")
				print(string.format("  m_specificID: %d", action.m_specificID))
				print(string.format("  m_specificID2: %d", action.m_specificID2))
				print(string.format("  m_specificID3: %d", action.m_specificID3))
				print(string.format("  m_string1: \"%s\"", action.m_string1.m_pchData:get()))
				print(string.format("  m_string2: \"%s\"", action.m_string2.m_pchData:get()))
				print(string.format("  m_dest.x: %d", action.m_dest.x))
				print(string.format("  m_dest.y: %d", action.m_dest.y))
				print(string.format("  m_internalFlags: 0x%X", action.m_internalFlags))
				print(string.format("  m_source: \"%s\"", action.m_source.m_pchData:get()))
				print("------------------------------------------")
			end)
		end)
	end)
end

-------------
-- Private --
-------------

function EEex_Debug_Private_DumpSprite()

	local object = EEex_GameObject_GetUnderCursor()
	if not EEex_GameObject_IsSprite(object) then return end

	local str = string.format("[EEex] address:[%s], id:[%s], name:[%s]",
		EEex_ToHex(EEex_UDToPtr(object)), EEex_ToHex(object.m_id), object.m_sName.m_pchData:get())

	print(str)
	Infinity_DisplayString(str)
end

--===============
-- Conditional ==
--===============

(function()

	if EEex_Debug_LogActions then

		local actionNames = {}

		EEex_GameState_AddInitializedListener(function()
			local actions = EEex_Resource_LoadIDS("ACTION", true)
			for i = 0, actions:getCount() - 1 do
				actionNames[i] = actions:getStart(i)
			end
			actions:free()
		end)

		EEex_Debug_Hook_LogAction = function(aiBase, bFromAIBase)

			local objectType = aiBase.m_objectType

			-- Don't double log certain actions
			if bFromAIBase == 1 and objectType == CGameObjectType.SPRITE then
				return
			end

			local objectName = "Unknown"

			if objectType == CGameObjectType.SPRITE then
				objectName = aiBase.m_sName.m_pchData:get().." ("..aiBase.m_resref:get()..")"
			elseif objectType == CGameObjectType.AREA_AI then
				objectName = "Area script ("..aiBase.m_pArea.m_resref:get()..")"
			elseif objectType == CGameObjectType.GAME_AI then
				objectName = "Game script (unknown)"
			elseif objectType == CGameObjectType.DOOR then
				objectName = "Door (unknown)"
			elseif objectType == CGameObjectType.CONTAINER then
				objectName = "Container (unknown)"
			elseif objectType == CGameObjectType.TRIGGER then
				objectName = "Trigger (unknown)"
			end

			local actionID = aiBase.m_curAction.m_actionID
			if actionID ~= 0 then
				local curScriptNum = aiBase.m_curScriptNum
				print(string.format("%s executing action %d (%s), script level %d (%s), block %d, response %d",
					objectName, actionID, actionNames[actionID] or "unknown", curScriptNum,
					aiBase:getScriptLevelResRef(aiBase, curScriptNum >= 3 and curScriptNum + 1 or curScriptNum),
					aiBase.m_curResponseSetNum, aiBase.m_curResponseNum))
			end
		end
	end
end)()

--=============
-- Listeners ==
--=============

EEex_Key_AddPressedListener(function(key)
	if worldScreen == e:GetActiveEngine() then
		if key == EEex_Key_GetFromName("`") and EEex_Key_IsDown(EEex_Key_GetFromName("Left Alt")) then
			EEex_Debug_Private_DumpSprite()
		end
	end
end)
