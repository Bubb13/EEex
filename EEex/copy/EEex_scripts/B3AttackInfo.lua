
-------------
-- Options --
-------------

EEex_Options_Register("B3AttackInfo_Enable", EEex_Options_Option.new({
	["default"]  = 1,
	["type"]     = EEex_Options_ToggleType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Attack Info" }),
	["onChange"] = function(self, oldValue) B3AttackInfo_SetEnabled(self:get() ~= 0) end,
}))

B3AttackInfo_Private_FontPoint = EEex_Options_Register("B3AttackInfo_FontPoint", EEex_Options_Option.new({
	["default"]  = 11,
	["type"]     = EEex_Options_EditType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 1, ["max"] = 99 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Attack Info Module: Font Point" }),
}))

B3AttackInfo_Private_ImmunityDisplayType = EEex_Options_Register("B3AttackInfo_ImmunityDisplayType", EEex_Options_Option.new({
	["default"]  = 0,
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 2 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Attack Info Module: Immunity Display Type" }),
}))

B3AttackInfo_Private_ImmunityDisplayTypeShowColorKey = EEex_Options_Register("B3AttackInfo_ImmunityDisplayType_ShowColorKey", EEex_Options_Option.new({
	["default"]  = 0,
	["type"]     = EEex_Options_ToggleType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Attack Info Module: Immunity Display Type Show Color Key" }),
}))

EEex_Options_Register("B3AttackInfo_ReverseKeybind", EEex_Options_Option.new({
	["default"]  = EEex_Options_UnmarshalKeybind("Left Alt|Down"),
	["type"]     = EEex_Options_KeybindType.new({
		["lockedFireType"] = EEex_Keybinds_FireType.DOWN,
		["callback"]       = function() B3AttackInfo_Private_Menu_Reversed = true end,
	}),
	["accessor"] = EEex_Options_KeybindAccessor.new({ ["keybindID"] = "B3AttackInfo_ReverseKeybind" }),
	["storage"]  = EEex_Options_KeybindLuaStorage.new({ ["section"] = "EEex", ["key"] = "Attack Info Module: Reverse Keybind" }),
}))

B3AttackInfo_Private_ShowColumnHeaders = EEex_Options_Register("B3AttackInfo_ShowColumnHeaders", EEex_Options_Option.new({
	["default"]  = 1,
	["type"]     = EEex_Options_ToggleType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Attack Info Module: Show Column Headers" }),
}))

B3AttackInfo_Private_HideUnusedOffhandHeader = EEex_Options_Register("B3AttackInfo_HideUnusedOffhandHeader", EEex_Options_Option.new({
	["default"]  = 1,
	["type"]     = EEex_Options_ToggleType.new(),
	["accessor"] = EEex_Options_ClampedAccessor.new({ ["min"] = 0, ["max"] = 1 }),
	["storage"]  = EEex_Options_NumberLuaStorage.new({ ["section"] = "EEex", ["key"] = "Attack Info Module: Hide Unused Offhand Header" }),
}))

EEex_Options_AddTab("EEex_Options_TRANSLATION_AttackInfo_TabTitle", function() return {
	{
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "B3AttackInfo_Enable",
			["label"]       = "EEex_Options_TRANSLATION_AttackInfo_Enable",
			["description"] = "EEex_Options_TRANSLATION_AttackInfo_Enable_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "B3AttackInfo_FontPoint",
			["label"]       = "EEex_Options_TRANSLATION_AttackInfo_FontPoint",
			["description"] = "EEex_Options_TRANSLATION_AttackInfo_FontPoint_Description",
			["widget"]      = EEex_Options_EditWidget.new({
				["maxCharacters"] = 2,
				["number"]        = true,
			}),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "B3AttackInfo_ImmunityDisplayType",
			["label"]       = "EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType",
			["description"] = "EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_Description",
			["widget"]      = EEex_Options_HorizontalMultiToggleWidget.new({
				["toggles"] = {
					{
						["label"] = "EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_Color",
						["data"] = { ["toggleValue"] = 0 },
					},
					{
						["label"] = "EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_None",
						["data"] = { ["toggleValue"] = 1 },
					},
					{
						["label"] = "EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_Text",
						["data"] = { ["toggleValue"] = 2 },
					},
				},
			}),
			["subOptions"] = {
				EEex_Options_DisplayEntry.new({
					["optionID"]    = "B3AttackInfo_ImmunityDisplayType_ShowColorKey",
					["label"]       = "EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_ShowColorKey",
					["description"] = "EEex_Options_TRANSLATION_AttackInfo_ImmunityDisplayType_ShowColorKey_Description",
					["widget"]      = EEex_Options_ToggleWidget.new(),
				}),
			},
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "B3AttackInfo_ReverseKeybind",
			["label"]       = "EEex_Options_TRANSLATION_AttackInfo_ReverseKeybind",
			["description"] = "EEex_Options_TRANSLATION_AttackInfo_ReverseKeybind_Description",
			["widget"]      = EEex_Options_KeybindWidget.new(),
		}),
		EEex_Options_DisplayEntry.new({
			["optionID"]    = "B3AttackInfo_ShowColumnHeaders",
			["label"]       = "EEex_Options_TRANSLATION_AttackInfo_ShowColumnHeaders",
			["description"] = "EEex_Options_TRANSLATION_AttackInfo_ShowColumnHeaders_Description",
			["widget"]      = EEex_Options_ToggleWidget.new(),
			["subOptions"]  = {
				EEex_Options_DisplayEntry.new({
					["optionID"]    = "B3AttackInfo_HideUnusedOffhandHeader",
					["label"]       = "EEex_Options_TRANSLATION_AttackInfo_HideUnusedOffhandHeader",
					["description"] = "EEex_Options_TRANSLATION_AttackInfo_HideUnusedOffhandHeader_Description",
					["widget"]      = EEex_Options_ToggleWidget.new(),
				}),
			}
		}),
	},
} end)

