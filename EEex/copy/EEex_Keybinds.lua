
-- Format: ["<id>"] = {function / spell resref, {required modifier keys}, {main keys combination}, <fire on release boolean>},

EEex_Keybinds_Private_Hotkeys = {
	-- ["EEex_Keybinds_ExampleOld"]            = {"SPIN103", {}, {0x73, 0x61, 0x64}},                                                      -- Old way of doing a spell keybinding
	-- ["EEex_Keybinds_ExampleSpell"]          = {function() EEex_Keybinds_Cast("SPWI112") end, {}, {0x73, 0x61, 0x64}},                   -- Example of a spell keybinding
	-- ["EEex_Keybinds_ExampleSelectPortrait"] = {function() EEex_Keybinds_SelectPortrait(0) end, {0x400000E1}, {0x31}},                   -- Example of a keybinding that uses shift mod
	-- ["EEex_Keybinds_ExampleCastTwoStep1"]   = {function() EEex_Keybinds_CastTwoStep("SPWI124", "SPWI112") end, {}, {0x61, 0x73, 0x64}}, -- Example of casting Magic Missile through Nahal's
	-- ["EEex_Keybinds_ExampleCastTwoStep2"]   = {function() EEex_Keybinds_CastTwoStep("SPWI510", "SPWI596") end, {}, {0x64, 0x73, 0x61}}, -- Example of casting Immunity : Necromancy
}

-- Initialize all stage counters to 1
for _, hotkeyDef in pairs(EEex_Keybinds_Private_Hotkeys) do
	if hotkeyDef[4] == nil then hotkeyDef[4] = true end
	hotkeyDef[5] = 1
end

--===========
-- Options ==
--===========

EEex_Options_Register(EEex_Options_Option.new({
	["id"]       = "EEex_Keybinds_ToggleKeycodeOutput",
	["default"]  = EEex_Options_UnmarshalKeybind("`|Up"),
	["type"]     = EEex_Options_KeybindType.new({
		["callback"] = function() EEex_Keybinds_Private_TogglePrintKeys() end,
	}),
	["accessor"] = EEex_Options_KeybindAccessor.new({ ["keybindID"] = "EEex_Keybinds_ToggleKeycodeOutput" }),
	["storage"]  = EEex_Options_KeybindLuaStorage.new({ ["section"] = "EEex", ["key"] = "Toggle Keycode Output" }),
}))

EEex_Options_AddTab("Miscellaneous", function() return {
	{
		EEex_Options_DisplayEntry.new({
			["name"]     = "Toggle Keycode Output",
			["optionID"] = "EEex_Keybinds_ToggleKeycodeOutput",
			["widget"]   = EEex_Options_KeybindWidget.new(),
		}),
	},
} end)

--===========
-- Globals ==
--===========

EEex_Keybinds_Private_InternalCastResref = nil
EEex_Keybinds_Private_PendingOnReleaseKeybind = nil
EEex_Keybinds_Private_PrintKeys = false

--===========
-- General ==
--===========

------------
-- Public --
------------

function EEex_Keybinds_SetBinding(id, modifierKeys, keys, fireType, func)
	local existingTable = EEex_Keybinds_Private_Hotkeys[id]
	if existingTable ~= nil then
		if func ~= nil then existingTable[1] = func end
		existingTable[2] = modifierKeys
		existingTable[3] = keys
		existingTable[4] = fireType
	else
		EEex_Keybinds_Private_Hotkeys[id] = { func, modifierKeys, keys, fireType, 1 }
	end
end

function EEex_Keybinds_GetBinding(id)
	local existingTable = EEex_Keybinds_Private_Hotkeys[id]
	if existingTable == nil then return nil, nil, nil, nil end
	return existingTable[2], existingTable[3], existingTable[4], existingTable[1]
end

