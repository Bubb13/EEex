
EEex_DerivedStats_DisabledButtonType = {
	["BUTTON_STEALTH"] = 0,
	["BUTTON_THIEVING"] = 1,
	["BUTTON_CASTSPELL"] = 2,
	["BUTTON_QUICKSPELL0"] = 3,
	["BUTTON_QUICKSPELL1"] = 4,
	["BUTTON_QUICKSPELL2"] = 5,
	["BUTTON_TURNUNDEAD"] = 6,
	["BUTTON_DIALOG"] = 7,
	["BUTTON_USEITEM"] = 8,
	["BUTTON_QUICKITEM1"] = 9,
	["BUTTON_BATTLESONG"] = 10,
	["BUTTON_QUICKITEM2"] = 11,
	["BUTTON_QUICKITEM3"] = 12,
	["BUTTON_INNATEBUTTON"] = 13,
	["SCREEN_INVENTORY"] = 14,
}

function EEex_Sprite_GetInPortrait(portraitIndex)
	return EEex_GameObject_Get(EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_charactersPortrait:get(portraitIndex))
end

function EEex_Sprite_GetInPortraitID(portraitIndex)
	return EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_charactersPortrait:get(portraitIndex)
end

function EEex_Sprite_GetPortraitIndex(sprite)
	local spriteID = sprite.m_id
	local portraitsArray = EngineGlobals.g_pBaldurChitin.m_pObjectGame.m_charactersPortrait
	for i = 0, 5 do
		if portraitsArray:get(i) == spriteID then
			return i
		end
	end
	return -1
end
CGameSprite.getPortraitIndex = EEex_Sprite_GetPortraitIndex

function EEex_Sprite_GetActiveStats(sprite)
	return sprite.m_bAllowEffectListCall and sprite.m_derivedStats or sprite.m_tempStats
end
CGameSprite.getActiveStats = EEex_Sprite_GetActiveStats

function EEex_Sprite_GetExtendedStat(sprite, id)
	return EEex_GetUDAux(sprite:getActiveStats())["EEex_ExtendedStats"][id]
end
CGameSprite.getExtendedStat = EEex_Sprite_GetExtendedStat

function EEex_Sprite_GetState(sprite)
	return sprite:getActiveStats().m_generalState
end
CGameSprite.getState = EEex_Sprite_GetState

function EEex_Sprite_GetSpellState(sprite, spellStateID)
	return sprite:getActiveStats():GetSpellState(spellStateID) ~= 0
end
CGameSprite.getSpellState = EEex_Sprite_GetSpellState

function EEex_Sprite_GetLocalInt(sprite, variableName)
	return sprite.m_pLocalVariables:getInt(variableName)
end
CGameSprite.getLocalInt = EEex_Sprite_GetLocalInt

function EEex_Sprite_GetLocalString(sprite, variableName)
	return sprite.m_pLocalVariables:getString(variableName)
end
CGameSprite.getLocalString = EEex_Sprite_GetLocalString

function EEex_Sprite_SetLocalInt(sprite, variableName, value)
	sprite.m_pLocalVariables:setInt(variableName, value)
end
CGameSprite.setLocalInt = EEex_Sprite_SetLocalInt

function EEex_Sprite_SetLocalString(sprite, variableName, value)
	sprite.m_pLocalVariables:setString(variableName, value)
end
CGameSprite.setLocalString = EEex_Sprite_SetLocalString

-- Returns the sprite's current modal state, (as defined in MODAL.IDS; stored at offset 0x28 of the global-creature structure).
function EEex_Sprite_GetModalState(sprite)
	if not sprite then return 0 end
	return sprite.m_nModalState
end
CGameSprite.getModalState = EEex_Sprite_GetModalState

-- [0-99], 0 = modal check pending
-- yes, this timer is faster than the others by 1 tick
function EEex_Sprite_GetModalTimer(sprite)
	if not sprite then return 0 end
	local idRemainder = sprite.m_id % 100
	local timerRemainder = sprite.m_PAICallCounterNoMod % 100
	if idRemainder >= timerRemainder then
		return idRemainder - timerRemainder
	else
		return 100 - timerRemainder + idRemainder
	end
end
CGameSprite.getModalTimer = EEex_Sprite_GetModalTimer

-- [0-100], 0 = contingency check pending
function EEex_Sprite_GetContingencyTimer(sprite)
	if not sprite then return 0 end
	return sprite.m_nLastContingencyCheck
end
CGameSprite.getContingencyTimer = EEex_Sprite_GetContingencyTimer

-- [-1-99], -1 = aura free
function EEex_Sprite_GetCastTimer(sprite)
	if not sprite then return 0 end
	return sprite.m_castCounter
end
CGameSprite.getCastTimer = EEex_Sprite_GetCastTimer

-- [0-1]
function EEex_Sprite_GetModalTimerPercentage(sprite)
	if not sprite then return 0 end
	return (99 - sprite:getModalTimer()) / 99
end
CGameSprite.getModalTimerPercentage = EEex_Sprite_GetModalTimerPercentage

-- [0-1]
function EEex_Sprite_GetContingencyTimerPercentage(sprite)
	if not sprite then return 0 end
	return (100 - sprite:getContingencyTimer()) / 100
end
CGameSprite.getContingencyTimerPercentage = EEex_Sprite_GetContingencyTimerPercentage

-- [0-1]
function EEex_Sprite_GetCastTimerPercentage(sprite)
	if not sprite then return 0 end
	return (sprite:getCastTimer() + 1) / 100
end
CGameSprite.getCastTimerPercentage = EEex_Sprite_GetCastTimerPercentage

-----------
-- Hooks --
-----------

function EEex_Sprite_Hook_CheckSuppressTooltip()
	return false
end

function EEex_Sprite_Hook_OnConstruct(sprite)

end

function EEex_Sprite_Hook_OnDestruct(sprite)

end
