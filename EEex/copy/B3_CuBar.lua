
B3CuBarAllowedConfigButtons = {
	[0] =  { 5, 27, 28, 24, 25, 26, 3,   14, 21, 22, 23, 10,    100                 },
	[1] =  { 5, 27, 28, 29, 30, 7,  100, 14, 21, 22, 23, 10,    24, 25, 26          },
	[2] =  { 5, 27, 28, 13, 24, 25, 3,   14, 21, 22, 23, 10,    26, 100             },
	[3] =  { 5, 27, 28, 4,  12, 11, 100, 14, 21, 22, 23, 10,    24, 25, 26          },
	[4] =  { 5, 27, 28, 2,  12, 24, 3,   14, 21, 22, 23, 10,    25, 26, 100         },
	[5] =  { 5, 27, 28, 29, 7,  13, 3,   14, 21, 22, 23, 10,    24, 25, 26, 100     },
	[6] =  { 5, 27, 28, 24, 25, 26, 3,   14, 21, 22, 23, 10,    100                 },
	[7] =  { 5, 27, 28, 13, 24, 25, 3,   14, 21, 22, 23, 10,    26, 100             },
	[8] =  { 5, 27, 28, 4,  12, 11, 100, 14, 21, 22, 23, 10,    24, 25, 26          },
	[9] =  { 5, 27, 28, 4,  12, 11, 3,   14, 21, 22, 23, 10,    24, 25, 26, 100     },
	[10] = { 5, 27, 28, 24, 25, 26, 3,   14, 21, 22, 23, 10,    100                 },
	[11] = { 5, 27, 28, 29, 7,  11, 3,   14, 21, 22, 23, 10,    24, 25, 26, 100     },
	[12] = { 5, 27, 28, 4,  12, 11, 3,   14, 21, 22, 23, 10,    24, 25, 26, 100     },
	[13] = { 5, 27, 28, 13, 24, 25, 3,   14, 21, 22, 23, 10,    26, 100             },
	[14] = { 5, 27, 28, 4,  13, 11, 3,   14, 21, 22, 23, 10,    24, 25, 26, 12, 100 },
	[15] = { 5, 27, 28, 24, 25, 26, 3,   14, 21, 22, 23, 10,    100                 },
	[16] = { 5, 27, 28, 13, 24, 25, 3,   14, 21, 22, 23, 10,    26, 100             },
	[17] = { 5, 27, 28, 13, 11, 24, 3,   14, 21, 22, 23, 10,    25, 26, 100         },
	[18] = { 5, 27, 28, 29, 7,  4,  11,  14, 21, 22, 23, 10,    24, 25, 26, 100     },
	[19] = { 5, 27, 28, 2,  4,  24, 3,   14, 21, 22, 23, 10,    25, 26, 100         },
}

function B3CuBarGetAllowedButtons(targetIndex)
	local defaultConfig = nil
	if B3CuBarCurrentConfig == 23 and (targetIndex == -1 or targetIndex == 0) and EEex_GetActorClass(EEex_GetActorIDSelected()) == 15 then
		-- A hack to allow Cleric-Thief Special Abilities thieving-slot hack to be hacked
		defaultConfig = { 5, 12 }
	else
		defaultConfig = B3CuBarAllowedConfigButtons[B3CuBarCurrentConfig]
	end
	return defaultConfig
end

function B3CuBarGetButtonTypeFrame(buttonType)
	if (buttonType >= 21 and buttonType <= 30) or buttonType == 100 then
		return 0
	elseif buttonType == 2 and EEex_GetActorClass(EEex_GetActorIDSelected()) == 21 then
		return 72
	else
		local knownButtonFrames = {
			[2] = 22,
			[3] = 12,
			[4] = 34,
			[5] = 4,
			[7] = 0,
			[10] = 38,
			[11] = 30,
			[12] = 26,
			[13] = 8,
			[14] = 18,
		}
		return knownButtonFrames[buttonType]
	end
