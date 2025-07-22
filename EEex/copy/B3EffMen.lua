
-------------
-- Options --
-------------

EEex_Options_Register(EEex_Options_Option.new({
	["id"]       = "B3EffectMenu_LaunchKeybind",
	["default"]  = EEex_Options_UnmarshalKeybind("Left Shift|Down"),
	["type"]     = EEex_Options_KeybindType.new({
		["lockedFireType"] = EEex_Options_KeybindFireType.DOWN,
		["callback"]       = function() B3EffectMenu_Private_Menu_KeybindActive = true end,
	}),
	["accessor"] = EEex_Options_KeybindAccessor.new({ ["keybindID"] = "B3EffectMenu_LaunchKeybind" }),
	["storage"]  = EEex_Options_KeybindLuaStorage.new({ ["section"] = "EEex", ["key"] = "Effect Menu Module: Launch Keybind" }),
}))

B3EffectMenu_Private_RowCount = EEex_Options_Register(EEex_Options_Option.new({
	["id"]       = "B3EffectMenu_RowCount",
	["default"]  = 4,
	["type"]     = EEex_Options_EditType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"]  = 1, ["max"]  = 99, }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Effect Menu Module: Row Count" }),
}))

EEex_Options_AddTab("Module: Effect Menu", function() return {
	{
		EEex_Options_DisplayEntry.new({
			["name"]     = "Launch Keybind",
			["optionID"] = "B3EffectMenu_LaunchKeybind",
			["widget"]   = EEex_Options_KeybindWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["name"]     = "Row Count",
			["optionID"] = "B3EffectMenu_RowCount",
			["widget"]   = EEex_Options_EditWidget.new({
				["maxCharacters"] = 2,
				["number"]        = true,
			}),
		}),
	},
} end)

-------------
-- Globals --
-------------

B3EffectMenu_Private_Menu_Enabled       = false
B3EffectMenu_Private_Menu_KeybindActive = false

-----------------------
-- Hooks / Listeners --
-----------------------

B3EffectMenu_Private_OldIsActorTooltipDisabled = EEex_Sprite_Hook_CheckSuppressTooltip
EEex_Sprite_Hook_CheckSuppressTooltip = function()
	return B3EffectMenu_Private_Menu_Enabled or B3EffectMenu_Private_OldIsActorTooltipDisabled()
end

EEex_Menu_AddMainFileLoadedListener(function()

	EEex_Menu_LoadFile("B3EffMen")

	local actionbarMenu = EEex_Menu_Find("WORLD_ACTIONBAR")

	local oldActionbarOnOpen = EEex_Menu_GetItemFunction(actionbarMenu.reference_onOpen)
	EEex_Menu_SetItemFunction(actionbarMenu.reference_onOpen, function()
		local openResult = oldActionbarOnOpen()
		B3EffectMenu_Private_Open()
		return openResult
	end)

	local oldActionbarOnClose = EEex_Menu_GetItemFunction(actionbarMenu.reference_onClose)
	EEex_Menu_SetItemFunction(actionbarMenu.reference_onClose, function()
		B3EffectMenu_Private_Close()
		return oldActionbarOnClose()
	end)
end)

EEex_Key_AddReleasedListener(function()
	B3EffectMenu_Private_Menu_KeybindActive = false
end)

----------
-- Main --
----------

function B3EffectMenu_Private_Init()
	B3EffectMenu_Private_CurrentActorID = nil
	B3EffectMenu_Private_EnableDelay = -1
	B3EffectMenu_Private_Menu_Enabled = false
end
B3EffectMenu_Private_Init()

function B3EffectMenu_Private_Open()
	B3EffectMenu_Private_Init()
	Infinity_PushMenu("B3EffectMenu_Menu")
end

function B3EffectMenu_Private_Close()
	Infinity_PopMenu("B3EffectMenu_Menu")
	B3EffectMenu_Private_Init()
end

function B3EffectMenu_Private_DoLayout()
	local rowTotal = 35 * B3EffectMenu_Private_RowCount:get()
	Infinity_SetArea("B3EffectMenu_Menu_Background", nil, nil, nil, rowTotal + 20)
	Infinity_SetArea("B3EffectMenu_Menu_List", nil, nil, nil, rowTotal)
