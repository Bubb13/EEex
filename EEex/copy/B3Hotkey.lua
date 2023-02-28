
-- Format: {function / spell resref, {required modifier keys}, {main keys combination}},

B3Hotkey_Hotkeys = {
	{function() B3Hotkey_TogglePrintKeys() end, {}, {0x60}},                               -- Key-Pressed Output Toggle ('`')
	--{"SPIN103", {}, {0x73, 0x61, 0x64}},                                                 -- Old way of doing a spell keybinding
	--{function() B3Hotkey_AttemptToCastViaHotkey("SPWI112") end, {}, {0x73, 0x61, 0x64}}, -- Example of a spell keybinding
	--{function() B3Hotkey_AttemptToSelectCharacter(0) end, {0x400000E1}, {0x31}},         -- Example of a keybinding that uses shift mod
	--{function() B3Hotkey_CastTwoStep("SPWI124", "SPWI112") end, {}, {0x61, 0x73, 0x64}}, -- Example of casting Magic Missile through Nahal's
	--{function() B3Hotkey_CastTwoStep("SPWI510", "SPWI596") end, {}, {0x64, 0x73, 0x61}}, -- Example of casting Immunity : Necromancy
}

-- Initialize all stage counters to 1
for _, hotkeyDef in ipairs(B3Hotkey_Hotkeys) do
	hotkeyDef[4] = 1
end

B3Hotkey_PrintKeys = false
function B3Hotkey_TogglePrintKeys()
	if not B3Hotkey_PrintKeys then
		B3Hotkey_PrintKeys = true
		Infinity_DisplayString("[EEex] Enabled Key-Pressed Output")
	else
		B3Hotkey_PrintKeys = false
		Infinity_DisplayString("[EEex] Disabled Key-Pressed Output")
	end
end

-- Internal to this file
function B3Hotkey_UseCGameButtonList(sprite, buttonList, resref, bOffInternal)

	local found = false

	EEex_Utility_IterateCPtrList(buttonList, function(buttonData)
		if buttonData.m_abilityId.m_res:get() == resref then
			if bOffInternal then
				sprite:ReadyOffInternalList(buttonData, false)
			else
				sprite:ReadySpell(buttonData, false)
			end
			found = true
			return true -- breaks out of EEex_Utility_IterateCPtrList()
		end
	end)

	EEex_Utility_FreeCPtrList(buttonList)
	return found
end

function B3Hotkey_AttemptToCastViaHotkey(resref)
	if worldScreen == e:GetActiveEngine() then
		local sprite = EEex_Sprite_GetSelected()
		if sprite then
			local spellButtonDataList = sprite:GetQuickButtons(2, false)
			if B3Hotkey_UseCGameButtonList(sprite, spellButtonDataList, resref, false) then return end
			local innateButtonDataList = sprite:GetQuickButtons(4, false)
			B3Hotkey_UseCGameButtonList(sprite, innateButtonDataList, resref, false)
		end
	end
end

function B3Hotkey_CastOffInternal(resref)
	if worldScreen == e:GetActiveEngine() then
		local sprite = EEex_Sprite_GetSelected()
		if sprite then
			local spellButtonDataList = sprite:GetInternalButtonList()
			if B3Hotkey_UseCGameButtonList(sprite, spellButtonDataList, resref, true) then
				EEex_Actionbar_RestoreLastState()
				return true
			end
		end
	end
	return false
end

function B3Hotkey_CastTwoStep(initial, second)
	B3Hotkey_AttemptToCastViaHotkey(initial)
	B3Hotkey_InternalCastResref = second
end

