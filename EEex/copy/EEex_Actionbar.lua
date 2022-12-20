
-----------------------
-- General Functions --
-----------------------

-- @bubb_doc { EEex_Actionbar_GetArray }
--
-- @summary: Returns the actionbar button array. This structure holds the current state of the actionbar.
--
-- @return { usertype=CInfButtonArray }: See summary.

function EEex_Actionbar_GetArray()
	return EEex_EngineGlobal_CBaldurChitin.m_pObjectGame.m_cButtonArray
end

-- @bubb_doc { EEex_Actionbar_GetState }
--
-- @summary: Returns the current actionbar state, which is a number that represents what the actionbar is displaying.
--
-- @return { type=number }: See summary.
--
-- @extra_comment:
--
-- ==================================================================================================================
--
-- **Actionbar State Ordinals**
-- ****************************
--
-- +-------+---------------------------------------------------+
-- | State | Description                                       |
-- +=======+===================================================+
-- | 1     | Mage / Sorcerer                                   |
-- +-------+---------------------------------------------------+
-- | 2     | Fighter                                           |
-- +-------+---------------------------------------------------+
-- | 3     | Cleric                                            |
-- +-------+---------------------------------------------------+
-- | 4     | Thief                                             |
-- +-------+---------------------------------------------------+
-- | 5     | Bard                                              |
-- +-------+---------------------------------------------------+
-- | 6     | Paladin                                           |
-- +-------+---------------------------------------------------+
-- | 7     | Fighter Mage                                      |
-- +-------+---------------------------------------------------+
-- | 8     | Fighter Cleric                                    |
-- +-------+---------------------------------------------------+
-- | 9     | Fighter Thief                                     |
-- +-------+---------------------------------------------------+
-- | 10    | Fighter Mage Thief                                |
-- +-------+---------------------------------------------------+
-- | 11    | Druid                                             |
-- +-------+---------------------------------------------------+
-- | 12    | Ranger                                            |
-- +-------+---------------------------------------------------+
-- | 13    | Mage Thief                                        |
-- +-------+---------------------------------------------------+
-- | 14    | Cleric Mage                                       |
-- +-------+---------------------------------------------------+
-- | 15    | Cleric Thief                                      |
-- +-------+---------------------------------------------------+
-- | 16    | Fighter Druid                                     |
-- +-------+---------------------------------------------------+
-- | 17    | Fighter Mage Cleric                               |
-- +-------+---------------------------------------------------+
-- | 18    | Cleric Ranger                                     |
-- +-------+---------------------------------------------------+
-- | 20    | Monk                                              |
-- +-------+---------------------------------------------------+
-- | 21    | Shaman                                            |
-- +-------+---------------------------------------------------+
-- | 101   | Select Weapon Ability                             |
-- +-------+---------------------------------------------------+
-- | 102   | Spells (Select Quick Spell)                       |
-- +-------+---------------------------------------------------+
-- | 103   | Spells (Cast)                                     |
-- +-------+---------------------------------------------------+
-- | 104   | Select Quick Item Ability                         |
-- +-------+---------------------------------------------------+
-- | 105   | Use Item                                          |
-- +-------+---------------------------------------------------+
-- | 106   | Special Abilities                                 |
-- +-------+---------------------------------------------------+
-- | 107   | Select Quick Formation                            |
-- +-------+---------------------------------------------------+
-- | 108   | Defunct Select Quick Formation (Not used)         |
-- +-------+---------------------------------------------------+
-- | 109   | Group Selected                                    |
-- +-------+---------------------------------------------------+
-- | 110   | Unknown (No buttons defined; not used?)           |
-- +-------+---------------------------------------------------+
-- | 111   | Internal List (Opcode #214)                       |
-- +-------+---------------------------------------------------+
-- | 112   | Controlled (Class doesn't have a dedicated state) |
-- +-------+---------------------------------------------------+
-- | 113   | Cleric / Mage Spells (Cast)                       |
-- +-------+---------------------------------------------------+
-- | 114   | Cleric / Mage Spells (Select Quick Spell)         |
-- +-------+---------------------------------------------------+

function EEex_Actionbar_GetState()
	return EEex_Actionbar_GetArray().m_nState
end

-- @bubb_doc { EEex_Actionbar_SetState }
--
-- @summary: Sets the current actionbar state. See :ref:`EEex_Actionbar_GetState` for more details.
--
-- @param { state / type=number }: The state to set.

function EEex_Actionbar_SetState(state)
	EEex_Actionbar_GetArray():SetState(state)
end

-- @bubb_doc { EEex_Actionbar_GetLastState }
--
-- @summary: Returns the previous actionbar state. See :ref:`EEex_Actionbar_GetState` for more details.
--
-- @return { type=number }: See summary.

function EEex_Actionbar_GetLastState()
	return EEex_Actionbar_GetArray().m_nLastState
end

-- @bubb_doc { EEex_Actionbar_RestoreLastState }
--
-- @summary: Restores the previous actionbar state. This is useful for exiting sub-states, such as the spell list.

function EEex_Actionbar_RestoreLastState()
	EEex_Actionbar_SetState(EEex_Actionbar_GetLastState())
end

EEex_Actionbar_ButtonType = {
	["BARD_SONG"] = 2,
	["CAST_SPELL"] = 3,
	["FIND_TRAPS"] = 4,
	["TALK"] = 5,
	["GUARD"] = 7,
	["ATTACK"] = 8,
	["SPECIAL_ABILITIES"] = 10,
	["STEALTH"] = 11,
	["THIEVING"] = 12,
	["TURN_UNDEAD"] = 13,
	["USE_ITEM"] = 14,
	["STOP"] = 15,
	["QUICK_ITEM_1"] = 21,
	["QUICK_ITEM_2"] = 22,
	["QUICK_ITEM_3"] = 23,
	["QUICK_SPELL_1"] = 24,
	["QUICK_SPELL_2"] = 25,
	["QUICK_SPELL_3"] = 26,
	["QUICK_WEAPON_1"] = 27,
	["QUICK_WEAPON_2"] = 28,
	["QUICK_WEAPON_3"] = 29,
	["QUICK_WEAPON_4"] = 30,
	["NONE"] = 100,
}

-- @bubb_doc { EEex_Actionbar_SetButton }
--
-- @summary: Changes the button at the given ``index`` to the given ``buttonType``.
--           Use this function in combination with an actionbar listener to permanently
--           change a button on the actionbar.
--
-- @param { index / type=number }: The button index to change. Valid values are [0-11].
--
-- @param { buttonType / type=EEex_Actionbar_ButtonType }: The button type to set.
--
-- @extra_comment:
--
-- ====================================================================================
--
-- **EEex_Actionbar_ButtonType**
-- *****************************
--
-- +-------------------+
-- | Ordinal Name      |
-- +===================+
-- | BARD_SONG         |
-- +-------------------+
-- | CAST_SPELL        |
-- +-------------------+
-- | FIND_TRAPS        |
-- +-------------------+
-- | TALK              |
-- +-------------------+
-- | GUARD             |
-- +-------------------+
-- | ATTACK            |
-- +-------------------+
-- | SPECIAL_ABILITIES |
-- +-------------------+
-- | STEALTH           |
-- +-------------------+
-- | THIEVING          |
-- +-------------------+
-- | TURN_UNDEAD       |
-- +-------------------+
-- | USE_ITEM          |
-- +-------------------+
-- | STOP              |
-- +-------------------+
-- | QUICK_ITEM_1      |
-- +-------------------+
-- | QUICK_ITEM_2      |
-- +-------------------+
-- | QUICK_ITEM_3      |
-- +-------------------+
-- | QUICK_SPELL_1     |
-- +-------------------+
-- | QUICK_SPELL_2     |
-- +-------------------+
-- | QUICK_SPELL_3     |
-- +-------------------+
-- | QUICK_WEAPON_1    |
-- +-------------------+
-- | QUICK_WEAPON_2    |
-- +-------------------+
-- | QUICK_WEAPON_3    |
-- +-------------------+
-- | QUICK_WEAPON_4    |
-- +-------------------+
-- | NONE              |
-- +-------------------+

function EEex_Actionbar_SetButton(buttonIndex, buttonType)
	if buttonIndex < 0 or buttonIndex > 11 then
		EEex_Error("buttonIndex out of bounds")
	end
	EEex_Actionbar_GetArray().m_buttonTypes:set(buttonIndex, buttonType)
end

-- @bubb_doc { EEex_Actionbar_IsThievingHotkeyOpeningSpecialAbilities }
--
-- @summary: Returns ``true`` if the thieving hotkey is currently in the middle of opening the special abilities menu.
--           It does this if the thieving button is not a part of the character's main actionbar state.
--           This function allows actionbar listeners to differentiate between a user opening the special abilities menu,
--           and the hotkey automatically doing so.
--
-- @return { type=boolean }: See summary.

function EEex_Actionbar_IsThievingHotkeyOpeningSpecialAbilities()
	return EEex_Actionbar_HookGlobal_IsThievingHotkeyOpeningSpecialAbilities
end

---------------
-- Listeners --
---------------

EEex_Actionbar_Listeners = EEex_Actionbar_Listeners or {}

-- @bubb_doc { EEex_Actionbar_AddListener }
--
-- @summary: Registers a function as an actionbar listener. Actionbar listeners are called whenever the actionbar changes state.
--           See :ref:`EEex_Actionbar_GetState` for more details.
--
-- @param { listener / type=function }: The listener to register.
--
-- @extra_comment:
--
-- =============================================================================================================================
--
-- **The listener function**
-- *************************
--
-- **Parameters:**
--
-- +--------+--------+---------------------------------------------------------------------------------------------------------+
-- | Name   | Type   | Description                                                                                             |
-- +========+========+=========================================================================================================+
-- | config | number | Certain actionbar states map to the same button configuration, albeit with different   :raw-html:`<br>` |
-- |        |        | functionality. This value represents a unique button configuration; see below for more :raw-html:`<br>` |
-- |        |        | details.                                                                                                |
-- +--------+--------+---------------------------------------------------------------------------------------------------------+
-- | state  | number | See :ref:`EEex_Actionbar_GetState`.                                                                     |
-- +--------+--------+---------------------------------------------------------------------------------------------------------+
--
-- **The following shows what actionbar states each** ``config`` **encompases:**
--
-- +--------+-----------------+
-- | Config | Matching States |
-- +========+=================+
-- | 0      | 1               |
-- +--------+-----------------+
-- | 1      | 2               |
-- +--------+-----------------+
-- | 2      | 3               |
-- +--------+-----------------+
-- | 3      | 4               |
-- +--------+-----------------+
-- | 4      | 5               |
-- +--------+-----------------+
-- | 5      | 6               |
-- +--------+-----------------+
-- | 6      | 7               |
-- +--------+-----------------+
-- | 7      | 8               |
-- +--------+-----------------+
-- | 8      | 9               |
-- +--------+-----------------+
-- | 9      | 10              |
-- +--------+-----------------+
-- | 10     | 11              |
-- +--------+-----------------+
-- | 11     | 12              |
-- +--------+-----------------+
-- | 12     | 13              |
-- +--------+-----------------+
-- | 13     | 14              |
-- +--------+-----------------+
-- | 14     | 15              |
-- +--------+-----------------+
-- | 15     | 16              |
-- +--------+-----------------+
-- | 16     | 17              |
-- +--------+-----------------+
-- | 17     | 18              |
-- +--------+-----------------+
-- | 18     | 20              |
-- +--------+-----------------+
-- | 19     | 21              |
-- +--------+-----------------+
-- | 20     | 101             |
-- +--------+-----------------+
-- | 21     | 102, 103        |
-- +--------+-----------------+
-- | 22     | 104, 105        |
-- +--------+-----------------+
-- | 23     | 106             |
-- +--------+-----------------+
-- | 24     | 107             |
-- +--------+-----------------+
-- | 25     | 108             |
-- +--------+-----------------+
-- | 26     | 109             |
-- +--------+-----------------+
-- | 27     | 110             |
-- +--------+-----------------+
-- | 28     | 111             |
-- +--------+-----------------+
-- | 29     | 112             |
-- +--------+-----------------+
-- | 30     | 113, 114        |
-- +--------+-----------------+

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