end

function B3EffectMenu_Private_LaunchInfo()

	B3EffectMenu_Private_DoLayout()

	B3EffectMenu_Private_Menu_List_Table = {}
	local sprite = EEex_GameObject_Get(B3EffectMenu_Private_CurrentActorID)

	local pos = sprite.m_pos
	local screenX, screenY = EEex_Menu_TranslateXYFromGame(pos.x, pos.y)
	Infinity_SetOffset("B3EffectMenu_Menu", screenX, screenY)

	local seenSpells = {}

	EEex_Utility_IterateCPtrList(sprite.m_timedEffectList, function(effect)

		-- Only process spell effects
		local sourceType = effect.m_sourceType
		if sourceType == 2 then return end -- Continue EEex_Utility_IterateCPtrList

		local sourceResref = effect.m_sourceRes:get()
		-- Sanity check
		if sourceResref == "" then return end -- Continue EEex_Utility_IterateCPtrList

		-- Already added this spell
		if seenSpells[sourceResref] then return end -- Continue EEex_Utility_IterateCPtrList

		-- Skip completely permanent spells (to hide behind-the-scenes spells)
		local m_durationType = effect.m_durationType
		if m_durationType == 9 then return end -- Continue EEex_Utility_IterateCPtrList

		seenSpells[sourceResref] = true

		local spellHeader = EEex_Resource_Demand(sourceResref, "SPL")
		-- Sanity check
		if not spellHeader then return end -- Continue EEex_Utility_IterateCPtrList

		local casterLevel = effect.m_casterLevel
		if casterLevel <= 0 then casterLevel = 1 end

		local abilityData = spellHeader:getAbilityForLevel(casterLevel)

		-- The caster shouldn't have been able to cast this spell, just use the first ability
		if not abilityData then
			abilityData = spellHeader:getAbility(0)
			-- The spell didn't even have an ability...
			if not abilityData then return end -- Continue EEex_Utility_IterateCPtrList
		end

		local spellName = Infinity_FetchString(spellHeader.genericName)
		if spellName == "" then spellName = "(No Name)" end

		-- Skip no-icon spells (to hide behind-the-scenes spells)
		local spellIcon = abilityData.quickSlotIcon:get()
		if spellIcon == "" then return end -- Continue EEex_Utility_IterateCPtrList

		local listData = {
			["bam"] = spellIcon,
			["text"] = spellName,
		}

		table.insert(B3EffectMenu_Private_Menu_List_Table, listData)
	end)

	EEex_Utility_AlphanumericSortTable(B3EffectMenu_Private_Menu_List_Table, function(t) return t.text end)
	B3EffectMenu_Private_EnableDelay = 0
end

function B3EffectMenu_Private_ClearWorldTooltip()
	EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_tempCursor = 4
end

------------------
-- UI Functions --
------------------

-----------------------
-- B3EffectMenu_Menu --
-----------------------

function B3EffectMenu_Private_Menu_Tick()

	if worldScreen ~= e:GetActiveEngine() then return end

	if B3EffectMenu_Private_EnableDelay > -1 then
		B3EffectMenu_Private_EnableDelay = B3EffectMenu_Private_EnableDelay + 1
		if B3EffectMenu_Private_EnableDelay == 1 then
			B3EffectMenu_Private_Menu_Enabled = true
			B3EffectMenu_Private_ClearWorldTooltip()
			B3EffectMenu_Private_EnableDelay = -1
		end
	end

	local object = EEex_GameObject_GetUnderCursor()
	if B3EffectMenu_Private_Menu_KeybindActive and object and object:isSprite() then
		if object.m_id ~= B3EffectMenu_Private_CurrentActorID then
			B3EffectMenu_Private_CurrentActorID = object.m_id
			B3EffectMenu_Private_LaunchInfo()
		end
	elseif (not B3EffectMenu_Private_Menu_KeybindActive) or (not EEex_Menu_IsCursorWithin("B3EffectMenu_Menu", "B3EffectMenu_Menu_Background")) then
		B3EffectMenu_Private_Init()
	end
end
