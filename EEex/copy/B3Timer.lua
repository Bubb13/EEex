
-----------------------
-- Template Handling --
-----------------------

B3Timer_TemplateInstances = {}

function B3Timer_CreateInstance(menuName, templateName, x, y, w, h)

	local menuEntry = B3Timer_TemplateInstances[menuName]
	if not menuEntry then
		menuEntry = {}
		B3Timer_TemplateInstances[menuName] = menuEntry
	end

	local entry = menuEntry[templateName]
	if not entry then
		entry = {["maxID"] = 0, ["instanceData"] = {}}
		menuEntry[templateName] = entry
	end

	local newID = entry.maxID + 1
	entry.maxID = newID

	local instanceEntry = {["id"] = newID}
	entry.instanceData[newID] = instanceEntry

	local oldAnimationID = currentAnimationID
	currentAnimationID = newID
	EEex_Menu_InjectTemplate(menuName, templateName, x, y, w, h)
	currentAnimationID = oldAnimationID

	return instanceEntry
end

B3Timer_TemplateInstancesByPortrait = {}

function B3Timer_CreateInstanceForPortrait(menuName, templateName, x, y, w, h, portraitIndex)
	local instanceEntry = B3Timer_CreateInstance(menuName, templateName, x, y, w, h)
	instanceEntry.portraitIndex = portraitIndex
	instanceEntry.enabled = false
	local portraitEntry = B3Timer_TemplateInstancesByPortrait[portraitIndex]
	if not portraitEntry then
		portraitEntry = {}
		B3Timer_TemplateInstancesByPortrait[portraitIndex] = portraitEntry
	end
	portraitEntry[templateName] = instanceEntry
end

---------------
-- Listeners -- 
---------------

B3Timer_InjectingMenu = "RIGHT_SIDEBAR"

function B3Timer_InstallBars()

	EEex_Menu_LoadFile("B3Timer")

	local sidebar = EEex_Menu_Find(B3Timer_InjectingMenu)
	local item = sidebar.items

	while item do
		local portrait = item.button.portrait
		if portrait then
			local area = item.area
			local portraitIndex = EEex_Menu_GetItemVariant(portrait)
			B3Timer_CreateInstanceForPortrait(B3Timer_InjectingMenu, "B3Timer_Menu_TEMPLATE_Background",       0, area.y - 1, 10, 92, portraitIndex)
			B3Timer_CreateInstanceForPortrait(B3Timer_InjectingMenu, "B3Timer_Menu_TEMPLATE_TimerModal",       0, area.y,     2,  90, portraitIndex)
			B3Timer_CreateInstanceForPortrait(B3Timer_InjectingMenu, "B3Timer_Menu_TEMPLATE_TimerContingency", 0, area.y,     2,  90, portraitIndex)
			B3Timer_CreateInstanceForPortrait(B3Timer_InjectingMenu, "B3Timer_Menu_TEMPLATE_TimerCast",        0, area.y,     2,  90, portraitIndex)
		end
		item = item.next
	end
end

function B3Timer_PushMenuListener()
	Infinity_PushMenu("B3Timer_Menu")
end

function B3Timer_InitListeners()
	EEex_Menu_AddMainFileLoadedListener(B3Timer_InstallBars)
	EEex_Menu_AddLuaBindingsInitializedListener(B3Timer_PushMenuListener)
	EEex_Menu_AddAfterMainFileReloadedListener(B3Timer_PushMenuListener)
	EEex_Menu_AddBeforeMainFileReloadedListener(B3Timer_InitListeners)
end
B3Timer_InitListeners()

--------------------
-- Menu Functions --
--------------------

B3Timer_NextUpdateTick = -1

