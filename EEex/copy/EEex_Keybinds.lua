
--=============
-- Constants ==
--=============

EEex_Keybinds_FireType = {
	["UP"]   = true,
	["DOWN"] = false,
}

--===========
-- Options ==
--===========

EEex_Options_Register(EEex_Options_Option.new({
	["id"]       = "EEex_Keybinds_OpenOptions",
	["default"]  = EEex_Options_UnmarshalKeybind("\\|Up"),
	["type"]     = EEex_Options_KeybindType.new({
		["callback"] = function() EEex_Options_Open() end,
	}),
	["accessor"] = EEex_Options_KeybindAccessor.new({ ["keybindID"] = "EEex_Keybinds_OpenOptions" }),
	["storage"]  = EEex_Options_KeybindLuaStorage.new({ ["section"] = "EEex", ["key"] = "Open Options Keybind" }),
}))

EEex_Options_Register(EEex_Options_Option.new({
	["id"]       = "EEex_Keybinds_ToggleKeycodeOutput",
	["default"]  = EEex_Options_UnmarshalKeybind("`|Up"),
	["type"]     = EEex_Options_KeybindType.new({
		["callback"] = function() EEex_Keybinds_Private_TogglePrintKeys() end,
	}),
	["accessor"] = EEex_Options_KeybindAccessor.new({ ["keybindID"] = "EEex_Keybinds_ToggleKeycodeOutput" }),
	["storage"]  = EEex_Options_KeybindLuaStorage.new({ ["section"] = "EEex", ["key"] = "Toggle Keycode Output" }),
}))

EEex_Options_AddTab("EEex_Options_TRANSLATION_Keybinds_TabTitle", function() return {
	{
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_Keybinds_OpenOptions",
			["label"]       = "EEex_Options_TRANSLATION_Keybinds_OpenOptions",
			["description"] = "EEex_Options_TRANSLATION_Keybinds_OpenOptions_Description",
			["widget"]      = EEex_Options_KeybindWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "EEex_Keybinds_ToggleKeycodeOutput",
			["label"]       = "EEex_Options_TRANSLATION_Keybinds_ToggleKeycodeOutput",
			["description"] = "EEex_Options_TRANSLATION_Keybinds_ToggleKeycodeOutput_Description",
			["widget"]      = EEex_Options_KeybindWidget.new(),
		}),
	},
} end)

--===========
-- Globals ==
--===========

EEex_Keybinds_Private_Definitions = {}
EEex_Keybinds_Private_InternalCastResref = nil
EEex_Keybinds_Private_PendingOnReleaseKeybind = nil
EEex_Keybinds_Private_PrintKeys = false

--===========
-- General ==
--===========

--=-=-=-=-==
-- Public ==
--=-=-=-=-==

---------------------
-- Keybind Actions --
---------------------

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

------------------------
-- Keybind Management --
------------------------

function EEex_Keybinds_Get(id)
	local t = EEex_Keybinds_Private_Definitions[id]
	if t == nil then return nil end
	return {
		["callback"]     = t.callback,
		["fireType"]     = t.fireType,
		["keys"]         = EEex.DeepCopy(t.keys),
		["modifierKeys"] = EEex.DeepCopy(t.modifierKeys),
	}
end

function EEex_Keybinds_Update(id, args)

	local t = EEex_Keybinds_Private_Definitions[id]

	if t == nil then
		t = {
			["callback"]     = function() end,
			["fireType"]     = EEex_Keybinds_FireType.UP,
			["keys"]         = {},
			["modifierKeys"] = {},
			["_stage"]       = 1,
		}
		EEex_Keybinds_Private_Definitions[id] = t
	end

	local callback     = args.callback
	local fireType     = args.fireType
	local keys         = args.keys
	local modifierKeys = args.modifierKeys

	if callback     ~= nil then t.callback     = callback                    end
	if fireType     ~= nil then t.fireType     = fireType                    end
	if keys         ~= nil then t.keys         = EEex.DeepCopy(keys)         end
	if modifierKeys ~= nil then t.modifierKeys = EEex.DeepCopy(modifierKeys) end
end

--=-=-=-=-=-==
-- Private  ==
--=-=-=-=-=-==

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

function EEex_Keybinds_Private_HandleKey(key, isReplay)

	EEex_Keybinds_Private_PendingOnReleaseKeybind = nil

	for hotkeyName, hotkeyDef in pairs(EEex_Keybinds_Private_Definitions) do

		local stage = hotkeyDef._stage

		if stage == 0 then
			-- If the current keybind stage indicates PROCESSING STOPPED, END
			goto continue
		end

		local isModifier = EEex_Utility_Find(hotkeyDef.modifierKeys, key)
		local hotkeyCombo = hotkeyDef.keys
		local onlyModifiers = hotkeyCombo[1] == nil and hotkeyDef.modifierKeys[1] ~= nil

		if not onlyModifiers then
			-- If the keybind isn't only modifiers ...

			if isModifier then
				-- ... and the key is a specified modifier, END
				goto continue
			end

			if hotkeyCombo[stage] ~= key then
				-- ... and the key isn't the expected value for the current keybind stage, STOP PROCESSING and END
				hotkeyDef._stage = 0
				goto continue
			end

			-- ADVANCE
			hotkeyDef._stage = stage + 1

			if stage ~= #hotkeyCombo then
				-- ... and the current keybind stage isn't the end of the sequence, END
				goto continue
			end

		elseif not isModifier then
			-- If the keybind is only modifiers, and the key isn't a specified modifier, STOP PROCESSING and END
			hotkeyDef._stage = 0
			goto continue
		end

		local allModifiersDown = true

		for _, modifier in ipairs(hotkeyDef.modifierKeys) do
			if not EEex_Key_IsDown(modifier) then
				allModifiersDown = false
				break
			end
		end

		if not allModifiersDown then
			-- If at least one of the specified modifiers isn't down ...
			if not onlyModifiers then
				-- ... and the keybind isn't only modifiers, STOP PROCESSING and ...
				hotkeyDef._stage = 0
			end
			-- ... END
			goto continue
		end

		if isReplay then
			-- If this is a replay event, STOP PROCESSING and END
			hotkeyDef._stage = 0
			goto continue
		end

		-- Success

		if hotkeyDef.fireType == EEex_Keybinds_FireType.UP then
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

	for _, hotkeyDef in pairs(EEex_Keybinds_Private_Definitions) do
		hotkeyDef._stage = 1
	end

	-- Replay the pressed keys stack so keybind states rebuild as if the released key wasn't pressed.
	-- This rebuild is not allowed to activate keybindings by itself.
	for _, key in ipairs(EEex_Key_GetPressedStack()) do
		EEex_Keybinds_Private_HandleKey(key, true)
	end
end

function EEex_Keybinds_Private_Run(hotkeyDef)
	hotkeyDef.callback()
end

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

--=============
-- Listeners ==
--=============

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
