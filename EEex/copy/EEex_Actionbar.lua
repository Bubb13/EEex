
-----------------------
-- General Functions --
-----------------------

function EEex_Actionbar_GetArray()
	return EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_cButtonArray
end

function EEex_Actionbar_SetState(state)
	EEex_Actionbar_GetArray():SetState(state)
end

function EEex_Actionbar_GetLastState()
	return EEex_Actionbar_GetArray().m_nLastState
end

function EEex_Actionbar_RestoreLastState()
	EEex_Actionbar_SetState(EEex_Actionbar_GetLastState())
end

---------------
-- Listeners --
---------------

EEex_Actionbar_Listeners = EEex_Actionbar_Listeners or {}

function EEex_Actionbar_AddListener(func)
	table.insert(EEex_Actionbar_Listeners, func)
end

-----------
-- Hooks --
-----------

EEex_Actionbar_IgnoreEngineStatup = true

--[[
Unique Config | State(s)
    [0]       |  = 1,   -- Mage / Sorcerer
    [1]       |  = 2,   -- Fighter
    [2]       |  = 3,   -- Cleric
    [3]       |  = 4,   -- Thief
    [4]       |  = 5,   -- Bard
    [5]       |  = 6,   -- Paladin
    [6]       |  = 7,   -- Fighter Mage
    [7]       |  = 8,   -- Fighter Cleric
    [8]       |  = 9,   -- Fighter Thief
    [9]       |  = 10,  -- Fighter Mage Thief
    [10]      |  = 11,  -- Druid
    [11]      |  = 12,  -- Ranger
    [12]      |  = 13,  -- Mage Thief
    [13]      |  = 14,  -- Cleric Mage
    [14]      |  = 15,  -- Cleric Thief
    [15]      |  = 16,  -- Fighter Druid
    [16]      |  = 17,  -- Fighter Mage Cleric
    [17]      |  = 18,  -- Cleric Ranger
    [18]      |  = 20,  -- Monk
    [19]      |  = 21,  -- Shaman
    [20]      |  = 101, -- Select Weapon Ability
              |
    [21]      |  = 102, -- Spells (Select Quick Spell)
              |    103, -- Spells (Cast)
              |
    [22]      |  = 104, -- Select Quick Item Ability
              |    105, -- Use Item
              |
    [23]      |  = 106, -- Special Abilities
    [24]      |  = 107, -- Select Quick Formation
    [25]      |  = 108, -- Defunct Select Quick Formation (Not used)
    [26]      |  = 109, -- Group Selected
    [27]      |  = 110, -- Unknown (No buttons defined; not used?)
    [28]      |  = 111, -- Internal List (Opcode #214)
    [29]      |  = 112, -- Controlled (Class doesn't have a dedicated state)
              |
    [30]      |  = 113, -- Cleric / Mage Spells (Cast)
              |    114, -- Cleric / Mage Spells (Select Quick Spell)
              |
--]]
function EEex_Actionbar_Hook_StateUpdating(config, state)
	if EEex_Actionbar_IgnoreEngineStatup then
		EEex_Actionbar_IgnoreEngineStatup = false
		return
	end
	for i, func in ipairs(EEex_Actionbar_Listeners) do
		func(config, state)
	end
end

function EEex_Actionbar_Hook_HasFullThieving(sprite)
	return sprite:getClass() ~= 5
end