function B3Timer_Menu_Tick()

	-- Game lags when this function is spammed, limit to 30tps.
	local curTick = Infinity_GetClockTicks()
	if curTick < B3Timer_NextUpdateTick then
		return
	end
	B3Timer_NextUpdateTick = curTick + 33

	for portraitIndex = 0, 5, 1 do

		local portraitEntry = B3Timer_TemplateInstancesByPortrait[portraitIndex]
		local sprite = EEex_Sprite_GetInPortrait(portraitIndex)

		if sprite then

			local startX = -2
			local curX = startX

			local updateTimerBar = function(portraitEntry, templateName, condition, changeX)
				local templateEntry = portraitEntry[templateName]
				if condition then
					templateEntry.enabled = true
					curX = curX - (curX == startX and 1 or 3)
					EEex_Menu_SetTemplateArea(B3Timer_InjectingMenu, templateName, templateEntry.id, curX, nil, nil, nil)
				else
					templateEntry.enabled = false
				end
			end

			updateTimerBar( portraitEntry, "B3Timer_Menu_TEMPLATE_TimerCast",        sprite:getCastTimerPercentage() > 0                     )
			updateTimerBar( portraitEntry, "B3Timer_Menu_TEMPLATE_TimerContingency", sprite:getActiveStats().m_cContingencyList.m_nCount > 0 )
			updateTimerBar( portraitEntry, "B3Timer_Menu_TEMPLATE_TimerModal",       sprite:getModalState() ~= 0                             )

			local backgroundEntry = portraitEntry["B3Timer_Menu_TEMPLATE_Background"]
			if curX ~= startX then
				backgroundEntry.enabled = true
				EEex_Menu_SetTemplateArea(B3Timer_InjectingMenu, "B3Timer_Menu_TEMPLATE_Background", backgroundEntry.id, curX - 1, nil, startX - curX + 3, nil)
			else
				backgroundEntry.enabled = false
			end
		else
			portraitEntry["B3Timer_Menu_TEMPLATE_Background"].enabled = false
			portraitEntry["B3Timer_Menu_TEMPLATE_TimerModal"].enabled = false
			portraitEntry["B3Timer_Menu_TEMPLATE_TimerContingency"].enabled = false
			portraitEntry["B3Timer_Menu_TEMPLATE_TimerCast"].enabled = false
		end
	end
end

function B3Timer_Menu_TEMPLATE_Background_Enabled()
	return B3Timer_TemplateInstances[B3Timer_InjectingMenu]["B3Timer_Menu_TEMPLATE_Background"].instanceData[instanceId].enabled
end

function B3Timer_Menu_TEMPLATE_TimerModal_Enabled()
	return B3Timer_TemplateInstances[B3Timer_InjectingMenu]["B3Timer_Menu_TEMPLATE_TimerModal"].instanceData[instanceId].enabled
end

function B3Timer_Menu_TEMPLATE_TimerModal_Frame()
	local portraitIndex = B3Timer_TemplateInstances[B3Timer_InjectingMenu]["B3Timer_Menu_TEMPLATE_TimerModal"].instanceData[instanceId].portraitIndex
	return math.floor(90 * EEex_Sprite_GetModalTimerPercentage(EEex_Sprite_GetInPortrait(portraitIndex)) + 0.5)
end

function B3Timer_Menu_TEMPLATE_TimerContingency_Enabled()
	return B3Timer_TemplateInstances[B3Timer_InjectingMenu]["B3Timer_Menu_TEMPLATE_TimerContingency"].instanceData[instanceId].enabled
end

function B3Timer_Menu_TEMPLATE_TimerContingency_Frame()
	local portraitIndex = B3Timer_TemplateInstances[B3Timer_InjectingMenu]["B3Timer_Menu_TEMPLATE_TimerContingency"].instanceData[instanceId].portraitIndex
	return math.floor(90 * EEex_Sprite_GetContingencyTimerPercentage(EEex_Sprite_GetInPortrait(portraitIndex)) + 0.5)
end

function B3Timer_Menu_TEMPLATE_TimerCast_Enabled()
	return B3Timer_TemplateInstances[B3Timer_InjectingMenu]["B3Timer_Menu_TEMPLATE_TimerCast"].instanceData[instanceId].enabled
end

function B3Timer_Menu_TEMPLATE_TimerCast_Frame()
	local portraitIndex = B3Timer_TemplateInstances[B3Timer_InjectingMenu]["B3Timer_Menu_TEMPLATE_TimerCast"].instanceData[instanceId].portraitIndex
	return math.floor(90 * EEex_Sprite_GetCastTimerPercentage(EEex_Sprite_GetInPortrait(portraitIndex)) + 0.5)
end
