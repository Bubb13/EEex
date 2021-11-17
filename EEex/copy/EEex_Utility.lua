
function EEex_Utility_FreeCPtrList(list)
	while list.m_nCount > 0 do
		EEex_FreeUD(list:RemoveHead())
	end
	list:Destruct()
	EEex_FreeUD(list)
end

function EEex_Utility_IterateCPtrList(list, func)
	local node = list.m_pNodeHead
	while node do
		if func(node.data) then break end
		node = node.pNext
	end
end

function EEex_Utility_DumpMetatables(obj)
	local meta = obj
	local i = 0
	while true do
		meta = getmetatable(meta)
		if not meta then break end
		B3Dump("meta["..i.."]", meta)
		i = i + 1
	end
end