function EEex_Keybinds_Cast(resref)

	if worldScreen ~= e:GetActiveEngine() then return false end

	local sprite = EEex_Sprite_GetSelected()
	if sprite == nil then return false end

	if EEex_Keybinds_Private_UseCGameButtonList(sprite, sprite:GetQuickButtons(2, false), resref, false) then
		return true
	end

	return EEex_Keybinds_Private_UseCGameButtonList(sprite, sprite:GetQuickButtons(4, false), resref, false)
end

function EEex_Keybinds_CastTwoStep(initial, second)
	if not EEex_Keybinds_Cast(initial) then return end
	EEex_Keybinds_Private_InternalCastResref = second
end

function EEex_Keybinds_SelectPortrait(portraitNum, dontUnselect)

	local activeEngine = e:GetActiveEngine()
	if worldScreen ~= activeEngine then
		EEex_CastUD(activeEngine, "EEex_CBaldurEngine"):virtual_OnPortraitLClick(portraitNum)
		return
	end

	local game = EngineGlobals.g_pBaldurChitin.m_pObjectGame
	local spriteID = EEex_Sprite_GetInPortraitID(portraitNum)
	local cursorState = game.m_nState

	if cursorState == 0 then
		local memberList = game.m_group.m_memberList
		if memberList.m_nCount == 1 and memberList.m_pNodeHead.data == spriteID then
			game:OnPortraitLDblClick(portraitNum)
		else
			if not dontUnselect then game:UnselectAll() end
			game:SelectCharacter(spriteID, true) -- boolean bPlaySelectSound
			game:SelectToolbar()
		end
	else
		local sprite = EEex_GameObject_Get(spriteID)
		if sprite == nil then return end

		local visibleArea = EEex_Area_GetVisible()
		if not EEex_UDEqual(visibleArea, sprite.m_pArea) then return end

		if cursorState == 1 then
			visibleArea:OnActionButtonClickGround(sprite.m_pos)
		else
			sprite:virtual_OnActionButton(sprite.m_pos)
		end
	end
end

-------------
-- Private --
-------------

function EEex_Keybinds_Private_TogglePrintKeys()
	if not EEex_Keybinds_Private_PrintKeys then
		Infinity_DisplayString("[EEex] Enabled Keycode Output")
	else
		Infinity_DisplayString("[EEex] Disabled Keycode Output")
	end
	EEex_Keybinds_Private_PrintKeys = not EEex_Keybinds_Private_PrintKeys
end

function EEex_Keybinds_Private_UseCGameButtonList(sprite, buttonList, resref, bOffInternal)

	local found = false

	EEex_Utility_IterateCPtrList(buttonList, function(buttonData)
		if buttonData.m_abilityId.m_res:get() ~= resref then return --[[ continue --]] end
		if bOffInternal then
			sprite:ReadyOffInternalList(buttonData, false)
		else
			sprite:ReadySpell(buttonData, false)
		end
		found = true
		return true -- break
	end)

	EEex_Utility_FreeCPtrList(buttonList)
	return found
end

function EEex_Keybinds_Private_CastOffInternal(resref)

	if worldScreen ~= e:GetActiveEngine() then return false end

	local sprite = EEex_Sprite_GetSelected()
	if sprite == nil then return false end

	if not EEex_Keybinds_Private_UseCGameButtonList(sprite, sprite:GetInternalButtonList(), resref, true) then
		return false
	end

	EEex_Actionbar_RestoreLastState()
	return true
end

--=============
-- Listeners ==
--=============

function EEex_Keybinds_Private_Run(hotkeyDef)

	local hotkeyValue = hotkeyDef[1]
	local hotkeyValueType = type(hotkeyValue)

	if hotkeyValueType == "string" then
		EEex_Keybinds_Cast(hotkeyValue)
	elseif hotkeyValueType == "function" then
		hotkeyValue()
	else
		EEex_Error("Unhandled keybind action type")
	end
end

