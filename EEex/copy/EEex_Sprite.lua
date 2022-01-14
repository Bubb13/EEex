
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

function EEex_Sprite_GetActiveStats(sprite)
	return sprite.m_bAllowEffectListCall and sprite.m_derivedStats or sprite.m_tempStats
end

-- Returns the sprite's current modal state, (as defined in MODAL.IDS; stored at offset 0x28 of the global-creature structure).
function EEex_Sprite_GetModalState(sprite)
	if not sprite then return 0 end
	return sprite.m_nModalState
end

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

-- [0-100], 0 = contingency check pending
function EEex_Sprite_GetContingencyTimer(sprite)
	if not sprite then return 0 end
	return sprite.m_nLastContingencyCheck
end

-- [-1-99], -1 = aura free
function EEex_Sprite_GetCastTimer(sprite)
	if not sprite then return 0 end
	return sprite.m_castCounter
end

-- [0-1]
function EEex_Sprite_GetModalTimerPercentage(sprite)
	if not sprite then return 0 end
	return (99 - sprite:getModalTimer()) / 99
end

-- [0-1]
function EEex_Sprite_GetContingencyTimerPercentage(sprite)
	if not sprite then return 0 end
	return (100 - sprite:getContingencyTimer()) / 100
end

-- [0-1]
function EEex_Sprite_GetCastTimerPercentage(sprite)
	if not sprite then return 0 end
	return (sprite:getCastTimer() + 1) / 100
end

-----------
-- Hooks --
-----------

function EEex_Sprite_Hook_CheckSuppressTooltip()
	return false
end
