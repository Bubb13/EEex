
EEex_Sprite_AddMarshalHandlers("EEex",
	function(sprite)
		local toMarshal = {}
		if not EEex.IsMarshallingCopy() then
			toMarshal["SummonerUUID"] = EEex_GetUDAux(sprite)["EEex_SummonerUUID"]
		end
		return toMarshal
	end,
	function(sprite, read)
		local summonerUUID = read["SummonerUUID"]
		if summonerUUID then
			EEex_GetUDAux(sprite)["EEex_SummonerUUID"] = summonerUUID
		end
	end
)

EEex_Sprite_AddMarshalHandlers("EEex_UDAux",
	function(sprite)

		if EEex.IsMarshallingCopy() then
			return nil
		end

		local toMarshal = {}

		local exportEffectList = function(list, path)
			local exported = {}
			local i = 1
			EEex_Utility_IterateCPtrList(list, function(effect)
				exported[i] = EEex_UDAux_Private_Export(effect, path.."["..i.."]")
				i = i + 1
			end)
			return next(exported) and exported or nil
		end

		local timedEffects = exportEffectList(sprite.m_timedEffectList, "CGameSprite.m_timedEffectList")
		if timedEffects then
			toMarshal["timedEffects"] = timedEffects
		end

		local equippedEffects = exportEffectList(sprite.m_equipedEffectList, "CGameSprite.m_equipedEffectList")
		if equippedEffects then
			toMarshal["equippedEffects"] = equippedEffects
		end

		local items = {}
		for i = 0, 38 do
			local item = sprite.m_equipment.m_items:get(i)
			if item then
				items[i] = EEex_UDAux_Private_Export(item, "CGameSprite.m_equipment.m_items["..i.."]")
			end
		end
		if next(items) then
			toMarshal["items"] = items
		end

		return next(toMarshal) and toMarshal or nil
	end,
	function(sprite, read)

		local importEffectList = function(list, data)
			if not data then
				return
			end
			local i = 1
			EEex_Utility_IterateCPtrList(list, function(effect)
				local auxiliary = data[i]
				if auxiliary then
					EEex_UDAux_Private_Import(effect, auxiliary)
				end
				i = i + 1
			end)
		end

		importEffectList(sprite.m_timedEffectList, read["timedEffects"])
		importEffectList(sprite.m_equipedEffectList, read["equippedEffects"])

		local items = read["items"]
		if items then
			-- The extra creature marshal block is read while the sprite is still being rebuilt.
			-- Equipment item pointers can be unavailable at this point, so keep slot data on the
			-- sprite and retry from normal post-load/update hooks until each item exists.
			EEex_GetUDAux(sprite)["EEex_UDAux_PendingItemAux"] = items
			EEex_UDAux_Private_ApplyPendingItemAux(sprite)
		end
	end
)

function EEex_Marshal_Private_OnSummonerLoaded(sprite, loadedSprite)
	sprite.m_lSummonedBy:Set(loadedSprite:virtual_GetAIType())
end

EEex_Sprite_AddLoadedListener(EEex_UDAux_Private_ApplyPendingItemAux)
EEex_Opcode_AddListsResolvedListener(EEex_UDAux_Private_ApplyPendingItemAux)

EEex_Sprite_AddLoadedListener(function(sprite)
	local summonerUUID = EEex_GetUDAux(sprite)["EEex_SummonerUUID"]
	if summonerUUID then
		sprite:loadedWithUUIDCallback(summonerUUID, EEex_Marshal_Private_OnSummonerLoaded)
	end
end)

EEex_AIBase_AddScriptingObjectUpdatedListener(function(aiBase, scriptingObject)

	if not aiBase:isSprite(true) then
		return
	end

	if scriptingObject == EEex_ScriptingObject.SUMMONED_BY then
		local summoner = EEex_GameObject_Get(aiBase.m_lSummonedBy.m_Instance)
		if EEex_GameObject_IsSprite(summoner, true) then
			EEex_GetUDAux(aiBase)["EEex_SummonerUUID"] = summoner:getUUID()
		end
	end
end)
