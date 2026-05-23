
if EEex_UDAux_AlreadyLoaded then
	return
end
EEex_UDAux_AlreadyLoaded = true

function EEex_UDAux_Private_AssertPersistentValue(value, path, seenTables)
	local valueType = type(value)
	if valueType == "boolean" then
		return value
	elseif valueType == "string" then
		if value:find("\0", 1, true) then
			EEex_Error("Persistent UDAux string at "..path.." cannot contain NUL bytes")
		end
		return value
	elseif valueType == "number" then
		if value ~= value or value % 1 ~= 0 then
			EEex_Error("Persistent UDAux value at "..path.." must be an integer number")
		end
		if value < -0x10000000000000000 or value > 0xFFFFFFFFFFFFFFFF then
			EEex_Error("Persistent UDAux number at "..path.." is outside the supported marshal range")
		end
		return value
	elseif valueType ~= "table" then
		EEex_Error("Persistent UDAux value at "..path.." has unsupported type "..valueType)
	end

	if seenTables[value] then
		EEex_Error("Persistent UDAux table cycle detected at "..path)
	end
	seenTables[value] = true

	local copy = {}
	for k, v in pairs(value) do
		local kType = type(k)
		if kType ~= "boolean" and kType ~= "number" and kType ~= "string" then
			EEex_Error("Persistent UDAux key at "..path.." has unsupported type "..kType)
		end
		local keyPath = path.."["..tostring(k).."]"
		copy[EEex_UDAux_Private_AssertPersistentValue(k, path.."<key>", seenTables)] =
			EEex_UDAux_Private_AssertPersistentValue(v, keyPath, seenTables)
	end

	seenTables[value] = nil
	return copy
end

function EEex_UDAux_Private_IsLightUDPersistent(lud)
	return EEex_UserDataAuxiliaryPersistent[lud] == true
end

function EEex_UDAux_Private_IsPersistent(ud)
	return EEex_UDAux_Private_IsLightUDPersistent(EEex_UDToLightUD(ud))
end

function EEex_UDAux_Private_Export(ud, path)
	local lud = EEex_UDToLightUD(ud)
	if not EEex_UDAux_Private_IsLightUDPersistent(lud) then
		return nil
	end

	local auxiliary = EEex_UserDataAuxiliary[lud]
	if not auxiliary or next(auxiliary) == nil then
		return nil
	end
	return EEex_UDAux_Private_AssertPersistentValue(auxiliary, path or "persistent UDAux", {})
end

function EEex_UDAux_Private_Import(ud, auxiliary)
	local lud = EEex_UDToLightUD(ud)
	EEex_UserDataAuxiliary[lud] = EEex_UDAux_Private_AssertPersistentValue(auxiliary, "persistent UDAux import", {})
	EEex_UserDataAuxiliaryPersistent[lud] = true
	return EEex_UserDataAuxiliary[lud]
end

function EEex_UDAux_Private_CopyByLightUD(srcLud, dstLud)
	local srcAuxiliary = EEex_UserDataAuxiliary[srcLud]
	if EEex_UserDataAuxiliaryPersistent[srcLud] and srcAuxiliary then
		EEex_UserDataAuxiliary[dstLud] = EEex_UDAux_Private_AssertPersistentValue(srcAuxiliary, "persistent UDAux copy", {})
	else
		EEex_UserDataAuxiliary[dstLud] = nil
	end

	if EEex_UserDataAuxiliaryPersistent[srcLud] then
		EEex_UserDataAuxiliaryPersistent[dstLud] = true
	else
		EEex_UserDataAuxiliaryPersistent[dstLud] = nil
	end
end

function EEex_UDAux_Private_DeleteByLightUD(lud)
	EEex_UserDataAuxiliary[lud] = nil
	EEex_UserDataAuxiliaryPersistent[lud] = nil
end

EEex_UDAux_Private_AreaMarshalData = nil
EEex_UDAux_Private_AreaMarshalContainerIndex = 0
EEex_UDAux_Private_AreaUnmarshalContainers = nil
EEex_UDAux_Private_AreaUnmarshalContainerIndex = 0

function EEex_UDAux_Private_ForEachContainerItem(container, func)
	local node = container.m_lstItems.m_pNodeHead
	local index = 1
	while node do
		local item = node.data
		if item then
			func(index, item)
		end
		node = node.pNext
		index = index + 1
	end
end

function EEex_UDAux_Private_NewAreaMarshalBundle(marshalData)
	local bundle = EEex_Marshal_Private_NewTableBundle()
	EEex_Marshal_Private_AddTableBundleEntry(bundle, "EEex_UDAux_Area", marshalData, "Area UDAux marshal")
	return bundle
end