-------------
-- Globals --
-------------

B3AttackInfo_Private_Enabled = false

-------------
-- General --
-------------

-- @bubb_doc { B3AttackInfo_SetEnabled }
--
-- @summary: Temporarily changes the enable state of the attack information popup.
--
-- @note: To persist this change, instead modify the ``B3AttackInfo_Enable`` option.
--
-- @param { enabled / type=boolean }: The enable / disable state to set.

function B3AttackInfo_SetEnabled(enabled)
	B3AttackInfo_Private_Enabled = enabled
	B3AttackInfo_Private_Menu_Ticker_SetOpen(B3AttackInfo_Private_Menu_Ticker_ShouldBeOpen and enabled)
end

----------
-- Misc --
----------

function B3AttackInfo_Private_GetWeaponHitChance(sourceSprite, targetSprite, leftHand)

	local sourceSpriteEquipment = sourceSprite.m_equipment

	local nSourceSpriteSelectedWeapon
	local nSourceSpriteSelectedWeaponAbility
	local sourceSpriteSelectedWeapon

	if leftHand then
		nSourceSpriteSelectedWeapon = 9
		nSourceSpriteSelectedWeaponAbility = 0
		sourceSpriteSelectedWeapon = sourceSpriteEquipment.m_items:get(nSourceSpriteSelectedWeapon)
	else
		nSourceSpriteSelectedWeapon = sourceSpriteEquipment.m_selectedWeapon
		nSourceSpriteSelectedWeaponAbility = sourceSpriteEquipment.m_selectedWeaponAbility
		sourceSpriteSelectedWeapon = sourceSpriteEquipment.m_items:get(nSourceSpriteSelectedWeapon)
	end

	local isImmune = EEex.IsImmuneToWeapon(sourceSprite, targetSprite, nSourceSpriteSelectedWeapon, sourceSpriteSelectedWeapon, nSourceSpriteSelectedWeaponAbility)
	local hitChance, reasoning = EEex.GetWeaponHitChance(sourceSprite, targetSprite, sourceSpriteSelectedWeapon, nSourceSpriteSelectedWeaponAbility, leftHand)
	return hitChance, isImmune, reasoning
end

------------------------------
-- B3AttackInfo_Menu_Ticker --
------------------------------

B3AttackInfo_Private_Menu_Ticker_IsOpen = false
B3AttackInfo_Private_Menu_Ticker_ShouldBeOpen = false