function B3Hotkey_AttemptToSelectCharacter(portraitNum, dontUnselect)

	local chitin = EngineGlobals.g_pBaldurChitin
	local activeEngine = e:GetActiveEngine()

	if worldScreen == activeEngine then

		local game = chitin.m_pObjectGame
		local spriteID = EEex_Sprite_GetInPortraitID(portraitNum)
		local cursorState = game.m_nState

		if cursorState == 0 then

			local doSelect = true

			local memberList = game.m_group.m_memberList
			if memberList.m_nCount == 1 and memberList.m_pNodeHead.data == spriteID then
				game:OnPortraitLDblClick(portraitNum)
				doSelect = false
			end

			if doSelect then

				if not dontUnselect then
					game:UnselectAll()
				end

				-- boolean bPlaySelectSound
				game:SelectCharacter(spriteID, true)
				game:SelectToolbar()
			end
		else
			local sprite = EEex_GameObject_Get(spriteID)
			if not sprite then
				return
			end

			local visibleArea = EEex_Area_GetVisible()
			if EEex_UserDataEqual(visibleArea, sprite.m_pArea) then
				if cursorState == 1 then
					visibleArea:OnActionButtonClickGround(sprite.m_pos)
				else
					sprite:virtual_OnActionButton(sprite.m_pos)
				end
			end
		end
	else
		EEex_CastUD(activeEngine, "EEex_CBaldurEngine"):virtual_OnPortraitLClick(portraitNum)
	end
end

B3Hotkey_LastSuccessfulHotkey = nil

function B3Hotkey_KeyPressedListener(key)
	if B3Hotkey_PrintKeys then
		Infinity_DisplayString("[EEex] Pressed: "..EEex_ToHex(key))
	end
	local completedMatch = false
	for _, hotkeyDef in ipairs(B3Hotkey_Hotkeys) do
		local stage = hotkeyDef[4]
		if stage ~= 0 then
			local hotkeyCombo = hotkeyDef[3]
			if hotkeyCombo[stage] == key then
				if stage ~= #hotkeyCombo then
					hotkeyDef[4] = stage + 1 -- Advance
				else
					hotkeyDef[4] = 0 -- Stop Processing
					local allFlagsDown = true
					for _, flag in ipairs(hotkeyDef[2]) do
						if not EEex_Key_IsDown(flag) then
							allFlagsDown = false
							break
						end
					end
					if allFlagsDown then
						-- Success
						B3Hotkey_LastSuccessfulHotkey = hotkeyDef
						completedMatch = true
					end
				end
			else
				local shouldFail = true
				for _, flag in ipairs(hotkeyDef[2]) do
					if key == flag then
						shouldFail = false
						break
					end
				end
				if shouldFail then
					-- Fail
					hotkeyDef[4] = 0 -- Stop Processing
				end
			end
		end
	end
	if not completedMatch then
		B3Hotkey_LastSuccessfulHotkey = nil
	end
end
EEex_Key_AddPressedListener(B3Hotkey_KeyPressedListener)

function B3Hotkey_KeyReleasedListener(key)
	if B3Hotkey_LastSuccessfulHotkey ~= nil then
		local hotkeyValue = B3Hotkey_LastSuccessfulHotkey[1]
		local hotkeyValueType = type(hotkeyValue)
		if hotkeyValueType == "string" then
			B3Hotkey_AttemptToCastViaHotkey(hotkeyValue)
		elseif hotkeyValueType == "function" then
			hotkeyValue()
		end
	end
	B3Hotkey_LastSuccessfulHotkey = nil
	for _, hotkeyDef in ipairs(B3Hotkey_Hotkeys) do
		hotkeyDef[4] = 1
	end
end
EEex_Key_AddReleasedListener(B3Hotkey_KeyReleasedListener)

B3Hotkey_InternalCastResref = nil

function B3Hotkey_ActionbarListener(config, state)
	if config == 28 and B3Hotkey_InternalCastResref then
		local myCopy = B3Hotkey_InternalCastResref
		B3Hotkey_InternalCastResref = nil
		-- B3Hotkey_CastOffInternal() causes the engine to reapply config 28 if
		-- the ability target is the caster. We don't want other listeners to
		-- detect this, especially the spell menu.
		return EEex_Actionbar_RunWithListenersSuppressed(function()
			-- Prevent future listeners from processing the event if we handled it.
			-- Again, keep the spell menu from interfering.
			return B3Hotkey_CastOffInternal(myCopy)
		end)
	end
end
EEex_Actionbar_AddListener(B3Hotkey_ActionbarListener)