end

B3CuBarOldToolbarTop = nil
B3CurBarOldGroundItemsButtonToggle = nil

-- Move the instances along with the top of the toolbar / out of the way of the quickitem area
function B3CuBarTick()

	local doUpdate = false

	if groundItemsButtonToggle ~= B3CurBarOldGroundItemsButtonToggle then
		B3CurBarOldGroundItemsButtonToggle = groundItemsButtonToggle
		doUpdate = true
	end

	if toolbarTop ~= B3CuBarOldToolbarTop then
		B3CuBarOldToolbarTop = toolbarTop
		doUpdate = true
	end

	if doUpdate then
		for templateName, entry in pairs(B3CuBarInstanceIDs) do
			for i = 1, entry.maxID, 1 do
				local newY = nil
				if groundItemsButtonToggle == 0 then
					newY = -toolbarTop
				else
					newY = -toolbarTop - 63
				end
				EEex_StoreTemplateInstance("WORLD_ACTIONBAR", templateName, i, "B3CuBarStoredTemplate")
				Infinity_SetArea('B3CuBarStoredTemplate', nil, newY, nil, nil)
			end
		end
	end
end

function B3CuBarGetInstanceBam(template, instance)
	local buttonType = B3CuBarInstanceIDs[template].instanceData[instance].buttonType
	if (buttonType >= 21 and buttonType <= 30) or buttonType == 100 then
		return "STONSLOT"
	else
		return "GUIBTACT"
	end
end

function B3CuBarGetInstanceFrame(template, instance)
	local buttonType = B3CuBarInstanceIDs[template].instanceData[instance].buttonType
	return B3CuBarGetButtonTypeFrame(buttonType)
end

function B3CuBarGetInstanceIcon(template, instance)
	local buttonType = B3CuBarInstanceIDs[template].instanceData[instance].buttonType
	if buttonType >= 21 and buttonType <= 23 then
		return "STONITEM"
	elseif buttonType >= 24 and buttonType <= 26 then
		return "STONSPEL"
	elseif buttonType >= 27 and buttonType <= 30 then
		return "STONWEAP"
	else
		return ""
	end
end

function B3CuBarGetInstanceCount(template, instance)
	local buttonType = B3CuBarInstanceIDs[template].instanceData[instance].buttonType
	if buttonType >= 21 and buttonType <= 23 then
		return buttonType - 21 + 1
	elseif buttonType >= 24 and buttonType <= 26 then
		return buttonType - 24 + 1
	elseif buttonType >= 27 and buttonType <= 30 then
		return buttonType - 27 + 1
	else
		return 0
	end
end

function B3CuBarInstanceAction(template, instance)

	local actorID = EEex_GetActorIDSelected()
	local buttonType = B3CuBarInstanceIDs[template].instanceData[instance].buttonType

	-- A hack to allow Cleric-Thief Special Abilities thieving-slot hack to be hacked
	local targetResource = nil
	local configTarget = nil
	if B3CuBarCurrentConfig == 23 then
		targetResource = "B3CuBa12"
		configTarget = 23
	else
		targetResource = "B3CuBa"..B3CuBarTargetIndex
		configTarget = -1
	end

	-- Remove any of my effects that modify this slot
	EEex_ApplyEffectToActor(actorID, {
		["source_target"] = actorID,
		["source_id"] = actorID,
		["opcode"] = 321,
		["resource"] = targetResource
	})

	-- Add my effect that modifies this slot
	EEex_ApplyEffectToActor(actorID, {
		["source_target"] = actorID,
		["source_id"] = actorID,
		["opcode"] = 405,
		["parameter1"] = B3CuBarTargetIndex,
		["parameter2"] = buttonType,
		["timing"] = 9,
		["special"] = configTarget,
		["parent_resource"] = targetResource
	})

	EEex_UpdateActionbar()