function B3AttackInfo_Private_Layout(targetSprite)

	-----------------------------------------------------------------------
	--     Filter and sort sprites to display attack information for     --
	-----------------------------------------------------------------------

	local selectedSprites = {}
	EEex_Sprite_IterateSelected(function(sprite)
		if EEex_UDEqual(sprite, targetSprite) then return end
		table.insert(selectedSprites, sprite)
	end)

	if selectedSprites[1] == nil then
		return false
	end

	EEex_Utility_AlphanumericSortTable(selectedSprites, function(sprite)
		return sprite:getName()
	end)

	--------------------------
	--     Read options     --
	--------------------------

	local fontPoint                     = B3AttackInfo_Private_FontPoint:get()
	local immuneDisplayType             = B3AttackInfo_Private_ImmunityDisplayType:get()
	local immuneDisplayTypeShowColorKey = B3AttackInfo_Private_ImmunityDisplayTypeShowColorKey:get() ~= 0
	local showColumnHeaders             = B3AttackInfo_Private_ShowColumnHeaders:get() ~= 0
	local hideUnusedOffhandHeader       = B3AttackInfo_Private_HideUnusedOffhandHeader:get() ~= 0

	------------------------------
	--     Layout constants     --
	------------------------------

	local spaceW, spaceH = EEex_Menu_GetTextWidthHeight(" ", styles["normal"].font, fontPoint, styles["normal"].useFontZoom)

	-----------
	-- Popup --
	-----------

	local popupLeftSideAdjust  = 6
	local popupRightSideAdjust = 20

	----------------
	-- Background --
	----------------

	local backgroundPad = 12

	------------
	-- Header --
	------------

	local headerLabelPadLeft           = 6
	local immuneColorKeySeparatorPad   = 5
	local immuneColorKeySeparatorW     = 2
	local headerHorizontalSepPadTop    = 5
	local headerHorizontalSepH         = 2
	local headerHorizontalSepPadBottom = 8

	---------------
	-- List rows --
	---------------

	local rowHeightPad = 0

	------------------
	-- List columns --
	------------------

	local divider1ColumnW       = 3
	local divider2ColumnPadLeft = spaceW
	local divider2ColumnW       = 2
	local divider3ColumnPadLeft = spaceW
	local divider3ColumnW       = 2

	local nameColumnIndex       = 1
	local mainHandColumnIndex   = 2
	local offHandColumnIndex    = 3

	local divider1ColumnIndex   = 2
	local divider2ColumnIndex   = 3
	local divider3ColumnIndex   = 4

	-----------------------------------------------
	--     Calculate header label dimensions     --
	-----------------------------------------------

	local otherLabelText

	if B3AttackInfo_Private_Menu_Reversed then
		B3AttackInfo_Private_Menu_Label = uiStrings["EEex_TRANSLATION_AttackInfo_TargetAttacksParty"]
		otherLabelText = uiStrings["EEex_TRANSLATION_AttackInfo_PartyAttacksTarget"]
	else
		B3AttackInfo_Private_Menu_Label = uiStrings["EEex_TRANSLATION_AttackInfo_PartyAttacksTarget"]
		otherLabelText = uiStrings["EEex_TRANSLATION_AttackInfo_TargetAttacksParty"]
	end

	-- `labelW` used in layout
	local labelW, labelH = EEex_Menu_GetTextWidthHeight(B3AttackInfo_Private_Menu_Label, styles["normal"].font, fontPoint, styles["normal"].useFontZoom)
	local otherLabelW, otherLabelH = EEex_Menu_GetTextWidthHeight(otherLabelText, styles["normal"].font, fontPoint, styles["normal"].useFontZoom)

	B3AttackInfo_Private_Menu_ShowImmuneColorKey = immuneDisplayType == 0 and immuneDisplayTypeShowColorKey

	-- `immuneColorKeyLabelW` and `immuneColorKeyLabelH` used in layout
	local immuneColorKeyLabelW = 0
	local immuneColorKeyLabelH = 0

	if B3AttackInfo_Private_Menu_ShowImmuneColorKey then
		immuneColorKeyLabelW, immuneColorKeyLabelH = EEex_Menu_GetTextWidthHeight(uiStrings["EEex_TRANSLATION_AttackInfo_ImmuneColorKey"], styles["normal"].font, fontPoint, styles["normal"].useFontZoom)
	end

	-- `maxHeaderLabelW` and `maxHeaderLabelH` used in layout
	local maxHeaderLabelW = math.max(labelW, otherLabelW)
	local maxHeaderLabelH = math.max(labelH, otherLabelH, immuneColorKeyLabelH)

	--------------------------------
	--     Layout header icon     --
	--------------------------------

	-- `headerIconW` used in layout
	local headerIconX = backgroundPad
	local headerIconY = backgroundPad
	local headerIconW = maxHeaderLabelH
	local headerIconH = maxHeaderLabelH

	Infinity_SetArea("B3AttackInfo_Menu_Icon", headerIconX, headerIconY, headerIconW, headerIconH)

	-- `afterIconX` used in layout
	local afterIconX = backgroundPad + headerIconW + headerLabelPadLeft

	---------------------------------
	--     Layout header label     --
	---------------------------------

	local headerLabelX = afterIconX
	local headerLabelY = backgroundPad
	local headerLabelW = labelW
	local headerLabelH = maxHeaderLabelH

	B3AttackInfo_Private_Menu_LabelUD.text.point = fontPoint
	Infinity_SetArea("B3AttackInfo_Menu_Label", headerLabelX, headerLabelY, headerLabelW, headerLabelH)

	-- `afterHeaderLabelX` used in layout
	local afterHeaderLabelX = afterIconX + maxHeaderLabelW

	--------------------------------------------
	--     Layout header immune color key     --
	--------------------------------------------

	local immuneColorKeyFillW = 0

	if B3AttackInfo_Private_Menu_ShowImmuneColorKey then

		----------------------------------------------------
		-- B3AttackInfo_Menu_ImmuneColorKeyLabelSeparator --
		----------------------------------------------------

		local immuneColorKeySeparatorX = afterHeaderLabelX + immuneColorKeySeparatorPad
		local immuneColorKeySeparatorY = backgroundPad
		local immuneColorKeySeparatorH = maxHeaderLabelH

		Infinity_SetArea("B3AttackInfo_Menu_ImmuneColorKeyLabelSeparator", immuneColorKeySeparatorX, immuneColorKeySeparatorY, immuneColorKeySeparatorW, immuneColorKeySeparatorH)

		-------------------------------------------
		-- B3AttackInfo_Menu_ImmuneColorKeyLabel --
		-------------------------------------------

		local immuneColorKeyLabelX = immuneColorKeySeparatorX + immuneColorKeySeparatorW + immuneColorKeySeparatorPad
		local immuneColorKeyLabelY = backgroundPad
		local immuneColorKeyLabelH = maxHeaderLabelH

		B3AttackInfo_Private_Menu_ImmuneColorKeyLabelUD.text.point = fontPoint
		Infinity_SetArea("B3AttackInfo_Menu_ImmuneColorKeyLabel", immuneColorKeyLabelX, immuneColorKeyLabelY, immuneColorKeyLabelW, immuneColorKeyLabelH)

		--------------------------------------
		-- B3AttackInfo_Menu_ImmuneColorKey --
		--------------------------------------

		local immuneColorKeyFillH = maxHeaderLabelH * 2 / 3
		immuneColorKeyFillW = immuneColorKeyFillH

		local immuneColorKeyFillX = immuneColorKeyLabelX + immuneColorKeyLabelW
		local immuneColorKeyFillY = immuneColorKeyLabelY + (immuneColorKeyLabelH - immuneColorKeyFillH) / 2

		Infinity_SetArea("B3AttackInfo_Menu_ImmuneColorKey", immuneColorKeyFillX, immuneColorKeyFillY, immuneColorKeyFillW, immuneColorKeyFillH)
	else
		immuneColorKeySeparatorPad = 0
		immuneColorKeySeparatorW = 0
	end

	-- `totalHeaderW` used in layout
	local totalHeaderW = (
		headerIconW
		+ headerLabelPadLeft + maxHeaderLabelW
		+ immuneColorKeySeparatorPad + immuneColorKeySeparatorW + immuneColorKeySeparatorPad + immuneColorKeyLabelW
		+ immuneColorKeyFillW
	)

	-------------------------
	--     Layout list     --
	-------------------------

	--------------------------------------------------
	-- Calculate list column widths and line height --
	--------------------------------------------------

	-- `columnWidths` used in layout
	local columnWidths = {}
	for i = 1, B3AttackInfo_Private_Menu_InfoListColumnUDsSize do
		columnWidths[i] = 0
	end

	B3AttackInfo_Private_Menu_InfoList_Table = {}
	local infoListInsertI = showColumnHeaders and 2 or 1

	-- `tallestRowHeight` used in layout
	local tallestRowHeight = 0

	local calculate = function(columnsText, insertFunc)

		---------------------------------
		-- Calculate column dimensions --
		---------------------------------

		local columnsDimensions = {}
		local infoListTableEntry = {}
		local infoListTableEntryI = 1

		for i, columnText in ipairs(columnsText) do

			if columnText ~= false then
				local columnW, columnH = EEex_Menu_GetTextWidthHeight(columnText, styles["normal"].font, fontPoint, styles["normal"].useFontZoom)
				columnsDimensions[i] = { columnW, columnH }
				infoListTableEntry[infoListTableEntryI] = columnText
			else
				columnsDimensions[i] = false
			end

			infoListTableEntryI = infoListTableEntryI + 1
		end

		if insertFunc ~= nil then
			insertFunc(infoListTableEntry)
		end

		-----------------------
		-- Apply column pads --
		-----------------------

		local divider1ColumnDimensions = columnsDimensions[divider1ColumnIndex]
		divider1ColumnDimensions[1] = divider1ColumnDimensions[1] + divider1ColumnW

		local divider2ColumnDimensions = columnsDimensions[divider2ColumnIndex]
		if divider2ColumnDimensions[1] > 0 then
			divider2ColumnDimensions[1] = divider2ColumnPadLeft + divider2ColumnW + divider2ColumnDimensions[1]
		end

		---------------------------------------------
		-- Calculate max column widths and heights --
		---------------------------------------------

		local tallestColumnHeight = 0

		for i, columnDimensions in ipairs(columnsDimensions) do

			if columnDimensions ~= false then

				if columnDimensions[1] > columnWidths[i] then
					columnWidths[i] = columnDimensions[1]
				end

				if columnDimensions[2] > tallestColumnHeight then
					tallestColumnHeight = columnDimensions[2]
				end
			end
		end

		if tallestColumnHeight > tallestRowHeight then
			tallestRowHeight = tallestColumnHeight
		end
	end

	local formatChanceStr = function(chance, immune, isRightHand)
		if immune then
			local colorStr = (immuneDisplayType == 0 and immune) and "^0xFF2B4BFF" or ""
			local chanceStr = immuneDisplayType == 2 and "Immune" or string.format("%d%%", chance)
			return string.format(" %s%s", colorStr, chanceStr)
		else
			return string.format(" %d%%", chance)
		end
	end

	local insertIntoList = function(infoListTableEntry)
		B3AttackInfo_Private_Menu_InfoList_Table[infoListInsertI] = infoListTableEntry
		infoListInsertI = infoListInsertI + 1
	end

	local calculateSprites = function(reverse, dummy)

		local hadOffhand = false

		for _, selectedSprite in ipairs(selectedSprites) do

			----------------------------
			-- Calculate columns text --
			----------------------------

			local rightHandChance, rightHandIneffective, rightHandReasoning
			if reverse then
				rightHandChance, rightHandIneffective, rightHandReasoning = B3AttackInfo_Private_GetWeaponHitChance(targetSprite, selectedSprite, false) -- (Alt) Target vs Party Member
			else
				rightHandChance, rightHandIneffective, rightHandReasoning = B3AttackInfo_Private_GetWeaponHitChance(selectedSprite, targetSprite, false) -- Party Member vs Target
			end

			local leftHandString = ""

			if EEex.CanAttackWithLeftHand(reverse and targetSprite or selectedSprite) then

				local leftHandChance, leftHandIneffective, leftHandReasoning
				if reverse then
					leftHandChance, leftHandIneffective, leftHandReasoning = B3AttackInfo_Private_GetWeaponHitChance(targetSprite, selectedSprite, true) -- (Alt) Target vs Party Member
				else
					leftHandChance, leftHandIneffective, leftHandReasoning = B3AttackInfo_Private_GetWeaponHitChance(selectedSprite, targetSprite, true) -- Party Member vs Target
				end

				leftHandString = formatChanceStr(leftHandChance, leftHandIneffective, false)
				hadOffhand = true
			end

			local columnsText = {
				[nameColumnIndex]     = string.format("%s ", selectedSprite:getName()),
				[mainHandColumnIndex] = formatChanceStr(rightHandChance, rightHandIneffective, true),
				[offHandColumnIndex]  = leftHandString,
			}

			calculate(columnsText, not dummy and insertIntoList or nil)
		end

		return hadOffhand
	end

	local normalHadOffhand = calculateSprites(false, B3AttackInfo_Private_Menu_Reversed)
	local reverseHadOffhand = calculateSprites(true, not B3AttackInfo_Private_Menu_Reversed)

	if showColumnHeaders then

		local currentViewHadOffhand = (not B3AttackInfo_Private_Menu_Reversed and normalHadOffhand) or (B3AttackInfo_Private_Menu_Reversed and reverseHadOffhand)

		local mainhandLabel = uiStrings["EEex_TRANSLATION_AttackInfo_Mainhand"]
		local offhandLabel = uiStrings["EEex_TRANSLATION_AttackInfo_Offhand"]

		local mainhandHeader = string.format(" %s", mainhandLabel)
		local offhandHeader = string.format(" %s", offhandLabel)

		local addColumnHeader = function(infoListTableEntry)
			B3AttackInfo_Private_Menu_InfoList_Table[1] = infoListTableEntry
		end

		if not hideUnusedOffhandHeader or currentViewHadOffhand then
			calculate({"", mainhandHeader, offhandHeader}, addColumnHeader)
		else
			calculate({"", mainhandHeader, ""}, addColumnHeader)
			if normalHadOffhand or reverseHadOffhand then
				calculate({"", mainhandHeader, offhandHeader}, nil)
			end
		end
	end

	--------------------------
	-- Calculate row height --
	--------------------------

	-- `rowHeight` used in layout
	local rowHeight = tallestRowHeight + rowHeightPad

	B3AttackInfo_Private_Menu_InfoListUD.list.rowheight = rowHeight

	-------------------------
	-- Calculate row width --
	-------------------------

	-- `rowWidth` used in layout
	local rowWidth = 0
	for _, columnWidth in ipairs(columnWidths) do
		rowWidth = rowWidth + columnWidth
	end

	-------------------------------------------
	-- Calculate total list width and height --
	-------------------------------------------

	local divider3ColumnNeededW = divider3ColumnPadLeft + divider3ColumnW
	local divider3NeededRowWidth = rowWidth + divider3ColumnNeededW

	if totalHeaderW >= divider3NeededRowWidth then
		columnWidths[divider3ColumnIndex] = divider3ColumnNeededW
		rowWidth = divider3NeededRowWidth
	end

	-- `infoListW` and `infoListH` used in layout
	local infoListW = rowWidth
	local infoListH = (infoListInsertI - 1) * rowHeight

	---------------------------
	-- Adjust column layouts --
	---------------------------

	local nameColumnTextItem = B3AttackInfo_Private_Menu_InfoListColumnUDs[nameColumnIndex].items
	nameColumnTextItem.text.point = fontPoint

	local divider1Item = B3AttackInfo_Private_Menu_InfoListColumnUDs[divider1ColumnIndex].items
	divider1Item.area.w = divider1ColumnW

	local diver1TextItem = divider1Item.next
	diver1TextItem.area.x = divider1ColumnW

	local mainHandColumnTextItem = B3AttackInfo_Private_Menu_InfoListColumnUDs[mainHandColumnIndex].items.next
	mainHandColumnTextItem.text.point = fontPoint

	local divider2Item = B3AttackInfo_Private_Menu_InfoListColumnUDs[divider2ColumnIndex].items
	divider2Item.area.x = columnWidths[divider2ColumnIndex] > 0 and divider2ColumnPadLeft or 0
	divider2Item.area.w = columnWidths[divider2ColumnIndex] > 0 and divider2ColumnW or 0

	local diver2TextItem = divider2Item.next
	diver2TextItem.area.x = divider2ColumnPadLeft + divider2ColumnW

	local offHandColumnTextItem = B3AttackInfo_Private_Menu_InfoListColumnUDs[offHandColumnIndex].items.next
	offHandColumnTextItem.text.point = fontPoint

	local divider3Item = B3AttackInfo_Private_Menu_InfoListColumnUDs[divider3ColumnIndex].items
	divider3Item.area.x = columnWidths[divider3ColumnIndex] > 0 and divider3ColumnPadLeft or 0
	divider3Item.area.w = columnWidths[divider3ColumnIndex] > 0 and divider3ColumnW or 0

	-----------------------------------------------------------------------------
	-- Convert and set calculated column lengths to percentages for the engine --
	-----------------------------------------------------------------------------

	local columnWidthPercentages = {}

	while true do

		local needGrow = false
		local totalPercent = 0

		for i, columnWidth in ipairs(columnWidths) do

			local columnWidthPercent = math.ceil(columnWidth * 100 / infoListW)
			local resultingColumnWidth = math.floor(infoListW * columnWidthPercent / 100)

			columnWidthPercentages[i] = columnWidthPercent
			totalPercent = totalPercent + columnWidthPercent

			if resultingColumnWidth < columnWidth then
				needGrow = true
				break
			end
		end

		if needGrow or totalPercent > 100 then
			infoListW = infoListW + 1
		else
			break
		end
	end

	for i, columnUD in ipairs(B3AttackInfo_Private_Menu_InfoListColumnUDs) do
		EEex_Menu_SetItemVariant(columnUD.reference_width, columnWidthPercentages[i])
	end

	-----------------------------------------
	--     Layout background (part 1)      --
	-----------------------------------------

	-- `cursorX` and `cursorY` used in layout
	local cursorX, cursorY = EEex_Menu_GetMousePos()

	-- `backgroundX`, `backgroundY`, and `backgroundWidth` used in layout
	local backgroundX = cursorX + popupRightSideAdjust
	local backgroundY = cursorY
	local backgroundWidth = math.max(totalHeaderW, infoListW) + backgroundPad * 2

	------------------------------------
	--     Layout label separator     --
	------------------------------------

	local headerHorizontalSepX = backgroundPad
	local headerHorizontalSepY = backgroundPad + maxHeaderLabelH + headerHorizontalSepPadTop
	local headerHorizontalSepW = backgroundWidth - backgroundPad * 2

	Infinity_SetArea("B3AttackInfo_Menu_LabelSeparator", headerHorizontalSepX, headerHorizontalSepY, headerHorizontalSepW, headerHorizontalSepH)

	-- `headerHorizontalSepTotalY` and `afterHeaderHorizontalSepY` used in layout
	local headerHorizontalSepTotalY = headerHorizontalSepPadTop + headerHorizontalSepH + headerHorizontalSepPadBottom
	local afterHeaderHorizontalSepY = headerHorizontalSepY + headerHorizontalSepH + headerHorizontalSepPadBottom

	----------------------------------------
	--     Layout background (part 2)     --
	----------------------------------------

	-- `backgroundHeight` used in layout
	local backgroundHeight = maxHeaderLabelH + infoListH + headerHorizontalSepTotalY + backgroundPad * 2

	local backgroundRight = backgroundX + backgroundWidth
	local backgroundBottom = backgroundY + backgroundHeight

	local screenW, screenH = Infinity_GetScreenSize()

	if backgroundRight > screenW then
		backgroundX = cursorX - backgroundWidth - popupLeftSideAdjust
	end

	if backgroundBottom > screenH then
		backgroundY = backgroundY - (backgroundBottom - screenH)
	end

	-----------------------------
	--     Finalize layout     --
	-----------------------------

	local infoListX = backgroundPad
	local infoListY = afterHeaderHorizontalSepY

	Infinity_SetOffset("B3AttackInfo_Menu", backgroundX, backgroundY)
	Infinity_SetArea("B3AttackInfo_Menu_InfoList", infoListX, infoListY, infoListW, infoListH)
	Infinity_SetArea("B3AttackInfo_Menu_BackgroundRect", 0, 0, backgroundWidth, backgroundHeight)

	return true
