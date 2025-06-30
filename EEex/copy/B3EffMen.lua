
--------------------
-- Manual Options --
--------------------

B3EffectMenu_Key = EEex_Key_GetFromName("Left Shift")

-------------
-- Options --
-------------

B3EffectMenu_RowCount = nil

B3EffectMenu_Options = {
	{
		EEex_Options_Option.new({
			["id"]      = "B3EffectMenu_RowCount",
			["name"]    = "Row Count",
			["default"] = 4,
			["type"] = EEex_Options_EditType.new({
				["maxCharacters"] = 2,
				["number"]        = true,
			}),
			["accessor"] = EEex_Options_ClampedAccessor.new({
				["accessor"] = EEex_Options_GlobalAccessor.new({ ["name"] = "B3EffectMenu_RowCount" }),
				["min"]      = 1,
				["max"]      = 99,
			}),
			["storage"] = EEex_Options_IntegerINIStorage.new({ ["section"] = "EEex", ["key"] = "Effect Menu Row Count" }),
		}),
	},
}

EEex_GameState_AddInitializedListener(function()
	EEex_Options_AddTab("Effect Menu", B3EffectMenu_Options)
end)

-------------
-- Globals --
-------------

B3EffectMenu_Menu_Enabled = false

-----------------------
-- Hooks / Listeners --
-----------------------

B3EffectMenu_OldIsActorTooltipDisabled = EEex_Sprite_Hook_CheckSuppressTooltip
EEex_Sprite_Hook_CheckSuppressTooltip = function()
	return B3EffectMenu_Menu_Enabled or B3EffectMenu_OldIsActorTooltipDisabled()
end

EEex_Menu_AddMainFileLoadedListener(function()

	EEex_Menu_LoadFile("B3EffMen")

	local actionbarMenu = EEex_Menu_Find("WORLD_ACTIONBAR")

	local oldActionbarOnOpen = EEex_Menu_GetItemFunction(actionbarMenu.reference_onOpen)
	EEex_Menu_SetItemFunction(actionbarMenu.reference_onOpen, function()
		local openResult = oldActionbarOnOpen()
		B3EffectMenu_Open()
		return openResult
	end)

	local oldActionbarOnClose = EEex_Menu_GetItemFunction(actionbarMenu.reference_onClose)
	EEex_Menu_SetItemFunction(actionbarMenu.reference_onClose, function()
		B3EffectMenu_Close()
		return oldActionbarOnClose()
	end)
end)

----------
-- Main --
----------

function B3EffectMenu_Init()
	B3EffectMenu_CurrentActorID = nil
	B3EffectMenu_EnableDelay = -1
	B3EffectMenu_Menu_Enabled = false
end
B3EffectMenu_Init()

function B3EffectMenu_Open()
	B3EffectMenu_Init()
	Infinity_PushMenu("B3EffectMenu_Menu")
end

function B3EffectMenu_Close()
	Infinity_PopMenu("B3EffectMenu_Menu")
	B3EffectMenu_Init()
end

function B3EffectMenu_DoLayout()
	local rowTotal = 35 * B3EffectMenu_RowCount
	Infinity_SetArea("B3EffectMenu_Menu_Background", nil, nil, nil, rowTotal + 20)
	Infinity_SetArea("B3EffectMenu_Menu_List", nil, nil, nil, rowTotal)
end

function B3EffectMenu_LaunchInfo()

	B3EffectMenu_DoLayout()

	B3EffectMenu_Menu_List_Table = {}
	local sprite = EEex_GameObject_Get(B3EffectMenu_CurrentActorID)

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

		table.insert(B3EffectMenu_Menu_List_Table, listData)
	end)

	-- Alphanumeric sort
	table.sort(B3EffectMenu_Menu_List_Table, function(a, b)
		local conv = function(s)
			local res, dot = "", ""
			for n, m, c in tostring(s):gmatch("(0*(%d*))(.?)") do
				if n == "" then
					dot, c = "", dot..c
				else
					res = res..(dot == "" and ("%03d%s"):format(#m, m) or "."..n)
					dot, c = c:match("(%.?)(.*)")
				end
				res = res..c:gsub(".", "\0%0")
			end
			return res
		end
		local ca, cb = conv(a.tooltip), conv(b.tooltip)
		return (a.text <= b.text) and (ca <= cb and a.text < b.text)
	end)

	B3EffectMenu_EnableDelay = 0
end

function B3EffectMenu_ClearWorldTooltip()
	EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_tempCursor = 4
end

------------------
-- UI Functions --
------------------

-----------------------
-- B3EffectMenu_Menu --
-----------------------

function B3EffectMenu_Menu_Tick()

	if worldScreen ~= e:GetActiveEngine() then return end

	if B3EffectMenu_EnableDelay > -1 then
		B3EffectMenu_EnableDelay = B3EffectMenu_EnableDelay + 1
		if B3EffectMenu_EnableDelay == 1 then
			B3EffectMenu_Menu_Enabled = true
			B3EffectMenu_ClearWorldTooltip()
			B3EffectMenu_EnableDelay = -1
		end
	end

	local object = EEex_GameObject_GetUnderCursor()
	if EEex_Key_IsDown(B3EffectMenu_Key) and object and object:isSprite() then
		if object.m_id ~= B3EffectMenu_CurrentActorID then
			B3EffectMenu_CurrentActorID = object.m_id
			B3EffectMenu_LaunchInfo()
		end
	elseif (not EEex_Key_IsDown(B3EffectMenu_Key)) or (not EEex_Menu_IsCursorWithin("B3EffectMenu_Menu", "B3EffectMenu_Menu_Background")) then
		B3EffectMenu_Init()
	end
end