end

B3CuBarTargetIndex = nil

function B3CuBarPresent(targetIndex)

	local defaultConfig = B3CuBarGetAllowedButtons(targetIndex)
	if not defaultConfig then return end

	B3CuBarDestroyInstances()

	local currentOffset = -78
	local widthAllotted = 901
	local slotWidth = 52

	local targetCount = #defaultConfig
	local maxPossible = math.floor(widthAllotted / slotWidth)

	local freeSpace = widthAllotted - slotWidth * targetCount
	local spaceInbetween = math.floor(freeSpace / targetCount)

	if targetCount > maxPossible then
		EEex_MessageBox("[B3_CuBar.lua] ERROR: Too many choices to display!")
		return
	end

	B3CuBarTargetIndex = targetIndex

	B3CuBarOldToolbarTop = toolbarTop
	B3CurBarOldGroundItemsButtonToggle = groundItemsButtonToggle
	B3CuBarCreateInstance("TEMPLATE_B3_Actionbar_Tick", 0, 0, 0, 0)

	for _, buttonType in ipairs(defaultConfig) do
		if B3CuBarGetButtonTypeFrame(buttonType) then
			B3CuBarCreateChoiceInstance(buttonType, currentOffset)
			currentOffset = currentOffset + slotWidth + spaceInbetween
		end
	end

end

function B3CuBarPickerTick()
	if not Infinity_IsMenuOnStack("WORLD_ACTIONBAR") then
		Infinity_PopMenu("B3_CuBarPicker")
	end
end

function B3CuBarKeyPressedListener(key)
	if key == 0x400000E1 then
		if B3CuBarGetAllowedButtons(-1) and Infinity_IsMenuOnStack("WORLD_ACTIONBAR") and not Infinity_IsMenuOnStack("B3_CuBarPicker") then
			Infinity_PushMenu("B3_CuBarPicker")
		end
	end
end

function B3CuBarKeyReleasedListener(key)
	if key == 0x400000E1 then
		if Infinity_IsMenuOnStack("B3_CuBarPicker") then
			Infinity_PopMenu("B3_CuBarPicker")
			B3CuBarDestroyInstances()
		end
	end
end

B3CuBarCurrentConfig = nil

function B3CuBarActionbarListener(config)
	B3CuBarDestroyInstances()
	B3CuBarCurrentConfig = config
end

function B3CuBarResetListener()
	EEex_LoadMenuFile("B3_CuBar")
	EEex_AddActionbarListener(B3CuBarActionbarListener)
	EEex_AddKeyPressedListener(B3CuBarKeyPressedListener)
	EEex_AddKeyReleasedListener(B3CuBarKeyReleasedListener)
end
B3CuBarResetListener()
EEex_AddPostResetListener(B3CuBarResetListener)

B3CuBarInstanceIDs = {}

function B3CuBarCreateInstance(templateName, x, y, w, h)
	local entry = B3CuBarInstanceIDs[templateName]
	if not entry then
		entry = {["maxID"] = 0, ["instanceData"] = {}}
		B3CuBarInstanceIDs[templateName] = entry
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

function B3CuBarCreateChoiceInstance(buttonType, xCoord)
	local yCoord = nil
	if groundItemsButtonToggle == 0 then
		yCoord = -toolbarTop
	else
		yCoord = -toolbarTop - 63
	end
	local instanceEntry = B3CuBarCreateInstance("TEMPLATE_B3_Actionbar_Choice", xCoord, yCoord, 52, 52)
	instanceEntry.buttonType = buttonType
end

function B3CuBarDestroyInstances()
	for templateName, entry in pairs(B3CuBarInstanceIDs) do
		for i = 1, entry.maxID, 1 do
			EEex_DestroyInjectedTemplate("WORLD_ACTIONBAR", templateName, i)
		end
		entry.maxID = 0
		entry.instanceData = {}
	end
end