end

function B3AttackInfo_Private_Menu_Ticker_Tick()

	local chitin = EngineGlobals.g_pBaldurChitin
	local game = chitin.m_pObjectGame
	local pObjectCursor = chitin.m_pObjectCursor

	if (game.m_nState ~= 2 and EEex_Key_IsDown(SDL_Keycode.SDLK_TAB)) or (B3EffectMenu_IsOpen ~= nil and B3EffectMenu_IsOpen()) then
		-- Hide the popup if a tooltip is being forced or the effect menu popup is open
		B3AttackInfo_Private_Menu_SetOpen(false)
		return
	end

	local nCurrentCursor = pObjectCursor.nCurrentCursor
	local shouldBeOpen = false

	if nCurrentCursor == 12 or (nCurrentCursor == 101 and EEex.IsDefaultAttackCursor()) then

		local targetSprite = EEex_GameObject_GetUnderCursor()

		if EEex_GameObject_IsSprite(targetSprite) then
			shouldBeOpen = B3AttackInfo_Private_Layout(targetSprite)
		end
	end

	B3AttackInfo_Private_Menu_SetOpen(shouldBeOpen)
end

function B3AttackInfo_Private_Menu_Ticker_Open()
	Infinity_PushMenu("B3AttackInfo_Menu_Ticker")
	B3AttackInfo_Private_Menu_Ticker_IsOpen = true
