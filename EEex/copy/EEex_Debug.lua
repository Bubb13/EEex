
EEex_Debug_DisableExtraCreatureMarshalling = false
EEex_Debug_LogActions = false

(function()

	if EEex_Debug_LogActions then

		local actionNames = {}

		EEex_GameState_AddInitializedListener(function()
			local actions = EEex_Resource_LoadIDS("ACTION")
			for i = 0, actions:getCount() - 1 do
				actionNames[i] = actions:getStart(i)
			end
			actions:free()
		end)

		EEex_Debug_LogAction = function(aiBase, bFromAIBase)

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

		EEex_DisableCodeProtection()

		EEex_HookBeforeConditionalJumpWithLabels(EEex_Label("Hook-CGameAIBase::ExecuteAction()-DefaultJmp"), 0, {
			{"integrity_ignore_registers", {
				EEex_IntegrityRegister.RAX, EEex_IntegrityRegister.RCX, EEex_IntegrityRegister.RDX,
				EEex_IntegrityRegister.R9, EEex_IntegrityRegister.R10, EEex_IntegrityRegister.R11
			}}},
			EEex_FlattenTable({
				{[[
					#MAKE_SHADOW_SPACE(56)
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], r8
				]]},
				EEex_GenLuaCall("EEex_Debug_LogAction", {
					["args"] = {
						function(rspOffset) return {[[
							mov qword ptr ss:[rsp+#$(1)], rbx
						]], {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
						function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], 1", {rspOffset}, "#ENDL"} end,
					},
				}),
				{[[
					call_error:
					mov r8, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
					#DESTROY_SHADOW_SPACE
				]]},
			})
		)

		EEex_HookBeforeConditionalJumpWithLabels(EEex_Label("Hook-CGameSprite::ExecuteAction()-DefaultJmp"), 0, {
			{"integrity_ignore_registers", {EEex_IntegrityRegister.RAX, EEex_IntegrityRegister.R11}}},
			EEex_FlattenTable({
				{[[
					#MAKE_SHADOW_SPACE(80)
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)], rcx
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)], rdx
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)], r9
					mov qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)], r10
				]]},
				EEex_GenLuaCall("EEex_Debug_LogAction", {
					["args"] = {
						function(rspOffset) return {[[
							mov qword ptr ss:[rsp+#$(1)], rdi
						]], {rspOffset}}, "CGameAIBase", "EEex_GameObject_CastUT" end,
						function(rspOffset) return {"mov qword ptr ss:[rsp+#$(1)], 0", {rspOffset}, "#ENDL"} end,
					},
				}),
				{[[
					call_error:
					mov r10, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-32)]
					mov r9, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-24)]
					mov rdx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-16)]
					mov rcx, qword ptr ss:[rsp+#SHADOW_SPACE_BOTTOM(-8)]
					#DESTROY_SHADOW_SPACE
					cmp ecx, 0x1D7
				]]},
			})
		)

		EEex_EnableCodeProtection()
	end

end)()
