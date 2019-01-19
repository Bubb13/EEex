
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

B3Hotkey_Hotkeys = {
	{B3Hotkey_TogglePrintKeys, 3, 0x60}, -- Key-Pressed Output Toggle
	--{"SPWI112", 3, 0x61, 0x73, 0x64},  -- Example keybinding...
}

function B3Hotkey_AttemptToCastViaHotkey(resref)
	local actorID = EEex_GetActorIDSelected()
	if actorID ~= 0x0 then
		local useCGameButtonList = function(m_CGameSprite, m_CGameButtonList)
			local found = false
			EEex_IterateCPtrList(m_CGameButtonList, function(m_CButtonData) 
				-- m_CButtonData.m_abilityId.m_res
				local m_res = EEex_ReadLString(m_CButtonData + 0x1C + 0x6, 0x8)
				if m_res == resref then
					-- Unlike most other functions, CGameSprite::ReadySpell() expects the CButtonData
					-- arg to be passed by VALUE, not by reference. EEex's call() function isn't designed
					-- to do that, so the hacky hilarity that follows is required...
					local stackArgs = {}
					table.insert(stackArgs, 0x0)
					for i = 0x30, 0x0, -0x4 do
						table.insert(stackArgs, EEex_ReadDword(m_CButtonData + i))
					end
					EEex_Call(EEex_Label("CGameSprite::ReadySpell"), stackArgs, m_CGameSprite, 0x0)
					found = true
					return true -- breaks out of EEex_IterateCPtrList()
				end
			end)
			EEex_FreeCPtrList(m_CGameButtonList)
			return found
		end
		local m_CGameSprite = EEex_GetActorShare(actorID)
		local spellButtonDataList = EEex_Call(EEex_Label("CGameSprite::GetQuickButtons"), {0, 2}, m_CGameSprite, 0x0)
		if useCGameButtonList(m_CGameSprite, spellButtonDataList) then return end
		local innateButtonDataList = EEex_Call(EEex_Label("CGameSprite::GetQuickButtons"), {0, 4}, m_CGameSprite, 0x0)
		useCGameButtonList(m_CGameSprite, innateButtonDataList)
	end
end

B3Hotkey_LastSuccessfulHotkey = nil

function B3Hotkey_KeyPressedListener(key)
	if worldScreen == e:GetActiveEngine() then
		if B3Hotkey_PrintKeys then
			Infinity_DisplayString("[EEex] Pressed: "..EEex_ToHex(key))
		end
		local completedMatch = false
		for _, hotkeyDef in ipairs(B3Hotkey_Hotkeys) do
			local stage = hotkeyDef[2]
			if stage ~= 0 then
				if hotkeyDef[stage] == key then
					if stage ~= #hotkeyDef then
						hotkeyDef[2] = stage + 1 -- Advance
					else
						-- Success
						hotkeyDef[2] = 0 -- Stop Processing
						B3Hotkey_LastSuccessfulHotkey = hotkeyDef
						completedMatch = true
					end
					
				else
					-- Fail
					hotkeyDef[2] = 0 -- Stop Processing
				end
			end
		end
		if not completedMatch then
			B3Hotkey_LastSuccessfulHotkey = nil
		end
	end
end
EEex_AddKeyPressedListener(B3Hotkey_KeyPressedListener)

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
		hotkeyDef[2] = 3
	end
end
EEex_AddKeyReleasedListener(B3Hotkey_KeyReleasedListener)

function B3Hotkey_ResetListener()
	EEex_AddKeyPressedListener(B3Hotkey_KeyPressedListener)
	EEex_AddKeyReleasedListener(B3Hotkey_KeyReleasedListener)
	EEex_AddResetListener(B3Hotkey_ResetListener)
end
EEex_AddResetListener(B3Hotkey_ResetListener)
