
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

local EEex_Marshal_Private_HasUnmarshaledPersistentItems = false

EEex_Sprite_AddMarshalHandlers("EEex_Item",
	function(sprite)
		local toMarshal = {}
		if not EEex.IsMarshallingCopy() then
			-- Persistent item state lives in one global registry, so only the first
			-- portrait sprite carries the marshal payload. This avoids emitting the same
			-- blob on every CRE.
			if EEex_Sprite_GetInPortraitID(0) == sprite.m_id then
				toMarshal["EEex_ItemMarshal"] = EEex_Item_Private_MarshalPersistentItems()
				-- Avoid emitting an empty EEex_ItemMarshal payload when there are zero persisted items.
				if string.find(toMarshal["EEex_ItemMarshal"], ":", 1, true) == nil then
					return nil
				end
			end
		end
		return toMarshal
	end,
	function(sprite, read)
		local marshaled = read["EEex_ItemMarshal"]
		if marshaled == nil or EEex_Marshal_Private_HasUnmarshaledPersistentItems then
			return
		end
		-- Every sprite importer sees the same global payload. Unmarshal it once per
		-- game-state lifetime so later importers do not repeatedly dump and rebuild ITMs.
		EEex_Item_Private_UnmarshalPersistentItems(marshaled)
		EEex_Marshal_Private_HasUnmarshaledPersistentItems = true
	end
)

EEex_GameState_AddDestroyedListener(function()
	-- The load-once gate is game-state scoped because the persistent item registry
	-- is global rather than attached to a specific sprite instance.
	EEex_Marshal_Private_HasUnmarshaledPersistentItems = false
end)

function EEex_Marshal_Private_OnSummonerLoaded(sprite, loadedSprite)
	sprite.m_lSummonedBy:Set(loadedSprite:virtual_GetAIType())
end

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