function EEex_UDAux_Private_BeginAreaMarshal(area)
	EEex_UDAux_Private_AreaMarshalData = {
		["containers"] = {},
	}
	EEex_UDAux_Private_AreaMarshalContainerIndex = 0
end

function EEex_UDAux_Private_OnAreaContainerMarshal(container)
	local marshalData = EEex_UDAux_Private_AreaMarshalData
	if not marshalData then
		return
	end

	EEex_UDAux_Private_AreaMarshalContainerIndex = EEex_UDAux_Private_AreaMarshalContainerIndex + 1
	local containerIndex = EEex_UDAux_Private_AreaMarshalContainerIndex
	local containerData = {}

	local containerAux = EEex_UDAux_Private_Export(container, "CGameArea.m_lContainers["..containerIndex.."]")
	if containerAux then
		containerData["aux"] = containerAux
	end

	local itemData = {}
	EEex_UDAux_Private_ForEachContainerItem(container, function(itemIndex, item)
		local itemAux = EEex_UDAux_Private_Export(item, "CGameArea.m_lContainers["..containerIndex.."].m_lstItems["..itemIndex.."]")
		if itemAux then
			itemData[itemIndex] = itemAux
		end
	end)

	if next(itemData) then
		containerData["items"] = itemData
	end
	if next(containerData) then
		marshalData["containers"][containerIndex] = containerData
	end
end

function EEex_UDAux_Private_CalculateAreaMarshalExtensionSize()
	local marshalData = EEex_UDAux_Private_AreaMarshalData
	if not marshalData or next(marshalData["containers"]) == nil then
		return 0
	end
	return EEex_Marshal_Private_CalculateTableBundleSize(EEex_UDAux_Private_NewAreaMarshalBundle(marshalData), "Area UDAux marshal")
end

function EEex_UDAux_Private_WriteAreaMarshalExtensionPayload(memory, size)
	local marshalData = EEex_UDAux_Private_AreaMarshalData
	if not marshalData then
		return
	end
	EEex_Memset(memory, 0, size)
	EEex_Marshal_Private_WriteTableBundle(memory, EEex_UDAux_Private_NewAreaMarshalBundle(marshalData), "Area UDAux marshal")
end

function EEex_UDAux_Private_EndAreaMarshal()
	EEex_UDAux_Private_AreaMarshalData = nil
	EEex_UDAux_Private_AreaMarshalContainerIndex = 0
end

function EEex_UDAux_Private_BeginAreaUnmarshal(memory, size)
	EEex_UDAux_Private_AreaUnmarshalContainers = {}
	EEex_UDAux_Private_AreaUnmarshalContainerIndex = 0

	if memory == 0 or size == 0 then
		return
	end

	EEex_Marshal_Private_ReadTableBundle(memory, function(handlerStr, toFill)
		if handlerStr == "EEex_UDAux_Area" and type(toFill) == "table" then
			EEex_UDAux_Private_AreaUnmarshalContainers = toFill["containers"] or {}
		end
	end)
end

function EEex_UDAux_Private_OnAreaContainerConstruct(container)
	local containers = EEex_UDAux_Private_AreaUnmarshalContainers
	if not containers then
		return
	end

	EEex_UDAux_Private_AreaUnmarshalContainerIndex = EEex_UDAux_Private_AreaUnmarshalContainerIndex + 1
	local containerData = containers[EEex_UDAux_Private_AreaUnmarshalContainerIndex]
	if not containerData then
		return
	end

	local containerAux = containerData["aux"]
	if containerAux then
		EEex_UDAux_Private_Import(container, containerAux)
	end

	local items = containerData["items"]
	if items then
		EEex_UDAux_Private_ForEachContainerItem(container, function(itemIndex, item)
			local itemAux = items[itemIndex]
			if itemAux then
				EEex_UDAux_Private_Import(item, itemAux)
			end
		end)
	end
end

function EEex_UDAux_Private_EndAreaUnmarshal()
	EEex_UDAux_Private_AreaUnmarshalContainers = nil
	EEex_UDAux_Private_AreaUnmarshalContainerIndex = 0
end

function EEex_UDAux_Private_ApplyPendingItemAux(sprite)
	local spriteAux = EEex_TryGetUDAux(sprite)
	local pendingItems = spriteAux and spriteAux["EEex_UDAux_PendingItemAux"]
	if not pendingItems then
		return
	end

	local anyPending = false
	for i = 0, 38 do
		local auxiliary = pendingItems[i]
		if auxiliary then
			local item = sprite.m_equipment.m_items:get(i)
			if item then
				EEex_UDAux_Private_Import(item, auxiliary)
				pendingItems[i] = nil
			else
				anyPending = true
			end
		end
	end

	if not anyPending then
		spriteAux["EEex_UDAux_PendingItemAux"] = nil
	end
end