function EEex_Keybinds_Private_HandleKey(key, isReplay)

	EEex_Keybinds_Private_PendingOnReleaseKeybind = nil

	for hotkeyName, hotkeyDef in pairs(EEex_Keybinds_Private_Hotkeys) do

		local stage = hotkeyDef[5]

		if stage == 0 then
			-- If the current keybind stage indicates PROCESSING STOPPED, END
			goto continue
		end

		local isModifier = EEex_Utility_Find(hotkeyDef[2], key)
		local hotkeyCombo = hotkeyDef[3]
		local onlyModifiers = hotkeyCombo[1] == nil and hotkeyDef[2][1] ~= nil

		if not onlyModifiers then
			-- If the keybind isn't only modifiers ...

			if isModifier then
				-- ... and the key is a specified modifier, END
				goto continue
			end

			if hotkeyCombo[stage] ~= key then
				-- ... and the key isn't the expected value for the current keybind stage, STOP PROCESSING and END
				hotkeyDef[5] = 0
				goto continue
			end

			-- ADVANCE
			hotkeyDef[5] = stage + 1

			if stage ~= #hotkeyCombo then
				-- ... and the current keybind stage isn't the end of the sequence, END
				goto continue
			end

		elseif not isModifier then
			-- If the keybind is only modifiers, and the key isn't a specified modifier, STOP PROCESSING and END
			hotkeyDef[5] = 0
			goto continue
		end

		local allModifiersDown = true

		for _, modifier in ipairs(hotkeyDef[2]) do
			if not EEex_Key_IsDown(modifier) then
				allModifiersDown = false
				break
			end
		end

		if not allModifiersDown then
			-- If at least one of the specified modifiers isn't down ...
			if not onlyModifiers then
				-- ... and the keybind isn't only modifiers, STOP PROCESSING and ...
				hotkeyDef[5] = 0
			end
			-- ... END
			goto continue
		end

		if isReplay then
			-- If this is a replay event, STOP PROCESSING and END
			hotkeyDef[5] = 0
			goto continue
		end

		-- Success

		if hotkeyDef[4] then
			-- Keybind fires on release
			EEex_Keybinds_Private_PendingOnReleaseKeybind = hotkeyDef
		else
			-- Keybind fires on press
			EEex_Keybinds_Private_Run(hotkeyDef)
		end

		do break end
		::continue::
	end
end

function EEex_Keybinds_Private_Reset()

	for _, hotkeyDef in pairs(EEex_Keybinds_Private_Hotkeys) do
		hotkeyDef[5] = 1
	end

	-- Replay the pressed keys stack so keybind states rebuild as if the released key wasn't pressed.
	-- This rebuild is not allowed to activate keybindings by itself.
	for _, key in ipairs(EEex_Key_GetPressedStack()) do
		EEex_Keybinds_Private_HandleKey(key, true)
	end
end

EEex_Key_AddPressedListener(function(key)
	if EEex_Keybinds_Private_PrintKeys then
		Infinity_DisplayString("[EEex] Pressed: "..EEex_ToHex(key))
	end
	EEex_Keybinds_Private_HandleKey(key, false)
end)

EEex_Key_AddReleasedListener(function(key)
	if EEex_Keybinds_Private_PendingOnReleaseKeybind ~= nil then
		EEex_Keybinds_Private_Run(EEex_Keybinds_Private_PendingOnReleaseKeybind)
		EEex_Keybinds_Private_PendingOnReleaseKeybind = nil
	end
	EEex_Keybinds_Private_Reset()
end)

EEex_Actionbar_AddListener(function(config, state)

	if EEex_Keybinds_Private_InternalCastResref == nil or config ~= 28 then return end

	local myCopy = EEex_Keybinds_Private_InternalCastResref
	EEex_Keybinds_Private_InternalCastResref = nil

	-- EEex_Keybinds_Private_CastOffInternal() causes the engine to reapply config 28 if
	-- the ability target is the caster. We don't want other listeners to
	-- detect this, especially the spell menu.
	return EEex_Actionbar_RunWithListenersSuppressed(function()
		return EEex_Keybinds_Private_CastOffInternal(myCopy)
	end)
end)
