
function B3TimerAttachListener(config)
	B3ResetProgress()
	local actorID = EEex_GetActorIDSelected()
	if actorID ~= 0x0 then
		for i = 0, 11, 1 do
			local template = B3GetButtonTemplate(i)
			if template ~= nil then
				B3CreateButtonProgressInstance(template, i)
			end
		end
		B3CreateProgressInstance("TEMPLATE_B3_Spell_Progress", 19, 10, 36, 36)
	end
end

EEex_AddPostResetListener(function()
	EEex_LoadMenuFile("B3_Timer")
	EEex_AddActionbarListener(B3TimerAttachListener)
end)

EEex_LoadMenuFile("B3_Timer")
EEex_AddActionbarListener(B3TimerAttachListener)

function B3GetButtonTemplate(i)
	local definitions = {
		[2] = "TEMPLATE_B3_Song_Progress",
		[3] = "TEMPLATE_B3_Cast_Progress",
		[4] = "TEMPLATE_B3_Trap_Progress",
		[13] = "TEMPLATE_B3_Turn_Progress",
	}
	return definitions[EEex_GetActionbarButton(i)]
end

function B3GetProgressEnabled(template, instance)
	local definitions = {
		[2]  = { ["default"] = false, [24] = true, [74] = true },
		[3]  = { ["default"] = true                            },
		[4]  = { ["default"] = false, [36] = true              },
		[13] = { ["default"] = false, [10] = true              },
	}
	local button = B3ProgressIDs[template].instanceData[instance].originatingButton
	local buttonDef = definitions[EEex_GetActionbarButton(button)]
	local specific = buttonDef[buttonArray:GetButtonSequence(button)]
	if specific then
		return specific
	else
		return buttonDef.default
	end
end

function B3GetProgressBAM(template, instance)
	local definitions = {
		[2]  = { ["default"] = nil,    [24] = "BARD",  [74] = "SHAMAN" },
		[3]  = { ["default"] = "CAST", [53] = "CAST2",                 },
		[4]  = { ["default"] = nil,    [36] = "TRAP",                  },
		[13] = { ["default"] = nil,    [10] = "TURN",                  },
	}
	local button = B3ProgressIDs[template].instanceData[instance].originatingButton
	local buttonDef = definitions[EEex_GetActionbarButton(button)]
	local specific = buttonDef[buttonArray:GetButtonSequence(button)]
	if specific then
		return specific
	else
		return buttonDef.default
	end
end

function B3GetProgressFrame(template, instance)
	local definitions = {
		[2]  = { ["func"] = B3GetModalPercent, ["default"] = 44, [74] = 44 },
		[3]  = { ["func"] = B3GetCastPercent,  ["default"] = 48, [53] = 44 },
		[4]  = { ["func"] = B3GetModalPercent, ["default"] = 44, [36] = 44 },
		[13] = { ["func"] = B3GetModalPercent, ["default"] = 44, [10] = 44 },
	}
	local button = B3ProgressIDs[template].instanceData[instance].originatingButton
	local buttonDef = definitions[EEex_GetActionbarButton(button)]
	local frameCount = buttonDef[buttonArray:GetButtonSequence(button)]
	if not frameCount then
		frameCount = buttonDef.default
	end
	return frameCount * (buttonDef.func() / 100)
end

function B3ContinFrame()
	local percent = B3GetContinPercent()
	return 135 * (percent / 100)
end

function B3GetModalPercent()
	local id = EEex_GetActorIDSelected()
	if id ~= 0x0  then
		local timeLeft = EEex_GetActorModalTimer(id)
		return 100 - timeLeft
	else
		return 0
	end
end

function B3GetCastPercent()
	local id = EEex_GetActorIDSelected()
	if id ~= 0x0  then
		local timeLeft = EEex_GetActorCastTimer(id)
		return 100 - timeLeft
	else
		return 0
	end
end

function B3GetContinPercent()
	local id = EEex_GetActorIDSelected()
	if id ~= 0x0  then
		local timeLeft = EEex_GetActorSpellTimer(id)
		return 100 - timeLeft
	else
		return 0
	end
end

B3ProgressIDs = {}

function B3CreateProgressInstance(templateName, x, y, w, h)
	local entry = B3ProgressIDs[templateName]
	if not entry then
		entry = {["maxID"] = 0, ["instanceData"] = {}}
		B3ProgressIDs[templateName] = entry
	end
	local newID = entry.maxID + 1
	entry.maxID = newID
	local instanceEntry = {}
	entry.instanceData[newID] = instanceEntry
	local oldAnimationID = currentAnimationID
	currentAnimationID = newID
	EEex_InjectTemplate("WORLD_ACTIONBAR", templateName, x, y, w, h)
	currentAnimationID = oldAnimationID
	return instanceEntry
end

function B3CreateButtonProgressInstance(templateName, buttonIndex)
	local actionbarPositions = {
		[0] = 68, 122, 177, 231, 299, 353,
		407, 461, 528, 582, 636, 689,
	}
	local xCoord = actionbarPositions[buttonIndex]
	local instanceEntry = B3CreateProgressInstance(templateName, xCoord, 1, 52, 52)
	instanceEntry.originatingButton = buttonIndex
end

function B3ResetProgress()
	for templateName, entry in pairs(B3ProgressIDs) do
		for i = 1, entry.maxID, 1 do
			EEex_DestroyInjectedTemplate("WORLD_ACTIONBAR", templateName, i)
		end
		entry.maxID = 0
		entry.instanceData = {}
	end
end
