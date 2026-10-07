
if EEex_UDAux_AlreadyLoaded then
	return
end
EEex_UDAux_AlreadyLoaded = true

function EEex_UDAux_Private_AssertPersistentValue(value, path, seenTables)
	-- Save data must stay in the shared marshal codec's safe domain. Return a deep copy so
	-- later Lua mutations cannot change the already-validated payload while native code writes it.
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
EEex_UDAux_Private_StoreMarshalData = nil
EEex_UDAux_Private_StoreUnmarshalAux = nil
EEex_UDAux_Private_StoreUnmarshalItems = nil

function EEex_UDAux_Private_ForEachContainerItem(container, func)
	-- Container items are saved in linked-list order, matching the order used by the area file.
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

function EEex_UDAux_Private_ForEachStoreItem(storeItemPtrs, func)
	-- Native code snapshots ordinal -> pointer because m_lInventory is a native linked list.
	for index, itemPtr in pairs(storeItemPtrs) do
		if itemPtr ~= 0 then
			func(index, EEex_PtrToUD(itemPtr, "CStoreFileItem"))
		end
	end
end

function EEex_UDAux_Private_NewAreaMarshalBundle(marshalData)
	local bundle = EEex_Marshal_Private_NewTableBundle()
	EEex_Marshal_Private_AddTableBundleEntry(bundle, "EEex_UDAux_Area", marshalData, "Area UDAux marshal")
	return bundle
end

function EEex_UDAux_Private_NewStoreMarshalBundle(marshalData)
	local bundle = EEex_Marshal_Private_NewTableBundle()
	EEex_Marshal_Private_AddTableBundleEntry(bundle, "EEex_UDAux_Store", marshalData, "Store UDAux marshal")
	return bundle
end

function EEex_UDAux_Private_BeginAreaMarshal(area)
	-- Area marshal state is filled by CGameContainer::Marshal callbacks as the engine walks containers.
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

	-- Persist by ordinal, not pointer. Pointers are process-local and change after load.
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
	-- Keep decoded data until each CGameContainer constructor callback supplies the matching runtime object.
	EEex_UDAux_Private_AreaUnmarshalContainers = {}
	EEex_UDAux_Private_AreaUnmarshalContainerIndex = 0

	if memory == 0 or size == 0 then
		return
	end

	EEex_Marshal_Private_ReadTableBundle(memory, function(handlerStr, toFill)
		if handlerStr == "EEex_UDAux_Area" and type(toFill) == "table" then
			EEex_UDAux_Private_AreaUnmarshalContainers = toFill["containers"] or {}
		end
	end, size)
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

function EEex_UDAux_Private_CalculateStoreMarshalExtensionSize(store, storeItemPtrs)
	EEex_UDAux_Private_StoreMarshalData = nil
	if storeItemPtrs == nil then
		storeItemPtrs = store
		store = nil
	end

	local marshalData = {
		["items"] = {},
	}

	if store then
		local storeAux = EEex_UDAux_Private_Export(store, "CStore")
		if storeAux then
			marshalData["aux"] = storeAux
		end
	end

	EEex_UDAux_Private_ForEachStoreItem(storeItemPtrs, function(itemIndex, item)
		-- Store-owned CStoreFileItem pointers are runtime list nodes; save their aux by list ordinal.
		local itemAux = EEex_UDAux_Private_Export(item, "CStore.m_lInventory["..itemIndex.."]")
		if itemAux then
			marshalData["items"][itemIndex] = itemAux
		end
	end)

	if not marshalData["aux"] and next(marshalData["items"]) == nil then
		return 0
	end

	EEex_UDAux_Private_StoreMarshalData = marshalData
	return EEex_Marshal_Private_CalculateTableBundleSize(EEex_UDAux_Private_NewStoreMarshalBundle(marshalData), "Store UDAux marshal")
end

function EEex_UDAux_Private_WriteStoreMarshalExtensionPayload(memory, size)
	local marshalData = EEex_UDAux_Private_StoreMarshalData
	if not marshalData then
		return
	end
	EEex_Memset(memory, 0, size)
	EEex_Marshal_Private_WriteTableBundle(memory, EEex_UDAux_Private_NewStoreMarshalBundle(marshalData), "Store UDAux marshal")
end

function EEex_UDAux_Private_EndStoreMarshal()
	EEex_UDAux_Private_StoreMarshalData = nil
end

function EEex_UDAux_Private_BeginStoreUnmarshal(memory, size)
	-- Store SetResRef has not populated m_lInventory yet; keep decoded data until the after-load hook.
	EEex_UDAux_Private_StoreUnmarshalAux = nil
	EEex_UDAux_Private_StoreUnmarshalItems = {}

	if memory == 0 or size == 0 then
		return
	end

	EEex_Marshal_Private_ReadTableBundle(memory, function(handlerStr, toFill)
		if handlerStr == "EEex_UDAux_Store" and type(toFill) == "table" then
			EEex_UDAux_Private_StoreUnmarshalAux = toFill["aux"]
			EEex_UDAux_Private_StoreUnmarshalItems = toFill["items"] or {}
		end
	end, size)
end

function EEex_UDAux_Private_OnStoreLoaded(store, storeItemPtrs)
	if storeItemPtrs == nil then
		storeItemPtrs = store
		store = nil
	end

	local storeAux = EEex_UDAux_Private_StoreUnmarshalAux
	if storeAux and store then
		EEex_UDAux_Private_Import(store, storeAux)
	end

	local items = EEex_UDAux_Private_StoreUnmarshalItems
	if not items then
		return
	end

	EEex_UDAux_Private_ForEachStoreItem(storeItemPtrs, function(itemIndex, item)
		local itemAux = items[itemIndex]
		if itemAux then
			EEex_UDAux_Private_Import(item, itemAux)
		end
	end)
end

function EEex_UDAux_Private_EndStoreUnmarshal()
	EEex_UDAux_Private_StoreUnmarshalAux = nil
	EEex_UDAux_Private_StoreUnmarshalItems = nil
end

function EEex_UDAux_Private_OnStoreInventoryClear(store, storeItemPtrs)
	if storeItemPtrs == nil then
		storeItemPtrs = store
		store = nil
	end

	-- This runs before the engine frees CStoreFileItem nodes, so deleting by pointer is still valid.
	if store then
		EEex_UDAux_Private_DeleteByLightUD(EEex_UDToLightUD(store))
	end
	EEex_UDAux_Private_ForEachStoreItem(storeItemPtrs, function(_, item)
		EEex_UDAux_Private_DeleteByLightUD(EEex_UDToLightUD(item))
	end)
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
			-- Creature extra marshal data can arrive before equipment pointers are rebuilt.
			-- Retry from load/list-resolved callbacks until every saved slot has a CItem.
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
