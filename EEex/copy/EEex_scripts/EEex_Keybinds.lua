
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

EEex_Options_Register("EEex_Keybinds_OpenOptions", EEex_Options_Option.new({
	["default"]  = EEex_Options_UnmarshalKeybind("\\|Up"),
	["type"]     = EEex_Options_KeybindType.new({
		["callback"] = function() EEex_Options_Open() end,
	}),
	["accessor"] = EEex_Options_KeybindAccessor.new({ ["keybindID"] = "EEex_Keybinds_OpenOptions" }),
	["storage"]  = EEex_Options_KeybindLuaStorage.new({ ["section"] = "EEex", ["key"] = "Open Options Keybind" }),
}))

EEex_Options_Register("EEex_Keybinds_ToggleKeycodeOutput", EEex_Options_Option.new({
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

-- @bubb_doc { EEex_Keybinds_Cast }
--
-- @summary: Attempts to cast ``resref`` as the leader of the currently selected sprites.
--
-- @param { resref / type=string }: The resref of the spell to cast.
--
-- @return { type=boolean }: ``true`` if the casting was started successfully; ``false`` otherwise.

function EEex_Keybinds_Cast(resref)

	if worldScreen ~= e:GetActiveEngine() then return false end

	local sprite = EEex_Sprite_GetSelected()
	if sprite == nil then return false end

	if EEex_Keybinds_Private_UseCGameButtonList(sprite, sprite:GetQuickButtons(2, false), resref, false) then
		return true
	end

	return EEex_Keybinds_Private_UseCGameButtonList(sprite, sprite:GetQuickButtons(4, false), resref, false)
end

-- @bubb_doc { EEex_Keybinds_CastTwoStep }
--
-- @summary: Attempts to cast ``firstResref`` |rarr| ``secondResref`` as the leader of the currently selected sprites.
--
-- @param { firstResref / type=string }:
--
--     The resref of the first spell to cast. @EOL
--     This spell should invoke op214.
--
-- @param { secondResref / type=string }:
--
--     The resref of the second spell to cast.                        @EOL
--     This spell should be provided by the previously invoked op214.

function EEex_Keybinds_CastTwoStep(firstResref, secondResref)
	if not EEex_Keybinds_Cast(firstResref) then return end
	EEex_Keybinds_Private_InternalCastResref = secondResref
end

-- @bubb_doc { EEex_Keybinds_SelectPortrait }
--
-- @summary: Attempts to select the portrait in ``portraitIndex``.
--
-- @param { portraitIndex / type=number }: The index of the portrait to select.
--
-- @param { dontUnselect / type=boolean / default=false }:
--
--     If ``true``, prevents the deselection of already-selected sprites. @EOL
--     This is analogous to holding Shift in the original keybindings.

function EEex_Keybinds_SelectPortrait(portraitIndex, dontUnselect)

	local activeEngine = e:GetActiveEngine()
	if worldScreen ~= activeEngine then
		EEex_CastUD(activeEngine, "EEex_CBaldurEngine"):virtual_OnPortraitLClick(portraitIndex)
		return
	end

	local game = EngineGlobals.g_pBaldurChitin.m_pObjectGame
	local spriteID = EEex_Sprite_GetInPortraitID(portraitIndex)
	local cursorState = game.m_nState

	if cursorState == 0 then
		local memberList = game.m_group.m_memberList
		if memberList.m_nCount == 1 and memberList.m_pNodeHead.data == spriteID then
			game:OnPortraitLDblClick(portraitIndex)
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

-- @bubb_doc { EEex_Keybinds_Get }
--
-- @summary: Returns a table representing the keybind with the given ``id``.
--
-- @param { id / type=string }: The unique id of the associated keybind.
--
-- @return { type=table | nil }: See summary.
--
-- @extra_comment:
--
-- ==========================================================================================================================================================================================================
--
-- .. _the-keybind-table:
--
-- **The Keybind Table**
-- *********************
--
-- +----------------+------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
-- | Key            | Value Type             | Description                                                                                                                            |
-- +================+========================+========================================================================================================================================+
-- | allowOtherKeys | boolean                | If ``true``, the keybind will not fail to match if unrelated keys are pressed.                                                         |
-- +----------------+------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
-- | callback       | function               | Function that is called when the conditions required by ``fireType`` are satisfied.                                                    |
-- +----------------+------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
-- | fireType       | EEex_Keybinds_FireType | The situation in which ``callback`` is invoked.                                                                                        |
-- +----------------+------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
-- | keys           | table                  | Table of keycodes defining the keybind's main sequence of keys.                                       :raw-html:`<br/>`                |
-- |                |                        | These keys must be pressed in the defined order for the keybind to be satisfied.                                                       |
-- +----------------+------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
-- | modifierKeys   | table                  | Table of keycodes defining the keys that are required to be down when the main sequence is satisfied. :raw-html:`<br/>`                |
-- |                |                        | Allowed keys include the left / right variants of Ctrl, Shift, and Alt.                                                                |
-- +----------------+------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
-- | onSatisfied    | function               | Called when the keybind is satisfied, including both the initial trigger, and during a state rebuild after releasing a subsequent key. |
-- +----------------+------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
-- | onUnsatisfied  | function               | Called when the keybind is unsatisfied, which occurs after releasing a key in its sequence.                                            |
-- +----------------+------------------------+----------------------------------------------------------------------------------------------------------------------------------------+
--
-- ==========================================================================================================================================================================================================
--
-- **EEex_Keybinds_FireType**
-- **************************
--
-- +--------------+----------------------------------------------------------------------------------------+
-- | Ordinal Name | Description                                                                            |
-- +==============+========================================================================================+
-- | UP           | Fires when any key is released after the keybind has been satisfied. :raw-html:`<br/>` |
-- |              | Additional key presses will cancel the satisfaction of the keybind.                    |
-- +--------------+----------------------------------------------------------------------------------------+
-- | DOWN         | Fires when the keybind has been satisfied.                                             |
-- +--------------+----------------------------------------------------------------------------------------+

function EEex_Keybinds_Get(id)
	local t = EEex_Keybinds_Private_Definitions[id]
	if t == nil then return nil end
	return {
		["allowOtherKeys"] = t.allowOtherKeys,
		["callback"]       = t.callback,
		["fireType"]       = t.fireType,
		["keys"]           = EEex.DeepCopy(t.keys),
		["modifierKeys"]   = EEex.DeepCopy(t.modifierKeys),
		["onSatisfied"]    = t.onSatisfied,
		["onUnsatisfied"]  = t.onUnsatisfied,
	}
end

-- @bubb_doc { EEex_Keybinds_IsSatisfied }
--
-- @summary: Returns whether the keybind with the given ``id`` is satisfied.
--
-- @note: If the key stack is currently being replayed this returns the current satisfaction state,
--        which might be `false` even if the keybind is satisfied later on in the sequence.
--
-- @param { id / type=string }: The unique id of the associated keybind.
--
-- @return { type=boolean }: See summary.

function EEex_Keybinds_IsSatisfied(id)
	local hotkeyDef = EEex_Keybinds_Private_Definitions[id]
	if hotkeyDef == nil then return false end
	return hotkeyDef._satisfied
end

-- @bubb_doc { EEex_Keybinds_Reset }
--
-- @summary: Resets the keybind with the given ``id``, such that it can immediately start matching keys again from the beginning of its sequence.
--
-- @param { id / type=string }: The unique id of the associated keybind.

function EEex_Keybinds_Reset(id)

	local hotkeyDef = EEex_Keybinds_Private_Definitions[id]
	if hotkeyDef == nil then return end

	local wasSatisfied = hotkeyDef._satisfied
	hotkeyDef._satisfied = false
	hotkeyDef._stage = 1

	if wasSatisfied then
		EEex_Utility_TryIgnore(hotkeyDef.onUnsatisfied)
	end
end

-- @bubb_doc { EEex_Keybinds_Update }
--
-- @summary: Updates the keybind with the given ``id`` with the fields present in ``args``.
--
-- @param { id / type=string }: The unique id of the associated keybind.
--
-- @param { args / type=table }:
--
--     A table containing fields used to update the keybind.              @EOL
--     See :ref:`The Keybind Table <the-keybind-table>` for more details.

function EEex_Keybinds_Update(id, args)

	local t = EEex_Keybinds_Private_Definitions[id]

	if t == nil then
		t = {
			["allowOtherKeys"]        = false,
			["callback"]              = function() end,
			["fireType"]              = EEex_Keybinds_FireType.UP,
			["keys"]                  = {},
			["modifierKeys"]          = {},
			["onSatisfied"]           = function() end,
			["onUnsatisfied"]         = function() end,
			["_satisfied"]            = false,
			["_satisfiedBeforeReset"] = false,
			["_stage"]                = 1,
		}
		EEex_Keybinds_Private_Definitions[id] = t
	end

	local allowOtherKeys = args.allowOtherKeys
	local callback       = args.callback
	local fireType       = args.fireType
	local keys           = args.keys
	local modifierKeys   = args.modifierKeys
	local onSatisfied    = args.onSatisfied
	local onUnsatisfied  = args.onUnsatisfied

	if allowOtherKeys ~= nil then t.allowOtherKeys = allowOtherKeys              end
	if callback       ~= nil then t.callback       = callback                    end
	if fireType       ~= nil then t.fireType       = fireType                    end
	if keys           ~= nil then t.keys           = EEex.DeepCopy(keys)         end
	if modifierKeys   ~= nil then t.modifierKeys   = EEex.DeepCopy(modifierKeys) end
	if onSatisfied    ~= nil then t.onSatisfied    = onSatisfied                 end
	if onUnsatisfied  ~= nil then t.onUnsatisfied  = onUnsatisfied               end
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

	local satisfiedHotkeyDefs = {}
	local satisfiedHotkeyDefsI = 0

	for hotkeyName, hotkeyDef in pairs(EEex_Keybinds_Private_Definitions) do

		local stage = hotkeyDef._stage

		if stage == 0 then
			-- If the current keybind stage indicates PROCESSING STOPPED, END
			goto continue
		end

		local allowOtherKeys = hotkeyDef.allowOtherKeys
		local isModifier = EEex_Utility_Find(hotkeyDef.modifierKeys, key)
		local hotkeyCombo = hotkeyDef.keys
		local onlyModifiers = hotkeyCombo[1] == nil and hotkeyDef.modifierKeys[1] ~= nil

		if not onlyModifiers then
			-- If the keybind isn't only modifiers ...

			if isModifier then
				-- ... and the key is a specified modifier, END
				goto continue
			end

			if hotkeyCombo[stage] == key then
				-- ... and the key is the expected value for the current keybind stage, ADVANCE ...
				hotkeyDef._stage = stage + 1
			else
				-- ... and the key isn't the expected value ...
				if not allowOtherKeys then
					-- ... and the keybind doesn't allow for other keys, STOP PROCESSING and ...
					hotkeyDef._stage = 0
				end
				--- ... END
				goto continue
			end

			if stage ~= #hotkeyCombo then
				-- ... and the current keybind stage isn't the end of the sequence, END
				goto continue
			end

		elseif not allowOtherKeys and not isModifier then
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

		-- Success, STOP PROCESSING
		hotkeyDef._stage = 0

		if isReplay then

			local resumedSatisfied = hotkeyDef._satisfiedBeforeReset
			hotkeyDef._satisfied = resumedSatisfied

			if resumedSatisfied then
				satisfiedHotkeyDefsI = satisfiedHotkeyDefsI + 1
				satisfiedHotkeyDefs[satisfiedHotkeyDefsI] = hotkeyDef
			end

			-- If this is a replay event, END
			goto continue
		end

		hotkeyDef._satisfied = true
		satisfiedHotkeyDefsI = satisfiedHotkeyDefsI + 1
		satisfiedHotkeyDefs[satisfiedHotkeyDefsI] = hotkeyDef

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

	-- Delayed to here because an `onSatisfied()` callback might want to reset another keybinding.
	-- Doing this in the middle of processing the hotkey defs could reset the keybinding too early,
	-- before it has processed the current key, causing it to fail right after it was reset.
	for _, hotkeyDef in ipairs(satisfiedHotkeyDefs) do
		EEex_Utility_TryIgnore(hotkeyDef.onSatisfied)
	end
end

function EEex_Keybinds_Private_Reset()

	for _, hotkeyDef in pairs(EEex_Keybinds_Private_Definitions) do
		hotkeyDef._satisfiedBeforeReset = hotkeyDef._satisfied
		hotkeyDef._satisfied = false
		hotkeyDef._stage = 1
	end

	-- Replay the pressed keys stack so keybind states rebuild as if the released key wasn't pressed.
	-- This rebuild is not allowed to activate keybindings by itself.
	for _, key in ipairs(EEex_Key_GetPressedStack()) do
		EEex_Keybinds_Private_HandleKey(key, true)
	end

	for _, hotkeyDef in pairs(EEex_Keybinds_Private_Definitions) do
		if hotkeyDef._satisfiedBeforeReset and not hotkeyDef._satisfied then
			EEex_Utility_TryIgnore(hotkeyDef.onUnsatisfied)
		end
	end
end

function EEex_Keybinds_Private_Run(hotkeyDef)
	EEex_Utility_TryIgnore(hotkeyDef.callback)
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