end

function B3AttackInfo_Private_Menu_Ticker_Close()
	B3AttackInfo_Private_Menu_SetOpen(false)
	Infinity_PopMenu("B3AttackInfo_Menu_Ticker")
	B3AttackInfo_Private_Menu_Ticker_IsOpen = false
end

function B3AttackInfo_Private_Menu_Ticker_SetOpen(open)
	if open then
		if B3AttackInfo_Private_Enabled and not B3AttackInfo_Private_Menu_Ticker_IsOpen then
			B3AttackInfo_Private_Menu_Ticker_Open()
		end
	elseif B3AttackInfo_Private_Menu_Ticker_IsOpen then
		B3AttackInfo_Private_Menu_Ticker_Close()
	end
end

function B3AttackInfo_Private_Menu_Ticker_SetShouldBeOpen(open)
	B3AttackInfo_Private_Menu_Ticker_SetOpen(open)
	B3AttackInfo_Private_Menu_Ticker_ShouldBeOpen = open
end

-----------------------
-- B3AttackInfo_Menu --
-----------------------

B3AttackInfo_Private_Menu_ImmuneColorKeyLabelUD = nil   -- uiItem
B3AttackInfo_Private_Menu_InfoList_SelectedRow  = 0
B3AttackInfo_Private_Menu_InfoList_Table        = {}
B3AttackInfo_Private_Menu_InfoListUD            = nil   -- uiItem
B3AttackInfo_Private_Menu_InfoListColumnUDs     = nil   -- table
B3AttackInfo_Private_Menu_InfoListColumnUDsSize = nil   -- number
B3AttackInfo_Private_Menu_IsOpen                = false
B3AttackInfo_Private_Menu_Label                 = ""
B3AttackInfo_Private_Menu_LabelUD               = nil   -- uiItem
B3AttackInfo_Private_Menu_Reversed              = false
B3AttackInfo_Private_Menu_ShowImmuneColorKey    = false

