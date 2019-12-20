
-------------
-- Options --
-------------

B3EffectMenu_Key = EEex_GetKeyFromName("Left Shift")
B3EffectMenu_RowCount = 4

-----------------------
-- Hooks / Listeners --
-----------------------

B3EffectMenu_OldIsActorTooltipDisabled = EEex_IsActorTooltipDisabled
EEex_IsActorTooltipDisabled = function()
	return B3EffectMenu_Menu_Enabled or B3EffectMenu_OldIsActorTooltipDisabled()
end

function B3EffectMenu_LoadMenu()

	EEex_LoadMenuFile("B3_EfMen")

	local rowTotal = 35 * B3EffectMenu_RowCount
	Infinity_SetArea("B3EffectMenu_Menu_Background", nil, nil, nil, rowTotal + 20)
	Infinity_SetArea("B3EffectMenu_Menu_List", nil, nil, nil, rowTotal)

	local actionbarOnOpen = EEex_GetMenuVariantFunction("WORLD_ACTIONBAR", "onopen")
	EEex_SetMenuVariantFunction("WORLD_ACTIONBAR", "onopen", function()
		local openResult = actionbarOnOpen()
		B3EffectMenu_Open()
		return openResult
	end)

	local actionbarOnClose = EEex_GetMenuVariantFunction("WORLD_ACTIONBAR", "onclose")
	EEex_SetMenuVariantFunction("WORLD_ACTIONBAR", "onclose", function()
		B3EffectMenu_Close()
		return actionbarOnClose()
	end)

end
EEex_AddUIMenuLoadListener(B3EffectMenu_LoadMenu)

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

function B3EffectMenu_LaunchInfo()

	B3EffectMenu_Menu_List_Table = {}
	local share = EEex_GetActorShare(B3EffectMenu_CurrentActorID)

	local actorX, actorY = EEex_GetActorLocation(B3EffectMenu_CurrentActorID)
	local screenX, screenY = EEex_TranslateGameXY(actorX, actorY)
	Infinity_SetOffset("B3EffectMenu_Menu", screenX, screenY)

	local seenSpells = {}

	EEex_IterateCPtrList(share + 0x33A8, function(CGameEffect)

		-- Only process spell effects
		local sourceType = EEex_ReadDword(CGameEffect + 0x8C)
		if sourceType == 2 then return end -- Continue EEex_IterateCPtrList

		local sourceResref = EEex_ReadLString(CGameEffect + 0x90, 0x8)
		-- Sanity check
		if sourceResref == "" then return end -- Continue EEex_IterateCPtrList

		-- Already added this spell
		if seenSpells[sourceResref] then return end -- Continue EEex_IterateCPtrList

		-- Skip completely permanent spells (to hide behind-the-scenes spells)
		local m_durationType = EEex_ReadDword(CGameEffect + 0x20)
		if m_durationType == 9 then return end -- Continue EEex_IterateCPtrList

		seenSpells[sourceResref] = true

		local spellData = EEex_DemandResData(sourceResref, "SPL")
		-- Sanity check
		if spellData == 0x0 then return end -- Continue EEex_IterateCPtrList

		local casterLevel = EEex_ReadDword(CGameEffect + 0xC4)
		if casterLevel <= 0 then casterLevel = 1 end

		local abilityData = EEex_GetSpellAbilityDataLevel(sourceResref, casterLevel)

		-- The caster shouldn't have been able to cast this spell, just use the first ability
		if abilityData == 0x0 then
			abilityData = EEex_GetSpellAbilityDataIndex(sourceResref, 0)
			-- The spell didn't even have an ability...
			if abilityData == 0x0 then return end -- Continue EEex_IterateCPtrList
		end

		local spellName = Infinity_FetchString(EEex_ReadDword(spellData + 0x8))
		if spellName == "" then spellName = "(No Name)" end

		-- Skip no-icon spells (to hide behind-the-scenes spells)
		local spellIcon = EEex_ReadLString(abilityData + 0x4, 0x8)
		if spellIcon == "" then return end -- Continue EEex_IterateCPtrList

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
	local g_pBaldurChitin = EEex_ReadDword(EEex_Label("g_pBaldurChitin")) -- (CBaldurChitin)
	local m_pObjectGame = EEex_ReadDword(g_pBaldurChitin + EEex_Label("CBaldurChitin::m_pObjectGame")) -- (CInfGame)
	EEex_WriteByte(m_pObjectGame + 0x2569, 4) -- m_tempCursor
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

	local actorIDCursor = EEex_GetActorIDCursor()
	if EEex_IsKeyDown(B3EffectMenu_Key) and EEex_IsSprite(actorIDCursor) then
		if actorIDCursor ~= B3EffectMenu_CurrentActorID then
			B3EffectMenu_CurrentActorID = actorIDCursor
			B3EffectMenu_LaunchInfo()
		end
	elseif (not EEex_IsKeyDown(B3EffectMenu_Key)) or (not EEex_IsCursorWithinMenu("B3EffectMenu_Menu", "B3EffectMenu_Menu_Background")) then
		B3EffectMenu_Init()
	end

end
