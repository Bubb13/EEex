
function EEex_Test_IDSFunctions()

	local doTest = function(cacheAsArray)

		local action = EEex_Resource_LoadIDS("ACTION", cacheAsArray)

		print(string.format("    [%s] %d", "EEex_Resource_GetIDSCount", EEex_Resource_GetIDSCount(action)))
		print(string.format("    [%s] %s", "EEex_Resource_GetIDSEntry", tostring(EEex_Resource_GetIDSEntry(action, 3))))
		print(string.format("    [%s] %s", "EEex_Resource_GetIDSLine", EEex_Resource_GetIDSLine(action, 1)))
		print(string.format("    [%s] %s", "EEex_Resource_GetIDSStart", EEex_Resource_GetIDSStart(action, 1)))
		print(string.format("    [%s] %s", "EEex_Resource_IDSHasID(3)", tostring(EEex_Resource_IDSHasID(action, 3))))
		print(string.format("    [%s] %s", "EEex_Resource_IDSHasID(4)", tostring(EEex_Resource_IDSHasID(action, 4))))

		print(string.format("    [%s]", "EEex_Resource_IterateIDSEntries"))
		EEex_Resource_IterateIDSEntries(action, function(entry)
			print(string.format("        %s", tostring(entry)))
		end)

		print(string.format("    [%s]", "EEex_Resource_IterateUnpackedIDSEntries"))
		EEex_Resource_IterateUnpackedIDSEntries(action, function(id, line, start)
			print(string.format("        %d, %s, %s", id, line, start))
		end)
	end

	print(string.format("[cacheAsArray=false]"))
	doTest(false)
	print(string.format("[cacheAsArray=true]"))
	doTest(true)
end

function EEex_Test_2DAFunctions()

	local kitlist = EEex_Resource_Load2DA("KITLIST")

	print(string.format("[%s] %d", "EEex_Resource_Find2DAColumnIndex", EEex_Resource_Find2DAColumnIndex(kitlist, 1, "CLABFI02")))
	print(string.format("[%s] %d", "EEex_Resource_Find2DAColumnLabel", EEex_Resource_Find2DAColumnLabel(kitlist, "ABILITIES")))
	print(string.format("[%s] %d", "EEex_Resource_Find2DARowIndex", EEex_Resource_Find2DARowIndex(kitlist, 0, "SHAPESHIFTER")))
	print(string.format("[%s] %d", "EEex_Resource_Find2DARowLabel", EEex_Resource_Find2DARowLabel(kitlist, "32")))
	print(string.format("[%s] %s", "EEex_Resource_Get2DAColumnLabel", EEex_Resource_Get2DAColumnLabel(kitlist, 2)))
	print(string.format("[%s] %s", "EEex_Resource_Get2DADefault", EEex_Resource_Get2DADefault(kitlist)))

	local dimX, dimY = EEex_Resource_Get2DADimensions(kitlist)
	print(string.format("[%s] %d, %d", "EEex_Resource_Get2DADimensions", dimX, dimY))

	print(string.format("[%s] %s", "EEex_Resource_Get2DARowLabel", EEex_Resource_Get2DARowLabel(kitlist, 5)))
	print(string.format("[%s] %s", "EEex_Resource_GetAt2DALabels", EEex_Resource_GetAt2DALabels(kitlist, "ABILITIES", "31")))
	print(string.format("[%s] %s", "EEex_Resource_GetAt2DAPoint", EEex_Resource_GetAt2DAPoint(kitlist, 3, 3)))

	local maxX, maxY = EEex_Resource_GetMax2DAIndices(kitlist)
	print(string.format("[%s] %d, %d", "EEex_Resource_GetMax2DAIndices", maxX, maxY))

	print(string.format("[%s]", "EEex_Resource_Iterate2DAColumnIndex"))
	EEex_Resource_Iterate2DAColumnIndex(kitlist, 1, function(i, str)
		print(string.format("    [%d] = %s", i, str))
	end)

	print(string.format("[%s]", "EEex_Resource_Iterate2DAColumnLabel"))
	EEex_Resource_Iterate2DAColumnLabel(kitlist, "UNUSABLE", function(i, str)
		print(string.format("    [%d] = %s", i, str))
	end)

	print(string.format("[%s]", "EEex_Resource_Iterate2DARowIndex"))
	EEex_Resource_Iterate2DARowIndex(kitlist, 5, function(i, str)
		print(string.format("    [%d] = %s", i, str))
	end)

	print(string.format("[%s]", "EEex_Resource_Iterate2DARowLabel"))
	EEex_Resource_Iterate2DARowLabel(kitlist, "41", function(i, str)
		print(string.format("    [%d] = %s", i, str))
	end)
end

function EEex_Test_CreateRuntimeItem()

	local sprite = EEex_Sprite_GetSelected() -- CGameSprite
	if not sprite then
		return
	end

	-- New item from scratch
	do
		local pHeader = EEex_Item_CreateFromResref("B3NEWITM", {
			["genericName"] = 1080,
			["identifiedName"] = 1080,
			["itemFlags"] = 0x2C, -- droppable, displayable, not copyable
			["itemType"] = 10, -- rings
			["minINTRequired"] = 9,
			["baseValue"] = 900,
			["genericDescription"] = 17054,
			["identifiedDescription"] = 17054,
			["itemIcon"] = "IRING01",
			["groundIcon"] = "GRING01",
		}, true) -- set last boolean parameter to ``false`` if you do not want the item to survive load/save
		--
		pHeader = EEex_Resource_AddItemAbility(pHeader, {
			["quickSlotIcon"] = "IRING01",
		})
		--
		pHeader = EEex_Resource_AddItemEqEffect(pHeader, {
			["effectID"] = 0x8E, -- type: display portrait icon
			["dwFlags"] = 94, -- icon: magnetized
		})
		--
		pHeader = EEex_Resource_AddItemEffect(pHeader, {
			["effectID"] = 0x92, -- type: Cast Spell (at Creature)
			["dwFlags"] = 1, -- mode: Cast instantly (caster level)
			["res"] = "SPWI112",
		})
		--
		sprite:applyEffect({
			["effectID"] = 0x7A, -- Create inventory item
			["durationType"] = 1,
			["effectAmount"] = Infinity_RandomNumber(1, 5),
			["res"] = "B3NEWITM",
			["sourceID"] = sprite.m_id,
			["sourceTarget"] = sprite.m_id,
		})
	end

	-- Clone existing item
	do
		local items = sprite.m_equipment.m_items -- Array<CItem*,39>
		for i = 0, 38 do
			local item = items:get(i) -- CItem
			if item then -- sanity check
				local resref = item.pRes.resref:get()
				if resref:upper() == "STAF01" then
					local pHeader = EEex_Item_CreateCopy("B3STAF01", item, {
						["attributes"] = 9, -- enchantment: +9
					}, true) -- set last boolean parameter to ``false`` if you do not want the item to survive load/save
					--
					pHeader.itemFlags = EEex_BOr(pHeader.itemFlags, 0x6) -- add magical flag
					pHeader.baseValue = pHeader.baseValue + 1000 -- increase base value by 1000
					--
					sprite:applyEffect({
						["effectID"] = 0x7A, -- Create inventory item
						["durationType"] = 1,
						["res"] = "B3STAF01",
						["sourceID"] = sprite.m_id,
						["sourceTarget"] = sprite.m_id,
					})
					--
					break
				end
			end
		end
	end
end