function B3AttackInfo_Private_Menu_InfoList_BamFrame()
	return B3AttackInfo_Private_Menu_Reversed and 1 or 0
end

function B3AttackInfo_Private_Menu_Open()
	EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_tempCursor = 4 -- Clear tooltip
	Infinity_PushMenu("B3AttackInfo_Menu")
	B3AttackInfo_Private_Menu_IsOpen = true
end

function B3AttackInfo_Private_Menu_Close()
	Infinity_PopMenu("B3AttackInfo_Menu")
	B3AttackInfo_Private_Menu_IsOpen = false
end

function B3AttackInfo_Private_Menu_SetOpen(open)
	if open then
		if not B3AttackInfo_Private_Menu_IsOpen then
			B3AttackInfo_Private_Menu_Open()
		end
	elseif B3AttackInfo_Private_Menu_IsOpen then
		B3AttackInfo_Private_Menu_Close()
	end
end

---------------
-- Listeners --
---------------

function B3AttackInfo_Private_OnActionbarOpened()
	B3AttackInfo_Private_Menu_Ticker_SetShouldBeOpen(true)
end

function B3AttackInfo_Private_OnActionbarClosed()
	B3AttackInfo_Private_Menu_Ticker_SetShouldBeOpen(false)
end

EEex_Menu_AddMainFileLoadedListener(function()

	EEex_Menu_LoadFile("B3AtkInf")

	---------------
	-- Store UDs --
	---------------

	B3AttackInfo_Private_Menu_ImmuneColorKeyLabelUD = EEex_Menu_GetItem("B3AttackInfo_Menu_ImmuneColorKeyLabel")
	B3AttackInfo_Private_Menu_InfoListColumnUDs = {}
	B3AttackInfo_Private_Menu_InfoListColumnUDsSize = 0
	B3AttackInfo_Private_Menu_InfoListUD = EEex_Menu_GetItem("B3AttackInfo_Menu_InfoList")
	B3AttackInfo_Private_Menu_LabelUD = EEex_Menu_GetItem("B3AttackInfo_Menu_Label")

	local columnUD = B3AttackInfo_Private_Menu_InfoListUD.list.columns
	while true do
		if columnUD == nil then break end
		B3AttackInfo_Private_Menu_InfoListColumnUDsSize = B3AttackInfo_Private_Menu_InfoListColumnUDsSize + 1
		B3AttackInfo_Private_Menu_InfoListColumnUDs[B3AttackInfo_Private_Menu_InfoListColumnUDsSize] = columnUD
		columnUD = columnUD.next
	end

	--------------------------------------
	-- Listen to actionbar open / close --
	--------------------------------------

	local listenToEngineEvent = function(eventRef, listener)
		local oldFunc = EEex_Menu_GetItemFunction(eventRef) or function() end
		EEex_Menu_SetItemFunction(eventRef, function()
			local toReturn = oldFunc()
			listener()
			return toReturn
		end)
	end

	local menu = EEex_Menu_Find("WORLD_ACTIONBAR")
	listenToEngineEvent(menu.reference_onOpen, B3AttackInfo_Private_OnActionbarOpened)
	listenToEngineEvent(menu.reference_onClose, B3AttackInfo_Private_OnActionbarClosed)
end)

