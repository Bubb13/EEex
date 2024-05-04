
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