EEex_Key_AddReleasedListener(function()
	B3AttackInfo_Private_Menu_Reversed = false
end)

EEex.RegisterSlicedRect("B3AttackInfo_BackgroundRect", {
	["topLeft"]     = {  0,  0, 32, 32 },
	["top"]         = { 16,  0, 32, 32 },
	["topRight"]    = { 32,  0, 32, 32 },
	["right"]       = { 32, 16, 32, 32 },
	["bottomRight"] = { 32, 32, 32, 32 },
	["bottom"]      = { 16, 32, 32, 32 },
	["bottomLeft"]  = {  0, 32, 32, 32 },
	["left"]        = {  0, 16, 32, 32 },
	["center"]      = { 16, 16, 32, 32 },
	["dimensions"]  = { 64, 64 },
	["resref"]      = "X-OPTBOX",
	["flags"]       = 0,
})

function B3AttackInfo_Private_Background_Render(item)
	EEex.DrawSlicedRect("B3AttackInfo_BackgroundRect", { item:getArea() }, 255 * 0.85)
end

EEex_Menu_AddBeforeUIItemRenderListener("B3AttackInfo_Menu_BackgroundRect", B3AttackInfo_Private_Background_Render)

EEex_Utility_NewScope(function()
	local old = EEex_Sprite_Hook_CheckSuppressTooltip
	EEex_Sprite_Hook_CheckSuppressTooltip = function()
		return B3AttackInfo_Private_Menu_IsOpen or old()
	end
end)
